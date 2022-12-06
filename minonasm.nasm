;
; minonasm.nasm: non-self-hosting, NASM-compatible assembler for DOS 8086, targeting 8086
; by pts@fazekas.hu at Fri Nov 18 04:17:31 CET 2022
;
; minonasm.nasm is a non-self-hosting source code version of minnnasm.nasm:
; it can be compiled by mininasm, but not minnnasm, and it should produce an
; bit-by-bit identical executable binary (minnnasm.com and minonasm.com).
; It can be used for testing new features of mininasm.
;
; This version of minnoasm.com (19399 bytes) is bit-by-bit identical to
; mininasm.com built from
; https://github.com/pts/mininasm/blob/28d95e0e9c47e70288fb0909a020700e14d27024/mininasm.c
; with `dosmc -mt -cpn mininasm.c'.
;
; For compilation with mininasm and NASM, minonasm.nasm needs the -O9
; optimization flag. Use any of:
;
;   $ nasm -O9 -f bin -o minonasm.com minonasm.nasm
;   $ mininasm -O9 -f bin -o minonasm.com minonasm.nasm
;   $ kvikdos mininasm.com -O9 -f bin -o minonas2.com minonasm.nas
;
; These NASM versions (as well as mininasm at the link above) were tested
; and found to produce minonasm.com bit-by-bit identical to mininasm.com
; above): NASM 0.98.39, NASM 0.99.06, NASM 2.13.02. Only the `-O9'
; optimization level produces the bit-by-bit identical output.
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
;  **   $ dosmc -mt mininasm.c && ls -ld mininasm.com
;  **
;  **   $ owcc -bdos -o mininasm.exe -mcmodel=c -Os -s -fstack-check -Wl,option -Wl,stack=1800 -march=i86 -W -Wall -Wextra mininasm.c && ls -ld mininasm.exe
;  **
;  **   $ owcc -bwin32 -Wl,runtime -Wl,console=3.10 -o mininasm.win32.exe -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm.c nouser32.c && ls -ld mininasm.win32.exe
;  **
;  **   $ i686-w64-mingw32-gcc -m32 -mconsole -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -march=i386 -o mininasm.win32msvcrt.exe mininasm.c && ls -ld mininasm.win32msvcrt.exe
;  **
;  **   $ wine tcc.exe -m32 -mconsole -s -O2 -W -Wall -o mininasm.win32msvcrt_tcc.exe mininasm.c && ls -ld mininasm.win32msvcrt_tcc.exe
;  **
;  */
;
; #ifdef __TINYC__  /* Works with tcc, pts-tcc (Linux i386 target), pts-tcc64 (Linux amd64 target) and tcc.exe (Win32, Windows i386 target). */
; #  if !defined(__i386__) /* && !defined(__amd64__)*/ && !defined(__x86_64__)
; #    error tcc is supported only on i386 and amd64.  /* Because of ssize_t. */
; #  endif
; #  if (defined(_WIN32) && !defined(__i386)) || defined(_WIN64)
; #    error Windows is supported only on i386.
; #  endif
; #  define ATTRIBUTE_NORETURN __attribute__((noreturn))
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
; void ATTRIBUTE_NORETURN __cdecl exit(int status);
; char *__cdecl strcpy(char *dest, const char *src);
; int __cdecl strcmp(const char *s1, const char *s2);
; char *__cdecl strcat(char *dest, const char *src);
; void *__cdecl memcpy(void *dest, const void *src, size_t n);
; int __cdecl memcmp(const void *s1, const void *s2, size_t n);
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
; #  define open2(pathname, flags) open(pathname, flags)
; #  ifdef _WIN32
; #    define O_CREAT 0x100
; #    define O_TRUNC 0x200
; #    define O_BINARY 0x8000
; #    define creat(filename, mode) open(filename, O_CREAT | O_TRUNC | O_WRONLY | O_BINARY, 0)  /* 0 to prevent Wine warning: fixme:msvcrt:MSVCRT__wsopen_s : pmode 0x406b9b ignored.  */
; int __cdecl setmode(int _FileHandle,int _Mode);
; #  endif
; #else
; #  ifdef __DOSMC__
; #    include <dosmc.h>  /* strcpy_far(...), strcmp_far(...) etc. */
; #  else /* Standard C. */
; #    include <ctype.h>
; #    include <fcntl.h>  /* open(...), O_BINARY. */
; #    include <stdio.h>  /* remove(...) */
; #    include <stdlib.h>
; #    include <string.h>
; #    if defined(_WIN32) || defined(_WIN64) || defined(MSDOS)  /* tcc.exe with Win32 target doesn't have <unistd.h>. For `owcc -bdos' and `owcc -bwin32', both <io.h> and <unistd.h> works. */
; #      include <io.h>  /* setmode(...) */
; #      define creat(filename, mode) open(filename, O_CREAT | O_TRUNC | O_WRONLY | O_BINARY, 0)  /* 0 to prevent Wine msvcrt.dll warning: `fixme:msvcrt:MSVCRT__wsopen_s : pmode 0x406b9b ignored.'. Also works with `owcc -bwin32' (msvcrtl.dll) and `owcc -bdos'. */
; #    else
; #      include <unistd.h>
; #    endif
; #    define open2(pathname, flags) open(pathname, flags)
; #  endif
; #endif
;
; #ifndef O_BINARY  /* Unix. */
; #define O_BINARY 0
; #endif
;
; #if !__SIZEOF_INT__  /* GCC has it, tried with GCC 4.8. */
; #undef __SIZEOF_INT__
; #ifdef __WATCOMC__
; #ifdef _M_I86  /* OpenWatcom only defines this for 16-bit targets, e.g. `owcc -bdos', but not for `owcc -bwin32'. */
; #define __SIZEOF_INT__ 2  /* Example: __DOSMC__. */
; #else
; #define __SIZEOF_INT__ 4
; #endif
; #ifdef _M_I386  /* OpenWatcom only defines this for 32-bit (and maybe 64-bit?) targets, e.g. `owcc -bwin32', but not for `owcc -bdos'. */
; #endif
; #else  /* Else __WATCOMC__. */
; #ifdef _M_I86
; #define __SIZEOF_INT__ 2
; #else
; #if defined(__TINYC__) && defined(__x86_64__)
; #define __SIZEOF_INT__ 4
; #else
; #if defined(__linux) || defined(__i386__) || defined(__i386) || defined(__linux__) || defined(_WIN32)  /* For __TINYC__. */
; #define __SIZEOF_INT__ 4
; #endif
; #endif
; #endif
; #endif  /* __WATCOMC__ */
; #endif  /* !__SIZEOF_INT__ */
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
; #if !defined(CONFIG_SHIFT_OK_31)
; #if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__) || defined(_M_IX86) || defined(__i386__) || defined(__386) || defined(__X86_64__) || defined(_M_I386)  /* 32-bit or 64-bit x86. Doesn't match 16-bit. */
; #define CONFIG_SHIFT_OK_31 1  /* `x << 31' and `x >> 31' works in C for 16-bit and 32-bit value_t. */
; #else
; #define CONFIG_SHIFT_OK_31 0
; #endif
; #endif
;
; #ifndef CONFIG_BALANCED
; #define CONFIG_BALANCED 1
; #endif
;
; #ifndef CONFIG_DOSMC_PACKED
; #ifdef __DOSMC__
; #define CONFIG_DOSMC_PACKED 1
; #else
; #define CONFIG_DOSMC_PACKED 0
; #endif
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
; "add ax, [es:3]"  /* Size of block in paragraphs. DOS has preallocated it to maximum size when loading the .com program. */ \
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
; #define MY_FAR far
; #define USING_FAR 1
; /* strcpy_far(...) and strcmp_far(...) are defined in <dosmc.h>. */
; #else  /* CONFIG_DOSMC. */
; #define MY_FAR
; #define USING_FAR 0
; #define strcpy_far(dest, src) strcpy(dest, src)
; #define strcmp_far(s1, s2) strcmp(s1, s2)
; #define malloc_far(size) malloc(size)
; #define malloc_init() do {} while (0)
; #if CONFIG_DOSMC_PACKED
; #error CONFIG_DOSMC_PACKED needs __DOSMC__.
; #endif
; #endif  /* Else CONFIG_DOSMC. */
;
; /* Example usage:
;  * static const STRING_WITHOUT_NUL(msg, "Hello, World!\r\n$");
;  * ... printmsgx(msg);
;  */
; #ifdef __cplusplus  /* We must reserve space for the NUL. */
; #define MY_STRING_WITHOUT_NUL(name, value) char name[sizeof(value)] = value
; #define STRING_SIZE_WITHOUT_NUL(name) (sizeof(name) - 1)
; #else
; #define MY_STRING_WITHOUT_NUL(name, value) char name[sizeof(value) - 1] = value
; #define STRING_SIZE_WITHOUT_NUL(name) (sizeof(name))
; #endif
;
; /* We aim for compatibility with NASM 0.98.39, so we do signed by default.
;  * Signed (sign-extended): NASM 0.99.06, Yasm 1.2.0, Yasm, 1.3.0.
;  * Unsigned (zero-extended): NASM 0.98.39, NASM 2.13.02.
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
; #define GET_VALUE(value) (value_t)(sizeof(short) == 2 ? (short)(value) : (short)(((short)(value) & 0x7fff) | -((short)(value) & 0x8000U)))  /* Sign-extended. */
; #define GET_UVALUE(value) (uvalue_t)(sizeof(unsigned short) == 2 ? (unsigned short)(value) : (unsigned short)(value) & 0xffffU)
; #define GET_U16(value) (unsigned short)(sizeof(unsigned short) == 2 ? (unsigned short)(value) : (unsigned short)(value) & 0xffffU)
; #else
; #if CONFIG_VALUE_BITS == 32
; #if __SIZEOF_INT__ >= 4
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
; #define GET_VALUE(value) (value_t)(sizeof(value_t) == 4 ? (value_t)(value) : sizeof(int) == 4 ? (value_t)(int)(value) : sizeof(long) == 4 ? (value_t)(long)(value) : (value_t)(((long)(value) & 0x7fffffffL) | -((long)(value) & 0x80000000UL)))
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
; #include "bbprintf.c"
;
; --- bbprintf.c
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
; #ifndef CONFIG_BBPRINTF_LONG
; #define CONFIG_BBPRINTF_LONG 0
; #endif
;
; #include "bbprintf.h"
;
; --- bbprintf.h
;
; #ifndef _BBPRINTF_H_
; #define _BBPRINTF_H_ 1
; #pragma once
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
; --- bbprintf.c continues
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
; #define BBPRINTF_INT long
; #else
; #define BBPRINTF_INT int
; #endif
;
; static int print(struct bbprintf_buf *bbb, const char *format, va_list args) {
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

;         s = va_arg(args, char*);
		mov word [bp-0xa], ax
		mov di, ax
		mov di, word [di-2]

;         if (!s) s = (char*)"(null)";
		test di, di
		jne @$9
		mov di, @$840

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
;         s[0] = (char)va_arg(args, int);
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

;           u = va_arg(args, unsigned long);
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

;           u = va_arg(args, unsigned);
@$22:
		mov word [bp-0xa], ax
		mov bx, ax
		mov ax, word [bx-2]
		mov word [bp-0x12], ax
		mov word [bp-8], 0

;         }
; #else
;         u = va_arg(args, unsigned);
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

;         /* pc += printi(bbb, va_arg(args, int), (c | 32) == 'x' ? 16 : 10, c == 'd', width, pad, c == 'X' ? 'A' : 'a'); */
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

;             u = -u;
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
;   va_end(args);
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
; CONFIG_BBPRINTF_STATIC int bbprintf(struct bbprintf_buf *bbb, const char *format, ...) {
bbprintf_:
		push bx
		push dx
		push bp
		mov bp, sp

;   va_list args;
;   va_start(args, format);
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

; --- mininasm.c continues
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
;  ** -O1: 2-pass, assume longest on undefined label, make signed immediate arguments of arithmetic operations as short as possble without looking forward.
;  ** -Ox == -OX == -O3 == -O9: full, multipass optimization, make it as short as possible, same as NASM 0.98.39 -O9 and newer NASM 2.x default.
;  */
; static unsigned char opt_level;
; static unsigned char do_opt_lea;  /* -OL. */
; static unsigned char do_opt_segreg;  /* -OG. */
;
; #define MAX_SIZE        256
;
; static char instr_name[10];  /* Assembly instruction mnemonic name or preprocessor directive name. Always ends with '\0', maybe truncated. */
; static char global_label[(MAX_SIZE - 2) * 2 + 1];  /* MAX_SIZE is the maximum allowed line size including the terminating '\n'. Thus 2 in `- 2' is the size of the shortest trailing ":\n". */
; static char *global_label_end;
;
; static char *g;
; static char generated[8];
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
;
; #if CONFIG_DOSMC_PACKED
; _Packed  /* Disable extra aligment byte at the end of `struct label'. */
; #endif
; struct label {
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
; };
;
; static struct label MY_FAR *label_list;
; static char has_undefined;
;
; extern const char instruction_set[];
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
; #ifndef RB_LOG2_MAX_MEM_BYTES
; #ifdef __DOSMC__
; #define RB_LOG2_MAX_MEM_BYTES 20  /* 1 MiB. */
; #else
; #define RB_LOG2_MAX_MEM_BYTES (sizeof(void*) << 3)
; #endif
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
; #define RBL_SET_LEFT_RIGHT_NULL(label) ((label)->left_right_ofs = 0, (label)->left_seg_swapped = 0xffffU, (label)->right_seg = 0)
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
		jmp near @$78

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
; #define RBL_SET_LEFT_RIGHT_NULL(label) ((label)->left_right_ofs = (label)->left_seg_swapped = 0xffffU, (label)->right_seg = 0)
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
; #define RBL_SET_LEFT_RIGHT_NULL(label) ((label)->tree_left = (label)->tree_right = NULL)
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
		mov ax, @$841
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
;     RBL_SET_LEFT_RIGHT_NULL(label);
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
;         static struct tree_path_entry path[RB_LOG2_MAX_NODES << 1];
;         struct tree_path_entry *pathp;
;         RBL_SET_RED_1(label);
		mov es, word [bp-4]
		or byte [es:si+4], 1

;         path->label = label_list;
		mov ax, word [_label_list]
		mov dx, word [_label_list+2]
		mov word [@$967], ax
		mov word [@$968], dx

;         for (pathp = path; !RBL_IS_NULL(pathp->label); pathp++) {
		mov si, @$967
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
		cmp ax, @$967
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
		mov bx, word [@$967]
		mov ax, word [@$968]
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
; /*
;  ** Find a label.
;  **
;  ** `name' as passed as a far pointer because reset_macros() needs it.
;  */
; static struct label MY_FAR *find_label(const char MY_FAR *name) {
find_label_:
		push bx
		push cx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		push ax
		push ax
		push dx

;     struct label MY_FAR *explore;
;     struct label MY_FAR *milestone = NULL;
		xor ax, ax
		mov word [bp-4], ax
		mov word [bp-2], ax

;     int c;
;
;     /* Follows a binary tree */
;     explore = label_list;
		mov di, word [_label_list]
		mov si, word [_label_list+2]

;     while (!RBL_IS_NULL(explore)) {
@$72:
		test si, si
		je @$75

;         c = strcmp_far(name, explore->name);
		lea bx, [di+9]
		mov cx, si
		mov ax, word [bp-6]
		mov dx, word [bp-8]
		call near strcmp_far_

;         if (c == 0) {
		test ax, ax
		jne @$73

;             return explore;
		mov ax, di
		jmp @$76

;         } else if (c < 0) {
@$73:
		jge @$74

;             milestone = explore;
		mov word [bp-4], di
		mov word [bp-2], si

;             explore = RBL_GET_LEFT(explore);
		mov ax, di
		mov dx, si
		call near RBL_GET_LEFT_
		mov di, ax
		mov si, dx

;         } else {
		jmp @$72

;             explore = RBL_GET_RIGHT(explore);
@$74:
		mov ax, di
		mov dx, si
		call near RBL_GET_RIGHT_
		mov di, ax
		mov si, dx

;             /* Stop on circular path created by Morris inorder traversal, e.g. in reset_macros(). */
;             if (explore == milestone) break;
		cmp dx, word [bp-2]
		jne @$72
		cmp ax, word [bp-4]
		jne @$72

;         }
;     }
;     return NULL;
@$75:
		xor ax, ax
		xor si, si

; }
@$76:
		mov dx, si
@$77:
		mov sp, bp
		pop bp
		pop di
@$78:
		pop si
		pop cx
		pop bx
		ret

;
; /*
;  ** Print labels sorted to listing_fd (already done by binary tree).
;  */
; static void print_labels_sorted_to_listing_fd(void) {
print_labels_sorted_to_listing_fd_:
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
;     char c;
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
		mov ax, @$842
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
		pop di
@$88:
		pop si
@$89:
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
@$90:
		cmp byte [bx], 0x20
		jne @$91
		inc bx
		jmp @$90

;     return p;
; }
@$91:
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
		jne @$92
		mov ax, dx
		call near isdigit_
		test ax, ax
		jne @$92
		cmp dx, 0x5f
		je @$92
		cmp dx, 0x2e
		je @$92
		cmp dx, 0x40
		je @$92
		cmp dx, 0x3f
		je @$92
		cmp dx, 0x24
		je @$92
		cmp dx, 0x7e
		je @$92
		cmp dx, 0x23
		jne @$93
@$92:
		mov ax, 1

; }
@$93:
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
; /* Returns bool (0 == false or 1 == true) indicating whether the
;  * NUL-terminated string p matches the NUL-terminated pattern.
;  *
;  * The match is performed from left to right, one byte at a time.
;  * A '!' in the pattern matches the end-of-string or a non-islabel(...)
;  * character and anything afterwards.
;  * A '*' in the pattern matches anything afterwards. An uppercase
;  * letter in the pattern matches itself and the lowercase equivalent.
;  * A '\0' in the pattern matches the '\0', and the matching stops
;  * with true. Every other byte in the pattern matches itself, and the
;  * matching continues.
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
@$94:
		mov al, byte [si]
		inc si
		cmp al, 0x2a
		je @$99

;         if (c - 'A' + 0U <= 'Z' - 'A' + 0U) {
		mov dl, al
		xor dh, dh
		mov cx, dx
		sub cx, 0x41
		cmp cx, 0x19
		ja @$96

;             if ((*p & ~32) != c) return 0;  /* Letters are matched case insensitively. */
		mov al, byte [bx]
		and ax, 0xdf
		cmp ax, dx
		je @$98
@$95:
		xor al, al
		jmp near @$78

;         } else if (c == '!') {
@$96:
		cmp al, 0x21
		jne @$97

;             if (islabel(*p)) return 0;  /* Doesn't return 0 for end-of-string. */
		mov al, byte [bx]
		xor ah, ah
		call near islabel_
		test ax, ax
		je @$99
		jmp @$95

;             break;
;         } else {
;             if (*p != c) return 0;
@$97:
		cmp al, byte [bx]
		jne @$95

;             if (c == '\0') break;
		test al, al
		je @$99

;         }
;     }
@$98:
		inc bx
		jmp @$94

;     return 1;
@$99:
		mov al, 1

; }
		jmp near @$78

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
		jne @$101

;         return casematch(p, "EQU!");
		mov dx, @$843
@$100:
		mov ax, bx
		call near casematch_
		xor ah, ah
		pop dx
		pop bx
		ret

;     } else if (c == 'D') {
@$101:
		cmp al, 0x44
		jne @$104

;         c = p[1] & ~32;
		mov al, byte [bx+1]
		and al, 0xdf

;         return (c == 'B' || c == 'W'
		cmp al, 0x42
		je @$102
		cmp al, 0x57
		je @$102
		cmp al, 0x44
		jne @$103
@$102:
		mov al, byte [bx+2]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$103
		mov ax, 1
		pop dx
		pop bx
		ret
@$103:
		xor ax, ax
		pop dx
		pop bx
		ret

; #if CONFIG_VALUE_BITS == 32
;             || c == 'D'  /* "DD". */
; #endif
;             ) && !islabel(p[2]);
;     } else if (c == 'R') {
@$104:
		cmp al, 0x52
		jne @$105

;         return casematch(p, "RESB!");
		mov dx, @$844
		jmp @$100

;     } else {
;         return 0;
@$105:
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
;     char cd[2];
;     cd[0] = *p;
		mov dl, byte [bx]

;     if (cd[0] == '$') {
		cmp dl, 0x24
		jne @$106

;         cd[0] = *++p;
		inc bx
		mov dl, byte [bx]

;         if (isalpha(cd[0])) goto goodc;
		mov al, dl
		xor ah, ah
		call near isalpha_
		test ax, ax
		jne @$108
		jmp near @$114

;     } else if (isalpha(cd[0])) {
@$106:
		mov al, dl
		xor ah, ah
		call near isalpha_
		test ax, ax
		je @$109

;         if (isalpha(cd[1] = p[1])) {
		mov dh, byte [bx+1]
		mov al, dh
		xor ah, ah
		call near isalpha_
		test ax, ax
		je @$108

;             if (!islabel(p[2])) {  /* 2-character label. */
		mov al, byte [bx+2]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$111

;                 if (CONFIG_CPU_UNALIGN && sizeof(short) == 2) {
;                     *(short*)cd &= ~0x2020;
;                 } else {
;                    cd[0] &= ~32;
;                    cd[1] &= ~32;
;                 }
		and dx, 0xdfdf

;                 for (p2 = (char*)register_names; p2 != register_names + STRING_SIZE_WITHOUT_NUL(register_names); p2 += 2) {
		mov si, _register_names
@$107:
		cmp si, _register_names+0x28
		je @$111

;                     if ((CONFIG_CPU_UNALIGN && sizeof(short) == 2) ? (*(short*)cd == *(short*)p2) : (cd[0] == p2[0] && cd[1] == p2[1])) return NULL;  /* A register name without a `$' prefix is not a valid label name. */
		cmp dx, word [si]
		je @$110

;                 }
		inc si
		inc si
		jmp @$107
@$108:
		jmp near @$115
@$109:
		jmp @$114
@$110:
		jmp @$113

;             }
;             if (is_colonless_instruction(p)) return NULL;
@$111:
		mov ax, bx
		call near is_colonless_instruction_
		test ax, ax
		jne @$113

;             /* TODO(pts): Is it faster or smaller to add these to a binary tree? */
;             if (casematch(p, "SHORT!") || casematch(p, "NEAR!") || casematch(p, "FAR!") || casematch(p, "BYTE!") || casematch(p, "WORD!") || casematch(p, "DWORD!") || casematch(p, "STRICT!")) return NULL;
		mov dx, @$845
		mov ax, bx
		call near casematch_
		test al, al
		jne @$113
		mov dx, @$846
		mov ax, bx
		call near casematch_
		test al, al
		jne @$113
		mov dx, @$847
		mov ax, bx
		call near casematch_
		test al, al
		jne @$113
		mov dx, @$848
		mov ax, bx
		call near casematch_
		test al, al
		jne @$113
		mov dx, @$849
		mov ax, bx
		call near casematch_
		test al, al
		jne @$113
		mov dx, @$850
		mov ax, bx
		call near casematch_
		test al, al
		jne @$113
		mov dx, @$851
		mov ax, bx
		call near casematch_
		test al, al
@$112:
		je @$115
@$113:
		xor ax, ax
		jmp @$117

;         }
;         goto goodc;
;     }
;     if (cd[0] != '_' && cd[0] != '.' && cd[0] != '@' && cd[0] != '?') return NULL;
@$114:
		cmp dl, 0x5f
		je @$115
		cmp dl, 0x2e
		je @$115
		cmp dl, 0x40
		je @$115
		cmp dl, 0x3f
		jmp @$112

;   goodc:
;     while (islabel(*++p)) {}
@$115:
		inc bx
		mov al, byte [bx]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$115

;     return p;
@$116:
		mov ax, bx

; }
@$117:
		pop si
		pop dx
		pop bx
		ret
@$118:
    DW	@$141
    DW	@$144
    DW	@$132
    DW	@$132
    DW	@$132
    DW	@$132
    DW	@$132
    DW	@$132
    DW	@$186
    DW	@$196
    DW	@$198
    DW	@$204
    DW	@$206
    DW	@$215
    DW	@$217
    DW	@$223
    DW	@$226
    DW	@$237
    DW	@$240
    DW	@$244

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
		sub sp, 0x12
		mov si, ax

