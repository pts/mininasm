/*
 ** mininasm: NASM-compatible mini assembler for 8086, able to run on DOS and on modern systems
 ** mininasm modifications by pts@fazekas.hu at Wed May 18 21:39:36 CEST 2022
 **
 ** based on Tinyasm by Oscar Toledo G, starting Oct/01/2019.
 **
 ** Compilation instructions (pick any one):
 **
 **   $ gcc -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o mininasm mininasm.c && ls -ld mininasm
 **
 **   $ gcc -m32 -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o mininasm mininasm.c && ls -ld mininasm.gcc32
 **
 **   $ g++ -ansi -pedantic -s -Os -W -Wall -o mininasm mininasm.c && ls -ld mininasm
 **
 **   $ pts-tcc -s -O2 -W -Wall -o mininasm.tcc mininasm.c && ls -ld mininasm.tcc
 **
 **   $ pts-tcc64 -m64 -s -O2 -W -Wall -o mininasm.tcc64 mininasm.c && ls -ld mininasm.tcc64
 **
 **   $ xtiny gcc -march=i386 -ansi -pedantic -W -Wall Wno-overlength-strings -o mininasm.xtiny mininasm.c && ls -ld mininasm.xtiny
 **
 **   $ xstatic gcc -ansi -pedantic -s -O2 -W -Wall Wno-overlength-strings -o mininasm.xstatic mininasm.c && ls -ld mininasm.xstatic
 **
 **   $ dosmc -mt -cpn mininasm.c && ls -ld mininasm.com
 **
 **   $ owcc -bdos -o mininasm.exe -mcmodel=c -Os -s -fstack-check -Wl,option -Wl,stack=1800 -march=i86 -W -Wall -Wextra mininasm.c && ls -ld mininasm.exe
 **
 **   $ owcc -bwin32 -Wl,runtime -Wl,console=3.10 -o mininasm.win32.exe -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm.c nouser32.c && ls -ld mininasm.win32.exe
 **
 **   $ owcc -blinux -o mininasm.watli3 -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm.c && sstrip mininasm.watli3 && ls -ld mininasm.watli3
 **
 **   $ i686-w64-mingw32-gcc -m32 -mconsole -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -march=i386 -o mininasm.win32msvcrt.exe mininasm.c && ls -ld mininasm.win32msvcrt.exe
 **
 **   $ wine tcc.exe -m32 -mconsole -s -O2 -W -Wall -o mininasm.win32msvcrt_tcc.exe mininasm.c && ls -ld mininasm.win32msvcrt_tcc.exe
 **
 **   Turbo C++ (1.01 or 3.0) on DOS, creates mininasm.exe: tcc -mc -O -X mininasm.c
 **
 **   Borland C++ (2.0, 3.00, 3.1, 4.00, 4.5, 4.52 or 5.2) on DOS, creates mininasm.exe: bcc -mc -O -X -w! mininasm.c
 **   From Borland C++ >=4.0, the .exe program is ~23 KiB larger.
 **   The -w! flag (treat warnings as errors) is ignored by Borland C++ <4.0.
 **
 **   Microsoft C 6.00a on DOS, creates mininasm.exe: cl /Os /AC /W2 /WX mininasm.c
 **
 */

#ifndef CONFIG_SKIP_LIBC
#define CONFIG_SKIP_LIBC 0
#endif

#if !CONFIG_SKIP_LIBC && defined(__LIBCH__)  /* Works with gcc, tcc, pts-tcc (Linux i386 target) and `owcc -blinux'. */
#  undef  CONFIG_SKIP_LIBC
#  define CONFIG_SKIP_LIBC 1
#  include <libc.h>
   /* !! TODO(pts): Use the main_argv function (rather than main_from_libc to take argv only. */
#  ifndef CONFIG_USE_OPEN2
#    define CONFIG_USE_OPEN2 1  /* Non-POSIX API provided by <libc.h>. Same as open(..., ..., 0). */
#  endif
#  if 0 && defined(__WATCOMC__) && defined(_M_I386)  /* Not enabling it, doesn't make a size difference. */
     static void memcpy_void_inline(void *dest, const void *src, size_t n);
#    pragma aux memcpy_void_inline = "rep movsb"  parm [ edi ] [ esi ] [ ecx ] modify [ esi edi ecx ];
     /* Returns dest + n. */
     static void *memcpy_newdest_inline(void *dest, const void *src, size_t n);
#    pragma aux memcpy_newdest_inline = "rep movsb"  value [ edi ] parm [ edi ] [ esi ] [ ecx ] modify [ esi ecx ];
#    define CONFIG_USE_MEMCPY_INLINE 1
#  endif
#endif  /* ifdef __TINYC__. */

#if !CONFIG_SKIP_LIBC && defined(__TINYC__)  /* Works with tcc, pts-tcc (Linux i386 target), pts-tcc64 (Linux amd64 target) and tcc.exe (Win32, Windows i386 target). */
#  undef  CONFIG_SKIP_LIBC
#  define CONFIG_SKIP_LIBC 1
#  if !defined(__i386__) /* && !defined(__amd64__)*/ && !defined(__x86_64__)
#    error tcc is supported only on i386 and amd64.  /* Because of ssize_t. */
#  endif
#  if (defined(_WIN32) && !defined(__i386)) || defined(_WIN64)
#    error Windows is supported only on i386.
#  endif
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef signed char int8_t;
typedef short int16_t;
typedef int int32_t;
typedef unsigned long size_t;  /* Good for __i386__ (4 bytes) and __amd64__ (8 bytes). */
typedef long ssize_t;  /* Good for __i386__ (4 bytes) and __amd64__ (8 bytes). */
typedef long off_t;  /* Good for __i386__ (4 bytes) and __amd64__ (8 bytes). */
#  define NULL ((void*)0)
#  ifdef _WIN32
#    define __cdecl __attribute__((__cdecl__))
#  else
#    define __cdecl
#  endif
void *__cdecl malloc(size_t size);
size_t __cdecl strlen(const char *s);
int __cdecl remove(const char *pathname);
__attribute__((noreturn)) void __cdecl exit(int status);
char *__cdecl strcpy(char *dest, const char *src);
int __cdecl strcmp(const char *s1, const char *s2);
void *__cdecl memcpy(void *dest, const void *src, size_t n);
int __cdecl isalpha(int c);
int __cdecl isspace(int c);
int __cdecl isdigit(int c);
int __cdecl isxdigit(int c);
ssize_t __cdecl read(int fd, void *buf, size_t count);  /* Win32 uses int instead of size_t etc. */
ssize_t __cdecl write(int fd, const void *buf, size_t count);  /* Win32 uses int instead of size_t etc. */
#define SEEK_SET 0  /* whence value below. */
#define SEEK_CUR 1
#define SEEK_END 2
off_t __cdecl lseek(int fd, off_t offset, int whence);  /* Just 32-bit off_t. */
#define O_RDONLY 0  /* flags bitfield value below. */
#define O_WRONLY 1
#define O_RDWR 2
int __cdecl open(const char *pathname, int flags, ...);  /* int mode */
int __cdecl creat(const char *pathname, int mode);
int __cdecl close(int fd);
#  ifdef _WIN32
#    define O_CREAT 0x100
#    define O_TRUNC 0x200
#    define O_BINARY 0x8000
#    define creat(filename, mode) open(filename, O_CREAT | O_TRUNC | O_WRONLY | O_BINARY, 0)  /* 0 to prevent Wine warning: fixme:msvcrt:MSVCRT__wsopen_s : pmode 0x406b9b ignored.  */
int __cdecl setmode(int _FileHandle,int _Mode);
#  endif
#endif  /* ifdef __TINYC__. */

#if !CONFIG_SKIP_LIBC && defined(__DOSMC__)
#  undef  CONFIG_SKIP_LIBC
#  define CONFIG_SKIP_LIBC 1
#  include <dosmc.h>  /* strcpy_far(...), strcmp_far(...), open2(...) etc. */
#  ifndef MSDOS  /* Not necessary, already done in the newest __DOSMC__. */
#    define MSDOS 1
#  endif
#  ifndef CONFIG_USE_MEMCPY_INLINE
#    define CONFIG_USE_MEMCPY_INLINE 1
#  endif
#  ifndef CONFIG_USE_OPEN2
#    define CONFIG_USE_OPEN2 1  /* Provided by __DOSMC__. */
#  endif
#endif

#if !CONFIG_SKIP_LIBC && defined(__XTINY__)
#  undef  CONFIG_SKIP_LIBC
#  define CONFIG_SKIP_LIBC 1
#  define _FILE_OFFSET_BITS 64  /* Make off_t for lseek(..) 64-bit, if available. */
#  include <xtiny.h>
#  ifndef CONFIG_MALLOC_FAR_USING_SYS_BRK
#    define CONFIG_MALLOC_FAR_USING_SYS_BRK 1
#  endif
#endif

#if !CONFIG_SKIP_LIBC  /* More or less Standard C. */
#  undef  CONFIG_SKIP_LIBC
#  define CONFIG_SKIP_LIBC 1
#  define _FILE_OFFSET_BITS 64  /* Make off_t for lseek(..) 64-bit, if available. */
#  include <ctype.h>
#  include <fcntl.h>  /* open(...), O_BINARY. */
#  include <stdio.h>  /* remove(...) */
#  include <stdlib.h>
#  include <string.h>
#  if defined(__TURBOC__) && !defined(MSDOS)  /* Turbo C++ 3.0 doesn't define MSDOS. Borland C++ 3.0 also defines __TURBOC__, and it doesn't define MSDOS. Microsoft C 6.00a defines MSDOS. */
#    define MSDOS 1  /* FYI Turbo C++ 1.00 is not supported, because for the macro MATCH_CASEI_LEVEL_TO_VALUE2 it incorrectly reports the error: Case outside of switch in function match_expression */
#  endif
#  if defined(_WIN32) || defined(_WIN64) || defined(MSDOS)  /* tcc.exe with Win32 target doesn't have <unistd.h>. For `owcc -bdos' and `owcc -bwin32', both <io.h> and <unistd.h> works.  For __TURBOC__, only <io.h> works. */
#    include <io.h>  /* setmode(...) */
#    if defined(__TURBOC__) || !(defined(_WIN32) || defined(_WIN64))
#      define creat(filename, mode) open(filename, O_CREAT | O_TRUNC | O_WRONLY | O_BINARY, mode)  /* In __TURBOC__ != 0x296, a nonzero mode must be passed, otherwise creat(...) will fail. */
#    else
#      define creat(filename, mode) open(filename, O_CREAT | O_TRUNC | O_WRONLY | O_BINARY, 0)  /* 0 to prevent Wine msvcrt.dll warning: `fixme:msvcrt:MSVCRT__wsopen_s : pmode 0x406b9b ignored.'. Also works with `owcc -bwin32' (msvcrtl.dll) and `owcc -bdos'. */
#    endif
#  else
#    include <unistd.h>
#  endif
#  if (defined(__TURBOC__) || defined(__PACIFIC__) || defined(_MSC_VER)) && defined(MSDOS)  /* __TURBOC__ values: Turbo C++ 1.01 (0x296), Turbo C++ 3.0 (0x401), Borland C++ 2.0 (0x297), Borland C++ 3.0 (0x400), Borland C++ 5.2 (0x520), Microsoft C 6.00a don't have a typedef ... off_t. */
typedef long off_t;  /* It's OK to define it multiple times, so not a big risk. */
#  endif
#  if defined(__WATCOMC__) && defined(__LINUX__)  /* Defined by __WATCOMC__: `owcc -blinux' or wcl `-bt=linux'. */
#    undef O_BINARY  /* Fix bug in OpenWatcom <unistd.h>. It defines O_BINARY as O_TRUNC, effectively overwriting input files. */
#  endif
#  if defined(__TURBOC__)
#    pragma warn -rch  /* Unreachable code. */
#    pragma warn -ccc  /* Condition is always true/false. */
#  endif
#endif  /* Else ifdef __DOSMC__. */

#ifndef O_BINARY  /* Unix. */
#define O_BINARY 0
#endif

#ifndef CONFIG_USE_OPEN2
#  define CONFIG_USE_OPEN2 0
#endif
#if !CONFIG_USE_OPEN2
#  define open2(pathname, flags) open(pathname, flags, 0)
#endif

#ifndef CONFIG_USE_MEMCPY_INLINE
#  define CONFIG_USE_MEMCPY_INLINE 0
#endif

#ifndef CONFIG_IS_SIZEOF_INT_AT_LEAST_4
#  if defined(__SIZEOF_INT__)  /* GCC has it, tried with GCC 4.8. */
#    if __SIZEOF_INT__ >= 4
#      define CONFIG_IS_SIZEOF_INT_AT_LEAST_4 1
#    endif
#  else  /* OpenWatcom only defines this _M_I386 for 32-bit (and maybe 64-bit?) targets, e.g. `owcc -bwin32' or `owcc -bdos32a', but not for `owcc -bdos'. Likewise, _M_I86 for only 16-bit targets. */
#    if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__) || defined(__i386__) || defined(__386) || defined(__X86_64__) || defined(_M_I386) || defined(_M_ARM) || defined(_M_ARM64) || defined(__m68k__) || defined(__ia64__) || defined(_M_IA64) || defined(__powerpc__) || defined(_M_PPC)
#      define CONFIG_IS_SIZEOF_INT_AT_LEAST_4 1
#    endif
#  endif
#  ifndef CONFIG_IS_SIZEOF_INT_AT_LEAST_4
#    define CONFIG_IS_SIZEOF_INT_AT_LEAST_4 0
#  endif
#endif

#if !defined(CONFIG_CPU_X86)
#if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__) || defined(_M_IX86) || defined(__i386__) || defined(__386) || defined(__X86_64__) || defined(_M_I386) || defined(__X86__) || defined(__I86__) || defined(_M_I86) || defined(_M_I8086) || defined(_M_I286)
#define CONFIG_CPU_X86 1
#else
#define CONFIG_CPU_X86 1
#endif
#endif

#if !defined(CONFIG_CPU_UNALIGN)
#if CONFIG_CPU_X86
#define CONFIG_CPU_UNALIGN 1  /* CPU supports unaligned memory access. i386 and amd64 do, arm and arm64 don't.  */
#else
#define CONFIG_CPU_UNALIGN 0
#endif
#endif

#if !defined(CONFIG_CPU_IDIV_TO_ZERO)
#if CONFIG_CPU_X86
#define CONFIG_CPU_IDIV_TO_ZERO 1  /* Signed integer division is guaranteed to round towards zero. */
#else
#define CONFIG_CPU_IDIV_TO_ZERO 0
#endif
#endif

#if !defined(CONFIG_INT_SHIFT_OK_31)
#if CONFIG_IS_SIZEOF_INT_AT_LEAST_4  /* 32-bit or 64-bit x86. Doesn't match 16-bit. */
#define CONFIG_INT_SHIFT_OK_31 1  /* `(value_t)x << 31' and `(value_t)x >> 31' works in C for 16-bit and 32-bit value_t. */
#else
#define CONFIG_INT_SHIFT_OK_31 0
#endif
#endif

#ifndef CONFIG_BALANCED
#define CONFIG_BALANCED 1
#endif

#ifndef CONFIG_STRUCT_PACKED
#if defined(__DOSMC__) || ((defined(__WATCOMC__) || defined(__GNUC__) || defined(__TINYC__)) && CONFIG_CPU_UNALIGN)
#define CONFIG_STRUCT_PACKED 1
#else
#define CONFIG_STRUCT_PACKED 0
#endif
#endif

#undef  STRUCT_PACKED_PREFIX
#define STRUCT_PACKED_PREFIX
#undef  STRUCT_PACKED_SUFFIX
#define STRUCT_PACKED_SUFFIX
#if CONFIG_STRUCT_PACKED
#if defined(__DOSMC__) || (defined(__WATCOMC__) && CONFIG_CPU_UNALIGN)
#undef  STRUCT_PACKED_PREFIX
#define STRUCT_PACKED_PREFIX _Packed  /* Disable extra aligment byte at the end of `struct label' etc. */
#else
#if (defined(__GNUC__) || defined(__TINYC__)) && CONFIG_CPU_UNALIGN
#undef  STRUCT_PACKED_SUFFIX
#define STRUCT_PACKED_SUFFIX __attribute__((packed)) __attribute__((aligned(1)))
#endif
#endif
#endif

#ifndef CONFIG_DOSMC_PACKED
#ifdef __DOSMC__
#define CONFIG_DOSMC_PACKED 1
#else
#define CONFIG_DOSMC_PACKED 0
#endif
#endif
#if CONFIG_DOSMC_PACKED && !defined(__DOSMC__)
#  error CONFIG_DOSMC_PACKED needs __DOSMC__.
#endif

#ifndef CONFIG_MALLOC_FAR_USING_SYS_BRK
#define CONFIG_MALLOC_FAR_USING_SYS_BRK 0
#endif

#ifndef CONFIG_CAN_FD_BE_NEGATIVE
#  define CONFIG_CAN_FD_BE_NEGATIVE 0
#endif
#if CONFIG_CAN_FD_BE_NEGATIVE
#  define HAS_OPEN_FAILED(result) ((result) == -1)
#else
#  define HAS_OPEN_FAILED(result) ((result) < 0)
#endif

#ifdef __GNUC__
#  define UNALIGNED __attribute__((aligned(1)))
#  if defined(__i386__) || defined(__386) || defined(_M_I386) || defined(_M_ARM) || defined(__m68k__) || defined(__powerpc__) || defined(_M_PPC)  /* Not the 64-bit variants. */
#    define ALIGN_MAYBE_4 __attribute__((aligned(4)))
#  else
#    define ALIGN_MAYBE_4
#  endif
#else
#  ifdef __WATCOMC__
#    define UNALIGNED __unaligned
#  else
#    define UNALIGNED
#  endif
#  define ALIGN_MAYBE_4
#endif

#ifdef __DOSMC__
__LINKER_FLAG(stack_size__0x140)  /* Specify -sc to dosmc, and run it to get the `max st:HHHH' value printed, and round up 0xHHHH to here. Typical value: 0x134. */
/* Below is a simple malloc implementation using an arena which is never
 * freed. Blocks are rounded up to paragraph (16-byte) boundary.
 */
#ifndef __MOV_AX_PSP_MCB__
#error Missing __MOV_AX_PSP_MCB__, please compile .c file with dosmc directly.
#endif
static struct {
  unsigned malloc_end_para;  /* Paragraph (segment) of end-of-heap. */
  char far *malloc_p;  /* First free byte on the heap. */
} __malloc_struct__;
static void malloc_init(void);
#pragma aux malloc_init = \
"mov ax, ds" \
"add ax, offset __sd_top__" \
"mov word ptr [offset __malloc_struct__+4], ax"  /* Set segment of malloc_p, keep offset (as 0). */ \
__MOV_AX_PSP_MCB__ \
"mov es, ax"  /* Memory Control Block (MCB). */ \
"inc ax"  /* Program Segment Prefix (PSP). */ \
"add ax, [es:3]"  /* Size of block in paragraphs. DOS has preallocated it to maximum size when loading the .com program. */ \
"mov word ptr [offset __malloc_struct__], ax"  /* Set malloc_end_para. */ \
;
/* Allocates `size' bytes unaligned. Returns the beginning of the allocated
 * data. With this arena allocator there is no way to free afterwards.
 */
static void far *malloc_far(int size);

/* We can use an inline assembly function since we call malloc_far only once, so the code won't be copy-pasted many times. */
#pragma aux malloc_far = \
"mov cl, 4" \
"mov si, offset __malloc_struct__+2"  /* Offset part of malloc_p. */ \
"add ax, [si]" \
"mov dx, ax" \
"and ax, 0fh" \
"shr dx, cl" \
"add dx, [si + 2]" \
"cmp dx, word ptr [si - 2]"  /* malloc_end_para. */ \
"ja @$out_of_memory" \
"jb @$fits" \
"test ax, ax" \
"jz @$fits" \
"@$out_of_memory:" \
"xor ax, ax" \
"xor dx, dx"  /* Set result pointer to NULL. */ \
"jmp short @$done" \
"@$fits:" \
"xchg ax, [si]" \
"xchg dx, [si + 2]" \
"@$done:" \
value [dx ax] \
parm [ax] \
modify [si cl]
#  define MY_FAR far
#  define USING_FAR 1
/* strcpy_far(...) and strcmp_far(...) are defined in <dosmc.h>. */
#else  /* Of ifdef __DOSMC__ */
#  define MY_FAR
#  define USING_FAR 0
#  define strcpy_far(dest, src) strcpy(dest, src)
#  define strcmp_far(s1, s2) strcmp(s1, s2)
#  define malloc_init() do {} while (0)
#  if CONFIG_MALLOC_FAR_USING_SYS_BRK
/* MAYBE_STATIC void *sys_brk(void *addr); */  /* Provided by the libc. */
#if 0  /* For debugging. */
static void writehex(const char *hdr, unsigned long u) {
    char tmp[9], *p = tmp + 8;
    unsigned char n;
    (void)!write(2, hdr, strlen(hdr));
    *p = '\n';
    while (p != tmp) {
        n = u & 15;
        if (n > 9) n += 'a' - '0' - 10;
        *--p = n + '0';
        u >>= 4;
    }
    (void)!write(2, tmp, 9);
}
#endif
/*
 ** A simplistic allocator which creates a heap of 64 KiB first, and then
 ** doubles it when necessary. It is implemented using Linux system call
 ** brk(2), exported by the libc as sys_brk(...). free(...)ing is not
 ** supported. Returns an unaligned address (which is OK on x86).
 **
 ** TODO(pts): Rewrite it in assembly, size-optimize it.
 */
