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

#import "HttpRequest.h"
#import "HttpResponse.h"
#import "WSFrame.h"

/*
 * This will listen for a web socket request, establish a connection, and then
 * print any messages received.
 */
int main()
{
	/* Set up autorelease pool for Objective-C memory management */
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

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
	[pool release];
	return 0;
}