;     static struct match_stack_item {
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
;         char *p3;
;         struct label MY_FAR *label;
;     /*} u;*/
;     char c;
;     unsigned char level;
;
;     level = 0;
		xor al, al
		mov byte [bp-4], al

;     has_undefined = 0;
		mov byte [_has_undefined], al

;     msp = match_stack;
		mov di, @$969

;     goto do_match;
@$119:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax
		xor ax, ax
		mov word [bp-0x12], ax
		mov word [bp-0x10], ax
		mov bx, dx
		mov al, byte [bx]
		mov byte [bp-2], al
		cmp al, 0x28
		jne @$122
@$120:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax
		mov al, byte [bx]
		mov byte [bp-2], al
		cmp al, 0x28
		jne @$126
		mov ax, word [bp-0x10]
		cmp ax, -0x1
		jg @$121
		jne @$126
		cmp word [bp-0x12], 0xff81
		jbe @$126
@$121:
		lea si, [bx+1]
		add word [bp-0x12], 0xffff
		adc word [bp-0x10], 0xffff
		jmp @$120
@$122:
		jmp near @$134

;   do_pop:
;     --msp;
;     value2 = value1;
@$123:
		mov cx, word [bp-0x12]
		mov ax, word [bp-0x10]
		mov word [bp-0xc], ax

		sub di, 6

;     value1 = msp->value1;
		mov ax, word [di+2]
		mov word [bp-0x12], ax
		mov ax, word [di+4]
		mov word [bp-0x10], ax

;     level = msp->level;
		mov al, byte [di+1]
		mov byte [bp-4], al

;     if (msp->casei < 0) {  /* End of expression in patentheses. */
		mov al, byte [di]
		test al, al
		jge @$129

;         value1 = value2;
		mov word [bp-0x12], cx
		mov ax, word [bp-0xc]
		mov word [bp-0x10], ax

;         match_p = avoid_spaces(match_p);
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;         if (match_p[0] != ')') {
		cmp byte [si], 0x29
		je @$127

;             MESSAGE(1, "Missing close paren");
		mov ax, @$852
@$124:
		call near message_

;           match_error:
;             instruction_value = 0;
@$125:
		xor ax, ax
		mov word [_instruction_value], ax
		mov word [_instruction_value+2], ax

;             return NULL;
		jmp near @$87
@$126:
		jmp @$130

;         }
;         match_p++;
@$127:
		inc si

;         if (++msp->casei != 0) {
		inc byte [di]
		je @$128

;             level = 0;
		mov byte [bp-4], 0

;             if (++msp == match_stack + sizeof(match_stack) / sizeof(match_stack[0])) goto too_deep;
		add di, 6
		cmp di, @$970
		je @$131
@$128:
		jmp near @$185

;         }
;         goto have_value1;
;     }
; #define MATCH_CASEI_LEVEL_TO_VALUE2(casei2, level2) do { msp->casei = casei2; msp->level = level; level = level2; goto do_push; case casei2: ; } while (0)
;     switch (msp->casei) {  /* This will jump after one of the MATCH_CASEI_LEVEL_TO_VALUE2(...) macros. */
@$129:
		mov bl, al
		sub bl, 2
		cmp bl, 0x13
		ja @$132
		xor bh, bh
		shl bx, 1
		mov ax, word [bp-0x12]
		add ax, cx
		mov word [bp-8], ax
		mov ax, word [bp-0x10]
		adc ax, word [bp-0xc]
		mov dx, word [bp-0x12]
		sub dx, cx
		mov word [bp-0xa], dx
		mov dx, word [bp-0x10]
		sbb dx, word [bp-0xc]
		jmp word [cs:bx+@$118]

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
@$130:
		mov al, byte [bp-0x12]
		mov byte [di], al
		mov al, byte [bp-4]
		mov byte [di+1], al
		mov byte [bp-4], 0
		jmp near @$191
@$131:
		jmp near @$192
@$132:
		cmp di, @$969
		je @$133
		jmp near @$123
@$133:
		cmp byte [_has_undefined], 0
		je @$138
		xor ax, ax
		xor dx, dx
		jmp near @$246

;         } else if (c == '-' || c == '+' || c == '~') {  /* Unary -, + and ~. */
@$134:
		cmp al, 0x2d
		je @$135
		cmp al, 0x2b
		je @$135
		cmp al, 0x7e
		jne @$142

;             /*value1 = 0;*/  /* Delta, can be nonzero iff unary ~ is encountered. */
;             if (c == '~') { --value1; c = '-'; }
@$135:
		cmp byte [bp-2], 0x7e
		jne @$136
		mov byte [bp-2], 0x2d
		add word [bp-0x12], 0xffff
		adc word [bp-0x10], 0xffff

;             for (;;) {  /* Shortcut to squeeze multiple unary - and + operators to a single match_stack_item. */
;                 match_p = avoid_spaces(match_p + 1);
@$136:
		lea ax, [si+1]
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if (match_p[0] == '+') {}
		mov al, byte [bx]
		cmp al, 0x2b
		je @$136

;                 else if (match_p[0] == '-') { do_switch_pm: c ^= 6; }  /* Switch between ASCII '+' and '-'. */
		cmp al, 0x2d
		je @$137
		cmp al, 0x7e
		jne @$139
		mov al, byte [bp-2]
		xor ah, ah
		xor dx, dx
		add ax, -0x2c
		adc dx, 0xffff
		add word [bp-0x12], ax
		adc word [bp-0x10], dx

;                 else if (match_p[0] == '~') { value1 += (value_t)c - ('-' - 1); goto do_switch_pm; }  /* Either ++value1 or --value1. */
@$137:
		xor byte [bp-2], 6
		jmp @$136
@$138:
		jmp near @$245

;                 else { break; }
;             }
;             if (c == '-') {
@$139:
		cmp byte [bp-2], 0x2d
		jne @$143

;               MATCH_CASEI_LEVEL_TO_VALUE2(2, 6);
		mov byte [di], 2
@$140:
		mov al, byte [bp-4]
		mov byte [di+1], al
		mov byte [bp-4], 6
		jmp near @$191

;               value1 -= value2;
@$141:
		mov ax, word [bp-0xa]
		mov word [bp-0x12], ax
		mov word [bp-0x10], dx

;             } else {
		jmp near @$185
@$142:
		jmp @$146

;               MATCH_CASEI_LEVEL_TO_VALUE2(3, 6);
@$143:
		mov byte [di], 3
		jmp @$140

;               value1 += value2;
@$144:
		mov dx, word [bp-8]
		mov word [bp-0x12], dx
@$145:
		mov word [bp-0x10], ax

;             }
		jmp near @$185

;         } else if (c == '0' && (match_p[1] | 32) == 'b') {  /* Binary. */
@$146:
		cmp al, 0x30
		jne @$151
		mov al, byte [bx+1]
		or al, 0x20
		cmp al, 0x62
		jne @$151

;             match_p += 2;
		inc si
		inc si

;             /*value1 = 0;*/
;             while (match_p[0] == '0' || match_p[0] == '1' || match_p[0] == '_') {
@$147:
		mov al, byte [si]
		cmp al, 0x30
		je @$148
		cmp al, 0x31
		je @$148
		cmp al, 0x5f
		jne @$150

;                 if (match_p[0] != '_') {
@$148:
		mov al, byte [si]
		cmp al, 0x5f
		je @$149

;                     value1 <<= 1;
		shl word [bp-0x12], 1
		rcl word [bp-0x10], 1

;                     if (match_p[0] == '1')
		cmp al, 0x31
		jne @$149

;                         value1 |= 1;
		or byte [bp-0x12], 1

;                 }
;                 match_p++;
@$149:
		inc si

;             }
		jmp @$147
@$150:
		jmp near @$160

;             goto check_nolabel;
;         } else if (c == '0' && (match_p[1] | 32) == 'x') {  /* Hexadecimal. */
@$151:
		cmp byte [bp-2], 0x30
		jne @$157
		mov al, byte [si+1]
		or al, 0x20
		cmp al, 0x78
		jne @$157

;             match_p += 2;
		inc si
		inc si

;           parse_hex0:
;             shift = 0;
@$152:
		xor bx, bx

;           parse_hex:
;             /*value1 = 0;*/
;             for (; c = match_p[0], isxdigit(c); ++match_p) {
@$153:
		mov al, byte [si]
		mov byte [bp-2], al
		xor ah, ah
		call near isxdigit_
		test ax, ax
		je @$156

;                 c -= '0';
		sub byte [bp-2], 0x30

;                 if ((unsigned char)c > 9) c = (c & ~32) - 7;
		mov al, byte [bp-2]
		cmp al, 9
		jbe @$154
		and al, 0xdf
		sub al, 7
		mov byte [bp-2], al

;                 value1 = (value1 << 4) | c;
@$154:
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x10]
		mov cx, 4
@$155:
		shl ax, 1
		rcl dx, 1
		loop @$155
		mov cl, byte [bp-2]
		mov byte [bp-0xe], cl
		mov byte [bp-0xd], 0
		mov cx, word [bp-0xe]
		or cx, ax
		mov word [bp-0x12], cx
		mov word [bp-0x10], dx

;             }
		inc si
		jmp @$153

;             if (shift) {  /* Expect c == 'H' || c == 'h'. */
@$156:
		test bx, bx
		je @$160

;                 if ((c | 32) != 'h') goto bad_label;
		mov al, byte [bp-2]
		or al, 0x20
		cmp al, 0x68
		jne @$161

;                 ++match_p;
		inc si

;             }
		jmp @$160

;             goto check_nolabel;
;         } else if (c == '0' && (match_p[1] | 32) == 'o') {  /* Octal. NASM 0.98.39 doesn't support it, but NASM 0.99.06 does. */
@$157:
		cmp byte [bp-2], 0x30
		jne @$162
		mov al, byte [si+1]
		or al, 0x20
		cmp al, 0x6f
		jne @$162

;             match_p += 2;
		inc si
		inc si

;             /*value1 = 0;*/
;             for (; (unsigned char)(c = match_p[0] + 0U - '0') < 8U; ++match_p) {
@$158:
		mov al, byte [si]
		sub al, 0x30
		mov byte [bp-2], al
		cmp al, 8
		jae @$160

;                 value1 = (value1 << 3) | c;
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x10]
		mov cx, 3
@$159:
		shl ax, 1
		rcl dx, 1
		loop @$159
		mov bl, byte [bp-2]
		xor bh, bh
		or ax, bx
		mov word [bp-0x12], ax
		mov word [bp-0x10], dx

;             }
		inc si
		jmp @$158

;           check_nolabel:
;             c = match_p[0];
@$160:
		mov al, byte [si]
		mov byte [bp-2], al

;             if (islabel(c)) goto bad_label;
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$161
		jmp near @$185
@$161:
		jmp near @$172

;         } else if (c == '\'' || c == '"') {  /* Character constant. */
@$162:
		mov al, byte [bp-2]
		cmp al, 0x27
		je @$163
		cmp al, 0x22
		jne @$167

;             /*value1 = 0;*/ shift = 0;
@$163:
		xor bx, bx

;             for (++match_p; match_p[0] != '\0' && match_p[0] != c; ++match_p) {
@$164:
		inc si
		mov al, byte [si]
		test al, al
		je @$165
		cmp al, byte [bp-2]
		je @$165

;                 if (shift < sizeof(value_t) * 8) {
		cmp bx, 0x20
		jae @$164

;                     value1 |= (unsigned char)match_p[0] << shift;
		xor ah, ah
		mov cl, bl
		shl ax, cl
		cwd
		or word [bp-0x12], ax
		or word [bp-0x10], dx

;                     shift += 8;
		add bx, 8

;                 }
;             }
		jmp @$164

;             if (match_p[0] == '\0') {
@$165:
		cmp byte [si], 0
		jne @$166

;                 MESSAGE(1, "Missing close quote");
		mov ax, @$854

;                 goto match_error;
		jmp near @$124

;             } else {
;                 ++match_p;
@$166:
		inc si

;             }
;         } else if (isdigit(c)) {  /* Decimal, even if it starts with '0'. */
		jmp near @$185
@$167:
		xor ah, ah
		call near isdigit_
		test ax, ax
		je @$171

;             /*value1 = 0;*/
;             for (p2 = (char*)match_p; (unsigned char)(c = match_p[0] + 0U - '0') <= 9U; ++match_p) {
		mov word [bp-6], si
@$168:
		mov al, byte [si]
		sub al, 0x30
		mov byte [bp-2], al
		cmp al, 9
		ja @$169

;                 value1 = value1 * 10 + c;
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x10]
		mov bx, 0xa
		xor cx, cx
		call near __I4M
		mov bx, dx
		mov dl, byte [bp-2]
		xor dh, dh
		mov word [bp-0xe], 0
		add ax, dx
		mov word [bp-0x12], ax
		mov ax, word [bp-0xe]
		adc ax, bx
		mov word [bp-0x10], ax

;             }
		inc si
		jmp @$168

;             c = match_p[0];
@$169:
		mov al, byte [si]
		mov byte [bp-2], al

;             if (islabel(c)) {
		mov dl, al
		xor dh, dh
		mov ax, dx
		call near islabel_
		test ax, ax
		je @$173

;                 if ((c | 32) != 'h' && !isxdigit(c)) goto bad_label;
		mov al, dl
		or al, 0x20
		cmp al, 0x68
		je @$170
		mov ax, dx
		call near isxdigit_
		test ax, ax
		je @$172

;                 match_p = p2;
@$170:
		mov si, word [bp-6]

;                 shift = 1;
		mov bx, 1

;                 value1 = 0;
		xor ax, ax
		mov word [bp-0x12], ax
		mov word [bp-0x10], ax

;                 goto parse_hex;
		jmp near @$153

;             }
;         } else if (c == '$') {
@$171:
		cmp byte [bp-2], 0x24
		jne @$176

;             c = *++match_p;
		inc si
		mov al, byte [si]
		mov byte [bp-2], al

;             if (c == '$') {  /* Start address ($$). */
		cmp al, 0x24
		jne @$174

;                 ++match_p;
;                 is_address_used = 1;
		mov byte [_is_address_used], 1

;                 value1 = start_address;
		mov ax, word [_start_address]
		mov word [bp-0x12], ax
		mov ax, word [_start_address+2]
		mov word [bp-0x10], ax

		inc si

;                 if (islabel(match_p[0])) { bad_label:
		mov al, byte [si]
		xor ah, ah
		call near islabel_
		test ax, ax
		je @$173

;                     MESSAGE(1, "bad label");
@$172:
		mov ax, @$855
		call near message_

;                 }
@$173:
		jmp near @$185

;             } else if (isdigit(c)) {
@$174:
		mov dl, al
		xor dh, dh
		mov ax, dx
		call near isdigit_
		test ax, ax
		je @$175
		jmp near @$152

;                 /* This is nasm syntax, notice no letter is allowed after $ */
;                 /* So it's preferrable to use prefix 0x for hexadecimal */
;                 shift = 0;
;                 goto parse_hex0;
;             } else if (islabel(c)) {
@$175:
		mov ax, dx
		call near islabel_
		test ax, ax
		jne @$177

;                 goto label_expr;
;             } else {  /* Current address ($). */
;                 is_address_used = 1;
		mov byte [_is_address_used], 1

;                 value1 = current_address;
		mov ax, word [_current_address]
		mov word [bp-0x12], ax
		mov ax, word [_current_address+2]
		jmp near @$145

;             }
;         } else if (match_label_prefix(match_p)) {  /* This also matches c == '$', but we've done that above. */
@$176:
		mov ax, si
		call near match_label_prefix_
		test ax, ax
		jne @$177
		jmp near @$125

;           label_expr:
;             p2 = global_label_end;
@$177:
		mov bx, word [_global_label_end]
		mov word [bp-6], bx

;             p3 = (c == '.') ? global_label : p2;  /* If label starts with '.', then prepend global_label. */
		cmp byte [bp-2], 0x2e
		jne @$178
		mov bx, _global_label
@$178:
		mov cx, bx

;             for (; islabel(match_p[0]); *p2++ = *match_p++) {}
@$179:
		mov al, byte [si]
		xor ah, ah
		call near islabel_
		test ax, ax
		je @$180
		mov al, byte [si]
		mov bx, word [bp-6]
		mov byte [bx], al
		inc si
		inc word [bp-6]
		jmp @$179

;             *p2 = '\0';
@$180:
		mov bx, word [bp-6]
		mov byte [bx], 0

;             if (0) DEBUG1("use_label=(%s)\r\n", p3);
		mov dx, ds
		mov ax, cx
		call near find_label_
		mov bx, ax

;             label = find_label(p3);
;             if (label == NULL || RBL_IS_DELETED(label)) {
		test dx, dx
		jne @$181
		test ax, ax
		je @$182
@$181:
		mov es, dx
		test byte [es:bx+4], 0x10
		je @$183

;                 /*value1 = 0;*/
;                 has_undefined = 1;
@$182:
		mov byte [_has_undefined], 1

;                 if (assembler_pass > 1) {
		cmp word [_assembler_pass], 1
		jbe @$184

;                     MESSAGE1STR(1, "Undefined label '%s'", p3);
		mov dx, cx
		mov ax, @$856
		call near message1str_

;                 }
		jmp @$184

;             } else {
;                 value1 = label->value;
@$183:
		mov ax, word [es:bx+5]
		mov word [bp-0x12], ax
		mov ax, word [es:bx+7]
		mov word [bp-0x10], ax

;             }
;             *global_label_end = '\0';  /* Undo the concat to global_label. */
@$184:
		mov bx, word [_global_label_end]
		mov byte [bx], 0

;         } else {
;             /* TODO(pts): Make this match syntax error nonsilent? What about when trying instructions? */
;             goto match_error;
;         }
;         /* Now value1 contains the value of the expression parsed so far. */
;       have_value1:
;         if (level <= 5) {
@$185:
		cmp byte [bp-4], 5
		ja @$195
		jmp @$188

;             while (1) {
;                 match_p = avoid_spaces(match_p);
;                 if ((c = match_p[0]) == '*') {  /* Multiply operator. */
;                     match_p++;
@$186:
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x10]
		mov bx, cx
		mov cx, word [bp-0xc]
		call near __I4M
@$187:
		mov word [bp-0x12], ax
		mov word [bp-0x10], dx

;                     MATCH_CASEI_LEVEL_TO_VALUE2(10, 6);
;                     value1 *= value2;
;                 } else if (c == '/' && match_p[1] == '/') {  /* Signed division operator. */
@$188:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax
		mov al, byte [si]
		mov byte [bp-2], al
		cmp al, 0x2a
		jne @$193
		mov byte [di], 0xa
@$189:
		mov al, byte [bp-4]
		mov byte [di+1], al
		mov byte [bp-4], 6
@$190:
		inc si
@$191:
		mov ax, word [bp-0x12]
		mov word [di+2], ax
		mov ax, word [bp-0x10]
		mov word [di+4], ax
		add di, 6
		cmp di, @$970
		je @$192
		jmp near @$119
@$192:
		mov ax, @$853
		jmp near @$124
@$193:
		cmp al, 0x2f
		jne @$197
		mov bx, dx
		cmp al, byte [bx+1]
		jne @$197

;                     match_p += 2;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(11, 6);
		mov byte [di], 0xb
@$194:
		mov al, byte [bp-4]
		mov byte [di+1], al
		mov byte [bp-4], 6

		inc si
		inc si
		jmp @$191
@$195:
		jmp near @$212

;                     c = 0;
@$196:
		mov byte [bp-2], 0

;                     goto do_divide;
		jmp @$199

;                 } else if (c == '/') {  /* Unsigned division operator. */
@$197:
		mov al, byte [bp-2]
		cmp al, 0x2f
		jne @$203

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(12, 6);
		mov byte [di], 0xc
		jmp @$189

@$198:
		mov byte [bp-2], 1

;                     c = 1;
;                   do_divide:
;                     if (GET_UVALUE(value2) == 0) {
@$199:
		mov ax, word [bp-0xc]
		or ax, cx
		jne @$201

;                         if (assembler_pass > 1)  /* This also implies !has_undefined, if there is no bug. */
		cmp word [_assembler_pass], 1
		jbe @$200

;                             MESSAGE(1, "division by zero");
		mov ax, @$857
		call near message_

;                         value2 = 1;
@$200:
		mov cx, 1
		mov word [bp-0xc], 0

;                     }
;                     value1 = c ? (value_t)(GET_UVALUE(value1) / GET_UVALUE(value2)) : VALUE_DIV(GET_VALUE(value1), GET_VALUE(value2));
@$201:
		cmp byte [bp-2], 0
		je @$202
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x10]
		mov bx, cx
		mov cx, word [bp-0xc]
		call near __U4D
		jmp near @$187
@$202:
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x10]
		mov bx, cx
		mov cx, word [bp-0xc]
		call near __I4D
		jmp near @$187

;                 } else if (c == '%' && match_p[1] == '%' && !islabel(match_p[2])) {  /* Signed modulo operator. We check for islabel(...) to make it similar to NASM, which uses %%... syntax for multiine macros. */
@$203:
		cmp al, 0x25
		jne @$205
		cmp al, byte [si+1]
		jne @$205
		mov al, byte [si+2]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$205

;                     match_p += 2;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(13, 6);
		mov byte [di], 0xd
		jmp near @$194

@$204:
		mov byte [bp-2], 0

;                     c = 0;
;                     goto do_modulo;
		jmp @$207

;                 } else if (c == '%' && !islabel(match_p[1])) {  /* Unsigned modulo operator. We check for islabel(...) to make it similar to NASM, which uses %%... syntax for multiine macros. */
@$205:
		cmp byte [bp-2], 0x25
		jne @$212
		mov al, byte [si+1]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$212

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(14, 6);
		mov byte [di], 0xe
		jmp near @$189

@$206:
		mov byte [bp-2], 1

;                     c = 1;
;                   do_modulo:
;                     if (GET_UVALUE(value2) == 0) {
@$207:
		mov ax, word [bp-0xc]
		or ax, cx
		jne @$209

;                         if (assembler_pass > 1)  /* This also implies !has_undefined, if there is no bug. */
		cmp word [_assembler_pass], 1
		jbe @$208

;                             MESSAGE(1, "modulo by zero");
		mov ax, @$858
		call near message_

;                         value2 = 1;
@$208:
		mov cx, 1
		mov word [bp-0xc], 0

;                     }
;                     value1 = c ? (value_t)(GET_UVALUE(value1) % GET_UVALUE(value2)) : VALUE_MOD(GET_VALUE(value1), GET_VALUE(value2));
@$209:
		cmp byte [bp-2], 0
		je @$210
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x10]
		mov bx, cx
		mov cx, word [bp-0xc]
		call near __U4D
		jmp @$211
@$210:
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x10]
		mov bx, cx
		mov cx, word [bp-0xc]
		call near __I4D

;                 } else {
;                     break;
;                 }
@$211:
		mov word [bp-0x12], bx
		mov word [bp-0x10], cx
		jmp near @$188

;             }
;         }
;         if (level <= 4) {
@$212:
		cmp byte [bp-4], 4
		ja @$218

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$213:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if ((c = match_p[0]) == '+') {  /* Add operator. */
		mov al, byte [bx]
		mov byte [bp-2], al
		lea ax, [bx+1]
		cmp byte [bp-2], 0x2b
		jne @$216

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(15, 5);
		mov byte [di], 0xf
@$214:
		mov dl, byte [bp-4]
		mov byte [di+1], dl
		mov byte [bp-4], 5

		mov si, ax
		jmp near @$191

;                     value1 += value2;
@$215:
		mov dx, word [bp-8]
		mov word [bp-0x12], dx
		mov word [bp-0x10], ax

;                 } else if (c == '-') {  /* Subtract operator. */
		jmp @$213
@$216:
		cmp byte [bp-2], 0x2d
		jne @$218

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(16, 5);
		mov byte [di], 0x10
		jmp @$214

;                     value1 -= value2;
;                 } else {
;                     break;
;                 }
@$217:
		mov ax, word [bp-0xa]
		mov word [bp-0x12], ax
		mov word [bp-0x10], dx
		jmp @$213

;             }
;         }
;         if (level <= 3) {
@$218:
		cmp byte [bp-4], 3
		ja @$225

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$219:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if (((c = match_p[0]) == '<' && match_p[1] == '<') || (c == '>' && match_p[1] == '>')) { /* Shift to left */
		mov al, byte [bx]
		mov byte [bp-2], al
		cmp al, 0x3c
		jne @$220
		cmp al, byte [bx+1]
		je @$221
@$220:
		cmp byte [bp-2], 0x3e
		jne @$225
		cmp byte [si+1], 0x3e
		jne @$225

;                     match_p += 2;
@$221:
		inc si
		inc si

;                     if (c == '<') {
		cmp byte [bp-2], 0x3c
		jne @$224

;                         MATCH_CASEI_LEVEL_TO_VALUE2(17, 4);
		mov byte [di], 0x11
@$222:
		mov al, byte [bp-4]
		mov byte [di+1], al
		mov byte [bp-4], 4
		jmp near @$191

;                         c = 1;
@$223:
		mov byte [bp-2], 1

;                     } else {
		jmp @$227

;                         MATCH_CASEI_LEVEL_TO_VALUE2(18, 4);
@$224:
		mov byte [di], 0x12
		jmp @$222
@$225:
		jmp @$235

;                         c = 0;
@$226:
		mov byte [bp-2], 0

;                     }
;                     if (GET_UVALUE(value2) > 31) {
@$227:
		cmp word [bp-0xc], 0
		jne @$228
		cmp cx, 0x1f
		jbe @$229

;                         /* 8086 processor (in 16-bit mode) uses all 8 bits of the shift amount.
;                          * i386 and amd64 processors in both 16-bit and 32-bit mode uses the last 5 bits of the shift amount.
;                          * amd64 processor in 64-bit mode uses the last 6 bits of the shift amount.
;                          * To get deterministic output, we disallow shift amounts with more than 5 bits.
;                          * NASM has nondeterministic output, depending on the host architecture (32-bit mode or 64-bit mode).
;                          */
;                         if (assembler_pass > 1)  /* This also implies !has_undefined, if there is no bug. */
@$228:
		cmp word [_assembler_pass], 1
		jbe @$219

;                             MESSAGE(1, "shift by larger than 31");
		mov ax, @$859
		call near message_
		jmp @$219

;                         value2 = 0;
; #if !CONFIG_SHIFT_OK_31
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
; #endif  /* CONFIG_SHIFT_OK_31 */
;                     } else {
; #if CONFIG_SHIFT_SIGNED
;                         value1 = c ? GET_VALUE( value1) << GET_UVALUE(value2) : GET_VALUE( value1) >> GET_UVALUE(value2);  /* Sign-extend value1 to CONFIG_VALUE_BITS. */
; #else
;                         value1 = c ? GET_UVALUE(value1) << GET_UVALUE(value2) : GET_UVALUE(value1) >> GET_UVALUE(value2);  /* Zero-extend value1 to CONFIG_VALUE_BITS. */
@$229:
		cmp byte [bp-2], 0
		je @$232
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x10]
		jcxz @$231
@$230:
		shl ax, 1
		rcl dx, 1
		loop @$230
@$231:
		jmp @$234
@$232:
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x10]
		jcxz @$234
@$233:
		shr dx, 1
		rcr ax, 1
		loop @$233
@$234:
		mov word [bp-0x12], ax
		mov word [bp-0x10], dx

; #endif
;                     }
		jmp near @$219

;                 } else {
;                     break;
;                 }
;             }
;         }
;         if (level <= 2) {
@$235:
		cmp byte [bp-4], 2
		ja @$238

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$236:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax

;                 if (match_p[0] == '&') {    /* Binary AND */
		cmp byte [si], 0x26
		jne @$238

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(19, 3);
		mov byte [di], 0x13
		mov al, byte [bp-4]
		mov byte [di+1], al
		mov byte [bp-4], 3
		jmp near @$190

;                     value1 &= value2;
;                 } else {
;                     break;
;                 }
@$237:
		and word [bp-0x12], cx
		mov ax, word [bp-0xc]
		and word [bp-0x10], ax

;             }
		jmp @$236

;         }
;         if (level <= 1) {
@$238:
		cmp byte [bp-4], 1
		ja @$241

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$239:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax

;                 if (match_p[0] == '^') {    /* Binary XOR */
		cmp byte [si], 0x5e
		jne @$241

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(20, 2);
		mov byte [di], 0x14
		mov al, byte [bp-4]
		mov byte [di+1], al
		mov byte [bp-4], 2

		jmp near @$190

;                     value1 ^= value2;
;                 } else {
;                     break;
;                 }
@$240:
		xor word [bp-0x12], cx
		mov ax, word [bp-0xc]
		xor word [bp-0x10], ax

;             }
		jmp @$239

;         }
;         if (level == 0) {  /* Top tier. */
@$241:
		cmp byte [bp-4], 0
		je @$243
@$242:
		jmp near @$132

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$243:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax

;                 if (match_p[0] == '|') {    /* Binary OR */
		cmp byte [si], 0x7c
		jne @$242

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(21, 1);
		mov byte [di], 0x15
		mov al, byte [bp-4]
		mov byte [di+1], al
		mov byte [bp-4], 1

		jmp near @$190

;                     value1 |= value2;
;                 } else {
;                     break;
;                 }
@$244:
		or word [bp-0x12], cx
		mov ax, word [bp-0xc]
		or word [bp-0x10], ax

;             }
		jmp @$243

;         }
;     }
;     if (msp != match_stack) goto do_pop;
;     instruction_value = has_undefined ? 0 : GET_VALUE(value1);
@$245:
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x10]
@$246:
		mov word [_instruction_value], ax
		mov word [_instruction_value+2], dx

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
@$247:
		mov dl, byte [bx]
		cmp dl, 0x2d
		je @$248
		cmp dl, 0x2b
		je @$248
		cmp dl, 0x7e
		je @$248
		mov al, dl
		xor ah, ah
		call near isspace_
		test ax, ax
		je @$249
@$248:
		inc bx
		jmp @$247

;     if (c == '0' && (p[1] | 32) == 'b') {  /* Binary. */
@$249:
		cmp dl, 0x30
		jne @$252
		mov al, byte [bx+1]
		or al, 0x20
		cmp al, 0x62
		jne @$252

;         p += 2;
		inc bx
		inc bx

;         for (; (c = p[0]) == '0' || c == '1' || c == '_'; ++p) {}
@$250:
		mov dl, byte [bx]
		cmp dl, 0x30
		je @$251
		cmp dl, 0x31
		je @$251
		cmp dl, 0x5f
		jne @$257
@$251:
		inc bx
		jmp @$250

;     } else if (c == '0' && (p[1] | 32) == 'x') {  /* Hexadecimal. */
@$252:
		cmp dl, 0x30
		jne @$255
		mov al, byte [bx+1]
		or al, 0x20
		cmp al, 0x78
		jne @$255

;       try_hex2:
;         p += 2;
@$253:
		inc bx
		inc bx

;         for (; c = p[0], isxdigit(c); ++p) {}
@$254:
		mov dl, byte [bx]
		mov al, dl
		xor ah, ah
		call near isxdigit_
		test ax, ax
		je @$257
		inc bx
		jmp @$254

;     } else if (c == '0' && (p[1] | 32) == 'o') {  /* Octal. */
@$255:
		cmp dl, 0x30
		jne @$258
		mov al, byte [bx+1]
		or al, 0x20
		cmp al, 0x6f
		jne @$258

;         p += 2;
		inc bx
		inc bx

;         for (; (unsigned char)(c = p[0]) - '0' + 0U < 8U; ++p) {}
@$256:
		mov dl, byte [bx]
		mov al, dl
		xor ah, ah
		sub ax, 0x30
		cmp ax, 8
		jae @$257
		inc bx
		jmp @$256
@$257:
		jmp near @$270

;     } else if (c == '\'' || c == '"') {  /* Character constant. */
@$258:
		cmp dl, 0x27
		je @$259
		cmp dl, 0x22
		jne @$263

;         return p[1] != '\0' && p[1] != c && p[2] == c;
@$259:
		mov al, byte [bx+1]
		test al, al
		je @$262
		cmp dl, al
		je @$262
		cmp dl, byte [bx+2]
@$260:
		jne @$262
@$261:
		mov al, 1
		jmp near @$89
@$262:
		xor al, al
		jmp near @$89

;     } else if (isdigit(c)) {  /* Decimal or hexadecimal. */
@$263:
		mov al, dl
		xor ah, ah
		call near isdigit_
		test ax, ax
		je @$269

;         for (; (unsigned char)(c = p[0]) - '0' + 0U <= 9U; ++p) {}
@$264:
		mov dl, byte [bx]
		mov al, dl
		xor ah, ah
		mov cx, ax
		sub cx, 0x30
		cmp cx, 9
		ja @$265
		inc bx
		jmp @$264

;         if ((c | 32) == 'h' || isxdigit(c)) {
@$265:
		mov dh, dl
		or dh, 0x20
		cmp dh, 0x68
		je @$266
		call near isxdigit_
		test ax, ax
		je @$270

;             for (; c = p[0], isxdigit(c); ++p) {}
@$266:
		mov dl, byte [bx]
		mov al, dl
		xor ah, ah
		call near isxdigit_
		test ax, ax
		je @$267
		inc bx
		jmp @$266

;             return (c | 32) == 'h';
@$267:
		mov al, dl
		or al, 0x20
		cmp al, 0x68
		je @$261
@$268:
		xor al, al
		jmp near @$89

;         }
;     } else if (c == '$' && isdigit(p[1])) {
@$269:
		cmp dl, 0x24
		jne @$268
		mov al, byte [bx+1]
		xor ah, ah
		call near isdigit_
		test ax, ax
		je @$268

;         goto try_hex2;
;     } else {
		jmp near @$253

;         return 0;
;     }
;     return c == '\0';
@$270:
		test dl, dl
		jmp @$260

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
;     char puc[2];
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
		je @$273
		mov al, byte [bx+1]
		xor ah, ah
		call near isalpha_
		test ax, ax
		je @$273
		mov al, byte [bx+2]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$273

