;
; minnoasm.nasm: non-self-hosting, NASM-compatible assembler for DOS 8086, targeting 8086
; by pts@fazekas.hu at Fri Nov  4 19:44:03 CET 2022
;
; minonasm.nasm is a non-self-hosting source code version of minnnasm.nasm:
; it can be compiled by mininasm, but not minnnasm, and it should produce an
; bit-by-bit identical executable binary (minnnasm.com and minonasm.com).
; It can be used for testing new features of mininasm.
;
; This version of minonasm.com (15341 bytes) is equivalent to mininasm.com in
; https://github.com/pts/mininasm/blob/2ea02b8b7dd1c1d451a0ee8bc691170825794ef9/mininasm.c
; It's not bit-by-bit identical, because the OpenWatcom C compiler, WASM and
; NASM generate different but equivalent machine code.
;

bits 16
cpu 8086
org 0x100  ; DOS .com file is loaded at CS:0x100.

; --- Startup code.
;
; Based on https://github.com/pts/dosmc/blob/f716c6cd9ec8947e72f1f7ad7c746d8c5d28acc4/dosmc.dir/dosmc.pl#L1141-L1187
___section_startup_text:

___stack_size	equ 0x200  ; To estimate, specify -sc to dosmc (mininasm.c), and run it to get the `max st:HHHH' value printed, and round up 0xHHHH to here. Typical value: 0x200.

___0100:
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

___section_mininasm_c_text:

; --- bbprintf.h
;
; struct bbprintf_buf {
;   char *buf, *buf_end, *p;
;   void *data;  /* Used by bbb.flush. */
;   void (*flush)(struct bbprintf_buf *bbb);
; };
;
; int bbprintf(struct bbprintf_buf *bbb, const char *format, ...);
;
; /* out must not be NULL. */
; int bbsprintf(char *out, const char *format, ...);
;
; /* out must not be NULL. size must be >= 1. */
; int bbsnprintf(char *out, int size, const char *format, ...);
;
; void bbwrite1(struct bbprintf_buf *bbb, int c);

___0184:

; %include 'mininasm_text.nasm'

; /*
;  ** mininasm: NASM-compatible mini assembler for 8086, able to run on DOS and on modern systems
;  ** mininasm modifications by pts@fazekas.hu at Wed May 18 21:39:36 CEST 2022
;  **
;  ** based on Tinyasm by Oscar Toledo G, starting Oct/01/2019.
;  **
;  ** Compilation instructions (pick any one):
;  **
;  **   $ gcc -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o mininasm mininasm.c bbprintf.c && ls -ld mininasm
;  **
;  **   $ gcc -m32 -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o mininasm mininasm.c bbprintf.c && ls -ld mininasm.gcc32
;  **
;  **   $ g++ -ansi -pedantic -s -Os -W -Wall -o mininasm mininasm.c bbprintf.c && ls -ld mininasm
;  **
;  **   $ pts-tcc -s -O2 -W -Wall -o mininasm.tcc mininasm.c bbprintf.c && ls -ld mininasm.tcc
;  **
;  **   $ pts-tcc64 -m64 -s -O2 -W -Wall -o mininasm.tcc64 mininasm.c bbprintf.c && ls -ld mininasm.tcc64
;  **
;  **   $ dosmc -mt mininasm.c bbprintf.c && ls -ld mininasm.com
;  **
;  **   $ owcc -bdos -o mininasm.exe -mcmodel=c -Os -s -fstack-check -Wl,option -Wl,stack=1800 -march=i86 -W -Wall -Wextra mininasm.c bbprintf.c && ls -ld mininasm.exe
;  **
;  **   $ owcc -bwin32 -Wl,runtime -Wl,console=3.10 -o mininasm.win32.exe -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm.c bbprintf.c nouser32.c && ls -ld mininasm.win32.exe
;  **
;  **   $ i686-w64-mingw32-gcc -m32 -mconsole -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -march=i386 -o mininasm.win32msvcrt.exe mininasm.c bbprintf.c && ls -ld mininasm.win32msvcrt.exe
;  **
;  **   $ wine tcc.exe -m32 -mconsole -s -O2 -W -Wall -o mininasm.win32msvcrt_tcc.exe mininasm.c bbprintf.c && ls -ld mininasm.win32msvcrt_tcc.exe
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
; int __cdecl tolower(int c);
; int __cdecl toupper(int c);
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
; #      define creat(filename, mode) open(filename, O_CREAT | O_TRUNC | O_WRONLY | O_BINARY, 0)  \
; #          /* 0 to prevent Wine msvcrt.dll warning: `fixme:msvcrt:MSVCRT__wsopen_s : pmode 0x406b9b ignored.'. Also works with `owcc -bwin32' (msvcrtl.dll) and `owcc -bdos'. */
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
; #if !defined(CONFIG_CPU_UNALIGN)
; #if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__) || defined(_M_IX86) || defined(__i386__)
; #define CONFIG_CPU_UNALIGN 1  /* CPU supports unaligned memory access. i386 and amd64 do, arm and arm64 don't.  */
; #else
; #define CONFIG_CPU_UNALIGN 0
; #endif
; #endif
;
; #if !defined(CONFIG_SHIFT_OK_31)
; #if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__) || defined(_M_IX86) || defined(__i386__)
; #define CONFIG_SHIFT_OK_31 1  /* `x << 31' and `x >> 31' works in C. */
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
; #if CONFIG_BALANCED
; __LINKER_FLAG(stack_size__0x200)  /* Extra memory needed by balanced_tree_insert. */
; #endif
; __LINKER_FLAG(stack_size__0x180)  /* Specify -sc to dosmc, and run it to get the `max st:HHHH' value printed, and round up 0xHHHH to here. Typical value: 0x134. */
; /* Below is a simple malloc implementation using an arena which is never
;  * freed. Blocks are rounded up to paragraph (16-byte) boundary.
;  */
; #ifndef __MOV_AX_PSP_MCB__
; #error Missing __MOV_AX_PSP_MCB__, please compile .c file with dosmc directly.
; #endif
; struct {
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
; /* strcpy_far(...) and strcmp_far(...) are defined in <dosmc.h>. */
; #else  /* CONFIG_DOSMC. */
; #define MY_FAR
; #define strcpy_far(dest, src) strcpy(dest, src)
; #define strcmp_far(s1, s2) strcmp(s1, s2)
; #define malloc_far(size) malloc(size)
; #define malloc_init() do {} while (0)
; #if CONFIG_DOSMC_PACKED
; #error CONFIG_DOSMC_PACKED needs __DOSMC__.
; #endif
; #endif  /* Else CONFIG_DOSMC. */
;
; #include "bbprintf.h"
;
; /* Example usage:
;  * static const STRING_WITHOUT_NUL(msg, "Hello, World!\r\n$");
;  * ... printmsgx(msg);
;  */
; #ifdef __cplusplus  /* We must reserve space for the NUL. */
; #define MY_STRING_WITHOUT_NUL(name, value) char name[sizeof(value)] = value
; #else
; #define MY_STRING_WITHOUT_NUL(name, value) char name[sizeof(value) - 1] = value
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
; #define DEBUG
;
; char *output_filename;
; int output_fd;
;
; char *listing_filename;
; int listing_fd = -1;
;
; #ifndef CONFIG_VALUE_BITS
; #define CONFIG_VALUE_BITS 32
; #endif
;
; #undef IS_VALUE_LONG
; #if CONFIG_VALUE_BITS == 16
; #define IS_VALUE_LONG 0
; typedef short value_t;  /* At least CONFIG_VALUE_BITS bits, preferably exactly. */
; typedef unsigned short uvalue_t;  /* At least CONFIG_VALUE_BITS bits, preferably exactly. */
; #define GET_VALUE(value) (value_t)(sizeof(short) == 2 ? (short)(value) : (short)(((short)(value) & 0x7fff) | -((short)(value) & 0x8000U)))  /* Sign-extended. */
; #define GET_UVALUE(value) (uvalue_t)(sizeof(unsigned short) == 2 ? (unsigned short)(value) : (unsigned short)(value) & 0xffffU)
; #else
; #if CONFIG_VALUE_BITS == 32
; #if __SIZEOF_INT__ >= 4
; #define IS_VALUE_LONG 0
; typedef int value_t;
; typedef unsigned uvalue_t;
; #else  /* sizeof(long) >= 4 is guaranteed by the C standard. */
; #define IS_VALUE_LONG 1
; typedef long value_t;
; typedef unsigned long uvalue_t;
; #endif
; #define GET_VALUE(value) (value_t)(sizeof(value_t) == 4 ? (value_t)(value) : sizeof(int) == 4 ? (value_t)(int)(value) : sizeof(long) == 4 ? (value_t)(long)(value) : (value_t)(((long)(value) & 0x7fffffffL) | -((long)(value) & 0x80000000UL)))
; #define GET_UVALUE(value) (uvalue_t)(sizeof(uvalue_t) == 4 ? (uvalue_t)(value) : sizeof(unsigned) == 4 ? (uvalue_t)(unsigned)(value) : sizeof(unsigned long) == 4 ? (uvalue_t)(unsigned long)(value) : (uvalue_t)(value) & 0xffffffffUL)
; #else
; #error CONFIG_VALUE_BITS must be 16 or 32.
; #endif
; #endif
; typedef char assert_value_size[sizeof(value_t) * 8 >= CONFIG_VALUE_BITS];
;
; uvalue_t line_number;
;
; int assembler_step;  /* !! Change many variables from int to char. */
; value_t default_start_address;
; value_t start_address;
; value_t address;
; int first_time;
;
; unsigned char instruction_addressing;
; unsigned char instruction_offset_width;
; value_t instruction_offset;
;
; unsigned char instruction_register;
;
; value_t instruction_value;
;
; #define MAX_SIZE        256
;
; char part[MAX_SIZE];
; char name[MAX_SIZE];
; char expr_name[MAX_SIZE];
; char global_label[MAX_SIZE];
;
; char *g;
; char generated[8];
;
; uvalue_t errors;
; uvalue_t warnings;  /* !! remove this, currently there are no possible warnings */
; uvalue_t bytes;
; int change;
; int change_number;
;
; #if CONFIG_DOSMC_PACKED
; _Packed  /* Disable extra aligment byte at the end of `struct label'. */
; #endif
; struct label {
; #if CONFIG_DOSMC_PACKED
;     /* The fields .left_right_ofs, .left_seg and .right_seg together contain
;      * 2 far pointers (tree_left and tree_right) and (if CONFIG_BALANCED is
;      * true) the tree_red bit. .left_seg contains the 16-bit segment part of
;      * tree_left, and .right_seg contains the 16-bit segment part of
;      * tree_right. .left_right_ofs contains the offset of the far pointers
;      * and the tree_red bit. It is assumed that far pointer offsets are 4
;      * bits wide (0 <= offset <= 15), because malloc_far guarantees it
;      * (with its and `and ax, 0fh' instruction).
;      *
;      * If CONFIG_BALANCED is false, bits of .left_right_ofs look like
;      * LLLLRRRR, where LLLL is the 4-bit offset of tree_left, and RRRR is the
;      * 4-bit offset of tree_right.
;      *
;      * If CONFIG_BALANCED is true, bits of .left_right_ofs look like
;      * LLL1RRRE, where LLLM is the 4-bit offset of tree_left, RRRS is the
;      * 4-bit offset of tree_right, 1 is 1, E is the tree_red bit value.
;      * The lower M and S bits of the offsets are not stored, but they will
;      * be inferred like below. The pointer with the offset LLL0 is either
;      * correct or 1 less than the correct LLL1. If it's correct, then it points
;      * to a nonzero .left_right_ofs (it has a 1 bit). If it's 1 less, then it
;      * points to the all-zero NUL byte (the NUL terminator of the name in the
;      * previous label). Thus by comparing the byte at offset LLL0 to zero,
;      * we can infer whether M is 0 or 1. For this to work we
;      * need that the very first struct label starts at an even offset; this
;      * is guaranteed by malloc_far.
;      */
;     unsigned char left_right_ofs;
;     unsigned left_seg, right_seg;
; #else
;     struct label MY_FAR *tree_left;
;     struct label MY_FAR *tree_right;
; #endif
;     value_t value;
; #if CONFIG_BALANCED && !CONFIG_DOSMC_PACKED
;     char tree_red;  /* Is it a red node of the red-black tree? */
; #endif
;     char name[1];
; };
;
; struct label MY_FAR *label_list;
; struct label MY_FAR *last_label;
; int undefined;
;
; extern const char instruction_set[];
;
; /* [32] without the trailing \0 wouldn't work in C++. */
; const char register_names[] = "ALCLDLBLAHCHDHBHAXCXDXBXSPBPSIDI";
;
; extern struct bbprintf_buf message_bbb;
;
; void message(int error, const char *message);
; void message_start(int error);
; void message_end(void);
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
; typedef char assert_label_size[sizeof(struct label) == 5 /* left and right pointers, tree_red */ + sizeof(value_t) + 1 /* trailing NUL in ->name */];
; #define RBL_IS_NULL(label) (FP_SEG(label) == 0)
; #define RBL_IS_LEFT_NULL(label) ((label)->left_seg == 0)
; #define RBL_IS_RIGHT_NULL(label) ((label)->right_seg == 0)
; #if CONFIG_BALANCED
; #define RBL_SET_LEFT_RIGHT_NULL(label) ((label)->left_right_ofs = 0x10, (label)->left_seg = (label)->right_seg = 0)
; static struct label MY_FAR *RBL_GET_LEFT(struct label MY_FAR *label) {
RBL_GET_LEFT_:
		push bx
		push cx
		push si
		mov bx, ax
		mov es, dx

;     char MY_FAR *p = MK_FP((label)->left_seg, ((label)->left_right_ofs >> 4) & 0xe);
		es mov al, byte [bx]
		xor ah, ah
		mov cl, 4
		mov si, ax
		sar si, cl
		and si, BYTE 0xe
		es mov es, word [bx+1]
		mov ax, si
		mov dx, es

;     if (*p == '\0') ++p;  /* Skip trailing NUL of previous label. */
		es cmp byte [si], 0
		jne @$1
		lea ax, [si+1]
@$1:
		jmp @$30

;     return (struct label MY_FAR*)p;
; }
; static struct label MY_FAR *RBL_GET_RIGHT(struct label MY_FAR *label) {
RBL_GET_RIGHT_:
		push bx
		push si
		mov bx, ax
		mov es, dx

;     char MY_FAR *p = MK_FP((label)->right_seg, (label)->left_right_ofs & 0xe);
		es mov al, byte [bx]
		and al, 0xe
		xor ah, ah
		es mov es, word [bx+3]
		mov bx, ax
		mov dx, es

;     if (*p == '\0') ++p;  /* Skip trailing NUL of previous label. */
		mov si, ax
		es cmp byte [si], 0
		jne @$2
		inc bx

;     return (struct label MY_FAR*)p;
; }
@$2:
		mov ax, bx
		pop si
		pop bx
		ret

; static void RBL_SET_LEFT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
RBL_SET_LEFT_:
		push si
		mov si, ax
		mov es, dx

;     label->left_seg = FP_SEG(ptr);
		es mov word [si+1], cx

;     label->left_right_ofs = (label->left_right_ofs & 0x1f) | (FP_OFF(ptr) & 0xe) << 4;  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
		and bx, BYTE 0xe
		mov cl, 4
		shl bx, cl
		es mov cl, byte [si]
		and cl, 0x1f
		xor ch, ch
		or bx, cx
		es mov byte [si], bl

; }
		pop si
		ret

; static void RBL_SET_RIGHT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
RBL_SET_RIGHT_:
		push si
		mov si, ax
		mov es, dx

;     label->right_seg = FP_SEG(ptr);
		es mov word [si+3], cx

;     label->left_right_ofs = (label->left_right_ofs & 0xf1) | (FP_OFF(ptr) & 0xe);  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
		es mov al, byte [si]
		and al, 0xf1
		and bl, 0xe
		or al, bl
		es mov byte [si], al

; }
		pop si
		ret

; #define RBL_IS_RED(label) ((label)->left_right_ofs & 1)  /* Nonzero means true. */
; #define RBL_COPY_RED(label, source_label) ((label)->left_right_ofs = ((label)->left_right_ofs & 0xfe) | ((source_label)->left_right_ofs & 1))
; #define RBL_SET_RED_0(label) ((label)->left_right_ofs &= 0xfe)
; #define RBL_SET_RED_1(label) ((label)->left_right_ofs |= 1)
; #else  /* Else CONFIG_BALANCED. */
; #define RBL_SET_LEFT_RIGHT_NULL(label) ((label)->left_right_ofs = (label)->left_seg = (label)->right_seg = 0)
; static struct label MY_FAR *RBL_GET_LEFT(struct label MY_FAR *label) {
;     char MY_FAR *p = MK_FP((label)->left_seg, (label)->left_right_ofs >> 4);
;     return (struct label MY_FAR*)p;
; }
; static struct label MY_FAR *RBL_GET_RIGHT(struct label MY_FAR *label) {
;     char MY_FAR *p = MK_FP((label)->right_seg, (label)->left_right_ofs & 0xf);
;     return (struct label MY_FAR*)p;
; }
; static void RBL_SET_LEFT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
;     label->left_seg = FP_SEG(ptr);
;     label->left_right_ofs = (label->left_right_ofs & 0x0f) | FP_OFF(ptr) << 4;  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
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
; #if CONFIG_BALANCED
; #define RBL_IS_RED(label) ((label)->tree_red)  /* Nonzero means true. */
; #define RBL_COPY_RED(label, source_label) ((label)->tree_red = (source_label)->tree_red)
; #define RBL_SET_RED_0(label) ((label)->tree_red = 0)
; #define RBL_SET_RED_1(label) ((label)->tree_red = 1)
; #endif  /* CONFIG_BALANCED. */
; #endif  /* CONFIG_DOSMC_PACKED. */
;
; /*
;  ** Define a new label
;  */
; struct label MY_FAR *define_label(char *name, value_t value) {
define_label_:
		push si
		push di
		push bp
		mov bp, sp
		sub sp, BYTE 0x14
		mov di, ax
		mov word [bp-0x10], cx

;     struct label MY_FAR *label;
;
;     /* Allocate label */
;     label = (struct label MY_FAR*)malloc_far((size_t)&((struct label*)0)->name + 1 + strlen(name));
		call near strlen_
		db 0x83, 0xC0, 0xa  ; !!! add ax, BYTE 0xa
		mov cl, 4
		mov si, ___malloc_struct__+2
		add ax, word [si]
		mov dx, ax
		db 0x83, 0xE0, 0xf  ; !!! and ax, BYTE 0xf
		shr dx, cl
		add dx, word [si+2]
		cmp dx, word [si-2]
		ja @$3
		jb @$4
		test ax, ax
		je @$4
@$3:
		xor ax, ax
		xor dx, dx
		jmp SHORT @$5
@$4:
		xchg word [si], ax
		xchg word [si+2], dx
@$5:
		mov word [bp-6], ax
		mov word [bp-4], dx

;     if (RBL_IS_NULL(label)) {
		test dx, dx
		jne @$6

;         message(1, "Out of memory for label");
		mov dx, @$527
		mov ax, 1
		call near message_

;         exit(1);
		mov ax, 1
		mov ah, 0x4c
		int 0x21

;         return NULL;
;     }
;
;     /* Fill label */
;     RBL_SET_LEFT_RIGHT_NULL(label);
@$6:
		les si, [bp-6]
		es mov byte [si], 0x10
		es mov word [si+3], 0
		es mov ax, word [si+3]
		es mov word [si+1], ax

;     label->value = value;
		es mov word [si+5], bx
		mov ax, word [bp-0x10]
		mov bx, si
		es mov word [bx+7], ax

;     strcpy_far(label->name, name);
		mov cx, ds
		lea ax, [si+9]
		mov bx, di
		mov dx, es
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
		mov bx, si
		es or byte [bx], 1

;         path->label = label_list;
		mov ax, [_label_list]  ; !!! mov ax, word [_label_list]
		mov dx, word [_label_list+2]
		mov [@$617], ax  ; !!! mov word [@$617], ax
		mov word [@$618], dx

;         for (pathp = path; !RBL_IS_NULL(pathp->label); pathp++) {
		mov si, @$617
@$7:
		mov bx, word [si]
		mov cx, word [si+2]
		test cx, cx
		je @$12

;             const char less = pathp->less = strcmp_far(label->name, pathp->label->name) < 0;
		add bx, BYTE 9
		mov ax, word [bp-6]
		db 0x83, 0xC0, 9  ; !!! add ax, BYTE 9
		mov dx, word [bp-4]
		call near strcmp_far_
		test ax, ax
		jge @$8
		mov dl, 1
		jmp SHORT @$9
@$8:
		xor dl, dl
@$9:
		mov byte [si+4], dl

;             pathp[1].label = less ? RBL_GET_LEFT(pathp->label) : RBL_GET_RIGHT(pathp->label);
		test dl, dl
		je @$10
		mov ax, word [si]
		mov dx, word [si+2]
		call near RBL_GET_LEFT_
		jmp SHORT @$11
@$10:
		mov ax, word [si]
		mov dx, word [si+2]
		call near RBL_GET_RIGHT_
@$11:
		mov word [si+6], ax
		mov word [si+8], dx

;         }
		add si, BYTE 6
		jmp SHORT @$7

;         pathp->label = label;
@$12:
		mov bx, word [bp-6]
		mov word [si], bx
		mov ax, word [bp-4]
@$13:
		mov word [si+2], ax

;         while (pathp-- != path) {
		mov ax, si
		sub si, BYTE 6
		cmp ax, @$617
		jne @$14
		jmp @$21

;             struct label MY_FAR *clabel = pathp->label;
@$14:
		mov di, word [si]
		mov ax, word [si+2]
		mov word [bp-2], ax

;             if (pathp->less) {
		cmp byte [si+4], 0
		je @$17

;                 struct label MY_FAR *left = pathp[1].label;
		mov bx, word [si+6]
		mov word [bp-0xe], bx
		mov ax, word [si+8]
		mov word [bp-0xa], ax

;                 RBL_SET_LEFT(clabel, left);
		mov cx, ax
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_SET_LEFT_

;                 if (RBL_IS_RED(left)) {
		mov es, word [bp-0xa]
		mov bx, word [bp-0xe]
		es test byte [bx], 1
		je @$15

;                     struct label MY_FAR *leftleft = RBL_GET_LEFT(left);
		mov ax, bx
		mov dx, es
		call near RBL_GET_LEFT_
		mov bx, ax
		mov es, dx

;                     if (!RBL_IS_NULL(leftleft) && RBL_IS_RED(leftleft)) {
		test dx, dx
		je @$16
		es test byte [bx], 1
		je @$16

;                         struct label MY_FAR *tlabel;
;                         RBL_SET_RED_0(leftleft);
		es and byte [bx], 0xfe

;                         tlabel = RBL_GET_LEFT(clabel);
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_GET_LEFT_
		mov word [bp-0x12], ax
		mov word [bp-0x14], dx

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
		mov ax, word [bp-0x12]
		mov dx, word [bp-0x14]
		call near RBL_SET_RIGHT_

;                         clabel = tlabel;
		mov di, word [bp-0x12]
		mov ax, word [bp-0x14]

;                     }
		jmp @$19
@$15:
		jmp @$22
@$16:
		jmp @$20

;                 } else {
;                     goto done;
;                 }
;             } else {
;                 struct label MY_FAR *right = pathp[1].label;
@$17:
		mov bx, word [si+6]
		mov word [bp-0xc], bx
		mov ax, word [si+8]
		mov word [bp-8], ax

;                 RBL_SET_RIGHT(clabel, right);
		mov cx, ax
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_SET_RIGHT_

;                 if (RBL_IS_RED(right)) {
		mov es, word [bp-8]
		mov bx, word [bp-0xc]
		es test byte [bx], 1
		je @$15

;                     struct label MY_FAR *left = RBL_GET_LEFT(clabel);
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_GET_LEFT_
		mov bx, ax
		mov es, dx

;                     if (!RBL_IS_NULL(left) && RBL_IS_RED(left)) {
		test dx, dx
		je @$18
		es test byte [bx], 1
		je @$18

;                          RBL_SET_RED_0(left);
		es and byte [bx], 0xfe

;                          RBL_SET_RED_0(right);
		mov es, word [bp-8]
		mov bx, word [bp-0xc]
		es and byte [bx], 0xfe

;                          RBL_SET_RED_1(clabel);
		mov es, word [bp-2]
		es or byte [di], 1

;                      } else {
		jmp SHORT @$20

;                          struct label MY_FAR *tlabel;
;                          tlabel = RBL_GET_RIGHT(clabel);
@$18:
		mov ax, di
		mov dx, word [bp-2]
		call near RBL_GET_RIGHT_
		mov word [bp-0x14], ax
		mov word [bp-0x12], dx

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
		mov ax, word [bp-0x14]
		mov dx, word [bp-0x12]
		call near RBL_SET_LEFT_

;                          RBL_COPY_RED(tlabel, clabel);
		les bx, [bp-0x14]
		es mov ah, byte [bx]
		and ah, 0xfe
		mov es, word [bp-2]
		es mov al, byte [di]
		and al, 1
		or ah, al
		mov es, word [bp-0x12]
		es mov byte [bx], ah

;                          RBL_SET_RED_1(clabel);
		mov es, word [bp-2]
		es or byte [di], 1

;                          clabel = tlabel;
		mov di, bx
		mov ax, word [bp-0x12]
@$19:
		mov word [bp-2], ax

;                      }
;                 } else {
;                     goto done;
;                 }
;             }
;             pathp->label = clabel;
@$20:
		mov word [si], di
		mov ax, word [bp-2]

;         }
		jmp @$13

;         label_list = path->label;
@$21:
		mov bx, word [@$617]
		mov dx, word [@$618]
		mov word [_label_list], bx
		mov word [_label_list+2], dx

;         RBL_SET_RED_0(label_list);
		mov es, dx
		es and byte [bx], 0xfe

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
; }
@$22:
		mov ax, word [bp-6]
		mov dx, word [bp-4]
		mov sp, bp
		pop bp
		pop di
		pop si
		ret

;
; /*
;  ** Find a label
;  */
; struct label MY_FAR *find_label(const char *name) {
find_label_:
		push bx
		push cx
		push si
		push di
		push bp
		mov bp, sp
		push ax

;     struct label MY_FAR *explore;
;     int c;
;
;     /* Follows a binary tree */
;     explore = label_list;
		mov di, word [_label_list]
		mov si, word [_label_list+2]
		jmp SHORT @$25

;     while (!RBL_IS_NULL(explore)) {
;         c = strcmp_far(name, explore->name);
;         if (c == 0)
;             return explore;
@$23:
		jge @$26

;         if (c < 0)
;             explore = RBL_GET_LEFT(explore);
		mov ax, di
		mov dx, si
		call near RBL_GET_LEFT_
@$24:
		mov di, ax
		mov si, dx

;         else
@$25:
		test si, si
		je @$27
		lea bx, [di+9]
		mov dx, ds
		mov cx, si
		mov ax, word [bp-2]
		call near strcmp_far_
		test ax, ax
		jne @$23
		jmp SHORT @$28

;             explore = RBL_GET_RIGHT(explore);
@$26:
		mov ax, di
		mov dx, si
		call near RBL_GET_RIGHT_
		jmp SHORT @$24

;     }
;     return NULL;
@$27:
		xor di, di

; }
@$28:
		mov ax, di
		mov dx, si
