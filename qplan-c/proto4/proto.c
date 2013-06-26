#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <err.h>
#include <errno.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "tcp_io.h"

#define SA struct sockaddr
#define LISTENQ 1024
#define MAXLINE 1024


typedef struct QPlanContext_ {
        lua_State *main_lua_state;
        pthread_mutex_t *main_mutex;

        lua_State *web_lua_state;
        pthread_mutex_t *web_mutex;
} QPlanContext;

typedef struct WebHandlerContext_ {
        QPlanContext *context;
        int connfd;
} WebHandlerContext;

static void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}

static void lock_main(QPlanContext *ctx)
{
        // TODO: Reject if we've already locked web
        if (pthread_mutex_lock(ctx->main_mutex) != 0)
                err_abort(-1, "Problem locking main mutex");
}

static void unlock_main(QPlanContext *ctx)
{
        if (pthread_mutex_unlock(ctx->main_mutex) != 0)
                err_abort(-1, "Problem unlocking main mutex");
}

static void lock_web(QPlanContext *ctx)
{
        if (pthread_mutex_lock(ctx->web_mutex) != 0)
                err_abort(-1, "Problem locking web mutex");
}

static void unlock_web(QPlanContext *ctx)
{
        if (pthread_mutex_unlock(ctx->web_mutex) != 0)
                err_abort(-1, "Problem unlocking web mutex");
}

static void *repl_routine(void *arg)
{
        char buf[MAXLINE];
        int error;
        QPlanContext *ctx = (QPlanContext *)arg;

        lua_State *L = ctx->main_lua_state;


        /*
         * REPL
         */
        printf("qplan> ");
        while (fgets(buf, sizeof(buf), stdin) != NULL) {
                lock_main(ctx);
                error = luaL_loadstring(L, buf) || lua_pcall(L, 0, 0, 0);

                if (error) {
                        fprintf(stderr, "%s\n", lua_tostring(L, -1));
                        lua_pop(L, 1);
                }
                unlock_main(ctx);
                printf("qplan> ");
        }

        return NULL;
}

static void *handle_request_routine(void *arg)
{
        WebHandlerContext *req_context = (WebHandlerContext *)arg;
        char *request_string;
	char buf[MAXLINE];
        int connfd = req_context->connfd;
        int cur_len;
        int str_capacity;
        int req_len = 0;
        lua_State *L_main = req_context->context->main_lua_state;
        int i;
        int res_len;
        char *tmp;
        char *res_str;

        if ((request_string = malloc(sizeof(char) * MAXLINE)) == NULL)
                err_abort(-1, "Couldn't allocate memory");
        str_capacity = MAXLINE;


        if (pthread_detach(pthread_self()) != 0)
                err_abort(-1, "Couldn't detach thread");

        // TODO: Need a timeout for malformed requests
	while ((cur_len = my_readline(connfd, buf, MAXLINE)) > 0) {
		if (strcmp(buf, "\r\n") == 0)
			break;

                /*
                 * Build request string
                 */
                if ((req_len + cur_len) >= str_capacity) {
                        if ((request_string = realloc(request_string,
                            sizeof(char) * (str_capacity + MAXLINE))) == NULL)
                                err_abort(-1, "Couldn't realloc memory");

                        str_capacity += MAXLINE;
                }
                for (i = 0; i < cur_len; i++)
                        request_string[req_len++] = buf[i];
	}
        request_string[req_len] = '\0';

        lock_main(req_context->context);
        lua_getglobal(L_main, "web");
        lua_pushstring(L_main, "handle_request");
        lua_gettable(L_main, -2);
        lua_pushlstring(L_main, request_string, req_len);
        if (lua_pcall(L_main, 1, 1, 0) != LUA_OK)
                luaL_error(L_main, "Problem calling lua function: %s",
                                lua_tostring(L_main, -1));
        /* Copy result string */
        tmp = lua_tolstring(L_main, -1, &res_len);
        if ((res_str = (char *)malloc(sizeof(char)*res_len)) == NULL)
                err_abort(-1, "Couldn't allocate memory");
        strncpy(res_str, tmp, res_len);
        unlock_main(req_context->context);

        my_writen(connfd, res_str, res_len);

        close(connfd);
        free(req_context);
        return NULL;
}

