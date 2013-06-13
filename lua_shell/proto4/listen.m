#import <Foundation/Foundation.h>
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


/*
 * Implementation
 */

static void
write_string(int connfd, NSString *string)
{
	Writen(connfd, [string cString], [string cStringLength]);
}

/* TODO: Move this to its own function */
static void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}

/*
 * This takes an HTML response body and sends it along with the other response
 * headers.
 */
static void
res_send(int connfd, NSString *body)
{
	NSString *content_length =
		[NSString stringWithFormat:@"Content-Length: %d\r\n",
		[body cStringLength]];

	write_string(connfd, @"HTTP/1.1 200 OK\r\n");
	write_string(connfd, content_length);
	write_string(connfd, @"Content-Type: text/html\r\n");
	write_string(connfd, @"\r\n");
	write_string(connfd, body);
}

static void
handle_http_request(int connfd)
{
	char buf[MAXLINE];

	while (readline(connfd, buf, MAXLINE) > 0) {
		if (strcmp(buf, "\r\n") == 0)
			break;
		printf("Got: '%s'\n", buf);
	}

	/* Just send a basic response */
	res_send(connfd, @"<html><body>Hi</body></html>\r\n");
}

pthread_t listener_thread_id;

static void *listen_routine(void *arg)
{
	int listenfd, connfd;
	socklen_t clilen;
	struct sockaddr_in cliaddr, servaddr;
        int option = 1;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

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
                handle_http_request(connfd);
                close(connfd);
	}
	[pool release];
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
