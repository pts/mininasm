;
; elf.inc.nasm: NASM macros for creating ELF executable programs
; by pts@fazekas.hu at Sun Apr 10 15:30:34 CEST 2022
;
; elf.inc.nasm is a collection of NASM macros for creating ELF executable
; programs (typically for Linux i386 and Linux amd64) in assembly language.
; It supports generating the executable program file directly using NASM (or
; Yasm), without creating object files or using a linker. It also creates
; tiny ELF headers without bloat or unnecessary overhead.
;
; Use elf.inc.nasm like this in your .nasm source file:
;
;   %include 'elf.inc.nasm'
;   _elf_start 32, Linux
;   _start: mov eax, 1  ; __NR_exit.
;           mov bl, 42  ; Exit code, only the bottom 8 bits matter.
;           int 0x80  ; Linux i386 system call.
;   _end
;
; The special lines above are the 2 lines (%include and _elf_start) in the
; beginning and the final line (_end).
;
; 64-bit Linux .nasm source file example:
;
;   %include 'elf.inc.nasm'
;   _elf_start 64, Linux
;   _start: mov eax, 60  ; __NR_exit.
;           mov bl, 42  ; Exit code, only the bottom 8 bits matter.
;           syscall  ; Linux amd64 system call.
;   _end
;
; Compile it with NASM (>=0.98.39 for 32-bit ELF and >=0.99.00 for 64-bit
; ELF):
;
;   nasm -O0 -f bin -o prog.elf prog.nasm
;
; Alternatively, compile it with Yasm 1.2.0 or 1.3.0:
;
;   yasm -O0 -f bin -o prog.elf prog.nasm
;
; If you forget to add _end to the end of your .nasm source file, you'll
; get: ``error: symbol `__text_end' undefined''.
;
; If you add something non-resb after the _end, you'll get: ``warning:
; attempt to initialize memory in a nobits section: ignored''.
;
; For debugging, disassemble .text + .data with ndisasm (part of NASM):
;
;   ndisasm -b 32 -e 0x54 -o 0x08048054 prog.elf
;
; For debugging, disassemble .text + .data with ndisasm (part of NASM):
;
;   ndisasm -b 64 -e 0x78 -o 0x400078 prog.elf
;
; The `-o ...' offsets above may vary depending of the extra phdrs.
;
; elf.inc.nasm supports 3 sections: `section .text' (default, contains code,
; currently it's executable and read-write), `section .data' (contains
; read-write initialized data) and `section .bss' (contains read-write
; uninitialized data). It also adds single-line macros _data and _bss to
; add a single line to .data or .bss, respectively. Examples:
;
;   _data answer: dd 42
;   _bss tmp: resd 1  ; 1 doubleword (4 bytes)
;
; Or, equivalently:
;
;   section .data
;   answer: dd 42
;   section .bss
;   tmp: resd 1
;   section .text  ; Back to .text.
;
; `section' directives and `_data' and `_bss' lines can appear many times
; and can be mixed with program code.
;

; Emit sections .text (rx), .rodata (r), .data (rw) and .bss (rw) separatley,
; on separate memory pages. This is a security feature. This implements W^X
; mandated by OpenBSD >=6.0, and is enabled by default for %1==OpenBSD.
%define _ELF_SFLAG_sect_many 0x200
; Add a PT_NOTE tag describing the operating system ABI version. This is
; enabled for %1==NetBSD, because otherwise it doesn't load the executable
; program.
%define _ELF_SFLAG_abi_tag 0x400
; Make the stack non-executable. This is a security feature. It is respected by
; Linux, FreeBSD and DragonFlyBSD (!! test). (Other systems may ignore it.)
; OpenBSD has this always on.
%define _ELF_SFLAG_stack_nx 0x800
; Make .text, .data, .rodata and .bss read-only. The stack remains
; read-write. This is a security feature, but please use sect_many (with or
; without this), it provides better security.
;
; FYI If sect_many+sect_ro are both specified, .data will have only read
; permission. Linux i386 (kernel 5.4.0, amd64) segfaults for that, even though
; the NX bit could work with PAE. Some more operating system support on
; r-- .data:
;
; * All amd64 releases support and enforce it.
; * Linux i386 (kernel 5.4.0 for amd64, Ubuntu 18.04) segfaults at
;   executable program load time.
; * OpenBSD 4.0 and 6.0 i386 supports and enforces it.
; * FreeBSD 12.3 i386 supports and enforces it.
; * xv6 ignores PHDR permissions.
%define _ELF_SFLAG_sect_ro 0x1000
; If specified, add a non-zero e_shentsize ELF header field. This is to match
; GNU ld.
%define _ELF_SFLAG_shentsize 0x2000
; Align end of bss vaddr to multiple of 4? To match GNU ld 2.30.
%define _ELF_SFLAG_bss_end_align4 0x4000

%macro __elf_define_align_and_sflags 1
__save_macros sect_many, abi_tag, stack_nx, sect_ro, shentsize, bss_end_align4
%assign sect_many _ELF_SFLAG_sect_many
%assign abi_tag _ELF_SFLAG_abi_tag
%assign stack_nx _ELF_SFLAG_stack_nx
%assign sect_ro _ELF_SFLAG_sect_ro
%assign shentsize _ELF_SFLAG_shentsize
%assign bss_end_align4 _ELF_SFLAG_bss_end_align4
%assign _PROG_ALIGN (%1) & 0x1ff
%assign _PROG_SFLAGS (%1) & ~0x1ff
__restore_macros
%endm

; Saves the definitions of a few macros so that they can be restored by
; __restore_macros. It supports only macros without arguments. It has a side
; effect of using %xdefine (full expansion).
%macro __save_macros 1+
%define __SAVEDS %1
__save_macros_low %1
%endm
%macro __save_macros 0
%define __SAVEDS
%endm

%macro __save_macros_low 0-*
%rep %0
%ifdef %1
; %defalias would be better, because it expands less, but even NASM 2.13.02 doesn't support it.
%xdefine __SAVED_%1 %1
%else
%undef __SAVED_%1
%endif
%rotate 1
%endrep
%endm

; Restores macros saved by __save_macros.
%macro __restore_macros 0
__restore_macros_low __SAVEDS
%endm

%macro __restore_macros_low 0-*
%rep %0
%ifdef __SAVED_%1
%xdefine %1 __SAVED_%1 %1
%undef __SAVED_%1
%endif
%rotate 1
%endrep
%endm

; ---

; Same as what GNU ld 2.30 does on Linux with `ld -m elf_i386'.
;
; Args:
;     %1: ELF architecture bits (32 or 64).
;     %2: Alignment of the .data and .bss sections (1, 2, 4, 8, 16, 32, 64,
;         128 or 256). The default (0) is 4 for 32-bit and 8 for 64-bit.
%macro _elf_start_ld 1-2 0
_elf_start (%1), SystemV, (%2)|sect_many|shentsize|bss_end_align4
%endm


