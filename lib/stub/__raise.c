/* -*-comment-start: "//";comment-end:""-*-
 * GNU Mes --- Maxwell Equations of Software
 * Copyright © 2020,2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#ifndef __raise

#if __M2__

/* The M2-Planet bootstrap build compiles this file without kill()/getpid()
 * in its translation unit, so reference them here would abort the build
 * ("kill is not a defined symbol").  Keep the historical stub for M2; the
 * seed interpreter does not rely on real signal delivery. */
int
__raise (int signum)
{
  return -1;
}

#else

#include <signal.h>
#include <unistd.h>

/* Deliver the signal for real (cf. lib/posix/raise.c's raise()).  abort()
 * calls __raise(SIGABRT) and, if it returns < 0, deliberately crashes via a
 * NULL dereference ("fail in any way possible", see src/posix.c).  Returning
 * -1 unconditionally meant every abort() -- e.g. an unhandled Scheme
 * exception's (abort) -- died with SIGSEGV instead of SIGABRT, masking the
 * already-printed error message behind a segfault.  kill()/getpid() are real
 * in the mescc/gcc mes libc; builds without syscalls use the __raise(x) -1
 * macro in include/mes/lib-cc.h instead of this function. */
int
__raise (int signum)
{
  return kill (getpid (), signum);
}

#endif

#endif