;         return NULL;
;     r0 = r = GP_REGISTER_NAMES + (width & 16);  /* Works for width == 8 and width == 16. */
		and dx, 0x10
		mov si, _register_names+8
		add si, dx
		mov ax, si

;     if (CONFIG_CPU_UNALIGN && sizeof(short) == 2) {
;         *(short*)puc = *(short*)p & ~0x2020;
;     } else {
;         puc[0] = p[0] & ~32;
;         puc[1] = p[1] & ~32;
;     }
		mov dx, word [bx]
		and dx, 0xdfdf
		mov word [bp-4], dx

;     for (r2 = r + 16; r != r2; r += 2) {
		lea dx, [si+0x10]
		mov bx, word [bp-4]
@$271:
		cmp si, dx
		je @$273
		cmp bx, word [si]
		jne @$272

;         if ((CONFIG_CPU_UNALIGN && sizeof(short) == 2) ? *(short*)puc == *(short*)r : (puc[0] == r[0] && puc[1] == r[1])) {
;             *reg = (r - r0) >> 1;
		sub si, ax
		mov ax, si
		sar ax, 1
		mov byte [di], al

;             return p + 2;
		mov ax, cx
		inc ax
		inc ax
		jmp near @$46

;         }
;     }
@$272:
		inc si
		inc si
		jmp @$271

;     return NULL;
@$273:
		xor ax, ax

; }
		jmp near @$46

;
; /* --- Recording of wide sources for -O0
;  *
;  * In assembler_pass == 1, add_wide_source_in_pass_1(...) for all jump
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
; #if CONFIG_DOSMC_PACKED
; _Packed  /* Disable extra aligment byte at the end of `struct label'. */
; #endif
; struct wide_instr_block {
;     struct wide_instr_block MY_FAR *next;
;     uvalue_t instrs[128];
; };
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
		je @$274
		add bx, 1
		mov word [bp-2], bx
		adc di, 0

; #if DEBUG
;     if (wide_instr_add_at != NULL && wide_instr_add_at[-1] >= fpos) {
;         DEBUG1("oops: added non-strictly-increasing wide instruction at fpos=0x%x\r\n", (unsigned)fpos);
;         MESSAGE(1, "oops: bad wide position");
;         return;
;     }
; #endif
;     if (wide_instr_add_at == wide_instr_add_block_end) {
@$274:
		mov dx, word [_wide_instr_add_at]
		mov si, word [_wide_instr_add_at+2]
		mov ax, word [_wide_instr_add_block_end]
		mov bx, word [_wide_instr_add_block_end+2]
		cmp si, bx
		jne @$279
		cmp dx, ax
		jne @$279

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
		ja @$275
		jb @$276
		test ax, ax
		je @$276
@$275:
		xor ax, ax
		xor dx, dx
		jmp @$277
@$276:
		xchg word [si], ax
		xchg word [si+2], dx
@$277:
		mov bx, ax
		mov cx, dx
		test dx, dx
		jne @$278
		test ax, ax
		jne @$278
		call near fatal_out_of_memory_

;         if (wide_instr_first_block == NULL) {
@$278:
		mov dx, word [_wide_instr_first_block]
		mov ax, word [_wide_instr_first_block+2]
		test ax, ax
		jne @$280
		test dx, dx
		jne @$280

;             wide_instr_first_block = new_block;
		mov word [_wide_instr_first_block], bx
		mov word [_wide_instr_first_block+2], cx

;         } else {
		jmp @$281
@$279:
		jmp @$282

;             wide_instr_last_block->next = new_block;
@$280:
		les si, [_wide_instr_last_block]
		mov word [es:si], bx
		mov word [es:si+2], cx

;         }
;         wide_instr_last_block = new_block;
@$281:
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
@$282:
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
		je @$283
		add dx, 1
		adc ax, 0

;     if (0) DEBUG2("guess from fpos=0x%x rp=%p\r\n", (unsigned)fpos, (void*)wide_instr_read_at);
;     if (wide_instr_read_at) {
@$283:
		mov bx, word [_wide_instr_read_at]
		mov si, word [_wide_instr_read_at+2]
		test si, si
		jne @$284
		test bx, bx
		je @$289

;         if (fpos == *wide_instr_read_at) {  /* Called again with the same fpos as last time. */
@$284:
		mov es, si
		cmp ax, word [es:bx+2]
		jne @$286
		cmp dx, word [es:bx]
		jne @$286

;             return 1;
@$285:
		mov al, 1
		jmp near @$87

;         } else if (fpos <= *wide_instr_read_at) { bad_instr_order:
@$286:
		cmp ax, word [es:bx+2]
		jb @$287
		jne @$288
		cmp dx, word [es:bx]
		ja @$288

;             DEBUG2("oops: bad instr order fpos=0x%x added=0x%x\r\n", (unsigned)fpos, wide_instr_read_at ? (unsigned)*wide_instr_read_at : 0);
;             MESSAGE(1, "oops: bad instr order");
@$287:
		mov ax, @$860
		call near message_

;             goto return_0;
		jmp near @$299

;         }
;         vp = wide_instr_read_at + 1;
@$288:
		mov word [bp-2], si
		add bx, 4

;     } else {
		jmp @$291

;         if (wide_instr_first_block == NULL) goto return_0;  /* No wide instructions at all. */
@$289:
		mov si, word [_wide_instr_first_block]
		mov bx, word [_wide_instr_first_block+2]
		test bx, bx
		jne @$290
		test si, si
		je @$293

;         wide_instr_read_block = wide_instr_first_block;
@$290:
		mov word [_wide_instr_read_block], si
		mov word [_wide_instr_read_block+2], bx

;         vp = wide_instr_read_block->instrs;
		mov word [bp-2], bx
		lea bx, [si+4]

;     }
;     if (0) DEBUG2("guess2 from 0x%x at=%d\r\n", (unsigned)fpos, (int)(vp - wide_instr_first_block->instrs));
;     if (vp == wide_instr_add_at) {  /* All wide instructions have been read. Also matches if there were none. */
@$291:
		mov si, word [_wide_instr_add_at]
		mov cx, word [_wide_instr_add_at+2]
		cmp cx, word [bp-2]
		jne @$292
		cmp bx, si
		je @$293

;         goto return_0;
;     } else if (vp == wide_instr_read_block->instrs + sizeof(wide_instr_read_block->instrs) / sizeof(wide_instr_read_block->instrs[0])) {
@$292:
		mov si, word [_wide_instr_read_block]
		mov cx, word [_wide_instr_read_block+2]
		mov word [bp-4], cx
		lea cx, [si+0x204]
		mov di, word [bp-2]
		cmp di, word [bp-4]
		jne @$294
		cmp bx, cx
		jne @$294

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
		jmp @$295
@$293:
		jmp @$299

;     } else {
;         is_next_block = 0;
@$294:
		xor cl, cl

;     }
;     if (fpos > *vp) {
@$295:
		mov es, word [bp-2]
		cmp ax, word [es:bx+2]
		ja @$287
		jne @$296
		cmp dx, word [es:bx]
		jbe @$296
		jmp near @$287

;         DEBUG0("oops: bad instr order2\r\n");
;         goto bad_instr_order;
;     } else if (fpos == *vp) {
@$296:
		cmp ax, word [es:bx+2]
		jne @$299
		cmp dx, word [es:bx]
		jne @$299

;         wide_instr_read_at = vp;
		mov word [_wide_instr_read_at], bx
		mov word [_wide_instr_read_at+2], es

;         if (is_next_block) wide_instr_read_block = wide_instr_read_block->next;
		test cl, cl
		jne @$298
@$297:
		jmp near @$285
@$298:
		les bx, [_wide_instr_read_block]
		mov ax, word [es:bx]
		mov dx, word [es:bx+2]
		mov word [_wide_instr_read_block], ax
		mov word [_wide_instr_read_block+2], dx
		jmp @$297

;         return 1;
;     } else { return_0:
;         return 0;
@$299:
		xor al, al

;     }
; }
		jmp near @$87

;
; /* --- */
;
; static const unsigned char reg_to_addressing[8] = { 0, 0, 0, 7 /* BX */, 0, 6 /* BP */, 4 /* SI */, 5 /* DI */ };
;
; /*
;  ** Match addressing (r/m): can be register or effective address [...].
;  ** As a side effect, it sets instruction_addressing, instruction_offset, instruction_offset_width.
;  */
; static const char *match_addressing(const char *p, int width) {
match_addressing_:
		push bx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		push ax
		mov di, ax

;     unsigned char reg, reg2, reg12;
;     unsigned char *instruction_addressing_p = &instruction_addressing;  /* Using this pointer saves 20 bytes in __DOSMC__. */
		mov si, _instruction_addressing

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

;
;     p = avoid_spaces(p);
		mov ax, di
		call near avoid_spaces_
		mov di, ax

;     if (*p == '[') {
		cmp byte [di], 0x5b
		jne @$303

;         p = avoid_spaces(p + 1);
		inc ax
		call near avoid_spaces_
		mov bx, ax
		mov di, ax

;         if (p[0] != '\0' && ((p[1] & ~32) == 'S') && ((c = p[0] & ~32) == 'S' || c - 'C' + 0U <= 'E' - 'C' + 0U)) {  /* Possible segment register: CS, DS, ES or SS. */
		cmp byte [bx], 0
		je @$306
		mov al, byte [bx+1]
		and ax, 0xdf
		cmp ax, 0x53
		jne @$306
		mov dl, byte [bx]
		and dl, 0xdf
		cmp dl, 0x53
		je @$300
		mov al, dl
		sub ax, 0x43
		cmp ax, 2
		ja @$306

;             p2 = avoid_spaces(p + 2);
@$300:
		lea ax, [di+2]
		call near avoid_spaces_
		mov bx, ax

;             if (p2[0] == ':') {  /* Found segment register. */
		cmp byte [bx], 0x3a
		jne @$306

;                 p = avoid_spaces(p2 + 1);
		inc ax
		call near avoid_spaces_
		mov di, ax

;                 instruction_addressing_segment = c == 'C' ? 0x2e : c == 'D' ? 0x3e : c == 'E' ? 0x26 : /* c == 'S' ? */ 0x36;
		cmp dl, 0x43
		jne @$301
		mov ax, 0x2e
		jmp @$305
@$301:
		cmp dl, 0x44
		jne @$302
		mov ax, 0x3e
		jmp @$305
@$302:
		cmp dl, 0x45
		jne @$304
		mov ax, 0x26
		jmp @$305
@$303:
		jmp near @$331
@$304:
		mov ax, 0x36
@$305:
		mov byte [_instruction_addressing_segment], al

;             }
;         }
;         p2 = match_register(p, 16, &reg);
@$306:
		lea bx, [bp-2]
		mov dx, 0x10
		mov ax, di
		call near match_register_

;         if (p2 != NULL) {
		test ax, ax
		je @$309

;             p = avoid_spaces(p2);
		call near avoid_spaces_
		mov di, ax

;             if (*p == ']') {
		cmp byte [di], 0x5d
		jne @$310

;                 p++;
		inc di

;                 if (reg == 5) {  /* Just [BP] without offset. */
		mov al, byte [bp-2]
		cmp al, 5
		jne @$307

;                     *instruction_addressing_p = 0x46;
		mov byte [si], 0x46

;                     /*instruction_offset = 0;*/  /* Already set. */
;                     ++instruction_offset_width;
		inc byte [_instruction_offset_width]

;                 } else {
		jmp near @$332

;                     if ((*instruction_addressing_p = reg_to_addressing[reg]) == 0) return NULL;
@$307:
		mov bl, al
		xor bh, bh
		mov al, byte [bx+_reg_to_addressing]
		mov byte [si], al
		test al, al
		jne @$313
@$308:
		xor ah, ah
		jmp near @$333
@$309:
		jmp near @$328

;                 }
;             } else if (*p == '+' || *p == '-') {
@$310:
		cmp byte [di], 0x2b
		je @$311
		cmp byte [di], 0x2d
		jne @$312

;                 if (*p == '+') {
@$311:
		cmp byte [di], 0x2b
		jne @$315

;                     p = avoid_spaces(p + 1);
		lea ax, [di+1]
		call near avoid_spaces_
		mov di, ax

;                     p2 = match_register(p, 16, &reg2);
		lea bx, [bp-4]
		mov dx, 0x10
		call near match_register_
		mov bx, ax

;                 } else {
;                     p2 = NULL;
;                 }
;                 if (p2 != NULL) {
		test ax, ax
		je @$315

;                     reg12 = reg * reg2;
		mov al, byte [bp-2]
		mul byte [bp-4]

;                     if (reg12 == 6 * 3) {  /* BX+SI / SI+BX. */
		cmp al, 0x12
		je @$314

;                     } else if (reg12 == 7 * 3) {  /* BX+DI / DI+BX. */
		cmp al, 0x15
		je @$314

;                     } else if (reg12 == 6 * 5) {  /* BP+SI / SI+BP. */
		cmp al, 0x1e
		je @$314

;                     } else if (reg12 == 7 * 5) {  /* BP+DI / DI+BP. */
		cmp al, 0x23
		je @$314

;                     } else {  /* Not valid. */
;                         return NULL;
@$312:
		xor ax, ax
		jmp near @$333
@$313:
		jmp near @$332

;                     }
;                     *instruction_addressing_p = reg + reg2 - 9;  /* Magic formula for encoding any of BX+SI, BX+DI, BP+SI, BP+DI. */
@$314:
		mov al, byte [bp-2]
		add al, byte [bp-4]
		sub al, 9
		mov byte [si], al

;                     p = avoid_spaces(p2);
		mov ax, bx
		call near avoid_spaces_
		mov bx, ax
		mov di, ax

;                     if (*p == ']') {
		mov al, byte [bx]
		cmp al, 0x5d
		jne @$316

;                         p++;
		lea di, [bx+1]

;                     } else if (*p == '+' || *p == '-') {
		jmp @$313
@$315:
		jmp near @$326
@$316:
		cmp al, 0x2b
		je @$317
		cmp al, 0x2d
		jne @$312

;                         p = match_expression(p);
@$317:
		mov ax, di
		call near match_expression_
		mov di, ax

;                         if (p == NULL)
		test ax, ax
		je @$325

;                             return NULL;
;                         if (*p != ']')
		cmp byte [di], 0x5d
		jne @$312

;                             return NULL;
;                         p++;
;                         reg = 0;  /* Make sure it's not BP, as checked below. */
		mov byte [bp-2], 0

;                         instruction_offset = GET_U16(instruction_value);  /* Higher bits are ignored. */
@$318:
		mov ax, word [_instruction_value]
		mov word [_instruction_offset], ax

		inc di

;                       set_width:
;                         if (opt_level <= 1) {  /* With -O0, `[...+ofs]' is 8-bit offset iff there are no undefined labels in ofs and it fits to 8-bit signed in assembler_pass == 1. This is similar to NASM. */
		cmp byte [_opt_level], 1
		ja @$320

;                            if (assembler_pass == 1) {
		cmp word [_assembler_pass], 1
		jne @$319

;                                if (has_undefined) {
		cmp byte [_has_undefined], 0
		je @$320

;                                    instruction_offset_width = 3;  /* Width is actually 2, but this indicates that add_wide_instr_in_pass_1(...) should be called later if this match is taken. */
		mov byte [_instruction_offset_width], 3

;                                    goto set_16bit_offset;
		jmp @$323

;                                }
;                            } else {
;                                if (is_wide_instr_in_pass_2(0)) goto force_16bit_offset;
@$319:
		xor ax, ax
		call near is_wide_instr_in_pass_2_
		test al, al
		jne @$322

;                            }
;                         }
;                         if (instruction_offset != 0 || reg == 5 /* BP only */) {
@$320:
		cmp word [_instruction_offset], 0
		jne @$321
		cmp byte [bp-2], 5
		jne @$330

;                             if ((instruction_offset + 0x80) & 0xff00U) {
@$321:
		mov ax, word [_instruction_offset]
		add ax, 0x80
		test ah, 0xff
		je @$324

;                               force_16bit_offset:
;                                 instruction_offset_width = 2;
@$322:
		mov byte [_instruction_offset_width], 2

;                               set_16bit_offset:
;                                 *instruction_addressing_p |= 0x80;  /* 16-bit offset. */
@$323:
		or byte [si], 0x80

;                             } else {
		jmp @$332

;                                 ++instruction_offset_width;
@$324:
		inc byte [_instruction_offset_width]

;                                 *instruction_addressing_p |= 0x40;  /* Signed 8-bit offset. */
		or byte [si], 0x40

;                             }
		jmp @$332
@$325:
		jmp @$333

;                         }
;                     } else {    /* Syntax error */
;                         return NULL;
;                     }
;                 } else {
;                     if ((*instruction_addressing_p = reg_to_addressing[reg]) == 0) return NULL;
@$326:
		mov bl, byte [bp-2]
		xor bh, bh
		mov al, byte [bx+_reg_to_addressing]
		mov byte [si], al
		test al, al
		jne @$327
		jmp near @$308

;                     p = match_expression(p);
@$327:
		mov ax, di
		call near match_expression_
		mov di, ax

;                     if (p == NULL)
		test ax, ax
		je @$333

;                         return NULL;
;                     if (*p != ']')
		cmp byte [di], 0x5d
		je @$318

;                         return NULL;
;                     p++;
;                     instruction_offset = GET_U16(instruction_value);
;                     goto set_width;
		jmp near @$312

;                 }
;             } else {    /* Syntax error */
;                 return NULL;
;             }
;         } else {    /* No valid register, try expression (absolute addressing) */
;             p = match_expression(p);
@$328:
		mov ax, di
		call near match_expression_
		mov di, ax

;             if (p == NULL)
		test ax, ax
		je @$333

;                 return NULL;
;             instruction_offset = GET_U16(instruction_value);
		mov ax, word [_instruction_value]
		mov word [_instruction_offset], ax

;             if (*p != ']')
		cmp byte [di], 0x5d
		je @$329
		jmp near @$312

;                 return NULL;
;             p++;
;             *instruction_addressing_p = 0x06;
@$329:
		mov byte [si], 6

;             instruction_offset_width = 2;
		mov byte [_instruction_offset_width], 2

		inc di

;         }
@$330:
		jmp @$332

;     } else {    /* Register */
;         p = match_register(p, width, &reg);
@$331:
		lea bx, [bp-2]
		call near match_register_
		mov di, ax

;         if (p == NULL)
		test ax, ax
		je @$333

;             return NULL;
;         *instruction_addressing_p = 0xc0 | reg;
		mov al, byte [bp-2]
		or al, 0xc0
		mov byte [_instruction_addressing], al

;     }
;     return p;
@$332:
		mov ax, di

; }
@$333:
		mov sp, bp
		pop bp
@$334:
		pop di
		pop si
		pop bx
		ret

;
; /* Not declaring static for compatibility with C++ and forward declarations. */
; extern struct bbprintf_buf emit_bbb;
;
; static char emit_buf[512];
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
		jne @$336
@$335:
		jmp near @$89

;         if (write(output_fd, emit_buf, size) != size) {
@$336:
		mov ax, word [_output_fd]
		mov bx, cx
		mov dx, _emit_buf
		call near write_
		cmp ax, cx
		je @$337

;             MESSAGE(1, "error writing to output file");
		mov ax, @$861
		call near message_

;             exit(3);
		mov ax, 3
		mov ah, 0x4c
		int 0x21

;         }
;         emit_bbb.p = emit_buf;
@$337:
		mov word [_emit_bbb+4], _emit_buf

;     }
		jmp @$335

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
@$338:
		mov ax, word [_emit_bbb+2]
		sub ax, word [_emit_bbb+4]
		mov word [bp-2], ax
		cmp dx, ax
		jl @$339

; #ifdef __DOSMC__  /* A few bytes smaller than memcpy(...). */
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
		jmp @$338

; #ifdef __DOSMC__  /* A few bytes smaller than memcpy(...). */
;     emit_bbb.p = (char*)memcpy_newdest_inline(emit_bbb.p, s, size);
@$339:
		mov di, word [_emit_bbb+4]
		mov cx, dx
		mov si, bx
		push ds
		pop es
		rep movsb
		mov word [_emit_bbb+4], di
		jmp near @$77

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
		ja @$341
@$340:
		jmp near @$334

;         emit_write(s, size);
@$341:
		mov dx, bx
		mov ax, si
		call near emit_write_

;         bytes += size;
		mov ax, bx
		cwd
		add word [_bytes], ax
		adc word [_bytes+2], dx

;         if (g != NULL) {
		cmp word [_g], 0
		je @$340

;             for (; size > 0 && g != generated + sizeof(generated); *g++ = *s++, --size) {}
@$342:
		test bx, bx
		jle @$340
		mov ax, word [_g]
		cmp ax, _generated+8
		je @$340
		mov di, si
		mov dx, ax
		inc si
		inc ax
		mov word [_g], ax
		mov al, byte [di]
		mov di, dx
		mov byte [di], al
		dec bx
		jmp @$342

;         }
;     }
; }
;
; /*
;  ** Emit one byte to output
;  */
; static void emit_byte(int byte) {  /* Changing `c' to `char' would increase the file size for __DOSMC__. */
emit_byte_:
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
		je @$343

;         MESSAGE(1, "extra characters at end of line");
		mov ax, @$862
		call near message_

;         return NULL;
		xor ax, ax

;     }
;     return p;
; }
@$343:
		pop bx
		ret

;
; char was_strict;
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
		mov dx, @$851
		call near casematch_
		test al, al
		je @$346

;         p = avoid_spaces(p + 6);
		lea ax, [si+6]
		call near avoid_spaces_
		mov bx, ax
		mov cx, ax

;         if (casematch(p, "BYTE!") || casematch(p, "WORD!") || casematch(p, "SHORT!") || casematch(p, "NEAR!")) {
		mov dx, @$848
		call near casematch_
		test al, al
		jne @$344
		mov dx, @$849
		mov ax, bx
		call near casematch_
		test al, al
		jne @$344
		mov dx, @$845
		mov ax, bx
		call near casematch_
		test al, al
		jne @$344
		mov dx, @$846
		mov ax, bx
		call near casematch_
		test al, al
		je @$345

;             was_strict = 1;
@$344:
		mov byte [_was_strict], 1

;         } else {
		jmp @$346

;             p = p1;
@$345:
		mov cx, si

;         }
;     }
;     return p;
; }
@$346:
		mov ax, cx
		jmp near @$88

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
		mov word [bp-0xc], dx

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
@$347:
		xor al, al
		mov byte [_instruction_addressing_segment], al

;     instruction_offset_width = 0;  /* Reset it in case something in the previous pattern didn't match after a matching match_addressing(...). */
		mov byte [_instruction_offset_width], al

;     for (error_base = pattern_and_encode; (dc = *pattern_and_encode++) != ' ';) {
		mov bx, word [bp-0xc]
		mov word [bp-0x14], bx
@$348:
		mov bx, word [bp-0xc]
		mov bl, byte [bx]
		inc word [bp-0xc]
		cmp bl, 0x20
		je @$354

;         if (dc - 'j' + 0U <= 'o' - 'j' + 0U) {  /* Addressing: 'j': %d8, 'k': %d16, 'l': %db8, 'm': %dw16, 'n': effective address without a size qualifier (for lds, les), 'o' effective address without a size qualifier (for lea). */
		mov al, bl
		xor ah, ah
		mov dx, ax
		sub dx, 0x6a
		cmp dx, 5
		ja @$355

;             qualifier = 0;
		xor al, bl
		mov word [bp-0xe], ax

;             if (dc == 'n') {
		cmp bl, 0x6e
		jne @$350

;               do_n_or_o:
;                 if (p[0] != '[') goto mismatch;
@$349:
		cmp byte [si], 0x5b
		jne @$356
		jmp near @$365

;                 goto do_addressing_16;  /* 8 would have been also fine. */
;             } else if (dc == 'o') {
@$350:
		cmp bl, 0x6f
		jne @$351

;                 if (do_opt_lea) do_opt_lea_now = 1;
		cmp byte [_do_opt_lea], 0
		je @$349
		mov byte [bp-8], 1
		jmp @$349

;                 goto do_n_or_o;
;             } else if (casematch(p, "WORD!")) {
@$351:
		mov dx, @$849
		mov ax, si
		call near casematch_
		test al, al
		je @$353

;                 p += 4;
;                 qualifier = 16;
		mov word [bp-0xe], 0x10

@$352:
		add si, 4

;             } else if (casematch(p, "BYTE!")) {
		jmp near @$361
@$353:
		mov dx, @$848
		mov ax, si
		call near casematch_
		test al, al
		je @$357

;                 p += 4;
;                 qualifier = 8;
		mov word [bp-0xe], 8
		jmp @$352
@$354:
		jmp near @$436
@$355:
		jmp near @$366
@$356:
		jmp near @$432

;             } else if ((dc == 'l' || dc == 'm') && p[0] == '[') {  /* Disallow e.g.: dec [bx] */
@$357:
		cmp bl, 0x6c
		je @$358
		cmp bl, 0x6d
		jne @$361
@$358:
		cmp byte [si], 0x5b
		jne @$361

;                 /* Example: case for `cmp [bp], word 1'. */
;                 if (pattern_and_encode[0] == ',' && ((dw = pattern_and_encode[1]) == 's' || dw == 't' || dw == 'u') &&
		mov di, word [bp-0xc]
		cmp byte [di], 0x2c
		jne @$356
		mov al, byte [di+1]
		mov byte [bp-2], al
		cmp al, 0x73
		je @$359
		cmp al, 0x74
		je @$359
		cmp al, 0x75
		jne @$356
@$359:
		xor dx, dx
		mov ax, si
		call near match_addressing_
		mov di, ax
		test ax, ax
		je @$356
		cmp byte [di], 0x2c
		jne @$356

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
		jne @$360
		mov dx, @$848
		call near casematch_
		test al, al
		jne @$361
@$360:
		cmp bl, 0x6d
		jne @$356
		mov dx, @$849
		mov ax, cx
		call near casematch_
		test al, al
		je @$356

;                 } else {
;                     goto mismatch;
;                 }
;             }
;             if (dc == 'j' || dc == 'l') {
@$361:
		cmp bl, 0x6a
		je @$362
		cmp bl, 0x6c
		jne @$364

;                 /* NASM allows with a warning, but we don't for dc == 'l': dec word bh */
;                 if (qualifier == 16) goto mismatch;
@$362:
		cmp word [bp-0xe], 0x10
		je @$356

;                 /* It sets instruction_addressing, instruction_offset, instruction_offset_width. */
;                 p = match_addressing(p, 8);
		mov dx, 8
@$363:
		mov ax, si
		call near match_addressing_
		jmp near @$430

;             } else /* if (dc == 'k' || dc == 'm') */ {
;                 /* NASM allows with a warning, but we don't for dc == 'm': dec byte bx */
;                 if (qualifier == 8) goto mismatch;
@$364:
		cmp word [bp-0xe], 8
		je @$374

;               do_addressing_16:
;                 /* It sets instruction_addressing, instruction_offset, instruction_offset_width. */
;                 p = match_addressing(p, 16);
@$365:
		mov dx, 0x10
		jmp @$363

;             }
;         } else if (dc == 'q') {  /* Register, 8-bit. */
@$366:
		cmp bl, 0x71
		jne @$369

;             /* NASM allows with a warning, but we don't for dc == 'l': dec word bh */
;             if (casematch(p, "BYTE!")) p += 4;
		mov dx, @$848
		mov ax, si
		call near casematch_
		test al, al
		je @$367
		add si, 4

;             p = match_register(p, 0, &instruction_register);  /* 0: anything without the 16 bit set. */
@$367:
		mov bx, _instruction_register
		xor dx, dx
@$368:
		mov ax, si
		call near match_register_
		jmp near @$430

;         } else if (dc == 'r') {  /* Register, 16-bit. */
@$369:
		cmp bl, 0x72
		jne @$371

;             /* NASM allows with a warning, but we don't for dc == 'm': dec byte bx */
;             if (casematch(p, "WORD!")) p += 4;
		mov dx, @$849
		mov ax, si
		call near casematch_
		test al, al
		je @$370
		add si, 4

;             p = match_register(p, 16, &instruction_register);
@$370:
		mov bx, _instruction_register
		mov dx, 0x10
		jmp @$368

;         } else if (dc == 'h') {  /* 8-bit immediate. */
@$371:
		cmp bl, 0x68
		jne @$375

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "BYTE!")) p += 4;
		mov dx, @$848
@$372:
		call near casematch_
		test al, al
		je @$373
		add si, 4

;             p = match_expression(p);
@$373:
		mov ax, si
		call near match_expression_
		jmp near @$430
@$374:
		jmp near @$432

