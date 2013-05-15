#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#import "request_threads.h"

static NSMutableDictionary *g_threads = nil;

@implementation RequestThread

+ (void) initialize
{
	if (g_threads == nil) {
		g_threads = [[NSMutableDictionary alloc] init];
	}
}

- (pthread_t*) pthread_id
{
	return &thread_id;
}
@end

/**
  * Just something to hold a request thread ID. We'll convert this to an
  * Objective-C class in an upcoming prototype
 */
typedef struct request_thread_tag {
	pthread_t thread_id;
} request_thread_t;



// Use this to refactor functions that set up request threads
typedef void *simulated_handler_t(void *arg);

/**
 * This stores all active request threads.
 */
static request_thread_t *g_request_threads[3];
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

/**
 * Module functions for keeping track of our request threads. These are
 * low-level functions that assume the mutex is held before they are called.
 */
static int get_free_slot();
static void store_thread(int slot, request_thread_t *request);
static int get_thread_slot(pthread_t* thread);
static request_thread_t *remove_thread(int slot);
static int get_num_thread_slots();
static int simulate_request(simulated_handler_t handler);
static int is_slot_invalid(int slot);


/**
 * When a thread completes or is canceled, it needs to remove itself from
 * *g_request_threads*.
 *
 * Needs to hold the mutex.
 */
static void cleanup_request_thread(void *arg)
{
	pthread_t self_id = pthread_self();

	/* Critical region */
	pthread_mutex_lock(&mutex);
	int slot = get_thread_slot(&self_id);
	request_thread_t *my_request = remove_thread(slot);
	pthread_mutex_unlock(&mutex);

	if (my_request == NULL) {
		fprintf(stderr, "Error removing request thread\n");
		exit(1);
	}

	free(my_request);
}

/**
 * Simulates the behavior of an HTTP request from a timing perspective. We just
 * want something that works for a while and then completes for the purposes of
 * testing thread management.
 */
static void *simulated_http_handler(void *arg)
{
	pthread_cleanup_push(cleanup_request_thread, NULL);
	printf("Starting request\n");
	sleep(5);
	printf("Finishing request\n");
	pthread_cleanup_pop(1);
	return NULL;
}

/**
 * This just spins up a thread to simulate the handling of an HTTP request. The
 * thread sleeps for a while and then returns. Each thread takes up a slot in
 * *g_request_threads*
 *
 * If thread was created, returns the slot; otherwise, returns -1.
 *
 * Needs to hold the mutex.
 */
int simulate_http_request()
{
	return simulate_request(simulated_http_handler);
}

static void *simulated_websocket_handler(void *arg)
{
	pthread_cleanup_push(cleanup_request_thread, NULL);
	printf("Starting connection\n");
	while(1) {
		// Pretend that we're having a conversation
		sleep(1);

		// See if we need to be canceled
		pthread_testcancel();
	}

	// I don't think we ever get here. I should verify this.
	fprintf(stderr, "We shouldn't get here\n");
	pthread_cleanup_pop(1);
	return NULL;
}


static int simulate_request(simulated_handler_t handler)
{
	/* Most of the function is a critical region */
	pthread_mutex_lock(&mutex);

	/* Used as a key into the g_threads dictionary */
	static int next_thread_key = 0;

	int status;
	int result = next_thread_key;

	RequestThread *new_thread = [[RequestThread alloc] init];
	
	if (!new_thread) {
		fprintf(stderr, "Problem allocating memory\n");
		result = -1;
		goto exit;
	}



	// This line is the only one that needs to be parameterized
	status = pthread_create([new_thread pthread_id], NULL, handler, NULL);
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
	[g_threads setValue:new_thread forKey:[NSNumber numberWithInt:next_thread_key++]]; 

exit:
	/* Mutex is locked upfront, so need to unlock it before exit */
	pthread_mutex_unlock(&mutex);
	return result;
}

int simulate_websocket_request()
{
	return simulate_request(simulated_websocket_handler);
}

int kill_thread(int key)
{
	/* Critical region */
	pthread_mutex_lock(&mutex);
	RequestThread *request_thread = [g_threads valueForKey:[NSNumber numberWithInt:key]];
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

/******************************************************************************
 * These functions are for managing the thread slots.
 */

int get_num_active_requests()
{
	return (int) ([g_threads count]);
}
