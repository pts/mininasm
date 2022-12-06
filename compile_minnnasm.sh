#!/bin/sh --
# by pts@fazekas.hu at Wed Oct 26 14:53:44 UTC 2022
set -ex

NASM=nasm-0.98.39

# dosmc -mt -nq -cpn -fm=mininasm.map mininasm.c  # Linking to mininasm.com succeeds.
# dosmc -mt -nq -cpn -d1 mininasm.c  # Creates mininasm.tmp.obj, linking doesn't succeed because of debug symbols.
# wdis -s -a -fi '-i=@' mininasm.tmp.obj >mininasm_debug1.wasm
# dosmc -mt -nq -cpn -d1 -c -DCONFIG_BBPRINTF_LONG=1 bbprintf.c
# wdis -s -a -fi '-i=@' bbprintf.obj >bbprintf_debug1.wasm  # Labels are wrong, but at least contains bbprintf.c as source comments.
#
# Convert from .wasm to .nasm assembly syntax.
for F in mininasm_debug1.wasm; do
  # Convert db hex to db 'literal': perl -pe 's@([0-9a-f]+)H@ my $o = hex($1); ($o >= 32 and $o <= 126 and $o != 0x27) ? "\x27" . chr($o) . "\x27" : $o @ge; s@\x27, \x27@@g'
  # Conversion of the _TEXT segment (output after ___section_mininasm_c_text: in minnnasm.nasm) is now fully automatic:
  perl -we 'use integer; use strict;
      my $is_text_segment = 0;
      while (<STDIN>) {
        if ($is_text_segment) {
          if (m@^\S+\t+ENDS\r?$@) { $is_text_segment = 0; next; }  # Extract _TEXT segment only.
          next if m@^\t*ASSUME\s@;
          s@[\r\n]+@@;
          my $comment = (s@(\s*;.*)@@ ? $1 : "");
          s@^\t(xchg|test)\t\t([a-z]{2}),([a-z]{2})$@\t$1\t\t$3,$2@;  # !! Swap register arguments of test and xchg, because wcc/wasm/wdis and nasm/ndisasm disagree on the order.
          #s@^\t(xchg|test)\t\t([^,]+),([a-z]{2}|(?![0-9a-f]+H?)[^,]+)$@\t$1\t\t$3,$2@;  # Swap r/r and r/m arguments of test and xchg. Not needed for r/m, the order of that does not matter.
          # Change e.g. (add ax, 0xffd4) to (add ax, -0x2c) as a workaround for optimizing to byte form by NASM 0.98.39 and NASM 0.99.06 with -O9.
          s@^\t(add|or|adc|sbb|and|sub|xor|cmp)\t\tax,([0-9][0-9a-f]*)H$@ my $i = hex($2); my $r2 = (($i >= 0xff80 and $i <= 0xffff) ? sprintf("-0%x", 0x10000 - $i) : $2); "\t$1\t\tax,${r2}H" @e;
          s@\bDGROUP:(?=\w|\@\$)@@g;
          s@\b([cdes]s:)\[@\[$1@g;
          if (m@ptr @ and !m@\bnear +ptr +@) {
            s@\bptr +((?:\@+\$+)?[.\w]+(?:[+][.\w]+)?)@[$1]@g;
          }
          s@\bptr\b *@@g;
          s@\boffset\b *@@g;
          s@\bles(\s+)(ax|bx|cx|dx|si|di|bp|sp),dword *\[@les$1$2,\[@;
          s@\b0([0-9a-f]*)H@0x$1@g;
          s@\b([1-9][0-9a-f]*)H@0x$1@g;
          s@^\t([a-z]+)\t+@\t\t$1 @;
          s@^\t([a-z]+)@\t\t$1@;
          s@,(?! )@, @ if m@^\t@;
          print "$_$comment\n";
        } else {
          $is_text_segment = 1 if m@^_TEXT\t+SEGMENT\s@;
        }
      }
  ' <"$F" >"${F%.*}.nasm"
done
#exit

$NASM -f bin -O9 -o minnnasm.com minnnasm.nasm
ndisasm -b 16 -o 0x100 minnnasm.com >minnnasm.com.ndisasm
ndisasm -b 16 -o 0x100 minnnasm.com | perl -pe 's@^(\S+\s+)([0-9A-F]+)(?=\s+)@ $1.("?"x length($2))  @e' >minnnasm.com.nocode.ndisasm
cmp mininasm_debug49.com.good minnnasm.com
nasm-2.13.02 -f bin -O9 -o minnnasm.com minnnasm.nasm
cmp mininasm_debug49.com.good minnnasm.com
./mininasm -f bin -O9 -o minnnas1.com minnnasm.nasm
ndisasm -b 16 -o 0x100 minnnas1.com >minnnas1.com.ndisasm
cmp mininasm_debug49.com.good minnnas1.com
$NASM -f bin -O9 -o minonasm.com minonasm.nasm
cmp mininasm_debug49.com.good minonasm.com
./mininasm -f bin -O9 -o minonas1.com minonasm.nasm
cmp mininasm_debug49.com.good minonas1.com
cat minnnasm.nasm >minnnasm.na  # DOS 8.3 character limit on filename extension.
./kvikdos minnnasm.com -f bin -O9 -o minnnas2.com minnnasm.na
# Check that it's self-hosting: when it compiles itself, it produces the golden good binary.
cmp mininasm_debug49.com.good minnnas2.com
cat minonasm.nasm >minonasm.na  # DOS 8.3 character limit on filename extension.
./kvikdos mininasm.com -f bin -O9 -o minonas3.com minonasm.na
cmp mininasm_debug49.com.good minonas3.com

: "$0" OK.
