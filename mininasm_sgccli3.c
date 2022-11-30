/* --- Based on https://github.com/pts/minilibc32/blob/2049e5ecf169d2fed196309adb1c859563c9e386/libc.h
 *
 * It's for targeting Linux i386 with GCC only.
 */

#if defined(__GNUC__) && !defined(__WATCOMC__) && defined(__i386__)
#else
#  error Unsupported libc target.
#endif

#define __LIBC_CALL __attribute__((regparm(3)))
#define __LIBC_FUNC(name, args) __LIBC_CALL name args __asm__(#name "__RP3__")
#define __LIBC_NORETURN __attribute__((noreturn, nothrow))

#define open open3  /* Avoid using the OpenWatcom C compiler using the `...' form. TODO(pts): Rename assembly symbols in OpenWatcom. */

#ifdef __WATCOMC__
#define main main_from_libc  /* TODO(pts): Rename at assembler level, add symbol alias here. For OpenWatcom. */
extern int __LIBC_CALL main(int argc, char **argv);
#endif

#define NULL ((void*)0)

#define SEEK_SET 0  /* whence value below. */
#define SEEK_CUR 1
#define SEEK_END 2

#define O_RDONLY 0  /* flags bitfield value below. */
#define O_WRONLY 1
#define O_RDWR   2

#define STDIN_FILENO  0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2

#define EXIT_SUCCESS 0  /* status values below. Can be 0..255. */
#define EXIT_FAILURE 1

typedef unsigned size_t;
typedef int ssize_t;
typedef unsigned mode_t;
typedef long off_t;  /* Not implemented: 64-bit off_t (#define _FILE_OFFSET_BITS 64), off64_r, lseek64(2). */

/* --- <stdarg.h> */

typedef char *va_list;  /* i386 only. */
#define va_start(ap, last) ap = ((char *)&(last)) + ((sizeof(last)+3)&~3)  /* i386 only. */
#define va_arg(ap, type) (ap += (sizeof(type)+3)&~3, *(type *)(ap - ((sizeof(type)+3)&~3)))  /* i386 only. */
#define va_copy(dest, src) (dest) = (src)  /* i386 only. */
#define va_end(ap)  /* i386 only. */

/* --- <ctype.h> */

extern int __LIBC_FUNC(isalpha, (int c));
extern int __LIBC_FUNC(isspace, (int c));
extern int __LIBC_FUNC(isdigit, (int c));
extern int __LIBC_FUNC(isxdigit, (int c));

/* --- <string.h> */

extern size_t __LIBC_FUNC(strlen, (const char *s));
extern char* __LIBC_FUNC(strcpy, (char *dest, const char *src));
extern int __LIBC_FUNC(strcmp, (const char *s1, const char *s2));
extern void* __LIBC_FUNC(memcpy, (void *dest, const void *src, size_t n));

/* --- <stdlib.h> */

extern void* __LIBC_FUNC(malloc, (size_t size));
extern __LIBC_NORETURN void __LIBC_FUNC(exit, (int status));

/* --- <fcntl.h> and <unistd.h> */
extern void* __LIBC_FUNC(sys_brk, (void *addr));
/**/
extern int __LIBC_FUNC(creat, (const char *pathname, mode_t mode));
extern int __LIBC_FUNC(open, (const char *pathname, int flags, mode_t mode));
extern int __LIBC_FUNC(close, (int fd));
/**/
extern ssize_t __LIBC_FUNC(read, (int fd, void *buf, size_t count));
extern ssize_t __LIBC_FUNC(write, (int fd, const void *buf, size_t count));
extern off_t __LIBC_FUNC(lseek, (int fd, off_t offset, int whence));
/**/
extern int __LIBC_FUNC(unlink, (const char *pathname));
extern int __LIBC_FUNC(remove, (const char *pathname));  /* Same as unlink(...). */
extern int __LIBC_FUNC(rename, (const char *oldpath, const char *newpath));

#define open2(pathname, flags) open(pathname, flags, 0)

/* --- Based on https://github.com/pts/minilibc32/blob/2049e5ecf169d2fed196309adb1c859563c9e386/minilibc32.s */

/* Labels starting with .L aren't saved by GNU as to the .o file. GCC
 * generates labels with .L<num>, we generate .LA<num> to avoid conflicts.
 */
