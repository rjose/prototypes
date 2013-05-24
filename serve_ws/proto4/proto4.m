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

#import "HttpRequest.h"
#import "HttpResponse.h"
#import "WSFrame.h"


/*
 * static declarations
 */
#define FRAME_LEN 1000
#define BUF_LENGTH 200

#define SHORT_MESSAGE_LEN 125
static char m_wsMagicString[] = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";


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

// TODO: Move this to HttpResponse
/* 
 * The key comes from Sec-WebSocket-Accept.
 */
NSString *calculate_websocket_accept(NSString *key)
{
	char sha_digest[SHA_DIGEST_LENGTH];
	char buf[BUF_LENGTH];

	/* Concatenate the magic string and take the SHA1... */
	strncpy(buf, [key cString], BUF_LENGTH/2);
	strncat(buf, m_wsMagicString, BUF_LENGTH/2);
	SHA1((const unsigned char*)buf, strlen(buf), (unsigned char*)sha_digest);

	/* ...then base64 encode */
	NSData *data = [NSData dataWithBytes:sha_digest length:SHA_DIGEST_LENGTH];
	NSData *encodedData = [GSMimeDocument encodeBase64:data];
	[encodedData getBytes:(void*)buf length:BUF_LENGTH-1];
	buf[[encodedData length]] = '\0'; 	/* Terminate string */

	/* Return result */
	NSString *result = [NSString stringWithCString:buf];
	return result;
}

static HttpResponse *get_websocket_response(HttpRequest *request)
{
	/* Check for Upgrade: websocket in request */
	NSString *upgradeHeader = [request getHeader:@"upgrade"];
	if ([upgradeHeader compare:@"websocket"] != NSOrderedSame) {
		warn("Upgrade is '%s' not websocket", [upgradeHeader cString]);
		return nil;
	}

	NSString *websocketKey = [request getHeader:@"sec-websocket-key"];
	if (websocketKey == nil) {
		warn("Expected a sec-websocket-key header");
		return nil;
	}

	NSString *websocketAccept = calculate_websocket_accept(websocketKey);
	if (websocketAccept == nil) {
		warn("Problem calculating websocket accept");
		return nil;
	}

	HttpResponse *result = [[HttpResponse alloc] initWithStatus:101
							  andReason:@"Switching Protocols"];
	[result addHeader:@"Upgrade" withValue:@"websocket"];
	[result addHeader:@"Connection" withValue:@"Upgrade"];
	[result addHeader:@"Sec-WebSocket-Accept" withValue:websocketAccept];
	[result autorelease];
	
	return result;
}

/*
 * The goal of this is to see if we can construct a Sec-WebSocket-Accept header
 * from a Sec-WebSocket-Key.
 */
int main()
{
	/* Set up autorelease pool for Objective-C memory management */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	char wsFrame[] = {0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f};
	NSData *frameData = [NSData dataWithBytes:wsFrame length:sizeof(wsFrame)];

	WSFrame *frame = [[WSFrame alloc] init];
	[[frame data] appendData:frameData];

	NSString *bodyText = [frame getBodyText];
	if (bodyText != nil && [bodyText compare:@"Hello"] == NSOrderedSame)
		NSLog(@"Match!");
	else
		NSLog(@"You LOSE!");

	[frame release];
	[pool release];
	return 0;
}
