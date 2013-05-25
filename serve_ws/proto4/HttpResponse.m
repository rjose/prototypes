#include <err.h>
#include <openssl/sha.h>

#import <GNUstepBase/GSMime.h>

#import "HttpRequest.h"
#import "HttpResponse.h"

#define BUF_LENGTH 200
static char m_wsMagicString[] = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

static NSString *calculate_websocket_accept(NSString *);


@implementation HttpResponse

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

/*
 * This converts the response to a string suitable for sending as an HTTP
 * response over TCP.
 */
- (NSString*) toString
{
	// TODO: Implement
	return nil;
}

+ (HttpResponse *)getResponse:(HttpRequest *)request
{
	/* Check for Upgrade: websocket in request */
	NSString *upgradeHeader = [request getHeader:@"upgrade"];
	if ([upgradeHeader compare:@"websocket"] != NSOrderedSame) {
		warnx("Upgrade is '%s' not websocket", [upgradeHeader cString]);
		return nil;
	}

	NSString *websocketKey = [request getHeader:@"sec-websocket-key"];
	if (websocketKey == nil) {
		warnx("Expected a sec-websocket-key header");
		return nil;
	}

	NSString *websocketAccept = calculate_websocket_accept(websocketKey);
	if (websocketAccept == nil) {
		warnx("Problem calculating websocket accept");
		return nil;
	}

	HttpResponse *result = [[HttpResponse alloc] initWithStatus:101
							  andReason:@"Switching Protocols"];
	[result addHeader:@"Upgrade" withValue:@"websocket"];
	[result addHeader:@"Connection" withValue:@"Upgrade"];
	[result addHeader:@"Sec-WebSocket-Accept" withValue:websocketAccept];
	[result autorelease];
	
	return result;
}
@end


/*
 * NOTE: We should add these to the HttpResponse class
 */


/* 
 * The key comes from Sec-WebSocket-Accept.
 */
static NSString *
calculate_websocket_accept(NSString *key)
{
	char sha_digest[SHA_DIGEST_LENGTH];
	char buf[BUF_LENGTH];

	/* Concatenate the magic string and take the SHA1... */
	strncpy(buf, [key cString], BUF_LENGTH/2);
	strncat(buf, m_wsMagicString, BUF_LENGTH/2);
	SHA1((const unsigned char*)buf, strlen(buf), (unsigned char*)sha_digest);

	/* ...then base64 encode */
	NSData *data = [NSData dataWithBytes:sha_digest length:SHA_DIGEST_LENGTH];
	NSData *encodedData = [GSMimeDocument encodeBase64:data];
	[encodedData getBytes:(void*)buf length:BUF_LENGTH-1];
	buf[[encodedData length]] = '\0'; 	/* Terminate string */

	/* Return result */
	NSString *result = [NSString stringWithCString:buf];
	return result;
}