%macro __elf_set_bits 0
bits _PROG_CPU_BITS
%ifndef _ELF_PROG_CPU_UNCHANGED
%if _PROG_CPU_BITS == 32
cpu 386  ; Later can be changed to 386, 486, 586 (PENTIUM), 686 (P6, PPRO).
%elif _PROG_CPU_BITS == 64
%ifdef __YASM_MAJOR__
cpu 686 amd
%else
cpu x64
%endif
%else  ; _PROG_CPU_BITS
%error unknown ELF CPU bits: _PROG_CPU_BITS
bits 0  ; Enforce the error in NASM 0.98.* and 0.99.*.
%endif  ; _PROG_CPU_BITS
%endif  ; ifndef _ELF_PROG_CPU_UNCHANGED
%endm

%ifidn __OUTPUT_FORMAT__,bin

; --- ELF-specific definitions.

%define _ELF_OS_SystemV  0
%define _ELF_OS_Linux    3
%define _ELF_OS_Solaris  6
%define _ELF_OS_FreeBSD  9
%define _ELF_OS_Minix    0  ; Uses SystemV.
%define _ELF_OS_xv6      0  ; Uses SystemV.
%define _ELF_OS_NetBSD   2
%define _ELF_OS_OpenBSD  0xc
%define _ELF_OS_DragonFlyBSD 0  ; Uses SystemV, DragonFlyBSD 6.2.1 doesn't accept FreeBSD.