@$29:
		mov sp, bp
		pop bp
		pop di
@$30:
		pop si
		pop cx
		pop bx
		ret

;
; /*
;  ** Print labels sorted to listing_fd (already done by binary tree).
;  */
; void print_labels_sorted_to_listing_fd(struct label MY_FAR *node) {
print_labels_sorted_to_listing_fd_:
		push bx
		push cx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		push ax
@$31:
		mov si, ax
		mov word [bp-2], dx

;     struct label MY_FAR *pre;
;     struct label MY_FAR *pre_right;
;     /* Morris in-order traversal of binary tree: iterative (non-recursive,
;      * so it uses O(1) stack), modifies the tree pointers temporarily, but
;      * then restores them, runs in O(n) time.
;      */
;     while (!RBL_IS_NULL(node)) {
		mov ax, word [bp-2]
		test ax, ax
		je @$29

;         if (RBL_IS_LEFT_NULL(node)) goto do_print;
		mov es, ax
		es cmp word [si+1], BYTE 0
		je @$35

;         for (pre = RBL_GET_LEFT(node); pre_right = RBL_GET_RIGHT(pre), !RBL_IS_NULL(pre_right) && pre_right != node; pre = pre_right) {}
		mov ax, si
		mov dx, es
		call near RBL_GET_LEFT_
@$32:
		mov word [bp-4], ax
		mov di, dx
		mov ax, word [bp-4]
		mov dx, di
		call near RBL_GET_RIGHT_
		mov bx, dx
		test dx, dx
		je @$33
		cmp dx, word [bp-2]
		jne @$32
		cmp ax, si
		jne @$32

;         if (RBL_IS_NULL(pre_right)) {
@$33:
		test bx, bx
		jne @$34

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

;         } else {
		jmp SHORT @$31

;             RBL_SET_RIGHT(pre, NULL);
@$34:
		xor bx, bx
		xor cx, cx
		mov ax, word [bp-4]
		mov dx, di
		call near RBL_SET_RIGHT_

;           do_print:
;             strcpy_far(global_label, node->name);
@$35:
		lea bx, [si+9]
		mov cx, word [bp-2]
		mov ax, _global_label
		mov dx, ds
		call near strcpy_far_

; #if CONFIG_VALUE_BITS == 32
; #if IS_VALUE_LONG
;             bbprintf(&message_bbb, "%-20s %04x%04x\r\n", global_label, (unsigned)(GET_UVALUE(node->value) >> 16), (unsigned)(GET_UVALUE(node->value) & 0xffffu));
		mov es, word [bp-2]
		es mov ax, word [si+5]
		push ax
		es mov ax, word [si+7]
		push ax
		mov ax, _global_label
		push ax
		mov ax, @$528
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 0xa

; #else
;             bbprintf(&message_bbb, "%-20s %08x\r\n", global_label, GET_UVALUE(node->value));
; #endif
; #else
;             bbprintf(&message_bbb, "%-20s %04x\r\n", global_label, GET_UVALUE(node->value));
; #endif
;             node = RBL_GET_RIGHT(node);
		mov ax, si
		mov dx, word [bp-2]
		call near RBL_GET_RIGHT_

;         }
		jmp @$31

;     }
; }
;
; /*
;  ** Avoid spaces in input
;  */
; const char *avoid_spaces(const char *p) {
avoid_spaces_:
		push bx
		mov bx, ax

;     while (isspace(*p))
@$36:
		mov al, byte [bx]
		xor ah, ah
		call near isspace_
		test ax, ax
		je @$37

;         p++;
		inc bx
		jmp SHORT @$36

;     return p;
; }
@$37:
		mov ax, bx
		pop bx
		ret

;
; #ifndef CONFIG_MATCH_STACK_DEPTH
; #define CONFIG_MATCH_STACK_DEPTH 100
; #endif
;
; /*
;  ** Match expression at match_p, update (increase) match_p or set it to NULL on error.
;  ** level == 0 is top tier, that's how callers should call near it.
;  ** Saves the result to `instruction_value'.
;  */
; const char *match_expression(const char *match_p) {
match_expression_:
		push bx
		push cx
		push dx
		push si
		push di
		push bp
		mov bp, sp
		sub sp, BYTE 0x10
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
;         struct label MY_FAR *label;
;     /*} u;*/
;     char c;
;     unsigned char level;
;
;     level = 0;
		mov byte [bp-2], 0

;     msp = match_stack;
		mov di, @$619

;     goto do_match;
@$38:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax
		xor ax, ax
		mov word [bp-0x10], ax
		mov word [bp-0xe], ax
		mov bx, dx
		mov al, byte [bx]
		mov byte [bp-4], al
		cmp al, 0x28
		jne @$41
@$39:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax
		mov al, byte [bx]
		mov byte [bp-4], al
		cmp al, 0x28
		jne @$45
		mov ax, word [bp-0xe]
		db 0x83, 0xF8, 0xff  ; !!! cmp ax, BYTE 0xffff
		jg @$40
		jne @$45
		; `| -0x1000' to prevent NASM warning: signed byte value exceeds bounds
		cmp word [bp-0x10], BYTE 0xff81 | -0x10000
		jbe @$45
@$40:
		lea si, [bx+1]
		add word [bp-0x10], BYTE -1
		adc word [bp-0xe], BYTE -1
		jmp SHORT @$39
@$41:
		jmp @$64

;   do_pop:
;     --msp;
;     value2 = value1;
@$42:
		mov cx, word [bp-0x10]
		mov ax, word [bp-0xe]
		mov word [bp-6], ax

		sub di, BYTE 6

;     value1 = msp->value1;
		mov ax, word [di+2]
		mov word [bp-0x10], ax
		mov ax, word [di+4]
		mov word [bp-0xe], ax

;     level = msp->level;
		mov al, byte [di+1]
		mov byte [bp-2], al

;     if (msp->casei < 0) {  /* End of expression in patentheses. */
		mov al, byte [di]
		test al, al
		jge @$48

;         value1 = value2;
		mov word [bp-0x10], cx
		mov ax, word [bp-6]
		mov word [bp-0xe], ax

;         match_p = avoid_spaces(match_p);
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;         if (match_p[0] != ')') {
		cmp byte [si], 0x29
		je @$46

;             message(1, "Missing close paren");
		mov dx, @$529
@$43:
		mov ax, 1
		call near message_

;           match_error:
;             instruction_value = 0;
@$44:
		xor ax, ax
		mov [_instruction_value], ax  ; !!! no word [...]
		mov [_instruction_value+2], ax  ; !!! no word [...]

;             return NULL;
		jmp @$160
@$45:
		jmp near @$53

;         }
;         match_p++;
@$46:
		inc si

;         if (++msp->casei != 0) {
		inc byte [di]
		je @$47

;             level = 0;
		mov byte [bp-2], 0
		mov ax, @$620

;             if (++msp == match_stack + sizeof(match_stack) / sizeof(match_stack[0])) goto too_deep;
		add di, BYTE 6
		cmp di, ax
		je @$51
@$47:
		jmp @$108

;         }
;         goto have_value1;
;     }
; #define MATCH_CASEI_LEVEL_TO_VALUE2(casei2, level2) do { msp->casei = casei2; msp->level = level; level = level2; goto do_push; case casei2: ; } while (0)
;     switch (msp->casei) {  /* This will jump after one of the MATCH_CASEI_LEVEL_TO_VALUE2(...) macros. */
@$48:
		mov dx, word [bp-0x10]
		add dx, cx
		mov word [bp-0xa], dx
		mov dx, word [bp-0xe]
		adc dx, word [bp-6]
		mov word [bp-8], dx
		mov dx, word [bp-0x10]
		sub dx, cx
		mov bx, word [bp-0xe]
		sbb bx, word [bp-6]
		cmp al, 0xd
		jb @$50
		jbe @$54
		cmp al, 0x10
		jb @$49
		jbe @$55
		cmp al, 0x13
		je @$56
		cmp al, 0x12
		je @$57
		cmp al, 0x11
		je @$58
		jmp @$158
@$49:
		cmp al, 0xf
		je @$59
		jmp @$128
@$50:
		cmp al, 0xa
		jb @$52
		jbe @$60
		cmp al, 0xc
		je @$61
		jmp @$115
@$51:
		jmp @$150
@$52:
		cmp al, 3
		je @$62
		cmp al, 2
		je @$63
		jmp @$158

;       do_push:
;         msp->value1 = value1;
;         if (++msp == match_stack + sizeof(match_stack) / sizeof(match_stack[0])) { too_deep:
;             message(1, "Expression too deep");  /* Stack overflow in match stack. */
;             goto match_error;
;         }
;       do_match:
;         match_p = avoid_spaces(match_p);
;         value1 = 0;  /* In addition to preventing duplicate initialization below, it also does pacify GCC 7.5.0: do_push jumped to by MATCH_CASEI_LEVEL_TO_VALUE2 does an `msp->value1 = value1'. */
;         if ((c = match_p[0]) == '(') {  /* Parenthesized expression. */
;             /* Count the consecutive open parentheses, and add a single match_stack_item. */
;             for (; (c = (match_p = avoid_spaces(match_p))[0]) == '(' && value1 > -127; ++match_p, --value1) {}
;             msp->casei = value1; msp->level = level; level = 0; goto do_push;
@$53:
		mov al, byte [bp-0x10]
		mov byte [di], al
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 0
		jmp @$149
@$54:
		jmp @$126
@$55:
		jmp @$136
@$56:
		jmp @$157
@$57:
		jmp @$154
@$58:
		jmp @$151
@$59:
		jmp @$134
@$60:
		jmp @$109
@$61:
		jmp @$119
@$62:
		jmp near @$71
@$63:
		mov word [bp-0x10], dx
		mov word [bp-0xe], bx
		jmp @$108

;         } else if (c == '-' || c == '+' || c == '~') {  /* Unary -, + and ~. */
@$64:
		cmp al, 0x2d
		je @$65
		cmp al, 0x2b
		je @$65
		cmp al, 0x7e
		jne @$72

;             /*value1 = 0;*/  /* Delta, can be nonzero iff unary ~ is encountered. */
;             if (c == '~') { --value1; c = '-'; }
@$65:
		cmp byte [bp-4], 0x7e
		jne @$66
		mov byte [bp-4], 0x2d
		add word [bp-0x10], BYTE -1
		adc word [bp-0xe], BYTE -1

;             for (;;) {  /* Shortcut to squeeze multiple unary - and + operators to a single match_stack_item. */
;                 match_p = avoid_spaces(match_p + 1);
@$66:
		lea ax, [si+1]
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if (match_p[0] == '+') {}
		mov al, byte [bx]
		cmp al, 0x2b
		je @$66

;                 else if (match_p[0] == '-') { do_switch_pm: c ^= 6; }  /* Switch between ASCII '+' and '-'. */
		cmp al, 0x2d
		je @$67
		cmp al, 0x7e
		jne @$68
		mov al, byte [bp-4]
		xor ah, ah
		xor dx, dx
		db 0x83, 0xC0, 0xd4  ; !!! add ax, BYTE 0xffd4 | -0x10000
		adc dx, BYTE -1
		add word [bp-0x10], ax
		adc word [bp-0xe], dx

;                 else if (match_p[0] == '~') { value1 += (value_t)c - ('-' - 1); goto do_switch_pm; }  /* Either ++value1 or --value1. */
@$67:
		xor byte [bp-4], 6
		jmp SHORT @$66

;                 else { break; }
;             }
;             if (c == '-') {
@$68:
		cmp byte [bp-4], 0x2d
		jne @$70

;               MATCH_CASEI_LEVEL_TO_VALUE2(2, 6);
		mov byte [di], 2
@$69:
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 6
		jmp @$149

;               value1 -= value2;
;             } else {
;               MATCH_CASEI_LEVEL_TO_VALUE2(3, 6);
@$70:
		mov byte [di], 3
		jmp SHORT @$69

;               value1 += value2;
@$71:
		mov ax, word [bp-0xa]
		mov word [bp-0x10], ax
		mov ax, word [bp-8]

;             }
		jmp @$107

;         } else if (c == '0' && tolower(match_p[1]) == 'b') {  /* Binary */
@$72:
		cmp al, 0x30
		jne @$77
		mov al, byte [bx+1]
		xor ah, ah
		call near tolower_
		db 0x83, 0xF8, 0x62  ; !!! cmp ax, BYTE 0x62
		jne @$77

;             match_p += 2;
		inc si
		inc si

;             /*value1 = 0;*/
;             while (match_p[0] == '0' || match_p[0] == '1' || match_p[0] == '_') {
@$73:
		mov al, byte [si]
		cmp al, 0x30
		je @$74
		cmp al, 0x31
		je @$74
		cmp al, 0x5f
		jne @$76

;                 if (match_p[0] != '_') {
@$74:
		mov al, byte [si]
		cmp al, 0x5f
		je @$75

;                     value1 <<= 1;
		shl word [bp-0x10], 1
		rcl word [bp-0xe], 1

;                     if (match_p[0] == '1')
		cmp al, 0x31
		jne @$75

;                         value1 |= 1;
		or byte [bp-0x10], 1

;                 }
;                 match_p++;
@$75:
		inc si

;             }
		jmp SHORT @$73
@$76:
		jmp @$108

;         } else if (c == '0' && tolower(match_p[1]) == 'x') {  /* Hexadecimal */
@$77:
		cmp byte [bp-4], 0x30
		jne @$82
		mov al, byte [si+1]
		xor ah, ah
		call near tolower_
		db 0x83, 0xF8, 0x78  ; !!! cmp ax, BYTE 0x78
		jne @$82

;             match_p += 2;
		inc si
		inc si

;           parse_hex:
;             /*value1 = 0;*/
;             for (; c = match_p[0], isxdigit(c); ++match_p) {
@$78:
		mov al, byte [si]
		mov byte [bp-4], al
		xor ah, ah
		call near isxdigit_
		test ax, ax
		je @$76

;                 c -= '0';
		sub byte [bp-4], 0x30

;                 if ((unsigned char)c > 9) c = (c & ~32) - 7;
		mov al, byte [bp-4]
		cmp al, 9
		jbe @$79
		and al, 0xdf
		sub al, 7
		mov byte [bp-4], al

;                 value1 = (value1 << 4) | c;
@$79:
		mov ax, word [bp-0x10]
		mov dx, word [bp-0xe]
		mov cx, 4
@$80:
		shl ax, 1
		rcl dx, 1
		loop @$80
		mov bl, byte [bp-4]
		xor bh, bh
		or ax, bx
		mov word [bp-0x10], ax
		mov word [bp-0xe], dx

;             }
@$81:
		inc si
		jmp SHORT @$78

;         } else if (c == '0' && tolower(match_p[1]) == 'o') {  /* Octal. NASM 0.98.39 doesn't support it, but NASM 0.99.06 does. */
@$82:
		cmp byte [bp-4], 0x30
		jne @$85
		mov al, byte [si+1]
		xor ah, ah
		call near tolower_
		db 0x83, 0xF8, 0x6f  ; !!! cmp ax, BYTE 0x6f
		jne @$85

;             match_p += 2;
		inc si
		inc si

;             /*value1 = 0;*/
;             for (; (unsigned char)(c = match_p[0] - '0') < 8; ++match_p) {
@$83:
		mov al, byte [si]
		sub al, 0x30
		mov byte [bp-4], al
		cmp al, 8
		jae @$76

;                 value1 = (value1 << 3) | c;
		mov ax, word [bp-0x10]
		mov dx, word [bp-0xe]
		mov cx, 3
@$84:
		shl ax, 1
		rcl dx, 1
		loop @$84
		mov bl, byte [bp-4]
		xor bh, bh
		or ax, bx
		mov word [bp-0x10], ax
		mov word [bp-0xe], dx

;             }
		inc si
		jmp SHORT @$83

;         } else if (c == '$' && isdigit(match_p[1])) {  /* Hexadecimal */
@$85:
		cmp byte [bp-4], 0x24
		jne @$86
		mov al, byte [si+1]
		xor ah, ah
		call near isdigit_
		test ax, ax
		jne @$81

;             /* This is nasm syntax, notice no letter is allowed after $ */
;             /* So it's preferrable to use prefix 0x for hexadecimal */
;             match_p += 1;
;             goto parse_hex;
;         } else if (c == '\'' || c == '"') {  /* Character constant */
@$86:
		mov al, byte [bp-4]
		cmp al, 0x27
		je @$87
		cmp al, 0x22
		jne @$91

;             /*value1 = 0;*/ shift = 0;
@$87:
		xor bx, bx

;             for (++match_p; match_p[0] != '\0' && match_p[0] != c; ++match_p) {
@$88:
		inc si
		mov al, byte [si]
		test al, al
		je @$89
		cmp al, byte [bp-4]
		je @$89

;                 if (shift < sizeof(value_t) * 8) {
		cmp bx, BYTE 0x20
		jae @$88

;                     value1 |= (unsigned char)match_p[0] << shift;
		xor ah, ah
		mov cl, bl
		shl ax, cl
		cwd
		or word [bp-0x10], ax
		or word [bp-0xe], dx

;                     shift += 8;
		add bx, BYTE 8

;                 }
;             }
		jmp SHORT @$88

;             if (match_p[0] == '\0') {
@$89:
		cmp byte [si], 0
		jne @$90

;                 message(1, "Missing close quote");
		mov dx, @$531

;                 goto match_error;
		jmp @$43

;             } else {
;                 ++match_p;
@$90:
		inc si

;             }
;         } else if (isdigit(c)) {   /* Decimal */
		jmp @$108
@$91:
		xor ah, ah
		call near isdigit_
		test ax, ax
		je @$93

;             /*value1 = 0;*/
;             for (; (unsigned char)(c = match_p[0] - '0') <= 9; ++match_p) {
@$92:
		mov al, byte [si]
		sub al, 0x30
		mov byte [bp-4], al
		cmp al, 9
		ja @$94

;                 value1 = value1 * 10 + c;
		mov ax, word [bp-0x10]
		mov dx, word [bp-0xe]
		mov bx, 0xa
		xor cx, cx
		call near __I4M
		mov bx, dx
		mov dl, byte [bp-4]
		xor dh, dh
		mov word [bp-0xc], 0
		add ax, dx
		mov word [bp-0x10], ax
		mov ax, word [bp-0xc]
		adc ax, bx
		mov word [bp-0xe], ax

;             }
		inc si
		jmp SHORT @$92

;         } else if (c == '$' && match_p[1] == '$') { /* Start address */
@$93:
		cmp byte [bp-4], 0x24
		jne @$95
		cmp byte [si+1], 0x24
		jne @$95

;             match_p += 2;
;             value1 = start_address;
		mov ax, [_start_address]  ; !!! no word [...]
		mov word [bp-0x10], ax
		mov ax, [_start_address+2]  ; !!! no word [...]
		mov word [bp-0xe], ax

		inc si
		inc si

;         } else if (c == '$') { /* Current address */
@$94:
		jmp @$108
@$95:
		mov al, byte [bp-4]
		cmp al, 0x24
		jne @$96

;             match_p++;
;             value1 = address;
		mov ax, [_address]  ; !!! no word [...]
		mov word [bp-0x10], ax
		mov ax, [_address+2]  ; !!! no word [...]
		mov word [bp-0xe], ax
		jmp SHORT @$90

;         } else if (isalpha(c) || c == '_' || c == '.') {  /* Start of label. */
@$96:
		xor ah, ah
		call near isalpha_
		test ax, ax
		jne @$98
		mov al, byte [bp-4]
		cmp al, 0x5f
		je @$98
		cmp al, 0x2e
		je @$98
@$97:
		jmp @$44

;             p2 = expr_name;
@$98:
		mov cx, _expr_name

;             if (c == '.') {
		cmp byte [bp-4], 0x2e
		jne @$100

;                 strcpy(expr_name, global_label);
		mov dx, _global_label
		mov ax, cx
		call near strcpy_

;                 while (*p2 != '\0')
@$99:
		mov bx, cx
		cmp byte [bx], 0
		je @$100

;                     p2++;
		inc cx
		jmp SHORT @$99

;             }
;             while (isalpha(match_p[0]) || isdigit(match_p[0]) || match_p[0] == '_' || match_p[0] == '.')
@$100:
		mov al, byte [si]
		xor ah, ah
		call near isalpha_
		test ax, ax
		jne @$101
		mov al, byte [si]
		xor ah, ah
		call near isdigit_
		test ax, ax
		jne @$101
		mov al, byte [si]
		cmp al, 0x5f
		je @$101
		cmp al, 0x2e
		jne @$102

;                 *p2++ = *match_p++;
@$101:
		mov al, byte [si]
		mov bx, cx
		mov byte [bx], al
		inc si
		inc cx
		jmp SHORT @$100

;             *p2 = '\0';
@$102:
		mov bx, cx
		mov byte [bx], 0

;             if (p2 == expr_name + 2) {
		cmp cx, _expr_name+2
		jne @$105

;                 for (p2 = (char*)register_names; p2 != register_names + 32; p2 += 2) {
		mov cx, _register_names
@$103:
		cmp cx, _register_names+0x20
		je @$105

;                     if (expr_name[0] == p2[0] && expr_name[1] == p2[1]) goto match_error;  /* Using a register name as a label is an error. */
		mov al, [_expr_name]  ; !!! no byte [...]
		mov bx, cx
		cmp al, byte [bx]
		jne @$104
		mov al, [_expr_name+1]  ; !!! no byte
		cmp al, byte [bx+1]
		je @$97

;                 }
@$104:
		inc cx
		inc cx
		jmp SHORT @$103

;             }
;             label = find_label(expr_name);
@$105:
		mov ax, _expr_name
		call near find_label_
		mov bx, ax

;             if (label == NULL) {
		test dx, dx
		jne @$106
		test ax, ax
		jne @$106

;                 /*value1 = 0;*/
;                 undefined++;
		inc word [_undefined]

;                 if (assembler_step == 2) {
		cmp word [_assembler_step], BYTE 2
		jne @$108

;                     message_start(1);
		mov ax, 1
		call near message_start_

;                     /* This will be printed twice for `jmp', but once for `jc'. */
;                     bbprintf(&message_bbb, "Undefined label '%s'", expr_name);
		mov ax, _expr_name
		push ax
		mov ax, @$532
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;                     message_end();
		call near message_end_

;                 }
		jmp SHORT @$108

;             } else {
;                 value1 = label->value;
@$106:
		mov es, dx
		es mov ax, word [bx+5]
		mov word [bp-0x10], ax
		es mov ax, word [bx+7]
@$107:
		mov word [bp-0xe], ax

;             }
;         } else {
;             /* TODO(pts): Make this match syntax error nonsilent? What about when trying instructions? */
;             goto match_error;
;         }
;         /* Now value1 contains the value of the expression parsed so far. */
;       have_value1:
;         if (level <= 5) {
@$108:
		cmp byte [bp-2], 5
		ja @$114
		jmp SHORT @$111

;             while (1) {
;                 match_p = avoid_spaces(match_p);
;                 if ((c = match_p[0]) == '*') {  /* Multiply operator. */
;                     match_p++;
@$109:
		mov ax, word [bp-0x10]
		mov dx, word [bp-0xe]
		mov bx, cx
		mov cx, word [bp-6]
		call near __I4M
@$110:
		mov word [bp-0x10], ax
		mov word [bp-0xe], dx

;                     MATCH_CASEI_LEVEL_TO_VALUE2(10, 6);
;                     value1 *= value2;
;                 } else if (c == '/') {  /* Division operator. */
@$111:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax
		mov al, byte [bx]
		mov byte [bp-4], al
		lea ax, [bx+1]
		cmp byte [bp-4], 0x2a
		jne @$113
		mov byte [di], 0xa
@$112:
		mov dl, byte [bp-2]
		mov byte [di+1], dl
		mov byte [bp-2], 6
		jmp @$125
@$113:
		cmp byte [bp-4], 0x2f
		jne @$118

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(11, 6);
		mov byte [di], 0xb
		jmp SHORT @$112
@$114:
		jmp near @$122

@$115:
		mov ax, word [bp-6]
		or ax, cx
		jne @$117

;                     if (GET_UVALUE(value2) == 0) {
;                         if (assembler_step == 2)
		cmp word [_assembler_step], BYTE 2
		jne @$116

;                             message(1, "division by zero");
		mov dx, @$533
		mov ax, 1
		call near message_

;                         value2 = 1;
@$116:
		mov cx, 1
		mov word [bp-6], 0

;                     }
;                     value1 = GET_UVALUE(value1) / GET_UVALUE(value2);
@$117:
		mov ax, word [bp-0x10]
		mov dx, word [bp-0xe]
		mov bx, cx
		mov cx, word [bp-6]
		call near __U4D
		jmp SHORT @$110

;                 } else if (c == '%') {  /* Modulo operator. */
@$118:
		cmp byte [bp-4], 0x25
		jne @$122

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(12, 6);
		mov byte [di], 0xc

		jmp SHORT @$112

;                     if (GET_UVALUE(value2) == 0) {
@$119:
		mov ax, word [bp-6]
		or ax, cx
		jne @$121

;                         if (assembler_step == 2)
		cmp word [_assembler_step], BYTE 2
		jne @$120

;                             message(1, "modulo by zero");
		mov dx, @$534
		mov ax, 1
		call near message_

;                         value2 = 1;
@$120:
		mov cx, 1
		mov word [bp-6], 0

;                     }
;                     value1 = GET_UVALUE(value1) % GET_UVALUE(value2);
;                 } else {
;                     break;
;                 }
@$121:
		mov ax, word [bp-0x10]
		mov dx, word [bp-0xe]
		mov bx, cx
		mov cx, word [bp-6]
		call near __U4D
		mov word [bp-0x10], bx
		mov word [bp-0xe], cx
		jmp @$111

;             }
;         }
;         if (level <= 4) {
@$122:
		cmp byte [bp-2], 4
		ja @$129

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$123:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if ((c = match_p[0]) == '+') {  /* Add operator. */
		mov al, byte [bx]
		mov byte [bp-4], al
		lea ax, [bx+1]
		cmp byte [bp-4], 0x2b
		jne @$127

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(13, 5);
		mov byte [di], 0xd
@$124:
		mov dl, byte [bp-2]
		mov byte [di+1], dl
		mov byte [bp-2], 5

@$125:
		mov si, ax
		jmp @$149

;                     value1 += value2;
@$126:
		mov ax, word [bp-0xa]
		mov word [bp-0x10], ax
		mov ax, word [bp-8]
		mov word [bp-0xe], ax

;                 } else if (c == '-') {  /* Subtract operator. */
		jmp SHORT @$123
@$127:
		cmp byte [bp-4], 0x2d
		jne @$129

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(14, 5);
		mov byte [di], 0xe
		jmp SHORT @$124

;                     value1 -= value2;
;                 } else {
;                     break;
;                 }
@$128:
		mov word [bp-0x10], dx
		mov word [bp-0xe], bx
		jmp SHORT @$123

;             }
;         }
;         if (level <= 3) {
@$129:
		cmp byte [bp-2], 3
		ja @$139

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$130:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if (((c = match_p[0]) == '<' && match_p[1] == '<') || (c == '>' && match_p[1] == '>')) { /* Shift to left */
		mov al, byte [bx]
		mov byte [bp-4], al
		cmp al, 0x3c
		jne @$131
		cmp al, byte [bx+1]
		je @$132
@$131:
		cmp byte [bp-4], 0x3e
		jne @$139
		cmp byte [si+1], 0x3e
		jne @$146

;                     match_p += 2;
@$132:
		inc si
		inc si

;                     if (c == '<') {
		cmp byte [bp-4], 0x3c
		jne @$135

;                         MATCH_CASEI_LEVEL_TO_VALUE2(15, 4);
		mov byte [di], 0xf
@$133:
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 4
		jmp near @$149

;                         c = 1;
@$134:
		mov byte [bp-4], 1

;                     } else {
		jmp SHORT @$137

;                         MATCH_CASEI_LEVEL_TO_VALUE2(16, 4);
@$135:
		mov byte [di], 0x10
		jmp SHORT @$133

;                         c = 0;
@$136:
		mov byte [bp-4], 0

;                     }
;                     if (GET_UVALUE(value2) > 31) {
@$137:
		cmp word [bp-6], BYTE 0
		jne @$138
		cmp cx, BYTE 0x1f
		jbe @$140

;                         /* 8086 processor (in 16-bit mode) uses all 8 bits of the shift amount.
;                          * i386 and amd64 processors in both 16-bit and 32-bit mode uses the last 5 bits of the shift amount.
;                          * amd64 processor in 64-bit mode uses the last 6 bits of the shift amount.
;                          * To get deterministic output, we disallow shift amounts with more than 5 bits.
;                          * NASM has nondeterministic output, depending on the host architecture (32-bit mode or 64-bit mode).
;                          */
;                         message(1, "shift by larger than 31");
@$138:
		mov dx, @$535
		mov ax, 1
		call near message_

;                         value2 = 0;
; #if !CONFIG_SHIFT_OK_31
;                     } else if (sizeof(int) == 2 && sizeof(value_t) == 2 && GET_UVALUE(value2) > 15) {
;                         /* We want `db 1 << 16' to emit 0, but if the host
;                          * architecture uses only the last 4 bits of the shift
;                          * amount, it would emit 1. Thus we forcibly emit 0 here.
;                          */
; #if CONFIG_SHIFT_SIGNED
;                         value1 = c ? 0 : GET_VALUE(value1) >> 15;  /* Sign-extend value1 to CONFIG_VALUE_BITS. */
; #else
;                         value1 = 0;
; #endif
; #endif  /* CONFIG_SHIFT_OK_31 */
;                     } else {
		jmp SHORT @$130
@$139:
		jmp SHORT @$146

; #if CONFIG_SHIFT_SIGNED
;                         value1 = c ? GET_VALUE( value1) << GET_UVALUE(value2) : GET_VALUE( value1) >> GET_UVALUE(value2);  /* Sign-extend value1 to CONFIG_VALUE_BITS. */
; #else
;                         value1 = c ? GET_UVALUE(value1) << GET_UVALUE(value2) : GET_UVALUE(value1) >> GET_UVALUE(value2);  /* Zero-extend value1 to CONFIG_VALUE_BITS. */
@$140:
		cmp byte [bp-4], 0
		je @$143
		mov ax, word [bp-0x10]
		mov dx, word [bp-0xe]
		jcxz @$142
@$141:
		shl ax, 1
		rcl dx, 1
		loop @$141
@$142:
		jmp SHORT @$145
@$143:
		mov ax, word [bp-0x10]
		mov dx, word [bp-0xe]
		jcxz @$145
@$144:
		shr dx, 1
		rcr ax, 1
		loop @$144
@$145:
		mov word [bp-0x10], ax
		mov word [bp-0xe], dx

; #endif
;                     }
		jmp @$130

;                 } else {
;                     break;
;                 }
;             }
;         }
;         if (level <= 2) {
@$146:
		cmp byte [bp-2], 2
		ja @$152

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$147:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax

;                 if (match_p[0] == '&') {    /* Binary AND */
		cmp byte [si], 0x26
		jne @$152

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(17, 3);
		mov byte [di], 0x11
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 3

@$148:
		inc si
@$149:
		mov ax, word [bp-0x10]
		mov word [di+2], ax
		mov ax, word [bp-0xe]
		mov word [di+4], ax
		add di, BYTE 6
		cmp di, @$620
		je @$150
		jmp @$38
@$150:
		mov dx, @$530
		jmp @$43

;                     value1 &= value2;
;                 } else {
;                     break;
;                 }
@$151:
		and word [bp-0x10], cx
		mov ax, word [bp-6]
		and word [bp-0xe], ax

;             }
		jmp SHORT @$147

