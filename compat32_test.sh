#!/bin/sh --
# by pts@fazekas.hu at Sun Jul  3 12:38:36 CEST 2022

set -ex

nasm-0.98.39.static -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin
nasm-0.99.06.static -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin
# Yasm is usually incompatible.
#yasm-1.2.0 -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin
#yasm-1.3.0 -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin
nasm -w-number-overflow -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin
./mininasm -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin
./mininasm.gcc32 -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin
./mininasm.tcc -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin
./mininasm.tcc64 -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin
"${KVIKDOS:-kvikdos}" mininasm.com -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin
"${KVIKDOS:-kvikdos}" mininasm.exe -f bin -o compat32.bin compat32.asm && cmp -l compat32.bin.good compat32.bin

: "$0" OK.
