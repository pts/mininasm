;
; incompat.asm: incompatibility test input file
; by pts@fazekas.hu at Sun Jul  3 12:35:34 CEST 2022
;
; It may generate the same .bin output file in NASM >= 0.98.39, Yasm >= 1.2
; and mininasm, depending on the version and the integer value size.
;

db 0d376  ; Decimal, for NASM 0.99.06 compatibility. NASM 0.98.39 doesn't support it.
db 0o376  ; NASM 0.98.39 doesn't have any octal literal syntax; NASM 0.99.06 supports 0o... as octal; 0376 is just decimal in both.
db -1 / 257 / 32767  ; Different, based on 16-bit, 32-bit and 64-bit.
db 13 << 32  ; Error in 16-bit mininasm, 13 in 32-bit NASM, 0 in 64-bit NASM.
db 13 << 64  ; Error in 16-bit mininasm, 32-bit NASM and 64-bit NASM.
db -1234 >> 31  ; 0 in 16-bit mininasm, 1 in 32-bit NASM, 255 in 64-bit NASM.
db 11 >> 32  ; Error in 16-bit mininasm.
db 11 >> 64  ; Error in 16-bit mininasm.
