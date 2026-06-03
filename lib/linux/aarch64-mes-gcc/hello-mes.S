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

	SYS_exit  = 93		/* Linux syscalls.  */
	SYS_write = 64
	stdout    = 1		/* File descriptor */
	.globl _start		/* Magic linker symbol: --entry-address.  */

	.text			/* Program text. */
hello:	.ascii	"Hello, GNU Mes!\n"
bye:
	.equ string_size, (bye - hello)

_start:
	mov	x8, SYS_write	/* System call function: write, in x8.  */
	mov	x0, stdout	/* 1st parameter: file descriptor, in x0. */
	adr	x1, hello	/* 2nd parameter: PC-relative address, in x1. */
	mov	x2, string_size	/* 3rd parameter: byte count, in x2. */
	svc	#0		/* Call system.  */

	mov	x8, SYS_exit	/* System call function: exit, in x8.  */
	mov	x0, #0		/* 1st parameter: exit status, in x0. */
	svc	#0		/* Call system.  */
	brk	#0		/* Should not be reached.  */
