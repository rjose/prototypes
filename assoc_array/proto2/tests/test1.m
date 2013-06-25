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

        aa_init(&array, 3, compare1);

        START_SET("Test set and get");

        elem.key.sval = "Howdy";
        elem.val.dval = 20.0;
        pass(aa_set_element(&array, &elem) == 0, "Set element1");

        elem.key.sval = "Adios";
        elem.val.dval = 10.0;
        pass(aa_set_element(&array, &elem) == 0, "Set element2");

        elem = *aa_get_element(&array, "Howdy");
        pass(EQ(elem.val.dval, 20.0), "Get element 2");

        elem = *aa_get_element(&array, "Adios");
        pass(EQ(elem.val.dval, 10.0), "Get element 1");

        END_SET("Test set and get");

        aa_free(&array);
}

// TODO: Test when we have to realloc
// TODO: Test getting the keys

int main()
{
        test_aa_init();
        test_aa_set_and_get();
        return 0;
}
