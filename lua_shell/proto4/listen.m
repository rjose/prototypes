#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <err.h>
#include <errno.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <strings.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#import "tcp_io.h"

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
/* TODO: Move this to its own function */

static void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}
pthread_t listener_thread_id;

static void *listen_routine(void *arg)
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
                printf("Got connection: %d and closing it\n", connfd);
                close(connfd);
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
