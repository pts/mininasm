#! /bin/sh --
# by pts@fazekas.hu at Sun Nov 27 19:23:39 CET 2022

set -ex

LD="$(gcc -print-prog-name=ld)"
test "$LD"

gcc -c -m32 -mregparm=3 -fno-pic -fno-stack-protector -fomit-frame-pointer -fno-ident -ffreestanding -fno-builtin -fno-unwind-tables -fno-asynchronous-unwind-tables -nostdlib -nostdinc -Os -falign-functions=1 -mpreferred-stack-boundary=2 -falign-jumps=1 -falign-loops=1 -march=i386 -ansi -pedantic -W -Wall -Werror=implicit-function-declaration -Wno-overlength-strings -o mininasm.sgccli3.o mininasm_sgccli3.c
"$LD" -s -m elf_i386 -o mininasm.sgccli3 mininasm.sgccli3.o
sstrip mininasm.sgccli3
ls -ld mininasm.sgccli3

: "$0" OK.
