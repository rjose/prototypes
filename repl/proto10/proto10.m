#import <Foundation/Foundation.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#import "repl.h"

void err_abort(int status, const char *message)
{
	fprintf(stderr, message);
	exit(status);
}

int main(int argc, char *argv[])
{
	// Set up autorelease pool for Objective-C memory management
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// Generic to work with pthread functions
	void *thread_result;
	int status;

	// Create REPL thread
	pthread_t repl_thread_id;
	// TODO: Rename repl_routine to repl_thread
	status = pthread_create(&repl_thread_id, NULL, repl_routine, NULL);
	if (status != 0)
		err_abort(status, "Create thread");

	// Join REPL thread
	status = pthread_join(repl_thread_id, &thread_result);
	if (status != 0)
		err_abort(status, "Join thread");

	// Free the pool
	[pool release];

	printf("We are most successfully done!\n");
	return 0;
}
