#include <string.h>
#include <err.h>

#import "Testing.h"

#include "../assoc_array.h"

#define NUM_ARRAYS 3
AssocArray m_arrays[NUM_ARRAYS];

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
static int vector_sum(AssocArray *result, const AssocArray *other)
{
        int i;
        AssocArrayElem *result_elem, *other_elem;

        for (i = 0; i < other->num_elements; i++) {
                other_elem = aa_element(other, i);
                result_elem = aa_get_element(result, other_elem->key.vval);

                if (result_elem != NULL) {
                        result_elem->val.dval += other_elem->val.dval;
                }
                else {
                        aa_set_element(result, other_elem);
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
        aa_reduce(&result, (const AssocArray **)arrays, NUM_ARRAYS, vector_sum);

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


int main()
{
        test_aa_reduce();
        return 0;
}
