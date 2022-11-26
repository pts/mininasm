/*
 * mininasm_swatli3.c: OpenWatcom Linux i386 port of mininasm, without the OpenWatcom libc
 * by pts@fazekas.hu at Fri Nov 25 21:41:31 CET 2022
 *
 # Compile without: owcc -blinux -o mininasm.watli3 -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm.c && sstrip mininasm.watli3 && ls -ld mininasm.watli3
 * Compile: owcc -blinux -fnostdlib -Wl,option -Wl,start=_start_ -o mininasm.swatli3 -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm_swatli3.c && sstrip swatli3 && ls -ld mininasm.swatli3
 * Compile better: ./compile_nwatli3.sh
 *
 * Size reduction:
 *
 * * mininasm.watli3:  29882 bytes
 * * mininasm.swatli3: 21533 bytes (no OpenWatcom libc)
 * * mininasm.nwatli3: 19631 bytes (smarter ELF linking with NASM)
 *
 * TODO(pts): Reimplement the C functions in this file in assembly only.
 * TODO(pts): Remove the PHDR program header from the ELF executable program (done in compile_nwatli3.pl).
 * TODO(pts): Remove the alignment NUL bytes between the TEXT (AUTO) and DGROUP sections (done in compile_nwatli3.pl).
 * TODO(pts): Change the section aligment of .data and .bss (and all symbols) to 1 in wcc. How much does it help?
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
#include <unistd.h>
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

/* --- <ctype.h> */

static int isalpha_inline(int c);
int isalpha(int c) { return isalpha_inline(c); }
#pragma aux isalpha_inline = "or al, 32"  "sub al, 97"  "cmp al, 26"  "sbb eax, eax"  "neg eax"  value [ eax ] parm [ eax ];

static int isspace_inline(int c);
int isspace(int c) { return isspace_inline(c); }
#pragma aux isspace_inline = "sub al, 9"  "cmp al, 13-9+1"  "jc short @$1"  "sub al, 32-9"  "cmp al, 1"  "@$1: sbb eax, eax"  "neg eax"  value [ eax ] parm [ eax ];

static int isdigit_inline(int c);
int isdigit(int c) { return isdigit_inline(c); }
#pragma aux isdigit_inline = "sub al, 48"  "cmp al, 10"  "sbb eax, eax"  "neg eax"  value [ eax ] parm [ eax ];

static int isxdigit_inline(int c);
int isxdigit(int c) { return isxdigit_inline(c); }
#pragma aux isxdigit_inline = "sub al, 48"  "cmp al, 10"  "jc short @$1"  "or al, 32"  "sub al, 49"  "cmp al, 6"  "@$1: sbb eax, eax"  "neg eax"  value [ eax ] parm [ eax ];

/* --- <string.h> */

static size_t strlen_inline(const char *s);
static size_t strlen_inline2(const char *s);  /* Unused. Maybe shorter for inlining. */
size_t strlen(const char *s) { return strlen_inline(s); }
#pragma aux strlen_inline = "xchg esi, eax"  "xor eax, eax"  "dec eax"  "again: cmp byte ptr [esi], 1"  "inc esi"  "inc eax"  "jnc short again"  value [ eax ] parm [ eax ] modify [ esi] ;
#pragma aux strlen_inline2 = "xor eax, eax"  "dec eax"  "again: cmp byte ptr [esi], 1"  "inc esi"  "inc eax"  "jnc short again"  value [ eax ] parm [ esi ] modify [ esi ];

static char *strcpy_inline(char *dest, const char *src);
char *strcpy(char *dest, const char *src) { return strcpy_inline(dest, src); }
#pragma aux strcpy_inline = "xchg esi, edx"  "xchg edi, eax"  "push edi"  "again: lodsb"  "stosb"  "cmp al, 0"  "jne short again"  "pop eax"  "xchg esi, edx"  value [ eax ] parm [ eax ] [ edx ] modify [ edi ];

static void memcpy_void_inline(void *dest, const void *src, size_t n);
#pragma aux memcpy_void_inline = "rep movsb"  parm [ edi ] [ esi ] [ ecx ] modify [ esi edi ecx ];

/* Returns dest + n. */
static void *memcpy_newdest_inline(void *dest, const void *src, size_t n);
#pragma aux memcpy_newdest_inline = "rep movsb"  value [ edi ] parm [ edi ] [ esi ] [ ecx ] modify [ esi ecx ];

#define CONFIG_USE_MEMCPY_INLINE 1

static int strcmp_inline(const char *s1, const char *s2);
int strcmp(const char *s1, const char *s2) { return strcmp_inline(s1, s2); }
/* This is much shorter than in OpenWatcom libc and shorter than QLIB 2.12.1 and Zortech C++. */
#pragma aux strcmp_inline = "xchg esi, eax"  "xor eax, eax"  "xchg edi, edx"  "next: lodsb"  "scasb"  "jne short diff"  "cmp al, 0"  "jne short next"  "jmp short done"  "diff: mov al, 1"  "jnc short done"  "neg eax"  "done: xchg edi, edx"  value [ eax ] parm [ eax ] [ edx ] modify [ esi ];

