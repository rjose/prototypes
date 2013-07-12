#include <stdint.h>

#include "base64.h"

#define PADDING '='

const static char digits64[] =
             "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
;


int base64_encode(char **dst, const uint8_t *src, size_t len)
{
        size_t i;
        size_t res_index;
        size_t pad_length;
        size_t result_len;
        uint8_t cur, leftover;
        uint8_t *result;

        /*
         * The pad length will be 0, 1, or 2 depending on how the final bits in
         * the source data lay over the 6-bit encoding characters.
         */
        pad_length = (8 * len) % 6;
        pad_length = pad_length == 0 ? 0 : (6 - pad_length)/2;

        /*
         * Next, we allocate memory for the result string.  To find the number
         * of 6-bit bytes we need, we multiply the number of source bytes by 8
         * and (integer) divide by 6. If we need to do any padding, that means
         * we need another 6-bit byte for the leftover bits. We'll also need to
         * allocate for the padding characters.
         */
        result_len = len * 8 / 6;
        result_len += (pad_length ? 1 : 0) + pad_length;

        if ((result = (uint8_t *)malloc(result_len + 1)) == NULL)
                exit(-1);

        /*
         * We can view the encoding of the src data as 3 cases which cycle over
         * the bytes:
         *
         *   Case 0: Start
         *   -------------
         *   Here, the top 6-bits of the first byte are downshifted 2 to form
         *   then ext encoded char. The leftover 2 bits are upshifted by 4 to be
         *   used as part of the next encoded byte. 
         *
         *   Case 1: Middle
         *   --------------
         *   Here, the 2 bits from Case 0 are added to the first 4 bits of the
         *   current byte (which are downshifted 4) to identify the next
         *   encoding char. The remaining 4 bits of the current byte are
         *   upshifted 2 to be used as part of the next encoded byte.
         *
         *   Case 2: End
         *   -----------
         *   Here, the 4 bits from Case 1 are added to the first 2 bits of the
         *   current byte (downshifted 6) to identify the next encoding char.
         *   This leaves exactly 6 bits from the current byte which are used to
         *   identify one more encoding char.
         */
        leftover = 0;
        res_index = 0;
        for (i = 0; i < len; i++) {
                cur = src[i];
                switch (i % 3) {
                        case 0:
                                result[res_index++] = digits64[cur >> 2];
                                leftover = (0x3 & cur) << 4;
                                break;

                        case 1:
                                result[res_index++] =
                                                digits64[leftover + (cur >> 4)];
                                leftover = (0xF & cur) << 2;
                                break;

                        case 2:
                                result[res_index++] =
                                                digits64[leftover + (cur >> 6)];
                                result[res_index++] = digits64[0x3F & cur];
                                leftover = 0;
                                break;
                }
        }


        /*
         * If there are any leftover bits, they will already have been shifted
         * appropriately, so we can add the next encoding char directly.
         */
        if (leftover)
                result[res_index++] = digits64[leftover];

        /*
         * The last step is to add the padding characters (if needed)
         */
        for (i = 0; i < pad_length; i++) {
                result[res_index++] = PADDING;
        }

        /*
         * Don't forget to terminate the string!
         */
        result[res_index++] = '\0';

        *dst = result;
        return 0;
}

//int base64_decode(char **dst, const char *b64_src);

