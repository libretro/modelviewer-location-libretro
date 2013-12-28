#ifndef _LIBRETRO_BASE64_H
#define _LIBRETRO_BASE64_H

#include "boolean.h"

bool base64_encode(char *output, const uint8_t* input, unsigned inlength);
bool base64_decode(uint8_t *output, unsigned *outlength, const char *input);

#endif
