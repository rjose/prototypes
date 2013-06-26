#include <string.h>
#include <err.h>

#import "Testing.h"

#include "../assoc_array.h"

#define NUM_ARRAYS 3
AssocArray m_arrays[NUM_ARRAYS];

static void setup_arrays()
{
        AssocArrayElem elem;
        int i;
        for (i=0; i < NUM_ARRAYS; i++) {
                aa_init(&m_arrays[i], 5, aa_string_compare);
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

        aa_init(&result, 5, aa_string_compare);
        aa_reduce(&result, (const AssocArray **)arrays, NUM_ARRAYS, aa_vector_sum, NULL);

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

static int destroy_running_totals(AssocArrayElem *elem)
{
        free(elem->val.vval);
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

        aa_init(&result, 5, aa_string_compare);
        result.destroy = destroy_running_totals;
        aa_reduce(&result, (const AssocArray **)arrays, NUM_ARRAYS,
                                                  aa_running_vector_sum, &context);

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

        free_arrays();
}

int main()
{
        test_aa_reduce();
        test_aa_reduce_with_list_values();
        return 0;
}
