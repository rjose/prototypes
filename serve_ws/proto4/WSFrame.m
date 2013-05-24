#include <err.h>

#import "WSFrame.h"

#define SHORT_MESSAGE_LEN 125

@implementation WSFrame

- (id)init
{
	self = [super init];
	if (self) {
		data = [NSMutableData dataWithCapacity:200];
		[data retain];
	}
	return self;
}

- (void)dealloc
{
	[data release];
	[super dealloc];
}

- (NSMutableData*)data
{
	return data;
}

- (void)appendData:(NSData*)moreData
{
	[data appendData:moreData];
}

/*
 * We're going to parse the data in this call as well. We may want to do this
 * someplace else later on.
 *
 * We're assuming that all of the data is completely transferred from TCP.
 */
- (NSString*)getBodyText
{
	NSUInteger dataLength = [data length];

	if (dataLength < 2) {
		warn("Data has to be at least 2 bytes long");
		return nil;
	}

	/* Check the first byte to ensure that the complete message is in this
	 * frame. Also that it's just text */
	const char *bytes = (const char*)[data bytes];
	if ((bytes[0] & WS_FRAME_FIN) == 0) {
		warn("Not handling fragmented messages yet");
		return nil;
	}
	if ((bytes[0] & WS_FRAME_OP_TEXT) == 0){
		warn("Only handling text messages right now");
		return nil;
	}

	/* Check the second byte to make sure it isn't masked */
	if (bytes[1] & WS_FRAME_MASK) {
		warn("Not handling masked messages yet");
		return nil;
	}

	/* Check the second byte for the length. Ensure that it's <= 125 */
	NSUInteger bodyLength = ~WS_FRAME_MASK & bytes[1];

	/* Check that the data length matches */
	if (dataLength != bodyLength + 2) { 	/* 2 chars for first 2 bytes in frame */
		warn("Data length mismatch");
		return nil;
	}

	/* Create an NSString from the body text */
	NSString *result = [NSString stringWithCString:(bytes+2) length:bodyLength];
	return result;
}
@end


/*
 * NOTE: We should add these to the WSFrame class
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
