/*
 * mininasm_swatli3.c: OpenWatcom Linux i386 port of mininasm, without the OpenWatcom libc
 * by pts@fazekas.hu at Fri Nov 25 21:41:31 CET 2022
 *
 # Compile without: owcc -blinux -o mininasm.watli3 -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm.c && sstrip mininasm.watli3 && ls -ld mininasm.watli3
 * Compile: owcc -blinux -fnostdlib -Wl,option -Wl,start=_start_ -o mininasm.swatli3 -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm_swatli3.c && sstrip mininasm.swatli3 && ls -ld mininasm.swatli3
 * Compile better: ./compile_nwatli3.sh
 * Compile even better, smaller libc: owcc -c -D__LIBCH__ -I../minilibc32 -blinux -fnostdlib -Os -fno-stack-check -march=i386 -W -Wall -Wextra -o mininasm.nwalli3.obj mininasm.c && ../minilibc32/as2nasm.pl -o mininasm.nwalli3 mininasm.nwalli3.obj
 * Compile similarly, with GCC: gcc -S -m32 -mno-align-stringops -mregparm=3 -fno-pic -fno-stack-protector -fomit-frame-pointer -fno-ident -ffreestanding -fno-builtin -fno-unwind-tables -fno-asynchronous-unwind-tables -nostdlib -nostdinc -Os -falign-functions=1 -mpreferred-stack-boundary=2 -falign-jumps=1 -falign-loops=1 -march=i386 -ansi -pedantic -W -Wall -Werror=implicit-function-declaration -Wno-overlength-strings -o mininasm.gcc75.s mininasm_sgccli3.c && ../minilibc32/as2nasm.pl -o mininasm.ngccli3 mininasm.gcc75.s
 *
 * Size reduction:
 *
 * * mininasm.watli3:  29882 bytes (OpenWatcom)
 * * mininasm.swatli3: 21533 bytes (OpenWatcom, inlined libc instead of OpenWatcom libc)
 * * mininasm.xtiny:   20580 bytes (GCC with pts-xtiny libc: https://github.com/pts/pts-xtiny )
 * * mininasm.ngccli3: 19996 bytes (GCC, better optimized libc, smarter ELF linking with NASM)
 * * mininasm.nwatli3: 19517 bytes (OpenWatcom, smarter ELF linking with NASM)
 * * mininasm.nwalli3: 19417 bytes (OpenWatcom, libc better optimized than the inlined version, smarter ELF linking with NASM)
 *
 * TODO(pts): Remove the PHDR program header from the ELF executable program (done in compile_nwatli3.pl).
 * TODO(pts): Remove the alignment NUL bytes between the TEXT (AUTO) and DGROUP sections (done in compile_nwatli3.pl).
 * TODO(pts): Change the section aligment of .data and .bss (and all symbols) to 1 in wcc. How much does it help? Not changing makes int up to 4*3 bytes longer. That's fine.
 * TODO(pts): Rewrite malloc_far(...) in mininasm.c in i386 assembly, size-optimize it.
 * TODO(pts): Inline the single call to syscall1_optregorder and also to syscall3_optregorder. Unify parts of syscall1_optregorder and syscall3_optregorder. OpenWatcom doesn't seem to be able to do it without breaking tails in read(...), write(...) etc.
 * TODO(pts): Define custom calling convention for all the non-inline functions, so that the xchgs are not needed.
 */

#ifndef __WATCOMC__
#  error Watcom C compiler required.
#endif

#ifndef __LINUX__
#  error Linux target required.
#endif

#ifndef _M_I386
#  error 32-bit intel target required.
#endif

#define open2(pathname, flags) open(pathname, flags, 0)

/* All routines below are optimized for program file size. */

/* --- typedefs and constants. */

#if 0  /* No need for these OpenWatcom libc headers. But would work even with them. */
#include <fcntl.h>
#include <stdlib.h>
#include <io.h>
#endif

#ifdef _IO_H_INCLUDED  /* Most of the time no, se `#if 0' above. */
#  define LIBC_STATIC
#else
#  define LIBC_STATIC static
#endif

#define NULL ((void *)0)

#define SEEK_SET 0  /* whence value below. */
#define SEEK_CUR 1
#define SEEK_END 2

#define O_RDONLY 0x0000  /* flags bitfield value below. */
#define O_WRONLY 0x0001
#define O_RDWR   0x0002

typedef unsigned size_t;
typedef int ssize_t;
typedef long off_t;  /* !! TODO(pts): Use 64-bit file offset (#define _FILE_OFFSET_BITS 64) in lseek(2). */

#undef O_BINARY

/* --- <stdarg.h> */

