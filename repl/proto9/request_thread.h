#import <Foundation/Foundation.h>
#include <pthread.h>

@interface RequestThread : NSObject
{
@private
	pthread_t thread_id;
	NSNumber* key;
}

+ (void) initialize;

- (id) initWithKey:(NSNumber*) aKey;
- (NSNumber*) key;
- (pthread_t*) pthread_id;
@end



/*
 * Simulated requests
 */
// TODO: Make these class functions of request thread
int simulate_http_request();
int simulate_websocket_request();

// Returns old key if successful; -1 otherwise.
int kill_thread(int key);

int get_num_active_requests();
