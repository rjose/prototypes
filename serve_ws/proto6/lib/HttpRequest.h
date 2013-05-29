#import <Foundation/Foundation.h>

@interface HttpRequest : NSObject
{
@private
	NSString *method;
	NSString *uri;

	NSMutableDictionary *headers;
}

- (id) initWithMethod: (NSString*)method andUri: (NSString*)uri;
- (void) addHeader: (NSString*)field withValue: (NSString*)value;
- (NSString*) getHeader: (NSString*)field;

@end
