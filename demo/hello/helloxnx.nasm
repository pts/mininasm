;
; helloxnx.nasm: minimalistic hello-world for Xenix 86 2.x x.out
; by pts@fazekas.hu at Sun Jan 22 01:50:33 CET 2023
;
; Compile: nasm -O0 -f bin -o helloxnx helloxnx.nasm
; Works with NASM >= 0.98.39.
;
; Compile: mininasm -O0 -f bin -o helloxnx helloxnx.nasm
;
; The created executable program is 306 bytes.
;
; Compatibility:
;
; * Xenix 86 2.1.3: It works on the installer floppy (n2.img).
; * Xenix 286 2.3.2b: It works on the installer floppy (n1.img).
; * Xenix 386: ?? Not tried. Probably it can run Xenix 86 programs.
;
; a.out.h also shows headers for the Xenix a.out and b.out file formats, but
; Xenix 286 2.3.2b isn't able to run such programs (it runs them as shell
; scripts).
;
; Xenix 86 syscall ABI (reverse engineered):
;
;   Call: mov ax, syscall_number; mov bx, arg1; mov cx, arg2; mov si, arg3; mov di, arg4; call section_text+0x17
;   On error, sets CF=1, AX=errno (error code), destroys BX, CX, DX, SI, DI, BP, FLAGS.
;   On success, sets CF=0, (AL, AX or BX:AX)=result, destroys AX, BX, CX, DX, SI, DI, BP, FLAGS, except for the result.
;   TODO(pts): How are argc, argv and envp passed in Xenix 86?
;
; Xenix 86 libc C ABI (not used in this program):
;
;   https://en.wikipedia.org/wiki/X86_calling_conventions#cdecl
;   Caller pushes args in reverse order, caller pops args.
;   Result in AL, AX or DX:AX, callee destroys AX, BX, CX, DX (except for result).
;   Example: ssize_t write(int fd, const void *buf, size_t count);
;   Call: push arg_count; arg_push buf; push arg_fd; call func_write; pop 3 words
;
; Using more than 64 KiB of data on Xenix:
;
;   Xenix 86 does not support the allocation of additional data segments,
;   therefore when brkctl() requests that require this are made by an 8086
;   binary running under Xenix 86 they will fail. The -compat option of the
;   C compiler can be used to link 8086 binaries with a special version of
;   brkctl() (in /lib/[SML]libbrkctl.a) that satisfies requests for
;   additional data segments under Xenix 86 by allocating shared memory
;   segments.
;

		bits 16
		cpu 8086
		;org ... ; Later.

XC:
.8086		equ 4
.hbfs		equ 0x80	; high byte first in short
.lwfl		equ 0x40	; low word first in long

XR:  ; Relocation table format.
.RXOUT		equ 0x00	; x.out long form, linkable
.RXEXEC		equ 0x10	; x.out short form, executable
.RBOUT		equ 0x20	; b.out format
.RAOUT		equ 0x30	; a.out format
.R86REL		equ 0x40	; 8086 relocatable format
.R86ABS		equ 0x50	; 8086 absolute format
.R286ABS	equ 0x60	; 80286 absolute format. Why this?
.R286REL	equ 0x70	; 80286 relocatable format

XSTF:  ; Symbol table format.
.SXOUT		equ 0x00	; trailing string, struct sym
.SBOUT		equ 0x01	; trailing string, struct bsym
.SAOUT		equ 0x02	; struct asym (nlist)
.S86REL		equ 0x03	; 8086 relocatable format
.S86ABS		equ 0x04	; 8086 absolute format
.SUCBVAX	equ 0x05	; separate string table
.S286ABS	equ 0x06	; 80286 absolute format
.S286REL	equ 0x07	; 80286 relocatable format
.SXSEG		equ 0x08	; segmented format
.SYM		equ 0x0f	; symbol format mask

XE:
.OSXENIX	equ 1

