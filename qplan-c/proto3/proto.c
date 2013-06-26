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

#define MAXLINE 1024


typedef struct QPlanContext_ {
        lua_State *main_lua_state;
        pthread_mutex_t *main_mutex;

        lua_State *web_lua_state;
        pthread_mutex_t *web_mutex;
} QPlanContext;

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

static void *web_routine(void *arg)
{
        QPlanContext *ctx = (QPlanContext *)arg;
        int cutline = 0;

        lua_State *L = ctx->main_lua_state;
        lua_State *Lweb = ctx->web_lua_state;

        /*
         * Simulate external change
         */
        while(1) {
                sleep(1);

                lock_main(ctx);
                lua_getglobal(L, "sc");
                lua_pushnumber(L, cutline);
                if (lua_pcall(L, 1, 0, 0) != LUA_OK)
                        luaL_error(L, "Problem calling lua function: %s",
                                        lua_tostring(L, -1));
                unlock_main(ctx);
                cutline++;
        }

        return NULL;
}


int main(int argc, char *argv[])
{
	void *thread_result;
	int status;
        pthread_mutex_t main_mutex = PTHREAD_MUTEX_INITIALIZER;
        pthread_mutex_t web_mutex = PTHREAD_MUTEX_INITIALIZER;

        pthread_t repl_thread_id;
        pthread_t web_thread_id;

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

        /* TODO: specify this from the commandline args */
        lua_getglobal(L_main, "s");
        lua_pushnumber(L_main, 8);
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