static void *malloc_far(size_t size) {
    static char *base, *free, *end;
    ssize_t new_heap_size;
    if ((ssize_t)size <= 0) return NULL;  /* Fail if size is too large (or 0). */
    if (!base) {
        if (!(base = free = (char*)sys_brk(NULL))) return NULL;  /* Error getting the initial data segment size for the very first time. */
        new_heap_size = 64 << 10;  /* 64 KiB. */
        end = base + new_heap_size;
        goto grow_heap;
    }
    while (size > (size_t)(end - free)) {  /* Double the heap size until there is `size' bytes free. */
        new_heap_size = (end - base) << 1;  /* !! TODO(pts): Don't allocate more than 1 MiB if not needed. */
      grow_heap:
        if ((ssize_t)new_heap_size <= 0 || (size_t)base + new_heap_size < (size_t)base) return NULL;  /* Heap would be too large. */
        end = base + new_heap_size;
        if ((char*)sys_brk(end) != end) return NULL;  /* Out of memory. */
    }
    free += size;
    return free - size;
}
#  else  /* Of if CONFIG_MALLOC_FAR_USING_SYS_BRK. */
#    define malloc_far(size) malloc(size)
#  endif  /* Else if CONFIG_MALLOC_FAR_USING_SYS_BRK. */
#endif  /* Else ifdef __DOSMC__. */

/* Example usage:
 * static const STRING_WITHOUT_NUL(msg, "Hello, World!\r\n$");
 * ... printmsgx(msg);
 */
#ifdef __cplusplus  /* We must reserve space for the NUL. */
#define MY_STRING_WITHOUT_NUL(name, value) UNALIGNED char name[sizeof(value)] = value
#define STRING_SIZE_WITHOUT_NUL(name) (sizeof(name) - 1)
#else
#define MY_STRING_WITHOUT_NUL(name, value) UNALIGNED char name[sizeof(value) - 1] = value
#define STRING_SIZE_WITHOUT_NUL(name) (sizeof(name))
#endif

/* We aim for compatibility with NASM 0.98.39, so we do unsigned by default.
 * Signed (sign-extended): NASM 0.99.06, Yasm 1.2.0, Yasm, 1.3.0, NASM 2.13.02.
 * Unsigned (zero-extended): NASM 0.98.39
 */
#ifndef CONFIG_SHIFT_SIGNED
#define CONFIG_SHIFT_SIGNED 0
#endif

#ifndef DEBUG
#define DEBUG 0
#endif
#if DEBUG && !defined(__DOSMC__)  /* fprintf not available in __DOSMC__. */
#include <stdio.h>
#define DEBUG0(fmt) fprintf(stderr, "debug: " fmt)
#define DEBUG1(fmt, a1) fprintf(stderr, "debug: " fmt, a1)
#define DEBUG2(fmt, a1, a2) fprintf(stderr, "debug: " fmt, a1, a2)
#define DEBUG3(fmt, a1, a2, a3) fprintf(stderr, "debug: " fmt, a1, a2, a3)
#define DEBUG4(fmt, a1, a2, a3, a4) fprintf(stderr, "debug: " fmt, a1, a2, a3, a4)
#else
#define DEBUG0(fmt) do {} while (0)
#define DEBUG1(fmt, a1) do {} while (0)
#define DEBUG2(fmt, a1, a2) do {} while (0)
#define DEBUG3(fmt, a1, a2, a3) do {} while (0)
#define DEBUG4(fmt, a1, a2, a3, a4) do {} while (0)
#endif

static char *output_filename;
static int output_fd;

static int listing_fd = -1;

#ifndef CONFIG_VALUE_BITS
#define CONFIG_VALUE_BITS 32
#endif

#undef IS_VALUE_LONG
#if CONFIG_VALUE_BITS == 16
#define IS_VALUE_LONG 0
#define FMT_VALUE ""
typedef short value_t;  /* At least CONFIG_VALUE_BITS bits, preferably exactly. */  /* !! TODO(pts): Use uvalue_t in more location, to get modulo 2**n arithmetics instead of undefined behavior without gcc -fwrapv. */
typedef unsigned short uvalue_t;  /* At least CONFIG_VALUE_BITS bits, preferably exactly. */
#define GET_VALUE(value) (value_t)(sizeof(short) == 2 ? (short)(value) : (short)(((short)(value) & (short)0x7fff) | -((short)(value) & (short)0x8000U)))  /* Sign-extended. */
#define GET_UVALUE(value) (uvalue_t)(sizeof(unsigned short) == 2 ? (unsigned short)(value) : (unsigned short)(value) & 0xffffU)
#define GET_U16(value) (unsigned short)(sizeof(unsigned short) == 2 ? (unsigned short)(value) : (unsigned short)(value) & 0xffffU)
#else
#if CONFIG_VALUE_BITS == 32
#if CONFIG_IS_SIZEOF_INT_AT_LEAST_4  /* Optimization in case sizeof(long) == 8, it would be too much. */
#define IS_VALUE_LONG 0
#define FMT_VALUE ""
typedef int value_t;
typedef unsigned uvalue_t;
#else  /* sizeof(long) >= 4 is guaranteed by the C standard. */
#define IS_VALUE_LONG 1
#define FMT_VALUE "l"
typedef long value_t;
typedef unsigned long uvalue_t;
#endif
#define GET_VALUE(value) (value_t)(sizeof(value_t) == 4 ? (value_t)(value) : sizeof(int) == 4 ? (value_t)(int)(value) : sizeof(long) == 4 ? (value_t)(long)(value) : (value_t)(((long)(value) & 0x7fffffffL) | -((long)(value) & (long)0x80000000UL)))
#define GET_UVALUE(value) (uvalue_t)(sizeof(uvalue_t) == 4 ? (uvalue_t)(value) : sizeof(unsigned) == 4 ? (uvalue_t)(unsigned)(value) : sizeof(unsigned long) == 4 ? (uvalue_t)(unsigned long)(value) : (uvalue_t)(value) & 0xffffffffUL)
#define GET_U16(value) (unsigned short)(sizeof(unsigned short) == 2 ? (unsigned short)(value) : (unsigned short)(value) & 0xffffU)
#else
#error CONFIG_VALUE_BITS must be 16 or 32.
#endif
#endif
typedef char assert_value_size[sizeof(value_t) * 8 >= CONFIG_VALUE_BITS];

#define CONFIG_BBPRINTF_LONG IS_VALUE_LONG
#define CONFIG_BBPRINTF_STATIC static
#include "bbprintf.c"

static uvalue_t line_number;

static unsigned short assembler_pass;  /* 0 at startup, 1 at offset calculation, >= 2 at code generation. */
static unsigned char size_decrease_count;
static value_t default_start_address;
static value_t start_address;
static value_t current_address;
static char is_address_used;
static char is_start_address_set;

static unsigned char instruction_addressing;
static unsigned char instruction_offset_width;
/* Machine code byte value or 0 segment register missing from effective address [...]. */
static char instruction_addressing_segment;
static unsigned short instruction_offset;

static unsigned char instruction_register;

static value_t instruction_value;  /* Always all bits valid. */

/*
 ** -O0: 2-pass, assume longest on undefined label, exactly the same as NASM 0.98.39 and 0.99.06 default and -O0. This is the default.
 ** -O1: 2-pass, assume longest on undefined label, make immediates and effective address displacements as short as possble without looking forward.
 ** -Ox == -OX == -O3 == -O9: full, multipass optimization, make it as short as possible, same as NASM 0.98.39 -O9 and newer NASM 2.x default.
 */
static unsigned char opt_level;
static unsigned char do_opt_lea;  /* -OL. */
static unsigned char do_opt_segreg;  /* -OG. */
static unsigned char do_opt_int;  /* -OI. */

#define MAX_SIZE        256

static UNALIGNED char instr_name[10];  /* Assembly instruction mnemonic name or preprocessor directive name. Always ends with '\0', maybe truncated. */
static UNALIGNED char global_label[(MAX_SIZE - 2) * 2 + 1];  /* MAX_SIZE is the maximum allowed line size including the terminating '\n'. Thus 2 in `- 2' is the size of the shortest trailing ":\n". */
static char *global_label_end;

static char *g;  /* !! TODO(pts): Rename this variable, make it longer for easier searching. */
static char generated[8];
static char *generated_ptr;

#ifndef CONFIG_SUPPORT_WARNINGS
#define CONFIG_SUPPORT_WARNINGS 0
#endif

static uvalue_t errors;
#if CONFIG_SUPPORT_WARNINGS
static uvalue_t warnings;
#endif
static uvalue_t bytes;
static char have_labels_changed;
static unsigned char cpu_level;

STRUCT_PACKED_PREFIX struct label {
#if CONFIG_DOSMC_PACKED
    /* The fields .left_right_ofs, .left_seg_swapped and .right_seg together
     * contain 2 far pointers (tree_left and tree_right), the is_node_deleted
     * bit and (if CONFIG_BALANCED is true) the is_node_red bit.
     * .left_seg_swapped contains the 16-bit segment part of tree_left (it's
     * byte-swapped (so it's stored big endian), and all bits are negated),
     * and .right_seg contains the 16-bit segment part of tree_right.
     * .left_right_ofs contains the offset of the far pointers, the
     * is_node_deleted bit and (if CONFIG_BALANCED is true) the is_node_red
     * bit. It is assumed that far pointer offsets are 4 bits wide
     * (0 <= offset <= 15), because malloc_far guarantees it (with its
     * `and ax, 0fh' instruction).
     *
     * Lemma 1. The first byte of .left_seg_swapped is nonzero. Proof. If it
     * was zero, then the high 8 bits of left_seg would be 0xff, thus the
     * linear memory address for tree_left (left child) would be at least
     * 0xff000, which is too large for a memory address in DOS conventional
     * memory ending at 0xa0000, and malloc_far allocates from there.
     *
     * If CONFIG_BALANCED is false, bits of .left_right_ofs look like
     * LLLDRRRR, where LLLM is the 4-bit offset of tree_left (see below how
     * to get M), RRRR is the 4-bit offset of tree_right, and D is the
     * is_node_deleted bit.
     *
     * If CONFIG_BALANCED is true, bits of .left_right_ofs look like
     * LLLDRRRE, where LLLM is the 4-bit offset of tree_left, RRRS is the
     * 4-bit offset of tree_right, D is the is_node_deleted bit, E is the
     * is_node_red bit. The lower M and S bits of the offsets are not stored,
     * but they will be inferred like below. The pointer with the offset LLL0
     * is either correct or 1 less than the correct LLL1. If it's correct, then
     * it points to a nonzero .left_seg_swapped (see Lemma 1 above). If it's 1
     * less, then it points to the all-zero NUL byte (the NUL terminator of the
     * name in the previous label). Thus by comparing the byte at offset LLL0
     * to zero, we can infer whether M is 0 (iff the byte is nonzero) or 1 (iff
     * the byte is zero). For this to work we need that the very first struct
     * label starts at an even offset; this is guaranteed by malloc_far.
     */
    unsigned left_seg_swapped;  /* Byte-swapped (so it's stored big endian), all bits negated. The first byte is never zero. */
    unsigned right_seg;
    unsigned char left_right_ofs;
#else
    struct label MY_FAR *tree_left;
    struct label MY_FAR *tree_right;
#endif
    value_t value;
#if CONFIG_BALANCED && !CONFIG_DOSMC_PACKED
    char is_node_red;  /* Is it a red node of the red-black tree? */
#endif
#if !CONFIG_DOSMC_PACKED
    char is_node_deleted;
#endif
    char name[1];  /* Usually multiple characters terminated by NUL. The last byte is alsways zero. */
} STRUCT_PACKED_SUFFIX;

static struct label MY_FAR *label_list;
static char has_undefined;

#ifndef CONFIG_SPLIT_INSTRUCTION_SET
#if defined(_MSC_VER) && _MSC_VER < 900  /* _MSC_VER < 900: Microsoft Visual C++ 1.52 (800 <= _MSC_VER < 900) doesn't have this limit (C4009) of 2048 bytes. */
/* Without this split, Microsoft C 6.00a (_MSC_VER == 600) will report warning C4009: string too big, trailing characters truncated */
#define CONFIG_SPLIT_INSTRUCTION_SET 1
#else
#define CONFIG_SPLIT_INSTRUCTION_SET 0
#endif
#endif

extern UNALIGNED const char instruction_set[];
#if CONFIG_SPLIT_INSTRUCTION_SET
extern const char *instruction_set_nul;
extern const char instruction_set2[];
#endif

static const MY_STRING_WITHOUT_NUL(register_names, "CSDSESSSALCLDLBLAHCHDHBHAXCXDXBXSPBPSIDI");
#define GP_REGISTER_NAMES (register_names + 8)  /* Skip over segment register names. */

/* Not declaring static for compatibility with C++ and forward declarations. */
extern struct bbprintf_buf message_bbb;

#if CONFIG_SUPPORT_WARNINGS
static void message(int error, const char *message);
static void message1str(int error, const char *pattern, const char *data);
static void message_start(int error);
#define MESSAGE message
#define MESSAGE1STR message1str
#define MESSAGE_START message_start
#else
static void message(const char *message);
static void message1str(const char *pattern, const char *data);
static void message_start(void);
#define MESSAGE(error, message_str) message(message_str)
#define MESSAGE1STR(error, pattern, data) message1str(pattern, data)
#define MESSAGE_START(error) message_start()
#endif
static void message_end(void);

#ifdef __DESMET__
/* Work around bug in DeSmet 3.1N runtime: closeall() overflows buffer and clobbers exit status */
#define exit(status) _exit(status)
#endif

#if CONFIG_BALANCED
/*
 * Each node in the RB tree consumes at least 1 byte of space (for the
 * linkage if nothing else, so there are a maximum of 1 << (sizeof(void *)
 * << 3 rb) tree nodes in any process, and thus, at most that many in any
 * tree.
 *
 * Maximum number of bytes in a process: 1 << (sizeof(void*) << 3).
 * Log2 of maximum number of bytes in a process: sizeof(void*) << 3.
 * Maximum number of tree nodes in a process: 1 << (sizeof(void*) << 3) / sizeof(tree_node).
 * Maximum number of tree nodes in a process is at most: 1 << (sizeof(void*) << 3) / sizeof(rb_node(a_type)).
 * Log2 of maximum number of tree nodes in a process is at most: (sizeof(void*) << 3) - log2(sizeof(rb_node(a_type)).
 * Log2 of maximum number of tree nodes in a process is at most without RB_COMPACT: (sizeof(void*) << 3) - (sizeof(void*) >= 8 ? 4 : sizeof(void*) >= 4 ? 3 : 2).
 */
#  ifndef RB_LOG2_MAX_MEM_BYTES
#    ifdef MSDOS
#      ifdef _M_I386  /* Only __WATCOMC__ (not in GCC, __TURBOC__ or _MSC_VER), only in 32-bit mode, but play it safe. */
#        define RB_LOG2_MAX_MEM_BYTES (sizeof(void near*) == 2 ? 20 : (sizeof(void*) << 3))
#      else
#        define RB_LOG2_MAX_MEM_BYTES 20  /* 1 MiB. */
#    endif
#  else
#    define RB_LOG2_MAX_MEM_BYTES (sizeof(void*) << 3)
#  endif
#endif
/**/
#ifndef RB_LOG2_MAX_NODES
#define RB_LOG2_MAX_NODES (RB_LOG2_MAX_MEM_BYTES - (sizeof(void*) >= 8 ? 4 : sizeof(void*) >= 4 ? 3 : 2) - 1)
#endif
/**/
struct tree_path_entry {
    struct label MY_FAR *label;
    char less;
};
/**/
#endif  /* CONFIG_BALANCED */

#if CONFIG_DOSMC_PACKED
/* Swap the 2 bytes and negate all bits. */
static unsigned swap16(unsigned u);
#pragma aux swap16 = "xchg al, ah" "not ax" value [ax] parm [ax]  /* TODO(pts): Optimize for size, try ax, bx and dx. */
typedef char assert_label_size[sizeof(struct label) == 5 /* left and right pointers, is_node_red */ + sizeof(value_t) + 1 /* trailing NUL in ->name */];
#define RBL_IS_NULL(label) (FP_SEG(label) == 0)
#define RBL_IS_LEFT_NULL(label) ((label)->left_seg_swapped == 0xffffU)
#define RBL_IS_RIGHT_NULL(label) ((label)->right_seg == 0)
#define RBL_IS_DELETED(label) ((label)->left_right_ofs & 0x10)
#define RBL_SET_DELETED_0(label) ((label)->left_right_ofs &= ~0x10)
#define RBL_SET_DELETED_1(label) ((label)->left_right_ofs |= 0x10)
#if CONFIG_BALANCED
/* Also sets IS_DELETED to false. */
#define RBL_SET_LEFT_RIGHT_NULL_ID_0(label) ((label)->left_right_ofs = 0, (label)->left_seg_swapped = 0xffffU, (label)->right_seg = 0)
static struct label MY_FAR *RBL_GET_LEFT(struct label MY_FAR *label) {
    char MY_FAR *p = MK_FP(swap16((label)->left_seg_swapped), ((label)->left_right_ofs >> 4) & 0xe);
    if (*p == '\0') ++p;  /* Skip trailing NUL of previous label. */
    return (struct label MY_FAR*)p;
}
static struct label MY_FAR *RBL_GET_RIGHT(struct label MY_FAR *label) {
    char MY_FAR *p = MK_FP((label)->right_seg, (label)->left_right_ofs & 0xe);
    if (*p == '\0') ++p;  /* Skip trailing NUL of previous label. */
    return (struct label MY_FAR*)p;
}
static void RBL_SET_LEFT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
    label->left_seg_swapped = swap16(FP_SEG(ptr));
    label->left_right_ofs = (label->left_right_ofs & 0x1f) | (FP_OFF(ptr) & 0xe) << 4;  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
}
static void RBL_SET_RIGHT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
    label->right_seg = FP_SEG(ptr);
    label->left_right_ofs = (label->left_right_ofs & 0xf1) | (FP_OFF(ptr) & 0xe);  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
}
#define RBL_IS_RED(label) ((label)->left_right_ofs & 1)  /* Nonzero means true. */
#define RBL_COPY_RED(label, source_label) ((label)->left_right_ofs = ((label)->left_right_ofs & 0xfe) | ((source_label)->left_right_ofs & 1))
#define RBL_SET_RED_0(label) ((label)->left_right_ofs &= 0xfe)
#define RBL_SET_RED_1(label) ((label)->left_right_ofs |= 1)
#else  /* Else CONFIG_BALANCED. */
#define RBL_SET_LEFT_RIGHT_NULL_ID_0(label) ((label)->left_right_ofs = (label)->left_seg_swapped = 0xffffU, (label)->right_seg = 0)
static struct label MY_FAR *RBL_GET_LEFT(struct label MY_FAR *label) {
    char MY_FAR *p = MK_FP(swap16((label)->left_seg_swapped), ((label)->left_right_ofs >> 4) & 0xe);
    if (*p == '\0') ++p;  /* Skip trailing NUL of previous label. */
    return (struct label MY_FAR*)p;
}
static struct label MY_FAR *RBL_GET_RIGHT(struct label MY_FAR *label) {
    char MY_FAR *p = MK_FP((label)->right_seg, (label)->left_right_ofs & 0xf);
    return (struct label MY_FAR*)p;
}
static void RBL_SET_LEFT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
    label->left_seg_swapped = swap16(FP_SEG(ptr));
    label->left_right_ofs = (label->left_right_ofs & 0x1f) | (FP_OFF(ptr) & 0xe) << 4;  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
}
static void RBL_SET_RIGHT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
    label->right_seg = FP_SEG(ptr);
    label->left_right_ofs = (label->left_right_ofs & 0xf0) | FP_OFF(ptr);  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
}
#endif  /* CONFIG_BALANCED. */
#else
#define RBL_IS_NULL(label) ((label) == NULL)
#define RBL_IS_LEFT_NULL(label) ((label)->tree_left == NULL)
#define RBL_IS_RIGHT_NULL(label) ((label)->tree_right == NULL)
#define RBL_SET_LEFT_RIGHT_NULL_ID_0(label) ((label)->tree_left = (label)->tree_right = NULL, (label)->is_node_deleted = 0)
#define RBL_GET_LEFT(label) ((label)->tree_left)
#define RBL_GET_RIGHT(label) ((label)->tree_right)
#define RBL_SET_LEFT(label, ptr) ((label)->tree_left = (ptr))
#define RBL_SET_RIGHT(label, ptr) ((label)->tree_right = (ptr))
#define RBL_IS_DELETED(label) ((label)->is_node_deleted)
#define RBL_SET_DELETED_0(label) ((label)->is_node_deleted = 0)
#define RBL_SET_DELETED_1(label) ((label)->is_node_deleted = 1)
#if CONFIG_BALANCED
#define RBL_IS_RED(label) ((label)->is_node_red)  /* Nonzero means true. */
#define RBL_COPY_RED(label, source_label) ((label)->is_node_red = (source_label)->is_node_red)
#define RBL_SET_RED_0(label) ((label)->is_node_red = 0)
#define RBL_SET_RED_1(label) ((label)->is_node_red = 1)
#endif  /* CONFIG_BALANCED. */
#endif  /* CONFIG_DOSMC_PACKED. */

static void fatal_out_of_memory(void) {
    MESSAGE(1, "Out of memory");  /* Only applies dynamically allocated memory (malloc(...)), e.g. for labels and wide instructions. */
    exit(1);
}

/*
 ** Defines a new label.
 **
 ** If the label already exists, it adds a duplicate one. This is not
 ** useful, so the caller is recommended to call define_label(name, ...)
 ** only if find_label(name) returns NULL.
 */
static struct label MY_FAR *define_label(const char *name, value_t value) {
    struct label MY_FAR *label;

    /* Allocate label */
    label = (struct label MY_FAR*)malloc_far((size_t)&((struct label*)0)->name + 1 + strlen(name));
    if (RBL_IS_NULL(label)) {
        fatal_out_of_memory();
        return NULL;
    }

    /* Fill label */
    if (0) DEBUG2("define_label name=(%s) value=0x%x\n", name, (unsigned)value);
    RBL_SET_LEFT_RIGHT_NULL_ID_0(label);
    label->value = value;
    strcpy_far(label->name, name);

