#include "api.h"

## REGISTER ALLOCATION
#define t0h t3
#define t0l t4
#define t1h t5
#define t1l t6
#define x0h s0
#define x0l s1
#define x1h s2
#define x1l s3
#define x2h s4
#define x2l s5
#define x3h s6
#define x3l s7
#define x4h s8
#define x4l s9
#define k0h s10
#define k0l s11
#define k1h a5
#define k1l a6

## OVERLAPPING REGISTER ALLOCATION
#define optr a0
#define olen a1
#define iptr a2
#define ilen a3
#define mode a7

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
##   8 | |         |           |           |            |           |
##  12 | \----     |           |           |            |           |
##  16 |           |           | key k2h   |            |           |
##  20 | optr      | optr      | optr      | optr       | optr      |
##  24 | mode      | mode      | mode      |            |           |
##  28 | saved s11 | saved s11 | saved s11 | saved s11  | saved s11 |
##  32 | saved s10 | saved s10 | saved s10 | saved s10  | saved s10 |
##  36 | saved s9  | saved s9  | saved s9  | saved s9   | saved s9  |
##  40 | saved s8  | saved s8  | saved s8  | saved s8   | saved s8  |
##  44 | saved s7  | saved s7  | saved s7  | saved s7   | saved s7  |
##  48 | saved s6  | saved s6  | saved s6  | saved s6   | saved s6  |
##  52 | saved s5  | saved s5  | saved s5  | saved s5   | saved s5  |
##  56 | saved s4  | saved s4  | saved s4  | saved s4   | saved s4  |
##  60 | saved s3  | saved s3  | saved s3  | saved s3   | saved s3  |
##  64 | saved s2  | saved s2  | saved s2  | saved s2   | saved s2  |
##  68 | saved s1  | saved s1  | saved s1  | saved s1   | saved s1  |
##  72 | saved s0  | saved s0  | saved s0  | saved s0   | saved s0  |
##  76 | saved ra  | saved ra  | saved ra  | saved ra   | saved ra  |
##  80 +-----------+-----------+-----------+------------+-----------+

## REGISTER ALLOCATION LAYOUT
##
## a0 ... optr
## a1 ... olen
## a2 ... iptr
## a3 ... ilen
## a4 ... temp
## a5 ... k1h
## a6 ... k1l
## a7 ... mode
## t0 ... temp / lr
## t1 ... temp
## t2 ... temp
## t3 ... t0h
## t4 ... t0l
## t5 ... t1h
## t6 ... t1l
## s0 ... x0h
## s1 ... x0l
## s2 ... x1h
## s3 ... x1l
## s4 ... x2h
## s5 ... x2l
## s6 ... x3h
## s7 ... x3l
## s8 ... x4h
## s9 ... x4l
## s10 .. k0h
## s11 .. k0l

## ASCONHASHa
#define RATE 8
#define PA_ROUNDS 12
#define PA_START_ROUND ascon_start_round_a
#define PB_ROUNDS 8
#define PB_START_ROUND ascon_start_round_b

#define S_key 16
#define S_optr 20
#define S_mode 24

.macro sbox x0, x1, x2, x3, x4, t0, t1, t2
    xor \t1, \x0, \x4
    xor \t2, \x3, \x4
    xor \t0, \x1, \x2
    orn \x4, \x3, \x4
    xor \x4, \x4, \t0
    xor \x3, \x3, \x1
    or \x3, \x3, \t0
    xor \x3, \x3, \t1
    xor \x2, \x2, \t1
    or \x2, \x2, \x1
    xor \x2, \x2, \t2
    or \x0, \x0, \t2
    xor \t0, \t0, \x0
    andn \x1, \x1, \t1
    xor \x1, \x1, \t2
.endm

.macro linear_odd_odd de, do, se, so, r0, r1, t0, t1
    rori \t0, \so, ((\r0 - \r1) / 2)
    rori \t1, \se, ((\r0 - \r1) / 2)
    xor \t0, \t0, \so
    xor \t1, \t1, \se
    rori \t0, \t0, ((\r1 - 1) / 2)
    rori \t1, \t1, ((\r1 + 1) / 2)
    xor \de, \se, \t0
    xor \do, \so, \t1
.endm

.macro linear_odd_even de, do, se, so, r0, r1, t0, t1
    .if (\r0 > 1)
        rori \t0, \so, ((\r0 - 1) / 2)
        xor \t0, \t0, \se
    .else
        xor \t0, \so, \se
    .endif
    rori \t1, \se, ((\r0 + 1) / 2)
    xor \t1, \t1, \so
    rori \se, \se, (\r1 / 2)
    rori \so, \so, (\r1 / 2)
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
    # state in s0 .. s9
    # start round constant ptr in t1
    # temporaries in t3, t4, t5
    # link register in t0
    j .LPloopcond
.LPloop:
    # round constant
    xor x2l, x2l, t2
    lbu t2, 1(t1)
    xor x2h, x2h, t2

    # s-box
    sbox x0l, x1l, x2l, x3l, x4l, t0l, t0h, t1h
    sbox x0h, x1h, x2h, x3h, x4h, t0h, x0l, t1h

    # linear layer
    linear x0l, x0h, x2l, x2h, 19, 28, x0l, x0h
    linear x2l, x2h, x4l, x4h, 1, 6, x2l, x2h
    linear x4l, x4h, x1l, x1h, 7, 41, x4l, x4h
    linear x1l, x1h, x3l, x3h, 61, 39, x1l, x1h
    linear x3l, x3h, t0l, t0h, 10, 17, x3l, x3h

    # condition
    addi t1, t1, 2
