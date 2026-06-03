;;; GNU Mes --- Maxwell Equations of Software
;;; Copyright © 2018 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 W. J. van der Laan <laanwj@protonmail.com>
;;; Copyright © 2023 Andrius Štikonas <andrius@stikonas.eu>
;;; Copyright © 2026 Alexandre Gomes Gaigalas (aarch64 port)
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
;;; Define aarch64 M1 assembly for mescc.
;;;
;;; Unlike riscv64 -- whose mescc-tools M1 mode assembles compositional
;;; "rd_t0 rs1_t0 rs2_t5 add" tokens for any register -- the aarch64 M1
;;; vocabulary (lib/aarch64-mes/aarch64.M1, shared with the M2-Planet
;;; path) is a set of *fixed* full-word instruction macros geared to the
;;; x0/x1 eval-stack convention.  Rather than explode that file into the
;;; x9..x16 register cross-product, the register-parametric instructions
;;; here are encoded directly in Scheme (aarch64:enc-*) and emitted as
;;; raw little-endian quoted-hex words via aarch64:w->line -- the same
;;; representation aarch64:le64-bytes already proved valid for the
;;; literal pool.  Each encoder's base word is verified against a known
;;; macro in aarch64.M1 (e.g. enc-add vs ADD_X0_X14_X0 = c001008b).
;;;
;;; Register partition (see module/mescc/aarch64/info.scm): IR temps
;;; x9..x13; condregx=x14, condregy=x15 (flag emulation, never used as
;;; transient scratch); x16 scratch; x17 BP; x18 SP; %retreg=x9.

;;; Code:

(define-module (mescc aarch64 as)
  #:use-module (mes guile)
  #:use-module (mescc as)
  #:use-module (mescc info)
  #:use-module (mescc aarch64 info)
  #:export (
            aarch64:instructions
            ))

;;; condition-flag emulation registers (cf. riscv64 s10/s11)
(define %condregx "x14")
(define %condregy "x15")
;;; transient scratch (literal-pool temp, computed addresses, trampoline)
(define %scratch "x16")
;;; return register: mescc r0 lives in the first IR register
(define %retreg "x9")

;;; aarch64 condition codes (the 4-bit cond field of B.cond / CSINC)
(define cc-eq 0) (define cc-ne 1)
(define cc-hs 2) (define cc-lo 3)
(define cc-hi 8) (define cc-ls 9)
(define cc-ge 10) (define cc-lt 11)
(define cc-gt 12) (define cc-le 13)

;;; ----------------------------------------------------------------
;;; Instruction encoders.  Each returns a 32-bit instruction word; the
;;; base constants are cross-checked against fixed macros in aarch64.M1.
;;; ----------------------------------------------------------------

;;; register name ("x9", "x17") -> register number
(define (aarch64:rn r) (string->number (substring r 1)))

