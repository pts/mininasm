;
; minnnasm.nasm: self-hosting, NASM-compatible assembler for DOS 8086, targeting 8086
; by pts@fazekas.hu at Fri Nov 18 04:17:31 CET 2022
;
; minnnasm is a minimalistic, self-hosting, NASM-compatiblie assembler for
; DOS 8086, targeting 8086, producing flat (binary) output (such as DOS .com
; programs). Self-hosting means that it's able to compile (assemble) its own
; source code and produce a DOS .com executable binary bit-by-bit identical
; to what is produced by NASM (>= 0.98.39) and mininasm
; (https://github.com/pts/mininasm).
;
; This version of minnnasm.com (20904 bytes) is bit-by-bit identical to
; mininasm.com built from
; https://github.com/pts/mininasm/blob/46de143afdd708d72885838fb72cae5e43e73bcf/mininasm.c
; with `dosmc -mt -cpn mininasm.c'.
;
; Compilation instructions (use any one of):
;
;   $ nasm -O9 -f bin -o minnnasm.com minnnasm.nasm
;   $ mininasm -O9 -f bin -o minnnasm.com minnnasm.nasm
;   $ kvikdos minnnasm.com -O9 -f bin -o minnnas2.com minnnasm.nas
;
; These NASM versions (as well as mininasm at the link above) were tested
; and found to produce minnnasm.com bit-by-bit identical to mininasm.com
; above): NASM 0.98.39, NASM 0.99.06, NASM 2.13.02. Only the `-O9'
; optimization level produces the bit-by-bit identical output.
;
; mininasm (mininasm.com on DOS) can compile this source with 64 KiB of memory
; + DOS buffers (e.g. file read buffers and filesystem metadata caches).
;
; `yasm' also works instead of `nasm', but it doesn't generate an identical
; executable program, because YASM generates different machine code for
; `xchg' (and maybe `test') register-to-register instructions, and also
; for some other instructions.
;
; The resulting .com executable program can be run on DOS or in a DOS
; emulator (e.g. DOSBox, emu2, kvikdos). The target architecture is 8086
; (newer instruction sets such as 182, 286, 386 are not used), floating point
; instructions are not used.
;
; minnnasm.nasm is a fork of https://github.com/pts/mininasm (mininasm.c
; implemented in C), compiled with the OpenWatcom C compiler, then
; disassembled, and some comments manually added. Some of the code
; (including _start and the libc functions) were written in assembly from
; the start.
;
; Function calling convention (ABI):
;
; * Its the Watcom calling convention (__watcall, `wcc -ecw' default) for
;   the 16-bit small model (`wcc -ms'). More details below.
; * See also https://www.agner.org/optimize/calling_conventions.pdf .
; * Only the following case is documented below: each function argument is
;   8-bit integer, 16-bit integer, 32-bit integer, 16-bit near pointer or
;   32-bit far pointer; function return value is 8-bit integer, 16-bit
;   integer, 32-bit integer or 16-bit near pointer, there are no varargs.
; * Return the return value (if not void) in AL for 8-bit result, AX for
;   16-bit result, and DX:AX for 32-bit result. (For far pointers, DX is the
;   segment. For integers, DX is the higher, more significant half.)
; * Rules for argument passing:
;   * If there are no arguments, don't pass any.
;   * Otherwise, if there is 1 argument, and it's 32-bit, then pass it in
;     DX:AX. (For far pointers, DX is the segment. For integers, DX is the
;     higher, more significant half.)
;   * Otherwise, if there is 1 argument, then pass it zero-extended in AX.
;   * Otherwise, if the first 2 arguments are 32-bit, then pass the 1st
;     argument in DX:AX, the 2nd argument in CX:BX, and push any remaining
;     arguments to the stack in reverse order (i.e. push the last argument
;     first; for 32-bit arguments, push higher half first; push 8-bit
;     arguments zero-extended to 16 bits).
;   * Otherwise, if the 1st argument is 32-bit, and the 2nd argument is 8-bit
;     or 16-bit, and the 3rd argument is 32-bit, then pass the 1st argument in
;     DX:AX, the 2nd argument zero-extended in BX, and push any remaining
;     arguments to the stack in reverse order.
;   * Otherwise, if the 1st argument is 32-bit, and the 2nd argument is 8-bit
;     or 16-bit, and the 3rd argument is 8-bit or 16-bit, then pass the 1st
;     argument in DX:AX, the 2nd argument zero-extended in BX, the 3rd
;     argument zero-extended in CX, and push any remaining arguments to the
;     stack in reverse order.
;   * Otherwise, if the 2nd argument is 32-bit, and the 3rd argument is 8-bit
;     or 16-bit, then pass the 1st argument zero-extended in AX, the 2nd
;     argument in CX:BX, the 3rd argument zero-extended in DX, and push any
;     remaining arguments to the stack in reverse order.
;   * Otherwise, if the 2nd argument is 32-bit, then pass the 1st argument
;     zero-extended in AX, the 2nd argument in CX:BX, and push any remaining
;     arguments to the stack in reverse order. (DX is not used for argument
;     passing.) (TODO(pts): Is this really correct?)
;   * Otherwise, pass the first 2, 3 or 4 arguments (as many as possible)
;     zero-extended in AX, then DX, then BX, then CX, and push any remaining
;     arguments to the stack in reverse order.
; * Upon return, the callee must remove (pop) arguments from the stack.
;   (For that, the `ret NN' instruction is practical, where NN is 2 times
;   the number of 16-bit words pushed to the stack.)
; * The callee must preserve registers CS, DS, SS, SI, DI, BP.
; * The callee must preserve registers BX, CX, DX, except those which were
;   used for argument passing.
; * The function may use registers AX, ES and the arithmetic FLAGS as scratch,
;   no need to preserve them (but AX or AL may be used as return value), and
;   for DF (direction flag) must be set to 0 (e.g. instruction `cld') before
;   each function call (if changed by the caller before), and before
;   returning.
;

		bits 16
		cpu 8086
		org 0x100  ; DOS .com file is loaded at CS:0x100.

; --- Startup code.
;
; Code in this section was written directly in WASM assmebly, and manually
; converted to NASM assembly.
;
; Based on https://github.com/pts/dosmc/blob/f716c6cd9ec8947e72f1f7ad7c746d8c5d28acc4/dosmc.dir/dosmc.pl#L1141-L1187
___section_startup_text:

___stack_size	equ 0x140  ; To estimate, specify -sc to dosmc (mininasm.c), and run it to get the `max st:HHHH' value printed, and round up 0xHHHH to here. Typical value: 0x200.

_start:  ; Entry point of the DOS .com program.
		cld
		mov sp, ___initial_sp
		mov di, ___section_mininasm_c_bss
		mov cx, (___section_startup_ubss-___section_mininasm_c_bss+1)>>1
		xor ax, ax
		rep stosw
		mov di, argv_bytes
		mov bp, argv_pointers
		push bp
		push es
		lds si, [0x2c-2]  ; Environment segment within PSP.
		
		xor si, si
		lodsb
.next_entry:	test al, al
		jz .end_entries
.next_char:	test al, al
		lodsb
		jnz .next_char
		jmp short .next_entry
.end_entries:	inc si  ; Skip over a single byte.
		inc si  ; Skip over '\0'.
		; Now ds:si points to the program name as an uppercase, absolute pathname with extension (e.g. .EXE or .COM). We will use it as argv.
		
		; Copy program name to argv[0].
		mov [bp], di  ; argv[0] pointer.
		inc bp
		inc bp
		mov cx, 144  ; To avoid overflowing argv_bytes. See above why 144.
.next_copy:	dec cx
		jnz .argv0_limit_not_reached
		xor al, al
		stosb
		jmp short .after_copy
.argv0_limit_not_reached:
		lodsb
		stosb
		test al, al
		jnz .next_copy
.after_copy:
		
		; Now copy cmdline.
		pop ds  ; PSP.
		mov si, 0x80  ; Command-line size byte within PSP, usually space. 0..127, we trust it.
		lodsb
		xor ah, ah
		xchg bx, ax  ; bx := ax.
		mov byte [si+bx], 0
.scan_for_arg:	lodsb
		test al, al
		jz .after_cmdline
		cmp al, ' '
		je .scan_for_arg
		cmp al, 9  ; Tab.
		je .scan_for_arg
		mov [bp], di  ; Start new argv[...] element. Uses ss by default, good.
		inc bp
		inc bp
		stosb  ; First byte of argv[...].
.next_argv_byte:
		lodsb
		stosb
		test al, al
		jz .after_cmdline
		cmp al, ' '
		je .end_arg
		cmp al, 9  ; Tab.
		jne .next_argv_byte
.end_arg:	dec di
		xor al, al
		stosb  ; Replace whitespace with terminating '\0'.
		jmp short .scan_for_arg
		
.after_cmdline:	mov word [bp], 0  ; NULL at the end of argv.
		pop dx  ; argv_pointers. Final return value of dx.
		sub bp, dx
		xchg ax, bp  ; ax := bp.
		shr ax, 1  ; Set ax to argc, it's final return value.
		call main_
		mov ah, 0x4c  ; dx: argv=NULL; EXIT, exit code in al
		int 0x21
		; This line is not reached.

; --- Main program code (from mininasm.c, bbprintf.h and bbprintf.c).
;
; Code in this section was written in C, compiled by wcc using dosmc,
; disassembled using `wdis -s -a' and autoconverted from WASM to NASM
; syntax.
___section_mininasm_c_text:

; /*
;  ** mininasm: NASM-compatible mini assembler for 8086, able to run on DOS and on modern systems
;  ** mininasm modifications by pts@fazekas.hu at Wed May 18 21:39:36 CEST 2022
;  **
;  ** based on Tinyasm by Oscar Toledo G, starting Oct/01/2019.
;  **
;  ** Compilation instructions (pick any one):
;  **
;  **   $ gcc -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o mininasm mininasm.c && ls -ld mininasm
;  **
;  **   $ gcc -m32 -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o mininasm mininasm.c && ls -ld mininasm.gcc32
;  **
;  **   $ g++ -ansi -pedantic -s -Os -W -Wall -o mininasm mininasm.c && ls -ld mininasm
;  **
;  **   $ pts-tcc -s -O2 -W -Wall -o mininasm.tcc mininasm.c && ls -ld mininasm.tcc
;  **
;  **   $ pts-tcc64 -m64 -s -O2 -W -Wall -o mininasm.tcc64 mininasm.c && ls -ld mininasm.tcc64
;  **
;  **   $ xtiny gcc -march=i386 -ansi -pedantic -W -Wall Wno-overlength-strings -o mininasm.xtiny mininasm.c && ls -ld mininasm.xtiny
;  **
;  **   $ xstatic gcc -ansi -pedantic -s -O2 -W -Wall Wno-overlength-strings -o mininasm.xstatic mininasm.c && ls -ld mininasm.xstatic
;  **
;  **   $ dosmc -mt -cpn mininasm.c && ls -ld mininasm.com
;  **
;  **   $ owcc -bdos -o mininasm.exe -mcmodel=c -Os -s -fstack-check -Wl,option -Wl,stack=1800 -march=i86 -W -Wall -Wextra mininasm.c && ls -ld mininasm.exe
;  **
;  **   $ owcc -bwin32 -Wl,runtime -Wl,console=3.10 -o mininasm.win32.exe -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm.c nouser32.c && ls -ld mininasm.win32.exe
;  **
;  **   $ owcc -blinux -o mininasm.watli3 -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm.c && sstrip mininasm.watli3 && ls -ld mininasm.watli3
;  **
;  **   $ i686-w64-mingw32-gcc -m32 -mconsole -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -march=i386 -o mininasm.win32msvcrt.exe mininasm.c && ls -ld mininasm.win32msvcrt.exe
;  **
;  **   $ wine tcc.exe -m32 -mconsole -s -O2 -W -Wall -o mininasm.win32msvcrt_tcc.exe mininasm.c && ls -ld mininasm.win32msvcrt_tcc.exe
;  **
;  **   Turbo C++ (1.01 or 3.0) on DOS, creates mininasm.exe: tcc -mc -O -X mininasm.c
;  **
;  **   Borland C++ (2.0, 3.00, 3.1, 4.00, 4.5, 4.52 or 5.2) on DOS, creates mininasm.exe: bcc -mc -O -X -w! mininasm.c
;  **   From Borland C++ >=4.0, the .exe program is ~23 KiB larger.
;  **   The -w! flag (treat warnings as errors) is ignored by Borland C++ <4.0.
;  **
;  **   Microsoft C 6.00a on DOS, creates mininasm.exe: cl /Os /AC /W2 /WX mininasm.c
;  **
;  */
; 
; #ifndef CONFIG_SKIP_LIBC
; #define CONFIG_SKIP_LIBC 0
; #endif
; 
; #if !CONFIG_SKIP_LIBC && defined(__LIBCH__)  /* Works with gcc, tcc, pts-tcc (Linux i386 target) and `owcc -blinux'. */
; #  undef  CONFIG_SKIP_LIBC
; #  define CONFIG_SKIP_LIBC 1
; #  include <libc.h>
;    /* !! TODO(pts): Use the main_argv function (rather than main_from_libc to take argv only. */
; #  ifndef CONFIG_USE_OPEN2
; #    define CONFIG_USE_OPEN2 1  /* Non-POSIX API provided by <libc.h>. Same as open(..., ..., 0). */
; #  endif
; #  if 0 && defined(__WATCOMC__) && defined(_M_I386)  /* Not enabling it, doesn't make a size difference. */
;      static void memcpy_void_inline(void *dest, const void *src, size_t n);
; #    pragma aux memcpy_void_inline = "rep movsb"  parm [ edi ] [ esi ] [ ecx ] modify [ esi edi ecx ];
;      /* Returns dest + n. */
;      static void *memcpy_newdest_inline(void *dest, const void *src, size_t n);
; #    pragma aux memcpy_newdest_inline = "rep movsb"  value [ edi ] parm [ edi ] [ esi ] [ ecx ] modify [ esi ecx ];
; #    define CONFIG_USE_MEMCPY_INLINE 1
; #  endif
; #endif  /* ifdef __TINYC__. */
; 
; #if !CONFIG_SKIP_LIBC && defined(__TINYC__)  /* Works with tcc, pts-tcc (Linux i386 target), pts-tcc64 (Linux amd64 target) and tcc.exe (Win32, Windows i386 target). */
; #  undef  CONFIG_SKIP_LIBC
; #  define CONFIG_SKIP_LIBC 1
; #  if !defined(__i386__) /* && !defined(__amd64__)*/ && !defined(__x86_64__)
; #    error tcc is supported only on i386 and amd64.  /* Because of ssize_t. */
; #  endif
; #  if (defined(_WIN32) && !defined(__i386)) || defined(_WIN64)
; #    error Windows is supported only on i386.
; #  endif
; typedef unsigned char uint8_t;
; typedef unsigned short uint16_t;
; typedef unsigned int uint32_t;
; typedef signed char int8_t;
; typedef short int16_t;
; typedef int int32_t;
; typedef unsigned long size_t;  /* Good for __i386__ (4 bytes) and __amd64__ (8 bytes). */
; typedef long ssize_t;  /* Good for __i386__ (4 bytes) and __amd64__ (8 bytes). */
; typedef long off_t;  /* Good for __i386__ (4 bytes) and __amd64__ (8 bytes). */
; #  define NULL ((void*)0)
; #  ifdef _WIN32
; #    define __cdecl __attribute__((__cdecl__))
; #  else
; #    define __cdecl
; #  endif
; void *__cdecl malloc(size_t size);
; size_t __cdecl strlen(const char *s);
; int __cdecl remove(const char *pathname);
; __attribute__((noreturn)) void __cdecl exit(int status);
; char *__cdecl strcpy(char *dest, const char *src);
; int __cdecl strcmp(const char *s1, const char *s2);
; void *__cdecl memcpy(void *dest, const void *src, size_t n);
; int __cdecl isalpha(int c);
; int __cdecl isspace(int c);
; int __cdecl isdigit(int c);
; int __cdecl isxdigit(int c);
; ssize_t __cdecl read(int fd, void *buf, size_t count);  /* Win32 uses int instead of size_t etc. */
; ssize_t __cdecl write(int fd, const void *buf, size_t count);  /* Win32 uses int instead of size_t etc. */
; #define SEEK_SET 0  /* whence value below. */
; #define SEEK_CUR 1
; #define SEEK_END 2
; off_t __cdecl lseek(int fd, off_t offset, int whence);  /* Just 32-bit off_t. */
; #define O_RDONLY 0  /* flags bitfield value below. */
; #define O_WRONLY 1
; #define O_RDWR 2
; int __cdecl open(const char *pathname, int flags, ...);  /* int mode */
; int __cdecl creat(const char *pathname, int mode);
; int __cdecl close(int fd);
; #  ifdef _WIN32
; #    define O_CREAT 0x100
; #    define O_TRUNC 0x200
; #    define O_BINARY 0x8000
; #    define creat(filename, mode) open(filename, O_CREAT | O_TRUNC | O_WRONLY | O_BINARY, 0)  /* 0 to prevent Wine warning: fixme:msvcrt:MSVCRT__wsopen_s : pmode 0x406b9b ignored.  */
; int __cdecl setmode(int _FileHandle,int _Mode);
; #  endif
; #endif  /* ifdef __TINYC__. */
; 
; #if !CONFIG_SKIP_LIBC && defined(__DOSMC__)
; #  undef  CONFIG_SKIP_LIBC
; #  define CONFIG_SKIP_LIBC 1
; #  include <dosmc.h>  /* strcpy_far(...), strcmp_far(...), open2(...) etc. */
; #  ifndef MSDOS  /* Not necessary, already done in the newest __DOSMC__. */
; #    define MSDOS 1
; #  endif
; #  ifndef CONFIG_USE_MEMCPY_INLINE
; #    define CONFIG_USE_MEMCPY_INLINE 1
; #  endif
; #  ifndef CONFIG_USE_OPEN2
; #    define CONFIG_USE_OPEN2 1  /* Provided by __DOSMC__. */
; #  endif
; #endif
; 
; #if !CONFIG_SKIP_LIBC && defined(__XTINY__)
; #  undef  CONFIG_SKIP_LIBC
; #  define CONFIG_SKIP_LIBC 1
; #  define _FILE_OFFSET_BITS 64  /* Make off_t for lseek(..) 64-bit, if available. */
; #  include <xtiny.h>
; #  ifndef CONFIG_MALLOC_FAR_USING_SYS_BRK
; #    define CONFIG_MALLOC_FAR_USING_SYS_BRK 1
; #  endif
; #endif
; 
; #if !CONFIG_SKIP_LIBC  /* More or less Standard C. */
; #  undef  CONFIG_SKIP_LIBC
; #  define CONFIG_SKIP_LIBC 1
; #  define _FILE_OFFSET_BITS 64  /* Make off_t for lseek(..) 64-bit, if available. */
; #  include <ctype.h>
; #  include <fcntl.h>  /* open(...), O_BINARY. */
; #  include <stdio.h>  /* remove(...) */
; #  include <stdlib.h>
; #  include <string.h>
; #  if defined(__TURBOC__) && !defined(MSDOS)  /* Turbo C++ 3.0 doesn't define MSDOS. Borland C++ 3.0 also defines __TURBOC__, and it doesn't define MSDOS. Microsoft C 6.00a defines MSDOS. */
; #    define MSDOS 1  /* FYI Turbo C++ 1.00 is not supported, because for the macro MATCH_CASEI_LEVEL_TO_VALUE2 it incorrectly reports the error: Case outside of switch in function match_expression */
; #  endif
; #  if defined(_WIN32) || defined(_WIN64) || defined(MSDOS)  /* tcc.exe with Win32 target doesn't have <unistd.h>. For `owcc -bdos' and `owcc -bwin32', both <io.h> and <unistd.h> works.  For __TURBOC__, only <io.h> works. */
; #    include <io.h>  /* setmode(...) */
; #    if defined(__TURBOC__) || !(defined(_WIN32) || defined(_WIN64))
; #      define creat(filename, mode) open(filename, O_CREAT | O_TRUNC | O_WRONLY | O_BINARY, mode)  /* In __TURBOC__ != 0x296, a nonzero mode must be passed, otherwise creat(...) will fail. */
; #    else
; #      define creat(filename, mode) open(filename, O_CREAT | O_TRUNC | O_WRONLY | O_BINARY, 0)  /* 0 to prevent Wine msvcrt.dll warning: `fixme:msvcrt:MSVCRT__wsopen_s : pmode 0x406b9b ignored.'. Also works with `owcc -bwin32' (msvcrtl.dll) and `owcc -bdos'. */
; #    endif
; #  else
; #    include <unistd.h>
; #  endif
; #  if (defined(__TURBOC__) || defined(__PACIFIC__) || defined(_MSC_VER)) && defined(MSDOS)  /* __TURBOC__ values: Turbo C++ 1.01 (0x296), Turbo C++ 3.0 (0x401), Borland C++ 2.0 (0x297), Borland C++ 3.0 (0x400), Borland C++ 5.2 (0x520), Microsoft C 6.00a don't have a typedef ... off_t. */
; typedef long off_t;  /* It's OK to define it multiple times, so not a big risk. */
; #  endif
; #  if defined(__WATCOMC__) && defined(__LINUX__)  /* Defined by __WATCOMC__: `owcc -blinux' or wcl `-bt=linux'. */
; #    undef O_BINARY  /* Fix bug in OpenWatcom <unistd.h>. It defines O_BINARY as O_TRUNC, effectively overwriting input files. */
; #  endif
; #  if defined(__TURBOC__)
; #    pragma warn -rch  /* Unreachable code. */
; #    pragma warn -ccc  /* Condition is always true/false. */
; #  endif
; #endif  /* Else ifdef __DOSMC__. */
; 
; #ifndef O_BINARY  /* Unix. */
; #define O_BINARY 0
; #endif
; 
; #ifndef CONFIG_USE_OPEN2
; #  define CONFIG_USE_OPEN2 0
; #endif
; #if !CONFIG_USE_OPEN2
; #  define open2(pathname, flags) open(pathname, flags, 0)
; #endif
; 
; #ifndef CONFIG_USE_MEMCPY_INLINE
; #  define CONFIG_USE_MEMCPY_INLINE 0
; #endif
; 
; #ifndef CONFIG_IS_SIZEOF_INT_AT_LEAST_4
; #  if defined(__SIZEOF_INT__)  /* GCC has it, tried with GCC 4.8. */
; #    if __SIZEOF_INT__ >= 4
; #      define CONFIG_IS_SIZEOF_INT_AT_LEAST_4 1
; #    endif
; #  else  /* OpenWatcom only defines this _M_I386 for 32-bit (and maybe 64-bit?) targets, e.g. `owcc -bwin32' or `owcc -bdos32a', but not for `owcc -bdos'. Likewise, _M_I86 for only 16-bit targets. */
; #    if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__) || defined(__i386__) || defined(__386) || defined(__X86_64__) || defined(_M_I386) || defined(_M_ARM) || defined(_M_ARM64) || defined(__m68k__) || defined(__ia64__) || defined(_M_IA64) || defined(__powerpc__) || defined(_M_PPC)
; #      define CONFIG_IS_SIZEOF_INT_AT_LEAST_4 1
; #    endif
; #  endif
; #  ifndef CONFIG_IS_SIZEOF_INT_AT_LEAST_4
; #    define CONFIG_IS_SIZEOF_INT_AT_LEAST_4 0
; #  endif
; #endif
; 
; #if !defined(CONFIG_CPU_X86)
; #if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__) || defined(_M_IX86) || defined(__i386__) || defined(__386) || defined(__X86_64__) || defined(_M_I386) || defined(__X86__) || defined(__I86__) || defined(_M_I86) || defined(_M_I8086) || defined(_M_I286)
; #define CONFIG_CPU_X86 1
; #else
; #define CONFIG_CPU_X86 1
; #endif
; #endif
; 
; #if !defined(CONFIG_CPU_UNALIGN)
; #if CONFIG_CPU_X86
; #define CONFIG_CPU_UNALIGN 1  /* CPU supports unaligned memory access. i386 and amd64 do, arm and arm64 don't.  */
; #else
; #define CONFIG_CPU_UNALIGN 0
; #endif
; #endif
; 
; #if !defined(CONFIG_CPU_IDIV_TO_ZERO)
; #if CONFIG_CPU_X86
; #define CONFIG_CPU_IDIV_TO_ZERO 1  /* Signed integer division is guaranteed to round towards zero. */
; #else
; #define CONFIG_CPU_IDIV_TO_ZERO 0
; #endif
; #endif
; 
; #if !defined(CONFIG_INT_SHIFT_OK_31)
; #if CONFIG_IS_SIZEOF_INT_AT_LEAST_4  /* 32-bit or 64-bit x86. Doesn't match 16-bit. */
; #define CONFIG_INT_SHIFT_OK_31 1  /* `(value_t)x << 31' and `(value_t)x >> 31' works in C for 16-bit and 32-bit value_t. */
; #else
; #define CONFIG_INT_SHIFT_OK_31 0
; #endif
; #endif
; 
; #ifndef CONFIG_BALANCED
; #define CONFIG_BALANCED 1
; #endif
; 
; #ifndef CONFIG_STRUCT_PACKED
; #if defined(__DOSMC__) || ((defined(__WATCOMC__) || defined(__GNUC__) || defined(__TINYC__)) && CONFIG_CPU_UNALIGN)
; #define CONFIG_STRUCT_PACKED 1
; #else
; #define CONFIG_STRUCT_PACKED 0
; #endif
; #endif
; 
; #undef  STRUCT_PACKED_PREFIX
; #define STRUCT_PACKED_PREFIX
; #undef  STRUCT_PACKED_SUFFIX
; #define STRUCT_PACKED_SUFFIX
; #if CONFIG_STRUCT_PACKED
; #if defined(__DOSMC__) || (defined(__WATCOMC__) && CONFIG_CPU_UNALIGN)
; #undef  STRUCT_PACKED_PREFIX
; #define STRUCT_PACKED_PREFIX _Packed  /* Disable extra aligment byte at the end of `struct label' etc. */
; #else
; #if (defined(__GNUC__) || defined(__TINYC__)) && CONFIG_CPU_UNALIGN
; #undef  STRUCT_PACKED_SUFFIX
; #define STRUCT_PACKED_SUFFIX __attribute__((packed)) __attribute__((aligned(1)))
; #endif
; #endif
; #endif
; 
; #ifndef CONFIG_DOSMC_PACKED
; #ifdef __DOSMC__
; #define CONFIG_DOSMC_PACKED 1
; #else
; #define CONFIG_DOSMC_PACKED 0
; #endif
; #endif
; #if CONFIG_DOSMC_PACKED && !defined(__DOSMC__)
; #  error CONFIG_DOSMC_PACKED needs __DOSMC__.
; #endif
; 
; #ifndef CONFIG_MALLOC_FAR_USING_SYS_BRK
; #define CONFIG_MALLOC_FAR_USING_SYS_BRK 0
; #endif
; 
; #ifndef CONFIG_CAN_FD_BE_NEGATIVE
; #  define CONFIG_CAN_FD_BE_NEGATIVE 0
; #endif
; #if CONFIG_CAN_FD_BE_NEGATIVE
; #  define HAS_OPEN_FAILED(result) ((result) == -1)
; #else
; #  define HAS_OPEN_FAILED(result) ((result) < 0)
; #endif
; 
; #ifdef __GNUC__
; #  define UNALIGNED __attribute__((aligned(1)))
; #  if defined(__i386__) || defined(__386) || defined(_M_I386) || defined(_M_ARM) || defined(__m68k__) || defined(__powerpc__) || defined(_M_PPC)  /* Not the 64-bit variants. */
; #    define ALIGN_MAYBE_4 __attribute__((aligned(4)))
; #  else
; #    define ALIGN_MAYBE_4
; #  endif
; #else
; #  ifdef __WATCOMC__
; #    define UNALIGNED __unaligned
; #  else
; #    define UNALIGNED
; #  endif
; #  define ALIGN_MAYBE_4
; #endif
; 
; #ifndef CONFIG_DOSMC_LIMIT_MEMORY_64K  /* 64 KiB of limit applied to total program usage (including code, global variables, stack and labels, excluding buffers managed by DOS). */
; #  define CONFIG_DOSMC_LIMIT_MEMORY_64K 0
; #endif
; 
; #if CONFIG_DOSMC_LIMIT_MEMORY_64K
; #  define DOSMC_ADD_AX_AVAILABLE_PARAS "add ax, 1000h"  /* 64 KiB is 0x1000 paragraphs. */
; #else
; #  define DOSMC_ADD_AX_AVAILABLE_PARAS "add ax, [es:3]"  /* Size of block in paragraphs. DOS has preallocated it to maximum size when loading the .com program. */
; #endif
; 
; #ifdef __DOSMC__
; __LINKER_FLAG(stack_size__0x140)  /* Specify -sc to dosmc, and run it to get the `max st:HHHH' value printed, and round up 0xHHHH to here. Typical value: 0x134. */
; /* Below is a simple malloc implementation using an arena which is never
;  * freed. Blocks are rounded up to paragraph (16-byte) boundary.
;  */
; #ifndef __MOV_AX_PSP_MCB__
; #error Missing __MOV_AX_PSP_MCB__, please compile .c file with dosmc directly.
; #endif
; static struct {
;   unsigned malloc_end_para;  /* Paragraph (segment) of end-of-heap. */
;   char far *malloc_p;  /* First free byte on the heap. */
; } __malloc_struct__;
; static void malloc_init(void);
; #pragma aux malloc_init = \
; "mov ax, ds" \
; "add ax, offset __sd_top__" \
; "mov word ptr [offset __malloc_struct__+4], ax"  /* Set segment of malloc_p, keep offset (as 0). */ \
; __MOV_AX_PSP_MCB__ \
; "mov es, ax"  /* Memory Control Block (MCB). */ \
; "inc ax"  /* Program Segment Prefix (PSP). */ \
; DOSMC_ADD_AX_AVAILABLE_PARAS \
; "mov word ptr [offset __malloc_struct__], ax"  /* Set malloc_end_para. */ \
; ;
; /* Allocates `size' bytes unaligned. Returns the beginning of the allocated
;  * data. With this arena allocator there is no way to free afterwards.
;  */
; static void far *malloc_far(int size);
; 
; /* We can use an inline assembly function since we call malloc_far only once, so the code won't be copy-pasted many times. */
; #pragma aux malloc_far = \
; "mov cl, 4" \
; "mov si, offset __malloc_struct__+2"  /* Offset part of malloc_p. */ \
; "add ax, [si]" \
; "mov dx, ax" \
; "and ax, 0fh" \
; "shr dx, cl" \
; "add dx, [si + 2]" \
; "cmp dx, word ptr [si - 2]"  /* malloc_end_para. */ \
; "ja @$out_of_memory" \
; "jb @$fits" \
; "test ax, ax" \
; "jz @$fits" \
; "@$out_of_memory:" \
; "xor ax, ax" \
; "xor dx, dx"  /* Set result pointer to NULL. */ \
; "jmp short @$done" \
; "@$fits:" \
; "xchg ax, [si]" \
; "xchg dx, [si + 2]" \
; "@$done:" \
; value [dx ax] \
; parm [ax] \
; modify [si cl]
; #  define MY_FAR far
; #  define USING_FAR 1
; /* strcpy_far(...) and strcmp_far(...) are defined in <dosmc.h>. */
; #else  /* Of ifdef __DOSMC__ */
; #  define MY_FAR
; #  define USING_FAR 0
; #  define strcpy_far(dest, src) strcpy(dest, src)
; #  define strcmp_far(s1, s2) strcmp(s1, s2)
; #  define malloc_init() do {} while (0)
; #  if CONFIG_MALLOC_FAR_USING_SYS_BRK
; /* MAYBE_STATIC void *sys_brk(void *addr); */  /* Provided by the libc. */
; #if 0  /* For debugging. */
; static void writehex(const char *hdr, unsigned long u) {
;     char tmp[9], *p = tmp + 8;
;     unsigned char n;
;     (void)!write(2, hdr, strlen(hdr));
;     *p = '\n';
;     while (p != tmp) {
;         n = u & 15;
;         if (n > 9) n += 'a' - '0' - 10;
;         *--p = n + '0';
;         u >>= 4;
;     }
;     (void)!write(2, tmp, 9);
; }
; #endif
; /*
;  ** A simplistic allocator which creates a heap of 64 KiB first, and then
;  ** doubles it when necessary. It is implemented using Linux system call
;  ** brk(2), exported by the libc as sys_brk(...). free(...)ing is not
;  ** supported. Returns an unaligned address (which is OK on x86).
;  **
;  ** TODO(pts): Rewrite it in assembly, size-optimize it.
;  */
; static void *malloc_far(size_t size) {
;     static char *base, *free, *end;
;     ssize_t new_heap_size;
;     if ((ssize_t)size <= 0) return NULL;  /* Fail if size is too large (or 0). */
;     if (!base) {
;         if (!(base = free = (char*)sys_brk(NULL))) return NULL;  /* Error getting the initial data segment size for the very first time. */
;         new_heap_size = 64 << 10;  /* 64 KiB. */
;         end = base + new_heap_size;
;         goto grow_heap;
;     }
;     while (size > (size_t)(end - free)) {  /* Double the heap size until there is `size' bytes free. */
;         new_heap_size = (end - base) << 1;  /* !! TODO(pts): Don't allocate more than 1 MiB if not needed. */
;       grow_heap:
;         if ((ssize_t)new_heap_size <= 0 || (size_t)base + new_heap_size < (size_t)base) return NULL;  /* Heap would be too large. */
;         end = base + new_heap_size;
;         if ((char*)sys_brk(end) != end) return NULL;  /* Out of memory. */
;     }
;     free += size;
;     return free - size;
; }
; #  else  /* Of if CONFIG_MALLOC_FAR_USING_SYS_BRK. */
; #    define malloc_far(size) malloc(size)
; #  endif  /* Else if CONFIG_MALLOC_FAR_USING_SYS_BRK. */
; #endif  /* Else ifdef __DOSMC__. */
; 
; /* Example usage:
;  * static const STRING_WITHOUT_NUL(msg, "Hello, World!\r\n$");
;  * ... printmsgx(msg);
;  */
; #ifdef __cplusplus  /* We must reserve space for the NUL. */
; #define MY_STRING_WITHOUT_NUL(name, value) UNALIGNED char name[sizeof(value)] = value
; #define STRING_SIZE_WITHOUT_NUL(name) (sizeof(name) - 1)
; #else
; #define MY_STRING_WITHOUT_NUL(name, value) UNALIGNED char name[sizeof(value) - 1] = value
; #define STRING_SIZE_WITHOUT_NUL(name) (sizeof(name))
; #endif
; 
; /* We aim for compatibility with NASM 0.98.39, so we do unsigned by default.
;  * Signed (sign-extended): NASM 0.99.06, Yasm 1.2.0, Yasm, 1.3.0, NASM 2.13.02.
;  * Unsigned (zero-extended): NASM 0.98.39
;  */
; #ifndef CONFIG_SHIFT_SIGNED
; #define CONFIG_SHIFT_SIGNED 0
; #endif
; 
; #ifndef DEBUG
; #define DEBUG 0
; #endif
; #if DEBUG && !defined(__DOSMC__)  /* fprintf not available in __DOSMC__. */
; #include <stdio.h>
; #define DEBUG0(fmt) fprintf(stderr, "debug: " fmt)
; #define DEBUG1(fmt, a1) fprintf(stderr, "debug: " fmt, a1)
; #define DEBUG2(fmt, a1, a2) fprintf(stderr, "debug: " fmt, a1, a2)
; #define DEBUG3(fmt, a1, a2, a3) fprintf(stderr, "debug: " fmt, a1, a2, a3)
; #define DEBUG4(fmt, a1, a2, a3, a4) fprintf(stderr, "debug: " fmt, a1, a2, a3, a4)
; #else
; #define DEBUG0(fmt) do {} while (0)
; #define DEBUG1(fmt, a1) do {} while (0)
; #define DEBUG2(fmt, a1, a2) do {} while (0)
; #define DEBUG3(fmt, a1, a2, a3) do {} while (0)
; #define DEBUG4(fmt, a1, a2, a3, a4) do {} while (0)
; #endif
; 
; static char *output_filename;
; static int output_fd;
; 
; static int listing_fd = -1;
; 
; #ifndef CONFIG_VALUE_BITS
; #define CONFIG_VALUE_BITS 32
; #endif
; 
; #undef IS_VALUE_LONG
; #if CONFIG_VALUE_BITS == 16
; #define IS_VALUE_LONG 0
; #define FMT_VALUE ""
; typedef short value_t;  /* At least CONFIG_VALUE_BITS bits, preferably exactly. */  /* !! TODO(pts): Use uvalue_t in more location, to get modulo 2**n arithmetics instead of undefined behavior without gcc -fwrapv. */
; typedef unsigned short uvalue_t;  /* At least CONFIG_VALUE_BITS bits, preferably exactly. */
; #define GET_VALUE(value) (value_t)(sizeof(short) == 2 ? (short)(value) : (short)(((short)(value) & (short)0x7fff) | -((short)(value) & (short)0x8000U)))  /* Sign-extended. */
; #define GET_UVALUE(value) (uvalue_t)(sizeof(unsigned short) == 2 ? (unsigned short)(value) : (unsigned short)(value) & 0xffffU)
; #define GET_U16(value) (unsigned short)(sizeof(unsigned short) == 2 ? (unsigned short)(value) : (unsigned short)(value) & 0xffffU)
; #else
; #if CONFIG_VALUE_BITS == 32
; #if CONFIG_IS_SIZEOF_INT_AT_LEAST_4  /* Optimization in case sizeof(long) == 8, it would be too much. */
; #define IS_VALUE_LONG 0
; #define FMT_VALUE ""
; typedef int value_t;
; typedef unsigned uvalue_t;
; #else  /* sizeof(long) >= 4 is guaranteed by the C standard. */
; #define IS_VALUE_LONG 1
; #define FMT_VALUE "l"
; typedef long value_t;
; typedef unsigned long uvalue_t;
; #endif
; #define GET_VALUE(value) (value_t)(sizeof(value_t) == 4 ? (value_t)(value) : sizeof(int) == 4 ? (value_t)(int)(value) : sizeof(long) == 4 ? (value_t)(long)(value) : (value_t)(((long)(value) & 0x7fffffffL) | -((long)(value) & (long)0x80000000UL)))
; #define GET_UVALUE(value) (uvalue_t)(sizeof(uvalue_t) == 4 ? (uvalue_t)(value) : sizeof(unsigned) == 4 ? (uvalue_t)(unsigned)(value) : sizeof(unsigned long) == 4 ? (uvalue_t)(unsigned long)(value) : (uvalue_t)(value) & 0xffffffffUL)
; #define GET_U16(value) (unsigned short)(sizeof(unsigned short) == 2 ? (unsigned short)(value) : (unsigned short)(value) & 0xffffU)
; #else
; #error CONFIG_VALUE_BITS must be 16 or 32.
; #endif
; #endif
; typedef char assert_value_size[sizeof(value_t) * 8 >= CONFIG_VALUE_BITS];
; 
; #define CONFIG_BBPRINTF_LONG IS_VALUE_LONG
; #define CONFIG_BBPRINTF_STATIC static
; 
; /* Start of #include "bbprintf.c" */
; 
; /* Based on: https://www.menie.org/georges/embedded/printf-stdarg.c
;  * Downloaded on 2022-05-27.
;  *
;  * Copyright 2001-2021 Georges Menie
;  * https://www.menie.org/georges/embedded/small_printf_source_code.html
;  * stdarg version contributed by Christian Ettinger
;  *
;  * This program is free software; you can redistribute it and/or modify
;  * it under the terms of the GNU Lesser General Public License as published by
;  * the Free Software Foundation; either version 2 of the License, or
;  * (at your option) any later version.
;  *
;  * This program is distributed in the hope that it will be useful,
;  * but WITHOUT ANY WARRANTY; without even the implied warranty of
;  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  * GNU Lesser General Public License for more details.
;  *
;  * You should have received a copy of the GNU Lesser General Public License
;  * along with this program; if not, write to the Free Software
;  * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;  *
;  * !! TODO(pts): See if https://www.sparetimelabs.com/tinyprintf/tinyprintf.php is any shorter.
;  */
; 
; #ifndef va_arg
; #ifdef __TINYC__  /* Works with tcc, pts-tcc (Linux i386 target), pts-tcc64 (Linux amd64 target) and tcc.exe (Win32, Windows i386 target). */
; #if defined(__i386__) /* || defined(__amd64__)*/ || defined(__x86_64__)
; #ifdef __i386__
; typedef char *va_list;  /* i386 only. */
; #define va_start(ap, last) ap = ((char *)&(last)) + ((sizeof(last)+3)&~3)  /* i386 only. */
; #define va_arg(ap, type) (ap += (sizeof(type)+3)&~3, *(type *)(ap - ((sizeof(type)+3)&~3)))  /* i386 only. */
; #define va_copy(dest, src) (dest) = (src)  /* i386 only. */
; #define va_end(ap)  /* i386 only. */
; #endif
; #ifdef __x86_64__  /* amd64. */
; #ifdef _WIN32
; #error Windows is supported only on i386.
; #endif
; #ifdef _WIN64
; #error Windows is supported only on i386.
; #endif
; typedef struct {
;   unsigned int gp_offset;
;   unsigned int fp_offset;
;   union {
;     unsigned int overflow_offset;
;     char *overflow_arg_area;
;   };
;   char *reg_save_area;
; } __va_list_struct;
; typedef __va_list_struct va_list[1];
; void __va_start(__va_list_struct *ap, void *fp);
; void *__va_arg(__va_list_struct *ap, int arg_type, int size, int align);
; typedef va_list __gnuc_va_list;
; #define va_start(ap, last) __va_start(ap, __builtin_frame_address(0))  /* amd64 only. */
; #define va_arg(ap, type) (*(type *)(__va_arg(ap, __builtin_va_arg_types(type), sizeof(type), __alignof__(type))))  /* amd64 only. */
; #define va_copy(dest, src) (*(dest) = *(src))  /* amd64 only. */
; #define va_end(ap)  /* amd64 only. */
; #endif
; #else
; #error tcc is only supported on i386 and amd64.
; #endif
; #else
; #include <stdarg.h>
; #endif
; #endif  /* !defined(va_arg) */
; 
; #if defined(__GNUC__) && defined(__i386__)  /* TODO(pts): Check MinGW GCC Win32 target. */
; /* This is a size optimization. It only works on i386 and if the function
;  * taking the `...' arguments is __attribute__((noinline)). It makes the
;  * program 104 bytes shorter.
;  */
; #define BBVA_NOINLINE __attribute__((noinline))
; typedef char *bbva_list;
; #define bbva_start(ap, last) ((ap) = (char*)&(last) + ((sizeof(last)+3)&~3), (void)0)  /* i386 only. */
; #define bbva_arg(ap, type) ((ap) += (sizeof(type)+3)&~3, *(type*)((ap) - ((sizeof(type)+3)&~3)))  /* i386 only. */
; #define bbva_copy(dest, src) ((dest) = (src), (void)0)  /* i386 only. */
; #define bbva_end(ap) /*((ap) = 0, (void)0)*/  /* i386 only. Adding the `= 0' back doesn't make a difference. */
; #else
; #define BBVA_NOINLINE
; #define bbva_list va_list  /* This would change the executable program with __DOSMC__: `typedef va_list bbva_list;`. */
; #define bbva_start(ap, last) va_start(ap, last)
; #define bbva_arg(ap, type) va_arg(ap, type)
; #define bbva_copy(dest, src) va_copy(dest, src)
; #define bbva_end(ap) va_end(ap)
; #endif
; 
; #ifndef CONFIG_BBPRINTF_LONG
; #define CONFIG_BBPRINTF_LONG 0
; #endif
; 
; 
; /* Start of #include "bbprintf.h" */
; 
; #ifndef _BBPRINTF_H_
; #define _BBPRINTF_H_ 1
; /*#pragma once*/  /* __PACIFIC__ doesn't have it. It doesn't help us much, so we skip it. */
; 
; #ifndef CONFIG_BBPRINTF_STATIC
; #define CONFIG_BBPRINTF_STATIC
; #endif
; 
; struct bbprintf_buf {
;   char *buf, *buf_end, *p;
;   void *data;  /* Used by bbb.flush. */
;   void (*flush)(struct bbprintf_buf *bbb);
; };
; 
; CONFIG_BBPRINTF_STATIC int bbprintf(struct bbprintf_buf *bbb, const char *format, ...);
; 
; #if 0 /* Unused. */
; /* out must not be NULL. */
; CONFIG_BBPRINTF_STATIC int bbsprintf(char *out, const char *format, ...);
; #endif
; 
; #if 0 /* Unused. */
; /* out must not be NULL. size must be >= 1. */
; CONFIG_BBPRINTF_STATIC int bbsnprintf(char *out, int size, const char *format, ...);
; #endif
; 
; CONFIG_BBPRINTF_STATIC void bbwrite1(struct bbprintf_buf *bbb, int c);
; 
; #endif  /* _BBPRINTF_H_ */
; 
; /* End of #include "bbprintf.h" */
; 
; 
; CONFIG_BBPRINTF_STATIC void bbwrite1(struct bbprintf_buf *bbb, int c) {
bbwrite1_:
		push bx
		push si
		mov bx, ax

;   while (bbb->p == bbb->buf_end) {
@$1:
		mov si, word [bx+4]
		cmp si, word [bx+2]
		jne @$2

;     bbb->flush(bbb);
		mov ax, bx
		call word [bx+8]

;   }
		jmp @$1

;   *bbb->p++ = c;
@$2:
		lea ax, [si+1]
		mov word [bx+4], ax
		mov byte [si], dl

; }
		pop si
		pop bx
		ret

; 
; #define PAD_RIGHT 1
; #define PAD_ZERO 2
; 
; #if CONFIG_BBPRINTF_LONG
; /* This comment line is to pacify Borland C++ 3.0 compiler not recognizing the no-CR LF line break in the previous line upon a successful #if. */
; #define BBPRINTF_INT long
; #else
; #define BBPRINTF_INT int
; #endif
; 
; static int print(struct bbprintf_buf *bbb, const char *format, bbva_list args) {
print_:
		push cx
		push si
		push di
		push bp
		mov bp, sp
		sub sp, 0x1e
		push ax
		mov si, dx
		mov word [bp-0xa], bx

;   register unsigned width, pad;
;   register unsigned pc = 0;
		mov word [bp-0x10], 0

;   /* String buffer large enough for the longest %u and %x. */
;   char print_buf[sizeof(BBPRINTF_INT) == 4 ? 11 : sizeof(BBPRINTF_INT) == 2 ? 6 : sizeof(BBPRINTF_INT) * 3 + 1];
;   char c;
;   unsigned BBPRINTF_INT u;
;   unsigned b;
;   unsigned char letbase, t;
;   /*register*/ char *s;
;   char neg;
; 
;   for (; *format != 0; ++format) {
@$3:
		mov al, byte [si]
		test al, al
		je @$6

;     if (*format == '%') {
		cmp al, 0x25
		jne @$7

;       ++format;
;       width = pad = 0;
		xor ax, ax
		mov word [bp-0xc], ax
		mov word [bp-6], ax

		inc si

;       if (*format == '\0') break;
		mov al, byte [si]
		test al, al
		je @$6

;       if (*format == '%') goto out;
		cmp al, 0x25
		je @$7

;       if (*format == '-') {
		cmp al, 0x2d
		jne @$4

;         ++format;
;         pad = PAD_RIGHT;
		mov ax, 1
		mov word [bp-0xc], ax

		add si, ax

;       }
;       while (*format == '0') {
@$4:
		cmp byte [si], 0x30
		jne @$5

;         ++format;
;         pad |= PAD_ZERO;
		or byte [bp-0xc], 2

		inc si

;       }
		jmp @$4

;       for (; *format >= '0' && *format <= '9'; ++format) {
@$5:
		mov al, byte [si]
		cmp al, 0x30
		jb @$8
		cmp al, 0x39
		ja @$8

;         width *= 10;
		mov ax, word [bp-6]
		mov dx, 0xa
		mul dx
		mov word [bp-6], ax

;         width += *format - '0';
		mov al, byte [si]
		xor ah, ah
		sub ax, 0x30
		add word [bp-6], ax

;       }
		inc si
		jmp @$5
@$6:
		jmp near @$45
@$7:
		jmp near @$42

;       c = *format;
@$8:
		mov cl, byte [si]

;       s = print_buf;
		lea di, [bp-0x1e]
		mov ax, word [bp-0xa]
		inc ax
		inc ax

;       if (c == 's') {
		cmp cl, 0x73
		jne @$16

;         s = bbva_arg(args, char*);
		mov word [bp-0xa], ax
		mov di, ax
		mov di, word [di-2]

;         if (!s) s = (char*)"(null)";
		test di, di
		jne @$9
		mov di, @$927

;        do_print_s:
;         /* pc += prints(bbb, s, width, pad); */
;         c = ' ';  /* padchar. */
@$9:
		mov cl, 0x20

;         if (width > 0) {
		cmp word [bp-6], 0
		jbe @$14

;           register unsigned len = 0;
		xor ax, ax

;           register const char *ptr;
;           for (ptr = s; *ptr; ++ptr) ++len;
		mov bx, di
@$10:
		cmp byte [bx], 0
		je @$11
		inc ax
		inc bx
		jmp @$10

;           if (len >= width) width = 0;
@$11:
		cmp ax, word [bp-6]
		jb @$12
		mov word [bp-6], 0

;           else width -= len;
		jmp @$13
@$12:
		sub word [bp-6], ax

;           if (pad & PAD_ZERO) c = '0';
@$13:
		test byte [bp-0xc], 2
		je @$14
		mov cl, 0x30

;         }
;         if (!(pad & PAD_RIGHT)) {
@$14:
		test byte [bp-0xc], 1
		jne @$17

;           for (; width > 0; --width) {
@$15:
		cmp word [bp-6], 0
		jbe @$17

;             bbwrite1(bbb, c);
		mov dl, cl
		xor dh, dh
		mov ax, word [bp-0x20]
		call near bbwrite1_

;             ++pc;
		inc word [bp-0x10]

;           }
		dec word [bp-6]
		jmp @$15
@$16:
		jmp @$19

;         }
;         for (; *s ; ++s) {
@$17:
		mov al, byte [di]
		test al, al
		je @$18

;           bbwrite1(bbb, *s);
		mov dl, al
		xor dh, dh
		mov ax, word [bp-0x20]
		call near bbwrite1_

;           ++pc;
		inc word [bp-0x10]

;         }
		inc di
		jmp @$17

;         for (; width > 0; --width) {
@$18:
		cmp word [bp-6], 0
		jbe @$21

;           bbwrite1(bbb, c);
		mov dl, cl
		xor dh, dh
		mov ax, word [bp-0x20]
		call near bbwrite1_

;           ++pc;
		inc word [bp-0x10]

;         }
		dec word [bp-6]
		jmp @$18

;       } else if (c == 'c') {
@$19:
		cmp cl, 0x63
		jne @$20

;         /* char are converted to int then pushed on the stack */
;         s[0] = (char)bbva_arg(args, int);
		mov word [bp-0xa], ax
		mov bx, ax
		mov al, byte [bx-2]
		mov byte [bp-0x1e], al

;         if (width == 0) {  /* Print '\0'. */
		cmp word [bp-6], 0
		je @$27
		jmp @$25

;           bbwrite1(bbb, s[0]);
;           ++pc;
;         } else {
;           goto do_print_1;
;         }
;       } else {
; #if CONFIG_BBPRINTF_LONG
;         if (c == 'l') {  /* !! TODO(pts): Keep u as `long' if sizeof(int) >= 4. This is for saving space and time if sizeof(long) > 4. */
@$20:
		cmp cl, 0x6c
		jne @$22

;           u = bbva_arg(args, unsigned long);
		add word [bp-0xa], 4
		mov bx, word [bp-0xa]
		mov ax, word [bx-4]
		mov word [bp-0x12], ax
		mov ax, word [bx-2]
		mov word [bp-8], ax

;           c = *++format;
		inc si
		mov cl, byte [si]

;         } else {
		jmp @$23
@$21:
		jmp near @$44

;           u = bbva_arg(args, unsigned);
@$22:
		mov word [bp-0xa], ax
		mov bx, ax
		mov ax, word [bx-2]
		mov word [bp-0x12], ax
		mov word [bp-8], 0

;         }
; #else
;         u = bbva_arg(args, unsigned);
; #endif
;         if (!(c == 'd' || c == 'u' || (c | 32) == 'x' )) goto done;  /* Assumes ASCII. */
@$23:
		cmp cl, 0x64
		je @$24
		cmp cl, 0x75
		je @$24
		mov al, cl
		or al, 0x20
		cmp al, 0x78
		jne @$32

;         /* pc += printi(bbb, bbva_arg(args, int), (c | 32) == 'x' ? 16 : 10, c == 'd', width, pad, c == 'X' ? 'A' : 'a'); */
;         /* This code block modifies `width', and it's fine to modify `width' and `pad'. */
;         if (u == 0) {
@$24:
		mov ax, word [bp-8]
		or ax, word [bp-0x12]
		jne @$26

;           s[0] = '0';
		mov byte [di], 0x30

;          do_print_1:
;           s[1] = '\0';
@$25:
		mov byte [di+1], 0

;           goto do_print_s;
		jmp near @$9

;         } else {
;           b = ((c | 32) == 'x') ? 16 : 10;
@$26:
		mov al, cl
		or al, 0x20
		cmp al, 0x78
		jne @$28
		mov ax, 0x10
		jmp @$29
@$27:
		jmp near @$41
@$28:
		mov ax, 0xa
@$29:
		mov word [bp-0xe], ax

;           letbase = ((c == 'X') ? 'A' : 'a') - '0' - 10;
		cmp cl, 0x58
		jne @$30
		mov ax, 0x41
		jmp @$31
@$30:
		mov ax, 0x61
@$31:
		sub ax, 0x3a
		mov byte [bp-4], al

;           if (c == 'd' && b == 10 && (BBPRINTF_INT)u < 0) {
		cmp cl, 0x64
		jne @$33
		cmp word [bp-0xe], 0xa
		jne @$33
		mov ax, word [bp-8]
		test ax, ax
		jge @$33

;             neg = 1;
		mov byte [bp-2], 1

;             u = -(BBPRINTF_INT)u;  /* Casting to BBPRINTF_INT to avoid Borland C++ 5.2 warning: Negating unsigned value. */
		neg word [bp-8]
		neg word [bp-0x12]
		sbb word [bp-8], 0

;           } else {
		jmp @$34
@$32:
		jmp near @$45

;             neg = 0;
@$33:
		mov byte [bp-2], 0

;           }
;           s = print_buf + sizeof(print_buf) - 1;
@$34:
		lea di, [bp-0x14]

;           *s = '\0';
		mov byte [bp-0x14], 0

;           while (u) {
@$35:
		mov ax, word [bp-8]
		or ax, word [bp-0x12]
		je @$37

;             t = u % b;
		mov ax, word [bp-0x12]
		mov dx, word [bp-8]
		mov bx, word [bp-0xe]
		xor cx, cx
		call near __U4D
		mov al, bl

;             if (t >= 10) t += letbase;
		cmp bl, 0xa
		jb @$36
		mov al, byte [bp-4]
		add al, bl

;             *--s = t + '0';
@$36:
		add al, 0x30
		dec di
		mov byte [di], al

;             u /= b;
		mov ax, word [bp-0x12]
		mov dx, word [bp-8]
		mov bx, word [bp-0xe]
		xor cx, cx
		call near __U4D
		mov word [bp-0x12], ax
		mov word [bp-8], dx

;           }
		jmp @$35

;           if (neg) {
@$37:
		cmp byte [bp-2], 0
		jne @$39
@$38:
		jmp near @$9

;             if (width && (pad & PAD_ZERO)) {
@$39:
		cmp word [bp-6], 0
		je @$40
		test byte [bp-0xc], 2
		je @$40

;               bbwrite1(bbb, '-');
		mov dx, 0x2d
		mov ax, word [bp-0x20]
		call near bbwrite1_

;               ++pc;
		inc word [bp-0x10]

;               --width;
		dec word [bp-6]

;             } else {
		jmp @$38

;               *--s = '-';
@$40:
		dec di
		mov byte [di], 0x2d

;             }
		jmp @$38

@$41:
		mov dl, al

;           }
;           goto do_print_s;
;         }
;       }
		jmp @$43

;     } else { out:
;       bbwrite1(bbb, *format);
@$42:
		mov dl, byte [si]
@$43:
		xor dh, dh
		mov ax, word [bp-0x20]
		call near bbwrite1_

;       ++pc;
		inc word [bp-0x10]

;     }
;   }
@$44:
		inc si
		jmp near @$3

;  done:
;   bbva_end(args);
;   return pc;
; }
@$45:
		mov ax, word [bp-0x10]
@$46:
		mov sp, bp
		pop bp
@$47:
		pop di
		pop si
		pop cx
		ret

; 
; CONFIG_BBPRINTF_STATIC BBVA_NOINLINE int bbprintf(struct bbprintf_buf *bbb, const char *format, ...) {
bbprintf_:
		push bx
		push dx
		push bp
		mov bp, sp

;   bbva_list args;
;   bbva_start(args, format);
;   return print(bbb, format, args);
		lea bx, [bp+0xc]
		mov dx, word [bp+0xa]
		mov ax, word [bp+8]
		call near print_

; }
		pop bp
		pop dx
		pop bx
		ret

; 
; #if 0  /* Unused. */
; CONFIG_BBPRINTF_STATIC BBVA_NOINLINE int bbsprintf(char *out, const char *format, ...) {
;   int result;
;   struct bbprintf_buf bbb;
;   bbva_list args;
;   bbb.buf = bbb.buf_end = bbb.p = out;
;   --bbb.buf_end;
;   bbva_start(args, format);
;   result = print(&bbb, format, args);
;   *bbb.p = '\0';
;   return result;
; }
; #endif
; 
; #if 0  /* Unused. */
; CONFIG_BBPRINTF_STATIC BBVA_NOINLINE int bbsnprintf(char *out, int size, const char *format, ...) {
;   int result;
;   struct bbprintf_buf bbb;
;   bbva_list args;
;   bbb.buf = bbb.p = out;
;   bbb.buf_end = out + size - 1;
;   bbva_start(args, format);
;   result = print(&bbb, format, args);
;   *bbb.p = '\0';
;   return result;
; }
; #endif
; 
; /* End of #include "bbprintf.c" */
; 
; 
; static uvalue_t line_number;
; 
; static unsigned short assembler_pass;  /* 0 at startup, 1 at offset calculation, >= 2 at code generation. */
; static unsigned char size_decrease_count;
; static value_t default_start_address;
; static value_t start_address;
; static value_t current_address;
; static char is_address_used;
; static char is_start_address_set;
; 
; static unsigned char instruction_addressing;
; static unsigned char instruction_offset_width;
; /* Machine code byte value or 0 segment register missing from effective address [...]. */
; static char instruction_addressing_segment;
; static unsigned short instruction_offset;
; 
; static unsigned char instruction_register;
; 
; static value_t instruction_value;  /* Always all bits valid. */
; 
; /*
;  ** -O0: 2-pass, assume longest on undefined label, exactly the same as NASM 0.98.39 and 0.99.06 default and -O0. This is the default.
;  ** -O1: 2-pass, assume longest on undefined label, make immediates and effective address displacements as short as possble without looking forward.
;  ** -Ox == -OX == -O3 == -O9: full, multipass optimization, make it as short as possible, same as NASM 0.98.39 -O9 and newer NASM 2.x default.
;  */
; static unsigned char opt_level;
; static unsigned char do_opt_lea;  /* -OL. */
; static unsigned char do_opt_segreg;  /* -OG. */
; static unsigned char do_opt_int;  /* -OI. */
; 
; #define MAX_SIZE        256
; 
; static UNALIGNED char instr_name[10];  /* Assembly instruction mnemonic name or preprocessor directive name. Always ends with '\0', maybe truncated. */
; static UNALIGNED char global_label[(MAX_SIZE - 2) * 2 + 1];  /* MAX_SIZE is the maximum allowed line size including the terminating '\n'. Thus 2 in `- 2' is the size of the shortest trailing ":\n". */
; static char *global_label_end;
; 
; static char *generated_cur;
; static char generated_buf[8];
; static char *generated_ptr;
; 
; #ifndef CONFIG_SUPPORT_WARNINGS
; #define CONFIG_SUPPORT_WARNINGS 0
; #endif
; 
; static uvalue_t errors;
; #if CONFIG_SUPPORT_WARNINGS
; static uvalue_t warnings;
; #endif
; static uvalue_t bytes;
; static char have_labels_changed;
; static unsigned char jump_range_bits;
; static unsigned char cpu_level;
; 
; STRUCT_PACKED_PREFIX struct label {
; #if CONFIG_DOSMC_PACKED
;     /* The fields .left_right_ofs, .left_seg_swapped and .right_seg together
;      * contain 2 far pointers (tree_left and tree_right), the is_node_deleted
;      * bit and (if CONFIG_BALANCED is true) the is_node_red bit.
;      * .left_seg_swapped contains the 16-bit segment part of tree_left (it's
;      * byte-swapped (so it's stored big endian), and all bits are negated),
;      * and .right_seg contains the 16-bit segment part of tree_right.
;      * .left_right_ofs contains the offset of the far pointers, the
;      * is_node_deleted bit and (if CONFIG_BALANCED is true) the is_node_red
;      * bit. It is assumed that far pointer offsets are 4 bits wide
;      * (0 <= offset <= 15), because malloc_far guarantees it (with its
;      * `and ax, 0fh' instruction).
;      *
;      * Lemma 1. The first byte of .left_seg_swapped is nonzero. Proof. If it
;      * was zero, then the high 8 bits of left_seg would be 0xff, thus the
;      * linear memory address for tree_left (left child) would be at least
;      * 0xff000, which is too large for a memory address in DOS conventional
;      * memory ending at 0xa0000, and malloc_far allocates from there.
;      *
;      * If CONFIG_BALANCED is false, bits of .left_right_ofs look like
;      * LLLDRRRR, where LLLM is the 4-bit offset of tree_left (see below how
;      * to get M), RRRR is the 4-bit offset of tree_right, and D is the
;      * is_node_deleted bit.
;      *
;      * If CONFIG_BALANCED is true, bits of .left_right_ofs look like
;      * LLLDRRRE, where LLLM is the 4-bit offset of tree_left, RRRS is the
;      * 4-bit offset of tree_right, D is the is_node_deleted bit, E is the
;      * is_node_red bit. The lower M and S bits of the offsets are not stored,
;      * but they will be inferred like below. The pointer with the offset LLL0
;      * is either correct or 1 less than the correct LLL1. If it's correct, then
;      * it points to a nonzero .left_seg_swapped (see Lemma 1 above). If it's 1
;      * less, then it points to the all-zero NUL byte (the NUL terminator of the
;      * name in the previous label). Thus by comparing the byte at offset LLL0
;      * to zero, we can infer whether M is 0 (iff the byte is nonzero) or 1 (iff
;      * the byte is zero). For this to work we need that the very first struct
;      * label starts at an even offset; this is guaranteed by malloc_far.
;      */
;     unsigned left_seg_swapped;  /* Byte-swapped (so it's stored big endian), all bits negated. The first byte is never zero. */
;     unsigned right_seg;
;     unsigned char left_right_ofs;
; #else
;     struct label MY_FAR *tree_left;
;     struct label MY_FAR *tree_right;
; #endif
;     value_t value;
; #if CONFIG_BALANCED && !CONFIG_DOSMC_PACKED
;     char is_node_red;  /* Is it a red node of the red-black tree? */
; #endif
; #if !CONFIG_DOSMC_PACKED
;     char is_node_deleted;
; #endif
;     char name[1];  /* Usually multiple characters terminated by NUL. The last byte is alsways zero. */
; } STRUCT_PACKED_SUFFIX;
; 
; static struct label MY_FAR *label_list;
; static char has_undefined;
; 
; #ifndef CONFIG_SPLIT_INSTRUCTION_SET
; #if defined(_MSC_VER) && _MSC_VER < 900  /* _MSC_VER < 900: Microsoft Visual C++ 1.52 (800 <= _MSC_VER < 900) doesn't have this limit (C4009) of 2048 bytes. */
; /* Without this split, Microsoft C 6.00a (_MSC_VER == 600) will report warning C4009: string too big, trailing characters truncated */
; #define CONFIG_SPLIT_INSTRUCTION_SET 1
; #else
; #define CONFIG_SPLIT_INSTRUCTION_SET 0
; #endif
; #endif
; 
; extern UNALIGNED const char instruction_set[];
; #if CONFIG_SPLIT_INSTRUCTION_SET
; extern const char *instruction_set_nul;
; extern const char instruction_set2[];
; #endif
; 
; static const MY_STRING_WITHOUT_NUL(register_names, "CSDSESSSALCLDLBLAHCHDHBHAXCXDXBXSPBPSIDI");
; #define GP_REGISTER_NAMES (register_names + 8)  /* Skip over segment register names. */
; 
; /* Not declaring static for compatibility with C++ and forward declarations. */
; extern struct bbprintf_buf message_bbb;
; 
; #if CONFIG_SUPPORT_WARNINGS
; static void message(int error, const char *message);
; static void message1str(int error, const char *pattern, const char *data);
; static void message_start(int error);
; #define MESSAGE message
; #define MESSAGE1STR message1str
; #define MESSAGE_START message_start
; #else
; static void message(const char *message);
; static void message1str(const char *pattern, const char *data);
; static void message_start(void);
; #define MESSAGE(error, message_str) message(message_str)
; #define MESSAGE1STR(error, pattern, data) message1str(pattern, data)
; #define MESSAGE_START(error) message_start()
; #endif
; static void message_end(void);
; 
; #ifdef __DESMET__
; /* Work around bug in DeSmet 3.1N runtime: closeall() overflows buffer and clobbers exit status */
; #define exit(status) _exit(status)
; #endif
; 
; #if CONFIG_BALANCED
; /*
;  * Each node in the RB tree consumes at least 1 byte of space (for the
;  * linkage if nothing else, so there are a maximum of 1 << (sizeof(void *)
;  * << 3 rb) tree nodes in any process, and thus, at most that many in any
;  * tree.
;  *
;  * Maximum number of bytes in a process: 1 << (sizeof(void*) << 3).
;  * Log2 of maximum number of bytes in a process: sizeof(void*) << 3.
;  * Maximum number of tree nodes in a process: 1 << (sizeof(void*) << 3) / sizeof(tree_node).
;  * Maximum number of tree nodes in a process is at most: 1 << (sizeof(void*) << 3) / sizeof(rb_node(a_type)).
;  * Log2 of maximum number of tree nodes in a process is at most: (sizeof(void*) << 3) - log2(sizeof(rb_node(a_type)).
;  * Log2 of maximum number of tree nodes in a process is at most without RB_COMPACT: (sizeof(void*) << 3) - (sizeof(void*) >= 8 ? 4 : sizeof(void*) >= 4 ? 3 : 2).
;  */
; #  ifndef RB_LOG2_MAX_MEM_BYTES
; #    ifdef MSDOS
; #      ifdef _M_I386  /* Only __WATCOMC__ (not in GCC, __TURBOC__ or _MSC_VER), only in 32-bit mode, but play it safe. */
; #        define RB_LOG2_MAX_MEM_BYTES (sizeof(void near*) == 2 ? 20 : (sizeof(void*) << 3))
; #      else
; #        define RB_LOG2_MAX_MEM_BYTES 20  /* 1 MiB. */
; #    endif
; #  else
; #    define RB_LOG2_MAX_MEM_BYTES (sizeof(void*) << 3)
; #  endif
; #endif
; /**/
; #ifndef RB_LOG2_MAX_NODES
; #define RB_LOG2_MAX_NODES (RB_LOG2_MAX_MEM_BYTES - (sizeof(void*) >= 8 ? 4 : sizeof(void*) >= 4 ? 3 : 2) - 1)
; #endif
; /**/
; struct tree_path_entry {
;     struct label MY_FAR *label;
;     char less;
; };
; /**/
; #endif  /* CONFIG_BALANCED */
; 
; #if CONFIG_DOSMC_PACKED
; /* Swap the 2 bytes and negate all bits. */
; static unsigned swap16(unsigned u);
; #pragma aux swap16 = "xchg al, ah" "not ax" value [ax] parm [ax]  /* TODO(pts): Optimize for size, try ax, bx and dx. */
; typedef char assert_label_size[sizeof(struct label) == 5 /* left and right pointers, is_node_red */ + sizeof(value_t) + 1 /* trailing NUL in ->name */];
; #define RBL_IS_NULL(label) (FP_SEG(label) == 0)
; #define RBL_IS_LEFT_NULL(label) ((label)->left_seg_swapped == 0xffffU)
; #define RBL_IS_RIGHT_NULL(label) ((label)->right_seg == 0)
; #define RBL_IS_DELETED(label) ((label)->left_right_ofs & 0x10)
; #define RBL_SET_DELETED_0(label) ((label)->left_right_ofs &= ~0x10)
; #define RBL_SET_DELETED_1(label) ((label)->left_right_ofs |= 0x10)
; #if CONFIG_BALANCED
; /* Also sets IS_DELETED to false. */
; #define RBL_SET_LEFT_RIGHT_NULL_ID_0(label) ((label)->left_right_ofs = 0, (label)->left_seg_swapped = 0xffffU, (label)->right_seg = 0)
; static struct label MY_FAR *RBL_GET_LEFT(struct label MY_FAR *label) {
RBL_GET_LEFT_:
		push bx
		push cx
		push si
		mov bx, ax
		mov es, dx

;     char MY_FAR *p = MK_FP(swap16((label)->left_seg_swapped), ((label)->left_right_ofs >> 4) & 0xe);
		mov al, byte [es:bx+4]
		xor ah, ah
		mov cl, 4
		mov si, ax
		sar si, cl
		and si, 0xe
		mov ax, word [es:bx]
		xchg ah, al
		not ax
		mov es, ax
		mov bx, si
		mov dx, ax

;     if (*p == '\0') ++p;  /* Skip trailing NUL of previous label. */
		cmp byte [es:si], 0
		jne @$48
		lea bx, [si+1]

;     return (struct label MY_FAR*)p;
; }
@$48:
		mov ax, bx
		jmp near @$340

; static struct label MY_FAR *RBL_GET_RIGHT(struct label MY_FAR *label) {
RBL_GET_RIGHT_:
		push bx
		push si
		mov bx, ax
		mov es, dx

;     char MY_FAR *p = MK_FP((label)->right_seg, (label)->left_right_ofs & 0xe);
		mov al, byte [es:bx+4]
		and al, 0xe
		xor ah, ah
		mov es, word [es:bx+2]
		mov bx, ax
		mov dx, es

;     if (*p == '\0') ++p;  /* Skip trailing NUL of previous label. */
		mov si, ax
		cmp byte [es:si], 0
		jne @$49
		inc bx

;     return (struct label MY_FAR*)p;
; }
@$49:
		mov ax, bx
		pop si
		pop bx
		ret

; static void RBL_SET_LEFT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
RBL_SET_LEFT_:
		push si
		mov si, ax
		mov ax, cx

;     label->left_seg_swapped = swap16(FP_SEG(ptr));
		xchg ah, al
		not ax
		mov es, dx
		mov word [es:si], ax

;     label->left_right_ofs = (label->left_right_ofs & 0x1f) | (FP_OFF(ptr) & 0xe) << 4;  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
		mov al, byte [es:si+4]
		and al, 0x1f
		xor ah, ah
		and bx, 0xe
		mov cl, 4
		shl bx, cl
		or ax, bx
@$50:
		mov byte [es:si+4], al

; }
		pop si
		ret

; static void RBL_SET_RIGHT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
RBL_SET_RIGHT_:
		push si
		mov si, ax
		mov es, dx

;     label->right_seg = FP_SEG(ptr);
		mov word [es:si+2], cx

;     label->left_right_ofs = (label->left_right_ofs & 0xf1) | (FP_OFF(ptr) & 0xe);  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
		mov al, byte [es:si+4]
		and al, 0xf1
		and bl, 0xe
		or al, bl
		jmp @$50

; }
; #define RBL_IS_RED(label) ((label)->left_right_ofs & 1)  /* Nonzero means true. */
; #define RBL_COPY_RED(label, source_label) ((label)->left_right_ofs = ((label)->left_right_ofs & 0xfe) | ((source_label)->left_right_ofs & 1))
; #define RBL_SET_RED_0(label) ((label)->left_right_ofs &= 0xfe)
; #define RBL_SET_RED_1(label) ((label)->left_right_ofs |= 1)
; #else  /* Else CONFIG_BALANCED. */
; #define RBL_SET_LEFT_RIGHT_NULL_ID_0(label) ((label)->left_right_ofs = (label)->left_seg_swapped = 0xffffU, (label)->right_seg = 0)
; static struct label MY_FAR *RBL_GET_LEFT(struct label MY_FAR *label) {
;     char MY_FAR *p = MK_FP(swap16((label)->left_seg_swapped), ((label)->left_right_ofs >> 4) & 0xe);
;     if (*p == '\0') ++p;  /* Skip trailing NUL of previous label. */
;     return (struct label MY_FAR*)p;
; }
; static struct label MY_FAR *RBL_GET_RIGHT(struct label MY_FAR *label) {
;     char MY_FAR *p = MK_FP((label)->right_seg, (label)->left_right_ofs & 0xf);
;     return (struct label MY_FAR*)p;
; }
; static void RBL_SET_LEFT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
;     label->left_seg_swapped = swap16(FP_SEG(ptr));
;     label->left_right_ofs = (label->left_right_ofs & 0x1f) | (FP_OFF(ptr) & 0xe) << 4;  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
; }
; static void RBL_SET_RIGHT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
;     label->right_seg = FP_SEG(ptr);
;     label->left_right_ofs = (label->left_right_ofs & 0xf0) | FP_OFF(ptr);  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
; }
; #endif  /* CONFIG_BALANCED. */
; #else
; #define RBL_IS_NULL(label) ((label) == NULL)
; #define RBL_IS_LEFT_NULL(label) ((label)->tree_left == NULL)
; #define RBL_IS_RIGHT_NULL(label) ((label)->tree_right == NULL)
; #define RBL_SET_LEFT_RIGHT_NULL_ID_0(label) ((label)->tree_left = (label)->tree_right = NULL, (label)->is_node_deleted = 0)
; #define RBL_GET_LEFT(label) ((label)->tree_left)
; #define RBL_GET_RIGHT(label) ((label)->tree_right)
; #define RBL_SET_LEFT(label, ptr) ((label)->tree_left = (ptr))
; #define RBL_SET_RIGHT(label, ptr) ((label)->tree_right = (ptr))
; #define RBL_IS_DELETED(label) ((label)->is_node_deleted)
; #define RBL_SET_DELETED_0(label) ((label)->is_node_deleted = 0)
; #define RBL_SET_DELETED_1(label) ((label)->is_node_deleted = 1)
; #if CONFIG_BALANCED
; #define RBL_IS_RED(label) ((label)->is_node_red)  /* Nonzero means true. */
; #define RBL_COPY_RED(label, source_label) ((label)->is_node_red = (source_label)->is_node_red)
; #define RBL_SET_RED_0(label) ((label)->is_node_red = 0)
; #define RBL_SET_RED_1(label) ((label)->is_node_red = 1)
; #endif  /* CONFIG_BALANCED. */
; #endif  /* CONFIG_DOSMC_PACKED. */
; 
; static void fatal_out_of_memory(void) {
fatal_out_of_memory_:
		mov ax, @$928
		call near message_

;     MESSAGE(1, "Out of memory");  /* Only applies dynamically allocated memory (malloc(...)), e.g. for labels and wide instructions. */
;     exit(1);
		mov ax, 1
		mov ah, 0x4c
		int 0x21

; }
; 
; /*
;  ** Defines a new label.
;  **
;  ** If the label already exists, it adds a duplicate one. This is not
;  ** useful, so the caller is recommended to call define_label(name, ...)
;  ** only if find_label(name) returns NULL.
;  */
; static struct label MY_FAR *define_label(const char *name, value_t value) {
define_label_:
		push si
		push di
		push bp
		mov bp, sp
		sub sp, 0x16
		mov di, ax
		mov word [bp-0x12], bx
		mov bx, cx

;     struct label MY_FAR *label;
; 
;     /* Allocate label */
;     label = (struct label MY_FAR*)malloc_far((size_t)&((struct label*)0)->name + 1 + strlen(name));
		call near strlen_
		add ax, 0xa
		mov cl, 4
		mov si, ___malloc_struct__+2
		add ax, word [si]
		mov dx, ax
		and ax, 0xf
		shr dx, cl
		add dx, word [si+2]
		cmp dx, word [si-2]
		ja @$51
		jb @$52
		test ax, ax
		je @$52
@$51:
		xor ax, ax
		xor dx, dx
		jmp @$53
@$52:
		xchg word [si], ax
		xchg word [si+2], dx
@$53:
		mov si, ax
		mov word [bp-4], dx
		mov word [bp-0xc], ax
		mov word [bp-0xa], dx

;     if (RBL_IS_NULL(label)) {
		test dx, dx
		jne @$54

;         fatal_out_of_memory();
		call near fatal_out_of_memory_

;         return NULL;
		xor ax, ax
		jmp near @$71

;     }
; 
;     /* Fill label */
;     if (0) DEBUG2("define_label name=(%s) value=0x%x\n", name, (unsigned)value);
;     RBL_SET_LEFT_RIGHT_NULL_ID_0(label);
@$54:
		mov es, dx
		mov byte [es:si+4], 0
		mov word [es:si], 0xffff
		mov word [es:si+2], 0

;     label->value = value;
		mov ax, word [bp-0x12]
		mov word [es:si+5], ax
		mov word [es:si+7], bx

;     strcpy_far(label->name, name);
		mov cx, ds
		lea ax, [si+9]
		mov bx, di
		call near strcpy_far_

; 
;     /* Insert label to binary tree. */
; #if CONFIG_BALANCED
;     /* Red-black tree node insertion implementation based on: commit on 2021-03-17
;      * https://github.com/jemalloc/jemalloc/blob/70e3735f3a71d3e05faa05c58ff3ca82ebaad908/include/jemalloc/internal/rb.h
;      *
;      * Tree with duplicate keys is untested.
;      *
;      * With __DOSMC__, this insertion is 319 bytes longer than the unbalanced alternative below.
;      */
;     {
;         /*
;          * The choice of algorithm bounds the depth of a tree to twice the binary
;          * log of the number of elements in the tree; the following bound follows.
;          */
;         static ALIGN_MAYBE_4 struct tree_path_entry path[RB_LOG2_MAX_NODES << 1];
;         struct tree_path_entry *pathp;
;         RBL_SET_RED_1(label);
		mov es, word [bp-4]
		or byte [es:si+4], 1

;         path->label = label_list;
		mov ax, word [_label_list]
		mov dx, word [_label_list+2]
		mov word [@$tree_path], ax
		mov word [@$tree_path+2], dx

;         for (pathp = path; !RBL_IS_NULL(pathp->label); pathp++) {
		mov si, @$tree_path
@$55:
		mov bx, word [si]
		mov cx, word [si+2]
		test cx, cx
		je @$60

;             const char less = pathp->less = strcmp_far(label->name, pathp->label->name) < 0;
		add bx, 9
		mov ax, word [bp-0xc]
		add ax, 9
		mov dx, word [bp-0xa]
		call near strcmp_far_
		test ax, ax
		jge @$56
		mov al, 1
		jmp @$57
@$56:
		xor al, al
@$57:
		mov byte [si+4], al

;             pathp[1].label = less ? RBL_GET_LEFT(pathp->label) : RBL_GET_RIGHT(pathp->label);
		test al, al
		je @$58
		mov ax, word [si]
		mov dx, word [si+2]
		call near RBL_GET_LEFT_
		jmp @$59
@$58:
		mov ax, word [si]
		mov dx, word [si+2]
		call near RBL_GET_RIGHT_
@$59:
		mov word [si+6], ax
		mov word [si+8], dx

;         }
		add si, 6
		jmp @$55

;         pathp->label = label;
@$60:
		mov ax, word [bp-0xc]
		mov word [si], ax
		mov ax, word [bp-0xa]
@$61:
		mov word [si+2], ax

;         while (pathp-- != path) {
		mov ax, si
		sub si, 6
		cmp ax, @$tree_path
		jne @$62
		jmp near @$69

;             struct label MY_FAR *clabel = pathp->label;
@$62:
		mov di, word [si]
		mov ax, word [si+2]
		mov word [bp-2], ax

;             if (pathp->less) {
		cmp byte [si+4], 0
		je @$65

;                 struct label MY_FAR *left = pathp[1].label;
		mov bx, word [si+6]
		mov word [bp-0x10], bx
		mov ax, word [si+8]
		mov word [bp-0xe], ax

;                 RBL_SET_LEFT(clabel, left);
		mov cx, ax
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_SET_LEFT_

;                 if (RBL_IS_RED(left)) {
		les bx, [bp-0x10]
		test byte [es:bx+4], 1
		je @$63

;                     struct label MY_FAR *leftleft = RBL_GET_LEFT(left);
		mov ax, bx
		mov dx, es
		call near RBL_GET_LEFT_
		mov bx, ax
		mov es, dx

;                     if (!RBL_IS_NULL(leftleft) && RBL_IS_RED(leftleft)) {
		test dx, dx
		je @$64
		test byte [es:bx+4], 1
		je @$64

;                         struct label MY_FAR *tlabel;
;                         RBL_SET_RED_0(leftleft);
		and byte [es:bx+4], 0xfe

;                         tlabel = RBL_GET_LEFT(clabel);
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_GET_LEFT_
		mov word [bp-0x14], ax
		mov word [bp-0x16], dx

;                         RBL_SET_LEFT(clabel, RBL_GET_RIGHT(tlabel));
		call near RBL_GET_RIGHT_
		mov bx, ax
		mov cx, dx
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_SET_LEFT_

;                         RBL_SET_RIGHT(tlabel, clabel);
		mov bx, di
		mov cx, word [bp-2]
		mov ax, word [bp-0x14]
		mov dx, word [bp-0x16]
		call near RBL_SET_RIGHT_

;                         clabel = tlabel;
		mov di, word [bp-0x14]
		mov ax, word [bp-0x16]

;                     }
		jmp near @$67
@$63:
		jmp near @$70
@$64:
		jmp near @$68

;                 } else {
;                     goto done;
;                 }
;             } else {
;                 struct label MY_FAR *right = pathp[1].label;
@$65:
		mov bx, word [si+6]
		mov word [bp-8], bx
		mov ax, word [si+8]
		mov word [bp-6], ax

;                 RBL_SET_RIGHT(clabel, right);
		mov cx, ax
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_SET_RIGHT_

;                 if (RBL_IS_RED(right)) {
		les bx, [bp-8]
		test byte [es:bx+4], 1
		je @$63

;                     struct label MY_FAR *left = RBL_GET_LEFT(clabel);
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_GET_LEFT_
		mov bx, ax
		mov es, dx

;                     if (!RBL_IS_NULL(left) && RBL_IS_RED(left)) {
		test dx, dx
		je @$66
		test byte [es:bx+4], 1
		je @$66

;                          RBL_SET_RED_0(left);
		and byte [es:bx+4], 0xfe

;                          RBL_SET_RED_0(right);
		les bx, [bp-8]
		and byte [es:bx+4], 0xfe

;                          RBL_SET_RED_1(clabel);
		mov es, word [bp-2]
		or byte [es:di+4], 1

;                      } else {
		jmp @$68

;                          struct label MY_FAR *tlabel;
;                          tlabel = RBL_GET_RIGHT(clabel);
@$66:
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_GET_RIGHT_
		mov word [bp-0x16], ax
		mov word [bp-0x14], dx

;                          RBL_SET_RIGHT(clabel, RBL_GET_LEFT(tlabel));
		call near RBL_GET_LEFT_
		mov bx, ax
		mov cx, dx
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_SET_RIGHT_

;                          RBL_SET_LEFT(tlabel, clabel);
		mov bx, di
		mov cx, word [bp-2]
		mov ax, word [bp-0x16]
		mov dx, word [bp-0x14]
		call near RBL_SET_LEFT_

;                          RBL_COPY_RED(tlabel, clabel);
		les bx, [bp-0x16]
		mov al, byte [es:bx+4]
		and al, 0xfe
		mov es, word [bp-2]
		mov ah, byte [es:di+4]
		and ah, 1
		or al, ah
		mov es, word [bp-0x14]
		mov byte [es:bx+4], al

;                          RBL_SET_RED_1(clabel);
		mov es, word [bp-2]
		or byte [es:di+4], 1

;                          clabel = tlabel;
		mov di, bx
		mov ax, word [bp-0x14]
@$67:
		mov word [bp-2], ax

;                      }
;                 } else {
;                     goto done;
;                 }
;             }
;             pathp->label = clabel;
@$68:
		mov word [si], di
		mov ax, word [bp-2]

;         }
		jmp near @$61

;         label_list = path->label;
@$69:
		mov bx, word [@$tree_path]
		mov ax, word [@$tree_path+2]
		mov word [_label_list], bx
		mov word [_label_list+2], ax

;         RBL_SET_RED_0(label_list);
		mov es, ax
		and byte [es:bx+4], 0xfe

;     }
;   done:
; #else  /* Unbalanced binary search tree node insertion. */
;     if (RBL_IS_NULL(label_list)) {
;         label_list = label;
;     } else {
;         struct label MY_FAR *explore = label_list;
;         while (1) {
;             const int c = strcmp_far(label->name, explore->name);
;             if (c < 0) {
;                 if (RBL_IS_LEFT_NULL(explore)) {
;                     RBL_SET_LEFT(explore, label);
;                     break;
;                 }
;                 explore = RBL_GET_LEFT(explore);
;             } else if (c > 0) {
;                 if (RBL_IS_RIGHT_NULL(explore)) {
;                     RBL_SET_RIGHT(explore, label);
;                     break;
;                 }
;                 explore = RBL_GET_RIGHT(explore);
;             }
;         }
;     }
; #endif
;     return label;
@$70:
		mov ax, word [bp-0xc]
		mov dx, word [bp-0xa]

; }
@$71:
		mov sp, bp
		pop bp
		pop di
		pop si
		ret

; 
; #ifdef __DOSMC__
; typedef signed char my_strcatcmp_far_result_t;
; static my_strcatcmp_far_result_t my_strcatcmp_far(const char *s1a, const char MY_FAR *s1b, const char MY_FAR *s2);
; /* strcmp_far: DX:AX == s1, CX:BX == s2, result in AX, but always -1, or -1 (for strcmp_far), so low byte can be used. */
; #pragma aux my_strcatcmp_far = \
;     "xchg ax, cx" \
;     "dec bx" \
;     "L2:" \
;     "inc bx" \
;     "lodsb" \
;     "cmp al, 0" \
;     "jne L3" \
;     "xchg ax, cx" \
;     "mov cx, es" \
;     "call strcmp_far" \
;     "jmp L5" \
;     "L3:" \
;     "sub al, es:[bx]" \
;     "jz L2" \
;     "L5:" \
;     value [ al ] parm [ si ] [ ax dx ] [ bx es ] modify [ si ax bx cx dx es ];
; #else
; typedef int my_strcatcmp_far_result_t;  /* Because of strcmp_far(...). */
; /* Compares strings s1a+s1b (concatenation) and s2 lexicographically like strcmp: returning -1 if the s2 is larger, 0 if equal, 1 if s2 is smaller. */
; static my_strcatcmp_far_result_t my_strcatcmp_far(const char *s1a, const char MY_FAR *s1b, const char MY_FAR *s2) {
;     for (;; ++s1a, ++s2) {
;         if (*s1a == '\0') return strcmp_far(s1b, s2);
;         if (*s1a != *s2) return *(const unsigned char*)s1a - *(const unsigned char MY_FAR*)s2;
;     }
; }
; #endif
; 
; /*
;  ** Find a label named prefix+name.
;  **
;  ** `name' as passed as a far pointer because reset_macros() needs it.
;  */
; static struct label MY_FAR *find_cat_label(const char *prefix, const char MY_FAR *name) {
find_cat_label_:
		push si
		push di
		push bp
		mov bp, sp
		sub sp, 6
		push ax
		push bx
		push cx

;     struct label MY_FAR *explore;
;     struct label MY_FAR *milestone = NULL;
		xor ax, ax
		mov word [bp-6], ax
		mov word [bp-4], ax

;     my_strcatcmp_far_result_t c;
; 
;     /* Follows a binary tree */
;     explore = label_list;
		mov ax, word [_label_list]
		mov word [bp-2], ax
		mov di, word [_label_list+2]

;     while (!RBL_IS_NULL(explore)) {
@$72:
		test di, di
		je @$78

;         c = my_strcatcmp_far(prefix, name, explore->name);
		mov bx, word [bp-2]
		add bx, 9
		mov es, di
		mov ax, word [bp-0xa]
		mov dx, word [bp-0xc]
		mov si, word [bp-8]
		xchg cx, ax
		dec bx
@$73:
		inc bx
		lodsb
		cmp al, 0
		jne @$74
		xchg cx, ax
		mov cx, es
		call near strcmp_far_
		jmp near @$75
@$74:
		sub al, byte [es:bx]
		je @$73

;         if (c == 0) {
@$75:
		test al, al
		jne @$76

;             return explore;
		mov ax, word [bp-2]
		mov dx, di
		jmp @$71

;         } else if (c < 0) {
@$76:
		jge @$77

;             milestone = explore;
		mov ax, word [bp-2]
		mov word [bp-6], ax
		mov word [bp-4], di

;             explore = RBL_GET_LEFT(explore);
		mov dx, di
		call near RBL_GET_LEFT_
		mov word [bp-2], ax
		mov di, dx

;         } else {
		jmp @$72

;             explore = RBL_GET_RIGHT(explore);
@$77:
		mov ax, word [bp-2]
		mov dx, di
		call near RBL_GET_RIGHT_
		mov word [bp-2], ax
		mov di, dx

;             /* Stop on circular path created by Morris inorder traversal, e.g. in reset_macros(). */
;             if (explore == milestone) break;
		cmp dx, word [bp-4]
		jne @$72
		cmp ax, word [bp-6]
		jne @$72

;         }
;     }
;     return NULL;
@$78:
		xor ax, ax
		xor dx, dx

; }
		jmp near @$71

; 
; /*
;  ** Find a label named `name'.
;  **
;  ** `name' as passed as a far pointer because reset_macros() needs it.
;  */
; static struct label MY_FAR *find_label(const char MY_FAR *name) {
find_label_:
		push bx
		push cx

;     return find_cat_label("", name);
		mov bx, ax
		mov cx, dx
		mov ax, @$929
		call near find_cat_label_

; }
		pop cx
		pop bx
		ret

; 
; /*
;  ** Print labels sorted to listing_fd (already done by binary tree).
;  */
; static void print_labels_sorted_to_listing(void) {
print_labels_sorted_to_listing_:
		push bx
		push cx
		push dx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		push ax

;     struct label MY_FAR *node = label_list;
		mov si, word [_label_list]
		mov ax, word [_label_list+2]
		mov word [bp-2], ax

;     struct label MY_FAR *pre;
;     struct label MY_FAR *pre_right;
;     /* Morris inorder traversal of binary tree: iterative (non-recursive,
;      * so it uses O(1) stack), modifies the tree pointers temporarily, but
;      * then restores them, runs in O(n) time.
;      */
;     while (!RBL_IS_NULL(node)) {
@$79:
		mov ax, word [bp-2]
		test ax, ax
		je @$83

;         if (RBL_IS_LEFT_NULL(node)) goto do_print;
		mov es, ax
		cmp word [es:si], 0xffff
		je @$85

;         for (pre = RBL_GET_LEFT(node); pre_right = RBL_GET_RIGHT(pre), !RBL_IS_NULL(pre_right) && pre_right != node; pre = pre_right) {}
		mov ax, si
		mov dx, es
		call near RBL_GET_LEFT_
@$80:
		mov di, ax
		mov word [bp-4], dx
		mov ax, di
		mov dx, word [bp-4]
		call near RBL_GET_RIGHT_
		mov bx, dx
		test dx, dx
		je @$81
		cmp dx, word [bp-2]
		jne @$80
		cmp ax, si
		jne @$80

;         if (RBL_IS_NULL(pre_right)) {
@$81:
		test bx, bx
		jne @$84

;             RBL_SET_RIGHT(pre, node);
		mov bx, si
		mov cx, word [bp-2]
		mov ax, di
		mov dx, word [bp-4]
		call near RBL_SET_RIGHT_

;             node = RBL_GET_LEFT(node);
		mov ax, si
		mov dx, word [bp-2]
		call near RBL_GET_LEFT_
@$82:
		mov si, ax
		mov word [bp-2], dx

;         } else {
		jmp @$79
@$83:
		jmp @$87

;             RBL_SET_RIGHT(pre, NULL);
@$84:
		xor bx, bx
		xor cx, cx
		mov ax, di
		mov dx, word [bp-4]
		call near RBL_SET_RIGHT_

;           do_print:
;             if (node->name[0] != '%') {  /* Skip macro definitions. */
@$85:
		mov es, word [bp-2]
		cmp byte [es:si+9], 0x25
		je @$86

; #if USING_FAR
;                 strcpy_far(global_label, node->name);  /* We copy because bbprintf(...) below doesn't support far pointers. */
		lea bx, [si+9]
		mov cx, es
		mov ax, _global_label
		mov dx, ds
		call near strcpy_far_

; #endif
;                 bbprintf(&message_bbb, "%-20s "
		mov es, word [bp-2]
		push word [es:si+7]
		push word [es:si+5]
		mov ax, _global_label
		push ax
		mov ax, @$930
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 0xa

; #if CONFIG_VALUE_BITS == 32
;                                        "%08"
; #else
;                                        "%04"
; #endif
;                                        FMT_VALUE "X\r\n",
; #if USING_FAR
;                                        global_label,
; #else
;                                        node->name,
; #endif
;                                        GET_UVALUE(node->value));
;             }
;             node = RBL_GET_RIGHT(node);
@$86:
		mov ax, si
		mov dx, word [bp-2]
		call near RBL_GET_RIGHT_
		jmp @$82

;         }
;     }
; }
@$87:
		mov sp, bp
		pop bp
@$88:
		pop di
@$89:
		pop si
@$90:
		pop dx
		pop cx
		pop bx
		ret

; 
; /*
;  ** Avoid spaces in input
;  */
; static const char *avoid_spaces(const char *p) {
avoid_spaces_:
		push bx
		mov bx, ax

;     for (; *p == ' '; p++) {}
@$91:
		cmp byte [bx], 0x20
		jne @$92
		inc bx
		jmp @$91

;     return p;
; }
@$92:
		mov ax, bx
		pop bx
		ret

; 
; #ifndef CONFIG_MATCH_STACK_DEPTH
; #define CONFIG_MATCH_STACK_DEPTH 100
; #endif
; 
; /*
;  ** Check for a non-first label character, same as in NASM.
;  */
; static int islabel(int c) {
islabel_:
		push dx
		mov dx, ax

;     return isalpha(c) || isdigit(c) || c == '_' || c == '.' || c == '@' || c == '?' || c == '$' || c == '~' || c == '#';
		call near isalpha_
		test ax, ax
		jne @$93
		mov ax, dx
		call near isdigit_
		test ax, ax
		jne @$93
		cmp dx, 0x5f
		je @$93
		cmp dx, 0x2e
		je @$93
		cmp dx, 0x40
		je @$93
		cmp dx, 0x3f
		je @$93
		cmp dx, 0x24
		je @$93
		cmp dx, 0x7e
		je @$93
		cmp dx, 0x23
		jne @$94
@$93:
		mov ax, 1

; }
@$94:
		pop dx
		ret

; 
; #if 0  /* Unused. */
; /*
;  ** Check for a first label character (excluding the leading '$' syntax), same as in NASM.
;  */
; static int islabel1(int c) {
;     return isalpha(c) || c == '_' || c == '.' || c == '@' || c == '?';
; }
; #endif
; 
; #ifndef __WATCOMC__  /* This c + (0U - 'A') is needed my Microsoft C 6.00 (_MSC_VER == 600), otherwise (e.g. with `c - 'A' + 0U') it generates incorrect code. */
; #define SUB_U(a, b) ((a) + (0U - (b)))  /* This would also work with __DOSMC__, but it would make the code 6 bytes longer. */
; #else
; #define SUB_U(a, b) ((a) - (b) + 0U)
; #endif
; 
; /* Returns bool (0 == false or 1 == true) indicating whether the
;  * NUL-terminated string p matches the NUL-terminated pattern.
;  *
;  * The match is performed from left to right, one byte at a time.
;  *
;  * A '!' in the pattern matches the end-of-string or a non-islabel(...)
;  * character and anything afterwards.
;  *
;  * A '*' in the pattern matches anything afterwards. An uppercase
;  * letter in the pattern matches itself and the lowercase equivalent.
;  *
;  * A '\0' in the pattern matches the '\0', and the matching stops
;  * with true. Every other byte in the pattern matches itself, and the
;  * matching continues.
;  *
;  * A '#" in the pattern matches a single letter 'B', 'W' or 'D', or
;  * the lowercase equivalent.
;  */
; static char casematch(const char *p, const char *pattern) {
casematch_:
		push bx
		push cx
		push si
		mov bx, ax
		mov si, dx

;     char c;
;     for (; (c = *pattern++) != '*'; ++p) {
@$95:
		mov al, byte [si]
		inc si
		cmp al, 0x2a
		je @$102

;         if (SUB_U(c, 'A') <= 'Z' - 'A' + 0U) {
		mov dl, al
		xor dh, dh
		mov cx, dx
		sub cx, 0x41
		cmp cx, 0x19
		ja @$98

;             if ((*p & ~32) != c) return 0;  /* Letters are matched case insensitively. */
		mov al, byte [bx]
		and ax, 0xdf
		cmp ax, dx
@$96:
		je @$101
@$97:
		xor al, al
		jmp near @$340

;         } else if (c == '!') {
@$98:
		cmp al, 0x21
		jne @$99

;             if (islabel(*p)) return 0;  /* Doesn't return 0 for end-of-string. */
		mov al, byte [bx]
		xor ah, ah
		call near islabel_
		test ax, ax
		je @$102
		jmp @$97

;             break;
;         } else if (c == '#') {
@$99:
		cmp al, 0x23
		jne @$100

;             c = *p & ~32;
		mov al, byte [bx]
		and al, 0xdf

;             if (c != 'B' && c != 'W'
		cmp al, 0x42
		je @$101
		cmp al, 0x57
		je @$101
		cmp al, 0x44
		jmp @$96

; #if CONFIG_VALUE_BITS == 32
;                 && c != 'D'
; #endif
;                ) return 0;
;         } else {
;             if (*p != c) return 0;
@$100:
		cmp al, byte [bx]
		jne @$97

;             if (c == '\0') break;
		test al, al
		je @$102

;         }
;     }
@$101:
		inc bx
		jmp @$95

;     return 1;
@$102:
		mov al, 1

; }
		jmp near @$340

; 
; /*
;  ** Returns true for prefix EQU, DB, DW and DD.
;  */
; static int is_colonless_instruction(const char *p) {
is_colonless_instruction_:
		push bx
		push dx
		mov bx, ax

;     char c = p[0] & ~32;
		mov al, byte [bx]
		and al, 0xdf

;     if (c == 'E') {
		cmp al, 0x45
		jne @$104

;         return casematch(p, "EQU!");
		mov dx, @$931
@$103:
		mov ax, bx
		call near casematch_
		xor ah, ah
		pop dx
		pop bx
		ret

;     } else if (c == 'D') {  /* DB, DW or DD. */
@$104:
		cmp al, 0x44
		jne @$105

;         return casematch(p, "D#!");
		mov dx, @$932
		jmp @$103

;     } else if (c == 'R') {
@$105:
		cmp al, 0x52
		jne @$106

;         return casematch(p, "RES#!");  /* RESB, RESW or RESD. */
		mov dx, @$933
		jmp @$103

;     } else if (c == 'T') {
@$106:
		cmp al, 0x54
		jne @$107

;         return casematch(p, "TIMES!");
		mov dx, @$934
		jmp @$103

;     } else {
;         return 0;
@$107:
		xor ax, ax

;     }
; }
		pop dx
		pop bx
		ret

; 
; /*
;  ** Returns NULL if not a label, otherwise after the label.
;  */
; static const char *match_label_prefix(const char *p) {
match_label_prefix_:
		push bx
		push dx
		push si
		mov bx, ax

;     const char *p2;
;     union { char a[2]; short s; } cd;  /* Avoid GCC warning: dereferencing type-punned pointer will break strict-aliasing rules [-Wstrict-aliasing] */
;     cd.a[0] = *p;
		mov dl, byte [bx]

;     if (cd.a[0] == '$') {
		cmp dl, 0x24
		jne @$108

;         cd.a[0] = *++p;
		inc bx
		mov dl, byte [bx]

;         if (isalpha(cd.a[0])) goto goodc;
		mov al, dl
		xor ah, ah
		call near isalpha_
		test ax, ax
		jne @$110
		jmp near @$116

;     } else if (isalpha(cd.a[0])) {
@$108:
		mov al, dl
		xor ah, ah
		call near isalpha_
		test ax, ax
		je @$111

;         if (isalpha(cd.a[1] = p[1])) {
		mov dh, byte [bx+1]
		mov al, dh
		xor ah, ah
		call near isalpha_
		test ax, ax
		je @$110

;             if (!islabel(p[2])) {  /* 2-character label. */
		mov al, byte [bx+2]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$113

;                 if (CONFIG_CPU_UNALIGN && sizeof(short) == 2) {
;                     cd.s &= ~0x2020;
;                 } else {
;                     cd.a[0] &= ~32;
;                     cd.a[1] &= ~32;
;                 }
		and dx, 0xdfdf

;                 for (p2 = (char*)register_names; p2 != register_names + STRING_SIZE_WITHOUT_NUL(register_names); p2 += 2) {
		mov si, _register_names
@$109:
		cmp si, _register_names+0x28
		je @$113

;                     if ((CONFIG_CPU_UNALIGN && sizeof(short) == 2) ? (cd.s == *(short*)p2) : (cd.a[0] == p2[0] && cd.a[1] == p2[1])) return NULL;  /* A register name without a `$' prefix is not a valid label name. */
		cmp dx, word [si]
		je @$112

;                 }
		inc si
		inc si
		jmp @$109
@$110:
		jmp near @$117
@$111:
		jmp @$116
@$112:
		jmp @$115

;             }
;             if (is_colonless_instruction(p)) return NULL;
@$113:
		mov ax, bx
		call near is_colonless_instruction_
		test ax, ax
		jne @$115

;             /* TODO(pts): Is it faster or smaller to add these to a binary tree? */
;             if (casematch(p, "SHORT!") || casematch(p, "NEAR!") || casematch(p, "FAR!") || casematch(p, "BYTE!") || casematch(p, "WORD!") || casematch(p, "DWORD!") || casematch(p, "STRICT!")) return NULL;
		mov dx, @$935
		mov ax, bx
		call near casematch_
		test al, al
		jne @$115
		mov dx, @$936
		mov ax, bx
		call near casematch_
		test al, al
		jne @$115
		mov dx, @$937
		mov ax, bx
		call near casematch_
		test al, al
		jne @$115
		mov dx, @$938
		mov ax, bx
		call near casematch_
		test al, al
		jne @$115
		mov dx, @$939
		mov ax, bx
		call near casematch_
		test al, al
		jne @$115
		mov dx, @$940
		mov ax, bx
		call near casematch_
		test al, al
		jne @$115
		mov dx, @$941
		mov ax, bx
		call near casematch_
		test al, al
@$114:
		je @$117
@$115:
		xor ax, ax
		jmp @$119

;         }
;         goto goodc;
;     }
;     if (cd.a[0] != '_' && cd.a[0] != '.' && cd.a[0] != '@' && cd.a[0] != '?') return NULL;
@$116:
		cmp dl, 0x5f
		je @$117
		cmp dl, 0x2e
		je @$117
		cmp dl, 0x40
		je @$117
		cmp dl, 0x3f
		jmp @$114

;   goodc:
;     while (islabel(*++p)) {}
@$117:
		inc bx
		mov al, byte [bx]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$117

;     return p;
@$118:
		mov ax, bx

; }
@$119:
		pop si
		pop dx
		pop bx
		ret
@$120:
		dw @$143
		dw @$146
		dw @$134
		dw @$134
		dw @$134
		dw @$134
		dw @$134
		dw @$134
		dw @$199
		dw @$209
		dw @$211
		dw @$217
		dw @$219
		dw @$229
		dw @$231
		dw @$237
		dw @$240
		dw @$251
		dw @$254
		dw @$258

; 
; #if CONFIG_CPU_IDIV_TO_ZERO
; #define VALUE_DIV(a, b) ((value_t)(a) / (value_t)(b))
; #define VALUE_MOD(a, b) ((value_t)(a) % (value_t)(b))
; #else
; #define VALUE_DIV(a, b) value_div((a), (b))
; #define VALUE_MOD(a, b) value_mod((a), (b))
; /*
;  ** Deterministic signed division, rounds towards zero.
;  ** The result is undefined if b == 0. It's defined for a == int_min and b == -1.
;  */
; static value_t value_div(value_t a, value_t b) {
;     const char an = (a < 0);
;     const char bn = (b < 0);
;     const uvalue_t d = (uvalue_t)(an ? -a : a) / (uvalue_t)(bn ? -b : b);
;     return an == bn ? d : -d;
; }
; static value_t value_mod(value_t a, value_t b) {
;     return a - value_div(a, b) * b;
; }
; #endif
; 
; static const char *match_register(const char *p, int width, unsigned char *reg);
; 
; /*
;  ** Match expression at match_p, update (increase) match_p or set it to NULL on error.
;  ** level == 0 is top tier, that's how callers should call it.
;  ** Saves the result to `instruction_value', or 0 if there was an undefined label.
;  ** Sets `has_undefined' indicating whether ther was an undefined label.
;  */
; static const char *match_expression(const char *match_p) {
match_expression_:
		push bx
		push cx
		push dx
		push si
		push di
		push bp
		mov bp, sp
		sub sp, 0x14
		mov si, ax

;     static ALIGN_MAYBE_4 struct match_stack_item {
;         signed char casei;
;         unsigned char level;
;         value_t value1;
;     } match_stack[CONFIG_MATCH_STACK_DEPTH];  /* This static variable makes match_expression(...) not reentrant. */
;     struct match_stack_item *msp;  /* Stack pointer within match_stack. */
;     value_t value1;
;     value_t value2;
;     /*union {*/  /* Using union to save stack memory would make __DOSMC__ program larger. */
;         unsigned shift;
;         char *p2;
;         struct label MY_FAR *label;
;     /*} u;*/
;     char c;
;     unsigned char level;
; 
;     level = 0;
		xor al, al
		mov byte [bp-2], al

;     has_undefined = 0;
		mov byte [_has_undefined], al

;     msp = match_stack;
		mov di, @$match_stack

;     goto do_match;
@$121:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax
		xor ax, ax
		mov word [bp-0x14], ax
		mov word [bp-0x12], ax
		mov bx, dx
		mov al, byte [bx]
		mov byte [bp-4], al
		cmp al, 0x28
		jne @$124
@$122:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax
		mov al, byte [bx]
		mov byte [bp-4], al
		cmp al, 0x28
		jne @$128
		mov ax, word [bp-0x12]
		cmp ax, -0x1
		jg @$123
		jne @$128
		cmp word [bp-0x14], 0xff81
		jbe @$128
@$123:
		lea si, [bx+1]
		add word [bp-0x14], 0xffff
		adc word [bp-0x12], 0xffff
		jmp @$122
@$124:
		jmp near @$136

;   do_pop:
;     --msp;
;     value2 = value1;
@$125:
		mov cx, word [bp-0x14]
		mov ax, word [bp-0x12]
		mov word [bp-0xc], ax

		sub di, 6

;     value1 = msp->value1;
		mov ax, word [di+2]
		mov word [bp-0x14], ax
		mov ax, word [di+4]
		mov word [bp-0x12], ax

;     level = msp->level;
		mov al, byte [di+1]
		mov byte [bp-2], al

;     if (msp->casei < 0) {  /* End of expression in patentheses. */
		mov al, byte [di]
		test al, al
		jge @$131

;         value1 = value2;
		mov word [bp-0x14], cx
		mov ax, word [bp-0xc]
		mov word [bp-0x12], ax

;         match_p = avoid_spaces(match_p);
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;         if (match_p[0] != ')') {
		cmp byte [si], 0x29
		je @$129

;             MESSAGE(1, "Missing close paren");
		mov ax, @$942
@$126:
		call near message_

;           match_error:
;             instruction_value = 0;
@$127:
		xor ax, ax
		mov word [_instruction_value], ax
		mov word [_instruction_value+2], ax

;             return NULL;
		jmp near @$87
@$128:
		jmp @$132

;         }
;         match_p++;
@$129:
		inc si

;         if (++msp->casei != 0) {
		inc byte [di]
		je @$130

;             level = 0;
		mov byte [bp-2], 0

;             if (++msp == match_stack + sizeof(match_stack) / sizeof(match_stack[0])) goto too_deep;
		add di, 6
		cmp di, @$segment_value
		je @$133
@$130:
		jmp near @$198

;         }
;         goto have_value1;
;     }
; #define MATCH_CASEI_LEVEL_TO_VALUE2(casei2, level2) do { msp->casei = casei2; msp->level = level; level = level2; goto do_push; case casei2: ; } while (0)
;     switch (msp->casei) {  /* This will jump after one of the MATCH_CASEI_LEVEL_TO_VALUE2(...) macros. */
@$131:
		mov bl, al
		sub bl, 2
		cmp bl, 0x13
		ja @$134
		xor bh, bh
		shl bx, 1
		mov ax, word [bp-0x14]
		add ax, cx
		mov dx, word [bp-0x12]
		adc dx, word [bp-0xc]
		mov word [bp-8], dx
		mov dx, word [bp-0x14]
		sub dx, cx
		mov word [bp-6], dx
		mov dx, word [bp-0x12]
		sbb dx, word [bp-0xc]
		jmp word [cs:bx+@$120]

;       do_push:
;         msp->value1 = value1;
;         if (++msp == match_stack + sizeof(match_stack) / sizeof(match_stack[0])) { too_deep:
;             MESSAGE(1, "Expression too deep");  /* Stack overflow in match stack. */
;             goto match_error;
;         }
;       do_match:
;         match_p = avoid_spaces(match_p);
;         value1 = 0;  /* In addition to preventing duplicate initialization below, it also does pacify GCC 7.5.0: do_push jumped to by MATCH_CASEI_LEVEL_TO_VALUE2 does an `msp->value1 = value1'. */
;         if ((c = match_p[0]) == '(') {  /* Parenthesized expression. */
;             /* Count the consecutive open parentheses, and add a single match_stack_item. */
;             for (; (c = (match_p = avoid_spaces(match_p))[0]) == '(' && value1 > -127; ++match_p, --value1) {}
;             msp->casei = value1; msp->level = level; level = 0; goto do_push;
@$132:
		mov al, byte [bp-0x14]
		mov byte [di], al
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 0
		jmp near @$204
@$133:
		jmp near @$205
@$134:
		cmp di, @$match_stack
		je @$135
		jmp near @$125
@$135:
		cmp byte [_has_undefined], 0
		je @$140
		xor dx, dx
		xor ax, ax
		jmp near @$260

;         } else if (c == '-' || c == '+' || c == '~') {  /* Unary -, + and ~. */
@$136:
		cmp al, 0x2d
		je @$137
		cmp al, 0x2b
		je @$137
		cmp al, 0x7e
		jne @$144

;             /*value1 = 0;*/  /* Delta, can be nonzero iff unary ~ is encountered. */
;             if (c == '~') { --value1; c = '-'; }
@$137:
		cmp byte [bp-4], 0x7e
		jne @$138
		mov byte [bp-4], 0x2d
		add word [bp-0x14], 0xffff
		adc word [bp-0x12], 0xffff

;             for (;;) {  /* Shortcut to squeeze multiple unary - and + operators to a single match_stack_item. */
;                 match_p = avoid_spaces(match_p + 1);
@$138:
		lea ax, [si+1]
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if (match_p[0] == '+') {}
		mov al, byte [bx]
		cmp al, 0x2b
		je @$138

;                 else if (match_p[0] == '-') { do_switch_pm: c ^= 6; }  /* Switch between ASCII '+' and '-'. */
		cmp al, 0x2d
		je @$139
		cmp al, 0x7e
		jne @$141
		mov al, byte [bp-4]
		xor ah, ah
		xor dx, dx
		add ax, -0x2c
		adc dx, 0xffff
		add word [bp-0x14], ax
		adc word [bp-0x12], dx

;                 else if (match_p[0] == '~') { value1 += (value_t)c - ('-' - 1); goto do_switch_pm; }  /* Either ++value1 or --value1. */
@$139:
		xor byte [bp-4], 6
		jmp @$138
@$140:
		jmp near @$259

;                 else { break; }
;             }
;             if (c == '-') {
@$141:
		cmp byte [bp-4], 0x2d
		jne @$145

;               MATCH_CASEI_LEVEL_TO_VALUE2(2, 6);
		mov byte [di], 2
@$142:
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 6
		jmp near @$204

;               value1 -= value2;
@$143:
		mov ax, word [bp-6]
		mov word [bp-0x14], ax
		mov word [bp-0x12], dx

;             } else {
		jmp near @$198
@$144:
		jmp @$148

;               MATCH_CASEI_LEVEL_TO_VALUE2(3, 6);
@$145:
		mov byte [di], 3
		jmp @$142

;               value1 += value2;
@$146:
		mov word [bp-0x14], ax
		mov ax, word [bp-8]
@$147:
		mov word [bp-0x12], ax

;             }
		jmp near @$198

;         } else if (c == '0' && (match_p[1] | 32) == 'b') {  /* Binary or hexadecimal. */
@$148:
		cmp al, 0x30
		jne @$154
		mov al, byte [bx+1]
		or al, 0x20
		cmp al, 0x62
		jne @$154

;             p2 = (char*)match_p;
		mov word [bp-0xe], dx

;             match_p += 2;
		inc si
		inc si

;             /*value1 = 0;*/
;             while ((c = match_p[0]) == '0' || c == '1' || c == '_') {
@$149:
		mov al, byte [si]
		mov byte [bp-4], al
		cmp al, 0x30
		je @$150
		cmp al, 0x31
		je @$150
		cmp al, 0x5f
		jne @$152

;                 if (c != '_') {
@$150:
		mov al, byte [bp-4]
		cmp al, 0x5f
		je @$151

;                     value1 <<= 1;
		shl word [bp-0x14], 1
		rcl word [bp-0x12], 1

;                     if (c == '1')
		cmp al, 0x31
		jne @$151

;                         value1 |= 1;
		or byte [bp-0x14], 1

;                 }
;                 match_p++;
@$151:
		inc si

;             }
		jmp @$149

;           parse_hex1:  /* Maybe hexadecimal. */
;             if ((c | 32) == 'h' || isxdigit(c)) {  /* Hexadecimal, start again. */
@$152:
		mov al, byte [bp-4]
		or al, 0x20
		cmp al, 0x68
		je @$153
		mov al, byte [bp-4]
		xor ah, ah
		call near isxdigit_
		test ax, ax
		je @$159

;               parse_hex2:
;                 match_p = p2;
@$153:
		mov si, word [bp-0xe]

;                 value1 = 0;
		xor ax, ax
		mov word [bp-0x14], ax
		mov word [bp-0x12], ax

;                 shift = 1;
		mov word [bp-0xa], 1

;                 goto parse_hex;
		jmp @$156

;             }
;             goto check_nolabel;
;         } else if (c == '0' && (match_p[1] | 32) == 'x') {  /* Hexadecimal. */
@$154:
		cmp byte [bp-4], 0x30
		jne @$161
		mov al, byte [si+1]
		or al, 0x20
		cmp al, 0x78
		jne @$161

;             match_p += 2;
		inc si
		inc si

;           parse_hex0:
;             shift = 0;
@$155:
		mov word [bp-0xa], 0

;           parse_hex:
;             /*value1 = 0;*/
;             for (; c = match_p[0], isxdigit(c); ++match_p) {
@$156:
		mov al, byte [si]
		mov byte [bp-4], al
		xor ah, ah
		call near isxdigit_
		test ax, ax
		je @$160

;                 c -= '0';
		sub byte [bp-4], 0x30

;                 if ((unsigned char)c > 9) c = (c & ~32) - 7;
		mov al, byte [bp-4]
		cmp al, 9
		jbe @$157
		and al, 0xdf
		sub al, 7
		mov byte [bp-4], al

;                 value1 = (value1 << 4) | c;
@$157:
		mov ax, word [bp-0x14]
		mov dx, word [bp-0x12]
		mov cx, 4
@$158:
		shl ax, 1
		rcl dx, 1
		loop @$158
		mov bl, byte [bp-4]
		xor bh, bh
		or ax, bx
		mov word [bp-0x14], ax
		mov word [bp-0x12], dx

;             }
		inc si
		jmp @$156
@$159:
		jmp @$165

;             if (shift) {  /* Expect c == 'H' || c == 'h'. */
@$160:
		cmp word [bp-0xa], 0
		je @$165

;                 if ((c | 32) != 'h') goto bad_label;
		mov al, byte [bp-4]
		or al, 0x20
		cmp al, 0x68
		jne @$166

;                 ++match_p;
		inc si

;             }
		jmp @$165

;             goto check_nolabel;
;         } else if (c == '0' && (match_p[1] | 32) == 'o') {  /* Octal. NASM 0.98.39 doesn't support it, but NASM 0.99.06 does. */
@$161:
		cmp byte [bp-4], 0x30
		jne @$167
		mov al, byte [si+1]
		or al, 0x20
		cmp al, 0x6f
		jne @$167

;             match_p += 2;
;             shift = 0;
		mov word [bp-0xa], 0

		inc si
		inc si

;           parse_octal:
;             /*value1 = 0;*/
;             for (; (unsigned char)(c = SUB_U(match_p[0], '0')) < 8U; ++match_p) {
@$162:
		mov al, byte [si]
		sub al, 0x30
		mov byte [bp-4], al
		lea dx, [si+1]
		cmp al, 8
		jae @$164

;                 value1 = (value1 << 3) | c;
		mov bx, word [bp-0x14]
		mov si, word [bp-0x12]
		mov cx, 3
@$163:
		shl bx, 1
		rcl si, 1
		loop @$163
		xor ah, ah
		or bx, ax
		mov word [bp-0x14], bx
		mov word [bp-0x12], si

;             }
		mov si, dx
		jmp @$162

;             if (shift) {  /* Expect c == 'O' || c == 'o'. */
@$164:
		cmp word [bp-0xa], 0
		je @$165

;                 if (c != (char)('o' - '0')) goto bad_label;
		cmp al, 0x3f
		jne @$166

;                 ++match_p;
		mov si, dx

;             }
;           check_nolabel:
;             c = match_p[0];
@$165:
		mov al, byte [si]
		mov byte [bp-4], al

;             if (islabel(c)) goto bad_label;
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$166
		jmp near @$198
@$166:
		jmp near @$183

;         } else if (c == '\'' || c == '"') {  /* Character constant. */
@$167:
		mov al, byte [bp-4]
		cmp al, 0x27
		je @$168
		cmp al, 0x22
		jne @$172

;             /*value1 = 0;*/ shift = 0;
@$168:
		mov word [bp-0xa], 0

;             for (++match_p; match_p[0] != '\0' && match_p[0] != c; ++match_p) {
@$169:
		inc si
		mov al, byte [si]
		test al, al
		je @$170
		cmp al, byte [bp-4]
		je @$170

;                 if (shift < sizeof(value_t) * 8) {
		cmp word [bp-0xa], 0x20
		jae @$169

;                     value1 |= (unsigned char)match_p[0] << shift;
		xor ah, ah
		mov cl, byte [bp-0xa]
		shl ax, cl
		cwd
		or word [bp-0x14], ax
		or word [bp-0x12], dx

;                     shift += 8;
		add word [bp-0xa], 8

;                 }
;             }
		jmp @$169

;             if (match_p[0] == '\0') {
@$170:
		cmp byte [si], 0
		jne @$171

;                 MESSAGE(1, "Missing close quote");
		mov ax, @$944

;                 goto match_error;
		jmp near @$126

;             } else {
;                 ++match_p;
@$171:
		inc si

;             }
;         } else if (isdigit(c)) {  /* Decimal, binary, octal or hexadecimal, even if it starts with '0'. */
		jmp near @$198
@$172:
		xor ah, ah
		call near isdigit_
		test ax, ax
		je @$175

;             /*value1 = 0;*/
;             for (p2 = (char*)match_p; (unsigned char)(c = SUB_U(match_p[0], '0')) <= 9U; ++match_p) {
		mov word [bp-0xe], si
@$173:
		mov al, byte [si]
		sub al, 0x30
		mov byte [bp-4], al
		cmp al, 9
		ja @$174

;                 value1 = value1 * 10 + c;
		mov ax, word [bp-0x14]
		mov dx, word [bp-0x12]
		mov bx, 0xa
		xor cx, cx
		call near __I4M
		mov bx, ax
		mov al, byte [bp-4]
		xor ah, ah
		mov word [bp-0x10], 0
		add bx, ax
		mov word [bp-0x14], bx
		mov ax, word [bp-0x10]
		adc ax, dx
		mov word [bp-0x12], ax

;             }
		inc si
		jmp @$173

;             c = match_p[0] | 32;
@$174:
		mov al, byte [si]
		or al, 0x20
		mov byte [bp-4], al

;             if (c == 'o') {
		cmp al, 0x6f
		jne @$176

;                 match_p = p2;
		mov si, word [bp-0xe]

;                 value1 = 0;
		xor ax, ax
		mov word [bp-0x14], ax
		mov word [bp-0x12], ax

;                 shift = 1;
		mov word [bp-0xa], 1

;                 goto parse_octal;
		jmp near @$162
@$175:
		jmp @$182

;             } else if (c == 'b') {  /* Binary or hexadecimal. */
@$176:
		cmp al, 0x62
		je @$177
		jmp near @$152

;                 value1 = 0;
@$177:
		xor ax, ax
		mov word [bp-0x14], ax
		mov word [bp-0x12], ax

;                 for (match_p = p2; (unsigned char)(c = SUB_U(match_p[0], '0')) <= 2U; ++match_p) {
		mov si, word [bp-0xe]
@$178:
		mov al, byte [si]
		sub al, 0x30
		mov byte [bp-4], al
		lea bx, [si+1]
		cmp al, 2
		ja @$179

;                     value1 <<= 1;
		shl word [bp-0x14], 1
		rcl word [bp-0x12], 1

;                     value1 |= c;
		xor ah, ah
		or word [bp-0x14], ax

;                 }
		mov si, bx
		jmp @$178

;                 c = *++match_p;  /* Skip over the 'b' or 'B'. */
@$179:
		mov si, bx
		mov al, byte [bx]
		mov byte [bp-4], al

;                 if ((c | 32) == 'h' || isxdigit(c)) {  /* Hexadecimal, start again. */
		or al, 0x20
		cmp al, 0x68
		jne @$181
@$180:
		jmp near @$153
@$181:
		mov al, byte [bp-4]
		xor ah, ah
		call near isxdigit_
		test ax, ax
		jne @$180
		jmp near @$198

;                     goto parse_hex2;
;                 }
;             } else {
;                 goto parse_hex1;
;             }
;         } else if (c == '$') {
@$182:
		cmp byte [bp-4], 0x24
		jne @$187

;             c = *++match_p;
		inc si
		mov al, byte [si]
		mov byte [bp-4], al

;             if (c == '$') {  /* Start address ($$). */
		cmp al, 0x24
		jne @$185

;                 ++match_p;
;                 is_address_used = 1;
		mov byte [_is_address_used], 1

;                 value1 = start_address;
		mov ax, word [_start_address]
		mov word [bp-0x14], ax
		mov ax, word [_start_address+2]
		mov word [bp-0x12], ax

		inc si

;                 if (islabel(match_p[0])) { bad_label:
		mov al, byte [si]
		xor ah, ah
		call near islabel_
		test ax, ax
		je @$184

;                     MESSAGE(1, "bad label");
@$183:
		mov ax, @$945
		call near message_

;                 }
@$184:
		jmp near @$198

;             } else if (isdigit(c)) {
@$185:
		mov dl, al
		xor dh, dh
		mov ax, dx
		call near isdigit_
		test ax, ax
		je @$186
		jmp near @$155

;                 /* This is nasm syntax, notice no letter is allowed after $ */
;                 /* So it's preferrable to use prefix 0x for hexadecimal */
;                 shift = 0;
;                 goto parse_hex0;
;             } else if (islabel(c)) {
@$186:
		mov ax, dx
		call near islabel_
		test ax, ax
		jne @$188

;                 goto label_expr;
;             } else {  /* Current address ($). */
;                 is_address_used = 1;
		mov byte [_is_address_used], 1

;                 value1 = current_address;
		mov ax, word [_current_address]
		mov word [bp-0x14], ax
		mov ax, word [_current_address+2]
		jmp near @$147

;             }
;         } else if (match_label_prefix(match_p)) {  /* This also matches c == '$', but we've done that above. */
@$187:
		mov ax, si
		call near match_label_prefix_
		test ax, ax
		jne @$188
		jmp near @$127

;           label_expr:
;             p2 = (char*)match_p;
@$188:
		mov word [bp-0xe], si

;             for (; islabel(match_p[0]); ++match_p) {}
@$189:
		mov al, byte [si]
		xor ah, ah
		call near islabel_
		test ax, ax
		je @$190
		inc si
		jmp @$189

;             c = match_p[0];
@$190:
		mov al, byte [si]
		mov byte [bp-4], al

;             ((char*)match_p)[0] = '\0';
		mov byte [si], 0

;             /* If label starts with `.', but not with `..@', then prepend global_label. */
;             label = find_cat_label(p2[0] == '.' && !(p2[1] == '.' && p2[2] == '@') ? global_label : "", p2);
		mov cx, ds
		mov dx, word [bp-0xe]
		mov bx, dx
		cmp byte [bx], 0x2e
		jne @$192
		cmp byte [bx+1], 0x2e
		jne @$191
		cmp byte [bx+2], 0x40
		je @$192
@$191:
		mov ax, _global_label
		jmp @$193
@$192:
		mov ax, @$929
@$193:
		mov bx, dx
		call near find_cat_label_
		mov bx, ax

;             if (0) DEBUG1("use_label=(%s)\r\n", p2);
		test dx, dx
		jne @$194
		test ax, ax
		je @$195
@$194:
		mov es, dx
		test byte [es:bx+4], 0x10
		je @$196

;             if (label == NULL || RBL_IS_DELETED(label)) {
;                 /*value1 = 0;*/
;                 has_undefined = 1;
@$195:
		mov byte [_has_undefined], 1

;                 if (assembler_pass > 1) {
		cmp word [_assembler_pass], 1
		jbe @$197

;                     MESSAGE1STR(1, "Undefined label '%s'", p2);  /* Doesn't contain the global label prefix. */
		mov dx, word [bp-0xe]
		mov ax, @$946
		call near message1str_

;                 }
		jmp @$197

;             } else {
;                 value1 = label->value;
@$196:
		mov ax, word [es:bx+5]
		mov word [bp-0x14], ax
		mov ax, word [es:bx+7]
		mov word [bp-0x12], ax

;             }
;             ((char*)match_p)[0] = c;  /* Undo. */
@$197:
		mov al, byte [bp-4]
		mov byte [si], al

;         } else {
;             /* TODO(pts): Make this match syntax error nonsilent? What about when trying instructions? */
;             goto match_error;
;         }
;         /* Now value1 contains the value of the expression parsed so far. */
;       have_value1:
;         if (level <= 5) {
@$198:
		cmp byte [bp-2], 5
		ja @$208
		jmp @$201

;             while (1) {
;                 match_p = avoid_spaces(match_p);
;                 if ((c = match_p[0]) == '*') {  /* Multiply operator. */
;                     match_p++;
@$199:
		mov ax, word [bp-0x14]
		mov dx, word [bp-0x12]
		mov bx, cx
		mov cx, word [bp-0xc]
		call near __I4M
@$200:
		mov word [bp-0x14], ax
		mov word [bp-0x12], dx

;                     MATCH_CASEI_LEVEL_TO_VALUE2(10, 6);
;                     value1 *= value2;
;                 } else if (c == '/' && match_p[1] == '/') {  /* Signed division operator. */
@$201:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax
		mov al, byte [si]
		mov byte [bp-4], al
		cmp al, 0x2a
		jne @$206
		mov byte [di], 0xa
@$202:
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 6
@$203:
		inc si
@$204:
		mov ax, word [bp-0x14]
		mov word [di+2], ax
		mov ax, word [bp-0x12]
		mov word [di+4], ax
		add di, 6
		cmp di, @$segment_value
		je @$205
		jmp near @$121
@$205:
		mov ax, @$943
		jmp near @$126
@$206:
		cmp al, 0x2f
		jne @$210
		mov bx, dx
		cmp al, byte [bx+1]
		jne @$210

;                     match_p += 2;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(11, 6);
		mov byte [di], 0xb
@$207:
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 6

		inc si
		inc si
		jmp @$204
@$208:
		jmp near @$225

;                     c = 0;
@$209:
		mov byte [bp-4], 0

;                     goto do_divide;
		jmp @$212

;                 } else if (c == '/') {  /* Unsigned division operator. */
@$210:
		mov al, byte [bp-4]
		cmp al, 0x2f
		jne @$216

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(12, 6);
		mov byte [di], 0xc
		jmp @$202

@$211:
		mov byte [bp-4], 1

;                     c = 1;
;                   do_divide:
;                     if (GET_UVALUE(value2) == 0) {
@$212:
		mov ax, word [bp-0xc]
		or ax, cx
		jne @$214

;                         if (assembler_pass > 1)  /* This also implies !has_undefined, if there is no bug. */
		cmp word [_assembler_pass], 1
		jbe @$213

;                             MESSAGE(1, "division by zero");
		mov ax, @$947
		call near message_

;                         value2 = 1;
@$213:
		mov cx, 1
		mov word [bp-0xc], 0

;                     }
;                     value1 = c ? (value_t)(GET_UVALUE(value1) / GET_UVALUE(value2)) : VALUE_DIV(GET_VALUE(value1), GET_VALUE(value2));
@$214:
		cmp byte [bp-4], 0
		je @$215
		mov ax, word [bp-0x14]
		mov dx, word [bp-0x12]
		mov bx, cx
		mov cx, word [bp-0xc]
		call near __U4D
		jmp near @$200
@$215:
		mov ax, word [bp-0x14]
		mov dx, word [bp-0x12]
		mov bx, cx
		mov cx, word [bp-0xc]
		call near __I4D
		jmp near @$200

;                 } else if (c == '%' && match_p[1] == '%' && !islabel(match_p[2])) {  /* Signed modulo operator. We check for islabel(...) to make it similar to NASM, which uses %%... syntax for multiine macros. */
@$216:
		cmp al, 0x25
		jne @$218
		cmp al, byte [si+1]
		jne @$218
		mov al, byte [si+2]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$218

;                     match_p += 2;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(13, 6);
		mov byte [di], 0xd
		jmp near @$207

@$217:
		mov byte [bp-4], 0

;                     c = 0;
;                     goto do_modulo;
		jmp @$220

;                 } else if (c == '%' && !islabel(match_p[1])) {  /* Unsigned modulo operator. We check for islabel(...) to make it similar to NASM, which uses %%... syntax for multiine macros. */
@$218:
		cmp byte [bp-4], 0x25
		jne @$225
		mov al, byte [si+1]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$225

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(14, 6);
		mov byte [di], 0xe
		jmp near @$202

@$219:
		mov byte [bp-4], 1

;                     c = 1;
;                   do_modulo:
;                     if (GET_UVALUE(value2) == 0) {
@$220:
		mov ax, word [bp-0xc]
		or ax, cx
		jne @$222

;                         if (assembler_pass > 1)  /* This also implies !has_undefined, if there is no bug. */
		cmp word [_assembler_pass], 1
		jbe @$221

;                             MESSAGE(1, "modulo by zero");
		mov ax, @$948
		call near message_

;                         value2 = 1;
@$221:
		mov cx, 1
		mov word [bp-0xc], 0

;                     }
;                     value1 = c ? (value_t)(GET_UVALUE(value1) % GET_UVALUE(value2)) : VALUE_MOD(GET_VALUE(value1), GET_VALUE(value2));
@$222:
		cmp byte [bp-4], 0
		je @$223
		mov ax, word [bp-0x14]
		mov dx, word [bp-0x12]
		mov bx, cx
		mov cx, word [bp-0xc]
		call near __U4D
		jmp @$224
@$223:
		mov ax, word [bp-0x14]
		mov dx, word [bp-0x12]
		mov bx, cx
		mov cx, word [bp-0xc]
		call near __I4D

;                 } else {
;                     break;
;                 }
@$224:
		mov word [bp-0x14], bx
		mov word [bp-0x12], cx
		jmp near @$201

;             }
;         }
;         if (level <= 4) {
@$225:
		cmp byte [bp-2], 4
		ja @$232

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$226:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if (((c = match_p[0]) == '+' || c == '-') && !match_register(match_p + 1, 16, NULL)) {  /* We stop early before matching `+si', so match_addressing(...) can pick up right after the '+' or '-'. */
		mov al, byte [bx]
		mov byte [bp-4], al
		cmp al, 0x2b
		je @$227
		cmp al, 0x2d
		jne @$232
@$227:
		lea cx, [si+1]
		xor bx, bx
		mov dx, 0x10
		mov ax, cx
		call near match_register_
		test ax, ax
		jne @$232

;                     if (c == '+') {  /* Add operator. */
		cmp byte [bp-4], 0x2b
		jne @$230

;                         match_p++;
;                         MATCH_CASEI_LEVEL_TO_VALUE2(15, 5);
		mov byte [di], 0xf
@$228:
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 5

		mov si, cx
		jmp near @$204

;                         value1 += value2;
@$229:
		mov word [bp-0x14], ax
		mov ax, word [bp-8]
		mov word [bp-0x12], ax

;                     } else /*if (c == '-')*/ {  /* Subtract operator. */
		jmp @$226

;                         match_p++;
;                         MATCH_CASEI_LEVEL_TO_VALUE2(16, 5);
@$230:
		mov byte [di], 0x10
		jmp @$228

@$231:
		mov ax, word [bp-6]
		mov word [bp-0x14], ax
		mov word [bp-0x12], dx

;                         value1 -= value2;
;                     }
		jmp @$226

;                 } else {
;                     break;
;                 }
;             }
;         }
;         if (level <= 3) {
@$232:
		cmp byte [bp-2], 3
		ja @$239

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$233:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if (((c = match_p[0]) == '<' && match_p[1] == '<') || (c == '>' && match_p[1] == '>')) { /* Shift to left */
		mov al, byte [bx]
		mov byte [bp-4], al
		cmp al, 0x3c
		jne @$234
		cmp al, byte [bx+1]
		je @$235
@$234:
		cmp byte [bp-4], 0x3e
		jne @$239
		cmp byte [si+1], 0x3e
		jne @$239

;                     match_p += 2;
@$235:
		inc si
		inc si

;                     if (c == '<') {
		cmp byte [bp-4], 0x3c
		jne @$238

;                         MATCH_CASEI_LEVEL_TO_VALUE2(17, 4);
		mov byte [di], 0x11
@$236:
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 4
		jmp near @$204

;                         c = 1;
@$237:
		mov byte [bp-4], 1

;                     } else {
		jmp @$241

;                         MATCH_CASEI_LEVEL_TO_VALUE2(18, 4);
@$238:
		mov byte [di], 0x12
		jmp @$236
@$239:
		jmp @$249

;                         c = 0;
@$240:
		mov byte [bp-4], 0

;                     }
;                     if (GET_UVALUE(value2) > 31) {
@$241:
		cmp word [bp-0xc], 0
		jne @$242
		cmp cx, 0x1f
		jbe @$243

;                         /* 8086 processor (in 16-bit mode) uses all 8 bits of the shift amount.
;                          * i386 and amd64 processors in both 16-bit and 32-bit mode uses the last 5 bits of the shift amount.
;                          * amd64 processor in 64-bit mode uses the last 6 bits of the shift amount.
;                          * To get deterministic output, we disallow shift amounts with more than 5 bits.
;                          * NASM has nondeterministic output, depending on the host architecture (32-bit mode or 64-bit mode).
;                          */
;                         if (assembler_pass > 1)  /* This also implies !has_undefined, if there is no bug. */
@$242:
		cmp word [_assembler_pass], 1
		jbe @$233

;                             MESSAGE(1, "shift by larger than 31");
		mov ax, @$949
		call near message_
		jmp @$233

;                         value2 = 0;
; #if !IS_VALUE_LONG && !CONFIG_INT_SHIFT_OK_31
;                     } else if (sizeof(int) == 2 && sizeof(value_t) == 2 && GET_UVALUE(value2) > 15) {
;                         /* We want `db 1 << 16' to emit 0, but if the host
;                          * architecture uses only the last 4 bits of the shift
;                          * amount, it would emit 1. Thus we forcibly emit 0 here.
;                          */
; #if CONFIG_SHIFT_SIGNED
;                         value1 = c ? 0 : GET_VALUE(value1) >> 15;  /* Sign-extend value1 to CONFIG_VALUE_BITS == sizeof(value_t) * 8 == 16. */
; #else
;                         value1 = 0;
; #endif
; #endif  /* !IS_VALUE_LONG && !CONFIG_INT_SHIFT_OK_31 */
;                     } else {
; #if CONFIG_SHIFT_SIGNED
;                         value1 = c ? GET_VALUE( value1) << GET_UVALUE(value2) : GET_VALUE( value1) >> GET_UVALUE(value2);  /* Sign-extend value1 to CONFIG_VALUE_BITS. */
; #else
;                         value1 = c ? GET_UVALUE(value1) << GET_UVALUE(value2) : GET_UVALUE(value1) >> GET_UVALUE(value2);  /* Zero-extend value1 to CONFIG_VALUE_BITS. */
@$243:
		cmp byte [bp-4], 0
		je @$246
		mov ax, word [bp-0x14]
		mov dx, word [bp-0x12]
		jcxz @$245
@$244:
		shl ax, 1
		rcl dx, 1
		loop @$244
@$245:
		jmp @$248
@$246:
		mov ax, word [bp-0x14]
		mov dx, word [bp-0x12]
		jcxz @$248
@$247:
		shr dx, 1
		rcr ax, 1
		loop @$247
@$248:
		mov word [bp-0x14], ax
		mov word [bp-0x12], dx

; #endif
;                     }
		jmp near @$233

;                 } else {
;                     break;
;                 }
;             }
;         }
;         if (level <= 2) {
@$249:
		cmp byte [bp-2], 2
		ja @$252

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$250:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax

;                 if (match_p[0] == '&') {    /* Binary AND */
		cmp byte [si], 0x26
		jne @$252

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(19, 3);
		mov byte [di], 0x13
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 3
		jmp near @$203

;                     value1 &= value2;
;                 } else {
;                     break;
;                 }
@$251:
		and word [bp-0x14], cx
		mov ax, word [bp-0xc]
		and word [bp-0x12], ax

;             }
		jmp @$250

;         }
;         if (level <= 1) {
@$252:
		cmp byte [bp-2], 1
		ja @$255

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$253:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax

;                 if (match_p[0] == '^') {    /* Binary XOR */
		cmp byte [si], 0x5e
		jne @$255

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(20, 2);
		mov byte [di], 0x14
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 2

		jmp near @$203

;                     value1 ^= value2;
;                 } else {
;                     break;
;                 }
@$254:
		xor word [bp-0x14], cx
		mov ax, word [bp-0xc]
		xor word [bp-0x12], ax

;             }
		jmp @$253

;         }
;         if (level == 0) {  /* Top tier. */
@$255:
		cmp byte [bp-2], 0
		je @$257
@$256:
		jmp near @$134

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$257:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax

;                 if (match_p[0] == '|') {    /* Binary OR */
		cmp byte [si], 0x7c
		jne @$256

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(21, 1);
		mov byte [di], 0x15
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 1

		jmp near @$203

;                     value1 |= value2;
;                 } else {
;                     break;
;                 }
@$258:
		or word [bp-0x14], cx
		mov ax, word [bp-0xc]
		or word [bp-0x12], ax

;             }
		jmp @$257

;         }
;     }
;     if (msp != match_stack) goto do_pop;
;     instruction_value = has_undefined ? 0 : GET_VALUE(value1);
@$259:
		mov dx, word [bp-0x14]
		mov ax, word [bp-0x12]
@$260:
		mov word [_instruction_value], dx
		mov word [_instruction_value+2], ax

;     return avoid_spaces(match_p);
		mov ax, si
		call near avoid_spaces_

; }
		jmp near @$87

; 
; /*
;  ** Returns true iff p is a valid `%DEFINE' value expression string.
;  **
;  ** `%DEFINE' value expressions are integer literals possibly prefixed by
;  ** any number of `-', `+' or `~'. The reason for that is NASM
;  ** compatibility: mininasm can store only integer-valued macro values, and
;  ** NASM stores the strings instead, and these restrictions check for the
;  ** intersection of same behavior.
;  **
;  ** The implementation corresponds to match_expression(...).
;  */
; static char is_define_value(const char *p) {
is_define_value_:
		push bx
		push cx
		push dx
		mov bx, ax

;     char c;
;     for (; (c = p[0]) == '-' || c == '+' || c == '~' || isspace(c); ++p) {}
@$261:
		mov dl, byte [bx]
		cmp dl, 0x2d
		je @$262
		cmp dl, 0x2b
		je @$262
		cmp dl, 0x7e
		je @$262
		mov al, dl
		xor ah, ah
		call near isspace_
		test ax, ax
		je @$263
@$262:
		inc bx
		jmp @$261

;     if (c == '0' && (p[1] | 32) == 'b') {  /* Binary. */
@$263:
		cmp dl, 0x30
		jne @$266
		mov al, byte [bx+1]
		or al, 0x20
		cmp al, 0x62
		jne @$266

;         p += 2;
		inc bx
		inc bx

;         for (; (c = p[0]) == '0' || c == '1' || c == '_'; ++p) {}
@$264:
		mov dl, byte [bx]
		cmp dl, 0x30
		je @$265
		cmp dl, 0x31
		je @$265
		cmp dl, 0x5f
		jne @$271
@$265:
		inc bx
		jmp @$264

;     } else if (c == '0' && (p[1] | 32) == 'x') {  /* Hexadecimal. */
@$266:
		cmp dl, 0x30
		jne @$269
		mov al, byte [bx+1]
		or al, 0x20
		cmp al, 0x78
		jne @$269

;       try_hex2:
;         p += 2;
@$267:
		inc bx
		inc bx

;         for (; c = p[0], isxdigit(c); ++p) {}
@$268:
		mov dl, byte [bx]
		mov al, dl
		xor ah, ah
		call near isxdigit_
		test ax, ax
		je @$271
		inc bx
		jmp @$268

;     } else if (c == '0' && (p[1] | 32) == 'o') {  /* Octal. */
@$269:
		cmp dl, 0x30
		jne @$272
		mov al, byte [bx+1]
		or al, 0x20
		cmp al, 0x6f
		jne @$272

;         p += 2;
		inc bx
		inc bx

;         for (; SUB_U((unsigned char)(c = p[0]), '0') < 8U; ++p) {}
@$270:
		mov dl, byte [bx]
		mov al, dl
		xor ah, ah
		sub ax, 0x30
		cmp ax, 8
		jae @$271
		inc bx
		jmp @$270
@$271:
		jmp near @$284

;     } else if (c == '\'' || c == '"') {  /* Character constant. */
@$272:
		cmp dl, 0x27
		je @$273
		cmp dl, 0x22
		jne @$277

;         return p[1] != '\0' && p[1] != c && p[2] == c;
@$273:
		mov al, byte [bx+1]
		test al, al
		je @$276
		cmp dl, al
		je @$276
		cmp dl, byte [bx+2]
@$274:
		jne @$276
@$275:
		mov al, 1
		jmp near @$90
@$276:
		xor al, al
		jmp near @$90

;     } else if (isdigit(c)) {  /* Decimal or hexadecimal. */
@$277:
		mov al, dl
		xor ah, ah
		call near isdigit_
		test ax, ax
		je @$283

;         for (; SUB_U((unsigned char)(c = p[0]), '0') <= 9U; ++p) {}
@$278:
		mov dl, byte [bx]
		mov al, dl
		xor ah, ah
		mov cx, ax
		sub cx, 0x30
		cmp cx, 9
		ja @$279
		inc bx
		jmp @$278

;         if ((c | 32) == 'h' || isxdigit(c)) {
@$279:
		mov dh, dl
		or dh, 0x20
		cmp dh, 0x68
		je @$280
		call near isxdigit_
		test ax, ax
		je @$284

;             for (; c = p[0], isxdigit(c); ++p) {}
@$280:
		mov dl, byte [bx]
		mov al, dl
		xor ah, ah
		call near isxdigit_
		test ax, ax
		je @$281
		inc bx
		jmp @$280

;             return (c | 32) == 'h';
@$281:
		mov al, dl
		or al, 0x20
		cmp al, 0x68
		je @$275
@$282:
		xor al, al
		jmp near @$90

;         }
;     } else if (c == '$' && isdigit(p[1])) {
@$283:
		cmp dl, 0x24
		jne @$282
		mov al, byte [bx+1]
		xor ah, ah
		call near isdigit_
		test ax, ax
		je @$282

;         goto try_hex2;
;     } else {
		jmp near @$267

;         return 0;
;     }
;     return c == '\0';
@$284:
		test dl, dl
		jmp @$274

; }
; 
; /*
;  ** Match register
;  */
; static const char *match_register(const char *p, int width, unsigned char *reg) {
match_register_:
		push cx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		push ax
		mov cx, ax
		mov di, bx

;     const char *r0, *r, *r2;
;     union { char a[2]; short s; } puc;  /* Avoid GCC warning: dereferencing type-punned pointer will break strict-aliasing rules [-Wstrict-aliasing] */
; 
;     p = avoid_spaces(p);
		call near avoid_spaces_
		mov bx, ax
		mov cx, ax

;     if (!isalpha(p[0]) || !isalpha(p[1]) || islabel(p[2]))
		mov al, byte [bx]
		mov byte [bp-2], al
		mov byte [bp-1], 0
		mov ax, word [bp-2]
		call near isalpha_
		test ax, ax
		je @$288
		mov al, byte [bx+1]
		xor ah, ah
		call near isalpha_
		test ax, ax
		je @$288
		mov al, byte [bx+2]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$288

;         return NULL;
;     r0 = r = GP_REGISTER_NAMES + (width & 16);  /* Works for width == 8 and width == 16. */
		and dx, 0x10
		mov si, _register_names+8
		add si, dx
		mov ax, si

;     if (CONFIG_CPU_UNALIGN && sizeof(short) == 2) {
;         puc.s = *(short*)p & ~0x2020;
;     } else {
;         puc.a[0] = p[0] & ~32;
;         puc.a[1] = p[1] & ~32;
;     }
		mov dx, word [bx]
		and dx, 0xdfdf
		mov word [bp-4], dx

;     for (r2 = r + 16; r != r2; r += 2) {
		lea dx, [si+0x10]
		mov bx, word [bp-4]
@$285:
		cmp si, dx
		je @$288
		cmp bx, word [si]
		jne @$287

;         if ((CONFIG_CPU_UNALIGN && sizeof(short) == 2) ? puc.s == *(short*)r : (puc.a[0] == r[0] && puc.a[1] == r[1])) {
;             if (reg) *reg = (r - r0) >> 1;
		test di, di
		je @$286
		sub si, ax
		mov ax, si
		sar ax, 1
		mov byte [di], al

;             return p + 2;
@$286:
		mov ax, cx
		inc ax
		inc ax
		jmp near @$46

;         }
;     }
@$287:
		inc si
		inc si
		jmp @$285

;     return NULL;
@$288:
		xor ax, ax

; }
		jmp near @$46

; 
; /* --- Recording of wide sources for -O0
;  *
;  * In assembler_pass == 0, add_wide_source_in_pass_1(...) for all jump
;  * sources which were guessed as `jmp near', and for all effective address
;  * offsets which were guessed as 16-bit, both
;  *  because they had undefined labels,
;  *
;  * In assembler_pass > 1, these sources are used to force the jump to
;  * `jmp near' and he effective address to 16-bit, thus the instruction won't
;  * get optimized to a smaller size (e.g. from `jmp near' to `jmp short'),
;  * which is a requirement for -O0.
;  */
; 
; STRUCT_PACKED_PREFIX struct wide_instr_block {
;     struct wide_instr_block MY_FAR *next;
;     uvalue_t instrs[128];
; } STRUCT_PACKED_SUFFIX;
; 
; static struct wide_instr_block MY_FAR *wide_instr_first_block;
; static struct wide_instr_block MY_FAR *wide_instr_last_block;
; static uvalue_t MY_FAR *wide_instr_add_block_end;
; static uvalue_t MY_FAR *wide_instr_add_at;
; 
; static struct wide_instr_block MY_FAR *wide_instr_read_block;
; static uvalue_t MY_FAR *wide_instr_read_at;
; 
; /*
;  ** Must be called with strictly increasing fpos values. Thus calling it with
;  ** the same fpos multiple times is not allowed.
;  */
; static void add_wide_instr_in_pass_1(char do_add_1) {
add_wide_instr_in_pass_1_:
		push bx
		push cx
		push dx
		push si
		push di
		push bp
		mov bp, sp
		push ax

;     /* TODO(pts): Optimize this function for size in __DOSMC__. */
;     uvalue_t fpos = current_address - start_address;  /* Output file offset. Valid even before `org'. */
		mov bx, word [_current_address]
		mov di, word [_current_address+2]
		sub bx, word [_start_address]
		sbb di, word [_start_address+2]
		mov word [bp-2], bx

;     struct wide_instr_block MY_FAR *new_block;
;     if (do_add_1) ++fpos;
		test al, al
		je @$289
		add bx, 1
		mov word [bp-2], bx
		adc di, 0

;     if (0) DEBUG1("add_wide fpos=0x%x\n", (unsigned)fpos);
; #if DEBUG
;     if (wide_instr_add_at != NULL && wide_instr_add_at[-1] >= fpos) {
;         DEBUG1("oops: added non-strictly-increasing wide instruction at fpos=0x%x\r\n", (unsigned)fpos);
;         MESSAGE(1, "oops: bad wide position");
;         return;
;     }
; #endif
;     if (wide_instr_add_at == wide_instr_add_block_end) {
@$289:
		mov dx, word [_wide_instr_add_at]
		mov si, word [_wide_instr_add_at+2]
		mov ax, word [_wide_instr_add_block_end]
		mov bx, word [_wide_instr_add_block_end+2]
		cmp si, bx
		jne @$294
		cmp dx, ax
		jne @$294

;         if ((new_block = (struct wide_instr_block MY_FAR*)malloc_far(sizeof(struct wide_instr_block) + CONFIG_DOSMC_PACKED)) == NULL) fatal_out_of_memory();
		mov ax, 0x205
		mov cl, 4
		mov si, ___malloc_struct__+2
		add ax, word [si]
		mov dx, ax
		and ax, 0xf
		shr dx, cl
		add dx, word [si+2]
		cmp dx, word [si-2]
		ja @$290
		jb @$291
		test ax, ax
		je @$291
@$290:
		xor ax, ax
		xor dx, dx
		jmp @$292
@$291:
		xchg word [si], ax
		xchg word [si+2], dx
@$292:
		mov bx, ax
		mov cx, dx
		test dx, dx
		jne @$293
		test ax, ax
		jne @$293
		call near fatal_out_of_memory_

;         if (wide_instr_first_block == NULL) {
@$293:
		mov dx, word [_wide_instr_first_block]
		mov ax, word [_wide_instr_first_block+2]
		test ax, ax
		jne @$295
		test dx, dx
		jne @$295

;             wide_instr_first_block = new_block;
		mov word [_wide_instr_first_block], bx
		mov word [_wide_instr_first_block+2], cx

;         } else {
		jmp @$296
@$294:
		jmp @$297

;             wide_instr_last_block->next = new_block;
@$295:
		les si, [_wide_instr_last_block]
		mov word [es:si], bx
		mov word [es:si+2], cx

;         }
;         wide_instr_last_block = new_block;
@$296:
		mov word [_wide_instr_last_block], bx
		mov word [_wide_instr_last_block+2], cx

;         wide_instr_add_at = new_block->instrs;
		mov word [_wide_instr_add_at+2], cx
		lea ax, [bx+4]
		mov word [_wide_instr_add_at], ax

;         wide_instr_add_block_end = new_block->instrs + sizeof(new_block->instrs) / sizeof (new_block->instrs[0]);  /* TODO(pts): For __DOSMC__, don't do the multiplication again. */
		mov word [_wide_instr_add_block_end+2], cx
		lea ax, [bx+0x204]
		mov word [_wide_instr_add_block_end], ax

; #if CONFIG_DOSMC_PACKED
;         ((char MY_FAR*)new_block)[sizeof(struct wide_instr_block)] = '\0';  /* Mimic trailing NUL of a ``previous label'' for RBL_GET_LEFT(..) and RBL_GET_RIGHT(...). */
		mov es, cx
		mov byte [es:bx+0x204], 0

; #endif
;     }
;     *wide_instr_add_at++ = fpos;
@$297:
		les bx, [_wide_instr_add_at]
		lea ax, [bx+4]
		mov word [_wide_instr_add_at], ax
		mov ax, word [bp-2]
		mov word [es:bx], ax
		mov word [es:bx+2], di
		jmp near @$87

;     if (0) DEBUG1("added preguessed wide instruction at fpos=0x%x\r\n", (unsigned)fpos);
; }
; 
; /*
;  ** Must be called with increasing fpos values. Thus calling it with the same
;  ** fpos multiple times is OK.
;  */
; static char is_wide_instr_in_pass_2(char do_add_1) {
is_wide_instr_in_pass_2_:
		push bx
		push cx
		push dx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		push ax
		mov cl, al

;     /* TODO(pts): Optimize this function for size in __DOSMC__. */
;     uvalue_t fpos = current_address - start_address;  /* Output file offset. Valid even before `org'. */
		mov bx, word [_current_address]
		mov ax, word [_current_address+2]
		sub bx, word [_start_address]
		sbb ax, word [_start_address+2]
		mov dx, bx

;     uvalue_t MY_FAR *vp;
;     char is_next_block;
;     if (do_add_1) ++fpos;
		test cl, cl
		je @$298
		add dx, 1
		adc ax, 0

;     if (0) DEBUG2("guess from fpos=0x%x rp=%p\r\n", (unsigned)fpos, (void*)wide_instr_read_at);
;     if (wide_instr_read_at) {
@$298:
		mov bx, word [_wide_instr_read_at]
		mov si, word [_wide_instr_read_at+2]
		test si, si
		jne @$299
		test bx, bx
		je @$304

;         if (fpos == *wide_instr_read_at) {  /* Called again with the same fpos as last time. */
@$299:
		mov es, si
		cmp ax, word [es:bx+2]
		jne @$301
		cmp dx, word [es:bx]
		jne @$301

;             return 1;
@$300:
		mov al, 1
		jmp near @$87

;         } else if (fpos <= *wide_instr_read_at) { bad_instr_order:
@$301:
		cmp ax, word [es:bx+2]
		jb @$302
		jne @$303
		cmp dx, word [es:bx]
		ja @$303

;             DEBUG2("oops: bad instr order fpos=0x%x added=0x%x\r\n", (unsigned)fpos, wide_instr_read_at ? (unsigned)*wide_instr_read_at : 0);
;             MESSAGE(1, "oops: bad instr order");
@$302:
		mov ax, @$950
		call near message_

;             goto return_0;
		jmp near @$314

;         }
;         vp = wide_instr_read_at + 1;
@$303:
		mov word [bp-2], si
		add bx, 4

;     } else {
		jmp @$306

;         if (wide_instr_first_block == NULL) goto return_0;  /* No wide instructions at all. */
@$304:
		mov si, word [_wide_instr_first_block]
		mov bx, word [_wide_instr_first_block+2]
		test bx, bx
		jne @$305
		test si, si
		je @$308

;         wide_instr_read_block = wide_instr_first_block;
@$305:
		mov word [_wide_instr_read_block], si
		mov word [_wide_instr_read_block+2], bx

;         vp = wide_instr_read_block->instrs;
		mov word [bp-2], bx
		lea bx, [si+4]

;     }
;     if (0) DEBUG2("guess2 from 0x%x at=%d\r\n", (unsigned)fpos, (int)(vp - wide_instr_first_block->instrs));
;     if (vp == wide_instr_add_at) {  /* All wide instructions have been read. Also matches if there were none. */
@$306:
		mov si, word [_wide_instr_add_at]
		mov cx, word [_wide_instr_add_at+2]
		cmp cx, word [bp-2]
		jne @$307
		cmp bx, si
		je @$308

;         goto return_0;
;     } else if (vp == wide_instr_read_block->instrs + sizeof(wide_instr_read_block->instrs) / sizeof(wide_instr_read_block->instrs[0])) {
@$307:
		mov si, word [_wide_instr_read_block]
		mov cx, word [_wide_instr_read_block+2]
		mov word [bp-4], cx
		lea cx, [si+0x204]
		mov di, word [bp-2]
		cmp di, word [bp-4]
		jne @$309
		cmp bx, cx
		jne @$309

;         vp = wide_instr_read_block->next->instrs;
		mov es, word [bp-4]
		mov cx, word [es:si]
		mov bx, word [es:si+2]
		mov word [bp-2], bx
		mov bx, cx
		add bx, 4

;         is_next_block = 1;
		mov cl, 1

;         if (0) DEBUG0("next wide block\r\n");
		jmp @$310
@$308:
		jmp @$314

;     } else {
;         is_next_block = 0;
@$309:
		xor cl, cl

;     }
;     if (fpos > *vp) {
@$310:
		mov es, word [bp-2]
		cmp ax, word [es:bx+2]
		ja @$302
		jne @$311
		cmp dx, word [es:bx]
		jbe @$311
		jmp near @$302

;         DEBUG0("oops: bad instr order2\r\n");
;         goto bad_instr_order;
;     } else if (fpos == *vp) {
@$311:
		cmp ax, word [es:bx+2]
		jne @$314
		cmp dx, word [es:bx]
		jne @$314

;         wide_instr_read_at = vp;
		mov word [_wide_instr_read_at], bx
		mov word [_wide_instr_read_at+2], es

;         if (is_next_block) wide_instr_read_block = wide_instr_read_block->next;
		test cl, cl
		jne @$313
@$312:
		jmp near @$300
@$313:
		les bx, [_wide_instr_read_block]
		mov ax, word [es:bx]
		mov dx, word [es:bx+2]
		mov word [_wide_instr_read_block], ax
		mov word [_wide_instr_read_block+2], dx
		jmp @$312

;         return 1;
;     } else { return_0:
;         return 0;
@$314:
		xor al, al

;     }
; }
		jmp near @$87

; 
; /* --- */
; 
; /* Table for describing a single register addition (+..) to an effective address.
; 
;         [bx+si]=0 [bx+di]=1 [bp+si]=2 [bp+di]=3   [si]=4    [di]=5    [bp]=6    [bx]=7    []=8     [bad]=9
; +BX=3:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bx+si]=0 [bx+di]=1 [bad]=9   [bad]=9   [bx]=7   [bad]=9
; +SP=4:  [bad]=9...
; +BP=5:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bp+si]=2 [bp+di]=3 [bad]=9   [bad]=9   [bp]=6   [bad]=9
; +SI=6:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bad]=9   [bad]=9   [bp+si]=2 [bx+si]=0 [si]=4   [bad]=9
; +DI=7:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bad]=9   [bad]=9   [bp+di]=3 [bx+di]=1 [di]=5   [bad]=9
; */
; static UNALIGNED const unsigned char reg_add_to_addressing[5 * 5] = {
;     /* +BX: */ 0, 1, 9, 9, 7,
;     /* +SP: */ 9, 9, 9, 9, 9,
;     /* +BP: */ 2, 3, 9, 9, 6,
;     /* +DI: */ 9, 9, 2, 0, 4,
;     /* +SI: */ 9, 9, 3, 1, 5,
; };
; 
; /*
;  ** Match addressing (r/m): can be register or effective address [...].
;  ** As a side effect, it sets instruction_addressing, instruction_offset, instruction_offset_width.
;  */
; static const char *match_addressing(const char *p, int width) {
match_addressing_:
		push bx
		push cx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		mov si, ax

;     unsigned char state, reg, has_any_undefined;
;     const char *p2;
;     char c;
; 
;     instruction_offset = 0;
		xor ax, ax
		mov word [_instruction_offset], ax

;     instruction_offset_width = 0;
		xor al, al
		mov byte [_instruction_offset_width], al

;     instruction_addressing_segment = 0;
		mov byte [_instruction_addressing_segment], al

;     has_any_undefined = 0;
		xor ch, ch

;     p = avoid_spaces(p);
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;     if (*p == '[') {  /* Effective address. */
		cmp byte [si], 0x5b
		jne @$318

;         p = avoid_spaces(p + 1);
		inc ax
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;         if (p[0] != '\0' && ((p[1] & ~32) == 'S') && ((c = p[0] & ~32) == 'S' || SUB_U(c, 'C') <= 'E' - 'C' + 0U)) {  /* Possible segment register: CS, DS, ES or SS. */
		cmp byte [bx], 0
		je @$321
		mov al, byte [bx+1]
		and ax, 0xdf
		cmp ax, 0x53
		jne @$321
		mov bl, byte [bx]
		and bl, 0xdf
		cmp bl, 0x53
		je @$315
		mov al, bl
		sub ax, 0x43
		cmp ax, 2
		ja @$321

;             p2 = avoid_spaces(p + 2);
@$315:
		lea ax, [si+2]
		call near avoid_spaces_
		mov di, ax

;             if (p2[0] == ':') {  /* Found segment register. */
		cmp byte [di], 0x3a
		jne @$321

;                 p = avoid_spaces(p2 + 1);
		inc ax
		call near avoid_spaces_
		mov si, ax

;                 instruction_addressing_segment = c == 'C' ? 0x2e : c == 'D' ? 0x3e : c == 'E' ? 0x26 : /* c == 'S' ? */ 0x36;
		cmp bl, 0x43
		jne @$316
		mov ax, 0x2e
		jmp @$320
@$316:
		cmp bl, 0x44
		jne @$317
		mov ax, 0x3e
		jmp @$320
@$317:
		cmp bl, 0x45
		jne @$319
		mov ax, 0x26
		jmp @$320
@$318:
		jmp near @$337
@$319:
		mov ax, 0x36
@$320:
		mov byte [_instruction_addressing_segment], al

;             }
;         }
;         state = 8;  /* [] so far. */
@$321:
		mov cl, 8

;         for (;;) {
;             p2 = match_register(p, 16, &reg);
@$322:
		lea bx, [bp-2]
		mov dx, 0x10
		mov ax, si
		call near match_register_
		mov di, ax

;             if (p2 != NULL) {
		test ax, ax
		je @$325

;                 if (reg - 3U > 7U - 3U || state < 4) return NULL;  /* Bad register combination. */
		mov al, byte [bp-2]
		xor ah, ah
		sub ax, 3
		cmp ax, 4
		ja @$323
		cmp cl, 4
		jae @$324
@$323:
		xor ax, ax
		jmp near @$339

;                 state = reg_add_to_addressing[state - 19 + 5 * reg];
@$324:
		mov al, cl
		xor ah, ah
		mov bx, ax
		mov al, byte [bp-2]
		mov dx, 5
		imul dx
		add bx, ax
		mov cl, byte [bx+_reg_add_to_addressing-0x13]

;                 if (state > 8) return NULL;  /* Bad register combination. */
		cmp cl, 8
		ja @$323

;                 p = p2;
		mov si, di

;             } else {  /* Displacement. */
		jmp @$326

;                 if ((p = match_expression(p)) == NULL) return NULL;  /* Displacemeny syntax error. */
@$325:
		mov ax, si
		call near match_expression_
		mov si, ax
		test ax, ax
		je @$330

;                 instruction_offset += GET_U16(instruction_value);  /* Higher bits are ignored. */
		mov ax, word [_instruction_value]
		add word [_instruction_offset], ax

;                 has_any_undefined |= has_undefined;
		or ch, byte [_has_undefined]

;             }
;             p = avoid_spaces(p);
@$326:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax
		inc ax

;             if (*p == ']') {
		cmp byte [bx], 0x5d
		je @$328

;                ++p;
;                break;
;             } else if (*p == '-') {
		cmp byte [bx], 0x2d
		je @$327

;             } else if (*p == '+') {
		cmp byte [bx], 0x2b
		jne @$323

;                ++p;  /* In case of +register. */
;             } else {
;               return NULL;  /* Displacement not followed by ']', '+' or '-'. */
;             }
		mov si, ax

;             p = avoid_spaces(p);
@$327:
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;         }
		jmp @$322

@$328:
		mov si, ax

;         if (state == 8) {  /* Absolute address without register. */
		cmp cl, 8
		jne @$329

;             state = 0x06;
		mov cl, 6

;             instruction_offset_width = 2;
		mov byte [_instruction_offset_width], 2

;         } else {
		jmp @$338

;             if (opt_level <= 1) {  /* With -O0, `[...+ofs]' is 8-bit offset iff there are no undefined labels in ofs and it fits to 8-bit signed in assembler_pass == 0. This is similar to NASM. */
@$329:
		cmp byte [_opt_level], 1
		ja @$332

;                if (assembler_pass == 0) {
		cmp word [_assembler_pass], 0
		jne @$331

;                    if (has_any_undefined) {
		test ch, ch
		je @$332

;                        instruction_offset_width = 3;  /* Width is actually 2, but this indicates that add_wide_instr_in_pass_1(...) should be called later if this match is taken. */
		mov byte [_instruction_offset_width], 3

;                        goto set_16bit_offset;
		jmp @$335
@$330:
		jmp @$339

;                    }
;                } else {
;                    if (is_wide_instr_in_pass_2(0)) goto force_16bit_offset;
@$331:
		xor ax, ax
		call near is_wide_instr_in_pass_2_
		test al, al
		jne @$334

;                }
;             }
;             instruction_offset = GET_U16(instruction_offset);
;             if (instruction_offset != 0 || state == 6 /* [bp]. */) {
@$332:
		cmp word [_instruction_offset], 0
		jne @$333
		cmp cl, 6
		jne @$338

;                 if ((instruction_offset + 0x80) & 0xff00U) {
@$333:
		mov ax, word [_instruction_offset]
		add ax, 0x80
		test ah, 0xff
		je @$336

;                   force_16bit_offset:
;                     instruction_offset_width = 2;
@$334:
		mov byte [_instruction_offset_width], 2

;                   set_16bit_offset:
;                     state |= 0x80;  /* 16-bit offset. */
@$335:
		or cl, 0x80

;                 } else {
		jmp @$338

;                     ++instruction_offset_width;  /* = 1; */
;                     state |= 0x40;  /* Signed 8-bit offset. */
@$336:
		or cl, 0x40

		inc byte [_instruction_offset_width]

;                 }
		jmp @$338

;             }
;         }
;     } else {  /* Register. */
;         p = match_register(p, width, &reg);
@$337:
		lea bx, [bp-2]
		call near match_register_
		mov si, ax

;         if (p == NULL)
		test ax, ax
		je @$339

;             return NULL;
;         state = 0xc0 | reg;
		mov cl, byte [bp-2]
		or cl, 0xc0

;     }
;     instruction_addressing = state;
@$338:
		mov byte [_instruction_addressing], cl

;     return p;
		mov ax, si

; }
@$339:
		mov sp, bp
		pop bp
		pop di
@$340:
		pop si
		pop cx
		pop bx
		ret

; 
; /* Not declaring static for compatibility with C++ and forward declarations. */
; extern struct bbprintf_buf emit_bbb;
; 
; static UNALIGNED char emit_buf[512];
; 
; static void emit_flush(struct bbprintf_buf *bbb) {
emit_flush_:
		push bx
		push cx
		push dx

;     const int size = emit_bbb.p - emit_buf;
		mov cx, word [_emit_bbb+4]
		sub cx, _emit_buf

;     (void)bbb;  /* emit_bbb. */
;     if (size) {
		jne @$342
@$341:
		jmp near @$90

;         if (write(output_fd, emit_buf, size) != size) {
@$342:
		mov ax, word [_output_fd]
		mov bx, cx
		mov dx, _emit_buf
		call near write_
		cmp ax, cx
		je @$343

;             MESSAGE(1, "error writing to output file");
		mov ax, @$951
		call near message_

;             exit(3);
		mov ax, 3
		mov ah, 0x4c
		int 0x21

;         }
;         emit_bbb.p = emit_buf;
@$343:
		mov word [_emit_bbb+4], _emit_buf

;     }
		jmp @$341

; }
; 
; struct bbprintf_buf emit_bbb = { emit_buf, emit_buf + sizeof(emit_buf), emit_buf, 0, emit_flush };
; 
; static void emit_write(const char *s, int size) {
emit_write_:
		push bx
		push cx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		mov bx, ax

;     int emit_free;
;     while ((emit_free = emit_bbb.buf_end - emit_bbb.p) <= size) {
@$344:
		mov ax, word [_emit_bbb+2]
		sub ax, word [_emit_bbb+4]
		mov word [bp-2], ax
		cmp dx, ax
		jl @$345

; #if CONFIG_USE_MEMCPY_INLINE  /* A few bytes smaller than memcpy(...) for __DOSMC__. Doesn't make a difference with __WATCOMC__ Linux i386 <libc.h>.  */
;         emit_bbb.p = (char*)memcpy_newdest_inline(emit_bbb.p, s, emit_free);
		mov di, word [_emit_bbb+4]
		mov cx, ax
		mov si, bx
		push ds
		pop es
		rep movsb
		mov word [_emit_bbb+4], di

; #else
;         memcpy(emit_bbb.p, s, emit_free);
;         emit_bbb.p += emit_free;
; #endif
;         s += emit_free; size -= emit_free;
		add bx, word [bp-2]
		sub dx, word [bp-2]

;         emit_flush(0);
		xor ax, ax
		call near emit_flush_

;     }
		jmp @$344

; #if CONFIG_USE_MEMCPY_INLINE  /* A few bytes smaller than memcpy(...). */
;     emit_bbb.p = (char*)memcpy_newdest_inline(emit_bbb.p, s, size);
@$345:
		mov di, word [_emit_bbb+4]
		mov cx, dx
		mov si, bx
		push ds
		pop es
		rep movsb
		mov word [_emit_bbb+4], di
		jmp near @$339

; #else
;     memcpy(emit_bbb.p, s, size);
;     emit_bbb.p += size;
; #endif
; }
; 
; static void emit_bytes(const char *s, int size)  {
emit_bytes_:
		push bx
		push si
		push di
		mov si, ax
		mov bx, dx

;     current_address += size;
		mov ax, dx
		cwd
		add word [_current_address], ax
		adc word [_current_address+2], dx

;     if (assembler_pass > 1) {
		cmp word [_assembler_pass], 1
		jbe @$347

;         emit_write(s, size);
		mov dx, bx
		mov ax, si
		call near emit_write_

;         bytes += size;
		mov ax, bx
		cwd
		add word [_bytes], ax
		adc word [_bytes+2], dx

;         if (generated_cur != NULL) {
		cmp word [_generated_cur], 0
		je @$347

;             for (; size > 0 && generated_cur != generated_buf + sizeof(generated_buf); *generated_cur++ = *s++, --size) {}
@$346:
		test bx, bx
		jle @$347
		mov ax, word [_generated_cur]
		cmp ax, _generated_buf+8
		je @$347
		mov di, si
		mov dx, ax
		inc si
		inc ax
		mov word [_generated_cur], ax
		mov al, byte [di]
		mov di, dx
		mov byte [di], al
		dec bx
		jmp @$346

;         }
;     }
; }
@$347:
		pop di
		pop si
		pop bx
		ret

; 
; /*
;  ** Emit one byte to output
;  */
; static void emit_byte_func(int byte) {  /* Changing `c' to `char' would increase the file size for __DOSMC__. */
emit_byte_func_:
		push dx
		push bp
		mov bp, sp
		push ax

;     const char c = byte;
		mov byte [bp-2], al

;     emit_bytes(&c, 1);
		mov dx, 1
		lea ax, [bp-2]
		call near emit_bytes_

; }
		mov sp, bp
		pop bp
		pop dx
		ret

; #ifdef _MSC_VER  /* Without this, Microsoft C 6.00a (_MSC_VER == 600) reports: warning C4061: long/short mismatch in argument : conversion supplied */
; #  define emit_byte(b) emit_byte_func((char)(b))
; #else
; #  define emit_byte(b) emit_byte_func(b)  /* Doing an explicit (char) conversion here would increase the file size by 25 bytes for __DOSMC__. */
; #endif
; 
; /*
;  ** Check for end of line
;  */
; static const char *check_end(const char *p) {
check_end_:
		push bx

;     p = avoid_spaces(p);
		call near avoid_spaces_
		mov bx, ax

;     if (*p) {
		cmp byte [bx], 0
		je @$348

;         MESSAGE(1, "extra characters at end of line");
		mov ax, @$952
		call near message_

;         return NULL;
		xor ax, ax

;     }
;     return p;
; }
@$348:
		pop bx
		ret

; 
; static char was_strict;
; 
; static const char *avoid_strict(const char *p) {
avoid_strict_:
		push bx
		push cx
		push dx
		push si
		mov cx, ax

;     const char *p1;
;     was_strict = 0;
		mov byte [_was_strict], 0

;     p1 = p;
		mov si, ax

;     if (casematch(p, "STRICT!")) {
		mov dx, @$941
		call near casematch_
		test al, al
		je @$351

;         p = avoid_spaces(p + 6);
		lea ax, [si+6]
		call near avoid_spaces_
		mov bx, ax
		mov cx, ax

;         if (casematch(p, "BYTE!") || casematch(p, "WORD!") || casematch(p, "SHORT!") || casematch(p, "NEAR!")) {
		mov dx, @$938
		call near casematch_
		test al, al
		jne @$349
		mov dx, @$939
		mov ax, bx
		call near casematch_
		test al, al
		jne @$349
		mov dx, @$935
		mov ax, bx
		call near casematch_
		test al, al
		jne @$349
		mov dx, @$936
		mov ax, bx
		call near casematch_
		test al, al
		je @$350

;             was_strict = 1;
@$349:
		mov byte [_was_strict], 1

;         } else {
		jmp @$351

;             p = p1;
@$350:
		mov cx, si

;         }
;     }
;     return p;
; }
@$351:
		mov ax, cx
		jmp near @$89

; 
; /*
;  ** Search for a match with instruction
;  */
; static const char *match(const char *p, const char *pattern_and_encode) {
match_:
		push bx
		push cx
		push si
		push di
		push bp
		mov bp, sp
		sub sp, 0x14
		mov si, ax
		mov word [bp-0x14], dx

;     int c;  /* Can be as little as 16-bits. value_t is used instead where larger is needed. */
;     int bit;
;     int qualifier;
;     const char *p0;
;     const char *p1;
;     const char *error_base;
;     static unsigned short segment_value;  /* Static just to pacify GCC 7.5.0 warning of uninitialized. */
;     char dc, dw, do_add_wide_imm8, is_imm_8bit, do_opt_lea_now;
; 
;     /* Example instructions with emitted_bytes + instructon + "pattern encode":
;      *
;      * 3B063412  cmp ax,[0x1234]  "r,k 3Bdrd"
;      * 88063412  mov [0x1234],al  "k,r 89drd"  ; A23412
;      * 89063412  mov [0x1234],ax  "k,r 89drd"  ; A33412
;      * 8A063412  mov al,[0x1234]  "q,j 8Adrd"  ; A03412
;      * 8B063412  mov ax,[0x1234]  "r,k 8Bdrd"  ; A13412
;      */
;     p0 = p;
		mov word [bp-0xa], ax

;     qualifier = 0;  /* Pacify gcc. */
		mov word [bp-0xe], 0

;     do_add_wide_imm8 = 0;
		xor al, al
		mov byte [bp-6], al

;     is_imm_8bit = 0;
		mov byte [bp-4], al

;     do_opt_lea_now = 0;
		mov byte [bp-8], al

;   next_pattern:
;     if (0) DEBUG1("match pattern=(%s)\n", pattern_and_encode);
;     instruction_addressing_segment = 0;  /* Reset it in case something in the previous pattern didn't match after a matching match_addressing(...). */
@$352:
		xor al, al
		mov byte [_instruction_addressing_segment], al

;     instruction_offset_width = 0;  /* Reset it in case something in the previous pattern didn't match after a matching match_addressing(...). */
		mov byte [_instruction_offset_width], al

;     /* Unused pattern characters: 'z'. */
;     for (error_base = pattern_and_encode; (dc = *pattern_and_encode++) != ' ';) {
		mov bx, word [bp-0x14]
		mov word [bp-0x12], bx
@$353:
		mov bx, word [bp-0x14]
		mov bl, byte [bx]
		inc word [bp-0x14]
		cmp bl, 0x20
		je @$359

;         if (SUB_U(dc, 'j') <= 'o' - 'j' + 0U) {  /* Addressing: 'j': %d8, 'k': %d16 (reg/mem16), 'l': %db8, 'm': %dw16 (reg/mem16 with explicit size qualifier), 'n': effective address without a size qualifier (for lds, les), 'o' effective address without a size qualifier (for lea). */
		mov al, bl
		xor ah, ah
		mov dx, ax
		sub dx, 0x6a
		cmp dx, 5
		ja @$360

;             qualifier = 0;
		xor al, bl
		mov word [bp-0xe], ax

;             if (dc == 'n') {
		cmp bl, 0x6e
		jne @$355

;               do_n_or_o:
;                 if (p[0] != '[') goto mismatch;
@$354:
		cmp byte [si], 0x5b
		jne @$361
		jmp near @$370

;                 goto do_addressing_16;  /* 8 would have been also fine. */
;             } else if (dc == 'o') {
@$355:
		cmp bl, 0x6f
		jne @$356

;                 if (do_opt_lea) do_opt_lea_now = 1;
		cmp byte [_do_opt_lea], 0
		je @$354
		mov byte [bp-8], 1
		jmp @$354

;                 goto do_n_or_o;
;             } else if (casematch(p, "WORD!")) {
@$356:
		mov dx, @$939
		mov ax, si
		call near casematch_
		test al, al
		je @$358

;                 p += 4;
;                 qualifier = 16;
		mov word [bp-0xe], 0x10

@$357:
		add si, 4

;             } else if (casematch(p, "BYTE!")) {
		jmp near @$366
@$358:
		mov dx, @$938
		mov ax, si
		call near casematch_
		test al, al
		je @$362

;                 p += 4;
;                 qualifier = 8;
		mov word [bp-0xe], 8
		jmp @$357
@$359:
		jmp near @$469
@$360:
		jmp near @$371
@$361:
		jmp near @$429

;             } else if ((dc == 'l' || dc == 'm') && p[0] == '[') {  /* Disallow e.g.: dec [bx] */
@$362:
		cmp bl, 0x6c
		je @$363
		cmp bl, 0x6d
		jne @$366
@$363:
		cmp byte [si], 0x5b
		jne @$366

;                 /* Example: case for `cmp [bp], word 1'. */
;                 if (pattern_and_encode[0] == ',' && ((dw = pattern_and_encode[1]) == 's' || dw == 't' || dw == 'u') &&
		mov di, word [bp-0x14]
		cmp byte [di], 0x2c
		jne @$361
		mov al, byte [di+1]
		mov byte [bp-2], al
		cmp al, 0x73
		je @$364
		cmp al, 0x74
		je @$364
		cmp al, 0x75
		jne @$361
@$364:
		xor dx, dx
		mov ax, si
		call near match_addressing_
		mov di, ax
		test ax, ax
		je @$361
		cmp byte [di], 0x2c
		jne @$361

;                     (p1 = match_addressing(p, 0)) != NULL &&  /* Width (0) doesn't matter, because it's not an register, but an effective address. */
;                     p1[0] == ','
;                    ) {
;                     p1 = avoid_strict(avoid_spaces(p1 + 1));
		inc ax
		call near avoid_spaces_
		call near avoid_strict_
		mov cx, ax

;                     if (!((dc == 'l' && casematch(p1, "BYTE!")) || (dc == 'm' && casematch(p1, "WORD!")))) goto mismatch;
		cmp bl, 0x6c
		jne @$365
		mov dx, @$938
		call near casematch_
		test al, al
		jne @$366
@$365:
		cmp bl, 0x6d
		jne @$361
		mov dx, @$939
		mov ax, cx
		call near casematch_
		test al, al
		je @$361

;                 } else {
;                     goto mismatch;
;                 }
;             }
;             if (dc == 'j' || dc == 'l') {
@$366:
		cmp bl, 0x6a
		je @$367
		cmp bl, 0x6c
		jne @$369

;                 /* NASM allows with a warning, but we don't for dc == 'l': dec word bh */
;                 if (qualifier == 16) goto mismatch;
@$367:
		cmp word [bp-0xe], 0x10
		je @$361

;                 /* It sets instruction_addressing, instruction_offset, instruction_offset_width. */
;                 p = match_addressing(p, 8);
		mov dx, 8
@$368:
		mov ax, si
		call near match_addressing_
		jmp near @$384

;             } else /* if (dc == 'k' || dc == 'm') */ {
;                 /* NASM allows with a warning, but we don't for dc == 'm': dec byte bx */
;                 if (qualifier == 8) goto mismatch;
@$369:
		cmp word [bp-0xe], 8
		je @$377

;               do_addressing_16:
;                 /* It sets instruction_addressing, instruction_offset, instruction_offset_width. */
;                 p = match_addressing(p, 16);
@$370:
		mov dx, 0x10
		jmp @$368

;             }
;         } else if (dc == 'q') {  /* Register, 8-bit. */
@$371:
		cmp bl, 0x71
		jne @$373

;             /* NASM allows with a warning, but we don't for dc == 'l': dec word bh */
;             if (casematch(p, "BYTE!")) p += 4;
		mov dx, @$938
		mov ax, si
		call near casematch_
		test al, al
		je @$372
		add si, 4

;             p = match_register(p, 0, &instruction_register);  /* 0: anything without the 16 bit set. */
@$372:
		mov bx, _instruction_register
		xor dx, dx
		mov ax, si
		call near match_register_
		jmp near @$384

;         } else if (dc == 'r') {  /* Register, 16-bit. */
@$373:
		cmp bl, 0x72
		jne @$376

;             /* NASM allows with a warning, but we don't for dc == 'm': dec byte bx */
;             qualifier = 0;
		xor al, bl
		mov word [bp-0xe], ax

;           do_reg16:
;             if (casematch(p, "WORD!")) p += 4;
@$374:
		mov dx, @$939
		mov ax, si
		call near casematch_
		test al, al
		je @$375
		add si, 4

;             p = match_register(p, 16, &instruction_register);
@$375:
		mov bx, _instruction_register
		mov dx, 0x10
		mov ax, si
		call near match_register_
		mov si, ax

;             if (qualifier) instruction_addressing = 0xc0 | instruction_register;
		cmp word [bp-0xe], 0
		je @$385
		mov al, byte [_instruction_register]
		or al, 0xc0
		mov byte [_instruction_addressing], al
		jmp @$385

;         } else if (dc == 'p') {  /* Register, 16-bit, but also save it to instruction_addressing. Used in 2-argument `imul'. */
@$376:
		cmp bl, 0x70
		jne @$378

;             qualifier = 1;
		mov word [bp-0xe], 1

;             goto do_reg16;
		jmp @$374
@$377:
		jmp near @$429

;         } else if (dc == 'e') {  /* 8-bit immediate, saved to instruction_offset. Used in the first argument of `enter'.   */
@$378:
		cmp bl, 0x65
		jne @$380

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "WORD!")) p += 4;
		mov dx, @$939
		call near casematch_
		test al, al
		je @$379
		add si, 4

;             p = match_expression(p);
@$379:
		mov ax, si
		call near match_expression_
		mov si, ax

;             instruction_offset = instruction_value;
		mov ax, word [_instruction_value]
		mov word [_instruction_offset], ax

;         } else if (dc == 'h') {  /* 8-bit immediate. */
		jmp @$385
@$380:
		cmp bl, 0x68
		jne @$386

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "BYTE!")) p += 4;
		mov dx, @$938
@$381:
		call near casematch_
		test al, al
		je @$382
		add si, 4

;             p = match_expression(p);
@$382:
		mov ax, si
@$383:
		call near match_expression_
@$384:
		mov si, ax
@$385:
		jmp near @$428

;         } else if (dc == 'i') {  /* 16-bit immediate. */
@$386:
		cmp bl, 0x69
		jne @$387

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "WORD!")) p += 4;
		mov dx, @$939
		jmp @$381

;             p = match_expression(p);
;         } else if (dc == 'g') {  /* 16-bit immediate, but don't match if immediate fits to signed 8-bit. Useful for -O1 and above. Used in arithmetic pattern "AX,g" (and not other registers). */
@$387:
		cmp bl, 0x67
		jne @$392

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             qualifier = 0;
		mov word [bp-0xe], 0

;             if (casematch(p, "WORD!")) {
		mov dx, @$939
		call near casematch_
		test al, al
		je @$388

;                 p += 4;
;                 qualifier = 1;
		mov word [bp-0xe], 1

		add si, 4

;             }
;             p = match_expression(p);
@$388:
		mov ax, si
		call near match_expression_
		mov si, ax

;             /* The next pattern (of the same byte size, but with 16-bit immediate) will match. For NASM compatibility.
;              *
;              * Here we don't have to special-case forward references (assembler_pass == 0 && has_undefined), because they will eventually be resolved with opt_level >= 1.
;              *
;              * Specifying !do_opt_int below (`-O1' and `-OI') is just a cosmetic improvement: the output size remains the same. It also deviates from `-O9'.
;              */
;             if (p != NULL && (qualifier == 0 || !was_strict) && opt_level > 1 && !do_opt_int &&
		test ax, ax
		je @$390
		cmp word [bp-0xe], 0
		je @$389
		cmp byte [_was_strict], 0
		jne @$390
@$389:
		cmp byte [_opt_level], 1
		jbe @$390
		cmp byte [_do_opt_int], 0
		jne @$390
		mov dx, word [_instruction_value]
		add dx, 0x80
		mov ax, word [_instruction_value+2]
		adc ax, 0
		jne @$390
		cmp dx, 0xff
		jbe @$391
@$390:
		jmp near @$428
@$391:
		jmp near @$429

;                 GET_UVALUE(instruction_value) + 0x80U <= 0xffU  /* It matches NASM 0.98.39 with -O9. It matches `cmp ax, -4', but it doesn't match 0xfffc. This is a harmless quirk (not affecting the output size) of NASM 0.98.39, but not NASM 2.13.02. */
;                 /*!((GET_UVALUE(instruction_value) + 0x80U) & ~(uvalue_t)0xffU)*/   /* It matches NASM 0.98.39 with -O9. Same result as above, but 4 bytes longer for __DOSMC__. */
;                 /*!(((unsigned)instruction_value + 0x80U) & 0xff00U)*/  /* It matches NASM 2.13.02 with -O9. It matches both `0xffffc' and `-4'. */
;                ) goto mismatch;
;         } else if (dc == 'a' || dc == 'c') {  /* Address for jump, 8-bit. 'c' is jmp, 'a' is everything else (e.g. jc, jcxz, loop) for which short is the only allowed qualifier. */
@$392:
		cmp bl, 0x61
		je @$393
		cmp bl, 0x63
		je @$393
		jmp near @$399

;             p = avoid_strict(p);  /* STRICT doesn't matter for jumps, qualifiers are respected without it. */
@$393:
		mov ax, si
		call near avoid_strict_
		mov cx, ax
		mov si, ax

;             qualifier = 0;
		mov word [bp-0xe], 0

;             if (casematch(p, "NEAR!") || casematch(p, "WORD!")) goto mismatch;
		mov dx, @$936
		call near casematch_
		test al, al
		jne @$395
		mov dx, @$939
		mov ax, cx
		call near casematch_
		test al, al
		jne @$395

;             if (casematch(p, "SHORT!")) {
		mov dx, @$935
		mov ax, cx
		call near casematch_
		test al, al
		je @$394

;                 p += 5;
;                 qualifier = 1;
		mov word [bp-0xe], 1

		add si, 5

;             }
;             p = match_expression(p);
@$394:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p != NULL) {
		test ax, ax
		je @$390

;                 if (qualifier == 0 && opt_level <= 1 && dc == 'c') {  /* With -O0, `jmp' is `jmp short' iff it fits to 8-bit signed in assembler_pass == 0. This is similar to NASM. */
		cmp word [bp-0xe], 0
		jne @$397
		cmp byte [_opt_level], 1
		ja @$397
		cmp bl, 0x63
		jne @$397

;                     if (assembler_pass == 0) {
		cmp word [_assembler_pass], 0
		jne @$396

;                         if (has_undefined) {
		cmp byte [_has_undefined], 0
		je @$397

;                             do_add_wide_imm8 = 1;
		mov byte [bp-6], 1

;                             goto mismatch;
@$395:
		jmp near @$429

;                         }
;                     } else {
;                         if (is_wide_instr_in_pass_2(1)) goto mismatch;
@$396:
		mov ax, 1
		call near is_wide_instr_in_pass_2_
		test al, al
		jne @$395

;                     }
;                 }
;                 if (has_undefined) instruction_value = current_address;  /* Hide the extra "short jump too long" error. */
@$397:
		cmp byte [_has_undefined], 0
		je @$398
		mov dx, word [_current_address]
		mov ax, word [_current_address+2]
		mov word [_instruction_value], dx
		mov word [_instruction_value+2], ax

;                 if (0 && assembler_pass > 1 && opt_level > 1) DEBUG3("short_jump value=0x%x relative=0x%x @0x%x\r\n", (unsigned)instruction_value, (unsigned)(instruction_value - (current_address + 2)), (unsigned)current_address);
;                 instruction_value -= current_address + 2;
@$398:
		mov ax, word [_current_address]
		add ax, 2
		mov dx, word [_current_address+2]
		adc dx, 0
		sub word [_instruction_value], ax
		sbb word [_instruction_value+2], dx

;                 if (qualifier == 0 && dc == 'c') {
		cmp word [bp-0xe], 0
		jne @$402
		cmp bl, 0x63
		jne @$402

;                     is_address_used = 1;
		mov byte [_is_address_used], 1

;                     /* Jump is longer than 8-bit signed relative jump. Do a mismatch here, so that the next pattern will generate a near jump. */
;                     if (((uvalue_t)instruction_value + 0x80) & ~0xffU) goto mismatch;
		mov ax, word [_instruction_value]
		add ax, 0x80
		test ah, 0xff
		jne @$395
		jmp @$402

;                 }
;             }
;         } else if (dc == 'b') {  /* Address for jump, 16-bit. */
@$399:
		cmp bl, 0x62
		jne @$403

;             p = avoid_strict(p);  /* STRICT doesn't matter for jumps, qualifiers are respected without it. */
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "SHORT!")) goto mismatch;
		mov dx, @$935
		call near casematch_
		test al, al
		jne @$395

;             if (casematch(p, "NEAR!") || casematch(p, "WORD!")) p += 4;
		mov dx, @$936
		mov ax, si
		call near casematch_
		test al, al
		jne @$400
		mov dx, @$939
		mov ax, si
		call near casematch_
		test al, al
		je @$401
@$400:
		add si, 4

;             p = match_expression(p);
@$401:
		mov ax, si
		call near match_expression_
		mov si, ax

;             instruction_value -= current_address + 3;
		mov ax, word [_current_address]
		add ax, 3
		mov dx, word [_current_address+2]
		adc dx, 0
		sub word [_instruction_value], ax
		sbb word [_instruction_value+2], dx

;         } else if (dc == 's') {  /* Signed immediate, 16-bit or 8-bit. Used in the pattern "m,s" (m is a 16-bit register or 16-bit effective address) and push imm pattern "xs" and `imul' with imm pattern "xr,k,s". */
@$402:
		jmp near @$428
@$403:
		cmp bl, 0x73
		jne @$409

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             qualifier = 0;
		mov word [bp-0xe], 0

;             if (casematch(p, "BYTE!")) {
		mov dx, @$938
		call near casematch_
		test al, al
		je @$404

;                 p += 4;
;                 qualifier = 1;
		mov word [bp-0xe], 1

;             } else if (casematch(p, "WORD!")) {
		jmp @$405
@$404:
		mov dx, @$939
		mov ax, si
		call near casematch_
		test al, al
		je @$406

;                 p += 4;
;                 qualifier = 2;
		mov word [bp-0xe], 2

@$405:
		add si, 4

;             }
;             p = match_expression(p);
@$406:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p == NULL) {
		test ax, ax
		je @$402

;             } else if (qualifier != 0) {
		cmp word [bp-0xe], 0
		je @$410

;                 if (opt_level > 1 && !was_strict && qualifier != 1) goto detect_si8_size;  /* For -O9, ignore `word', but respect `strict word'. */
		cmp byte [_opt_level], 1
		jbe @$407
		cmp byte [_was_strict], 0
		jne @$407
		cmp word [bp-0xe], 1
		jne @$413

;                 if (qualifier == 1) is_imm_8bit = 1;
@$407:
		cmp word [bp-0xe], 1
		jne @$408
		mov byte [bp-4], 1
@$408:
		jmp near @$435
@$409:
		jmp near @$431

;                 if (opt_level == 0) goto do_nasm_o0_immediate_compat;
;             } else if (opt_level == 0) {
@$410:
		mov al, byte [_opt_level]
		test al, al
		jne @$418

;                 if (pattern_and_encode[-2] == ',') {  /* "m,s" rathern than "xs" (`push'). */
		mov bx, word [bp-0x14]
		cmp byte [bx-2], 0x2c
		jne @$417

;               do_nasm_o0_immediate_compat:
;                 /* With -O0, match NASM 0.98.39 (but not later NASM)
;                  * behavior: if there are undefined labels in the immediate,
;                  * then don't optimize the effective address.
;                  *
;                  * The opposite direction (with -O0, if there are undefined
;                  * labels in the effective address, then don't optimize the
;                  * immediate) is implemented by never optimizing the
;                  * immediate with -O0.
;                  */
;                 if ((unsigned char)instruction_addressing < 0xc0) {  /* Effective address (not register). */
@$411:
		cmp byte [_instruction_addressing], 0xc0
		jae @$417

;                     if (assembler_pass == 0) {
		cmp word [_assembler_pass], 0
		jne @$412

;                         if (has_undefined) {
		cmp byte [_has_undefined], 0
		je @$414

;                             do_add_wide_imm8 = 1;
		mov byte [bp-6], 1

;                         }
		jmp @$414

;                     } else {
;                         if (is_wide_instr_in_pass_2(1)) has_undefined = 1;
@$412:
		mov ax, 1
		call near is_wide_instr_in_pass_2_
		test al, al
		je @$414
		mov byte [_has_undefined], 1
		jmp @$415
@$413:
		jmp @$421

;                     }
;                     if (has_undefined) {  /* Missed optimization opportunity in NASM 0.98.39 and 0.99.06, mininasm does the same with -O0, but mininasm optimizes it with -O1. */
@$414:
		cmp byte [_has_undefined], 0
		je @$419

;                         /* We assume that the pattern is "m,s" or "m,u". */
;                         if (instruction_offset_width == 0) {
@$415:
		mov al, byte [_instruction_offset_width]
		test al, al
		jne @$416

;                             instruction_addressing |= 0x80;
		or byte [_instruction_addressing], 0x80

;                             instruction_offset_width = 2;
		mov byte [_instruction_offset_width], 2

;                         } else if (instruction_offset_width == 1) {
		jmp @$419
@$416:
		cmp al, 1
		jne @$419

;                             instruction_addressing ^= 0xc0;
		xor byte [_instruction_addressing], 0xc0

;                             ++instruction_offset_width;
		add byte [_instruction_offset_width], al

;                         }
@$417:
		jmp @$419

;                     }
;                 }
;                 }
;             } else if (opt_level == 1) {
@$418:
		cmp al, 1
		jne @$421

;                 if (assembler_pass == 0) {
		cmp word [_assembler_pass], 0
		jne @$420

;                     if (!has_undefined) goto detect_si8_size;
		cmp byte [_has_undefined], 0
		je @$421

;                     do_add_wide_imm8 = 1;
		mov byte [bp-6], al

;                 } else {
@$419:
		jmp near @$428

;                     if (!is_wide_instr_in_pass_2(1)) goto detect_si8_size;
@$420:
		mov ax, 1
		call near is_wide_instr_in_pass_2_
		test al, al
		jne @$428

;                 }
;             } else {
;               detect_si8_size:
;                 /* 16-bit integer cannot be represented as signed 8-bit, so don't use this encoding. Doesn't happen for has_undefined. */
;                 is_imm_8bit = !(/* !has_undefined && */
@$421:
		cmp byte [_do_opt_int], 0
		jne @$424
		mov bx, word [bp-0x14]
		cmp byte [bx-2], 0x2c
		je @$424
		mov dx, word [_instruction_value]
		add dx, 0x80
		mov ax, word [_instruction_value+2]
		adc ax, 0
		jne @$422
		cmp dx, 0xff
		jbe @$423
@$422:
		mov ax, 1
		jmp @$425
@$423:
		xor ax, ax
		jmp @$425
@$424:
		mov ax, word [_instruction_value]
		add ax, 0x80
		xor al, al
@$425:
		test ax, ax
		jne @$426
		mov al, 1
		jmp @$427
@$426:
		xor al, al
@$427:
		mov byte [bp-4], al

;                     !do_opt_int && pattern_and_encode[-2] != ',' ?  GET_UVALUE(instruction_value) + 0x80U > 0xffU :  /* It matches NASM 0.98.39 with -O9. It matches `push -4', but it doesn't match 0xfffc. This is a quirk of NASM 0.98.39 making the output file longer. */
;                     (((unsigned)instruction_value + 0x80) & 0xff00U));
;             }
@$428:
		test si, si
		je @$429
		jmp near @$353
@$429:
		mov bx, word [bp-0x14]
		mov bl, byte [bx]
		inc word [bp-0x14]
		test bl, bl
		je @$430
		cmp bl, 0x2d
		jne @$429
@$430:
		test bl, bl
		jne @$438
		xor ax, ax
		jmp near @$339

;         } else if (dc == 't') {  /* 8-bit immediate, with the NASM -O0 compatibility. Used with pattern "l,t", corresponding to an 8-bit addressing. */
@$431:
		cmp bl, 0x74
		jne @$436

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "BYTE!")) p += 4;
		mov dx, @$938
		call near casematch_
		test al, al
		je @$432
		add si, 4

;             p = match_expression(p);
@$432:
		mov ax, si
		call near match_expression_
		mov si, ax

;           force_imm_8bit:
;             is_imm_8bit = 1;
@$433:
		mov byte [bp-4], 1

;             if (p != NULL && opt_level == 0) goto do_nasm_o0_immediate_compat;
		test si, si
@$434:
		je @$428
@$435:
		cmp byte [_opt_level], 0
		jne @$428
		jmp near @$411

;         } else if (dc == 'u') {  /* 16-bit immediate, with the NASM -O0 compatibility. Used with pattern "m.u". */
@$436:
		cmp bl, 0x75
		jne @$439

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "WORD!")) p += 4;
		mov dx, @$939
		call near casematch_
		test al, al
		je @$437
		add si, 4

;             p = match_expression(p);
@$437:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p != NULL && opt_level == 0) goto do_nasm_o0_immediate_compat;
		test ax, ax
		jmp @$434
@$438:
		jmp near @$467

;         } else if (dc == 'v') {  /* Optionally the token BYTE. */
@$439:
		cmp bl, 0x76
		jne @$442

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "BYTE!")) p = avoid_spaces(p + 4);
		mov dx, @$938
@$440:
		call near casematch_
		test al, al
		jne @$441
		jmp near @$428
@$441:
		lea ax, [si+4]
		call near avoid_spaces_
		jmp near @$384

;         } else if (dc == 'w') {  /* Optionally the token WORD. */
@$442:
		cmp bl, 0x77
		jne @$443

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "WORD!")) p = avoid_spaces(p + 4);
		mov dx, @$939
		jmp @$440

;         } else if (dc == 'f') {  /* FAR pointer. */
@$443:
		cmp bl, 0x66
		jne @$446

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "SHORT!") || casematch(p, "NEAR!") || casematch(p, "WORD!")) goto mismatch;
		mov dx, @$935
		call near casematch_
		test al, al
		je @$445
@$444:
		jmp near @$429
@$445:
		mov dx, @$936
		mov ax, si
		call near casematch_
		test al, al
		jne @$444
		mov dx, @$939
		mov ax, si
		call near casematch_
		test al, al
		jne @$444

;             p = match_expression(p);
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p == NULL)
		test ax, ax
		je @$444

;                 goto mismatch;
;             segment_value = instruction_value;
		mov ax, word [_instruction_value]
		mov word [@$segment_value], ax

;             if (*p != ':')
		cmp byte [si], 0x3a
		jne @$444

;                 goto mismatch;
;             p = match_expression(p + 1);
		lea ax, [si+1]
		jmp near @$383

;         } else if (dc == '1') {  /* 8-bit immediate, shift amount (e.g. `shl' and `shr'), must be 1 on 8086. */
@$446:
		cmp bl, 0x31
		jne @$448

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "BYTE!")) p += 4;
		mov dx, @$938
		call near casematch_
		test al, al
		je @$447
		add si, 4

;             p = match_expression(p);
@$447:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p == NULL) goto mismatch;
		test ax, ax
		je @$444

;             if (opt_level <= 1) {
		cmp byte [_opt_level], 1
		ja @$450

;                 if (assembler_pass == 0) {
		cmp word [_assembler_pass], 0
		jne @$449

;                     if (has_undefined) {
		cmp byte [_has_undefined], 0
		je @$450

;                         if (cpu_level == 0) goto mismatch;
		cmp byte [_cpu_level], 0
		je @$444

;                         do_add_wide_imm8 = 1;
		mov byte [bp-6], 1

;                         goto force_imm_8bit_1;
		jmp @$453
@$448:
		jmp @$458

;                     }
;                 } else {
;                     if (is_wide_instr_in_pass_2(1)) goto force_imm_8bit_1;
@$449:
		mov ax, 1
		call near is_wide_instr_in_pass_2_
		test al, al
		jne @$453

;                 }
;             } 
;             if (!has_undefined && instruction_value != 1) {
@$450:
		cmp byte [_has_undefined], 0
		je @$452
@$451:
		jmp near @$428
@$452:
		cmp word [_instruction_value+2], 0
		jne @$453
		cmp word [_instruction_value], 1
		je @$451

;               force_imm_8bit_1:
;                 if (cpu_level == 0 && assembler_pass > 1) goto mismatch;
@$453:
		cmp byte [_cpu_level], 0
		je @$455
@$454:
		jmp near @$433
@$455:
		cmp word [_assembler_pass], 1
		jbe @$457
@$456:
		jmp near @$429
@$457:
		jmp @$454

;                 goto force_imm_8bit;
;             }
;         } else if (dc == 'x') {  /* Minimum `cpu 186' is needed. */
@$458:
		cmp bl, 0x78
		jne @$460

;             if (cpu_level == 0) goto mismatch;
		cmp byte [_cpu_level], 0
@$459:
		je @$456
		jmp @$451

;         } else if (dc == 'y') {  /* Minimum `cpu 286' is needed. */
@$460:
		cmp bl, 0x79
		jne @$461

;             if (cpu_level < 2) goto mismatch;
		cmp byte [_cpu_level], 2
		jb @$456
		jmp @$451

;         } else if (dc == '!') {
@$461:
		cmp bl, 0x21
		jne @$462

;             if (islabel(*p)) goto mismatch;
		mov al, byte [si]
		call near islabel_
		test ax, ax
		jne @$456
		jmp near @$353

;             continue;
;         } else if (dc == '.') {
@$462:
		cmp bl, 0x2e
		jne @$463

;             p = avoid_spaces(p);
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;             if (*p == ',') goto mismatch;  /* Another pattern with ',' will match. Used in `imul'. */
		cmp byte [si], 0x2c
		jmp @$459

;         } else if (SUB_U(dc, 'a') <= 'z' - 'a' + 0U) {  /* Unexpected special (lowercase) character in pattern. */
@$463:
		mov dx, ax
		sub dx, 0x61
		cmp dx, 0x19
		jbe @$468

;             goto decode_internal_error;
;         } else if (dc == ',') {
		cmp bl, 0x2c
		jne @$464

;             p = avoid_spaces(p);
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;             if (*p != ',') goto mismatch;
		cmp bl, byte [si]
		jne @$456

;             p = avoid_spaces(p + 1);
		inc ax
		call near avoid_spaces_
		mov si, ax

;             continue;
		jmp near @$353

;         } else {
;             if ((SUB_U(dc, 'A') <= 'Z' - 'A' + 0U ? *p & ~32 : *p) != dc) goto mismatch;  /* Case insensitive match for uppercase letters in pattern. */
@$464:
		sub ax, 0x41
		cmp ax, 0x19
		ja @$465
		mov al, byte [si]
		and ax, 0xdf
		jmp @$466
@$465:
		mov al, byte [si]
		xor ah, ah
@$466:
		xor bh, bh
		cmp ax, bx
		jne @$456

;             p++;
		inc si

;             continue;
		jmp near @$353

;         }
;         if (p == NULL) goto mismatch;
;     }
;     goto do_encode;
;   mismatch:
;     while ((dc = *pattern_and_encode++) != '\0' && dc != '-' /* ALSO */) {}
;     if (dc == '\0') return NULL;
@$467:
		mov si, word [bp-0xa]

;     p = p0;
;     goto next_pattern;
		jmp near @$352
@$468:
		mov dx, word [bp-0x12]
		mov ax, @$957
		call near message1str_
		mov ax, 2
		mov ah, 0x4c
		int 0x21

; 
;   do_encode:
;     /*
;      ** Instruction properly matched, now generate binary
;      */
;     if (instruction_offset_width == 3) {
@$469:
		cmp byte [_instruction_offset_width], 3
		jne @$470

;         add_wide_instr_in_pass_1(0);  /* Call it only once per encode. Calling it once per match would add extra values in case of mismatch. */
		xor ax, ax
		call near add_wide_instr_in_pass_1_

;     }
;     if (do_add_wide_imm8) {
@$470:
		cmp byte [bp-6], 0
		je @$471

;         add_wide_instr_in_pass_1(1);  /* Call it only once per encode. Calling it once per match would add extra values in case of mismatch. 1 so that it doesn't conflict with the wideness of instruction_offset. */
		mov ax, 1
		call near add_wide_instr_in_pass_1_

;     }
;     if (do_opt_lea_now) {
@$471:
		cmp byte [bp-8], 0
		je @$472

;         instruction_addressing_segment = 0;  /* Ignore the segment part of the effective address, it doesn't make a difference for `lea'. */
;         if (0) DEBUG2("lea ia=0x%02x iow=%d\r\n", instruction_addressing, instruction_offset_width);
;         if (instruction_addressing == 0x06 /* [immediate] */) {
		mov byte [_instruction_addressing_segment], 0

		mov al, byte [_instruction_addressing]
		cmp al, 6
		jne @$473

;             emit_byte(0xb8 | instruction_register);
		mov al, byte [_instruction_register]
		or al, 0xb8
		xor ah, ah
		call near emit_byte_func_

;             pattern_and_encode = "j";
		mov word [bp-0x14], @$953

; #if 1  /* Convert e.g. `lea cx, [ex]' to `mov cx, bx', of the same size. */
;         } else if (instruction_addressing == 0x04 /* [SI] */) {
@$472:
		jmp @$478
@$473:
		cmp al, 4
		jne @$474

;             c = 0xc0 | 6 << 3;
		mov word [bp-0xc], 0xf0

;             goto emit_lea_mov;
		jmp @$477

;         } else if (instruction_addressing == 0x05 /* [DI] */) {
@$474:
		cmp al, 5
		jne @$475

;             c = 0xc0 | 7 << 3;
		mov word [bp-0xc], 0xf8

;             goto emit_lea_mov;
		jmp @$477

;         } else if (instruction_addressing == 0x07 /* [BX] */) {
@$475:
		cmp al, 7
		jne @$476

;             c = 0xc0 | 3 << 3;
		mov word [bp-0xc], 0xd8

;             goto emit_lea_mov;
		jmp @$477

; #endif
;         } else if (instruction_addressing == 0x46 && instruction_offset == 0 && instruction_offset_width == 1 /* [BP] */) {
@$476:
		cmp al, 0x46
		jne @$478
		cmp word [_instruction_offset], 0
		jne @$478
		cmp byte [_instruction_offset_width], 1
		jne @$478

;             c = 0xc0 | 5 << 3;
		mov word [bp-0xc], 0xe8

;           emit_lea_mov:
;             emit_byte(0x89);
@$477:
		mov ax, 0x89
		call near emit_byte_func_

;             emit_byte(c | instruction_register);
		mov al, byte [_instruction_register]
		xor ah, ah
		or ax, word [bp-0xc]
		call near emit_byte_func_

;             goto done;
		jmp near @$534

;         }
;     }
;     if (instruction_addressing_segment) {
@$478:
		cmp byte [_instruction_addressing_segment], 0
		je @$485

;         if (do_opt_segreg) {
		cmp byte [_do_opt_segreg], 0
		je @$484

;             if ((unsigned char)instruction_addressing >= 0xc0) goto omit_segreg;  /* If there is a register (rather than effective address) in the addressing. */
		mov al, byte [_instruction_addressing]
		cmp al, 0xc0
		jae @$485

;             c = instruction_addressing;
		xor ah, ah

;             if (c == 0x06 /* [immesiate] */) {
		cmp ax, 6
		jne @$479

;                 c = 0x3e /* DS */;
		mov word [bp-0xc], 0x3e

;             } else {
		jmp @$483

;                 c &= 7;
@$479:
		and al, 7
		mov word [bp-0xc], ax

;                 c = (c == 0x02 || c == 0x03 || c == 0x06) ? 0x36 /* SS */ : 0x3e /* DS */;  /* If it contains BP, then it's [SS:...] by default, otherwise [DS:...]. */
		cmp ax, 2
		je @$480
		cmp ax, 3
		je @$480
		cmp ax, 6
		jne @$481
@$480:
		mov ax, 0x36
		jmp @$482
@$481:
		mov ax, 0x3e
@$482:
		mov word [bp-0xc], ax

;             }
;             if ((unsigned char)instruction_addressing_segment == (unsigned char)c) goto omit_segreg;  /* If the default segment register is used. */
@$483:
		mov al, byte [_instruction_addressing_segment]
		cmp al, byte [bp-0xc]
		je @$485

;         }
;         emit_byte(instruction_addressing_segment);
@$484:
		mov al, byte [_instruction_addressing_segment]
		xor ah, ah
		call near emit_byte_func_

;       omit_segreg: ;
;     }
;     for (error_base = pattern_and_encode; (dc = *pattern_and_encode++) != '\0' && dc != '-' /* ALSO */;) {
@$485:
		mov bx, word [bp-0x14]
		mov word [bp-0x12], bx
@$486:
		mov bx, word [bp-0x14]
		mov bl, byte [bx]
		inc word [bp-0x14]
		test bl, bl
		je @$487
		cmp bl, 0x2d
		je @$487

;         dw = 0;
		xor al, al
		mov byte [bp-2], al

;         if (dc == '+') {  /* Instruction is a prefix. */
		cmp bl, 0x2b
		jne @$488

;             return p;  /* Don't call check_end(p). */
		mov ax, si
		jmp near @$339
@$487:
		jmp near @$534

;         } else if ((unsigned char)dc <= 'F' + 0U) {  /* Byte: uppercase hex. */
@$488:
		cmp bl, 0x46
		ja @$491

;             c = dc - '0';
		xor bh, bh
		sub bx, 0x30
		mov word [bp-0xc], bx

;             if (c > 9) c -= 7;
		cmp bx, 9
		jle @$489
		sub word [bp-0xc], 7

;             dc = *pattern_and_encode++ - '0';
@$489:
		mov di, word [bp-0x14]
		inc word [bp-0x14]
		mov bl, byte [di]
		sub bl, 0x30

;             if (dc > 9) dc -= 7;
		cmp bl, 9
		jbe @$490
		sub bl, 7

;             c = (c << 4) | dc;
@$490:
		mov cl, 4
		mov ax, word [bp-0xc]
		shl ax, cl
		xor bh, bh
		or ax, bx
		mov word [bp-0xc], ax

;             if ((unsigned char)(c - 0x88) <= (unsigned char)(0x8b - 0x88) && pattern_and_encode == error_base + 2 && instruction_addressing == 6 && instruction_register == 0) {
		mov al, byte [bp-0xc]
		sub al, 0x88
		cmp al, 3
		ja @$492
		mov ax, word [bp-0x12]
		inc ax
		inc ax
		cmp ax, word [bp-0x14]
		jne @$492
		cmp byte [_instruction_addressing], 6
		jne @$492
		cmp byte [_instruction_register], 0
		jne @$492

;                 /* Optimization:
;                  *
;                  * 88063412  mov [0x1234],al  "k,r 89drd"  --> A23412
;                  * 89063412  mov [0x1234],ax  "k,r 89drd"  --> A33412
;                  * 8A063412  mov al,[0x1234]  "q,j 8Adrd"  --> A03412
;                  * 8B063412  mov ax,[0x1234]  "r,k 8Bdrd"  --> A13412
;                  */
;                 pattern_and_encode = "";
		mov word [bp-0x14], @$929

;                 dw = 2;
		mov al, 2
		mov byte [bp-2], al

;                 c += 0xa0 - 0x88;
		add word [bp-0xc], 0x18

;                 c ^= 2;
		xor byte [bp-0xc], al

;             } else if ((unsigned char)(c - 0x70) <= 0xfU && qualifier == 0 && (((uvalue_t)instruction_value + 0x80) & ~0xffU) && !has_undefined
		jmp near @$531
@$491:
		jmp @$494
@$492:
		mov al, byte [bp-0xc]
		sub al, 0x70
		cmp al, 0xf
		ja @$493
		cmp word [bp-0xe], 0
		jne @$493
		mov ax, word [_instruction_value]
		add ax, 0x80
		test ah, 0xff
		je @$493
		cmp byte [_has_undefined], 0
		jne @$500

;                       ) {  /* Generate 5-byte `near' version of 8-bit relative conditional jump with an inverse. */
;                 emit_byte(c ^ 1);  /* Conditional jump with negated condition. */
		mov ax, word [bp-0xc]
		xor al, 1
		call near emit_byte_func_

;                 emit_byte(3);  /* Skip next 3 bytes if negated condition is true. */
		mov ax, 3
		call near emit_byte_func_

;                 c = 0xe9;  /* `jmp near', 2 bytes will follow for encode "b". */
		mov word [bp-0xc], 0xe9

;                 pattern_and_encode = "b";
		mov word [bp-0x14], @$954

;                 instruction_value -= 3;  /* Jump source address (0xe9) is 3 bytes larger than previously anticipated. */
		add word [_instruction_value], 0xfffd
		adc word [_instruction_value+2], 0xffff

;             }
@$493:
		jmp @$500

;         } else if (dc == 'i') {  /* 8-bit immediate. */
@$494:
		cmp bl, 0x69
		jne @$496

;             c = instruction_value;
@$495:
		mov ax, word [_instruction_value]
		jmp @$504

;         } else if (dc == 'k') {  /* 8-bit immediate, but only if is_imm_8bit. */
@$496:
		cmp bl, 0x6b
		jne @$497

;             if (!is_imm_8bit) continue;
		cmp byte [bp-4], 0
		jne @$495
		jmp near @$486

;             c = instruction_value;
;         } else if (dc == 'j') {  /* 16-bit immediate, maybe optimized to 8 bits. */
@$497:
		cmp bl, 0x6a
		jne @$501

;             c = instruction_value;
		mov ax, word [_instruction_value]
		mov word [bp-0xc], ax

;             if (!is_imm_8bit) {
		cmp byte [bp-4], 0
		jne @$505

;                 instruction_offset = instruction_value >> 8;
		mov dx, word [_instruction_value+2]
		mov cx, 8
@$498:
		sar dx, 1
		rcr ax, 1
		loop @$498
@$499:
		mov word [_instruction_offset], ax

;                 dw = 1;  /* TODO(pts): Optimize this and below as ++dw. */
		mov byte [bp-2], 1

;             }
@$500:
		jmp @$505

;         } else if (dc == 's') {
@$501:
		cmp bl, 0x73
		jne @$506

;             c = is_imm_8bit ? (char)0x83 : (char)0x81;
		cmp byte [bp-4], 0
		je @$502
		mov al, 0x83
		jmp @$503
@$502:
		mov al, 0x81
@$503:
		xor ah, ah
@$504:
		mov word [bp-0xc], ax
@$505:
		jmp near @$531

;         } else if (dc == 'g') {  /* Used in byte shifts with immediate. */
@$506:
		cmp bl, 0x67
		jne @$508

;             c = is_imm_8bit ? (char)0xc0 : (char)0xd0;
		cmp byte [bp-4], 0
		je @$507
		mov al, 0xc0
		jmp @$503
@$507:
		mov al, 0xd0
		jmp @$503

;         } else if (dc == 'h') {  /* Used in words shifts with immediate. */
@$508:
		cmp bl, 0x68
		jne @$510

;             c = is_imm_8bit ? (char)0xc1 : (char)0xd1;
		cmp byte [bp-4], 0
		je @$509
		mov al, 0xc1
		jmp @$503
@$509:
		mov al, 0xd1
		jmp @$503

;         } else if (dc == 'l') {  /* Used in `push imm'. */
@$510:
		cmp bl, 0x6c
		jne @$512

;             c = is_imm_8bit ? (char)0x6a : (char)0x68;
		cmp byte [bp-4], 0
		je @$511
		mov al, 0x6a
		jmp @$503
@$511:
		mov al, 0x68
		jmp @$503

;         } else if (dc == 'm') {  /* Used in 3rd, immediate argument for 3-argument `imul'. */
@$512:
		cmp bl, 0x6d
		jne @$514

;             c = is_imm_8bit ? (char)0x6b : (char)0x69;
		cmp byte [bp-4], 0
		je @$513
		mov al, 0x6b
		jmp @$503
@$513:
		mov al, 0x69
		jmp @$503

;         } else if (dc == 'a') {  /* Address for jump, 8-bit. */
@$514:
		cmp bl, 0x61
		jne @$517

;             is_address_used = 1;
		mov byte [_is_address_used], 1

;             if (assembler_pass > 1 && (((uvalue_t)instruction_value + 0x80) & ~0xffU)) {
		cmp word [_assembler_pass], 1
		ja @$516
@$515:
		jmp near @$495
@$516:
		mov ax, word [_instruction_value]
		add ax, 0x80
		test ah, 0xff
		je @$515

;                 jump_range_bits |= 1;
		or byte [_jump_range_bits], 1

;                 if (jump_range_bits & 2) {  /* Only report it in the last pass. See xtest/jmpopt.nasm for an example when it's not an error. */
		test byte [_jump_range_bits], 2
		je @$515

;                     MESSAGE(1, "short jump is out of range");  /* Same error message as NASM 0.98.39. */
		mov ax, @$955
		call near message_

;                 }
;                 if (0) DEBUG3("short_jump by=0x%x value=%d @0x%x\n", instruction_value, instruction_value, current_address);
;             }
		jmp @$515

;             c = instruction_value;
;         } else if (dc == 'b') {  /* Address for jump, 16-bit. */
@$517:
		cmp bl, 0x62
		jne @$519

;             is_address_used = 1;
		mov byte [_is_address_used], 1

;             /*if (assembler_pass > 1 && (((uvalue_t)instruction_value + 0x8000U) & ~0xffffU)) {}*/  /* This check is too strict, e.g. from offset 3 it's possible to jump to 0xffff, but this one reports an error, because of the >= 32 KiB difference. */
;             if (assembler_pass > 1 && (((uvalue_t)instruction_value + (uvalue_t)0x10000UL) & (uvalue_t)~0x1ffffUL)) {  /* This check is a bit lenient. */
		cmp word [_assembler_pass], 1
		jbe @$518
		mov ax, word [_instruction_value]
		add ax, 0
		mov ax, word [_instruction_value+2]
		adc ax, 1
		test ax, 0xfffe
		je @$518

;                 MESSAGE(1, "near jump too long");
		mov ax, @$956
		call near message_

;             }
;             c = instruction_value;
@$518:
		mov ax, word [_instruction_value]
		mov word [bp-0xc], ax

;             instruction_offset = c >> 8;
		mov al, byte [bp-0xb]
		cbw
		jmp near @$499

;             dw = 1;
;         } else if (dc == 'f') {  /* Far (16+16 bit) jump or call. */
@$519:
		cmp bl, 0x66
		jne @$521

;             emit_byte(instruction_value);
		mov ax, word [_instruction_value]
		call near emit_byte_func_

;             c = instruction_value >> 8;
		mov ax, word [_instruction_value]
		mov dx, word [_instruction_value+2]
		mov cx, 8
@$520:
		sar dx, 1
		rcr ax, 1
		loop @$520
		mov word [bp-0xc], ax

;             instruction_offset = segment_value;
		mov ax, word [@$segment_value]
		mov word [_instruction_offset], ax

;             dw = 2;
		mov byte [bp-2], 2

;         } else if (dc == 'e') {  /* 16-bit instruction_offset, for `enter'. */
		jmp near @$531
@$521:
		cmp bl, 0x65
		jne @$522

;             emit_byte(instruction_offset);
		mov ax, word [_instruction_offset]
		call near emit_byte_func_

;             c = instruction_offset >> 8;
		mov al, byte [_instruction_offset+1]
		jmp near @$503

;         } else {  /* Binary. */
;             c = 0;
@$522:
		xor ah, ah
		mov word [bp-0xc], ax

;             --pattern_and_encode;
;             for (bit = 0; bit < 8;) {
		mov word [bp-0x10], ax

		dec word [bp-0x14]
		jmp @$527

;                 dc = *pattern_and_encode++;
;                 if (dc == 'z') {  /* Zero. */
;                     bit++;
;                 } else if (dc == 'o') {  /* One. */
;                     c |= 0x80 >> bit;
;                     bit++;
;                 } else if (dc == 'r') {  /* Register field. */
@$523:
		mov ax, word [bp-0x10]
		add ax, 3
		cmp bl, 0x72
		jne @$524

;                     c |= instruction_register << (5 - bit);
		mov cx, 5
		sub cx, word [bp-0x10]
		mov dl, byte [_instruction_register]
		xor dh, dh
		shl dx, cl
		jmp @$528

;                     bit += 3;
;                 } else if (dc == 'd') {  /* Addressing field. */
@$524:
		cmp bl, 0x64
		je @$525
		jmp near @$468

;                     if (bit == 0) {
@$525:
		cmp word [bp-0x10], 0
		jne @$530

;                         c |= instruction_addressing & 0xc0;
		mov al, byte [_instruction_addressing]
		and al, 0xc0
		xor ah, ah
		or word [bp-0xc], ax

;                         bit += 2;
		add word [bp-0x10], 2

;                     } else {
@$526:
		cmp word [bp-0x10], 8
		jge @$531
@$527:
		mov bx, word [bp-0x14]
		mov bl, byte [bx]
		inc word [bp-0x14]
		mov ax, word [bp-0x10]
		inc ax
		cmp bl, 0x7a
		je @$529
		cmp bl, 0x6f
		jne @$523
		mov cl, byte [bp-0x10]
		mov dx, 0x80
		sar dx, cl
@$528:
		or word [bp-0xc], dx
@$529:
		mov word [bp-0x10], ax
		jmp @$526

;                         c |= instruction_addressing & 0x07;
@$530:
		mov dl, byte [_instruction_addressing]
		and dl, 7
		xor dh, dh
		or word [bp-0xc], dx

;                         bit += 3;
;                         dw = instruction_offset_width;  /* 1, 2 or 3. 3 means 2 for dw. */
		mov dl, byte [_instruction_offset_width]
		mov byte [bp-2], dl
		jmp @$529

;                     }
;                 } else { decode_internal_error:  /* assert(...). */
;                     MESSAGE1STR(1, "ooops: decode (%s)", error_base);
;                     exit(2);
;                     break;
;                 }
;             }
;         }
;         emit_byte(c);
@$531:
		mov ax, word [bp-0xc]
		call near emit_byte_func_

;         if (dw != 0) {
		cmp byte [bp-2], 0
		jne @$533
@$532:
		jmp near @$486

;             emit_byte(instruction_offset);
@$533:
		mov ax, word [_instruction_offset]
		call near emit_byte_func_

;             if (dw > 1) emit_byte(instruction_offset >> 8);
		cmp byte [bp-2], 1
		jbe @$532
		mov al, byte [_instruction_offset+1]
		xor ah, ah
		call near emit_byte_func_
		jmp @$532

;         }
;     }
;   done:
;     return check_end(p);
@$534:
		mov ax, si
		call near check_end_

; }
		jmp near @$339

; 
; /*
;  ** Separate a portion of entry up to the first space.
;  ** First word gets copied to `instr_name' (silently truncated if needed),
;  ** and `p' is advanced after it, and the new p is returned.
;  */
; static const char *separate(const char *p) {
separate_:
		push bx
		push dx
		push si
		mov bx, ax

;     char *p2;
;     char *instr_name_end = instr_name + sizeof(instr_name) - 1;
		mov dx, _instr_name+9

; 
;     for (; *p == ' '; ++p) {}
@$535:
		cmp byte [bx], 0x20
		jne @$536
		inc bx
		jmp @$535

;     p2 = instr_name;
@$536:
		mov si, _instr_name

;     for (;;) {
;         if (p2 == instr_name_end) {
@$537:
		cmp si, dx
		jne @$539

;             for (; *p && *p != ' '; ++p) {}  /* Silently truncate instr_name. */
@$538:
		mov al, byte [bx]
		test al, al
		je @$540
		cmp al, 0x20
		je @$540
		inc bx
		jmp @$538

;             break;
;         } else if (*p && *p != ' ') {
@$539:
		mov al, byte [bx]
		test al, al
		je @$540
		cmp al, 0x20
		je @$540

;             *p2++ = *p++;
		mov byte [si], al
		inc bx
		inc si

;         } else {
;             break;
;         }
;     }
		jmp @$537

;     *p2 = '\0';
@$540:
		mov byte [si], 0

;     for (; *p == ' '; ++p) {}
@$541:
		cmp byte [bx], 0x20
		je @$542
		jmp near @$118
@$542:
		inc bx
		jmp @$541

;     return p;
; }
; 
; static UNALIGNED char message_buf[512];
; 
; static void message_flush(struct bbprintf_buf *bbb) {
message_flush_:
		push bx
		push cx
		push dx

;     const int size = message_bbb.p - message_buf;
		mov cx, word [_message_bbb+4]
		sub cx, _message_buf

;     (void)bbb;  /* message_bbb. */
;     if (size) {
		jne @$544
@$543:
		jmp near @$90

;         if (message_bbb.data) (void)!write(2 /* stderr */, message_buf, size);
@$544:
		cmp word [_message_bbb+6], 0
		je @$545
		mov bx, cx
		mov dx, _message_buf
		mov ax, 2
		call near write_

;         message_bbb.p = message_buf;
@$545:
		mov word [_message_bbb+4], _message_buf

;         if (listing_fd >= 0) {
		mov ax, word [_listing_fd]
		test ax, ax
		jl @$543

;             if (write(listing_fd, message_buf, size) != size) {
		mov bx, cx
		mov dx, _message_buf
		call near write_
		cmp ax, cx
		je @$543

;                 listing_fd = -1;
		mov word [_listing_fd], 0xffff

;                 MESSAGE(1, "error writing to listing file");
		mov ax, @$958
		call near message_

;                 exit(3);
		mov ax, 3
		mov ah, 0x4c
		int 0x21

;             }
;         }
;     }
; }
; 
; /* data = 0 means write to listing_fd only, = 1 means write to stderr + listing_fd. */
; struct bbprintf_buf message_bbb = { message_buf, message_buf + sizeof(message_buf), message_buf, 0, message_flush };
; 
; static const char *filename_for_message;
; 
; /*
;  ** Generate a message
;  */
; #if CONFIG_SUPPORT_WARNINGS
; static void message_start(int error)
; #else
; static void message_start(void)
message_start_:
		push dx

; #endif
; {
;     const char *msg_prefix;
;     if (!message_bbb.data) {
		mov ax, word [_message_bbb+6]
		test ax, ax
		jne @$546

;         message_flush(NULL);  /* Flush listing_fd. */
		call near message_flush_

;         message_bbb.data = (void*)1;
		mov word [_message_bbb+6], 1

;     }
; #if CONFIG_SUPPORT_WARNINGS
;     if (error) {
; #endif
;         msg_prefix = "error: ";
@$546:
		mov dx, @$959

;         if (GET_UVALUE(++errors) == 0) --errors;  /* Cappped at max uvalue_t. */
		add word [_errors], 1
		adc word [_errors+2], 0
		mov ax, word [_errors+2]
		or ax, word [_errors]
		jne @$547
		add word [_errors], 0xffff
		adc word [_errors+2], 0xffff

; #if CONFIG_SUPPORT_WARNINGS
;     } else {
;         msg_prefix = "warning: ";
;         if (GET_UVALUE(++warnings) == 0) --warnings;  /* Cappped at max uvalue_t. */
;     }
; #endif
;     if (line_number) {
@$547:
		mov ax, word [_line_number+2]
		or ax, word [_line_number]
		je @$548

;         bbprintf(&message_bbb, "%s:%u: %s", filename_for_message, (unsigned)line_number, msg_prefix);
		push dx
		push word [_line_number]
		push word [_filename_for_message]
		mov ax, @$960
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 0xa

;     } else {
		pop dx
		ret

;         bbprintf(&message_bbb, msg_prefix);  /* "%s" not needed, no `%' patterns in msg_prefix. */
@$548:
		push dx
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 4

;     }
; }
		pop dx
		ret

; 
; static void message_end(void) {
message_end_:
		mov ax, @$961
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 4

;     /* We must use \r\n, because this will end up on stderr, and on DOS
;      * with O_BINARY, just a \n doesn't break the line properly.
;      */
;     bbprintf(&message_bbb, "\r\n");
;     message_flush(NULL);
		xor ax, ax
		call near message_flush_

;     message_bbb.data = (void*)0;  /* Write subsequent bytes to listing_fd only (no stderr). */
		xor ax, ax
		mov word [_message_bbb+6], ax

; }
		ret

; 
; #if CONFIG_SUPPORT_WARNINGS
; static void message(int error, const char *message)
; #else
; static void message(const char *message)
message_:
		push dx
		mov dx, ax

; #endif
; {
;     MESSAGE_START(error);
		call near message_start_

;     bbprintf(&message_bbb, "%s", message);
		push dx
		mov dx, @$962
		push dx
		mov dx, _message_bbb
		push dx
		call near bbprintf_
		add sp, 6

;     message_end();
		call near message_end_

; }
		pop dx
		ret

; 
; /*
;  ** Shortcut to make the executable program smaller for __DOSMC__.
;  */
; #if CONFIG_SUPPORT_WARNINGS
; static void message1str(int error, const char *pattern, const char *data)
; #else
; static void message1str(const char *pattern, const char *data)
message1str_:
		push bx
		mov bx, ax

; #endif
; {
;     MESSAGE_START(error);
		call near message_start_

;     bbprintf(&message_bbb, pattern, data);
		push dx
		push bx
		mov dx, _message_bbb
		push dx
		call near bbprintf_
		add sp, 6

;     message_end();
		call near message_end_

; }
		pop bx
		ret

; 
; /*
;  ** Process an instruction `p' (starting with mnemonic name).
;  */
; static void process_instruction(const char *p) {
process_instruction_:
		push bx
		push cx
		push dx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		mov bx, ax

;     const char *p2 = NULL, *p3;
;     char c;
; 
;     p = separate(p);
		call near separate_
		mov bx, ax

;     if (casematch(instr_name, "DB")) {  /* Define 8-bit byte. */
		mov dx, @$963
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$556

;         while (1) {
;             p = avoid_spaces(p);
@$549:
		mov ax, bx
		call near avoid_spaces_
		mov si, ax
		mov bx, ax

;             if (*p == '\'' || *p == '"') {    /* ASCII text, quoted. */
		mov al, byte [si]
		cmp al, 0x27
		je @$550
		cmp al, 0x22
		jne @$557

;                 c = *p++;
@$550:
		mov al, byte [bx]
		mov byte [bp-2], al
		inc bx

;                 for (p2 = p; *p2 != '\0' && *p2 != c; ++p2) {}
		mov si, bx
@$551:
		mov al, byte [si]
		test al, al
		je @$552
		cmp al, byte [bp-2]
		je @$552
		inc si
		jmp @$551

;                 p3 = p2;
@$552:
		mov cx, si

;                 if (*p3 == '\0') {
		cmp byte [si], 0
		jne @$553

;                     MESSAGE(1, "Missing close quote");
		mov ax, @$944
		call near message_

;                 } else {
		jmp @$555

;                     p3 = avoid_spaces(p3 + 1);
@$553:
		lea ax, [si+1]
		call near avoid_spaces_
		mov di, ax
		mov cx, ax

;                     if (*p3 != ',' && *p3 != '\0') { --p; goto db_expr; }
		mov al, byte [di]
		cmp al, 0x2c
		je @$554
		test al, al
		je @$554
		dec bx
		jmp @$557

;                     emit_bytes(p, p2 - p);
@$554:
		mov dx, si
		sub dx, bx
		mov ax, bx
		call near emit_bytes_

;                 }
;                 p = p3;
@$555:
		mov bx, cx

;             } else { db_expr:
		jmp @$560
@$556:
		jmp @$564

;                 p = match_expression(p);
@$557:
		mov ax, bx
		call near match_expression_
		mov bx, ax

;                 if (p == NULL) {
		test ax, ax
		jne @$559

;                     MESSAGE(1, "Bad expression");
@$558:
		mov ax, @$964
		call near message_

;                     break;
		jmp near @$87

;                 }
;                 emit_byte(instruction_value);
@$559:
		mov ax, word [_instruction_value]
		call near emit_byte_func_

;             }
;             if (*p == ',') {
@$560:
		cmp byte [bx], 0x2c
		jne @$563

;                 p++;
		lea ax, [bx+1]
		call near avoid_spaces_
		mov si, ax
		mov bx, ax

;                 p = avoid_spaces(p);
;                 if (*p == '\0') break;
		cmp byte [si], 0
		jne @$562
@$561:
		jmp near @$87
@$562:
		jmp near @$549

;             } else {
;                 check_end(p);
@$563:
		mov ax, bx
		call near check_end_

;                 break;
		jmp @$561

;             }
;         }
;         return;
;     } else if ((c = casematch(instr_name, "DW")) != 0 /* Define 16-bit word. */
@$564:
		mov dx, @$965
		mov ax, _instr_name
		call near casematch_
		mov byte [bp-2], al
		test al, al
		jne @$565
		mov dx, @$966
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$568

; #if CONFIG_VALUE_BITS == 32
;                || casematch(instr_name, "DD")  /* Define 32-bit quadword. */
;               ) {
; #endif
;         while (1) {
;             p = match_expression(p);
@$565:
		mov ax, bx
		call near match_expression_
		mov bx, ax

;             if (p == NULL) {
		test ax, ax
		je @$558

;                 MESSAGE(1, "Bad expression");
;                 break;
;             }
;             emit_byte(instruction_value);
		mov ax, word [_instruction_value]
		call near emit_byte_func_

;             emit_byte(instruction_value >> 8);
		mov ax, word [_instruction_value]
		mov dx, word [_instruction_value+2]
		mov cx, 8
@$566:
		sar dx, 1
		rcr ax, 1
		loop @$566
		call near emit_byte_func_

; #if CONFIG_VALUE_BITS == 32
;             if (!c) {
		cmp byte [bp-2], 0
		jne @$567

;                 emit_byte(instruction_value >> 16);
		mov ax, word [_instruction_value+2]
		call near emit_byte_func_

;                 emit_byte(instruction_value >> 24);
		mov al, byte [_instruction_value+3]
		cbw
		call near emit_byte_func_

;             }
; #endif
;             if (*p == ',') {
@$567:
		cmp byte [bx], 0x2c
		jne @$563

;                 p++;
		lea ax, [bx+1]
		call near avoid_spaces_
		mov si, ax
		mov bx, ax

;                 p = avoid_spaces(p);
;                 if (*p == '\0') break;
		cmp byte [si], 0
		jne @$565
		jmp @$561

;                 continue;
;             }
;             check_end(p);
;             break;
;         }
;         return;
;     }
;     while (instr_name[0]) {   /* Match against instruction set. */
@$568:
		cmp byte [_instr_name], 0
		je @$561

;         p2 = instruction_set;
		mov si, _instruction_set

;         for (;;) {
;             if (*p2 == '\0') {
@$569:
		cmp byte [si], 0
		jne @$570

; #if CONFIG_SPLIT_INSTRUCTION_SET
;                 if (p2 == instruction_set_nul) {
;                     p2 = instruction_set2;
;                     continue;
;                 }
; #endif
;                 MESSAGE1STR(1, "Unknown instruction '%s'", instr_name);
		mov dx, _instr_name
		mov ax, @$967
		call near message1str_

;                 goto after_matches;
		jmp near @$87

;             }
;             p3 = p2;
@$570:
		mov cx, si

;             while (*p2++ != '\0') {}  /* Skip over instruction name. */
@$571:
		mov di, si
		inc si
		cmp byte [di], 0
		jne @$571

;             if (casematch(instr_name, p3)) break;  /* Match actual instruction mnemonic name (instr_name) against candidate from instruction_set (p2). */
		mov dx, cx
		mov ax, _instr_name
		call near casematch_
		test al, al
		jne @$573

;             while (*p2++ != '\0') {}  /* Skip over pattern_and_encode. */
@$572:
		mov di, si
		inc si
		cmp byte [di], 0
		jne @$572
		jmp @$569

;         }
;         p3 = p;
;         p = match(p, p2);
@$573:
		mov dx, si
		mov ax, bx
		call near match_

;         if (p == NULL) {
		test ax, ax
		jne @$574

;             MESSAGE_START(1);
		call near message_start_

;             bbprintf(&message_bbb, "Error in instruction '%s %s'", instr_name, p3);
		push bx
		mov ax, _instr_name
		push ax
		mov ax, @$968
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 8

;             message_end();
		call near message_end_

;             break;
		jmp near @$87

;         }
;         p = separate(p);
@$574:
		call near separate_
		mov bx, ax

;     }
		jmp @$568

;   after_matches: ;
; }
; 
; /*
;  ** Reset current address.
;  ** Called anytime the assembler needs to generate code.
;  */
; static void reset_address(void) {
reset_address_:
		push dx

;     current_address = start_address = default_start_address;
		mov ax, word [_default_start_address]
		mov dx, word [_default_start_address+2]
		mov word [_start_address], ax
		mov word [_start_address+2], dx
		mov word [_current_address], ax
		mov word [_current_address+2], dx

; }
		pop dx
		ret

; 
; /*
;  ** Creates label named `name' with value `instruction_value'.
;  */
; static void create_label(const char *name) {
create_label_:
		push bx
		push cx
		push dx
		push si
		push di
		mov di, ax

;     struct label MY_FAR *last_label = find_label(name);
		mov dx, ds
		call near find_label_
		mov si, ax
		mov cx, dx
		mov bx, ax
		mov ax, dx

; #if 0 && DEBUG
;     if (name[0] == '.' && name[1] == '.' && name[2] == '@' && name[3] == '@') {
;         DEBUG3("create_label name=(%s) value=0x%x pass=%u\r\n", name, (unsigned)instruction_value, (unsigned)assembler_pass);
;     }
; #endif
;     if (assembler_pass <= 1) {
		cmp word [_assembler_pass], 1
		ja @$579

;         if (last_label == NULL) {
		test dx, dx
		jne @$575
		test si, si
		jne @$575

;             last_label = define_label(name, instruction_value);
		mov bx, word [_instruction_value]
		mov cx, word [_instruction_value+2]
		mov ax, di
		call near define_label_

;         } else if (RBL_IS_DELETED(last_label)) {  /* This is possible if it is an %UNDEF-ined macro. */
		jmp near @$88
@$575:
		mov es, dx
		test byte [es:si+4], 0x10
		je @$577

;           do_undelete:
;             RBL_SET_DELETED_0(last_label);
@$576:
		mov es, ax
		and byte [es:bx+4], 0xef

;             last_label->value = instruction_value;
		mov dx, word [_instruction_value]
		mov cx, word [_instruction_value+2]

;         } else {
		jmp @$583

;             MESSAGE1STR(1, "Redefined label '%s'", name);
@$577:
		mov dx, di
		mov ax, @$969
@$578:
		call near message1str_

;         }
		jmp near @$88

;     } else {
;         if (last_label == NULL) {
@$579:
		test dx, dx
		jne @$580
		test si, si
		jne @$580

;             MESSAGE1STR(1, "oops: label '%s' not found", name);
		mov dx, di
		mov ax, @$970
		jmp @$578

;         } else if (RBL_IS_DELETED(last_label)) {  /* This is possible if it is an %undef-ined macro. */
@$580:
		mov es, dx
		test byte [es:si+4], 0x10
		jne @$576

;             goto do_undelete;
;         } else {
;             if (last_label->value != instruction_value) {
		mov dx, word [es:si+5]
		mov cx, word [es:si+7]
		cmp cx, word [_instruction_value+2]
		jne @$581
		cmp dx, word [_instruction_value]
		je @$582

; #if DEBUG
;                 /* if (0 && DEBUG && opt_level <= 1) { MESSAGE_START(1); bbprintf(&message_bbb, "oops: label '%s' changed value from 0x%x to 0x%x", last_label->name, (unsigned)last_label->value, (unsigned)instruction_value); message_end(); } */
;                 if (opt_level <= 1) DEBUG3("oops: label '%s' changed value from 0x%x to 0x%x\r\n", last_label->name, (unsigned)last_label->value, (unsigned)instruction_value);
; #endif
;                 have_labels_changed = 1;
@$581:
		mov byte [_have_labels_changed], 1

;             }
;             last_label->value = instruction_value;
@$582:
		mov dx, word [_instruction_value]
		mov cx, word [_instruction_value+2]
		mov es, ax
@$583:
		mov word [es:bx+5], dx
		mov word [es:bx+7], cx

;         }
;     }
		jmp near @$88

; }
; 
; static UNALIGNED char line_buf[512];
; typedef char assert_line_buf_size[sizeof(line_buf) >= 2 * MAX_SIZE];  /* To avoid too much copy per line in do_assembly(...). */
; 
; #if !CONFIG_CPU_UNALIGN
; struct guess_align_assembly_info_helper { off_t o; char c; };
; typedef char guess_align_assembly_info[sizeof(struct guess_align_assembly_info_helper) - sizeof(off_t)];
; #endif
; 
; struct assembly_info {
;     off_t file_offset;  /* Largest alignment first, to save size. */
;     uvalue_t level;  /* !! TODO(pts): Is using (forcing) 16 bits only make the code smaller for dosmc? */
;     uvalue_t avoid_level;
;     uvalue_t line_number;
;     char zero;  /* '\0'. Used by assembly_pop(...). */
;     char input_filename[1];  /* Longer, ASCIIZ (NUL-terminated). */
; };
; 
; /* A stack of files being assembled. The one at the beginning was specified
;  * in the command line, others were %include()d in order.
;  *
;  * Supports %INCLUDE depth of more than 21 on DOS with 8.3 filenames (no pathname).
;  */
; #if CONFIG_CPU_UNALIGN
; static UNALIGNED char assembly_stack[512];
; #else
; static struct assembly_info assembly_stack[(512 + sizeof(struct assembly_info) - 1) / sizeof(struct assembly_info)];
; #endif
; static struct assembly_info *assembly_p;  /* = (struct assembly_info*)assembly_stack; */
; 
; static struct assembly_info *assembly_push(const char *input_filename) {
assembly_push_:
		push bx
		push cx
		push dx
		push di
		mov dx, ax

;     const int input_filename_len = strlen(input_filename);
		call near strlen_
		mov di, ax

; #if !CONFIG_CPU_UNALIGN
;     int extra_nul_count = (sizeof(guess_align_assembly_info) - ((unsigned)(size_t)&((struct assembly_info*)0)->input_filename + input_filename_len + 1) % sizeof(guess_align_assembly_info)) % sizeof(guess_align_assembly_info);
; #endif
;     struct assembly_info *aip;
;     if ((size_t)(((char*)&assembly_p->input_filename + input_filename_len) - (char*)assembly_stack) >= sizeof(assembly_stack)) return NULL;  /* Out of assembly_stack memory. */
		mov bx, word [_assembly_p]
		lea ax, [bx+0x11]
		add ax, di
		sub ax, _assembly_stack
		cmp ax, 0x200
		jb @$584
		xor ax, ax
		jmp @$585

;     /* TODO(pts): In dosmc, can we generate better assembly code for this initialization? The `mov bx, [assembly_p]' instruction is repeated too much. */
;     assembly_p->level = 1;
@$584:
		mov word [bx+4], 1
		mov word [bx+6], 0

;     assembly_p->line_number = 0;
		mov bx, word [_assembly_p]
		mov word [bx+0xc], 0
		mov word [bx+0xe], 0

;     assembly_p->avoid_level = 0;
		mov bx, word [_assembly_p]
		mov word [bx+8], 0
		mov word [bx+0xa], 0

;     assembly_p->file_offset = 0;
		mov bx, word [_assembly_p]
		mov word [bx], 0
		mov word [bx+2], 0

;     assembly_p->zero = 0;
		mov bx, word [_assembly_p]
		mov byte [bx+0x10], 0

;     /* strcpy(...) would also work (there are no far pointers here), but we can save a few bytes if we avoid linking strcpy(...), for __DOSMC__. */
;     strcpy_far(assembly_p->input_filename, input_filename);
		mov cx, ds
		mov ax, word [_assembly_p]
		add ax, 0x11
		mov bx, dx
		mov dx, ds
		call near strcpy_far_

;     aip = assembly_p;
		mov ax, word [_assembly_p]

;     assembly_p = (struct assembly_info*)((char*)&assembly_p->input_filename + 1 + input_filename_len);
		mov dx, ax
		add dx, 0x12
		add dx, di
		mov word [_assembly_p], dx

; #if !CONFIG_CPU_UNALIGN
;     for (; extra_nul_count > 0; --extra_nul_count, *(char*)assembly_p = '\0', assembly_p = (struct assembly_info*)((char*)(assembly_p) + 1)) {}
; #endif
;     return aip;
; }
@$585:
		pop di
		jmp near @$90

; 
; static struct assembly_info *assembly_pop(struct assembly_info *aip) {
assembly_pop_:
		push bx

;     char *p;
;     if (aip == (struct assembly_info*)assembly_stack) return NULL;
		cmp ax, _assembly_stack
		jne @$586
		xor ax, ax
		pop bx
		ret

;     assembly_p = aip;
@$586:
		mov word [_assembly_p], ax

;     p = (char*)aip;
;     if (*--p != '\0') {
		mov bx, ax
		dec bx
		cmp byte [bx], 0
		jne @$588

; #if DEBUG
;         MESSAGE(1, "oops: pop from empty %include stack\n");
; #endif
;     } else {
; #if CONFIG_CPU_UNALIGN
;         --p;
@$587:
		dec bx

; #else
;         for (; *p == '\0'; --p) {}
; #endif
;         for (; *p != '\0'; --p) {}  /* Find ->zero with value '\0', preceding ->input_filename. */
		cmp byte [bx], 0
		jne @$587

;         aip = (struct assembly_info*)(p - (int)(size_t)&((struct assembly_info*)0)->zero);
		lea ax, [bx-0x10]

;     }
;     return aip;
; }
@$588:
		pop bx
		ret

; 
; #define MACRO_CMDLINE 1  /* Macro defined in the command-line with an INTVALUE. */
; #define MACRO_SELF 2  /* Macro defined in the assembly source as `%DEFINE NAME NAME', so itself. */
; #define MACRO_VALUE 3  /* Macro defined in the assembly source as `%DEFINE NAME INTVALUE' or `%assign NAME EXPR'. */
; 
; static char has_macros;
; static char do_special_pass_1;
; 
; static void reset_macros(void) {
reset_macros_:
		push bx
		push cx
		push dx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		push ax

;     struct label MY_FAR *node = label_list;
		mov si, word [_label_list]
		mov ax, word [_label_list+2]
		mov word [bp-2], ax

;     struct label MY_FAR *pre;
;     struct label MY_FAR *pre_right;
;     char value;
;     struct label MY_FAR *value_label;
;     if (!has_macros && do_special_pass_1 != 1) return;
		cmp byte [_has_macros], 0
		jne @$590
		cmp byte [_do_special_pass_1], 1
		je @$590
@$589:
		jmp near @$87

;     /* Morris inorder traversal of binary tree: iterative (non-recursive,
;      * so it uses O(1) stack), modifies the tree pointers temporarily, but
;      * then restores them, runs in O(n) time.
;      */
;     while (!RBL_IS_NULL(node)) {
@$590:
		mov ax, word [bp-2]
		test ax, ax
		je @$589

;         if (RBL_IS_LEFT_NULL(node)) goto do_work;
		mov es, ax
		cmp word [es:si], 0xffff
		je @$595

;         for (pre = RBL_GET_LEFT(node); pre_right = RBL_GET_RIGHT(pre), !RBL_IS_NULL(pre_right) && pre_right != node; pre = pre_right) {}
		mov ax, si
		mov dx, es
		call near RBL_GET_LEFT_
@$591:
		mov word [bp-4], ax
		mov di, dx
		mov ax, word [bp-4]
		mov dx, di
		call near RBL_GET_RIGHT_
		mov bx, dx
		test dx, dx
		je @$592
		cmp dx, word [bp-2]
		jne @$591
		cmp ax, si
		jne @$591

;         if (RBL_IS_NULL(pre_right)) {
@$592:
		test bx, bx
		jne @$594

;             RBL_SET_RIGHT(pre, node);
		mov bx, si
		mov cx, word [bp-2]
		mov ax, word [bp-4]
		mov dx, di
		call near RBL_SET_RIGHT_

;             node = RBL_GET_LEFT(node);
		mov ax, si
		mov dx, word [bp-2]
		call near RBL_GET_LEFT_
@$593:
		mov si, ax
		mov word [bp-2], dx

;         } else {
		jmp @$590

;             RBL_SET_RIGHT(pre, NULL);
@$594:
		xor bx, bx
		xor cx, cx
		mov ax, word [bp-4]
		mov dx, di
		call near RBL_SET_RIGHT_

;           do_work:  /* Do for each node. */
;             if (node->name[0] == '%') {
@$595:
		mov es, word [bp-2]
		cmp byte [es:si+9], 0x25
		jne @$597

;                 value = node->value;  /* Also make it shorter (char). */
		mov al, byte [es:si+5]

;                 if (value != MACRO_CMDLINE) {
		cmp al, 1
		je @$598

;                     RBL_SET_DELETED_1(node);
		or byte [es:si+4], 0x10

;                     /* Delete the label corresponding to the macro defined with an INTVALUE. */
;                     if (value == MACRO_VALUE && do_special_pass_1 != 1) {
		cmp al, 3
		jne @$598
		cmp byte [_do_special_pass_1], 1
		je @$598

;                         if ((value_label = find_label(node->name + 1)) != NULL) RBL_SET_DELETED_1(value_label);
		lea ax, [si+0xa]
		mov dx, es
		call near find_label_
		mov bx, ax
		test dx, dx
		jne @$596
		test ax, ax
		je @$598
@$596:
		mov es, dx
		or byte [es:bx+4], 0x10
		jmp @$598

;                     }
;                 }
;             } else if (do_special_pass_1 == 1) {  /* Delete all non-macro labels. */
@$597:
		cmp byte [_do_special_pass_1], 1
		jne @$598

;                 RBL_SET_DELETED_1(node);
		or byte [es:si+4], 0x10

;             }
;             node = RBL_GET_RIGHT(node);
@$598:
		mov ax, si
		mov dx, word [bp-2]
		call near RBL_GET_RIGHT_
		jmp @$593

;         }
;     }
; }
; 
; /*
;  ** name1 points to 1 byte before `NAME'.
;  ** It's OK if the macro is not defined.
;  */
; static void unset_macro(char *name1) {
unset_macro_:
		push bx
		push cx
		push dx
		push si
		push bp
		mov bp, sp
		push ax
		mov bx, ax

;     char c;
;     const char name1c = *name1;
		mov al, byte [bx]
		mov byte [bp-2], al

;     const char *p3;
;     struct label MY_FAR *label;
;     if (!(isalpha(name1[1]) || name1[1] == '_') || (p3 = match_label_prefix(name1 + 1)) == NULL || *p3 != '\0') {
		mov al, byte [bx+1]
		xor ah, ah
		call near isalpha_
		test ax, ax
		jne @$599
		cmp byte [bx+1], 0x5f
		jne @$600
@$599:
		lea cx, [bx+1]
		mov ax, cx
		call near match_label_prefix_
		mov si, ax
		test ax, ax
		je @$600
		cmp byte [si], 0
		je @$602

;          MESSAGE(1, "bad macro name");
@$600:
		mov ax, @$971
@$601:
		call near message_

;          return;
		jmp @$606

;     }
;     *name1 = '%';
@$602:
		mov byte [bx], 0x25

;     label = find_label(name1);
		mov dx, ds
		mov ax, bx
		call near find_label_
		mov si, ax

;     *name1 = name1c;
		mov al, byte [bp-2]
		mov byte [bx], al

;     if (label == NULL || RBL_IS_DELETED(label)) return;  /* No such macro, unset is a noop. */
		test dx, dx
		jne @$603
		test si, si
		je @$606
@$603:
		mov es, dx
		test byte [es:si+4], 0x10
		jne @$606

;     c = label->value;  /* Make it shorter for future comparisons. */
		mov al, byte [es:si+5]

;     if (c == MACRO_CMDLINE) {
		cmp al, 1
		jne @$604

;         MESSAGE(1, "invalid macro override");
		mov ax, @$972
		jmp @$601

;         return;
;     }
;     RBL_SET_DELETED_1(label);
@$604:
		or byte [es:si+4], 0x10

;     if (c == MACRO_VALUE) {  /* Also delete the corresponding label. */
		cmp al, 3
		jne @$606

;         if ((label = find_label(name1 + 1)) != NULL) RBL_SET_DELETED_1(label);
		mov dx, ds
		mov ax, cx
		call near find_label_
		mov bx, ax
		test dx, dx
		jne @$605
		test ax, ax
		je @$606
@$605:
		mov es, dx
		or byte [es:bx+4], 0x10

;     }
; }
@$606:
		mov sp, bp
		pop bp
		jmp near @$89

; 
; #define MACRO_SET_DEFINE_CMDLINE MACRO_CMDLINE
; #define MACRO_SET_DEFINE MACRO_VALUE
; #define MACRO_SET_ASSIGN (MACRO_VALUE | 0x10)
; 
; /*
;  ** name1 points to 1 byte before `NAME', name_end points to the end of
;  ** name. Both *name1 and *name_end can be changed temporarily.
;  */
; static void set_macro(char *name1, char *name_end, const char *value, char macro_set_mode) {
set_macro_:
		push si
		push di
		push bp
		mov bp, sp
		sub sp, 0x14
		mov si, ax
		mov word [bp-0xc], dx
		mov word [bp-0xe], bx
		mov byte [bp-4], cl

;     const char name1c = *name1;
		mov al, byte [si]
		mov byte [bp-6], al

;     const char name_endc = *name_end;
		mov bx, dx
		mov al, byte [bx]
		mov byte [bp-2], al

;     const char *p3;
;     struct label MY_FAR *label;
;     struct label MY_FAR *macro_label;
; 
;     value = avoid_spaces(value);  /* Before we change *name_end, in case name_end == value. */
		mov ax, word [bp-0xe]
		call near avoid_spaces_
		mov word [bp-0xe], ax

;     *name_end = '\0';
		mov byte [bx], 0

;     if (!(isalpha(name1[1]) || name1[1] == '_') || (p3 = match_label_prefix(name1 + 1)) != name_end) {
		mov al, byte [si+1]
		xor ah, ah
		call near isalpha_
		test ax, ax
		jne @$607
		cmp byte [si+1], 0x5f
		jne @$608
@$607:
		lea ax, [si+1]
		mov word [bp-0x14], ax
		call near match_label_prefix_
		cmp ax, word [bp-0xc]
		je @$610

;          MESSAGE(1, "bad macro name");
@$608:
		mov ax, @$971
@$609:
		call near message_

;          goto do_return;
		jmp near @$632

;     }
;     *name1 = '%';  /* Macro NAME prefixed by '%'. */
@$610:
		mov byte [si], 0x25

;     macro_label = find_label(name1);
		mov dx, ds
		mov ax, si
		call near find_label_
		mov word [bp-0xa], dx

;     if (0) DEBUG3("set_macro mode 0x%x strcmp (%s) (%s)\n", macro_set_mode, name1 + 1, value);
;     /* strcmp(...) would also work (there are no far pointers here), but we can save a few bytes if we avoid linking strcmp(...), for __DOSMC__. */
;     if (macro_set_mode == MACRO_SET_DEFINE && strcmp_far(name1 + 1, value) == 0) {  /* `%DEFINE NAME NAME'. */
		mov di, ax
		mov word [bp-8], dx

		cmp byte [bp-4], 3
		jne @$615
		mov cx, ds
		mov dx, ds
		mov bx, word [bp-0xe]
		mov ax, word [bp-0x14]
		call near strcmp_far_
		test ax, ax
		jne @$615

;         if (macro_label == NULL) {
		cmp word [bp-0xa], 0
		jne @$612
		test di, di
		jne @$612

;             define_label(name1, MACRO_SELF);
		mov bx, 2
		xor cx, cx
		mov ax, si
@$611:
		call near define_label_

;         } else if (RBL_IS_DELETED(macro_label)) {
		jmp near @$631
@$612:
		mov es, word [bp-0xa]
		mov bx, di
		test byte [es:bx+4], 0x10
		je @$613

;             RBL_SET_DELETED_0(macro_label);
		and byte [es:bx+4], 0xef

;             macro_label->value = MACRO_SELF;
		mov word [es:bx+5], 2

;         } else if ((char)macro_label->value != MACRO_SELF) {
		jmp near @$630
@$613:
		cmp byte [es:bx+5], 2
		je @$621

;           invalid_macro_override:
;             MESSAGE(1, "invalid macro override");
@$614:
		mov ax, @$972
		jmp @$609

;             goto do_return;
;         }
;         /* !! TODO(pts): Allow `%DEFINE offset' and `%DEFINE ptr' for compatibility with A72, TASM and A86. Also add corresponding command-line flags. */
;         /* !! TODO(pts): Allow effective addresses ds:[bp] and [bp][bx] for compatibility with TASM. */
;     } else if (macro_set_mode != MACRO_SET_ASSIGN && !is_define_value(value)) {
@$615:
		cmp byte [bp-4], 0x13
		je @$617
		mov ax, word [bp-0xe]
		call near is_define_value_
		test al, al
		jne @$617

;       bad_macro_value:
;         /* By reporting an error here we want to avoid the following NASM
;          * incompatibility:
;          *
;          *   %define foo 5+2
;          *   db foo*6
;          *
;          * In NASM, this is equivalent to`db 5+2* 6', which is `db 17'.
;          * mininasm is not able to store strings (e.g. `5+2') as macro
;          * values, and storing 7 would be incompatible with NASM, because
;          * that would be equivalent to `db 7*6', which is `db 42'.
;          */
;         MESSAGE(1, "bad macro value");
@$616:
		mov ax, @$973
		jmp near @$609

;         goto do_return;
;     } else if ((label = find_label(name1 + 1)) != NULL && !RBL_IS_DELETED(label) && (macro_label == NULL || RBL_IS_DELETED(macro_label))) {
@$617:
		lea ax, [si+1]
		mov dx, ds
		call near find_label_
		mov bx, ax
		mov word [bp-0x12], ax
		mov word [bp-0x10], dx
		test dx, dx
		jne @$618
		test ax, ax
		je @$622
@$618:
		mov es, dx
		test byte [es:bx+4], 0x10
		jne @$622
		mov ax, word [bp-8]
		test ax, ax
		jne @$619
		test di, di
		je @$620
@$619:
		mov es, ax
		test byte [es:di+4], 0x10
		je @$622

;         MESSAGE(1, "macro name conflicts with label");
@$620:
		mov ax, @$974
		jmp near @$609
@$621:
		jmp near @$631

;         goto do_return;
;     } else {
;         *name_end = name_endc;
@$622:
		mov al, byte [bp-2]
		mov bx, word [bp-0xc]
		mov byte [bx], al

;         p3 = match_expression(value);
		mov ax, word [bp-0xe]
		call near match_expression_

;         *name_end = '\0';
		mov byte [bx], 0

;         if (p3 == NULL || *p3 != '\0') {
		test ax, ax
		je @$623
		mov bx, ax
		cmp byte [bx], 0
		je @$624

;             if (macro_set_mode != MACRO_SET_ASSIGN) goto bad_macro_value;
@$623:
		cmp byte [bp-4], 0x13
		jne @$616

;             MESSAGE(1, "Bad expression");
		mov ax, @$964
		jmp near @$609

;             goto do_return;
;         } else if (has_undefined) {
@$624:
		cmp byte [_has_undefined], 0
		je @$625

;             MESSAGE(1, "Cannot use undefined labels");
		mov ax, @$975
		jmp near @$609

;             goto do_return;
;         }
;         macro_set_mode &= ~0x10;  /* Change MACRO_SET_ASSIGN to MACRO_VALUE == MACRO_SET_DEFINE. */
@$625:
		and byte [bp-4], 0xef

;         /* Now: macro_set_mode is MACRO_CMDLINE == MACRO_SET_DEFINE_CMDLINE or MACRO_VALUE == MACRO_SET_DEFINE. */
;         if (macro_label == NULL) {
		mov ax, word [bp-8]
		test ax, ax
		jne @$626
		test di, di
		jne @$626

;             define_label(name1, macro_set_mode);
		mov bl, byte [bp-4]
		xor bh, bh
		xor cx, cx
		mov ax, si
		call near define_label_

;         } else if (RBL_IS_DELETED(macro_label)) {
		jmp @$628
@$626:
		mov es, ax
		test byte [es:di+4], 0x10
		je @$627

;             RBL_SET_DELETED_0(macro_label);
		and byte [es:di+4], 0xef

;             macro_label->value = macro_set_mode;
		mov al, byte [bp-4]
		xor ah, ah
		mov word [es:di+5], ax
		mov word [es:di+7], 0

;         } else if ((char)macro_label->value != macro_set_mode) {
		jmp @$628
@$627:
		mov al, byte [es:di+5]
		cmp al, byte [bp-4]
		je @$628
		jmp near @$614

;             goto invalid_macro_override;
;         }
;         if (label == NULL) {
@$628:
		cmp word [bp-0x10], 0
		jne @$629
		cmp word [bp-0x12], 0
		jne @$629

;             define_label(name1 + 1, instruction_value);
		mov bx, word [_instruction_value]
		mov cx, word [_instruction_value+2]
		lea ax, [si+1]
		jmp near @$611

;         } else {
;             RBL_SET_DELETED_0(label);
@$629:
		les bx, [bp-0x12]
		and byte [es:bx+4], 0xef

;             label->value = instruction_value;
		mov dx, word [_instruction_value]
		mov ax, word [_instruction_value+2]
		mov word [es:bx+5], dx
@$630:
		mov word [es:bx+7], ax

;         }
;     }
;     has_macros = 1;
@$631:
		mov byte [_has_macros], 1

;   do_return:
;     *name1 = name1c;
@$632:
		mov al, byte [bp-6]
		mov byte [si], al

;     *name_end = name_endc;
		mov al, byte [bp-2]
		mov bx, word [bp-0xc]
		mov byte [bx], al
		jmp near @$71

; }
; 
; #if CONFIG_USE_MEMCPY_INLINE
; #if 1
; static void memcpy_void_my(void *dest, const void *src, size_t n) {
memcpy_void_my_:
		push cx
		push si
		push di

;     memcpy_void_inline(dest, src, n);
		mov cx, bx
		mov si, dx
		mov di, ax
		push ds
		pop es
		rep movsb
		jmp near @$47

; }
; #else
; /* This would make the __WATCOMC__ Linux i386 <libc.h> executable program 160 bytes larger (!). Also it would cause similar size increases for __DOSMC__. */
; #define memcpy_void_my memcpy_void_inline
; #endif
; #endif
; 
; /*
;  ** Do an assembler pass.
;  */
; static void do_assembly(const char *input_filename) {
do_assembly_:
		push bx
		push cx
		push dx
		push si
		push di
		push bp
		mov bp, sp
		sub sp, 0x30
		push ax

;     struct assembly_info *aip;
;     const char *p3;
;     const char *p;
;     const char *psave;
;     char *line;
;     char *linep;
;     char *liner;
;     char *line_rend;
;     uvalue_t level;
;     uvalue_t avoid_level;
;     value_t times;
;     value_t line_address;
;     value_t incbin_offset;
;     value_t incbin_size;
;     int discarded_after_read;  /* Number of bytes discarded in an incomplete line since the last file read(...) at line_rend, i.e. the end of the buffer (line_buf). */
;     char include;  /* 0, 1 or 2. */
;     int got;
;     int input_fd;
;     int incbin_fd;
;     char pc;
;     char rc;  /* Restore character: save a byte of a string to here, change in the string, and restore it later from here. */
;     char is_if_not;
;     char is_bss;
;     struct label MY_FAR *label;
; 
;     have_labels_changed = 0;
		mov byte [_have_labels_changed], 0

;     jump_range_bits &= ~1;
		and byte [_jump_range_bits], 0xfe

;     if (opt_level <= 1) jump_range_bits |= 2;  /* Report ``short jump is out of range'' errors early. */
		cmp byte [_opt_level], 1
		ja @$633
		or byte [_jump_range_bits], 2

;     cpu_level = 0xff;  /* Accept all supported instructions. */
@$633:
		mov byte [_cpu_level], 0xff

;     is_bss = 0;
		mov byte [bp-4], 0

;     assembly_p = (struct assembly_info*)assembly_stack;  /* Clear the stack. */
		mov word [_assembly_p], _assembly_stack

; 
;   do_assembly_push:
;     line_number = 0;  /* Global variable. */
@$634:
		xor ax, ax
		mov word [_line_number], ax
		mov word [_line_number+2], ax

;     if ((aip = assembly_push(input_filename)) == NULL) {
		mov ax, word [bp-0x32]
		call near assembly_push_
		mov word [bp-0xc], ax
		test ax, ax
		jne @$635

;         MESSAGE(1, "assembly stack overflow, too many pending %INCLUDE files");
		mov ax, @$976
		call near message_

;         return;
		jmp near @$87

;     }
; 
;   do_open_again:
;     line_number = 0;  /* Global variable. */
@$635:
		xor ax, ax
		mov word [_line_number], ax
		mov word [_line_number+2], ax

;     filename_for_message = aip->input_filename;
		mov bx, word [bp-0xc]
		add bx, 0x11
		mov word [_filename_for_message], bx

;     if (HAS_OPEN_FAILED(input_fd = open2(aip->input_filename, O_RDONLY | O_BINARY))) {
		xor dx, dx
		mov ax, bx
		call near open2_
		mov word [bp-0x16], ax
		test ax, ax
		jge @$637

;         MESSAGE1STR(1, "cannot open '%s' for input", aip->input_filename);
		mov dx, bx
		mov ax, @$977
@$636:
		call near message1str_

;         return;
		jmp near @$87

;     }
;     if (0) DEBUG2("seeking to %d in file: %s\n", (int)aip->file_offset, aip->input_filename);
;     if (aip->file_offset != 0 && lseek(input_fd, aip->file_offset, SEEK_SET) != aip->file_offset) {
@$637:
		mov bx, word [bp-0xc]
		mov dx, word [bx+2]
		or dx, word [bx]
		je @$639
		mov bx, word [bx]
		mov si, word [bp-0xc]
		mov cx, word [si+2]
		xor dx, dx
		call near lseek_
		cmp dx, word [si+2]
		jne @$638
		cmp ax, word [si]
		je @$639

;         MESSAGE1STR(1, "cannot seek in '%s'", input_filename);
@$638:
		mov dx, word [bp-0x32]
		mov ax, @$978
		jmp @$636

;         return;
;     }
;     level = aip->level;
@$639:
		mov bx, word [bp-0xc]
		mov ax, word [bx+4]
		mov word [bp-0xa], ax
		mov ax, word [bx+6]
		mov word [bp-0x26], ax

;     avoid_level = aip->avoid_level;
		mov ax, word [bx+8]
		mov word [bp-0xe], ax
		mov ax, word [bx+0xa]
		mov word [bp-8], ax

;     line_number = aip->line_number;
		mov ax, word [bx+0xc]
		mov dx, word [bx+0xe]
		mov word [_line_number], ax
		mov word [_line_number+2], dx

; 
;     global_label[0] = '\0';
		mov byte [_global_label], 0

;     global_label_end = global_label;
		mov word [_global_label_end], _global_label

;     linep = line_rend = line_buf;
		mov ax, _line_buf
		mov word [bp-0x20], ax
		mov word [bp-0x10], ax

;     discarded_after_read = 0;
		mov word [bp-0x24], 0

;     for (;;) {  /* Read and process next line from input. */
;         if (GET_UVALUE(++line_number) == 0) --line_number;  /* Cappped at max uvalue_t. */
@$640:
		add word [_line_number], 1
		adc word [_line_number+2], 0
		mov ax, word [_line_number+2]
		or ax, word [_line_number]
		jne @$641
		add word [_line_number], 0xffff
		adc word [_line_number+2], 0xffff

;         line = linep;
@$641:
		mov ax, word [bp-0x10]
		mov word [bp-0x28], ax

;        find_eol:
;         /* linep can be used as scratch from now on */
;         for (p = line; p != line_rend && *p != '\n'; ++p) {}
@$642:
		mov si, word [bp-0x28]
@$643:
		cmp si, word [bp-0x20]
		je @$644
		cmp byte [si], 0xa
		je @$644
		inc si
		jmp @$643

;         if (p == line_rend) {  /* No newline in the remaining unprocessed bytes, so read more bytes from the file. */
@$644:
		cmp si, word [bp-0x20]
		jne @$648

;             if (line != line_buf) {  /* Move the remaining unprocessed bytes (line...line_rend) to the beginning of the buffer (line_buf). */
		cmp word [bp-0x28], _line_buf
		je @$647

;                 if (line_rend - line >= MAX_SIZE) goto line_too_long;
		mov ax, si
		sub ax, word [bp-0x28]
		cmp ax, 0x100
		jge @$650

;                 /*if (line_rend - line > (int)(sizeof(line_buf) - (sizeof(line_buf) >> 2))) goto line_too_long;*/  /* Too much copy per line (thus too slow). This won't be triggered, because the `line_rend - line >= MAX_SIZE' check above triggers first. */
;                 for (liner = line_buf, p = line; p != line_rend; *liner++ = *p++) {}
		mov word [bp-0x1a], _line_buf
		mov si, word [bp-0x28]
@$645:
		cmp si, word [bp-0x20]
		je @$646
		mov al, byte [si]
		mov bx, word [bp-0x1a]
		mov byte [bx], al
		inc si
		inc word [bp-0x1a]
		jmp @$645

;                 p = line_rend = liner;
@$646:
		mov bx, word [bp-0x1a]
		mov word [bp-0x20], bx
		mov si, bx

;                 line = line_buf;
		mov word [bp-0x28], _line_buf

;             }
;           read_more:
;             discarded_after_read = 0;  /* This must be after `read_more' for correct offset calculations. */
@$647:
		mov word [bp-0x24], 0

;             /* Now: p == line_rend. */
;             if ((got = line_buf + sizeof(line_buf) - line_rend) <= 0) goto line_too_long;
		mov bx, _line_buf+0x200
		sub bx, word [bp-0x20]
		test bx, bx
		jle @$650

;             if (0) DEBUG0("READ\r\n");
;             if ((got = read(input_fd, line_rend, got)) < 0) {
		mov dx, word [bp-0x20]
		mov ax, word [bp-0x16]
		call near read_
		test ax, ax
		jge @$649

;                 MESSAGE(1, "error reading assembly file");
		mov ax, @$979

;                 goto close_return;
		jmp near @$866
@$648:
		jmp near @$677

;             }
;             line_rend += got;
@$649:
		add word [bp-0x20], ax

;             if (got == 0) {
		test ax, ax
		jne @$651

;                 if (p == line_rend) break;  /* EOF. */
		mov ax, word [bp-0x20]
		cmp si, ax
		je @$658

;                 *line_rend++ = '\n';  /* Add sentinel. This is valid memory access in line_buf, because got > 0 in the read(...) call above. */
		mov bx, ax
		mov byte [bx], 0xa
		inc word [bp-0x20]

;             } else if (line_rend != line_buf + sizeof(line_buf)) {
		jmp @$652
@$650:
		jmp near @$680
@$651:
		cmp word [bp-0x20], _line_buf+0x200
		jne @$647

;                 goto read_more;
;             }
;             /* We may process the last partial line here again later, but that performance degradation is fine. TODO(pts): Keep some state (comment, quote) to avoid this. */
;             for (p = linep = line; p != line_rend; ) {
@$652:
		mov ax, word [bp-0x28]
		mov word [bp-0x10], ax
		mov si, ax
@$653:
		cmp si, word [bp-0x20]
		jne @$654
		jmp near @$642

;                 pc = *p;
@$654:
		mov cl, byte [si]

;                 if (pc == '\'' || pc == '"') {
		cmp cl, 0x27
		je @$655
		cmp cl, 0x22
		jne @$659

;                     ++p;
@$655:
		inc si

;                     do {
;                         if (p == line_rend) break;  /* This quote may be closed later, after a read(...). */
@$656:
		cmp si, word [bp-0x20]
		je @$653

;                         if (*p == '\n') goto newline;  /* This unclosed quote will be reported as a syntax error later. */
		mov al, byte [si]
		cmp al, 0xa
		je @$662

;                         if (*p == '\0') {
		test al, al
		jne @$657

;                             MESSAGE(1, "quoted NUL found");
		mov ax, @$980
		call near message_

;                             *(char*)p = ' ';
		mov byte [si], 0x20

;                         }
;                     } while (*p++ != pc);
@$657:
		mov bx, si
		inc si
		cmp cl, byte [bx]
		jne @$656
		jmp @$653
@$658:
		jmp near @$864

;                 } else if (pc == ';') {
@$659:
		cmp cl, 0x3b
		jne @$666

;                     for (liner = (char*)p; p != line_rend; *(char*)p++ = ' ') {
		mov word [bp-0x1a], si
@$660:
		cmp si, word [bp-0x20]
		je @$661

;                         if (*p == '\n') goto newline;
		cmp byte [si], 0xa
		je @$667

;                     }
		mov byte [si], 0x20
		inc si
		jmp @$660

;                     /* Now: p == line_rend. We have comment which hasn't been finished in the remaining buffer. */
;                     for (; liner != line && liner[-1] != '\n' && isspace(liner[-1]); --liner) {}  /* Find start of whitespace preceding the comment. */
@$661:
		mov bx, word [bp-0x1a]
		cmp bx, word [bp-0x28]
		je @$663
		mov al, byte [bx-1]
		cmp al, 0xa
		je @$663
		xor ah, ah
		call near isspace_
		test ax, ax
		je @$663
		dec word [bp-0x1a]
		jmp @$661
@$662:
		jmp @$667

;                     *liner++ = ';';  /* Process this comment again later. */
@$663:
		mov bx, word [bp-0x1a]
		mov byte [bx], 0x3b
		inc word [bp-0x1a]

;                     discarded_after_read = line_rend - liner;  /* TODO(pts): We should check for overflow for source files >= 2 GiB. */
;                     if (0) DEBUG1("DISCARD_COMMENT %d\r\n", (int)(line_rend - liner));
;                     p = line_rend = liner;
		mov bx, word [bp-0x20]
		sub bx, word [bp-0x1a]
		mov word [bp-0x24], bx

		mov bx, word [bp-0x1a]
		mov word [bp-0x20], bx
		mov si, bx

;                     if (linep == line) { /* Reached end of the read buffer before the end of the single-line comment in the upcoming line. Read more bytes of this comment. */
		mov ax, word [bp-0x10]
		cmp ax, word [bp-0x28]
		je @$665
@$664:
		jmp near @$642

;                         if (line_rend - linep >= MAX_SIZE) goto line_too_long;
@$665:
		mov ax, bx
		sub ax, word [bp-0x10]
		cmp ax, 0x100
		jge @$675
		jmp near @$647

;                         goto read_more;
;                     }
;                     goto find_eol;  /* Superfluous. */
;                 } else if (pc == '\n') {
@$666:
		cmp cl, 0xa
		jne @$668

;                   newline:
;                     linep = (char*)++p;
@$667:
		inc si
		mov word [bp-0x10], si

;                 } else if (pc == '\0' || isspace(pc)) {
		jmp near @$653
@$668:
		test cl, cl
		je @$669
		mov al, cl
		xor ah, ah
		call near isspace_
		test ax, ax
		je @$676

;                     *(char*)p++ = ' ';
@$669:
		mov byte [si], 0x20
		inc si

;                     for (liner = (char*)p; liner != line_rend && ((pc = *liner) == '\0' || (pc != '\n' && isspace(pc))); *liner++ = ' ') {}
		mov word [bp-0x1a], si
@$670:
		mov bx, word [bp-0x1a]
		cmp bx, word [bp-0x20]
		je @$672
		mov cl, byte [bx]
		test cl, cl
		je @$671
		cmp cl, 0xa
		je @$672
		mov al, cl
		xor ah, ah
		call near isspace_
		test ax, ax
		je @$672
@$671:
		mov bx, word [bp-0x1a]
		mov byte [bx], 0x20
		inc word [bp-0x1a]
		jmp @$670

;                     if (liner == line_rend) {
@$672:
		mov bx, word [bp-0x1a]
		cmp bx, word [bp-0x20]
		je @$674
@$673:
		jmp near @$653

;                         discarded_after_read = (const char*)line_rend - p;  /* TODO(pts): We should check for overflow for source files >= 2 GiB. */
;                         if (0) DEBUG1("DISCARD_WHITESPACE %d\r\n", (int)(line_rend - p));
;                         line_rend = (char*)p;  /* Compress trailing whitespace bytes at the end of the buffer to a single space, so that they won't count against the line size (MAX_SIZE) at the end of the line. */
@$674:
		sub bx, si
		mov word [bp-0x24], bx

		mov word [bp-0x20], si

;                         goto find_eol;  /* Superfluous. */
		jmp @$664
@$675:
		jmp @$680

;                     }
;                 } else {
;                     ++p;
@$676:
		inc si

;                 }
		jmp @$673

;             }
;             goto find_eol;
;         }
;         /* Now: *p == '\n'. */
;         linep = (char*)p + 1;
@$677:
		lea ax, [si+1]
		mov word [bp-0x10], ax

;         for (; p != line && p[-1] == ' '; --p) {}  /* Removes trailing \r and spaces. */
@$678:
		cmp si, word [bp-0x28]
		je @$679
		cmp byte [si-1], 0x20
		jne @$679
		dec si
		jmp @$678

;         *(char*)p = '\0';  /* Change trailing '\n' to '\0'. */
@$679:
		mov byte [si], 0

;         if (0) DEBUG3("line @0x%x %u=(%s)\r\n", (unsigned)current_address, (unsigned)line_number, line);
		sub si, word [bp-0x28]
		cmp si, 0x100
		jl @$681

;         if (p - line >= MAX_SIZE) { line_too_long:
;             MESSAGE(1, "assembly line too long");
@$680:
		mov ax, @$981
		jmp near @$866

;             goto close_return;
;         }
; 
;         line_address = current_address;
@$681:
		mov ax, word [_current_address]
		mov word [bp-0x1e], ax
		mov ax, word [_current_address+2]
		mov word [bp-0x30], ax

;         generated_cur = generated_ptr;
		mov ax, word [_generated_ptr]
		mov word [_generated_cur], ax

;         include = 0;
		mov byte [bp-6], 0

; 
;         p = avoid_spaces(line);
		mov ax, word [bp-0x28]
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;         if (p[0] == '[') {  /* Change e.g. `[org 100h]' (as in output of the NASM preprocessor `nasm -E' to `org 100h'. */
		cmp byte [bx], 0x5b
		jne @$684

;             p3 = p + strlen(p) - 1;
		call near strlen_
		mov di, ax
		add di, bx
		dec di

;             if (p3[0] == ']') {
		cmp byte [di], 0x5d
		jne @$684

;                 for (; p3[-1] == ' '; --p3) {}
@$682:
		cmp byte [di-1], 0x20
		jne @$683
		dec di
		jmp @$682

;                 ((char*)p3)[0] = '\0';
@$683:
		mov byte [di], 0

;                 p = avoid_spaces(p + 1);
		lea ax, [si+1]
		call near avoid_spaces_
		mov si, ax

;             }
;         }
;         if (p[0] == '\0') {  /* Empty line. */
@$684:
		mov al, byte [si]
		test al, al
		je @$688

;             goto after_line;
;         } else if (p[0] != '%') {
		cmp al, 0x25
		je @$686

;             if (avoid_level != 0 && level >= avoid_level) {
		mov ax, word [bp-8]
		or ax, word [bp-0xe]
		je @$685
		mov ax, word [bp-0x26]
		cmp ax, word [bp-8]
		ja @$688
		jne @$685
		mov ax, word [bp-0xa]
		cmp ax, word [bp-0xe]
		jae @$688
@$685:
		jmp near @$759

; #if DEBUG
;                 if (0) MESSAGE1STR(1, "Avoiding '%s'", p);
; #endif
;                 goto after_line;
;             }
;             goto not_preproc;
;         }
; 
;         /* Process preprocessor directive. Labels are not allowed here. */
;         p = separate(p);
@$686:
		mov ax, si
		call near separate_
		mov si, ax

;         if (casematch(instr_name, "%IF")) {
		mov dx, @$982
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$691

;             if (GET_UVALUE(++level) == 0) { if_too_deep:
		add word [bp-0xa], 1
		adc word [bp-0x26], 0
		mov ax, word [bp-0x26]
		or ax, word [bp-0xa]
		jne @$689

;                 MESSAGE(1, "%IF too deep");
@$687:
		mov ax, @$983
		jmp near @$866
@$688:
		jmp near @$751

;                 goto close_return;
;             }
;             if (avoid_level != 0 && level >= avoid_level)
@$689:
		mov ax, word [bp-8]
		or ax, word [bp-0xe]
		je @$690
		mov ax, word [bp-0x26]
		cmp ax, word [bp-8]
		ja @$699
		jne @$690
		mov ax, word [bp-0xa]
		cmp ax, word [bp-0xe]
		jae @$699

;                 goto after_line;
;             /* !! TODO(pts): Add operators < > <= >=  == = != <> && || ^^ for `%IF' only. NASM doesn't do short-circuit. */
;             p = match_expression(p);
@$690:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p == NULL) {
		test ax, ax
		jne @$692

;                 MESSAGE(1, "Bad expression");
		mov ax, @$964

;             } else if (has_undefined) {
		jmp @$693
@$691:
		jmp @$700
@$692:
		cmp byte [_has_undefined], 0
		je @$694

;                 MESSAGE(1, "Cannot use undefined labels");
		mov ax, @$975
@$693:
		call near message_

;             }
;             if (instruction_value != 0) {
@$694:
		mov ax, word [_instruction_value+2]
		or ax, word [_instruction_value]
@$695:
		jne @$697

;                 ;
;             } else {
;                 avoid_level = level;
		mov ax, word [bp-0xa]
		mov word [bp-0xe], ax
		mov ax, word [bp-0x26]
@$696:
		mov word [bp-8], ax

;             }
;             check_end(p);
@$697:
		mov ax, si
@$698:
		call near check_end_

;         } else if (casematch(instr_name, "%IFDEF")) {
@$699:
		jmp near @$751
@$700:
		mov dx, @$984
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$704

;             is_if_not = 0;
		mov byte [bp-2], 0

;           ifdef_or_ifndef:
;             if (GET_UVALUE(++level) == 0) goto if_too_deep;
@$701:
		add word [bp-0xa], 1
		adc word [bp-0x26], 0
		mov ax, word [bp-0x26]
		or ax, word [bp-0xa]
		je @$687

;             if (avoid_level != 0 && level >= avoid_level)
		mov ax, word [bp-8]
		or ax, word [bp-0xe]
		je @$702
		mov ax, word [bp-0x26]
		cmp ax, word [bp-8]
		ja @$699
		jne @$702
		mov ax, word [bp-0xa]
		cmp ax, word [bp-0xe]
		jae @$699

;                 goto after_line;
;             if (0) DEBUG1("%%IFDEF macro=(%s)\r\n", p);
;             p3 = match_label_prefix(p);
@$702:
		mov ax, si
		call near match_label_prefix_
		mov bx, ax
		mov di, ax

;             if (!p3 || *p3 != '\0' || !(isalpha(*p) || *p == '_')) {
		test ax, ax
		je @$703
		cmp byte [bx], 0
		jne @$703
		mov al, byte [si]
		xor ah, ah
		call near isalpha_
		test ax, ax
		jne @$705
		cmp byte [si], 0x5f
		je @$705

;                 MESSAGE(1, "bad macro name");
@$703:
		mov ax, @$971
		jmp near @$786
@$704:
		jmp @$710

;             } else {
;                 pc = *--p;
@$705:
		dec si
		mov cl, byte [si]

;                 *(char*)p = '%';  /* Prefix the macro name with a '%'. */
		mov byte [si], 0x25

;                 if (((label = find_label(p)) != NULL && !RBL_IS_DELETED(label)) == is_if_not) {
		mov dx, ds
		mov ax, si
		call near find_label_
		mov bx, ax
		test dx, dx
		jne @$706
		test ax, ax
		je @$707
@$706:
		mov es, dx
		test byte [es:bx+4], 0x10
		jne @$707
		mov ax, 1
		jmp @$708
@$707:
		xor ax, ax
@$708:
		mov dl, byte [bp-2]
		xor dh, dh
		cmp ax, dx
		jne @$709

;                     avoid_level = level;  /* Our %IFDEF or %IFNDEF is false, start hiding. */
		mov ax, word [bp-0xa]
		mov word [bp-0xe], ax
		mov ax, word [bp-0x26]
		mov word [bp-8], ax

;                 }
;                 *(char*)p = pc;  /* Restore original character for listing_fd. */
@$709:
		mov byte [si], cl

;             }
		jmp near @$751

;         } else if (casematch(instr_name, "%IFNDEF")) {
@$710:
		mov dx, @$985
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$711

;             is_if_not = 1;
		mov byte [bp-2], 1

;             goto ifdef_or_ifndef;
		jmp near @$701

;         } else if (casematch(instr_name, "%IFIDN")) {  /* Only `%ifidn __OUTPUT_FORMAT__, ...' is supported, and it is true only for `bin'. */
@$711:
		mov dx, @$986
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$718

;             is_if_not = 0;
		mov byte [bp-2], 0

;           ifidn_or_ifnidn:
;             if (GET_UVALUE(++level) == 0) goto if_too_deep;
@$712:
		add word [bp-0xa], 1
		adc word [bp-0x26], 0
		mov ax, word [bp-0x26]
		or ax, word [bp-0xa]
		jne @$713
		jmp near @$687

;             if (avoid_level != 0 && level >= avoid_level)
@$713:
		mov ax, word [bp-8]
		or ax, word [bp-0xe]
		je @$714
		mov ax, word [bp-0x26]
		cmp ax, word [bp-8]
		ja @$720
		jne @$714
		mov ax, word [bp-0xa]
		cmp ax, word [bp-0xe]
		jae @$723

;                 goto after_line;
;             for (p3 = "__OUTPUT_FORMAT__"; p3[0] != '\0' && p[0] == p3[0]; ++p, ++p3) {}
@$714:
		mov di, @$987
@$715:
		cmp byte [di], 0
		je @$716
		mov al, byte [si]
		cmp al, byte [di]
		jne @$716
		inc si
		inc di
		jmp @$715

;             if (p3[0] != '\0') { bad_ifidn:
@$716:
		cmp byte [di], 0
		je @$719

;                 MESSAGE(1, "bad %IFIDN");
@$717:
		mov ax, @$988
		jmp near @$786
@$718:
		jmp @$724

;             } else if ((p = avoid_spaces(p))[0] != ',') {
@$719:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		cmp byte [bx], 0x2c
		jne @$717

;                 goto bad_ifidn;
;             } else {
;                 p = avoid_spaces(p + 1);
		inc ax
		call near avoid_spaces_

;                 /* strcmp(...) would also work (there are no far pointers here), but we can save a few bytes if we avoid linking strcmp(...), for __DOSMC__. */
;                 if ((strcmp_far(p, "bin") == 0) == is_if_not) {
		mov dx, ds
		mov bx, @$989
		mov cx, ds
		call near strcmp_far_
		test ax, ax
		jne @$721
		mov dx, 1
		jmp @$722
@$720:
		jmp @$723
@$721:
		xor dx, dx
@$722:
		mov al, byte [bp-2]
		xor ah, ah
		cmp dx, ax
		jne @$723

;                     avoid_level = level;  /* Our %IFIDN or %IFNIDN is false, start hiding. */
		mov ax, word [bp-0xa]
		mov word [bp-0xe], ax
		mov ax, word [bp-0x26]
		mov word [bp-8], ax

;                 }
@$723:
		jmp near @$751

;             }
;         } else if (casematch(instr_name, "%IFNIDN")) {
@$724:
		mov dx, @$990
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$725

;             is_if_not = 1;
		mov byte [bp-2], 1

;             goto ifidn_or_ifnidn;
		jmp near @$712

;         } else if (casematch(instr_name, "%ELSE")) {
@$725:
		mov dx, @$991
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$729

;             if (level == 1) {
		cmp word [bp-0x26], 0
		jne @$726
		cmp word [bp-0xa], 1
		jne @$726

;                 MESSAGE(1, "%ELSE without %IF");
		mov ax, @$992
		jmp near @$866

;                 goto close_return;
;             }
;             if (avoid_level != 0 && level > avoid_level)
@$726:
		mov ax, word [bp-8]
		or ax, word [bp-0xe]
		je @$727
		mov ax, word [bp-0x26]
		cmp ax, word [bp-8]
		ja @$723
		jne @$727
		mov ax, word [bp-0xa]
		cmp ax, word [bp-0xe]
		ja @$723

;                 goto after_line;
;             if (avoid_level == level) {
@$727:
		mov ax, word [bp-8]
		cmp ax, word [bp-0x26]
		jne @$728
		mov ax, word [bp-0xe]
		cmp ax, word [bp-0xa]
		jne @$728

;                 avoid_level = 0;
		xor ax, ax
		mov word [bp-0xe], ax

;             } else if (avoid_level == 0) {
		jmp near @$696
@$728:
		mov ax, word [bp-8]
		or ax, word [bp-0xe]

;                 avoid_level = level;
;             }
		jmp near @$695

;             check_end(p);
;         } else if (casematch(instr_name, "%ENDIF")) {
@$729:
		mov dx, @$993
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$732

;             if (avoid_level == level)
		mov ax, word [bp-8]
		cmp ax, word [bp-0x26]
		jne @$730
		mov ax, word [bp-0xe]
		cmp ax, word [bp-0xa]
		jne @$730

;                 avoid_level = 0;
		xor ax, ax
		mov word [bp-0xe], ax
		mov word [bp-8], ax

;             if (--level == 0) {
@$730:
		add word [bp-0xa], 0xffff
		adc word [bp-0x26], 0xffff
		mov ax, word [bp-0x26]
		or ax, word [bp-0xa]
		je @$731
		jmp near @$697

;                 MESSAGE(1, "%ENDIF without %IF");
@$731:
		mov ax, @$994
		jmp near @$866

;                 goto close_return;
;             }
;             check_end(p);
;         } else if (casematch(instr_name, "%IF*") || casematch(instr_name, "%ELIF*")) {
@$732:
		mov dx, @$995
		mov ax, _instr_name
		call near casematch_
		test al, al
		jne @$733
		mov dx, @$996
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$734

;             /* We report this even if skipped. */
;             MESSAGE1STR(1, "Unknown preprocessor condition: %s", instr_name);
@$733:
		mov dx, _instr_name
		mov ax, @$997
		call near message1str_

;             goto close_return;  /* There is no meaningful way to continue in this file. */
		jmp near @$867

;         } else if (avoid_level != 0 && level >= avoid_level) {
@$734:
		mov ax, word [bp-8]
		or ax, word [bp-0xe]
		je @$735
		mov ax, word [bp-0x26]
		cmp ax, word [bp-8]
		ja @$740
		jne @$735
		mov ax, word [bp-0xa]
		cmp ax, word [bp-0xe]
		jae @$740

;         } else if (casematch(instr_name, "%INCLUDE")) {
@$735:
		mov dx, @$998
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$741

;             pc = *p++;
		mov cl, byte [si]
		inc si

;             if (pc != '"' && pc != '\'') {
		cmp cl, 0x22
		je @$737
		cmp cl, 0x27
		je @$737

;               missing_quotes_in_include:
;                 MESSAGE(1, "Missing quotes in %INCLUDE");
@$736:
		mov ax, @$999
		jmp near @$786

;                 goto after_line;
;             }
;             for (p3 = p; *p != '\0' && *p != pc; ++p) {}
@$737:
		mov di, si
@$738:
		mov al, byte [si]
		test al, al
		je @$739
		cmp cl, al
		je @$739
		inc si
		jmp @$738

;             if (*p == '\0') goto missing_quotes_in_include;
@$739:
		cmp byte [si], 0
		je @$736

;             if (!check_end(p + 1)) goto after_line;
		lea ax, [si+1]
		call near check_end_
		test ax, ax
		je @$747

;             liner = (char*)p;
		mov word [bp-0x1a], si

;             include = 1;
		mov byte [bp-6], 1

;         } else if ((pc = casematch(instr_name, "%DEFINE")) != 0 || casematch(instr_name, "%ASSIGN")) {
@$740:
		jmp @$747
@$741:
		mov dx, @$1000
		mov ax, _instr_name
		call near casematch_
		mov cl, al
		test al, al
		jne @$742
		mov dx, @$1001
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$748

;             for (p3 = p; *p3 != '\0' && !isspace(*p3); ++p3) {}
@$742:
		mov di, si
@$743:
		mov al, byte [di]
		test al, al
		je @$744
		xor ah, ah
		call near isspace_
		test ax, ax
		jne @$744
		inc di
		jmp @$743

;             set_macro((char*)p - 1, (char*)p3, p3, (char)(pc ? MACRO_SET_DEFINE : MACRO_SET_ASSIGN));
@$744:
		test cl, cl
		je @$745
		mov cx, 3
		jmp @$746
@$745:
		mov cx, 0x13
@$746:
		xor ch, ch
		lea ax, [si-1]
		mov bx, di
		mov dx, di
		call near set_macro_

;         } else if (casematch(instr_name, "%UNDEF")) {
@$747:
		jmp near @$751
@$748:
		mov dx, @$1002
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$749

;             unset_macro((char*)p - 1);
		lea ax, [si-1]
		call near unset_macro_

;         } else if (casematch(instr_name, "%LINE")) {  /* Just ignore. */
		jmp @$747
@$749:
		mov dx, @$1003
		mov ax, _instr_name
		call near casematch_
		test al, al
		jne @$751

;         } else {
;             MESSAGE1STR(1, "Unknown preprocessor directive: %s", instr_name);
		mov dx, _instr_name
		mov ax, @$1004
@$750:
		call near message1str_

;         }
@$751:
		cmp word [_assembler_pass], 1
		jbe @$753
		cmp word [_listing_fd], 0
		jl @$753
		push word [bp-0x30]
		push word [bp-0x1e]
		mov ax, @$1034
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 8
		mov si, word [_generated_ptr]
@$752:
		cmp si, word [_generated_cur]
		jae @$754
		mov al, byte [si]
		xor ah, ah
		push ax
		mov ax, @$1035
		push ax
		mov ax, _message_bbb
		push ax
		inc si
		call near bbprintf_
		add sp, 6
		jmp @$752
@$753:
		jmp near @$756
@$754:
		cmp si, _generated_buf+8
		jae @$755
		mov ax, @$1036
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 4
		inc si
		jmp @$754
@$755:
		push word [bp-0x28]
		push word [_line_number+2]
		push word [_line_number]
		mov ax, @$1037
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 0xa
@$756:
		mov al, byte [bp-6]
		cmp al, 1
		jne @$757
		mov ax, word [bp-0x10]
		test ax, ax
		je @$758
		sub ax, word [bp-0x20]
		sub ax, word [bp-0x24]
		cwd
		mov cx, dx
		mov dx, 1
		mov bx, ax
		mov ax, word [bp-0x16]
		call near lseek_
		mov bx, word [bp-0xc]
		mov word [bx], ax
		mov word [bx+2], dx
		mov dx, word [bx]
		mov ax, word [bx+2]
		test ax, ax
		jge @$758
		mov ax, @$1038
		jmp near @$866
@$757:
		jmp near @$851
@$758:
		mov ax, word [bp-0x16]
		call near close_
		mov ax, word [bp-0xa]
		mov bx, word [bp-0xc]
		mov word [bx+4], ax
		mov ax, word [bp-0x26]
		mov word [bx+6], ax
		mov ax, word [bp-0xe]
		mov word [bx+8], ax
		mov ax, word [bp-8]
		mov word [bx+0xa], ax
		mov ax, word [_line_number]
		mov dx, word [_line_number+2]
		mov word [bx+0xc], ax
		mov word [bx+0xe], dx
		mov bx, word [bp-0x1a]
		mov byte [bx], 0
		mov word [bp-0x32], di
		jmp near @$634

;         goto after_line;
;       not_preproc:
; 
;         /* Parse and process label, if any. */
;         if ((p3 = match_label_prefix(p)) != NULL && p3[0] != '\0' && (psave = avoid_spaces(p3 + 1), p3[0] == ':' || (p3[0] == ' ' && (p[0] == '$' || (is_colonless_instruction(psave)
@$759:
		mov ax, si
		call near match_label_prefix_
		mov bx, ax
		mov di, ax
		test ax, ax
		jne @$761
@$760:
		jmp near @$776
@$761:
		cmp byte [bx], 0
		je @$760
		inc ax
		call near avoid_spaces_
		mov word [bp-0x2c], ax
		cmp byte [bx], 0x3a
		je @$762
		cmp byte [bx], 0x20
		jne @$760
		cmp byte [si], 0x24
		je @$762
		call near is_colonless_instruction_
		test ax, ax
		je @$760

;             /* && !is_colonless_instruction(p) */ ))))) {  /* !is_colonless_instruction(p) is implied by match_label_prefix(p) */
;             if (p[0] == '$') ++p;
@$762:
		cmp byte [si], 0x24
		jne @$763
		inc si

;             rc = p3[0];
@$763:
		mov ch, byte [di]

;             if ((pc = casematch(psave, "EQU!")) != 0) psave = match_expression(psave + 3);  /* EQU. */
		mov dx, @$931
		mov ax, word [bp-0x2c]
		call near casematch_
		mov cl, al
		test al, al
		je @$764
		mov ax, word [bp-0x2c]
		add ax, 3
		call near match_expression_
		mov word [bp-0x2c], ax

;             if ((pc && p[0] != '.') ||  /* If it's an `EQU' for a non-local label, then use the specified label as a global label, and don't change global_label. */
@$764:
		test cl, cl
		je @$765
		cmp byte [si], 0x2e
		jne @$766
@$765:
		cmp byte [si], 0x2e
		jne @$767
		cmp byte [si+1], 0x2e
		jne @$767
		cmp byte [si+2], 0x40
		jne @$767

;                 (p[0] == '.' && p[1] == '.' && p[2] == '@')  /* If the label name starts with a `:', then use the specified label as a global label, and don't change global_label. */
;                ) {
;                 liner = (char*)p;
@$766:
		mov word [bp-0x1a], si

;                 ((char*)p3)[0] = '\0';  /* ASCIIZ string terminator after tha label. We'll restore the original byte from rc later. */
		mov byte [di], 0

;             } else {
		jmp @$771

;                 liner = (/*pc ||*/ p[0] == '.') ? global_label_end : global_label;  /* If label starts with '.', then prepend global_label. */
@$767:
		cmp byte [si], 0x2e
		jne @$768
		mov ax, word [_global_label_end]
		mov word [bp-0x1c], ax
		jmp @$769
@$768:
		mov word [bp-0x1c], _global_label

; #if CONFIG_USE_MEMCPY_INLINE  /* A few bytes smaller than memcpy(...). */
;                 /* Calling memcpy_newdest_inline(...) or memcpy_void_inline(...) instead here would add 127 bytes to the program, so we are not doing it. OpenWatcom optimization is weird. */
;                 memcpy_void_my(liner, p, p3 - p);
@$769:
		mov ax, di
		sub ax, si
		mov word [bp-0x2e], ax
		mov bx, ax
		mov dx, si
		mov ax, word [bp-0x1c]
		call near memcpy_void_my_

; #else
;                 memcpy(liner, p, p3 - p);
; #endif
;                 liner += p3 - p;
		mov bx, word [bp-0x1c]
		add bx, word [bp-0x2e]
		mov word [bp-0x1a], bx

;                 *liner = '\0';
		mov byte [bx], 0

;                 if (p[0] != '.') global_label_end = liner;
		cmp byte [si], 0x2e
		je @$770
		mov word [_global_label_end], bx

;                 liner = global_label;
@$770:
		mov word [bp-0x1a], _global_label

;             }
;             p = psave;
@$771:
		mov si, word [bp-0x2c]

;             if (pc) {  /* EQU. */
		test cl, cl
		je @$773

;                 if (p == NULL) {
		test si, si
		jne @$772

;                     MESSAGE(1, "bad expression");
		mov ax, @$1005
		call near message_

;                 } else {
		jmp @$774

;                     check_end(p);
@$772:
		mov ax, si
		call near check_end_

;                     p = NULL;
		xor si, si

;                 }
		jmp @$774

;                 /* Create the label even if p was NULL (bad expression or check_end(p) has failed. It doesn't matter. */
;             } else {
;                 instruction_value = current_address;
@$773:
		mov dx, word [_current_address]
		mov ax, word [_current_address+2]
		mov word [_instruction_value], dx
		mov word [_instruction_value+2], ax

;             }
;             create_label(liner);
@$774:
		mov ax, word [bp-0x1a]
		call near create_label_

;             *global_label_end = '\0';  /* Undo the concat to global_label. */
		mov bx, word [_global_label_end]
		mov byte [bx], 0

;             ((char*)p3)[0] = rc;  /* Undo the change: back from ASCII string terminator '\0' to the original character in the source line. */
		mov byte [di], ch

;             if (p == NULL) goto after_line;
		test si, si
		jne @$776
@$775:
		jmp near @$751

;         }
; 
;         /* Process command (non-preprocessor, non-label). */
;         if (p[0] == '\0') {
@$776:
		mov al, byte [si]
		test al, al
		je @$775

;             goto after_line;
;         } else if (!isalpha(p[0])) {
		xor ah, ah
		call near isalpha_
		test ax, ax
		jne @$777

;             MESSAGE(1, "Instruction expected");
		mov ax, @$1006
		jmp near @$786

;             goto after_line;
;         }
;         p = separate(p3 = p);
@$777:
		mov di, si
		mov ax, si
		call near separate_
		mov bx, ax
		mov si, ax

;         if (casematch(instr_name, "USE16")) {
		mov dx, @$1007
		mov ax, _instr_name
		call near casematch_
		test al, al
		jne @$775

;         } else if (casematch(instr_name, "CPU")) {
		mov dx, @$1008
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$782

;             if (casematch(p, "8086")) {
		mov dx, @$1009
		mov ax, bx
		call near casematch_
		test al, al
		je @$778

;                 cpu_level = 0;
		mov byte [_cpu_level], 0

;             } else if (casematch(p, "186")) {
		jmp @$775
@$778:
		mov dx, @$1010
		mov ax, bx
		call near casematch_
		test al, al
		je @$779

;                 cpu_level = 1;
		mov byte [_cpu_level], 1

;             } else {
		jmp @$775

;                 cpu_level = 0xff;
@$779:
		mov byte [_cpu_level], 0xff

;                 if (SUB_U(*p, '3') <= '9' - '3' + 0U && casematch(p + 1, "86")) {  /* Disallow `cpu 386', ..., `cpu 986'. Actually, `cpu 786', `cpu 886' and `cpu 986' are not valid in NASM. */
		mov al, byte [bx]
		xor ah, ah
		sub ax, 0x33
		cmp ax, 6
		ja @$775
		mov dx, @$1011
		lea ax, [bx+1]
		call near casematch_
		test al, al
		jne @$781
@$780:
		jmp near @$751

;                     MESSAGE(1, "Unsupported processor requested");
@$781:
		mov ax, @$1012
		jmp @$786

;                 }
;             }
;         } else if (casematch(instr_name, "BITS")) {
@$782:
		mov dx, @$1013
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$789

;             p = match_expression(p);
		mov ax, bx
		call near match_expression_
		mov si, ax

;             if (p == NULL) {
		test ax, ax
		jne @$784

;                 MESSAGE(1, "Bad expression");
@$783:
		mov ax, @$964
		jmp @$786

;             } else if (has_undefined) {
@$784:
		cmp byte [_has_undefined], 0
		je @$787

;                 MESSAGE(1, "Cannot use undefined labels");
@$785:
		mov ax, @$975
@$786:
		call near message_
		jmp @$780

;             } else if (instruction_value != 16) {
@$787:
		cmp word [_instruction_value+2], 0
		jne @$788
		cmp word [_instruction_value], 0x10
		jne @$788
		jmp near @$698

;                 MESSAGE(1, "Unsupported BITS requested");
@$788:
		mov ax, @$1014
		jmp @$786

;             } else {
;                 check_end(p);
;             }
;         } else if (casematch(instr_name, "INCBIN")) {
@$789:
		mov dx, @$1015
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$793

;             pc = *p++;
		mov cl, byte [bx]
		lea si, [bx+1]

;             if (pc != '"' && pc != '\'') {
		cmp cl, 0x22
		je @$791
		cmp cl, 0x27
		je @$791

;               missing_quotes_in_incbin:
;                 MESSAGE(1, "Missing quotes in INCBIN");
@$790:
		mov ax, @$1016
		jmp @$786

;                 goto after_line;
;             }
;             for (p3 = p; *p != '\0' && *p != pc; ++p) {}
@$791:
		mov di, si
@$792:
		mov al, byte [si]
		test al, al
		je @$794
		cmp cl, al
		je @$794
		inc si
		jmp @$792
@$793:
		jmp near @$806

;             if (*p == '\0') goto missing_quotes_in_incbin;
@$794:
		cmp byte [si], 0
		je @$790

;             liner = (char*)p;
		mov word [bp-0x1a], si

;             incbin_offset = 0;
		xor ax, ax
		mov word [bp-0x18], ax
		mov word [bp-0x14], ax

;             incbin_size = -1;  /* Unlimited. */
		mov ax, 0xffff
		mov word [bp-0x2a], ax
		mov word [bp-0x12], ax

;             if (*(p = avoid_spaces(p + 1)) == ',') {
		lea ax, [si+1]
		call near avoid_spaces_
		mov bx, ax
		cmp byte [bx], 0x2c
		jne @$803

;                 p = match_expression(p + 1);
		inc ax
		call near match_expression_

;                 if (p == NULL) {
		test ax, ax
		jne @$796
@$795:
		jmp near @$783

;                     MESSAGE(1, "Bad expression");
;                     goto after_line;
;                 } else if (has_undefined) {
@$796:
		cmp byte [_has_undefined], 0
		je @$798
@$797:
		jmp near @$785

;                     MESSAGE(1, "Cannot use undefined labels");
;                     goto after_line;
;                 } else if (instruction_value < 0) {
@$798:
		cmp word [_instruction_value+2], 0
		jge @$800

;                     MESSAGE(1, "INCBIN value is negative");
@$799:
		mov ax, @$1017
		jmp near @$786

;                     goto after_line;
;                 } else {
;                     incbin_offset = instruction_value;
@$800:
		mov dx, word [_instruction_value]
		mov word [bp-0x18], dx
		mov dx, word [_instruction_value+2]
		mov word [bp-0x14], dx

;                     if (*(p = avoid_spaces(p)) == ',') {
		call near avoid_spaces_
		mov bx, ax
		cmp byte [bx], 0x2c
		jne @$804

;                         p = match_expression(p + 1);
		inc ax
		call near match_expression_

;                         if (p == NULL) {
		test ax, ax
		je @$795

;                             MESSAGE(1, "Bad expression");
;                             goto after_line;
;                         } else if (has_undefined) {
		cmp byte [_has_undefined], 0
		jne @$797

;                             MESSAGE(1, "Cannot use undefined labels");
;                             goto after_line;
;                         } else if (!check_end(p)) {
		call near check_end_
		test ax, ax
		jne @$802
@$801:
		jmp near @$751

;                             goto after_line;
;                         } else if (instruction_value < 0) {
@$802:
		mov ax, word [_instruction_value+2]
		test ax, ax
		jl @$799

;                             MESSAGE(1, "INCBIN value is negative");
;                             goto after_line;
;                         } else {
;                             incbin_size = instruction_value;
		mov ax, word [_instruction_value]
		mov word [bp-0x2a], ax
		mov ax, word [_instruction_value+2]
		mov word [bp-0x12], ax

;                         }
;                     } else if (!check_end(p)) {
@$803:
		jmp @$805
@$804:
		call near check_end_
		test ax, ax
		je @$801

;                         goto after_line;
;                     }
;                 }
;             }
;             include = 2;
@$805:
		mov byte [bp-6], 2

;         } else if (casematch(instr_name, "ORG")) {
		jmp @$801
@$806:
		mov dx, @$1018
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$811

;             p = match_expression(p);
		mov ax, bx
		call near match_expression_
		mov si, ax

;             if (p != NULL) check_end(p);
		test ax, ax
		je @$807
		call near check_end_

;             if (p == NULL) {
@$807:
		test si, si
		jne @$808
		jmp near @$783

;                 MESSAGE(1, "Bad expression");
;             } else if (has_undefined) {
@$808:
		cmp byte [_has_undefined], 0
		je @$809
		jmp near @$785

;                 MESSAGE(1, "Cannot use undefined labels");
;             } else if (is_start_address_set) {
@$809:
		cmp byte [_is_start_address_set], 0
		je @$812

;                 if (instruction_value != default_start_address) {
		mov ax, word [_instruction_value]
		mov dx, word [_instruction_value+2]
		cmp dx, word [_default_start_address+2]
		jne @$810
		cmp ax, word [_default_start_address]
		je @$801

;                     MESSAGE(1, "program origin redefined");  /* Same error as in NASM. */
@$810:
		mov ax, @$1019
		call near message_

;                     aip = (struct assembly_info*)assembly_stack;  /* Also abort %includers. */
		mov word [bp-0xc], _assembly_stack

;                     goto close_return;
		jmp near @$867
@$811:
		jmp @$816

;                 }
;             } else {
;                 is_start_address_set = 1;
@$812:
		mov byte [_is_start_address_set], 1

;                 if (instruction_value != default_start_address) {
		mov dx, word [_instruction_value]
		mov ax, word [_instruction_value+2]
		cmp ax, word [_default_start_address+2]
		jne @$814
		cmp dx, word [_default_start_address]
		jne @$814
@$813:
		jmp near @$751

;                     default_start_address = instruction_value;
@$814:
		mov word [_default_start_address], dx
		mov word [_default_start_address+2], ax

;                     if (is_address_used) {
		cmp byte [_is_address_used], 0
		je @$815

;                         /* Currently we are at assembler_pass == 0 (because
;                          * we have !is_start_address_set, and before
;                          * assembler_pass == 2 we set is_start_address_set
;                          * to true), we set start_address after it has been
;                          * used (as indicated by is_address_used). Thus all
;                          * such previous uses are wrong, and we need to do
;                          * another assembler pass to fix it. Usually we set
;                          * change = 1 to ask for a next pass, but currently
;                          * it's not necessary, because we always,
;                          * unconditionally do assembler_pass == 2.
;                          */
;                         /*change = 1;*/
;                         /* We want to delete all labels between
;                          * assembler_pass == 0 and == 2, to accelerate fixed
;                          * point convergence of optimization, and also to
;                          * make code size growing (rather than shrinking).
;                          * More specifically, pass 2 starts at a different
;                          * start_address, and jump target labels produced by
;                          * pass 1 are way to much off (by `start_address'),
;                          * thus pas 2 would generate 5-byte conditional
;                          * jumps everywhere, thus file size will shrink from
;                          * that (to 2 bytes for some conditional jumps) only
;                          * after pass 2. But we want growing rather than
;                          * shrinking, and we get this by discarding all labels
;                          * and doing pass 1.
;                          */
;                         do_special_pass_1 = 1;
		mov byte [_do_special_pass_1], 1

;                     } else {
		jmp @$813

;                         reset_address();
@$815:
		call near reset_address_

;                     }
		jmp @$813

;                 }
;             }
;         } else if (casematch(instr_name, "SECTION")) {
@$816:
		mov dx, @$1020
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$821

;             for (p3 = ".bss ", liner = (char*)p; p3[0] != '\0'; ++p, ++p3) {
		mov di, @$1021
		mov word [bp-0x1a], bx
@$817:
		cmp byte [di], 0
		je @$818

;               if (p[0] != p3[0]) goto unsupported_section;  /* Case sensitive match of section name, like in NASM. */
		mov al, byte [si]
		cmp al, byte [di]
		jne @$819

;             }
		inc si
		inc di
		jmp @$817

;             if (!casematch(avoid_spaces(p), "ALIGN=1")) {
@$818:
		mov ax, si
		call near avoid_spaces_
		mov dx, @$1022
		call near casematch_
		test al, al
		jne @$820

;               unsupported_section:
;                 MESSAGE1STR(1, "Unsupported SECTION: %s", liner);
@$819:
		mov dx, word [bp-0x1a]
		mov ax, @$1023
		jmp near @$750

;             } else if (!is_bss) {
@$820:
		cmp byte [bp-4], 0
		jne @$813

;                 is_bss = 1;
		mov al, 1
		mov byte [bp-4], al

;                 is_address_used = 1;
		mov byte [_is_address_used], al

;                 start_address = current_address;
		mov dx, word [_current_address]
		mov ax, word [_current_address+2]
		mov word [_start_address], dx
		mov word [_start_address+2], ax

;             }
		jmp @$813

;         } else if (casematch(instr_name, "ABSOLUTE")) {
@$821:
		mov dx, @$1024
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$823

;             if (!casematch(p, "$")) {
		mov dx, @$1025
		mov ax, bx
		call near casematch_
		test al, al
		jne @$822

;                 MESSAGE1STR(1, "Unsupported ABSOLUTE: %s", p);
		mov dx, bx
		mov ax, @$1026
		jmp near @$750

;             } else {
;                 is_bss = 1;
@$822:
		mov byte [bp-4], 1

;             }
		jmp near @$751

;         } else if (is_bss) {
@$823:
		cmp byte [bp-4], 0
		je @$828

;             if (casematch(instr_name, "RES#")) {
		mov dx, @$1027
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$835

;                 /* We also could add RESW, RESD, ALIGNB, but the user can implement them in terms of RESB. */
;                 p = match_expression(p);
		mov ax, bx
		call near match_expression_

;                 if (p == NULL) {
		test ax, ax
		jne @$825
@$824:
		jmp near @$783

;                     MESSAGE(1, "Bad expression");
;                 } else if (has_undefined) {
@$825:
		cmp byte [_has_undefined], 0
		je @$827
@$826:
		jmp near @$785

;                     MESSAGE(1, "Cannot use undefined labels");
;                 } else if (instruction_value < 0) {
@$827:
		cmp word [_instruction_value+2], 0
		jge @$829

;                     MESSAGE(1, "RESB value is negative");
		mov ax, @$1028
		jmp near @$786
@$828:
		jmp @$836

;                 } else if (!check_end(p)) {
@$829:
		call near check_end_
		test ax, ax
		jne @$831
@$830:
		jmp near @$751

;                 } else {
;                     pc = instr_name[3] & ~32;
@$831:
		mov cl, byte [_instr_name+3]
		and cl, 0xdf

;                     if (pc == 'W'
		cmp cl, 0x57
		je @$832
		cmp cl, 0x44
		jne @$833

; #if CONFIG_VALUE_BITS == 32
;                         || pc == 'D'
; #endif
;                        ) {
;                         instruction_value <<= 1;
@$832:
		shl word [_instruction_value], 1
		rcl word [_instruction_value+2], 1

;                     }
; #if CONFIG_VALUE_BITS == 32
;                     if (pc == 'D') instruction_value <<= 1;
@$833:
		cmp cl, 0x44
		jne @$834
		shl word [_instruction_value], 1
		rcl word [_instruction_value+2], 1

; #endif
;                     current_address += instruction_value;
@$834:
		mov ax, word [_instruction_value]
		mov dx, word [_instruction_value+2]
		add word [_current_address], ax
		adc word [_current_address+2], dx

;                 }
		jmp @$830

;             } else {
;                 MESSAGE1STR(1, "Unsupported .bss instrucction: %s", instr_name);
@$835:
		mov dx, _instr_name
		mov ax, @$1029
		jmp near @$750

;             }
;         } else if (casematch(instr_name, "ALIGN")) {
@$836:
		mov dx, @$1030
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$840

;             p = match_expression(p);
		mov ax, bx
		call near match_expression_
		mov si, ax

;             if (p == NULL) {
		test ax, ax
		je @$824

;                 MESSAGE(1, "Bad expression");
;             } else if (has_undefined) {
		cmp byte [_has_undefined], 0
		jne @$826

;                 MESSAGE(1, "Cannot use undefined labels");
;             } else if (instruction_value <= 0) {
		mov ax, word [_instruction_value+2]
		test ax, ax
		jl @$837
		jne @$838
		cmp word [_instruction_value], 0
		ja @$838

;                 MESSAGE(1, "ALIGN value is not positive");
@$837:
		mov ax, @$1031
		jmp near @$786

;             } else {
;                 /* NASM 0.98.39 does the wrong thing if instruction_value is not a power of 2. Newer NASMs report an error. mininasm just works. */
;                 times = (uvalue_t)current_address % instruction_value;
@$838:
		mov ax, word [_current_address]
		mov dx, word [_current_address+2]
		mov bx, word [_instruction_value]
		mov cx, word [_instruction_value+2]
		call near __U4D
		mov dx, cx
		mov word [bp-0x22], bx

;                 if (times != 0) times = instruction_value - times;
		or dx, bx
		je @$839
		mov ax, word [_instruction_value]
		sub ax, bx
		mov word [bp-0x22], ax
		mov ax, word [_instruction_value+2]
		sbb ax, cx
		mov cx, ax

;                 p = avoid_spaces(p);
@$839:
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;                 if (p[0] == ',') {
		cmp byte [si], 0x2c
		jne @$841

;                     ++p;
		inc si

;                     goto do_instruction_with_times;  /* This doesn't work correctly if the instruction at `p' doesn't emit exiacty 1 byte. That's fine, same as for NASM. */
		jmp @$849
@$840:
		jmp @$845

;                 }
;                 check_end(p);
@$841:
		call near check_end_

;                 for (; (uvalue_t)times != 0; --times) {
@$842:
		mov ax, word [bp-0x22]
		or ax, cx
		jne @$844
@$843:
		jmp near @$751

;                     emit_byte(0x90);
@$844:
		mov ax, 0x90
		call near emit_byte_func_

;                 }
		add word [bp-0x22], 0xffff
		adc cx, 0xffff
		jmp @$842

;             }
;         } else {
;             times = 1;
@$845:
		mov word [bp-0x22], 1
		xor cx, cx

;             if (casematch(instr_name, "TIMES")) {
		mov dx, @$1032
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$848

;                 p3 = match_expression(p);
		mov ax, bx
		call near match_expression_
		mov di, ax

;                 if (p3 == NULL) {
		test ax, ax
		jne @$846
		jmp near @$783

;                     MESSAGE(1, "Bad expression");
;                     goto after_line;
;                 }
;                 if (has_undefined) {
@$846:
		cmp byte [_has_undefined], 0
		je @$847
		jmp near @$785

;                     MESSAGE(1, "Cannot use undefined labels");
;                     goto after_line;
;                 }
;                 if ((value_t)(times = instruction_value) < 0) {
@$847:
		mov ax, word [_instruction_value]
		mov word [bp-0x22], ax
		mov cx, word [_instruction_value+2]
		test cx, cx
		jge @$848

;                     MESSAGE(1, "TIMES value is negative");
		mov ax, @$1033
		jmp near @$786

;                     goto after_line;
;                 }
;             }
;             p = p3;
@$848:
		mov si, di

;           do_instruction_with_times:
;             line_address = current_address;
@$849:
		mov ax, word [_current_address]
		mov word [bp-0x1e], ax
		mov ax, word [_current_address+2]
		mov word [bp-0x30], ax

;             generated_cur = generated_ptr;
		mov ax, word [_generated_ptr]
		mov word [_generated_cur], ax

;             for (; (uvalue_t)times != 0; --times) {
@$850:
		mov ax, word [bp-0x22]
		or ax, cx
		je @$843

;                 process_instruction(p);
		mov ax, si
		call near process_instruction_

;             }
		add word [bp-0x22], 0xffff
		adc cx, 0xffff
		jmp @$850

;         }
;       after_line:
;         if (assembler_pass > 1 && listing_fd >= 0) {
;             bbprintf(&message_bbb /* listing_fd */, "%04" FMT_VALUE "X  ", GET_UVALUE(line_address));
;             p = generated_ptr;
;             while (p < generated_cur) {
;                 bbprintf(&message_bbb /* listing_fd */, "%02X", *p++ & 255);
;             }
;             while (p < generated_buf + sizeof(generated_buf)) {
;                 bbprintf(&message_bbb /* listing_fd */, "  ");
;                 p++;
;             }
;             /* TODO(pts): Keep the original line with the original comment, if possible. This is complicated and needs more memory. */
;             bbprintf(&message_bbb /* listing_fd */, "  %05" FMT_VALUE "u %s\r\n", GET_UVALUE(line_number), line);
;         }
;         if (include == 1) {  /* %INCLUDE. */
;             if (0) DEBUG1("INCLUDE %s\r\n", p3);  /* Not yet NUL-terminated early. */
;             if (linep != NULL && (aip->file_offset = lseek(input_fd, (linep - line_rend) - discarded_after_read, SEEK_CUR)) < 0) {  /* TODO(pts): We should check for overflow for source files >= 2 GiB. */
;                 MESSAGE(1, "Cannot seek in source file");
;                 goto close_return;
;             }
;             close(input_fd);
;             aip->level = level;
;             aip->avoid_level = avoid_level;
;             aip->line_number = line_number;
;             *liner = '\0';
;             input_filename = p3;
;             goto do_assembly_push;
;         } else if (include == 2) {  /* INCBIN. */
@$851:
		cmp al, 2
		je @$853
@$852:
		jmp near @$640

;             *liner = '\0';  /* NUL-terminate the filename in p3. It's OK, we've already written the line to listing_fd. */
@$853:
		mov bx, word [bp-0x1a]
		mov byte [bx], 0

;             if (HAS_OPEN_FAILED(incbin_fd = open2(p3, O_RDONLY | O_BINARY))) {
		xor dx, dx
		mov ax, di
		call near open2_
		mov si, ax
		test ax, ax
		jge @$854

;                 MESSAGE1STR(1, "Error: Cannot open '%s' for input", p3);
		mov dx, di
		mov ax, @$1039
		call near message1str_

;             } else {
		jmp @$852

;                 if (incbin_offset != 0 && lseek(incbin_fd, incbin_offset, SEEK_SET) != incbin_offset) {
@$854:
		mov dx, word [bp-0x14]
		or dx, word [bp-0x18]
		je @$857
		xor dx, dx
		mov bx, word [bp-0x18]
		mov cx, word [bp-0x14]
		call near lseek_
		cmp dx, word [bp-0x14]
		jne @$855
		cmp ax, word [bp-0x18]
		je @$857

;                     MESSAGE1STR(1, "Cannot seek in INCBIN file: ", p3);
@$855:
		mov dx, di
		mov ax, @$1040
@$856:
		call near message1str_

;                 } else {
		jmp @$863

;                     message_flush(NULL);  /* Because we reuse message_buf below. */
@$857:
		xor ax, ax
		call near message_flush_

;                     generated_cur = NULL;  /* Doesn't make an actual difference, incbin is called too late to append to incbin anyway. */
		xor ax, ax
		mov word [_generated_cur], ax

;                     /* Condition below is good even if incbin_size == -1 (unlimited). */
;                     while (incbin_size != 0) {
@$858:
		mov ax, word [bp-0x12]
		or ax, word [bp-0x2a]
		je @$863

;                         if ((got = read(incbin_fd, message_buf, (uvalue_t)incbin_size < sizeof(message_buf) ? (unsigned)incbin_size : sizeof(message_buf))) <= 0) {
		cmp word [bp-0x12], 0
		jne @$859
		cmp word [bp-0x2a], 0x200
		jae @$859
		mov bx, word [bp-0x2a]
		jmp @$860
@$859:
		mov bx, 0x200
@$860:
		mov dx, _message_buf
		mov ax, si
		call near read_
		mov bx, ax
		test ax, ax
		jg @$861

;                             if (got < 0) MESSAGE1STR(1, "Error: Error reading from '%s'", p3);
		jge @$863
		mov dx, di
		mov ax, @$1041
		jmp @$856

;                             break;
;                         }
;                         emit_bytes(message_buf, got);
@$861:
		mov dx, ax
		mov ax, _message_buf
		call near emit_bytes_

;                         if (incbin_size != -1) incbin_size -= got;
		cmp word [bp-0x12], 0xffff
		jne @$862
		cmp word [bp-0x2a], 0xffff
		je @$858
@$862:
		mov ax, bx
		cwd
		sub word [bp-0x2a], ax
		sbb word [bp-0x12], dx
		jmp @$858

;                     }
;                 }
;                 close(incbin_fd);
@$863:
		mov ax, si
		call near close_

;             }
		jmp near @$640

;         }
;     }
;     if (level != 1) {
@$864:
		cmp word [bp-0x26], 0
		jne @$865
		cmp word [bp-0xa], 1
		je @$867

;         MESSAGE(1, "pending %IF at end of file");
@$865:
		mov ax, @$1042
@$866:
		call near message_

;     }
;   close_return:
;     close(input_fd);
@$867:
		mov ax, word [bp-0x16]
		call near close_

;     if ((aip = assembly_pop(aip)) != NULL) goto do_open_again;  /* Continue processing the input file which %INCLUDE()d the current input file. */
		mov ax, word [bp-0xc]
		call near assembly_pop_
		mov word [bp-0xc], ax
		test ax, ax
		je @$868
		jmp near @$635

;     line_number = 0;  /* Global variable. */
@$868:
		mov word [_line_number], ax
		mov word [_line_number+2], ax

; }
		jmp near @$87

; 
; static MY_STRING_WITHOUT_NUL(mininasm_macro_name, " __MININASM__");
; 
; #ifndef CONFIG_MAIN_ARGV
; #define CONFIG_MAIN_ARGV 0
; #endif
; 
; /*
;  ** Main program
;  */
; #if CONFIG_MAIN_ARGV
; int main_argv(char **argv)
; #else
; int main(int argc, char **argv)
main_:
		push bx
		push cx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		push ax
		mov si, dx

; #endif
; {
;     int d;
;     const char *p;
;     char *ifname;
;     char *listing_filename;
;     value_t prev_address;
; #if !CONFIG_MAIN_ARGV
;     (void)argc;
; #endif
; 
; #if (defined(MSDOS) || defined(_WIN32)) && !defined(__DOSMC__)
;     setmode(2, O_BINARY);  /* STDERR_FILENO. */
; #endif
; 
; #if 0
;     malloc_init();
;     MESSAGE_START(1);
;     bbprintf(&message_bbb, "malloc_p_para=0x%04x malloc_end_para=%04x", ((const unsigned*)&__malloc_struct__.malloc_p)[1], __malloc_struct__.malloc_end_para);
;     message_end();
; #endif
; 
;     /*
;      ** If ran without arguments then show usage
;      */
;     if (*++argv == NULL) {
		inc si
		inc si
		cmp word [si], 0
		jne @$869

;         static const MY_STRING_WITHOUT_NUL(msg, "Typical usage:\r\nmininasm -f bin input.asm -o input.bin\r\n");
;         (void)!write(2, (char*)msg, STRING_SIZE_WITHOUT_NUL(msg));  /* Without the (char*), Borland C++ 2.0 reports warning: Suspicious pointer conversion in function main */
		mov bx, 0x38
		mov dx, @$usage
		mov ax, 2
		call near write_
		jmp near @$926

;         return 1;
;     }
; 
;     /*
;      ** Start to collect arguments
;      */
;     ifname = NULL;
@$869:
		xor ax, ax
		mov word [bp-2], ax

;     /* output_filename = NULL; */  /* Default. */
;     listing_filename = NULL;
		mov word [bp-4], ax

;     /* default_start_address = 0; */  /* Default. */
;     /* is_start_address_set = 0; */  /* Default. */
;     malloc_init();
		mov ax, ds
		add ax, ___sd_top__
		mov word [___malloc_struct__+4], ax
		mov ax, cs
		dec ax
		mov es, ax
		inc ax
		add ax, word [es:3]
		mov word [___malloc_struct__], ax

;     set_macro(mininasm_macro_name, mininasm_macro_name + STRING_SIZE_WITHOUT_NUL(mininasm_macro_name), "5", MACRO_SET_DEFINE_CMDLINE);  /* `%DEFINE __MININASM__ ...'. */
		mov cx, 1
		mov bx, @$1043
		mov dx, _mininasm_macro_name.end
		mov ax, _mininasm_macro_name
		call near set_macro_

;     while (argv[0] != NULL) {
@$870:
		mov ax, word [si]
		test ax, ax
		je @$875

;         if (0) DEBUG1("arg=(%s)\n", argv[0]);
;         if (argv[0][0] == '-') {    /* All arguments start with dash */
		mov bx, ax
		cmp byte [bx], 0x2d
		jne @$876

;             d = argv[0][1] | 32;  /* Flags characters are case insensitive. */
		mov dl, byte [bx+1]
		or dl, 0x20
		xor dh, dh
		mov ax, dx

;             if (d == 'd') {  /* Define macro: -DNAME and -DNAME=VALUE. -DNAME is not allowed, because macros with an empty values are nt allowed. */
		cmp dx, 0x64
		jne @$877

;                 for (p = argv[0] + 2; *p != '\0' && *p != '='; ++p) {}
		lea di, [bx+2]
@$871:
		mov al, byte [di]
		test al, al
		je @$872
		cmp al, 0x3d
		je @$872
		inc di
		jmp @$871

;                 set_macro(argv[0] + 1, (char*)p, p + (*p == '='), MACRO_SET_DEFINE_CMDLINE);
@$872:
		mov cx, 1
		cmp byte [di], 0x3d
		jne @$873
		mov bx, cx
		jmp @$874
@$873:
		xor bx, bx
@$874:
		add bx, di
		mov ax, word [si]
		inc ax
		mov dx, di
		call near set_macro_

;                 if (errors) return 1;
		mov ax, word [_errors+2]
		or ax, word [_errors]
		je @$882
		jmp near @$926
@$875:
		jmp near @$907
@$876:
		jmp near @$904

;             } else if (d == 'w') {  /* NASM warning flag, ignore. */
@$877:
		cmp dx, 0x77
		je @$885

;             } else if (argv[0][2] != '\0' && d == 'o') {  /* Optimization level (`nasm -O...'). */
		cmp byte [bx+2], 0
		je @$886
		cmp dx, 0x6f
		jne @$886

;                 d = argv[0][2];
		mov dl, byte [bx+2]
		mov ax, dx

;                 if (d == '\0' || (d != '9' && argv[0][3] != '\0')) { bad_opt_level:
		test dx, dx
		je @$878
		cmp dx, 0x39
		je @$880
		cmp byte [bx+3], 0
		je @$880

;                     MESSAGE(1, "bad optimization argument");
@$878:
		mov ax, @$1044
@$879:
		call near message_
		jmp near @$926

;                     return 1;
;                 }
;                 d |= 32;
@$880:
		or al, 0x20

;                 if (SUB_U(d, '0') <= 1U) {  /* -O0 is compatible with NASM, -O1 does some more. */
		mov dx, ax
		sub dx, 0x30
		cmp dx, 1
		ja @$883

;                     opt_level = d - '0';
		sub al, 0x30
		mov byte [_opt_level], al

;                     if (opt_level != 0) do_opt_int = 1;
		je @$889
@$881:
		mov byte [_do_opt_int], 1
@$882:
		jmp @$889

;                 } else if (d == 'x' || d == '3' || d == '9') {  /* -Ox, -O3, -O9, -O9... (compatible with NASM). We allow e.g. -O99999999 etc., for compatibility with NASM 0.98.39, where -09 can be too small, causing ``error: phase error detected at end of assembly''.. */
@$883:
		cmp ax, 0x78
		je @$884
		cmp ax, 0x33
		je @$884
		cmp ax, 0x39
		jne @$887

;                   set_opt_level_9:
;                     opt_level = 9;
@$884:
		mov byte [_opt_level], 9

;                 } else if (d == 'l') {  /* -OL (not compatible with NASM, `nasm -O9' doesn't do it) to optimize `lea', including `lea ax, [bx]' and `lea ax, [es:bx]'. */
@$885:
		jmp @$889
@$886:
		jmp @$891
@$887:
		cmp ax, 0x6c
		jne @$888

;                     do_opt_lea = 1;
		mov byte [_do_opt_lea], 1

;                 } else if (d == 'g') {  /* -OG (not compatible with NASM, `nasm -O9' doesn't do it) to optimize segment prefixes in effective addresses, e.g. ``mov ax, [ds:si]'. */
		jmp @$889
@$888:
		cmp ax, 0x67
		jne @$890

;                     do_opt_segreg = 1;
		mov byte [_do_opt_segreg], 1

;                 } else if (d == 'i') {  /* -OI (not compatible with NASM, `nasm-0.98.39 -O9' doesn't do it) to optimize integers (immediates and effective address displacements) even where NASM 0.98.39 doesn't do it, e.g. ``push 0xfffd'. */
@$889:
		jmp near @$906
@$890:
		cmp ax, 0x69
		je @$881
		cmp ax, 0x61
		jne @$878

;                     do_opt_int = 1;
;                 } else if (d == 'a') {  /* -OA to turn on all optimizations, even those which are not compatible with NASM. Equivalent to `-O9 -OL -OG -OI'. */
;                     do_opt_lea = 1;
		mov al, 1
		mov byte [_do_opt_lea], al

;                     do_opt_segreg = 1;
		mov byte [_do_opt_segreg], al

;                     do_opt_int = 1;
		mov byte [_do_opt_int], al

;                     goto set_opt_level_9;
		jmp @$884

;                 } else {
;                     goto bad_opt_level;
;                 }
;             } else if (argv[0][2] != '\0' && (d == 'f' || d == 'o' || d == 'l')) {
@$891:
		mov bx, word [si]
		cmp byte [bx+2], 0
		je @$894
		cmp ax, 0x66
		je @$892
		cmp ax, 0x6f
		je @$892
		cmp ax, 0x6c
		jne @$894

;                 MESSAGE1STR(1, "flag too long: %s", argv[0]);  /* Example: `-fbin' should be `-f bin'. */
@$892:
		mov dx, word [si]
		mov ax, @$1045
@$893:
		call near message1str_
		jmp near @$926

;                 return 1;
;             } else if (d == 'f') { /* Format */
@$894:
		lea bx, [si+2]
		cmp ax, 0x66
		jne @$899

;                 if (*++argv == NULL) {
		mov si, bx
		mov ax, word [bx]
		test ax, ax
		jne @$896

;                   error_no_argument:
;                     MESSAGE1STR(1, "no argument for %s", argv[-1]);
@$895:
		mov dx, word [si-2]
		mov ax, @$1046
		jmp @$893

;                     return 1;
;                 } else {
;                     if (casematch(argv[0], "BIN")) {
@$896:
		mov dx, @$1047
		call near casematch_
		test al, al
		je @$897

;                         default_start_address = 0;
		xor ax, ax
		mov word [_default_start_address], ax
		mov word [_default_start_address+2], ax

;                         is_start_address_set = 0;
		mov byte [_is_start_address_set], 0

;                     } else if (casematch(argv[0], "COM")) {
		jmp @$889
@$897:
		mov ax, word [bx]
		mov dx, @$1048
		call near casematch_
		test al, al
		jne @$898

;                         default_start_address = 0x100;
;                         is_start_address_set = 1;
;                     } else {
;                         MESSAGE1STR(1, "only 'bin', 'com' supported for -f (it is '%s')", argv[0]);
		mov dx, word [bx]
		mov ax, @$1049
		jmp @$893

@$898:
		mov word [_default_start_address], 0x100
		xor ax, ax
		mov word [_default_start_address+2], ax

;                         return 1;
;                     }
		mov byte [_is_start_address_set], 1
		jmp @$906

;                 }
;             } else if (d == 'o') {  /* Object file name */
@$899:
		cmp ax, 0x6f
		jne @$901

;                 if (*++argv == NULL) {
		mov si, bx
		cmp word [bx], 0
		je @$895

;                     goto error_no_argument;
;                 } else if (output_filename != NULL) {
		cmp word [_output_filename], 0
		je @$900

;                     MESSAGE(1, "already a -o argument is present");
		mov ax, @$1050
		jmp near @$879

;                     return 1;
;                 } else {
;                     output_filename = argv[0];
@$900:
		mov ax, word [bx]
		mov word [_output_filename], ax

;                 }
;             } else if (d == 'l') {  /* Listing file name */
		jmp @$906
@$901:
		cmp ax, 0x6c
		jne @$902

;                 if (*++argv == NULL) {
		mov si, bx
		cmp word [bx], 0
		je @$895

;                     goto error_no_argument;
;                     return 1;
;                 } else if (listing_filename != NULL) {
		cmp word [bp-4], 0
		je @$903

;                     MESSAGE(1, "already a -l argument is present");
		mov ax, @$1051
		jmp near @$879

;                     return 1;
;                 } else {
;                     listing_filename = argv[0];
;                 }
;             } else {
;                 MESSAGE1STR(1, "unknown argument %s", argv[0]);
@$902:
		mov dx, word [si]
		mov ax, @$1052
		jmp near @$893

;                 return 1;
;             }
@$903:
		mov ax, word [bx]
		mov word [bp-4], ax
		jmp @$906

;         } else {
;             if (0) DEBUG1("ifname=(%s)\n", argv[0]);
;             if (ifname != NULL) {
@$904:
		cmp word [bp-2], 0
		je @$905

;                 MESSAGE1STR(1, "more than one input file name: %s", argv[0]);
		mov dx, ax
		mov ax, @$1053
		jmp near @$893

;                 return 1;
;             } else {
;                 ifname = argv[0];
@$905:
		mov word [bp-2], ax

;             }
;         }
;         ++argv;
@$906:
		inc si
		inc si

;     }
		jmp near @$870

; 
;     if (ifname == NULL) {
@$907:
		cmp word [bp-2], 0
		jne @$908

;         MESSAGE(1, "No input filename provided");
		mov ax, @$1054
		jmp near @$879

;         return 1;
;     }
; 
;     /*
;      ** Do first pass of assembly, calculating offsets and labels only.
;      */
;     assembler_pass = 0;
@$908:
		mov word [_assembler_pass], ax

;     /* if (opt_level <= 1) wide_instr_add_at = NULL; */  /* No need, this is the default. */
;     reset_address();
		call near reset_address_

;     do_assembly(ifname);
		mov ax, word [bp-2]
		call near do_assembly_

;     message_flush(NULL);
		xor ax, ax
		call near message_flush_

;     if (errors) { do_remove:
		mov ax, word [_errors+2]
		or ax, word [_errors]
		jne @$913

;         remove(output_filename);
;         /* if (listing_filename != NULL) remove(listing_filename); */  /* Don't remove listing_filename, it may contain useful error messages etc. */
;     } else {
;         ++assembler_pass;  /* = 1. */
;         is_start_address_set = 1;
		mov byte [_is_start_address_set], 1

		inc word [_assembler_pass]

;         if (opt_level <= 1) {
		cmp byte [_opt_level], 1
		ja @$909

;             /* wide_instr_add_at = NULL; */  /* Keep for reading. */
;             wide_instr_read_at = NULL;
		mov word [_wide_instr_read_at], ax
		mov word [_wide_instr_read_at+2], ax

;         }
;         if (do_special_pass_1) {  /* In this special pass 1, we recompute all labels (starting with the right, final start_address) from scratch, and we don't emit any bytes. */
@$909:
		cmp byte [_do_special_pass_1], 0
		je @$910

;             reset_address();
		call near reset_address_

;             reset_macros();  /* Delete all (non-macro) labels because since do_special_pass is true. */
		call near reset_macros_

;             do_assembly(ifname);
		mov ax, word [bp-2]
		call near do_assembly_

;             ++do_special_pass_1;  /* = 2. */
		inc byte [_do_special_pass_1]

;         }
;         if (0) DEBUG2("current_address after pass %d: 0x%x\n", (unsigned)assembler_pass, (unsigned)current_address);
;         /*
;          ** Do second pass of assembly and generate final output
;          */
;         if (output_filename == NULL) {
@$910:
		cmp word [_output_filename], 0
		jne @$911

;             MESSAGE(1, "No output filename provided");
		mov ax, @$1055
		jmp near @$879

;             return 1;
;         }
;         do {
;             if (GET_U16(++assembler_pass) == 0) { do_special_pass_1 = 2; --assembler_pass; }  /* Cappped at 0xffff. */
@$911:
		inc word [_assembler_pass]
		jne @$912
		mov byte [_do_special_pass_1], 2
		dec word [_assembler_pass]

;             if (listing_filename != NULL) {
@$912:
		mov ax, word [bp-4]
		test ax, ax
		je @$915

;                 if (HAS_OPEN_FAILED(listing_fd = creat(listing_filename, 0644))) {
		mov dx, 0x1a4
		call near creat_
		mov word [_listing_fd], ax
		test ax, ax
		jge @$914

;                     MESSAGE1STR(1, "couldn't open '%s' as listing file", output_filename);
		mov dx, word [_output_filename]
		mov ax, @$1056
		jmp near @$893
@$913:
		jmp near @$925

;                     return 1;
;                 }
;                 generated_ptr = generated_buf;  /* Start saving bytes to the `generated_buf' array, for the listing. */
@$914:
		mov word [_generated_ptr], _generated_buf

;             }
;             if (HAS_OPEN_FAILED(output_fd = creat(output_filename, 0644))) {
@$915:
		mov ax, word [_output_filename]
		mov dx, 0x1a4
		call near creat_
		mov word [_output_fd], ax
		test ax, ax
		jge @$916

;                 MESSAGE1STR(1, "couldn't open '%s' as output file", output_filename);
		mov dx, word [_output_filename]
		mov ax, @$1057
		jmp near @$893

;                 return 1;
;             }
;             prev_address = current_address;
@$916:
		mov bx, word [_current_address]
		mov dx, word [_current_address+2]

;             reset_address();
		call near reset_address_

;             reset_macros();
		call near reset_macros_

;             do_assembly(ifname);
		mov ax, word [bp-2]
		call near do_assembly_

;             emit_flush(0);
		xor ax, ax
		call near emit_flush_

;             close(output_fd);
		mov ax, word [_output_fd]

;             if (0) DEBUG3("current_address after pass %d: current_address=0x%x jrb=0x%x\n", (unsigned)assembler_pass, (unsigned)current_address, (unsigned)jump_range_bits);
;             if (!have_labels_changed && jump_range_bits == 1) {
		call near close_

		cmp byte [_have_labels_changed], 0
		jne @$917
		mov al, byte [_jump_range_bits]
		cmp al, 1
		jne @$917

;                 ++jump_range_bits;  /* = 2. Report ``short jump out of range'' errors in the next pass. */
		add byte [_jump_range_bits], al

;                 ++have_labels_changed;  /* = 1. Do another pass. */
		add byte [_have_labels_changed], al

;             }
;             if (have_labels_changed) {
@$917:
		cmp byte [_have_labels_changed], 0
		je @$921

;                 if (opt_level <= 1) {
		cmp byte [_opt_level], 1
		ja @$918

;                     MESSAGE(1, "oops: labels changed");
		mov ax, @$1058

;                 } else if (current_address > prev_address) {  /* It's OK and we don't count that the size increases, converging to and eventually stabilizing at a fixed point. */
		jmp @$920
@$918:
		mov ax, word [_current_address+2]
		cmp dx, ax
		jl @$921
		jne @$919
		cmp bx, word [_current_address]
		jb @$921

;                 } else if (++size_decrease_count == 5) {  /* TODO(pts): Make this configurable? NASM also counts increasing. */
@$919:
		inc byte [_size_decrease_count]
		cmp byte [_size_decrease_count], 5
		jne @$921

;                     MESSAGE(1, "Aborted: Couldn't stabilize moving label");
		mov ax, @$1059
@$920:
		call near message_

;                 }
;             }
;             if (listing_fd >= 0) {
@$921:
		cmp word [_listing_fd], 0
		jge @$922
		jmp near @$923

;                 bbprintf(&message_bbb /* listing_fd */, "\r\n%05" FMT_VALUE "u ERRORS FOUND\r\n", GET_UVALUE(errors));
@$922:
		push word [_errors+2]
		push word [_errors]
		mov ax, @$1060
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 8

;                 bbprintf(&message_bbb /* listing_fd */, "%05" FMT_VALUE "u WARNINGS FOUND\r\n",
		xor ax, ax
		push ax
		push ax
		mov ax, @$1061
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 8

; #if CONFIG_SUPPORT_WARNINGS
;                          GET_UVALUE(warnings)
; #else
;                          GET_UVALUE(0)
; #endif
;                         );
;                 bbprintf(&message_bbb /* listing_fd */, "%05" FMT_VALUE "u PROGRAM BYTES\r\n", GET_UVALUE(bytes));
		push word [_bytes+2]
		push word [_bytes]
		mov ax, @$1062
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 8

;                 bbprintf(&message_bbb /* listing_fd */, "%05" FMT_VALUE "u ASSEMBLER PASSES\r\n\r\n", GET_UVALUE(assembler_pass) + (do_special_pass_1 & 1));
		mov al, byte [_do_special_pass_1]
		and al, 1
		xor ah, ah
		xor bx, bx
		mov dx, word [_assembler_pass]
		add ax, dx
		adc bx, bx
		push bx
		push ax
		mov ax, @$1063
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 8

;                 bbprintf(&message_bbb /* listing_fd */, "%-20s VALUE/ADDRESS\r\n\r\n", "LABEL");
		mov ax, @$1064
		push ax
		mov ax, @$1065
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 6

;                 print_labels_sorted_to_listing();
		call near print_labels_sorted_to_listing_

;                 bbprintf(&message_bbb /* listing_fd */, "\r\n");
		mov ax, @$961
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 4

;                 message_flush(NULL);
		xor ax, ax
		call near message_flush_

;                 close(listing_fd);
		mov ax, word [_listing_fd]
		call near close_

;             }
;             if (errors) goto do_remove;
@$923:
		mov ax, word [_errors+2]
		or ax, word [_errors]
		jne @$925

;         } while (have_labels_changed);
		mov al, byte [_have_labels_changed]
		test al, al
		je @$924
		jmp near @$911

;         return 0;
@$924:
		xor ah, ah
		jmp near @$339

@$925:
		mov ax, word [_output_filename]

;     }
		call near remove_

; 
;     return 1;
@$926:
		mov ax, 1

; }
		jmp near @$339

; --- C library functions based on https://github.com/pts/dosmc/tree/master/dosmclib
;
; Code in this section was written directly in WASM assmebly, and manually
; converted to NASM assembly.
___section_libc_text:


; int close(int fd);
; Optimized for size. AX == fd.
; for Unix compatibility.
close_:		push bx
		xchg ax, bx		; BX := fd; AX := junk.
		mov ah, 0x3e
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		pop bx
		ret

; int creat(const char *pathname, int mode);
; Optimized for size. AX == pathname, DX == mode.
; The value O_CREAT | O_TRUNC | O_WRONLY is used as flags.
; mode is ignored, except for bit 8 (read-only). Recommended value: 0644,
; for Unix compatibility.
creat_:		push cx
		xchg ax, dx		; DX := pathname; AX := mode.
		xor cx, cx
		test ah, 1
		jz .1
		inc cx			; CX := 1 means read-only.
.1:		mov ah, 0x3c
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		pop cx
		ret

; Implements `(long a) / (long b)' and also computes the
; modulo (%).
;
; Implementation copied from
; open-watcom-2_0-c-linux-x86-2022-05-01/lib286/dos/clibs.lib:i4d.o
__I4D:		or dx, dx
		js .1
		or cx, cx
		js .0
		jmp __U4D
.0:		neg cx
		neg bx
		sbb cx, byte 0
		call __U4D
		neg dx
		neg ax
		sbb dx, byte 0
		ret
.1:		neg dx
		neg ax
		sbb dx, byte 0
		or cx, cx
		jns .2
		neg cx
		neg bx
		sbb cx, byte 0
		call __U4D
		neg cx
		neg bx
		sbb cx, byte 0
		ret
.2:		call __U4D
		neg cx
		neg bx
		sbb cx, byte 0
		neg dx
		neg ax
		sbb dx, byte 0
		ret

; Implements `(unsigned long a) * (unsigned long b)' and `(long)a * (long b)'.
;
; Implementation copied from
; open-watcom-2_0-c-linux-x86-2022-05-01/lib286/dos/clibs.lib:i4m.o
__U4M:
__I4M:		xchg ax, bx
		push ax
		xchg ax, dx
		or ax, ax
		je .1
		mul dx
.1:		xchg ax, cx
		or ax, ax
		je .2
		mul bx
		add cx, ax
.2:		pop ax
		mul bx
		add dx, cx
		ret

; int isalpha(int c);
; Optimized for size.
isalpha_:	or al, 32		; Covert to ASCII uppercase.
		sub al, 'a'
		cmp al, 'z' - 'a' + 1
		mov ax, 0
		adc al, 0
		ret

; int isdigit(int c);
; Optimized for size.
isdigit_:	sub al, '0'
		cmp al, '9' - '0' + 1
		mov ax, 0
		adc al, 0
		ret

; int isspace(int c);
; Optimized for size.
isspace_:	sub al, 9
		cmp al, 13 - 9 + 1
		jc .done		; ASCII 9 .. 13 are whitespace.
		sub al, ' ' - 9		; ASCII ' ' is whitespace.
		cmp al, 1
.done:		mov ax, 0
		adc al, 0
		ret

; int isxdigit(int c);
; Optimized for size.
isxdigit_:	sub al, '0'
		cmp al, '9' - '0' + 1
		jc .done
		or al, 32		; Covert to ASCII uppercase.
		sub al, 'a' - '0'
		cmp al, 'f' - 'a' + 1
.done:		mov ax, 0
		adc al, 0
		ret

; off_t lseek(int fd, off_t offset, int whence);
; Optimized for size. AX == fd, CX:BX == offset, DX == whence.
lseek_:		xchg ax, bx		; BX := fd; AX := low offset.
		xchg ax, dx		; AX := whence; DX := low offset.
		mov ah, 0x42
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
		sbb dx, dx		; DX := -1.
.ok:		ret

; int open(const char *pathname, int flags, int mode);
; int open2(const char *pathname, int flags);
; Optimized for size. AX == pathname, DX == flags, BX == mode.
; Unix open(2) is able to create new files (O_CREAT), in DOS please use
; creat() for that.
; mode is ignored. Recommended value: 0644, for Unix compatibility.
open2_:
open_:		xchg ax, dx		; DX := pathname; AX := junk.
		mov ah, 0x3d
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		ret

; ssize_t read(int fd, void *buf, size_t count);
; Optimized for size. AX == fd, DX == buf, BX == count.
read_:		push cx
		xchg ax, bx		; AX := count; BX := fd.
		xchg ax, cx		; CX := count; AX := junk.
		mov ah, 0x3f
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		pop cx
		ret

; int remove(const char *fn);
; int unlink(const char *fn);
; Optimized for size.
unlink_:
remove_:	xchg dx, ax		; DX := AX, AX := junk.
		mov ah, 0x41
		int 0x21
		sbb ax, ax		; AX := -1 on error (CF), 0 otherwise.
		ret

; int strcmp_far(const char far *s1, const char far *s2);
; Assumes that offset in s1 and s2 doesn't wrap around.
; Optimized for size. DX:AX == s1, CX:BX == s2.
strcmp_far_:	push si
		push ds
		mov ds, dx
		mov es, cx
		xchg si, ax		; SI := s1, AX := junk.
		xor ax, ax
		xchg bx, di
.next:		lodsb
		scasb
		jne .diff
		cmp al, 0
		je .done
		jmp short .next
.diff:		mov al, 1
		jnc .done
		neg ax
.done:		xchg bx, di		; Restore original DI.
		pop ds
		pop si
		ret

; char far *strcpy_far(char far *dest, const char far *src);
; Assumes that offset in dest and src don't wrap around.
; Optimized for size. DX:AX == s1, CX:BX == s2.
strcpy_far_:	push di
		push ds
		mov es, dx
		mov ds, cx
		xchg bx, si
		xchg di, ax		; DI := dest; AX := junk.
		push di
.again:		lodsb
		stosb
		cmp al, 0
		jne .again
		pop ax			; Will return dest.
		xchg bx, si		; Restore SI.
		pop ds
		pop di
		ret

; size_t strlen(const char *s);
; Optimized for size.
strlen_:	push si
		xchg si, ax		; SI := AX, AX := junk.
		mov ax, -1
.again:		cmp byte [si], 1
		inc si
		inc ax
		jnc .again
		pop si
		ret

; Implements `(unsigned long a) / (unsigned long b)' and also computes the
; modulo (%).
;
; Implementation copied from
; open-watcom-2_0-c-linux-x86-2022-05-01/lib286/dos/clibs.lib:i4d.o
__U4D:		or cx, cx
		jne .5
		dec bx
		je .4
		inc bx
		cmp bx, dx
		ja .3
		mov cx, ax
		mov ax, dx
		sub dx, dx
		div bx
		xchg ax, cx
.3:		div bx
		mov bx, dx
		mov dx, cx
		sub cx, cx
.4:		ret
.5:		cmp cx, dx
		jb .7
		jne .6
		cmp bx, ax
		ja .6
		sub ax, bx
		mov bx, ax
		sub cx, cx
		sub dx, dx
		mov ax, 1
		ret
.6:		sub cx, cx
		sub bx, bx
		xchg ax, bx
		xchg cx, dx
		ret
.7:		push bp
		push si
		sub si, si
		mov bp, si
.8:		add bx, bx
		adc cx, cx
		jb .11
		inc bp
		cmp cx, dx
		jb .8
		ja .9
		cmp bx, ax
		jbe .8
.9:		clc
.10:		adc si, si
		dec bp
		js .14
.11:		rcr cx, 1
		rcr bx, 1
		sub ax, bx
		sbb dx, cx
		cmc
		jb .10
.12:		add si, si
		dec bp
		js .13
		shr cx, 1
		rcr bx, 1
		add ax, bx
		adc dx, cx
		jae .12
		jmp short .10
.13:		add ax, bx
		adc dx, cx
.14:		mov bx, ax
		mov cx, dx
		mov ax, si
		xor dx, dx
		pop si
		pop bp
		ret

; ssize_t write(int fd, const void *buf, size_t count);
; Optimized for size. AX == fd, DX == buf, BX == count.
write_:		push cx
		xchg ax, bx		; AX := count; BX := fd.
		xchg ax, cx		; CX := count; AX := junk.
		mov ah, 0x40
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		pop cx
		ret

___section_mininasm_c_const:

@$927		db '(null)', 0
@$928		db 'Out of memory', 0
@$929		db 0
@$930		db '%-20s %08lX', 13, 10, 0
@$931		db 'EQU!', 0
@$932		db 'D#!', 0
@$933		db 'RES#!', 0
@$934		db 'TIMES!', 0
@$935		db 'SHORT!', 0
@$936		db 'NEAR!', 0
@$937		db 'FAR!', 0
@$938		db 'BYTE!', 0
@$939		db 'WORD!', 0
@$940		db 'DWORD!', 0
@$941		db 'STRICT!', 0
@$942		db 'Missing close paren', 0
@$943		db 'Expression too deep', 0
@$944		db 'Missing close quote', 0
@$945		db 'bad label', 0
@$946		db 'Undefined label ', 39, '%s', 39, 0
@$947		db 'division by zero', 0
@$948		db 'modulo by zero', 0
@$949		db 'shift by larger than 31', 0
@$950		db 'oops: bad instr order', 0
@$951		db 'error writing to output file', 0
@$952		db 'extra characters at end of line', 0
@$953		db 'j', 0
@$954		db 'b', 0
@$955		db 'short jump is out of range', 0
@$956		db 'near jump too long', 0
@$957		db 'ooops: decode (%s)', 0
@$958		db 'error writing to listing file', 0
@$959		db 'error: ', 0
@$960		db '%s:%u: %s', 0
@$961		db 13, 10, 0
@$962		db '%s', 0
@$963		db 'DB', 0
@$964		db 'Bad expression', 0
@$965		db 'DW', 0
@$966		db 'DD', 0
@$967		db 'Unknown instruction ', 39, '%s', 39, 0
@$968		db 'Error in instruction ', 39, '%s %s', 39, 0
@$969		db 'Redefined label ', 39, '%s', 39, 0
@$970		db 'oops: label ', 39, '%s', 39, ' not found', 0
@$971		db 'bad macro name', 0
@$972		db 'invalid macro override', 0
@$973		db 'bad macro value', 0
@$974		db 'macro name conflicts with label', 0
@$975		db 'Cannot use undefined labels', 0
@$976		db 'assembly stack overflow, too many pending %INCLUDE files', 0
@$977		db 'cannot open ', 39, '%s', 39, ' for input', 0
@$978		db 'cannot seek in ', 39, '%s', 39, 0
@$979		db 'error reading assembly file', 0
@$980		db 'quoted NUL found', 0
@$981		db 'assembly line too long', 0
@$982		db '%IF', 0
@$983		db '%IF too deep', 0
@$984		db '%IFDEF', 0
@$985		db '%IFNDEF', 0
@$986		db '%IFIDN', 0
@$987		db '__OUTPUT_FORMAT__', 0
@$988		db 'bad %IFIDN', 0
@$989		db 'bin', 0
@$990		db '%IFNIDN', 0
@$991		db '%ELSE', 0
@$992		db '%ELSE without %IF', 0
@$993		db '%ENDIF', 0
@$994		db '%ENDIF without %IF', 0
@$995		db '%IF*', 0
@$996		db '%ELIF*', 0
@$997		db 'Unknown preprocessor condition: %s', 0
@$998		db '%INCLUDE', 0
@$999		db 'Missing quotes in %INCLUDE', 0
@$1000		db '%DEFINE', 0
@$1001		db '%ASSIGN', 0
@$1002		db '%UNDEF', 0
@$1003		db '%LINE', 0
@$1004		db 'Unknown preprocessor directive: %s', 0
@$1005		db 'bad expression', 0
@$1006		db 'Instruction expected', 0
@$1007		db 'USE16', 0
@$1008		db 'CPU', 0
@$1009		db '8086', 0
@$1010		db '186', 0
@$1011		db '86', 0
@$1012		db 'Unsupported processor requested', 0
@$1013		db 'BITS', 0
@$1014		db 'Unsupported BITS requested', 0
@$1015		db 'INCBIN', 0
@$1016		db 'Missing quotes in INCBIN', 0
@$1017		db 'INCBIN value is negative', 0
@$1018		db 'ORG', 0
@$1019		db 'program origin redefined', 0
@$1020		db 'SECTION', 0
@$1021		db '.bss ', 0
@$1022		db 'ALIGN=1', 0
@$1023		db 'Unsupported SECTION: %s', 0
@$1024		db 'ABSOLUTE', 0
@$1025		db '$', 0
@$1026		db 'Unsupported ABSOLUTE: %s', 0
@$1027		db 'RES#', 0
@$1028		db 'RESB value is negative', 0
@$1029		db 'Unsupported .bss instrucction: %s', 0
@$1030		db 'ALIGN', 0
@$1031		db 'ALIGN value is not positive', 0
@$1032		db 'TIMES', 0
@$1033		db 'TIMES value is negative', 0
@$1034		db '%04lX  ', 0
@$1035		db '%02X', 0
@$1036		db '  ', 0
@$1037		db '  %05lu %s', 13, 10, 0
@$1038		db 'Cannot seek in source file', 0
@$1039		db 'Error: Cannot open ', 39, '%s', 39, ' for input', 0
@$1040		db 'Cannot seek in INCBIN file: ', 0
@$1041		db 'Error: Error reading from ', 39, '%s', 39, 0
@$1042		db 'pending %IF at end of file', 0
@$1043		db '6', 0
@$1044		db 'bad optimization argument', 0
@$1045		db 'flag too long: %s', 0
@$1046		db 'no argument for %s', 0
@$1047		db 'BIN', 0
@$1048		db 'COM', 0
@$1049		db 'only ', 39, 'bin', 39, ', ', 39, 'com', 39, ' supported for -f (it is ', 39, '%s', 39, ')', 0
@$1050		db 'already a -o argument is present', 0
@$1051		db 'already a -l argument is present', 0
@$1052		db 'unknown argument %s', 0
@$1053		db 'more than one input file name: %s', 0
@$1054		db 'No input filename provided', 0
@$1055		db 'No output filename provided', 0
@$1056		db 'couldn', 39, 't open ', 39, '%s', 39, ' as listing file', 0
@$1057		db 'couldn', 39, 't open ', 39, '%s', 39, ' as output file', 0
@$1058		db 'oops: labels changed', 0
@$1059		db 'Aborted: Couldn', 39, 't stabilize moving label', 0
@$1060		db 13, 10, '%05lu ERRORS FOUND', 13, 10, 0
@$1061		db '%05lu WARNINGS FOUND', 13, 10, 0
@$1062		db '%05lu PROGRAM BYTES', 13, 10, 0
@$1063		db '%05lu ASSEMBLER PASSES', 13, 10, 13, 10, 0
@$1064		db 'LABEL', 0
@$1065		db '%-20s VALUE/ADDRESS', 13, 10, 13, 10, 0

___section_mininasm_c_const2:

_register_names	db 'CSDSESSSALCLDLBLAHCHDHBHAXCXDXBXSPBPSIDI'
; Table for describing a single register addition (+..) to an effective address.
;
;         [bx+si]=0 [bx+di]=1 [bp+si]=2 [bp+di]=3   [si]=4    [di]=5    [bp]=6    [bx]=7    []=8     [bad]=9
; +BX=3:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bx+si]=0 [bx+di]=1 [bad]=9   [bad]=9   [bx]=7   [bad]=9
; +SP=4:  [bad]=9...
; +BP=5:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bp+si]=2 [bp+di]=3 [bad]=9   [bad]=9   [bp]=6   [bad]=9
; +SI=6:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bad]=9   [bad]=9   [bp+si]=2 [bx+si]=0 [si]=4   [bad]=9
; +DI=7:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bad]=9   [bad]=9   [bp+di]=3 [bx+di]=1 [di]=5   [bad]=9
_reg_add_to_addressing db 0, 1, 9, 9, 7, 9, 9, 9, 9, 9, 2, 3, 9, 9, 6, 9, 9, 2, 0, 4, 9, 9, 3, 1, 5
@$usage		db 'Typical usage:', 13, 10, 'mininasm -f bin input.asm -o input.bin', 13, 10

; /*
;  ** Instruction set.
;  ** Notice some instructions are sorted by less byte usage first.
;  */
; #define ALSO "-"
; /* GCC 7.5 adds an alignment to 32 bytes without the UNALIGNED. We don't
;  * want to waste program size because of such useless alignments.
;  *
;  * See x86 instructions at https://www.felixcloutier.com/x86/
;  * See x86 instructions at http://ref.x86asm.net/geek64-abc.html .
;  */
; UNALIGNED const char instruction_set[] =
;     "AAA\0" " 37\0"
;     "AAD\0" "i D5i" ALSO " D50A\0"
;     "AAM\0" "i D4i" ALSO " D40A\0"
;     "AAS\0" " 3F\0"
;     "ADC\0" "j,q 10drd" ALSO "k,r 11drd" ALSO "q,j 12drd" ALSO "r,k 13drd" ALSO "vAL,h 14i" ALSO "wAX,g 15j" ALSO "m,s sdzozdj" ALSO "l,t 80dzozdi\0"
;     "ADD\0" "j,q 00drd" ALSO "k,r 01drd" ALSO "q,j 02drd" ALSO "r,k 03drd" ALSO "vAL,h 04i" ALSO "wAX,g 05j" ALSO "m,s sdzzzdj" ALSO "l,t 80dzzzdi\0"
;     "AND\0" "j,q 20drd" ALSO "k,r 21drd" ALSO "q,j 22drd" ALSO "r,k 23drd" ALSO "vAL,h 24i" ALSO "wAX,g 25j" ALSO "m,s sdozzdj" ALSO "l,t 80dozzdi\0"
;     "BOUND\0" "xr,o 62drd\0"
;     "CALL\0" "FAR!k FFdzood" ALSO "f 9Af" ALSO "k FFdzozd" ALSO "b E8b\0"
;     "CBW\0" " 98\0"
;     "CLC\0" " F8\0"
;     "CLD\0" " FC\0"
;     "CLI\0" " FA\0"
;     "CMC\0" " F5\0"
;     "CMP\0" "j,q 38drd" ALSO "k,r 39drd" ALSO "q,j 3Adrd" ALSO "r,k 3Bdrd" ALSO "vAL,h 3Ci" ALSO "wAX,g 3Dj" ALSO "m,s sdooodj" ALSO "l,t 80dooodi\0"
;     "CMPSB\0" " A6\0"
;     "CMPSW\0" " A7\0"
;     "CS\0" " 2E+\0"
;     "CWD\0" " 99\0"
;     "DAA\0" " 27\0"
;     "DAS\0" " 2F\0"
;     "DEC\0" "r zozzor" ALSO "l FEdzzod" ALSO "m FFdzzod\0"
;     "DIV\0" "l F6doozd" ALSO "m F7doozd\0"
;     "DS\0" " 3E+\0"
;     "ENTER\0" "xe,h C8ei\0"
;     "ES\0" " 26+\0"
;     "HLT\0" " F4\0"
;     "IDIV\0" "l F6doood" ALSO "m F7doood\0"
;     "IMUL\0" "l. F6dozod" ALSO "m. F7dozod" ALSO "xp,s. mdrdj" ALSO "xr,k,s mdrdj\0"
;     "IN\0" "vAL,wDX EC" ALSO "wAX,wDX ED" ALSO "vAL,h E4i" ALSO "wAX,i E5i\0"
;     "INC\0" "r zozzzr" ALSO "l FEdzzzd" ALSO "m FFdzzzd\0"
;     "INSB\0" "x 6C\0"
;     "INSW\0" "x 6D\0"
;     "INT\0" "i CDi\0"
;     "INT3\0" " CC\0"
;     "INTO\0" " CE\0"
;     "IRET\0" " CF\0"
;     "JA\0" "a 77a\0"
;     "JAE\0" "a 73a\0"
;     "JB\0" "a 72a\0"
;     "JBE\0" "a 76a\0"
;     "JC\0" "a 72a\0"
;     "JCXZ\0" "a E3a\0"
;     "JE\0" "a 74a\0"
;     "JG\0" "a 7Fa\0"
;     "JGE\0" "a 7Da\0"
;     "JL\0" "a 7Ca\0"
;     "JLE\0" "a 7Ea\0"
;     "JMP\0" "FAR!k FFdozod" ALSO "f EAf" ALSO "k FFdozzd" ALSO "c EBa" ALSO "b E9b\0"
;     "JNA\0" "a 76a\0"
;     "JNAE\0" "a 72a\0"
;     "JNB\0" "a 73a\0"
;     "JNBE\0" "a 77a\0"
;     "JNC\0" "a 73a\0"
;     "JNE\0" "a 75a\0"
;     "JNG\0" "a 7Ea\0"
;     "JNGE\0" "a 7Ca\0"
;     "JNL\0" "a 7Da\0"
;     "JNLE\0" "a 7Fa\0"
;     "JNO\0" "a 71a\0"
;     "JNP\0" "a 7Ba\0"
;     "JNS\0" "a 79a\0"
;     "JNZ\0" "a 75a\0"
;     "JO\0" "a 70a\0"
;     "JP\0" "a 7Aa\0"
;     "JPE\0" "a 7Aa\0"
;     "JPO\0" "a 7Ba\0"
;     "JS\0" "a 78a\0"
;     "JZ\0" "a 74a\0"
;     "LAHF\0" " 9F\0"
;     "LDS\0" "r,n C5drd\0"
;     "LEA\0" "r,o 8Ddrd\0"
;     "LEAVE\0" "x C9\0"
;     "LES\0" "r,n C4drd\0"
;     "LOCK\0" " F0+\0"
;     "LODSB\0" " AC\0"
;     "LODSW\0" " AD\0"
;     "LOOP\0" "a E2a\0"
;     "LOOPE\0" "a E1a\0"
;     "LOOPNE\0" "a E0a\0"
;     "LOOPNZ\0" "a E0a\0"
;     "LOOPZ\0" "a E1a\0"
;     "MOV\0" "j,q 88drd" ALSO "k,r 89drd" ALSO "q,j 8Adrd" ALSO "r,k 8Bdrd" ALSO "k,ES 8Cdzzzd" ALSO "k,CS 8Cdzzod" ALSO "k,SS 8Cdzozd" ALSO "k,DS 8Cdzood" ALSO "ES,k 8Edzzzd" ALSO "CS,k 8Edzzod" ALSO "SS,k 8Edzozd" ALSO "DS,k 8Edzood" ALSO "q,h ozoozri" ALSO "r,i ozooorj" ALSO "m,u C7dzzzdj" ALSO "l,t C6dzzzdi\0"
;     "MOVSB\0" " A4\0"
;     "MOVSW\0" " A5\0"
;     "MUL\0" "l F6dozzd" ALSO "m F7dozzd\0"
;     "NEG\0" "l F6dzood" ALSO "m F7dzood\0"
;     "NOP\0" " 90\0"
;     "NOT\0" "l F6dzozd" ALSO "m F7dzozd\0"
;     "OR\0" "j,q 08drd" ALSO "k,r 09drd" ALSO "q,j 0Adrd" ALSO "r,k 0Bdrd" ALSO "vAL,h 0Ci" ALSO "wAX,g 0Dj" ALSO "m,s sdzzodj" ALSO "l,t 80dzzodi\0"
;     "OUT\0" "wDX,vAL EE" ALSO "wDX,AX EF" ALSO "h,vAL E6i" ALSO "i,AX E7i\0"
;     "OUTSB\0" "x 6E\0"
;     "OUTSW\0" "x 6F\0"
;     "PAUSE\0" " F390\0"
;     "POP\0" "ES 07" ALSO "SS 17" ALSO "DS 1F" ALSO "CS 0F" ALSO "r zozoor" ALSO "k 8Fdzzzd\0"
;     "POPA\0" "x 61\0"
;     "POPAW\0" "x 61\0"
;     "POPF\0" " 9D\0"
;     "PUSH\0" "ES 06" ALSO "CS 0E" ALSO "SS 16" ALSO "DS 1E" ALSO "r zozozr" ALSO "xs lj" ALSO "k FFdoozd\0"
;     "PUSHA\0" "x 60\0"
;     "PUSHAW\0" "x 60\0"
;     "PUSHF\0" " 9C\0"
;     "RCL\0" "j,1 gdzozdk" ALSO "k,1 hdzozdk" ALSO "j,CL D2dzozd" ALSO "k,CL D3dzozd\0"
;     "RCR\0" "j,1 gdzoodk" ALSO "k,1 hdzoodk" ALSO "j,CL D2dzood" ALSO "k,CL D3dzood\0"
;     "REP\0" " F3+\0"
;     "REPE\0" " F3+\0"
;     "REPNE\0" " F2+\0"
;     "REPNZ\0" " F2+\0"
;     "REPZ\0" " F3+\0"
;     "RET\0" "i C2j" ALSO " C3\0"
;     "RETF\0" "i CAj" ALSO " CB\0"
;     "ROL\0" "j,1 gdzzzdk" ALSO "k,1 hdzzzdk" ALSO "j,CL D2dzzzd" ALSO "k,CL D3dzzzd\0"
;     "ROR\0" "j,1 gdzzodk" ALSO "k,1 hdzzodk" ALSO "j,CL D2dzzod" ALSO "k,CL D3dzzod\0"
;     "SAHF\0" " 9E\0"
;     "SAL\0" "j,1 gdozzdk" ALSO "k,1 hdozzdk" ALSO "j,CL D2dozzd" ALSO "k,CL D3dozzd\0"
;     "SAR\0" "j,1 gdooodk" ALSO "k,1 hdooodk" ALSO "j,CL D2doood" ALSO "k,CL D3doood\0"
;     "SBB\0" "j,q 18drd" ALSO "k,r 19drd" ALSO "q,j 1Adrd" ALSO "r,k 1Bdrd" ALSO "vAL,h 1Ci" ALSO "wAX,g 1Dj" ALSO "m,s sdzoodj" ALSO "l,t 80dzoodi\0"
;     "SCASB\0" " AE\0"
;     "SCASW\0" " AF\0"
;     "SHL\0" "j,1 gdozzdk" ALSO "k,1 hdozzdk" ALSO "j,CL D2dozzd" ALSO "k,CL D3dozzd\0"
;     "SHR\0" "j,1 gdozodk" ALSO "k,1 hdozodk" ALSO "j,CL D2dozod" ALSO "k,CL D3dozod\0"
;     "SS\0" " 36+\0"
;     "STC\0" " F9\0"
;     "STD\0" " FD\0"
;     "STI\0" " FB\0"
;     "STOSB\0" " AA\0"
;     "STOSW\0" " AB\0"
;     "SUB\0" "j,q 28drd" ALSO "k,r 29drd" ALSO "q,j 2Adrd" ALSO "r,k 2Bdrd" ALSO "vAL,h 2Ci" ALSO "wAX,g 2Dj" ALSO "m,s sdozodj" ALSO "l,t 80dozodi\0"
;     "TEST\0" "j,q 84drd" ALSO "q,j 84drd" ALSO "k,r 85drd" ALSO "r,k 85drd" ALSO "vAL,h A8i" ALSO "wAX,i A9j" ALSO "m,u F7dzzzdj" ALSO "l,t F6dzzzdi\0"
;     "UD0\0" "y 0FFF\0"
;     "UD1\0" "y 0FB9\0"
;     "UD2\0" "y 0F0B\0"
;     "WAIT\0" " 9B+\0"
;     "XCHG\0" "wAX,r ozzozr" ALSO "r,AX ozzozr" ALSO "q,j 86drd" ALSO "j,q 86drd" ALSO "r,k 87drd" ALSO "k,r 87drd\0"
;     "XLAT\0" " D7\0"
;     "XOR\0" "j,q 30drd" ALSO "k,r 31drd" ALSO "q,j 32drd" ALSO "r,k 33drd" ALSO "vAL,h 34i" ALSO "wAX,g 35j" ALSO "m,s sdoozdj" ALSO "l,t 80doozdi\0"
; ;
_instruction_set:
ALSO		equ '-'
		db 'AAA', 0, ' 37', 0
		db 'AAD', 0, 'i D5i', ALSO, ' D50A', 0
		db 'AAM', 0, 'i D4i', ALSO, ' D40A', 0
		db 'AAS', 0, ' 3F', 0
		db 'ADC', 0, 'j,q 10drd', ALSO, 'k,r 11drd', ALSO, 'q,j 12drd', ALSO, 'r,k 13drd', ALSO, 'vAL,h 14i', ALSO, 'wAX,g 15j', ALSO, 'm,s sdzozdj', ALSO, 'l,t 80dzozdi', 0
		db 'ADD', 0, 'j,q 00drd', ALSO, 'k,r 01drd', ALSO, 'q,j 02drd', ALSO, 'r,k 03drd', ALSO, 'vAL,h 04i', ALSO, 'wAX,g 05j', ALSO, 'm,s sdzzzdj', ALSO, 'l,t 80dzzzdi', 0
		db 'AND', 0, 'j,q 20drd', ALSO, 'k,r 21drd', ALSO, 'q,j 22drd', ALSO, 'r,k 23drd', ALSO, 'vAL,h 24i', ALSO, 'wAX,g 25j', ALSO, 'm,s sdozzdj', ALSO, 'l,t 80dozzdi', 0
		db 'BOUND', 0, 'xr,o 62drd', 0
		db 'CALL', 0, 'FAR!k FFdzood', ALSO, 'f 9Af', ALSO, 'k FFdzozd', ALSO, 'b E8b', 0
		db 'CBW', 0, ' 98', 0
		db 'CLC', 0, ' F8', 0
		db 'CLD', 0, ' FC', 0
		db 'CLI', 0, ' FA', 0
		db 'CMC', 0, ' F5', 0
		db 'CMP', 0, 'j,q 38drd', ALSO, 'k,r 39drd', ALSO, 'q,j 3Adrd', ALSO, 'r,k 3Bdrd', ALSO, 'vAL,h 3Ci', ALSO, 'wAX,g 3Dj', ALSO, 'm,s sdooodj', ALSO, 'l,t 80dooodi', 0
		db 'CMPSB', 0, ' A6', 0
		db 'CMPSW', 0, ' A7', 0
		db 'CS', 0, ' 2E+', 0
		db 'CWD', 0, ' 99', 0
		db 'DAA', 0, ' 27', 0
		db 'DAS', 0, ' 2F', 0
		db 'DEC', 0, 'r zozzor', ALSO, 'l FEdzzod', ALSO, 'm FFdzzod', 0
		db 'DIV', 0, 'l F6doozd', ALSO, 'm F7doozd', 0
		db 'DS', 0, ' 3E+', 0
		db 'ENTER', 0, 'xe,h C8ei', 0
		db 'ES', 0, ' 26+', 0
		db 'HLT', 0, ' F4', 0
		db 'IDIV', 0, 'l F6doood', ALSO, 'm F7doood', 0
		db 'IMUL', 0, 'l. F6dozod', ALSO, 'm. F7dozod', ALSO, 'xp,s. mdrdj', ALSO, 'xr,k,s mdrdj', 0
		db 'IN', 0, 'vAL,wDX EC', ALSO, 'wAX,wDX ED', ALSO, 'vAL,h E4i', ALSO, 'wAX,i E5i', 0
		db 'INC', 0, 'r zozzzr', ALSO, 'l FEdzzzd', ALSO, 'm FFdzzzd', 0
		db 'INSB', 0, 'x 6C', 0
		db 'INSW', 0, 'x 6D', 0
		db 'INT', 0, 'i CDi', 0
		db 'INT3', 0, ' CC', 0
		db 'INTO', 0, ' CE', 0
		db 'IRET', 0, ' CF', 0
		db 'JA', 0, 'a 77a', 0
		db 'JAE', 0, 'a 73a', 0
		db 'JB', 0, 'a 72a', 0
		db 'JBE', 0, 'a 76a', 0
		db 'JC', 0, 'a 72a', 0
		db 'JCXZ', 0, 'a E3a', 0
		db 'JE', 0, 'a 74a', 0
		db 'JG', 0, 'a 7Fa', 0
		db 'JGE', 0, 'a 7Da', 0
		db 'JL', 0, 'a 7Ca', 0
		db 'JLE', 0, 'a 7Ea', 0
		db 'JMP', 0, 'FAR!k FFdozod', ALSO, 'f EAf', ALSO, 'k FFdozzd', ALSO, 'c EBa', ALSO, 'b E9b', 0
		db 'JNA', 0, 'a 76a', 0
		db 'JNAE', 0, 'a 72a', 0
		db 'JNB', 0, 'a 73a', 0
		db 'JNBE', 0, 'a 77a', 0
		db 'JNC', 0, 'a 73a', 0
		db 'JNE', 0, 'a 75a', 0
		db 'JNG', 0, 'a 7Ea', 0
		db 'JNGE', 0, 'a 7Ca', 0
		db 'JNL', 0, 'a 7Da', 0
		db 'JNLE', 0, 'a 7Fa', 0
		db 'JNO', 0, 'a 71a', 0
		db 'JNP', 0, 'a 7Ba', 0
		db 'JNS', 0, 'a 79a', 0
		db 'JNZ', 0, 'a 75a', 0
		db 'JO', 0, 'a 70a', 0
		db 'JP', 0, 'a 7Aa', 0
		db 'JPE', 0, 'a 7Aa', 0
		db 'JPO', 0, 'a 7Ba', 0
		db 'JS', 0, 'a 78a', 0
		db 'JZ', 0, 'a 74a', 0
		db 'LAHF', 0, ' 9F', 0
		db 'LDS', 0, 'r,n C5drd', 0
		db 'LEA', 0, 'r,o 8Ddrd', 0
		db 'LEAVE', 0, 'x C9', 0
		db 'LES', 0, 'r,n C4drd', 0
		db 'LOCK', 0, ' F0+', 0
		db 'LODSB', 0, ' AC', 0
		db 'LODSW', 0, ' AD', 0
		db 'LOOP', 0, 'a E2a', 0
		db 'LOOPE', 0, 'a E1a', 0
		db 'LOOPNE', 0, 'a E0a', 0
		db 'LOOPNZ', 0, 'a E0a', 0
		db 'LOOPZ', 0, 'a E1a', 0
		db 'MOV', 0, 'j,q 88drd', ALSO, 'k,r 89drd', ALSO, 'q,j 8Adrd', ALSO, 'r,k 8Bdrd', ALSO, 'k,ES 8Cdzzzd', ALSO, 'k,CS 8Cdzzod', ALSO, 'k,SS 8Cdzozd', ALSO, 'k,DS 8Cdzood', ALSO, 'ES,k 8Edzzzd', ALSO, 'CS,k 8Edzzod', ALSO, 'SS,k 8Edzozd', ALSO
		    db 'DS,k 8Edzood', ALSO, 'q,h ozoozri', ALSO, 'r,i ozooorj', ALSO, 'm,u C7dzzzdj', ALSO, 'l,t C6dzzzdi', 0
		db 'MOVSB', 0, ' A4', 0
		db 'MOVSW', 0, ' A5', 0
		db 'MUL', 0, 'l F6dozzd', ALSO, 'm F7dozzd', 0
		db 'NEG', 0, 'l F6dzood', ALSO, 'm F7dzood', 0
		db 'NOP', 0, ' 90', 0
		db 'NOT', 0, 'l F6dzozd', ALSO, 'm F7dzozd', 0
		db 'OR', 0, 'j,q 08drd', ALSO, 'k,r 09drd', ALSO, 'q,j 0Adrd', ALSO, 'r,k 0Bdrd', ALSO, 'vAL,h 0Ci', ALSO, 'wAX,g 0Dj', ALSO, 'm,s sdzzodj', ALSO, 'l,t 80dzzodi', 0
		db 'OUT', 0, 'wDX,vAL EE', ALSO, 'wDX,AX EF', ALSO, 'h,vAL E6i', ALSO, 'i,AX E7i', 0
		db 'OUTSB', 0, 'x 6E', 0
		db 'OUTSW', 0, 'x 6F', 0
		db 'PAUSE', 0, ' F390', 0
		db 'POP', 0, 'ES 07', ALSO, 'SS 17', ALSO, 'DS 1F', ALSO, 'CS 0F', ALSO, 'r zozoor', ALSO, 'k 8Fdzzzd', 0
		db 'POPA', 0, 'x 61', 0
		db 'POPAW', 0, 'x 61', 0
		db 'POPF', 0, ' 9D', 0
		db 'PUSH', 0, 'ES 06', ALSO, 'CS 0E', ALSO, 'SS 16', ALSO, 'DS 1E', ALSO, 'r zozozr', ALSO, 'xs lj', ALSO, 'k FFdoozd', 0
		db 'PUSHA', 0, 'x 60', 0
		db 'PUSHAW', 0, 'x 60', 0
		db 'PUSHF', 0, ' 9C', 0
		db 'RCL', 0, 'j,1 gdzozdk', ALSO, 'k,1 hdzozdk', ALSO, 'j,CL D2dzozd', ALSO, 'k,CL D3dzozd', 0
		db 'RCR', 0, 'j,1 gdzoodk', ALSO, 'k,1 hdzoodk', ALSO, 'j,CL D2dzood', ALSO, 'k,CL D3dzood', 0
		db 'REP', 0, ' F3+', 0
		db 'REPE', 0, ' F3+', 0
		db 'REPNE', 0, ' F2+', 0
		db 'REPNZ', 0, ' F2+', 0
		db 'REPZ', 0, ' F3+', 0
		db 'RET', 0, 'i C2j', ALSO, ' C3', 0
		db 'RETF', 0, 'i CAj', ALSO, ' CB', 0
		db 'ROL', 0, 'j,1 gdzzzdk', ALSO, 'k,1 hdzzzdk', ALSO, 'j,CL D2dzzzd', ALSO, 'k,CL D3dzzzd', 0
		db 'ROR', 0, 'j,1 gdzzodk', ALSO, 'k,1 hdzzodk', ALSO, 'j,CL D2dzzod', ALSO, 'k,CL D3dzzod', 0
		db 'SAHF', 0, ' 9E', 0
		db 'SAL', 0, 'j,1 gdozzdk', ALSO, 'k,1 hdozzdk', ALSO, 'j,CL D2dozzd', ALSO, 'k,CL D3dozzd', 0
		db 'SAR', 0, 'j,1 gdooodk', ALSO, 'k,1 hdooodk', ALSO, 'j,CL D2doood', ALSO, 'k,CL D3doood', 0
		db 'SBB', 0, 'j,q 18drd', ALSO, 'k,r 19drd', ALSO, 'q,j 1Adrd', ALSO, 'r,k 1Bdrd', ALSO, 'vAL,h 1Ci', ALSO, 'wAX,g 1Dj', ALSO, 'm,s sdzoodj', ALSO, 'l,t 80dzoodi', 0
		db 'SCASB', 0, ' AE', 0
		db 'SCASW', 0, ' AF', 0
		db 'SHL', 0, 'j,1 gdozzdk', ALSO, 'k,1 hdozzdk', ALSO, 'j,CL D2dozzd', ALSO, 'k,CL D3dozzd', 0
		db 'SHR', 0, 'j,1 gdozodk', ALSO, 'k,1 hdozodk', ALSO, 'j,CL D2dozod', ALSO, 'k,CL D3dozod', 0
		db 'SS', 0, ' 36+', 0
		db 'STC', 0, ' F9', 0
		db 'STD', 0, ' FD', 0
		db 'STI', 0, ' FB', 0
		db 'STOSB', 0, ' AA', 0
		db 'STOSW', 0, ' AB', 0
		db 'SUB', 0, 'j,q 28drd', ALSO, 'k,r 29drd', ALSO, 'q,j 2Adrd', ALSO, 'r,k 2Bdrd', ALSO, 'vAL,h 2Ci', ALSO, 'wAX,g 2Dj', ALSO, 'm,s sdozodj', ALSO, 'l,t 80dozodi', 0
		db 'TEST', 0, 'j,q 84drd', ALSO, 'q,j 84drd', ALSO, 'k,r 85drd', ALSO, 'r,k 85drd', ALSO, 'vAL,h A8i', ALSO, 'wAX,i A9j', ALSO, 'm,u F7dzzzdj', ALSO, 'l,t F6dzzzdi', 0
		db 'UD0', 0, 'y 0FFF', 0
		db 'UD1', 0, 'y 0FB9', 0
		db 'UD2', 0, 'y 0F0B', 0
		db 'WAIT', 0, ' 9B+', 0
		db 'XCHG', 0, 'wAX,r ozzozr', ALSO, 'r,AX ozzozr', ALSO, 'q,j 86drd', ALSO, 'j,q 86drd', ALSO, 'r,k 87drd', ALSO, 'k,r 87drd', 0
		db 'XLAT', 0, ' D7', 0
		db 'XOR', 0, 'j,q 30drd', ALSO, 'k,r 31drd', ALSO, 'q,j 32drd', ALSO, 'r,k 33drd', ALSO, 'vAL,h 34i', ALSO, 'wAX,g 35j', ALSO, 'm,s sdoozdj', ALSO, 'l,t 80doozdi', 0
		db 0

___section_mininasm_c_data:

_listing_fd	dw -1
; struct bbprintf_buf emit_bbb = { emit_buf, emit_buf + sizeof(emit_buf), emit_buf, 0, emit_flush };
_emit_bbb:
		dw _emit_buf
		dw _emit_buf+0x200
		dw _emit_buf
		dw 0
		dw emit_flush_
; /* data = 0 means write to listing_fd only, = 1 means write to stderr + listing_fd. */
; struct bbprintf_buf message_bbb = { message_buf, message_buf + sizeof(message_buf), message_buf, 0, message_flush };
_message_bbb:
		dw _message_buf
		dw _message_buf+0x200
		dw _message_buf
		dw 0
		dw message_flush_
_mininasm_macro_name db ' __MININASM__'
.end:

; --- Variables initialized to 0 by _start.
___section_nobss_end:
		section .bss align=1
___section_bss:
		;resb (___section_startup_text-___section_nobss_end)&(2-1)  ; Align to multiple of 2. We don't do it.

___section_mininasm_c_bss:
_line_buf		resb 512
_assembly_stack		resb 512
_message_buf		resb 512
_emit_buf		resb 512
_generated_buf		resb 8
_wide_instr_read_block		resb 4
_wide_instr_add_at		resb 4
_wide_instr_read_at		resb 4
_wide_instr_last_block		resb 4
_wide_instr_first_block		resb 4
_wide_instr_add_block_end		resb 4
_label_list		resb 4
_errors		resb 4
_bytes		resb 4
_instruction_value		resb 4
_current_address		resb 4
_start_address		resb 4
_line_number		resb 4
_default_start_address		resb 4
_instr_name		resb 10
___malloc_struct__		resb 6
_assembly_p		resb 2
_filename_for_message		resb 2
_global_label_end		resb 2
_generated_cur		resb 2
_generated_ptr		resb 2
_instruction_offset		resb 2
_assembler_pass		resb 2
_output_fd		resb 2
_output_filename		resb 2
_global_label		resb 509
_do_special_pass_1		resb 1
_has_macros		resb 1
_was_strict		resb 1
_has_undefined		resb 1
_jump_range_bits		resb 1
_have_labels_changed		resb 1
_cpu_level		resb 1
_do_opt_int		resb 1
_do_opt_lea		resb 1
_instruction_addressing_segment		resb 1
_is_address_used		resb 1
_is_start_address_set		resb 1
_instruction_offset_width		resb 1
_instruction_register		resb 1
_opt_level		resb 1
_do_opt_segreg		resb 1
_instruction_addressing		resb 1
_size_decrease_count		resb 1
@$tree_path		resb 204  ; static struct tree_path_entry path[RB_LOG2_MAX_NODES << 1];
@$match_stack		resb 600  ; static struct match_stack_item { ... } match_stack[CONFIG_MATCH_STACK_DEPTH];
@$segment_value		resb 2

; --- Uninitialized .bss used by _start.    ___section_startup_ubss:
___section_startup_ubss:

argv_bytes	resb 270
argv_pointers	resb 130

___section_ubss_end:

___initial_sp	equ ___section_startup_text+((___section_ubss_end-___section_bss+___section_nobss_end-___section_startup_text+___stack_size+1)&~1)  ; Word-align stack for speed.
___sd_top__	equ 0x10+((___initial_sp-___section_startup_text+0xf)>>4)  ; Round top of stack to next para, use para (16-byte).

; __END__