    /* Insert label to binary tree. */
#if CONFIG_BALANCED
    /* Red-black tree node insertion implementation based on: commit on 2021-03-17
     * https://github.com/jemalloc/jemalloc/blob/70e3735f3a71d3e05faa05c58ff3ca82ebaad908/include/jemalloc/internal/rb.h
     *
     * Tree with duplicate keys is untested.
     *
     * With __DOSMC__, this insertion is 319 bytes longer than the unbalanced alternative below.
     */
    {
        /*
         * The choice of algorithm bounds the depth of a tree to twice the binary
         * log of the number of elements in the tree; the following bound follows.
         */
        static ALIGN_MAYBE_4 struct tree_path_entry path[RB_LOG2_MAX_NODES << 1];
        struct tree_path_entry *pathp;
        RBL_SET_RED_1(label);
        path->label = label_list;
        for (pathp = path; !RBL_IS_NULL(pathp->label); pathp++) {
            const char less = pathp->less = strcmp_far(label->name, pathp->label->name) < 0;
            pathp[1].label = less ? RBL_GET_LEFT(pathp->label) : RBL_GET_RIGHT(pathp->label);
        }
        pathp->label = label;
        while (pathp-- != path) {
            struct label MY_FAR *clabel = pathp->label;
            if (pathp->less) {
                struct label MY_FAR *left = pathp[1].label;
                RBL_SET_LEFT(clabel, left);
                if (RBL_IS_RED(left)) {
                    struct label MY_FAR *leftleft = RBL_GET_LEFT(left);
                    if (!RBL_IS_NULL(leftleft) && RBL_IS_RED(leftleft)) {
                        struct label MY_FAR *tlabel;
                        RBL_SET_RED_0(leftleft);
                        tlabel = RBL_GET_LEFT(clabel);
                        RBL_SET_LEFT(clabel, RBL_GET_RIGHT(tlabel));
                        RBL_SET_RIGHT(tlabel, clabel);
                        clabel = tlabel;
                    }
                } else {
                    goto done;
                }
            } else {
                struct label MY_FAR *right = pathp[1].label;
                RBL_SET_RIGHT(clabel, right);
                if (RBL_IS_RED(right)) {
                    struct label MY_FAR *left = RBL_GET_LEFT(clabel);
                    if (!RBL_IS_NULL(left) && RBL_IS_RED(left)) {
                         RBL_SET_RED_0(left);
                         RBL_SET_RED_0(right);
                         RBL_SET_RED_1(clabel);
                     } else {
                         struct label MY_FAR *tlabel;
                         tlabel = RBL_GET_RIGHT(clabel);
                         RBL_SET_RIGHT(clabel, RBL_GET_LEFT(tlabel));
                         RBL_SET_LEFT(tlabel, clabel);
                         RBL_COPY_RED(tlabel, clabel);
                         RBL_SET_RED_1(clabel);
                         clabel = tlabel;
                     }
                } else {
                    goto done;
                }
            }
            pathp->label = clabel;
        }
        label_list = path->label;
        RBL_SET_RED_0(label_list);
    }
  done:
#else  /* Unbalanced binary search tree node insertion. */
    if (RBL_IS_NULL(label_list)) {
        label_list = label;
    } else {
        struct label MY_FAR *explore = label_list;
        while (1) {
            const int c = strcmp_far(label->name, explore->name);
            if (c < 0) {
                if (RBL_IS_LEFT_NULL(explore)) {
                    RBL_SET_LEFT(explore, label);
                    break;
                }
                explore = RBL_GET_LEFT(explore);
            } else if (c > 0) {
                if (RBL_IS_RIGHT_NULL(explore)) {
                    RBL_SET_RIGHT(explore, label);
                    break;
                }
                explore = RBL_GET_RIGHT(explore);
            }
        }
    }
#endif
    return label;
}

/*
 ** Find a label.
 **
 ** `name' as passed as a far pointer because reset_macros() needs it.
 */
static struct label MY_FAR *find_label(const char MY_FAR *name) {
    struct label MY_FAR *explore;
    struct label MY_FAR *milestone = NULL;
    int c;

    /* Follows a binary tree */
    explore = label_list;
    while (!RBL_IS_NULL(explore)) {
        c = strcmp_far(name, explore->name);
        if (c == 0) {
            return explore;
        } else if (c < 0) {
            milestone = explore;
            explore = RBL_GET_LEFT(explore);
        } else {
            explore = RBL_GET_RIGHT(explore);
            /* Stop on circular path created by Morris inorder traversal, e.g. in reset_macros(). */
            if (explore == milestone) break;
        }
    }
    return NULL;
}

/*
 ** Print labels sorted to listing_fd (already done by binary tree).
 */
static void print_labels_sorted_to_listing(void) {
    struct label MY_FAR *node = label_list;
    struct label MY_FAR *pre;
    struct label MY_FAR *pre_right;
    /* Morris inorder traversal of binary tree: iterative (non-recursive,
     * so it uses O(1) stack), modifies the tree pointers temporarily, but
     * then restores them, runs in O(n) time.
     */
    while (!RBL_IS_NULL(node)) {
        if (RBL_IS_LEFT_NULL(node)) goto do_print;
        for (pre = RBL_GET_LEFT(node); pre_right = RBL_GET_RIGHT(pre), !RBL_IS_NULL(pre_right) && pre_right != node; pre = pre_right) {}
        if (RBL_IS_NULL(pre_right)) {
            RBL_SET_RIGHT(pre, node);
            node = RBL_GET_LEFT(node);
        } else {
            RBL_SET_RIGHT(pre, NULL);
          do_print:
            if (node->name[0] != '%') {  /* Skip macro definitions. */
#if USING_FAR
                strcpy_far(global_label, node->name);  /* We copy because bbprintf(...) below doesn't support far pointers. */
#endif
                bbprintf(&message_bbb, "%-20s "
#if CONFIG_VALUE_BITS == 32
                                       "%08"
#else
                                       "%04"
#endif
                                       FMT_VALUE "X\r\n",
#if USING_FAR
                                       global_label,
#else
                                       node->name,
#endif
                                       GET_UVALUE(node->value));
            }
            node = RBL_GET_RIGHT(node);
        }
    }
}

/*
 ** Avoid spaces in input
 */
static const char *avoid_spaces(const char *p) {
    for (; *p == ' '; p++) {}
    return p;
}

#ifndef CONFIG_MATCH_STACK_DEPTH
#define CONFIG_MATCH_STACK_DEPTH 100
#endif

/*
 ** Check for a non-first label character, same as in NASM.
 */
static int islabel(int c) {
    return isalpha(c) || isdigit(c) || c == '_' || c == '.' || c == '@' || c == '?' || c == '$' || c == '~' || c == '#';
}

#if 0  /* Unused. */
/*
 ** Check for a first label character (excluding the leading '$' syntax), same as in NASM.
 */
static int islabel1(int c) {
    return isalpha(c) || c == '_' || c == '.' || c == '@' || c == '?';
}
#endif

#ifndef __WATCOMC__  /* This c + (0U - 'A') is needed my Microsoft C 6.00 (_MSC_VER == 600), otherwise (e.g. with `c - 'A' + 0U') it generates incorrect code. */
#define SUB_U(a, b) ((a) + (0U - (b)))  /* This would also work with __DOSMC__, but it would make the code 6 bytes longer. */
#else
#define SUB_U(a, b) ((a) - (b) + 0U)
#endif

/* Returns bool (0 == false or 1 == true) indicating whether the
 * NUL-terminated string p matches the NUL-terminated pattern.
 *
 * The match is performed from left to right, one byte at a time.
 * A '!' in the pattern matches the end-of-string or a non-islabel(...)
 * character and anything afterwards.
 * A '*' in the pattern matches anything afterwards. An uppercase
 * letter in the pattern matches itself and the lowercase equivalent.
 * A '\0' in the pattern matches the '\0', and the matching stops
 * with true. Every other byte in the pattern matches itself, and the
 * matching continues.
 */
static char casematch(const char *p, const char *pattern) {
    char c;
    for (; (c = *pattern++) != '*'; ++p) {
        if (SUB_U(c, 'A') <= 'Z' - 'A' + 0U) {
            if ((*p & ~32) != c) return 0;  /* Letters are matched case insensitively. */
        } else if (c == '!') {
            if (islabel(*p)) return 0;  /* Doesn't return 0 for end-of-string. */
            break;
        } else {
            if (*p != c) return 0;
            if (c == '\0') break;
        }
    }
    return 1;
}

/*
 ** Returns true for prefix EQU, DB, DW and DD.
 */
static int is_colonless_instruction(const char *p) {
    char c = p[0] & ~32;
    if (c == 'E') {
        return casematch(p, "EQU!");
    } else if (c == 'D') {
        c = p[1] & ~32;
        return (c == 'B' || c == 'W'
#if CONFIG_VALUE_BITS == 32
            || c == 'D'  /* "DD". */
#endif
            ) && !islabel(p[2]);
    } else if (c == 'R') {
        return casematch(p, "RESB!");
    } else if (c == 'T') {
        return casematch(p, "TIMES!");
    } else {
        return 0;
    }
}

/*
 ** Returns NULL if not a label, otherwise after the label.
 */
static const char *match_label_prefix(const char *p) {
    const char *p2;
    union { char a[2]; short s; } cd;  /* Avoid GCC warning: dereferencing type-punned pointer will break strict-aliasing rules [-Wstrict-aliasing] */
    cd.a[0] = *p;
    if (cd.a[0] == '$') {
        cd.a[0] = *++p;
        if (isalpha(cd.a[0])) goto goodc;
    } else if (isalpha(cd.a[0])) {
        if (isalpha(cd.a[1] = p[1])) {
            if (!islabel(p[2])) {  /* 2-character label. */
                if (CONFIG_CPU_UNALIGN && sizeof(short) == 2) {
                    cd.s &= ~0x2020;
                } else {
                    cd.a[0] &= ~32;
                    cd.a[1] &= ~32;
                }
                for (p2 = (char*)register_names; p2 != register_names + STRING_SIZE_WITHOUT_NUL(register_names); p2 += 2) {
                    if ((CONFIG_CPU_UNALIGN && sizeof(short) == 2) ? (cd.s == *(short*)p2) : (cd.a[0] == p2[0] && cd.a[1] == p2[1])) return NULL;  /* A register name without a `$' prefix is not a valid label name. */
                }
            }
            if (is_colonless_instruction(p)) return NULL;
            /* TODO(pts): Is it faster or smaller to add these to a binary tree? */
            if (casematch(p, "SHORT!") || casematch(p, "NEAR!") || casematch(p, "FAR!") || casematch(p, "BYTE!") || casematch(p, "WORD!") || casematch(p, "DWORD!") || casematch(p, "STRICT!")) return NULL;
        }
        goto goodc;
    }
    if (cd.a[0] != '_' && cd.a[0] != '.' && cd.a[0] != '@' && cd.a[0] != '?') return NULL;
  goodc:
    while (islabel(*++p)) {}
    return p;
}

#if CONFIG_CPU_IDIV_TO_ZERO
#define VALUE_DIV(a, b) ((value_t)(a) / (value_t)(b))
#define VALUE_MOD(a, b) ((value_t)(a) % (value_t)(b))
#else
#define VALUE_DIV(a, b) value_div((a), (b))
#define VALUE_MOD(a, b) value_mod((a), (b))
/*
 ** Deterministic signed division, rounds towards zero.
 ** The result is undefined if b == 0. It's defined for a == int_min and b == -1.
 */
static value_t value_div(value_t a, value_t b) {
    const char an = (a < 0);
    const char bn = (b < 0);
    const uvalue_t d = (uvalue_t)(an ? -a : a) / (uvalue_t)(bn ? -b : b);
    return an == bn ? d : -d;
}
static value_t value_mod(value_t a, value_t b) {
    return a - value_div(a, b) * b;
}
#endif

static const char *match_register(const char *p, int width, unsigned char *reg);

/*
 ** Match expression at match_p, update (increase) match_p or set it to NULL on error.
 ** level == 0 is top tier, that's how callers should call it.
 ** Saves the result to `instruction_value', or 0 if there was an undefined label.
 ** Sets `has_undefined' indicating whether ther was an undefined label.
 */
static const char *match_expression(const char *match_p) {
    static ALIGN_MAYBE_4 struct match_stack_item {
        signed char casei;
        unsigned char level;
        value_t value1;
    } match_stack[CONFIG_MATCH_STACK_DEPTH];  /* This static variable makes match_expression(...) not reentrant. */
    struct match_stack_item *msp;  /* Stack pointer within match_stack. */
    value_t value1;
    value_t value2;
    /*union {*/  /* Using union to save stack memory would make __DOSMC__ program larger. */
        unsigned shift;
        char *p2;
        char *p3;
        struct label MY_FAR *label;
    /*} u;*/
    char c;
    unsigned char level;

    level = 0;
    has_undefined = 0;
    msp = match_stack;
    goto do_match;
  do_pop:
    --msp;
    value2 = value1;
    value1 = msp->value1;
    level = msp->level;
    if (msp->casei < 0) {  /* End of expression in patentheses. */
        value1 = value2;
        match_p = avoid_spaces(match_p);
        if (match_p[0] != ')') {
            MESSAGE(1, "Missing close paren");
          match_error:
            instruction_value = 0;
            return NULL;
        }
        match_p++;
        if (++msp->casei != 0) {
            level = 0;
            if (++msp == match_stack + sizeof(match_stack) / sizeof(match_stack[0])) goto too_deep;
        }
        goto have_value1;
    }
#define MATCH_CASEI_LEVEL_TO_VALUE2(casei2, level2) do { msp->casei = casei2; msp->level = level; level = level2; goto do_push; case casei2: ; } while (0)
    switch (msp->casei) {  /* This will jump after one of the MATCH_CASEI_LEVEL_TO_VALUE2(...) macros. */
      do_push:
        msp->value1 = value1;
        if (++msp == match_stack + sizeof(match_stack) / sizeof(match_stack[0])) { too_deep:
            MESSAGE(1, "Expression too deep");  /* Stack overflow in match stack. */
            goto match_error;
        }
      do_match:
        match_p = avoid_spaces(match_p);
        value1 = 0;  /* In addition to preventing duplicate initialization below, it also does pacify GCC 7.5.0: do_push jumped to by MATCH_CASEI_LEVEL_TO_VALUE2 does an `msp->value1 = value1'. */
        if ((c = match_p[0]) == '(') {  /* Parenthesized expression. */
            /* Count the consecutive open parentheses, and add a single match_stack_item. */
            for (; (c = (match_p = avoid_spaces(match_p))[0]) == '(' && value1 > -127; ++match_p, --value1) {}
            msp->casei = value1; msp->level = level; level = 0; goto do_push;
        } else if (c == '-' || c == '+' || c == '~') {  /* Unary -, + and ~. */
            /*value1 = 0;*/  /* Delta, can be nonzero iff unary ~ is encountered. */
            if (c == '~') { --value1; c = '-'; }
            for (;;) {  /* Shortcut to squeeze multiple unary - and + operators to a single match_stack_item. */
                match_p = avoid_spaces(match_p + 1);
                if (match_p[0] == '+') {}
                else if (match_p[0] == '-') { do_switch_pm: c ^= 6; }  /* Switch between ASCII '+' and '-'. */
                else if (match_p[0] == '~') { value1 += (value_t)c - ('-' - 1); goto do_switch_pm; }  /* Either ++value1 or --value1. */
                else { break; }
            }
            if (c == '-') {
              MATCH_CASEI_LEVEL_TO_VALUE2(2, 6);
              value1 -= value2;
            } else {
              MATCH_CASEI_LEVEL_TO_VALUE2(3, 6);
              value1 += value2;
            }
        } else if (c == '0' && (match_p[1] | 32) == 'b') {  /* Binary or hexadecimal. */
            p2 = (char*)match_p;
            match_p += 2;
            /*value1 = 0;*/
            while ((c = match_p[0]) == '0' || c == '1' || c == '_') {
                if (c != '_') {
                    value1 <<= 1;
                    if (c == '1')
                        value1 |= 1;
                }
                match_p++;
            }
          parse_hex1:  /* Maybe hexadecimal. */
            if ((c | 32) == 'h' || isxdigit(c)) {  /* Hexadecimal, start again. */
                match_p = p2;
                value1 = 0;
                shift = 1;
                goto parse_hex;
            }
            goto check_nolabel;
        } else if (c == '0' && (match_p[1] | 32) == 'x') {  /* Hexadecimal. */
            match_p += 2;
          parse_hex0:
            shift = 0;
          parse_hex:
            /*value1 = 0;*/
            for (; c = match_p[0], isxdigit(c); ++match_p) {
                c -= '0';
                if ((unsigned char)c > 9) c = (c & ~32) - 7;
                value1 = (value1 << 4) | c;
            }
            if (shift) {  /* Expect c == 'H' || c == 'h'. */
                if ((c | 32) != 'h') goto bad_label;
                ++match_p;
            }
            goto check_nolabel;
        } else if (c == '0' && (match_p[1] | 32) == 'o') {  /* Octal. NASM 0.98.39 doesn't support it, but NASM 0.99.06 does. */
            match_p += 2;
            shift = 0;
          parse_octal:
            /*value1 = 0;*/
            for (; (unsigned char)(c = SUB_U(match_p[0], '0')) < 8U; ++match_p) {
                value1 = (value1 << 3) | c;
            }
            if (shift) {  /* Expect c == 'O' || c == 'o'. */
                if (c != (char)('o' - '0')) goto bad_label;
                ++match_p;
            }
          check_nolabel:
            c = match_p[0];
            if (islabel(c)) goto bad_label;
        } else if (c == '\'' || c == '"') {  /* Character constant. */
            /*value1 = 0;*/ shift = 0;
            for (++match_p; match_p[0] != '\0' && match_p[0] != c; ++match_p) {
                if (shift < sizeof(value_t) * 8) {
                    value1 |= (unsigned char)match_p[0] << shift;
                    shift += 8;
                }
            }
            if (match_p[0] == '\0') {
                MESSAGE(1, "Missing close quote");
                goto match_error;
            } else {
                ++match_p;
            }
        } else if (isdigit(c)) {  /* Decimal or hexadecimal, even if it starts with '0'. */
            /*value1 = 0;*/
            for (p2 = (char*)match_p; (unsigned char)(c = SUB_U(match_p[0], '0')) <= 9U; ++match_p) {
                value1 = value1 * 10 + c;
            }
            c = match_p[0] | 32;
            if (c == 'o') {
                match_p = p2;
                value1 = 0;
                shift = 1;
                goto parse_octal;
            } else if (c == 'b') {
                value1 = 0;
                for (match_p = p2; (unsigned char)(c = SUB_U(match_p[0], '0')) <= 2U; ++match_p) {
                    value1 <<= 1;
                    value1 |= c;
                }
                ++match_p;  /* Skip over the 'b' or 'B'. */
            } else {
                goto parse_hex1;
            }
        } else if (c == '$') {
            c = *++match_p;
            if (c == '$') {  /* Start address ($$). */
                ++match_p;
                is_address_used = 1;
                value1 = start_address;
                if (islabel(match_p[0])) { bad_label:
                    MESSAGE(1, "bad label");
                }
            } else if (isdigit(c)) {
                /* This is nasm syntax, notice no letter is allowed after $ */
                /* So it's preferrable to use prefix 0x for hexadecimal */
                shift = 0;
                goto parse_hex0;
            } else if (islabel(c)) {
                goto label_expr;
            } else {  /* Current address ($). */
                is_address_used = 1;
                value1 = current_address;
            }
        } else if (match_label_prefix(match_p)) {  /* This also matches c == '$', but we've done that above. */
          label_expr:
            p2 = global_label_end;
            p3 = (c == '.') ? global_label : p2;  /* If label starts with '.', then prepend global_label. */
            for (; islabel(match_p[0]); *p2++ = *match_p++) {}
            *p2 = '\0';
            if (0) DEBUG1("use_label=(%s)\r\n", p3);
            label = find_label(p3);
            if (label == NULL || RBL_IS_DELETED(label)) {
                /*value1 = 0;*/
                has_undefined = 1;
                if (assembler_pass > 1) {
                    MESSAGE1STR(1, "Undefined label '%s'", p3);
                }
            } else {
                value1 = label->value;
            }
            *global_label_end = '\0';  /* Undo the concat to global_label. */
        } else {
            /* TODO(pts): Make this match syntax error nonsilent? What about when trying instructions? */
            goto match_error;
        }
        /* Now value1 contains the value of the expression parsed so far. */
      have_value1:
        if (level <= 5) {
            while (1) {
                match_p = avoid_spaces(match_p);
                if ((c = match_p[0]) == '*') {  /* Multiply operator. */
                    match_p++;
                    MATCH_CASEI_LEVEL_TO_VALUE2(10, 6);
                    value1 *= value2;
                } else if (c == '/' && match_p[1] == '/') {  /* Signed division operator. */
                    match_p += 2;
                    MATCH_CASEI_LEVEL_TO_VALUE2(11, 6);
                    c = 0;
                    goto do_divide;
                } else if (c == '/') {  /* Unsigned division operator. */
                    match_p++;
                    MATCH_CASEI_LEVEL_TO_VALUE2(12, 6);
                    c = 1;
                  do_divide:
                    if (GET_UVALUE(value2) == 0) {
                        if (assembler_pass > 1)  /* This also implies !has_undefined, if there is no bug. */
                            MESSAGE(1, "division by zero");
                        value2 = 1;
                    }
                    value1 = c ? (value_t)(GET_UVALUE(value1) / GET_UVALUE(value2)) : VALUE_DIV(GET_VALUE(value1), GET_VALUE(value2));
                } else if (c == '%' && match_p[1] == '%' && !islabel(match_p[2])) {  /* Signed modulo operator. We check for islabel(...) to make it similar to NASM, which uses %%... syntax for multiine macros. */
                    match_p += 2;
                    MATCH_CASEI_LEVEL_TO_VALUE2(13, 6);
                    c = 0;
                    goto do_modulo;
                } else if (c == '%' && !islabel(match_p[1])) {  /* Unsigned modulo operator. We check for islabel(...) to make it similar to NASM, which uses %%... syntax for multiine macros. */
                    match_p++;
                    MATCH_CASEI_LEVEL_TO_VALUE2(14, 6);
                    c = 1;
                  do_modulo:
                    if (GET_UVALUE(value2) == 0) {
                        if (assembler_pass > 1)  /* This also implies !has_undefined, if there is no bug. */
                            MESSAGE(1, "modulo by zero");
                        value2 = 1;
                    }
                    value1 = c ? (value_t)(GET_UVALUE(value1) % GET_UVALUE(value2)) : VALUE_MOD(GET_VALUE(value1), GET_VALUE(value2));
                } else {
                    break;
                }
            }
        }
        if (level <= 4) {
            while (1) {
                match_p = avoid_spaces(match_p);
                if (((c = match_p[0]) == '+' || c == '-') && !match_register(match_p + 1, 16, NULL)) {  /* We stop early before matching `+si', so match_addressing(...) can pick up right after the '+' or '-'. */
                    if (c == '+') {  /* Add operator. */
                        match_p++;
                        MATCH_CASEI_LEVEL_TO_VALUE2(15, 5);
                        value1 += value2;
                    } else /*if (c == '-')*/ {  /* Subtract operator. */
                        match_p++;
                        MATCH_CASEI_LEVEL_TO_VALUE2(16, 5);
                        value1 -= value2;
                    }
                } else {
                    break;
                }
            }
        }
        if (level <= 3) {
            while (1) {
                match_p = avoid_spaces(match_p);
                if (((c = match_p[0]) == '<' && match_p[1] == '<') || (c == '>' && match_p[1] == '>')) { /* Shift to left */
                    match_p += 2;
                    if (c == '<') {
                        MATCH_CASEI_LEVEL_TO_VALUE2(17, 4);
                        c = 1;
                    } else {
                        MATCH_CASEI_LEVEL_TO_VALUE2(18, 4);
                        c = 0;
                    }
                    if (GET_UVALUE(value2) > 31) {
                        /* 8086 processor (in 16-bit mode) uses all 8 bits of the shift amount.
                         * i386 and amd64 processors in both 16-bit and 32-bit mode uses the last 5 bits of the shift amount.
                         * amd64 processor in 64-bit mode uses the last 6 bits of the shift amount.
                         * To get deterministic output, we disallow shift amounts with more than 5 bits.
                         * NASM has nondeterministic output, depending on the host architecture (32-bit mode or 64-bit mode).
                         */
                        if (assembler_pass > 1)  /* This also implies !has_undefined, if there is no bug. */
                            MESSAGE(1, "shift by larger than 31");
                        value2 = 0;
#if !IS_VALUE_LONG && !CONFIG_INT_SHIFT_OK_31
                    } else if (sizeof(int) == 2 && sizeof(value_t) == 2 && GET_UVALUE(value2) > 15) {
                        /* We want `db 1 << 16' to emit 0, but if the host
                         * architecture uses only the last 4 bits of the shift
                         * amount, it would emit 1. Thus we forcibly emit 0 here.
                         */
#if CONFIG_SHIFT_SIGNED
                        value1 = c ? 0 : GET_VALUE(value1) >> 15;  /* Sign-extend value1 to CONFIG_VALUE_BITS == sizeof(value_t) * 8 == 16. */
#else
                        value1 = 0;
#endif
#endif  /* !IS_VALUE_LONG && !CONFIG_INT_SHIFT_OK_31 */
                    } else {
#if CONFIG_SHIFT_SIGNED
                        value1 = c ? GET_VALUE( value1) << GET_UVALUE(value2) : GET_VALUE( value1) >> GET_UVALUE(value2);  /* Sign-extend value1 to CONFIG_VALUE_BITS. */
#else
                        value1 = c ? GET_UVALUE(value1) << GET_UVALUE(value2) : GET_UVALUE(value1) >> GET_UVALUE(value2);  /* Zero-extend value1 to CONFIG_VALUE_BITS. */
#endif
                    }
                } else {
                    break;
                }
            }
        }
        if (level <= 2) {
            while (1) {
                match_p = avoid_spaces(match_p);
                if (match_p[0] == '&') {    /* Binary AND */
                    match_p++;
                    MATCH_CASEI_LEVEL_TO_VALUE2(19, 3);
                    value1 &= value2;
                } else {
                    break;
                }
            }
        }
        if (level <= 1) {
            while (1) {
                match_p = avoid_spaces(match_p);
                if (match_p[0] == '^') {    /* Binary XOR */
                    match_p++;
                    MATCH_CASEI_LEVEL_TO_VALUE2(20, 2);
                    value1 ^= value2;
                } else {
                    break;
                }
            }
        }
        if (level == 0) {  /* Top tier. */
            while (1) {
                match_p = avoid_spaces(match_p);
                if (match_p[0] == '|') {    /* Binary OR */
                    match_p++;
                    MATCH_CASEI_LEVEL_TO_VALUE2(21, 1);
                    value1 |= value2;
                } else {
                    break;
                }
            }
        }
    }
    if (msp != match_stack) goto do_pop;
    instruction_value = has_undefined ? 0 : GET_VALUE(value1);
    return avoid_spaces(match_p);
}

