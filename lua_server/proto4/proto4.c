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

static void
str_echo(int sockfd)
{
	ssize_t n;
	char buf[MAXLINE];

	printf("Echoing data from port %d\n", sockfd);

again:
	while ( (n = read(sockfd, buf, MAXLINE)) > 0) {
		Writen(sockfd, buf, n);
	}

	if (n < 0 && errno == EINTR)
		goto again;
	else if (n < 0)
		err(1, "Problem reading");
}


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
		str_echo(connfd);
		close(connfd);
		//close(listenfd);
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

static const struct luaL_Reg mylib [] = {
	{"start_listening", l_start_listening},
	{NULL, NULL}
};

int luaopen_proto4(lua_State *L) {
	luaL_newlib(L, mylib);
	return 1;
}
