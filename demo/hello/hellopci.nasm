;
; hellopci.nasm: minimalistic hello-world for PC/IX
; by pts@fazekas.hu at Tue Jan 24 05:03:15 CET 2023
;
; Compile: nasm -O0 -f bin -o hellopci hellopci.nasm
; Works with NASM >= 0.98.39.
;
; Compile: mininasm -O0 -f bin -o hellopci hellopci.nasm
;
; The created executable program is 64 bytes.
;
; Compatibility:
;
; * PC/IX 1.0: It works.
;

		bits 16
		cpu 8086
		;org ... ; Later.

A_CPU:  ; Based on /usr/include/a.out.h
.I8086		equ 4  ; Intel 8086 or 8088.

A_FLAGS:  ; Based on /usr/include/a.out.h
.EXEC		equ 0x10  ; executable
.SEP	 	equ 0x20  ; separate I/D
.PURE		equ 0x40  ; pure text

$SYSCALL:  ; PC/IX syscall numbers. Based on /usr/include/sys.s
.exit		equ 1
.write		equ 4

STACK_SIZE	equ 0x100  ; Works.

exec_header:  ; Based on /usr/include/a.out.h
.a_magic	dw 0x301  ; magic number: A_MAGIC0|A_MAGIC1<<3
.a_flags	db A_FLAGS.EXEC|A_FLAGS.SEP|A_FLAGS.PURE  ; flags
.a_cpu		db A_CPU.I8086  ; cpu id
.a_hdrlen	db .end-exec_header  ; length of header
.a_unused	db 0  ; reserved for future use
.a_version	dw 0  ; version stamp
.a_text		dd section_text_end-section_text  ; size of text segment
.a_data		dd section_data_end-section_data  ; size of data segment
.a_bss		dd section_bss_end-section_bss  ; size of bss segment
.a_entry	dd _start-section_text  ; entry point
.a_misc		dd section_data_end-section_data+section_bss_end-section_bss+STACK_SIZE  ; misc., e.g. initial stack pointer
.a_syms		dd 0  ; symbol table size
; Short form ends here. We could waste 0x10 more bytes (4 fields) below.
;.a_trsize	dd 0  ; text relocation size
;.a_drsize	dd 0  ; data relocation size
;.a_tbase	dd 0  ; text relocation base
;.a_dbase	dd 0  ; data relocation base
;.a_lnums	dd 0  ; size of line number section
;.a_toffs	dd 0  ; offset of text from start of file
.end:

section_text:
_start:		mov ax, msg.end-msg
		push ax
		xor ax, ax  ; mov ax, msg
		push ax
		inc ax  ; mov ax, 1  ; STDOUT_FILENO.
		push ax
		push ax  ; Dummy C return address.
		int 0x80+$SYSCALL.write

		xor ax, ax  ; EXIT_SUCCESS.
		push ax
		push ax  ; Dummy C return address.
		int 0x80+$SYSCALL.exit
section_text_end:

		org exec_header-$
section_data:
msg		db 'Hello, World!', 10
.end:
section_data_end:

absolute $
section_bss:  ; Must follow section_data.
		;resb 2
section_bss_end:
