#! /bin/sh

# GNU Mes --- Maxwell Equations of Software
# Copyright © 2019,2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of GNU Mes.
#
# GNU Mes is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or (at
# your option) any later version.
#
# GNU Mes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GNU Mes.  If not, see <http://www.gnu.org/licenses/>.

. ./config.sh
. ${srcdest}build-aux/configure-lib.sh
. ${srcdest}build-aux/trace.sh
. ${srcdest}build-aux/cc.sh

trap 'test -f .log && cat .log' EXIT

mkdir -p $mes_cpu-mes
crt1_src=${srcdest}lib/$mes_kernel/$mes_cpu-mes-$compiler
if test -e $crt1_src/crt1.M1; then
    # aarch64: _start must INIT_SP before mescc's unconditional function
    # preamble stores through the (uninitialised) x18 software SP, so it
    # is hand-written assembly assembled directly rather than a crt1.c.
    cp $crt1_src/crt1.M1 .
    trace "M1         crt1.M1" $M1 --little-endian --architecture $mes_cpu -f ${srcdest}lib/$mes_cpu-mes/$mes_cpu.M1 -f crt1.M1 -o crt1.o
    # crt1.M1 is itself the assembly text; the linker's blood-elf debug
    # pass expects a crt1.s, so provide it (the crt1.c path emits one).
    cp crt1.M1 crt1.s
else
    cp $crt1_src/crt1.c .
    compile crt1.c
fi
cp crt1.o $mes_cpu-mes
if test -e crt1.s; then
    cp crt1.s $mes_cpu-mes
fi

archive libc-mini.a $libc_mini_SOURCES
cp libc-mini.a $mes_cpu-mes
if test -e libc-mini.s; then
    cp libc-mini.s $mes_cpu-mes
fi

archive libmes.a $libmes_SOURCES
cp libmes.a $mes_cpu-mes
if test -e libmes.s; then
    cp libmes.s $mes_cpu-mes
fi

archive libmescc.a $libmescc_SOURCES
cp libmescc.a $mes_cpu-mes
if test -e libmescc.s; then
    cp libmescc.s $mes_cpu-mes
fi

if test $mes_libc = mes; then
    archive libc.a $libc_SOURCES
    cp libc.a $mes_cpu-mes
    if test -e libc.s; then
        cp libc.s $mes_cpu-mes
    fi
fi

archive libc+tcc.a $libc_tcc_SOURCES
cp libc+tcc.a $mes_cpu-mes
if test -e libc+tcc.s; then
    cp libc+tcc.s $mes_cpu-mes
fi

archive libtcc1.a $libtcc1_SOURCES
cp libtcc1.a $mes_cpu-mes
if test -e libtcc1.s; then
    cp libtcc1.s $mes_cpu-mes
fi

archive libgetopt.a lib/posix/getopt.c
cp libgetopt.a $mes_cpu-mes
if test -e libgetopt.s; then
    cp libgetopt.s $mes_cpu-mes
fi

if $courageous; then
    exit 0
fi

archive libc+gnu.a $libc_gnu_SOURCES
cp libc+gnu.a $mes_cpu-mes
if test -e libc+gnu.s; then
    cp libc+gnu.s $mes_cpu-mes
fi
