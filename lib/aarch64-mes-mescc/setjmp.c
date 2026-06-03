/* -*-comment-start: "//";comment-end:""-*-
 * GNU Mes --- Maxwell Equations of Software
 * Copyright © 2017,2018,2019 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include <setjmp.h>
#include <stdlib.h>

void
longjmp (jmp_buf env, int val)
{
  val = val == 0 ? 1 : val;
  /* env is arg1 at [BP+16], val is arg2 at [BP+24]; the jmp_buf fields
     are __bp (offset 0), __pc (offset 8), __sp (offset 16).  Put the
     return value in x9 (mescc r0 / %retreg) so setjmp appears to return
     val, then restore BP and SP and branch to the saved __pc.  x9 is
     loaded first and never touched again, so it survives to the jump. */
  asm ("SET_X0_FROM_BP");       // x0 = BP (scratch)
  asm ("ADD_X0_24");
  asm ("DEREF_X0");
  asm ("SET_X9_FROM_X0");       // x9 = val (mescc r0 / %retreg)
  asm ("SET_X0_FROM_BP");       // x0 = BP (scratch for loading env)
  asm ("ADD_X0_16");
  asm ("DEREF_X0");
  asm ("SET_BP_FROM_X0");
  asm ("SET_X0_FROM_BP");       // x0 = env (scratch)
  asm ("ADD_X0_8");
  asm ("DEREF_X0");
  asm ("SET_X16_FROM_X0");      // x16 = env.__pc (jump target)
  asm ("SET_X0_FROM_BP");       // x0 = env (scratch for loading __sp)
  asm ("ADD_X0_16");
  asm ("DEREF_X0");
  asm ("SET_SP_FROM_X0");       // SP = env.__sp
  asm ("SET_X0_FROM_BP");       // x0 = env (scratch for loading __bp)
  asm ("DEREF_X0");
  asm ("SET_BP_FROM_X0");
  asm ("BR_X16");
  // not reached
  exit (42);
}

int
setjmp (__jmp_buf * env)
{
  long *p = (long *) &env;
  env[0].__bp = p[-2];
  env[0].__pc = p[-1];
  env[0].__sp = (long) &env;
  return 0;
}