__asm__(
".globl isalpha__RP3__\n"
".type  isalpha__RP3__, @function\n"
"isalpha__RP3__:\n"
"		or $0x20, %al\n"
"		sub $0x61, %al\n"
"		cmp $0x1a, %al\n"
"		sbb %eax, %eax\n"
"		neg %eax\n"
"		ret\n"
"\n"
".globl isspace__RP3__\n"
".type  isspace__RP3__, @function\n"
"isspace__RP3__:\n"
"		sub $9, %al\n"
"		cmp $5, %al\n"
"		jb .LA1\n"
"		sub $0x17, %al\n"
"		cmp $1, %al\n"
".LA1:		sbb %eax, %eax\n"
"		neg %eax\n"
"		ret\n"
"\n"
".globl isdigit__RP3__\n"
".type  isdigit__RP3__, @function\n"
"isdigit__RP3__:\n"
"		sub $0x30, %al\n"
"		cmp $0x0a, %al\n"
"		sbb %eax, %eax\n"
"		neg %eax\n"
"		ret\n"
"\n"
".globl isxdigit__RP3__\n"
".type  isxdigit__RP3__, @function\n"
"isxdigit__RP3__:\n"
"		sub $0x30, %al\n"
"		cmp $0x0a, %al\n"
"		jb .LA2\n"
"		or $0x20, %al\n"
"		sub $0x31, %al\n"
"		cmp $6, %al\n"
".LA2:		sbb %eax, %eax\n"
"		neg %eax\n"
"		ret\n"
"\n"
".globl strlen__RP3__\n"
".type  strlen__RP3__, @function\n"
"strlen__RP3__:\n"
"		push %esi\n"
"		xchg %esi, %eax\n"
"		xor %eax, %eax\n"
"		dec %eax\n"
".LA3:		cmpb $1, (%esi)\n"
"		inc %esi\n"
"		inc %eax\n"
"		jae .LA3\n"
"		pop %esi\n"
"		ret\n"
"\n"
".globl strcpy__RP3__\n"
".type  strcpy__RP3__, @function\n"
"strcpy__RP3__:\n"
"		push %edi\n"
"		xchg %edx, %esi\n"
"		xchg %edi, %eax\n"
"		push %edi\n"
".LA4:		lodsb\n"
"		stosb\n"
"		cmp $0, %al\n"
"		jne .LA4\n"
"		pop %eax\n"
"		xchg %edx, %esi\n"
"		pop %edi\n"
"		ret\n"
"\n"
".globl strcmp__RP3__\n"
".type  strcmp__RP3__, @function\n"
"strcmp__RP3__:\n"
"		push %esi\n"
"		xchg %esi, %eax\n"
"		xor %eax, %eax\n"
"		xchg %edx, %edi\n"
".LA5:		lodsb\n"
"		scasb\n"
"		jne .LA6\n"
"		cmp $0, %al\n"
"		jne .LA5\n"
"		jmp .LA7\n"
".LA6:		mov $1, %al\n"
"		jae .LA7\n"
"		neg %eax\n"
".LA7:		xchg %edx, %edi\n"
"		pop %esi\n"
"		ret\n"
"\n"
".globl memcpy__RP3__\n"
".type  memcpy__RP3__, @function\n"
"memcpy__RP3__:\n"
"		push %edi\n"
"		xchg %edx, %esi\n"
"		xchg %eax, %edi\n"
"		push %edi\n"
"		rep movsb\n"
"		pop %eax\n"
"		xchg %edx, %esi\n"
"		pop %edi\n"
"		ret\n"
"\n"
".globl sys_brk__RP3__\n"
".type  sys_brk__RP3__, @function\n"
"sys_brk__RP3__:\n"
"		push $45\n"
"		jmp __do_syscall3\n"
"\n"
".globl unlink__RP3__\n"
".type  unlink__RP3__, @function\n"
"unlink__RP3__:\n"
"\n"
".globl remove__RP3__\n"
".type  remove__RP3__, @function\n"
"remove__RP3__:\n"
"		push $10\n"
"		jmp __do_syscall3\n"
"\n"
".globl close__RP3__\n"
".type  close__RP3__, @function\n"
"close__RP3__:\n"
"		push $6\n"
"		jmp __do_syscall3\n"
"\n"
".globl creat__RP3__\n"
".type  creat__RP3__, @function\n"
"creat__RP3__:\n"
"		push $8\n"
"		jmp __do_syscall3\n"
"\n"
".globl open__RP3__\n"
".type  open__RP3__, @function\n"
"open__RP3__:\n"
"\n"
".globl open3__RP3__\n"
".type  open3__RP3__, @function\n"
"open3__RP3__:\n"
"		push $5\n"
"		jmp __do_syscall3\n"
"\n"
".globl read__RP3__\n"
".type  read__RP3__, @function\n"
"read__RP3__:\n"
"		push $3\n"
"		jmp __do_syscall3\n"
"\n"
".globl lseek__RP3__\n"
".type  lseek__RP3__, @function\n"
"lseek__RP3__:\n"
"		push $19\n"
"		jmp __do_syscall3\n"
"\n"
".globl write__RP3__\n"
".type  write__RP3__, @function\n"
"write__RP3__:\n"
"		push $4\n"
"		jmp __do_syscall3\n"
"\n"
".globl _start\n"
".type  _start, @function\n"
"_start:\n"
"		pop %eax\n"
"		mov %esp, %edx\n"
"		push %edx\n"
"		push %eax\n"
".extern main  /* Optional. */\n"
"		call main\n"
"/* Fall through to exit(...). */\n"
"\n"
".globl exit__RP3__\n"
".type  exit__RP3__, @function\n"
"exit__RP3__:\n"
"		push $1\n"
"__do_syscall3:\n"
"		xchg (%esp), %ebx\n"
"		xchg %ebx, %eax\n"
"		xchg %edx, %ecx\n"
"		push %edx\n"
"		push %ecx\n"
"		int $0x80\n"
"		test %eax, %eax\n"
"		jns .LA8\n"
"		or $-1, %eax\n"
".LA8:		pop %ecx\n"
"		pop %edx\n"
"		pop %ebx\n"
"		ret\n"
);

/* --- */

#define open2(pathname, flags) open(pathname, flags, 0)

/* TODO(pts): Add memcpy_void_inline and memcpy_newdest_inline, to match to size improvements from mininasm_sgwatli.c. */

#define CONFIG_SKIP_LIBC 1
#define CONFIG_SKIP_STDARG 1
#define CONFIG_MALLOC_FAR_USING_SYS_BRK 1
#include "mininasm.c"
