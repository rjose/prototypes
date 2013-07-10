#ifndef BASE64_H
#define BASE64_H

int base64_encode(char **dst, const char* src);
int base64_decode(char **dst, const char*b64src);

#endif
