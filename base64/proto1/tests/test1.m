#include <err.h>
#include <stdlib.h>
#include <string.h>

#include "../base64.h"

#import "Testing.h"


int main()
{
        char *base64Output;

        /*
         * Test encode
         */
        base64_encode(&base64Output, "Hello");
        printf(base64Output);
        pass(0 == strcmp(base64Output, "SGVsbG8="), "Encode hello");

        if (base64Output)
                free(base64Output);

        /*
         * Test decode
         */
        return 0;
}
