#import <Foundation/Foundation.h>

@interface WSFrame : NSObject
{
@private
	NSMutableData *data;
}

- (void)appendData:(NSData*)moreData;
- (BOOL)isMasked;
- (long)messageLength;
- (NSString*)message;

@end
