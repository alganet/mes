/* -*-comment-start: "//";comment-end:""-*-
 * GNU Mes --- Maxwell Equations of Software
 * Copyright © 2024 Ekaitz Zarraga <ekaitz@elenq.tech>
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
 */

// Taken from musl libc, adapted for AArch64

/* AArch64 has 31 general-purpose registers (x0..x30) plus sp.
 * pc, sp, pstate are stored alongside in the kernel's user_regs_struct.
 * NEON/floating-point state is __aarch64_ctx-tagged blobs in __reserved. */

#define REG_X0 0
#define REG_X1 1
#define REG_X29 29
#define REG_LR 30
#define REG_SP 31
#define REG_PC 32

typedef unsigned long __aarch64_mc_gp_state[34]; /* x0..x30, sp, pc, pstate */

typedef struct mcontext_t
{
  unsigned long fault_address;
  __aarch64_mc_gp_state regs;
  /* Followed by __aarch64_ctx-tagged FP/NEON state in __reserved.
   * Not modeled here -- mes doesn't dispatch from a ucontext. */
  unsigned long __reserved[256];
} mcontext_t;

typedef unsigned long greg_t;
typedef unsigned long gregset_t[34];

struct sigcontext
{
  unsigned long fault_address;
  gregset_t gregs;
};

struct sigaltstack
{
  void *ss_sp;
  int ss_flags;
  size_t ss_size;
};

typedef struct __ucontext
{
  unsigned long uc_flags;
  struct __ucontext *uc_link;
  stack_t uc_stack;
  sigset_t uc_sigmask;
  mcontext_t uc_mcontext;
} ucontext_t;
