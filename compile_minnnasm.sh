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
cmp mininasm_debug44.com.good minnnasm.com
nasm -f bin -O0 -o minnnasm.com minnnasm.nasm
cmp mininasm_debug44.com.good minnnasm.com
./mininasm -f bin -o minnnasmm.com minnnasm.nasm
ndisasm -b 16 -o 0x100 minnnasmm.com >minnnasmm.com.ndisasm
cmp mininasm_debug44.com.good minnnasmm.com

: "$0" OK.