;
; hellofli3.nasm: minimalistic hello-world for Linux i386
; by pts@fazekas.hu at Mon Dec 19 22:09:09 CET 2022
;
; Compile: nasm -O9 -f bin -o hellofli3 hellofli3.nasm && chmod +x hellofli3
; The created executable program is 104 bytes.
; Run on Linux i386 or amd64: ./hellofli3
;
; Disassemble: ndisasm -b 32 -e 0x54 hellofli3
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
; ELF32 header based on
; https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html
;

		;org 0x10000 ; Minimum value. Ubuntu 18.04 Linux 5.4.0 has this by default: sudo sysctl vm.mmap_min_addr=65536
		org 0x08048000

%ifndef __MININASM__
		bits 32
		cpu 386
%else  ; Hack for 16-bit assemblers such as mininasm.
		bits 16
		cpu 8086
%endif

ehdr:					; Elf32_Ehdr
		db 0x7f, 'ELF'		;   e_ident[EI_MAG...]
		db 1			;   e_ident[EI_CLASS]: 32-bit
		db 1			;   e_ident[EI_DATA]: little endian
		db 1			;   e_ident[EI_VERSION]
		db 3			;   e_ident[EI_OSABI]: Linux
		db 0			;   e_ident[EI_ABIVERSION]
entry:		; We have 5 bytes + the 2 bytes for the `jmp strict short' here.
%ifndef __MININASM__
		mov ecx, message	; Pointer to message string.
%else
		db 0xb9
		dd message		; B9????0800  mov ecx, message
%endif
		jmp strict short code2
%if 0  ; The code at `entry' above overlaps with this.
		db 0, 0, 0, 0, 0, 0, 0	;   e_ident[EI_PAD]
%endif
		dw 2			;   e_type == ET_EXEC.
		dw 3			;   e_machine == x86.
		dd 1			;   e_version
		dd entry		;   e_entry
		dd phdr-$$		;   e_phoff
		dd 0			;   e_shoff
		dd 0			;   e_flags
		dw 0x34  ; ehdr.size	;   e_ehsize; qemu-i386 fails with ``Invalid ELF image for this architecture'' if this value isn't 0x34.
		dw 0x20  ; phdr.size	;   e_phentsize; Linux fails with `Exec format error' if it isn't 0x20. qemu-i386 fails with ``Invalid ELF image for this architecture'' if this value isn't 0x20.
%if 0  ; `phdr' below overlaps with this.
		dw 1			;   e_phnum
		dw 0			;   e_shentsize
		dw 0			;   e_shnum
		dw 0			;   e_shstrndx
.size		equ $-ehdr
%endif

phdr:					; Elf32_Phdr              ELF32_Ehdr (continued):
		dw 1			;   p_type == PT_LOAD.      e_phum
		dw 0			;   High word of p_type.    e_shentsize
		dw 0			;   p_offset                e_shnum
		dw 0			;   High word of p_offset.  e_shnum
		dd $$			;   p_vaddr
		dd $$			;   p_paddr
		dd filesize		;   p_filesz
		dd filesize		;   p_memsz
		dd 5			;   p_flags: r-x: read and execute, no write
		dd 0x1000		;   p_align
.size		equ $-phdr

code2:
%ifndef __MININASM__
		;mov ebx, 1		; STDOUT_FILENO.
		xor ebx, ebx		; EBX := 0. This isn't necessary since Linux 2.2, but it is in Linux 2.0: ELF_PLAT_INIT: https://asm.sourceforge.net/articles/startup.html
		inc ebx			; EBX := 1 == STDOUT_FILENO.
		mov al, 4		; EAX := __NR_write == 4. EAX happens to be 0. https://stackoverflow.com/a/9147794
		push ebx
		mov dl, message.end-message  ; EDX := size of message to write. EDX is 0 since Linux 2.0 (or earlier): ELF_PLAT_INIT: https://asm.sourceforge.net/articles/startup.html
		int 0x80		; Linux i386 syscall.
		;mov eax, 1		; __NR_exit.
		pop eax			; EAX := 1 == __NR_exit.
		;mov ebx, 0		; EXIT_SUCCESS.
		dec ebx			; EBX := 0 == EXIT_SUCCESS.
%else  ; Hack for 16-bit assemblers such as mininasm.
		xor bx, bx		; xor ebx, ebx
		inc bx			; inc ebx
		mov al, 4		; mov al, 4
		push bx			; push ebx
		mov dl, message.end-message  ; mov dl, message.end-message
		int 0x80		; int 0x80
		pop ax			; pop eax
		dec bx			; dec ebx
%endif
		int 0x80		; Linux i386 syscall.
		; Not reached.

message:	db 'Hello, World!', 10
.end:

filesize	equ $-$$
