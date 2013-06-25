#include <string.h>
#include <err.h>

#import "Testing.h"

#include "../assoc_array.h"

static int compare1(const void *k1, const void *k2)
{
        return strcmp((const char *)k1, (const char *)k2);
}

static void test_aa_init()
{
        AssocArray array;

        START_SET("Initialize an AssocArray");
        aa_init(&array, 3, compare1);
        aa_free(&array);

        END_SET("Initialize an AssocArray");
}

static void test_aa_set_and_get()
{
        AssocArray array;
        AssocArrayElem elem;

        aa_init(&array, 2, compare1);

        START_SET("Test set and get");

        elem.key.sval = "Howdy";
        elem.val.dval = 20.0;
        pass(aa_set_element(&array, &elem) == 0, "Set element 1");

        elem.key.sval = "Adios";
        elem.val.dval = 10.0;
        pass(aa_set_element(&array, &elem) == 1, "Set element 2");

        elem = *aa_get_element(&array, "Howdy");
        pass(EQ(elem.val.dval, 20.0), "Get element 2");

        elem = *aa_get_element(&array, "Adios");
        pass(EQ(elem.val.dval, 10.0), "Get element 1");

        /* Check that we realloc */
        elem.key.sval = "Don't crash!";
        elem.val.dval = 100.0;
        pass(aa_set_element(&array, &elem) == 0, "Set realloc'd element");
        elem = *aa_get_element(&array, "Don't crash!");
        pass(EQ(elem.val.dval, 100.0), "Get realloc'd element");

        /* Check that we get NULL for missing element */
        pass(NULL == aa_get_element(&array, "GARBAGE"),
                                                    "Return NULL if not found");

        END_SET("Test set and get");

        aa_free(&array);
}

static char *get_string_key(AssocArrayElem *elem)
{
        return elem->key.sval;
}

static void test_aa_get_keys()
{
        AssocArray array;
        AssocArrayElem elem;
        char *key;

        aa_init(&array, 5, compare1);
        elem.key.sval = "One";
        aa_set_element(&array, &elem);

        elem.key.sval = "Who";
        aa_set_element(&array, &elem);

        elem.key.sval = "Two";
        aa_set_element(&array, &elem);


        START_SET("Test get keys");

        key = get_string_key(aa_element(&array, 1));
        pass(strcmp("Who", key) == 0, "Second key should be correct");

        /* Sort keys */
        aa_sort_keys(&array);

        key = get_string_key(aa_element(&array, 1));
        pass(strcmp("Two", key) == 0, "Sorted second key should be correct");

        END_SET("Test get keys");

        aa_free(&array);
}

int main()
{
        test_aa_init();
        test_aa_set_and_get();
        test_aa_get_keys();
        return 0;
}
