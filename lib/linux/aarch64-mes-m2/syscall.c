/* -*-comment-start: "//";comment-end:""-*-
 * GNU Mes --- Maxwell Equations of Software
 * Copyright © 2016,2017,2018,2020,2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

/* aarch64 Linux ABI: x0..x5 = args, x8 = syscall number, SVC #0 = trap.
 * Same convention as riscv64 except for register names and trap mnemonic.
 * M2-Planet's save-frame puts arg N at fp-(N*8):
 *   sys_call -> fp-8, one -> fp-16, two -> fp-24, three -> fp-32,
 *   four     -> fp-40, five -> fp-48.
 *
 * Loading order matters: x0 is the scratch register for the
 * SET_X0_FROM_BP / SUB_X0_N / DEREF_X0 idiom. Once a value lands in
 * its target register (x1..x4 or x8), it survives subsequent loads.
 * So we load:
 *   1. sys_call -> x0 -> SET_X8_FROM_X0           (x8 = syscall #)
 *   2. higher-index args -> x0 -> SET_Xn_FROM_X0  (xN = arg N)
 *   3. arg1 (one) -> x0                           (x0 = arg 1)
 *   4. SVC
 *   5. SET_X16_FROM_X0                            (mes ABI epilogue idiom,
 *                                                  mirrors riscv64's
 *                                                  `mv t0, a0` -- return
 *                                                  value relayed via x16)
 *
 * SET_X8_FROM_X0 is a mes-specific addition to aarch64_defs.M1
 * (M2libc only emits SET_X8_TO_SYS_* constants, never X8 from a
 * runtime register).
 */

long
__sys_call (long sys_call)
{
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_8");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SYSCALL");
  asm ("SET_X16_FROM_X0");
}

long
__sys_call1 (long sys_call, long one)
{
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_8");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_16");
  asm ("DEREF_X0");
  asm ("SYSCALL");
  asm ("SET_X16_FROM_X0");
}

long
__sys_call2 (long sys_call, long one, long two)
{
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_8");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_24");
  asm ("DEREF_X0");
  asm ("SET_X1_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_16");
  asm ("DEREF_X0");
  asm ("SYSCALL");
  asm ("SET_X16_FROM_X0");
}

long
__sys_call3 (long sys_call, long one, long two, long three)
{
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_8");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_32");
  asm ("DEREF_X0");
  asm ("SET_X2_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_24");
  asm ("DEREF_X0");
  asm ("SET_X1_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_16");
  asm ("DEREF_X0");
  asm ("SYSCALL");
  asm ("SET_X16_FROM_X0");
}

long
__sys_call4 (long sys_call, long one, long two, long three, long four)
{
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_8");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_40");
  asm ("DEREF_X0");
  asm ("SET_X3_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_32");
  asm ("DEREF_X0");
  asm ("SET_X2_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_24");
  asm ("DEREF_X0");
  asm ("SET_X1_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_16");
  asm ("DEREF_X0");
  asm ("SYSCALL");
  asm ("SET_X16_FROM_X0");
}

long
__sys_call5 (long sys_call, long one, long two, long three, long four, long five)
{
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_8");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_48");
  asm ("DEREF_X0");
  asm ("SET_X4_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_40");
  asm ("DEREF_X0");
  asm ("SET_X3_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_32");
  asm ("DEREF_X0");
  asm ("SET_X2_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_24");
  asm ("DEREF_X0");
  asm ("SET_X1_FROM_X0");
  asm ("SET_X0_FROM_BP");
  asm ("SUB_X0_16");
  asm ("DEREF_X0");
  asm ("SYSCALL");
  asm ("SET_X16_FROM_X0");
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