;         } else if (dc == 'i') {  /* 16-bit immediate. */
@$375:
		cmp bl, 0x69
		jne @$376

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "WORD!")) p += 4;
		mov dx, @$849
		jmp @$372

;             p = match_expression(p);
;         } else if (dc == 'g') {  /* 16-bit immediate, but don't match if immediate is signed 8-bit. Useful for -O1 and above. Typically used in arithmetic pattern "AX,g". */
@$376:
		cmp bl, 0x67
		jne @$380

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             qualifier = 0;
		mov word [bp-0xe], 0

;             if (casematch(p, "WORD!")) {
		mov dx, @$849
		call near casematch_
		test al, al
		je @$377

;                 p += 4;
;                 qualifier = 1;
		mov word [bp-0xe], 1

		add si, 4

;             }
;             p = match_expression(p);
@$377:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p != NULL && (qualifier == 0 || !was_strict) && opt_level > 1 && !(((unsigned)instruction_value + 0x80) & 0xff00U)) goto mismatch;  /* The next pattern (of the same byte size) will match. For NASM compatibility. */
		test ax, ax
		je @$379
		cmp word [bp-0xe], 0
		je @$378
		cmp byte [_was_strict], 0
		jne @$379
@$378:
		cmp byte [_opt_level], 1
		jbe @$379
		mov ax, word [_instruction_value]
		add ax, 0x80
		test ah, 0xff
		je @$374
@$379:
		jmp near @$431

;         } else if (dc == 'a' || dc == 'c') {  /* Address for jump, 8-bit. 'c' is jmp, 'a' is everything else (e.g. jc, jcxz, loop) for which short is the only allowed qualifier. */
@$380:
		cmp bl, 0x61
		je @$381
		cmp bl, 0x63
		je @$381
		jmp near @$387

;             p = avoid_strict(p);  /* STRICT doesn't matter for jumps, qualifiers are respected without it. */
@$381:
		mov ax, si
		call near avoid_strict_
		mov cx, ax
		mov si, ax

;             qualifier = 0;
		mov word [bp-0xe], 0

;             if (casematch(p, "NEAR!") || casematch(p, "WORD!")) goto mismatch;
		mov dx, @$846
		call near casematch_
		test al, al
		jne @$383
		mov dx, @$849
		mov ax, cx
		call near casematch_
		test al, al
		jne @$383

;             if (casematch(p, "SHORT!")) {
		mov dx, @$845
		mov ax, cx
		call near casematch_
		test al, al
		je @$382

;                 p += 5;
;                 qualifier = 1;
		mov word [bp-0xe], 1

		add si, 5

;             }
;             p = match_expression(p);
@$382:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p != NULL) {
		test ax, ax
		je @$379

;                 if (qualifier == 0 && opt_level <= 1 && dc == 'c') {  /* With -O0, `jmp' is `jmp short' iff it fits to 8-bit signed in assembler_pass == 1. This is similar to NASM. */
		cmp word [bp-0xe], 0
		jne @$385
		cmp byte [_opt_level], 1
		ja @$385
		cmp bl, 0x63
		jne @$385

;                     if (assembler_pass == 1) {
		cmp word [_assembler_pass], 1
		jne @$384

;                         if (has_undefined) {
		cmp byte [_has_undefined], 0
		je @$385

;                             do_add_wide_imm8 = 1;
		mov byte [bp-6], 1

;                             goto mismatch;
@$383:
		jmp near @$432

;                         }
;                     } else {
;                         if (is_wide_instr_in_pass_2(1)) goto mismatch;
@$384:
		mov ax, 1
		call near is_wide_instr_in_pass_2_
		test al, al
		jne @$383

;                     }
;                 }
;                 if (has_undefined) instruction_value = current_address;  /* Hide the extra "short jump too long" error. */
@$385:
		cmp byte [_has_undefined], 0
		je @$386
		mov dx, word [_current_address]
		mov ax, word [_current_address+2]
		mov word [_instruction_value], dx
		mov word [_instruction_value+2], ax

;                 instruction_value -= current_address + 2;
@$386:
		mov ax, word [_current_address]
		add ax, 2
		mov dx, word [_current_address+2]
		adc dx, 0
		sub word [_instruction_value], ax
		sbb word [_instruction_value+2], dx

;                 if (qualifier == 0 && dc == 'c') {
		cmp word [bp-0xe], 0
		jne @$390
		cmp bl, 0x63
		jne @$390

;                     is_address_used = 1;
		mov byte [_is_address_used], 1

;                     /* Jump is longer than 8-bit signed relative jump. Do a mismatch here, so that the next pattern will generate a near jump. */
;                     if (((uvalue_t)instruction_value + 0x80) & ~0xffU) goto mismatch;
		mov ax, word [_instruction_value]
		add ax, 0x80
		test ah, 0xff
		jne @$383
		jmp @$390

;                 }
;             }
;         } else if (dc == 'b') {  /* Address for jump, 16-bit. */
@$387:
		cmp bl, 0x62
		jne @$391

;             p = avoid_strict(p);  /* STRICT doesn't matter for jumps, qualifiers are respected without it. */
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "SHORT!")) goto mismatch;
		mov dx, @$845
		call near casematch_
		test al, al
		jne @$383

;             if (casematch(p, "NEAR!") || casematch(p, "WORD!")) p += 4;
		mov dx, @$846
		mov ax, si
		call near casematch_
		test al, al
		jne @$388
		mov dx, @$849
		mov ax, si
		call near casematch_
		test al, al
		je @$389
@$388:
		add si, 4

;             p = match_expression(p);
@$389:
		mov ax, si
		call near match_expression_
		mov si, ax

;             instruction_value -= current_address + 3;
		mov dx, word [_current_address]
		add dx, 3
		mov ax, word [_current_address+2]
		adc ax, 0
		sub word [_instruction_value], dx
		sbb word [_instruction_value+2], ax

;         } else if (dc == 's') {  /* Signed immediate, 8-bit. Used in the pattern "m,s", m is a 16-bit register or 16-bit effective address.  */
@$390:
		jmp near @$431
@$391:
		cmp bl, 0x73
		jne @$397

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             qualifier = 0;
		mov word [bp-0xe], 0

;             if (casematch(p, "BYTE!")) {
		mov dx, @$848
		call near casematch_
		test al, al
		je @$392

;                 p += 4;
;                 qualifier = 1;
		mov word [bp-0xe], 1

;             } else if (casematch(p, "WORD!")) {
		jmp @$393
@$392:
		mov dx, @$849
		mov ax, si
		call near casematch_
		test al, al
		je @$394

;                 p += 4;
;                 qualifier = 2;
		mov word [bp-0xe], 2

@$393:
		add si, 4

;             }
;             p = match_expression(p);
@$394:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p == NULL) {
		test ax, ax
		je @$390

;             } else if (qualifier != 0) {
		cmp word [bp-0xe], 0
		je @$398

;                 if (opt_level > 1 && !was_strict && qualifier != 1) goto detect_si8_size;  /* For -O9, ignore `word', but respect `strict word'. */
		cmp byte [_opt_level], 1
		jbe @$395
		cmp byte [_was_strict], 0
		jne @$395
		cmp word [bp-0xe], 1
		jne @$403

;                 if (qualifier == 1) is_imm_8bit = 1;
@$395:
		cmp word [bp-0xe], 1
		jne @$396
		mov byte [bp-4], 1
@$396:
		jmp near @$415
@$397:
		jmp near @$412

;                 if (opt_level == 0) goto do_nasm_o0_immediate_compat;
;             } else if (opt_level == 0) {
@$398:
		mov al, byte [_opt_level]
		test al, al
		jne @$406

;                 /* Don't optimize this with -O0 (because NASM doesn't do it either). */
;               do_nasm_o0_immediate_compat:  /* If there are undefined labels in the immediate, then don't optimize the effective address. */  /* !! What about the other way aroud? */
;                 if ((unsigned char)instruction_addressing < 0xc0) {  /* Effective address (not register). */
@$399:
		cmp byte [_instruction_addressing], 0xc0
		jae @$405

;                     if (assembler_pass == 1) {
		cmp word [_assembler_pass], 1
		jne @$400

;                         if (has_undefined) {
		cmp byte [_has_undefined], 0
		je @$401

;                             do_add_wide_imm8 = 1;
		mov byte [bp-6], 1

;                         }
		jmp @$401

;                     } else {
;                         if (is_wide_instr_in_pass_2(1)) has_undefined = 1;
@$400:
		mov ax, 1
		call near is_wide_instr_in_pass_2_
		test al, al
		je @$401
		mov byte [_has_undefined], 1
		jmp @$402

;                     }
;                     if (has_undefined) {  /* Missed optimization opportunity in NASM 0.98.39and 0.99.06, mininasm does the same with -O0, but mininasm optimizes it with -O1. */
@$401:
		cmp byte [_has_undefined], 0
		je @$411

;                         /* We assume that the pattern is "m,s" or "m,u". */
;                         if (instruction_offset_width == 0) {
@$402:
		mov al, byte [_instruction_offset_width]
		test al, al
		jne @$404

;                             instruction_addressing |= 0x80;
		or byte [_instruction_addressing], 0x80

;                             instruction_offset_width = 2;
		mov byte [_instruction_offset_width], 2

;                         } else if (instruction_offset_width == 1) {
		jmp @$411
@$403:
		jmp @$408
@$404:
		cmp al, 1
		jne @$411

;                             instruction_addressing ^= 0xc0;
		xor byte [_instruction_addressing], 0xc0

;                             ++instruction_offset_width;
		add byte [_instruction_offset_width], al

;                         }
@$405:
		jmp @$411

;                     }
;                 }
;             } else if (opt_level == 1) {
@$406:
		cmp al, 1
		jne @$408

;                 if (assembler_pass == 1) {
		cmp word [_assembler_pass], 1
		jne @$407

;                     if (!has_undefined) goto detect_si8_size;
		cmp byte [_has_undefined], 0
		je @$408

;                     do_add_wide_imm8 = 1;
		mov byte [bp-6], al

;                 } else {
		jmp @$411

;                     if (!is_wide_instr_in_pass_2(1)) goto detect_si8_size;
@$407:
		mov ax, 1
		call near is_wide_instr_in_pass_2_
		test al, al
		jne @$416

;                 }
;             } else {
;               detect_si8_size:
;                 /* 16-bit integer cannot be represented as signed 8-bit, so don't use this encoding. Doesn't happen for has_undefined. */
;                 is_imm_8bit = !(/* !has_undefined && */ (((unsigned)instruction_value + 0x80) & 0xff00U));
@$408:
		mov ax, word [_instruction_value]
		add ax, 0x80
		test ah, 0xff
		jne @$409
		mov al, 1
		jmp @$410
@$409:
		xor al, al
@$410:
		mov byte [bp-4], al

;             }
@$411:
		jmp @$416

;         } else if (dc == 't') {  /* 8-bit immediate, with the NASM -O0 compatibility. Used with pattern "l,t", corresponding to an 8-bit addressing. */
@$412:
		cmp bl, 0x74
		jne @$417

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "BYTE!")) p += 4;
		mov dx, @$848
@$413:
		call near casematch_
		test al, al
		je @$414
		add si, 4

;             p = match_expression(p);
@$414:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p != NULL && opt_level == 0) goto do_nasm_o0_immediate_compat;
		test ax, ax
		je @$416
@$415:
		cmp byte [_opt_level], 0
		jne @$416
		jmp near @$399
@$416:
		jmp near @$431

;         } else if (dc == 'u') {  /* 16-bit immediate, with the NASM -O0 compatibility. Used with pattern "m.u". */
@$417:
		cmp bl, 0x75
		jne @$418

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "WORD!")) p += 4;
		mov dx, @$849
		jmp @$413

;             p = match_expression(p);
;             if (p != NULL && opt_level == 0) goto do_nasm_o0_immediate_compat;
;         } else if (dc == 'v') {  /* Optionally the token BYTE. */
@$418:
		cmp bl, 0x76
		jne @$420

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov si, ax

;             if (casematch(p, "BYTE!")) p = avoid_spaces(p + 4);
		mov dx, @$848
		call near casematch_
		test al, al
		je @$416
		lea ax, [si+4]
@$419:
		call near avoid_spaces_
		jmp near @$430

;         } else if (dc == 'w') {  /* Optionally the token WORD. */
@$420:
		cmp bl, 0x77
		jne @$421

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov cx, ax
		mov si, ax

;             if (casematch(p, "WORD!")) p = avoid_spaces(p + 4);
		mov dx, @$849
		call near casematch_
		test al, al
		je @$416
		mov ax, cx
		add ax, 4
		jmp @$419

;         } else if (dc == 'f') {  /* FAR pointer. */
@$421:
		cmp bl, 0x66
		jne @$422

;             p = avoid_strict(p);
		mov ax, si
		call near avoid_strict_
		mov cx, ax

;             if (casematch(p, "SHORT!") || casematch(p, "NEAR!") || casematch(p, "WORD!")) goto mismatch;
		mov dx, @$845
		call near casematch_
		test al, al
		jne @$424
		mov dx, @$846
		mov ax, cx
		call near casematch_
		test al, al
		jne @$424
		mov dx, @$849
		mov ax, cx
		call near casematch_
		test al, al
		jne @$424

;             p = match_expression(p);
		mov ax, cx
		call near match_expression_
		mov si, ax

;             if (p == NULL)
		test ax, ax
		je @$432

;                 goto mismatch;
;             segment_value = instruction_value;
		mov ax, word [_instruction_value]
		mov word [@$970], ax

;             if (*p != ':')
		cmp byte [si], 0x3a
		jne @$432
		jmp @$429

;                 goto mismatch;
@$422:
		cmp bl, 0x21
		jne @$423

;             p = match_expression(p + 1);
;         } else if (dc == '!') {
;             if (islabel(*p)) goto mismatch;
		mov al, byte [si]
		call near islabel_
		test ax, ax
		jne @$432
		jmp near @$348

;             continue;
;         } else if (dc - 'a' + 0U <= 'z' - 'a' + 0U) {  /* Unexpected special (lowercase) character in pattern. */
@$423:
		mov dx, ax
		sub dx, 0x61
		cmp dx, 0x19
		jbe @$435

;             goto decode_internal_error;
;         } else {
;             if ((dc - 'A' + 0U <= 'Z' - 'A' + 0U ? *p & ~32 : *p) != dc) goto mismatch;  /* Case insensitive match for uppercase letters in pattern. */
		sub ax, 0x41
		cmp ax, 0x19
		ja @$425
		mov al, byte [si]
		and ax, 0xdf
		jmp @$426
@$424:
		jmp @$432
@$425:
		mov al, byte [si]
		xor ah, ah
@$426:
		mov dl, bl
		xor dh, dh
		cmp ax, dx
		jne @$432

;             p++;
		inc si

;             if (dc == ',') p = avoid_spaces(p);  /* Allow spaces in p after comma in pattern and p. */
		cmp bl, 0x2c
		je @$428
@$427:
		jmp near @$348
@$428:
		mov ax, si
		call near avoid_spaces_
		mov si, ax
		jmp @$427

@$429:
		lea ax, [si+1]
		call near match_expression_

;             continue;
;         }
@$430:
		mov si, ax

;         if (p == NULL) goto mismatch;
@$431:
		test si, si
		jne @$427

;     }
;     goto do_encode;
;   mismatch:
;     while ((dc = *pattern_and_encode++) != '\0' && dc != '-' /* ALSO */) {}
@$432:
		mov bx, word [bp-0xc]
		mov bl, byte [bx]
		inc word [bp-0xc]
		test bl, bl
		je @$433
		cmp bl, 0x2d
		jne @$432

;     if (dc == '\0') return NULL;
@$433:
		test bl, bl
		jne @$434
		xor ax, ax
		jmp near @$77

;     p = p0;
@$434:
		mov si, word [bp-0xa]

;     goto next_pattern;
		jmp near @$347
@$435:
		mov dx, word [bp-0x14]
		mov ax, @$868
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
@$436:
		cmp byte [_instruction_offset_width], 3
		jne @$437

;         add_wide_instr_in_pass_1(0);  /* Call it only once per encode. Calling it once per match would add extra values in case of mismatch. */
		xor ax, ax
		call near add_wide_instr_in_pass_1_

;     }
;     if (do_add_wide_imm8) {
@$437:
		cmp byte [bp-6], 0
		je @$438

;         add_wide_instr_in_pass_1(1);  /* Call it only once per encode. Calling it once per match would add extra values in case of mismatch. 1 so that it doesn't conflict with the wideness of instruction_offset. */
		mov ax, 1
		call near add_wide_instr_in_pass_1_

;     }
;     if (do_opt_lea_now) {
@$438:
		cmp byte [bp-8], 0
		je @$439

;         instruction_addressing_segment = 0;  /* Ignore the segment part of the effective address, it doesn't make a difference for `lea'. */
;         if (0) DEBUG2("lea ia=0x%02x iow=%d\r\n", instruction_addressing, instruction_offset_width);
;         if (instruction_addressing == 0x06 /* [immediate] */) {
		mov byte [_instruction_addressing_segment], 0

		mov al, byte [_instruction_addressing]
		cmp al, 6
		jne @$440

;             emit_byte(0xb8 | instruction_register);
		mov al, byte [_instruction_register]
		or al, 0xb8
		xor ah, ah
		call near emit_byte_

;             pattern_and_encode = "j";
		mov word [bp-0xc], @$863

; #if 1  /* Convert e.g. `lea cx, [ex]' to `mov cx, bx', of the same size. */
;         } else if (instruction_addressing == 0x04 /* [SI] */) {
@$439:
		jmp @$445
@$440:
		cmp al, 4
		jne @$441

;             c = 0xc0 | 6 << 3;
		mov word [bp-0x12], 0xf0

;             goto emit_lea_mov;
		jmp @$444

;         } else if (instruction_addressing == 0x05 /* [DI] */) {
@$441:
		cmp al, 5
		jne @$442

;             c = 0xc0 | 7 << 3;
		mov word [bp-0x12], 0xf8

;             goto emit_lea_mov;
		jmp @$444

;         } else if (instruction_addressing == 0x07 /* [BX] */) {
@$442:
		cmp al, 7
		jne @$443

;             c = 0xc0 | 3 << 3;
		mov word [bp-0x12], 0xd8

;             goto emit_lea_mov;
		jmp @$444

; #endif
;         } else if (instruction_addressing == 0x46 && instruction_offset == 0 && instruction_offset_width == 1 /* [BP] */) {
@$443:
		cmp al, 0x46
		jne @$445
		cmp word [_instruction_offset], 0
		jne @$445
		cmp byte [_instruction_offset_width], 1
		jne @$445

;             c = 0xc0 | 5 << 3;
		mov word [bp-0x12], 0xe8

;           emit_lea_mov:
;             emit_byte(0x89);
@$444:
		mov ax, 0x89
		call near emit_byte_

;             emit_byte(c | instruction_register);
		mov al, byte [_instruction_register]
		xor ah, ah
		or ax, word [bp-0x12]
		call near emit_byte_

;             goto done;
		jmp near @$488

;         }
;     }
;     if (instruction_addressing_segment) {
@$445:
		cmp byte [_instruction_addressing_segment], 0
		je @$452

;         if (do_opt_segreg) {
		cmp byte [_do_opt_segreg], 0
		je @$451

;             if ((unsigned char)instruction_addressing >= 0xc0) goto omit_segreg;  /* If there is a register (rather than effective address) in the addressing. */
		mov al, byte [_instruction_addressing]
		cmp al, 0xc0
		jae @$452

;             c = instruction_addressing;
		xor ah, ah

;             if (c == 0x06 /* [immesiate] */) {
		cmp ax, 6
		jne @$446

;                 c = 0x3e /* DS */;
		mov word [bp-0x12], 0x3e

;             } else {
		jmp @$450

;                 c &= 7;
@$446:
		and al, 7
		mov word [bp-0x12], ax

;                 c = (c == 0x02 || c == 0x03 || c == 0x06) ? 0x36 /* SS */ : 0x3e /* DS */;  /* If it contains BP, then it's [SS:...] by default, otherwise [DS:...]. */
		cmp ax, 2
		je @$447
		cmp ax, 3
		je @$447
		cmp ax, 6
		jne @$448
@$447:
		mov ax, 0x36
		jmp @$449
@$448:
		mov ax, 0x3e
@$449:
		mov word [bp-0x12], ax

;             }
;             if ((unsigned char)instruction_addressing_segment == (unsigned char)c) goto omit_segreg;  /* If the default segment register is used. */
@$450:
		mov al, byte [_instruction_addressing_segment]
		cmp al, byte [bp-0x12]
		je @$452

;         }
;         emit_byte(instruction_addressing_segment);
@$451:
		mov al, byte [_instruction_addressing_segment]
		xor ah, ah
		call near emit_byte_

;       omit_segreg: ;
;     }
;     for (error_base = pattern_and_encode; (dc = *pattern_and_encode++) != '\0' && dc != '-' /* ALSO */;) {
@$452:
		mov bx, word [bp-0xc]
		mov word [bp-0x14], bx
@$453:
		mov bx, word [bp-0xc]
		mov bl, byte [bx]
		inc word [bp-0xc]
		test bl, bl
		je @$454
		cmp bl, 0x2d
		je @$454

;         dw = 0;
		xor al, al
		mov byte [bp-2], al

;         if (dc == '+') {  /* Instruction is a prefix. */
		cmp bl, 0x2b
		jne @$455

;             return p;  /* Don't call check_end(p). */
		mov ax, si
		jmp near @$77
@$454:
		jmp near @$488

;         } else if ((unsigned char)dc <= 'F' + 0U) {  /* Byte: uppercase hex. */
@$455:
		cmp bl, 0x46
		ja @$458

;             c = dc - '0';
		xor bh, bh
		sub bx, 0x30
		mov word [bp-0x12], bx

;             if (c > 9) c -= 7;
		cmp bx, 9
		jle @$456
		sub word [bp-0x12], 7

;             dc = *pattern_and_encode++ - '0';
@$456:
		mov di, word [bp-0xc]
		inc word [bp-0xc]
		mov bl, byte [di]
		sub bl, 0x30

;             if (dc > 9) dc -= 7;
		cmp bl, 9
		jbe @$457
		sub bl, 7

;             c = (c << 4) | dc;
@$457:
		mov cl, 4
		mov ax, word [bp-0x12]
		shl ax, cl
		xor bh, bh
		or ax, bx
		mov word [bp-0x12], ax

;             if ((unsigned char)(c - 0x88) <= (unsigned char)(0x8b - 0x88) && pattern_and_encode == error_base + 2 && instruction_addressing == 6 && instruction_register == 0) {
		mov al, byte [bp-0x12]
		sub al, 0x88
		cmp al, 3
		ja @$459
		mov ax, word [bp-0x14]
		inc ax
		inc ax
		cmp ax, word [bp-0xc]
		jne @$459
		cmp byte [_instruction_addressing], 6
		jne @$459
		cmp byte [_instruction_register], 0
		jne @$459

;                 /* Optimization:
;                  *
;                  * 88063412  mov [0x1234],al  "k,r 89drd"  --> A23412
;                  * 89063412  mov [0x1234],ax  "k,r 89drd"  --> A33412
;                  * 8A063412  mov al,[0x1234]  "q,j 8Adrd"  --> A03412
;                  * 8B063412  mov ax,[0x1234]  "r,k 8Bdrd"  --> A13412
;                  */
;                 pattern_and_encode = "";
		mov word [bp-0xc], @$864

;                 dw = 2;
		mov al, 2
		mov byte [bp-2], al

;                 c += 0xa0 - 0x88;
		add word [bp-0x12], 0x18

;                 c ^= 2;
		xor byte [bp-0x12], al

;             } else if ((unsigned char)(c - 0x70) <= 0xfU && qualifier == 0 && (((uvalue_t)instruction_value + 0x80) & ~0xffU) && !has_undefined
		jmp near @$485
@$458:
		jmp @$460
@$459:
		mov al, byte [bp-0x12]
		sub al, 0x70
		cmp al, 0xf
		ja @$463
		cmp word [bp-0xe], 0
		jne @$467
		mov ax, word [_instruction_value]
		add ax, 0x80
		test ah, 0xff
		je @$467
		cmp byte [_has_undefined], 0
		jne @$467

;                       ) {  /* Generate 5-byte `near' version of 8-bit relative conditional jump with an inverse. */
;                 emit_byte(c ^ 1);  /* Conditional jump with negated condition. */
		mov ax, word [bp-0x12]
		xor al, 1
		call near emit_byte_

;                 emit_byte(3);  /* Skip next 3 bytes if negated condition is true. */
		mov ax, 3
		call near emit_byte_

;                 c = 0xe9;  /* `jmp near', 2 bytes will follow for encode "b". */
		mov word [bp-0x12], 0xe9

;                 pattern_and_encode = "b";
		mov word [bp-0xc], @$865

;                 instruction_value -= 3;  /* Jump source address (0xe9) is 3 bytes larger than previously anticipated. */
		add word [_instruction_value], 0xfffd
		adc word [_instruction_value+2], 0xffff

;             }
		jmp @$467

;         } else if (dc == 'i') {  /* 8-bit immediate. */
@$460:
		cmp bl, 0x69
		jne @$464

;             c = instruction_value;
@$461:
		mov ax, word [_instruction_value]
@$462:
		mov word [bp-0x12], ax

;         } else if (dc == 'j') {  /* 16-bit immediate, maybe optimized to 8 bits. */
@$463:
		jmp @$467
@$464:
		cmp bl, 0x6a
		jne @$468

;             c = instruction_value;
		mov ax, word [_instruction_value]
		mov word [bp-0x12], ax

;             if (!is_imm_8bit) {
		cmp byte [bp-4], 0
		jne @$467

;                 instruction_offset = instruction_value >> 8;
		mov dx, word [_instruction_value+2]
		mov cx, 8
@$465:
		sar dx, 1
		rcr ax, 1
		loop @$465
@$466:
		mov word [_instruction_offset], ax

;                 dw = 1;  /* TODO(pts): Optimize this and below as ++dw. */
		mov byte [bp-2], 1

;             }
@$467:
		jmp near @$485

;         } else if (dc == 's') {
@$468:
		cmp bl, 0x73
		jne @$471

;             c = is_imm_8bit ? (char)0x83 : (char)0x81;
		cmp byte [bp-4], 0
		je @$469
		mov al, 0x83
		jmp @$470
@$469:
		mov al, 0x81
@$470:
		xor ah, ah
		jmp @$462

;         } else if (dc == 'a') {  /* Address for jump, 8-bit. */
@$471:
		cmp bl, 0x61
		jne @$472

;             is_address_used = 1;
		mov byte [_is_address_used], 1

;             if (assembler_pass > 1 && (((uvalue_t)instruction_value + 0x80) & ~0xffU))
		cmp word [_assembler_pass], 1
		jbe @$461
		mov ax, word [_instruction_value]
		add ax, 0x80
		test ah, 0xff
		je @$461

;                 MESSAGE(1, "short jump too long");
		mov ax, @$866
		call near message_
		jmp @$461

;             c = instruction_value;
;         } else if (dc == 'b') {  /* Address for jump, 16-bit. */
@$472:
		cmp bl, 0x62
		jne @$474

;             is_address_used = 1;
		mov byte [_is_address_used], 1

;             /*if (assembler_pass > 1 && (((uvalue_t)instruction_value + 0x8000U) & ~0xffffU)) {}*/  /* This check is too strict, e.g. from offset 3 it's possible to jump to 0xffff, but this one reports an error, because of the >= 32 KiB difference. */
;             if (assembler_pass > 1 && (((uvalue_t)instruction_value + (uvalue_t)0x10000UL) & (uvalue_t)~0x1ffffUL)) {  /* This check is a bit lenient. */
		cmp word [_assembler_pass], 1
		jbe @$473
		mov ax, word [_instruction_value]
		add ax, 0
		mov ax, word [_instruction_value+2]
		adc ax, 1
		test ax, 0xfffe
		je @$473

;                 MESSAGE(1, "near jump too long");
		mov ax, @$867
		call near message_

;             }
;             c = instruction_value;
@$473:
		mov ax, word [_instruction_value]
		mov word [bp-0x12], ax

;             instruction_offset = c >> 8;
		mov al, byte [bp-0x11]
		cbw
		jmp @$466

;             dw = 1;
;         } else if (dc == 'f') {  /* Far (16+16 bit) jump or call. */
@$474:
		cmp bl, 0x66
		jne @$476

;             emit_byte(instruction_value);
		mov ax, word [_instruction_value]
		call near emit_byte_

;             c = instruction_value >> 8;
		mov ax, word [_instruction_value]
		mov dx, word [_instruction_value+2]
		mov cx, 8
@$475:
		sar dx, 1
		rcr ax, 1
		loop @$475
		mov word [bp-0x12], ax

;             instruction_offset = segment_value;
		mov ax, word [@$970]
		mov word [_instruction_offset], ax

;             dw = 2;
		mov byte [bp-2], 2

;         } else {  /* Binary. */
		jmp near @$485

;             c = 0;
@$476:
		xor ah, ah
		mov word [bp-0x12], ax

;             --pattern_and_encode;
;             for (bit = 0; bit < 8;) {
		mov word [bp-0x10], ax

		dec word [bp-0xc]
		jmp @$481

;                 dc = *pattern_and_encode++;
;                 if (dc == 'z') {  /* Zero. */
;                     bit++;
;                 } else if (dc == 'o') {  /* One. */
;                     c |= 0x80 >> bit;
;                     bit++;
;                 } else if (dc == 'r') {  /* Register field. */
@$477:
		mov ax, word [bp-0x10]
		add ax, 3
		cmp bl, 0x72
		jne @$478

;                     c |= instruction_register << (5 - bit);
		mov cx, 5
		sub cx, word [bp-0x10]
		mov dl, byte [_instruction_register]
		xor dh, dh
		shl dx, cl
		jmp @$482

;                     bit += 3;
;                 } else if (dc == 'd') {  /* Addressing field. */
@$478:
		cmp bl, 0x64
		je @$479
		jmp near @$435

;                     if (bit == 0) {
@$479:
		cmp word [bp-0x10], 0
		jne @$484

;                         c |= instruction_addressing & 0xc0;
		mov al, byte [_instruction_addressing]
		and al, 0xc0
		xor ah, ah
		or word [bp-0x12], ax

;                         bit += 2;
		add word [bp-0x10], 2

;                     } else {
@$480:
		cmp word [bp-0x10], 8
		jge @$485
@$481:
		mov bx, word [bp-0xc]
		mov bl, byte [bx]
		inc word [bp-0xc]
		mov ax, word [bp-0x10]
		inc ax
		cmp bl, 0x7a
		je @$483
		cmp bl, 0x6f
		jne @$477
		mov cl, byte [bp-0x10]
		mov dx, 0x80
		sar dx, cl
@$482:
		or word [bp-0x12], dx
@$483:
		mov word [bp-0x10], ax
		jmp @$480

;                         c |= instruction_addressing & 0x07;
@$484:
		mov dl, byte [_instruction_addressing]
		and dl, 7
		xor dh, dh
		or word [bp-0x12], dx

;                         bit += 3;
;                         dw = instruction_offset_width;  /* 1, 2 or 3. 3 means 2 for dw. */
		mov dl, byte [_instruction_offset_width]
		mov byte [bp-2], dl
		jmp @$483

;                     }
;                 } else { decode_internal_error:  /* assert(...). */
;                     MESSAGE1STR(1, "ooops: decode (%s)", error_base);
;                     exit(2);
;                     break;
;                 }
;             }
;         }
;         emit_byte(c);
@$485:
		mov ax, word [bp-0x12]
		call near emit_byte_

;         if (dw != 0) {
		cmp byte [bp-2], 0
		jne @$487
@$486:
		jmp near @$453

;             emit_byte(instruction_offset);
@$487:
		mov ax, word [_instruction_offset]
		call near emit_byte_

;             if (dw > 1) emit_byte(instruction_offset >> 8);
		cmp byte [bp-2], 1
		jbe @$486
		mov al, byte [_instruction_offset+1]
		xor ah, ah
		call near emit_byte_
		jmp @$486

;         }
;     }
;   done:
;     return check_end(p);
@$488:
		mov ax, si
		call near check_end_