;         }
;         if (level <= 1) {
@$152:
		cmp byte [bp-2], 1
		ja @$155

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$153:
		mov ax, si
		call near avoid_spaces_
		mov dx, ax
		mov si, ax

;                 if (match_p[0] == '^') {    /* Binary XOR */
		cmp byte [si], 0x5e
		jne @$155

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(18, 2);
		mov byte [di], 0x12
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 2
		jmp SHORT @$148

;                     value1 ^= value2;
;                 } else {
;                     break;
;                 }
@$154:
		xor word [bp-0x10], cx
		mov ax, word [bp-6]
		xor word [bp-0xe], ax

;             }
		jmp SHORT @$153

;         }
;         if (level == 0) {  /* Top tier. */
@$155:
		cmp byte [bp-2], 0
		jne @$158

;             while (1) {
;                 match_p = avoid_spaces(match_p);
@$156:
		mov ax, si
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if (match_p[0] == '|') {    /* Binary OR */
		cmp byte [bx], 0x7c
		jne @$158

;                     match_p++;
;                     MATCH_CASEI_LEVEL_TO_VALUE2(19, 1);
		mov byte [di], 0x13
		mov al, byte [bp-2]
		mov byte [di+1], al
		mov byte [bp-2], 1

		lea si, [bx+1]
		jmp SHORT @$149

;                     value1 |= value2;
;                 } else {
;                     break;
;                 }
@$157:
		or word [bp-0x10], cx
		mov ax, word [bp-6]
		or word [bp-0xe], ax

;             }
		jmp SHORT @$156

;         }
;     }
;     if (msp != match_stack) goto do_pop;
@$158:
		cmp di, @$619
		je @$159
		jmp @$42

;     instruction_value = value1;
@$159:
		mov ax, word [bp-0x10]
		mov [_instruction_value], ax  ; !!! no word [...]
		mov ax, word [bp-0xe]
		mov [_instruction_value+2], ax  ; !!! no word [...]

;     return avoid_spaces(match_p);
		mov ax, si
		call near avoid_spaces_

; }
@$160:
		mov sp, bp
		pop bp
		pop di
@$161:
		pop si
@$162:
		pop dx
		pop cx
		pop bx
		ret

;
; /*
;  ** Check for a label character
;  */
; int islabel(int c) {
islabel_:
		push dx
		mov dx, ax

;     return isalpha(c) || isdigit(c) || c == '_' || c == '.';
		call near isalpha_
		test ax, ax
		jne @$163
		mov ax, dx
		call near isdigit_
		test ax, ax
		jne @$163
		cmp dx, BYTE 0x5f
		je @$163
		cmp dx, BYTE 0x2e
		jne @$164
@$163:
		mov ax, 1

; }
@$164:
		pop dx
		ret

;
; /*
;  ** Match register
;  */
; const char *match_register(const char *p, int width, unsigned char *reg) {
match_register_:
		push cx
		push si
		push di
		mov si, ax
		mov di, bx

;     const char *r0, *r, *r2;
;
;     p = avoid_spaces(p);
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;     if (!isalpha(p[0]) || !isalpha(p[1]) || islabel(p[2]))
		mov al, byte [bx]
		xor ah, ah
		call near isalpha_
		test ax, ax
		je @$167
		mov al, byte [bx+1]
		xor ah, ah
		call near isalpha_
		test ax, ax
		je @$167
		mov al, byte [bx+2]
		xor ah, ah
		call near islabel_
		test ax, ax
		jne @$167

;         return NULL;
;     r0 = r = register_names + (width & 16);  /* Works for width == 8 and width == 16. */
		and dx, BYTE 0x10
		mov bx, _register_names
		add bx, dx
		mov dx, bx

;     for (r2 = r + 16; r != r2; r += 2) {
		lea cx, [bx+0x10]
@$165:
		cmp bx, cx
		je @$167

;         if (p[0] == r[0] && p[1] == r[1]) {
		mov al, byte [si]
		cmp al, byte [bx]
		jne @$166
		mov al, byte [si+1]
		cmp al, byte [bx+1]
		jne @$166

;             *reg = (r - r0) >> 1;
		sub bx, dx
		sar bx, 1
		mov byte [di], bl

;             return p + 2;
		lea ax, [si+2]
		jmp SHORT @$168

;         }
;     }
@$166:
		inc bx
		inc bx
		jmp SHORT @$165

;     return NULL;
@$167:
		xor ax, ax

; }
@$168:
		pop di
		pop si
		pop cx
		ret

;
; const unsigned char reg_to_addressing[8] = { 0, 0, 0, 7 /* BX */, 0, 6 /* BP */, 4 /* SI */, 5 /* DI */ };
;
; /*
;  ** Match addressing.
;  ** As a side effect, it sets instruction_addressing, instruction_offset, instruction_offset_width.
;  */
; const char *match_addressing(const char *p, int width) {
match_addressing_:
		push bx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		push ax
		mov si, ax

;     unsigned char reg, reg2, reg12;
;     unsigned char *instruction_addressing_p = &instruction_addressing;  /* Using this pointer saves 20 bytes in __DOSMC__. */
		mov di, _instruction_addressing

;     const char *p2;
;
;     instruction_offset = 0;
		xor ax, ax
		mov [_instruction_offset], ax  ; !!! no word [...]
		mov [_instruction_offset+2], ax  ; !!! no word [...]

;     instruction_offset_width = 0;
		mov byte [_instruction_offset_width], 0

;
;     p = avoid_spaces(p);
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;     if (*p == '[') {
		cmp byte [si], 0x5b
		jne @$171

;         p = avoid_spaces(p + 1);
		inc ax
		call near avoid_spaces_
		mov si, ax

;         p2 = match_register(p, 16, &reg);
		lea bx, [bp-2]
		mov dx, 0x10
		call near match_register_

;         if (p2 != NULL) {
		test ax, ax
		je @$172

;             p = avoid_spaces(p2);
		call near avoid_spaces_
		mov si, ax

;             if (*p == ']') {
		cmp byte [si], 0x5d
		jne @$173

;                 p++;
		inc si

;                 if (reg == 5) {  /* BP. */
		mov al, byte [bp-2]
		cmp al, 5
		jne @$169

;                     *instruction_addressing_p = 0x46;
		mov byte [_instruction_addressing], 0x46

;                     /*instruction_offset = 0;*/  /* Already set. */
;                     ++instruction_offset_width;
		inc byte [_instruction_offset_width]

;                 } else {
		jmp @$191

;                     if ((*instruction_addressing_p = reg_to_addressing[reg]) == 0) return NULL;
@$169:
		mov bl, al
		xor bh, bh
		mov al, byte [bx+_reg_to_addressing]
		mov [_instruction_addressing], al  ; !!! no byte [...]
		test al, al
		jne @$176
@$170:
		xor ah, ah
		jmp @$192
@$171:
		jmp @$190
@$172:
		jmp @$188

;                 }
;             } else if (*p == '+' || *p == '-') {
@$173:
		cmp byte [si], 0x2b
		je @$174
		cmp byte [si], 0x2d
		jne @$175

;                 if (*p == '+') {
@$174:
		cmp byte [si], 0x2b
		jne @$178

;                     p = avoid_spaces(p + 1);
		lea ax, [si+1]
		call near avoid_spaces_
		mov si, ax

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
		je @$178

;                     reg12 = reg * reg2;
		mov al, byte [bp-2]
		mul byte [bp-4]

;                     if (reg12 == 6 * 3) {  /* BX+SI / SI+BX. */
		cmp al, 0x12
		je @$177

;                     } else if (reg12 == 7 * 3) {  /* BX+DI / DI+BX. */
		cmp al, 0x15
		je @$177

;                     } else if (reg12 == 6 * 5) {  /* BP+SI / SI+BP. */
		cmp al, 0x1e
		je @$177

;                     } else if (reg12 == 7 * 5) {  /* BP+DI / DI+BP. */
		cmp al, 0x23
		je @$177

;                     } else {  /* Not valid. */
;                         return NULL;
@$175:
		xor ax, ax
		jmp @$192
@$176:
		jmp @$191

;                     }
;                     *instruction_addressing_p = reg + reg2 - 9;  /* Magic formula for encoding any of BX+SI, BX+DI, BP+SI, BP+DI. */
@$177:
		mov al, byte [bp-2]
		add al, byte [bp-4]
		sub al, 9
		mov byte [di], al

;                     p = avoid_spaces(p2);
		mov ax, bx
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                     if (*p == ']') {
		mov al, byte [bx]
		cmp al, 0x5d
		jne @$179

;                         p++;
		lea si, [bx+1]

;                     } else if (*p == '+' || *p == '-') {
		jmp SHORT @$176
@$178:
		jmp SHORT @$186
@$179:
		cmp al, 0x2b
		je @$180
		cmp al, 0x2d
		jne @$175

;                         p = match_expression(p);
@$180:
		mov ax, si
		call near match_expression_
		mov si, ax

;                         if (p == NULL)
		test ax, ax
		je @$185

;                             return NULL;
@$181:
		mov ax, [_instruction_value]  ; !!! no word [...]
		mov dx, word [_instruction_value+2]
		mov [_instruction_offset], ax  ; !!! no word [...]
		mov word [_instruction_offset+2], dx

;                         instruction_offset = instruction_value;
;                         if (*p != ']')
		cmp byte [si], 0x5d
		jne @$175

;                             return NULL;
;                         p++;
		inc si

;                       set_width:
;                         ++instruction_offset_width;
		inc byte [_instruction_offset_width]

;                         if (instruction_offset >= -0x80 && instruction_offset <= 0x7f) {
		mov ax, [_instruction_offset+2]  ; !!! no word [...]
		db 0x83, 0xF8, 0xff  ; !!! cmp ax, BYTE 0xffff
		jg @$182
		jne @$184
		cmp word [_instruction_offset], BYTE 0xff80 | -0x10000
		jb @$184
@$182:
		test ax, ax
		jl @$183
		jne @$184
		cmp word [_instruction_offset], BYTE 0x7f
		ja @$184

;                             *instruction_addressing_p |= 0x40;
@$183:
		or byte [di], 0x40

;                         } else {
		jmp SHORT @$191

;                             ++instruction_offset_width;
@$184:
		inc byte [_instruction_offset_width]

;                             *instruction_addressing_p |= 0x80;
		or byte [di], 0x80

;                         }
		jmp SHORT @$191
@$185:
		jmp SHORT @$192

;                     } else {    /* Syntax error */
;                         return NULL;
;                     }
;                 } else {
;                     if ((*instruction_addressing_p = reg_to_addressing[reg]) == 0) return NULL;
@$186:
		mov bl, byte [bp-2]
		xor bh, bh
		mov al, byte [bx+_reg_to_addressing]
		mov byte [di], al
		test al, al
		jne @$187
		jmp @$170

;                     p = match_expression(p);
@$187:
		mov ax, si
		call near match_expression_
		mov si, ax

;                     if (p == NULL)
		test ax, ax
		jne @$181

;                         return NULL;
		jmp SHORT @$192

;                     instruction_offset = instruction_value;
;                     if (*p != ']')
;                         return NULL;
;                     p++;
;                     goto set_width;
;                 }
;             } else {    /* Syntax error */
;                 return NULL;
;             }
;         } else {    /* No valid register, try expression (absolute addressing) */
;             p = match_expression(p);
@$188:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p == NULL)
		test ax, ax
		je @$192

;                 return NULL;
;             instruction_offset = instruction_value;
		mov ax, [_instruction_value]  ; !!! no word [...]
		mov dx, word [_instruction_value+2]
		mov [_instruction_offset], ax  ; !!! no word [...]
		mov word [_instruction_offset+2], dx

;             if (*p != ']')
		cmp byte [si], 0x5d
		je @$189
		jmp @$175

;                 return NULL;
;             p++;
;             *instruction_addressing_p = 0x06;
@$189:
		mov byte [_instruction_addressing], 6

;             instruction_offset_width = 2;
		mov byte [_instruction_offset_width], 2

		inc si

;         }
		jmp SHORT @$191

;     } else {    /* Register */
;         p = match_register(p, width, &reg);
@$190:
		lea bx, [bp-2]
		call near match_register_
		mov si, ax

;         if (p == NULL)
		test ax, ax
		je @$192

;             return NULL;
;         *instruction_addressing_p = 0xc0 | reg;
		mov al, byte [bp-2]
		or al, 0xc0
		mov [_instruction_addressing], al  ; !!! no byte [...]

;     }
;     return p;
@$191:
		mov ax, si

; }
@$192:
		mov sp, bp
		pop bp
@$193:
		pop di
@$194:
		pop si
		pop bx
		ret

;
; extern struct bbprintf_buf emit_bbb;
;
; char emit_buf[512];
;
; void emit_flush(struct bbprintf_buf *bbb) {
emit_flush_:
		push bx
		push cx
		push dx

;     const int size = emit_bbb.p - emit_buf;
		mov cx, word [_emit_bbb+4]
		sub cx, _emit_buf

;     (void)bbb;  /* emit_bbb. */
;     if (size) {
		jne @$196
@$195:
		jmp @$162

;         if (write(output_fd, emit_buf, size) != size) {
@$196:
		mov ax, [_output_fd]  ; !!! no word [...]
		mov bx, cx
		mov dx, _emit_buf
		call near write_
		cmp ax, cx
		je @$197

;             message(1, "error writing to output file");
		mov dx, @$536
		mov ax, 1
		call near message_

;             exit(3);
		mov ax, 3
		mov ah, 0x4c
		int 0x21

;         }
;         emit_bbb.p = emit_buf;
@$197:
		mov word [_emit_bbb+4], _emit_buf

;     }
		jmp SHORT @$195

; }
;
; struct bbprintf_buf emit_bbb = { emit_buf, emit_buf + sizeof(emit_buf), emit_buf, 0, emit_flush };
;
; void emit_write(const char *s, int size) {
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
@$198:
		mov ax, [_emit_bbb+2]  ; !!! no word [...]
		sub ax, word [_emit_bbb+4]
		mov word [bp-2], ax
		cmp dx, ax
		jl @$199

; #ifdef __DOSMC__  /* A few byte smaller than memcpy(...). */
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
		jmp SHORT @$198

; #ifdef __DOSMC__  /* A few byte smaller than memcpy(...). */
;     emit_bbb.p = (char*)memcpy_newdest_inline(emit_bbb.p, s, size);
@$199:
		mov di, word [_emit_bbb+4]
		mov cx, dx
		mov si, bx
		push ds
		pop es
		rep movsb
		mov word [_emit_bbb+4], di
		jmp @$29

; #else
;     memcpy(emit_bbb.p, s, size);
;     emit_bbb.p += size;
; #endif
; }
;
; void emit_bytes(const char *s, int size)  {
emit_bytes_:
		push bx
		push si
		push di
		mov si, ax
		mov bx, dx

;     address += size;
		mov ax, dx
		cwd
		add word [_address], ax
		adc word [_address+2], dx

;     if (assembler_step == 2) {
		cmp word [_assembler_step], BYTE 2
		je @$201
@$200:
		jmp @$193

;         emit_write(s, size);
@$201:
		mov dx, bx
		mov ax, si
		call near emit_write_

;         bytes += size;
		mov ax, bx
		cwd
		add word [_bytes], ax
		adc word [_bytes+2], dx

;         if (g != NULL) {
		cmp word [_g], BYTE 0
		je @$200

;             for (; size > 0 && g != generated + sizeof(generated); *g++ = *s++, --size) {}
@$202:
		test bx, bx
		jle @$200
		mov ax, [_g]  ; !!! no word [...]
		cmp ax, _generated+8
		je @$200
		mov di, si
		mov dx, ax
		inc si
		inc ax
		mov [_g], ax  ; !!! no word [...]
		mov al, byte [di]
		mov di, dx
		mov byte [di], al
		dec bx
		jmp SHORT @$202

;         }
;     }
; }
;
; /*
;  ** Emit one byte to output
;  */
; void emit_byte(int byte) {
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
; const char *check_end(const char *p) {
check_end_:
		push bx
		push dx

;     p = avoid_spaces(p);
		call near avoid_spaces_
		mov bx, ax

;     if (*p && *p != ';') {
		cmp byte [bx], 0
		je @$203
		cmp byte [bx], 0x3b
		je @$203

;         message(1, "extra characters at end of line");
		mov dx, @$537
		mov ax, 1
		call near message_

;         return NULL;
		xor ax, ax

;     }
;     return p;
; }
@$203:
		pop dx
@$204:
		pop bx
		ret

;
; /*
;  ** Search for a match with instruction
;  */
; const char *match(const char *p, const char *pattern_and_encode) {
match_:
		push bx
		push cx
		push si
		push di
		push bp
		mov bp, sp
		sub sp, BYTE 0xe
		mov si, ax
		mov di, dx

;     int c;
;     int bit;
;     int qualifier;
;     const char *p0;
;     const char *error_base;
;     static value_t segment_value;  /* Static just to pacify GCC 7.5.0 warning of uninitialized. */
;     unsigned char unused_reg;
;     char dc, dw;
;
;     p0 = p;
		mov word [bp-0xa], ax

;   next_pattern:
;     undefined = 0;
@$205:
		xor ax, ax
		mov [_undefined], ax  ; !!! no word [...]

;     for (error_base = pattern_and_encode; (dc = *pattern_and_encode++) != ' ';) {
		mov word [bp-8], di
@$206:
		mov al, byte [di]
		mov byte [bp-6], al
		inc di
		cmp al, 0x20
		je @$207

;         if (dc - 'j' + 0U <= 'm' - 'j' + 0U) {  /* Addressing: 'j': %d8, 'k': %d16, 'l': %db8, 'm': %dw16. */
		xor ah, ah
		mov dx, ax
		sub dx, BYTE 0x6a
		cmp dx, BYTE 3
		ja @$208

;             qualifier = 0;
		xor cx, cx

;             if (memcmp(p, "WORD", 4) == 0 && !isalpha(p[4])) {
		mov bx, 4
		mov dx, @$538
		mov ax, si
		call near memcmp_
		test ax, ax
		jne @$209
		mov al, byte [si+4]
		xor ah, ch
		call near isalpha_
		test ax, ax
		jne @$209

;                 p = avoid_spaces(p + 4);
		lea ax, [si+4]
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if (*p != '[')
		cmp byte [bx], 0x5b
		jne @$215

;                     goto mismatch;
;                 qualifier = 16;
		mov cx, 0x10

;             } else if (memcmp(p, "BYTE", 4) == 0 && !isalpha(p[4])) {
		jmp SHORT @$210
@$207:
		jmp @$248
@$208:
		jmp @$220
@$209:
		mov bx, 4
		mov dx, @$539
		mov ax, si
		call near memcmp_
		test ax, ax
		jne @$210
		mov al, byte [si+4]
		xor ah, ah
		call near isalpha_
		test ax, ax
		jne @$210

;                 p = avoid_spaces(p + 4);
		lea ax, [si+4]
		call near avoid_spaces_
		mov bx, ax
		mov si, ax

;                 if (*p != '[')
		cmp byte [bx], 0x5b
		jne @$215

;                     goto mismatch;
;                 qualifier = 8;
		mov cx, 8

;             }
;             if (dc == 'j') {
@$210:
		mov al, byte [bp-6]
		cmp al, 0x6a
		jne @$214

;                 if (qualifier == 16) goto mismatch;
		cmp cx, BYTE 0x10
@$211:
		je @$215

;               match_addressing_8:
;                 /* It sets instruction_addressing, instruction_offset, instruction_offset_width. */
;                 p = match_addressing(p, 8);
@$212:
		mov dx, 8
@$213:
		mov ax, si
		call near match_addressing_
		jmp @$243

;             } else if (dc == 'k') {
@$214:
		cmp al, 0x6b
		jne @$216

;                 if (qualifier == 8) goto mismatch;
		cmp cx, BYTE 8
		jmp SHORT @$218
@$215:
		jmp @$245

;               match_addressing_16:
@$216:
		cmp al, 0x6c
		jne @$217

;                 /* It sets instruction_addressing, instruction_offset, instruction_offset_width. */
;                 p = match_addressing(p, 16);
;             } else if (dc == 'l') {
;                 if (qualifier != 8 && match_register(p, 8, &unused_reg) == 0) goto mismatch;
		cmp cx, BYTE 8
		je @$212
		lea bx, [bp-2]
		mov dx, 8
		mov ax, si
		call near match_register_
		test ax, ax
		jmp SHORT @$211

;                 goto match_addressing_8;
;             } else /*if (dc == 'm')*/ {
;                 if (qualifier != 16 && match_register(p, 16, &unused_reg) == 0) goto mismatch;
@$217:
		cmp cx, BYTE 0x10
		je @$219
		lea bx, [bp-2]
		mov dx, 0x10
		mov ax, si
		call near match_register_
		test ax, ax
@$218:
		je @$215

@$219:
		mov dx, 0x10
		jmp SHORT @$213

;                 goto match_addressing_16;
;             }
;         } else if (dc == 'q' || dc == 'r') {  /* Register, 8-bit (q) or 16-bit (r). */
@$220:
		cmp al, 0x71
		je @$221
		cmp al, 0x72
		jne @$224

;             p = match_register(p, dc == 'q' ? 0 : 16, &instruction_register);  /* 0: anything without the 16 bit set. */
@$221:
		mov bx, _instruction_register
		cmp byte [bp-6], 0x71
		jne @$222
		xor dx, dx
		jmp SHORT @$223
@$222:
		mov dx, 0x10
@$223:
		mov ax, si
		call near match_register_
		jmp @$243

;         } else if (dc == 'i') {  /* Unsigned immediate, 8-bit or 16-bit. */
@$224:
		cmp al, 0x69
		jne @$226

;             p = match_expression(p);
@$225:
		mov ax, si
		call near match_expression_
		jmp @$243

;         } else if (dc == 'a' || dc == 'c') {  /* Address for jump, 8-bit. */
@$226:
		cmp al, 0x61
		je @$227
		cmp al, 0x63
		jne @$231

;             p = avoid_spaces(p);
@$227:
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;             qualifier = 0;
		xor cx, cx

;             if (memcmp(p, "SHORT", 5) == 0 && isspace(p[5])) {
		mov bx, 5
		mov dx, @$540
		call near memcmp_
		test ax, ax
		jne @$228
		mov bx, si
		mov al, byte [bx+5]
		xor ah, ch
		call near isspace_
		test ax, ax
		je @$228

;                 p += 5;
;                 qualifier = 1;
		mov cx, 1

		add si, BYTE 5

;             }
;             p = match_expression(p);
@$228:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p != NULL && qualifier == 0) {
		test ax, ax
		je @$230
		test cx, cx
		jne @$230

;                 c = instruction_value - (address + 2);
		mov ax, [_address]  ; !!! no word [...]
		inc ax
		inc ax
		mov dx, word [_instruction_value]
		sub dx, ax
		mov word [bp-0xe], dx

;                 if (dc == 'c' && undefined == 0 && (c < -128 || c > 127))
		cmp byte [bp-6], 0x63
		jne @$230
		cmp word [_undefined], BYTE 0
		jne @$230
		cmp dx, BYTE 0xff80 | -0x10000
		jl @$234
		cmp dx, BYTE 0x7f
@$229:
		jg @$234
@$230:
		jmp @$244

;                     goto mismatch;
;             }
;         } else if (dc == 'b') {  /* Address for jump, 16-bit. */
@$231:
		cmp al, 0x62
		jne @$235

;             p = avoid_spaces(p);
		mov ax, si
		call near avoid_spaces_
		mov cx, ax
		mov si, ax

;             if (memcmp(p, "SHORT", 5) == 0 && isspace(p[5])) {
		mov bx, 5
		mov dx, @$540
		call near memcmp_
		test ax, ax
		je @$233
@$232:
		jmp @$225
@$233:
		mov bx, cx
		mov al, byte [bx+5]
		xor ah, ah
		call near isspace_
		test ax, ax
		jne @$234

;                 p = NULL;
;             } else {
		jmp SHORT @$232
@$234:
		jmp @$245

;                 p = match_expression(p);
;             }
;         } else if (dc == 's') {  /* Signed immediate, 8-bit. */
@$235:
		cmp al, 0x73
		jne @$237

;             p = avoid_spaces(p);
		mov ax, si
		call near avoid_spaces_
		mov si, ax

;             qualifier = 0;
		xor cx, cx

;             if (memcmp(p, "BYTE", 4) == 0 && isspace(p[4])) {
		mov bx, 4
		mov dx, @$539
		call near memcmp_
		test ax, ax
		jne @$236
		mov bx, si
		mov al, byte [bx+4]
		xor ah, ch
		call near isspace_
		test ax, ax
		je @$236

;                 p += 4;
;                 qualifier = 1;
		mov cx, 1

		add si, BYTE 4

;             }
;             p = match_expression(p);
@$236:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p != NULL && qualifier == 0) {
		test ax, ax
		je @$230
		test cx, cx
		jne @$230

;                 c = instruction_value;
		mov ax, [_instruction_value]  ; !!! no word [...]
		mov word [bp-0xe], ax

;                 if (undefined != 0)
		cmp word [_undefined], BYTE 0
		jne @$234

;                     goto mismatch;
;                 if (undefined == 0 && (c < -128 || c > 127))
		jne @$230
		db 0x83, 0xF8, 0x80  ; !!! cmp ax, BYTE 0xff80
		jl @$234
		db 0x83, 0xF8, 0x7f  ; !!! cmp ax, BYTE 0x7f
		jmp @$229

;                     goto mismatch;
;             }
;         } else if (dc == 'f') {  /* FAR pointer. */
@$237:
		cmp al, 0x66
		jne @$239

;             if (memcmp(p, "SHORT", 5) == 0 && isspace(p[5])) {
		mov bx, 5
		mov dx, @$540
		mov ax, si
		call near memcmp_
		test ax, ax
		jne @$238
		mov al, byte [si+5]
		xor ah, ah
		call near isspace_
		test ax, ax
		jne @$245

;                 goto mismatch;
;             }
;             p = match_expression(p);
@$238:
		mov ax, si
		call near match_expression_
		mov si, ax

;             if (p == NULL)
		test ax, ax
		je @$245

;                 goto mismatch;
;             segment_value = instruction_value;
		mov dx, word [_instruction_value]
		mov ax, [_instruction_value+2]  ; !!! no word [...]
		mov word [@$620], dx
		mov [@$621], ax  ; !!! no word [...]

;             if (*p != ':')
		cmp byte [si], 0x3a
		jne @$245
		jmp SHORT @$242

;                 goto mismatch;
@$239:
		db 0x83, 0xE8, 0x61  ; !!! sub ax, BYTE 0x61
		db 0x83, 0xF8, 0x19  ; !!! cmp ax, BYTE 0x19
		jbe @$250

;             p = match_expression(p + 1);
;         } else if (dc - 'a' + 0U <= 'z' - 'a' + 0U) {  /* Unexpected special (lowercase) character in pattern. */
;             goto decode_internal_error;
;         } else {
;             if (*p != dc) goto mismatch;
		mov al, byte [si]
		cmp al, byte [bp-6]
		jne @$245

;             p++;
		inc si

;             if (dc == ',') p = avoid_spaces(p);  /* Allow spaces in p after comma in pattern and p. */
		cmp al, 0x2c
		je @$241
@$240:
		jmp @$206
@$241:
		mov ax, si
		call near avoid_spaces_
		mov si, ax
		jmp SHORT @$240

@$242:
		lea ax, [si+1]
		call near match_expression_

;             continue;
;         }
@$243:
		mov si, ax

;         if (p == NULL) goto mismatch;
@$244:
		test si, si
		jne @$240

;     }
;     goto do_encode;
;   mismatch:
;     while ((dc = *pattern_and_encode++) != '\0' && dc != '-' /* ALSO */) {}
@$245:
		mov al, byte [di]
		mov byte [bp-6], al
		inc di
		test al, al
		je @$246
		cmp al, 0x2d
		jne @$245