/*
 ** Returns true iff p is a valid `%DEFINE' value expression string.
 **
 ** `%DEFINE' value expressions are integer literals possibly prefixed by
 ** any number of `-', `+' or `~'. The reason for that is NASM
 ** compatibility: mininasm can store only integer-valued macro values, and
 ** NASM stores the strings instead, and these restrictions check for the
 ** intersection of same behavior.
 **
 ** The implementation corresponds to match_expression(...).
 */
static char is_define_value(const char *p) {
    char c;
    for (; (c = p[0]) == '-' || c == '+' || c == '~' || isspace(c); ++p) {}
    if (c == '0' && (p[1] | 32) == 'b') {  /* Binary. */
        p += 2;
        for (; (c = p[0]) == '0' || c == '1' || c == '_'; ++p) {}
    } else if (c == '0' && (p[1] | 32) == 'x') {  /* Hexadecimal. */
      try_hex2:
        p += 2;
        for (; c = p[0], isxdigit(c); ++p) {}
    } else if (c == '0' && (p[1] | 32) == 'o') {  /* Octal. */
        p += 2;
        for (; SUB_U((unsigned char)(c = p[0]), '0') < 8U; ++p) {}
    } else if (c == '\'' || c == '"') {  /* Character constant. */
        return p[1] != '\0' && p[1] != c && p[2] == c;
    } else if (isdigit(c)) {  /* Decimal or hexadecimal. */
        for (; SUB_U((unsigned char)(c = p[0]), '0') <= 9U; ++p) {}
        if ((c | 32) == 'h' || isxdigit(c)) {
            for (; c = p[0], isxdigit(c); ++p) {}
            return (c | 32) == 'h';
        }
    } else if (c == '$' && isdigit(p[1])) {
        goto try_hex2;
    } else {
        return 0;
    }
    return c == '\0';
}

/*
 ** Match register
 */
static const char *match_register(const char *p, int width, unsigned char *reg) {
    const char *r0, *r, *r2;
    union { char a[2]; short s; } puc;  /* Avoid GCC warning: dereferencing type-punned pointer will break strict-aliasing rules [-Wstrict-aliasing] */

    p = avoid_spaces(p);
    if (!isalpha(p[0]) || !isalpha(p[1]) || islabel(p[2]))
        return NULL;
    r0 = r = GP_REGISTER_NAMES + (width & 16);  /* Works for width == 8 and width == 16. */
    if (CONFIG_CPU_UNALIGN && sizeof(short) == 2) {
        puc.s = *(short*)p & ~0x2020;
    } else {
        puc.a[0] = p[0] & ~32;
        puc.a[1] = p[1] & ~32;
    }
    for (r2 = r + 16; r != r2; r += 2) {
        if ((CONFIG_CPU_UNALIGN && sizeof(short) == 2) ? puc.s == *(short*)r : (puc.a[0] == r[0] && puc.a[1] == r[1])) {
            if (reg) *reg = (r - r0) >> 1;
            return p + 2;
        }
    }
    return NULL;
}

/* --- Recording of wide sources for -O0
 *
 * In assembler_pass == 0, add_wide_source_in_pass_1(...) for all jump
 * sources which were guessed as `jmp near', and for all effective address
 * offsets which were guessed as 16-bit, both
 *  because they had undefined labels,
 *
 * In assembler_pass > 1, these sources are used to force the jump to
 * `jmp near' and he effective address to 16-bit, thus the instruction won't
 * get optimized to a smaller size (e.g. from `jmp near' to `jmp short'),
 * which is a requirement for -O0.
 */

STRUCT_PACKED_PREFIX struct wide_instr_block {
    struct wide_instr_block MY_FAR *next;
    uvalue_t instrs[128];
} STRUCT_PACKED_SUFFIX;

static struct wide_instr_block MY_FAR *wide_instr_first_block;
static struct wide_instr_block MY_FAR *wide_instr_last_block;
static uvalue_t MY_FAR *wide_instr_add_block_end;
static uvalue_t MY_FAR *wide_instr_add_at;

static struct wide_instr_block MY_FAR *wide_instr_read_block;
static uvalue_t MY_FAR *wide_instr_read_at;

/*
 ** Must be called with strictly increasing fpos values. Thus calling it with
 ** the same fpos multiple times is not allowed.
 */
static void add_wide_instr_in_pass_1(char do_add_1) {
    /* TODO(pts): Optimize this function for size in __DOSMC__. */
    uvalue_t fpos = current_address - start_address;  /* Output file offset. Valid even before `org'. */
    struct wide_instr_block MY_FAR *new_block;
    if (do_add_1) ++fpos;
    if (0) DEBUG1("add_wide fpos=0x%x\n", (unsigned)fpos);
#if DEBUG
    if (wide_instr_add_at != NULL && wide_instr_add_at[-1] >= fpos) {
        DEBUG1("oops: added non-strictly-increasing wide instruction at fpos=0x%x\r\n", (unsigned)fpos);
        MESSAGE(1, "oops: bad wide position");
        return;
    }
#endif
    if (wide_instr_add_at == wide_instr_add_block_end) {
        if ((new_block = (struct wide_instr_block MY_FAR*)malloc_far(sizeof(struct wide_instr_block) + CONFIG_DOSMC_PACKED)) == NULL) fatal_out_of_memory();
        if (wide_instr_first_block == NULL) {
            wide_instr_first_block = new_block;
        } else {
            wide_instr_last_block->next = new_block;
        }
        wide_instr_last_block = new_block;
        wide_instr_add_at = new_block->instrs;
        wide_instr_add_block_end = new_block->instrs + sizeof(new_block->instrs) / sizeof (new_block->instrs[0]);  /* TODO(pts): For __DOSMC__, don't do the multiplication again. */
#if CONFIG_DOSMC_PACKED
        ((char MY_FAR*)new_block)[sizeof(struct wide_instr_block)] = '\0';  /* Mimic trailing NUL of a ``previous label'' for RBL_GET_LEFT(..) and RBL_GET_RIGHT(...). */
#endif
    }
    *wide_instr_add_at++ = fpos;
    if (0) DEBUG1("added preguessed wide instruction at fpos=0x%x\r\n", (unsigned)fpos);
}

/*
 ** Must be called with increasing fpos values. Thus calling it with the same
 ** fpos multiple times is OK.
 */
static char is_wide_instr_in_pass_2(char do_add_1) {
    /* TODO(pts): Optimize this function for size in __DOSMC__. */
    uvalue_t fpos = current_address - start_address;  /* Output file offset. Valid even before `org'. */
    uvalue_t MY_FAR *vp;
    char is_next_block;
    if (do_add_1) ++fpos;
    if (0) DEBUG2("guess from fpos=0x%x rp=%p\r\n", (unsigned)fpos, (void*)wide_instr_read_at);
    if (wide_instr_read_at) {
        if (fpos == *wide_instr_read_at) {  /* Called again with the same fpos as last time. */
            return 1;
        } else if (fpos <= *wide_instr_read_at) { bad_instr_order:
            DEBUG2("oops: bad instr order fpos=0x%x added=0x%x\r\n", (unsigned)fpos, wide_instr_read_at ? (unsigned)*wide_instr_read_at : 0);
            MESSAGE(1, "oops: bad instr order");
            goto return_0;
        }
        vp = wide_instr_read_at + 1;
    } else {
        if (wide_instr_first_block == NULL) goto return_0;  /* No wide instructions at all. */
        wide_instr_read_block = wide_instr_first_block;
        vp = wide_instr_read_block->instrs;
    }
    if (0) DEBUG2("guess2 from 0x%x at=%d\r\n", (unsigned)fpos, (int)(vp - wide_instr_first_block->instrs));
    if (vp == wide_instr_add_at) {  /* All wide instructions have been read. Also matches if there were none. */
        goto return_0;
    } else if (vp == wide_instr_read_block->instrs + sizeof(wide_instr_read_block->instrs) / sizeof(wide_instr_read_block->instrs[0])) {
        vp = wide_instr_read_block->next->instrs;
        is_next_block = 1;
        if (0) DEBUG0("next wide block\r\n");
    } else {
        is_next_block = 0;
    }
    if (fpos > *vp) {
        DEBUG0("oops: bad instr order2\r\n");
        goto bad_instr_order;
    } else if (fpos == *vp) {
        wide_instr_read_at = vp;
        if (is_next_block) wide_instr_read_block = wide_instr_read_block->next;
        return 1;
    } else { return_0:
        return 0;
    }
}

/* --- */

/* Table for describing a single register addition (+..) to an effective address.

        [bx+si]=0 [bx+di]=1 [bp+si]=2 [bp+di]=3   [si]=4    [di]=5    [bp]=6    [bx]=7    []=8     [bad]=9
+BX=3:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bx+si]=0 [bx+di]=1 [bad]=9   [bad]=9   [bx]=7   [bad]=9
+SP=4:  [bad]=9...
+BP=5:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bp+si]=2 [bp+di]=3 [bad]=9   [bad]=9   [bp]=6   [bad]=9
+SI=6:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bad]=9   [bad]=9   [bp+si]=2 [bx+si]=0 [si]=4   [bad]=9
+DI=7:  [bad]=9   [bad]=9   [bad]=9   [bad]=9     [bad]=9   [bad]=9   [bp+di]=3 [bx+di]=1 [di]=5   [bad]=9
*/
static UNALIGNED const unsigned char reg_add_to_addressing[5 * 5] = {
    /* +BX: */ 0, 1, 9, 9, 7,
    /* +SP: */ 9, 9, 9, 9, 9,
    /* +BP: */ 2, 3, 9, 9, 6,
    /* +DI: */ 9, 9, 2, 0, 4,
    /* +SI: */ 9, 9, 3, 1, 5,
};

/*
 ** Match addressing (r/m): can be register or effective address [...].
 ** As a side effect, it sets instruction_addressing, instruction_offset, instruction_offset_width.
 */
static const char *match_addressing(const char *p, int width) {
    unsigned char state, reg, has_any_undefined;
    const char *p2;
    char c;

    instruction_offset = 0;
    instruction_offset_width = 0;
    instruction_addressing_segment = 0;
    has_any_undefined = 0;
    p = avoid_spaces(p);
    if (*p == '[') {  /* Effective address. */
        p = avoid_spaces(p + 1);
        if (p[0] != '\0' && ((p[1] & ~32) == 'S') && ((c = p[0] & ~32) == 'S' || SUB_U(c, 'C') <= 'E' - 'C' + 0U)) {  /* Possible segment register: CS, DS, ES or SS. */
            p2 = avoid_spaces(p + 2);
            if (p2[0] == ':') {  /* Found segment register. */
                p = avoid_spaces(p2 + 1);
                instruction_addressing_segment = c == 'C' ? 0x2e : c == 'D' ? 0x3e : c == 'E' ? 0x26 : /* c == 'S' ? */ 0x36;
            }
        }
        state = 8;  /* [] so far. */
        for (;;) {
            p2 = match_register(p, 16, &reg);
            if (p2 != NULL) {
                if (reg - 3U > 7U - 3U || state < 4) return NULL;  /* Bad register combination. */
                state = reg_add_to_addressing[state - 19 + 5 * reg];
                if (state > 8) return NULL;  /* Bad register combination. */
                p = p2;
            } else {  /* Displacement. */
                if ((p = match_expression(p)) == NULL) return NULL;  /* Displacemeny syntax error. */
                instruction_offset += GET_U16(instruction_value);  /* Higher bits are ignored. */
                has_any_undefined |= has_undefined;
            }
            p = avoid_spaces(p);
            if (*p == ']') {
               ++p;
               break;
            } else if (*p == '-') {
            } else if (*p == '+') {
               ++p;  /* In case of +register. */
            } else {
              return NULL;  /* Displacement not followed by ']', '+' or '-'. */
            }
            p = avoid_spaces(p);
        }
        if (state == 8) {  /* Absolute address without register. */
            state = 0x06;
            instruction_offset_width = 2;
        } else {
            if (opt_level <= 1) {  /* With -O0, `[...+ofs]' is 8-bit offset iff there are no undefined labels in ofs and it fits to 8-bit signed in assembler_pass == 0. This is similar to NASM. */
               if (assembler_pass == 0) {
                   if (has_any_undefined) {
                       instruction_offset_width = 3;  /* Width is actually 2, but this indicates that add_wide_instr_in_pass_1(...) should be called later if this match is taken. */
                       goto set_16bit_offset;
                   }
               } else {
                   if (is_wide_instr_in_pass_2(0)) goto force_16bit_offset;
               }
            }
            instruction_offset = GET_U16(instruction_offset);
            if (instruction_offset != 0 || state == 6 /* [bp]. */) {
                if ((instruction_offset + 0x80) & 0xff00U) {
                  force_16bit_offset:
                    instruction_offset_width = 2;
                  set_16bit_offset:
                    state |= 0x80;  /* 16-bit offset. */
                } else {
                    ++instruction_offset_width;  /* = 1; */
                    state |= 0x40;  /* Signed 8-bit offset. */
                }
            }
        }
    } else {  /* Register. */
        p = match_register(p, width, &reg);
        if (p == NULL)
            return NULL;
        state = 0xc0 | reg;
    }
    instruction_addressing = state;
    return p;
}

/* Not declaring static for compatibility with C++ and forward declarations. */
extern struct bbprintf_buf emit_bbb;

static UNALIGNED char emit_buf[512];

static void emit_flush(struct bbprintf_buf *bbb) {
    const int size = emit_bbb.p - emit_buf;
    (void)bbb;  /* emit_bbb. */
    if (size) {
        if (write(output_fd, emit_buf, size) != size) {
            MESSAGE(1, "error writing to output file");
            exit(3);
        }
        emit_bbb.p = emit_buf;
    }
}

struct bbprintf_buf emit_bbb = { emit_buf, emit_buf + sizeof(emit_buf), emit_buf, 0, emit_flush };

static void emit_write(const char *s, int size) {
    int emit_free;
    while ((emit_free = emit_bbb.buf_end - emit_bbb.p) <= size) {
#if CONFIG_USE_MEMCPY_INLINE  /* A few bytes smaller than memcpy(...) for __DOSMC__. Doesn't make a difference with __WATCOMC__ Linux i386 <libc.h>.  */
        emit_bbb.p = (char*)memcpy_newdest_inline(emit_bbb.p, s, emit_free);
#else
        memcpy(emit_bbb.p, s, emit_free);
        emit_bbb.p += emit_free;
#endif
        s += emit_free; size -= emit_free;
        emit_flush(0);
    }
#if CONFIG_USE_MEMCPY_INLINE  /* A few bytes smaller than memcpy(...). */
    emit_bbb.p = (char*)memcpy_newdest_inline(emit_bbb.p, s, size);
#else
    memcpy(emit_bbb.p, s, size);
    emit_bbb.p += size;
#endif
}

static void emit_bytes(const char *s, int size)  {
    current_address += size;
    if (assembler_pass > 1) {
        emit_write(s, size);
        bytes += size;
        if (g != NULL) {
            for (; size > 0 && g != generated + sizeof(generated); *g++ = *s++, --size) {}
        }
    }
}

/*
 ** Emit one byte to output
 */
static void emit_byte_func(int byte) {  /* Changing `c' to `char' would increase the file size for __DOSMC__. */
    const char c = byte;
    emit_bytes(&c, 1);
}
#ifdef _MSC_VER  /* Without this, Microsoft C 6.00a (_MSC_VER == 600) reports: warning C4061: long/short mismatch in argument : conversion supplied */
#  define emit_byte(b) emit_byte_func((char)(b))
#else
#  define emit_byte(b) emit_byte_func(b)  /* Doing an explicit (char) conversion here would increase the file size by 25 bytes for __DOSMC__. */
#endif

/*
 ** Check for end of line
 */
static const char *check_end(const char *p) {
    p = avoid_spaces(p);
    if (*p) {
        MESSAGE(1, "extra characters at end of line");
        return NULL;
    }
    return p;
}

static char was_strict;

static const char *avoid_strict(const char *p) {
    const char *p1;
    was_strict = 0;
    p1 = p;
    if (casematch(p, "STRICT!")) {
        p = avoid_spaces(p + 6);
        if (casematch(p, "BYTE!") || casematch(p, "WORD!") || casematch(p, "SHORT!") || casematch(p, "NEAR!")) {
            was_strict = 1;
        } else {
            p = p1;
        }
    }
    return p;
}

/*
 ** Search for a match with instruction
 */
