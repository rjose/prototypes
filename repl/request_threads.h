/*
 * Request thread management
 */

int get_free_slot();
void store_thread(int slot, request_thread_t *request);
int get_thread_slot(pthread_t* thread);
request_thread_t *remove_thread(int slot);

/*
 * Simulated requests
 */
request_thread_t *simulate_http_request();