.LPloopcond:
    lbu t2, 0(t1)
    bne t2, zero, .LPloop

.LPend:
    jalr zero, 0(t0)

.macro to_bi32_rev8 de, do, xl, xh, t0
    rev8 \t0, \xl
    rev8 \do, \xh
    unzip \t0, \t0
    unzip \do, \do
    pack \de, \t0, \do
    packu \do, \t0, \do
.endm

.macro from_bi32_rev8 dl, dh, xe, xo, t0
    pack \t0, \xe, \xo
    packu \dh, \xe, \xo
    zip \dl, \t0
    zip \dh, \dh
    rev8 \dl, \dl
    rev8 \dh, \dh
.endm

.align 4
.globl ascon_to_bi32_rev8_half
.type ascon_to_bi32_rev8_half,@function
ascon_to_bi32_rev8_half:
    to_bi32_rev8 t0l, t0h, t0l, t0h, t1
    jalr zero, 0(t0)

.align 4
.globl ascon_from_bi32_rev8_half
.type ascon_from_bi32_rev8_half,@function
ascon_from_bi32_rev8_half:
    from_bi32_rev8 t0l, t0h, t0l, t0h, t1
    jalr zero, 0(t0)

.align 4
.globl ascon_memcpy
.type ascon_memcpy,@function
ascon_memcpy:
    # memcpy that preserves registers used by ascon
    # dest in t1
    # src in t2
    # len in a4
    # temporaries in t3, t4
    # link register in t0
    li t3, 0
    j .LMcond
.LMloop:
    lbu t4, 0(t2)
    sb t4, 0(t1)
    addi t1, t1, 1
    addi t2, t2, 1
    addi t3, t3, 1
.LMcond:
    blt t3, ilen, .LMloop
.LMend:
    jalr zero, 0(t0)

.align 4
.globl ascon_core
.type ascon_core,@function
ascon_core:
    # ascon algorithm
    # sets up state in s0 .. s9
    # outptr in a0
    # outlen in a1
    # inptr in a2
    # inlen in a3
    # link register in ra
    addi sp, sp, -80
    sw ra, 76(sp)
    sw s0, 72(sp)
    sw s1, 68(sp)
    sw s2, 64(sp)
    sw s3, 60(sp)
    sw s4, 56(sp)
    sw s5, 52(sp)
    sw s6, 48(sp)
    sw s7, 44(sp)
    sw s8, 40(sp)
    sw s9, 36(sp)
    sw s10, 32(sp)
    sw s11, 28(sp)

    # initialize
    li x0h, 0x0108e46d
    li x0l, 0x1b16eb02
    li x1h, 0x5b9b8efd
    li x1l, 0xd29083f3
    li x2h, 0x7ad66562
    li x2l, 0x2891ae4a
    li x3h, 0x9dc27156
    li x3l, 0xee3bfc7f
    li x4h, 0xc61d5fa9
    li x4l, 0x16801633

    j .LAcond
.LAloop:
    lw t0h, 0(iptr)
    lw t0l, 4(iptr)
    jal t0, ascon_to_bi32_rev8_half
    xor x0h, x0h, t0h
    xor x0l, x0l, t0l

.LApermute:
    la t1, PB_START_ROUND
    jal t0, ascon_permute

    addi iptr, iptr, RATE
    addi ilen, ilen, -RATE

.LAcond:
    li t0, RATE
    bge ilen, t0, .LAloop

.LAend:
    sw zero, 0(sp)
    sw zero, 4(sp)

.LAendabsorb:
    mv t1, sp
    mv t2, iptr
    jal t0, ascon_memcpy

    add t1, sp, ilen
    lbu t0, 0(t1)
    xori t0, t0, 0x80
    sb t0, 0(t1)

    lw t0h, 0(sp)
    lw t0l, 4(sp)
    jal t0, ascon_to_bi32_rev8_half
    xor x0h, x0h, t0h
    xor x0l, x0l, t0l

.LCpermute:
    la t1, PA_START_ROUND
    jal t0, ascon_permute

    j .LScond
.LSloop:
    mv t0h, x0h
    mv t0l, x0l
    jal t0, ascon_from_bi32_rev8_half
    sw t0h, 0(optr)
    sw t0l, 4(optr)

.LSpermute:
    la t1, PB_START_ROUND
    jal t0, ascon_permute

    addi optr, optr, RATE
    addi olen, olen, -RATE

.LScond:
    li t0, RATE
    bge olen, t0, .LSloop

.LSend:
    sw zero, 0(sp)
    sw zero, 4(sp)

.LSendsqueeze:
    mv t0h, x0h
    mv t0l, x0l
    jal t0, ascon_from_bi32_rev8_half
    sw t0h, 0(sp)
    sw t0l, 4(sp)

    mv t1, optr
    mv t2, sp
    mv ilen, olen
    jal t0, ascon_memcpy

.LCzeroreturn:
    li a0, 0
.LCreturn:
    lw ra, 76(sp)
    lw s0, 72(sp)
    lw s1, 68(sp)
    lw s2, 64(sp)
    lw s3, 60(sp)
    lw s4, 56(sp)
    lw s5, 52(sp)
    lw s6, 48(sp)
    lw s7, 44(sp)
    lw s8, 40(sp)
    lw s9, 36(sp)
    lw s10, 32(sp)
    lw s11, 28(sp)
    addi sp, sp, 80
    jalr zero, 0(ra)
