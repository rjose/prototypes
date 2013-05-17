#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>
#include <strings.h>

#define SA struct sockaddr
#define MAXLINE 100
#define LISTENQ 1024

ssize_t						/* Write "n" bytes to a descriptor. */
writen(int fd, const void *vptr, size_t n)
{
	size_t		nleft;
	ssize_t		nwritten;
	const char	*ptr;

	ptr = vptr;
	nleft = n;
	while (nleft > 0) {
		if ( (nwritten = write(fd, ptr, nleft)) <= 0) {
			if (nwritten < 0 && errno == EINTR)
				nwritten = 0;		/* and call write() again */
			else
				return(-1);			/* error */
		}

		nleft -= nwritten;
		ptr   += nwritten;
	}
	return(n);
}
/* end writen */

void
Writen(int fd, void *ptr, size_t nbytes)
{
	if (writen(fd, ptr, nbytes) != nbytes) {
		fprintf(stderr, "writen error\n");
		exit(1);
	}
}

void str_echo(int sockfd)
{
	ssize_t n;
	char buf[MAXLINE];

again:
	while ( (n = read(sockfd, buf, MAXLINE)) > 0 ) {
		Writen(sockfd, buf, n);

		if (n < 0 && errno == EINTR)
			goto again;
		else if (n < 0) {
			fprintf(stderr, "Read error\n");
			exit(1);
		}

	}
}

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

	if (bind(listenfd, (SA*) &servaddr, sizeof(servaddr)) < 0) {
		fprintf(stderr, "Problem binding: %d\n", errno);
		exit(1);
	}

	// Check for error here
	listen(listenfd, LISTENQ);

	while (1) {
		clilen = sizeof(cliaddr);
		connfd = accept(listenfd, (SA*) &cliaddr, &clilen);

		if ( (childpid = fork()) == 0) { /* Child */
			close(listenfd);
			str_echo(connfd);
			exit(0);
		}

		/* Parent closes socket */
		close(connfd);
	}
	return 0;
}
