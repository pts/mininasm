;
; hellohli3.nasm: minimalistic hello-world for Linux i386, with ELF-32 header overlap
; by pts@fazekas.hu at Sat Dec 17 17:17:43 CET 2022
;
; Compile: nasm -O9 -f bin -o hellohli3 hellohli3.nasm && chmod +x hellohli3
; The created executable program is 83 bytes.
; Run on Linux i386 or amd64: ./hellohli3
;
; Inspired by:
;
; * https://pastebin.com/a2RTNhEX (96 bytes)
; * https://www.reddit.com/r/programming/comments/t32i0/comment/c4j4tb7/
; * https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
; * https://github.com/pts/mininasm/blob/310ecf3f9f93bf69ff9e9f64bf722e5e52dc5592/demo/hello/helloli3.nasm (119 bytes)
;
; Compatibility:
;
; * Linux 2.6.20 i386 executes it happily.
; * Linux 5.4.0 amd64 executes it happily.
; * Doesn't work with `objdump -x'.
; * Doesn't run in qemu-i386 ./hellohli3
;

		org 0x80000

%ifndef __MININASM__
		bits 32
		cpu 386
%else  ; Hack for 16-bit assemblers such as mininasm.
		bits 16
		cpu 8086
%endif

ehdr:					; Elf32_Ehdr
		db 0x7f, 'ELF'		;   e_ident[EI_MAG...]
entry:		; We have 10 bytes + the 2 bytes for the `jmp strict short' here.
%ifndef __MININASM__
		xor ebx, ebx
		inc ebx			; EBX := 1 == STDOUT_FILENO.
		lea eax, [ebx-1+4]	; EAX := __NR_write == 4.
		push ebx
		lea edx, [ebx-1+message.end-message]  ; EDX := Size of message to write.
%else
		xor bx, bx		; 31DB  xor ebx, ebx
		inc bx			; 43  inc ebx
		lea ax, [bp+di-1+4]	; 8D4303  lea eax, [ebx-1+4]
		push bx			; 53  push ebx
		lea dx, [bp+di-1+message.end-message]  ; 8D530D  lea edx, [ebx-1+messag.end-message]
%endif
		jmp strict short code2
%if 0  ; The code at `entry' above overlaps with this.
		db 1			;   e_ident[EI_CLASS]: 32-bit
		db 1			;   e_ident[EI_DATA]: little endian
		db 1			;   e_ident[EI_VERSION]
		db 3			;   e_ident[EI_OSABI]: Linux
		db 0			;   e_ident[EI_ABIVERSION]
		db 0, 0, 0, 0, 0, 0, 0	;   e_ident[EI_PAD]
%endif
		dw 2			;   e_type
		dw 3			;   e_machine
		dd 1			;   e_version. Linux doesn't care.
		dd entry		;   e_entry
		dd phdr-$$		;   e_phoff
code2:		; We have 8 bytes + the 2 bytes for the `jmp strict short' here.
%ifndef __MININASM__
		mov ecx, message	; Pointer to message string.
		int 0x80		; Linux i386 syscall.
		pop eax			; EAX := 1 == __NR_exit.
%else
		db 0xb9
		dd message		; B9????0800  mov ecx, message
		int 0x80		; CD80  int 0x80
		pop ax			; 58  pop eax
%endif
		jmp strict short code3
%if 0  ; The code at `code2' above overlaps with this.
		dd 0			;   e_shoff
		dd 0			;   e_flags
		dw .size		;   e_ehsize
%endif
		dw 0x20  ; phdr.size	;   e_phentsize  ; Linux checks this.
%if 0  ; `phdr' below overlaps with this.
		dw 1			;   e_phnum
		dw 40			;   e_shentsize
		dw 0			;   e_shnum
		dw 0			;   e_shstrndx
.size		equ $-ehdr
%endif

phdr:					; Elf32_Phdr
		dd 1			;   p_type
		dd 0			;   p_offset
		dd $$			;   p_vaddr
code3:		; We have 4 bytes here.
%ifndef __MININASM__
		dec ebx			; EBX := 0 == EXIT_SUCCESS.
%else
		dec bx			; 4B  dec ebx
%endif
		int 0x80		; Linux i386 syscall.
		nop			; Not reached.
%if 0  ; The code at `code3' above overlaps with this.
		dd $$			;   p_paddr
%endif
		dd filesize		;   p_filesz
		dd filesize		;   p_memsz
		db 5			;   p_flags: r-x: read and execute, no write
%if 0  ; The message below overlaps with this.
		db 0, 0, 0		;   p_flags, remaining 3 bytes
		dd 0x1000		;   p_align
.size		equ $-phdr
%endif

message:	db 'Hello, World!', 10
.end:

filesize	equ $-$$
