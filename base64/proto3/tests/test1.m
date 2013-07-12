#include <err.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "../base64.h"

#import "Testing.h"

static int check_data(uint8_t *d1, uint8_t *d2, size_t len)
{
        size_t i;

        for (i = 0; i < len; i++)
                if (*d1++ != *d2++)
                        return 0;

        return 1;
}


int main()
{
        char *base64Output;
        uint8_t *decodedOutput;
        size_t data_len;

        /*
         * Test encode
         */
        uint8_t data[] = {0x14, 0xfb, 0x9c, 0x03, 0xd9, 0x7e};
        base64_encode(&base64Output, data, 6);
        pass(0 == strcmp(base64Output, "FPucA9l+"), "Encode data");
        free(base64Output);

        base64_encode(&base64Output, data, 5);
        pass(0 == strcmp(base64Output, "FPucA9k="), "Encode data");
        free(base64Output);

        base64_encode(&base64Output, data, 4);
        pass(0 == strcmp(base64Output, "FPucAw=="), "Encode data");
        free(base64Output);

        base64_encode(&base64Output, "Hello", 5);
        pass(0 == strcmp(base64Output, "SGVsbG8="), "Encode hello");
        free(base64Output);

        /*
         * Test decode
         */
        base64_decode(&decodedOutput, "SGVsbG8=", &data_len);
        pass(5 == data_len, "Check data len");
        pass(0 == strncmp((char *)decodedOutput, "Hello", data_len), "Decode hello");
        free(decodedOutput);

        base64_decode(&decodedOutput, "FPucA9l+", &data_len);
        pass(6 == data_len, "Check data len");
        pass(1 == check_data(decodedOutput, data, data_len), "Check data");
        free(decodedOutput);

        base64_decode(&decodedOutput, "FPucA9k=", &data_len);
        pass(5 == data_len, "Check data len");
        pass(1 == check_data(decodedOutput, data, data_len), "Check data");
        free(decodedOutput);

        base64_decode(&decodedOutput, "FPucAw==", &data_len);
        pass(4 == data_len, "Check data len");
        pass(1 == check_data(decodedOutput, data, data_len), "Check data");
        free(decodedOutput);
        return 0;
}

