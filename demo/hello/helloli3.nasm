;
; helloli3.nasm: minimalistic hello-world for Linux i386
; by pts@fazekas.hu at Wed Dec  7 04:13:28 CET 2022
;
; Compile: nasm -O9 -f bin -o helloli3 helloli3.nasm && chmod +x helloli3
; The created executable program is 117 bytes.
; Run on Linux i386 or amd64: ./helloli3
;
; Disassemble: ndisasm -b 32 -e 0x54 helloli3
;
; Memory usage: 0x2000 == 8192 bytes (including stack).
;
; Compatibility:
;
; * Linux 2.0 i386 (1996-06-06): It works, tested in Debian 1.1 running in QEMU. Also tested that it doesn't print the message without the `xor ebx, ebx'.
; * Linux 2.6.20 i386 executes it happily.
; * Linux 5.4.0 amd64 executes it happily.
; * qemu-i386 (on Linux, any architecture) executes it happily.
; * FreeBSD 9.3 and 12.04 execute it happily when Linux emulation is active.
; * `objdump -x' can dump the ELF-32 headers.
;
; Copied from https://github.com/pts/minilibc32/blob/650159f22961744bd6a4f59a6aea149cd18f5d00/hello_min.nasm
;
; ELF32 header based on
; https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
;
; To the best knowledge of the author this is the shortest Linux i386
; executable program doing hello-world without overlapping the code and data
; with the ELF32 headers.
;
; More discussion here (with 95-byte solution): https://www.reddit.com/r/programming/comments/t32i0/smallest_x86_elf_hello_world/
;
; More discussion here (with 92-byte solution): https://www.reddit.com/r/programming/comments/t32i0/comment/c4jkpxj/
;

		;org 0x10000 ; Minimum value. Ubuntu 18.04 Linux 5.4.0 has this by default: sudo sysctl vm.mmap_min_addr=65536
		org 0x08048000

ehdr:					; Elf32_Ehdr
		db 0x7f, 'ELF'		;   e_ident[EI_MAG...]
		db 1			;   e_ident[EI_CLASS]: 32-bit
		db 1			;   e_ident[EI_DATA]: little endian
		db 1			;   e_ident[EI_VERSION]
		db 3			;   e_ident[EI_OSABI]: Linux
		db 0			;   e_ident[EI_ABIVERSION]
		db 0, 0, 0, 0, 0, 0, 0	;   e_ident[EI_PAD]
		dw 2			;   e_type == ET_EXEC.
		dw 3			;   e_machine == x86.
		dd 1			;   e_version
		dd _start		;   e_entry
		dd phdr-$$		;   e_phoff
		dd 0			;   e_shoff
		dd 0			;   e_flags
		dw .size		;   e_ehsize
		dw phdr.size		;   e_phentsize
		dw 1			;   e_phnum
		dw 40			;   e_shentsize
		dw 0			;   e_shnum
		dw 0			;   e_shstrndx
.size		equ $-ehdr

phdr:					; Elf32_Phdr
		dd 1			;   p_type == PT_LOAD.
		dd 0			;   p_offset
		dd $$			;   p_vaddr
		dd $$			;   p_paddr
		dd filesize		;   p_filesz
		dd filesize		;   p_memsz
		dd 5			;   p_flags: r-x: read and execute, no write
		dd 0x1000		;   p_align
.size		equ $-phdr

_start:
%ifndef __MININASM__
		bits 32
		cpu 386
		;mov ebx, 1		; STDOUT_FILENO.
		xor ebx, ebx		; EBX := 0. This isn't necessary since Linux 2.2, but it is in Linux 2.0: ELF_PLAT_INIT: https://asm.sourceforge.net/articles/startup.html
		inc ebx			; EBX := 1 == STDOUT_FILENO.
		mov al, 4		; EAX := __NR_write == 4. EAX happens to be 0. https://stackoverflow.com/a/9147794
		push ebx
		mov ecx, message	; Pointer to message string.
		mov dl, message.end-message  ; EDX := size of message to write. EDX is 0 since Linux 2.0 (or earlier): ELF_PLAT_INIT: https://asm.sourceforge.net/articles/startup.html
		int 0x80		; Linux i386 syscall.
		;mov eax, 1		; __NR_exit.
		pop eax			; EAX := 1 == __NR_exit.
		;mov ebx, 0		; EXIT_SUCCESS.
		dec ebx			; EBX := 0 == EXIT_SUCCESS.
		int 0x80		; Linux i386 syscall.
%else  ; Hack for 16-bit assemblers such as mininasm.
		bits 16
		cpu 8086
		xor bx, bx		; xor ebx, ebx
		inc bx			; inc ebx
		mov al, 4		; mov al, 4
		push bx			; push ebx
		db 0xb9
		dd message		; mov ecx, message
		mov dl, message.end-message  ; mov dl, message.end-message
		int 0x80		; int 0x80
		pop ax			; pop eax
		dec bx			; dec ebx
		int 0x80		; int 0x80
%endif
		; Not reached.

; Feel free to change the message within the size limits.
; Minimum message size: 0 bytes.
; Maximum message size: 255 byes (for the `mov dl, ...' to fit).
message:	db 'Hello, World!', 10
.end:

filesize	equ $-$$
