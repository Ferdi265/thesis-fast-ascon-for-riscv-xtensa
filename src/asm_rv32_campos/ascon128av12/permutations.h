#ifndef PERMUTATIONS_H_
#define PERMUTATIONS_H_

#include "ascon.h"

#define EXT_BYTE64(x, n) ((u8)((u64)(x) >> (8 * (7 - (n)))))
#define INS_BYTE64(x, n) ((u64)(x) << (8 * (7 - (n))))
#define ROTR64(x, n) (((x) >> (n)) | ((x) << (64 - (n))))

#define P12() (ascon_asm(&s, 0xf0))
#define P8() (ascon_asm(&s, 0xb4))

#endif  // PERMUTATIONS_H_
