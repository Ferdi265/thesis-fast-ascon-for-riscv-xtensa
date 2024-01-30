#include <xtensa/coreasm.h>
#include "api.h"

## REGISTER ALLOCATION
#define t0h a4
#define t0l a5
#define x0h a6
#define x0l a7
#define x1h a8
#define x1l a9
#define x2h a10
#define x2l a11
#define x3h a12
#define x3l a13
#define x4h a14
#define x4l a15
## OVERLAPPING REGISTER ALLOCATION
#define optr x2h
#define iptr x2l
#define ilen x3h
#define mode x3l
#define t1h x4h
#define t1l x4l

## STACK FRAME LAYOUT
##     +-----------+-----------+-----------+------------+-----------+
##     | ASCON128a | ASCON128  | ASCON80PQ | ASCONHASHa | ASCONHASH |
##     | RATE 16   | RATE  8   | RATE  8   | RATE  8    | RATE  8   |
##     | PA   12   | PA   12   | PA   12   | PA   12    | PA   12   |
##     | PB    8   | PB    6   | PB    6   | PB    8    | PB   12   |
##     | KEY  16   | KEY  16   | KEY  20   |            |           |
##     +-----------+-----------+-----------+------------+-----------+
##   0 | bytes     | bytes     | bytes     | bytes      | bytes     |
##   4 | |         | \----     | \----     | \----      | \----     |
##   8 | |         | optr      | optr      | optr       | optr      |
##  12 | \----     | iptr      | iptr      | iptr  cur  | iptr  cur |
##  16 | state x2h | state x2h | state x2h |            |           |
##  20 | |     x2l | |     x2l | |     x2l | state x2l  | state x2l |
##  24 | |     x3h | |     x3h | |     x3h | \---- x3h  | \---- x3h |
##  28 | |     x3l | \---- x3l | \---- x3l |            |           |
##  32 | |     x4h | ilen      | ilen      | ilen  cur  | ilen  cur |
##  36 | \---- x4l | mode  cur | mode  cur | olen       | olen      |
##  40 | key   k0h | key   k0h | key   k1h |            |           |
##  44 | |     k0l | |     k0l | |     k1l | lr         | lr        |
##  48 | |     k1h | |     k1h | |     k2h +------------+-----------+
##  52 | \---- k1l | \---- k1l | |     k2l |
##  56 |           |           | \---- k0h |
##  60 | optr  cur | optr  cur | optr  cur |
##  64 | iptr  cur | iptr  cur | iptr  cur |
##  68 | ilen  cur | ilen  cur | ilen  cur |
##  72 | mode  cur | lr2       | lr2       |
##  76 | optr      | lr        | lr        |
##  80 | iptr      +-----------+-----------+
##  84 | ilen      |           |           |
##  88 | lr2       |           |           |
##  92 | lr        +-----------+-----------+
##  96 +-----------+ kptr  arg | kptr  arg |
## 100 |           | mode  arg | mode  arg |
## 104 |           +-----------+-----------+
## 108 +-----------+
## 112 | kptr  arg |
## 116 | mode  arg |
## 120 +-----------+

## REGISTER ALLOCATION LAYOUT
##
## a2 ... temp
## a3 ... temp
## a4 ... t0h
## a5 ... t0l
## a6 ... x0h
## a7 ... x0l
## a8 ... x1h
## a9 ... x1l
## a10 .. x2h / optr
## a11 .. x2l / iptr
## a12 .. x3h / ilen
## a13 .. x3l / mode
## a14 .. x4h / t1h
## a15 .. x4l / t1l

## ASCONXOFa
#define RATE 8
#define PA_ROUNDS 12
#define PA_START_ROUND ascon_start_round_a
#define PB_ROUNDS 8
#define PB_START_ROUND ascon_start_round_b

#define S_state 20
#define S_iptr_cur 12
#define S_ilen_cur 32
#define S_optr 8
#define S_olen 36
#define S_lr 44

.macro sbox x0, x1, x2, x3, x4, t0, t1, t2
    xor \t2, \x3, \x4
    xor \t1, \x0, \x4
    movi \t0, -1
    xor \x4, \x4, \t0
    xor \t0, \x1, \x2
    or \x4, \x4, \x3
    xor \x4, \x4, \t0
    xor \x3, \x3, \x1
    or \x3, \x3, \t0
    xor \x3, \x3, \t1
    xor \x2, \x2, \t1
    or \x2, \x2, \x1
    xor \x2, \x2, \t2
    or \x0, \x0, \t2
    xor \t0, \t0, \x0
    and \t1, \t1, \x1
    xor \x1, \x1, \t1
    xor \x1, \x1, \t2
.endm

.set ssai_val, 0
.macro set_ssai r, p
    .if (ssai_val ^ ((\r \p)/2))
        ssai ((\r \p)/2)
        .set ssai_val, ((\r \p)/2)
    .endif
.endm

.macro linear_odd_odd de, do, se, so, r0, r1, t0, t1
    set_ssai \r0, -\r1
    src \t0, \so, \so
    src \t1, \se, \se
    xor \t0, \t0, \so
    xor \t1, \t1, \se
    set_ssai \r1, -1
    src \t0, \t0, \t0
    set_ssai \r1, +1
    src \t1, \t1, \t1
    xor \de, \se, \t0
    xor \do, \so, \t1
.endm

.macro linear_odd_even de, do, se, so, r0, r1, t0, t1
    .if (\r0 > 1)
        set_ssai \r0, -1
        src \t0, \so, \so
        xor \t0, \t0, \se
    .else
        xor \t0, \so, \se
    .endif
    set_ssai \r0, +1
    src \t1, \se, \se
    xor \t1, \t1, \so
    set_ssai \r1, +0
    src \se, \se, \se
    src \so, \so, \so
    xor \de, \se, \t0
    xor \do, \so, \t1
.endm

.macro linear de, do, se, so, r0, r1, t0, t1
    .if (\r0 < \r1)
        linear \de, \do, \se, \so, \r1, \r0, \t0, \t1
    .elseif ((\r0 % 2) == 0)
        linear_odd_even \de, \do, \se, \so, \r1, \r0, \t0, \t1
    .elseif ((\r1 % 2) == 0)
        linear_odd_even \de, \do, \se, \so, \r0, \r1, \t0, \t1
    .else
        linear_odd_odd \de, \do, \se, \so, \r0, \r1, \t0, \t1
    .endif
.endm

.section .data
.align 2
.global ascon_round_constants
.type ascon_round_constants,@object
ascon_round_constants:
ascon_start_round_a:
    .byte 0xc, 0xc
    .byte 0x9, 0xc
    .byte 0xc, 0x9
    .byte 0x9, 0x9
ascon_start_round_b:
    .byte 0x6, 0xc
    .byte 0x3, 0xc
    .byte 0x6, 0x9
    .byte 0x3, 0x9
    .byte 0xc, 0x6
    .byte 0x9, 0x6
    .byte 0xc, 0x3
    .byte 0x9, 0x3
    .byte 0x0

.section .text
.align 4
.globl ascon_permute
.type ascon_permute,@function
ascon_permute:
    # ascon permutation
    # state in a6 .. a9 and sp + 16 .. sp + 36
    # start round constant ptr in a2
    # temporaries in a3, a4, a5
    l32i x2l, a1, (S_state + 0)
    l32i x3h, a1, (S_state + 4)
.globl ascon_permute_noload
.type ascon_permute_noload,@function
ascon_permute_noload:
    # state in a6 .. a15
    # start round constant ptr in a2
    # temporaries in a3, a4, a5

    j .LPloopcond
.LPloop:
    # round constant
    xor x2l, x2l, a3
    l8ui a3, a2, 1
    xor x2h, x2h, a3

    # s-box
    sbox x0l, x1l, x2l, x3l, x4l, t0l, t0h, a3
    sbox x0h, x1h, x2h, x3h, x4h, t0h, x0l, a3

    # linear layer
    linear x0l, x0h, x2l, x2h, 19, 28, x0l, x0h
    linear x2l, x2h, x4l, x4h, 1, 6, x2l, x2h
    linear x4l, x4h, x1l, x1h, 7, 41, x4l, x4h
    linear x1l, x1h, x3l, x3h, 61, 39, x1l, x1h
    linear x3l, x3h, t0l, t0h, 10, 17, x3l, x3h

    # condition
    addi a2, a2, 2
.LPloopcond:
    l8ui a3, a2, 0
    bnez a3, .LPloop
.LPend:
    s32i x2l, a1, (S_state + 0)
    s32i x3h, a1, (S_state + 4)
    ret

.macro bitxchg d, x, mask, off, t0
    srli \t0, \x, \off
    xor \t0, \t0, \x
    and \t0, \t0, \mask
    xor \d, \x, \t0
    slli \t0, \t0, \off
    xor \d, \d, \t0
.endm

.macro to_bi32_rev8 dl, dh, xl, xh, t0, t1
    movi \t1, 0x22222222
    bitxchg \dl, \xl, \t1, 1, \t0
    bitxchg \dh, \xh, \t1, 1, \t0
    movi \t1, 0x0C0C0C0C
    bitxchg \dl, \dl, \t1, 2, \t0
    bitxchg \dh, \dh, \t1, 2, \t0
    movi \t1, 0x000F000F
    bitxchg \dl, \dl, \t1, 12, \t0
    bitxchg \dh, \dh, \t1, 12, \t0
    movi \t1, 0x000000FF
    bitxchg \dl, \dl, \t1, 24, \t0
    bitxchg \dh, \dh, \t1, 24, \t0

    srli \t0, \dl, 16
    xor \t0, \t0, \dh
    slli \t0, \t0, 16
    xor \dl, \dl, \t0
    srli \t0, \t0, 16
    xor \dh, \dh, \t0
.endm

