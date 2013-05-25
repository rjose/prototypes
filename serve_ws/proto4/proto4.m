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
#import "HttpRequest.h"
#import "HttpResponse.h"
#import "WSFrame.h"

enum WebsocketState
{
	CONNECTING,
	OPEN,
	CLOSING,
	CLOSED
};

/*
 * Static declarations
 */
#define SA struct sockaddr
#define MAXLINE 1024
#define LISTENQ 1024

static void accept_websocket_connections();
static void handle_websocket_request(int);
static enum WebsocketState m_state = CONNECTING;


/* This should be a unit test */
void
test_parse_frame()
{
	char wsFrame[] = {0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f};
	NSData *frameData = [NSData dataWithBytes:wsFrame length:sizeof(wsFrame)];

	WSFrame *frame = [[WSFrame alloc] init];
	[frame appendData:frameData];

	NSString *bodyText = [frame getBodyText];
	if (bodyText != nil && [bodyText compare:@"Hello"] == NSOrderedSame)
		NSLog(@"Match!");
	else
		NSLog(@"You LOSE!");

	[frame release];
}

static int
look_for_http_request(int connfd, HttpRequest **result)
{
	char buf[MAXLINE];
	char method[20], uri[200], version[20];
	char *field, *value;

	/* Look for URI and then create request */
	if (readline(connfd, buf, MAXLINE) < 0) {
		warnx("Problem reading from tcp");
		return -1;
	}
	if (sscanf(buf, "%s %s %s", method, uri, version) == EOF) {
		warnx("Couldn't find URI when expected");
		return -1;
	}
	HttpRequest *request = [[HttpRequest alloc]
		initWithMethod:[NSString stringWithCString:method]
			andUri:[NSString stringWithCString:uri]];
	[request autorelease];

	/* Add headers */


	while (readline(connfd, buf, MAXLINE) > 0) {
		/* If we get a blank line, the HTTP request is done */
		if (strcmp(buf, "\r\n") == 0)
			break;

		/* Parse header and store */
		if (parse_header(buf, &field, &value) != 0) {
			warnx("Problem parsing header");
			return -1;
		}
		[request addHeader:[NSString stringWithCString:field]
			 withValue:[NSString stringWithCString:value]];
		printf("field: '%s', value: '%s'\n", field, value);
		free(field);
		free(value);
	}

	*result = request;
	return 0;
}


static void
handle_websocket_request(int connfd)
{
	char buf[MAXLINE];

	/* First we're CONNECTING */
	m_state = CONNECTING;
	HttpRequest *request;
	if (look_for_http_request(connfd, &request) != 0)
		errx(1, "No request");
	[request retain];

	/* Construct a handshake response and send */
	HttpResponse *response = [HttpResponse getResponse:request];
	if (response == nil)
		errx(1, "Exiting handler thread because didn't get a WebSocket request");

        warnx("Send response:\n%s", [[response toString] cString]);
        // TODO: Write this back

        warnx("TODO: Finish handling the request");

	/* Listen for messages, looking for a CLOSE frame */
	[request release];
}

/*
 * This forks off new processes to handle web socket requests. If something goes
 * wrong, the child process will print an error and then exit.
 */
static void
accept_websocket_connections()
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
			handle_websocket_request(connfd);
			exit(0);
		}

		/* Parent closes socket */
		close(connfd);
	}
}

/*
 * This will listen for a web socket request, establish a connection, and then
 * print any messages received.
 */
int main()
{
	/* Set up autorelease pool for Objective-C memory management */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	accept_websocket_connections();

	[pool release];
	return 0;
}