static const char *match(const char *p, const char *pattern_and_encode) {
    int c;  /* Can be as little as 16-bits. value_t is used instead where larger is needed. */
    int bit;
    int qualifier;
    const char *p0;
    const char *p1;
    const char *error_base;
    static unsigned short segment_value;  /* Static just to pacify GCC 7.5.0 warning of uninitialized. */
    char dc, dw, do_add_wide_imm8, is_imm_8bit, do_opt_lea_now;

    /* Example instructions with emitted_bytes + instructon + "pattern encode":
     *
     * 3B063412  cmp ax,[0x1234]  "r,k 3Bdrd"
     * 88063412  mov [0x1234],al  "k,r 89drd"  ; A23412
     * 89063412  mov [0x1234],ax  "k,r 89drd"  ; A33412
     * 8A063412  mov al,[0x1234]  "q,j 8Adrd"  ; A03412
     * 8B063412  mov ax,[0x1234]  "r,k 8Bdrd"  ; A13412
     */
    p0 = p;
    qualifier = 0;  /* Pacify gcc. */
    do_add_wide_imm8 = 0;
    is_imm_8bit = 0;
    do_opt_lea_now = 0;
  next_pattern:
    if (0) DEBUG1("match pattern=(%s)\n", pattern_and_encode);
    instruction_addressing_segment = 0;  /* Reset it in case something in the previous pattern didn't match after a matching match_addressing(...). */
    instruction_offset_width = 0;  /* Reset it in case something in the previous pattern didn't match after a matching match_addressing(...). */
    /* Unused pattern characters: 'z'. */
    for (error_base = pattern_and_encode; (dc = *pattern_and_encode++) != ' ';) {
        if (SUB_U(dc, 'j') <= 'o' - 'j' + 0U) {  /* Addressing: 'j': %d8, 'k': %d16 (reg/mem16), 'l': %db8, 'm': %dw16 (reg/mem16 with explicit size qualifier), 'n': effective address without a size qualifier (for lds, les), 'o' effective address without a size qualifier (for lea). */
            qualifier = 0;
            if (dc == 'n') {
              do_n_or_o:
                if (p[0] != '[') goto mismatch;
                goto do_addressing_16;  /* 8 would have been also fine. */
            } else if (dc == 'o') {
                if (do_opt_lea) do_opt_lea_now = 1;
                goto do_n_or_o;
            } else if (casematch(p, "WORD!")) {
                p += 4;
                qualifier = 16;
            } else if (casematch(p, "BYTE!")) {
                p += 4;
                qualifier = 8;
            } else if ((dc == 'l' || dc == 'm') && p[0] == '[') {  /* Disallow e.g.: dec [bx] */
                /* Example: case for `cmp [bp], word 1'. */
                if (pattern_and_encode[0] == ',' && ((dw = pattern_and_encode[1]) == 's' || dw == 't' || dw == 'u') &&
                    (p1 = match_addressing(p, 0)) != NULL &&  /* Width (0) doesn't matter, because it's not an register, but an effective address. */
                    p1[0] == ','
                   ) {
                    p1 = avoid_strict(avoid_spaces(p1 + 1));
                    if (!((dc == 'l' && casematch(p1, "BYTE!")) || (dc == 'm' && casematch(p1, "WORD!")))) goto mismatch;
                } else {
                    goto mismatch;
                }
            }
            if (dc == 'j' || dc == 'l') {
                /* NASM allows with a warning, but we don't for dc == 'l': dec word bh */
                if (qualifier == 16) goto mismatch;
                /* It sets instruction_addressing, instruction_offset, instruction_offset_width. */
                p = match_addressing(p, 8);
            } else /* if (dc == 'k' || dc == 'm') */ {
                /* NASM allows with a warning, but we don't for dc == 'm': dec byte bx */
                if (qualifier == 8) goto mismatch;
              do_addressing_16:
                /* It sets instruction_addressing, instruction_offset, instruction_offset_width. */
                p = match_addressing(p, 16);
            }
        } else if (dc == 'q') {  /* Register, 8-bit. */
            /* NASM allows with a warning, but we don't for dc == 'l': dec word bh */
            if (casematch(p, "BYTE!")) p += 4;
            p = match_register(p, 0, &instruction_register);  /* 0: anything without the 16 bit set. */
        } else if (dc == 'r') {  /* Register, 16-bit. */
            /* NASM allows with a warning, but we don't for dc == 'm': dec byte bx */
            qualifier = 0;
          do_reg16:
            if (casematch(p, "WORD!")) p += 4;
            p = match_register(p, 16, &instruction_register);
            if (qualifier) instruction_addressing = 0xc0 | instruction_register;
        } else if (dc == 'p') {  /* Register, 16-bit, but also save it to instruction_addressing. Used in 2-argument `imul'. */
            qualifier = 1;
            goto do_reg16;
        } else if (dc == 'e') {  /* 8-bit immediate, saved to instruction_offset. Used in the first argument of `enter'.   */
            p = avoid_strict(p);
            if (casematch(p, "WORD!")) p += 4;
            p = match_expression(p);
            instruction_offset = instruction_value;
        } else if (dc == 'h') {  /* 8-bit immediate. */
            p = avoid_strict(p);
            if (casematch(p, "BYTE!")) p += 4;
            p = match_expression(p);
        } else if (dc == 'i') {  /* 16-bit immediate. */
            p = avoid_strict(p);
            if (casematch(p, "WORD!")) p += 4;
            p = match_expression(p);
        } else if (dc == 'g') {  /* 16-bit immediate, but don't match if immediate fits to signed 8-bit. Useful for -O1 and above. Used in arithmetic pattern "AX,g" (and not other registers). */
            p = avoid_strict(p);
            qualifier = 0;
            if (casematch(p, "WORD!")) {
                p += 4;
                qualifier = 1;
            }
            p = match_expression(p);
            /* The next pattern (of the same byte size, but with 16-bit immediate) will match. For NASM compatibility.
             *
             * Here we don't have to special-case forward references (assembler_pass == 0 && has_undefined), because they will eventually be resolved with opt_level >= 1.
             *
             * Specifying !do_opt_int below (`-O1' and `-OI') is just a cosmetic improvement: the output size remains the same. It also deviates from `-O9'.
             */
            if (p != NULL && (qualifier == 0 || !was_strict) && opt_level > 1 && !do_opt_int &&
                GET_UVALUE(instruction_value) + 0x80U <= 0xffU  /* It matches NASM 0.98.39 with -O9. It matches `cmp ax, -4', but it doesn't match 0xfffc. This is a harmless quirk (not affecting the output size) of NASM 0.98.39, but not NASM 2.13.02. */
                /*!((GET_UVALUE(instruction_value) + 0x80U) & ~(uvalue_t)0xffU)*/   /* It matches NASM 0.98.39 with -O9. Same result as above, but 4 bytes longer for __DOSMC__. */
                /*!(((unsigned)instruction_value + 0x80U) & 0xff00U)*/  /* It matches NASM 2.13.02 with -O9. It matches both `0xffffc' and `-4'. */
               ) goto mismatch;
        } else if (dc == 'a' || dc == 'c') {  /* Address for jump, 8-bit. 'c' is jmp, 'a' is everything else (e.g. jc, jcxz, loop) for which short is the only allowed qualifier. */
            p = avoid_strict(p);  /* STRICT doesn't matter for jumps, qualifiers are respected without it. */
            qualifier = 0;
            if (casematch(p, "NEAR!") || casematch(p, "WORD!")) goto mismatch;
            if (casematch(p, "SHORT!")) {
                p += 5;
                qualifier = 1;
            }
            p = match_expression(p);
            if (p != NULL) {
                if (qualifier == 0 && opt_level <= 1 && dc == 'c') {  /* With -O0, `jmp' is `jmp short' iff it fits to 8-bit signed in assembler_pass == 0. This is similar to NASM. */
                    if (assembler_pass == 0) {
                        if (has_undefined) {
                            do_add_wide_imm8 = 1;
                            goto mismatch;
                        }
                    } else {
                        if (is_wide_instr_in_pass_2(1)) goto mismatch;
                    }
                }
                if (has_undefined) instruction_value = current_address;  /* Hide the extra "short jump too long" error. */
                instruction_value -= current_address + 2;
                if (qualifier == 0 && dc == 'c') {
                    is_address_used = 1;
                    /* Jump is longer than 8-bit signed relative jump. Do a mismatch here, so that the next pattern will generate a near jump. */
                    if (((uvalue_t)instruction_value + 0x80) & ~0xffU) goto mismatch;
                }
            }
        } else if (dc == 'b') {  /* Address for jump, 16-bit. */
            p = avoid_strict(p);  /* STRICT doesn't matter for jumps, qualifiers are respected without it. */
            if (casematch(p, "SHORT!")) goto mismatch;
            if (casematch(p, "NEAR!") || casematch(p, "WORD!")) p += 4;
            p = match_expression(p);
            instruction_value -= current_address + 3;
        } else if (dc == 's') {  /* Signed immediate, 16-bit or 8-bit. Used in the pattern "m,s" (m is a 16-bit register or 16-bit effective address) and push imm pattern "xs" and `imul' with imm pattern "xr,k,s". */
            p = avoid_strict(p);
            qualifier = 0;
            if (casematch(p, "BYTE!")) {
                p += 4;
                qualifier = 1;
            } else if (casematch(p, "WORD!")) {
                p += 4;
                qualifier = 2;
            }
            p = match_expression(p);
            if (p == NULL) {
            } else if (qualifier != 0) {
                if (opt_level > 1 && !was_strict && qualifier != 1) goto detect_si8_size;  /* For -O9, ignore `word', but respect `strict word'. */
                if (qualifier == 1) is_imm_8bit = 1;
                if (opt_level == 0) goto do_nasm_o0_immediate_compat;
            } else if (opt_level == 0) {
                if (pattern_and_encode[-2] == ',') {  /* "m,s" rathern than "xs" (`push'). */
              do_nasm_o0_immediate_compat:
                /* With -O0, match NASM 0.98.39 (but not later NASM)
                 * behavior: if there are undefined labels in the immediate,
                 * then don't optimize the effective address.
                 *
                 * The opposite direction (with -O0, if there are undefined
                 * labels in the effective address, then don't optimize the
                 * immediate) is implemented by never optimizing the
                 * immediate with -O0.
                 */
                if ((unsigned char)instruction_addressing < 0xc0) {  /* Effective address (not register). */
                    if (assembler_pass == 0) {
                        if (has_undefined) {
                            do_add_wide_imm8 = 1;
                        }
                    } else {
                        if (is_wide_instr_in_pass_2(1)) has_undefined = 1;
                    }
                    if (has_undefined) {  /* Missed optimization opportunity in NASM 0.98.39 and 0.99.06, mininasm does the same with -O0, but mininasm optimizes it with -O1. */
                        /* We assume that the pattern is "m,s" or "m,u". */
                        if (instruction_offset_width == 0) {
                            instruction_addressing |= 0x80;
                            instruction_offset_width = 2;
                        } else if (instruction_offset_width == 1) {
                            instruction_addressing ^= 0xc0;
                            ++instruction_offset_width;
                        }
                    }
                }
                }
            } else if (opt_level == 1) {
                if (assembler_pass == 0) {
                    if (!has_undefined) goto detect_si8_size;
                    do_add_wide_imm8 = 1;
                } else {
                    if (!is_wide_instr_in_pass_2(1)) goto detect_si8_size;
                }
            } else {
              detect_si8_size:
                /* 16-bit integer cannot be represented as signed 8-bit, so don't use this encoding. Doesn't happen for has_undefined. */
                is_imm_8bit = !(/* !has_undefined && */
                    !do_opt_int && pattern_and_encode[-2] != ',' ?  GET_UVALUE(instruction_value) + 0x80U > 0xffU :  /* It matches NASM 0.98.39 with -O9. It matches `push -4', but it doesn't match 0xfffc. This is a quirk of NASM 0.98.39 making the output file longer. */
                    (((unsigned)instruction_value + 0x80) & 0xff00U));
            }
        } else if (dc == 't') {  /* 8-bit immediate, with the NASM -O0 compatibility. Used with pattern "l,t", corresponding to an 8-bit addressing. */
            p = avoid_strict(p);
            if (casematch(p, "BYTE!")) p += 4;
            p = match_expression(p);
          force_imm_8bit:
            is_imm_8bit = 1;
            if (p != NULL && opt_level == 0) goto do_nasm_o0_immediate_compat;
        } else if (dc == 'u') {  /* 16-bit immediate, with the NASM -O0 compatibility. Used with pattern "m.u". */
            p = avoid_strict(p);
            if (casematch(p, "WORD!")) p += 4;
            p = match_expression(p);
            if (p != NULL && opt_level == 0) goto do_nasm_o0_immediate_compat;
        } else if (dc == 'v') {  /* Optionally the token BYTE. */
            p = avoid_strict(p);
            if (casematch(p, "BYTE!")) p = avoid_spaces(p + 4);
        } else if (dc == 'w') {  /* Optionally the token WORD. */
            p = avoid_strict(p);
            if (casematch(p, "WORD!")) p = avoid_spaces(p + 4);
        } else if (dc == 'f') {  /* FAR pointer. */
            p = avoid_strict(p);
            if (casematch(p, "SHORT!") || casematch(p, "NEAR!") || casematch(p, "WORD!")) goto mismatch;
            p = match_expression(p);
            if (p == NULL)
                goto mismatch;
            segment_value = instruction_value;
            if (*p != ':')
                goto mismatch;
            p = match_expression(p + 1);
        } else if (dc == '1') {  /* 8-bit immediate, shift amount (e.g. `shl' and `shr'), must be 1 on 8086. */
            p = avoid_strict(p);
            if (casematch(p, "BYTE!")) p += 4;
            p = match_expression(p);
            if (p == NULL) goto mismatch;
            if (opt_level <= 1) {
                if (assembler_pass == 0) {
                    if (has_undefined) {
                        if (cpu_level == 0) goto mismatch;
                        do_add_wide_imm8 = 1;
                        goto force_imm_8bit_1;
                    }
                } else {
                    if (is_wide_instr_in_pass_2(1)) goto force_imm_8bit_1;
                }
            } 
            if (!has_undefined && instruction_value != 1) {
              force_imm_8bit_1:
                if (cpu_level == 0 && assembler_pass > 1) goto mismatch;
                goto force_imm_8bit;
            }
        } else if (dc == 'x') {  /* Minimum `cpu 186' is needed. */
            if (cpu_level == 0) goto mismatch;
        } else if (dc == 'y') {  /* Minimum `cpu 286' is needed. */
            if (cpu_level < 2) goto mismatch;
        } else if (dc == '!') {
            if (islabel(*p)) goto mismatch;
            continue;
        } else if (dc == '.') {
            p = avoid_spaces(p);
            if (*p == ',') goto mismatch;  /* Another pattern with ',' will match. Used in `imul'. */
        } else if (SUB_U(dc, 'a') <= 'z' - 'a' + 0U) {  /* Unexpected special (lowercase) character in pattern. */
            goto decode_internal_error;
        } else if (dc == ',') {
            p = avoid_spaces(p);
            if (*p != ',') goto mismatch;
            p = avoid_spaces(p + 1);
            continue;
        } else {
            if ((SUB_U(dc, 'A') <= 'Z' - 'A' + 0U ? *p & ~32 : *p) != dc) goto mismatch;  /* Case insensitive match for uppercase letters in pattern. */
            p++;
            continue;
        }
        if (p == NULL) goto mismatch;
    }
    goto do_encode;
  mismatch:
    while ((dc = *pattern_and_encode++) != '\0' && dc != '-' /* ALSO */) {}
    if (dc == '\0') return NULL;
    p = p0;
    goto next_pattern;

  do_encode:
    /*
     ** Instruction properly matched, now generate binary
     */
    if (instruction_offset_width == 3) {
        add_wide_instr_in_pass_1(0);  /* Call it only once per encode. Calling it once per match would add extra values in case of mismatch. */
    }
    if (do_add_wide_imm8) {
        add_wide_instr_in_pass_1(1);  /* Call it only once per encode. Calling it once per match would add extra values in case of mismatch. 1 so that it doesn't conflict with the wideness of instruction_offset. */
    }
    if (do_opt_lea_now) {
        instruction_addressing_segment = 0;  /* Ignore the segment part of the effective address, it doesn't make a difference for `lea'. */
        if (0) DEBUG2("lea ia=0x%02x iow=%d\r\n", instruction_addressing, instruction_offset_width);
        if (instruction_addressing == 0x06 /* [immediate] */) {
            emit_byte(0xb8 | instruction_register);
            pattern_and_encode = "j";
#if 1  /* Convert e.g. `lea cx, [ex]' to `mov cx, bx', of the same size. */
        } else if (instruction_addressing == 0x04 /* [SI] */) {
            c = 0xc0 | 6 << 3;
            goto emit_lea_mov;
        } else if (instruction_addressing == 0x05 /* [DI] */) {
            c = 0xc0 | 7 << 3;
            goto emit_lea_mov;
        } else if (instruction_addressing == 0x07 /* [BX] */) {
            c = 0xc0 | 3 << 3;
            goto emit_lea_mov;
#endif
        } else if (instruction_addressing == 0x46 && instruction_offset == 0 && instruction_offset_width == 1 /* [BP] */) {
            c = 0xc0 | 5 << 3;
          emit_lea_mov:
            emit_byte(0x89);
            emit_byte(c | instruction_register);
            goto done;
        }
    }
    if (instruction_addressing_segment) {
        if (do_opt_segreg) {
            if ((unsigned char)instruction_addressing >= 0xc0) goto omit_segreg;  /* If there is a register (rather than effective address) in the addressing. */
            c = instruction_addressing;
            if (c == 0x06 /* [immesiate] */) {
                c = 0x3e /* DS */;
            } else {
                c &= 7;
                c = (c == 0x02 || c == 0x03 || c == 0x06) ? 0x36 /* SS */ : 0x3e /* DS */;  /* If it contains BP, then it's [SS:...] by default, otherwise [DS:...]. */
            }
            if ((unsigned char)instruction_addressing_segment == (unsigned char)c) goto omit_segreg;  /* If the default segment register is used. */
        }
        emit_byte(instruction_addressing_segment);
      omit_segreg: ;
    }
    for (error_base = pattern_and_encode; (dc = *pattern_and_encode++) != '\0' && dc != '-' /* ALSO */;) {
        dw = 0;
        if (dc == '+') {  /* Instruction is a prefix. */
            return p;  /* Don't call check_end(p). */
        } else if ((unsigned char)dc <= 'F' + 0U) {  /* Byte: uppercase hex. */
            c = dc - '0';
            if (c > 9) c -= 7;
            dc = *pattern_and_encode++ - '0';
            if (dc > 9) dc -= 7;
            c = (c << 4) | dc;
            if ((unsigned char)(c - 0x88) <= (unsigned char)(0x8b - 0x88) && pattern_and_encode == error_base + 2 && instruction_addressing == 6 && instruction_register == 0) {
                /* Optimization:
                 *
                 * 88063412  mov [0x1234],al  "k,r 89drd"  --> A23412
                 * 89063412  mov [0x1234],ax  "k,r 89drd"  --> A33412
                 * 8A063412  mov al,[0x1234]  "q,j 8Adrd"  --> A03412
                 * 8B063412  mov ax,[0x1234]  "r,k 8Bdrd"  --> A13412
                 */
                pattern_and_encode = "";
                dw = 2;
                c += 0xa0 - 0x88;
                c ^= 2;
            } else if ((unsigned char)(c - 0x70) <= 0xfU && qualifier == 0 && (((uvalue_t)instruction_value + 0x80) & ~0xffU) && !has_undefined
                      ) {  /* Generate 5-byte `near' version of 8-bit relative conditional jump with an inverse. */
                emit_byte(c ^ 1);  /* Conditional jump with negated condition. */
                emit_byte(3);  /* Skip next 3 bytes if negated condition is true. */
                c = 0xe9;  /* `jmp near', 2 bytes will follow for encode "b". */
                pattern_and_encode = "b";
                instruction_value -= 3;  /* Jump source address (0xe9) is 3 bytes larger than previously anticipated. */
            }
        } else if (dc == 'i') {  /* 8-bit immediate. */
            c = instruction_value;
        } else if (dc == 'k') {  /* 8-bit immediate, but only if is_imm_8bit. */
            if (!is_imm_8bit) continue;
            c = instruction_value;
        } else if (dc == 'j') {  /* 16-bit immediate, maybe optimized to 8 bits. */
            c = instruction_value;
            if (!is_imm_8bit) {
                instruction_offset = instruction_value >> 8;
                dw = 1;  /* TODO(pts): Optimize this and below as ++dw. */
            }
        } else if (dc == 's') {
            c = is_imm_8bit ? (char)0x83 : (char)0x81;
        } else if (dc == 'g') {  /* Used in byte shifts with immediate. */
            c = is_imm_8bit ? (char)0xc0 : (char)0xd0;
        } else if (dc == 'h') {  /* Used in words shifts with immediate. */
            c = is_imm_8bit ? (char)0xc1 : (char)0xd1;
        } else if (dc == 'l') {  /* Used in `push imm'. */
            c = is_imm_8bit ? (char)0x6a : (char)0x68;
        } else if (dc == 'm') {  /* Used in 3rd, immediate argument for 3-argument `imul'. */
            c = is_imm_8bit ? (char)0x6b : (char)0x69;
        } else if (dc == 'a') {  /* Address for jump, 8-bit. */
            is_address_used = 1;
            if (assembler_pass > 1 && (((uvalue_t)instruction_value + 0x80) & ~0xffU))
                MESSAGE(1, "short jump too long");
            c = instruction_value;
        } else if (dc == 'b') {  /* Address for jump, 16-bit. */
            is_address_used = 1;
            /*if (assembler_pass > 1 && (((uvalue_t)instruction_value + 0x8000U) & ~0xffffU)) {}*/  /* This check is too strict, e.g. from offset 3 it's possible to jump to 0xffff, but this one reports an error, because of the >= 32 KiB difference. */
            if (assembler_pass > 1 && (((uvalue_t)instruction_value + (uvalue_t)0x10000UL) & (uvalue_t)~0x1ffffUL)) {  /* This check is a bit lenient. */
                MESSAGE(1, "near jump too long");
            }
            c = instruction_value;
            instruction_offset = c >> 8;
            dw = 1;
        } else if (dc == 'f') {  /* Far (16+16 bit) jump or call. */
            emit_byte(instruction_value);
            c = instruction_value >> 8;
            instruction_offset = segment_value;
            dw = 2;
        } else if (dc == 'e') {  /* 16-bit instruction_offset, for `enter'. */
            emit_byte(instruction_offset);
            c = instruction_offset >> 8;
        } else {  /* Binary. */
            c = 0;
            --pattern_and_encode;
            for (bit = 0; bit < 8;) {
                dc = *pattern_and_encode++;
                if (dc == 'z') {  /* Zero. */
                    bit++;
                } else if (dc == 'o') {  /* One. */
                    c |= 0x80 >> bit;
                    bit++;
                } else if (dc == 'r') {  /* Register field. */
                    c |= instruction_register << (5 - bit);
                    bit += 3;
                } else if (dc == 'd') {  /* Addressing field. */
                    if (bit == 0) {
                        c |= instruction_addressing & 0xc0;
                        bit += 2;
                    } else {
                        c |= instruction_addressing & 0x07;
                        bit += 3;
                        dw = instruction_offset_width;  /* 1, 2 or 3. 3 means 2 for dw. */
                    }
                } else { decode_internal_error:  /* assert(...). */
                    MESSAGE1STR(1, "ooops: decode (%s)", error_base);
                    exit(2);
                    break;
                }
            }
        }
        emit_byte(c);
        if (dw != 0) {
            emit_byte(instruction_offset);
            if (dw > 1) emit_byte(instruction_offset >> 8);
        }
    }
  done:
    return check_end(p);
}