; Args:
;     %1: ELF architecture bits (32 or 64). Can also be arm32 etc for non-x86.
;     %2: Operating system (SystemV or Linux) to put to the ELF header.
;     %3: Alignment of the .data and .bss sections (1, 2, 4, 8, 16, 32, 64,
;         128 or 256). The default (0) is 4 for 32-bit and 8 for 64-bit. This
;         can be or-ed with or added to some flags (e.g. sect_many and
;         abi_tag). Example: 4+sect_many.
%macro _elf_start 2-3 0
__elf_define_align_and_sflags %3
;
%if _PROG_ALIGN && _PROG_ALIGN & (_PROG_ALIGN - 1)
%error bad ELF section alignment: _PROG_ALIGN
bits 0  ; Enforce the error in NASM 0.98.* and 0.99.*.
%assign _PROG_ALIGN 1
%endif
;
%ifdef _ELF_SECT_RO_MASK
%assign _ELF_SECT_RO_MASK _ELF_SECT_RO_MASK
%elif _PROG_SFLAGS & _ELF_SFLAG_sect_ro
%assign _ELF_SECT_RO_MASK ~2  ; Non-writable.
%else
%assign _ELF_SECT_RO_MASK ~0  ; Keep it as is.
%endif
%assign _ELF_SECT_NX_RO_MASK 0
;
%undef _ELF_MACHINE
%define _ELF_FLAGS 0
%define _ELF_PAGE_SIZE 0x1000  ; Must be a power of 2. Guessing a larger page size is OK.
%assign _ELF_OS _ELF_OS_%2
%ifidn %1,arm32  ; Compatible with all Raspberry Pi models. Linux architecture armhf.
%define _PROG_BITS 32
%define _PROG_CPU_BITS 32
%define _ELF_MACHINE 0x28
%define _ELF_FLAGS 0x05000400  ; EABI5
%define _ELF_ORG 0x10000  ; GCC default.
%elifidn %1,arm64  ; Compatible with Raspberry Pi 3B, 3B+, 3A+, 4, 400, CM3, CM3+, CM4, Zero 2 W. Linux architecture aarch64.
%define _PROG_BITS 64
%define _PROG_CPU_BITS 32
%define _ELF_MACHINE 0xb7
%define _ELF_ORG 0x400000  ; GNU ld default. For Raspbian, GCC generates lower, e.g. 0x3000.
%elifidn %1,powerpc64_le
%define _PROG_BITS 64
%define _PROG_CPU_BITS 32
%define _ELF_MACHINE 0x15
%define _ELF_ORG 0x10000000  ; GNU ld default.
%elifidn %1,riscv32
%define _PROG_BITS 32
%define _PROG_CPU_BITS 32
%define _ELF_MACHINE 0xf3
; There are some _ELF_FLAGS, but we don't need them.
%define _ELF_ORG 0x10000  ; GNU ld default.
%elifidn %1,riscv64
%define _PROG_BITS 64
%define _PROG_CPU_BITS 32
%define _ELF_MACHINE 0xf3
%define _ELF_ORG 0x10000  ; GNU ld default.
%else
%assign _PROG_BITS %1
%assign _PROG_CPU_BITS _PROG_BITS
%if _PROG_BITS == 32
%ifidn %2,Linux
%assign _ELF_SECT_NX_RO_MASK 2  ; As a workaround, make .data and .rodata writeable. (gcc makes .rodata executable instead.)
%define _ELF_ORG 0x08048000  ; GCC default on Linux.
%elifidn %2,xv6
%define _ELF_ORG 0  ; xv6 default.
%else
;%define _ELF_ORG 0x08050000  ; GCC default on OpenSolaris.
%define _ELF_ORG 0x08048000  ; GCC default on Linux.
%endif
%else
%define _ELF_ORG 0x400000  ; GCC default.
%endif
%endif
;
__elf_set_bits
;
%if (_PROG_SFLAGS & _ELF_SFLAG_shentsize) == 0
%define _ELF_SHENTSIZE 0
%endif
;
%if _PROG_BITS == 32
%ifndef _ELF_SHENTSIZE
%define _ELF_SHENTSIZE 40  ; Match GNU ld.
%endif
%if _PROG_ALIGN == 0
%assign _PROG_ALIGN 4
%endif
%ifndef _ELF_MACHINE
%define _ELF_MACHINE 3
%endif
%elif _PROG_BITS == 64
%ifndef _ELF_SHENTSIZE
%define _ELF_SHENTSIZE 40  ; Match GNU ld.
%endif
%if _PROG_ALIGN == 0
%assign _PROG_ALIGN 8 ; GCC uses an alignment depending on the actual data. For uint64_t, the alignment is 8.
%endif
%ifndef _ELF_MACHINE
%define _ELF_MACHINE 0x3e
%endif
%else  ; _PROG_BITS
%error unknown ELF bits: _PROG_BITS
bits 0  ; Enforce the error in NASM 0.98.* and 0.99.*.
%assign _ELF_MACHINE 0  ; Fallback.
%endif  ; _PROG_BITS
;
%ifndef _ELF_SHENTSIZE
%define _ELF_SHENTSIZE 0
%endif
;
%ifdef _ELF_EMIT_ABI_TAG
%assign _ELF_EMIT_ABI_TAG _ELF_EMIT_ABI_TAG
%elifidn %2,NetBSD
%assign _ELF_EMIT_ABI_TAG 1
%else
%assign _ELF_EMIT_ABI_TAG (_PROG_SFLAGS & _ELF_SFLAG_abi_tag) / _ELF_SFLAG_abi_tag
%endif
;
%ifdef _ELF_EMIT_GNU_STACK
%assign _ELF_EMIT_GNU_STACK _ELF_EMIT_GNU_STACK
%elifidn %2,OpenBSD
; OpenBSD >=3.2 (and thus also all ELF OpenBSDs) has non-executable stack
; implicitly, the PT_GNU_STACK phdr is ignored, so we won't even generate it.
%assign _ELF_EMIT_GNU_STACK 0
%else
%assign _ELF_EMIT_GNU_STACK (_PROG_SFLAGS & _ELF_SFLAG_stack_nx) / _ELF_SFLAG_stack_nx
%endif
;
%ifndef _ELF_EMIT_SECT_MANY
%ifidn %2,OpenBSD
%if _ELF_SECT_RO_MASK == ~0
; OpenBSD >=6.0 mandates W^X (no section with wx+ permissions), which we
; implement here by turning sect_many on if sect_ro is not on. sect_many is
; the more secure choice.
;
; Please note that W^X doesn't mean that only code that can be executed is in
; the .text section. Some exceptions:
;
; * The .ehdr and .phdr sections are also mapped to the same page (of
;   _ELF_PAGE_SIZE bytes) as .text, so code accidentally residing there can
;   be executed.
; * The last partial page of the .text section may overlap (in the file) the
;   beginning of the .rodata, .data and .bss sections, so code accidentally
;   residing there can be executed. (This is confirmed on Linux.) To fix it,
;   add `times ($$-$) & (_ELF_PAGE_SIZE - 1) nop' to the end of .text,
;   making the executable program longer.
; * Code in dynamically allocated memory using mmap(2) with PROT_EXEC can be
;   executed. This can't happen if your program doesn't call mmap(2) or
;   similar.
%define _ELF_EMIT_SECT_MANY 1
%endif
%endif
%endif
%ifdef _ELF_EMIT_SECT_MANY
%assign _ELF_EMIT_SECT_MANY _ELF_EMIT_SECT_MANY
%else
%assign _ELF_EMIT_SECT_MANY (_PROG_SFLAGS & _ELF_SFLAG_sect_many) / _ELF_SFLAG_sect_many
%endif
;
%define _ELF_HAVE_NOTE 0
;
; Creates an Elf32_Phdr or Elf64_Phdr entry.
; %1: p_type, %2: p_flags (or of: 1=executable, 2=writable, 4=readable),
; %3: p_offset Within the file, %4: p_vaddr == p_paddr Memory load address.,
; %5: p_filesz Size within file, %6: p_memsz Size in memory,
; %7: p_align As power of 2.
; Invariant: p_vaddr % p_align == p_offset % p_align.
%if _PROG_BITS == 64
%if 1 << 31 << 1 == 0  ; 32-bit NASM without dq, e.g. NASM 0.98.39. Zero-extend.
%define _ELF_PHDR(p_type, p_flags, p_offset, p_vaddr, p_filesz, p_memsz, p_align) dd (p_type), (p_flags) << 32, (p_offset), 0, (p_vaddr), 0, (p_vaddr), 0, (p_filesz), 0, (p_memsz), 0, (p_align), 0
%define _ELF_DADDR(x) dd (x), 0
%else
%define _ELF_PHDR(p_type, p_flags, p_offset, p_vaddr, p_filesz, p_memsz, p_align) dq (p_type) | (p_flags) << 32, (p_offset), (p_vaddr), (p_vaddr), (p_filesz), (p_memsz), (p_align)
%define _ELF_DADDR(x) dq (x)
%endif
%else
%define _ELF_PHDR(p_type, p_flags, p_offset, p_vaddr, p_filesz, p_memsz, p_align) dd (p_type), (p_offset), (p_vaddr), (p_vaddr), (p_filesz), (p_memsz), (p_flags), (p_align)
%define _ELF_DADDR(x) dd (x)
%endif
;
%ifdef __YASM_MAJOR__  ; Yasm. For correct memsz calculation of .bss.
%define NOBITS_VFOLLOWS(x) vfollows=x
%else  ; NASM. It fails for sections with `nobits vfollows=...'.
%define NOBITS_VFOLLOWS(x)
%endif
section .ehdr align=1 valign=1 progbits vstart=_ELF_ORG
__ehdr:
section .phdr align=1 valign=1 progbits follows=.ehdr vfollows=.ehdr
__phdr:
section .notes align=1 valign=1 progbits follows=.phdr vfollows=.phdr
__notes:
;org _ELF_ORG  ; We use `vstart=' instead. This is ignored.
section .text align=1 valign=1 progbits follows=.notes vfollows=.notes
__text:
%ifdef __YASM_MAJOR__  ; This works in Yasm.
section .rodata_gap align=1 nobits follows=.footer NOBITS_VFOLLOWS(.text)  ; NASM error: Cannot mix real and virtual.
section .rodata align=1 valign=1 follows=.text vfollows=.rodata_gap progbits
__rodata:
section .data_gap align=1 nobits follows=.rodata_gap NOBITS_VFOLLOWS(.rodata)  ; NASM error: Cannot mix real and virtual.
section .data align=1 valign=1 follows=.rodata vfollows=.data_gap progbits
__data:
%else  ; This works in NASM.
section .rodata align=1 valign=1 follows=.text vstart=(__rodata_vstart) progbits  ; Yasm 1.2.0 and 1.3.0 error: vstart expression is too complex
__rodata:
section .data align=1 valign=1 follows=.rodata vstart=(__data_vstart) progbits  ; Yasm 1.2.0 and 1.3.0 error: vstart expression is too complex
__data:
%endif
section .data_align align=1 follows=.data NOBITS_VFOLLOWS(.data) nobits
section .bss align=1 follows=.data_align NOBITS_VFOLLOWS(.data_align) nobits
__bss:
; TODO(pts): Make .footer progbits, but overlap with .bss addr.
section .footer align=1 follows=.bss NOBITS_VFOLLOWS(.bss) nobits
;
section .ehdr
; https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
; 32-bit and 64-bit ELF header from:
;     https://blog.stalkr.net/2014/10/tiny-elf-3264-with-nasm.html
;                                       ; Elf32_Ehdr or Elf64_Ehdr
		db 0x7F, 'ELF'          ;   e_ident ei_mag
%if _PROG_BITS == 64
		db 2                    ;   e_ident ei_class 32bit=1 64bit=2
%else
		db 1                    ;   e_ident ei_class 32bit=1 64bit=2
%endif
		db 1                    ;   e_ident ei_data little_endian=1 big_endian=2
		db 1                    ;   e_ident ei_version
		db _ELF_OS              ;   e_ident ei_osabi SystemV=0 Linux=3; GCC generates 0 here even for Linux.
        	dd 0, 0                 ;   e_ident ei_abiversion+ei_pad
		dw 2                    ;   e_type executable=2
		dw _ELF_MACHINE         ;   e_machine x86=i386=3 amd64=0x3e
		dd 1                    ;   e_version
		_ELF_DADDR(__elf_entry)  ;   e_entry Entry point.
		_ELF_DADDR(__phdr - _ELF_ORG)  ;   e_phoff
		_ELF_DADDR(0)           ;   e_shoff
		dd _ELF_FLAGS           ;   e_flags
		dw __ehdr_end - __ehdr  ;   e_ehsize
		dw __phdr_end0 - __phdr ;   e_phentsize
		dw (__phdr_end - __phdr) / (__phdr_end0 - __phdr)  ;   e_phnum Number of __phdrs.
		dw _ELF_SHENTSIZE       ;   e_shentsize
		dw 0                    ;   e_shnum
		dw 0                    ;   e_shstrndx
;
section .phdr
;		; 0 or more Elf32_Phdr or Elf64_Phdr.
;		;
;		; PT_LOAD=1.
;		; The way we generate this (p_offset=0) is UPX-compressible.
;		; `gcc -static -Wl,-N' generates a single PT_LOAD phdr, but it
;		; also does p_offset+=tfo, p_vaddr+=tfo, p_paddr+=tfo,
;		; p_filesz-=tfo, p_memsz-=tfo, where tfo == __text - _ELF_ORG;
;		; all this makes the file not UPX-compressible.
%if _ELF_EMIT_SECT_MANY
		_ELF_PHDR(1, 5 & _ELF_SECT_RO_MASK, 0, _ELF_ORG, __text_end - _ELF_ORG, __text_end - _ELF_ORG, _ELF_PAGE_SIZE)
%else
		_ELF_PHDR(1, 7 & _ELF_SECT_RO_MASK, 0, _ELF_ORG, __data_end - _ELF_ORG, __bss_end_aligned - _ELF_ORG + __bss_end_alignment, _ELF_PAGE_SIZE)
%endif
__phdr_end0:
section .text
;
%if _ELF_EMIT_SECT_MANY
; Create a gap in virtual addresses of the same size as the page size, so that
; the virtual address range of .text (rx) and .data (rw) won't overlap.
%assign _ELF_SECTION_GAP _ELF_PAGE_SIZE
%else
%define _ELF_SECTION_GAP 0
%endif
;
%if _ELF_EMIT_ABI_TAG
; !! Make these better and customizable via %define.
;
; For executable programs on Solaris (tested on OpenSolaris 2009.06),
; ei_osabi is SystemV, there is no PT_NOTE header, there are .SUNW_*
; sections (not mentioned in the program header), and the PT_DYNAMIC entries
; may contain some more system version information.
;
; For executable programs on xv6 (tested on i386 on 2022-04-15), ei_osabi is
; SystemV, there is no PT_NOTE header, and there are no useful section headers.
%ifidn %2,NetBSD
__elf_note 'NetBSD', 1, dd 800000000  ; ABI version 8.0 on NetBSD. This isn't checked, even NetBSD 3.0 runs it, although it was built for NetBSD 8.0.
%elifidn %2,DragonFlyBSD
__elf_note 'DragonFly', 1, dd 600200  ; ABI version 6.2 on DragonFlyBSD 6.2.1. 300800 means ABI version 3.8 on DragonFlyBSD 3.8.2.
%elifidn %2,OpenBSD
__elf_note 'OpenBSD', 1, dd 0  ; ABI version 0 on OpenBSD 6.1.
%elifidn %2,FreeBSD
__elf_note 'FreeBSD', 1, dd 1203000  ; ABI version on FreeBSD 12.3.
%elifidn %2,Linux
__elf_note 'GNU', 1, dd 0, 3, 2, 0  ; ABI version GNU/Linux 3.2.0, as on Ubuntu 18.04.
%elifidn %2,Minix
__elf_note 'Minix', 1, dd 300300000  ; ABI version on Minix 3.3.0.
%else
%error Unexpected ELF note.
bits 0  ; Enforce the error in NASM 0.98.* and 0.99.*.
__elf_note '___', 1, dd 0
%endif
%endif
;
%ifidn %2,Solaris
%if _PROG_BITS == 32
%define syscall __elf_syscall  ; Make it work with `cpu 386' as well.
%endif
%endif
%endm  ; _elf_start

; %1 is 'name', %2 is type (e.g. 1), %3 is desc (e.g. dd 0).
%macro __elf_note 3+
%xdefine __PREV_SECT __SECT__
section .notes
%define _ELF_HAVE_NOTE 1
		dd %%note_name_size  ; n_namesz
		dd %%note_desc_size  ; n_descsz
		dd %2  ; n_type
%%note_name:	db %1, 0
%%note_name_size equ $ - %%note_name
times -%%note_name_size & 3 db 0  ; Pad to multiple of 4.
%%note_desc:	%3
%%note_desc_size equ $ - %%note_desc
times -%%note_desc_size & 3 db 0  ; Pad to multiple of 4.
%xdefine __SECT__ __PREV_SECT
__PREV_SECT  ; Change back to previous section.
%endm

; `__elf_maybe %1, %2' is like `times %1 %2', but it treats all nonzero
; values of %1 as 1, i.e. it executes %2 (once) iff %1 is nonzero. It also
; doesn't expand multiline macros in %2 (as a side effect).
%macro __elf_maybe 2+
__elf_maybe_equ %%ic, %1
		times %%ic %2
