#include <string.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include <openssl/bio.h>
#include <openssl/evp.h>

#include "base64.h"


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
         
         return 0; //success
}
