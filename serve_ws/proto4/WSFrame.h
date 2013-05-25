#import <Foundation/Foundation.h>

// TODO: Move this to WSFrame.m
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

@interface WSFrame : NSObject
{
@private
	NSMutableData *data;
}

- (NSMutableData*)data;
- (void)appendData:(NSData*)moreData;
- (NSString*)getBodyText;
- (BOOL)isCloseFrame;
@end

