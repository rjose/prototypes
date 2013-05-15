#include <stdio.h>

void main()
{
	char *test1 = "k 3";
	char command;
	int slot;

	sscanf(test1, "%c", &command);
	sscanf(test1, "k %d", &slot);

	printf("Slot: %d\n", slot);
}
