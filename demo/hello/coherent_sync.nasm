;
; coherent_sync.nasm: reimplementation of the sync(1) tool of Coherent 3.2 in NASM
; by pts@fazekas.hu at Thu Jan 19 14:36:38 CET 2023
;
; Compile: nasm -O0 -f bin -o coherent_sync coherent_sync.nasm
; Works with NASM >= 0.98.39.
;
; Compile: mininasm -O0 -f bin -o coherent_sync coherent_sync.nasm
;
; The created executable program is 126 bytes.
;
; Compatibility:
;
; * Coherent 3.2: It works. Indeed, it is bitwise identical to /bin/sync.
;
; Based on: https://www.autometer.de/unix4fun/coherent/coh_qemu.html
;
; Based on executables and sources found in: https://www.autometer.de/unix4fun/coherent/ftp/vms/pcem-coherent-3.2-NOV-2020.img.gz
;

		bits 16
		cpu 8086
		;org ... ; Later.

; /usr/include/l.out.h defines the header file format for executables and
; object files.

LF:  ; l_flag flags.
.$SHR		equ 1			; Bound shared.
.SEP		equ 2			; Bound separated.
.NRB		equ 4			; No relocations.
.KER		equ 8			; Loadable driver.

coherent_ldheader:  ; `struct ldheader'. 44 == 0x2c bytes.
.l_magic	dw 0x107		; L_MAGIC == 0407 == 0x107. Signature.
.l_flag		dw LF.SEP|LF.NRB	; Flags.
.l_machine	dw 6			; M_8086 == 6. Target machine.
.l_entry	dw _start-section_text	; Entry point.
; These dwords are stored in the Coherent ``canonical format'', i.e. words
; swapped: 0xAABBCCDD is stored as `db 0xBB, 0xAA, 0xDD, 0xCC' ==
; `dw 0xAABB, 0xCCDD'.
.l_SHRI		dw 0, (section_text_end-section_text+1)&~1  ; Shared Instruction space.
.l_PRVI		dw 0, 0			; Private Instruction space.
.l_BSSI		dw 0, 0			; Uninitialised Instruction.
.l_SHRD		dw 0, (section_data_end-section_data+1)&~1  ; Shared Data space.
.l_PRVD		dw 0, (section_prvd_end-section_prvd+1)&~1  ; Private Data space.
.l_BSSD		dw 0, (section_bss_end-section_bss+1)&~1  ; Uninitalised Data.
.l_DEBUG	dw 0, 0			; Debug tables.
.l_SYM		dw 0, 0			; Symbols.
.l_REL		dw 0, 0			; Relocation.
; Stack size is not indicated in the header.
.end:

NR:  ; Coherent 3.2 syscall numbers.
.exit		equ 1
.sync		equ 36

section_text:  ; Must follow coherent_ldheader.
; Based on lib/libc/csu/crts0.s.
_start:		jmp strict short .target34
		dw 0  ; Why?
		dw 0
		dw 0
.target34:	mov word [dummy_data], 0  ; Why clear? It's already 0.
		dw 0xec8b  ; Coherent as(1) mov bp, sp
		mov ax, [bp+4]
		mov [environ_], ax
		call main_
		push ax
		call exit_
_exit_:	 ; No cleanups, _exit(2).
		int 0x80+NR.exit  ; Coherent syscall.
		int3  ; `int3' alignment emitted by the linker ld(1).
; Based on bin/sync/sync.c.
main_:		push si
		push di
		push bp
		dw 0xec8b  ; Coherent as(1) mov bp, sp
		call sync_
		pop bp
		pop di
		pop si
		ret
; Based on lib/libc/stdio/exit.c.
exit_:  ; Does the cleanups. Exit code in [bp+2].
		push si
		push di
		push bp
		dw 0xec8b  ; Coherent as(1) mov bp, sp
		call _finish
		push word [bp+8]  ; Exit code.
		call _exit_
		add sp, strict byte 2
		pop bp
		pop di
		pop si
		ret
		db 0  ; `int3' alignment emitted by the C compiler cc(1).
; Based on lib/libc/stdio/_finish.c.
; No-op implementation because standard I/O is not used.
_finish:	ret
		db 0  ; `int3' alignment emitted by the C compiler cc(1).
; Based on lib/libc/sys/i8086/old/sync.s.
sync_:		int 0x80+NR.sync  ; Coherent syscall.
		ret
		int3  ; `int3' alignment emitted by the linker ld(1).
section_text_end:
		times ($$-$)&1 db 0  ; Align to even.

		org coherent_ldheader-$
section_data:  ; Must follow section_text.
; Based on lib/libc/csu/crts0.s.
dummy_data	dw 0, 0, 0, 0  ; What is stored in here?
section_data_end:
		times ($$-$)&1 db 0  ; Align to even.

section_prvd:  ; Private data. Must follow section_data.
; Based on lib/libc/csu/crts0.s.
environ_	dw 0  ; Why not in bss?
section_prvd_end:
		times ($$-$)&1 db 0  ; Align to even.

absolute $
section_bss:  ; Must follow section_prvd.
section_bss_end:

; __END__
