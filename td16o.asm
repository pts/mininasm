; Test sign-extension of various operators. The result should be the same in
; nasm (if there was 16-bit value_t), mininasm. The result should be
; different if value_t is 16-bit vs at-least-32-bit.
;
; Compile: nasm -f bin -o td16o.bin td16o.asm
;
db 1 << 14 >> 14
db 1 << 15 >> 15
db (1 << 8 << 8) / 501
dw -1 / 257
db -1 / 257 / 32767
dw -1 % 257
dw -1 / -257
dw -1 % -257
db 1 / -257
db 1 % -257
dw 13 << 8
db 13 << 16  ; 13 in 16-bit mininasm, 0 in 32-bit nasm and 64-bit nasm.
db 13 << 32  ; 13 in 16-bit mininasm, 13 in 32-bit nasm, 0 in 64-bit nasm.
db 13 << 64  ; 13 in 16-bit mininasm, 32-bit nasm and 64-bit nasm.
%if 1 << 8 << 8
db 'A'
%else
db 'B'
%endif
