/** @file
  Assembler code for comparing GUIDs.

  Copyright (c) 2016, Linaro Limited
  All rights reserved.
  Copyright (c) 2020, Arm Limited. All rights reserved.<BR>
  SPDX-License-Identifier: BSD-2-Clause-Patent
**/

    AREA    |.text|,ALIGN=5,CODE,READONLY

    EXPORT  InternalMemCompareGuid

InternalMemCompareGuid PROC
    mov     x2, xzr
    ldp     x3, x4, [x0]
    cbz     x1, L0
    ldp     x1, x2, [x1]
L0
    cmp     x1, x3
    ccmpeq  x2, x4, #0
    cseteq  w0
    ret
    ENDP

    END

