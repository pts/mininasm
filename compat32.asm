;
; compat32.asm: compatibility test input file
; by pts@fazekas.hu at Sun Jul  3 12:35:34 CEST 2022
;
; It should generate the same .bin output file with NASM >= 0.98.39, and
; mininasm. It may generate a different .bin output file with Yasm >= 1.2.0.
;
; It should generate the same .bin output file no matter the integer value
; size (32-bit, 64-bit or longer). If the integer value size is 16-bit, then
; it will generate a different .bin output file.
;
; Compile: nasm -f bin -o td16o.bin td16o.asm
;

db +-+- +   -+-+-+-+-+-+~-+-+-+-+~-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+--1
db ((((((((((  (((((((( (((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((~~4))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) )))))))))))))   )))))))))))))))))))))))))))) )  ;
db ((((1)+2)+3)+4)+5
db ((~~4))
db ~-~~-4
db -~-~~-~5
db -+~+5
db +~-++5
db 0376  ; Decimal, for NASM compatibility.
db 3<<6 | 7<<3 | 6
db 1 << 14 >> 14
db 1 << 15 >> 15
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
dw 13 << 8
db 1 << 14 >> 14
db (-1 >> 14) & 3
db (1 << 8 << 8) / 501
dw -1 / 257
dw ((1 << 16 << 16) - 1) / 3 / 5 / 17 / 257 - 3  ; Result: 0xfffe.
dw -1 % 257
dw -1 / -257
dw -1 % -257
db 1 / -257
db 1 % -257
dw 13 << 8
db 13 << 16  ; 13 in 16-bit mininasm, 0 in 32-bit NASM and 64-bit NASM.
db 13 << 31  ; 13 in 16-bit mininasm, 0 in 32-bit NASM and 64-bit NASM.
db 11 >> 8
db 11 >> 16
db 11 >> 31
db -1234 >> 8
db -1234 >> 16
dd -1
dd 3 * 5 * 17 * 257 * 65537 * -0x1020a0B  ; Result: 0x1020a0b.
%if 1 << 8 << 8
db 'A'
%else
db 'B'
%endif
