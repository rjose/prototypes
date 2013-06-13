#import <Foundation/Foundation.h>
#include <err.h>
#include <errno.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

#include <readline/readline.h>
#include <readline/history.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#import "listen.h"

#define MAXLINE 1024


pthread_t repl_thread_id;

static void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}


static void *repl_routine(void *arg)
{
        // Lua things
        //char buf[MAXLINE];
	char *line;
        int error;

        lua_State *L = luaL_newstate();
        luaL_openlibs(L);

        /* Register functions */
        lua_pushcfunction(L, l_listen);
        lua_setglobal(L, "listen");

        while ((line = readline("qplan> ")) != NULL) {
                error = luaL_loadstring(L, line) || lua_pcall(L, 0, 0, 0);
		add_history(line);
		free(line);

                if (error) {
                        fprintf(stderr, "%s\n", lua_tostring(L, -1));
                        lua_pop(L, 1);
                }
        }

        lua_close(L);
        return NULL;
}



int main(int argc, char *argv[])
{
	// Set up autorelease pool for Objective-C memory management
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// Generic to work with pthread functions
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

	// Free the pool
	[pool release];

	printf("We are most successfully done!\n");
	return 0;
}
