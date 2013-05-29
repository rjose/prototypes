#import "HttpRequest.h"

@implementation HttpRequest

- (id)initWithMethod: (NSString*)aMethod andUri: (NSString*) aUri
{
	self = [super init];
	if (self) {
		method = aMethod;
		uri = aUri;
		headers = [NSMutableDictionary dictionaryWithCapacity:8];
		[headers retain];
	}
	return self;
}

- (void)dealloc
{
	[headers release];
	[super dealloc];
}


- (void)addHeader: (NSString*)field withValue:(NSString*)value
{
	[headers setObject:value forKey:[field lowercaseString]];
}

- (NSString*)getHeader: (NSString*)field
{
	NSString *result = (NSString*)[headers objectForKey:[field lowercaseString]];
	return result;
}

@end
