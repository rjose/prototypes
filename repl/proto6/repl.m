#include <stdio.h>
#include <pthread.h>
#import "request_threads.h"

static void handle_command(char command);

void *repl_routine(void *arg)
{
	char line_buffer[80];
	char command;
	int status;
	int quit = 0;
	int slot;

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

		// Eval
		handle_command(command);

	}

	// TODO: Clean up all threads
	return NULL;
}

/**
 * Returns 1 if should quit; 0 otherwise.
 */
static void handle_command(char command)
{
	// Do something with input
	switch(command) {
		// Status
		case 's':
			printf("Num active requests: %d\n", get_num_active_requests());
			break;

		// Simulate http request
		case 'r':
			printf("Simulate handling of HTTP request\n");
			if (simulate_http_request() < 0) {
				fprintf(stderr, "Too many request threads\n");
			}
			break;

		// Simulate websocket request
		case 'w':
			printf("Simulate handling of websocket request\n");
			if ( (slot = simulate_websocket_request() ) < 0) {
				fprintf(stderr, "Too many request threads\n");
			}
			printf("Websocket connection started at: %d\n", slot);
			break;

		// Kill a request thread
	       case 'k':
			if (status = sscanf(line_buffer, "k %d", &slot) < 1) {
				fprintf(stderr, "k <integer>\n");
				return 0;
			}
			if (kill_thread(slot) < 0) {
				fprintf(stderr, "Problem killing thread at slot %d\n",
						slot);
			}
			break;

		// Quit program
		case 'q':
			printf("Goodbye\n");
			return 1;

		default:
			fprintf(stderr, "Unknown command: %c\n", command);
			break;
	}

	return 0;
}
