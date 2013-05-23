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

static char m_wsMagicString[] = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

/*
 * Implementation
 */
#define BUF_LENGTH 200


/*
 * The goal of this is to see if we can construct a Sec-WebSocket-Accept header
 * from a Sec-WebSocket-Key.
 */
int main()
{
	/* Set up autorelease pool for Objective-C memory management */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	char sha_digest[SHA_DIGEST_LENGTH];
	char buf[BUF_LENGTH];

	/* Comes from Sec-WebSocket-Accept */
	char key[] = "dGhlIHNhbXBsZSBub25jZQ==";
	char expected[] = "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=";

	/* Concatenate the magic string, take the SHA1 and then base64 encode */
	strncpy(buf, key, BUF_LENGTH/2);
	strncat(buf, m_wsMagicString, BUF_LENGTH/2);
	SHA1((const unsigned char*)buf, strlen(buf), (unsigned char*)sha_digest);

	/* Correct up to here */
	NSData *data = [NSData dataWithBytes:sha_digest length:SHA_DIGEST_LENGTH];
	NSData *encodedData = [GSMimeDocument encodeBase64:data];
	[encodedData getBytes:(void*)buf length:BUF_LENGTH-1];
	buf[[encodedData length]] = '\0'; 	/* Terminate string */

	NSLog(@"key: %s", buf);

	/* Check the expected response */
	if (strcmp(expected, buf) == 0)
		NSLog(@"Matches!");
	else
		NSLog(@"You LOSE!");

	[pool release];
	return 0;
}
