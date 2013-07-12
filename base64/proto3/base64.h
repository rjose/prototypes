#ifndef BASE64_H
#define BASE64_H

#include <stdlib.h>
#include <stdint.h>

int base64_encode(char **dst, const uint8_t *src, size_t len);
int base64_decode(char **dst, const char *b64_src);

#endif
