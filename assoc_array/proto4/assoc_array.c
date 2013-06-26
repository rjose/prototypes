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
        int i;
        if (array->destroy) {
                for (i = 0; i < array->num_elements; i++)
                        array->destroy(array->elements + i);
        }

        free(array->elements);
        memset(array, 0, sizeof(AssocArray));
}

int aa_set_element(AssocArray *array, const AssocArrayElem *elem)
{
        AssocArrayElem *e;
        AssocArrayElem *tmp;
        int i;

        for (i=0; i < array->num_elements; i++) {
                e = array->elements + i;
                if (array->compare(e, elem) == 0) {
                        // TODO: Think about who should free previous
                        // element's memory
                        *e = *elem;
                        return 0;
                }
        }

        /*
         * If couldn't find element, add a new one
         */
        array->elements[array->num_elements] = *elem;
        array->num_elements++;

        if (array->num_elements == array->capacity) {
                array->capacity *= 2;
                tmp = (AssocArrayElem*)realloc(array->elements,
                                      sizeof(AssocArrayElem) * array->capacity);
                if (tmp == NULL) {
                        // TODO: Log something
                        return -1;
                }
                array->elements = tmp;
                return 1;
        }

        return 0;
}


AssocArrayElem *aa_get_element(const AssocArray *array, void *key)
{
        AssocArrayElem *e;
        AssocArrayElem tmp;
        tmp.key.vval = key;
        int i;

        for (i=0; i < array->num_elements; i++) {
                e = array->elements + i;
                if (array->compare(e, &tmp) == 0) {
                        return e;
                }
        }

        return NULL;
}

void aa_sort_keys(AssocArray *array)
{
        qsort(array->elements, array->num_elements, sizeof(AssocArrayElem),
                                                                array->compare);
}

int aa_reduce(AssocArray *result, const AssocArray **assoc_arrays, size_t n,
           int (*f)(AssocArray *result, const AssocArray *other, void *context),
                                                                 void *context)
{
        int i;
        for (i = 0; i < n; i++) {
                if (f(result, assoc_arrays[i], context) != 0)
                        return -1;
        }
        return 0;
}

int aa_string_compare(const void *k1, const void *k2)
{
        AssocArrayElem *key1 = (AssocArrayElem *)k1;
        AssocArrayElem *key2 = (AssocArrayElem *)k2;

        return strcmp(key1->key.sval, key2->key.sval);
}


/*
 * Iterate over elements in "other" and look them up in "result".
 *
 * If the element is there, we update the dval by summing.
 *
 * If the element isn't there, we set the value to what's in other.
 */
int aa_vector_sum(AssocArray *result, const AssocArray *other, void *context)
{
        int i;
        double scale;
        AssocArrayElem *result_elem, *other_elem;
        ReduceContext *ctx = (ReduceContext *)context;

        /* Figure out scale factor */
        scale = 1.0;
        if (ctx != NULL)
                scale = ctx->scale;

        for (i = 0; i < other->num_elements; i++) {
                other_elem = aa_element(other, i);
                result_elem = aa_get_element(result, other_elem->key.vval);

                if (result_elem != NULL) {
                        result_elem->val.dval += scale * other_elem->val.dval;
                }
                else {
                        aa_set_element(result, other_elem);
                        result_elem = aa_get_element(result, other_elem->key.vval);
                        result_elem->val.dval *= scale;
                }
        }

        return 0;
}


/*
 * Iterate over elements in "other" and look them up in "result".
 *
 * If the element is there, we update the dval by summing.
 *
 * If the element isn't there, we set the value to what's in other.
 */
int aa_running_vector_sum(AssocArray *result, const AssocArray *other, 
                                                                  void *context)
{
        int i, j;
        AssocArrayElem *result_elem, *other_elem;
        ReduceContext *ctx;
        double *double_array;
        int cur_index;
        double other_val;
        double scale;
       
        ctx = (ReduceContext *)context;
        cur_index = ctx->cur_index;

        /* Figure out scale factor */
        scale = 1.0;
        if (ctx)
                scale = ctx->scale;

        /*
         * Ensure all keys in other are in result
         */
        for (i = 0; i < other->num_elements; i++) {
                other_elem = aa_element(other, i);
                result_elem = aa_get_element(result, other_elem->key.vval);

                /* Create double array if needed */
                if (result_elem == NULL) {
                        /* Create new element in array */
                        aa_set_element(result, other_elem);
                        result_elem = aa_get_element(result, other_elem->key.vval);

                        /* Allocate space to store values */
                        double_array =
                           (double *)malloc(ctx->num_items * sizeof(double));
                        if (double_array == NULL) {
                                // TODO: Log something
                                return -1;
                        }
                        for (j = 0; j < ctx->num_items; j++)
                                double_array[j] = 0.0;

                        /* Set value in new element */
                        result_elem->val.vval = (void *)double_array;
                }
        }

        /*
         * Compute running total
         */
        for (i = 0; i < result->num_elements; i++) {
                result_elem = aa_element(result, i);
                other_elem = aa_get_element(other, result_elem->key.vval);

                double_array = (double *)result_elem->val.vval;

                /* Figure out what the other value should be */
                other_val = 0.0;
                if (other_elem != NULL)
                        other_val = scale * other_elem->val.dval;

                /*
                 * If first element, start with current value. Otherwise sum
                 * with previous value.
                 */
                if (cur_index == 0)
                        double_array[cur_index] = other_val;
                else
                        double_array[cur_index] = double_array[cur_index - 1] +
                                                                      other_val;
        }

        /* Done with this item */
        ctx->cur_index++;

        return 0;
}

