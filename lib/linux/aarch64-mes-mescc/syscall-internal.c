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

/* Like syscall.c but private to __raise, so signal delivery does not
 * clobber the public errno path.  See syscall.c for the arg layout. */

static long
__sys_call_internal (long sys_call)
{
  asm ("SET_X0_FROM_BP");
  asm ("ADD_X0_16");
  asm ("DEREF_X0");
  asm ("SET_X8_FROM_X0");
  asm ("SYSCALL");
  asm ("SET_X9_FROM_X0");
}

static long
__sys_call2_internal (long sys_call, long one, long two)
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

/* Return < 0 on error (errno-like value from kernel), or 0 on success */
int
__raise (int signum)
{
  long pid = __sys_call_internal (SYS_getpid);
  if (pid < 0)
    return pid;
  else
    return __sys_call2_internal (SYS_kill, pid, signum);
}
