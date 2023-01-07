#!/bin/sh --
# by pts@fazekas.hu at Sat Jan  7 00:40:37 CET 2023
set -ex

perl a72conv.pl <a72.asm >a72.nasm
nasm-0.98.39 -O9 -f bin -o a72n.com a72.nasm
../../mininasm -O9 -f bin -o a72m.com a72.nasm
cmp -l a72n.com a72m.com
cmp -l a72.com.golden a72n.com

perl a72conv.pl <a72_8087.asm >a72_8087.nasm
nasm-0.98.39 -O9 -f bin -o a72_808n.com a72_8087.nasm
../../mininasm -O9 -f bin -o a72_808m.com a72_8087.nasm
cmp -l a72_808n.com a72_808m.com
cmp -l a72_8087.com.golden a72_808n.com

: "$0" OK.
