#import <Foundation/Foundation.h>

@interface WSFrame : NSObject
{
@private
	NSMutableData *data;
}

- (void)appendData:(NSData*)moreData;
- (BOOL)isMasked;
- (BOOL)isCloseFrame;
- (long)messageLength;
- (NSString*)message;

@end
