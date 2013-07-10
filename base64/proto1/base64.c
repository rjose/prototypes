#include <string.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include <openssl/bio.h>
#include <openssl/evp.h>

#include "base64.h"

static int calcDecodeLength(const char *);



int base64_encode(char **dst, const char* src)
{
         BIO *bio, *b64;
         FILE* stream;
         int encodedSize = 4*ceil((double)strlen(src)/3);
         *dst = (char *)malloc(encodedSize+1);
         
         stream = fmemopen(*dst, encodedSize+1, "w");
         b64 = BIO_new(BIO_f_base64());
         bio = BIO_new_fp(stream, BIO_NOCLOSE);
         bio = BIO_push(b64, bio);
         BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL); //Ignore newlines - write everything in one line
         BIO_write(bio, src, strlen(src));
         BIO_flush(bio);
         BIO_free_all(bio);
         fclose(stream);
         
         return 0;
}

 
static int calcDecodeLength(const char* b64input)
{
        int len = strlen(b64input);
        int padding = 0;

        if (b64input[len-1] == '=' && b64input[len-2] == '=') //last two chars are =
                padding = 2;
        else if (b64input[len-1] == '=') //last char is =
                padding = 1;

        return (int)len*0.75 - padding;
}
 
int base64_decode(char **dst, const char *b64_src)
{
        BIO *bio, *b64;
        int decodeLen = calcDecodeLength(b64_src),
            len = 0;
        *dst = (char*)malloc(decodeLen+1);
        FILE* stream = fmemopen(b64_src, strlen(b64_src), "r");

        b64 = BIO_new(BIO_f_base64());
        bio = BIO_new_fp(stream, BIO_NOCLOSE);
        bio = BIO_push(b64, bio);
        BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL); //Do not use newlines to flush dst
        len = BIO_read(bio, *dst, strlen(b64_src));
        //Can test here if len == decodeLen - if not, then return an error
        (*dst)[len] = '\0';

        BIO_free_all(bio);
        fclose(stream);

        return 0;
} 
