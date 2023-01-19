;
; hellomin.nasm: minimalistic hello-world for Minix 1.x and 2.x 8086
; by pts@fazekas.hu at Thu Jan 12 04:06:16 CET 2023
;
; Compile: nasm -O0 -f bin -o hellomin hellomin.nasm
; Works with NASM >= 0.98.39.
;
; Compile: mininasm -O0 -f bin -o hellomin hellomin.nasm
;
; The created executable program is 78 bytes.
;
; Compatibility:
;
; * Minix 1.7.5: It works.
; * Minix 2.0.4: It works.
;

		bits 16
		cpu 8086
		;org ... ; Later.

A_FLAG:
.A_EXEC	equ 0x10  ; Executable.
.A_SEP  equ 0x20  ; Separate I/D.

STACK_SIZE equ 0x400  ; 0x380 seems to be too low (fails with `hellomin: Out of space) in ELKS 0.2.0.

minix_header:  ; https://github.com/jbruchon/mins/blob/4ac1ff3fac33160769ca5a1a04aca3cd3d15d746/mins/arch/i86/tools/a.out.h#L6-L67
.a_magic	dw 0x0301  ; A_MAGIC.
.a_flags	db A_FLAG.A_SEP  ; Minix 2.0.4 /bin/sync has A_FLAG.A_SEP.
.a_cpu		db 4  ; A_I8086
.a_hdrlen	db .end-minix_header
.a_unused	db 0
.a_version	dw 0  ; Minix 2.0.4 /bin/sync has 0.
.a_text		dd section_text_end-section_text
.a_data		dd section_data_end-section_data
.a_bss		dd section_bss_end-section_bss
.a_entry	dd _start-section_text
.a_total	dd section_data_end-section_data+section_bss_end-section_bss+STACK_SIZE  ; Is this used at all? It's filled in Minix 2.0.4 /bin/sync.
.a_syms		dd 0  ; Unused.
.end:

section_text:  ; Must follow minix_header.
_start:
do_write:	mov ax, 1  ; FS.
		mov bx, ipcmsg  ; Prefilled with the syscall number and the 3 arguments of write(2).
		mov cx, 3  ; BOTH.
		push bx
		push cx
		int 0x20  ; SYSVEC. Minix 8086 syscall. Also destroys AX, BX, CX, and the entire ipcmsg (except that it puts the result to .m_type).
do_exit:	xor ax, ax  ; MM == 0. (SYSVEC has overwritten AX.)
		pop cx  ; mov cx, 3  ; Needed, SYSVEC has overwritten BX.
		pop bx  ; mov bx, ipcmsg  ; Needed, SYSVEC has overwritten BX.
		mov byte [bx+2], 1  ; [bx+ipcmsg2.m_type-ipcmsg]  ; EXIT. `byte' is enough, Minix sets the high byte to 0 as part of the result.
		mov [bx+4], ax  ; [bx+ipcmsg2.m1_i1-ipcmsg]  ; EXIT_SUCCESS == 0.
		int 0x20  ; SYSVEC. Minix 8086 syscall.
section_text_end:

		org minix_header-$
section_data:  ; Must follow section_text.
msg		db 'Hello, World!', 10
.end:
ipcmsg equ $-2  ; Arbitrary, we reuse the previous 2 bytes.
;.m_source	resw 1
ipcmsg2:
.m_type		dw 4  ; WRITE.
.m1_i1		dw 1  ; STDOUT_FILENO == 1, will be changed to EXIT_SUCCESS == 0.
.m1_i2		dw msg.end-msg
section_data_end:

absolute $
section_bss:  ; Must follow section_data.
ipcmsg3:
.m1_i3		resw 1  ; dw 0  ; Arbitrary.
.m1_p1		resw 1  ; dw msg-section_data  ; 0.
.m1_p2		resw 1
.m1_p3		resw 1
.dummy		resw 4
section_bss_end:
