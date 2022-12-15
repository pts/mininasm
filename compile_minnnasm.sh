#!/bin/sh --
# by pts@fazekas.hu at Wed Oct 26 14:53:44 UTC 2022
set -ex

NASM=nasm-0.98.39

"$NASM" -f bin -O9 -o minnnasm.com minnnasm.nasm
ndisasm -b 16 -o 0x100 minnnasm.com >minnnasm.com.ndisasm
ndisasm -b 16 -o 0x100 minnnasm.com | perl -pe 's@^(\S+\s+)([0-9A-F]+)(?=\s+)@ $1.("?"x length($2))  @e' >minnnasm.com.nocode.ndisasm
cmp mininasm_debug49.com.good minnnasm.com
nasm-2.13.02 -f bin -O9 -o minnnasm.com minnnasm.nasm
cmp mininasm_debug49.com.good minnnasm.com
./mininasm -f bin -O9 -o minnnas1.com minnnasm.nasm
ndisasm -b 16 -o 0x100 minnnas1.com >minnnas1.com.ndisasm
cmp mininasm_debug49.com.good minnnas1.com
cmp mininasm_debug49.com.good minonas1.com
cat minnnasm.nasm >minnnasm.na  # DOS 8.3 character limit on filename extension.
./kvikdos minnnasm.com -f bin -O9 -o minnnas2.com minnnasm.na
# Check that it's self-hosting: when it compiles itself, it produces the golden good binary.
cmp mininasm_debug49.com.good minnnas2.com

: "$0" OK.
