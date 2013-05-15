#include <pthread.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct request_thread_tag {
	pthread_t thread_id;
} request_thread_t;

// TODO: Guard this with a mutex
static request_thread_t *g_request_threads[3];

static int get_num_thread_slots()
{
	return sizeof(g_request_threads)/sizeof(g_request_threads[0]);
}

// Returns index of next available slot; -1 if there isn't one
int get_free_slot()
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
int get_thread_slot(pthread_t* thread)
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

void store_thread(int slot, request_thread_t *request)
{
	if (slot < 0 || slot >= get_num_thread_slots()) {
		fprintf(stderr, "Slot out of range: %d\n", slot);
		return;
	}
	g_request_threads[slot] = request;
}

// Returns thread at slot and nulls out slot. If error, returns NULL.
request_thread_t *remove_thread(int slot)
{
	if (slot < 0 || slot >= get_num_thread_slots()) {
		fprintf(stderr, "Slot out of range: %d\n", slot);
		return NULL;
	}
	request_thread_t *result = g_request_threads[slot];
	g_request_threads[slot] = NULL;

	return result;
}

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

static void *simluated_http_handler(void *arg)
{
	pthread_cleanup_push(cleanup_request_thread, NULL);
	printf("Starting request\n");
	sleep(5);
	printf("Finishing request\n");
	pthread_cleanup_pop(1);
	return NULL;
}


request_thread_t *simulate_http_request()
{
	int status;
	// TODO: Lock mutex here
	int slot = get_free_slot();
	if (slot < 0)
		return NULL;

	request_thread_t *new_thread = calloc(1, sizeof(request_thread_t));
	if (new_thread == NULL) {
		fprintf(stderr, "Problem allocating memory\n");
		return NULL;
	}
	status = pthread_create(&new_thread->thread_id, NULL, simluated_http_handler, NULL);
	if (status != 0) {
		fprintf(stderr, "Problem creating new_thread\n");
		free(new_thread);
		return NULL;
	}

	store_thread(slot, new_thread);
	// TODO: Unlock mutex

	return new_thread;
}

