/*
 * GNU Mes --- Maxwell Equations of Software
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

/** Code: */

	SYS_exit = 93		/* Linux syscalls.  */
	.globl _start		/* Magic linker symbol: --entry-address.  */

	.text			/* Program text. */
_start:
	mov	x8, SYS_exit	/* System call function: exit, in x8.  */
	mov	x0, #42		/* 1st parameter: exit status, in x0. */
	svc	#0		/* Call system.  */
	brk	#0		/* Should not be reached.  */