; }
		jmp near @$77

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
@$489:
		cmp byte [bx], 0x20
		jne @$490
		inc bx
		jmp @$489

;     p2 = instr_name;
@$490:
		mov si, _instr_name

;     for (;;) {
;         if (p2 == instr_name_end) {
@$491:
		cmp si, dx
		jne @$493

;             for (; *p && *p != ' '; ++p) {}  /* Silently truncate instr_name. */
@$492:
		mov al, byte [bx]
		test al, al
		je @$494
		cmp al, 0x20
		je @$494
		inc bx
		jmp @$492

;             break;
;         } else if (*p && *p != ' ') {
@$493:
		mov al, byte [bx]
		test al, al
		je @$494
		cmp al, 0x20
		je @$494

;             *p2++ = *p++;
		mov byte [si], al
		inc bx
		inc si

;         } else {
;             break;
;         }
;     }
		jmp @$491

;     *p2 = '\0';
@$494:
		mov byte [si], 0

;     for (; *p == ' '; ++p) {}
@$495:
		cmp byte [bx], 0x20
		je @$496
		jmp near @$116
@$496:
		inc bx
		jmp @$495

;     return p;
; }
;
; static char message_buf[512];
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
		jne @$498
@$497:
		jmp near @$89

;         if (message_bbb.data) (void)!write(2 /* stderr */, message_buf, size);
@$498:
		cmp word [_message_bbb+6], 0
		je @$499
		mov bx, cx
		mov dx, _message_buf
		mov ax, 2
		call near write_

;         message_bbb.p = message_buf;
@$499:
		mov word [_message_bbb+4], _message_buf

;         if (listing_fd >= 0) {
		mov ax, word [_listing_fd]
		test ax, ax
		jl @$497

;             if (write(listing_fd, message_buf, size) != size) {
		mov bx, cx
		mov dx, _message_buf
		call near write_
		cmp ax, cx
		je @$497

;                 listing_fd = -1;
		mov word [_listing_fd], 0xffff

;                 MESSAGE(1, "error writing to listing file");
		mov ax, @$869
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
		jne @$500

;         message_flush(NULL);  /* Flush listing_fd. */
		call near message_flush_

;         message_bbb.data = (void*)1;
		mov word [_message_bbb+6], 1

;     }
; #if CONFIG_SUPPORT_WARNINGS
;     if (error) {
; #endif
;         msg_prefix = "error: ";
@$500:
		mov dx, @$870

;         if (GET_UVALUE(++errors) == 0) --errors;  /* Cappped at max uvalue_t. */
		add word [_errors], 1
		adc word [_errors+2], 0
		mov ax, word [_errors+2]
		or ax, word [_errors]
		jne @$501
		add word [_errors], 0xffff
		adc word [_errors+2], 0xffff

; #if CONFIG_SUPPORT_WARNINGS
;     } else {
;         msg_prefix = "warning: ";
;         if (GET_UVALUE(++warnings) == 0) --warnings;  /* Cappped at max uvalue_t. */
;     }
; #endif
;     if (line_number) {
@$501:
		mov ax, word [_line_number+2]
		or ax, word [_line_number]
		je @$502

;         bbprintf(&message_bbb, "%s:%u: %s", filename_for_message, (unsigned)line_number, msg_prefix);
		push dx
		push word [_line_number]
		push word [_filename_for_message]
		mov ax, @$871
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 0xa

;     } else {
		pop dx
		ret

;         bbprintf(&message_bbb, msg_prefix);  /* "%s" not needed, no `%' patterns in msg_prefix. */
@$502:
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
		mov ax, @$872
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
		mov dx, @$873
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
		mov dx, @$874
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$510

;         while (1) {
;             p = avoid_spaces(p);
@$503:
		mov ax, bx
		call near avoid_spaces_
		mov si, ax
		mov bx, ax

;             if (*p == '\'' || *p == '"') {    /* ASCII text, quoted. */
		mov al, byte [si]
		cmp al, 0x27
		je @$504
		cmp al, 0x22
		jne @$511

;                 c = *p++;
@$504:
		mov al, byte [bx]
		mov byte [bp-2], al
		inc bx

;                 for (p2 = p; *p2 != '\0' && *p2 != c; ++p2) {}
		mov si, bx
@$505:
		mov al, byte [si]
		test al, al
		je @$506
		cmp al, byte [bp-2]
		je @$506
		inc si
		jmp @$505

;                 p3 = p2;
@$506:
		mov cx, si

;                 if (*p3 == '\0') {
		cmp byte [si], 0
		jne @$507

;                     MESSAGE(1, "Missing close quote");
		mov ax, @$854
		call near message_

;                 } else {
		jmp @$509

;                     p3 = avoid_spaces(p3 + 1);
@$507:
		lea ax, [si+1]
		call near avoid_spaces_
		mov di, ax
		mov cx, ax

;                     if (*p3 != ',' && *p3 != '\0') { --p; goto db_expr; }
		mov al, byte [di]
		cmp al, 0x2c
		je @$508
		test al, al
		je @$508
		dec bx
		jmp @$511

;                     emit_bytes(p, p2 - p);
@$508:
		mov dx, si
		sub dx, bx
		mov ax, bx
		call near emit_bytes_

;                 }
;                 p = p3;
@$509:
		mov bx, cx

;             } else { db_expr:
		jmp @$514
@$510:
		jmp @$518

;                 p = match_expression(p);
@$511:
		mov ax, bx
		call near match_expression_
		mov bx, ax

;                 if (p == NULL) {
		test ax, ax
		jne @$513

;                     MESSAGE(1, "Bad expression");
@$512:
		mov ax, @$875
		call near message_

;                     break;
		jmp near @$87

;                 }
;                 emit_byte(instruction_value);
@$513:
		mov ax, word [_instruction_value]
		call near emit_byte_

;             }
;             if (*p == ',') {
@$514:
		cmp byte [bx], 0x2c
		jne @$517

;                 p++;
		lea ax, [bx+1]
		call near avoid_spaces_
		mov si, ax
		mov bx, ax

;                 p = avoid_spaces(p);
;                 if (*p == '\0') break;
		cmp byte [si], 0
		jne @$516
@$515:
		jmp near @$87
@$516:
		jmp near @$503

;             } else {
;                 check_end(p);
@$517:
		mov ax, bx
		call near check_end_

;                 break;
		jmp @$515

;             }
;         }
;         return;
;     } else if ((c = casematch(instr_name, "DW")) /* Define 16-bit word. */
@$518:
		mov dx, @$876
		mov ax, _instr_name
		call near casematch_
		mov byte [bp-2], al
		test al, al
		jne @$519
		mov dx, @$877
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$522

; #if CONFIG_VALUE_BITS == 32
;                || casematch(instr_name, "DD")  /* Define 32-bit quadword. */
;               ) {
; #endif
;         while (1) {
;             p = match_expression(p);
@$519:
		mov ax, bx
		call near match_expression_
		mov bx, ax

;             if (p == NULL) {
		test ax, ax
		je @$512

;                 MESSAGE(1, "Bad expression");
;                 break;
;             }
;             emit_byte(instruction_value);
		mov ax, word [_instruction_value]
		call near emit_byte_

;             emit_byte(instruction_value >> 8);
		mov ax, word [_instruction_value]
		mov dx, word [_instruction_value+2]
		mov cx, 8
@$520:
		sar dx, 1
		rcr ax, 1
		loop @$520
		call near emit_byte_

; #if CONFIG_VALUE_BITS == 32
;             if (!c) {
		cmp byte [bp-2], 0
		jne @$521

;                 emit_byte(instruction_value >> 16);
		mov ax, word [_instruction_value+2]
		call near emit_byte_

;                 emit_byte(instruction_value >> 24);
		mov al, byte [_instruction_value+3]
		cbw
		call near emit_byte_

;             }
; #endif
;             if (*p == ',') {
@$521:
		cmp byte [bx], 0x2c
		jne @$517

;                 p++;
		lea ax, [bx+1]
		call near avoid_spaces_
		mov si, ax
		mov bx, ax

;                 p = avoid_spaces(p);
;                 if (*p == '\0') break;
		cmp byte [si], 0
		jne @$519
		jmp @$515

;                 continue;
;             }
;             check_end(p);
;             break;
;         }
;         return;
;     }
;     while (instr_name[0]) {   /* Match against instruction set. */
@$522:
		cmp byte [_instr_name], 0
		je @$515

;         p2 = instruction_set;
		mov si, _instruction_set

;         for (;;) {
;             if (*p2 == '\0') {
@$523:
		cmp byte [si], 0
		jne @$524

;                 MESSAGE1STR(1, "Unknown instruction '%s'", instr_name);
		mov dx, _instr_name
		mov ax, @$878
		call near message1str_

;                 goto after_matches;
		jmp near @$87

;             }
;             p3 = p2;
@$524:
		mov cx, si

;             while (*p2++ != '\0') {}  /* Skip over instruction name. */
@$525:
		mov di, si
		inc si
		cmp byte [di], 0
		jne @$525

;             if (casematch(instr_name, p3)) break;  /* Match actual instruction mnemonic name (instr_name) against candidate from instruction_set (p2). */
		mov dx, cx
		mov ax, _instr_name
		call near casematch_
		test al, al
		jne @$527

;             while (*p2++ != '\0') {}  /* Skip over pattern_and_encode. */
@$526:
		mov di, si
		inc si
		cmp byte [di], 0
		jne @$526
		jmp @$523

;         }
;         p3 = p;
;         p = match(p, p2);
@$527:
		mov dx, si
		mov ax, bx
		call near match_

;         if (p == NULL) {
		test ax, ax
		jne @$528

;             MESSAGE_START(1);
		call near message_start_

;             bbprintf(&message_bbb, "Error in instruction '%s %s'", instr_name, p3);
		push bx
		mov ax, _instr_name
		push ax
		mov ax, @$879
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
@$528:
		call near separate_
		mov bx, ax

;     }
		jmp @$522

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
;  ** Creates label named `global_label' with value `instruction_value'.
;  */
; static void create_label(void) {
create_label_:
		push bx
		push cx
		push dx
		push si

;     struct label MY_FAR *last_label = find_label(global_label);
		mov ax, _global_label
		mov dx, ds
		call near find_label_
		mov si, ax
		mov cx, dx
		mov bx, ax

;     if (assembler_pass == 1) {
		cmp word [_assembler_pass], 1
		jne @$533

;         if (last_label == NULL) {
		test dx, dx
		jne @$529
		test ax, ax
		jne @$529

;             last_label = define_label(global_label, instruction_value);
		mov bx, word [_instruction_value]
		mov cx, word [_instruction_value+2]
		mov ax, _global_label
		call near define_label_

;         } else if (RBL_IS_DELETED(last_label)) {  /* This is possible if it is an %UNDEF-ined macro. */
		jmp near @$88
@$529:
		mov es, dx
		test byte [es:si+4], 0x10
		je @$531

;           do_undelete:
;             RBL_SET_DELETED_0(last_label);
@$530:
		mov es, dx
		and byte [es:bx+4], 0xef

;             last_label->value = instruction_value;
		mov ax, word [_instruction_value]
		mov cx, word [_instruction_value+2]

;         } else {
		jmp @$537

;             MESSAGE1STR(1, "Redefined label '%s'", global_label);
@$531:
		mov dx, _global_label
		mov ax, @$880
@$532:
		call near message1str_

;         }
		jmp near @$88

;     } else {
;         if (last_label == NULL) {
@$533:
		test dx, dx
		jne @$534
		test ax, ax
		jne @$534

;             MESSAGE1STR(1, "oops: label '%s' not found", global_label);
		mov dx, _global_label
		mov ax, @$881
		jmp @$532

;         } else if (RBL_IS_DELETED(last_label)) {  /* This is possible if it is an %undef-ined macro. */
@$534:
		mov es, dx
		test byte [es:si+4], 0x10
		jne @$530

;             goto do_undelete;
;         } else {
;             if (last_label->value != instruction_value) {
		mov ax, word [es:si+5]
		mov cx, word [es:si+7]
		cmp cx, word [_instruction_value+2]
		jne @$535
		cmp ax, word [_instruction_value]
		je @$536

; #if DEBUG
;                 /* if (0 && DEBUG && opt_level <= 1) { MESSAGE_START(1); bbprintf(&message_bbb, "oops: label '%s' changed value from 0x%x to 0x%x", last_label->name, (unsigned)last_label->value, (unsigned)instruction_value); message_end(); } */
;                 if (opt_level <= 1) DEBUG3("oops: label '%s' changed value from 0x%x to 0x%x\r\n", last_label->name, (unsigned)last_label->value, (unsigned)instruction_value);
; #endif
;                 have_labels_changed = 1;
@$535:
		mov byte [_have_labels_changed], 1

;             }
;             last_label->value = instruction_value;
@$536:
		mov ax, word [_instruction_value]
		mov cx, word [_instruction_value+2]
		mov es, dx
@$537:
		mov word [es:bx+5], ax
		mov word [es:bx+7], cx

;         }
;     }
		jmp near @$88

; }
;
; static char line_buf[512];
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
; static char assembly_stack[512];
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
		jb @$538
		xor ax, ax
		jmp @$539

;     /* TODO(pts): In dosmc, can we generate better assembly code for this initialization? The `mov bx, [assembly_p]' instruction is repeated too much. */
;     assembly_p->level = 1;
@$538:
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
@$539:
		pop di
		jmp near @$89

;
; static struct assembly_info *assembly_pop(struct assembly_info *aip) {
assembly_pop_:
		push bx

;     char *p;
;     if (aip == (struct assembly_info*)assembly_stack) return NULL;
		cmp ax, _assembly_stack
		jne @$540
		xor ax, ax
		pop bx
		ret

;     assembly_p = aip;
@$540:
		mov word [_assembly_p], ax

;     p = (char*)aip;
;     if (*--p != '\0') {
		mov bx, ax
		dec bx
		cmp byte [bx], 0
		jne @$542

; #if DEBUG
;         MESSAGE(1, "oops: pop from empty %include stack\n");
; #endif
;     } else {
; #if CONFIG_CPU_UNALIGN
;         --p;
@$541:
		dec bx

; #else
;         for (; *p == '\0'; --p) {}
; #endif
;         for (; *p != '\0'; --p) {}  /* Find ->zero with value '\0', preceding ->input_filename. */
		cmp byte [bx], 0
		jne @$541

;         aip = (struct assembly_info*)(p - (int)(size_t)&((struct assembly_info*)0)->zero);
		lea ax, [bx-0x10]

;     }
;     return aip;
; }
@$542:
		pop bx
		ret

;
; #define MACRO_CMDLINE 1  /* Macro defined in the command-line with an INTVALUE. */
; #define MACRO_SELF 2  /* Macro defined in the assembly source as `%DEFINE NAME NAME', so itself. */
; #define MACRO_VALUE 3  /* Macro defined in the assembly source as `%DEFINE NAME INTVALUE' or `%assign NAME EXPR'. */
;
; static char has_macros;
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
;     if (!has_macros) return;
		cmp byte [_has_macros], 0
		jne @$544
@$543:
		jmp near @$87

;     /* Morris inorder traversal of binary tree: iterative (non-recursive,
;      * so it uses O(1) stack), modifies the tree pointers temporarily, but
;      * then restores them, runs in O(n) time.
;      */
;     while (!RBL_IS_NULL(node)) {
@$544:
		mov ax, word [bp-2]
		test ax, ax
		je @$543

;         if (RBL_IS_LEFT_NULL(node)) goto do_work;
		mov es, ax
		cmp word [es:si], 0xffff
		je @$549

;         for (pre = RBL_GET_LEFT(node); pre_right = RBL_GET_RIGHT(pre), !RBL_IS_NULL(pre_right) && pre_right != node; pre = pre_right) {}
		mov ax, si
		mov dx, es
		call near RBL_GET_LEFT_
@$545:
		mov word [bp-4], ax
		mov di, dx
		mov ax, word [bp-4]
		mov dx, di
		call near RBL_GET_RIGHT_
		mov bx, dx
		test dx, dx
		je @$546
		cmp dx, word [bp-2]
		jne @$545
		cmp ax, si
		jne @$545

;         if (RBL_IS_NULL(pre_right)) {
@$546:
		test bx, bx
		jne @$548

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
@$547:
		mov si, ax
		mov word [bp-2], dx

;         } else {
		jmp @$544

;             RBL_SET_RIGHT(pre, NULL);
@$548:
		xor bx, bx
		xor cx, cx
		mov ax, word [bp-4]
		mov dx, di
		call near RBL_SET_RIGHT_

;           do_work:  /* Do for each node. */
;             if (node->name[0] == '%') {
@$549:
		mov es, word [bp-2]
		cmp byte [es:si+9], 0x25
		jne @$551

;                 value = node->value;  /* Also make it shorter (char). */
		mov al, byte [es:si+5]

;                 if (value != MACRO_CMDLINE) {
		cmp al, 1
		je @$551

;                     RBL_SET_DELETED_1(node);
		or byte [es:si+4], 0x10

;                     /* Delete the label corresponding to the macro defined with an INTVALUE. */
;                     if (value == MACRO_VALUE) {
		cmp al, 3
		jne @$551

;                         if ((value_label = find_label(node->name + 1)) != NULL) RBL_SET_DELETED_1(value_label);
		lea ax, [si+0xa]
		mov dx, es
		call near find_label_
		mov bx, ax
		test dx, dx
		jne @$550
		test ax, ax
		je @$551
@$550:
		mov es, dx
		or byte [es:bx+4], 0x10

;                     }
;                 }
;             }
;             node = RBL_GET_RIGHT(node);
@$551:
		mov ax, si
		mov dx, word [bp-2]
		call near RBL_GET_RIGHT_
		jmp @$547

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
		jne @$552
		cmp byte [bx+1], 0x5f
		jne @$553
@$552:
		lea cx, [bx+1]
		mov ax, cx
		call near match_label_prefix_
		mov si, ax
		test ax, ax
		je @$553
		cmp byte [si], 0
		je @$555

;          MESSAGE(1, "bad macro name");
@$553:
		mov ax, @$882
@$554:
		call near message_

;          return;
		jmp @$559

;     }
;     *name1 = '%';
@$555:
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
		jne @$556
		test si, si
		je @$559
@$556:
		mov es, dx
		test byte [es:si+4], 0x10
		jne @$559

;     c = label->value;  /* Make it shorter for future comparisons. */
		mov al, byte [es:si+5]

;     if (c == MACRO_CMDLINE) {
		cmp al, 1
		jne @$557

;         MESSAGE(1, "invalid macro override");
		mov ax, @$883
		jmp @$554

;         return;
;     }
;     RBL_SET_DELETED_1(label);
@$557:
		or byte [es:si+4], 0x10

;     if (c == MACRO_VALUE) {  /* Also delete the corresponding label. */
		cmp al, 3
		jne @$559

;         if ((label = find_label(name1 + 1)) != NULL) RBL_SET_DELETED_1(label);
		mov dx, ds
		mov ax, cx
		call near find_label_
		mov bx, ax
		test dx, dx
		jne @$558
		test ax, ax
		je @$559
@$558:
		mov es, dx
		or byte [es:bx+4], 0x10

;     }
; }
@$559:
		mov sp, bp
		pop bp
		jmp near @$88

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
		jne @$560
		cmp byte [si+1], 0x5f
		jne @$561
@$560:
		lea ax, [si+1]
		mov word [bp-0x14], ax
		call near match_label_prefix_
		cmp ax, word [bp-0xc]
		je @$563

;          MESSAGE(1, "bad macro name");
@$561:
		mov ax, @$882
@$562:
		call near message_

;          goto do_return;
		jmp near @$585

;     }
;     *name1 = '%';  /* Macro NAME prefixed by '%'. */
@$563:
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
		jne @$568
		mov cx, ds
		mov dx, ds
		mov bx, word [bp-0xe]
		mov ax, word [bp-0x14]
		call near strcmp_far_
		test ax, ax
		jne @$568

;         if (macro_label == NULL) {
		cmp word [bp-0xa], 0
		jne @$565
		test di, di
		jne @$565

;             define_label(name1, MACRO_SELF);
		mov bx, 2
		xor cx, cx
		mov ax, si
@$564:
		call near define_label_

;         } else if (RBL_IS_DELETED(macro_label)) {
		jmp near @$584
@$565:
		mov es, word [bp-0xa]
		mov bx, di
		test byte [es:bx+4], 0x10
		je @$566

;             RBL_SET_DELETED_0(macro_label);
		and byte [es:bx+4], 0xef

;             macro_label->value = MACRO_SELF;
		mov word [es:bx+5], 2

;         } else if ((char)macro_label->value != MACRO_SELF) {
		jmp near @$583
@$566:
		cmp byte [es:bx+5], 2
		je @$574

;           invalid_macro_override:
;             MESSAGE(1, "invalid macro override");
@$567:
		mov ax, @$883
		jmp @$562

;             goto do_return;
;         }
;         /* !! TODO(pts): Allow `%DEFINE offset' and `%DEFINE ptr' for compatibility with A72, TASM and A86. Also add corresponding command-line flags. */
;         /* !! TODO(pts): Allow effective addresses ds:[bp] and [bp][bx] for compatibility with TASM. */
;     } else if (macro_set_mode != MACRO_SET_ASSIGN && !is_define_value(value)) {
@$568:
		cmp byte [bp-4], 0x13
		je @$570
		mov ax, word [bp-0xe]
		call near is_define_value_
		test al, al
		jne @$570

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
@$569:
		mov ax, @$884
		jmp near @$562

;         goto do_return;
;     } else if ((label = find_label(name1 + 1)) != NULL && !RBL_IS_DELETED(label) && (macro_label == NULL || RBL_IS_DELETED(macro_label))) {
@$570:
		lea ax, [si+1]
		mov dx, ds
		call near find_label_
		mov bx, ax
		mov word [bp-0x12], ax
		mov word [bp-0x10], dx
		test dx, dx
		jne @$571
		test ax, ax
		je @$575
@$571:
		mov es, dx
		test byte [es:bx+4], 0x10
		jne @$575
		mov ax, word [bp-8]
		test ax, ax
		jne @$572
		test di, di
		je @$573
@$572:
		mov es, ax
		test byte [es:di+4], 0x10
		je @$575

;         MESSAGE(1, "macro name conflicts with label");
@$573:
		mov ax, @$885
		jmp near @$562
@$574:
		jmp near @$584

;         goto do_return;
;     } else {
;         *name_end = name_endc;
@$575:
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
		je @$576
		mov bx, ax
		cmp byte [bx], 0
		je @$577

;             if (macro_set_mode != MACRO_SET_ASSIGN) goto bad_macro_value;
@$576:
		cmp byte [bp-4], 0x13
		jne @$569

;             MESSAGE(1, "Bad expression");
		mov ax, @$875
		jmp near @$562

;             goto do_return;
;         } else if (has_undefined) {
@$577:
		cmp byte [_has_undefined], 0
		je @$578

;             MESSAGE(1, "Cannot use undefined labels");
		mov ax, @$886
		jmp near @$562

;             goto do_return;
;         }
;         macro_set_mode &= ~0x10;  /* Change MACRO_SET_ASSIGN to MACRO_VALUE == MACRO_SET_DEFINE. */
@$578:
		and byte [bp-4], 0xef

;         /* Now: macro_set_mode is MACRO_CMDLINE == MACRO_SET_DEFINE_CMDLINE or MACRO_VALUE == MACRO_SET_DEFINE. */
;         if (macro_label == NULL) {
		mov ax, word [bp-8]
		test ax, ax
		jne @$579
		test di, di
		jne @$579

;             define_label(name1, macro_set_mode);
		mov bl, byte [bp-4]
		xor bh, bh
		xor cx, cx
		mov ax, si
		call near define_label_

;         } else if (RBL_IS_DELETED(macro_label)) {
		jmp @$581
@$579:
		mov es, ax
		test byte [es:di+4], 0x10
		je @$580

;             RBL_SET_DELETED_0(macro_label);
		and byte [es:di+4], 0xef

;             macro_label->value = macro_set_mode;
		mov al, byte [bp-4]
		xor ah, ah
		mov word [es:di+5], ax
		mov word [es:di+7], 0

;         } else if ((char)macro_label->value != macro_set_mode) {
		jmp @$581
@$580:
		mov al, byte [es:di+5]
		cmp al, byte [bp-4]
		je @$581
		jmp near @$567

;             goto invalid_macro_override;
;         }
;         if (label == NULL) {
@$581:
		cmp word [bp-0x10], 0
		jne @$582
		cmp word [bp-0x12], 0
		jne @$582

;             define_label(name1 + 1, instruction_value);
		mov bx, word [_instruction_value]
		mov cx, word [_instruction_value+2]
		lea ax, [si+1]
		jmp near @$564

;         } else {
;             RBL_SET_DELETED_0(label);
@$582:
		les bx, [bp-0x12]
		and byte [es:bx+4], 0xef

;             label->value = instruction_value;
		mov dx, word [_instruction_value]
		mov ax, word [_instruction_value+2]
		mov word [es:bx+5], dx
@$583:
		mov word [es:bx+7], ax

;         }
;     }
;     has_macros = 1;
@$584:
		mov byte [_has_macros], 1

;   do_return:
;     *name1 = name1c;
@$585:
		mov al, byte [bp-6]
		mov byte [si], al

;     *name_end = name_endc;
		mov al, byte [bp-2]
		mov bx, word [bp-0xc]
		mov byte [bx], al
		jmp near @$71

; }
;
; #ifdef __DOSMC__
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
		sub sp, 0x2a
		push ax

;     struct assembly_info *aip;
;     const char *p3;
;     const char *p;
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
;     char is_ifndef;
;     char is_bss;
;     struct label MY_FAR *label;
;
;     have_labels_changed = 0;
		xor al, al
		mov byte [_have_labels_changed], al

;     is_bss = 0;
		mov byte [bp-4], al

