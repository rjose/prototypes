#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

/* TODO: Move this to its own function */

static void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}
pthread_t listener_thread_id;

static void *listen_routine(void *arg)
{
        while(1) {
                printf("Listening...\n");
                sleep(2);
        }
        return NULL;
}

int l_listen(lua_State *L)
{
	int status = pthread_create(&listener_thread_id, NULL, listen_routine, NULL);
	if (status != 0)
		err_abort(status, "Create thread");

        printf("Created listener thread!\n");
        return 0;
}
