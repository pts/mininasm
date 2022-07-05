#!/bin/sh --
# by pts@fazekas.hu at Sun Jul  3 12:38:36 CEST 2022

set -ex

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
"${KVIKDOS:-kvikdos}" mininasm.com -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"
"${KVIKDOS:-kvikdos}" mininasm.exe -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin || exit "$?"

: "$0" OK.
