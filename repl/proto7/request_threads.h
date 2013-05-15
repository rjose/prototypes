/*
 * Simulated requests
 */
int simulate_http_request();
int simulate_websocket_request();

// Returns old slot if successful; -1 otherwise.
int kill_thread(int slot);

int get_num_active_requests();