/*
 ** Separate a portion of entry up to the first space.
 ** First word gets copied to `instr_name' (silently truncated if needed),
 ** and `p' is advanced after it, and the new p is returned.
 */
static const char *separate(const char *p) {
    char *p2;
    char *instr_name_end = instr_name + sizeof(instr_name) - 1;

    for (; *p == ' '; ++p) {}
    p2 = instr_name;
    for (;;) {
        if (p2 == instr_name_end) {
            for (; *p && *p != ' '; ++p) {}  /* Silently truncate instr_name. */
            break;
        } else if (*p && *p != ' ') {
            *p2++ = *p++;
        } else {
            break;
        }
    }
    *p2 = '\0';
    for (; *p == ' '; ++p) {}
    return p;
}

static UNALIGNED char message_buf[512];

static void message_flush(struct bbprintf_buf *bbb) {
    const int size = message_bbb.p - message_buf;
    (void)bbb;  /* message_bbb. */
    if (size) {
        if (message_bbb.data) (void)!write(2 /* stderr */, message_buf, size);
        message_bbb.p = message_buf;
        if (listing_fd >= 0) {
            if (write(listing_fd, message_buf, size) != size) {
                listing_fd = -1;
                MESSAGE(1, "error writing to listing file");
                exit(3);
            }
        }
    }
}

/* data = 0 means write to listing_fd only, = 1 means write to stderr + listing_fd. */
struct bbprintf_buf message_bbb = { message_buf, message_buf + sizeof(message_buf), message_buf, 0, message_flush };

static const char *filename_for_message;

/*
 ** Generate a message
 */
#if CONFIG_SUPPORT_WARNINGS
static void message_start(int error)
#else
static void message_start(void)
#endif
{
    const char *msg_prefix;
    if (!message_bbb.data) {
        message_flush(NULL);  /* Flush listing_fd. */
        message_bbb.data = (void*)1;
    }
#if CONFIG_SUPPORT_WARNINGS
    if (error) {
#endif
        msg_prefix = "error: ";
        if (GET_UVALUE(++errors) == 0) --errors;  /* Cappped at max uvalue_t. */
#if CONFIG_SUPPORT_WARNINGS
    } else {
        msg_prefix = "warning: ";
        if (GET_UVALUE(++warnings) == 0) --warnings;  /* Cappped at max uvalue_t. */
    }
#endif
    if (line_number) {
        bbprintf(&message_bbb, "%s:%u: %s", filename_for_message, (unsigned)line_number, msg_prefix);
    } else {
        bbprintf(&message_bbb, msg_prefix);  /* "%s" not needed, no `%' patterns in msg_prefix. */
    }
}

static void message_end(void) {
    /* We must use \r\n, because this will end up on stderr, and on DOS
     * with O_BINARY, just a \n doesn't break the line properly.
     */
    bbprintf(&message_bbb, "\r\n");
    message_flush(NULL);
    message_bbb.data = (void*)0;  /* Write subsequent bytes to listing_fd only (no stderr). */
}

#if CONFIG_SUPPORT_WARNINGS
static void message(int error, const char *message)
#else
static void message(const char *message)
#endif
{
    MESSAGE_START(error);
    bbprintf(&message_bbb, "%s", message);
    message_end();
}

/*
 ** Shortcut to make the executable program smaller for __DOSMC__.
 */
#if CONFIG_SUPPORT_WARNINGS
static void message1str(int error, const char *pattern, const char *data)
#else
static void message1str(const char *pattern, const char *data)
#endif
{
    MESSAGE_START(error);
    bbprintf(&message_bbb, pattern, data);
    message_end();
}

/*
 ** Process an instruction `p' (starting with mnemonic name).
 */
static void process_instruction(const char *p) {
    const char *p2 = NULL, *p3;
    char c;

    p = separate(p);
    if (casematch(instr_name, "DB")) {  /* Define 8-bit byte. */
        while (1) {
            p = avoid_spaces(p);
            if (*p == '\'' || *p == '"') {    /* ASCII text, quoted. */
                c = *p++;
                for (p2 = p; *p2 != '\0' && *p2 != c; ++p2) {}
                p3 = p2;
                if (*p3 == '\0') {
                    MESSAGE(1, "Missing close quote");
                } else {
                    p3 = avoid_spaces(p3 + 1);
                    if (*p3 != ',' && *p3 != '\0') { --p; goto db_expr; }
                    emit_bytes(p, p2 - p);
                }
                p = p3;
            } else { db_expr:
                p = match_expression(p);
                if (p == NULL) {
                    MESSAGE(1, "Bad expression");
                    break;
                }
                emit_byte(instruction_value);
            }
            if (*p == ',') {
                p++;
                p = avoid_spaces(p);
                if (*p == '\0') break;
            } else {
                check_end(p);
                break;
            }
        }
        return;
    } else if ((c = casematch(instr_name, "DW")) != 0 /* Define 16-bit word. */
#if CONFIG_VALUE_BITS == 32
               || casematch(instr_name, "DD")  /* Define 32-bit quadword. */
              ) {
#endif
        while (1) {
            p = match_expression(p);
            if (p == NULL) {
                MESSAGE(1, "Bad expression");
                break;
            }
            emit_byte(instruction_value);
            emit_byte(instruction_value >> 8);
#if CONFIG_VALUE_BITS == 32
            if (!c) {
                emit_byte(instruction_value >> 16);
                emit_byte(instruction_value >> 24);
            }
#endif
            if (*p == ',') {
                p++;
                p = avoid_spaces(p);
                if (*p == '\0') break;
                continue;
            }
            check_end(p);
            break;
        }
        return;
    }
    while (instr_name[0]) {   /* Match against instruction set. */
        p2 = instruction_set;
        for (;;) {
            if (*p2 == '\0') {
#if CONFIG_SPLIT_INSTRUCTION_SET
                if (p2 == instruction_set_nul) {
                    p2 = instruction_set2;
                    continue;
                }
#endif
                MESSAGE1STR(1, "Unknown instruction '%s'", instr_name);
                goto after_matches;
            }
            p3 = p2;
            while (*p2++ != '\0') {}  /* Skip over instruction name. */
            if (casematch(instr_name, p3)) break;  /* Match actual instruction mnemonic name (instr_name) against candidate from instruction_set (p2). */
            while (*p2++ != '\0') {}  /* Skip over pattern_and_encode. */
        }
        p3 = p;
        p = match(p, p2);
        if (p == NULL) {
            MESSAGE_START(1);
            bbprintf(&message_bbb, "Error in instruction '%s %s'", instr_name, p3);
            message_end();
            break;
        }
        p = separate(p);
    }
  after_matches: ;
}

/*
 ** Reset current address.
 ** Called anytime the assembler needs to generate code.
 */
static void reset_address(void) {
    current_address = start_address = default_start_address;
}

/*
 ** Creates label named `global_label' with value `instruction_value'.
 */
static void create_label(void) {
    struct label MY_FAR *last_label = find_label(global_label);
    if (assembler_pass <= 1) {
        if (last_label == NULL) {
            last_label = define_label(global_label, instruction_value);
        } else if (RBL_IS_DELETED(last_label)) {  /* This is possible if it is an %UNDEF-ined macro. */
          do_undelete:
            RBL_SET_DELETED_0(last_label);
            last_label->value = instruction_value;
        } else {
            MESSAGE1STR(1, "Redefined label '%s'", global_label);
        }
    } else {
        if (last_label == NULL) {
            MESSAGE1STR(1, "oops: label '%s' not found", global_label);
        } else if (RBL_IS_DELETED(last_label)) {  /* This is possible if it is an %undef-ined macro. */
            goto do_undelete;
        } else {
            if (last_label->value != instruction_value) {
#if DEBUG
                /* if (0 && DEBUG && opt_level <= 1) { MESSAGE_START(1); bbprintf(&message_bbb, "oops: label '%s' changed value from 0x%x to 0x%x", last_label->name, (unsigned)last_label->value, (unsigned)instruction_value); message_end(); } */
                if (opt_level <= 1) DEBUG3("oops: label '%s' changed value from 0x%x to 0x%x\r\n", last_label->name, (unsigned)last_label->value, (unsigned)instruction_value);
#endif
                have_labels_changed = 1;
            }
            last_label->value = instruction_value;
        }
    }
}

static UNALIGNED char line_buf[512];
typedef char assert_line_buf_size[sizeof(line_buf) >= 2 * MAX_SIZE];  /* To avoid too much copy per line in do_assembly(...). */

#if !CONFIG_CPU_UNALIGN
struct guess_align_assembly_info_helper { off_t o; char c; };
typedef char guess_align_assembly_info[sizeof(struct guess_align_assembly_info_helper) - sizeof(off_t)];
#endif

struct assembly_info {
    off_t file_offset;  /* Largest alignment first, to save size. */
    uvalue_t level;  /* !! TODO(pts): Is using (forcing) 16 bits only make the code smaller for dosmc? */
    uvalue_t avoid_level;
    uvalue_t line_number;
    char zero;  /* '\0'. Used by assembly_pop(...). */
    char input_filename[1];  /* Longer, ASCIIZ (NUL-terminated). */
};

/* A stack of files being assembled. The one at the beginning was specified
 * in the command line, others were %include()d in order.
 *
 * Supports %INCLUDE depth of more than 21 on DOS with 8.3 filenames (no pathname).
 */
#if CONFIG_CPU_UNALIGN
static UNALIGNED char assembly_stack[512];
#else
static struct assembly_info assembly_stack[(512 + sizeof(struct assembly_info) - 1) / sizeof(struct assembly_info)];
#endif
static struct assembly_info *assembly_p;  /* = (struct assembly_info*)assembly_stack; */

static struct assembly_info *assembly_push(const char *input_filename) {
    const int input_filename_len = strlen(input_filename);
#if !CONFIG_CPU_UNALIGN
    int extra_nul_count = (sizeof(guess_align_assembly_info) - ((unsigned)(size_t)&((struct assembly_info*)0)->input_filename + input_filename_len + 1) % sizeof(guess_align_assembly_info)) % sizeof(guess_align_assembly_info);
#endif
    struct assembly_info *aip;
    if ((size_t)(((char*)&assembly_p->input_filename + input_filename_len) - (char*)assembly_stack) >= sizeof(assembly_stack)) return NULL;  /* Out of assembly_stack memory. */
    /* TODO(pts): In dosmc, can we generate better assembly code for this initialization? The `mov bx, [assembly_p]' instruction is repeated too much. */
    assembly_p->level = 1;
    assembly_p->line_number = 0;
    assembly_p->avoid_level = 0;
    assembly_p->file_offset = 0;
    assembly_p->zero = 0;
    /* strcpy(...) would also work (there are no far pointers here), but we can save a few bytes if we avoid linking strcpy(...), for __DOSMC__. */
    strcpy_far(assembly_p->input_filename, input_filename);
    aip = assembly_p;
    assembly_p = (struct assembly_info*)((char*)&assembly_p->input_filename + 1 + input_filename_len);
#if !CONFIG_CPU_UNALIGN
    for (; extra_nul_count > 0; --extra_nul_count, *(char*)assembly_p = '\0', assembly_p = (struct assembly_info*)((char*)(assembly_p) + 1)) {}
#endif
    return aip;
}

static struct assembly_info *assembly_pop(struct assembly_info *aip) {
    char *p;
    if (aip == (struct assembly_info*)assembly_stack) return NULL;
    assembly_p = aip;
    p = (char*)aip;
    if (*--p != '\0') {
#if DEBUG
        MESSAGE(1, "oops: pop from empty %include stack\n");
#endif
    } else {
#if CONFIG_CPU_UNALIGN
        --p;
#else
        for (; *p == '\0'; --p) {}
#endif
        for (; *p != '\0'; --p) {}  /* Find ->zero with value '\0', preceding ->input_filename. */
        aip = (struct assembly_info*)(p - (int)(size_t)&((struct assembly_info*)0)->zero);
    }
    return aip;
}

#define MACRO_CMDLINE 1  /* Macro defined in the command-line with an INTVALUE. */
#define MACRO_SELF 2  /* Macro defined in the assembly source as `%DEFINE NAME NAME', so itself. */
#define MACRO_VALUE 3  /* Macro defined in the assembly source as `%DEFINE NAME INTVALUE' or `%assign NAME EXPR'. */

static char has_macros;
static char do_special_pass_1;

static void reset_macros(void) {
    struct label MY_FAR *node = label_list;
    struct label MY_FAR *pre;
    struct label MY_FAR *pre_right;
    char value;
    struct label MY_FAR *value_label;
    if (!has_macros && do_special_pass_1 != 1) return;
    /* Morris inorder traversal of binary tree: iterative (non-recursive,
     * so it uses O(1) stack), modifies the tree pointers temporarily, but
     * then restores them, runs in O(n) time.
     */
    while (!RBL_IS_NULL(node)) {
        if (RBL_IS_LEFT_NULL(node)) goto do_work;
        for (pre = RBL_GET_LEFT(node); pre_right = RBL_GET_RIGHT(pre), !RBL_IS_NULL(pre_right) && pre_right != node; pre = pre_right) {}
        if (RBL_IS_NULL(pre_right)) {
            RBL_SET_RIGHT(pre, node);
            node = RBL_GET_LEFT(node);
        } else {
            RBL_SET_RIGHT(pre, NULL);
          do_work:  /* Do for each node. */
            if (node->name[0] == '%') {
                value = node->value;  /* Also make it shorter (char). */
                if (value != MACRO_CMDLINE) {
                    RBL_SET_DELETED_1(node);
                    /* Delete the label corresponding to the macro defined with an INTVALUE. */
                    if (value == MACRO_VALUE && do_special_pass_1 != 1) {
                        if ((value_label = find_label(node->name + 1)) != NULL) RBL_SET_DELETED_1(value_label);
                    }
                }
            } else if (do_special_pass_1 == 1) {  /* Delete all non-macro labels. */
                RBL_SET_DELETED_1(node);
            }
            node = RBL_GET_RIGHT(node);
        }
    }
}

/*
 ** name1 points to 1 byte before `NAME'.
 ** It's OK if the macro is not defined.
 */
static void unset_macro(char *name1) {
    char c;
    const char name1c = *name1;
    const char *p3;
    struct label MY_FAR *label;
    if (!(isalpha(name1[1]) || name1[1] == '_') || (p3 = match_label_prefix(name1 + 1)) == NULL || *p3 != '\0') {
         MESSAGE(1, "bad macro name");
         return;
    }
    *name1 = '%';
    label = find_label(name1);
    *name1 = name1c;
    if (label == NULL || RBL_IS_DELETED(label)) return;  /* No such macro, unset is a noop. */
    c = label->value;  /* Make it shorter for future comparisons. */
    if (c == MACRO_CMDLINE) {
        MESSAGE(1, "invalid macro override");
        return;
    }
    RBL_SET_DELETED_1(label);
    if (c == MACRO_VALUE) {  /* Also delete the corresponding label. */
        if ((label = find_label(name1 + 1)) != NULL) RBL_SET_DELETED_1(label);
    }
}

#define MACRO_SET_DEFINE_CMDLINE MACRO_CMDLINE
#define MACRO_SET_DEFINE MACRO_VALUE
#define MACRO_SET_ASSIGN (MACRO_VALUE | 0x10)

/*
 ** name1 points to 1 byte before `NAME', name_end points to the end of
 ** name. Both *name1 and *name_end can be changed temporarily.
 */
static void set_macro(char *name1, char *name_end, const char *value, char macro_set_mode) {
    const char name1c = *name1;
    const char name_endc = *name_end;
    const char *p3;
    struct label MY_FAR *label;
    struct label MY_FAR *macro_label;

    value = avoid_spaces(value);  /* Before we change *name_end, in case name_end == value. */
    *name_end = '\0';
    if (!(isalpha(name1[1]) || name1[1] == '_') || (p3 = match_label_prefix(name1 + 1)) != name_end) {
         MESSAGE(1, "bad macro name");
         goto do_return;
    }
    *name1 = '%';  /* Macro NAME prefixed by '%'. */
    macro_label = find_label(name1);
    if (0) DEBUG3("set_macro mode 0x%x strcmp (%s) (%s)\n", macro_set_mode, name1 + 1, value);
    /* strcmp(...) would also work (there are no far pointers here), but we can save a few bytes if we avoid linking strcmp(...), for __DOSMC__. */
    if (macro_set_mode == MACRO_SET_DEFINE && strcmp_far(name1 + 1, value) == 0) {  /* `%DEFINE NAME NAME'. */
        if (macro_label == NULL) {
            define_label(name1, MACRO_SELF);
        } else if (RBL_IS_DELETED(macro_label)) {
            RBL_SET_DELETED_0(macro_label);
            macro_label->value = MACRO_SELF;
        } else if ((char)macro_label->value != MACRO_SELF) {
          invalid_macro_override:
            MESSAGE(1, "invalid macro override");
            goto do_return;
        }
        /* !! TODO(pts): Allow `%DEFINE offset' and `%DEFINE ptr' for compatibility with A72, TASM and A86. Also add corresponding command-line flags. */
        /* !! TODO(pts): Allow effective addresses ds:[bp] and [bp][bx] for compatibility with TASM. */
    } else if (macro_set_mode != MACRO_SET_ASSIGN && !is_define_value(value)) {
      bad_macro_value:
        /* By reporting an error here we want to avoid the following NASM
         * incompatibility:
         *
         *   %define foo 5+2
         *   db foo*6
         *
         * In NASM, this is equivalent to`db 5+2* 6', which is `db 17'.
         * mininasm is not able to store strings (e.g. `5+2') as macro
         * values, and storing 7 would be incompatible with NASM, because
         * that would be equivalent to `db 7*6', which is `db 42'.
         */
        MESSAGE(1, "bad macro value");
        goto do_return;
    } else if ((label = find_label(name1 + 1)) != NULL && !RBL_IS_DELETED(label) && (macro_label == NULL || RBL_IS_DELETED(macro_label))) {
        MESSAGE(1, "macro name conflicts with label");
        goto do_return;
    } else {
        *name_end = name_endc;
        p3 = match_expression(value);
        *name_end = '\0';
        if (p3 == NULL || *p3 != '\0') {
            if (macro_set_mode != MACRO_SET_ASSIGN) goto bad_macro_value;
            MESSAGE(1, "Bad expression");
            goto do_return;
        } else if (has_undefined) {
            MESSAGE(1, "Cannot use undefined labels");
            goto do_return;
        }
        macro_set_mode &= ~0x10;  /* Change MACRO_SET_ASSIGN to MACRO_VALUE == MACRO_SET_DEFINE. */
        /* Now: macro_set_mode is MACRO_CMDLINE == MACRO_SET_DEFINE_CMDLINE or MACRO_VALUE == MACRO_SET_DEFINE. */
        if (macro_label == NULL) {
            define_label(name1, macro_set_mode);
        } else if (RBL_IS_DELETED(macro_label)) {
            RBL_SET_DELETED_0(macro_label);
            macro_label->value = macro_set_mode;
        } else if ((char)macro_label->value != macro_set_mode) {
            goto invalid_macro_override;
        }
        if (label == NULL) {
            define_label(name1 + 1, instruction_value);
        } else {
            RBL_SET_DELETED_0(label);
            label->value = instruction_value;
        }
    }
    has_macros = 1;
  do_return:
    *name1 = name1c;
    *name_end = name_endc;
}

#if CONFIG_USE_MEMCPY_INLINE
#if 1
static void memcpy_void_my(void *dest, const void *src, size_t n) {
    memcpy_void_inline(dest, src, n);
}
#else
/* This would make the __WATCOMC__ Linux i386 <libc.h> executable program 160 bytes larger (!). Also it would cause similar size increases for __DOSMC__. */
#define memcpy_void_my memcpy_void_inline
#endif
#endif

/*
 ** Do an assembler pass.
 */
