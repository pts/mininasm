#!/bin/sh --
# by pts@fazekas.hu at Wed Oct 26 14:53:44 UTC 2022
set -ex

NASM=nasm-0.98.39

# Convery from .wasm to .nasm assembly syntax.
LOCALSYM=_.
for F in mininasm_text.wasm bbprintf_text.wasm; do
  LOCALSYM="$LOCALSYM."
  export LOCALSYM
  perl -wpe 'use integer; use strict;
      s@\bDGROUP:(?=\w|\@\$)@@g;
      s/\@(\$+)/$ENV{LOCALSYM}/g;
      if (!m@;@) {
        s@\b([cdes]s:)\[@\[$1@g;
        if (m@ptr @ and !m@\bnear +ptr +@) {
          s@\bptr +([.\w]+(?:[+][.\w]+)?)@[$1]@g;
        }
        s@\bptr\b *@@g;
        s@\boffset\b *@@g;
        s@\bles(\s+)(ax|bx|cx|dx|si|di|bp|sp),dword *\[@les$1$2,\[@;
        s@\b0([0-9a-f]*)H@0x$1@g;
        s@\b([1-9][0-9a-f]*)H@0x$1@g;
        s@^\t([a-z]+)\t+@\t\t$1 @;
        s@^\t([a-z]+)@\t\t$1@;
        s@,(?! )@, @ if m@^\t@;
      }
  ' <"$F" >"${F%.*}.nasm"
done  

$NASM -f bin -O0 -o minnnasm.com minnnasm.nasm
ndisasm -b 16 -o 0x100 minnnasm.com >minnnasm.com.ndisasm
ndisasm -b 16 -o 0x100 minnnasm.com | perl -pe 's@^(\S+\s+)([0-9A-F]+)(?=\s+)@ $1.("?"x length($2))  @e' >minnnasm.com.nocode.ndisasm
cmp mininasm_debug47.com.good minnnasm.com
nasm-2.13.02 -f bin -O0 -o minnnasm.com minnnasm.nasm
cmp mininasm_debug47.com.good minnnasm.com
./mininasm -f bin -o minnnas1.com minnnasm.nasm
ndisasm -b 16 -o 0x100 minnnas1.com >minnnas1.com.ndisasm
cmp mininasm_debug47.com.good minnnas1.com
$NASM -f bin -O0 -o minonasm.com minonasm.nasm
cmp mininasm_debug47.com.good minonasm.com
./mininasm -f bin -o minonas1.com minonasm.nasm
cmp mininasm_debug47.com.good minonas1.com
cat minnnasm.nasm >minnnasm.na  # DOS 8.3 character limit on filename extension.
./kvikdos minnnasm.com -f bin -o minnnas2.com minnnasm.na
# Check that it's self-hosting: when it compiles itself, it produces the golden good binary.
cmp mininasm_debug47.com.good minnnas2.com

: "$0" OK.
