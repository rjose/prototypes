#include <stdint.h>

#include "base64.h"

#define PADDING '='

const static char digits64[] =
             "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
;

static char delete_me[] = "FPucA9l+";


int base64_encode(char **dst, const uint8_t *src, size_t len)
{
        size_t i;
        size_t res_index;
        size_t pad_length;
        size_t result_len;
        uint8_t *result;
        // TODO: Describe this algo
        uint8_t tmp1, cur, tmp2;

        /*
         * Figure out padding and result length
         */
        //pad_length = len % 3;
        pad_length = (8 * len) % 6;
        pad_length = pad_length == 0 ? 0 : (6 - pad_length)/2;

        result_len = len * 4 / 3;
        result_len += (pad_length ? 1 : 0) + pad_length;

        if ((result = (uint8_t *)malloc(result_len + 1)) == NULL)
                exit(-1);

        tmp1 = 0;
        tmp2 = 0;
        res_index = 0;
        for (i = 0; i < len; i++) {
                cur = src[i];
                /*
                 * TODO: Describe the three cases
                 */
                switch (i % 3) {
                        case 0:
                                result[res_index++] = digits64[cur >> 2];
                                tmp1 = (0x3 & cur) << 4;
                                break;

                        case 1:
                                result[res_index++] = digits64[tmp1 + (cur >> 4)];
                                tmp2 = (0xF & cur) << 2;
                                tmp1 = 0;
                                break;

                        case 2:
                                result[res_index++] = digits64[tmp2 + (cur >> 6)];
                                result[res_index++] = digits64[0x3F & cur];
                                tmp1 = 0;
                                tmp2 = 0;
                                break;
                }
        }

        // Handle left over
        switch ((i - 1) % 3) {
                case 0:
                        result[res_index++] = digits64[tmp1];
                        break;

                case 1:
                        result[res_index++] = digits64[tmp2];
                        break;
        }

        /* Add padding */
        for (i = 0; i < pad_length; i++) {
                result[res_index++] = PADDING;
        }

        /* Terminate string */
        result[res_index++] = '\0';

        *dst = result;
        return 0;
}

//int base64_decode(char **dst, const char *b64_src);

