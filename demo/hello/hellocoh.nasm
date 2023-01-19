;
; hellocoh.nasm: minimalistic hello-world for Coherent 3.x
; by pts@fazekas.hu at Thu Jan 19 15:31:30 CET 2023
;
; Compile: nasm -O0 -f bin -o hellocoh hellocoh.nasm
; Works with NASM >= 0.98.39.
;
; Compile: mininasm -O0 -f bin -o hellocoh hellocoh.nasm
;
; The created executable program is 72 bytes.
;
; Compatibility:
;
; * Coherent 3.2: Untested, but it should work. TODO(pts): Test it.
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
.write		equ 4

section_text:  ; Must follow coherent_ldheader.
_start:		mov ax, msg.end-msg
		push ax			; Coherent 3.x syscall ABI: push last arg first.
		xor ax, ax  ; mov ax, msg
		push ax
		inc ax  ; mov ax, 1	; STDOUT_FILENO.
		push ax
		int 0x80+NR.write	; Coherent syscall.
		int 0x80+NR.exit	; Coherent syscall.
		; Not reached.
section_text_end:
		times ($$-$)&1 db 0  ; Align to even.

		org coherent_ldheader-$
section_data:  ; Must follow section_text.
msg		db 'Hello, World!', 10
.end:
section_data_end:
		times ($$-$)&1 db 0  ; Align to even.

section_prvd:  ; Private data. Must follow section_data.
section_prvd_end:
		times ($$-$)&1 db 0  ; Align to even.

absolute $
section_bss:  ; Must follow section_prvd.
section_bss_end:

; __END__
