/* -*-comment-start: "//";comment-end:""-*-
 * GNU Mes --- Maxwell Equations of Software
 * Copyright © 2016,2017,2018 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include <errno.h>
#include <linux/aarch64/syscall.h>

/* AArch64 Linux syscall ABI: x8 = syscall number, x0..x5 = arguments,
   `svc #0`, result in x0.  Mirrors riscv64-mes-gcc/syscall.c. */
// *INDENT-OFF*
long
__sys_call (long sys_call)
{
  register long __x8 asm ("x8") = sys_call;
  register long __x0 asm ("x0");
  asm volatile (
       "svc #0\n\t"
       : "=r" (__x0)
       : "r" (__x8)
       );
  return __x0;
}

long
__sys_call1 (long sys_call, long one)
{
  register long __x8 asm ("x8") = sys_call;
  register long __x0 asm ("x0") = one;
  asm volatile (
       "svc #0\n\t"
       : "+r" (__x0)
       : "r" (__x8)
       );
  return __x0;
}

long
__sys_call2 (long sys_call, long one, long two)
{
  register long __x8 asm ("x8") = sys_call;
  register long __x0 asm ("x0") = one;
  register long __x1 asm ("x1") = two;
  asm volatile (
       "svc #0\n\t"
       : "+r" (__x0)
       : "r" (__x8), "r" (__x1)
       );
  return __x0;
}

long
__sys_call3 (long sys_call, long one, long two, long three)
{
  register long __x8 asm ("x8") = sys_call;
  register long __x0 asm ("x0") = one;
  register long __x1 asm ("x1") = two;
  register long __x2 asm ("x2") = three;
  asm volatile (
       "svc #0\n\t"
       : "+r" (__x0)
       : "r" (__x8), "r" (__x1), "r" (__x2)
       );
  return __x0;
}

long
__sys_call4 (long sys_call, long one, long two, long three, long four)
{
  register long __x8 asm ("x8") = sys_call;
  register long __x0 asm ("x0") = one;
  register long __x1 asm ("x1") = two;
  register long __x2 asm ("x2") = three;
  register long __x3 asm ("x3") = four;
  asm volatile (
       "svc #0\n\t"
       : "+r" (__x0)
       : "r" (__x8), "r" (__x1), "r" (__x2), "r" (__x3)
       );
  return __x0;
}

long
__sys_call5 (long sys_call, long one, long two, long three, long four, long five)
{
  register long __x8 asm ("x8") = sys_call;
  register long __x0 asm ("x0") = one;
  register long __x1 asm ("x1") = two;
  register long __x2 asm ("x2") = three;
  register long __x3 asm ("x3") = four;
  register long __x4 asm ("x4") = five;
  asm volatile (
       "svc #0\n\t"
       : "+r" (__x0)
       : "r" (__x8), "r" (__x1), "r" (__x2), "r" (__x3), "r" (__x4)
       );
  return __x0;
}
// *INDENT-ON*

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
