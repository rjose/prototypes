#include <err.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "../base64.h"

#import "Testing.h"


int main()
{
        char *base64Output;
        char *decodedOutput;

        /*
         * Test encode
         */
        
        uint8_t data[] = {0x14, 0xfb, 0x9c, 0x03, 0xd9, 0x7e};
        base64_encode(&base64Output, data, 6);
        pass(0 == strcmp(base64Output, "FPucA9l+"), "Encode data");
        free(base64Output);

        base64_encode(&base64Output, "Hello", 5);
        pass(0 == strcmp(base64Output, "SGVsbG8="), "Encode hello");
        free(base64Output);
//
//        if (base64Output)
//                free(base64Output);
//
//        /*
//         * Test decode
//         */
//        base64_decode(&decodedOutput, "SGVsbG8=");
//        pass(0 == strcmp(decodedOutput, "Hello"), "Decode hello");

        return 0;
}
