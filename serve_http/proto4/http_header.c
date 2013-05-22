#include <err.h>
#include <stdlib.h>
#include <string.h>

/**
 * Parses an HTTP header into a field and value. If anything goes wrong,
 * returns -1; otherwise returns 0.
 *
 * The field and value will need to be freed by the caller.
 */
#define MAX_FIELD_LEN 40
#define MAX_VALUE_LEN 1000
int
parse_header(const char *line, char **field, char **value)
{
	char *my_field = malloc(MAX_FIELD_LEN);
	char *my_value = malloc(MAX_VALUE_LEN);

	/* Look for header field name */
	int index = 0;
	int found_colon = 0;
	while (index < MAX_FIELD_LEN) {
		if (line[index] == ':') {
			found_colon = 1;
			my_field[index] = '\0';
			break;
		}
		my_field[index] = line[index];
		index++;
	}
	if (!found_colon) {
		warnx("Couldn't find ':' for header: %s", line);
		return -1;
	}

	/* Advance index to first non-blank. Assuming only spaces are
	 * whitespace */
	while (line[index++] == ' ') { }
	index--; 	/* Back up to first non-blank */

	/* Copy value over */
	strncpy(my_value, line+index, MAX_VALUE_LEN);

	/* Return results */
	*field = my_field;
	*value = my_value;
	return 0;
}
