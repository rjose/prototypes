#include <pthread.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

/**
  * Just something to hold a request thread ID. We'll convert this to an
  * Objective-C class in an upcoming prototype
 */
typedef struct request_thread_tag {
	pthread_t thread_id;
} request_thread_t;

// TODO: Guard this with a mutex
/**
 * This stores all active request threads.
 */
static request_thread_t *g_request_threads[3];

/**
 * Module functions for keeping track of our request threads.
 */
static int get_free_slot();
static void store_thread(int slot, request_thread_t *request);
static int get_thread_slot(pthread_t* thread);
static request_thread_t *remove_thread(int slot);


/**
 * When a thread completes or is canceled, it needs to remove itself from
 * *g_request_threads*.
 */
static void cleanup_request_thread(void *arg)
{
	// TODO: Need to lock the mutex here
	pthread_t self_id = pthread_self();
	int slot = get_thread_slot(&self_id);
	request_thread_t *my_request = remove_thread(slot);
	if (my_request == NULL) {
		fprintf(stderr, "Error removing request thread\n");
		exit(1);
	}
	// TODO: Unlock mutex

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
 * If thread was created, returns 0; otherwise, returns -1.
 */
int simulate_http_request()
{
	int status;
	// TODO: Lock mutex here
	int slot = get_free_slot();
	if (slot < 0)
		return -1;

	request_thread_t *new_thread = calloc(1, sizeof(request_thread_t));
	if (new_thread == NULL) {
		fprintf(stderr, "Problem allocating memory\n");
		return -1;
	}
	status = pthread_create(&new_thread->thread_id, NULL, simulated_http_handler, NULL);
	if (status != 0) {
		fprintf(stderr, "Problem creating new_thread\n");
		free(new_thread);
		return -1;
	}

	store_thread(slot, new_thread);
	// TODO: Unlock mutex

	return 0;
}


static int get_num_thread_slots()
{
	return sizeof(g_request_threads)/sizeof(g_request_threads[0]);
}

// TODO: Need mutex
// Returns index of next available slot; -1 if there isn't one
static int get_free_slot()
{
	int num_slots = get_num_thread_slots();

	for (int i=0; i < num_slots; i++) {
		if (g_request_threads[i] == NULL) {
			return i;
		}
	}
	return -1;
}

// TODO: Need mutex
// Returns index where thread was stored; -1 if couldn't be found.
static int get_thread_slot(pthread_t* thread)
{
	int num_slots = get_num_thread_slots();

	for (int i=0; i < num_slots; i++) {
		if (g_request_threads[i] != NULL &&
		    pthread_equal(*thread, g_request_threads[i]->thread_id)) {
			return i;
		}
	}
	return -1;
}

// TODO: Need mutex
static void store_thread(int slot, request_thread_t *request)
{
	if (slot < 0 || slot >= get_num_thread_slots()) {
		fprintf(stderr, "Slot out of range: %d\n", slot);
		return;
	}
	g_request_threads[slot] = request;
}

// TODO: Need mutex
// Returns thread at slot and nulls out slot. If error, returns NULL.
static request_thread_t *remove_thread(int slot)
{
	if (slot < 0 || slot >= get_num_thread_slots()) {
		fprintf(stderr, "Slot out of range: %d\n", slot);
		return NULL;
	}
	request_thread_t *result = g_request_threads[slot];
	g_request_threads[slot] = NULL;

	return result;
}

