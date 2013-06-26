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

pthread_t repl_thread_id;

static void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}


static void *repl_routine(void *arg)
{
        char buf[MAXLINE];
        int error;

        lua_State *L = luaL_newstate();
        luaL_openlibs(L);

        /*
         * Require shell functions
         */
        lua_getglobal(L, "require");
        lua_pushstring(L, "app.shell_functions");
        if (lua_pcall(L, 1, 1, 0) != LUA_OK)
                luaL_error(L, "Problem requiring shell functions: %s",
                                lua_tostring(L, -1));

        /*
         * REPL
         */
        printf("qplan> ");
        while (fgets(buf, sizeof(buf), stdin) != NULL) {
                error = luaL_loadstring(L, buf) || lua_pcall(L, 0, 0, 0);

                if (error) {
                        fprintf(stderr, "%s\n", lua_tostring(L, -1));
                        lua_pop(L, 1);
                }
                printf("qplan> ");
        }

        lua_close(L);
        return NULL;
}



int main(int argc, char *argv[])
{
	void *thread_result;
	int status;

	// Create REPL thread
	status = pthread_create(&repl_thread_id, NULL, repl_routine, NULL);
	if (status != 0)
		err_abort(status, "Create thread");

        printf("Created thread!\n");

	// Join REPL thread
	status = pthread_join(repl_thread_id, &thread_result);
	if (status != 0)
		err_abort(status, "Join thread");

	printf("We are most successfully done!\n");
	return 0;
}
