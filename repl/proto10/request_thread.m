#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#import "request_thread.h"

/* Module-level dictionary for keeping track of active request threads */
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
static NSMutableDictionary *g_threads = nil;

/*
 * Module functions for keeping track of our request threads. These are
 * low-level functions that assume the mutex is held before they are called.
 */
typedef void *simulated_handler_t(void *arg);
static int simulate_request(simulated_handler_t handler);
static void *simulated_http_handler(void *new_thread);
static void *simulated_websocket_handler(void *new_thread);
static void cleanup_request_thread(void *new_thread);

/*******************************************************************************
 ** RequestThread Implementation
 **/
@implementation RequestThread

+ (void) allocateStaticVariables
{
	if (g_threads == nil) {
		g_threads = [[NSMutableDictionary alloc] init];
	}
}

+ (int) getNumActiveRequests
{
	if (!g_threads)
		return 0;

	return (int) ([g_threads count]);
}


/**
 * This just spins up a thread to simulate the handling of an HTTP request. The
 * thread sleeps for a while and then returns. Each thread takes up a slot in
 * *g_request_threads*
 *
 * If thread was created, returns the slot; otherwise, returns -1.
 *
 */
+ (int) simulateHttpRequest
{
	return simulate_request(simulated_http_handler);
}

+ (int) simulateWebsocketRequest
{
	return simulate_request(simulated_websocket_handler);
}


+ (int) killThread:(int) key
{
	/* Critical region */
	pthread_mutex_lock(&mutex);
	RequestThread *request_thread = [g_threads objectForKey:[NSNumber numberWithInt:key]];
	pthread_mutex_unlock(&mutex);

	if (!request_thread) {
		return -1;
	}

	/* Detach so we don't have to wait for the thread to finish */
	if (pthread_detach(*[request_thread pthread_id]) != 0) {
		fprintf(stderr, "Problem detaching thread at key: %d\n", key);
		return -1;
	}

	if (pthread_cancel(*[request_thread pthread_id]) != 0) {
		fprintf(stderr, "Problem canceling thread at key: %d\n", key);
		return -1;
	}

	return key;
}

+ (void) releaseStaticVariables
{
	[g_threads release];
}

- (id) initWithKey:(NSNumber*) aKey
{
	self = [super init];
	if (self) {
		self->key = aKey;
	}
	return self;
}

- (NSNumber*) key
{
	return key;
}

- (pthread_t*) pthread_id
{
	return &thread_id;
}
@end


/*******************************************************************************
 ** Internal methods
 **/

/**
 * When a thread completes or is canceled, it needs to remove itself from
 * *g_request_threads*. The *new_thread* argument is the RequestThread that
 * will be cleaning up when it's done.
 *
 * Needs to hold the mutex.
 */
static void cleanup_request_thread(void *new_thread)
{
	RequestThread *request_thread = (RequestThread*) new_thread;

	/* Critical region */
	pthread_mutex_lock(&mutex);
	[g_threads removeObjectForKey:[request_thread key]];
	pthread_mutex_unlock(&mutex);
}

/**
 * Simulates the behavior of an HTTP request from a timing perspective. We just
 * want something that works for a while and then completes for the purposes of
 * testing thread management. The *new_thread* argument is the newly created
 * RequestThread. We pass this to the cleanup handler so it can remove the
 * RequestThread when we're done.
 */
static void *simulated_http_handler(void *new_thread)
{
	pthread_cleanup_push(cleanup_request_thread, new_thread);
	printf("Starting request\n");
	sleep(5);
	printf("Finishing request\n");
	pthread_cleanup_pop(1);
	return NULL;
}


/**
 * This spins up a thread that pretends to have a long-lived websocket
 * connection.
 */
static void *simulated_websocket_handler(void *new_thread)
{
	pthread_cleanup_push(cleanup_request_thread, new_thread);
	printf("Starting connection\n");
	while(1) {
		// Pretend that we're having a conversation
		sleep(1);

		// See if we need to be canceled
		pthread_testcancel();
	}

	// We should never get here.
	fprintf(stderr, "We shouldn't get here\n");
	pthread_cleanup_pop(1);
	return NULL;
}


/**
 * This is used to simulate http and websocket requests. It creates the
 * threads and stores the thread ID in a RequestThread which is then stored in
 * g_threads to keep track of which requests are active.
 */
static int simulate_request(simulated_handler_t handler)
{
	/* Most of the function is a critical region */
	pthread_mutex_lock(&mutex);

	/* Used as a key into the g_threads dictionary */
	static int next_thread_key = 0;

	int status;
	int result = next_thread_key;

	RequestThread *new_thread = [[RequestThread alloc]
		initWithKey:[NSNumber numberWithInt:next_thread_key++]];
	
	if (!new_thread) {
		fprintf(stderr, "Problem allocating memory\n");
		result = -1;
		goto exit;
	}
	
	// This line is the only one that needs to be parameterized
	status = pthread_create([new_thread pthread_id], NULL, handler, new_thread);
	if (status != 0) {
		fprintf(stderr, "Problem creating new_thread\n");
		[new_thread release];
		result = -1;
		goto exit;
	}

	if (!g_threads) {
		fprintf(stderr, "g_threads was not initialized!\n");
		result = -1;
		goto exit;
	}

	/* Everything good, so store the request thread */
	[g_threads setObject:new_thread forKey:[new_thread key]]; 
	[new_thread release]; /* g_threads owns it now, so can release */

exit:
	/* Mutex is locked upfront, so need to unlock it before exit */
	pthread_mutex_unlock(&mutex);
	return result;
}
