#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <openssl/sha.h>

#include <err.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

#import <Foundation/Foundation.h>
#import <GNUstepBase/GSMime.h>


/*
 * static declarations
 */
#define FRAME_LEN 1000

#define SHORT_MESSAGE_LEN 125

/* Byte 0 of frame */
#define WS_FRAME_FIN 0x80
#define WS_FRAME_OP_CONT 0x00
#define WS_FRAME_OP_TEXT 0x01
#define WS_FRAME_OP_BIN 0x02
#define WS_FRAME_OP_CLOSE 0x08
#define WS_FRAME_OP_PING 0x09
#define WS_FRAME_OP_PONG 0x0A

/* Byte 1 of frame */
#define WS_FRAME_MASK 0x80

/*
 * Implementation
 */


/*
 * This is only used for constructing small messages (body <=
 * SHORT_MESSAGE_LEN).
 */
static int
construct_frame(char *dst, const char *body, size_t max_len)
{
	char byte0, byte1;
	int len = strlen(body);

	/* Check some edge cases */
	if (len > SHORT_MESSAGE_LEN) {
		warn("Length (%d) must be <= %d", len, SHORT_MESSAGE_LEN);
		return -1;
	}
	if (max_len < len + 2) { /* byte0, byte1 go at front of frame */
		warn("Not enough characters to store frame");
		return -1;
	}

	/* Figure out first 2 bytes */
	byte0 = WS_FRAME_FIN | WS_FRAME_OP_TEXT;
	byte1 = 0;
	byte1 |= len;

	/* Copy data into dst */
	*dst++ = byte0;
	*dst++ = byte1;
	int i;
	for (i=0; i < len; i++)
		*dst++ = body[i];

	return 0;
}

/*
 * The goal of this is to see if we can construct a Sec-WebSocket-Accept header
 * from a Sec-WebSocket-Key.
 */
int main()
{
	/* Set up autorelease pool for Objective-C memory management */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	char frame[FRAME_LEN];

	char body[] = "Hello";
	char expected[] = {0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f};

	if (construct_frame(frame, body, FRAME_LEN) != 0)
		err(1, "Problem with frame");

	if (memcmp(expected, frame, sizeof(expected)) == 0)
		NSLog(@"Match!");
	else
		NSLog(@"You LOSE!");

	[pool release];
	return 0;
}