;     assembly_p = (struct assembly_info*)assembly_stack;  /* Clear the stack. */
		mov word [_assembly_p], _assembly_stack

;
;   do_assembly_push:
;     line_number = 0;  /* Global variable. */
@$586:
		xor ax, ax
		mov word [_line_number], ax
		mov word [_line_number+2], ax

;     if (!(aip = assembly_push(input_filename))) {
		mov ax, word [bp-0x2c]
		call near assembly_push_
		mov di, ax
		test ax, ax
		jne @$587

;         MESSAGE(1, "assembly stack overflow, too many pending %INCLUDE files");
		mov ax, @$887
		call near message_

;         return;
		jmp near @$87

;     }
;
;   do_open_again:
;     line_number = 0;  /* Global variable. */
@$587:
		xor ax, ax
		mov word [_line_number], ax
		mov word [_line_number+2], ax

;     filename_for_message = aip->input_filename;
		lea ax, [di+0x11]
		mov word [_filename_for_message], ax

;     if ((input_fd = open2(aip->input_filename, O_RDONLY | O_BINARY)) < 0) {
		mov bx, ax
		xor dx, dx
		call near open2_
		mov word [bp-0x22], ax
		test ax, ax
		jge @$589

;         MESSAGE1STR(1, "cannot open '%s' for input", aip->input_filename);
		mov dx, bx
		mov ax, @$888
@$588:
		call near message1str_

;         return;
		jmp near @$87

;     }
;     if (0) DEBUG2("seeking to %d in file: %s\n", (int)aip->file_offset, aip->input_filename);
;     if (aip->file_offset != 0 && lseek(input_fd, aip->file_offset, SEEK_SET) != aip->file_offset) {
@$589:
		mov dx, word [di+2]
		or dx, word [di]
		je @$591
		mov bx, word [di]
		mov cx, word [di+2]
		xor dx, dx
		call near lseek_
		cmp dx, word [di+2]
		jne @$590
		cmp ax, word [di]
		je @$591

;         MESSAGE1STR(1, "cannot seek in '%s'", input_filename);
@$590:
		mov dx, word [bp-0x2c]
		mov ax, @$889
		jmp @$588

;         return;
;     }
;     level = aip->level;
@$591:
		mov ax, word [di+4]
		mov word [bp-0x24], ax
		mov ax, word [di+6]
		mov word [bp-8], ax

;     avoid_level = aip->avoid_level;
		mov ax, word [di+8]
		mov word [bp-0x10], ax
		mov ax, word [di+0xa]
		mov word [bp-0xa], ax

;     line_number = aip->line_number;
		mov ax, word [di+0xc]
		mov dx, word [di+0xe]
		mov word [_line_number], ax
		mov word [_line_number+2], dx

;
;     global_label[0] = '\0';
		mov byte [_global_label], 0

;     global_label_end = global_label;
		mov word [_global_label_end], _global_label

;     linep = line_rend = line_buf;
		mov ax, _line_buf
		mov word [bp-0xc], ax
		mov word [bp-0x16], ax

;     discarded_after_read = 0;
		mov word [bp-0x1e], 0

;     for (;;) {  /* Read and process next line from input. */
;         if (GET_UVALUE(++line_number) == 0) --line_number;  /* Cappped at max uvalue_t. */
@$592:
		add word [_line_number], 1
		adc word [_line_number+2], 0
		mov ax, word [_line_number+2]
		or ax, word [_line_number]
		jne @$593
		add word [_line_number], 0xffff
		adc word [_line_number+2], 0xffff

;         line = linep;
@$593:
		mov ax, word [bp-0x16]
		mov word [bp-0x12], ax

;        find_eol:
;         /* linep can be used as scratch from now on */
;         for (p = line; p != line_rend && *p != '\n'; ++p) {}
@$594:
		mov si, word [bp-0x12]
@$595:
		cmp si, word [bp-0xc]
		je @$596
		cmp byte [si], 0xa
		je @$596
		inc si
		jmp @$595

;         if (p == line_rend) {  /* No newline in the remaining unprocessed bytes, so read more bytes from the file. */
@$596:
		cmp si, word [bp-0xc]
		jne @$600

;             if (line != line_buf) {  /* Move the remaining unprocessed bytes (line...line_rend) to the beginning of the buffer (line_buf). */
		cmp word [bp-0x12], _line_buf
		je @$599

;                 if (line_rend - line >= MAX_SIZE) goto line_too_long;
		mov ax, si
		sub ax, word [bp-0x12]
		cmp ax, 0x100
		jge @$602

;                 /*if (line_rend - line > (int)(sizeof(line_buf) - (sizeof(line_buf) >> 2))) goto line_too_long;*/  /* Too much copy per line (thus too slow). This won't be triggered, because the `line_rend - line >= MAX_SIZE' check above triggers first. */
;                 for (liner = line_buf, p = line; p != line_rend; *liner++ = *p++) {}
		mov word [bp-6], _line_buf
		mov si, word [bp-0x12]
@$597:
		cmp si, word [bp-0xc]
		je @$598
		mov al, byte [si]
		mov bx, word [bp-6]
		mov byte [bx], al
		inc si
		inc word [bp-6]
		jmp @$597

;                 p = line_rend = liner;
@$598:
		mov bx, word [bp-6]
		mov word [bp-0xc], bx
		mov si, bx

;                 line = line_buf;
		mov word [bp-0x12], _line_buf

;             }
;           read_more:
;             discarded_after_read = 0;  /* This must be after `read_more' for correct offset calculations. */
@$599:
		mov word [bp-0x1e], 0

;             /* Now: p == line_rend. */
;             if ((got = line_buf + sizeof(line_buf) - line_rend) <= 0) goto line_too_long;
		mov bx, _line_buf+0x200
		sub bx, word [bp-0xc]
		test bx, bx
		jle @$602

;             if (0) DEBUG0("READ\r\n");
;             if ((got = read(input_fd, line_rend, got)) < 0) {
		mov dx, word [bp-0xc]
		mov ax, word [bp-0x22]
		call near read_
		test ax, ax
		jge @$601

;                 MESSAGE(1, "error reading assembly file");
		mov ax, @$890

;                 goto close_return;
		jmp near @$784
@$600:
		jmp near @$629

;             }
;             line_rend += got;
@$601:
		add word [bp-0xc], ax

;             if (got == 0) {
		test ax, ax
		jne @$603

;                 if (p == line_rend) break;  /* EOF. */
		mov ax, word [bp-0xc]
		cmp si, ax
		je @$610

;                 *line_rend++ = '\n';  /* Add sentinel. This is valid memory access in line_buf, because got > 0 in the read(...) call above. */
		mov bx, ax
		mov byte [bx], 0xa
		inc word [bp-0xc]

;             } else if (line_rend != line_buf + sizeof(line_buf)) {
		jmp @$604
@$602:
		jmp near @$632
@$603:
		cmp word [bp-0xc], _line_buf+0x200
		jne @$599

;                 goto read_more;
;             }
;             /* We may process the last partial line here again later, but that performance degradation is fine. TODO(pts): Keep some state (comment, quote) to avoid this. */
;             for (p = linep = line; p != line_rend; ) {
@$604:
		mov ax, word [bp-0x12]
		mov word [bp-0x16], ax
		mov si, ax
@$605:
		cmp si, word [bp-0xc]
		jne @$606
		jmp near @$594

;                 pc = *p;
@$606:
		mov cl, byte [si]

;                 if (pc == '\'' || pc == '"') {
		cmp cl, 0x27
		je @$607
		cmp cl, 0x22
		jne @$611

;                     ++p;
@$607:
		inc si

;                     do {
;                         if (p == line_rend) break;  /* This quote may be closed later, after a read(...). */
@$608:
		cmp si, word [bp-0xc]
		je @$605

;                         if (*p == '\n') goto newline;  /* This unclosed quote will be reported as a syntax error later. */
		mov al, byte [si]
		cmp al, 0xa
		je @$614

;                         if (*p == '\0') {
		test al, al
		jne @$609

;                             MESSAGE(1, "quoted NUL found");
		mov ax, @$891
		call near message_

;                             *(char*)p = ' ';
		mov byte [si], 0x20

;                         }
;                     } while (*p++ != pc);
@$609:
		mov bx, si
		inc si
		cmp cl, byte [bx]
		jne @$608
		jmp @$605
@$610:
		jmp near @$782

;                 } else if (pc == ';') {
@$611:
		cmp cl, 0x3b
		jne @$618

;                     for (liner = (char*)p; p != line_rend; *(char*)p++ = ' ') {
		mov word [bp-6], si
@$612:
		cmp si, word [bp-0xc]
		je @$613

;                         if (*p == '\n') goto newline;
		cmp byte [si], 0xa
		je @$619

;                     }
		mov byte [si], 0x20
		inc si
		jmp @$612

;                     /* Now: p == line_rend. We have comment which hasn't been finished in the remaining buffer. */
;                     for (; liner != line && liner[-1] != '\n' && isspace(liner[-1]); --liner) {}  /* Find start of whitespace preceding the comment. */
@$613:
		mov bx, word [bp-6]
		cmp bx, word [bp-0x12]
		je @$615
		mov al, byte [bx-1]
		cmp al, 0xa
		je @$615
		xor ah, ah
		call near isspace_
		test ax, ax
		je @$615
		dec word [bp-6]
		jmp @$613
@$614:
		jmp @$619

;                     *liner++ = ';';  /* Process this comment again later. */
@$615:
		mov bx, word [bp-6]
		mov byte [bx], 0x3b
		inc word [bp-6]

;                     discarded_after_read = line_rend - liner;  /* TODO(pts): We should check for overflow for source files >= 2 GiB. */
;                     if (0) DEBUG1("DISCARD_COMMENT %d\r\n", (int)(line_rend - liner));
;                     p = line_rend = liner;
		mov bx, word [bp-0xc]
		sub bx, word [bp-6]
		mov word [bp-0x1e], bx

		mov bx, word [bp-6]
		mov word [bp-0xc], bx
		mov si, bx

;                     if (linep == line) { /* Reached end of the read buffer before the end of the single-line comment in the upcoming line. Read more bytes of this comment. */
		mov ax, word [bp-0x16]
		cmp ax, word [bp-0x12]
		je @$617
@$616:
		jmp near @$594

;                         if (line_rend - linep >= MAX_SIZE) goto line_too_long;
@$617:
		mov ax, bx
		sub ax, word [bp-0x16]
		cmp ax, 0x100
		jge @$627
		jmp near @$599

;                         goto read_more;
;                     }
;                     goto find_eol;  /* Superfluous. */
;                 } else if (pc == '\n') {
@$618:
		cmp cl, 0xa
		jne @$620

;                   newline:
;                     linep = (char*)++p;
@$619:
		inc si
		mov word [bp-0x16], si

;                 } else if (pc == '\0' || isspace(pc)) {
		jmp near @$605
@$620:
		test cl, cl
		je @$621
		mov al, cl
		xor ah, ah
		call near isspace_
		test ax, ax
		je @$628

;                     *(char*)p++ = ' ';
@$621:
		mov byte [si], 0x20
		inc si

;                     for (liner = (char*)p; liner != line_rend && ((pc = *liner) == '\0' || (pc != '\n' && isspace(pc))); *liner++ = ' ') {}
		mov word [bp-6], si
@$622:
		mov bx, word [bp-6]
		cmp bx, word [bp-0xc]
		je @$624
		mov cl, byte [bx]
		test cl, cl
		je @$623
		cmp cl, 0xa
		je @$624
		mov al, cl
		xor ah, ah
		call near isspace_
		test ax, ax
		je @$624
@$623:
		mov bx, word [bp-6]
		mov byte [bx], 0x20
		inc word [bp-6]
		jmp @$622

;                     if (liner == line_rend) {
@$624:
		mov bx, word [bp-6]
		cmp bx, word [bp-0xc]
		je @$626
@$625:
		jmp near @$605

;                         discarded_after_read = line_rend - p;  /* TODO(pts): We should check for overflow for source files >= 2 GiB. */
;                         if (0) DEBUG1("DISCARD_WHITESPACE %d\r\n", (int)(line_rend - p));
;                         line_rend = (char*)p;  /* Compress trailing whitespace bytes at the end of the buffer to a single space, so that they won't count against the line size (MAX_SIZE) at the end of the line. */
@$626:
		sub bx, si
		mov word [bp-0x1e], bx

		mov word [bp-0xc], si

;                         goto find_eol;  /* Superfluous. */
		jmp @$616
@$627:
		jmp @$632

;                     }
;                 } else {
;                     ++p;
@$628:
		inc si

;                 }
		jmp @$625

;             }
;             goto find_eol;
;         }
;         /* Now: *p == '\n'. */
;         linep = (char*)p + 1;
@$629:
		lea ax, [si+1]
		mov word [bp-0x16], ax

;         for (; p != line && p[-1] == ' '; --p) {}  /* Removes trailing \r and spaces. */
@$630:
		cmp si, word [bp-0x12]
		je @$631
		cmp byte [si-1], 0x20
		jne @$631
		dec si
		jmp @$630

;         *(char*)p = '\0';  /* Change trailing '\n' to '\0'. */
@$631:
		mov byte [si], 0

;         if (0) DEBUG3("line @0x%x %u=(%s)\r\n", (unsigned)current_address, (unsigned)line_number, line);
		sub si, word [bp-0x12]
		cmp si, 0x100
		jl @$633

;         if (p - line >= MAX_SIZE) { line_too_long:
;             MESSAGE(1, "assembly line too long");
@$632:
		mov ax, @$892
		jmp near @$784

;             goto close_return;
;         }
;
;         line_address = current_address;
@$633:
		mov ax, word [_current_address]
		mov word [bp-0x28], ax
		mov ax, word [_current_address+2]
		mov word [bp-0x2a], ax

;         g = generated_ptr;
		mov ax, word [_generated_ptr]
		mov word [_g], ax

;         include = 0;
		mov byte [bp-2], 0

;
;         p = avoid_spaces(line);
		mov ax, word [bp-0x12]
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;         if (p[0] == '\0') {  /* Empty line. */
		mov al, byte [bx]
		test al, al
		je @$637

;             goto after_line;
;         } else if (p[0] != '%') {
		cmp al, 0x25
		je @$635

;             if (avoid_level != 0 && level >= avoid_level) {
		mov ax, word [bp-0xa]
		or ax, word [bp-0x10]
		je @$634
		mov ax, word [bp-8]
		cmp ax, word [bp-0xa]
		ja @$637
		jne @$634
		mov ax, word [bp-0x24]
		cmp ax, word [bp-0x10]
		jae @$637
@$634:
		jmp near @$690

; #if DEBUG
;                 if (0) MESSAGE1STR(1, "Avoiding '%s'", line);
; #endif
;                 goto after_line;
;             }
;             goto not_preproc;
;         }
;
;         /* Process preprocessor directive. Labels are not allowed here. */
;         p = separate(p);
@$635:
		mov ax, bx
		call near separate_
		mov si, ax

;         if (casematch(instr_name, "%IF")) {
		mov dx, @$893
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$640

;             if (GET_UVALUE(++level) == 0) { if_too_deep:
		add word [bp-0x24], 1
		adc word [bp-8], 0
		mov ax, word [bp-8]
		or ax, word [bp-0x24]
		jne @$638

;                 MESSAGE(1, "%IF too deep");
@$636:
		mov ax, @$894
		jmp near @$784
@$637:
		jmp near @$687

;                 goto close_return;
;             }
;             if (avoid_level != 0 && level >= avoid_level)
@$638:
		mov ax, word [bp-0xa]
		or ax, word [bp-0x10]
		je @$639
		mov ax, word [bp-8]
		cmp ax, word [bp-0xa]
		ja @$648
		jne @$639
		mov ax, word [bp-0x24]
		cmp ax, word [bp-0x10]
		jae @$648

;                 goto after_line;
;             /* !! TODO(pts): Add operators < > <= >=  == = != <> && || ^^ for `%IF' only. NASM doesn't do short-circuit. */
;             p = match_expression(p);
@$639:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p == NULL) {
		test ax, ax
		jne @$641

;                 MESSAGE(1, "Bad expression");
		mov ax, @$875

;             } else if (has_undefined) {
		jmp @$642
@$640:
		jmp @$649
@$641:
		cmp byte [_has_undefined], 0
		je @$643

;                 MESSAGE(1, "Cannot use undefined labels");
		mov ax, @$886
@$642:
		call near message_

;             }
;             if (instruction_value != 0) {
@$643:
		mov ax, word [_instruction_value+2]
		or ax, word [_instruction_value]
@$644:
		jne @$646

;                 ;
;             } else {
;                 avoid_level = level;
		mov ax, word [bp-0x24]
		mov word [bp-0x10], ax
		mov ax, word [bp-8]
@$645:
		mov word [bp-0xa], ax

;             }
;             check_end(p);
@$646:
		mov ax, si
@$647:
		call near check_end_

;         } else if (casematch(instr_name, "%IFDEF")) {
@$648:
		jmp near @$687
@$649:
		mov dx, @$895
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$653

;             is_ifndef = 0;
		xor ch, ch

;           ifdef_or_ifndef:
;             if (GET_UVALUE(++level) == 0) goto if_too_deep;
@$650:
		add word [bp-0x24], 1
		adc word [bp-8], 0
		mov ax, word [bp-8]
		or ax, word [bp-0x24]
		je @$636

;             if (avoid_level != 0 && level >= avoid_level)
		mov ax, word [bp-0xa]
		or ax, word [bp-0x10]
		je @$651
		mov ax, word [bp-8]
		cmp ax, word [bp-0xa]
		ja @$648
		jne @$651
		mov ax, word [bp-0x24]
		cmp ax, word [bp-0x10]
		jae @$648

;                 goto after_line;
;             if (0) DEBUG1("%%IFDEF macro=(%s)\r\n", p);
;             p3 = match_label_prefix(p);
@$651:
		mov ax, si
		call near match_label_prefix_
		mov bx, ax
		mov word [bp-0xe], ax

;             if (!p3 || *p3 != '\0' || !(isalpha(*p) || *p == '_')) {
		test ax, ax
		je @$652
		cmp byte [bx], 0
		jne @$652
		mov al, byte [si]
		xor ah, ah
		call near isalpha_
		test ax, ax
		jne @$654
		cmp byte [si], 0x5f
		je @$654

;                 MESSAGE(1, "bad macro name");
@$652:
		mov ax, @$882
		jmp near @$709
@$653:
		jmp @$659

;             } else {
;                 pc = *--p;
@$654:
		dec si
		mov cl, byte [si]

;                 *(char*)p = '%';  /* Prefix the macro name with a '%'. */
		mov byte [si], 0x25

;                 if (((label = find_label(p)) != NULL && !RBL_IS_DELETED(label)) == is_ifndef) {
		mov dx, ds
		mov ax, si
		call near find_label_
		mov bx, ax
		test dx, dx
		jne @$655
		test ax, ax
		je @$656
@$655:
		mov es, dx
		test byte [es:bx+4], 0x10
		jne @$656
		mov dx, 1
		jmp @$657
@$656:
		xor dx, dx
@$657:
		mov al, ch
		xor ah, ah
		cmp dx, ax
		jne @$658

;                     avoid_level = level;  /* Our %IFDEF or %IFNDEF is false, start hiding. */
		mov ax, word [bp-0x24]
		mov word [bp-0x10], ax
		mov ax, word [bp-8]
		mov word [bp-0xa], ax

;                 }
;                 *(char*)p = pc;  /* Restore original character for listing_fd. */
@$658:
		mov byte [si], cl

;             }
		jmp near @$687

;         } else if (casematch(instr_name, "%IFNDEF")) {
@$659:
		mov dx, @$896
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$660

;             is_ifndef = 1;
		mov ch, 1

;             goto ifdef_or_ifndef;
		jmp near @$650

;         } else if (casematch(instr_name, "%ELSE")) {
@$660:
		mov dx, @$897
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$665

;             if (level == 1) {
		cmp word [bp-8], 0
		jne @$661
		cmp word [bp-0x24], 1
		jne @$661

;                 MESSAGE(1, "%ELSE without %IF");
		mov ax, @$898
		jmp near @$784

;                 goto close_return;
;             }
;             if (avoid_level != 0 && level > avoid_level)
@$661:
		mov ax, word [bp-0xa]
		or ax, word [bp-0x10]
		je @$662
		mov ax, word [bp-8]
		cmp ax, word [bp-0xa]
		ja @$664
		jne @$662
		mov ax, word [bp-0x24]
		cmp ax, word [bp-0x10]
		ja @$664

;                 goto after_line;
;             if (avoid_level == level) {
@$662:
		mov ax, word [bp-0xa]
		cmp ax, word [bp-8]
		jne @$663
		mov ax, word [bp-0x10]
		cmp ax, word [bp-0x24]
		jne @$663

;                 avoid_level = 0;
		xor ax, ax
		mov word [bp-0x10], ax

;             } else if (avoid_level == 0) {
		jmp near @$645
@$663:
		mov ax, word [bp-0xa]
		or ax, word [bp-0x10]

;                 avoid_level = level;
;             }
		jmp near @$644
@$664:
		jmp near @$687

;             check_end(p);
;         } else if (casematch(instr_name, "%ENDIF")) {
@$665:
		mov dx, @$899
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$668

;             if (avoid_level == level)
		mov ax, word [bp-0xa]
		cmp ax, word [bp-8]
		jne @$666
		mov ax, word [bp-0x10]
		cmp ax, word [bp-0x24]
		jne @$666

;                 avoid_level = 0;
		xor ax, ax
		mov word [bp-0x10], ax
		mov word [bp-0xa], ax

;             if (--level == 0) {
@$666:
		add word [bp-0x24], 0xffff
		adc word [bp-8], 0xffff
		mov ax, word [bp-8]
		or ax, word [bp-0x24]
		je @$667
		jmp near @$646

;                 MESSAGE(1, "%ENDIF without %IF");
@$667:
		mov ax, @$900
		jmp near @$784

;                 goto close_return;
;             }
;             check_end(p);
;         } else if (casematch(instr_name, "%IF*") || casematch(instr_name, "%ELIF*")) {
@$668:
		mov dx, @$901
		mov ax, _instr_name
		call near casematch_
		test al, al
		jne @$669
		mov dx, @$902
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$670

;             /* We report this even if skipped. */
;             MESSAGE1STR(1, "Unknown preprocessor condition: %s", instr_name);
@$669:
		mov dx, _instr_name
		mov ax, @$903
		call near message1str_

;             goto close_return;  /* There is no meaningful way to continue. */
		jmp near @$785

;         } else if (avoid_level != 0 && level >= avoid_level) {
@$670:
		mov ax, word [bp-0xa]
		or ax, word [bp-0x10]
		je @$671
		mov ax, word [bp-8]
		cmp ax, word [bp-0xa]
		ja @$676
		jne @$671
		mov ax, word [bp-0x24]
		cmp ax, word [bp-0x10]
		jae @$676

;         } else if (casematch(instr_name, "%INCLUDE")) {
@$671:
		mov dx, @$904
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$677

;             pc = *p++;
		mov cl, byte [si]
		inc si

;             if (pc != '"' && pc != '\'') {
		cmp cl, 0x22
		je @$673
		cmp cl, 0x27
		je @$673

;               missing_quotes_in_include:
;                 MESSAGE(1, "Missing quotes in %INCLUDE");
@$672:
		mov ax, @$905
		jmp near @$709

;                 goto after_line;
;             }
;             for (p3 = p; *p != '\0' && *p != pc; ++p) {}
@$673:
		mov word [bp-0xe], si
@$674:
		mov al, byte [si]
		test al, al
		je @$675
		cmp cl, al
		je @$675
		inc si
		jmp @$674

;             if (*p == '\0') goto missing_quotes_in_include;
@$675:
		cmp byte [si], 0
		je @$672

;             if (!check_end(p + 1)) goto after_line;
		lea ax, [si+1]
		call near check_end_
		test ax, ax
		je @$683

;             liner = (char*)p;
		mov word [bp-6], si

;             include = 1;
		mov byte [bp-2], 1

;         } else if ((pc = casematch(instr_name, "%DEFINE")) || casematch(instr_name, "%ASSIGN")) {
@$676:
		jmp @$683
@$677:
		mov dx, @$906
		mov ax, _instr_name
		call near casematch_
		mov cl, al
		test al, al
		jne @$678
		mov dx, @$907
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$684

;             for (p3 = p; *p3 != '\0' && !isspace(*p3); ++p3) {}
@$678:
		mov word [bp-0xe], si
@$679:
		mov bx, word [bp-0xe]
		mov al, byte [bx]
		test al, al
		je @$680
		xor ah, ah
		call near isspace_
		test ax, ax
		jne @$680
		inc word [bp-0xe]
		jmp @$679

;             set_macro((char*)p - 1, (char*)p3, p3, pc ? MACRO_SET_DEFINE : MACRO_SET_ASSIGN);
@$680:
		test cl, cl
		je @$681
		mov cx, 3
		jmp @$682
@$681:
		mov cx, 0x13
@$682:
		xor ch, ch
		lea ax, [si-1]
		mov bx, word [bp-0xe]
		mov dx, bx
		call near set_macro_

;         } else if (casematch(instr_name, "%UNDEF")) {
@$683:
		jmp near @$687
@$684:
		mov dx, @$908
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$685

;             unset_macro((char*)p - 1);
		lea ax, [si-1]
		call near unset_macro_

;         } else {
		jmp @$683

;             MESSAGE1STR(1, "Unknown preprocessor directive: %s", instr_name);
@$685:
		mov dx, _instr_name
		mov ax, @$909
@$686:
		call near message1str_

;         }
@$687:
		cmp word [_assembler_pass], 1
		jbe @$689
		cmp word [_listing_fd], 0
		jl @$689
		push word [bp-0x2a]
		push word [bp-0x28]
		mov ax, @$934
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 8
		mov si, word [_generated_ptr]
@$688:
		cmp si, word [_g]
		jae @$693
		mov al, byte [si]
		xor ah, ah
		push ax
		mov ax, @$935
		push ax
		mov ax, _message_bbb
		push ax
		inc si
		call near bbprintf_
		add sp, 6
		jmp @$688
@$689:
		jmp near @$767

;         goto after_line;
;       not_preproc:
;
;         /* Parse and process label, if any. */
;         if ((p3 = match_label_prefix(p)) != NULL && (p3[0] == ':' || (p3[0] == ' ' && (p[0] == '$' || (is_colonless_instruction(avoid_spaces(p3 + 1))
@$690:
		mov ax, si
		call near match_label_prefix_
		mov bx, ax
		mov word [bp-0xe], ax
		test ax, ax
		je @$694
		mov al, byte [bx]
		cmp al, 0x3a
		je @$691
		cmp al, 0x20
		jne @$694
		cmp byte [si], 0x24
		je @$691
		lea ax, [bx+1]
		call near avoid_spaces_
		call near is_colonless_instruction_
		test ax, ax
		je @$694

;             /* && !is_colonless_instruction(p) */ ))))) {  /* !is_colonless_instruction(p) is implied by match_label_prefix(p) */
;             if (p[0] == '$') ++p;
@$691:
		cmp byte [si], 0x24
		jne @$692
		inc si

;             liner = (p[0] == '.') ? global_label_end : global_label;  /* If label starts with '.', then prepend global_label. */
@$692:
		cmp byte [si], 0x2e
		jne @$695
		mov cx, word [_global_label_end]
		jmp @$696
@$693:
		jmp near @$765
@$694:
		jmp near @$701
@$695:
		mov cx, _global_label

; #ifdef __DOSMC__  /* A few bytes smaller than memcpy(...). */
;             /* Calling memcpy_newdest_inline(...) or memcpy_void_inline(...) instead here would add 127 bytes to the program, so we are not doing it. OpenWatcom optimization is weird. */
;             memcpy_void_my(liner, p, p3 - p);
@$696:
		mov bx, word [bp-0xe]
		sub bx, si
		mov word [bp-0x26], bx
		mov dx, si
		mov ax, cx
		call near memcpy_void_my_

; #else
;             memcpy(liner, p, p3 - p);
; #endif
;             liner += p3 - p;
		mov bx, word [bp-0x26]
		add bx, cx
		mov word [bp-6], bx

;             *liner = '\0';
		mov byte [bx], 0

;             if (p[0] != '.') global_label_end = liner;
		cmp byte [si], 0x2e
		je @$697
		mov word [_global_label_end], bx

;             p = avoid_spaces(p3 + 1);
@$697:
		mov ax, word [bp-0xe]
		inc ax
		call near avoid_spaces_
		mov cx, ax
		mov si, ax

;             if (casematch(p, "EQU!")) {
		mov dx, @$843
		call near casematch_
		test al, al
		je @$700

;                 p = match_expression(p + 3);
		mov ax, cx
		add ax, 3
		call near match_expression_
		mov dx, ax

;                 if (p == NULL) {
		test ax, ax
		jne @$698

;                     MESSAGE(1, "bad expression");
		mov ax, @$910
		call near message_

;                 } else {
		jmp @$699

;                     create_label();
@$698:
		call near create_label_

;                     check_end(p);
		mov ax, dx
		call near check_end_

;                 }
;                 *global_label_end = '\0';  /* Undo the concat to global_label. */
@$699:
		mov bx, word [_global_label_end]
		mov byte [bx], 0

;                 goto after_line;
		jmp near @$687

;             }
;             instruction_value = current_address;
@$700:
		mov dx, word [_current_address]
		mov ax, word [_current_address+2]
		mov word [_instruction_value], dx
		mov word [_instruction_value+2], ax

;             create_label();
		call near create_label_

;             *global_label_end = '\0';  /* Undo the concat to global_label. */
		mov bx, word [_global_label_end]
		mov byte [bx], 0

;         }
;
;         /* Process command (non-preprocessor, non-label). */
;         if (p[0] == '\0') {
@$701:
		mov al, byte [si]
		test al, al
		jne @$703
@$702:
		jmp near @$687

;             goto after_line;
;         } else if (!isalpha(p[0])) {
@$703:
		xor ah, ah
		call near isalpha_
		test ax, ax
		jne @$704

;             MESSAGE(1, "Instruction expected");
		mov ax, @$911
		jmp @$709

;             goto after_line;
;         }
;         p = separate(p3 = p);
@$704:
		mov word [bp-0xe], si
		mov ax, si
		call near separate_
		mov bx, ax
		mov si, ax

