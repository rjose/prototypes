#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>
#include <strings.h>
#include <string.h>

#define SA struct sockaddr
#define MAXLINE 100
#define LISTENQ 1024

// TODO: Move some of these to another file
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

// TODO: Bring the readline function over

int proto_echo()
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
	if (listen(listenfd, LISTENQ) < 0) {
		fprintf(stderr, "Problem listening: %d\n", errno);
		exit(1);
	}

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

int parse_header(const char *line, char **header_field, char **header_value)
{
	int len = strlen(line);
	if (len == 0)
		return -1;

	/* Scan to find the first ':'. This will give me the header name.
	 *
	 * If I find a space or no colon, we'll return -1. */
	int i = 0;
	int field_len = -1;
	for (i=0; i < len; i++) {
		if (line[i] == ' ' || line[i] == '\t')
			break;

		if (line[i] == ':')
			field_len = i;
			break;
	}
	if (field_len < 0) {
		fprintf(stderr, "Couldn't find header in: %s\n", line);
		return -1;
	}
	
	/* I'll allocate enough space to hold the header name (and the \0)
	 * without the colon. */
	char *field = malloc(field_len);
	if (field == NULL) {
		fprintf(stderr, "Problem allocating memory\n");
		return -1;
	}
	strncpy(field, line, field_len);
	field[field_len-1] = '\0';

	
	/* Next, I'll scan to the first non-whitespace character and then
	 * allocate memory to hold from that point to the end and then copy
	 * the header value there. */ 
	int value_start = -1;
	for (i=field_len+1; i < len; i++) {
		if (line[i] != ' ' && line[i] != '\t')
			value_start = i;
			break;
	}
	if (value_start < 0) {
		fprintf(stderr, "Couldn't find header value\n");
		return -1;
	}
	// TODO: Allocate space for value and copy data into it
	
	We'll point the header_name and
header_value arguments to those values respectively. The caller is responsible
for freeing memory. I'm assuming that we'll only see tabs and spaces as
whitespace.
}

int main()
{
	/* NOTE: assuming that the request has been parsed into lines */
	char *line1 = "GET / HTTP/1.1";
	char *line2 = "User-Agent: curl/7.19.7 (x86_64-redhat-linux-gnu) "
		      "libcurl/7.19.7 NSS/3.12.9.0 zlib/1.2.3 libidn/1.18 libssh2/1.2.2";
	char *line3 = "Host: localhost:8888";
	char *line4 = "Accept: */*";

	/* Parse request */
	char method[20], uri[200], version[20];

	/* Parse line1 */
	sscanf(line1, "%s %s %s", &method, &uri, &version);
	printf("Method: %s, uri: %s, version: %s\n", method, uri, version);

	/* sscanf won't work for the rest because of whitespace. We'll need to
	 * parse these differently. Let's do this afterwards. */

	return 0;
}
