#include <lua.h>
#include <lauxlib.h>

#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

static pthread_t listener_thread_id;

static void *listener_routine(void *arg)
{
	lua_State *L = (lua_State*) arg;
	printf("%p: OUCH!\n", L);
	while(1) {
		fprintf(stderr, "Listening...\n");
		sleep(5);
	}
	return NULL;
}

static int l_start_listening(lua_State *L) {
	fprintf(stderr, "TODO: Start listening now\n");

	lua_State *L1 = luaL_newstate();

	if (!L1)
		luaL_error(L, "Unable to create new state");

	if (pthread_create(&listener_thread_id, NULL, listener_routine, L1) != 0)
		fprintf(stderr, "Unable to create listener thread\n");

	pthread_detach(listener_thread_id);
	return 0;
}

static const struct luaL_Reg mylib [] = {
	{"start_listening", l_start_listening},
	{NULL, NULL}
};

int luaopen_proto3(lua_State *L) {
	luaL_newlib(L, mylib);
	return 1;
}