RENV:
.EXECUTABLE	equ 1
.SEPARATE_I_D	equ 2
.TEXT_PURE	equ 4
.FS	equ 8  ; Fixed stack.
; *	           o        set if text overlay
; *	          d         set if large model data
; *	         t          set if large model text
; *	        f           set if floating point hardware required
; *	       v            set if virtual kernel module or shared library was (h) but this was never used.
; *	      i             set if segment table contains iterated text/data
; *	     a              set if absolute (set up for physical address)
.SEG		equ 0x800  ; segmented x.out: segment table present.
.V1		equ 0x4000
.V2		equ 0x8000
.VUSE_OSVERS	equ 0xc000

XST:
.TTEXT		equ 1  ; text (code) segment.
.TDATA		equ 2  ; data segment.

XS:
.AMEM		equ 0x8000  ; segment represents a memory image.
.ABSS		equ 0x0004  ; contains implicit bss.
.APURE		equ 0x0008  ; read-only, may be shared.

; Executable-specific.
CODE_SEGMENT_NUMBER equ 0x3f
DATA_DELTA equ 2  ; Should be 0. How much is x_data larger than it should be.

xexec_header:  ; Based on /usr/include/sys/a.out.h on Xenix 286 2.3.2b.
.x_magic	dw 0x206	; X_MAGIC magic number
.x_ext		dw xext_header.end-xext_header  ; size of header extension
.x_text		dd section_text_end-section_text  ; size of text segment (s)
.x_data		dd section_data_end-section_data+DATA_DELTA  ; size of initialized data (s)
.x_bss		dd section_bss_end-section_bss-DATA_DELTA  ; size of uninitialized data (s)
.x_syms		dd 0		; size of symbol table (s)
.x_reloc	dd 0		; size of relocation table (s)
.x_entry	dd _start-section_text  ; entry point
.x_cpu		db XC.8086|XC.lwfl  ; cpu type & byte/word order
.x_relsym	db XR.R286ABS|XSTF.S86ABS    ; relocation & symbol format (u) TODO(pts): Why not XR.RXEXEC etc.? Would it be shorter? It doesn't matter, the file doesn't have symbols or relocations.
.x_renv		dw RENV.EXECUTABLE|RENV.SEPARATE_I_D|RENV.TEXT_PURE|RENV.FS|RENV.SEG|RENV.VUSE_OSVERS  ; run-time environment

xext_header:  ; Based on /usr/include/sys/a.out.h on Xenix 286 2.3.2b.
.xe_trsize	dd 0		; size of text relocation (s) unused
.xe_drsize	dd 0		; size of data relocation (s) unused
.xe_tbase	dd 0		; text relocation base (u) unused
.xe_dbase	dd 0		; data relocation base (u) unused
.xe_stksize	dd 0x1000	; stack size (if RENV.FS set)
.xe_segpos	dd xseg0-xexec_header  ; segment table position this and all following must be present if RENV.SEG is set
.xe_segsize	dd xseg_end-xseg0  ; segment table size
.xe_mdtpos	dd 0		; machine dependent table position
.xe_mdtsize	dd 0		; machine dependent table size
.xe_mdttype	db 0		; machine dependent table type
.xe_pagesize	db 0		; file pagesize, in multiples of 512. 0 means unaligned (?).
.xe_ostype	db XE.OSXENIX	; operating system type
.xe_osvers	db 2		; operating system version
.xe_eseg	dw CODE_SEGMENT_NUMBER  ; entry segment
.xe_sres	dw 0		; reserved
.end:

xseg0:
.xs_type	dw XST.TTEXT	; segment type
.xs_attr	dw XS.AMEM|XS.APURE  ; segment attributes
.xs_seg		dw CODE_SEGMENT_NUMBER  ; segment number (arbitrary)
.xs_align	db 0		; log base 2 of alignment
.xs_cres	db 0		; unused
.xs_filpos	dd section_text-xexec_header  ; file position
.xs_psize	dd section_text_end-section_text  ; physical size (in file)
.xs_vsize	dd section_text_end-section_text  ; virtual size (in core), must be the same as xs_psize
.xs_rbase	dd 0		; relocation base address/offset
.xs_noff	dw 0		; segment name string table offset
.xs_sres	dw 0		; unused
.xs_lres	dd 0		; unused