;;; a 32-bit word -> one M1 line: four little-endian quoted-hex byte
;;; tokens (e.g. '8b' '00' '01' 'c0').  Strings, so line->M1 accepts it.
(define (aarch64:w->line w)
  (let ((u (logand w #xffffffff)))
    (map (lambda (sh)
           (let ((b (logand (ash u sh) #xff)))
             (string-append "'" (if (< b 16) "0" "") (number->string b 16) "'")))
         '(0 -8 -16 -24))))

;;; convenience: encoder word -> wrapped as a single-line list
(define (aarch64:insn w) (list (aarch64:w->line w)))

;;; mov xd, xm           (orr xd, xzr, xm)  cf. SET_X1_FROM_X0 = e10300aa
(define (aarch64:enc-mov rd rm)
  (logior #xaa0003e0 (ash (aarch64:rn rm) 16) (aarch64:rn rd)))
;;; add xd, xn, xm                          cf. ADD_X0_X14_X0 = c001008b
(define (aarch64:enc-add rd rn rm)
  (logior #x8b000000 (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
;;; sub xd, xn, xm                          cf. SUB_X0_X0_X14 = 00000ecb
(define (aarch64:enc-sub rd rn rm)
  (logior #xcb000000 (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
;;; add xd, xn, #imm12                      cf. ADD_X1_SP_8 = 41220091
(define (aarch64:enc-addimm rd rn imm)
  (logior #x91000000 (ash (logand imm #xfff) 10) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
;;; sub xd, xn, #imm12                      cf. SUB_X0_8 = 002000d1
(define (aarch64:enc-subimm rd rn imm)
  (logior #xd1000000 (ash (logand imm #xfff) 10) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
;;; ldr xt, [xn]                            cf. DEREF_X0 = 000040f9
(define (aarch64:enc-ldr rt rn)
  (logior #xf9400000 (ash (aarch64:rn rn) 5) (aarch64:rn rt)))
;;; str xt, [xn]                            cf. STR_X0_[X1] = 200000f9
(define (aarch64:enc-str rt rn)
  (logior #xf9000000 (ash (aarch64:rn rn) 5) (aarch64:rn rt)))
;;; sized loads (zero-extend) and stores; bases cf. macros in aarch64.M1
(define (aarch64:enc-ldrb rt rn)  ; ldrb wt,[xn]   cf. DEREF_X0_BYTE = 00004039
  (logior #x39400000 (ash (aarch64:rn rn) 5) (aarch64:rn rt)))
(define (aarch64:enc-ldrh rt rn)  ; ldrh wt,[xn]   cf. LDRH_W0_[X0] = 00004079
  (logior #x79400000 (ash (aarch64:rn rn) 5) (aarch64:rn rt)))
(define (aarch64:enc-ldrw rt rn)  ; ldr wt,[xn]    cf. LDR_W0_[X0] = 000040b9
  (logior #xb9400000 (ash (aarch64:rn rn) 5) (aarch64:rn rt)))
(define (aarch64:enc-strb rt rn)  ; strb wt,[xn]   cf. STR_BYTE_W0_[X1] = 20000039
  (logior #x39000000 (ash (aarch64:rn rn) 5) (aarch64:rn rt)))
(define (aarch64:enc-strh rt rn)  ; strh wt,[xn]   cf. STRH_W0_[X1] = 20000079
  (logior #x79000000 (ash (aarch64:rn rn) 5) (aarch64:rn rt)))
(define (aarch64:enc-strw rt rn)  ; str wt,[xn]    cf. STR_W0_[X1] = 200000b9
  (logior #xb9000000 (ash (aarch64:rn rn) 5) (aarch64:rn rt)))
;;; bitwise reg-reg                         cf. AND_X0_X1_X0 = 2000008a etc.
(define (aarch64:enc-and rd rn rm)
  (logior #x8a000000 (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
(define (aarch64:enc-orr rd rn rm)
  (logior #xaa000000 (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
(define (aarch64:enc-eor rd rn rm)
  (logior #xca000000 (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
;;; mvn xd, xm           (orn xd, xzr, xm)  cf. MVN_X0 = e00320aa
(define (aarch64:enc-mvn rd rm)
  (logior #xaa2003e0 (ash (aarch64:rn rm) 16) (aarch64:rn rd)))
;;; mul xd, xn, xm       (madd ...,xzr)     cf. MUL_X0_X1_X0 = 207c009b
(define (aarch64:enc-mul rd rn rm)
  (logior #x9b007c00 (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
;;; msub xd, xn, xm, xa                     cf. MSUB_X0_X0_X2_X1 = 0084029b
(define (aarch64:enc-msub rd rn rm ra)
  (logior #x9b008000 (ash (aarch64:rn rm) 16) (ash (aarch64:rn ra) 10)
          (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
;;; sdiv / udiv xd, xn, xm                  cf. SDIV_X0_X1_X0 = 200cc09a
(define (aarch64:enc-sdiv rd rn rm)
  (logior #x9ac00c00 (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
(define (aarch64:enc-udiv rd rn rm)
  (logior #x9ac00800 (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
;;; shifts xd := xn <op> xm                 cf. LSHIFT_X0_X1_X0 = 2020c09a
(define (aarch64:enc-lsl rd rn rm)
  (logior #x9ac02000 (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
(define (aarch64:enc-lsr rd rn rm)  ; logical    cf. LOGICAL_RSHIFT_X0_X1_X0 = 2024c09a
  (logior #x9ac02400 (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
(define (aarch64:enc-asr rd rn rm)  ; arithmetic cf. ARITH_RSHIFT_X0_X1_X0 = 2028c09a
  (logior #x9ac02800 (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5) (aarch64:rn rd)))
;;; cmp xn, xm           (subs xzr,xn,xm)   cf. CMP_X1_X0 = 3f0000eb
(define (aarch64:enc-cmp rn rm)
  (logior #xeb00001f (ash (aarch64:rn rm) 16) (ash (aarch64:rn rn) 5)))
;;; cset xd, cc          (csinc xd,xzr,xzr,!cc); base verified by the
;;; 12-* / 17-* compare tests.  invert(cc) = cc xor 1 for the
;;; standard condition pairs (eq/ne, ge/lt, hi/ls, hs/lo, gt/le).
;;; NB: the condition arg is named `cc`, not `cond` -- a parameter named
;;; `cond` shadows the cond macro and crashes the mes interpreter when
;;; mescc is self-hosted (the other backends avoid it too).
(define (aarch64:enc-cset rd cc)
  (logior #x9a9f07e0 (ash (logxor cc 1) 12) (aarch64:rn rd)))
;;; b.cond #(ahead instructions)            cf. SKIP_INST_NE = 41000054 (ahead=2)
(define (aarch64:enc-bcond cc ahead)
  (logior #x54000000 (ash (logand ahead #x7ffff) 5) cc))
;;; blr xn / br xn                          cf. BLR_X16 = 00023fd6, BR_X16 = 00021fd6
(define (aarch64:enc-blr rn) (logior #xd63f0000 (ash (aarch64:rn rn) 5)))
(define (aarch64:enc-br rn)  (logior #xd61f0000 (ash (aarch64:rn rn) 5)))

;;; ----------------------------------------------------------------
;;; Small building blocks
;;; ----------------------------------------------------------------

;;; the 8 little-endian byte tokens of a 64-bit value, as M1 quoted-hex
;;; data.  The 64-bit mask gives two's-complement for negatives.
(define (aarch64:le64-bytes v)
  ;; mescc has no float backend; a floating C constant (e.g. ceil.c's
  ;; `number + 0.9999`) can still reach an integer immediate load.  Like
  ;; riscv64 we treat it as best-effort integer rather than crashing the
  ;; compiler in logand below -- truncate toward zero to an exact int.
  ;; NB: guard on `integer?` (bound in both guile and the self-hosted mes)
  ;; and keep `truncate`/`inexact->exact` in the else branch only -- mes
  ;; lacks `exact-integer?` and `truncate`, but it has no floats either,
  ;; so under mes v is always an integer and the else branch never runs.
  (let* ((v (if (integer? v)
                v
                (inexact->exact (truncate v))))
         (u (logand v #xffffffffffffffff)))
    (map (lambda (sh)
           (let ((b (logand (ash u sh) #xff)))
             (string-append "'" (if (< b 16) "0" "") (number->string b 16) "'")))
         '(0 -8 -16 -24 -32 -40 -48 -56))))

;;; load a full 64-bit immediate into register r via an inline literal
;;; pool: ldr x<n>,[pc+8] (LOAD_X<n>_AHEAD); b .+12 (SKIP_64_DATA);
;;; <8-byte little-endian literal>.  Exact for any signed/unsigned value.
(define (aarch64:value_address r v)
  `((,(string-append "LOAD_X" (substring r 1) "_AHEAD"))
    ("SKIP_64_DATA")
    ,(aarch64:le64-bytes v)))

;;; load a label/global/function ADDRESS into register r via the same
;;; 64-bit literal pool.  The relocation is a 4-byte &-token; the high 4
;;; bytes are zero ('00') since programs link below 2^32.
(define (aarch64:label_address r label)
  `((,(string-append "LOAD_X" (substring r 1) "_AHEAD"))
    ("SKIP_64_DATA")
    ((#:address ,label) "'00'" "'00'" "'00'" "'00'")))

;;; x16 := fp + off   (off may be negative; two's-complement add)
(define (aarch64:scratch-fp+ off)
  (append (aarch64:value_address %scratch off)
          (aarch64:insn (aarch64:enc-add %scratch "x17" %scratch))))

;;; the 4-instruction far-branch trampoline: load <label>'s 32-bit
;;; address into x16 and BR/BLR through it (mescc programs link below
;;; 2^32, so the W-load suffices -- same shape as crt1.M1).  <tail> is
;;; "BR_X16" (jump) or "BLR_X16" (call); it rides on the address line so
;;; line->M1 sees a trailing string and SKIP_32_DATA branches over the
;;; 4 address bytes straight to it.
(define (aarch64:trampoline label tail)
  `(("LOAD_W16_AHEAD")
    ("SKIP_32_DATA")
    ((#:address ,label) ,tail)))

;;; push register onto the x18 software stack (M2libc convention)
(define (aarch64:push r) (string-append "PUSH_" (string-upcase r)))
;;; pop register from the x18 software stack
(define (aarch64:pop r) (string-append "POP_" (string-upcase r)))

;;; ----------------------------------------------------------------
;;; Frame management
;;; ----------------------------------------------------------------

;;; function preamble: push lr (x30) and bp (x17), then bp := sp
(define (aarch64:function-preamble info . rest)
  `(("PUSH_LR")
    ("PUSH_BP")
    ("SET_BP_FROM_SP")))

;;; allocate function locals: 8*1025 buf + 20 local vars * 8 bytes,
;;; matching riscv64.  The frame exceeds the 12-bit sub-immediate, so
;;; load the size into the scratch register and subtract it from SP.
(define (aarch64:function-locals . rest)
  (append (aarch64:value_address %scratch (+ (* 8 1025) (* 20 8)))
          '(("SUB_SP_SP_X16"))))

;;; function epilogue: sp := bp, restore bp/lr, ret
(define (aarch64:ret . rest)
  `(("SET_SP_FROM_BP")
    (,(aarch64:pop "BP"))
    (,(aarch64:pop "LR"))
    ("RETURN")))

;;; ----------------------------------------------------------------
;;; Immediates / labels / locals
;;; ----------------------------------------------------------------

(define (aarch64:value->r info v)
  (or v (error "invalid value: aarch64:value->r: " v))
  (aarch64:value_address (get-r info) v))

(define (aarch64:value->r0 info v)
  (aarch64:value_address (get-r0 info) v))

(define (aarch64:label->r info label)
  (aarch64:label_address (get-r info) label))

;;; stack local to register: r := *(fp - 8n)
(define (aarch64:local->r info n)
  (let ((r (get-r info)))
    (append (aarch64:scratch-fp+ (- (* 8 n)))
            (aarch64:insn (aarch64:enc-ldr r %scratch)))))

;;; compute address of local variable: r := fp - 8n
(define (aarch64:local-ptr->r info n)
  (let ((r (get-r info)))
    (append (aarch64:value_address r (- (* 8 n)))
            (aarch64:insn (aarch64:enc-add r "x17" r)))))

;;; ----------------------------------------------------------------
;;; Calls and arguments
;;; ----------------------------------------------------------------

;;; call a function through a label, then pop n word-sized arguments
(define (aarch64:call-label info label n)
  (append (aarch64:trampoline label "BLR_X16")
          (if (= n 0) '()
              (aarch64:insn (aarch64:enc-addimm "x18" "x18" (* n 8))))))

;;; call function pointer held in register r, then pop n arguments
(define (aarch64:call-r info n)
  (let ((r (get-r info)))
    (append (aarch64:insn (aarch64:enc-blr r))
            (if (= n 0) '()
                (aarch64:insn (aarch64:enc-addimm "x18" "x18" (* n 8)))))))

;;; register to function argument (push it on the x18 stack)
(define (aarch64:r->arg info i)
  (let ((r (get-r info)))
    `((,(aarch64:push r)))))

;;; label address to function argument
(define (aarch64:label->arg info label i)
  (append (aarch64:label_address %scratch label)
          `((,(aarch64:push %scratch)))))

;;; ----------------------------------------------------------------
;;; ALU
;;; ----------------------------------------------------------------

(define (aarch64:r0+r1 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn (aarch64:enc-add r0 r0 r1))))

(define (aarch64:r0-r1 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn (aarch64:enc-sub r0 r0 r1))))

(define (aarch64:r0*r1 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn (aarch64:enc-mul r0 r0 r1))))

(define (aarch64:r0/r1 info signed?)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn ((if signed? aarch64:enc-sdiv aarch64:enc-udiv) r0 r0 r1))))

;;; r0 := r0 - (r0 / r1) * r1, with the quotient signed or unsigned to
;;; match the operand type (msub itself is sign-agnostic)
(define (aarch64:r0%r1 info signed?)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (list (aarch64:w->line ((if signed? aarch64:enc-sdiv aarch64:enc-udiv) %scratch r0 r1))
          (aarch64:w->line (aarch64:enc-msub r0 %scratch r1 r0)))))

(define (aarch64:r0<<r1 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn (aarch64:enc-lsl r0 r0 r1))))

(define (aarch64:r0>>r1 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn (aarch64:enc-lsr r0 r0 r1))))

(define (aarch64:r0>>r1-signed info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn (aarch64:enc-asr r0 r0 r1))))

(define (aarch64:r0-and-r1 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn (aarch64:enc-and r0 r0 r1))))

(define (aarch64:r0-or-r1 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn (aarch64:enc-orr r0 r0 r1))))

(define (aarch64:r0-xor-r1 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn (aarch64:enc-eor r0 r0 r1))))

;;; r0 := r0 + imm (via scratch literal load + add; always 64-bit exact)
(define (aarch64:r0+value info v)
  (let ((r0 (get-r0 info)))
    (append (aarch64:value_address %scratch v)
            (aarch64:insn (aarch64:enc-add r0 r0 %scratch)))))

;;; r := r + imm
(define (aarch64:r+value info v)
  (let ((r (get-r info)))
    (append (aarch64:value_address %scratch v)
            (aarch64:insn (aarch64:enc-add r r %scratch)))))

;;; r := r + r (doubling)
(define (aarch64:r+r info)
  (let ((r (get-r info)))
    (aarch64:insn (aarch64:enc-add r r r))))

;;; r := r & imm
(define (aarch64:r-and info v)
  (let ((r (get-r info)))
    (append (aarch64:value_address %scratch v)
            (aarch64:insn (aarch64:enc-and r r %scratch)))))

;;; r := r << imm
(define (aarch64:shl-r info n)
  (let ((r (get-r info)))
    (append (aarch64:value_address %scratch n)
            (aarch64:insn (aarch64:enc-lsl r r %scratch)))))

;;; r := ~r
(define (aarch64:not-r info)
  (let ((r (get-r info)))
    (aarch64:insn (aarch64:enc-mvn r r))))

;;; copy register r0 to r1 / r1 to r0
(define (aarch64:r0->r1 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn (aarch64:enc-mov r1 r0))))

(define (aarch64:r1->r0 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (aarch64:insn (aarch64:enc-mov r0 r1))))

;;; swap r0 and r1 (through scratch)
(define (aarch64:swap-r0-r1 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (list (aarch64:w->line (aarch64:enc-mov %scratch r0))
          (aarch64:w->line (aarch64:enc-mov r0 r1))
          (aarch64:w->line (aarch64:enc-mov r1 %scratch)))))

;;; swap value of register r with the top word of the x18 stack
(define (aarch64:swap-r-stack info)
  (let ((r (get-r info)))
    (list (aarch64:w->line (aarch64:enc-ldr %scratch "x18"))
          (aarch64:w->line (aarch64:enc-str r "x18"))
          (aarch64:w->line (aarch64:enc-mov r %scratch)))))

;;; swap value of register r0 with the top word of the stack (expr->arg)
(define (aarch64:swap-r1-stack info)
  (let ((r0 (get-r0 info)))
    (list (aarch64:w->line (aarch64:enc-ldr %scratch "x18"))
          (aarch64:w->line (aarch64:enc-str r0 "x18"))
          (aarch64:w->line (aarch64:enc-mov r0 %scratch)))))

;;; copy r2 to r1 when a third value is allocated, else re-peek r0 off
;;; the stack (mescc's r2->r0; see the riscv64 comment for the puzzle)
(define (aarch64:r2->r0 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)) (allocated (.allocated info)))
    (if (> (length allocated) 2)
        (aarch64:insn (aarch64:enc-mov r1 (cadddr allocated)))
        (list (list (aarch64:pop r0)) (list (aarch64:push r0))))))

;;; ----------------------------------------------------------------
;;; Truncation / extension of register r (low `bits`, in place) via a
;;; left/right shift pair -- mirrors riscv64's sll+sra approach.
;;; ----------------------------------------------------------------
(define (aarch64:extend-r r bits arith?)
  (append (aarch64:value_address %scratch (- 64 bits))
          (list (aarch64:w->line (aarch64:enc-lsl r r %scratch))
                (aarch64:w->line ((if arith? aarch64:enc-asr aarch64:enc-lsr)
                                  r r %scratch)))))

(define (aarch64:byte-r info)         (aarch64:extend-r (get-r info) 8 #f))
(define (aarch64:byte-signed-r info)  (aarch64:extend-r (get-r info) 8 #t))
(define (aarch64:word-r info)         (aarch64:extend-r (get-r info) 16 #f))
(define (aarch64:word-signed-r info)  (aarch64:extend-r (get-r info) 16 #t))
(define (aarch64:long-r info)         (aarch64:extend-r (get-r info) 32 #f))
(define (aarch64:long-signed-r info)  (aarch64:extend-r (get-r info) 32 #t))

;;; ----------------------------------------------------------------
;;; Memory loads/stores through a register-held address
;;; ----------------------------------------------------------------

;;; read (and zero-extend) from address in r into r
(define (aarch64:byte-mem->r info) (let ((r (get-r info))) (aarch64:insn (aarch64:enc-ldrb r r))))
(define (aarch64:word-mem->r info) (let ((r (get-r info))) (aarch64:insn (aarch64:enc-ldrh r r))))
(define (aarch64:long-mem->r info) (let ((r (get-r info))) (aarch64:insn (aarch64:enc-ldrw r r))))
(define (aarch64:mem->r info)      (let ((r (get-r info))) (aarch64:insn (aarch64:enc-ldr r r))))

;;; store r0 (sized) to address in r1
(define (aarch64:byte-r0->r1-mem info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info))) (aarch64:insn (aarch64:enc-strb r0 r1))))
(define (aarch64:word-r0->r1-mem info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info))) (aarch64:insn (aarch64:enc-strh r0 r1))))
(define (aarch64:long-r0->r1-mem info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info))) (aarch64:insn (aarch64:enc-strw r0 r1))))
(define (aarch64:r0->r1-mem info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info))) (aarch64:insn (aarch64:enc-str r0 r1))))

;;; load (sized) at address r0, store to address r1 (through scratch)
(define (aarch64:byte-r0-mem->r1-mem info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (list (aarch64:w->line (aarch64:enc-ldrb %scratch r0))
          (aarch64:w->line (aarch64:enc-strb %scratch r1)))))
(define (aarch64:word-r0-mem->r1-mem info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (list (aarch64:w->line (aarch64:enc-ldrh %scratch r0))
          (aarch64:w->line (aarch64:enc-strh %scratch r1)))))
(define (aarch64:long-r0-mem->r1-mem info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (list (aarch64:w->line (aarch64:enc-ldrw %scratch r0))
          (aarch64:w->line (aarch64:enc-strw %scratch r1)))))
(define (aarch64:r0-mem->r1-mem info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (list (aarch64:w->line (aarch64:enc-ldr %scratch r0))
          (aarch64:w->line (aarch64:enc-str %scratch r1)))))

;;; add a small immediate to the sized cell addressed by r (used by
;;; ++/-- through a pointer).  v fits the 12-bit add/sub-immediate
;;; (struct sizes / 1), keeping a single scratch.
(define (aarch64:mem-add-sized info v ld st)
  (let ((r (get-r info)))
    (list (aarch64:w->line (ld %scratch r))
          (aarch64:w->line (if (>= v 0)
                               (aarch64:enc-addimm %scratch %scratch v)
                               (aarch64:enc-subimm %scratch %scratch (- v))))
          (aarch64:w->line (st %scratch r)))))

(define (aarch64:r-byte-mem-add info v) (aarch64:mem-add-sized info v aarch64:enc-ldrb aarch64:enc-strb))
(define (aarch64:r-word-mem-add info v) (aarch64:mem-add-sized info v aarch64:enc-ldrh aarch64:enc-strh))
(define (aarch64:r-long-mem-add info v) (aarch64:mem-add-sized info v aarch64:enc-ldrw aarch64:enc-strw))
(define (aarch64:r-mem-add info v)      (aarch64:mem-add-sized info v aarch64:enc-ldr  aarch64:enc-str))

;;; ----------------------------------------------------------------
;;; Register-to-local stores (offset = -8*id + n)
;;; ----------------------------------------------------------------
(define (aarch64:store-local info id n st)
  (let ((r (get-r info)))
    (append (aarch64:scratch-fp+ (+ (- (* 8 id)) n))
            (aarch64:insn (st r %scratch)))))

(define (aarch64:byte-r->local+n info id n) (aarch64:store-local info id n aarch64:enc-strb))
(define (aarch64:word-r->local+n info id n) (aarch64:store-local info id n aarch64:enc-strh))
(define (aarch64:long-r->local+n info id n) (aarch64:store-local info id n aarch64:enc-strw))
(define (aarch64:r->local+n info id n)      (aarch64:store-local info id n aarch64:enc-str))
(define (aarch64:r->local info n)           (aarch64:store-local info n 0 aarch64:enc-str))

;;; add a small immediate to a memory cell (used by ++/-- and += const
;;; on locals/globals).  Needs two working registers -- one for the
;;; address, one for the loaded value -- so it borrows x9 off the stack
;;; rather than touching the condregs.  x16 holds the address; v fits
;;; the 12-bit add/sub-immediate (true for ++/-- and struct strides).
(define (aarch64:cell-add addr-lines v)
  (append `(("PUSH_X9"))
          addr-lines                       ; x16 := address
          (list (aarch64:w->line (aarch64:enc-ldr "x9" %scratch))
                (aarch64:w->line (if (>= v 0)
                                     (aarch64:enc-addimm "x9" "x9" v)
                                     (aarch64:enc-subimm "x9" "x9" (- v))))
                (aarch64:w->line (aarch64:enc-str "x9" %scratch)))
          `(("POP_X9"))))

;;; *(fp - 8n) += v
(define (aarch64:local-add info n v)
  (aarch64:cell-add (aarch64:scratch-fp+ (- (* 8 n))) v))

;;; *label += v
(define (aarch64:label-mem-add info label v)
  (aarch64:cell-add (aarch64:label_address %scratch label) v))

;;; ----------------------------------------------------------------
;;; Label memory access
;;; ----------------------------------------------------------------

;;; load word at label into r
(define (aarch64:label-mem->r info label)
  (let ((r (get-r info)))
    (append (aarch64:label_address %scratch label)
            (aarch64:insn (aarch64:enc-ldr r %scratch)))))

(define (aarch64:store-label info label st)
  (let ((r (get-r info)))
    (append (aarch64:label_address %scratch label)
            (aarch64:insn (st r %scratch)))))

(define (aarch64:r->byte-label info label) (aarch64:store-label info label aarch64:enc-strb))
(define (aarch64:r->word-label info label) (aarch64:store-label info label aarch64:enc-strh))
(define (aarch64:r->long-label info label) (aarch64:store-label info label aarch64:enc-strw))
(define (aarch64:r->label info label)      (aarch64:store-label info label aarch64:enc-str))

;;; ----------------------------------------------------------------
;;; Stack helpers
;;; ----------------------------------------------------------------
(define (aarch64:push-register info r) `((,(aarch64:push r))))
(define (aarch64:pop-register info r)  `((,(aarch64:pop r))))
(define (aarch64:push-r0 info) `((,(aarch64:push (get-r0 info)))))
(define (aarch64:pop-r0 info)  `((,(aarch64:pop (get-r0 info)))))

;;; get function return value: move %retreg (x9) into the allocated reg
(define (aarch64:return->r info)
  (let ((r (car (.allocated info))))
    (if (equal? r %retreg) '()
        (aarch64:insn (aarch64:enc-mov r %retreg)))))

(define (aarch64:nop info) (aarch64:insn #xd503201f))

;;; ----------------------------------------------------------------
;;; Control flow
;;; ----------------------------------------------------------------

;;; unconditional jump to label
(define (aarch64:jump info label)
  (aarch64:trampoline label "BR_X16"))

;;; jump to label when <cond> holds: skip the 4-instruction trampoline
;;; on the inverse condition (b.!cond +5), else fall through and branch.
(define (aarch64:cond-jump cc label)
  (cons (aarch64:w->line (aarch64:enc-bcond (logxor cc 1) 5))
        (aarch64:trampoline label "BR_X16")))

;;; ----------------------------------------------------------------
;;; Flag emulation (cf. riscv64 condregx/condregy).  The compare ops
;;; stash the two operands in x14/x15; the jump/setcc ops re-issue a
;;; cmp from them, so no real NZCV state has to survive between ops.
;;; ----------------------------------------------------------------

;;; test register r against 0
(define (aarch64:test-r info)
  (let ((r (get-r info)))
    (cons (aarch64:w->line (aarch64:enc-mov %condregx r))
          (aarch64:value_address %condregy 0))))

;;; same, used for jump-* paths
(define (aarch64:r-zero? info)
  (let ((r (car (if (pair? (.allocated info)) (.allocated info) (.registers info)))))
    (cons (aarch64:w->line (aarch64:enc-mov %condregx r))
          (aarch64:value_address %condregy 0))))

;;; compare register to immediate value
(define (aarch64:r-cmp-value info v)
  (let ((r (get-r info)))
    (cons (aarch64:w->line (aarch64:enc-mov %condregx r))
          (aarch64:value_address %condregy v))))

;;; compare two registers
(define (aarch64:r0-cmp-r1 info)
  (let ((r0 (get-r0 info)) (r1 (get-r1 info)))
    (list (aarch64:w->line (aarch64:enc-mov %condregx r0))
          (aarch64:w->line (aarch64:enc-mov %condregy r1)))))

;;; negate the zero flag: condregx := (condregx == condregy) ? 1 : 0;
;;; condregy := 0  -- so a following "zero?" test reads the inverse.
(define (aarch64:xor-zf info)
  (append (list (aarch64:w->line (aarch64:enc-cmp %condregx %condregy))
                (aarch64:w->line (aarch64:enc-cset %condregx cc-eq)))
          (aarch64:value_address %condregy 0)))

(define (aarch64:jump-nz info label)
  (cons (aarch64:w->line (aarch64:enc-cmp %condregx %condregy))
        (aarch64:cond-jump cc-ne label)))

(define (aarch64:jump-z info label)
  (cons (aarch64:w->line (aarch64:enc-cmp %condregx %condregy))
        (aarch64:cond-jump cc-eq label)))

;;; assuming proper zero/sign extension, same as jump-z
(define (aarch64:jump-byte-z info label)
  (aarch64:jump-z info label))

;;; set register from a condition (cmp condregx,condregy; cset r,cc)
(define (aarch64:cc->r info cc)
  (let ((r (get-r info)))
    (list (aarch64:w->line (aarch64:enc-cmp %condregx %condregy))
          (aarch64:w->line (aarch64:enc-cset r cc)))))

(define (aarch64:zf->r info)     (aarch64:cc->r info cc-eq))
(define (aarch64:r-negate info)  (aarch64:cc->r info cc-eq))
(define (aarch64:g?->r info)     (aarch64:cc->r info cc-gt))
(define (aarch64:ge?->r info)    (aarch64:cc->r info cc-ge))
(define (aarch64:l?->r info)     (aarch64:cc->r info cc-lt))
(define (aarch64:le?->r info)    (aarch64:cc->r info cc-le))
(define (aarch64:a?->r info)     (aarch64:cc->r info cc-hi))
(define (aarch64:ae?->r info)    (aarch64:cc->r info cc-hs))
(define (aarch64:b?->r info)     (aarch64:cc->r info cc-lo))
(define (aarch64:be?->r info)    (aarch64:cc->r info cc-ls))

;;; ----------------------------------------------------------------
;;; Instruction alist.  This is the implemented subset of riscv64's
;;; table -- the integer ISA; float/double, varargs spilling and the
;;; swap-stack helpers are not yet ported.  mescc errors out on any IR
;;; op whose key is absent, so an unported feature fails its own test
;;; rather than miscompiling.
;;; ----------------------------------------------------------------
(define aarch64:instructions
  `((a?->r . ,aarch64:a?->r)
    (ae?->r . ,aarch64:ae?->r)
    (b?->r . ,aarch64:b?->r)
    (be?->r . ,aarch64:be?->r)
    (byte-mem->r . ,aarch64:byte-mem->r)
    (byte-r . ,aarch64:byte-r)
    (byte-r->local+n . ,aarch64:byte-r->local+n)
    (byte-r0->r1-mem . ,aarch64:byte-r0->r1-mem)
    (byte-r0-mem->r1-mem . ,aarch64:byte-r0-mem->r1-mem)
    (byte-signed-r . ,aarch64:byte-signed-r)
    (call-label . ,aarch64:call-label)
    (call-r . ,aarch64:call-r)
    (function-locals . ,aarch64:function-locals)
    (function-preamble . ,aarch64:function-preamble)
    (g?->r . ,aarch64:g?->r)
    (ge?->r . ,aarch64:ge?->r)
    (jump . ,aarch64:jump)
    (jump-byte-z . ,aarch64:jump-byte-z)
    (jump-nz . ,aarch64:jump-nz)
    (jump-z . ,aarch64:jump-z)
    (l?->r . ,aarch64:l?->r)
    (label->arg . ,aarch64:label->arg)
    (label->r . ,aarch64:label->r)
    (label-mem->r . ,aarch64:label-mem->r)
    (label-mem-add . ,aarch64:label-mem-add)
    (local-add . ,aarch64:local-add)
    (le?->r . ,aarch64:le?->r)
    (local->r . ,aarch64:local->r)
    (local-ptr->r . ,aarch64:local-ptr->r)
    (long-mem->r . ,aarch64:long-mem->r)
    (long-r . ,aarch64:long-r)
    (long-r->local+n . ,aarch64:long-r->local+n)
    (long-r0->r1-mem . ,aarch64:long-r0->r1-mem)
    (long-r0-mem->r1-mem . ,aarch64:long-r0-mem->r1-mem)
    (long-signed-r . ,aarch64:long-signed-r)
    (mem->r . ,aarch64:mem->r)
    (nop . ,aarch64:nop)
    (not-r . ,aarch64:not-r)
    (pop-r0 . ,aarch64:pop-r0)
    (pop-register . ,aarch64:pop-register)
    (push-r0 . ,aarch64:push-r0)
    (push-register . ,aarch64:push-register)
    (quad-r0->r1-mem . ,aarch64:r0->r1-mem)
    (r+r . ,aarch64:r+r)
    (r+value . ,aarch64:r+value)
    (r->arg . ,aarch64:r->arg)
    (r->byte-label . ,aarch64:r->byte-label)
    (r->label . ,aarch64:r->label)
    (r->local . ,aarch64:r->local)
    (r->local+n . ,aarch64:r->local+n)
    (r->long-label . ,aarch64:r->long-label)
    (r->word-label . ,aarch64:r->word-label)
    (r-and . ,aarch64:r-and)
    (r-byte-mem-add . ,aarch64:r-byte-mem-add)
    (r-cmp-value . ,aarch64:r-cmp-value)
    (r-long-mem-add . ,aarch64:r-long-mem-add)
    (r-mem-add . ,aarch64:r-mem-add)
    (r-negate . ,aarch64:r-negate)
    (r-word-mem-add . ,aarch64:r-word-mem-add)
    (r-zero? . ,aarch64:r-zero?)
    (r0%r1 . ,aarch64:r0%r1)
    (r0*r1 . ,aarch64:r0*r1)
    (r0+r1 . ,aarch64:r0+r1)
    (r0+value . ,aarch64:r0+value)
    (r0->r1 . ,aarch64:r0->r1)
    (r0->r1-mem . ,aarch64:r0->r1-mem)
    (r0-and-r1 . ,aarch64:r0-and-r1)
    (r0-cmp-r1 . ,aarch64:r0-cmp-r1)
    (r0-mem->r1-mem . ,aarch64:r0-mem->r1-mem)
    (r0-or-r1 . ,aarch64:r0-or-r1)
    (r0-r1 . ,aarch64:r0-r1)
    (r0-xor-r1 . ,aarch64:r0-xor-r1)
    (r0/r1 . ,aarch64:r0/r1)
    (r0<<r1 . ,aarch64:r0<<r1)
    (r0>>r1 . ,aarch64:r0>>r1)
    (r0>>r1-signed . ,aarch64:r0>>r1-signed)
    (r1->r0 . ,aarch64:r1->r0)
    (r2->r0 . ,aarch64:r2->r0)
    (ret . ,aarch64:ret)
    (return->r . ,aarch64:return->r)
    (shl-r . ,aarch64:shl-r)
    (swap-r-stack . ,aarch64:swap-r-stack)
    (swap-r0-r1 . ,aarch64:swap-r0-r1)
    (swap-r1-stack . ,aarch64:swap-r1-stack)
    (test-r . ,aarch64:test-r)
    (value->r . ,aarch64:value->r)
    (value->r0 . ,aarch64:value->r0)
    (word-mem->r . ,aarch64:word-mem->r)
    (word-r . ,aarch64:word-r)
    (word-r->local+n . ,aarch64:word-r->local+n)
    (word-r0->r1-mem . ,aarch64:word-r0->r1-mem)
    (word-r0-mem->r1-mem . ,aarch64:word-r0-mem->r1-mem)
    (word-signed-r . ,aarch64:word-signed-r)
    (xor-zf . ,aarch64:xor-zf)
    (zf->r . ,aarch64:zf->r)))