%endm

; `__elf_maybe_equ %1, %2' is like `%1 equ %2', but it treats all %2 values
; whose low 64-bit part is nonzero as 1.
%macro __elf_maybe_equ 2+
; This simpler solution makes Yasm fail with:
; non-constant value given to `%if'.
;   %if %2
;   %1 equ 1
;   %else
;   %1 equ 0
;   %endif
%%i0 equ (%2)
%%i1 equ %%i0 | %%i0 >> 32
%%i2 equ %%i1 | %%i1 >> 16
%%i3 equ %%i2 | %%i2 >> 8
%%i4 equ %%i3 | %%i3 >> 4
%%i5 equ %%i4 | %%i4 >> 2
%%i6 equ %%i5 | %%i5 >> 1
; This is a bit slow in Yasm, because Yasm evaluates the equ formulas
; recursively, without caching. But it's still OK, since it's only 64
; evaluation. NASM caches the temporary results, thus it doesn't have this
; performance issue.
;
; Example file: tob32w.nasm
%1 equ %%i6 & 1
%endm

; To be used as `syscall' on Solaris i386.
%macro __elf_syscall 0
db 0x0f, 5
%endm

%macro _end 0-1 _start
__elf_entry equ (%1)  ; Labels in %1 must be defined by now.
section .ehdr
__ehdr_end:
times ($$-$) & 3 db 0  ; Should be a no-op.
__ehdr_end_aligned:
section .notes
__notes_end:
times ($$-$) & 3 db 0  ; Should be a no-op.
__notes_end_aligned:
%if _ELF_HAVE_NOTE == 0
%ifdef __YASM_MAJOR__
; Poor man's assertion: fail with `multiple is negative'
; if __notes != __notes_end_aligned.
; Solution for the Yasm user: use NASM, or use __elf_note, or explicitly:
;   %define _ELF_HAVE_NOTE 1
times +__notes_end_aligned-__notes db 0
times -__notes_end_aligned+__notes db 0
%else
%if __notes != __notes_end_aligned  ; Yasm 1.2.0 would fail: non-constant value given to `%if'.
%define _ELF_HAVE_NOTE 1
%endif
%endif
%endif
section .text
__text_end:
; Do alignment manually, because align=16 etc. would mess up the p_memsz
; calculations.
;
; Now we add extra alignment before .data.
__estimated_phdr_count1 equ 1+_ELF_HAVE_NOTE
%if _ELF_EMIT_SECT_MANY  ; __estimated_phdr_count1 is too complicated to estimate. It's more than that above.
%if (_PROG_BITS == 32 && _PROG_ALIGN > 32) || (_PROG_BITS == 64 && _PROG_ALIGN > 8)
; For _PROG_BITS == 32: .ehdr is 52 bytes, .phdr is 32 bytes each.
; For _PROG_BITS == 64: .ehdr is 64 bytes, .phdr is 56 bytes each.
;
; It would be awesome to add (__phdr_end_aligned-__phdr) below, but it's too
; early (we don't have the end of __phdr yet), so we just give up if the
; alignment is too large.
%error unsupported alignment-bits combo with sect_many: _PROG_ALIGN-_PROG_BITS
%endif
%endif
%if _ELF_EMIT_GNU_STACK
__estimated_phdr_count equ __estimated_phdr_count1+1
%else
__estimated_phdr_count equ __estimated_phdr_count1
%endif
%if _PROG_BITS == 32
__estimated_phdr_size equ __estimated_phdr_count*32
%else
__estimated_phdr_size equ __estimated_phdr_count*56
%endif
times ($$-$-(__ehdr_end_aligned-__ehdr)-__estimated_phdr_size-(__notes_end_aligned-__notes)) & (_PROG_ALIGN - 1) db 0
__text_end_aligned:
section .data
__data_end:
__data_end_alignment equ ($$-$) & (_PROG_ALIGN - 1)
section .data_align  ; The user should keep this section empty.
resb __data_end_alignment
section .rodata
__rodata_end:
__elf_maybe_equ __data_maybe, __data_end - __data
times __data_maybe * (($$-$) & (_PROG_ALIGN - 1)) db 0  ; Should be a no-op.
__rodata_end_aligned:
%assign _ELF_RODATA_FLAGS (4 & _ELF_SECT_RO_MASK) | _ELF_SECT_NX_RO_MASK
%assign _ELF_DATA_FLAGS   (6 & _ELF_SECT_RO_MASK) | _ELF_SECT_NX_RO_MASK
%if _ELF_RODATA_FLAGS == _ELF_DATA_FLAGS
%define _ELF_RODATACO 1
%else
%define _ELF_RODATACO 0
%endif
__elf_maybe_equ __rodata_maybe, __rodata_end - __rodata
%if _ELF_EMIT_SECT_MANY
%ifdef __YASM_MAJOR__
%if _ELF_RODATACO
section .rodata_gap
		resb _ELF_SECTION_GAP * __rodata_maybe
section .data_gap
		resb _ELF_SECTION_GAP * (1 - __rodata_maybe)
%else
section .rodata_gap
		resb _ELF_SECTION_GAP * __rodata_maybe
section .data_gap
		resb _ELF_SECTION_GAP
%endif
section .text
%endif
%endif
section .bss
__bss_end:
resb ($$-$) & (_PROG_ALIGN - 1)
__bss_end_aligned:
%if _PROG_SFLAGS & _ELF_SFLAG_bss_end_align4
__bss_end_alignment equ -((__text_end_aligned - __text) + (__data_end + __data_end_alignment - __data) + (__rodata_end_aligned - __rodata) + (__bss_end_aligned - __bss)) & 3
%else
__bss_end_alignment equ 0
%endif
;
section .phdr
%if _ELF_EMIT_SECT_MANY
%if _ELF_RODATACO  ; Emit .data and .rodata in the same PHDR if the permissions are the same.
		__elf_maybe __rodata_end - __rodata + __data_end - __data + __bss_end_aligned - __bss, _ELF_PHDR(1, _ELF_DATA_FLAGS, __rodata - _ELF_ORG - _ELF_SECTION_GAP * __rodata_maybe, __rodata + _ELF_SECTION_GAP * (1 - __rodata_maybe), __rodata_end_aligned - __rodata + __data_end - __data, __rodata_end_aligned - __rodata + __bss_end_aligned - __bss + __data_end - __data + __data_end_alignment + __bss_end_alignment, _ELF_PAGE_SIZE)
%else
		__elf_maybe __rodata_end - __rodata, _ELF_PHDR(1, _ELF_RODATA_FLAGS, __rodata - _ELF_ORG - _ELF_SECTION_GAP, __rodata, __rodata_end - __rodata, __rodata_end - __rodata, _ELF_PAGE_SIZE)
		__elf_maybe __data_end - __data + __bss_end_aligned - __bss, _ELF_PHDR(1, _ELF_DATA_FLAGS, __data - _ELF_ORG - _ELF_SECTION_GAP * (__rodata_maybe + 1), __data, __data_end - __data, __bss_end_aligned - __bss + __data_end - __data + __data_end_alignment + __bss_end_alignment, _ELF_PAGE_SIZE)
%endif
%endif
%if _ELF_EMIT_GNU_STACK
		; PT_GNU_STACK=0x6474e551. Make it non-executable. Align=0 would also work.
		; rw=6.
		; FreeBSD and DragonFlyBSD have this explicitly.
		; OpenBSD >=3.2 enforces nonexecutable stack and heap even
		; without this. (OpenBSD 3.1 didn't even used ELF.)
		_ELF_PHDR(0x6474e551, 6, 0, 0, 0, 0, 4)
%endif
%if _ELF_HAVE_NOTE
;		; PT_NOTE=4.
		_ELF_PHDR(4, 4, __notes - _ELF_ORG, __notes - _ELF_ORG, __notes_end - __notes, __notes_end - __notes, 4)
%endif
__phdr_end:
times ($$-$) & 3 db 0  ; Should be a no-op.
__phdr_end_aligned:
;
__text_vstart equ _ELF_ORG + (__ehdr_end_aligned - __ehdr) + (__phdr_end_aligned - __phdr) + (__notes_end_aligned - __notes)
;
; These are only valid for NASM (not Yasm).
__rodata_vstart equ __text_vstart + _ELF_SECTION_GAP * __rodata_maybe +  (__text_end_aligned - __text)
__data_vstart equ __rodata_vstart + _ELF_SECTION_GAP * (1 - __rodata_maybe * _ELF_RODATACO) + (__rodata_end_aligned - __rodata)
__bss_vstart equ __data_vstart + (__data_end - __data + __data_end_alignment)
;
; For _section_vs.
__.text equ __text
__.text_vstart equ __text_vstart
__.rodata equ __rodata
__.rodata_vstart equ __rodata_vstart
__.data equ __data
__.data_vstart equ __data_vstart
__.bss equ __bss
__.bss_vstart equ __bss_vstart
section .footer  ; In case the user accidentally adds something.
__do_all __AT_END
%endm

; Comma-separated instructions to be executed at the end of _end.
%xdefine __AT_END __at_end_dummy equ 42

; Executes each macro argument as a separate instruction.
%macro __do_all 0-*
%rep %0
%1
%rotate 1
%endrep
%endm

; Usage: `LABEL: _section_vs SECTION, INSTRUCTION', when SECTION is e.g.
; .text. INSTRUCTION is any one-liner instruction, including a macro call.
; It is the same as `LABEL: INSTRUCTION', but defines additinal labels
; LABEL_size, LABEL_end, LABEL_vs, LABEL_end_vs. The labels ending with _vs
; have the same value as without _vs, but they are absolute (not
; section-relative), thus they can be used in `&' and similar operations.
;
; Calling it many times is quite slow (O(n**2)) because it appends to the
; macro __AT_END by copying it.
%macro _section_vs 2+
%xdefine __PREV_SECT __SECT__
section %1
%00: %2
%00_size equ $ - %00
%00_end:
; SUXX: equ doesn't work, it's a forward-declaration.
;%define message_vs ((%00) - __data + __data_vstart)
%xdefine __SECT__ __PREV_SECT
%xdefine __AT_END __AT_END, %00_vs equ ((%00) - __%1 + __%1_vstart), %00_end_vs equ ((%00_end) - __%1 + __%1_vstart)
__PREV_SECT  ; Change back to previous section.
%endm