static void *web_routine(void *arg)
{
        QPlanContext *ctx = (QPlanContext *)arg;
        WebHandlerContext *handler_context;

	int listenfd, connfd;
	socklen_t clilen;
	struct sockaddr_in cliaddr, servaddr;
        pthread_t tid;
        int option = 1;
        int status;

	listenfd = socket(AF_INET, SOCK_STREAM, 0);

	/* Reuse port so we don't have to wait before the program can be
	 * restarted because of the TIME_WAIT state. */
        if ( setsockopt(listenfd,
                        SOL_SOCKET,
                        SO_REUSEADDR,
                        &option, sizeof(option)) != 0)
                err(1, "setsockopt failed");

	bzero(&servaddr, sizeof(servaddr));
	servaddr.sin_family = AF_INET;
	servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
	servaddr.sin_port = htons(8888);

	if (bind(listenfd, (SA*) &servaddr, sizeof(servaddr)) < 0)
		err(1, "Problem binding to descriptor:%d", listenfd);

	if (listen(listenfd, LISTENQ) < 0)
		err(1, "Problem listening to descriptor: %d", listenfd);

        /*
         * Listen for connections
         */
        clilen = sizeof(cliaddr);
        while(1) {
		connfd = accept(listenfd, (SA*) &cliaddr, &clilen);

                /*
                 * Set up handler context
                 */
                handler_context = (WebHandlerContext *)malloc(sizeof(WebHandlerContext));
                if (handler_context == NULL)
                        err_abort(-1, "Unable to allocate memory");
                handler_context->context = ctx;
                handler_context->connfd = connfd;

                status = pthread_create(&tid, NULL, handle_request_routine,
                                                       (void *)handler_context);
                if (status != 0)
                        err_abort(status, "Create repl thread");
        }

        return NULL;
}


int main(int argc, char *argv[])
{
        int version;
	void *thread_result;
	long status;
        pthread_mutex_t main_mutex = PTHREAD_MUTEX_INITIALIZER;
        pthread_mutex_t web_mutex = PTHREAD_MUTEX_INITIALIZER;

        pthread_t repl_thread_id;
        pthread_t web_thread_id;

        if (argc < 2) {
                printf("Usage: qplan <version>\n");
                return 1;
        }

        version = strtol(argv[1], NULL, 0);

        /*
         * Create lua states
         */
        lua_State *L_main = luaL_newstate();
        luaL_openlibs(L_main);

        lua_State *L_web = luaL_newstate();
        luaL_openlibs(L_web);

        /*
         * Require shell functions
         */
        lua_getglobal(L_main, "require");
        lua_pushstring(L_main, "app.shell_functions");
        if (lua_pcall(L_main, 1, 1, 0) != LUA_OK)
                luaL_error(L_main, "Problem requiring shell functions: %s",
                                lua_tostring(L_main, -1));

        /* Load version specified from commandline */
        lua_getglobal(L_main, "s");
        lua_pushnumber(L_main, version);
        if (lua_pcall(L_main, 1, 0, 0) != LUA_OK)
                luaL_error(L_main, "Problem calling lua function: %s",
                                lua_tostring(L_main, -1));

        lua_getglobal(L_web, "require");
        lua_pushstring(L_web, "modules.web");
        if (lua_pcall(L_web, 1, 1, 0) != LUA_OK)
                luaL_error(L_web, "Problem requiring shell functions: %s",
                                lua_tostring(L_web, -1));

        /*
         * Set up context
         */
        QPlanContext qplan_context;
        qplan_context.main_lua_state = L_main;
        qplan_context.main_mutex = &main_mutex;
        qplan_context.web_lua_state = L_web;
        qplan_context.web_mutex = &web_mutex;

	/* Create REPL thread */
	status = pthread_create(&repl_thread_id, NULL, repl_routine, (void *)&qplan_context);
	if (status != 0)
		err_abort(status, "Create repl thread");

        /* Create web server thread */
	status = pthread_create(&web_thread_id, NULL, web_routine, (void *)&qplan_context);
	if (status != 0)
		err_abort(status, "Create web thread");
	status = pthread_detach(web_thread_id);
	if (status != 0)
		err_abort(status, "Porlbme detaching web thread");


	/* Join REPL thread */
	status = pthread_join(repl_thread_id, &thread_result);
	if (status != 0)
		err_abort(status, "Join thread");

        lua_close(L_main);
        lua_close(L_web);

	printf("We are most successfully done!\n");
	return 0;
}