/* --- Memory allocator based on brk(2). */

void *sys_brk(void *addr);

/*
 * A simplistic allocator which creates a heap of 64 KiB first, and then
 * doubles it when necessary. free(...)ing is not supported. Returns an
 * unaligned address (which is OK on x86).
 *
 * TODO(pts): Rewrite it in assembly, size-optimize it.
 */
void *malloc(size_t size) {
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
    new_heap_size = (end - base) << 1;
    grow_heap:
    if ((ssize_t)new_heap_size <= 0 || (size_t)base + new_heap_size < (size_t)base) return NULL;  /* Heap would be too large. */
    end = base + new_heap_size;
    if ((char*)sys_brk(end) != end) return NULL;  /* Out of memory. */
  }
  free += size;
  return free - size;
}

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

#define __NR_exit		  1
#define __NR_read		  3
#define __NR_write		  4
#define __NR_open		  5
#define __NR_close		  6
#define __NR_creat		  8
#define __NR_unlink		 10
#define __NR_lseek		 19
#define __NR_brk		 45

static int syscall1_inline(int nr, int arg1);
/*#pragma aux syscall1_inline = "int 80h"  "test eax, eax"  "jns short done"  "or eax, -1"  "done:"  value [ eax ] parm [ eax ] [ ebx ];*/
/* Gets the syscall number in ebx, for better inlining with the __watcall calling convention.
 * TODO(pts): Is there a way to unify the tail return (from "test eax, eax")? OpenWatcom seems to be smart if it generates the code.
 */
#pragma aux syscall1_inline = "xchg eax, ebx"  "int 80h"  "test eax, eax"  "jns short done"  "or eax, -1"  "done:"  value [ eax ] parm [ ebx ] [ eax ];

__declspec(aborts) static int syscall1_noreturn_inline(int nr, int arg1);
#pragma aux syscall1_noreturn_inline = "xchg eax, ebx"  "int 80h"  value [ eax ] parm [ ebx ] [ eax ];

static int syscall2_inline(int nr, int arg1, int arg2);
#pragma aux syscall2_inline = "xchg eax, ebx" "int 80h"  "test eax, eax"  "jns short done"  "or eax, -1"  "done:"  value [ eax ] parm [ ebx ] [ eax ] [ ecx ];

static int syscall3_inline(int nr, int arg1, int arg2, int arg3);
#pragma aux syscall3_inline = "xchg eax, ebx"  "int 80h"  "test eax, eax"  "jns short done"  "or eax, -1"  "done:"  value [ eax ] parm [ ebx ] [ eax ] [ ecx ] [ edx ];

void *sys_brk(void *addr) { return (void*)syscall1_inline(__NR_brk, (int)addr); }

__declspec(aborts) static void exit_inline(int status);
#pragma aux exit_inline = "xchg eax, ebx"  "xor eax, eax"  "inc eax"  "int 80h"  parm [ eax ];

__declspec(aborts) void exit(int status) {
#if 1
  exit_inline(status);
#else
  syscall1_noreturn_inline(__NR_exit, status);  /* 4 bytes longer than exit_inline(...). */
#endif
}

int unlink(const char *pathname) { return syscall1_inline(__NR_unlink, (int)pathname); }
#define remove(pathname) unlink(pathname)

/* This would work, but OpenWatcom generates suboptimal code (with lots of stack pushes) for this. */
int open3(const char *pathname, int flags, int mode) { return syscall3_inline(__NR_open, (int)pathname, flags, mode); }
/* Without this renaming, OpenWatcom generates suboptimal code (with lots of stack pushes) for this. Why? Because of the hidden `...' in the function prototype? */
#define open(pathname, flags, mode) open3(pathname, flags, mode)

#ifdef _IO_H_INCLUDED  /* OpenWatcom <io.h> has `unsigned short' type for `mode' below. */
/* This has a `movzx' instead of a `mov' (1 byte longer). */
int creat(const char *pathname, unsigned short mode) { return syscall2_inline(__NR_creat, (int)pathname, mode); }
#else
int creat(const char *pathname, int mode) { return syscall2_inline(__NR_creat, (int)pathname, mode); }
#endif

ssize_t read(int fd, void *buf, size_t count) { return syscall3_inline(__NR_read, fd, (int)buf, count); }

ssize_t write(int fd, const void *buf, size_t count) { return syscall3_inline(__NR_write, fd, (int)buf, count); }

off_t lseek(int fd, off_t offset, int whence) { return syscall3_inline(__NR_lseek, fd, offset, whence); }

int close(int fd) { return syscall1_inline(__NR_close, fd); }

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
#include "mininasm.c"
