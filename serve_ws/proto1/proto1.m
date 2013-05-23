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
#import <Foundation/NSString.h>
#import <GNUstepBase/GSMime.h>


/*
 * static declarations
 */


/*
 * Implementation
 */
#define BUF_LENGTH 256


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

	/* Magic web socket string */
	NSString *wsMagicString = @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

	/* Comes from Sec-WebSocket-Accept */
	NSString *key = @"dGhlIHNhbXBsZSBub25jZQ==";

	/* Concatenate the magic string, take the SHA1 and then base64 encode */
	NSMutableString *responseValue = [NSMutableString stringWithString:key];
	[responseValue appendString:wsMagicString];

	[responseValue getCString:buf maxLength:BUF_LENGTH encoding:NSUTF8StringEncoding];
	if ([responseValue length] >= BUF_LENGTH)
		err(1, "Problem storing string");

	SHA1((const unsigned char*)buf, [responseValue length], (unsigned char*)sha_digest);

	/* Correct up to here */
	NSData *data = [NSData dataWithBytes:sha_digest length:SHA_DIGEST_LENGTH];
	NSData *encodedData = [GSMimeDocument encodeBase64:data];
	[encodedData getBytes:(void*)buf length:BUF_LENGTH-1];
	buf[[encodedData length]] = '\0'; 	/* Terminate string */
	

	NSLog(@"key: %s", buf);

	/* TODO: Check the expected response */
	//NSString *expectedResponse = @"s3pPLMBiTxaQ9kYGzzhZRbK+xOo=";

	[pool release];
	return 0;
}
