;
; hellovnx.nasm: minimalistic hello-world for Venix/86 2.x x.out
; by pts@fazekas.hu at Wed Jan 25 15:46:38 CET 2023
;
; Compile: nasm -O0 -f bin -o hellovnx hellovnx.nasm
; Works with NASM >= 0.98.39.
;
; Compile: mininasm -O0 -f bin -o hellovnx hellovnx.nasm
;
; The created executable program is 67 bytes. !! Try with NMAGIC.
;
; Compatibility:
;
; * Venix/86 2.1: Not tried.
;
; See more in the video: https://archive.fosdem.org/2022/schedule/event/venix/
;

		bits 16
		cpu 8086
		;org ... ; Later.

A_MAGIC:  ; Based on /usr/include/a.out.h
.OMAGIC		equ 0x107  ; old impure format
.NMAGIC		equ 0x109  ; read-only text (seperate I&D)

$SYSCALL:  ; From disassembled .o files in /lib/libc.a.
.exit		equ 1
.write		equ 4

; If STACK_SIZE == 0, then OMAGIC/NMAGIC stack is at offset 0xff80 (0x80 bytes). (See video at 16:12.)
; Otherwise, OMAGIC stack is at offset 0, NMAGIC stack is at offset section_text_end-section_text.
STACK_SIZE	equ 0x100

exec_header:  ; Based on /usr/include/a.out.h
.a_magic	dw A_MAGIC.OMAGIC  ; magic number
.a_stack	dw STACK_SIZE  ; size of stack if Z type, 0 otherwise
.a_text		dd section_text_end-section_text
.a_data		dd section_data_end-section_data
.a_bss		dd section_bss_end-section_bss
.a_syms		dd 0  ; size of symbol table
.a_entry	dd _start  ; entry point; with NMAGIC, this would be `dd _start-section_text'.
.a_trsize	dd 0  ; size of text relocation
.a_drsize	dd 0  ; size of data relocation
.end:

		org exec_header-$+STACK_SIZE  ; OMAGIC with STACK_SIZE > 0.
section_text:
_start:  ; vofs 0x2000.
		mov bx, $SYSCALL.write
		mov ax, 1  ; STDOUT_FILENO.
		mov dx, msg  ; !! size optimization: With NMAGIC, this could be 1 byte shorter: `xor dx, dx`.
		mov cx, msg.end-msg
		int 0xf1

		mov bx, $SYSCALL.exit  ; !! size optimization: Does `bl' instead of `bx' work?
		xor ax, ax  ; EXIT_SUCCESS.
		int 0xf1
section_text_end:

		;org exec_header-$+STACK_SIZE  ; Only for OMAGIC.
section_data:  ; Must follow setion_text.
msg		db 'Hello, World!', 10
.end:
section_data_end:

absolute $
section_bss:  ; Must follow section_data.
		;resb 2
section_bss_end:
