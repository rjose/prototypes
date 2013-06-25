#include <string.h>
#include <err.h>

#import "Testing.h"

#include "../assoc_array.h"

#define NUM_ARRAYS 3
AssocArray m_arrays[NUM_ARRAYS];

// TODO: Move this to the assoc array file
typedef struct ReduceContext_ {
        int num_items;
        int cur_index;
        double scale;
} ReduceContext;

// TODO: Move this to the assoc array file
static int compare1(const void *k1, const void *k2)
{
        return strcmp((const char *)k1, (const char *)k2);
}

static void setup_arrays()
{
        AssocArrayElem elem;
        int i;
        for (i=0; i < NUM_ARRAYS; i++) {
                aa_init(&m_arrays[i], 5, compare1);
        }

        /* Set up m_arrays[0] */
        elem.key.sval = "Native";
        elem.val.dval = 10.0;
        aa_set_element(&m_arrays[0], &elem);

        elem.key.sval = "Apps";
        elem.val.dval = 5.0;
        aa_set_element(&m_arrays[0], &elem);

        /* Set up m_arrays[1] */
        elem.key.sval = "Native";
        elem.val.dval = 1.0;
        aa_set_element(&m_arrays[1], &elem);

        elem.key.sval = "Web";
        elem.val.dval = 2.0;
        aa_set_element(&m_arrays[1], &elem);

        /* Set up m_arrays[2] */
        elem.key.sval = "Apps";
        elem.val.dval = 1.0;
        aa_set_element(&m_arrays[2], &elem);

        elem.key.sval = "Web";
        elem.val.dval = 1.0;
        aa_set_element(&m_arrays[2], &elem);
}

static void free_arrays()
{
        int i;
        for (i=0; i < NUM_ARRAYS; i++) {
                aa_free(&m_arrays[i]);
        }
}

/*
 * Iterate over elements in "other" and look them up in "result".
 *
 * If the element is there, we update the dval by summing.
 *
 * If the element isn't there, we set the value to what's in other.
 */
static int vector_sum(AssocArray *result, const AssocArray *other, void *context)
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


static void test_aa_reduce()
{
        AssocArray result;
        AssocArray *arrays[NUM_ARRAYS];
        AssocArrayElem *elem;

        setup_arrays();

        START_SET("Test reduce");
        int i;

        /* Set up array pointers */
        for (i = 0; i < NUM_ARRAYS; i++)
                arrays[i] = &m_arrays[i];

        aa_init(&result, 5, compare1);
        aa_reduce(&result, (const AssocArray **)arrays, NUM_ARRAYS, vector_sum, NULL);

        /* Check result array */
        elem = aa_get_element(&result, "Native");
        pass(EQ(11, elem->val.dval), "Native sum should be correct");

        elem = aa_get_element(&result, "Apps");
        pass(EQ(6, elem->val.dval), "Apps sum should be correct");

        elem = aa_get_element(&result, "Web");
        pass(EQ(3, elem->val.dval), "Web sum should be correct");


        END_SET("Test reduce");

        free_arrays();
}

/*
 * Iterate over elements in "other" and look them up in "result".
 *
 * If the element is there, we update the dval by summing.
 *
 * If the element isn't there, we set the value to what's in other.
 */
static int running_vector_sum(AssocArray *result, const AssocArray *other, 
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

static void test_aa_reduce_with_list_values()
{
        AssocArray result;
        AssocArray *arrays[NUM_ARRAYS];
        AssocArrayElem *elem;
        ReduceContext context;
        double *running_totals;
        int i;

        /* Set up context to tell running_vector_sum how many doubles to
         * allocate for each AssocArrayElem */
        context.num_items = NUM_ARRAYS;
        context.cur_index = 0;
        context.scale = 1.0;

        setup_arrays();

        START_SET("Test reduce with list values");

        /* Set up array pointers */
        for (i = 0; i < NUM_ARRAYS; i++)
                arrays[i] = &m_arrays[i];

        aa_init(&result, 5, compare1);
        aa_reduce(&result, (const AssocArray **)arrays, NUM_ARRAYS,
                                                  running_vector_sum, &context);

        /* Check result array */
        elem = aa_get_element(&result, "Native");
        running_totals = (double *)elem->val.vval;
        pass(EQ(10, running_totals[0]), "Native sum should be correct 0");
        pass(EQ(11, running_totals[1]), "Native sum should be correct 1");
        pass(EQ(11, running_totals[2]), "Native sum should be correct 2");

        elem = aa_get_element(&result, "Apps");
        running_totals = (double *)elem->val.vval;
        pass(EQ(5, running_totals[0]), "Apps sum should be correct 0");
        pass(EQ(5, running_totals[1]), "Apps sum should be correct 1");
        pass(EQ(6, running_totals[2]), "Apps sum should be correct 2");

        elem = aa_get_element(&result, "Web");
        running_totals = (double *)elem->val.vval;
        pass(EQ(0, running_totals[0]), "Web sum should be correct 0");
        pass(EQ(2, running_totals[1]), "Web sum should be correct 1");
        pass(EQ(3, running_totals[2]), "Web sum should be correct 2");

        END_SET("Test reduce with list values");

        for (i = 0; i < result.num_elements; i++) {
                free(aa_element(&result, i)->val.vval);
        }

        free_arrays();
}

int main()
{
        test_aa_reduce();
        test_aa_reduce_with_list_values();
        return 0;
}
