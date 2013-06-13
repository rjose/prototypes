#import <Foundation/Foundation.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#define MAXLINE 1024

pthread_t repl_thread_id;

void *repl_routine(void *arg)
{
        // Lua things
        char buf[MAXLINE];
        int error;

        lua_State *L = luaL_newstate();
        luaL_openlibs(L);

        while (fgets(buf, sizeof(buf), stdin) != NULL) {
                error = luaL_loadstring(L, buf) || lua_pcall(L, 0, 0, 0);

                if (error) {
                        fprintf(stderr, "%s\n", lua_tostring(L, -1));
                        lua_pop(L, 1);
                }
        }

        lua_close(L);
        return NULL;
}

void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}

int main(int argc, char *argv[])
{
	// Set up autorelease pool for Objective-C memory management
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];


	// Generic to work with pthread functions
	void *thread_result;
	int status;

	// Create REPL thread
	pthread_t repl_thread_id;
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
