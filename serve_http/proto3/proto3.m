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

/**
 * Parses an HTTP header into a field and value. If anything goes wrong,
 * returns -1; otherwise returns 0.
 *
 * The field and value will need to be freed by the caller.
 */
#define MAX_FIELD_LEN 40
#define MAX_VALUE_LEN 1000
int parse_header(const char *line, char **field, char **value)
{
	char *my_field = malloc(MAX_FIELD_LEN);
	char *my_value = malloc(MAX_VALUE_LEN);

	/* Look for header field name */
	int index = 0;
	int found_colon = 0;
	while (index < MAX_FIELD_LEN) {
		if (line[index] == ':') {
			found_colon = 1;
			my_field[index] = '\0';
			break;
		}
		my_field[index] = line[index];
		index++;
	}
	if (!found_colon) {
		fprintf(stderr, "Couldn't find ':' for header: %s\n", line);
		return -1;
	}

	/* Advance index to first non-blank. Assuming only spaces are
	 * whitespace */
	while (line[index++] == ' ') { }
	index--; 	/* Back up to first non-blank */

	/* Copy value over */
	strncpy(my_value, line+index, MAX_VALUE_LEN);

	/* Return results */
	*field = my_field;
	*value = my_value;
	return 0;
}


int main()
{
	/* NOTE: assuming that the request has been parsed into lines */
	char *line1 = "GET / HTTP/1.1";
	char *line2 = "User-Agent: curl/7.19.7 (x86_64-redhat-linux-gnu) "
		      "libcurl/7.19.7 NSS/3.12.9.0 zlib/1.2.3 libidn/1.18 libssh2/1.2.2";
	char *line3 = "Host: localhost:8888";
	char *line4 = "Accept: */*";
	char *headers[] = {line2, line3, line4};

	/* Parse request */
	char method[20], uri[200], version[20];

	/* Parse line1 */
	sscanf(line1, "%s %s %s", method, uri, version);
	printf("Method: %s, uri: %s, version: %s\n", method, uri, version);

	/* Parse headers */
	char *field;
	char *value;
	int i;
	for (i=0; i < 3; i++) {
		if (parse_header(headers[i], &field, &value) < 0)
			exit(1);
		printf("Field: %s, Value: %s\n", field, value);
		free(field);
		free(value);
	}

	return 0;
}
