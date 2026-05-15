;;; GNU Mes --- Maxwell Equations of Software
;;; Copyright © 2018 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 W. J. van der Laan <laanwj@protonmail.com>
;;; Copyright © 2023 Andrius Štikonas <andrius@stikonas.eu>
;;; Copyright © 2026 Alexandre Gomes Gaigalas (aarch64 port, scaffold)
;;;
;;; This file is part of GNU Mes.
;;;
;;; GNU Mes is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Mes is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Mes.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;;
;;; INCOMPLETE: aarch64 backend scaffold for mescc. The production aarch64
;;; mes build uses the M2-Planet path in lib/linux/aarch64-mes-m2/; this
;;; module exists so `(mescc aarch64 as)` resolves on import. The AARCH64_TODO_*
;;; sentinels below mark code-emission helpers that still need to be
;;; rewritten from their riscv64-derived placeholders into proper
;;; aarch64 M2libc macros.

;;; Code:

(define-module (mescc aarch64 as)
  #:use-module (mes guile)
  #:use-module (mescc as)
  #:use-module (mescc info)
  #:use-module (mescc aarch64 info)
  #:export (
            aarch64:instructions
            ))

;;; ----------------------------------------------------------------
;;; Translated helpers (functional)
;;; ----------------------------------------------------------------

;;; push register onto x18-stack (M2libc convention)
(define (aarch64:push r)
  (string-append "PUSH_" (string-upcase r)))

;;; pop register from x18-stack
(define (aarch64:pop r)
  (string-append "POP_" (string-upcase r)))

;;; function preamble: save lr (x30), fp (x29) onto x18-stack,
;;; set fp to top-of-frame
(define (aarch64:function-preamble info . rest)
  `(("PUSH_LR")
    ("PUSH_BP")
    ("SET_BP_FROM_SP")))

;;; allocate function locals: 8*1024 buf + 20 local vars * 8 bytes
;;; aarch64 has no addi-large; needs add x18, x18, #-imm via multiple
;;; SUB_X18_imm steps OR ADD_X18_NEG via a temp register. For now
;;; emit a placeholder that needs imm-large support added.
(define (aarch64:function-locals . rest)
  `(("AARCH64_TODO_function_locals_alloc_8392")))

;;; immediate value to register
(define (aarch64:value->r info v)
  (or v (error "invalid value: aarch64:value->r: " v))
  (let ((r (get-r info)))
    `((,(string-append "AARCH64_TODO_li_" r "_" (number->string v))))))

(define (aarch64:value->r0 info v)
  (let ((r0 (get-r0 info)))
    `((,(string-append "AARCH64_TODO_li_" r0 "_" (number->string v))))))

;;; function epilogue: restore fp/lr, ret
(define (aarch64:ret . rest)
  `(("SET_SP_FROM_BP")
    (,(aarch64:pop "BP"))
    (,(aarch64:pop "LR"))
    ("RETURN")))

;;; label address into register (uses LOAD_W<R>_AHEAD + SKIP_32_DATA
;;; + &label, then sign-extension if needed). For x16 specifically
;;; this matches the M2libc pattern; LOAD_W<R>_AHEAD macros are
;;; defined for X0,X1,X2,X9..X16 in lib/m2/aarch64/aarch64_defs.M1
;;; -- which covers the x9..x14 IR temporaries declared in
;;; aarch64:registers (info.scm).
(define (aarch64:label_address r label)
  `((,(string-append "LOAD_W" (substring r 1) "_AHEAD"))
    ("SKIP_32_DATA")
    ((#:address ,label))))

(define (aarch64:label->r info label)
  (let ((r (get-r info)))
    `(,(aarch64:label_address r label))))

;;; ----------------------------------------------------------------
;;; PLACEHOLDER helpers (need translation to aarch64 macros)
;;; ----------------------------------------------------------------
;;; Each function below currently emits a TODO sentinel. A real
;;; aarch64 implementation would translate the RV64 sequence into
;;; the appropriate M2libc/aarch64 macro chain.

(define (aarch64:local->r info n)
  `(("AARCH64_TODO_local_to_r")))

(define (aarch64:call-label info label n)
  `(("AARCH64_TODO_call_label")))

(define (aarch64:call-r info n)
  `(("AARCH64_TODO_call_r")))

(define (aarch64:r->arg info i)
  `(("AARCH64_TODO_r_to_arg")))

(define (aarch64:label->arg info label i)
  `(("AARCH64_TODO_label_to_arg")))

(define (aarch64:r0+r1 info)
  `(("AARCH64_TODO_r0_plus_r1")))

(define (aarch64:r0-r1 info)
  `(("AARCH64_TODO_r0_minus_r1")))

(define (aarch64:r0+value info v)
  `(("AARCH64_TODO_r0_plus_value")))

(define (aarch64:r-byte-mem-add info v)
  `(("AARCH64_TODO_r_byte_mem_add")))

(define (aarch64:r-word-mem-add info v)
  `(("AARCH64_TODO_r_word_mem_add")))

(define (aarch64:r-long-mem-add info v)
  `(("AARCH64_TODO_r_long_mem_add")))

(define (aarch64:r-mem-add info v)
  `(("AARCH64_TODO_r_mem_add")))

(define (aarch64:local-ptr->r info n)
  `(("AARCH64_TODO_local_ptr_to_r")))

(define (aarch64:r0->r1 info)
  `(("AARCH64_TODO_r0_to_r1")))

(define (aarch64:r1->r0 info)
  `(("AARCH64_TODO_r1_to_r0")))

(define (aarch64:byte-r info)
  `(("AARCH64_TODO_byte_r")))

(define (aarch64:byte-signed-r info)
  `(("AARCH64_TODO_byte_signed_r")))

(define (aarch64:word-r info)
  `(("AARCH64_TODO_word_r")))

(define (aarch64:word-signed-r info)
  `(("AARCH64_TODO_word_signed_r")))

(define (aarch64:long-r info)
  `(("AARCH64_TODO_long_r")))

(define (aarch64:long-signed-r info)
  `(("AARCH64_TODO_long_signed_r")))

(define (aarch64:jump info label)
  `(("AARCH64_TODO_jump")))

(define (aarch64:r-zero? info)
  `(("AARCH64_TODO_r_zero?")))

(define (aarch64:test-r info)
  `(("AARCH64_TODO_test_r")))

(define (aarch64:xor-zf info)
  `(("AARCH64_TODO_xor_zf")))

(define (aarch64:r-cmp-value info v)
  `(("AARCH64_TODO_r_cmp_value")))

(define (aarch64:r0-cmp-r1 info)
  `(("AARCH64_TODO_r0_cmp_r1")))

(define (aarch64:jump-nz info label)
  `(("AARCH64_TODO_jump_nz")))

(define (aarch64:jump-z info label)
  `(("AARCH64_TODO_jump_z")))

(define (aarch64:jump-byte-z info label)
  `(("AARCH64_TODO_jump_byte_z")))

(define (aarch64:zf->r info)
  `(("AARCH64_TODO_zf_to_r")))

(define (aarch64:r-negate info)
  `(("AARCH64_TODO_r_negate")))

;;; ----------------------------------------------------------------
;;; Instruction alist (mescc dispatches IR ops through this table).
;;; ----------------------------------------------------------------
;;; The keys come from mescc's IR; values are the aarch64-emit
;;; helpers above. As helpers are completed, they're plugged in
;;; here. The set of keys mirrors riscv64:instructions; see
;;; module/mescc/riscv64/as.scm for the canonical list.
(define aarch64:instructions
  `((function-preamble . ,aarch64:function-preamble)
    (function-locals . ,aarch64:function-locals)
    (push . ,aarch64:push)
    (pop . ,aarch64:pop)
    (ret . ,aarch64:ret)
    (value->r . ,aarch64:value->r)
    (value->r0 . ,aarch64:value->r0)
    (label->r . ,aarch64:label->r)
    (local->r . ,aarch64:local->r)
    (call-label . ,aarch64:call-label)
    (call-r . ,aarch64:call-r)
    (r->arg . ,aarch64:r->arg)
    (label->arg . ,aarch64:label->arg)
    (r0+r1 . ,aarch64:r0+r1)
    (r0-r1 . ,aarch64:r0-r1)
    (r0+value . ,aarch64:r0+value)
    (r-byte-mem-add . ,aarch64:r-byte-mem-add)
    (r-word-mem-add . ,aarch64:r-word-mem-add)
    (r-long-mem-add . ,aarch64:r-long-mem-add)
    (r-mem-add . ,aarch64:r-mem-add)
    (local-ptr->r . ,aarch64:local-ptr->r)
    (r0->r1 . ,aarch64:r0->r1)
    (r1->r0 . ,aarch64:r1->r0)
    (byte-r . ,aarch64:byte-r)
    (byte-signed-r . ,aarch64:byte-signed-r)
    (word-r . ,aarch64:word-r)
    (word-signed-r . ,aarch64:word-signed-r)
    (long-r . ,aarch64:long-r)
    (long-signed-r . ,aarch64:long-signed-r)
    (jump . ,aarch64:jump)
    (r-zero? . ,aarch64:r-zero?)
    (test-r . ,aarch64:test-r)
    (xor-zf . ,aarch64:xor-zf)
    (r-cmp-value . ,aarch64:r-cmp-value)
    (r0-cmp-r1 . ,aarch64:r0-cmp-r1)
    (jump-nz . ,aarch64:jump-nz)
    (jump-z . ,aarch64:jump-z)
    (jump-byte-z . ,aarch64:jump-byte-z)
    (zf->r . ,aarch64:zf->r)
    (r-negate . ,aarch64:r-negate)))
