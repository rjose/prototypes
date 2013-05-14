#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

void *repl_routine(void *arg)
{
	printf("Started REPL!\n");
	return arg;
}

void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}

int main(int argc, char *argv[])
{
	// Generic to work with pthread functions
	void *thread_result;
	int status;

	// Create REPL thread
	pthread_t repl_thread_id;
	status = pthread_create(&repl_thread_id, NULL, repl_routine, NULL);
	if (status != 0)
		err_abort(status, "Create thread");

	// Join REPL thread
	status = pthread_join(repl_thread_id, &thread_result);
	if (status != 0)
		err_abort(status, "Join thread");

	printf("We are most successfully done!\n");
	return 0;
}