%macro _text_vs 1+
%if %0
%00: _section_vs .text, %1
%else
%00: _section_vs .text, times 0 nop
%endif
%endm

%macro _rodata_vs 1+
%if %0
%00: _section_vs .rodata, %1
%else
%00: _section_vs .rodata, times 0 nop
%endif
%endm

%macro _data_vs 1+
%if %0
%00: _section_vs .data, %1
%else
%00: _section_vs .data, times 0 nop
%endif
%endm

%macro _bss_vs 1+
%if %0
%00: _section_vs .bss, %1
%else
%00: _section_vs .bss, times 0 nop
%endif
%endm

; ---

%else  ; Big %ifdn __OUTPUT_FORMAT__,bin
; Provide some compatibility so that the same .nasm source compiles with
; `nasm -f bin' and `nasm -f elf'.
;
; %1 (from which _PROG_BITS would be derived) is ignored.
%macro _elf_start 2-3 0
__elf_define_align_and_sflags %3
%if _PROG_ALIGN && _PROG_ALIGN & (_PROG_ALIGN - 1)
%error bad ELF section alignment: _PROG_ALIGN
bits 0  ; Enforce the error in NASM 0.98.* and 0.99.*.
%assign _PROG_ALIGN 1
%endif
%if _PROG_ALIGN == 0
%ifidn __OUTPUT_FORMAT__,elf64
%define _PROG_ALIGN 8
%else
%define _PROG_ALIGN 4
%endif
%endif
;
%ifidn __OUTPUT_FORMAT__,elf64
%define _PROG_CPU_BITS 64
%else
%define _PROG_CPU_BITS 32
%endif
__elf_set_bits
;
section .text align=1
section .rodata align=_PROG_ALIGN
section .data align=_PROG_ALIGN
section .bss align=_PROG_ALIGN
section .text
%endm
%macro _end 0
__at_end_dummy:  ; Make duplicate definition fail.
%endm
%endif