#if defined(__GNUC__) || (defined(__WATCOMC__) && !defined(_IO_H_INCLUDED))  /* i386 only, not amd64 */
#define CONFIG_SKIP_STDARG 1
#if 1  /* Shorter by 24 bytes, same as for GCC. */
typedef char *va_list;  /* i386 only. */
#define va_start(ap, last) ((ap) = (char*)&(last) + ((sizeof(last)+3)&~3), (void)0)  /* i386 only. */
#define va_arg(ap, type) ((ap) += (sizeof(type)+3)&~3, *(type*)((ap) - ((sizeof(type)+3)&~3)))  /* i386 only. */
#define va_copy(dest, src) ((dest) = (src), (void)0)  /* i386 only. */
#define va_end(ap) /*((ap) = 0, (void)0)*/  /* i386 only. Adding the `= 0' back doesn't make a difference. */
#else  /* Similar definition to OpenWatcom <stdarg.h>, same number of bytes. */
typedef char *va_list[1];  /* i386 only. */
#define va_start(ap, last) ((ap)[0] = (char*)&(last) + ((sizeof(last)+3)&~3),(void)0)  /* i386 only. */
#define va_arg(ap, type) ((ap)[0] += ((sizeof(type)+3)&~3), *(type*)((ap)[0] - ((sizeof(type)+3)&~3)))  /* i386 only. */
#define va_copy(dest, src) ((dest)[0] = (src)[0], (void)0)  /* i386 only. */
#define va_end(ap) ((ap)[0] = 0, (void)0)  /* i386 only. */
#endif
#endif

/* --- <ctype.h> */

static int isalpha_inline(int c);
LIBC_STATIC int isalpha(int c) { return isalpha_inline(c); }
#pragma aux isalpha_inline = "or al, 32"  "sub al, 97"  "cmp al, 26"  "sbb eax, eax"  "neg eax"  value [ eax ] parm [ eax ];

static int isspace_inline(int c);
LIBC_STATIC int isspace(int c) { return isspace_inline(c); }
#pragma aux isspace_inline = "sub al, 9"  "cmp al, 13-9+1"  "jc short @$1"  "sub al, 32-9"  "cmp al, 1"  "@$1: sbb eax, eax"  "neg eax"  value [ eax ] parm [ eax ];

static int isdigit_inline(int c);
LIBC_STATIC int isdigit(int c) { return isdigit_inline(c); }
#pragma aux isdigit_inline = "sub al, 48"  "cmp al, 10"  "sbb eax, eax"  "neg eax"  value [ eax ] parm [ eax ];

static int isxdigit_inline(int c);
LIBC_STATIC int isxdigit(int c) { return isxdigit_inline(c); }
#pragma aux isxdigit_inline = "sub al, 48"  "cmp al, 10"  "jc short @$1"  "or al, 32"  "sub al, 49"  "cmp al, 6"  "@$1: sbb eax, eax"  "neg eax"  value [ eax ] parm [ eax ];

/* --- <string.h> */

static size_t strlen_inline(const char *s);
static size_t strlen_inline2(const char *s);  /* Unused. Maybe shorter for inlining. */
LIBC_STATIC size_t strlen(const char *s) { return strlen_inline(s); }
#pragma aux strlen_inline = "xchg esi, eax"  "xor eax, eax"  "dec eax"  "again: cmp byte ptr [esi], 1"  "inc esi"  "inc eax"  "jnc short again"  value [ eax ] parm [ eax ] modify [ esi ] ;
#pragma aux strlen_inline2 = "xor eax, eax"  "dec eax"  "again: cmp byte ptr [esi], 1"  "inc esi"  "inc eax"  "jnc short again"  value [ eax ] parm [ esi ] modify [ esi ];

static char *strcpy_inline(char *dest, const char *src);
LIBC_STATIC char *strcpy(char *dest, const char *src) { return strcpy_inline(dest, src); }
#pragma aux strcpy_inline = "xchg esi, edx"  "xchg edi, eax"  "push edi"  "again: lodsb"  "stosb"  "cmp al, 0"  "jne short again"  "pop eax"  "xchg esi, edx"  value [ eax ] parm [ eax ] [ edx ] modify [ edi ];

static void memcpy_void_inline(void *dest, const void *src, size_t n);
#pragma aux memcpy_void_inline = "rep movsb"  parm [ edi ] [ esi ] [ ecx ] modify [ esi edi ecx ];

/* Returns dest + n. */
static void *memcpy_newdest_inline(void *dest, const void *src, size_t n);
#pragma aux memcpy_newdest_inline = "rep movsb"  value [ edi ] parm [ edi ] [ esi ] [ ecx ] modify [ esi ecx ];

#define CONFIG_USE_MEMCPY_INLINE 1

