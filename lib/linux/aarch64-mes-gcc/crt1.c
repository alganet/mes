/* -*-comment-start: "//";comment-end:""-*-
 * GNU Mes --- Maxwell Equations of Software
 * Copyright © 2017,2018,2019,2020,2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include <mes/lib-mini.h>
int main (int argc, char *argv[], char *envp[]);

/* GCC emits no prologue for this asm-only, C-local-free _start, so on
   entry `sp` still points at the kernel-supplied stack: [sp] = argc,
   sp+8 = &argv[0], argv[argc] = NULL, then envp[].  We capture the entry
   sp into a scratch register as the very first instruction (before any
   push), compute argc/argv/envp, then set up the calls.  envp = &argv[0]
   + (argc + 1) * 8.  (cf. the arm-mes-gcc/crt1.c approach, which reads
   the incoming frame the same way.) */

// *INDENT-OFF*
void
_start ()
{
  asm (
       "mov  x9, sp\n\t"             /* x9 = entry sp (MUST be first)    */
       "ldr  x0, [x9]\n\t"           /* x0 = argc                        */
       "add  x1, x9, #8\n\t"         /* x1 = &argv[0]                    */
       "add  x2, x0, #1\n\t"         /* x2 = argc + 1                    */
       "lsl  x2, x2, #3\n\t"         /* x2 = (argc + 1) * 8              */
       "add  x2, x2, x1\n\t"         /* x2 = envp = &argv[0] + above     */
       "stp  x1, x2, [sp, #-16]!\n\t"/* save argv, envp                  */
       "str  x0, [sp, #-16]!\n\t"    /* save argc (keep sp 16-aligned)   */
       "bl   __init_io\n\t"          /* __init_io (argc, argv, envp)     */
       "ldr  x0, [sp]\n\t"           /* reload argc (clobbered by call)  */
       "ldp  x1, x2, [sp, #16]\n\t"  /* reload argv, envp                */
       "bl   main\n\t"              /* main (argc, argv, envp)          */
       "mov  x8, #93\n\t"            /* SYS_exit                         */
       "svc  #0\n\t"                 /* exit (return value from main)    */
       "brk  #0\n\t"                 /* not reached                      */
       );
}
