; Test sign-extension of various operators. The result should be the same in
; nasm, mininasm. The result should be the same if value_t is 16-bit, 32-bit
; or 64-bit.
;
; Compile: nasm -f bin -o td16.bin td16.asm
;
db 3 + 4
db -3 * -4
db -13 / -3
db -13 / 3
db 13 / -3
db 13 / 3
db -13 % -3
db -13 % 3
db 13 % -3
db 13 % 3
db (-1 >> 14) & 3
dw 13 << 8
db 1 << 14 >> 14
