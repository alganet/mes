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

;;; ====================================================================
;;; aarch64 backend for mescc -- INITIAL SCAFFOLD, not yet functional.
;;; ====================================================================
;;;
;;; This module declares the aarch64 instructions alist that mescc's
;;; code generator will consult for IR -> machine-code emission. The
;;; M2-Planet path (see lib/linux/aarch64-mes-m2/) is the production
;;; route for building mes-on-aarch64 today; this file exists for
;;; future mescc-native (Scheme-driven) compilation.
;;;
;;; Status: Module structure + simplest helpers (push/pop, frame
;;; setup, ret, label addressing) are translated to aarch64
;;; conventions. More complex helpers (arithmetic, comparisons,
;;; type conversions, byte/word mem ops) emit RV64-style mnemonics
;;; as placeholders -- they will need re-translation to aarch64
;;; M2libc macros (SET_X0_FROM_BP etc.) before this backend can
;;; produce running aarch64 binaries.
;;;
;;; Translation plan for outstanding ops:
;;;   1. lib/aarch64-mes/aarch64.M1 currently a stub. To support the
;;;      generic patterns this file emits, it needs PUSH_X9..PUSH_X14,
;;;      POP_X9..POP_X14, and parameterized arithmetic macros.
;;;   2. Each helper below that mentions "RV64 placeholder" needs to
;;;      be rewritten to use M2libc/aarch64 macros (the same vocabulary
;;;      M2-Planet's aarch64 backend in cc_emit.c emits).
;;;   3. Validation: mes's `make check` test suite under
;;;      ARCH=aarch64; passing is the gate.
;;;
;;; Why this stub exists despite being incomplete:
;;;   The user (alganet) explicitly chose to include the mescc native
;;;   backend in the aarch64 mes port for upstream-PR completeness,
;;;   even though abuild's bootstrap chain uses only the M2-Planet
;;;   path. This file establishes the module name and exports so that
;;;   downstream code referencing (mescc aarch64 as) doesn't fail at
;;;   import time; the actual code-emission logic is a follow-up.

;;; Code:

(define-module (mescc aarch64 as)
  #:use-module (mes guile)
  #:use-module (mescc as)
  #:use-module (mescc info)
  #:use-module (mescc aarch64 info)
  #:export (
            aarch64:instructions
            ))

;;; Reserved temporary intermediate registers.
;;; aarch64 ABI: x9..x15 are caller-saved scratch; mescc uses
;;; x9..x14 as IR temporaries (see info.scm), x15 reserved here for
;;; mescc-internal scratch in code emission.
(define %tmpreg1 "x15")
(define %tmpreg2 "x16")              ; intra-procedure-call scratch

;;; Registers for return values and condition flag emulation.
(define %retreg "x9")
(define %zero "xzr")

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
;;; this matches the M2libc pattern; other registers need their own
;;; LOAD_W<R>_AHEAD macros (currently only X0,X1,X2,X13,X14,X15,X16
;;; are defined in M2libc/aarch64/aarch64_defs.M1).
(define (aarch64:label_address r label)
  `((,(string-append "LOAD_W" (substring r 1) "_AHEAD"))
    ("SKIP_32_DATA")
    ((#:absolute-address ,label))))

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
  `(("ADD_X0_X1_X0_TODO_aarch64_r0_minus_r1")))

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
