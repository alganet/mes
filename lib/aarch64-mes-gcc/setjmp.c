/* -*-comment-start: "//";comment-end:""-*-
 * GNU Mes --- Maxwell Equations of Software
 * Copyright © 2017,2018,2019 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
 * Copyright © 2021 W. J. van der Laan <laanwj@protonmail.com>
 * Copyright © 2026 Alexandre Gomes Gaigalas (aarch64 port)
 *
 * This file is part of GNU Mes.
 *
 * GNU Mes is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or (at
 * your option) any later version.
 *
 * GNU Mes is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with GNU Mes.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <setjmp.h>
#include <stdlib.h>

/* Save/restore the AArch64 callee-saved state: x19-x28, x29 (fp),
   x30 (lr) and sp.  Layout (13 longs) must match the __jmp_buf in
   include/setjmp.h.  longjmp returns val, or 1 when val is 0. */

asm (".global __longjmp\n\t"
     ".global _longjmp\n\t"
     ".global longjmp\n\t"
     ".type __longjmp, %function\n\t"
     ".type _longjmp,  %function\n\t"
     ".type longjmp,   %function\n\t"
     "__longjmp:\n\t"
     "_longjmp:\n\t"
     "longjmp:\n\t"
     "ldp x19, x20, [x0, #0]\n\t"
     "ldp x21, x22, [x0, #16]\n\t"
     "ldp x23, x24, [x0, #32]\n\t"
     "ldp x25, x26, [x0, #48]\n\t"
     "ldp x27, x28, [x0, #64]\n\t"
     "ldp x29, x30, [x0, #80]\n\t"
     "ldr x2,       [x0, #96]\n\t"
     "mov sp, x2\n\t"
     "cmp x1, #0\n\t"
     "csinc x0, x1, xzr, ne\n\t"   /* x0 = (val != 0) ? val : 1 */
     "ret\n\t");

asm (".global __setjmp\n\t"
     ".global _setjmp \n\t"
     ".global setjmp\n\t"
     ".type __setjmp, %function\n\t"
     ".type _setjmp,  %function\n\t"
     ".type setjmp,   %function\n\t"
     "__setjmp:\n\t"
     "_setjmp:\n\t"
     "setjmp:\n\t"
     "stp x19, x20, [x0, #0]\n\t"
     "stp x21, x22, [x0, #16]\n\t"
     "stp x23, x24, [x0, #32]\n\t"
     "stp x25, x26, [x0, #48]\n\t"
     "stp x27, x28, [x0, #64]\n\t"
     "stp x29, x30, [x0, #80]\n\t"
     "mov x1, sp\n\t"
     "str x1,       [x0, #96]\n\t"
     "mov x0, #0\n\t"
     "ret\n\t");
