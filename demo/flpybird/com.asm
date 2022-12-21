;
; Compile: nasm -O9 -f bin -o flpybird.com com.asm
;
; Compile: mininasm -O9 -f bin -o flpybird.com com.asm
;
; The compiled flpybird.com is bitwise identical to the released version.
;

%define COM 1
%define SECTORS 16				; keep it under 18
%assign IMAGE_SIZE ((SECTORS + 1) * 512)	; SECTORS + 1 (~= 18) * 512 bytes

bits 16		; 16 bit mode
org 100h	; entry point "address"
cpu 186		; Some instructions need `cpu 386', will be marked later.

; entry point
_start:
	call main	; call main
	jmp $		; loop forever

; mixin sys and main
%include 'sys/txt.asm'
%include 'sys/tmr.asm'
%include 'sys/rnd.asm'
%include 'sys/snd.asm'
%include 'sys/vga.asm'
%include 'main.asm'

times IMAGE_SIZE - ($ - $$) db 0	; pad to IMAGE_SIZE