;         if (casematch(instr_name, "USE16")) {
		mov dx, @$912
		mov ax, _instr_name
		call near casematch_
		test al, al
		jne @$702

;         } else if (casematch(instr_name, "CPU")) {
		mov dx, @$913
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$705

;             if (!casematch(p, "8086"))
		mov dx, @$914
		mov ax, bx
		call near casematch_
		test al, al
		jne @$702

;                 MESSAGE(1, "Unsupported processor requested");
		mov ax, @$915
		jmp @$709

;         } else if (casematch(instr_name, "BITS")) {
@$705:
		mov dx, @$916
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$712

;             p = match_expression(p);
		mov ax, bx
		call near match_expression_
		mov si, ax

;             if (p == NULL) {
		test ax, ax
		jne @$707

;                 MESSAGE(1, "Bad expression");
@$706:
		mov ax, @$875
		jmp @$709

;             } else if (has_undefined) {
@$707:
		cmp byte [_has_undefined], 0
		je @$710

;                 MESSAGE(1, "Cannot use undefined labels");
@$708:
		mov ax, @$886
@$709:
		call near message_
		jmp @$702

;             } else if (instruction_value != 16) {
@$710:
		cmp word [_instruction_value+2], 0
		jne @$711
		cmp word [_instruction_value], 0x10
		jne @$711
		jmp near @$647

;                 MESSAGE(1, "Unsupported BITS requested");
@$711:
		mov ax, @$917
		jmp @$709

;             } else {
;                 check_end(p);
;             }
;         } else if (casematch(instr_name, "INCBIN")) {
@$712:
		mov dx, @$918
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$716

;             pc = *p++;
		mov cl, byte [bx]
		lea si, [bx+1]

;             if (pc != '"' && pc != '\'') {
		cmp cl, 0x22
		je @$714
		cmp cl, 0x27
		je @$714

;               missing_quotes_in_incbin:
;                 MESSAGE(1, "Missing quotes in INCBIN");
@$713:
		mov ax, @$919
		jmp @$709

;                 goto after_line;
;             }
;             for (p3 = p; *p != '\0' && *p != pc; ++p) {}
@$714:
		mov word [bp-0xe], si
@$715:
		mov al, byte [si]
		test al, al
		je @$717
		cmp cl, al
		je @$717
		inc si
		jmp @$715
@$716:
		jmp near @$729

;             if (*p == '\0') goto missing_quotes_in_incbin;
@$717:
		cmp byte [si], 0
		je @$713

;             liner = (char*)p;
		mov word [bp-6], si

;             incbin_offset = 0;
		xor ax, ax
		mov word [bp-0x20], ax
		mov word [bp-0x1c], ax

;             incbin_size = -1;  /* Unlimited. */
		mov ax, 0xffff
		mov word [bp-0x1a], ax
		mov word [bp-0x18], ax

;             if (*(p = avoid_spaces(p + 1)) == ',') {
		lea ax, [si+1]
		call near avoid_spaces_
		mov bx, ax
		cmp byte [bx], 0x2c
		jne @$726

;                 p = match_expression(p + 1);
		inc ax
		call near match_expression_

;                 if (p == NULL) {
		test ax, ax
		jne @$719
@$718:
		jmp near @$706

;                     MESSAGE(1, "Bad expression");
;                     goto after_line;
;                 } else if (has_undefined) {
@$719:
		cmp byte [_has_undefined], 0
		je @$721
@$720:
		jmp near @$708

;                     MESSAGE(1, "Cannot use undefined labels");
;                     goto after_line;
;                 } else if (instruction_value < 0) {
@$721:
		cmp word [_instruction_value+2], 0
		jge @$723

;                     MESSAGE(1, "INCBIN value is negative");
@$722:
		mov ax, @$920
		jmp near @$709

;                     goto after_line;
;                 } else {
;                     incbin_offset = instruction_value;
@$723:
		mov dx, word [_instruction_value]
		mov word [bp-0x20], dx
		mov dx, word [_instruction_value+2]
		mov word [bp-0x1c], dx

;                     if (*(p = avoid_spaces(p)) == ',') {
		call near avoid_spaces_
		mov bx, ax
		cmp byte [bx], 0x2c
		jne @$727

;                         p = match_expression(p + 1);
		inc ax
		call near match_expression_

;                         if (p == NULL) {
		test ax, ax
		je @$718

;                             MESSAGE(1, "Bad expression");
;                             goto after_line;
;                         } else if (has_undefined) {
		cmp byte [_has_undefined], 0
		jne @$720

;                             MESSAGE(1, "Cannot use undefined labels");
;                             goto after_line;
;                         } else if (!check_end(p)) {
		call near check_end_
		test ax, ax
		jne @$725
@$724:
		jmp near @$687

;                             goto after_line;
;                         } else if (instruction_value < 0) {
@$725:
		mov ax, word [_instruction_value+2]
		test ax, ax
		jl @$722

;                             MESSAGE(1, "INCBIN value is negative");
;                             goto after_line;
;                         } else {
;                             incbin_size = instruction_value;
		mov ax, word [_instruction_value]
		mov word [bp-0x1a], ax
		mov ax, word [_instruction_value+2]
		mov word [bp-0x18], ax

;                         }
;                     } else if (!check_end(p)) {
@$726:
		jmp @$728
@$727:
		call near check_end_
		test ax, ax
		je @$724

;                         goto after_line;
;                     }
;                 }
;             }
;             include = 2;
@$728:
		mov byte [bp-2], 2

;         } else if (casematch(instr_name, "ORG")) {
		jmp @$724
@$729:
		mov dx, @$921
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$734

;             p = match_expression(p);
		mov ax, bx
		call near match_expression_
		mov si, ax

;             if (p != NULL) check_end(p);
		test ax, ax
		je @$730
		call near check_end_

;             if (p == NULL) {
@$730:
		test si, si
		jne @$731
		jmp near @$706

;                 MESSAGE(1, "Bad expression");
;             } else if (has_undefined) {
@$731:
		cmp byte [_has_undefined], 0
		je @$732
		jmp near @$708

;                 MESSAGE(1, "Cannot use undefined labels");
;             } else if (is_start_address_set) {
@$732:
		cmp byte [_is_start_address_set], 0
		je @$735

;                 if (instruction_value != default_start_address) {
		mov dx, word [_instruction_value]
		mov ax, word [_instruction_value+2]
		cmp ax, word [_default_start_address+2]
		jne @$733
		cmp dx, word [_default_start_address]
		je @$724

;                     MESSAGE(1, "program origin redefined");  /* Same error as in NASM. */
@$733:
		mov ax, @$922
		jmp near @$784
@$734:
		jmp @$738

;                     goto close_return;  /* TODO(pts): Abort %includers as well. */
;                 }
;             } else {
;                 is_start_address_set = 1;
@$735:
		mov byte [_is_start_address_set], 1

;                 if (instruction_value != default_start_address) {
		mov dx, word [_instruction_value]
		mov ax, word [_instruction_value+2]
		cmp ax, word [_default_start_address+2]
		jne @$737
		cmp dx, word [_default_start_address]
		jne @$737
@$736:
		jmp near @$687

;                     default_start_address = instruction_value;
@$737:
		mov word [_default_start_address], dx
		mov word [_default_start_address+2], ax

;                     if (is_address_used) {
		cmp byte [_is_address_used], 0
		jne @$736

;                         /* change = 1; */  /* The start_address change will take effect in the next pass. Not needed, because we do `assembler_step > 1' anyway. */
;                     } else {
;                         reset_address();
		call near reset_address_

;                     }
		jmp @$736

;                 }
;             }
;         } else if (casematch(instr_name, "SECTION")) {
@$738:
		mov dx, @$923
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$741

;             if (!casematch(p, ".bss *") || !casematch(avoid_spaces(p + 5), "ALIGN=1")) {
		mov dx, @$924
		mov ax, bx
		call near casematch_
		test al, al
		je @$739
		mov dx, @$925
		lea ax, [bx+5]
		call near avoid_spaces_
		call near casematch_
		test al, al
		jne @$740

;                 MESSAGE1STR(1, "Unsupported SECTION: %s", p);
@$739:
		mov dx, si
		mov ax, @$926
		jmp near @$686

;             } else if (!is_bss) {
@$740:
		cmp byte [bp-4], 0
		jne @$736

;                 is_bss = 1;
		mov al, 1
		mov byte [bp-4], al

;                 is_address_used = 1;
		mov byte [_is_address_used], al

;                 start_address = current_address;
		mov ax, word [_current_address]
		mov dx, word [_current_address+2]
		mov word [_start_address], ax
		mov word [_start_address+2], dx

;             }
		jmp @$736

;         } else if (is_bss) {
@$741:
		cmp byte [bp-4], 0
		je @$750

;             if (casematch(instr_name, "RESB")) {
		mov dx, @$927
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$749

;                 /* We also could add RESW, RESD, ALIGNB, but the user can implement them in terms of RESB. */
;                 p = match_expression(p);
		mov ax, bx
		call near match_expression_

;                 if (p == NULL) {
		test ax, ax
		jne @$743
@$742:
		jmp near @$706

;                     MESSAGE(1, "Bad expression");
;                 } else if (has_undefined) {
@$743:
		cmp byte [_has_undefined], 0
		je @$745
@$744:
		jmp near @$708

;                     MESSAGE(1, "Cannot use undefined labels");
;                 } else if (instruction_value < 0) {
@$745:
		cmp word [_instruction_value+2], 0
		jge @$746

;                     MESSAGE(1, "RESB value is negative");
		mov ax, @$928
		jmp near @$709

;                 } else if (!check_end(p)) {
@$746:
		call near check_end_
		test ax, ax
		jne @$748
@$747:
		jmp near @$687

;                 } else {
;                     current_address += instruction_value;
@$748:
		mov ax, word [_instruction_value]
		mov dx, word [_instruction_value+2]
		add word [_current_address], ax
		adc word [_current_address+2], dx

;                 }
		jmp @$747

;             } else {
;                 MESSAGE1STR(1, "Unsupported .bss instrucction: %s", instr_name);
@$749:
		mov dx, _instr_name
		mov ax, @$929
		jmp near @$686

;             }
;         } else if (casematch(instr_name, "ALIGN")) {
@$750:
		mov dx, @$930
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$754

;             p = match_expression(p);
		mov ax, bx
		call near match_expression_
		mov si, ax

;             if (p == NULL) {
		test ax, ax
		je @$742

;                 MESSAGE(1, "Bad expression");
;             } else if (has_undefined) {
		cmp byte [_has_undefined], 0
		jne @$744

;                 MESSAGE(1, "Cannot use undefined labels");
;             } else if (instruction_value <= 0) {
		mov ax, word [_instruction_value+2]
		test ax, ax
		jl @$751
		jne @$752
		cmp word [_instruction_value], 0
		ja @$752

;                 MESSAGE(1, "ALIGN value is not positive");
@$751:
		mov ax, @$931
		jmp near @$709

;             } else {
;                 /* NASM 0.98.39 does the wrong thing if instruction_value is not a power of 2. Newer NASMs report an error. mininasm just works. */
;                 times = (uvalue_t)current_address % instruction_value;
@$752:
		mov ax, word [_current_address]
		mov dx, word [_current_address+2]
		mov bx, word [_instruction_value]
		mov cx, word [_instruction_value+2]
		call near __U4D
		mov dx, cx
		mov word [bp-0x14], bx

;                 if (times != 0) times = instruction_value - times;
		or dx, bx
		je @$753
		mov ax, word [_instruction_value]
		sub ax, bx
		mov word [bp-0x14], ax
		mov ax, word [_instruction_value+2]
		sbb ax, cx
		mov cx, ax

;                 p = avoid_spaces(p);
@$753:
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;                 if (p[0] == ',') {
		cmp byte [si], 0x2c
		jne @$755

;                     ++p;
		inc si

;                     goto do_instruction_with_times;  /* This doesn't work correctly if the instruction at `p' doesn't emit exiacty 1 byte. That's fine, same as for NASM. */
		jmp @$763
@$754:
		jmp @$759

;                 }
;                 check_end(p);
@$755:
		call near check_end_

;                 for (; (uvalue_t)times != 0; --times) {
@$756:
		mov ax, word [bp-0x14]
		or ax, cx
		jne @$758
@$757:
		jmp near @$687

;                     emit_byte(0x90);
@$758:
		mov ax, 0x90
		call near emit_byte_

;                 }
		add word [bp-0x14], 0xffff
		adc cx, 0xffff
		jmp @$756

;             }
;         } else {
;             times = 1;
@$759:
		mov word [bp-0x14], 1
		xor cx, cx

;             if (casematch(instr_name, "TIMES")) {
		mov dx, @$932
		mov ax, _instr_name
		call near casematch_
		test al, al
		je @$762

;                 p3 = match_expression(p);
		mov ax, bx
		call near match_expression_
		mov word [bp-0xe], ax

;                 if (p3 == NULL) {
		test ax, ax
		jne @$760
		jmp near @$706

;                     MESSAGE(1, "Bad expression");
;                     goto after_line;
;                 }
;                 if (has_undefined) {
@$760:
		cmp byte [_has_undefined], 0
		je @$761
		jmp near @$708

;                     MESSAGE(1, "Cannot use undefined labels");
;                     goto after_line;
;                 }
;                 if ((value_t)(times = instruction_value) < 0) {
@$761:
		mov ax, word [_instruction_value]
		mov word [bp-0x14], ax
		mov cx, word [_instruction_value+2]
		test cx, cx
		jge @$762

;                     MESSAGE(1, "TIMES value is negative");
		mov ax, @$933
		jmp near @$709

;                     goto after_line;
;                 }
;             }
;             p = p3;
@$762:
		mov si, word [bp-0xe]

;           do_instruction_with_times:
;             line_address = current_address;
@$763:
		mov ax, word [_current_address]
		mov word [bp-0x28], ax
		mov ax, word [_current_address+2]
		mov word [bp-0x2a], ax

;             g = generated_ptr;
		mov ax, word [_generated_ptr]
		mov word [_g], ax

;             for (; (uvalue_t)times != 0; --times) {
@$764:
		mov ax, word [bp-0x14]
		or ax, cx
		je @$757

;                 process_instruction(p);
		mov ax, si
		call near process_instruction_

;             }
		add word [bp-0x14], 0xffff
		adc cx, 0xffff
		jmp @$764

;         }
;       after_line:
;         if (assembler_pass > 1 && listing_fd >= 0) {
;             bbprintf(&message_bbb /* listing_fd */, "%04" FMT_VALUE "X  ", GET_UVALUE(line_address));
;             p = generated_ptr;
;             while (p < g) {
;                 bbprintf(&message_bbb /* listing_fd */, "%02X", *p++ & 255);
;             }
;             while (p < generated + sizeof(generated)) {
@$765:
		cmp si, _generated+8
		jae @$766

;                 bbprintf(&message_bbb /* listing_fd */, "  ");
		mov ax, @$936
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 4

;                 p++;
		inc si

;             }
		jmp @$765

;             /* TODO(pts): Keep the original line with the original comment, if possible. This is complicated and needs more memory. */
;             bbprintf(&message_bbb /* listing_fd */, "  %05" FMT_VALUE "u %s\r\n", GET_UVALUE(line_number), line);
@$766:
		push word [bp-0x12]
		push word [_line_number+2]
		push word [_line_number]
		mov ax, @$937
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 0xa

;         }
;         if (include == 1) {  /* %INCLUDE. */
@$767:
		mov al, byte [bp-2]
		cmp al, 1
		jne @$769

;             if (0) DEBUG1("INCLUDE %s\r\n", p3);  /* Not yet NUL-terminated early. */
;             if (linep != NULL && (aip->file_offset = lseek(input_fd, (linep - line_rend) - discarded_after_read, SEEK_CUR)) < 0) {  /* TODO(pts): We should check for overflow for source files >= 2 GiB. */
		mov ax, word [bp-0x16]
		test ax, ax
		je @$768
		sub ax, word [bp-0xc]
		sub ax, word [bp-0x1e]
		cwd
		mov cx, dx
		mov dx, 1
		mov bx, ax
		mov ax, word [bp-0x22]
		call near lseek_
		mov word [di], ax
		mov word [di+2], dx
		mov dx, word [di]
		mov ax, word [di+2]
		test ax, ax
		jge @$768

;                 MESSAGE(1, "Cannot seek in source file");
		mov ax, @$938
		jmp near @$784

;                 goto close_return;
;             }
;             close(input_fd);
@$768:
		mov ax, word [bp-0x22]
		call near close_

;             aip->level = level;
		mov ax, word [bp-0x24]
		mov word [di+4], ax
		mov ax, word [bp-8]
		mov word [di+6], ax

;             aip->avoid_level = avoid_level;
		mov ax, word [bp-0x10]
		mov word [di+8], ax
		mov ax, word [bp-0xa]
		mov word [di+0xa], ax

;             aip->line_number = line_number;
		mov ax, word [_line_number]
		mov dx, word [_line_number+2]
		mov word [di+0xc], ax
		mov word [di+0xe], dx

;             *liner = '\0';
		mov bx, word [bp-6]
		mov byte [bx], 0

;             input_filename = p3;
		mov bx, word [bp-0xe]
		mov word [bp-0x2c], bx

;             goto do_assembly_push;
		jmp near @$586

;         } else if (include == 2) {  /* INCBIN. */
@$769:
		cmp al, 2
		je @$771
@$770:
		jmp near @$592

;             *liner = '\0';  /* NUL-terminate the filename in p3. It's OK, we've already written the line to listing_fd. */
@$771:
		mov bx, word [bp-6]
		mov byte [bx], 0

;             if ((incbin_fd = open2(p3, O_RDONLY | O_BINARY)) < 0) {
		xor dx, dx
		mov ax, word [bp-0xe]
		call near open2_
		mov si, ax
		test ax, ax
		jge @$772

;                 MESSAGE1STR(1, "Error: Cannot open '%s' for input", p3);
		mov dx, word [bp-0xe]
		mov ax, @$939
		call near message1str_

;             } else {
		jmp @$770

;                 if (incbin_offset != 0 && lseek(incbin_fd, incbin_offset, SEEK_SET) != incbin_offset) {
@$772:
		mov dx, word [bp-0x1c]
		or dx, word [bp-0x20]
		je @$775
		xor dx, dx
		mov bx, word [bp-0x20]
		mov cx, word [bp-0x1c]
		call near lseek_
		cmp dx, word [bp-0x1c]
		jne @$773
		cmp ax, word [bp-0x20]
		je @$775

;                     MESSAGE1STR(1, "Cannot seek in INCBIN file: ", p3);
@$773:
		mov dx, word [bp-0xe]
		mov ax, @$940
@$774:
		call near message1str_

;                 } else {
		jmp @$781

;                     message_flush(NULL);  /* Because we reuse message_buf below. */
@$775:
		xor ax, ax
		call near message_flush_

;                     g = NULL;  /* Doesn't make an actual difference, incbin is called too late to append to incbin anyway. */
		xor ax, ax
		mov word [_g], ax

;                     /* Condition below is good even if incbin_size == -1 (unlimited). */
;                     while (incbin_size != 0) {
@$776:
		mov ax, word [bp-0x18]
		or ax, word [bp-0x1a]
		je @$781

;                         if ((got = read(incbin_fd, message_buf, (uvalue_t)incbin_size < sizeof(message_buf) ? (unsigned)incbin_size : sizeof(message_buf))) <= 0) {
		cmp word [bp-0x18], 0
		jne @$777
		cmp word [bp-0x1a], 0x200
		jae @$777
		mov bx, word [bp-0x1a]
		jmp @$778
@$777:
		mov bx, 0x200
@$778:
		mov dx, _message_buf
		mov ax, si
		call near read_
		mov bx, ax
		test ax, ax
		jg @$779

;                             if (got < 0) MESSAGE1STR(1, "Error: Error reading from '%s'", p3);
		jge @$781
		mov dx, word [bp-0xe]
		mov ax, @$941
		jmp @$774

;                             break;
;                         }
;                         emit_bytes(message_buf, got);
@$779:
		mov dx, ax
		mov ax, _message_buf
		call near emit_bytes_

;                         if (incbin_size != -1) incbin_size -= got;
		cmp word [bp-0x18], 0xffff
		jne @$780
		cmp word [bp-0x1a], 0xffff
		je @$776
@$780:
		mov ax, bx
		cwd
		sub word [bp-0x1a], ax
		sbb word [bp-0x18], dx
		jmp @$776

;                     }
;                 }
;                 close(incbin_fd);
@$781:
		mov ax, si
		call near close_

;             }
		jmp near @$592

;         }
;     }
;     if (level != 1) {
@$782:
		cmp word [bp-8], 0
		jne @$783
		cmp word [bp-0x24], 1
		je @$785

;         MESSAGE(1, "pending %IF at end of file");
@$783:
		mov ax, @$942
@$784:
		call near message_

;     }
;   close_return:
;     close(input_fd);
@$785:
		mov ax, word [bp-0x22]
		call near close_

;     if ((aip = assembly_pop(aip)) != NULL) goto do_open_again;  /* Continue processing the input file which %INCLUDE()d the current input file. */
		mov ax, di
		call near assembly_pop_
		mov di, ax
		test ax, ax
		je @$786
		jmp near @$587

;     line_number = 0;  /* Global variable. */
@$786:
		mov word [_line_number], ax
		mov word [_line_number+2], ax

; }
		jmp near @$87

;
; static MY_STRING_WITHOUT_NUL(mininasm_macro_name, " __MININASM__");
;
; /*
;  ** Main program
;  */
; int main(int argc, char **argv) {
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

;     int d;
;     const char *p;
;     char *ifname;
;     char *listing_filename;
;     value_t prev_address;
;     (void)argc;
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
		jne @$787

;         static const MY_STRING_WITHOUT_NUL(msg, "Typical usage:\r\nmininasm -f bin input.asm -o input.bin\r\n");
;         (void)!write(2, msg, STRING_SIZE_WITHOUT_NUL(msg));
		mov bx, 0x38
		mov dx, @$966
		mov ax, 2
		call near write_
		jmp near @$839

;         return 1;
;     }
;
;     /*
;      ** Start to collect arguments
;      */
;     ifname = NULL;
@$787:
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

;     set_macro(mininasm_macro_name,  mininasm_macro_name + sizeof(mininasm_macro_name) - 1, "3", MACRO_SET_DEFINE_CMDLINE);  /* `%DEFINE __MININASM__ ...'. */
		mov cx, 1
		mov bx, @$943
		mov dx, _mininasm_macro_name.end
		mov ax, _mininasm_macro_name
		call near set_macro_

;     while (argv[0] != NULL) {
@$788:
		mov ax, word [si]
		test ax, ax
		je @$793

;         if (0) DEBUG1("arg=(%s)\n", argv[0]);
;         if (argv[0][0] == '-') {    /* All arguments start with dash */
		mov bx, ax
		cmp byte [bx], 0x2d
		jne @$794

;             d = argv[0][1] | 32;  /* Flags characters are case insensitive. */
		mov dl, byte [bx+1]
		or dl, 0x20
		xor dh, dh
		mov ax, dx

;             if (d == 'd') {  /* Define macro: -DNAME and -DNAME=VALUE. -DNAME is not allowed, because macros with an empty values are nt allowed. */
		cmp dx, 0x64
		jne @$795

;                 for (p = argv[0] + 2; *p != '\0' && *p != '='; ++p) {}
		lea di, [bx+2]
@$789:
		mov al, byte [di]
		test al, al
		je @$790
		cmp al, 0x3d
		je @$790
		inc di
		jmp @$789

;                 set_macro(argv[0] + 1, (char*)p, p + (*p == '='), MACRO_SET_DEFINE_CMDLINE);
@$790:
		mov cx, 1
		cmp byte [di], 0x3d
		jne @$791
		mov bx, cx
		jmp @$792
@$791:
		xor bx, bx
@$792:
		add bx, di
		mov ax, word [si]
		inc ax
		mov dx, di
		call near set_macro_

;                 if (errors) return 1;
		mov ax, word [_errors+2]
		or ax, word [_errors]
		je @$801
		jmp near @$839
@$793:
		jmp near @$822
@$794:
		jmp near @$819

;             } else if (argv[0][2] != '\0' && d == 'o') {  /* Optimization level (`nasm -O...'). */
@$795:
		cmp byte [bx+2], 0
		je @$803
		cmp dx, 0x6f
		jne @$803

;                 d = argv[0][2];
		mov dl, byte [bx+2]
		mov ax, dx

;                 if (d == '\0' || argv[0][3] != '\0') { bad_opt_level:
		test dx, dx
		je @$796
		cmp byte [bx+3], 0
		je @$798

;                     MESSAGE(1, "bad optimization argument");
@$796:
		mov ax, @$944
@$797:
		call near message_
		jmp near @$839

;                     return 1;
;                 }
;                 d |= 32;
@$798:
		or al, 0x20

;                 if (d + 0U - '0' <= 1U) {  /* -O0 is compatible with NASM, -O1 does some more. */
		mov dx, ax
		sub dx, 0x30
		cmp dx, 1
		ja @$799

;                     opt_level = d - '0';
		sub al, 0x30
		mov byte [_opt_level], al

;                 } else if (d == 'x' || d == '3' || d == '9') {  /* -Ox, -O3, -O9 (compatible with NASM). */
		jmp @$801
@$799:
		cmp ax, 0x78
		je @$800
		cmp ax, 0x33
		je @$800
		cmp ax, 0x39
		jne @$802

;                   set_opt_level_9:
;                     opt_level = 9;
@$800:
		mov byte [_opt_level], 9

;                 } else if (d == 'l') {  /* -OL (not compatible with NASM, `nasm -O9' doesn't do it) to optimize `lea', including `lea ax, [bx]' and `lea ax, [es:bx]'. */
@$801:
		jmp near @$821
@$802:
		cmp ax, 0x6c
		jne @$804

;                     do_opt_lea = 1;
		mov byte [_do_opt_lea], 1

;                 } else if (d == 'g') {  /* -OG (not compatible with NASM, `nasm -O9' doesn't do it) to optimize segment prefixes in effective addresses, e.g. ``mov ax, [ds:si]'. */
		jmp @$801
@$803:
		jmp @$806
@$804:
		cmp ax, 0x67
		je @$805
		cmp ax, 0x61
		jne @$796

;                     do_opt_segreg = 1;
;                 } else if (d == 'a') {  /* -OA to turn on all optimizations, even those which are not compatible with NASM. Equilvalent to `-O9 -OL -OG'. */
;                     do_opt_lea = 1;
		mov al, 1
		mov byte [_do_opt_lea], al

;                     do_opt_segreg = 1;
		mov byte [_do_opt_segreg], al

;                     goto set_opt_level_9;
		jmp @$800

;                 } else {
;                     goto bad_opt_level;
;                 }
@$805:
		mov byte [_do_opt_segreg], 1
		jmp @$801

;             } else if (argv[0][2] != '\0' && (d == 'f' || d == 'o' || d == 'l')) {
@$806:
		mov bx, word [si]
		cmp byte [bx+2], 0
		je @$809
		cmp ax, 0x66
		je @$807
		cmp ax, 0x6f
		je @$807
		cmp ax, 0x6c
		jne @$809

;                 MESSAGE1STR(1, "flag too long: %s", argv[0]);  /* Example: `-fbin' should be `-f bin'. */
@$807:
		mov dx, word [si]
		mov ax, @$945
@$808:
		call near message1str_
		jmp near @$839

;                 return 1;
;             } else if (d == 'f') { /* Format */
@$809:
		lea bx, [si+2]
		cmp ax, 0x66
		jne @$814

;                 if (*++argv == NULL) {
		mov si, bx
		mov ax, word [bx]
		test ax, ax
		jne @$811

;                   error_no_argument:
;                     MESSAGE1STR(1, "no argument for %s", argv[-1]);
@$810:
		mov dx, word [si-2]
		mov ax, @$946
		jmp @$808

;                     return 1;
;                 } else {
;                     if (casematch(argv[0], "BIN")) {
@$811:
		mov dx, @$947
		call near casematch_
		test al, al
		je @$812

;                         default_start_address = 0;
		xor ax, ax
		mov word [_default_start_address], ax
		mov word [_default_start_address+2], ax

;                         is_start_address_set = 0;
		mov byte [_is_start_address_set], 0

;                     } else if (casematch(argv[0], "COM")) {
		jmp @$801
@$812:
		mov ax, word [bx]
		mov dx, @$948
		call near casematch_
		test al, al
		jne @$813

;                         default_start_address = 0x100;
;                         is_start_address_set = 1;
;                     } else {
;                         MESSAGE1STR(1, "only 'bin', 'com' supported for -f (it is '%s')", argv[0]);
		mov dx, word [bx]
		mov ax, @$949
		jmp @$808

@$813:
		mov word [_default_start_address], 0x100
		xor ax, ax
		mov word [_default_start_address+2], ax

;                         return 1;
;                     }
		mov byte [_is_start_address_set], 1
		jmp @$821

;                 }
;             } else if (d == 'o') {  /* Object file name */
@$814:
		cmp ax, 0x6f
		jne @$816

;                 if (*++argv == NULL) {
		mov si, bx
		cmp word [bx], 0
		je @$810

;                     goto error_no_argument;
;                 } else if (output_filename != NULL) {
		cmp word [_output_filename], 0
		je @$815

;                     MESSAGE(1, "already a -o argument is present");
		mov ax, @$950
		jmp near @$797

;                     return 1;
;                 } else {
;                     output_filename = argv[0];
@$815:
		mov ax, word [bx]
		mov word [_output_filename], ax

;                 }
;             } else if (d == 'l') {  /* Listing file name */
		jmp @$821
@$816:
		cmp ax, 0x6c
		jne @$817

;                 if (*++argv == NULL) {
		mov si, bx
		cmp word [bx], 0
		je @$810

;                     goto error_no_argument;
;                     return 1;
;                 } else if (listing_filename != NULL) {
		cmp word [bp-4], 0
		je @$818

;                     MESSAGE(1, "already a -l argument is present");
		mov ax, @$951
		jmp near @$797

;                     return 1;
;                 } else {
;                     listing_filename = argv[0];
;                 }
;             } else {
;                 MESSAGE1STR(1, "unknown argument %s", argv[0]);
@$817:
		mov dx, word [si]
		mov ax, @$952
		jmp near @$808

;                 return 1;
;             }
@$818:
		mov ax, word [bx]
		mov word [bp-4], ax
		jmp @$821

;         } else {
;             if (0) DEBUG1("ifname=(%s)\n", argv[0]);
;             if (ifname != NULL) {
@$819:
		cmp word [bp-2], 0
		je @$820

;                 MESSAGE1STR(1, "more than one input file name: %s", argv[0]);
		mov dx, ax
		mov ax, @$953
		jmp near @$808

;                 return 1;
;             } else {
;                 ifname = argv[0];
@$820:
		mov word [bp-2], ax

;             }
;         }
;         ++argv;
@$821:
		inc si
		inc si

;     }
		jmp near @$788

