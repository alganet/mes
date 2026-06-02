;;; GNU Mes --- Maxwell Equations of Software
;;; Copyright © 2018,2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 W. J. van der Laan <laanwj@protonmail.com>
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

;;; Initialize MesCC as aarch64 compiler.
;;;
;;; Type sizes match riscv64 (asm-generic 64-bit Linux ABI: same
;;; sizeof(long), sizeof(int), etc.). Registers follow M2libc's
;;; convention, not the standard AArch64 ABI. The mescc backend
;;; partitions the M2libc temporaries like riscv64 partitions t0..t6:
;;;   x9..x13  caller-saved IR temporaries (aarch64:registers below);
;;;            x9 is also the return register (mescc r0 / %retreg).
;;;   x14 x15  condition-flag emulation registers (condregx/condregy in
;;;            module/mescc/aarch64/as.scm) -- they must survive between
;;;            a compare op and the jump/setcc that consumes it, so the
;;;            backend never uses them as transient scratch.
;;;   x16      transient scratch (literal-pool temp, computed addresses,
;;;            the call/jump trampoline target; used by crt1 too).
;;;   x17      base pointer (BP); x18 the stack pointer (SP) -- cf.
;;;            INIT_SP (mov x18, sp) and SET_SP_FROM_BP (mov x18, x17) in
;;;            lib/m2/aarch64/aarch64_defs.M1.
;;; x30 is the link register; x29 (the ABI frame pointer) is unused --
;;; BP=x17 takes its place.

;;; Code:

(define-module (mescc aarch64 info)
  #:use-module (mescc info)
  #:use-module (mescc aarch64 as)
  #:export (aarch64-info
            aarch64:registers))

(define (aarch64-info)
  (make <info> #:types aarch64:type-alist #:registers aarch64:registers #:instructions aarch64:instructions))

;;; Caller-saved general-purpose registers usable for IR temporaries
;;; (x9..x13, 5 registers -- same count as riscv64 t0..t4). x14/x15 are
;;; the flag-emulation registers and x16 the scratch; see commentary.
(define aarch64:registers '("x9" "x10" "x11" "x12" "x13"))

(define aarch64:type-alist
  `(("char" . ,(make-type 'signed 1 #f))
    ("short" . ,(make-type 'signed 2 #f))
    ("int" . ,(make-type 'signed 4 #f))
    ("long" . ,(make-type 'signed 8 #f))
    ("default" . ,(make-type 'signed 4 #f))
    ("*" . ,(make-type 'unsigned 8 #f))
    ("long long" . ,(make-type 'signed 8 #f))
    ("long long int" . ,(make-type 'signed 8 #f))

    ("void" . ,(make-type 'void 1 #f))
    ("signed char" . ,(make-type 'signed 1 #f))
    ("unsigned char" . ,(make-type 'unsigned 1 #f))
    ("unsigned short" . ,(make-type 'unsigned 2 #f))
    ("unsigned" . ,(make-type 'unsigned 4 #f))
    ("unsigned int" . ,(make-type 'unsigned 4 #f))
    ("unsigned long" . ,(make-type 'unsigned 8 #f))
    ("unsigned long long" . ,(make-type 'unsigned 8 #f))
    ("unsigned long long int" . ,(make-type 'unsigned 8 #f))

    ("float" . ,(make-type 'float 4 #f))
    ("double" . ,(make-type 'float 8 #f))
    ("long double" . ,(make-type 'float 8 #f))

    ("short int" . ,(make-type 'signed 2 #f))
    ("unsigned short int" . ,(make-type 'unsigned 2 #f))
    ("long int" . ,(make-type 'signed 8 #f))
    ("unsigned long int" . ,(make-type 'unsigned 8 #f))))
