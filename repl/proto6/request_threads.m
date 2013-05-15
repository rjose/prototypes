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
	/* Most of the function is a critical region */
	pthread_mutex_lock(&mutex);

	int status;
	int result = 0;
	int slot = get_free_slot();
	if (slot < 0) {
		result = -1;
		goto exit;
	}
	result = slot;

	request_thread_t *new_thread = calloc(1, sizeof(request_thread_t));
	if (new_thread == NULL) {
		fprintf(stderr, "Problem allocating memory\n");
		result = -1;
		goto exit;
	}
	status = pthread_create(&new_thread->thread_id, NULL, simulated_http_handler, NULL);
	if (status != 0) {
		fprintf(stderr, "Problem creating new_thread\n");
		free(new_thread);
		result = -1;
		goto exit;
	}

	/* Everything good, so store the request thread */
	store_thread(slot, new_thread);

exit:
	/* Mutex is locked upfront, so need to unlock it before exit */
	pthread_mutex_unlock(&mutex);
	return result;
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

// TODO: Refactor to pull common pieces out of simulate_websocket_request and
// simulate_http_request
int simulate_websocket_request()
{
	/* Most of the function is a critical region */
	pthread_mutex_lock(&mutex);

	int status;
	int result = 0;
	int slot = get_free_slot();
	if (slot < 0) {
		result = -1;
		goto exit;
	}
	result = slot;

	request_thread_t *new_thread = calloc(1, sizeof(request_thread_t));
	if (new_thread == NULL) {
		fprintf(stderr, "Problem allocating memory\n");
		result = -1;
		goto exit;
	}
	// This line is the only one that needs to be parameterized
	status = pthread_create(&new_thread->thread_id, NULL, simulated_websocket_handler, NULL);
	if (status != 0) {
		fprintf(stderr, "Problem creating new_thread\n");
		free(new_thread);
		result = -1;
		goto exit;
	}

	/* Everything good, so store the request thread */
	store_thread(slot, new_thread);

exit:
	/* Mutex is locked upfront, so need to unlock it before exit */
	pthread_mutex_unlock(&mutex);
	return result;
}

/**
 * Kills thread at slot and then nulls out the slot. Returns 0 on success; -1
 * otherwise.
 */
int kill_thread(int slot)
{
	// TODO: Refactor to pull this out into its own function
	if (slot < 0 || slot >= get_num_thread_slots()) {
		fprintf(stderr, "Slot out of range: %d\n", slot);
		return;
	}

	/* Critical region */
	pthread_mutex_lock(&mutex);
	request_thread_t *request_thread = g_request_threads[slot];
	g_request_threads[slot] = NULL;
	pthread_mutex_unlock(&mutex);

	if (request_thread == NULL) {
		return -1;
	}

	/* Detach so we don't have to wait for the thread to finish */
	if (pthread_detach(request_thread->thread_id) != 0) {
		fprintf(stderr, "Problem detaching thread at slot: %d\n", slot);
		return -1;
	}

	if (pthread_cancel(request_thread->thread_id) != 0) {
		fprintf(stderr, "Problem canceling thread at slot: %d\n", slot);
		return -1;
	}

	return slot;
}

/******************************************************************************
 * These functions are for managing the thread slots.
 */

int get_num_active_requests()
{
	int result = 0;
	int num_slots = get_num_thread_slots();

	for (int i=0; i < num_slots; i++) {
		if (g_request_threads[i] != NULL)
			result++;
	}
	return result;
}

static int get_num_thread_slots()
{
	return sizeof(g_request_threads)/sizeof(g_request_threads[0]);
}

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

// Stores a thread in one of our slots
static void store_thread(int slot, request_thread_t *request)
{
	if (slot < 0 || slot >= get_num_thread_slots()) {
		fprintf(stderr, "Slot out of range: %d\n", slot);
		return;
	}
	g_request_threads[slot] = request;
}

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

