/* -*-comment-start: "//";comment-end:""-*-
 * GNU Mes --- Maxwell Equations of Software
 * Copyright © 2018,2020,2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
 * Copyright © 2021 W. J. van der Laan <laanwj@protonmail.com>
 * Copyright © 2023 Andrius Štikonas <andrius@stikonas.eu>
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

#include "mes/lib-mini.h"

void
_write (int filedes, void const *buffer, size_t size)
{
  /* aarch64 Linux ABI: arg1=x0, arg2=x1, arg3=x2, syscall_num=x8.
   * Args are stored at fp-8, fp-16, fp-24 by M2-Planet's save-frame.
   * Load LATER args first so x0 doesn't get clobbered before its
   * value is captured.
   *
   *   arg3 (size)    fp-24 -> x2
   *   arg2 (buffer)  fp-16 -> x1
   *   arg1 (filedes) fp-8  -> x0
   */
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_24");
  asm ("DEREF_X0");
  asm ("SET_X2_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_16");
  asm ("DEREF_X0");
  asm ("SET_X1_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_8");
  asm ("DEREF_X0");
  asm ("SET_X8_TO_SYS_WRITE");
  asm ("SYSCALL");
}
