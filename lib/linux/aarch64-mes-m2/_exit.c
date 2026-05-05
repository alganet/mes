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
_exit (int status)
{
  /* Load arg `status` from frame pointer (x17) -8 into x0,
   * set syscall number EXIT (93) into x8, trap to kernel via
   * SVC #0. The SET_X0_FROM_BP / SUB_X0_8 / DEREF_X0 idiom is
   * the M2libc/aarch64 convention for "load arg N from stack
   * frame slot fp-(N*8)". */
  asm ("SET_X0_FROM_BP" "SUB_X0_8" "DEREF_X0"
       "SET_X8_TO_SYS_EXIT"
       "SYSCALL");
  // no need to read return value
}