static void do_assembly(const char *input_filename) {
    struct assembly_info *aip;
    const char *p3;
    const char *p;
    char *line;
    char *linep;
    char *liner;
    char *line_rend;
    uvalue_t level;
    uvalue_t avoid_level;
    value_t times;
    value_t line_address;
    value_t incbin_offset;
    value_t incbin_size;
    int discarded_after_read;  /* Number of bytes discarded in an incomplete line since the last file read(...) at line_rend, i.e. the end of the buffer (line_buf). */
    char include;  /* 0, 1 or 2. */
    int got;
    int input_fd;
    int incbin_fd;
    char pc;
    char is_if_not;
    char is_bss;
    struct label MY_FAR *label;

    have_labels_changed = 0;
    cpu_level = 0xff;  /* Accept all supported instructions. */
    is_bss = 0;
    assembly_p = (struct assembly_info*)assembly_stack;  /* Clear the stack. */

  do_assembly_push:
    line_number = 0;  /* Global variable. */
    if ((aip = assembly_push(input_filename)) == NULL) {
        MESSAGE(1, "assembly stack overflow, too many pending %INCLUDE files");
        return;
    }

  do_open_again:
    line_number = 0;  /* Global variable. */
    filename_for_message = aip->input_filename;
    if (HAS_OPEN_FAILED(input_fd = open2(aip->input_filename, O_RDONLY | O_BINARY))) {
        MESSAGE1STR(1, "cannot open '%s' for input", aip->input_filename);
        return;
    }
    if (0) DEBUG2("seeking to %d in file: %s\n", (int)aip->file_offset, aip->input_filename);
    if (aip->file_offset != 0 && lseek(input_fd, aip->file_offset, SEEK_SET) != aip->file_offset) {
        MESSAGE1STR(1, "cannot seek in '%s'", input_filename);
        return;
    }
    level = aip->level;
    avoid_level = aip->avoid_level;
    line_number = aip->line_number;

    global_label[0] = '\0';
    global_label_end = global_label;
    linep = line_rend = line_buf;
    discarded_after_read = 0;
    for (;;) {  /* Read and process next line from input. */
        if (GET_UVALUE(++line_number) == 0) --line_number;  /* Cappped at max uvalue_t. */
        line = linep;
       find_eol:
        /* linep can be used as scratch from now on */
        for (p = line; p != line_rend && *p != '\n'; ++p) {}
        if (p == line_rend) {  /* No newline in the remaining unprocessed bytes, so read more bytes from the file. */
            if (line != line_buf) {  /* Move the remaining unprocessed bytes (line...line_rend) to the beginning of the buffer (line_buf). */
                if (line_rend - line >= MAX_SIZE) goto line_too_long;
                /*if (line_rend - line > (int)(sizeof(line_buf) - (sizeof(line_buf) >> 2))) goto line_too_long;*/  /* Too much copy per line (thus too slow). This won't be triggered, because the `line_rend - line >= MAX_SIZE' check above triggers first. */
                for (liner = line_buf, p = line; p != line_rend; *liner++ = *p++) {}
                p = line_rend = liner;
                line = line_buf;
            }
          read_more:
            discarded_after_read = 0;  /* This must be after `read_more' for correct offset calculations. */
            /* Now: p == line_rend. */
            if ((got = line_buf + sizeof(line_buf) - line_rend) <= 0) goto line_too_long;
            if (0) DEBUG0("READ\r\n");
            if ((got = read(input_fd, line_rend, got)) < 0) {
                MESSAGE(1, "error reading assembly file");
                goto close_return;
            }
            line_rend += got;
            if (got == 0) {
                if (p == line_rend) break;  /* EOF. */
                *line_rend++ = '\n';  /* Add sentinel. This is valid memory access in line_buf, because got > 0 in the read(...) call above. */
            } else if (line_rend != line_buf + sizeof(line_buf)) {
                goto read_more;
            }
            /* We may process the last partial line here again later, but that performance degradation is fine. TODO(pts): Keep some state (comment, quote) to avoid this. */
            for (p = linep = line; p != line_rend; ) {
                pc = *p;
                if (pc == '\'' || pc == '"') {
                    ++p;
                    do {
                        if (p == line_rend) break;  /* This quote may be closed later, after a read(...). */
                        if (*p == '\n') goto newline;  /* This unclosed quote will be reported as a syntax error later. */
                        if (*p == '\0') {
                            MESSAGE(1, "quoted NUL found");
                            *(char*)p = ' ';
                        }
                    } while (*p++ != pc);
                } else if (pc == ';') {
                    for (liner = (char*)p; p != line_rend; *(char*)p++ = ' ') {
                        if (*p == '\n') goto newline;
                    }
                    /* Now: p == line_rend. We have comment which hasn't been finished in the remaining buffer. */
                    for (; liner != line && liner[-1] != '\n' && isspace(liner[-1]); --liner) {}  /* Find start of whitespace preceding the comment. */
                    *liner++ = ';';  /* Process this comment again later. */
                    discarded_after_read = line_rend - liner;  /* TODO(pts): We should check for overflow for source files >= 2 GiB. */
                    if (0) DEBUG1("DISCARD_COMMENT %d\r\n", (int)(line_rend - liner));
                    p = line_rend = liner;
                    if (linep == line) { /* Reached end of the read buffer before the end of the single-line comment in the upcoming line. Read more bytes of this comment. */
                        if (line_rend - linep >= MAX_SIZE) goto line_too_long;
                        goto read_more;
                    }
                    goto find_eol;  /* Superfluous. */
                } else if (pc == '\n') {
                  newline:
                    linep = (char*)++p;
                } else if (pc == '\0' || isspace(pc)) {
                    *(char*)p++ = ' ';
                    for (liner = (char*)p; liner != line_rend && ((pc = *liner) == '\0' || (pc != '\n' && isspace(pc))); *liner++ = ' ') {}
                    if (liner == line_rend) {
                        discarded_after_read = (const char*)line_rend - p;  /* TODO(pts): We should check for overflow for source files >= 2 GiB. */
                        if (0) DEBUG1("DISCARD_WHITESPACE %d\r\n", (int)(line_rend - p));
                        line_rend = (char*)p;  /* Compress trailing whitespace bytes at the end of the buffer to a single space, so that they won't count against the line size (MAX_SIZE) at the end of the line. */
                        goto find_eol;  /* Superfluous. */
                    }
                } else {
                    ++p;
                }
            }
            goto find_eol;
        }
        /* Now: *p == '\n'. */
        linep = (char*)p + 1;
        for (; p != line && p[-1] == ' '; --p) {}  /* Removes trailing \r and spaces. */
        *(char*)p = '\0';  /* Change trailing '\n' to '\0'. */
        if (0) DEBUG3("line @0x%x %u=(%s)\r\n", (unsigned)current_address, (unsigned)line_number, line);
        if (p - line >= MAX_SIZE) { line_too_long:
            MESSAGE(1, "assembly line too long");
            goto close_return;
        }

        line_address = current_address;
        g = generated_ptr;
        include = 0;

        p = avoid_spaces(line);
        if (p[0] == '[') {  /* Change e.g. `[org 100h]' (as in output of the NASM preprocessor `nasm -E' to `org 100h'. */
            p3 = p + strlen(p) - 1;
            if (p3[0] == ']') {
                for (; p3[-1] == ' '; --p3) {}
                ((char*)p3)[0] = '\0';
                p = avoid_spaces(p + 1);
            }
        }
        if (p[0] == '\0') {  /* Empty line. */
            goto after_line;
        } else if (p[0] != '%') {
            if (avoid_level != 0 && level >= avoid_level) {
#if DEBUG
                if (0) MESSAGE1STR(1, "Avoiding '%s'", p);
#endif
                goto after_line;
            }
            goto not_preproc;
        }

        /* Process preprocessor directive. Labels are not allowed here. */
        p = separate(p);
        if (casematch(instr_name, "%IF")) {
            if (GET_UVALUE(++level) == 0) { if_too_deep:
                MESSAGE(1, "%IF too deep");
                goto close_return;
            }
            if (avoid_level != 0 && level >= avoid_level)
                goto after_line;
            /* !! TODO(pts): Add operators < > <= >=  == = != <> && || ^^ for `%IF' only. NASM doesn't do short-circuit. */
            p = match_expression(p);
            if (p == NULL) {
                MESSAGE(1, "Bad expression");
            } else if (has_undefined) {
                MESSAGE(1, "Cannot use undefined labels");
            }
            if (instruction_value != 0) {
                ;
            } else {
                avoid_level = level;
            }
            check_end(p);
        } else if (casematch(instr_name, "%IFDEF")) {
            is_if_not = 0;
          ifdef_or_ifndef:
            if (GET_UVALUE(++level) == 0) goto if_too_deep;
            if (avoid_level != 0 && level >= avoid_level)
                goto after_line;
            if (0) DEBUG1("%%IFDEF macro=(%s)\r\n", p);
            p3 = match_label_prefix(p);
            if (!p3 || *p3 != '\0' || !(isalpha(*p) || *p == '_')) {
                MESSAGE(1, "bad macro name");
            } else {
                pc = *--p;
                *(char*)p = '%';  /* Prefix the macro name with a '%'. */
                if (((label = find_label(p)) != NULL && !RBL_IS_DELETED(label)) == is_if_not) {
                    avoid_level = level;  /* Our %IFDEF or %IFNDEF is false, start hiding. */
                }
                *(char*)p = pc;  /* Restore original character for listing_fd. */
            }
        } else if (casematch(instr_name, "%IFNDEF")) {
            is_if_not = 1;
            goto ifdef_or_ifndef;
        } else if (casematch(instr_name, "%IFIDN")) {  /* Only `%ifidn __OUTPUT_FORMAT__, ...' is supported, and it is true only for `bin'. */
            is_if_not = 0;
          ifidn_or_ifnidn:
            if (GET_UVALUE(++level) == 0) goto if_too_deep;
            if (avoid_level != 0 && level >= avoid_level)
                goto after_line;
            for (p3 = "__OUTPUT_FORMAT__"; p3[0] != '\0' && p[0] == p3[0]; ++p, ++p3) {}
            if (p3[0] != '\0') { bad_ifidn:
                MESSAGE(1, "bad %IFIDN");
            } else if ((p = avoid_spaces(p))[0] != ',') {
                goto bad_ifidn;
            } else {
                p = avoid_spaces(p + 1);
                /* strcmp(...) would also work (there are no far pointers here), but we can save a few bytes if we avoid linking strcmp(...), for __DOSMC__. */
                if ((strcmp_far(p, "bin") == 0) == is_if_not) {
                    avoid_level = level;  /* Our %IFIDN or %IFNIDN is false, start hiding. */
                }
            }
        } else if (casematch(instr_name, "%IFNIDN")) {
            is_if_not = 1;
            goto ifidn_or_ifnidn;
        } else if (casematch(instr_name, "%ELSE")) {
            if (level == 1) {
                MESSAGE(1, "%ELSE without %IF");
                goto close_return;
            }
            if (avoid_level != 0 && level > avoid_level)
                goto after_line;
            if (avoid_level == level) {
                avoid_level = 0;
            } else if (avoid_level == 0) {
                avoid_level = level;
            }
            check_end(p);
        } else if (casematch(instr_name, "%ENDIF")) {
            if (avoid_level == level)
                avoid_level = 0;
            if (--level == 0) {
                MESSAGE(1, "%ENDIF without %IF");
                goto close_return;
            }
            check_end(p);
        } else if (casematch(instr_name, "%IF*") || casematch(instr_name, "%ELIF*")) {
            /* We report this even if skipped. */
            MESSAGE1STR(1, "Unknown preprocessor condition: %s", instr_name);
            goto close_return;  /* There is no meaningful way to continue. */
        } else if (avoid_level != 0 && level >= avoid_level) {
        } else if (casematch(instr_name, "%INCLUDE")) {
            pc = *p++;
            if (pc != '"' && pc != '\'') {
              missing_quotes_in_include:
                MESSAGE(1, "Missing quotes in %INCLUDE");
                goto after_line;
            }
            for (p3 = p; *p != '\0' && *p != pc; ++p) {}
            if (*p == '\0') goto missing_quotes_in_include;
            if (!check_end(p + 1)) goto after_line;
            liner = (char*)p;
            include = 1;
        } else if ((pc = casematch(instr_name, "%DEFINE")) != 0 || casematch(instr_name, "%ASSIGN")) {
            for (p3 = p; *p3 != '\0' && !isspace(*p3); ++p3) {}
            set_macro((char*)p - 1, (char*)p3, p3, (char)(pc ? MACRO_SET_DEFINE : MACRO_SET_ASSIGN));
        } else if (casematch(instr_name, "%UNDEF")) {
            unset_macro((char*)p - 1);
        } else if (casematch(instr_name, "%LINE")) {  /* Just ignore. */
        } else {
            MESSAGE1STR(1, "Unknown preprocessor directive: %s", instr_name);
        }
        goto after_line;
      not_preproc:

        /* Parse and process label, if any. */
        if ((p3 = match_label_prefix(p)) != NULL && (p3[0] == ':' || (p3[0] == ' ' && (p[0] == '$' || (is_colonless_instruction(avoid_spaces(p3 + 1))
            /* && !is_colonless_instruction(p) */ ))))) {  /* !is_colonless_instruction(p) is implied by match_label_prefix(p) */
            if (p[0] == '$') ++p;
            liner = (p[0] == '.') ? global_label_end : global_label;  /* If label starts with '.', then prepend global_label. */
#if CONFIG_USE_MEMCPY_INLINE  /* A few bytes smaller than memcpy(...). */
            /* Calling memcpy_newdest_inline(...) or memcpy_void_inline(...) instead here would add 127 bytes to the program, so we are not doing it. OpenWatcom optimization is weird. */
            memcpy_void_my(liner, p, p3 - p);
#else
            memcpy(liner, p, p3 - p);
#endif
            liner += p3 - p;
            *liner = '\0';
            if (p[0] != '.') global_label_end = liner;
            p = avoid_spaces(p3 + 1);
            if (casematch(p, "EQU!")) {
                p = match_expression(p + 3);
                if (p == NULL) {
                    MESSAGE(1, "bad expression");
                } else {
                    create_label();
                    check_end(p);
                }
                *global_label_end = '\0';  /* Undo the concat to global_label. */
                goto after_line;
            }
            instruction_value = current_address;
            create_label();
            *global_label_end = '\0';  /* Undo the concat to global_label. */
        }

        /* Process command (non-preprocessor, non-label). */
        if (p[0] == '\0') {
            goto after_line;
        } else if (!isalpha(p[0])) {
            MESSAGE(1, "Instruction expected");
            goto after_line;
        }
        p = separate(p3 = p);
        if (casematch(instr_name, "USE16")) {
        } else if (casematch(instr_name, "CPU")) {
            if (casematch(p, "8086")) {
                cpu_level = 0;
            } else if (casematch(p, "186")) {
                cpu_level = 1;
            } else {
                cpu_level = 0xff;
                if (SUB_U(*p, '3') <= '9' - '3' + 0U && casematch(p + 1, "86")) {  /* Disallow `cpu 386', ..., `cpu 986'. Actually, `cpu 786', `cpu 886' and `cpu 986' are not valid in NASM. */
                    MESSAGE(1, "Unsupported processor requested");
                }
            }
        } else if (casematch(instr_name, "BITS")) {
            p = match_expression(p);
            if (p == NULL) {
                MESSAGE(1, "Bad expression");
            } else if (has_undefined) {
                MESSAGE(1, "Cannot use undefined labels");
            } else if (instruction_value != 16) {
                MESSAGE(1, "Unsupported BITS requested");
            } else {
                check_end(p);
            }
        } else if (casematch(instr_name, "INCBIN")) {
            pc = *p++;
            if (pc != '"' && pc != '\'') {
              missing_quotes_in_incbin:
                MESSAGE(1, "Missing quotes in INCBIN");
                goto after_line;
            }
            for (p3 = p; *p != '\0' && *p != pc; ++p) {}
            if (*p == '\0') goto missing_quotes_in_incbin;
            liner = (char*)p;
            incbin_offset = 0;
            incbin_size = -1;  /* Unlimited. */
            if (*(p = avoid_spaces(p + 1)) == ',') {
                p = match_expression(p + 1);
                if (p == NULL) {
                    MESSAGE(1, "Bad expression");
                    goto after_line;
                } else if (has_undefined) {
                    MESSAGE(1, "Cannot use undefined labels");
                    goto after_line;
                } else if (instruction_value < 0) {
                    MESSAGE(1, "INCBIN value is negative");
                    goto after_line;
                } else {
                    incbin_offset = instruction_value;
                    if (*(p = avoid_spaces(p)) == ',') {
                        p = match_expression(p + 1);
                        if (p == NULL) {
                            MESSAGE(1, "Bad expression");
                            goto after_line;
                        } else if (has_undefined) {
                            MESSAGE(1, "Cannot use undefined labels");
                            goto after_line;
                        } else if (!check_end(p)) {
                            goto after_line;
                        } else if (instruction_value < 0) {
                            MESSAGE(1, "INCBIN value is negative");
                            goto after_line;
                        } else {
                            incbin_size = instruction_value;
                        }
                    } else if (!check_end(p)) {
                        goto after_line;
                    }
                }
            }
            include = 2;
        } else if (casematch(instr_name, "ORG")) {
            p = match_expression(p);
            if (p != NULL) check_end(p);
            if (p == NULL) {
                MESSAGE(1, "Bad expression");
            } else if (has_undefined) {
                MESSAGE(1, "Cannot use undefined labels");
            } else if (is_start_address_set) {
                if (instruction_value != default_start_address) {
                    MESSAGE(1, "program origin redefined");  /* Same error as in NASM. */
                    goto close_return;  /* TODO(pts): Abort %includers as well. */
                }
            } else {
                is_start_address_set = 1;
                if (instruction_value != default_start_address) {
                    default_start_address = instruction_value;
                    if (is_address_used) {
                        /* Currently we are at assembler_pass == 0 (because
                         * we have !is_start_address_set, and before
                         * assembler_pass == 2 we set is_start_address_set
                         * to true), we set start_address after it has been
                         * used (as indicated by is_address_used). Thus all
                         * such previous uses are wrong, and we need to do
                         * another assembler pass to fix it. Usually we set
                         * change = 1 to ask for a next pass, but currently
                         * it's not necessary, because we always,
                         * unconditionally do assembler_pass == 2.
                         */
                        /*change = 1;*/
                        /* We want to delete all labels between
                         * assembler_pass == 0 and == 2, to accelerate fixed
                         * point convergence of optimization, and also to
                         * make code size growing (rather than shrinking).
                         * More specifically, pass 2 starts at a different
                         * start_address, and jump target labels produced by
                         * pass 1 are way to much off (by `start_address'),
                         * thus pas 2 would generate 5-byte conditional
                         * jumps everywhere, thus file size will shrink from
                         * that (to 2 bytes for some conditional jumps) only
                         * after pass 2. But we want growing rather than
                         * shrinking, and we get this by discarding all labels
                         * and doing pass 1.
                         */
                        do_special_pass_1 = 1;
                    } else {
                        reset_address();
                    }
                }
            }
        } else if (casematch(instr_name, "SECTION")) {
            /* In NASM, .bss is case sensitive. */
            if (!casematch(p, ".bss *") || !casematch(avoid_spaces(p + 5), "ALIGN=1")) {
                MESSAGE1STR(1, "Unsupported SECTION: %s", p);
            } else if (!is_bss) {
                is_bss = 1;
                is_address_used = 1;
                start_address = current_address;
            }
        } else if (is_bss) {
            if (casematch(instr_name, "RESB")) {
                /* We also could add RESW, RESD, ALIGNB, but the user can implement them in terms of RESB. */
                p = match_expression(p);
                if (p == NULL) {
                    MESSAGE(1, "Bad expression");
                } else if (has_undefined) {
                    MESSAGE(1, "Cannot use undefined labels");
                } else if (instruction_value < 0) {
                    MESSAGE(1, "RESB value is negative");
                } else if (!check_end(p)) {
                } else {
                    current_address += instruction_value;
                }
            } else {
                MESSAGE1STR(1, "Unsupported .bss instrucction: %s", instr_name);
            }
        } else if (casematch(instr_name, "ALIGN")) {
            p = match_expression(p);
            if (p == NULL) {
                MESSAGE(1, "Bad expression");
            } else if (has_undefined) {
                MESSAGE(1, "Cannot use undefined labels");
            } else if (instruction_value <= 0) {
                MESSAGE(1, "ALIGN value is not positive");
            } else {
                /* NASM 0.98.39 does the wrong thing if instruction_value is not a power of 2. Newer NASMs report an error. mininasm just works. */
                times = (uvalue_t)current_address % instruction_value;
                if (times != 0) times = instruction_value - times;
                p = avoid_spaces(p);
                if (p[0] == ',') {
                    ++p;
                    goto do_instruction_with_times;  /* This doesn't work correctly if the instruction at `p' doesn't emit exiacty 1 byte. That's fine, same as for NASM. */
                }
                check_end(p);
                for (; (uvalue_t)times != 0; --times) {
                    emit_byte(0x90);
                }
            }
        } else {
            times = 1;
            if (casematch(instr_name, "TIMES")) {
                p3 = match_expression(p);
                if (p3 == NULL) {
                    MESSAGE(1, "Bad expression");
                    goto after_line;
                }
                if (has_undefined) {
                    MESSAGE(1, "Cannot use undefined labels");
                    goto after_line;
                }
                if ((value_t)(times = instruction_value) < 0) {
                    MESSAGE(1, "TIMES value is negative");
                    goto after_line;
                }
            }
            p = p3;
          do_instruction_with_times:
            line_address = current_address;
            g = generated_ptr;
            for (; (uvalue_t)times != 0; --times) {
                process_instruction(p);
            }
        }
      after_line:
        if (assembler_pass > 1 && listing_fd >= 0) {
            bbprintf(&message_bbb /* listing_fd */, "%04" FMT_VALUE "X  ", GET_UVALUE(line_address));
            p = generated_ptr;
            while (p < g) {
                bbprintf(&message_bbb /* listing_fd */, "%02X", *p++ & 255);
            }
            while (p < generated + sizeof(generated)) {
                bbprintf(&message_bbb /* listing_fd */, "  ");
                p++;
            }
            /* TODO(pts): Keep the original line with the original comment, if possible. This is complicated and needs more memory. */
            bbprintf(&message_bbb /* listing_fd */, "  %05" FMT_VALUE "u %s\r\n", GET_UVALUE(line_number), line);
        }
        if (include == 1) {  /* %INCLUDE. */
            if (0) DEBUG1("INCLUDE %s\r\n", p3);  /* Not yet NUL-terminated early. */
            if (linep != NULL && (aip->file_offset = lseek(input_fd, (linep - line_rend) - discarded_after_read, SEEK_CUR)) < 0) {  /* TODO(pts): We should check for overflow for source files >= 2 GiB. */
                MESSAGE(1, "Cannot seek in source file");
                goto close_return;
            }
            close(input_fd);
            aip->level = level;
            aip->avoid_level = avoid_level;
            aip->line_number = line_number;
            *liner = '\0';
            input_filename = p3;
            goto do_assembly_push;
        } else if (include == 2) {  /* INCBIN. */
            *liner = '\0';  /* NUL-terminate the filename in p3. It's OK, we've already written the line to listing_fd. */
            if (HAS_OPEN_FAILED(incbin_fd = open2(p3, O_RDONLY | O_BINARY))) {
                MESSAGE1STR(1, "Error: Cannot open '%s' for input", p3);
            } else {
                if (incbin_offset != 0 && lseek(incbin_fd, incbin_offset, SEEK_SET) != incbin_offset) {
                    MESSAGE1STR(1, "Cannot seek in INCBIN file: ", p3);
                } else {
                    message_flush(NULL);  /* Because we reuse message_buf below. */
                    g = NULL;  /* Doesn't make an actual difference, incbin is called too late to append to incbin anyway. */
                    /* Condition below is good even if incbin_size == -1 (unlimited). */
                    while (incbin_size != 0) {
                        if ((got = read(incbin_fd, message_buf, (uvalue_t)incbin_size < sizeof(message_buf) ? (unsigned)incbin_size : sizeof(message_buf))) <= 0) {
                            if (got < 0) MESSAGE1STR(1, "Error: Error reading from '%s'", p3);
                            break;
                        }
                        emit_bytes(message_buf, got);
                        if (incbin_size != -1) incbin_size -= got;
                    }
                }
                close(incbin_fd);
            }
        }
    }
    if (level != 1) {
        MESSAGE(1, "pending %IF at end of file");
    }
  close_return:
    close(input_fd);
    if ((aip = assembly_pop(aip)) != NULL) goto do_open_again;  /* Continue processing the input file which %INCLUDE()d the current input file. */
    line_number = 0;  /* Global variable. */
}

