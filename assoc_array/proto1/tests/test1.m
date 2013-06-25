#include <err.h>

#import "Testing.h"

#include "../assoc_array.h"

static void test_aa_init()
{
        AssocArray array;

        START_SET("Initialize an AssocArray");
        aa_init(&array);

        END_SET("Initialize an AssocArray");
}

int main()
{
        test_aa_init();
        return 0;
}
