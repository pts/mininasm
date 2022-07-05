#!/bin/sh --
# by pts@fazekas.hu at Sun Jul  3 12:38:36 CEST 2022

if test "$KVIKDOS"; then :
elif type kvikdos >/dev/null 2>&1; then KVIKDOS=kvikdos
else KVIKDOS="$HOME/prg/kvikdos/kvikdos"
fi

if test "$DOSMC"; then :
elif type dosmc >/dev/null 2>&1; then DOSMC=dosmc
else DOSMC="$HOME/prg/dosmc/dosmc"
fi

set -ex

if test "$1" = --compile; then
gcc -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o mininasm mininasm.c bbprintf.c || exit "$?" #&& ls -ld mininasm
gcc -m32 -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o mininasm.gcc32 mininasm.c bbprintf.c || exit "$?" #&& ls -ld mininasm.gcc32
owcc -bdos -o mininasm.exe -mcmodel=c -Os -s -fstack-check -Wl,option -Wl,stack=1800 -march=i86 -W -Wall -Wextra mininasm.c bbprintf.c || exit "$?" #&& ls -ld mininasm.exe
pts-tcc -s -O2 -W -Wall -o mininasm.tcc mininasm.c bbprintf.c || exit "$?" #&& ls -ld mininasm.tcc
pts-tcc64 -m64 -s -O2 -W -Wall -o mininasm.tcc64 mininasm.c bbprintf.c || exit "$?" #&& ls -ld mininasm.tcc64
"$DOSMC" -mt mininasm.c bbprintf.c || exit "$?"
fi

nasm-0.98.39.static -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"
nasm-0.99.06.static -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"
# Yasm is usually incompatible.
#yasm-1.2.0 -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"
#yasm-1.3.0 -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"
nasm -w-number-overflow -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"
./mininasm -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"
./mininasm.gcc32 -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"
./mininasm.tcc -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"
./mininasm.tcc64 -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"
"$KVIKDOS" mininasm.com -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"
"$KVIKDOS" mininasm.exe -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"

: "$0" OK.
