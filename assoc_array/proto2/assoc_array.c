#include <string.h>
#include <stdlib.h>

#include "assoc_array.h"

int aa_init(AssocArray *array, int capacity, 
                                int (*compare)(const void *k1, const void *k2))
{
        array->compare = compare;
        array->capacity = capacity;
        array->num_elements = 0;

        if ((array->elements =
             (AssocArrayElem *)malloc(sizeof(AssocArrayElem)*capacity)) == NULL)
                return -1;

        return 0;
}

void aa_free(AssocArray *array)
{
        // TODO: If destroy isn't NULL, destroy each elem, too
        free(array->elements);
        memset(array, 0, sizeof(AssocArray));
}

int aa_set_element(AssocArray *array, const AssocArrayElem *elem)
{
        AssocArrayElem *e;
        int i;

        for (i=0; i < array->num_elements; i++) {
                e = array->elements + i;
                if (array->compare(e->key.vval, elem->key.vval) == 0) {
                        *e = *elem;
                        return 0;
                }
        }

        /*
         * If couldn't find element, add a new one
         */
        array->elements[array->num_elements] = *elem;
        array->num_elements++;

        // TODO: Handle realloc
        return 0;
}


AssocArrayElem *aa_get_element(AssocArray *array, void *key)
{
        AssocArrayElem *e;
        int i;

        for (i=0; i < array->num_elements; i++) {
                e = array->elements + i;
                if (array->compare(e->key.vval, key) == 0) {
                        return e;
                }
        }

        return NULL;
}
