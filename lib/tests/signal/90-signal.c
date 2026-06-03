/* -*-comment-start: "//";comment-end:""-*-
 * GNU Mes --- Maxwell Equations of Software
 * Copyright © 2018 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include <mes/lib.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>

int g_alarm_handled_p = 0;

void
handler (int signum)
{
#if __MESC__ && __x86_64__
  asm ("mov____%rdi,0x8(%rbp) !0x10");  // FIXME: AMDCC
#endif
#if __MESC__ && __aarch64__
  // The kernel passes signum in x0, but mescc reads the first argument
  // from the stack slot at [BP+16].  Stash x0 there before it is read.
  asm ("SET_X16_FROM_X0");      // x16 = signum (save across the BP math)
  asm ("SET_X0_FROM_BP");       // x0 = BP
  asm ("ADD_X0_16");            // x0 = &arg0 = BP + 16
  asm ("SET_X1_FROM_X0");       // x1 = &arg0
  asm ("SET_X0_FROM_X16");      // x0 = signum
  asm ("STR_X0_[X1]");          // arg0 = signum
#endif
  eputs ("handle:");
  eputs (itoa (signum));
  eputs ("\n");
  if (signum != SIGALRM)
    exit (66);
  g_alarm_handled_p = 1;
#if __x86_64__
  exit (0);
#endif
}

int
main (void)
{
  eputs ("pid_t=");
  eputs (itoa (sizeof (pid_t)));
  eputs ("\n");
  signal (SIGALRM, handler);
  kill (getpid (), SIGALRM);
  if (!g_alarm_handled_p)
    return 2;
  return 0;
}
