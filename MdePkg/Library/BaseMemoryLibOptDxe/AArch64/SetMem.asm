/** @file
  Assembler code for memory set and zero operations.

  Copyright (c) 2012 - 2016, Linaro Limited
  All rights reserved.
  Copyright (c) 2015 - 2020, Arm Limited. All rights reserved.<BR>
  SPDX-License-Identifier: BSD-2-Clause-Patent
**/

// Assumptions:
//
// ARMv8-a, AArch64, unaligned accesses
//
//

#define dstin     x0
#define count     x1
#define val       x2
#define valw      w2
#define dst       x3
#define dstend    x4
#define tmp1      x5
#define tmp1w     w5
#define tmp2      x6
#define tmp2w     w6
#define zva_len   x7
#define zva_lenw  w7

#define L(l) L ## l


    AREA    |.text|,ALIGN=5,CODE,READONLY

    EXPORT  InternalMemSetMem16
    EXPORT  InternalMemSetMem32
    EXPORT  InternalMemSetMem64
    EXPORT  InternalMemZeroMem
    EXPORT  InternalMemSetMem

InternalMemSetMem16 PROC
    dup     v0.8H, valw
    lsl     count, count, #1
    b       L(L0)
    ENDP

InternalMemSetMem32 PROC
    dup     v0.4S, valw
    lsl     count, count, #2
    b       L(L0)
    ENDP


InternalMemSetMem64 PROC
    dup     v0.2D, val
    lsl     count, count, #3
    b       L(L0)
    ENDP

InternalMemZeroMem PROC
    movi    v0.16B, #0
    b       L(L0)
    ENDP

InternalMemSetMem PROC
    dup     v0.16B, valw
L(L0)
    add     dstend, dstin, count
    umov    val, v0.D[0]

    cmp     count, 96
    bhi     L(set_long)
    cmp     count, 16
    bhs     L(set_medium)

    // Set 0..15 bytes.
    tbz     count, 3, L(L1)
    str     val, [dstin]
    str     val, [dstend], #-8
    ret
    nop
L(L1)
    tbz     count, 2, L(L2)
    str     valw, [dstin]
    str     valw, [dstend], #-4
    ret
L(L2)
    cbz     count, L(L3)
    strb    valw, [dstin]
    tbz     count, 1, L(L3)
    strh    valw, [dstend], #-2
L(L3)
    ret

    // Set 17..96 bytes.
L(set_medium)
    str     q0, [dstin]
    tbnz    count, 6, L(set96)
    str     q0, [dstend], #-16
    tbz     count, 5, L(L4)
    str     q0, [dstin, #16]
    str     q0, [dstend], #-32
L(L4)
    ret

    ALIGN 16
    // Set 64..96 bytes.  Write 64 bytes from the start and
    // 32 bytes from the end.
L(set96)
    str     q0, [dstin, #16]
    stp     q0, q0, [dstin, #32]
    stp     q0, q0, [dstend, #-32]
    ret

    ALIGN 8
    nop
L(set_long)
    bic     dst, dstin, 15
    str     q0, [dstin]
    cmp     count, 256
    ccmpcs  val, 0, 0
    beq     L(try_zva)

L(no_zva)
    sub     count, dstend, dst        // Count is 16 too large.
    add     dst, dst, 16
    sub     count, count, 64 + 16     // Adjust count and bias for loop.
L(L5)
    stp     q0, q0, [dst], #64
    stp     q0, q0, [dst, #-32]
L(tail64)
    subs    count, count, 64
    bhi     L(L5)

    stp     q0, q0, [dstend, #-64]
    stp     q0, q0, [dstend, #-32]
    ret

    ALIGN 8
L(try_zva)
    mrs     tmp1, dczid_el0
    tbnz    tmp1, 4, L(no_zva)
    and     tmp1w, tmp1w, 15
    cmp     tmp1w, 4                  // ZVA size is 64 bytes.
    bne     L(zva_128)

    // Write the first and last 64 byte aligned block using stp rather
    // than using DC ZVA.  This is faster on some cores.
L(zva_64)
    str     q0, [dst, #16]
    stp     q0, q0, [dst, #32]
    bic     dst, dst, 63
    stp     q0, q0, [dst, #64]
    stp     q0, q0, [dst, #96]
    sub     count, dstend, dst         // Count is now 128 too large.
    sub     count, count, 128+64+64    // Adjust count and bias for loop.
    add     dst, dst, 128
    nop
L(L7)
    dc      zva, dst
    add     dst, dst, 64
    subs    count, count, 64
    bhi     L(L7)
    stp     q0, q0, [dst, #0]
    stp     q0, q0, [dst, #32]
    stp     q0, q0, [dstend, #-64]
    stp     q0, q0, [dstend, #-32]
    ret

    ALIGN 8
L(zva_128)
    cmp     tmp1w, 5                    // ZVA size is 128 bytes.
    bne     L(zva_other)

    str     q0, [dst, #16]
    stp     q0, q0, [dst, #32]
    stp     q0, q0, [dst, #64]
    stp     q0, q0, [dst, #96]
    bic     dst, dst, 127
    sub     count, dstend, dst          // Count is now 128 too large.
    sub     count, count, 128+128       // Adjust count and bias for loop.
    add     dst, dst, 128
L(L8)
    dc      zva, dst
    add     dst, dst, 128
    subs    count, count, 128
    bhi     L(L8)
    stp     q0, q0, [dstend, #-128]
    stp     q0, q0, [dstend, #-96]
    stp     q0, q0, [dstend, #-64]
    stp     q0, q0, [dstend, #-32]
    ret

L(zva_other)
    mov     tmp2w, 4
    lsl     zva_lenw, tmp2w, tmp1w
    add     tmp1, zva_len, 64           // Max alignment bytes written.
    cmp     count, tmp1
    blo     L(no_zva)

    sub     tmp2, zva_len, 1
    add     tmp1, dst, zva_len
    add     dst, dst, 16
    subs    count, tmp1, dst            // Actual alignment bytes to write.
    bic     tmp1, tmp1, tmp2            // Aligned dc zva start address.
    beq     L(L10)
L(L9)
    stp     q0, q0, [dst], #64
    stp     q0, q0, [dst, #-32]
    subs    count, count, 64
    bhi     L(L9)
L(L10)
    mov     dst, tmp1
    sub     count, dstend, tmp1         // Remaining bytes to write.
    subs    count, count, zva_len
    blo     L(L12)
L(L11)
    dc      zva, dst
    add     dst, dst, zva_len
    subs    count, count, zva_len
    bhs     L(L11)
L(L12)
    add     count, count, zva_len
    b       L(tail64)
    ENDP

    END