; --- Convenience section macros.

%macro _rodata 1+  ; !! Rename it to .rodata.
%xdefine __PREV_SECT __SECT__
section .rodata
%1
%xdefine __SECT__ __PREV_SECT
__PREV_SECT  ; Change back to previous section.
%endm

%macro _data 1+  ; !! Rename it to .data.
%xdefine __PREV_SECT __SECT__
section .data
%1
%xdefine __SECT__ __PREV_SECT
__PREV_SECT  ; Change back to previous section.
%endm

%macro _bss 1+
%xdefine __PREV_SECT __SECT__
section .bss
%1
%xdefine __SECT__ __PREV_SECT
__PREV_SECT  ; Change back to previous section.
%endm

; --- Convenience definitions.

; `label: db_size ...' is like `label: db ...', but it also defines label
; label_end and also label_size (as both symbol and macro). `label:' must
; always be present (otherwise its a syntax error).
%macro db_size 0-*
%define __DB_SIZE 0
%rep %0
%ifstr %1
%strlen __DB_STRLEN %1
%assign __DB_SIZE __DB_SIZE+__DB_STRLEN
%else
%assign __DB_SIZE __DB_SIZE+1
%endif
%rotate 1
%endrep
%00:
%rep %0
		db %1
%rotate 1
%endrep
%00_end:
%undef %00_size
%00_size equ %00_end-%00
%assign %00_size __DB_SIZE  ; Make it a constant.
%endm
