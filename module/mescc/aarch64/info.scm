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
;;; sizeof(long), sizeof(int), etc.). Register set differs: aarch64
;;; uses x9..x14 as caller-saved scratch, with x15 reserved for
;;; mescc's own intermediate state. x16/x17 are reserved by the
;;; ABI for intra-procedure-call (linker veneers); x18..x28 are
;;; callee-saved. x29 is the frame pointer, x30 the link register.

;;; Code:

(define-module (mescc aarch64 info)
  #:use-module (mescc info)
  #:use-module (mescc aarch64 as)
  #:export (aarch64-info
            aarch64:registers))

(define (aarch64-info)
  (make <info> #:types aarch64:type-alist #:registers aarch64:registers #:instructions aarch64:instructions))

;;; Caller-saved general-purpose registers usable for IR temporaries.
;;; x9..x14 (6 registers); x15 is reserved for mescc internal use.
(define aarch64:registers '("x9" "x10" "x11" "x12" "x13" "x14"))

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
