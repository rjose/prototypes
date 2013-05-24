#import <Foundation/Foundation.h>

@interface HttpResponse : NSObject
{
@private
	NSUInteger statusCode;
	NSString *reason;
	NSMutableDictionary *headers;
}

- (id) initWithStatus:(NSUInteger)status andReason:(NSString*)reason;
- (void) addHeader:(NSString*)field withValue:(NSString*)value;
- (NSString*) getHeaderForField:(NSString*)field;
@end