;     if (dc == '\0') return NULL;
@$246:
		mov al, byte [bp-6]
		test al, al
		jne @$247
		xor ah, ah
		jmp @$29

;     p = p0;
@$247:
		mov si, word [bp-0xa]

;     goto next_pattern;
		jmp @$205

;
;   do_encode:
;     /*
;      ** Instruction properly matched, now generate binary
;      */
;     for (error_base = pattern_and_encode; (dc = *pattern_and_encode++) != '\0' && dc != '-' /* ALSO */;) {
@$248:
		mov word [bp-8], di
@$249:
		mov al, byte [di]
		mov byte [bp-6], al
		inc di
		test al, al
		je @$255
		cmp al, 0x2d
		je @$255

;         dw = 0;
		mov byte [bp-4], 0

;         if (dc == '+') {  /* Instruction is a prefix. */
		cmp al, 0x2b
		jne @$251

;             return p;  /* Don't call near check_end(p). */
		mov ax, si
		jmp @$29
@$250:
		jmp @$274

;         } else if ((unsigned char)dc <= 'F' + 0U) {  /* Byte: uppercase hex. */
@$251:
		cmp al, 0x46
		ja @$254

;             c = dc - '0';
		xor ah, ah
		db 0x83, 0xE8, 0x30  ; !!! sub ax, BYTE 0x30
		mov word [bp-0xe], ax

;             if (c > 9) c -= 7;
		db 0x83, 0xF8, 9  ; !!! cmp ax, BYTE 9
		jle @$252
		sub word [bp-0xe], BYTE 7

;             dc = *pattern_and_encode++ - '0';
@$252:
		mov bx, di
		inc di
		mov al, byte [bx]
		sub al, 0x30
		mov byte [bp-6], al

;             if (dc > 9) dc -= 7;
		cmp al, 9
		jbe @$253
		sub byte [bp-6], 7

;             c = (c << 4) | dc;
@$253:
		mov cl, 4
		mov dx, word [bp-0xe]
		shl dx, cl
		mov al, byte [bp-6]
		xor ah, ah
		or dx, ax
		mov word [bp-0xe], dx

;         } else if (dc == 'i') {
		jmp @$275
@$254:
		cmp al, 0x69
		jne @$256

;             c = instruction_value;
		mov ax, [_instruction_value]  ; !!! no word [...]
		mov word [bp-0xe], ax

;         } else if (dc == 'j') {
		jmp @$275
@$255:
		jmp @$279
@$256:
		cmp al, 0x6a
		jne @$259

;             c = instruction_value;
		mov ax, [_instruction_value]  ; !!! no word [...]
		mov word [bp-0xe], ax

;             instruction_offset = instruction_value >> 8;
		mov dx, word [_instruction_value+2]
		mov cx, 8
@$257:
		sar dx, 1
		rcr ax, 1
		loop @$257
@$258:
		mov [_instruction_offset], ax  ; !!! no word [...]
		mov word [_instruction_offset+2], dx

;             dw = 1;
		mov byte [bp-4], 1

;         } else if (dc == 'a') {  /* Address for jump, 8-bit. */
		jmp @$275
@$259:
		cmp al, 0x61
		jne @$261

;             c = instruction_value - (address + 1);
		mov ax, [_address]  ; !!! no word [...]
		inc ax
		mov dx, word [_instruction_value]
		sub dx, ax
		mov word [bp-0xe], dx

;             if (assembler_step == 2 && (c < -128 || c > 127))
		cmp word [_assembler_step], BYTE 2
		jne @$264
		cmp dx, BYTE 0xff80 | -0x10000
		jl @$260
		cmp dx, BYTE 0x7f
		jle @$264

;                 message(1, "short jump too long");
@$260:
		mov dx, @$541
		mov ax, 1
		call near message_
		jmp SHORT @$264

;         } else if (dc == 'b') {  /* Address for jump, 16-bit. */
@$261:
		cmp al, 0x62
		jne @$262

;             c = instruction_value - (address + 2);
		mov ax, [_address]  ; !!! no word [...]
		inc ax
		inc ax
		mov dx, word [_instruction_value]
		sub dx, ax
		mov word [bp-0xe], dx

;             instruction_offset = c >> 8;
		mov al, byte [bp-0xd]
		cbw
		cwd
		jmp SHORT @$258

;             dw = 1;
;         } else if (dc == 'f') {  /* Far (16+16 bit) jump or call. */
@$262:
		cmp al, 0x66
		jne @$265

;             emit_byte(instruction_value);
		mov ax, [_instruction_value]  ; !!! no word [...]
		call near emit_byte_

;             c = instruction_value >> 8;
		mov ax, [_instruction_value]  ; !!! no word [...]
		mov dx, word [_instruction_value+2]
		mov cx, 8
@$263:
		sar dx, 1
		rcr ax, 1
		loop @$263
		mov word [bp-0xe], ax

;             instruction_offset = segment_value;
		mov ax, [@$620]  ; !!! no word [...]
		mov dx, word [@$621]
		mov [_instruction_offset], ax  ; !!! no word [...]
		mov word [_instruction_offset+2], dx

;             dw = 2;
		mov byte [bp-4], 2

;         } else {  /* Binary. */
@$264:
		jmp @$275

;             c = 0;
@$265:
		xor ax, ax
		mov word [bp-0xe], ax

;             --pattern_and_encode;
;             for (bit = 0; bit < 8;) {
		mov word [bp-0xc], ax

		dec di
		jmp SHORT @$270

;                 dc = *pattern_and_encode++;
;                 if (dc == 'z') {  /* Zero. */
;                     bit++;
;                 } else if (dc == 'o') {  /* One. */
@$266:
		cmp byte [bp-6], 0x6f
		jne @$267

;                     c |= 0x80 >> bit;
		mov cl, byte [bp-0xc]
		mov dx, 0x80
		sar dx, cl
		or word [bp-0xe], dx
		jmp SHORT @$271

;                     bit++;
;                 } else if (dc == 'r') {  /* Register field. */
@$267:
		mov dx, word [bp-0xc]
		add dx, BYTE 3
		mov al, byte [bp-6]
		cmp al, 0x72
		jne @$272

;                     c |= instruction_register << (5 - bit);
		mov cx, 5
		sub cx, word [bp-0xc]
		mov al, [_instruction_register]  ; !!! no byte
		xor ah, ah
		shl ax, cl
		or word [bp-0xe], ax

;                     bit += 3;
@$268:
		mov word [bp-0xc], dx

;                 } else if (dc == 'd') {  /* Addressing field. */
@$269:
		cmp word [bp-0xc], BYTE 8
		jge @$275
@$270:
		mov al, byte [di]
		mov byte [bp-6], al
		inc di
		mov ax, word [bp-0xc]
		inc ax
		cmp byte [bp-6], 0x7a
		jne @$266
@$271:
		mov word [bp-0xc], ax
		jmp SHORT @$269
@$272:
		cmp al, 0x64
		jne @$274

;                     if (bit == 0) {
		cmp word [bp-0xc], BYTE 0
		jne @$273

;                         c |= instruction_addressing & 0xc0;
		mov al, [_instruction_addressing]  ; !!! no byte
		and al, 0xc0
		xor ah, ah
		or word [bp-0xe], ax

;                         bit += 2;
		add word [bp-0xc], BYTE 2

;                     } else {
		jmp SHORT @$269

;                         c |= instruction_addressing & 0x07;
@$273:
		mov al, [_instruction_addressing]  ; !!! no byte
		and al, 7
		xor ah, ah
		or word [bp-0xe], ax

;                         bit += 3;
;                         dw = instruction_offset_width;  /* 1 or 2. */
		mov al, [_instruction_offset_width]  ; !!! no byte
		mov byte [bp-4], al
		jmp SHORT @$268

;                     }
;                 } else { decode_internal_error:  /* assert(...). */
;                     message_start(1);
@$274:
		mov ax, 1
		call near message_start_

;                     bbprintf(&message_bbb, "decode: internal error (%s)", error_base);
		push word [bp-8]
		mov ax, @$542
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;                     message_end();
		call near message_end_

;                     exit(2);
		mov ax, 2
		mov ah, 0x4c
		int 0x21

;                     break;
;                 }
;             }
;         }
;         emit_byte(c);
@$275:
		mov ax, word [bp-0xe]
		call near emit_byte_

;         if (dw != 0) {
		cmp byte [bp-4], 0
		jne @$277
@$276:
		jmp @$249

;             emit_byte(instruction_offset);
@$277:
		mov ax, [_instruction_offset]  ; !!! no word [...]
		call near emit_byte_

;             if (dw > 1) emit_byte(instruction_offset >> 8);
		cmp byte [bp-4], 1
		jbe @$276
		mov ax, [_instruction_offset]  ; !!! no word [...]
		mov dx, word [_instruction_offset+2]
		mov cx, 8
@$278:
		sar dx, 1
		rcr ax, 1
		loop @$278
		call near emit_byte_
		jmp SHORT @$276

;         }
;     }
;     return check_end(p);
@$279:
		mov ax, si
		call near check_end_

; }
		jmp @$29

