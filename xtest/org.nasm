;
; by pts@fazekas.hu at Fri Nov  4 19:57:22 CET 2022
;
; $ nasm-0.98.39 -O0 -f bin -o org.nasm98.bin org.nasm
; $ ndisasm -b 16 -o 0x100 org.nasm98.bin >org.nasm98.ndisasm
;
; $ nasm-0.98.39 -O9 -f bin -o org.nasm98o9.bin org.nasm
; $ ndisasm -b 16 -o 0x100 org.nasm98o9.bin >org.nasm98o9.ndisasm
;
; $ nasm-0.98.39 -O1 -f bin -o org.nasm98o1.bin org.nasm
; $ ndisasm -b 16 -o 0x100 org.nasm98o1.bin >org.nasm98o1.ndisasm
;
; $ nasm-2.13.02 -O0 -f bin -o org.nasm.bin org.nasm
; $ ndisasm -b 16 -o 0x100 org.nasm.bin >org.nasm.ndisasm
;
; $ nasm-2.13.02 -O9 -f bin -o org.nasmo9.bin org.nasm
; $ ndisasm -b 16 -o 0x100 org.nasmo9.bin >org.nasmo9.ndisasm
;
; $ nasm-2.13.02 -O1 -f bin -o org.nasmo1.bin org.nasm
; $ ndisasm -b 16 -o 0x100 org.nasmo1.bin >org.nasmo1.ndisasm
;
; $ ../mininasm -f bin -o org.mininasm.bin org.nasm
; $ ndisasm -b 16 -o 0x100 org.mininasm.bin >org.mininasm.ndisasm
;

		bits 16
		cpu 8086

s$		equ $
s$$		equ $$			; This will be 0x100, even though the `org' is later.
		nop
a$		equ $
a$$		equ $$			; This will be 0x100, even though the `org' is later.

		org 0x100
		nop
b$		equ $
b$$		equ $$

		org 0x100
		nop
c$		equ $
c$$		equ $$

;		org 0x200		; NASM aborts with: error: program origin redefined
;		nop
;d$		equ $
;d$$		equ $$

		org 0x100
		nop
e$		equ $
e$$		equ $$

		mov ax, s$
		mov ax, s$$
		mov ax, a$
		mov ax, a$$
		mov ax, b$
		mov ax, b$$
		mov ax, c$
		mov ax, c$$
;		mov ax, d$
;		mov ax, d$$
		mov ax, e$
		mov ax, e$$
