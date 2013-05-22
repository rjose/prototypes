#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <err.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

#import <Foundation/Foundation.h>

#include "http_header.h"
#include "tcp_io.h"

#define SA struct sockaddr
#define MAXLINE 1024
#define LISTENQ 1024

/*
 * static declarations
 */
static void write_string(int, NSString *);


/*
 * Implementation
 */

static void
write_string(int connfd, NSString *string)
{
	Writen(connfd, [string cString], [string cStringLength]);
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

/*
 * The first pass will read the request until we see the final CRLF. At some
 * point we should look for the Content-Length header to see if there's a
 * message, too.
 */
int main()
{
	int listenfd, connfd;
	pid_t childpid;
	socklen_t clilen;
	struct sockaddr_in cliaddr, servaddr;

	/* Set up autorelease pool for Objective-C memory management */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	listenfd = socket(AF_INET, SOCK_STREAM, 0);

	bzero(&servaddr, sizeof(servaddr));
	servaddr.sin_family = AF_INET;
	servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
	servaddr.sin_port = htons(8888);

	if (bind(listenfd, (SA*) &servaddr, sizeof(servaddr)) < 0)
		err(1, "Problem binding to descriptor:%d", listenfd);

	// Check for error here
	if (listen(listenfd, LISTENQ) < 0)
		err(1, "Problem listening to descriptor: %d", listenfd);

	while (1) {
		clilen = sizeof(cliaddr);
		connfd = accept(listenfd, (SA*) &cliaddr, &clilen);

		if ( (childpid = fork()) == 0) { /* Child */
			close(listenfd);
			handle_http_request(connfd);
			exit(0);
		}

		/* Parent closes socket */
		close(connfd);
	}

	[pool release];
	return 0;
}