;
;     if (ifname == NULL) {
@$822:
		cmp word [bp-2], 0
		jne @$823

;         MESSAGE(1, "No input filename provided");
		mov ax, @$954
		jmp near @$797

;         return 1;
;     }
;
;     /*
;      ** Do first pass of assembly, calculating offsets and labels only.
;      */
;     assembler_pass = 1;
@$823:
		mov word [_assembler_pass], 1

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
		jne @$828

;         remove(output_filename);
;         /* if (listing_filename != NULL) remove(listing_filename); */  /* Don't remove listing_filename, it may contain useful error messages etc. */
;     } else {
;         /*
;          ** Do second pass of assembly and generate final output
;          */
;         if (output_filename == NULL) {
		cmp word [_output_filename], 0
		jne @$824

;             MESSAGE(1, "No output filename provided");
		mov ax, @$955
		jmp near @$797

;             return 1;
;         }
;         do {
;             if (GET_U16(++assembler_pass) == 0) --assembler_pass;  /* Cappped at 0xffff. */
@$824:
		inc word [_assembler_pass]
		jne @$825
		dec word [_assembler_pass]

;             if (listing_filename != NULL) {
@$825:
		mov ax, word [bp-4]
		test ax, ax
		je @$827

;                 if ((listing_fd = creat(listing_filename, 0644)) < 0) {
		mov dx, 0x1a4
		call near creat_
		mov word [_listing_fd], ax
		test ax, ax
		jge @$826

;                     MESSAGE1STR(1, "couldn't open '%s' as listing file", output_filename);
		mov dx, word [_output_filename]
		mov ax, @$956
		jmp near @$808

;                     return 1;
;                 }
;                 generated_ptr = generated;  /* Start saving bytes to the `generated' array, for the listing. */
@$826:
		mov word [_generated_ptr], _generated

;             }
;             if ((output_fd = creat(output_filename, 0644)) < 0) {
@$827:
		mov ax, word [_output_filename]
		mov dx, 0x1a4
		call near creat_
		mov word [_output_fd], ax
		test ax, ax
		jge @$829

;                 MESSAGE1STR(1, "couldn't open '%s' as output file", output_filename);
		mov dx, word [_output_filename]
		mov ax, @$957
		jmp near @$808
@$828:
		jmp near @$838

;                 return 1;
;             }
;             prev_address = current_address;
@$829:
		mov bx, word [_current_address]
		mov dx, word [_current_address+2]

;             is_start_address_set = 1;
		mov byte [_is_start_address_set], 1

;             if (opt_level <= 1) {
		cmp byte [_opt_level], 1
		ja @$830

;                 /* wide_instr_add_at = NULL; */  /* Keep for reading. */
;                 wide_instr_read_at = NULL;
		xor ax, ax
		mov word [_wide_instr_read_at], ax
		mov word [_wide_instr_read_at+2], ax

;             }
;             reset_address();
@$830:
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
		call near close_

;             if (have_labels_changed) {
		cmp byte [_have_labels_changed], 0
		je @$834

;                 if (opt_level <= 1) {
		cmp byte [_opt_level], 1
		ja @$831

;                     MESSAGE(1, "oops: labels changed");
		mov ax, @$958

;                 } else if (current_address > prev_address) {  /* It's OK that the size increases because of overly optimistic optimizations. */
		jmp @$833
@$831:
		mov ax, word [_current_address+2]
		cmp dx, ax
		jl @$834
		jne @$832
		cmp bx, word [_current_address]
		jb @$834

;                 } else if (++size_decrease_count == 5) {  /* TODO(pts): Make this configurable? What is the limit for NASM? */
@$832:
		inc byte [_size_decrease_count]
		cmp byte [_size_decrease_count], 5
		jne @$834

;                     MESSAGE(1, "Aborted: Couldn't stabilize moving label");
		mov ax, @$959
@$833:
		call near message_

;                 }
;             }
;             if (listing_fd >= 0) {
@$834:
		cmp word [_listing_fd], 0
		jge @$835
		jmp near @$836

;                 bbprintf(&message_bbb /* listing_fd */, "\r\n%05" FMT_VALUE "u ERRORS FOUND\r\n", GET_UVALUE(errors));
@$835:
		push word [_errors+2]
		push word [_errors]
		mov ax, @$960
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 8

;                 bbprintf(&message_bbb /* listing_fd */, "%05" FMT_VALUE "u WARNINGS FOUND\r\n",
		xor ax, ax
		push ax
		push ax
		mov ax, @$961
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
		mov ax, @$962
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 8

;                 bbprintf(&message_bbb /* listing_fd */, "%05" FMT_VALUE "u ASSEMBLER PASSES\r\n\r\n", GET_UVALUE(assembler_pass));
		mov dx, word [_assembler_pass]
		xor ax, ax
		push ax
		push dx
		mov ax, @$963
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 8

;                 bbprintf(&message_bbb /* listing_fd */, "%-20s VALUE/ADDRESS\r\n\r\n", "LABEL");
		mov ax, @$964
		push ax
		mov ax, @$965
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, 6

;                 print_labels_sorted_to_listing_fd();
		call near print_labels_sorted_to_listing_fd_

;                 bbprintf(&message_bbb /* listing_fd */, "\r\n");
		mov ax, @$872
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
@$836:
		mov ax, word [_errors+2]
		or ax, word [_errors]
		jne @$838

;         } while (have_labels_changed);
		mov al, byte [_have_labels_changed]
		test al, al
		je @$837
		jmp near @$824

;         return 0;
@$837:
		xor ah, ah
		jmp near @$77

@$838:
		mov ax, word [_output_filename]

;     }
		call near remove_

;
;     return 1;
@$839:
		mov ax, 1

; }
		jmp near @$77

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

@$840		db '(null)', 0
@$841		db 'Out of memory', 0
@$842		db '%-20s %08lX', 13, 10, 0
@$843		db 'EQU!', 0
@$844		db 'RESB!', 0
@$845		db 'SHORT!', 0
@$846		db 'NEAR!', 0
@$847		db 'FAR!', 0
@$848		db 'BYTE!', 0
@$849		db 'WORD!', 0
@$850		db 'DWORD!', 0
@$851		db 'STRICT!', 0
@$852		db 'Missing close paren', 0
@$853		db 'Expression too deep', 0
@$854		db 'Missing close quote', 0
@$855		db 'bad label', 0
@$856		db 'Undefined label ', 39, '%s', 39, 0
@$857		db 'division by zero', 0
@$858		db 'modulo by zero', 0
@$859		db 'shift by larger than 31', 0
@$860		db 'oops: bad instr order', 0
@$861		db 'error writing to output file', 0
@$862		db 'extra characters at end of line', 0
@$863		db 'j', 0
@$864		db 0
@$865		db 'b', 0
@$866		db 'short jump too long', 0
@$867		db 'near jump too long', 0
@$868		db 'ooops: decode (%s)', 0
@$869		db 'error writing to listing file', 0
@$870		db 'error: ', 0
@$871		db '%s:%u: %s', 0
@$872		db 13, 10, 0
@$873		db '%s', 0
@$874		db 'DB', 0
@$875		db 'Bad expression', 0
@$876		db 'DW', 0
@$877		db 'DD', 0
@$878		db 'Unknown instruction ', 39, '%s', 39, 0
@$879		db 'Error in instruction ', 39, '%s %s', 39, 0
@$880		db 'Redefined label ', 39, '%s', 39, 0
@$881		db 'oops: label ', 39, '%s', 39, ' not found', 0
@$882		db 'bad macro name', 0
@$883		db 'invalid macro override', 0
@$884		db 'bad macro value', 0
@$885		db 'macro name conflicts with label', 0
@$886		db 'Cannot use undefined labels', 0
@$887		db 'assembly stack overflow, too many pending %INCLUDE files', 0
@$888		db 'cannot open ', 39, '%s', 39, ' for input', 0
@$889		db 'cannot seek in ', 39, '%s', 39, 0
@$890		db 'error reading assembly file', 0
@$891		db 'quoted NUL found', 0
@$892		db 'assembly line too long', 0
@$893		db '%IF', 0
@$894		db '%IF too deep', 0
@$895		db '%IFDEF', 0
@$896		db '%IFNDEF', 0
@$897		db '%ELSE', 0
@$898		db '%ELSE without %IF', 0
@$899		db '%ENDIF', 0
@$900		db '%ENDIF without %IF', 0
@$901		db '%IF*', 0
@$902		db '%ELIF*', 0
@$903		db 'Unknown preprocessor condition: %s', 0
@$904		db '%INCLUDE', 0
@$905		db 'Missing quotes in %INCLUDE', 0
@$906		db '%DEFINE', 0
@$907		db '%ASSIGN', 0
@$908		db '%UNDEF', 0
@$909		db 'Unknown preprocessor directive: %s', 0
@$910		db 'bad expression', 0
@$911		db 'Instruction expected', 0
@$912		db 'USE16', 0
@$913		db 'CPU', 0
@$914		db '8086', 0
@$915		db 'Unsupported processor requested', 0
@$916		db 'BITS', 0
@$917		db 'Unsupported BITS requested', 0
@$918		db 'INCBIN', 0
@$919		db 'Missing quotes in INCBIN', 0
@$920		db 'INCBIN value is negative', 0
@$921		db 'ORG', 0
@$922		db 'program origin redefined', 0
@$923		db 'SECTION', 0
@$924		db '.bss *', 0
@$925		db 'ALIGN=1', 0
@$926		db 'Unsupported SECTION: %s', 0
@$927		db 'RESB', 0
@$928		db 'RESB value is negative', 0
@$929		db 'Unsupported .bss instrucction: %s', 0
@$930		db 'ALIGN', 0
@$931		db 'ALIGN value is not positive', 0
@$932		db 'TIMES', 0
@$933		db 'TIMES value is negative', 0
@$934		db '%04lX  ', 0
@$935		db '%02X', 0
@$936		db '  ', 0
@$937		db '  %05lu %s', 13, 10, 0
@$938		db 'Cannot seek in source file', 0
@$939		db 'Error: Cannot open ', 39, '%s', 39, ' for input', 0
@$940		db 'Cannot seek in INCBIN file: ', 0
@$941		db 'Error: Error reading from ', 39, '%s', 39, 0
@$942		db 'pending %IF at end of file', 0
@$943		db '4', 0
@$944		db 'bad optimization argument', 0
@$945		db 'flag too long: %s', 0
@$946		db 'no argument for %s', 0
@$947		db 'BIN', 0
@$948		db 'COM', 0
@$949		db 'only ', 39, 'bin', 39, ', ', 39, 'com', 39, ' supported for -f (it is ', 39, '%s', 39, ')', 0
@$950		db 'already a -o argument is present', 0
@$951		db 'already a -l argument is present', 0
@$952		db 'unknown argument %s', 0
@$953		db 'more than one input file name: %s', 0
@$954		db 'No input filename provided', 0
@$955		db 'No output filename provided', 0
@$956		db 'couldn', 39, 't open ', 39, '%s', 39, ' as listing file', 0
@$957		db 'couldn', 39, 't open ', 39, '%s', 39, ' as output file', 0
@$958		db 'oops: labels changed', 0
@$959		db 'Aborted: Couldn', 39, 't stabilize moving label', 0
@$960		db 13, 10, '%05lu ERRORS FOUND', 13, 10, 0
@$961		db '%05lu WARNINGS FOUND', 13, 10, 0
@$962		db '%05lu PROGRAM BYTES', 13, 10, 0
@$963		db '%05lu ASSEMBLER PASSES', 13, 10, 13, 10, 0
@$964		db 'LABEL', 0
@$965		db '%-20s VALUE/ADDRESS', 13, 10, 13, 10, 0

___section__mininasm_c_const2:

_register_names	db 'CSDSESSSALCLDLBLAHCHDHBHAXCXDXBXSPBPSIDI'
_reg_to_addressing db 0, 0, 0, 7, 0, 6, 4, 5
; static const MY_STRING_WITHOUT_NUL(msg, ...);
@$966		db 'Typical usage:', 13, 10, 'mininasm -f bin input.asm -o input.bin', 13, 10
; /** Instruction set.
;  ** Notice some instructions are sorted by less byte usage first.
;  */
; #define ALSO "-"
; const char instruction_set[] =
;     "AAA\0" " 37\0"
;     "AAD\0" "i D5i" ALSO " D50A\0"
;     "AAM\0" "i D4i" ALSO " D40A\0"
;     "AAS\0" " 3F\0"
;     "ADC\0" "j,q 10drd" ALSO "k,r 11drd" ALSO "q,j 12drd" ALSO "r,k 13drd" ALSO "vAL,h 14i" ALSO "wAX,g 15j" ALSO "m,s sdzozdj" ALSO "l,t 80dzozdi\0"
;     "ADD\0" "j,q 00drd" ALSO "k,r 01drd" ALSO "q,j 02drd" ALSO "r,k 03drd" ALSO "vAL,h 04i" ALSO "wAX,g 05j" ALSO "m,s sdzzzdj" ALSO "l,t 80dzzzdi\0"
;     "AND\0" "j,q 20drd" ALSO "k,r 21drd" ALSO "q,j 22drd" ALSO "r,k 23drd" ALSO "vAL,h 24i" ALSO "wAX,g 25j" ALSO "m,s sdozzdj" ALSO "l,t 80dozzdi\0"
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
;     "ES\0" " 26+\0"
;     "HLT\0" " F4\0"
;     "IDIV\0" "l F6doood" ALSO "m F7doood\0"
;     "IMUL\0" "l F6dozod" ALSO "m F7dozod\0"
;     "IN\0" "vAL,wDX EC" ALSO "wAX,wDX ED" ALSO "vAL,h E4i" ALSO "wAX,i E5i\0"
;     "INC\0" "r zozzzr" ALSO "l FEdzzzd" ALSO "m FFdzzzd\0"
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
;     "PAUSE\0" " F390\0"
;     "POP\0" "ES 07" ALSO "SS 17" ALSO "DS 1F" ALSO "r zozoor" ALSO "k 8Fdzzzd\0"
;     "POPF\0" " 9D\0"
;     "PUSH\0" "ES 06" ALSO "CS 0E" ALSO "SS 16" ALSO "DS 1E" ALSO "r zozozr" ALSO "k FFdoozd\0"
;     "PUSHF\0" " 9C\0"
;     "RCL\0" "j,1 D0dzozd" ALSO "k,1 D1dzozd" ALSO "j,CL D2dzozd" ALSO "k,CL D3dzozd\0"
;     "RCR\0" "j,1 D0dzood" ALSO "k,1 D1dzood" ALSO "j,CL D2dzood" ALSO "k,CL D3dzood\0"
;     "REP\0" " F3+\0"
;     "REPE\0" " F3+\0"
;     "REPNE\0" " F2+\0"
;     "REPNZ\0" " F2+\0"
;     "REPZ\0" " F3+\0"
;     "RET\0" "i C2j" ALSO " C3\0"
;     "RETF\0" "i CAj" ALSO " CB\0"
;     "ROL\0" "j,1 D0dzzzd" ALSO "k,1 D1dzzzd" ALSO "j,CL D2dzzzd" ALSO "k,CL D3dzzzd\0"
;     "ROR\0" "j,1 D0dzzod" ALSO "k,1 D1dzzod" ALSO "j,CL D2dzzod" ALSO "k,CL D3dzzod\0"
;     "SAHF\0" " 9E\0"
;     "SAR\0" "j,1 D0doood" ALSO "k,1 D1doood" ALSO "j,CL D2doood" ALSO "k,CL D3doood\0"
;     "SBB\0" "j,q 18drd" ALSO "k,r 19drd" ALSO "q,j 1Adrd" ALSO "r,k 1Bdrd" ALSO "vAL,h 1Ci" ALSO "wAX,g 1Dj" ALSO "m,s sdzoodj" ALSO "l,t 80dzoodi\0"
;     "SCASB\0" " AE\0"
;     "SCASW\0" " AF\0"
;     "SHL\0" "j,1 D0dozzd" ALSO "k,1 D1dozzd" ALSO "j,CL D2dozzd" ALSO "k,CL D3dozzd\0"
;     "SHR\0" "j,1 D0dozod" ALSO "k,1 D1dozod" ALSO "j,CL D2dozod" ALSO "k,CL D3dozod\0"
;     "SS\0" " 36+\0"
;     "STC\0" " F9\0"
;     "STD\0" " FD\0"
;     "STI\0" " FB\0"
;     "STOSB\0" " AA\0"
;     "STOSW\0" " AB\0"
;     "SUB\0" "j,q 28drd" ALSO "k,r 29drd" ALSO "q,j 2Adrd" ALSO "r,k 2Bdrd" ALSO "vAL,h 2Ci" ALSO "wAX,g 2Dj" ALSO "m,s sdozodj" ALSO "l,t 80dozodi\0"
;     "TEST\0" "j,q 84drd" ALSO "q,j 84drd" ALSO "k,r 85drd" ALSO "r,k 85drd" ALSO "vAL,h A8i" ALSO "wAX,i A9j" ALSO "m,u F7dzzzdj" ALSO "l,t F6dzzzdi\0"
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
		db 'ES', 0, ' 26+', 0
		db 'HLT', 0, ' F4', 0
		db 'IDIV', 0, 'l F6doood', ALSO, 'm F7doood', 0
		db 'IMUL', 0, 'l F6dozod', ALSO, 'm F7dozod', 0
		db 'IN', 0, 'vAL,wDX EC', ALSO, 'wAX,wDX ED', ALSO, 'vAL,h E4i', ALSO, 'wAX,i E5i', 0
		db 'INC', 0, 'r zozzzr', ALSO, 'l FEdzzzd', ALSO, 'm FFdzzzd', 0
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
		db 'LES', 0, 'r,n C4drd', 0
		db 'LOCK', 0, ' F0+', 0
		db 'LODSB', 0, ' AC', 0
		db 'LODSW', 0, ' AD', 0
		db 'LOOP', 0, 'a E2a', 0
		db 'LOOPE', 0, 'a E1a', 0
		db 'LOOPNE', 0, 'a E0a', 0
		db 'LOOPNZ', 0, 'a E0a', 0
		db 'LOOPZ', 0, 'a E1a', 0
		db 'MOV', 0, 'j,q 88drd', ALSO, 'k,r 89drd', ALSO, 'q,j 8Adrd', ALSO, 'r,k 8Bdrd', ALSO, 'k,ES 8Cdzzzd', ALSO, 'k,CS 8Cdzzod', ALSO
		    db 'k,SS 8Cdzozd', ALSO, 'k,DS 8Cdzood', ALSO, 'ES,k 8Edzzzd', ALSO, 'CS,k 8Edzzod', ALSO, 'SS,k 8Edzozd', ALSO, 'DS,k 8Edzood', ALSO
		    db 'q,h ozoozri', ALSO, 'r,i ozooorj', ALSO, 'm,u C7dzzzdj', ALSO, 'l,t C6dzzzdi', 0
		db 'MOVSB', 0, ' A4', 0
		db 'MOVSW', 0, ' A5', 0
		db 'MUL', 0, 'l F6dozzd', ALSO, 'm F7dozzd', 0
		db 'NEG', 0, 'l F6dzood', ALSO, 'm F7dzood', 0
		db 'NOP', 0, ' 90', 0
		db 'NOT', 0, 'l F6dzozd', ALSO, 'm F7dzozd', 0
		db 'OR', 0, 'j,q 08drd', ALSO, 'k,r 09drd', ALSO, 'q,j 0Adrd', ALSO, 'r,k 0Bdrd', ALSO, 'vAL,h 0Ci', ALSO, 'wAX,g 0Dj', ALSO, 'm,s sdzzodj', ALSO, 'l,t 80dzzodi', 0
		db 'OUT', 0, 'wDX,vAL EE', ALSO, 'wDX,AX EF', ALSO, 'h,vAL E6i', ALSO, 'i,AX E7i', 0
		db 'PAUSE', 0, ' F390', 0
		db 'POP', 0, 'ES 07', ALSO, 'SS 17', ALSO, 'DS 1F', ALSO, 'r zozoor', ALSO, 'k 8Fdzzzd', 0
		db 'POPF', 0, ' 9D', 0
		db 'PUSH', 0, 'ES 06', ALSO, 'CS 0E', ALSO, 'SS 16', ALSO, 'DS 1E', ALSO, 'r zozozr', ALSO, 'k FFdoozd', 0
		db 'PUSHF', 0, ' 9C', 0
		db 'RCL', 0, 'j,1 D0dzozd', ALSO, 'k,1 D1dzozd', ALSO, 'j,CL D2dzozd', ALSO, 'k,CL D3dzozd', 0
		db 'RCR', 0, 'j,1 D0dzood', ALSO, 'k,1 D1dzood', ALSO, 'j,CL D2dzood', ALSO, 'k,CL D3dzood', 0
		db 'REP', 0, ' F3+', 0
		db 'REPE', 0, ' F3+', 0
		db 'REPNE', 0, ' F2+', 0
		db 'REPNZ', 0, ' F2+', 0
		db 'REPZ', 0, ' F3+', 0
		db 'RET', 0, 'i C2j', ALSO, ' C3', 0
		db 'RETF', 0, 'i CAj', ALSO, ' CB', 0
		db 'ROL', 0, 'j,1 D0dzzzd', ALSO, 'k,1 D1dzzzd', ALSO, 'j,CL D2dzzzd', ALSO, 'k,CL D3dzzzd', 0
		db 'ROR', 0, 'j,1 D0dzzod', ALSO, 'k,1 D1dzzod', ALSO, 'j,CL D2dzzod', ALSO, 'k,CL D3dzzod', 0
		db 'SAHF', 0, ' 9E', 0
		db 'SAR', 0, 'j,1 D0doood', ALSO, 'k,1 D1doood', ALSO, 'j,CL D2doood', ALSO, 'k,CL D3doood', 0
		db 'SBB', 0, 'j,q 18drd', ALSO, 'k,r 19drd', ALSO, 'q,j 1Adrd', ALSO, 'r,k 1Bdrd', ALSO, 'vAL,h 1Ci', ALSO, 'wAX,g 1Dj', ALSO, 'm,s sdzoodj', ALSO, 'l,t 80dzoodi', 0
		db 'SCASB', 0, ' AE', 0
		db 'SCASW', 0, ' AF', 0
		db 'SHL', 0, 'j,1 D0dozzd', ALSO, 'k,1 D1dozzd', ALSO, 'j,CL D2dozzd', ALSO, 'k,CL D3dozzd', 0
		db 'SHR', 0, 'j,1 D0dozod', ALSO, 'k,1 D1dozod', ALSO, 'j,CL D2dozod', ALSO, 'k,CL D3dozod', 0
		db 'SS', 0, ' 36+', 0
		db 'STC', 0, ' F9', 0
		db 'STD', 0, ' FD', 0
		db 'STI', 0, ' FB', 0
		db 'STOSB', 0, ' AA', 0
		db 'STOSW', 0, ' AB', 0
		db 'SUB', 0, 'j,q 28drd', ALSO, 'k,r 29drd', ALSO, 'q,j 2Adrd', ALSO, 'r,k 2Bdrd', ALSO, 'vAL,h 2Ci', ALSO, 'wAX,g 2Dj', ALSO, 'm,s sdozodj', ALSO, 'l,t 80dozodi', 0
		db 'TEST', 0, 'j,q 84drd', ALSO, 'q,j 84drd', ALSO, 'k,r 85drd', ALSO, 'r,k 85drd', ALSO, 'vAL,h A8i', ALSO, 'wAX,i A9j', ALSO, 'm,u F7dzzzdj', ALSO, 'l,t F6dzzzdi', 0
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

_line_buf	resb 0x200
_assembly_stack	resb 0x200
_message_buf	resb 0x200
_emit_buf	resb 0x200
_generated	resb 8
_wide_instr_read_block resb 4
_wide_instr_last_block resb 4
_wide_instr_first_block resb 4
_wide_instr_add_block_end resb 4
_wide_instr_add_at resb 4
_wide_instr_read_at resb 4
_label_list	resb 4
_bytes		resb 4
_instruction_value resb 4
_current_address resb 4
_errors		resb 4
_start_address	resb 4
_line_number	resb 4
_default_start_address resb 4
_instr_name	resb 10
___malloc_struct__ resb 6
_assembly_p	resb 2
_filename_for_message resb 2
_global_label_end resb 2
_g		resb 2
_generated_ptr	resb 2
_instruction_offset resb 2
_assembler_pass	resb 2
_output_fd	resb 2
_output_filename resb 2
_global_label	resb 0x200 - 3
_has_macros	resb 1
_was_strict	resb 1
_has_undefined	resb 1
_have_labels_changed resb 1
_do_opt_lea	resb 1
_instruction_addressing_segment resb 1
_is_address_used resb 1
_is_start_address_set resb 1
_instruction_offset_width resb 1
_instruction_register resb 1
_opt_level	resb 1
_do_opt_segreg	resb 1
_instruction_addressing resb 1
_size_decrease_count resb 1
@$967		resb 2  ; static struct tree_path_entry path[RB_LOG2_MAX_NODES << 1];
@$968		resb 202  ; Continuation of path above.
@$969		resb 600  ; static struct match_stack_item { ... } match_stack[CONFIG_MATCH_STACK_DEPTH];
@$970		resb 2  ; segment_value.

; --- Uninitialized .bss used by _start.    ___section_startup_ubss:
___section_startup_ubss:

argv_bytes	resb 270
argv_pointers	resb 130

___section_ubss_end:

___initial_sp	equ ___section_startup_text+((___section_ubss_end-___section_bss+___section_nobss_end-___section_startup_text+___stack_size+1)&~1)  ; Word-align stack for speed.
___sd_top__	equ 0x10+((___initial_sp-___section_startup_text+0xf)>>4)  ; Round top of stack to next para, use para (16-byte).

; __END__
