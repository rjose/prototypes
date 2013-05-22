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

#include "http_header.h"
#include "tcp_io.h"

#define SA struct sockaddr
#define MAXLINE 1024
#define LISTENQ 1024

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
	Writen(connfd, "HTTP/1.1 200 OK\r\n", 17);
	Writen(connfd, "Content-Length: 28\r\n", 20);
	Writen(connfd, "Content-Type: text/html\r\n", 25);
	Writen(connfd, "\r\n", 2);
	Writen(connfd, "<html><body>Hi</body></html>\r\n", 30);
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
	return 0;
}
