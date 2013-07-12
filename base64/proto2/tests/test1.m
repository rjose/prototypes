#include <err.h>
#include <stdlib.h>
#include <string.h>

#include "../base64.h"

#import "Testing.h"


int main()
{
        char *base64Output;
        char *decodedOutput;

        /*
         * Test encode
         */
        base64_encode(&base64Output, "Hello");
        pass(0 == strcmp(base64Output, "SGVsbG8="), "Encode hello");

        if (base64Output)
                free(base64Output);

        /*
         * Test decode
         */
        base64_decode(&decodedOutput, "SGVsbG8=");
        pass(0 == strcmp(decodedOutput, "Hello"), "Decode hello");

        return 0;
}