static int strcmp_inline(const char *s1, const char *s2);
LIBC_STATIC int strcmp(const char *s1, const char *s2) { return strcmp_inline(s1, s2); }
/* This is much shorter than in OpenWatcom libc and shorter than QLIB 2.12.1 and Zortech C++. */
#pragma aux strcmp_inline = "xchg esi, eax"  "xor eax, eax"  "xchg edi, edx"  "next: lodsb"  "scasb"  "jne short diff"  "cmp al, 0"  "jne short next"  "jmp short done"  "diff: mov al, 1"  "jnc short done"  "neg eax"  "done: xchg edi, edx"  value [ eax ] parm [ eax ] [ edx ] modify [ esi ];

/* --- Linux i386 system calls.
 *
 * Syscall number is passed in EAX to int 80h, arguments in EBX, ECX, EDX,
 * ESI, EDI, EBP. Return value is in EAX. If EAX is negative, then there is
 * an error, and the negative errno is returned in EAX.
 *
 * FYI OpenWatcom __watcall passes function arguments in EAX, EDX, EBX, ECX, and
 * expects the return value in EAX.
 *
 * Simplification: they don't set errno (but they return -1 as needed).
 */

#ifdef _IO_H_INCLUDED  /* OpenWatcom <io.h> has `unsigned short' type for `mode_t'. */
/* With this creat(...) has a `movzx' instead of a `mov' (1 byte longer). */
typedef unsigned short mode_t;
#else
typedef unsigned mode_t;
#endif

#define __NR_exit		  1
#define __NR_read		  3
#define __NR_write		  4
#define __NR_open		  5
#define __NR_close		  6
#define __NR_creat		  8
#define __NR_unlink		 10
#define __NR_lseek		 19
#define __NR_brk		 45

#if 1
#define SYSCALL_ASM "int 80h"  "test eax, eax"  "jns short done"  "or eax, -1"  "done:"  /* 9 bytes, with jump. */
#else
#define SYSCALL_ASM "int 80h"  "cmp eax, 080000000h"  "cmc"  "sbb ebx, ebx"  "or eax, ebx"  /* 12 bytes, without a jump. Doesn't help OpenWatcom with tail optimizations. */
#endif

static int syscall1_inline(int nr, int arg1);
/* Gets the syscall number in ebx, for better inlining with the OpenWatcom __watcall calling convention. */
#pragma aux syscall1_inline = SYSCALL_ASM  value [ eax ] parm [ eax ] [ ebx ];

static int syscall1_optregorder_inline(int arg1, int nr);
#pragma aux syscall1_optregorder_inline = "xchg eax, ebx" "xchg eax, edx"  SYSCALL_ASM  value [ eax ] parm [ eax ] [ edx ] modify [ ebx edx ];

__declspec(aborts) static int syscall1_noreturn_inline(int nr, int arg1);
#pragma aux syscall1_noreturn_inline = "xchg eax, ebx"  "int 80h"  value [ eax ] parm [ ebx ] [ eax ];

static int syscall2_inline(int nr, int arg1, int arg2);
#pragma aux syscall2_inline = SYSCALL_ASM  value [ eax ] parm [ eax ] [ ebx ] [ ecx ];

static int syscall2_optregorder_inline(int arg1, int arg2, int nr);
#pragma aux syscall2_optregorder_inline = "xchg eax, ebx"  "xchg ecx, edx"  SYSCALL_ASM  value [ eax ] parm [ eax ] [ edx ] [ ebx ] modify [ ebx ecx edx ];

static int syscall3_inline(int nr, int arg1, int arg2, int arg3);
#pragma aux syscall3_inline = SYSCALL_ASM  value [ eax ] parm [ eax ] [ ebx ] [ ecx ] [ edx ];

/* Arguments reorderd to match __watcall, for shorter caller code */
static int syscall3_optregorder_inline(int arg1, int arg2, int arg3, int nr);
#pragma aux syscall3_optregorder_inline = "xchg ebx, eax"  "xchg eax, edx"  "xchg eax, ecx"  SYSCALL_ASM  value [ eax ] parm [ eax ] [ edx ] [ ebx ] [ ecx ] modify [ ebx ecx edx ];

__declspec(aborts) static void exit_inline(int status);
#pragma aux exit_inline = "xchg eax, ebx"  "xor eax, eax"  "inc eax"  "int 80h"  parm [ eax ];

#undef SYSCALL_ASM

/* Inlining this function would make the executable program 12 bytes longer,because of (?) some tail optimization misses. */
__declspec(aborts) LIBC_STATIC void exit(int status) {
#if 1
  exit_inline(status);
#else
  syscall1_noreturn_inline(__NR_exit, status);  /* 4 bytes longer than exit_inline(...). */
#endif
}

/* --- Put syscall3 functions (sys_brk, unlink, close) next to each other, for better tail locality. */

