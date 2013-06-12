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

#include <lua.h>
#include <lauxlib.h>

#include "tcp_io.h"

#define SA struct sockaddr
#define MAXLINE 1024
#define LISTENQ 1024


/*
 * static declarations
 */
static void write_string(int, const char *);


/*
 * Implementation
 */

static void
write_string(int connfd, const char *string)
{
	Writen(connfd, string, strlen(string));
}

static pthread_t listener_thread_id;

#define MAX_CONNECTIONS 10
static int connections[MAX_CONNECTIONS];
static int next_connection_index = 0;
pthread_mutex_t connections_mutex = PTHREAD_MUTEX_INITIALIZER;


static void *listener_routine(void *arg)
{
	int listenfd, connfd;
	socklen_t clilen;
	struct sockaddr_in cliaddr, servaddr;
        int option = 1;
	char buf[MAXLINE];

	//lua_State *L = (lua_State*) arg;

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

	// Check for error here
	if (listen(listenfd, LISTENQ) < 0)
		err(1, "Problem listening to descriptor: %d", listenfd);
	while(1) {
		clilen = sizeof(cliaddr);
		connfd = accept(listenfd, (SA*) &cliaddr, &clilen);
		if (next_connection_index >= MAX_CONNECTIONS) {
			fprintf(stderr, "Can't store any more connections\n");
			close(connfd);
		}
		else {
			if (pthread_mutex_lock(&connections_mutex) != 0)
				err(1, "Can't lock connections_mutex");

			connections[next_connection_index] = connfd;
			next_connection_index++;

			if (pthread_mutex_unlock(&connections_mutex) != 0)
				err(1, "Can't unlock connections_mutex");
		}
	}
	return NULL;
}

static int l_start_listening(lua_State *L) {
	fprintf(stderr, "Accepting connections to 8888\n");

	lua_State *L1 = luaL_newstate();

	if (!L1)
		luaL_error(L, "Unable to create new state");

	if (pthread_create(&listener_thread_id, NULL, listener_routine, L1) != 0)
		fprintf(stderr, "Unable to create listener thread\n");

	pthread_detach(listener_thread_id);
	return 0;
}

static int l_broadcast_message(lua_State *L) {
	// Lock
	if (pthread_mutex_lock(&connections_mutex) != 0)
		err(1, "Can't lock connections_mutex");
	int i;

	for (i=0; i < next_connection_index; i++) {
		write_string(connections[i], "Hello from a broadcast!\n");
	}

	// Unlock
	if (pthread_mutex_unlock(&connections_mutex) != 0)
		err(1, "Can't unlock connections_mutex");
	return 0;
}
static const struct luaL_Reg mylib [] = {
	{"start_listening", l_start_listening},
	{"broadcast_message", l_broadcast_message},
	{NULL, NULL}
};

int luaopen_proto6(lua_State *L) {
	luaL_newlib(L, mylib);
	return 1;
}
