#! /bin/sh --
# by pts@fazekas.hu at Thu Apr 20 16:00:04 CEST 2023
set -ex

test "${0##*/*}" || cd "${0%/*}"

MININASM="${MININASM:-../../mininasm}"

for F in ./*.nasm; do
  B="${F%.nasm}"
  if test -f "$B".golden; then :
  elif test -f "$B".exe.golden; then B="$B".exe
  elif test -f "$B".com.golden; then B="$B".com
  elif test -f "$B".cmd.golden; then B="$B".cmd
  elif test -f "$B".wasm.golden; then B="$B".wasm
  fi
  nasm -O0 -f bin -o "$B" "$F"
  cmp -l "$B".golden "$B"
  case "$F" in
   ./he95.nasm) ;;  # Contains `bits 32', mininasm cannot compile it.
   *)
    "$MININASM" -o "$B" "$F"
    cmp -l "$B".golden "$B"
    ;;
  esac
done

: "$0" OK.
