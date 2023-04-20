#! /bin/sh --
# by pts@fazekas.hu at Tue Dec 13 00:34:54 CET 2022
set -ex

if test $# = 0; then
  set x syntax new186 xchg jmpdist arbyte cjump cmpax ifdef iopt org reg simple jmpopt lateorg
  shift
fi

test "${0##*/*}" || cd "${0%/*}"

# !! TODO(pts): Also test with -O1. What to comare against?
for F in "$@"; do
  nasm-0.98.39 -O9 -f bin -o "$F".nasm98o9.bin "$F".nasm
  nasm-0.98.39 -DO01=1 -DO0=1 -O0 -f bin -o "$F".nasm98.bin "$F".nasm
  ndisasm -b 16 -o 0x100 "$F".nasm98.bin >"$F".nasm98.ndisasm
  ndisasm -b 16 -o 0x100 "$F".nasm98o9.bin >"$F".nasm98o9.ndisasm
  ../mininasm -DO01=1 -DO0=1 -f bin -o "$F".mininasm.bin "$F".nasm
  ../mininasm -DO01=1 -O1 -f bin -o "$F".mininasmo1.bin "$F".nasm  # Not compared against anything.
  ../mininasm -O9 -f bin -o "$F".mininasmo9.bin "$F".nasm
  ndisasm -b 16 -o 0x100 "$F".mininasm.bin >"$F".mininasm.ndisasm
  ndisasm -b 16 -o 0x100 "$F".mininasmo1.bin >"$F".mininasmo1.ndisasm
  ndisasm -b 16 -o 0x100 "$F".mininasmo9.bin >"$F".mininasmo9.ndisasm
  diff -U999999999 "$F".nasm98.ndisasm "$F".mininasm.ndisasm
  diff -U999999999 "$F".nasm98o9.ndisasm "$F".mininasmo9.ndisasm
done

: "$0" OK.
