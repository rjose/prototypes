#include <stdio.h>
#include <pthread.h>
#import "request_threads.h"

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

			case 'r':
				printf("Simulate handling of HTTP request\n");
				if (simulate_http_request() < 0) {
					fprintf(stderr, "Too many request threads\n");
				}
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

