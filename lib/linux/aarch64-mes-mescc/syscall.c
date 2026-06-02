/* -*-comment-start: "//";comment-end:""-*-
 * GNU Mes --- Maxwell Equations of Software
 * Copyright © 2016,2017,2018,2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include <errno.h>
#include <linux/aarch64/syscall.h>

/* aarch64 Linux ABI: x8 = syscall number, x0..x4 = args, SVC #0 = trap,
 * x0 = result.  mescc passes positional args above the frame, so the
 * Nth arg of these wrappers is at [BP + 16 + 8*(N-1)]: sys_call at +16,
 * one at +24, two at +32, three at +40, four at +48, five at +56 -- the
 * same layout riscv64-mes-mescc reads with `rd_aN rs1_fp !off ld`.
 *
 * x0 doubles as the SET_X0_FROM_BP / ADD_X0_<off> / DEREF_X0 scratch,
 * so the arg that lands in x0 (one) is loaded LAST; sys_call and the
 * higher args are captured into x8/x1.. first.  The result is relayed
 * from x0 to x9 (mescc r0 / %retreg) like riscv64's `mv t0, a0`. */

long
__sys_call (long sys_call)
{
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_16");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SYSCALL");
  asm ("SET_X9_FROM_X0");
}

long
__sys_call1 (long sys_call, long one)
{
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_16");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_24");
  asm ("DEREF_X0");
  asm ("SYSCALL");
  asm ("SET_X9_FROM_X0");
}

long
__sys_call2 (long sys_call, long one, long two)
{
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_16");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_32");
  asm ("DEREF_X0");
  asm ("SET_X1_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_24");
  asm ("DEREF_X0");
  asm ("SYSCALL");
  asm ("SET_X9_FROM_X0");
}

long
__sys_call3 (long sys_call, long one, long two, long three)
{
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_16");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_40");
  asm ("DEREF_X0");
  asm ("SET_X2_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_32");
  asm ("DEREF_X0");
  asm ("SET_X1_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_24");
  asm ("DEREF_X0");
  asm ("SYSCALL");
  asm ("SET_X9_FROM_X0");
}

long
__sys_call4 (long sys_call, long one, long two, long three, long four)
{
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_16");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_48");
  asm ("DEREF_X0");
  asm ("SET_X3_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_40");
  asm ("DEREF_X0");
  asm ("SET_X2_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_32");
  asm ("DEREF_X0");
  asm ("SET_X1_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_24");
  asm ("DEREF_X0");
  asm ("SYSCALL");
  asm ("SET_X9_FROM_X0");
}

long
__sys_call5 (long sys_call, long one, long two, long three, long four, long five)
{
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_16");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_56");
  asm ("DEREF_X0");
  asm ("SET_X4_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_48");
  asm ("DEREF_X0");
  asm ("SET_X3_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_40");
  asm ("DEREF_X0");
  asm ("SET_X2_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_32");
  asm ("DEREF_X0");
  asm ("SET_X1_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_24");
  asm ("DEREF_X0");
  asm ("SYSCALL");
  asm ("SET_X9_FROM_X0");
}

long
_sys_call (long sys_call)
{
  long r = __sys_call (sys_call);
  if (r < 0)
    {
      errno = -r;
      r = -1;
    }
  else
    errno = 0;
  return r;
}

long
_sys_call1 (long sys_call, long one)
{
  long r = __sys_call1 (sys_call, one);
  if (r < 0)
    {
      errno = -r;
      r = -1;
    }
  else
    errno = 0;
  return r;
}

long
_sys_call2 (long sys_call, long one, long two)
{
  long r = __sys_call2 (sys_call, one, two);
  if (r < 0)
    {
      errno = -r;
      r = -1;
    }
  else
    errno = 0;
  return r;
}

long
_sys_call3 (long sys_call, long one, long two, long three)
{
  long r = __sys_call3 (sys_call, one, two, three);
  if (r < 0)
    {
      errno = -r;
      r = -1;
    }
  else
    errno = 0;
  return r;
}

long
_sys_call4 (long sys_call, long one, long two, long three, long four)
{
  long r = __sys_call4 (sys_call, one, two, three, four);
  if (r < 0)
    {
      errno = -r;
      r = -1;
    }
  else
    errno = 0;
  return r;
}

long
_sys_call5 (long sys_call, long one, long two, long three, long four, long five)
{
  long r = __sys_call5 (sys_call, one, two, three, four, five);
  if (r < 0)
    {
      errno = -r;
      r = -1;
    }
  else
    errno = 0;
  return r;
}
