#import "HttpResponse.h"

@implementation HttpResponse
// 	NSUInteger statusCode;
// 	NSString *reason;
// 	NSMutableDictionary *headers;

- (id)initWithStatus:(NSUInteger)status andReason:(NSString*)aReason
{
	self = [super init];
	if (self) {
		statusCode = status;
		reason = aReason;
		headers = [NSMutableDictionary dictionaryWithCapacity:8];

		[reason retain];
		[headers retain];
	}
	return self;
}

- (void)dealloc
{
	[reason release];
	[headers release];
	[super dealloc];
}

- (void) addHeader:(NSString*)field withValue:(NSString*)value
{
	[headers setObject:value forKey:[field lowercaseString]];
}

- (NSString*) getHeaderForField:(NSString*)field
{
	NSString *result = (NSString*)[headers objectForKey:[field lowercaseString]];
	return result;
}

@end