/* For the optimization to take effect, `int nr' must be passed last here, and this must be a non-inline function. */
static int syscall1_optregorder(int arg1, int nr) { return syscall1_optregorder_inline(arg1, nr); }

LIBC_STATIC void *sys_brk(void *addr) { return (void*)syscall1_optregorder((int)addr, __NR_brk); }

LIBC_STATIC int unlink(const char *pathname) { return syscall1_optregorder((int)pathname, __NR_unlink); }
#define remove(pathname) unlink(pathname)

LIBC_STATIC int close(int fd) { return syscall1_optregorder(fd, __NR_close); }

/* --- Put syscall2 functions (creat) next to each other, for better tail locality. */

/* No need for syscall2_optregorder(...) function, because creat(...) is a single syscall2 function. */
LIBC_STATIC int creat(const char *pathname, mode_t mode) { return syscall2_optregorder_inline((int)pathname, mode, __NR_creat); }

/* --- Put syscall3 functions (open3, read, write, lseek) next to each other, for better tail locality. */

/* For the optimization to take effect, `int nr' must be passed last here, and this must be a non-inline function. */
static int syscall3_optregorder(int arg1, int arg2, int arg3, int nr) { return syscall3_optregorder_inline(arg1, arg2, arg3, nr); }

/* This would work, but OpenWatcom generates suboptimal code (with lots of stack pushes) for this. */
LIBC_STATIC int open3(const char *pathname, int flags, mode_t mode) { return syscall3_optregorder((int)pathname, flags, mode, __NR_open); }
/* Without this renaming, OpenWatcom generates suboptimal code (with lots of stack pushes) for this. Why? Because of the hidden `...' in the function prototype? */
#define open(pathname, flags, mode) open3(pathname, flags, mode)

LIBC_STATIC ssize_t read(int fd, void *buf, size_t count) { return syscall3_optregorder(fd, (int)buf, count, __NR_read); }

LIBC_STATIC ssize_t write(int fd, const void *buf, size_t count) { return syscall3_optregorder(fd, (int)buf, count, __NR_write); }

LIBC_STATIC off_t lseek(int fd, off_t offset, int whence) { return syscall3_optregorder(fd, offset, whence, __NR_lseek); }

/* --- End of syscall3 functions. */

/* --- Startup code. Run as: owcc -fnostdlib -Wl,option -Wl,start=_start */

#if 0  /* We don't need environ, envp and argc. */
#define main PROGRAM_MAIN  /* Without this, OpenWatcom would link its standard library. */
extern int main(int argc, char **argv, char **envp);
const char* const* environ;
void __cdecl start_(char *argv0) {
  char **a = &argv0;
  for (; *a != (char*)0; ++a) {}
  environ = (const char* const*)a + 1;
  exit(main(a-&argv0, &argv0, a + 1));
}
#endif

#if 0  /* We don't need to compute argc. */
#define main PROGRAM_MAIN  /* Without this, OpenWatcom would link its standard library. */
extern int main(int argc, char **argv);
void __cdecl start_(char *argv0) {
  char **a = &argv0;
  for (; *a != (char*)0; ++a) {}
  exit(main(a-&argv0, &argv0));
}
#endif

#if 0  /* We don't need to set argc. */
#define main PROGRAM_MAIN  /* Without this, OpenWatcom would link its standard library. */
extern int main(int argc, char **argv);
void __cdecl start_(char *argv0) { exit(main(0, &argv0)); }
#endif

#if 0  /* We don't need main(...) to have an argc argument. */
#define main PROGRAM_MAIN  /* Without this, OpenWatcom would link its standard library. */
extern int main(int argc, char **argv);
__declspec(aborts) static void start_inline(void);
#pragma aux start_inline = "lea edx, [esp+4]"  "call PROGRAM_MAIN"  "jmp exit";
__declspec(aborts) void _start(void) { start_inline(); }
#endif

#if 0  /* The lea below is just 4 bytes, we can make it smaller. */
#define CONFIG_MAIN_ARGV 1
extern int main_argv(char **argv);
__declspec(aborts) static void start_inline(void);
#pragma aux start_inline = "lea eax, [esp+4]"  "call main_argv"  "jmp exit";
__declspec(aborts) void _start(void) { start_inline(); }
#endif

#if 1
#define CONFIG_MAIN_ARGV 1
extern int main_argv(char **argv);
__declspec(aborts) static void start_inline(void);
#pragma aux start_inline = "pop eax"  "mov eax, esp"  "push exit"  "jmp main_argv";
__declspec(aborts) void _start(void) { start_inline(); }
#endif

#define CONFIG_SKIP_LIBC 1
#define CONFIG_MALLOC_FAR_USING_SYS_BRK 1
#include "mininasm.c"
