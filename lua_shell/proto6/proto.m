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


char *my_generator(const char*, int);
static char **my_completion(const char*, int, int);
char *dupstr(char*);
void *xmalloc(int);



static char **my_completion(const char *text, int start, int end)
{
	char **matches;
	matches = (char **)NULL;

	if (start == 0)
		matches = rl_completion_matches((char*)text, &my_generator);
	else
		rl_bind_key('\t', rl_abort);

	return matches;
}

char *my_generator(const char *text, int state)
{
	static char *cmd[] = {"rbt()", "rrt()", "pw()", NULL};
	static int list_index, len;
	char *name;

	if (!state) {
		list_index = 0;
		len = strlen(text);
	}

	while ((name = cmd[list_index++])) {
		if (strncmp(name, text, len) == 0)
			return dupstr(name);
	}
	return (char*) NULL;
}

char *dupstr(char *s)
{
	char *r;
	// TODO: Check the result of this
	r = (char*) malloc((strlen(s) + 1));
	strcpy(r, s);
	return r;
}


pthread_t repl_thread_id;

static void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}


static void *repl_routine(void *arg)
{
	char *line;
        int error;

	rl_attempted_completion_function = my_completion;

        lua_State *L = luaL_newstate();
        luaL_openlibs(L);

        /* Register functions */
        lua_pushcfunction(L, l_listen);
        lua_setglobal(L, "listen");

        while ((line = readline("qplan> ")) != NULL) {
		rl_bind_key('\t', rl_complete);

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
