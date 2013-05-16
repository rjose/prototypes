#import <Foundation/Foundation.h>
#include <pthread.h>

@interface RequestThread : NSObject
{
@private
	pthread_t thread_id;
	NSNumber* key;
}

+ (void) initialize;
+ (int) getNumActiveRequests;
+ (int) simulateHttpRequest;
+ (int) simulateWebsocketRequest;

// Returns old key if successful; -1 otherwise.
+ (int) killThread:(int) key;

- (id) initWithKey:(NSNumber*) aKey;
- (NSNumber*) key;
- (pthread_t*) pthread_id;
@end