static MY_STRING_WITHOUT_NUL(mininasm_macro_name, " __MININASM__");

#ifndef CONFIG_MAIN_ARGV
#define CONFIG_MAIN_ARGV 0
#endif

/*
 ** Main program
 */
#if CONFIG_MAIN_ARGV
int main_argv(char **argv)
#else
int main(int argc, char **argv)
#endif
{
    int d;
    const char *p;
    char *ifname;
    char *listing_filename;
    value_t prev_address;
#if !CONFIG_MAIN_ARGV
    (void)argc;
#endif

#if (defined(MSDOS) || defined(_WIN32)) && !defined(__DOSMC__)
    setmode(2, O_BINARY);  /* STDERR_FILENO. */
#endif

#if 0
    malloc_init();
    MESSAGE_START(1);
    bbprintf(&message_bbb, "malloc_p_para=0x%04x malloc_end_para=%04x", ((const unsigned*)&__malloc_struct__.malloc_p)[1], __malloc_struct__.malloc_end_para);
    message_end();
#endif

    /*
     ** If ran without arguments then show usage
     */
    if (*++argv == NULL) {
        static const MY_STRING_WITHOUT_NUL(msg, "Typical usage:\r\nmininasm -f bin input.asm -o input.bin\r\n");
        (void)!write(2, (char*)msg, STRING_SIZE_WITHOUT_NUL(msg));  /* Without the (char*), Borland C++ 2.0 reports warning: Suspicious pointer conversion in function main */
        return 1;
    }

    /*
     ** Start to collect arguments
     */
    ifname = NULL;
    /* output_filename = NULL; */  /* Default. */
    listing_filename = NULL;
    /* default_start_address = 0; */  /* Default. */
    /* is_start_address_set = 0; */  /* Default. */
    malloc_init();
    set_macro(mininasm_macro_name, mininasm_macro_name + STRING_SIZE_WITHOUT_NUL(mininasm_macro_name), "5", MACRO_SET_DEFINE_CMDLINE);  /* `%DEFINE __MININASM__ ...'. */
    while (argv[0] != NULL) {
        if (0) DEBUG1("arg=(%s)\n", argv[0]);
        if (argv[0][0] == '-') {    /* All arguments start with dash */
            d = argv[0][1] | 32;  /* Flags characters are case insensitive. */
            if (d == 'd') {  /* Define macro: -DNAME and -DNAME=VALUE. -DNAME is not allowed, because macros with an empty values are nt allowed. */
                for (p = argv[0] + 2; *p != '\0' && *p != '='; ++p) {}
                set_macro(argv[0] + 1, (char*)p, p + (*p == '='), MACRO_SET_DEFINE_CMDLINE);
                if (errors) return 1;
            } else if (d == 'w') {  /* NASM warning flag, ignore. */
            } else if (argv[0][2] != '\0' && d == 'o') {  /* Optimization level (`nasm -O...'). */
                d = argv[0][2];
                if (d == '\0' || (d != '9' && argv[0][3] != '\0')) { bad_opt_level:
                    MESSAGE(1, "bad optimization argument");
                    return 1;
                }
                d |= 32;
                if (SUB_U(d, '0') <= 1U) {  /* -O0 is compatible with NASM, -O1 does some more. */
                    opt_level = d - '0';
                    if (opt_level != 0) do_opt_int = 1;
                } else if (d == 'x' || d == '3' || d == '9') {  /* -Ox, -O3, -O9, -O9... (compatible with NASM). We allow e.g. -O99999999 etc., for compatibility with NASM 0.98.39, where -09 can be too small, causing ``error: phase error detected at end of assembly''.. */
                  set_opt_level_9:
                    opt_level = 9;
                } else if (d == 'l') {  /* -OL (not compatible with NASM, `nasm -O9' doesn't do it) to optimize `lea', including `lea ax, [bx]' and `lea ax, [es:bx]'. */
                    do_opt_lea = 1;
                } else if (d == 'g') {  /* -OG (not compatible with NASM, `nasm -O9' doesn't do it) to optimize segment prefixes in effective addresses, e.g. ``mov ax, [ds:si]'. */
                    do_opt_segreg = 1;
                } else if (d == 'i') {  /* -OI (not compatible with NASM, `nasm-0.98.39 -O9' doesn't do it) to optimize integers (immediates and effective address displacements) even where NASM 0.98.39 doesn't do it, e.g. ``push 0xfffd'. */
                    do_opt_int = 1;
                } else if (d == 'a') {  /* -OA to turn on all optimizations, even those which are not compatible with NASM. Equivalent to `-O9 -OL -OG -OI'. */
                    do_opt_lea = 1;
                    do_opt_segreg = 1;
                    do_opt_int = 1;
                    goto set_opt_level_9;
                } else {
                    goto bad_opt_level;
                }
            } else if (argv[0][2] != '\0' && (d == 'f' || d == 'o' || d == 'l')) {
                MESSAGE1STR(1, "flag too long: %s", argv[0]);  /* Example: `-fbin' should be `-f bin'. */
                return 1;
            } else if (d == 'f') { /* Format */
                if (*++argv == NULL) {
                  error_no_argument:
                    MESSAGE1STR(1, "no argument for %s", argv[-1]);
                    return 1;
                } else {
                    if (casematch(argv[0], "BIN")) {
                        default_start_address = 0;
                        is_start_address_set = 0;
                    } else if (casematch(argv[0], "COM")) {
                        default_start_address = 0x100;
                        is_start_address_set = 1;
                    } else {
                        MESSAGE1STR(1, "only 'bin', 'com' supported for -f (it is '%s')", argv[0]);
                        return 1;
                    }
                }
            } else if (d == 'o') {  /* Object file name */
                if (*++argv == NULL) {
                    goto error_no_argument;
                } else if (output_filename != NULL) {
                    MESSAGE(1, "already a -o argument is present");
                    return 1;
                } else {
                    output_filename = argv[0];
                }
            } else if (d == 'l') {  /* Listing file name */
                if (*++argv == NULL) {
                    goto error_no_argument;
                    return 1;
                } else if (listing_filename != NULL) {
                    MESSAGE(1, "already a -l argument is present");
                    return 1;
                } else {
                    listing_filename = argv[0];
                }
            } else {
                MESSAGE1STR(1, "unknown argument %s", argv[0]);
                return 1;
            }
        } else {
            if (0) DEBUG1("ifname=(%s)\n", argv[0]);
            if (ifname != NULL) {
                MESSAGE1STR(1, "more than one input file name: %s", argv[0]);
                return 1;
            } else {
                ifname = argv[0];
            }
        }
        ++argv;
    }

    if (ifname == NULL) {
        MESSAGE(1, "No input filename provided");
        return 1;
    }

    /*
     ** Do first pass of assembly, calculating offsets and labels only.
     */
    assembler_pass = 0;
    /* if (opt_level <= 1) wide_instr_add_at = NULL; */  /* No need, this is the default. */
    reset_address();
    do_assembly(ifname);
    message_flush(NULL);
    if (errors) { do_remove:
        remove(output_filename);
        /* if (listing_filename != NULL) remove(listing_filename); */  /* Don't remove listing_filename, it may contain useful error messages etc. */
    } else {
        ++assembler_pass;  /* = 1. */
        is_start_address_set = 1;
        if (opt_level <= 1) {
            /* wide_instr_add_at = NULL; */  /* Keep for reading. */
            wide_instr_read_at = NULL;
        }
        if (do_special_pass_1) {  /* In this special pass 1, we recompute all labels (starting with the right, final start_address) from scratch, and we don't emit any bytes. */
            reset_address();
            reset_macros();  /* Delete all (non-macro) labels because since do_special_pass is true. */
            do_assembly(ifname);
            ++do_special_pass_1;  /* = 2. */
        }
        /*
         ** Do second pass of assembly and generate final output
         */
        if (output_filename == NULL) {
            MESSAGE(1, "No output filename provided");
            return 1;
        }
        do {
            if (GET_U16(++assembler_pass) == 0) { do_special_pass_1 = 2; --assembler_pass; }  /* Cappped at 0xffff. */
            if (listing_filename != NULL) {
                if (HAS_OPEN_FAILED(listing_fd = creat(listing_filename, 0644))) {
                    MESSAGE1STR(1, "couldn't open '%s' as listing file", output_filename);
                    return 1;
                }
                generated_ptr = generated;  /* Start saving bytes to the `generated' array, for the listing. */
            }
            if (HAS_OPEN_FAILED(output_fd = creat(output_filename, 0644))) {
                MESSAGE1STR(1, "couldn't open '%s' as output file", output_filename);
                return 1;
            }
            prev_address = current_address;
            reset_address();
            reset_macros();
            do_assembly(ifname);
            emit_flush(0);
            close(output_fd);
            if (have_labels_changed) {
                if (opt_level <= 1) {
                    MESSAGE(1, "oops: labels changed");
                } else if (current_address > prev_address) {  /* It's OK and we don't count that the size increases, converging to and eventually stabilizing at a fixed point. */
                } else if (++size_decrease_count == 5) {  /* TODO(pts): Make this configurable? NASM also counts increasing. */
                    MESSAGE(1, "Aborted: Couldn't stabilize moving label");
                }
            }
            if (listing_fd >= 0) {
                bbprintf(&message_bbb /* listing_fd */, "\r\n%05" FMT_VALUE "u ERRORS FOUND\r\n", GET_UVALUE(errors));
                bbprintf(&message_bbb /* listing_fd */, "%05" FMT_VALUE "u WARNINGS FOUND\r\n",
#if CONFIG_SUPPORT_WARNINGS
                         GET_UVALUE(warnings)
#else
                         GET_UVALUE(0)
#endif
                        );
                bbprintf(&message_bbb /* listing_fd */, "%05" FMT_VALUE "u PROGRAM BYTES\r\n", GET_UVALUE(bytes));
                bbprintf(&message_bbb /* listing_fd */, "%05" FMT_VALUE "u ASSEMBLER PASSES\r\n\r\n", GET_UVALUE(assembler_pass) + (do_special_pass_1 & 1));
                bbprintf(&message_bbb /* listing_fd */, "%-20s VALUE/ADDRESS\r\n\r\n", "LABEL");
                print_labels_sorted_to_listing();
                bbprintf(&message_bbb /* listing_fd */, "\r\n");
                message_flush(NULL);
                close(listing_fd);
            }
            if (errors) goto do_remove;
        } while (have_labels_changed);
        return 0;
    }

    return 1;
}

/*
 ** mininasm: NASM-compatible mini assembler for 8086, able to run on DOS and on modern systems
 **
 ** Instruction set.
 **
 ** based on tinyasm by Oscar Toledo G, starting Oct/01/2019.
 */

/*
 ** Notice some instructions are sorted by less byte usage first.
 */
#define ALSO "-"
/* GCC 7.5 adds an alignment to 32 bytes without the UNALIGNED. We don't
 * want to waste program size because of such useless alignments.
 *
 * See x86 instructions at https://www.felixcloutier.com/x86/
 * See x86 instructions at http://ref.x86asm.net/geek64-abc.html .
 */
UNALIGNED const char instruction_set[] =
    "AAA\0" " 37\0"
    "AAD\0" "i D5i" ALSO " D50A\0"
    "AAM\0" "i D4i" ALSO " D40A\0"
    "AAS\0" " 3F\0"
    "ADC\0" "j,q 10drd" ALSO "k,r 11drd" ALSO "q,j 12drd" ALSO "r,k 13drd" ALSO "vAL,h 14i" ALSO "wAX,g 15j" ALSO "m,s sdzozdj" ALSO "l,t 80dzozdi\0"
    "ADD\0" "j,q 00drd" ALSO "k,r 01drd" ALSO "q,j 02drd" ALSO "r,k 03drd" ALSO "vAL,h 04i" ALSO "wAX,g 05j" ALSO "m,s sdzzzdj" ALSO "l,t 80dzzzdi\0"
    "AND\0" "j,q 20drd" ALSO "k,r 21drd" ALSO "q,j 22drd" ALSO "r,k 23drd" ALSO "vAL,h 24i" ALSO "wAX,g 25j" ALSO "m,s sdozzdj" ALSO "l,t 80dozzdi\0"
    "BOUND\0" "xr,o 62drd\0"
    "CALL\0" "FAR!k FFdzood" ALSO "f 9Af" ALSO "k FFdzozd" ALSO "b E8b\0"
    "CBW\0" " 98\0"
    "CLC\0" " F8\0"
    "CLD\0" " FC\0"
    "CLI\0" " FA\0"
    "CMC\0" " F5\0"
    "CMP\0" "j,q 38drd" ALSO "k,r 39drd" ALSO "q,j 3Adrd" ALSO "r,k 3Bdrd" ALSO "vAL,h 3Ci" ALSO "wAX,g 3Dj" ALSO "m,s sdooodj" ALSO "l,t 80dooodi\0"
    "CMPSB\0" " A6\0"
    "CMPSW\0" " A7\0"
    "CS\0" " 2E+\0"
    "CWD\0" " 99\0"
    "DAA\0" " 27\0"
    "DAS\0" " 2F\0"
    "DEC\0" "r zozzor" ALSO "l FEdzzod" ALSO "m FFdzzod\0"
    "DIV\0" "l F6doozd" ALSO "m F7doozd\0"
    "DS\0" " 3E+\0"
    "ENTER\0" "xe,h C8ei\0"
    "ES\0" " 26+\0"
    "HLT\0" " F4\0"
    "IDIV\0" "l F6doood" ALSO "m F7doood\0"
    "IMUL\0" "l. F6dozod" ALSO "m. F7dozod" ALSO "xp,s. mdrdj" ALSO "xr,k,s mdrdj\0"
    "IN\0" "vAL,wDX EC" ALSO "wAX,wDX ED" ALSO "vAL,h E4i" ALSO "wAX,i E5i\0"
    "INC\0" "r zozzzr" ALSO "l FEdzzzd" ALSO "m FFdzzzd\0"
    "INSB\0" "x 6C\0"
    "INSW\0" "x 6D\0"
    "INT\0" "i CDi\0"
    "INT3\0" " CC\0"
    "INTO\0" " CE\0"
    "IRET\0" " CF\0"
    "JA\0" "a 77a\0"
    "JAE\0" "a 73a\0"
    "JB\0" "a 72a\0"
    "JBE\0" "a 76a\0"
    "JC\0" "a 72a\0"
    "JCXZ\0" "a E3a\0"
    "JE\0" "a 74a\0"
    "JG\0" "a 7Fa\0"
    "JGE\0" "a 7Da\0"
    "JL\0" "a 7Ca\0"
    "JLE\0" "a 7Ea\0"
    "JMP\0" "FAR!k FFdozod" ALSO "f EAf" ALSO "k FFdozzd" ALSO "c EBa" ALSO "b E9b\0"
    "JNA\0" "a 76a\0"
    "JNAE\0" "a 72a\0"
    "JNB\0" "a 73a\0"
    "JNBE\0" "a 77a\0"
    "JNC\0" "a 73a\0"
    "JNE\0" "a 75a\0"
    "JNG\0" "a 7Ea\0"
    "JNGE\0" "a 7Ca\0"
    "JNL\0" "a 7Da\0"
    "JNLE\0" "a 7Fa\0"
    "JNO\0" "a 71a\0"
    "JNP\0" "a 7Ba\0"
    "JNS\0" "a 79a\0"
    "JNZ\0" "a 75a\0"
    "JO\0" "a 70a\0"
    "JP\0" "a 7Aa\0"
    "JPE\0" "a 7Aa\0"
    "JPO\0" "a 7Ba\0"
    "JS\0" "a 78a\0"
    "JZ\0" "a 74a\0"
    "LAHF\0" " 9F\0"
    "LDS\0" "r,n C5drd\0"
    "LEA\0" "r,o 8Ddrd\0"
    "LEAVE\0" "x C9\0"
    "LES\0" "r,n C4drd\0"
    "LOCK\0" " F0+\0"
    "LODSB\0" " AC\0"
    "LODSW\0" " AD\0"
    "LOOP\0" "a E2a\0"
    "LOOPE\0" "a E1a\0"
    "LOOPNE\0" "a E0a\0"
    "LOOPNZ\0" "a E0a\0"
    "LOOPZ\0" "a E1a\0"
#if CONFIG_SPLIT_INSTRUCTION_SET
;
const char *instruction_set_nul = instruction_set + sizeof(instruction_set) - 1;
UNALIGNED const char instruction_set2[] =
#endif
    "MOV\0" "j,q 88drd" ALSO "k,r 89drd" ALSO "q,j 8Adrd" ALSO "r,k 8Bdrd" ALSO "k,ES 8Cdzzzd" ALSO "k,CS 8Cdzzod" ALSO "k,SS 8Cdzozd" ALSO "k,DS 8Cdzood" ALSO "ES,k 8Edzzzd" ALSO "CS,k 8Edzzod" ALSO "SS,k 8Edzozd" ALSO "DS,k 8Edzood" ALSO "q,h ozoozri" ALSO "r,i ozooorj" ALSO "m,u C7dzzzdj" ALSO "l,t C6dzzzdi\0"
    "MOVSB\0" " A4\0"
    "MOVSW\0" " A5\0"
    "MUL\0" "l F6dozzd" ALSO "m F7dozzd\0"
    "NEG\0" "l F6dzood" ALSO "m F7dzood\0"
    "NOP\0" " 90\0"
    "NOT\0" "l F6dzozd" ALSO "m F7dzozd\0"
    "OR\0" "j,q 08drd" ALSO "k,r 09drd" ALSO "q,j 0Adrd" ALSO "r,k 0Bdrd" ALSO "vAL,h 0Ci" ALSO "wAX,g 0Dj" ALSO "m,s sdzzodj" ALSO "l,t 80dzzodi\0"
    "OUT\0" "wDX,vAL EE" ALSO "wDX,AX EF" ALSO "h,vAL E6i" ALSO "i,AX E7i\0"
    "OUTSB\0" "x 6E\0"
    "OUTSW\0" "x 6F\0"
    "PAUSE\0" " F390\0"
    "POP\0" "ES 07" ALSO "SS 17" ALSO "DS 1F" ALSO "CS 0F" ALSO "r zozoor" ALSO "k 8Fdzzzd\0"
    "POPA\0" "x 61\0"
    "POPAW\0" "x 61\0"
    "POPF\0" " 9D\0"
    "PUSH\0" "ES 06" ALSO "CS 0E" ALSO "SS 16" ALSO "DS 1E" ALSO "r zozozr" ALSO "xs lj" ALSO "k FFdoozd\0"
    "PUSHA\0" "x 60\0"
    "PUSHAW\0" "x 60\0"
    "PUSHF\0" " 9C\0"
    "RCL\0" "j,1 gdzozdk" ALSO "k,1 hdzozdk" ALSO "j,CL D2dzozd" ALSO "k,CL D3dzozd\0"
    "RCR\0" "j,1 gdzoodk" ALSO "k,1 hdzoodk" ALSO "j,CL D2dzood" ALSO "k,CL D3dzood\0"
    "REP\0" " F3+\0"
    "REPE\0" " F3+\0"
    "REPNE\0" " F2+\0"
    "REPNZ\0" " F2+\0"
    "REPZ\0" " F3+\0"
    "RET\0" "i C2j" ALSO " C3\0"
    "RETF\0" "i CAj" ALSO " CB\0"
    "ROL\0" "j,1 gdzzzdk" ALSO "k,1 hdzzzdk" ALSO "j,CL D2dzzzd" ALSO "k,CL D3dzzzd\0"
    "ROR\0" "j,1 gdzzodk" ALSO "k,1 hdzzodk" ALSO "j,CL D2dzzod" ALSO "k,CL D3dzzod\0"
    "SAHF\0" " 9E\0"
    "SAL\0" "j,1 gdozzdk" ALSO "k,1 hdozzdk" ALSO "j,CL D2dozzd" ALSO "k,CL D3dozzd\0"
    "SAR\0" "j,1 gdooodk" ALSO "k,1 hdooodk" ALSO "j,CL D2doood" ALSO "k,CL D3doood\0"
    "SBB\0" "j,q 18drd" ALSO "k,r 19drd" ALSO "q,j 1Adrd" ALSO "r,k 1Bdrd" ALSO "vAL,h 1Ci" ALSO "wAX,g 1Dj" ALSO "m,s sdzoodj" ALSO "l,t 80dzoodi\0"
    "SCASB\0" " AE\0"
    "SCASW\0" " AF\0"
    "SHL\0" "j,1 gdozzdk" ALSO "k,1 hdozzdk" ALSO "j,CL D2dozzd" ALSO "k,CL D3dozzd\0"
    "SHR\0" "j,1 gdozodk" ALSO "k,1 hdozodk" ALSO "j,CL D2dozod" ALSO "k,CL D3dozod\0"
    "SS\0" " 36+\0"
    "STC\0" " F9\0"
    "STD\0" " FD\0"
    "STI\0" " FB\0"
    "STOSB\0" " AA\0"
    "STOSW\0" " AB\0"
    "SUB\0" "j,q 28drd" ALSO "k,r 29drd" ALSO "q,j 2Adrd" ALSO "r,k 2Bdrd" ALSO "vAL,h 2Ci" ALSO "wAX,g 2Dj" ALSO "m,s sdozodj" ALSO "l,t 80dozodi\0"
    "TEST\0" "j,q 84drd" ALSO "q,j 84drd" ALSO "k,r 85drd" ALSO "r,k 85drd" ALSO "vAL,h A8i" ALSO "wAX,i A9j" ALSO "m,u F7dzzzdj" ALSO "l,t F6dzzzdi\0"
    "UD0\0" "y 0FFF\0"
    "UD1\0" "y 0FB9\0"
    "UD2\0" "y 0F0B\0"
    "WAIT\0" " 9B+\0"
    "XCHG\0" "wAX,r ozzozr" ALSO "r,AX ozzozr" ALSO "q,j 86drd" ALSO "j,q 86drd" ALSO "r,k 87drd" ALSO "k,r 87drd\0"
    "XLAT\0" " D7\0"
    "XOR\0" "j,q 30drd" ALSO "k,r 31drd" ALSO "q,j 32drd" ALSO "r,k 33drd" ALSO "vAL,h 34i" ALSO "wAX,g 35j" ALSO "m,s sdoozdj" ALSO "l,t 80doozdi\0"
;