xseg1:
.xs_type	dw XST.TDATA	; segment type
.xs_attr	dw XS.AMEM|XS.ABSS  ; segment attributes
.xs_seg		dw 0x47		; segment number (arbitrary)
.xs_align	db 0		; log base 2 of alignment
.xs_cres	db 0		; unused
.xs_filpos	dd section_data-xexec_header  ; file position
.xs_psize	dd section_data_end-section_data  ; physical size (in file)
.xs_vsize	dd section_data_end-section_data+section_bss_end-section_bss  ; virtual size (in core)
.xs_rbase	dd 0		; relocation base address/offset
.xs_noff	dw 0		; segment name string table offset
.xs_sres	dw 0		; unused
.xs_lres	dd 0		; unused

xseg_end:

$SYSCALL:  ; Xenix 86 syscall numbers.
.exit		equ 0x1
.write		equ 0x4
.sys0x6		equ 0x6
.sys0x14	equ 0x14
.sys0x25	equ 0x25
.sys0x36	equ 0x36
.sys0x828	equ 0x828
.sys0x1328	equ 0x1328

section_text:
_start:
; !! Why is all this needed (0x80 bytes between _start and _start2)? https://retrocomputing.stackexchange.com/q/26225/3494
..@t0x0000: jmp strict short _start2

syscall_part2:
..@t0x0002: jmp strict short syscall_part3

do_syscall_sys0x828:
..@t0x0004: jmp strict short proc0x14

proc0x6_unused:
..@t0x0006: jmp strict short proc0x14

proc0x8_unused:
..@t0x0008: jmp strict short $  ; Infinite loop.
..@t0x000a: jmp strict short $  ; Infinite loop.
..@t0x000c: jmp strict short $  ; Infinite loop.
..@t0x000e: jmp strict short $  ; Infinite loop.
..@t0x0010: jmp strict short $  ; Infinite loop.
..@t0x0012: jmp strict short $  ; Infinite loop.

proc0x14:  ; Only called from do_syscall_sys0x828.
..@t0x0014: mov ax, $SYSCALL.sys0x828

syscall_part3:
..@t0x0017: int 5  ; Xenix 86 syscall.
..@t0x0019: jmp strict short .ret
..@t0x001b: times 0x7f-0x1b db 0  ; Why?
.ret:
..@t0x007f: ret

_start2:
..@t0x0080:
		; Experimental hello-world code. It works (both write(2) and exit(2)) on the Xenix 286 2.3.2b installer floppy (n1.img).
		mov ax, $SYSCALL.write
		mov bx, 1  ; STDOUT_FILENO.
		mov cx, msg
		mov si, msg.end-msg
		call syscall_part3  ; !! syscall_part2 and syscall_part3 work, syscall_part3b fails with Memory fault  ; Xenix 86 syscall. https://retrocomputing.stackexchange.com/q/26225

		mov ax, $SYSCALL.exit
		xor bx, bx  ; EXIT_SUCCESS.
		call syscall_part3  ; !! syscall_part2 and syscall_part3 work, syscall_part3b fails with Memory fault  ; Xenix 86 syscall. https://retrocomputing.stackexchange.com/q/26225
		; Not reached.

;syscall_part3b:	int 5
;		ret

section_text_end:

		org xexec_header-$
section_data:
		db 0  ; Without this, the address of msg would be 0, and $SYSCALL.write doesn't allow that.
msg		db 'Hello, World!', 10
.end:
section_data_end:

absolute $
section_bss:  ; Must follow section_data.
		;resb 2
section_bss_end:
