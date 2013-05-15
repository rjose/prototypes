// TODO: Rename this file to request_thread.h
#import <Foundation/Foundation.h>
#include <pthread.h>

@interface RequestThread : NSObject
{
@public
	pthread_t thread_id;
	// TODO: Make this into an NSNumber and then add an accessor
	int key;
}

+ (void) initialize;

- (id) initWithKey:(int) aKey;
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
