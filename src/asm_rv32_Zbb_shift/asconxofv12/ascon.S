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

## ASCONXOF
#define RATE 8
#define PA_ROUNDS 12
#define PA_START_ROUND 0xf0
#define PB_ROUNDS 12
#define PB_START_ROUND 0xf0

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

.macro linear dl, dh, sl, sh, sl0, sh0, r0, sl1, sh1, r1, t0
    slli \dh, \sl0, (32 - \r0)
    srli \t0, \sh0, \r0
    xor \dh, \dh, \t0
    slli \t0, \sl1, (32 - \r1)
    xor \dh, \dh, \t0
    srli \t0, \sh1, \r1
    xor \dh, \dh, \t0
    slli \dl, \sh0, (32 - \r0)
    srli \t0, \sl0, \r0
    xor \dl, \dl, \t0
    slli \t0, \sh1, (32 - \r1)
    xor \dl, \dl, \t0
    srli \t0, \sl1, \r1
    xor \dl, \dl, \t0
    xor \dl, \dl, \sl
    xor \dh, \dh, \sh
.endm

.align 4
.globl ascon_permute
.type ascon_permute,@function
ascon_permute:
    # ascon permutation
    # state in s0 .. s9
    # start round constant in t1
    # temporaries in t3, t4, t5
    # link register in t0
    li t1l, 0x4b
.LPloop:
    # round constant
    xor x2l, x2l, t1

    # s-box
    sbox x0l, x1l, x2l, x3l, x4l, t0l, t0h, t1h
    sbox x0h, x1h, x2h, x3h, x4h, t0h, x0l, t1h

    # linear layer
    linear x0l, x0h, x2l, x2h, x2l, x2h, 19, x2l, x2h, 28, t1h
    linear x2l, x2h, x4l, x4h, x4l, x4h, 1, x4l, x4h, 6, t1h
    linear x4l, x4h, x1l, x1h, x1h, x1l, 9, x1l, x1h, 7, t1h
    linear x1l, x1h, x3l, x3h, x3h, x3l, 7, x3h, x3l, 29, t1h
    linear x3l, x3h, t0l, t0h, t0l, t0h, 10, t0l, t0h, 17, t1h

    # condition
    addi t1, t1, -15
    bge t1, t1l, .LPloop

.LPend:
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
    li x0h, 0xb57e273b
    li x0l, 0x814cd416
    li x1h, 0x2b510425
    li x1l, 0x62ae2420
    li x2h, 0x66a3a776
    li x2l, 0x8ddf2218
    li x3h, 0x5aad0a7a
    li x3l, 0x8153650c
    li x4h, 0x4f3e0e32
    li x4l, 0x539493b6

    j .LAcond
.LAloop:
    lw t0h, 0(iptr)
    lw t0l, 4(iptr)
    rev8 t0h, t0h
    rev8 t0l, t0l
    xor x0h, x0h, t0h
    xor x0l, x0l, t0l

.LApermute:
    li t1, PB_START_ROUND
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
    rev8 t0h, t0h
    rev8 t0l, t0l
    xor x0h, x0h, t0h
    xor x0l, x0l, t0l

.LCpermute:
    li t1, PA_START_ROUND
    jal t0, ascon_permute

    j .LScond
.LSloop:
    rev8 t0h, x0h
    rev8 t0l, x0l
    sw t0h, 0(optr)
    sw t0l, 4(optr)

.LSpermute:
    li t1, PB_START_ROUND
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
    rev8 t0h, x0h
    rev8 t0l, x0l
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
