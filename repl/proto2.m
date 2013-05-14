#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}

void *repl_routine(void *arg)
{
	char line_buffer[80];
	char command;
	int status;
	int quit = 0;

	while (!quit) {
		// Prompt
		printf("> ");

		// Read input
		if (fgets(line_buffer, sizeof(line_buffer), stdin) == NULL) {
			printf("EOF\n");
			fprintf(stderr, "Got an EOF. Shutting down...\n");
			break;
		}
		if (status = sscanf(line_buffer, "%c", &command) < 1) {
			// If run into trouble, try again
			fprintf(stderr, "Trouble scanning line. status: %d\n", status);
			continue;
		}

		// Do something with input
		switch(command) {
			case 's':
				printf("TODO: Implement status\n");
				break;

			case 'q':
				printf("Goodbye\n");
				quit = 1;
				break;

			default:
				fprintf(stderr, "Unknown command: %c\n", command);
				break;
		}
	}

	// TODO: Clean up all threads
	return NULL;
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