.macro from_bi32_rev8 dl, dh, xl, xh, t0, t1
    srli \t0, \xl, 16
    xor \t0, \t0, \xh
    slli \t0, \t0, 16
    xor \dl, \xl, \t0
    srli \t0, \t0, 16
    xor \dh, \xh, \t0

    movi \t1, 0x000000FF
    bitxchg \dl, \dl, \t1, 24, \t0
    bitxchg \dh, \dh, \t1, 24, \t0
    movi \t1, 0x000F000F
    bitxchg \dl, \dl, \t1, 12, \t0
    bitxchg \dh, \dh, \t1, 12, \t0
    movi \t1, 0x0C0C0C0C
    bitxchg \dl, \dl, \t1, 2, \t0
    bitxchg \dh, \dh, \t1, 2, \t0
    movi \t1, 0x22222222
    bitxchg \dl, \dl, \t1, 1, \t0
    bitxchg \dh, \dh, \t1, 1, \t0
.endm

.align 4
.globl ascon_to_bi32_rev8_half
.type ascon_to_bi32_rev8_half,@function
ascon_to_bi32_rev8_half:
    to_bi32_rev8 t0l, t0h, t0l, t0h, a2, a3
    ret
.align 4
.globl ascon_from_bi32_rev8_half
.type ascon_from_bi32_rev8_half,@function
ascon_from_bi32_rev8_half:
    from_bi32_rev8 t0l, t0h, t0l, t0h, a2, a3
    ret

.align 4
.globl ascon_memcpy
.type ascon_memcpy,@function
ascon_memcpy:
    # memcpy that preserves registers used by ascon
    # dest in a2
    # src in a3
    # temporaries in a4, a5
    movi a4, 0
    j .LMcond
.LMloop:
    l8ui a5, a3, 0
    s8i a5, a2, 0
    addi a2, a2, 1
    addi a3, a3, 1
    addi a4, a4, 1
.LMcond:
    bltu a4, ilen, .LMloop
.LMend:
    ret

.align 4
.globl ascon_core
.type ascon_core,@function
ascon_core:
    abi_entry 48, 4
    s32i a0, a1, S_lr
    s32i a2, a1, S_optr
    s32i a3, a1, S_olen

    # setup absorb args
    mov iptr, a4
    mov ilen, a5

    # initialize
    movi x0h, 0x0846d7a5
    movi x0l, 0xa4b87d44
    movi x1h, 0xaa6f1005
    movi x1l, 0xb3a2dbf4
    movi x2h, 0xdc451146
    movi t0h, 0xf713e811
    movi t0l, 0x468cb253
    movi x3l, 0x2839e30d
    movi x4h, 0xeb2d4297
    movi x4l, 0x09e96977

    # save state
    s32i t0h, a1, (S_state + 0)
    s32i t0l, a1, (S_state + 4)

    j .LAcond
.LAloop:
    l32i t0h, iptr, 0
    l32i t0l, iptr, 4
    call0 ascon_to_bi32_rev8_half
    xor x0h, x0h, t0h
    xor x0l, x0l, t0l

.LApermute:
    s32i iptr, a1, S_iptr_cur
    s32i ilen, a1, S_ilen_cur
    movi a2, PB_START_ROUND
    movi a3, PB_ROUNDS
    call0 ascon_permute
    l32i iptr, a1, S_iptr_cur
    l32i ilen, a1, S_ilen_cur

    addi iptr, iptr, RATE
    addi ilen, ilen, -RATE

.LAcond:
    bgeui ilen, RATE, .LAloop

.LAend:
    movi a2, 0
    s32i a2, a1, 0
    s32i a2, a1, 4

.LAendabsorb:
    mov a2, a1
    mov a3, iptr
    call0 ascon_memcpy

    movi a4, 0x80
    add a2, a1, ilen
    l8ui a3, a2, 0
    xor a3, a3, a4
    s8i a3, a2, 0

    l32i t0h, a1, 0
    l32i t0l, a1, 4
    call0 ascon_to_bi32_rev8_half
    xor x0h, x0h, t0h
    xor x0l, x0l, t0l

.LCpermute:
    movi a2, PA_START_ROUND
    movi a3, PA_ROUNDS
    call0 ascon_permute

    # setup squeeze args
    l32i iptr, a1, S_optr
    l32i ilen, a1, S_olen

    j .LScond
.LSloop:
    mov t0h, x0h
    mov t0l, x0l
    call0 ascon_from_bi32_rev8_half
    s32i t0h, iptr, 0
    s32i t0l, iptr, 4

.LSpermute:
    s32i iptr, a1, S_iptr_cur
    s32i ilen, a1, S_ilen_cur
    movi a2, PB_START_ROUND
    movi a3, PB_ROUNDS
    call0 ascon_permute
    l32i iptr, a1, S_iptr_cur
    l32i ilen, a1, S_ilen_cur

    addi iptr, iptr, RATE
    addi ilen, ilen, -RATE

.LScond:
    bgeui ilen, RATE, .LSloop

.LSend:
    movi a2, 0
    s32i a2, a1, 0
    s32i a2, a1, 4

.LSendsqueeze:
    mov t0h, x0h
    mov t0l, x0l
    call0 ascon_from_bi32_rev8_half
    s32i t0h, a1, 0
    s32i t0l, a1, 4

    mov a2, iptr
    mov a3, a1
    call0 ascon_memcpy

    # return
    movi a2, 0
    l32i a0, a1, S_lr
    abi_return
