;
; unstable.nasm: a NASM source files whose labels cannot be stabilized
; by pts@fazekas.hu at Mon Dec 12 03:26:19 CET 2022
;
; It fails with -DREP=66 (default):
;
;   $ ../mininasm  -O99 -f bin -o unstable.bin unstable.nasm
;   error: Aborted: Couldn't stabilize moving label
;   $ nasm-0.98.39 -O99 -f bin -o unstable.bin unstable.nasm
;   unstable.nasm:11: error: phase error detected at end of assembly.
;   $ nasm-2.13.02 -Ox  -f bin -o unstable.bin unstable.nasm
;   nasm: error: Can't find valid values for all labels after 1000 passes, giving up.
;   nasm: error: Possible causes: recursive EQUs, macro abuse.
;
; It succeeds with any other value (e.g. -DREP=65);
;
;   $ ../mininasm  -DREP=65 -O99 -f bin -o unstable.bin unstable.nasm
;   $ nasm-0.98.39 -DREP=65 -O99 -f bin -o unstable.bin unstable.nasm
;   $ nasm-2.13.02 -DREP=65 -Ox  -f bin -o unstable.bin unstable.nasm
;
; Here is why it can't be stabilized with -DREP=66:
;
; * If the `a: jmp c' jump is 2 bytes (b-a == 2), then c-b <= 127 (because
;   of the jump delta limit to signed 8-bit), and also c-b == (a-b+66)*2
;   (because that's how `times' works), so (a-b)*2+132 <= 127, so b-a >= 2.5,
;   but b-a == 2.
; * If the `a: jmp c' jump is 3 bytes (b-a == 3), then c-b >= 128 (because
;   that's how NASM optimizes jumps, it's not an inherent limitation of 8086
;   machine language), and also c-b == (a-b+66)*2
;   (because that's how `times' works), so (a-b)*2+132 >= 128, so b-a <= 2,
;   but b-a == 3.
; * It could be stabilized by writing `a: jmp near c' instead of `a: jmp c'.
;   In that case b-a == 3, c-b == 2*(a-b+66) == 126, and thus a suboptimal
;   3-byte jump is used, but at least it would compile. Neither NASM nor
;   mininasm is smart enough to generate such code.
;

%ifndef REP
%define REP 66
%endif

		bits 16
		cpu 8086

a:		jmp c
b:		times a-b+REP dw 0x9090  ; Double nops.
c:
