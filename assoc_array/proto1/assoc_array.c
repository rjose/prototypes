#include <stdlib.h>

#include "assoc_array.h"

void aa_init(AssocArray *array)
{
        array->num_elements = 0;
        array->elements = NULL;
}