;
; /*
;  ** Make a string lowercase
;  */
; void to_lowercase(char *p) {
to_lowercase_:
		push bx
		mov bx, ax

;     while (*p) {
@$280:
		mov al, byte [bx]
		test al, al
		jne @$281
		jmp @$204

;         *p = tolower(*p);
@$281:
		xor ah, ah
		call near tolower_
		mov byte [bx], al

;         p++;
		inc bx

;     }
		jmp SHORT @$280

; }
;
; const char *prev_p;
; const char *p;
;
; /*
;  ** Separate a portion of entry up to the first space
;  */
; void separate(void) {
separate_:
		push bx
		push si

;     char *p2;
;
;     while (*p && isspace(*p))
@$282:
		mov bx, word [_p]
		mov al, byte [bx]
		test al, al
		je @$283
		xor ah, ah
		call near isspace_
		test ax, ax
		je @$283

;         p++;
		inc word [_p]
		jmp SHORT @$282

;     prev_p = p;
@$283:
		mov ax, [_p]  ; !!! no word [...]
		mov [_prev_p], ax  ; !!! no word [...]

;     p2 = part;
		mov bx, _part

;     while (*p && !isspace(*p) && *p != ';')
@$284:
		mov si, word [_p]
		mov al, byte [si]
		test al, al
		je @$285
		xor ah, ah
		call near isspace_
		test ax, ax
		jne @$285
		mov si, word [_p]
		cmp byte [si], 0x3b
		je @$285

;         *p2++ = *p++;
		lea ax, [si+1]
		mov [_p], ax  ; !!! no word [...]
		mov al, byte [si]
		mov byte [bx], al
		inc bx
		jmp SHORT @$284

;     *p2 = '\0';
@$285:
		mov byte [bx], 0

;     while (*p && isspace(*p))
@$286:
		mov bx, word [_p]
		mov al, byte [bx]
		test al, al
		jne @$288
@$287:
		jmp @$194
@$288:
		mov bl, al
		xor bh, bh
		mov ax, bx
		call near isspace_
		test ax, ax
		je @$287

;         p++;
		inc word [_p]
		jmp SHORT @$286

; }
;
; char message_buf[512];
;
; void message_flush(struct bbprintf_buf *bbb) {
message_flush_:
		push bx
		push cx
		push dx

;     const int size = message_bbb.p - message_buf;
		mov cx, word [_message_bbb+4]
		sub cx, _message_buf

;     (void)bbb;  /* message_bbb. */
;     if (size) {
		jne @$290
@$289:
		jmp @$162

;         if (message_bbb.data) (void)!write(2 /* stderr */, message_buf, size);
@$290:
		cmp word [_message_bbb+6], BYTE 0
		je @$291
		mov bx, cx
		mov dx, _message_buf
		mov ax, 2
		call near write_

;         message_bbb.p = message_buf;
@$291:
		mov word [_message_bbb+4], _message_buf

;         if (listing_fd >= 0) {
		mov ax, [_listing_fd]  ; !!! no word [...]
		test ax, ax
		jl @$289

;             if (write(listing_fd, message_buf, size) != size) {
		mov bx, cx
		mov dx, _message_buf
		call near write_
		cmp ax, cx
		je @$289

;                 listing_fd = -1;
		mov word [_listing_fd], 0xffff

;                 message(1, "error writing to listing file");
		mov dx, @$543
		mov ax, 1
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
; /*
;  ** Generate a message
;  */
; void message_start(int error) {
message_start_:
		push dx

;     const char *msg_prefix;
;     if (error) {
		test ax, ax
		je @$292

;         msg_prefix = "Error: ";  /* !! Also display current input_filename. */
		mov dx, @$544

;         if (GET_UVALUE(++errors) == 0) --errors;  /* Cappped at max uvalue_t. */
		add word [_errors], BYTE 1
		adc word [_errors+2], BYTE 0
		mov ax, [_errors+2]  ; !!! no word [...]
		or ax, word [_errors]
		jne @$293
		add word [_errors], BYTE -1
		adc word [_errors+2], BYTE -1
		jmp SHORT @$293

;     } else {
;         msg_prefix = "Warning: ";
@$292:
		mov dx, @$545

;         if (GET_UVALUE(++warnings) == 0) --warnings;  /* Cappped at max uvalue_t. */
		add word [_warnings], BYTE 1
		adc word [_warnings+2], ax
		mov ax, [_warnings+2]  ; !!! no word [...]
		or ax, word [_warnings]
		jne @$293
		add word [_warnings], BYTE -1
		adc word [_warnings+2], BYTE -1

;     }
;     if (!message_bbb.data) {
@$293:
		mov ax, [_message_bbb+6]  ; !!! no word [...]
		test ax, ax
		jne @$294

;         message_flush(NULL);  /* Flush listing_fd. */
		call near message_flush_

;         message_bbb.data = (void*)1;
		mov word [_message_bbb+6], 1

;     }
;     bbprintf(&message_bbb, "%s", msg_prefix);
@$294:
		push dx
		mov ax, @$546
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

; }
		pop dx
		ret

;
; void message_end(void) {
;     if (line_number) {
;       /* We must use \r\n, because this will end up on stderr, and on DOS
;        * with O_BINARY, just a \n doesn't break the line properly.
;        */
;       bbprintf(&message_bbb, " at line %u\r\n", line_number);
;     } else {
;       bbprintf(&message_bbb, "\r\n");
@$295:
		mov ax, @$548
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 4

;     }
;     message_flush(NULL);
@$296:
		xor ax, ax
		call near message_flush_

;     message_bbb.data = (void*)0;  /* Write subsequent bytes to listing_fd only (no stderr). */
		xor ax, ax
		mov [_message_bbb+6], ax  ; !!! no word [...]

; }
		ret

;
; void message(int error, const char *message) {
message_:
		call near message_start_

;     message_start(error);
;     bbprintf(&message_bbb, "%s", message);
		push dx
		mov ax, @$546
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;     message_end();
message_end_:
		mov ax, [_line_number+2]  ; !!! no word [...]
		or ax, word [_line_number]
		je @$295
		push word [_line_number+2]
		push word [_line_number]
		mov ax, @$547
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 8
		jmp SHORT @$296

; }
;
; /*
;  ** Process an instruction
;  */
; void process_instruction(void) {
process_instruction_:
		push bx
		push cx
		push dx
		push si
		push bp
		mov bp, sp
		push ax

;     const char *p2 = NULL, *p3;
;     char c;
;
;     if (strcmp(part, "DB") == 0) {  /* Define 8-bit byte. */
		mov dx, @$549
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$302

;         while (1) {
;             p = avoid_spaces(p);
@$297:
		mov ax, [_p]  ; !!! no word [...]
		call near avoid_spaces_
		mov bx, ax
		mov [_p], ax  ; !!! no word [...]

;             if (*p == '\'' || *p == '"') {    /* ASCII text, quoted. */
		mov al, byte [bx]
		cmp al, 0x27
		je @$298
		cmp al, 0x22
		jne @$305

;                 c = *p++;
@$298:
		mov bx, word [_p]
		lea ax, [bx+1]
		mov [_p], ax  ; !!! no word [...]
		mov al, byte [bx]
		mov byte [bp-2], al

;                 for (p2 = p; *p2 != '\0' && *p2 != c; ++p2) {}
		mov bx, word [_p]
@$299:
		mov al, byte [bx]
		test al, al
		je @$300
		cmp al, byte [bp-2]
		je @$300
		inc bx
		jmp SHORT @$299

;                 p3 = p2;
@$300:
		mov cx, bx

;                 if (*p3 == '\0') {
		cmp byte [bx], 0
		jne @$301

;                     message(1, "Missing close quote");
		mov dx, @$531
		mov ax, 1
		call near message_

;                 } else {
		jmp SHORT @$304

;                     p3 = avoid_spaces(p3 + 1);
@$301:
		lea ax, [bx+1]
		call near avoid_spaces_
		mov si, ax
		mov cx, ax

;                     if (*p3 != ',' && *p3 != '\0') { --p; goto db_expr; }
		mov al, byte [si]
		cmp al, 0x2c
		je @$303
		test al, al
		je @$303
		dec word [_p]
		jmp SHORT @$305
@$302:
		jmp SHORT @$311

;                     emit_bytes(p, p2 - p);
@$303:
		mov dx, bx
		sub dx, word [_p]
		mov ax, [_p]  ; !!! no word [...]
		call near emit_bytes_

;                 }
;                 p = p3;
@$304:
		mov word [_p], cx

;             } else { db_expr:
		jmp SHORT @$308

;                 p = match_expression(p);
@$305:
		mov ax, [_p]  ; !!! no word [...]
		call near match_expression_
		mov [_p], ax  ; !!! no word [...]

;                 if (p == NULL) {
		test ax, ax
		jne @$307

;                     message(1, "Bad expression");
@$306:
		mov dx, @$550
		mov ax, 1
		call near message_

;                     break;
		jmp @$324

;                 }
;                 emit_byte(instruction_value);
@$307:
		mov ax, [_instruction_value]  ; !!! no word [...]
		call near emit_byte_

;             }
;             if (*p == ',') {
@$308:
		mov bx, word [_p]
		cmp byte [bx], 0x2c
		jne @$309

;                 p++;
		inc bx
		mov word [_p], bx

;                 p = avoid_spaces(p);
		mov ax, bx
		call near avoid_spaces_
		mov bx, ax
		mov [_p], ax  ; !!! no word [...]

;                 if (*p == '\0') break;
		cmp byte [bx], 0
		je @$310
		jmp @$297

;             } else {
;                 check_end(p);
@$309:
		mov ax, bx
		call near check_end_

;                 break;
@$310:
		jmp @$324

;             }
;         }
;         return;
;     } else if ((c = strcmp(part, "DW")) == 0 /* Define 16-bit word. */
@$311:
		mov dx, @$551
		mov ax, _part
		call near strcmp_
		mov byte [bp-2], al
		test al, al
		je @$312
		mov dx, @$552
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$315

; #if CONFIG_VALUE_BITS == 32
;                || strcmp(part, "DD") == 0  /* Define 32-bit quadword. */
;               ) {
; #endif
;         while (1) {
;             p = match_expression(p);
@$312:
		mov ax, [_p]  ; !!! no word [...]
		call near match_expression_
		mov [_p], ax  ; !!! no word [...]

;             if (p == NULL) {
		test ax, ax
		je @$306

;                 message(1, "Bad expression");
;                 break;
;             }
;             emit_byte(instruction_value);
		mov ax, [_instruction_value]  ; !!! no word [...]
		call near emit_byte_

;             emit_byte(instruction_value >> 8);
		mov ax, [_instruction_value]  ; !!! no word [...]
		mov dx, word [_instruction_value+2]
		mov cx, 8
@$313:
		sar dx, 1
		rcr ax, 1
		loop @$313
		call near emit_byte_

; #if CONFIG_VALUE_BITS == 32
;             if (c) {
		cmp byte [bp-2], 0
		je @$314

;                 emit_byte(instruction_value >> 16);
		mov ax, [_instruction_value+2]  ; !!! no word [...]
		call near emit_byte_

;                 emit_byte(instruction_value >> 24);
		mov al, [_instruction_value+3]  ; !!! no byte
		cbw
		call near emit_byte_

;             }
; #endif
;             if (*p == ',') {
@$314:
		mov bx, word [_p]
		cmp byte [bx], 0x2c
		jne @$309

;                 p++;
		inc bx
		mov word [_p], bx

;                 p = avoid_spaces(p);
		mov ax, bx
		call near avoid_spaces_
		mov bx, ax
		mov [_p], ax  ; !!! no word [...]

;                 if (*p == '\0') break;
		cmp byte [bx], 0
		jne @$312
		jmp SHORT @$310

;                 continue;
;             }
;             check_end(p);
;             break;
;         }
;         return;
;     }
;     while (part[0]) {   /* Match against instruction set */
@$315:
		cmp byte [_part], 0
		je @$318

;         p2 = instruction_set;
		mov bx, _instruction_set

;         for (;;) {
;             if (*p2 == '\0') {
@$316:
		cmp byte [bx], 0
		jne @$319

;                 message_start(1);
		mov ax, 1
		call near message_start_

;                 bbprintf(&message_bbb, "Unknown instruction '%s'", part);
		mov ax, _part
		push ax
		mov ax, @$553
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;                 message_end();
@$317:
		call near message_end_

;                 goto after_matches;
@$318:
		jmp SHORT @$324

;             }
;             if (strcmp(part, p2) == 0) break;
@$319:
		mov dx, bx
		mov ax, _part
		call near strcmp_
		test ax, ax
		je @$322

;             while (*p2++ != '\0') {}  /* Skip over instruction name. !! TODO(pts): Remove duplication. */
@$320:
		mov si, bx
		inc bx
		cmp byte [si], 0
		jne @$320

;             while (*p2++ != '\0') {}  /* Skip over pattern_and_encode. */
@$321:
		mov si, bx
		inc bx
		cmp byte [si], 0
		jne @$321
		jmp SHORT @$316

;         }
;         while (*p2++ != '\0') {}  /* Skip over instruction name. */
@$322:
		mov si, bx
		inc bx
		cmp byte [si], 0
		jne @$322

;         p3 = p;
		mov cx, word [_p]

;         p = match(p, p2);
		mov dx, bx
		mov ax, cx
		call near match_
		mov [_p], ax  ; !!! no word [...]

;         if (p == NULL) {
		test ax, ax
		jne @$323

;             message_start(1);
		mov ax, 1
		call near message_start_

;             bbprintf(&message_bbb, "Error in instruction '%s %s'", part, p3);
		push cx
		mov ax, _part
		push ax
		mov ax, @$554
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 8
		jmp SHORT @$317

;             message_end();
;             break;
;         }
;         separate();
@$323:
		call near separate_

;     }
		jmp @$315

;   after_matches: ;
; }
@$324:
		mov sp, bp
		pop bp
		jmp @$161

;
; /*
;  ** Reset current address.
;  ** Called anytime the assembler needs to generate code.
;  */
; void reset_address(void) {
reset_address_:
		push dx

;     address = start_address = default_start_address;
		mov ax, [_default_start_address]  ; !!! no word [...]
		mov dx, word [_default_start_address+2]
		mov [_start_address], ax  ; !!! no word [...]
		mov word [_start_address+2], dx
		mov [_address], ax  ; !!! no word [...]
		mov word [_address+2], dx

; }
		pop dx
		ret

;
; /*
;  ** Include a binary file
;  */
; void incbin(const char *fname) {
incbin_:
		push bx
		push cx
		push dx
		push si
		mov cx, ax

;     int input_fd;
;     int size;
;
;     if ((input_fd = open2(fname, O_RDONLY | O_BINARY)) < 0) {
		xor dx, dx
		call near open2_
		mov si, ax
		test ax, ax
		jge @$325

;         message_start(1);
		mov ax, 1
		call near message_start_

;         bbprintf(&message_bbb, "Error: Cannot open '%s' for input", fname);
		push cx
		mov ax, @$555
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;         message_end();
		call near message_end_

;         return;
		jmp @$161

;     }
;
;     message_flush(NULL);  /* Because we reuse message_buf below. */
@$325:
		xor ax, ax
		call near message_flush_

;     g = NULL;  /* Doesn't make an actual difference, incbin is called too late to append to incbin anyway. */
		xor ax, ax
		mov [_g], ax  ; !!! no word [...]

;     while ((size = read(input_fd, message_buf, sizeof(message_buf))) > 0) {
@$326:
		mov bx, 0x200
		mov dx, _message_buf
		mov ax, si
		call near read_
		test ax, ax
		jle @$327

;         emit_bytes(message_buf, size);
		mov dx, ax
		mov ax, _message_buf
		call near emit_bytes_

;     }
		jmp SHORT @$326

;     if (size < 0) {
@$327:
		jge @$328

;         message_start(1);
		mov ax, 1
		call near message_start_

;         bbprintf(&message_bbb, "Error: Error reading from '%s'", fname);
		push cx
		mov ax, @$556
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;         message_end();
		call near message_end_

;     }
;     close(input_fd);
@$328:
		mov ax, si
		call near close_

; }
		jmp @$161

;
; char line_buf[512];
;
; #if !CONFIG_CPU_UNALIGN
; struct guess_align_assembly_info_helper { off_t o; char c; };
; typedef char guess_align_assembly_info[sizeof(struct guess_align_assembly_info_helper) - sizeof(off_t)];
; #endif
;
; struct assembly_info {
;     off_t file_offset;  /* Largest alignment first, to save size. */
;     uvalue_t level;
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
; char assembly_stack[512];
; #else
; struct assembly_info assembly_stack[(512 + sizeof(struct assembly_info) - 1) / sizeof(struct assembly_info)];
; #endif
; struct assembly_info *assembly_p;  /* = (struct assembly_info*)assembly_stack; */
;
; static struct assembly_info *assembly_push(const char *input_filename) {
assembly_push_:
		push bx
		push cx
		push dx
		mov dx, ax

;     const int input_filename_len = strlen(input_filename);
		call near strlen_
		mov cx, ax

; #if !CONFIG_CPU_UNALIGN
;     int extra_nul_count = (sizeof(guess_align_assembly_info) - ((unsigned)(size_t)&((struct assembly_info*)0)->input_filename + input_filename_len + 1) % sizeof(guess_align_assembly_info)) % sizeof(guess_align_assembly_info);
; #endif
;     struct assembly_info *aip;
;     if ((size_t)(((char*)&assembly_p->input_filename + input_filename_len) - (char*)assembly_stack) >= sizeof(assembly_stack)) return NULL;  /* Out of assembly_stack memory. */
		mov bx, word [_assembly_p]
		lea ax, [bx+0x11]
		add ax, cx
		sub ax, _assembly_stack
		cmp ax, 0x200
		jb @$329
		xor bx, bx
		jmp SHORT @$330

;     assembly_p->level = 1;
@$329:
		mov word [bx+4], 1
		mov word [bx+6], 0

;     assembly_p->avoid_level = 0;
		mov bx, word [_assembly_p]
		mov word [bx+8], 0
		mov word [bx+0xa], 0

;     assembly_p->line_number = 0;
		mov bx, word [_assembly_p]
		mov word [bx+0xc], 0
		mov word [bx+0xe], 0

;     assembly_p->file_offset = 0;
		mov bx, word [_assembly_p]
		mov word [bx], 0
		mov word [bx+2], 0

;     aip = assembly_p;
		mov bx, word [_assembly_p]

;     assembly_p->zero = 0;
		mov byte [bx+0x10], 0

;     strcpy(assembly_p->input_filename, input_filename);
		mov ax, [_assembly_p]  ; !!! no word [...]
		db 0x83, 0xC0, 0x11  ; !!! add ax, BYTE 0x11
		call near strcpy_

;     assembly_p = (struct assembly_info*)((char*)&assembly_p->input_filename + 1 + input_filename_len);
		mov ax, [_assembly_p]  ; !!! no word [...]
		db 0x83, 0xC0, 0x12  ; !!! add ax, BYTE 0x12
		add ax, cx
		mov [_assembly_p], ax  ; !!! no word [...]

; #if !CONFIG_CPU_UNALIGN
;     for (; extra_nul_count > 0; --extra_nul_count, *(char*)assembly_p = '\0', assembly_p = (struct assembly_info*)((char*)(assembly_p) + 1)) {}
; #endif
;     return aip;
; }
@$330:
		mov ax, bx
		jmp @$162

;
; static struct assembly_info *assembly_pop(struct assembly_info *aip) {
assembly_pop_:
		push bx

;     char *p;
;     if (aip == (struct assembly_info*)assembly_stack) return NULL;
		cmp ax, _assembly_stack
		jne @$331
		xor ax, ax
		pop bx
		ret

;     assembly_p = aip;
@$331:
		mov [_assembly_p], ax  ; !!! no word [...]

;     p = (char*)aip;
;     if (*--p != '\0') {
		mov bx, ax
		dec bx
		cmp byte [bx], 0
		jne @$333

;         /* TODO(pts): If DEBUG, assert it. */
;     } else {
; #if CONFIG_CPU_UNALIGN
;         --p;
@$332:
		dec bx

; #else
;         for (; *p == '\0'; --p) {}
; #endif
;         for (; *p != '\0'; --p) {}  /* Find ->zero with value '\0', preceding ->input_filename. */
		cmp byte [bx], 0
		jne @$332

;         aip = (struct assembly_info*)(p - (int)(size_t)&((struct assembly_info*)0)->zero);
		lea ax, [bx-0x10]

;     }
;     return aip;
; }
@$333:
		pop bx
		ret

;
; #if CONFIG_VALUE_BITS == 32 && IS_VALUE_LONG  /* Example: __DOSMC__. */
; #define FMT_05U "%05s"
; #define GET_FMT_U_VALUE(value) get_fmt_u_value(value)  /* Only one of this works in a single bbprintf(...), because get_fmt_u_value(...) uses a static, global buffer. */
; /* Returns uvalue_t formatted as a decimal, '\0'-terminated string.
;  * The returned pointer points to within a static, global buffer.
;  * We can't use bbprintf(...), because it supports only int size, and here sizeof(uvalue_t) > sizeof(int).
;  */
; static const char *get_fmt_u_value(uvalue_t u) {
get_fmt_u_value_:
		push bx
		push cx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		mov di, ax
		mov si, dx

;     static char buf[sizeof(u) * 3 + 1];  /* Long enough for a decimal representation. */
;     char *p = buf + sizeof(buf) - 1;
		;mov word [bp-BYTE 2], @$622  ; !!! Syntax error with BYTE, generates longer instruction without BYTE in NASM 0.98.39.
		db 0xC7, 0x46, -2
		dw @$622

;     *p = '\0';
		mov byte [@$622], 0

;     do {
;         *--p = '0' + (unsigned char)(u % 10);
@$334:
		mov ax, di
		mov dx, si
		mov bx, 0xa
		xor cx, cx
		call near __U4D
		xor bh, bh
		lea ax, [bx+0x30]
		dec word [bp-2]
		mov bx, word [bp-2]
		mov byte [bx], al

;         u /= 10;
		mov ax, di
		mov dx, si
		mov bx, 0xa
		xor cx, cx
		call near __U4D
		mov di, ax
		mov si, dx

;     } while (u != 0);
		mov ax, dx
		or ax, di
		jne @$334

;     return p;
; }
		mov ax, word [bp-2]
		jmp @$29

; #else
; #define FMT_05U "%05u"
; #define GET_FMT_U_VALUE(value) (value)
; #endif
;
; /*
;  ** Do an assembler step
;  */
; void do_assembly(const char *input_filename) {
do_assembly_:
		push bx
		push cx
		push dx
		push si
		push di
		push bp
		mov bp, sp
		sub sp, BYTE 0x14
		push ax

;     struct assembly_info *aip;
;     const char *p3;
;     char *line;
;     char *linep;
;     char *liner;
;     char *line_rend;
;     uvalue_t level;
;     uvalue_t avoid_level;
;     int times;
;     int base;
;     int include;
;     int align;
;     int got;
;     int input_fd;
;
;     assembly_p = (struct assembly_info*)assembly_stack;  /* Clear the stack. */
		mov word [_assembly_p], _assembly_stack

;
;   do_assembly_push:
;     line_number = 0;  /* Global variable. */
@$335:
		xor ax, ax
		mov [_line_number], ax  ; !!! no word [...]
		mov [_line_number+2], ax  ; !!! no word [...]

;     if (!(aip = assembly_push(input_filename))) {
		mov ax, word [bp-0x16]
		call near assembly_push_
		mov si, ax
		test ax, ax
		jne @$336

;         message(1, "assembly stack overflow, too many pending %INCLUDE files");
		mov dx, @$557
		mov ax, 1
		call near message_

;         return;
		jmp @$160

;     }
;
;   do_open_again:
;     line_number = 0;  /* Global variable. */
@$336:
		xor ax, ax
		mov [_line_number], ax  ; !!! no word [...]
		mov [_line_number+2], ax  ; !!! no word [...]

;     if ((input_fd = open2(aip->input_filename, O_RDONLY | O_BINARY)) < 0) {
		lea bx, [si+0x11]
		xor dx, dx
		mov ax, bx
		call near open2_
		mov word [bp-0x10], ax
		test ax, ax
		jge @$338

;         message_start(1);
		mov ax, 1
		call near message_start_

;         bbprintf(&message_bbb, "cannot open '%s' for input", aip->input_filename);
		push bx
		mov ax, @$558
@$337:
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;         message_end();
		call near message_end_

;         return;
		jmp @$160

;     }
;     if (aip->file_offset != 0 && lseek(input_fd, aip->file_offset, SEEK_SET) != aip->file_offset) {
@$338:
		mov bx, word [si+2]
		or bx, word [si]
		je @$340
		mov bx, word [si]
		mov cx, word [si+2]
		xor dx, dx
		call near lseek_
		cmp dx, word [si+2]
		jne @$339
		cmp ax, word [si]
		je @$340

;         message_start(1);
@$339:
		mov ax, 1
		call near message_start_

;         bbprintf(&message_bbb, "cannot seek in '%s'", input_filename);
		push word [bp-0x16]
		mov ax, @$559
		jmp SHORT @$337

;         message_end();
;         return;
;     }
;     level = aip->level;
@$340:
		mov ax, word [si+4]
		mov word [bp-6], ax
		mov ax, word [si+6]
		mov word [bp-2], ax

;     avoid_level = aip->avoid_level;
		mov ax, word [si+8]
		mov word [bp-4], ax
		mov di, word [si+0xa]

;     line_number = aip->line_number;
		mov ax, word [si+0xc]
		mov dx, word [si+0xe]
		mov [_line_number], ax  ; !!! no word [...]
		mov [_line_number+2], dx  ; !!! no word [...]

;
;     global_label[0] = '\0';
		mov byte [_global_label], 0

;     base = 0;
;     linep = line_rend = line_buf;
		mov ax, _line_buf
		mov word [bp-8], ax
		mov word [bp-0xe], ax

;     while (linep) {  /* Read and process next line from input. */
@$341:
		mov ax, word [bp-0xe]
		test ax, ax
		je @$345

;         for (p = line = linep; p != line_rend && *p != '\n'; ++p) {}
		mov word [bp-0xa], ax
		mov [_p], ax  ; !!! no word [...]
@$342:
		mov ax, [_p]  ; !!! no word [...]
		cmp ax, word [bp-8]
		je @$343
		mov bx, ax
		cmp byte [bx], 0xa
		je @$343
		inc bx
		mov word [_p], bx
		jmp SHORT @$342

;         if (p == line_rend) {
@$343:
		mov ax, [_p]  ; !!! no word [...]
		cmp ax, word [bp-8]
		jne @$349

;             if (line != line_buf) {
		;mov word [bp-BYTE 2], @$622  ; !!! Syntax error with BYTE, generates longer instruction without BYTE in NASM 0.98.39.
		;cmp word [bp-BYTE 0xa], _line_buf  ; !!! Syntax error with BYTE, generates longer instruction without BYTE in NASM 0.98.39.
		db 0x81, 0x7E, -0xa
		dw _line_buf
		je @$347

;                 if (line_rend - line > (int)(sizeof(line_buf) - (sizeof(line_buf) >> 2))) goto line_too_long;  /* Too much copy per line (thus too slow). This won't be triggered, because the `>= MAX_SIZE' check triggers first. */
		sub ax, word [bp-0xa]
		cmp ax, 0x180
		jg @$351

;                 for (liner = line_buf, p = line; p != line_rend; *liner++ = *p++) {}
		mov dx, _line_buf
		mov ax, word [bp-0xa]
		mov [_p], ax  ; !!! no word [...]
@$344:
		mov ax, [_p]  ; !!! no word [...]
		cmp ax, word [bp-8]
		je @$346
		mov bx, ax
		inc ax
		mov [_p], ax  ; !!! no word [...]
		mov al, byte [bx]
		mov bx, dx
		mov byte [bx], al
		inc dx
		jmp SHORT @$344
@$345:
		jmp @$476

;                 p = line_rend = liner;
@$346:
		mov word [bp-8], dx
		mov word [_p], dx

;                 line = linep = line_buf;
		;mov word [bp-BYTE 0xa], _line_buf  ; !!! Syntax error with BYTE, generates longer instruction without BYTE in NASM 0.98.39.
		db 0xC7, 0x46, -0xa,
		dw _line_buf

;             }
;             if ((got = read(input_fd, line_rend, line_buf + sizeof(line_buf) - line_rend)) < 0) {
@$347:
		mov bx, _line_buf+0x200
		sub bx, word [bp-8]
		mov dx, word [bp-8]
		mov ax, word [bp-0x10]
		call near read_
		test ax, ax
		jge @$350

;                 message(1, "error reading assembly file");
		mov dx, @$560
@$348:
		mov ax, 1
		call near message_

;                 break;
		jmp SHORT @$345
@$349:
		jmp SHORT @$355

;             }
;             if (got == 0) {  /* End of file (EOF). */
@$350:
		jne @$352

;               if (line_rend == line_buf) break;
		mov ax, word [bp-8]
		cmp ax, _line_buf
		je @$345

;               *line_rend = '\0';
		mov bx, ax
		mov byte [bx], 0

;               linep = NULL;
		mov word [bp-0xe], 0

;               goto after_line_read;
		jmp SHORT @$356
@$351:
		jmp @$368

;             }
;             line_rend += got;
@$352:
		add word [bp-8], ax

;             for (; p != line_rend && *p != '\n'; ++p) {}
@$353:
		mov ax, [_p]  ; !!! no word [...]
		cmp ax, word [bp-8]
		je @$354
		mov bx, ax
		cmp byte [bx], 0xa
		je @$354
		inc bx
		mov word [_p], bx
		jmp SHORT @$353

;             if (p == line_rend) goto line_too_long;
@$354:
		mov ax, [_p]  ; !!! no word [...]
		cmp ax, word [bp-8]
		je @$351

;         }
;         *(char*)p = '\0';  /* Change trailing '\n' to '\0'. */
@$355:
		mov bx, word [_p]
		mov byte [bx], 0

;         linep = (char*)p + 1;
		mov ax, [_p]  ; !!! no word [...]
		inc ax
		mov word [bp-0xe], ax

;        after_line_read:
;
;         if (GET_UVALUE(++line_number) == 0) --line_number;  /* Cappped at max uvalue_t. */
@$356:
		add word [_line_number], BYTE 1
		adc word [_line_number+2], BYTE 0
		mov ax, [_line_number+2]  ; !!! no word [...]
		or ax, word [_line_number]
		jne @$357
		add word [_line_number], BYTE -1
		adc word [_line_number+2], BYTE -1

;         p = line;
@$357:
		mov ax, word [bp-0xa]
		mov [_p], ax  ; !!! no word [...]

;         while (*p) {
@$358:
		mov ax, [_p]  ; !!! no word [...]
		mov bx, ax
		cmp byte [bx], 0
		je @$362

;             if (*p == '\'' && *(p - 1) != '\\') {
		cmp byte [bx], 0x27
		jne @$360
		cmp byte [bx-1], 0x5c
		je @$360

;                 p++;
		inc ax
		mov [_p], ax  ; !!! no word [...]

;                 while (*p && *p != '\'' && *(p - 1) != '\\')
@$359:
		mov bx, word [_p]
		mov al, byte [bx]
		test al, al
		je @$365
		cmp al, 0x27
		je @$365
		cmp byte [bx-1], 0x5c
		je @$365

;                     p++;
		inc bx
		mov word [_p], bx
		jmp SHORT @$359

;             } else if (*p == '"' && *(p - 1) != '\\') {
@$360:
		mov ax, [_p]  ; !!! no word [...]
		mov bx, ax
		cmp byte [bx], 0x22
		jne @$363
		cmp byte [bx-1], 0x5c
		je @$363

;                 p++;
		inc ax
		mov [_p], ax  ; !!! no word [...]

;                 while (*p && *p != '"' && *(p - 1) != '\\')
@$361:
		mov bx, word [_p]
		mov al, byte [bx]
		test al, al
		je @$365
		cmp al, 0x22
		je @$365
		cmp byte [bx-1], 0x5c
		je @$365

;                     p++;
		inc bx
		mov word [_p], bx
		jmp SHORT @$361
@$362:
		jmp SHORT @$366

;             } else if (*p == ';') {
@$363:
		mov bx, word [_p]
		cmp byte [bx], 0x3b
		jne @$365

;                 while (*p)
@$364:
		mov bx, word [_p]
		cmp byte [bx], 0
		je @$366

;                     p++;
		inc bx
		mov word [_p], bx
		jmp SHORT @$364

;                 break;
;             }
;             *(char*)p = toupper(*p);
@$365:
		mov bx, word [_p]
		mov al, byte [bx]
		xor ah, ah
		call near toupper_
		mov bx, word [_p]
		mov byte [bx], al

;             p++;
		inc word [_p]

;         }
		jmp @$358

;         if (p != line && *(p - 1) == '\r')
@$366:
		mov ax, [_p]  ; !!! no word [...]
		cmp ax, word [bp-0xa]
		je @$367
		mov bx, ax
		cmp byte [bx-1], 0xd
		jne @$367

;             *(char*)--p = '\0';
		dec bx
		mov word [_p], bx
		mov byte [bx], 0

;         if (p - line >= MAX_SIZE) { line_too_long:
@$367:
		mov ax, [_p]  ; !!! no word [...]
		sub ax, word [bp-0xa]
		cmp ax, 0x100
		jl @$369

;             message(1, "assembly line too long");
@$368:
		mov dx, @$561
		jmp @$348

;             break;
;         }
;
;         base = address;
@$369:
		mov ax, [_address]  ; !!! no word [...]
		mov word [bp-0x14], ax

;         g = generated;
		mov word [_g], _generated

;         include = 0;
		mov word [bp-0x12], 0

;
;         while (1) {
;             p = line;
		mov ax, word [bp-0xa]
		mov [_p], ax  ; !!! no word [...]

;             separate();
		call near separate_

;             if (part[0] == '\0' && (*p == '\0' || *p == ';'))    /* Empty line */
		cmp byte [_part], 0
		jne @$370
		mov bx, word [_p]
		mov al, byte [bx]
		test al, al
		je @$371
		cmp al, 0x3b
		je @$371

;                 break;
;             if (part[0] != '\0' && part[strlen(part) - 1] == ':') {  /* Label */
@$370:
		cmp byte [_part], 0
		je @$372
		mov ax, _part
		call near strlen_
		mov bx, ax
		cmp byte [bx+_part-1], 0x3a
		jne @$372

;                 part[strlen(part) - 1] = '\0';
		mov ax, _part
		call near strlen_
		mov bx, ax
		mov byte [bx+_part-1], 0

;                 if (part[0] == '.') {
		cmp byte [_part], 0x2e
		jne @$373

;                     strcpy(name, global_label);
		mov dx, _global_label
		mov ax, _name
		call near strcpy_

;                     strcat(name, part);
		mov dx, _part
		mov ax, _name
		call near strcat_

;                 } else {
		jmp SHORT @$374
@$371:
		jmp @$464
@$372:
		jmp @$394

;                     strcpy(name, part);
@$373:
		mov dx, _part
		mov ax, _name
		call near strcpy_

;                     strcpy(global_label, name);
		mov dx, _name
		mov ax, _global_label
		call near strcpy_

;                 }
;                 separate();
@$374:
		call near separate_

;                 if (avoid_level == 0 || level < avoid_level) {
		mov ax, word [bp-4]
		or ax, di
		je @$375
		mov ax, word [bp-2]
		cmp di, ax
		ja @$375
		jne @$372
		mov ax, word [bp-6]
		cmp ax, word [bp-4]
		jae @$372

;                     if (strcmp(part, "EQU") == 0) {
@$375:
		mov dx, @$562
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$380

;                         p = match_expression(p);
		mov ax, [_p]  ; !!! no word [...]
		call near match_expression_
		mov [_p], ax  ; !!! no word [...]

;                         if (p == NULL) {
		test ax, ax
		jne @$376

;                             message(1, "bad expression");
		mov dx, @$563
		jmp @$430

;                         } else {
;                             if (assembler_step == 1) {
@$376:
		cmp word [_assembler_step], BYTE 1
		jne @$381

;                                 if (find_label(name)) {
		mov ax, _name
		call near find_label_
		test dx, dx
		jne @$377
		test ax, ax
		je @$379

;                                     message_start(1);
@$377:
		mov ax, 1
		call near message_start_

;                                     bbprintf(&message_bbb, "Redefined label '%s'", name);
		mov ax, _name
		push ax
		mov ax, @$564
@$378:
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;                                     message_end();
		call near message_end_

;                                 } else {
		jmp @$404

;                                     last_label = define_label(name, instruction_value);
@$379:
		mov bx, word [_instruction_value]
		mov cx, word [_instruction_value+2]
		mov ax, _name
		call near define_label_
		mov [_last_label], ax  ; !!! no word [...]
		mov word [_last_label+2], dx

;                                 }
		jmp @$404
@$380:
		jmp SHORT @$385

;                             } else {
;                                 last_label = find_label(name);
@$381:
		mov ax, _name
		call near find_label_
		mov bx, ax
		mov ax, dx
		mov word [_last_label], bx
		mov word [_last_label+2], dx

;                                 if (last_label == NULL) {
		test dx, dx
		jne @$382
		test bx, bx
		jne @$382

;                                     message_start(1);
		mov ax, 1
		call near message_start_

;                                     bbprintf(&message_bbb, "Inconsistency, label '%s' not found", name);
		mov ax, _name
		push ax
		mov ax, @$565
		jmp SHORT @$378

;                                     message_end();
;                                 } else {
;                                     if (last_label->value != instruction_value) {
@$382:
		mov es, dx
		es mov dx, word [bx+5]
		es mov ax, word [bx+7]
		cmp ax, word [_instruction_value+2]
		jne @$383
		cmp dx, word [_instruction_value]
		je @$384

; #ifdef DEBUG
; /*                                        message_start(1); bbprintf(&message_bbb, "Woops: label '%s' changed value from %04x to %04x", last_label->name, last_label->value, instruction_value); message_end(); */
; #endif
;                                         change = 1;
@$383:
		mov word [_change], 1

;                                     }
;                                     last_label->value = instruction_value;
@$384:
		les bx, [_last_label]
		mov ax, [_instruction_value]  ; !!! no word [...]
		mov dx, word [_instruction_value+2]
		es mov word [bx+5], ax
		es mov word [bx+7], dx
		jmp @$404

;                                 }
;                             }
;                             check_end(p);
;                         }
;                         break;
;                     }
;                     if (first_time == 1) {
@$385:
		cmp word [_first_time], BYTE 1
		jne @$386

; #ifdef DEBUG
;                         /*                        message_start(1); bbprintf(&message_bbb, "First time '%s'", line); message_end();  */
; #endif
;                         first_time = 0;
		xor ax, ax
		mov [_first_time], ax  ; !!! no word [...]

;                         reset_address();
		call near reset_address_

;                     }
;                     if (assembler_step == 1) {
@$386:
		cmp word [_assembler_step], BYTE 1
		jne @$390

;                         if (find_label(name)) {
		mov ax, _name
		call near find_label_
		test dx, dx
		jne @$387
		test ax, ax
		je @$389

;                             message_start(1);
@$387:
		mov ax, 1
		call near message_start_

;                             bbprintf(&message_bbb, "Redefined label '%s'", name);
		mov ax, _name
		push ax
		mov ax, @$564
@$388:
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;                             message_end();
		call near message_end_

;                         } else {
		jmp SHORT @$394

;                             last_label = define_label(name, address);
@$389:
		mov bx, word [_address]
		mov cx, word [_address+2]
		mov ax, _name
		call near define_label_
		mov [_last_label], ax  ; !!! no word [...]
		mov word [_last_label+2], dx

;                         }
		jmp SHORT @$394

;                     } else {
;                         last_label = find_label(name);
@$390:
		mov ax, _name
		call near find_label_
		mov bx, ax
		mov ax, dx
		mov word [_last_label], bx
		mov word [_last_label+2], dx

;                         if (last_label == NULL) {
		test dx, dx
		jne @$391
		test bx, bx
		jne @$391

;                             message_start(1);
		mov ax, 1
		call near message_start_

;                             bbprintf(&message_bbb, "Inconsistency, label '%s' not found", name);
		mov ax, _name
		push ax
		mov ax, @$565
		jmp SHORT @$388

;                             message_end();
;                         } else {
;                             if (last_label->value != address) {
@$391:
		mov es, dx
		es mov dx, word [bx+5]
		es mov ax, word [bx+7]
		cmp ax, word [_address+2]
		jne @$392
		cmp dx, word [_address]
		je @$393

; #ifdef DEBUG
; /*                                message_start(1); bbprintf(&message_bbb, "Woops: label '%s' changed value from %04x to %04x", last_label->name, last_label->value, address); message_end(); */
; #endif
;                                 change = 1;
@$392:
		mov word [_change], 1

;                             }
;                             last_label->value = address;
@$393:
		les bx, [_last_label]
		mov ax, [_address]  ; !!! no word [...]
		mov dx, word [_address+2]
		es mov word [bx+5], ax
		es mov word [bx+7], dx

;                         }
;
;                     }
;                 }
;             }
;             if (strcmp(part, "%IF") == 0) {
@$394:
		mov dx, @$566
		mov ax, _part
		call near strcmp_
		mov dx, word [bp-6]
		add dx, BYTE 1
		mov word [bp-0xc], dx
		mov cx, word [bp-2]
		adc cx, BYTE 0
		test ax, ax
		jne @$398

;                 if (GET_UVALUE(++level) == 0) { if_too_deep:
		mov ax, dx
		mov word [bp-6], dx
		mov word [bp-2], cx
		or ax, cx
		jne @$396

;                     message(1, "%IF too deep");
@$395:
		mov dx, @$567

;                     goto close_return;
		jmp @$478

;                 }
;                 if (avoid_level != 0 && level >= avoid_level)
@$396:
		mov ax, word [bp-4]
		or ax, di
		je @$397
		cmp cx, di
		ja @$406
		jne @$397
		mov ax, dx
		cmp ax, word [bp-4]
		jae @$406

;                     break;
;                 undefined = 0;
@$397:
		xor ax, ax
		mov [_undefined], ax  ; !!! no word [...]

;                 p = match_expression(p);
		mov ax, [_p]  ; !!! no word [...]
		call near match_expression_
		mov [_p], ax  ; !!! no word [...]

;                 if (p == NULL) {
		test ax, ax
		jne @$399

;                     message(1, "Bad expression");
		mov dx, @$550

;                 } else if (undefined) {
		jmp SHORT @$400
@$398:
		jmp SHORT @$407
@$399:
		cmp word [_undefined], BYTE 0
		je @$401

;                     message(1, "Cannot use undefined labels");
		mov dx, @$568
@$400:
		mov ax, 1
		call near message_

;                 }
;                 if (GET_UVALUE(instruction_value) != 0) {
@$401:
		mov ax, [_instruction_value+2]  ; !!! no word [...]
		or ax, word [_instruction_value]
@$402:
		jne @$404

;                     ;
;                 } else {
;                     avoid_level = level;
@$403:
		mov ax, word [bp-6]
		mov word [bp-4], ax
		mov di, word [bp-2]

;                 }
@$404:
		mov ax, [_p]  ; !!! no word [...]
@$405:
		call near check_end_
@$406:
		jmp @$464

;                 check_end(p);
;                 break;
;             }
;             if (strcmp(part, "%IFDEF") == 0) {
@$407:
		mov dx, @$569
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$409

;                 if (GET_UVALUE(++level) == 0) goto if_too_deep;
		mov ax, word [bp-0xc]
		mov word [bp-6], ax
		mov word [bp-2], cx
		or ax, cx
		je @$395

;                 if (avoid_level != 0 && level >= avoid_level)
		mov ax, word [bp-4]
		or ax, di
		je @$408
		cmp cx, di
		ja @$406
		jne @$408
		mov ax, word [bp-0xc]
		cmp ax, word [bp-4]
		jae @$406

;                     break;
;                 separate();
@$408:
		call near separate_

;                 if (find_label(part) != NULL) {
		mov ax, _part
		call near find_label_
		test dx, dx
		jne @$404
		test ax, ax

;                     ;
;                 } else {
		jmp SHORT @$402

;                     avoid_level = level;
;                 }
;                 check_end(p);
;                 break;
;             }
;             if (strcmp(part, "%IFNDEF") == 0) {
@$409:
		mov dx, @$570
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$416

;                 if (GET_UVALUE(++level) == 0) goto if_too_deep;
		mov ax, word [bp-0xc]
		mov word [bp-6], ax
		mov word [bp-2], cx
		or ax, cx
		jne @$410
		jmp @$395

;                 if (avoid_level != 0 && level >= avoid_level)
@$410:
		mov ax, word [bp-4]
		or ax, di
		je @$411
		cmp cx, di
		ja @$406
		jne @$411
		mov ax, word [bp-0xc]
		cmp ax, word [bp-4]
		jae @$406

;                     break;
;                 separate();
@$411:
		call near separate_

;                 if (find_label(part) == NULL) {
		mov ax, _part
		call near find_label_
		test dx, dx
		je @$413
@$412:
		jmp @$403
@$413:
		test ax, ax
		jne @$415
@$414:
		jmp @$404

;                     ;
;                 } else {
;                     avoid_level = level;
;                 }
@$415:
		jmp SHORT @$412

;                 check_end(p);
;                 break;
;             }
;             if (strcmp(part, "%ELSE") == 0) {
@$416:
		mov dx, @$571
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$420

;                 if (level == 1) {
		cmp word [bp-2], BYTE 0
		jne @$417
		cmp word [bp-6], BYTE 1
		jne @$417

;                     message(1, "%ELSE without %IF");
		mov dx, @$572
		jmp @$478

;                     goto close_return;
;                 }
;                 if (avoid_level != 0 && level > avoid_level)
@$417:
		mov ax, word [bp-4]
		or ax, di
		je @$418
		mov ax, word [bp-2]
		cmp di, ax
		jb @$423
		jne @$418
		mov ax, word [bp-6]
		cmp ax, word [bp-4]
		ja @$423

;                     break;
;                 if (avoid_level == level) {
@$418:
		cmp di, word [bp-2]
		jne @$419
		mov ax, word [bp-4]
		cmp ax, word [bp-6]
		jne @$419

;                     avoid_level = 0;
		mov word [bp-4], 0
		xor di, di

;                 } else if (avoid_level == 0) {
		jmp SHORT @$414
@$419:
		mov ax, word [bp-4]
		or ax, di

;                     avoid_level = level;
;                 }
		jmp @$402

;                 check_end(p);
;                 break;
;             }
;             if (strcmp(part, "%ENDIF") == 0) {
@$420:
		mov dx, @$573
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$424

;                 if (avoid_level == level)
		cmp di, word [bp-2]
		jne @$421
		mov ax, word [bp-4]
		cmp ax, word [bp-6]
		jne @$421

;                     avoid_level = 0;
		mov word [bp-4], 0
		xor di, di

;                 if (--level == 0) {
@$421:
		add word [bp-6], BYTE -1
		adc word [bp-2], BYTE -1
		mov ax, word [bp-2]
		or ax, word [bp-6]
		je @$422
		jmp @$404

;                     message(1, "%ENDIF without %IF");
@$422:
		mov dx, @$574
		jmp @$478
@$423:
		jmp @$464

;                     goto close_return;
;                 }
;                 check_end(p);
;                 break;
;             }
;             if (avoid_level != 0 && level >= avoid_level) {
@$424:
		mov ax, word [bp-4]
		or ax, di
		je @$425
		mov ax, word [bp-2]
		cmp di, ax
		jb @$423
		jne @$425
		mov ax, word [bp-6]
		cmp ax, word [bp-4]
		jae @$423

; #ifdef DEBUG
;                 /* message_start(); bbprintf(&message_bbb, "Avoiding '%s'", line); message_end(); */
; #endif
;                 break;
;             }
;             if (strcmp(part, "USE16") == 0) {
@$425:
		mov dx, @$575
		mov ax, _part
		call near strcmp_
		test ax, ax
		je @$423

;                 break;
;             }
;             if (strcmp(part, "CPU") == 0) {
		mov dx, @$576
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$426

;                 p = avoid_spaces(p);
		mov ax, [_p]  ; !!! no word [...]
		call near avoid_spaces_
		mov [_p], ax  ; !!! no word [...]

;                 if (memcmp(p, "8086", 4) != 0)
		mov bx, 4
		mov dx, @$577
		call near memcmp_
		test ax, ax
		je @$423

;                     message(1, "Unsupported processor requested");
		mov dx, @$578
		jmp SHORT @$430

;                 break;
;             }
;             if (strcmp(part, "BITS") == 0) {
@$426:
		mov dx, @$579
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$433

;                 p = avoid_spaces(p);
		mov ax, [_p]  ; !!! no word [...]
		call near avoid_spaces_
		mov [_p], ax  ; !!! no word [...]

;                 undefined = 0;
		mov word [_undefined], 0

;                 p = match_expression(p);
		call near match_expression_
		mov [_p], ax  ; !!! no word [...]

;                 if (p == NULL) {
		test ax, ax
		jne @$428

;                     message(1, "Bad expression");
@$427:
		mov dx, @$550
		jmp SHORT @$430

;                 } else if (undefined) {
@$428:
		cmp word [_undefined], BYTE 0
		je @$431

;                     message(1, "Cannot use undefined labels");
@$429:
		mov dx, @$568
@$430:
		mov ax, 1
		jmp @$459

;                 } else if (GET_UVALUE(instruction_value) != 16) {
@$431:
		cmp word [_instruction_value+2], BYTE 0
		jne @$432
		cmp word [_instruction_value], BYTE 0x10
		jne @$432
		jmp @$405

;                     message(1, "Unsupported BITS requested");
@$432:
		mov dx, @$580
		jmp SHORT @$430

;                 } else {
;                     check_end(p);
;                 }
;                 break;
;             }
;             if (strcmp(part, "%INCLUDE") == 0) {
@$433:
		mov dx, @$581
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$437

;                 separate();
		call near separate_

;                 check_end(p);
		mov ax, [_p]  ; !!! no word [...]
		call near check_end_

;                 if ((part[0] != '"' && part[0] != '\'') || part[strlen(part) - 1] != part[0]) {
		mov al, [_part]  ; !!! no byte
		cmp al, 0x22
		je @$434
		cmp al, 0x27
		jne @$435
@$434:
		mov ax, _part
		call near strlen_
		mov bx, ax
		mov al, byte [bx+_part-1]
		cmp al, byte [_part]
		je @$436

;                     message(1, "Missing quotes on %include");
@$435:
		mov dx, @$582
		jmp SHORT @$430

;                     break;
;                 }
;                 include = 1;
@$436:
		mov word [bp-0x12], 1

;                 break;
		jmp @$464

;             }
;             if (strcmp(part, "INCBIN") == 0) {
@$437:
		mov dx, @$583
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$441

;                 separate();
		call near separate_

;                 check_end(p);
		mov ax, [_p]  ; !!! no word [...]
		call near check_end_

;                 if ((part[0] != '"' && part[0] != '\'') || part[strlen(part) - 1] != part[0]) {
		mov al, [_part]  ; !!! no byte
		cmp al, 0x22
		je @$438
		cmp al, 0x27
		jne @$439
@$438:
		mov ax, _part
		call near strlen_
		mov bx, ax
		mov al, byte [bx+_part-1]
		cmp al, byte [_part]
		je @$440

;                     message(1, "Missing quotes on incbin");
@$439:
		mov dx, @$584
		jmp @$430

;                     break;
;                 }
;                 include = 2;
@$440:
		mov word [bp-0x12], 2

;                 break;
		jmp @$464

;             }
;             if (strcmp(part, "ORG") == 0) {
@$441:
		mov dx, @$585
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$446

;                 p = avoid_spaces(p);
		mov ax, [_p]  ; !!! no word [...]
		call near avoid_spaces_
		mov [_p], ax  ; !!! no word [...]

;                 undefined = 0;
		mov word [_undefined], 0

;                 p = match_expression(p);
		call near match_expression_
		mov [_p], ax  ; !!! no word [...]

;                 if (p == NULL) {
		test ax, ax
		jne @$442
		jmp @$427

;                     message(1, "Bad expression");
;                 } else if (undefined) {
@$442:
		cmp word [_undefined], BYTE 0
		je @$443
		jmp @$429

;                     message(1, "Cannot use undefined labels");
;                 } else {
;                     if (first_time == 1) {
@$443:
		cmp word [_first_time], BYTE 1
		jne @$444

;                         first_time = 0;
		xor ax, ax
		mov [_first_time], ax  ; !!! no word [...]

;                         address = instruction_value;
		mov ax, [_instruction_value]  ; !!! no word [...]
		mov dx, word [_instruction_value+2]
		mov [_address], ax  ; !!! no word [...]
		mov word [_address+2], dx

;                         start_address = instruction_value;
		mov [_start_address], ax  ; !!! no word [...]
		mov word [_start_address+2], dx

;                         base = address;
		mov word [bp-0x14], ax

;                     } else {
		jmp @$404

;                         if (instruction_value < address) {
@$444:
		mov dx, word [_instruction_value]
		mov ax, [_instruction_value+2]  ; !!! no word [...]
		cmp ax, word [_address+2]
		jl @$445
		jne @$447
		cmp dx, word [_address]
		jae @$447

;                             message(1, "Backward address");
@$445:
		mov dx, @$586
		mov ax, 1
		call near message_

;                         } else {
		jmp @$404
@$446:
		jmp SHORT @$451

;                             while (address < instruction_value)
@$447:
		mov dx, word [_address]
		mov ax, [_address+2]  ; !!! no word [...]
		cmp ax, word [_instruction_value+2]
		jl @$450
		je @$449
@$448:
		jmp @$404
@$449:
		cmp dx, word [_instruction_value]
		jae @$448

;                                 emit_byte(0);
@$450:
		xor ax, ax
		call near emit_byte_
		jmp SHORT @$447

;
;                         }
;                     }
;                     check_end(p);
;                 }
;                 break;
;             }
;             if (strcmp(part, "ALIGN") == 0) {
@$451:
		mov dx, @$587
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$456

;                 p = avoid_spaces(p);
		mov ax, [_p]  ; !!! no word [...]
		call near avoid_spaces_
		mov [_p], ax  ; !!! no word [...]

;                 undefined = 0;
		mov word [_undefined], 0

;                 p = match_expression(p);
		call near match_expression_
		mov [_p], ax  ; !!! no word [...]

;                 if (p == NULL) {
		test ax, ax
		jne @$452
		jmp @$427

;                     message(1, "Bad expression");
;                 } else if (undefined) {
@$452:
		cmp word [_undefined], BYTE 0
		je @$453
		jmp @$429

;                     message(1, "Cannot use undefined labels");
;                 } else {
;                     align = address / instruction_value;
@$453:
		mov ax, [_address]  ; !!! no word [...]
		mov dx, word [_address+2]
		mov bx, word [_instruction_value]
		mov cx, word [_instruction_value+2]
		call near __I4D

;                     align = align * instruction_value;
		imul word [_instruction_value]
		mov cx, ax

;                     align = align + instruction_value;
		add cx, word [_instruction_value]

;                     while (address < align)
@$454:
		mov ax, cx
		cwd
		cmp dx, word [_address+2]
		jg @$455
		jne @$448
		cmp ax, word [_address]
		jbe @$448

;                         emit_byte(0x90);
@$455:
		mov ax, 0x90
		call near emit_byte_
		jmp SHORT @$454

;                     check_end(p);
;                 }
;                 break;
;             }
;             if (first_time == 1) {
@$456:
		cmp word [_first_time], BYTE 1
		jne @$457

; #ifdef DEBUG
;                 /* message_start(1); bbprintf(&message_bbb, "First time '%s'", line); message_end(); */
; #endif
;                 first_time = 0;
		xor ax, ax
		mov [_first_time], ax  ; !!! no word [...]

;                 reset_address();
		call near reset_address_

;             }
;             times = 1;
@$457:
		mov cx, 1

;             if (strcmp(part, "TIMES") == 0) {
		mov dx, @$588
		mov ax, _part
		call near strcmp_
		test ax, ax
		jne @$462

;                 undefined = 0;
		mov [_undefined], ax  ; !!! no word [...]

;                 p = match_expression(p);
		mov ax, [_p]  ; !!! no word [...]
		call near match_expression_
		mov [_p], ax  ; !!! no word [...]

;                 if (p == NULL) {
		test ax, ax
		jne @$460

;                     message(1, "Bad expression");
		mov dx, @$550
@$458:
		mov ax, cx
@$459:
		call near message_
		jmp SHORT @$464

;                     break;
;                 }
;                 if (undefined) {
@$460:
		cmp word [_undefined], BYTE 0
		je @$461

;                     message(1, "Cannot use undefined labels");
		mov dx, @$568
		jmp SHORT @$458

;                     break;
;                 }
;                 times = instruction_value;
@$461:
		mov cx, word [_instruction_value]

;                 separate();
		call near separate_

;             }
;             base = address;
@$462:
		mov ax, [_address]  ; !!! no word [...]
		mov word [bp-0x14], ax

;             g = generated;
		mov word [_g], _generated

;             p3 = prev_p;
		mov dx, word [_prev_p]

;             while (times) {
@$463:
		test cx, cx
		je @$464

;                 p = p3;
		mov word [_p], dx

;                 separate();
		call near separate_

;                 process_instruction();
		call near process_instruction_

;                 times--;
		dec cx

;             }
		jmp SHORT @$463

;             break;
;         }
;         if (assembler_step == 2 && listing_fd >= 0) {
@$464:
		cmp word [_assembler_step], BYTE 2
		jne @$468
		cmp word [_listing_fd], BYTE 0
		jl @$468

;             if (first_time)
		cmp word [_first_time], BYTE 0
		je @$465

;                 bbprintf(&message_bbb /* listing_fd */, "      ");
		mov ax, @$589
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 4

;             else
		jmp SHORT @$466

;                 bbprintf(&message_bbb /* listing_fd */, "%04X  ", base);
@$465:
		push word [bp-0x14]
		mov ax, @$590
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;             p = generated;
@$466:
		mov word [_p], _generated

;             while (p < g) {
@$467:
		mov bx, word [_p]
		cmp bx, word [_g]
		jae @$469

;                 bbprintf(&message_bbb /* listing_fd */, "%02X", *p++ & 255);
		lea ax, [bx+1]
		mov [_p], ax  ; !!! no word [...]
		mov al, byte [bx]
		xor ah, ah
		push ax
		mov ax, @$591
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;             }
		jmp SHORT @$467
@$468:
		jmp SHORT @$471

;             while (p < generated + sizeof(generated)) {
@$469:
		cmp word [_p], _generated+8
		jae @$470

;                 bbprintf(&message_bbb /* listing_fd */, "  ");
		mov ax, @$592
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 4

;                 p++;
		inc word [_p]

;             }
		jmp SHORT @$469

;             bbprintf(&message_bbb /* listing_fd */, "  " FMT_05U " %s\r\n", GET_FMT_U_VALUE(line_number), line);
@$470:
		push word [bp-0xa]
		mov ax, [_line_number]  ; !!! no word [...]
		mov dx, word [_line_number+2]
		call near get_fmt_u_value_
		push ax
		mov ax, @$593
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 8

;         }
;         if (include == 1) {
@$471:
		mov ax, word [bp-0x12]
		db 0x83, 0xF8, 1  ; !!! cmp ax, BYTE 1
		jne @$473

;             if (linep != NULL && (aip->file_offset = lseek(input_fd, linep - line_rend, SEEK_CUR)) < 0) {
		mov ax, word [bp-0xe]
		test ax, ax
		je @$472
		sub ax, word [bp-8]
		cwd
		mov cx, dx
		mov dx, 1
		mov bx, ax
		mov ax, word [bp-0x10]
		call near lseek_
		mov word [si], ax
		mov word [si+2], dx
		mov dx, word [si]
		mov ax, word [si+2]
		test ax, ax
		jge @$472

;                 message(1, "Cannot seek in source file");
		mov dx, @$594
		mov ax, 1
		call near message_

;                 close(input_fd);
		mov ax, word [bp-0x10]
		call near close_

;                 return;
		jmp @$160

;             }
;             close(input_fd);
@$472:
		mov ax, word [bp-0x10]
		call near close_

;             aip->level = level;
		mov ax, word [bp-6]
		mov word [si+4], ax
		mov ax, word [bp-2]
		mov word [si+6], ax

;             aip->avoid_level = avoid_level;
		mov ax, word [bp-4]
		mov word [si+8], ax
		mov word [si+0xa], di

;             aip->line_number = line_number;
		mov dx, word [_line_number]
		mov ax, [_line_number+2]  ; !!! no word [...]
		mov word [si+0xc], dx
		mov word [si+0xe], ax

;             part[strlen(part) - 1] = '\0';
		mov ax, _part
		call near strlen_
		mov bx, ax
		mov byte [bx+_part-1], 0

;             input_filename = part + 1;
		;mov word [bp-BYTE 0x16], _part+1  ; !!! Syntax error with BYTE, generates longer instruction without BYTE in NASM 0.98.39.
		db 0xC7, 0x46, -0x16
		dw _part+1

;             goto do_assembly_push;
		jmp @$335

;         } else if (include == 2) {
@$473:
		db 0x83, 0xF8, 2  ; !!! cmp ax, BYTE 2
		je @$475
@$474:
		jmp @$341

;             part[strlen(part) - 1] = '\0';
@$475:
		mov ax, _part
		call near strlen_
		mov bx, ax
		mov byte [bx+_part-1], 0

;             incbin(part + 1);
		mov ax, _part+1
		call near incbin_

;         }
		jmp SHORT @$474

;     }
;     if (level != 1) {
@$476:
		cmp word [bp-2], BYTE 0
		jne @$477
		cmp word [bp-6], BYTE 1
		je @$479

;         message(1, "pending %IF at end of file");
@$477:
		mov dx, @$595
@$478:
		mov ax, 1
		call near message_

;     }
;   close_return:
;     close(input_fd);
@$479:
		mov ax, word [bp-0x10]
		call near close_

;     if ((aip = assembly_pop(aip)) != NULL) goto do_open_again;  /* Continue processing the input file which %INCLUDE()d the current input file. */
		mov ax, si
		call near assembly_pop_
		mov si, ax
		test ax, ax
		je @$480
		jmp @$336

; }
@$480:
		jmp @$160

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
		push dx

;     int c;
;     int d;
;     const char *p;
;     char *ifname;
;
; #if (defined(MSDOS) || defined(_WIN32)) && !defined(__DOSMC__)
;     setmode(2, O_BINARY);  /* STDERR_FILENO. */
; #endif
;
; #if 0
;     malloc_init();
;     message_start(1);
;     bbprintf(&message_bbb, "malloc_p_para=0x%04x malloc_end_para=%04x", ((const unsigned*)&__malloc_struct__.malloc_p)[1], __malloc_struct__.malloc_end_para);
;     message_end();
; #endif
;
;     /*
;      ** If ran without arguments then show usage
;      */
;     if (argc == 1) {
		db 0x83, 0xF8, 1  ; !!! cmp ax, BYTE 1
		jne @$481

;         static const MY_STRING_WITHOUT_NUL(msg, "Typical usage:\r\nmininasm -f bin input.asm -o input.bin\r\n");
;         (void)!write(2, msg, sizeof(msg));
		mov bx, 0x38
		mov dx, @$616
		mov ax, 2
		call near write_
		jmp @$526

;         return 1;
;     }
;
;     /*
;      ** Start to collect arguments
;      */
;     ifname = NULL;
@$481:
		xor ax, ax
		mov word [bp-2], ax

;     output_filename = NULL;
		mov [_output_filename], ax  ; !!! no word [...]

;     listing_filename = NULL;
		mov [_listing_filename], ax  ; !!! no word [...]

;     default_start_address = 0;
		mov [_default_start_address], ax  ; !!! no word [...]
		mov [_default_start_address+2], ax  ; !!! no word [...]

;     c = 1;
		mov si, 1
		jmp near @$492

;     while (c < argc) {
;         if (argv[c][0] == '-') {    /* All arguments start with dash */
;             d = tolower(argv[c][1]);
;             if (d == 'f') { /* Format */
;                 c++;
;                 if (c >= argc) {
;                     message(1, "no argument for -f");
;                     return 1;
;                 } else {
;                     to_lowercase(argv[c]);
@$482:
		mov ax, word [bx]
		call near to_lowercase_

;                     if (strcmp(argv[c], "bin") == 0) {
		mov ax, word [bx]
		mov dx, @$597
		call near strcmp_
		test ax, ax
		jne @$483

;                         default_start_address = 0;
		mov [_default_start_address], ax  ; !!! no word [...]

;                     } else if (strcmp(argv[c], "com") == 0) {
		jmp SHORT @$486
@$483:
		mov ax, word [bx]
		mov dx, @$598
		call near strcmp_
		test ax, ax
		je @$485

;                         default_start_address = 0x0100;
;                     } else {
;                         message_start(1);
		mov ax, 1
		call near message_start_

;                         bbprintf(&message_bbb, "only 'bin', 'com' supported for -f (it is '%s')", argv[c]);
		push word [bx]
		mov ax, @$599
@$484:
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;                         message_end();
		call near message_end_
		jmp @$526

;                         return 1;
;                     }
@$485:
		mov word [_default_start_address], 0x100
@$486:
		mov [_default_start_address+2], ax  ; !!! no word [...]

;                     c++;
@$487:
		inc si

;                 }
;             } else if (d == 'o') {  /* Object file name */
		jmp SHORT @$492
@$488:
		mov cx, dx
		inc cx
		db 0x83, 0xF8, 0x6f  ; !!! cmp ax, BYTE 0x6f
		jne @$495

;                 c++;
;                 if (c >= argc) {
		cmp dx, word [bp-4]
		jl @$489

;                     message(1, "no argument for -o");
		mov dx, @$600
		jmp SHORT @$494

;                     return 1;
;                 } else if (output_filename != NULL) {
@$489:
		cmp word [_output_filename], BYTE 0
		je @$490

;                     message(1, "already a -o argument is present");
		mov dx, @$601
		jmp SHORT @$494

;                     return 1;
;                 } else {
;                     output_filename = argv[c];
@$490:
		mov ax, word [bx]
		mov [_output_filename], ax  ; !!! no word [...]

;                     c++;
@$491:
		mov si, cx

;                 }
;             } else if (d == 'l') {  /* Listing file name */
@$492:
		cmp si, word [bp-4]
		jge @$498
		mov di, si
		shl di, 1
		add di, word [bp-6]
		mov bx, word [di]
		lea dx, [si+1]
		cmp byte [bx], 0x2d
		jne @$499
		mov al, byte [bx+1]
		xor ah, ah
		call near tolower_
		mov bx, dx
		shl bx, 1
		add bx, word [bp-6]
		db 0x83, 0xF8, 0x66  ; !!! cmp ax, BYTE 0x66
		jne @$488
		mov si, dx
		cmp dx, word [bp-4]
		jge @$493
		jmp @$482
@$493:
		mov dx, @$596
@$494:
		mov ax, 1
		call near message_
		jmp @$526
@$495:
		db 0x83, 0xF8, 0x6c  ; !!! cmp ax, BYTE 0x6c
		jne @$500

;                 c++;
;                 if (c >= argc) {
		cmp dx, word [bp-4]
		jl @$496

;                     message(1, "no argument for -l");
		mov dx, @$602
		jmp SHORT @$494

;                     return 1;
;                 } else if (listing_filename != NULL) {
@$496:
		cmp word [_listing_filename], BYTE 0
		je @$497

;                     message(1, "already a -l argument is present");
		mov dx, @$603
		jmp SHORT @$494

;                     return 1;
;                 } else {
;                     listing_filename = argv[c];
@$497:
		mov ax, word [bx]
		mov [_listing_filename], ax  ; !!! no word [...]
		jmp SHORT @$491
@$498:
		jmp @$510
@$499:
		jmp near @$508

;                     c++;
;                 }
;             } else if (d == 'd') {  /* Define label */
@$500:
		db 0x83, 0xF8, 0x64  ; !!! cmp ax, BYTE 0x64
		jne @$507

;                 p = argv[c] + 2;
		mov bx, word [di]
		inc bx
		inc bx

;                 while (*p && *p != '=') {
@$501:
		mov al, byte [bx]
		test al, al
		je @$502
		cmp al, 0x3d
		je @$502

;                     *(char*)p = toupper(*p);
		xor ah, ah
		call near toupper_
		mov byte [bx], al

;                     p++;
		inc bx

;                 }
		jmp SHORT @$501

;                 if (*p == '=') {
@$502:
		cmp byte [bx], 0x3d
		je @$504
@$503:
		jmp @$487

;                     *(char*)p++ = 0;
@$504:
		mov byte [bx], 0

;                     undefined = 0;
		xor ax, ax
		mov [_undefined], ax  ; !!! no word [...]
		lea ax, [bx+1]
		call near match_expression_

;                     p = match_expression(p);
;                     if (p == NULL) {
		test ax, ax
		jne @$505

;                         message(1, "Bad expression");
		mov dx, @$550
		jmp SHORT @$494

;                         return 1;
;                     } else if (undefined) {
@$505:
		cmp word [_undefined], BYTE 0
		je @$506

;                         message(1, "Cannot use undefined labels");
		mov dx, @$568
		jmp SHORT @$494

;                         return 1;
;                     } else {
;                         define_label(argv[c] + 2, instruction_value);
@$506:
		mov dx, word [_instruction_value]
		mov cx, word [_instruction_value+2]
		mov bx, si
		shl bx, 1
		add bx, word [bp-6]
		mov ax, word [bx]
		inc ax
		inc ax
		mov bx, dx
		call near define_label_

;                     }
;                 }
		jmp SHORT @$503

;                 c++;
;             } else {
;                 message_start(1);
@$507:
		mov ax, 1
		call near message_start_

;                 bbprintf(&message_bbb, "unknown argument %s", argv[c]);
		push word [di]
		mov ax, @$604
		jmp @$484

;                 message_end();
;                 return 1;
;             }
;         } else {
;             if (ifname != NULL) {
@$508:
		cmp word [bp-2], BYTE 0
		je @$509

;                 message_start(1);
		mov ax, 1
		call near message_start_

;                 bbprintf(&message_bbb, "more than one input file name: %s", argv[c]);
		push word [di]
		mov ax, @$605
		jmp @$484

;                 message_end();
;                 return 1;
;             } else {
;                 ifname = argv[c];
@$509:
		mov word [bp-2], bx

;             }
;             c++;
		mov si, dx

;         }
		jmp @$492

;     }
;
;     if (ifname == NULL) {
@$510:
		cmp word [bp-2], BYTE 0
		jne @$511

;         message(1, "No input filename provided");
		mov dx, @$606
		jmp @$494

;         return 1;
;     }
;
;     /*
;      ** Do first step of assembly
;      */
;     assembler_step = 1;
@$511:
		mov ax, 1
		mov [_assembler_step], ax  ; !!! no word [...]

;     first_time = 1;
		mov [_first_time], ax  ; !!! no word [...]

;     malloc_init();
		mov ax, ds
		add ax, ___sd_top__
		mov [___malloc_struct__+4], ax  ; !!! no word [...]
		mov ax, cs
		dec ax
		mov es, ax
		inc ax
		es add ax, word [3]
		mov [___malloc_struct__], ax  ; !!! no word [...]

;     do_assembly(ifname);
		mov ax, word [bp-2]
		call near do_assembly_

;     message_flush(NULL);
		xor ax, ax
		call near message_flush_

;     if (errors) { do_remove:
		mov ax, [_errors+2]  ; !!! no word [...]
		or ax, word [_errors]
		je @$514

;         remove(output_filename);
@$512:
		mov ax, [_output_filename]  ; !!! no word [...]
		call near remove_

;         if (listing_filename != NULL)
		mov ax, [_listing_filename]  ; !!! no word [...]
		test ax, ax
		je @$513

;             remove(listing_filename);
		call near remove_
@$513:
		jmp @$526

;     } else {
;         /*
;          ** Do second step of assembly and generate final output
;          */
;         if (output_filename == NULL) {
@$514:
		cmp word [_output_filename], BYTE 0
		jne @$515

;             message(1, "No output filename provided");
		mov dx, @$607
		jmp @$494

;             return 1;
;         }
;         change_number = 0;
@$515:
		mov [_change_number], ax  ; !!! no word [...]

;         do {
;             change = 0;
@$516:
		xor ax, ax
		mov [_change], ax  ; !!! no word [...]

;             if (listing_filename != NULL) {
		mov ax, [_listing_filename]  ; !!! no word [...]
		test ax, ax
		je @$517

;                 if ((listing_fd = creat(listing_filename, 0644)) < 0) {
		mov dx, 0x1a4
		call near creat_
		mov [_listing_fd], ax  ; !!! no word [...]
		test ax, ax
		jge @$517

;                     message_start(1);
		mov ax, 1
		call near message_start_

;                     bbprintf(&message_bbb, "couldn't open '%s' as listing file", output_filename);
		push word [_output_filename]
		mov ax, @$608
		jmp @$484

;                     message_end();
;                     return 1;
;                 }
;             }
;             if ((output_fd = creat(output_filename, 0644)) < 0) {
@$517:
		mov ax, [_output_filename]  ; !!! no word [...]
		mov dx, 0x1a4
		call near creat_
		mov [_output_fd], ax  ; !!! no word [...]
		test ax, ax
		jge @$518

;                 message_start(1);
		mov ax, 1
		call near message_start_

;                 bbprintf(&message_bbb, "couldn't open '%s' as output file", output_filename);
		push word [_output_filename]
		mov ax, @$609
		jmp @$484

;                 message_end();
;                 return 1;
;             }
;             assembler_step = 2;
@$518:
		mov word [_assembler_step], 2

;             first_time = 1;
		mov word [_first_time], 1

;             address = start_address;
		mov ax, [_start_address]  ; !!! no word [...]
		mov dx, word [_start_address+2]
		mov [_address], ax  ; !!! no word [...]
		mov word [_address+2], dx

;             do_assembly(ifname);
		mov ax, word [bp-2]
		call near do_assembly_

;
;             if (listing_fd >= 0 && change == 0) {
		cmp word [_listing_fd], BYTE 0
		jge @$519
		jmp near @$521
@$519:
		cmp word [_change], BYTE 0
		jne @$521

;                 bbprintf(&message_bbb /* listing_fd */, "\r\n" FMT_05U " ERRORS FOUND\r\n", GET_FMT_U_VALUE(errors));
		mov ax, [_errors]  ; !!! no word [...]
		mov dx, word [_errors+2]
		call near get_fmt_u_value_
		push ax
		mov ax, @$610
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;                 bbprintf(&message_bbb /* listing_fd */, FMT_05U " WARNINGS FOUND\r\n\r\n", GET_FMT_U_VALUE(warnings));
		mov ax, [_warnings]  ; !!! no word [...]
		mov dx, word [_warnings+2]
		call near get_fmt_u_value_
		push ax
		mov ax, @$611
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;                 bbprintf(&message_bbb /* listing_fd */, FMT_05U " PROGRAM BYTES\r\n\r\n", GET_FMT_U_VALUE(GET_UVALUE(bytes)));
		mov ax, [_bytes]  ; !!! no word [...]
		mov dx, word [_bytes+2]
		call near get_fmt_u_value_
		push ax
		mov ax, @$612
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;                 if (label_list != NULL) {
		mov dx, word [_label_list]
		mov ax, [_label_list+2]  ; !!! no word [...]
		test ax, ax
		jne @$520
		test dx, dx
		je @$521

;                     bbprintf(&message_bbb /* listing_fd */, "%-20s VALUE/ADDRESS\r\n\r\n", "LABEL");
@$520:
		mov ax, @$613
		push ax
		mov ax, @$614
		push ax
		mov ax, _message_bbb
		push ax
		call near bbprintf_
		add sp, BYTE 6

;                     print_labels_sorted_to_listing_fd(label_list);
		mov ax, [_label_list]  ; !!! no word [...]
		mov dx, word [_label_list+2]
		call near print_labels_sorted_to_listing_fd_

;                 }
;             }
;             emit_flush(0);
@$521:
		xor ax, ax
		call near emit_flush_

;             close(output_fd);
		mov ax, [_output_fd]  ; !!! no word [...]
		call near close_

;             if (listing_filename != NULL) {
		cmp word [_listing_filename], BYTE 0
		je @$522

;                 message_flush(NULL);
		xor ax, ax
		call near message_flush_

;                 close(listing_fd);
		mov ax, [_listing_fd]  ; !!! no word [...]
		call near close_

;             }
;             if (change) {
@$522:
		cmp word [_change], BYTE 0
		je @$523

;                 change_number++;
		inc word [_change_number]

;                 if (change_number == 5) {
		cmp word [_change_number], BYTE 5
		jne @$523

;                     message(1, "Aborted: Couldn't stabilize moving label");
		mov dx, @$615
		mov ax, 1
		call near message_

;                 }
;             }
;             if (errors) goto do_remove;
@$523:
		mov ax, [_errors+2]  ; !!! no word [...]
		or ax, word [_errors]
		je @$524
		jmp @$512

;         } while (change) ;
@$524:
		mov ax, [_change]  ; !!! no word [...]
		test ax, ax
		je @$525
		jmp @$516

;         return 0;
@$525:
		jmp @$29

;     }
;
;     return 1;
@$526:
		mov ax, 1

; }
		jmp @$29


___section_bbprintf_c_text:

___25AA:

; %include 'bbprintf_text.nasm'

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
;
; #include "bbprintf.h"
;
; void bbwrite1(struct bbprintf_buf *bbb, int c) {
bbwrite1_:
		push bx
		push si
		mov bx, ax

;   while (bbb->p == bbb->buf_end) {
@@$1:
		mov si, word [bx+4]
		cmp si, word [bx+2]
		jne @@$2

;     bbb->flush(bbb);
		mov ax, bx
		call word [bx+8]

;   }
		jmp SHORT @@$1

;   *bbb->p++ = c;
@@$2:
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
; static int prints(struct bbprintf_buf *bbb, const char *string, int width, int pad) {
prints_:
		push si
		push di
		push bp
		mov bp, sp
		push ax
		push ax
		mov si, dx
		mov dx, cx

;   register int pc = 0, padchar = ' ';
		xor cx, cx
		mov word [bp-2], 0x20

;   if (width > 0) {
		test bx, bx
		jle @@$7

;     register int len = 0;
		xor ax, ax

;     register const char *ptr;
;     for (ptr = string; *ptr; ++ptr) ++len;
		mov di, si
@@$3:
		cmp byte [di], 0
		je @@$4
		inc ax
		inc di
		jmp SHORT @@$3

;     if (len >= width) width = 0;
@@$4:
		cmp ax, bx
		jl @@$5
		xor bx, bx

;     else width -= len;
		jmp SHORT @@$6
@@$5:
		sub bx, ax

;     if (pad & PAD_ZERO) padchar = '0';
@@$6:
		test dl, 2
		je @@$7
		mov word [bp-2], 0x30

;   }
;   if (!(pad & PAD_RIGHT)) {
@@$7:
		test dl, 1
		jne @@$9

;     for (; width > 0; --width) {
@@$8:
		test bx, bx
		jle @@$9

;       bbwrite1(bbb, padchar);
		mov dx, word [bp-2]
		mov ax, word [bp-4]
		call near bbwrite1_

;       ++pc;
		inc cx

;     }
		dec bx
		jmp SHORT @@$8

;   }
;   for (; *string ; ++string) {
@@$9:
		mov al, byte [si]
		test al, al
		je @@$10

;     bbwrite1(bbb, *string);
		xor ah, ah
		mov dx, ax
		mov ax, word [bp-4]
		call near bbwrite1_

;     ++pc;
		inc cx

;   }
		inc si
		jmp SHORT @@$9

;   for (; width > 0; --width) {
@@$10:
		test bx, bx
		jle @@$11

;     bbwrite1(bbb, padchar);
		mov dx, word [bp-2]
		mov ax, word [bp-4]
		call near bbwrite1_

;     ++pc;
		inc cx

;   }
		dec bx
		jmp SHORT @@$10

;   return pc;
; }
@@$11:
		mov ax, cx
		mov sp, bp
		pop bp
		pop di
		pop si
		ret

;
; /* the following should be enough for 32 bit int */
; #define PRINT_BUF_LEN 12
;
; static int printi(struct bbprintf_buf *bbb, int i, int b, int sg, int width, int pad, int letbase) {
printi_:
		push si
		push di
		push bp
		mov bp, sp
		sub sp, BYTE 0x12
		mov di, ax
		mov word [bp-6], bx

;   char print_buf[PRINT_BUF_LEN];
;   register char *s;
;   register int t, neg = 0, pc = 0;
		xor ax, ax
		mov word [bp-4], ax
		mov word [bp-2], ax

;   register unsigned int u = i;
		mov bx, dx

;
;   if (i == 0) {
		test dx, dx
		jne @@$12

;     print_buf[0] = '0';
		mov word [bp-0x12], 0x30

;     print_buf[1] = '\0';
;     return prints(bbb, print_buf, width, pad);
		mov cx, word [bp+0xa]
		mov bx, word [bp+8]
		lea dx, [bp-0x12]
		mov ax, di
		call near prints_
		jmp near @@$19

;   }
;
;   if (sg && b == 10 && i < 0) {
@@$12:
		test cx, cx
		je @@$13
		cmp word [bp-6], BYTE 0xa
		jne @@$13
		test dx, dx
		jge @@$13

;     neg = 1;
		mov word [bp-4], 1

;     u = -i;
		neg bx

;   }
;
;   s = print_buf + PRINT_BUF_LEN-1;
@@$13:
		lea si, [bp-7]

;   *s = '\0';
		mov byte [bp-7], 0

;
;   while (u) {
@@$14:
		test bx, bx
		je @@$16

;     t = u % b;
		mov ax, bx
		xor dx, dx
		div word [bp-6]

;     if (t >= 10)
		cmp dx, BYTE 0xa
		jl @@$15

;       t += letbase - '0' - 10;
		mov ax, word [bp+0xc]
		db 0x83, 0xE8, 0x3a  ; !!! sub ax, BYTE 0x3a
		add dx, ax

;     *--s = t + '0';
@@$15:
		mov al, dl
		add al, 0x30
		dec si
		mov byte [si], al

;     u /= b;
		mov ax, bx
		xor dx, dx
		div word [bp-6]
		mov bx, ax

;   }
		jmp SHORT @@$14

;
;   if (neg) {
@@$16:
		cmp word [bp-4], BYTE 0
		je @@$18

;     if (width &&(pad & PAD_ZERO)) {
		cmp word [bp+8], BYTE 0
		je @@$17
		test byte [bp+0xa], 2
		je @@$17

;       bbwrite1(bbb, '-');
		mov dx, 0x2d
		mov ax, di
		call near bbwrite1_

;       ++pc;
		inc word [bp-2]

;       --width;
		dec word [bp+8]

;     }
;     else {
		jmp SHORT @@$18

;       *--s = '-';
@@$17:
		dec si
		mov byte [si], 0x2d

;     }
;   }
;
;   return pc + prints(bbb, s, width, pad);
@@$18:
		mov cx, word [bp+0xa]
		mov bx, word [bp+8]
		mov dx, si
		mov ax, di
		call near prints_
		add ax, word [bp-2]

; }
@@$19:
		mov sp, bp
		pop bp
		pop di
		pop si
		ret 6

;
; static int print(struct bbprintf_buf *bbb, const char *format, va_list args) {
print_:
		push cx
		push si
		push di
		push bp
		mov bp, sp
		push ax
		push ax
		push ax
		mov si, dx
		mov word [bp-2], bx

;   register int width, pad;
;   register int pc = 0;
		xor di, di

;   char scr[2];
;
;   for (; *format != 0; ++format) {
@@$20:
		mov al, byte [si]
		test al, al
		je @@$23

;     if (*format == '%') {
		cmp al, 0x25
		jne @@$25

;       ++format;
;       width = pad = 0;
		xor cx, cx
		xor dx, dx

		inc si

;       if (*format == '\0') break;
		mov al, byte [si]
		test al, al
		je @@$23

;       if (*format == '%') goto out;
		cmp al, 0x25
		je @@$25

;       if (*format == '-') {
		cmp al, 0x2d
		jne @@$21

;         ++format;
;         pad = PAD_RIGHT;
		mov cx, 1

		add si, cx

;       }
;       while (*format == '0') {
@@$21:
		cmp byte [si], 0x30
		jne @@$22

;         ++format;
;         pad |= PAD_ZERO;
		or cl, 2

		inc si

;       }
		jmp SHORT @@$21

;       for (; *format >= '0' && *format <= '9'; ++format) {
@@$22:
		mov al, byte [si]
		cmp al, 0x30
		jb @@$24
		cmp al, 0x39
		ja @@$24

;         width *= 10;
		mov ax, dx
		mov dx, 0xa
		imul dx
		mov dx, ax

;         width += *format - '0';
		mov bl, byte [si]
		xor bh, bh
		lea ax, [bx-0x30]
		add dx, ax

;       }
		inc si
		jmp SHORT @@$22
@@$23:
		jmp @@$42
@@$24:
		mov bx, word [bp-2]
		inc bx
		inc bx

;       if (*format == 's') {
		mov al, byte [si]
		cmp al, 0x73
		jne @@$30

;         register char *s = va_arg(args, char*);
		mov word [bp-2], bx
		mov bx, word [bx-2]

;         pc += prints(bbb, s?s:"(null)", width, pad);
		mov ax, dx
		test bx, bx
		je @@$26
		mov dx, bx
		jmp SHORT @@$27
@@$25:
		jmp @@$39
@@$26:
		mov dx, @@$44
@@$27:
		mov bx, ax
@@$28:
		mov ax, word [bp-6]
		call near prints_
@@$29:
		add di, ax
		jmp near @@$41

;         continue;
;       }
;       if (*format == 'd') {
@@$30:
		cmp al, 0x64
		jne @@$33

;         pc += printi(bbb, va_arg(args, int), 10, 1, width, pad, 'a');
		mov ax, 0x61
		push ax
		push cx
		push dx
		mov word [bp-2], bx
		mov dx, word [bx-2]
		mov cx, 1
@@$31:
		mov bx, 0xa
@@$32:
		mov ax, word [bp-6]
		call near printi_
		jmp SHORT @@$29

;         continue;
;       }
;       if (*format == 'x') {
@@$33:
		cmp al, 0x78
		jne @@$35

;         pc += printi(bbb, va_arg(args, int), 16, 0, width, pad, 'a');
		mov ax, 0x61
@@$34:
		push ax
		push cx
		push dx
		mov word [bp-2], bx
		mov dx, word [bx-2]
		xor cx, cx
		mov bx, 0x10
		jmp SHORT @@$32

;         continue;
;       }
;       if (*format == 'X') {
@@$35:
		cmp al, 0x58
		jne @@$36

;         pc += printi(bbb, va_arg(args, int), 16, 0, width, pad, 'A');
		mov ax, 0x41
		jmp SHORT @@$34

;         continue;
;       }
;       if (*format == 'u') {
@@$36:
		cmp al, 0x75
		jne @@$37

;         pc += printi(bbb, va_arg(args, int), 10, 0, width, pad, 'a');
		mov ax, 0x61
		push ax
		push cx
		push dx
		mov word [bp-2], bx
		mov dx, word [bx-2]
		xor cx, cx
		jmp SHORT @@$31

;         continue;
;       }
;       if (*format == 'c') {
@@$37:
		cmp al, 0x63
		jne @@$41

;         /* char are converted to int then pushed on the stack */
;         scr[0] = (char)va_arg(args, int);
		mov word [bp-2], bx
		mov al, byte [bx-2]
		mov byte [bp-4], al

;         if (width == 0) {  /* Print '\0'. */
		test dx, dx
		jne @@$38

;           bbwrite1(bbb, scr[0]);
		mov dl, al

;           ++pc;
;         } else {
		jmp SHORT @@$40

;           scr[1] = '\0';
@@$38:
		mov byte [bp-3], 0

;           pc += prints(bbb, scr, width, pad);
		mov bx, dx
		lea dx, [bp-4]
		jmp SHORT @@$28

;         }
;         continue;
;       }
;     } else { out:
;       bbwrite1(bbb, *format);
@@$39:
		mov dl, byte [si]
@@$40:
		xor dh, dh
		mov ax, word [bp-6]
		call near bbwrite1_

;       ++pc;
		inc di

;     }
;   }
@@$41:
		inc si
		jmp @@$20

;   va_end(args);
;   return pc;
; }
@@$42:
		mov ax, di
		mov sp, bp
		pop bp
		pop di
		pop si
		pop cx
		ret

;
; int bbprintf(struct bbprintf_buf *bbb, const char *format, ...) {
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
@@$43:
		pop bp
		pop dx
		pop bx
		ret

;
; int bbsprintf(char *out, const char *format, ...) {
bbsprintf_:
		push bx
		push dx
		push bp
		mov bp, sp
		sub sp, BYTE 0xa

;   int result;
;   struct bbprintf_buf bbb;
;   va_list args;
;   bbb.buf = bbb.buf_end = bbb.p = out;
		mov bx, word [bp+8]
		mov word [bp-6], bx
		mov word [bp-0xa], bx

;   --bbb.buf_end;
		lea ax, [bx-1]
		mov word [bp-8], ax
		lea bx, [bp+0xc]
		mov dx, word [bp+0xa]
		lea ax, [bp-0xa]
		call near print_

;   va_start(args, format);
;   result = print(&bbb, format, args);
;   *bbb.p = '\0';
		mov bx, word [bp-6]
		mov byte [bx], 0

;   return result;
; }
		mov sp, bp
		jmp SHORT @@$43


; --- C library functions based on https://github.com/pts/dosmc/tree/master/dosmclib
___section_libc_text:

; char *strcat(char *dest, const char *src);
; Optimized for size. AX == s1, DX == s2.
; TODO(pts): Check the Watcom libc if it is any shorter.
___2850:
strcat_:	push di
		push ds
		pop es
		xchg si, dx
		xchg di, ax		; DI := dest; AX := junk.
		push di
		dec di
.skipagain:	inc di
		cmp byte [di], 1
		jnc .skipagain
.again:		lodsb
		stosb
		cmp al, 0
		jne .again
		pop ax			; Will return dest.
		xchg si, dx		; Restore SI.
		pop di
		ret

; int open(const char *pathname, int flags, int mode);
; int open2(const char *pathname, int flags);
; Optimized for size. AX == pathname, DX == flags, BX == mode.
; Unix open(2) is able to create new files (O_CREAT), in DOS please use
; creat() for that.
; mode is ignored. Recommended value: 0644, for Unix compatibility.
___2869:
open2_:
open_:		xchg ax, dx		; DX := pathname; AX := junk.
		mov ah, 0x3d
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		ret

; Implements `(unsigned long a) * (unsigned long b)' and `(long)a * (long b)'.
;
; Implementation copied from
; open-watcom-2_0-c-linux-x86-2022-05-01/lib286/dos/clibs.lib:i4m.o
___2873:
__U4M:
__I4M:		xchg ax,bx
		push ax
		xchg ax,dx
		or ax, ax
		je .1
		mul dx
.1:		xchg ax,cx
		or ax, ax
		je .2
		mul bx
		add cx, ax
.2:		pop ax
		mul bx
		add dx, cx
		ret

; !!! toupper_ not needed in future versions; what else is not needed from libc?
; int toupper(int c);
; Optimized for size.
___288B:
toupper_:	sub al, 'a'
		cmp al, 'z' - 'a'
		ja .done
		add al, 'A' - 'a'
.done:		add al, 'a'
		cbw			; Sign-extend AL to AX.
		ret

; int close(int fd);
; Optimized for size. AX == fd.
; for Unix compatibility.
___2897:
close_:		push bx
		xchg ax, bx		; BX := fd; AX := junk.
		mov ah, 0x3e
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		pop bx
		ret

; int isalpha(int c);
; Optimized for size.
___28A3:
isalpha_:	or al, 32		; Covert to ASCII uppercase.
		sub al, 'a'
		cmp al, 'z' - 'a' + 1
		mov ax, 0
		adc al, 0
		ret

; char *strcpy(char *dest, const char *src);
; Optimized for size. AX == dest, DX == src.
; TODO(pts): Check the Watcom libc if it is any shorter.
___28AF:
strcpy_:	push di
		push ds
		pop es
		xchg si, dx
		xchg di, ax		; DI := dest; AX := junk.
		push di
.again:		lodsb
		stosb
		cmp al, 0
		jne .again
		pop ax			; Will return dest.
		xchg si, dx		; Restore SI.
		pop di
		ret

; Implements `(unsigned long a) / (unsigned long b)' and also computes the
; modulo (%).
;
; Implementation copied from
; open-watcom-2_0-c-linux-x86-2022-05-01/lib286/dos/clibs.lib:i4d.o
___28C1:
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
		xchg ax,cx
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
		mov ax,1
		ret
.6:		sub cx, cx
		sub bx, bx
		xchg ax,bx
		xchg dx, cx
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
.11:		rcr cx,1
		rcr bx,1
		sub ax, bx
		sbb dx,cx
		cmc
		jb .10
.12:		add si, si
		dec bp
		js .13
		shr cx,1
		rcr bx,1
		add ax, bx
		adc dx, cx
		jae .12
		jmp short .10
.13:		add ax, bx
		adc dx, cx
.14:		mov bx, ax
		mov cx, dx
		mov ax, si
		xor dx,dx
		pop si
		pop bp
		ret

; Implements `(long a) / (long b)' and also computes the
; modulo (%).
;
; Implementation copied from
; open-watcom-2_0-c-linux-x86-2022-05-01/lib286/dos/clibs.lib:i4d.o
___2945:
__I4D:		or dx, dx
		js .1
		or cx, cx
		js .0
		jmp __U4D
.0:		neg cx
		neg bx
		sbb cx, byte 0
		call near __U4D
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
		call near __U4D
		neg cx
		neg bx
		sbb cx, byte 0
		ret
.2:		call near __U4D
		neg cx
		neg bx
		sbb cx, byte 0
		neg dx
		neg ax
		sbb dx, byte 0
		ret

; int creat(const char *pathname, int mode);
; Optimized for size. AX == pathname, DX == mode.
; The value O_CREAT | O_TRUNC | O_WRONLY is used as flags.
; mode is ignored, except for bit 8 (read-only). Recommended value: 0644,
; for Unix compatibility.
___2991:
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

; int isxdigit(int c);
; Optimized for size.
___29A5:
isxdigit_:	sub al, '0'
		cmp al, '9' - '0' + 1
		jc .done
		or al, 32		; Covert to ASCII uppercase.
		sub al, 'a' - '0'
		cmp al, 'f' - 'a' + 1
.done:		mov ax, 0
		adc al, 0
		ret

; int strcmp(const void *s1, const void *s2);
; Optimized for size. AX == s1, DX == s2.
; TODO(pts): Check the Watcom libc if it is any shorter.
___29B7:
strcmp_:	push si
		push ds
		pop es
		xchg si, ax		; SI := s1, AX := junk.
		xor ax, ax
		xchg di, dx
.next:		lodsb
		scasb
		jne .diff
		cmp al, 0
		je .done
		jmp short .next
.diff:		mov al, 1
		jnc .done
		neg ax
.done:		xchg di, dx		; Restore original DI.
		pop si
		ret

; off_t lseek(int fd, off_t offset, int whence);
; Optimized for size. AX == fd, CX:BX == offset, DX == whence.
___29D3:
lseek_:		xchg ax, bx		; BX := fd; AX := low offset.
		xchg ax, dx		; AX := whence; DX := low offset.
		mov ah, 0x42
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
		sbb dx, dx		; DX := -1.
.ok:		ret

; int memcmp(const void *s1, const void *s2, size_t n);
; Optimized for size. AX == s1, DX == s2, BX == n.
___29E0:
memcmp_:	push si
		push ds
		pop es
		xchg si, ax		; SI := s1, AX := junk.
		xor ax, ax
		xchg di, dx
		xchg cx, bx
		jcxz .done
		repz cmpsb		; Continue while equal.
		je .done
		inc ax
		jnc .done
		neg ax
.done:		xchg cx, bx		; Restore original CX.
		xchg di, dx		; Restore original DI.
		pop si
		ret

; int isdigit(int c);
; Optimized for size.
___29FB:
isdigit_:	sub al, '0'
		cmp al, '9' - '0' + 1
		mov ax, 0
		adc al, 0
		ret

; int remove(const char *fn);
; int unlink(const char *fn);
; Optimized for size.
___2A05:
unlink_:
remove_:	xchg dx, ax		; DX := AX, AX := junk.
		mov ah, 0x41
		int 0x21
		sbb ax, ax		; AX := -1 on error (CF), 0 otherwise.
		ret

; int strcmp_far(const char far *s1, const char far *s2);
; Assumes that offset in s1 and s2 doesn't wrap around.
; Optimized for size. DX:AX == s1, CX:BX == s2.
___2A0D:
strcmp_far_:	push si
		push ds
		mov ds, dx
		mov es, cx
		xchg si, ax		; SI := s1, AX := junk.
		xor ax, ax
		xchg di, bx
.next:		lodsb
		scasb
		jne .diff
		cmp al, 0
		je .done
		jmp short .next
.diff:		mov al, 1
		jnc .done
		neg ax
.done:		xchg di, bx		; Restore original DI.
		pop ds
		pop si
		ret

; ssize_t read(int fd, void *buf, size_t count);
; Optimized for size. AX == fd, DX == buf, BX == count.
___2A2D:
read_:		push cx
		xchg ax, bx		; AX := count; BX := fd.
		xchg ax, cx		; CX := count; AX := junk.
		mov ah, 0x3f
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		pop cx
		ret

; char far *strcpy_far(char far *dest, const char far *src);
; Assumes that offset in dest and src don't wrap around.
; Optimized for size. DX:AX == s1, CX:BX == s2.
___2A3A:
strcpy_far_:	push di
		push ds
		mov es, dx
		mov ds, cx
		xchg si, bx
		xchg di, ax		; DI := dest; AX := junk.
		push di
.again:		lodsb
		stosb
		cmp al, 0
		jne .again
		pop ax			; Will return dest.
		xchg si, bx		; Restore SI.
		pop ds
		pop di
		ret

; size_t strlen(const char *s);
; Optimized for size.
___2A50:
strlen_:	push si
		xchg si, ax		; SI := AX, AX := junk.
		mov ax, -1
.again:		cmp byte [si], 1
		inc si
		inc ax
		jnc .again
		pop si
		ret

; !!! tolower_ not needed in future versions; what else is not needed from libc?
; int tolower(int c);
; Optimized for size.
___2A5E:
tolower_:	sub al, 'A'
		cmp al, 'Z' - 'A'
		ja .done
		add al, 'a' - 'A'
.done:		add al, 'A'
		cbw			; Sign-extend AL to AX.
		ret

; ssize_t write(int fd, const void *buf, size_t count);
; Optimized for size. AX == fd, DX == buf, BX == count.
___2A6A:
write_:		push cx
		xchg ax, bx		; AX := count; BX := fd.
		xchg ax, cx		; CX := count; AX := junk.
		mov ah, 0x40
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		pop cx
		ret

; int isspace(int c);
; Optimized for size.
___2A77:
isspace_:	sub al, 9
		cmp al, 13 - 9 + 1
		jc .done		; ASCII 9 .. 13 are whitespace.
		sub al, ' ' - 9		; ASCII ' ' is whitespace.
		cmp al, 1
.done:		mov ax, 0
		adc al, 0
		ret

___section_mininasm_c_const:

___2A87:
@$527:		db 'Out of memory for label', 0
@$528:		db '%-20s %04x%04x', 0xd, 0xa, 0
@$529:		db 'Missing close paren', 0
@$530:		db 'Expression too deep', 0
@$531:		db 'Missing close quote', 0
@$532:		db 'Undefined label ', 0x27, '%s', 0x27, 0
@$533:		db 'division by zero', 0
@$534:		db 'modulo by zero', 0
@$535:		db 'shift by larger than 31', 0
@$536:		db 'error writing to output file', 0
@$537:		db 'extra characters at end of line', 0
@$538:		db 'WORD', 0
@$539:		db 'BYTE', 0
@$540:		db 'SHORT', 0
@$541:		db 'short jump too long', 0
@$542:		db 'decode: internal error (%s)', 0
@$543:		db 'error writing to listing file', 0
@$544:		db 'Error: ', 0
@$545:		db 'Warning: ', 0
@$546:		db '%s', 0
@$547:		db ' at line %u', 0xd, 0xa, 0
@$548:		db 0xd, 0xa, 0
@$549:		db 'DB', 0
@$550:		db 'Bad expression', 0
@$551:		db 'DW', 0
@$552:		db 'DD', 0
@$553:		db 'Unknown instruction ', 0x27, '%s', 0x27, 0
@$554:		db 'Error in instruction ', 0x27, '%s %s', 0x27, 0
@$555:		db 'Error: Cannot open ', 0x27, '%s', 0x27, ' for input', 0
@$556:		db 'Error: Error reading from ', 0x27, '%s', 0x27, 0
@$557:		db 'assembly stack overflow, too many pending %INCLUDE files', 0
@$558:		db 'cannot open ', 0x27, '%s', 0x27, ' for input', 0
@$559:		db 'cannot seek in ', 0x27, '%s', 0x27, 0
@$560:		db 'error reading assembly file', 0
@$561:		db 'assembly line too long', 0
@$562:		db 'EQU', 0
@$563:		db 'bad expression', 0
@$564:		db 'Redefined label ', 0x27, '%s', 0x27, 0
@$565:		db 'Inconsistency, label ', 0x27, '%s', 0x27, ' not found', 0
@$566:		db '%IF', 0
@$567:		db '%IF too deep', 0
@$568:		db 'Cannot use undefined labels', 0
@$569:		db '%IFDEF', 0
@$570:		db '%IFNDEF', 0
@$571:		db '%ELSE', 0
@$572:		db '%ELSE without %IF', 0
@$573:		db '%ENDIF', 0
@$574:		db '%ENDIF without %IF', 0
@$575:		db 'USE16', 0
@$576:		db 'CPU', 0
@$577:		db '8086', 0
@$578:		db 'Unsupported processor requested', 0
@$579:		db 'BITS', 0
@$580:		db 'Unsupported BITS requested', 0
@$581:		db '%INCLUDE', 0
@$582:		db 'Missing quotes on %include', 0
@$583:		db 'INCBIN', 0
@$584:		db 'Missing quotes on incbin', 0
@$585:		db 'ORG', 0
@$586:		db 'Backward address', 0
@$587:		db 'ALIGN', 0
@$588:		db 'TIMES', 0
@$589:		db '      ', 0
@$590:		db '%04X  ', 0
@$591:		db '%02X', 0
@$592:		db '  ', 0
@$593:		db '  %05s %s', 0xd, 0xa, 0
@$594:		db 'Cannot seek in source file', 0
@$595:		db 'pending %IF at end of file', 0
@$596:		db 'no argument for -f', 0
@$597:		db 'bin', 0
@$598:		db 'com', 0
@$599:		db 'only ', 0x27, 'bin', 0x27, ', ', 0x27, 'com', 0x27, ' supported for -f (it is ', 0x27, '%s', 0x27, ')', 0
@$600:		db 'no argument for -o', 0
@$601:		db 'already a -o argument is present', 0
@$602:		db 'no argument for -l', 0
@$603:		db 'already a -l argument is present', 0
@$604:		db 'unknown argument %s', 0
@$605:		db 'more than one input file name: %s', 0
@$606:		db 'No input filename provided', 0
@$607:		db 'No output filename provided', 0
@$608:		db 'couldn', 0x27, 't open ', 0x27, '%s', 0x27, ' as listing file', 0
@$609:		db 'couldn', 0x27, 't open ', 0x27, '%s', 0x27, ' as output file', 0
@$610:		db 0xd, 0xa, '%05s ERRORS FOUND', 0xd, 0xa, 0
@$611:		db '%05s WARNINGS FOUND', 0xd, 0xa, 0xd, 0xa, 0
@$612:		db '%05s PROGRAM BYTES', 0xd, 0xa, 0xd, 0xa, 0
@$613:		db 'LABEL', 0
@$614:		db '%-20s VALUE/ADDRESS', 0xd, 0xa, 0xd, 0xa, 0
@$615:		db 'Aborted: Couldn', 0x27, 't stabilize moving label', 0

___section_bbprintf_c_const:

___30DB:
@@$44: db '(null)', 0

___section__mininasm_c_const2:

___30E2:
_register_names: db 'ALCLDLBLAHCHDHBHAXCXDXBXSPBPSIDI', 0
___3104:
_reg_to_addressing: db 0, 0, 0, 7, 0, 6, 4, 5
___310B:
@$616: db 'Typical usage:', 0xd, 0xa, 'mininasm -f bin input.asm -o input.bin', 0xd, 0xa
; /** Instruction set.
;  ** Notice some instructions are sorted by less byte usage first.
;  */
; #define ALSO "-"
; const char instruction_set[] =
;     "AAA\0" " 37\0"
;     "AAD\0" "i D5i" ALSO " D50A\0"
;     "AAM\0" "i D4i" ALSO " D40A\0"
;     "AAS\0" " 3F\0"
;     "ADC\0" "j,q 10drd" ALSO "k,r 11drd" ALSO "q,j 12drd" ALSO "r,k 13drd" ALSO "AL,i 14i" ALSO "AX,i 15j" ALSO "k,s 83dzozdi" ALSO "j,i 80dzozdi" ALSO "k,i 81dzozdj\0"
;     "ADD\0" "j,q 00drd" ALSO "k,r 01drd" ALSO "q,j 02drd" ALSO "r,k 03drd" ALSO "AL,i 04i" ALSO "AX,i 05j" ALSO "k,s 83dzzzdi" ALSO "j,i 80dzzzdi" ALSO "k,i 81dzzzdj\0"
;     "AND\0" "j,q 20drd" ALSO "k,r 21drd" ALSO "q,j 22drd" ALSO "r,k 23drd" ALSO "AL,i 24i" ALSO "AX,i 25j" ALSO "k,s 83dozzdi" ALSO "j,i 80dozzdi" ALSO "k,i 81dozzdj\0"
;     "CALL\0" "FAR k FFdzood" ALSO "f 9Af" ALSO "k FFdzozd" ALSO "b E8b\0"
;     "CBW\0" " 98\0"
;     "CLC\0" " F8\0"
;     "CLD\0" " FC\0"
;     "CLI\0" " FA\0"
;     "CMC\0" " F5\0"
;     "CMP\0" "j,q 38drd" ALSO "k,r 39drd" ALSO "q,j 3Adrd" ALSO "r,k 3Bdrd" ALSO "AL,i 3Ci" ALSO "AX,i 3Dj" ALSO "k,s 83dooodi" ALSO "j,i 80dooodi" ALSO "k,i 81dooodj\0"
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
;     "IN\0" "AL,DX EC" ALSO "AX,DX ED" ALSO "AL,i E4i" ALSO "AX,i E5i\0"
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
;     "JMP\0" "FAR k FFdozod" ALSO "f EAf" ALSO "k FFdozzd" ALSO "c EBa" ALSO "b E9b\0"
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
;     "LDS\0" "r,k oozzzozodrd\0"
;     "LEA\0" "r,k 8Ddrd\0"
;     "LES\0" "r,k oozzzozzdrd\0"
;     "LOCK\0" " F0+\0"
;     "LODSB\0" " AC\0"
;     "LODSW\0" " AD\0"
;     "LOOP\0" "a E2a\0"
;     "LOOPE\0" "a E1a\0"
;     "LOOPNE\0" "a E0a\0"
;     "LOOPNZ\0" "a E0a\0"
;     "LOOPZ\0" "a E1a\0"
;     "MOV\0" "AL,[i] A0j" ALSO "AX,[i] A1j" ALSO "[i],AL A2j" ALSO "[i],AX A3j" ALSO "j,q 88drd" ALSO "k,r 89drd" ALSO "q,j 8Adrd" ALSO "r,k 8Bdrd" ALSO "k,ES 8Cdzzzd" ALSO "k,CS 8Cdzzod" ALSO "k,SS 8Cdzozd" ALSO "k,DS 8Cdzood" ALSO "ES,k 8Edzzzd" ALSO "CS,k 8Edzzod" ALSO "SS,k 8Edzozd" ALSO "DS,k 8Edzood" ALSO "q,i ozoozri" ALSO "r,i ozooorj" ALSO "l,i oozzzoozdzzzdi" ALSO "m,i oozzzooodzzzdj\0"
;     "MOVSB\0" " A4\0"
;     "MOVSW\0" " A5\0"
;     "MUL\0" "l F6dozzd" ALSO "m F7dozzd\0"
;     "NEG\0" "l F6dzood" ALSO "m F7dzood\0"
;     "NOP\0" " 90\0"
;     "NOT\0" "l F6dzozd" ALSO "m F7dzozd\0"
;     "OR\0" "j,q 08drd" ALSO "k,r 09drd" ALSO "q,j 0Adrd" ALSO "r,k 0Bdrd" ALSO "AL,i 0Ci" ALSO "AX,i 0Dj" ALSO "k,s 83dzzodi" ALSO "j,i 80dzzodi" ALSO "k,i 81dzzodj\0"
;     "OUT\0" "DX,AL EE" ALSO "DX,AX EF" ALSO "i,AL E6i" ALSO "i,AX E7i\0"
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
;     "SBB\0" "j,q 18drd" ALSO "k,r 19drd" ALSO "q,j 1Adrd" ALSO "r,k 1Bdrd" ALSO "AL,i 1Ci" ALSO "AX,i 1Dj" ALSO "k,s 83dzoodi" ALSO "j,i 80dzoodi" ALSO "k,i 81dzoodj\0"
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
;     "SUB\0" "j,q 28drd" ALSO "k,r 29drd" ALSO "q,j 2Adrd" ALSO "r,k 2Bdrd" ALSO "AL,i 2Ci" ALSO "AX,i 2Dj" ALSO "k,s 83dozodi" ALSO "j,i 80dozodi" ALSO "k,i 81dozodj\0"
;     "TEST\0" "j,q 84drd" ALSO "q,j 84drd" ALSO "k,r 85drd" ALSO "r,k 85drd" ALSO "AL,i A8i" ALSO "AX,i A9j" ALSO "l,i F6dzzzdi" ALSO "m,i F7dzzzdj\0"
;     "WAIT\0" " 9B+\0"
;     "XCHG\0" "AX,r ozzozr" ALSO "r,AX ozzozr" ALSO "q,j 86drd" ALSO "j,q 86drd" ALSO "r,k 87drd" ALSO "k,r 87drd\0"
;     "XLAT\0" " D7\0"
;     "XOR\0" "j,q 30drd" ALSO "k,r 31drd" ALSO "q,j 32drd" ALSO "r,k 33drd" ALSO "AL,i 34i" ALSO "AX,i 35j" ALSO "k,s 83doozdi" ALSO "j,i 80doozdi" ALSO "k,i 81doozdj\0"
; ;
___3143:
_instruction_set:
ALSO		equ '-'
		db 'AAA', 0, ' 37', 0
		db 'AAD', 0, 'i D5i', ALSO, ' D50A', 0
		db 'AAM', 0, 'i D4i', ALSO, ' D40A', 0
		db 'AAS', 0, ' 3F', 0
		db 'ADC', 0, 'j,q 10drd', ALSO, 'k,r 11drd', ALSO, 'q,j 12drd', ALSO, 'r,k 13drd', ALSO, 'AL,i 14i', ALSO, 'AX,i 15j', ALSO, 'k,s 83dzozdi', ALSO, 'j,i 80dzozdi', ALSO, 'k,i 81dzozdj', 0
		db 'ADD', 0, 'j,q 00drd', ALSO, 'k,r 01drd', ALSO, 'q,j 02drd', ALSO, 'r,k 03drd', ALSO, 'AL,i 04i', ALSO, 'AX,i 05j', ALSO, 'k,s 83dzzzdi', ALSO, 'j,i 80dzzzdi', ALSO, 'k,i 81dzzzdj', 0
		db 'AND', 0, 'j,q 20drd', ALSO, 'k,r 21drd', ALSO, 'q,j 22drd', ALSO, 'r,k 23drd', ALSO, 'AL,i 24i', ALSO, 'AX,i 25j', ALSO, 'k,s 83dozzdi', ALSO, 'j,i 80dozzdi', ALSO, 'k,i 81dozzdj', 0
		db 'CALL', 0, 'FAR k FFdzood', ALSO, 'f 9Af', ALSO, 'k FFdzozd', ALSO, 'b E8b', 0
		db 'CBW', 0, ' 98', 0
		db 'CLC', 0, ' F8', 0
		db 'CLD', 0, ' FC', 0
		db 'CLI', 0, ' FA', 0
		db 'CMC', 0, ' F5', 0
		db 'CMP', 0, 'j,q 38drd', ALSO, 'k,r 39drd', ALSO, 'q,j 3Adrd', ALSO, 'r,k 3Bdrd', ALSO, 'AL,i 3Ci', ALSO, 'AX,i 3Dj', ALSO, 'k,s 83dooodi', ALSO, 'j,i 80dooodi', ALSO, 'k,i 81dooodj', 0
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
		db 'IN', 0, 'AL,DX EC', ALSO, 'AX,DX ED', ALSO, 'AL,i E4i', ALSO, 'AX,i E5i', 0
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
		db 'JMP', 0, 'FAR k FFdozod', ALSO, 'f EAf', ALSO, 'k FFdozzd', ALSO, 'c EBa', ALSO, 'b E9b', 0
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
		db 'LDS', 0, 'r,k oozzzozodrd', 0
		db 'LEA', 0, 'r,k 8Ddrd', 0
		db 'LES', 0, 'r,k oozzzozzdrd', 0
		db 'LOCK', 0, ' F0+', 0
		db 'LODSB', 0, ' AC', 0
		db 'LODSW', 0, ' AD', 0
		db 'LOOP', 0, 'a E2a', 0
		db 'LOOPE', 0, 'a E1a', 0
		db 'LOOPNE', 0, 'a E0a', 0
		db 'LOOPNZ', 0, 'a E0a', 0
		db 'LOOPZ', 0, 'a E1a', 0
		db 'MOV', 0, 'AL,[i] A0j', ALSO, 'AX,[i] A1j', ALSO, '[i],AL A2j', ALSO, '[i],AX A3j', ALSO, 'j,q 88drd', ALSO, 'k,r 89drd', ALSO, 'q,j 8Adrd', ALSO, 'r,k 8Bdrd', ALSO, 'k,ES 8Cdzzzd', ALSO, 'k,CS 8Cdzzod', ALSO, 'k,SS 8Cdzozd', ALSO, 'k,DS 8Cdzood'
		db     ALSO, 'ES,k 8Edzzzd', ALSO, 'CS,k 8Edzzod', ALSO, 'SS,k 8Edzozd', ALSO, 'DS,k 8Edzood', ALSO, 'q,i ozoozri', ALSO, 'r,i ozooorj', ALSO, 'l,i oozzzoozdzzzdi', ALSO, 'm,i oozzzooodzzzdj', 0
		db 'MOVSB', 0, ' A4', 0
		db 'MOVSW', 0, ' A5', 0
		db 'MUL', 0, 'l F6dozzd', ALSO, 'm F7dozzd', 0
		db 'NEG', 0, 'l F6dzood', ALSO, 'm F7dzood', 0
		db 'NOP', 0, ' 90', 0
		db 'NOT', 0, 'l F6dzozd', ALSO, 'm F7dzozd', 0
		db 'OR', 0, 'j,q 08drd', ALSO, 'k,r 09drd', ALSO, 'q,j 0Adrd', ALSO, 'r,k 0Bdrd', ALSO, 'AL,i 0Ci', ALSO, 'AX,i 0Dj', ALSO, 'k,s 83dzzodi', ALSO, 'j,i 80dzzodi', ALSO, 'k,i 81dzzodj', 0
		db 'OUT', 0, 'DX,AL EE', ALSO, 'DX,AX EF', ALSO, 'i,AL E6i', ALSO, 'i,AX E7i', 0
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
		db 'SBB', 0, 'j,q 18drd', ALSO, 'k,r 19drd', ALSO, 'q,j 1Adrd', ALSO, 'r,k 1Bdrd', ALSO, 'AL,i 1Ci', ALSO, 'AX,i 1Dj', ALSO, 'k,s 83dzoodi', ALSO, 'j,i 80dzoodi', ALSO, 'k,i 81dzoodj', 0
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
		db 'SUB', 0, 'j,q 28drd', ALSO, 'k,r 29drd', ALSO, 'q,j 2Adrd', ALSO, 'r,k 2Bdrd', ALSO, 'AL,i 2Ci', ALSO, 'AX,i 2Dj', ALSO, 'k,s 83dozodi', ALSO, 'j,i 80dozodi', ALSO, 'k,i 81dozodj', 0
		db 'TEST', 0, 'j,q 84drd', ALSO, 'q,j 84drd', ALSO, 'k,r 85drd', ALSO, 'r,k 85drd', ALSO, 'AL,i A8i', ALSO, 'AX,i A9j', ALSO, 'l,i F6dzzzdi', ALSO, 'm,i F7dzzzdj', 0
		db 'WAIT', 0, ' 9B+', 0
		db 'XCHG', 0, 'AX,r ozzozr', ALSO, 'r,AX ozzozr', ALSO, 'q,j 86drd', ALSO, 'j,q 86drd', ALSO, 'r,k 87drd', ALSO, 'k,r 87drd', 0
		db 'XLAT', 0, ' D7', 0
		db 'XOR', 0, 'j,q 30drd', ALSO, 'k,r 31drd', ALSO, 'q,j 32drd', ALSO, 'r,k 33drd', ALSO, 'AL,i 34i', ALSO, 'AX,i 35j', ALSO, 'k,s 83doozdi', ALSO, 'j,i 80doozdi', ALSO, 'k,i 81doozdj', 0
		db 0

___section_mininasm_c_data:

___3C71:
_listing_fd:	dw -1
; struct bbprintf_buf emit_bbb = { emit_buf, emit_buf + sizeof(emit_buf), emit_buf, 0, emit_flush };
_emit_bbb:
___3C73:	dw _emit_buf
___3C75:	dw _emit_buf+0x200
___3C77:	dw _emit_buf
___3C79:	dw 0
___3C7B:	dw emit_flush_
; /* data = 0 means write to listing_fd only, = 1 means write to stderr + listing_fd. */
; struct bbprintf_buf message_bbb = { message_buf, message_buf + sizeof(message_buf), message_buf, 0, message_flush };
_message_bbb:
___3C7D:	dw _message_buf
___3C7F:	dw _message_buf+0x200
___3C81:	dw _message_buf
___3C83:	dw 0
___3C85:	dw message_flush_

; --- Variables initialized to 0 by _start.
___section_mininasm_c_bss:

___3C87:
_line_buf	equ $+0
_assembly_stack	equ $+0x200
_message_buf	equ $+0x400
_emit_buf	equ $+0x600
_part		equ $+0x800
_generated	equ $+0x900
_name		equ $+0x908
_expr_name	equ $+0xa08
_global_label	equ $+0xb08
_instruction_value equ $+0xc08
_warnings	equ $+0xc0c
_label_list	equ $+0xc10
_last_label	equ $+0xc14
_errors	equ $+0xc18
_bytes		equ $+0xc1c
_start_address	equ $+0xc20
_address	equ $+0xc24
_instruction_offset equ $+0xc28
_line_number	equ $+0xc2c
_default_start_address equ $+0xc30
___malloc_struct__ equ $+0xc34
_assembly_p	equ $+0xc3a
_prev_p	equ $+0xc3c
_p		equ $+0xc3e
_change_number	equ $+0xc40
_g		equ $+0xc42
_undefined	equ $+0xc44
_change	equ $+0xc46
_first_time	equ $+0xc48
_output_fd	equ $+0xc4a
_assembler_step	equ $+0xc4c
_listing_filename equ $+0xc4e
_output_filename equ $+0xc50
_instruction_register equ $+0xc52
_instruction_offset_width equ $+0xc53
_instruction_addressing equ $+0xc54
@$617		equ $+0xc55
@$618		equ $+0xc57
@$619		equ $+0xd21
@$620		equ $+0xf79
@$621		equ $+0xf7b
@$622		equ $+0xf89
_bss_end	equ $+0xf8a

; --- Uninitialized .bss used by _start.
___section_startup_ubss equ _bss_end

argv_bytes	equ ___section_startup_ubss
argv_pointers	equ argv_bytes+270
_ubss_end	equ argv_pointers+130

___section_end	equ _ubss_end

___initial_sp	equ ___section_startup_text+((___section_end-___section_startup_text+___stack_size+1)&~1)  ; Word-align stack for speed.
___sd_top__	equ 0x10+((___initial_sp-___section_startup_text+0xf)>>4)  ; Round top of stack to next para, use para (16-byte).
