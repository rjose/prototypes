#include <err.h>
#include <stdlib.h>
#include <string.h>

#import "WSFrame.h"

/* Byte 0 of websocket frame */
#define WS_FRAME_FIN 0x80
#define WS_FRAME_OP_TEXT 0x01

/* Byte 1 of websocket frame */
#define WS_FRAME_MASK 0x80

#define SHORT_MESSAGE_LEN 125

/*
 * Static declarations
 */
static char toggle_byte_mask(const char *, int, const char*);


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

- (void)appendData:(NSData*)moreData
{
	[data appendData:moreData];
}

- (BOOL)isMasked
{
        const char *frame = [data bytes];

        /* The mask bit is in the second byte of the frame */
        if (frame[1] & WS_FRAME_MASK)
                return YES;
        else
                return NO;
}

- (BOOL)isCloseFrame
{
	// TODO: Implement this
	return NO;
}


- (long)messageLength
{
        const char *frame = [data bytes];

        /* The length is in the second byte (if the length < 125) */
        char result = frame[1] & ~WS_FRAME_MASK;

        if (result > 125)
                errx(1, "Can't handle messages > 125");

        return result;
}

- (NSString*)message
{
        const char *frame = [data bytes];
        long len = [self messageLength];

        if (len > 125)
                errx(1, "Not handling messages longer than 125 bytes");

        /* For a message of length < 125, the mask starts at Byte 2 and the
         * message starts at Byte 6 */
        const char *mask_start;
        const char *message_start;
        mask_start = frame + 2;
        message_start = frame + 6;

        /* Allocate memory to write unmasked string into */
        char *buf = malloc(len+1);
        if (buf == NULL) {
                warn("Unable to allocate memory");
                return nil;
        }

        /* Unmask memory byte-by-byte */
        int i;
        for (i=0; i < len; i++)
                buf[i] = toggle_byte_mask(message_start, i, mask_start);
        buf[len] = '\0';

        /* Construct result and clean up */
        NSString *result = [NSString stringWithCString:buf];
        free(buf);

        return result;
}


@end

static char
toggle_byte_mask(const char *message, int byteIndex, const char *mask)
{
        char mask_byte = mask[byteIndex % 4];
        char result = message[byteIndex] ^ mask_byte;

        return result;
}
