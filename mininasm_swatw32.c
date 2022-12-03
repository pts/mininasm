/*
 * mininasm_swatw32.c: OpenWatcom Win32 port of mininasm, without the OpenWatcom libc
 * by pts@fazekas.hu at Fri Nov 25 21:41:31 CET 2022
 *
 # Compile without: owcc -bwin32 -Wl,runtime -Wl,console=3.10 -o mininasm.win32.exe -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm.c nouser32.c && ls -ld mininasm.win32.exe
 * Compile: owcc -bwin32 -fnostdlib -Wl,option -Wl,start=_mainCRTStartup -Wl,runtime -Wl,console=3.10 -o mininasm.swatw32.exe -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm_swatw32.c && ls -ld mininasm.swatw32.exe
 *
 * TODO(pts): Rewrite malloc_far(...) in mininasm.c in i386 assembly, size-optimize it.
 * TODO(pts): Define custom calling convention for all the non-inline functions, so that the xchgs are not needed.
 */

#ifndef __WATCOMC__
#  error Watcom C compiler required.
#endif

#ifndef _WIN32
#  error Windows target required.
#endif

#ifndef _M_I386
#  error 32-bit intel target required.
#endif

/* All routines below are optimized for program file size. */

/* --- typedefs and constants. */

/*#include <windows.h>*/  /* Too much, also loads <ctype.h> etc. */

typedef unsigned long   ULONG;
typedef ULONG           *PULONG;
typedef unsigned short  USHORT;
typedef USHORT          *PUSHORT;
typedef unsigned char   UCHAR;
typedef UCHAR           *PUCHAR;
typedef char            *PSZ;
typedef unsigned long   DWORD;
typedef int             BOOL;
typedef unsigned char   BYTE;
typedef unsigned short  WORD;
typedef float           FLOAT;
typedef FLOAT           *PFLOAT;
typedef BOOL            *PBOOL;
typedef BOOL            *LPBOOL;
typedef BYTE            *PBYTE;
typedef BYTE            *LPBYTE;
typedef int             *PINT;
typedef int             *LPINT;
typedef WORD            *PWORD;
typedef WORD            *LPWORD;
typedef long            *LPLONG;
typedef DWORD           *PDWORD;
typedef DWORD           *LPDWORD;
typedef void            *LPVOID;
typedef const void      *LPCVOID;
typedef int             INT;
typedef unsigned int    UINT;
typedef unsigned int    *PUINT;
typedef void                *PVOID;
typedef void                *PVOID64;
typedef char                CHAR;
typedef short               SHORT;
typedef long                LONG;
typedef SHORT               *PSHORT;
typedef LONG                *PLONG;
typedef void                *HANDLE;
typedef HANDLE              *PHANDLE;
typedef BYTE                FCHAR;
typedef WORD                FSHORT;
typedef DWORD               FLONG;
typedef LONG                HRESULT;
typedef char                CCHAR;
typedef DWORD               LCID;
typedef PDWORD              PLCID;
typedef CHAR        *LPSTR;
typedef const CHAR  *LPCSTR;
typedef unsigned short wchar_t;
typedef wchar_t                 WCHAR;
typedef WCHAR                   *LPWSTR;
typedef long            LONG_PTR;

typedef struct _OVERLAPPED  *LPOVERLAPPED;
typedef struct _SECURITY_ATTRIBUTES *LPSECURITY_ATTRIBUTES;

/* kernel32.dll, <windows.h> */
/* TODO(pts): Write alternative implementation which uses UTF-8 and the *W(...) APIs with WTF-8 encoding: https://nullprogram.com/blog/2022/02/18/ */
/*__declspec(aborts)!!*/ __declspec(dllimport) void __stdcall ExitProcess(UINT uExitCode);
__declspec(dllimport) HANDLE __stdcall GetStdHandle(DWORD nStdHandle);
__declspec(dllimport) BOOL   __stdcall WriteFile(HANDLE hFile, LPCVOID lpBuffer, DWORD nNumberOfBytesToWrite, LPDWORD lpNumberOfBytesWritten, LPOVERLAPPED lpOverlapped);
__declspec(dllimport) BOOL   __stdcall ReadFile(HANDLE hFile, LPVOID lpBuffer, DWORD nNumberOfBytesToRead, LPDWORD lpNumberOfBytesRead, LPOVERLAPPED lpOverlapped);
__declspec(dllimport) LPSTR  __stdcall GetCommandLineA(void);
/*__declspec(dllimport) LPWSTR __stdcall GetCommandLineW(void);*/
__declspec(dllimport) BOOL   __stdcall DeleteFileA(LPCSTR lpFileName);
__declspec(dllimport) BOOL   __stdcall CloseHandle(HANDLE hObject);
__declspec(dllimport) DWORD  __stdcall SetFilePointer(HANDLE hFile, LONG lDinstanceToMove, PLONG *lpDistanceToMoveHigh, DWORD dwMoveMethod);
__declspec(dllimport) BOOL   __stdcall MoveFileExA(LPCSTR lpExistingFileName, LPCSTR lpNewFileName, DWORD dwFlags);
__declspec(dllimport) HANDLE __stdcall CreateFileA(LPCSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);

#if 0  /* Not needed by mininasm. */
__declspec(dllimport) BOOL   __stdcall CreateDirectoryA(LPCSTR lpPathName, LPSECURITY_ATTRIBUTES lpSecurityAttributes);
__declspec(dllimport) BOOL   __stdcall RemoveDirectoryA(LPCSTR lpPathName);
__declspec(dllimport) BOOL   __stdcall SetCurrentDirectoryA(LPCSTR lpPathName);
__declspec(dllimport) DWORD  __stdcall GetCurrentProcessId(void);
#endif

/* nStdHandle for GetStdHandle(...): */
#define STD_INPUT_HANDLE    ((DWORD)-10)
#define STD_OUTPUT_HANDLE   ((DWORD)-11)
#define STD_ERROR_HANDLE    ((DWORD)-12)

#define INVALID_HANDLE_VALUE ((HANDLE)(LONG_PTR)-1)

/* deDesiredAccess for CreateFileA(...) (bitfield): */
#define GENERIC_READ  0x80000000L
#define GENERIC_WRITE 0x40000000L
/*
#define FILE_READ_DATA              0x0001L 
#define FILE_WRITE_DATA             0x0002L
#define FILE_APPEND_DATA            0x0004L  // WDOSX and MWPESTUB don't support it.
*/

/* dwCreationDisposition for CreateFileA(...): */
#define CREATE_NEW          1L
#define CREATE_ALWAYS       2L
#define OPEN_EXISTING       3L
#define OPEN_ALWAYS         4L
#define TRUNCATE_EXISTING   5L

/* dwFlagsAndAttributes for CreateFileA(...): */
#define FILE_ATTRIBUTE_NORMAL 0x00000080L

/* dwShareMode for CreateFileA(...) (bitfield): */
#define FILE_SHARE_READ     0x00000001L 
#define FILE_SHARE_WRITE    0x00000002L
#define FILE_SHARE_DELETE   0x00000004L

/* dwFlags for MoveFileExA(...): */
#define MOVEFILE_REPLACE_EXISTING 0x00000001L
#define MOVEFILE_COPY_ALLOWED     0x00000002L

/* dwMoveMethod for SetFilePointer(...):
#define FILE_BEGIN 0    // Same as SEEK_SET.
#define FILE_CURRENT 1  // Same as SEEK_CUR.
#define FILE_END 2      // Same as SEEK_END.
#define INVALID_SET_FILE_POINTER    0xFFFFFFFFL  // Same as -1 error indicator.
*/

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
#define O_CREAT 0100  /* Linux-specific. */
#define O_TRUNC 01000  /* Linux-specific. */

typedef unsigned size_t;
typedef int ssize_t;
typedef long off_t;  /* !! TODO(pts): Use 64-bit file offset (#define _FILE_OFFSET_BITS 64) in lseek(2). */

#undef O_BINARY

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

/* --- Unix system calls implemented using Win32 kernel32.dll functions.
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

typedef int pid_t;

#if 1
#define exit ExitProcess
#else
__declspec(aborts) LIBC_STATIC void exit(int status) {
  ExitProcess(status);
}
#endif

LIBC_STATIC HANDLE __libc_std_fd_handles[3];

LIBC_STATIC HANDLE __fd_to_handle(int fd) {
  if ((unsigned)fd < 3U) {  /* Use __libc_std_fd_handles. */
    /* !! TODO(pts): Can a valid HANDLE be NULL? */
    HANDLE h = (HANDLE)((char*)__libc_std_fd_handles[fd] - 1);  /* 0 (by default) becomes INVALID_HANDLE_VALUE (-1) */
    if (h == INVALID_HANDLE_VALUE) __libc_std_fd_handles[fd] = (HANDLE)((char*)(h = GetStdHandle((DWORD)(-10 - fd))) + 1);  /* STD_INPUT_HANDLE, STD_OUTPUT_HANDLE, STD_ERROR_HANDLE. */
    return h;
  }
  /* TODO(pts): Provide low fd values (3 .. 19) for ~20 open files. */
  return (HANDLE)((unsigned)fd - 3);
}

LIBC_STATIC int open2(const char *pathname, int flags) {
  /* mode_t mode, the 3rd argument of open3(...), would be ignored here. */
  static unsigned char desired_access_table[4] = { GENERIC_READ >> 24 /* O_RDONLY */, GENERIC_WRITE >> 24 /* O_WRONLY */, (GENERIC_READ | GENERIC_WRITE) >> 24 /* O_RDWR */, 0 };
  const DWORD dwCreationDisposition = (flags & O_CREAT) ?  /* TODO(pts): Write this shorter in assembly language. */
      ((flags & O_TRUNC) ? CREATE_ALWAYS : OPEN_ALWAYS) :
      ((flags & O_TRUNC) ? TRUNCATE_EXISTING : OPEN_EXISTING);
  /* Returns INVALID_HANDLE_VALUE (-1) on error, which is exactly what we
   * need if the caller checks for `== -1' rather than `< 0'. Hence we
   * define CONFIG_CAN_FD_BE_NEGATIVE.
   */
  return (int)CreateFileA(pathname, desired_access_table[flags & 3] << 24, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, dwCreationDisposition, FILE_ATTRIBUTE_NORMAL, NULL) + 3;
}
#define CONFIG_CAN_FD_BE_NEGATIVE 1
/* Without this renaming, OpenWatcom generates suboptimal code (with lots of stack pushes) for this. Why? Because of the hidden `...' in the function prototype? */
#define open(pathname, flags, mode) open2(pathname, flags)

/* On Linux, equivalent to O_CREAT|O_WRONLY|O_TRUNC. */
LIBC_STATIC int creat(const char *pathname, mode_t mode) {
  (void)mode;
  return open2(pathname, O_CREAT | O_WRONLY | O_TRUNC);
}

LIBC_STATIC int close(int fd) {
  return CloseHandle(__fd_to_handle(fd)) - 1;
  }

LIBC_STATIC ssize_t read(int fd, void *buf, size_t count) {
  DWORD read_count;
  return ReadFile(__fd_to_handle(fd), buf, count, &read_count, NULL) ? read_count : -1;
}

LIBC_STATIC ssize_t write(int fd, const void *buf, size_t count) {
  DWORD written_count;
  return WriteFile(__fd_to_handle(fd), buf, count, &written_count, NULL) ? written_count : -1;
}

LIBC_STATIC off_t lseek(int fd, off_t offset, int whence) {
  /* whence and result (-1 on error) are both correct. */
  return SetFilePointer(__fd_to_handle(fd), offset, NULL, whence);
}

LIBC_STATIC int unlink(const char *pathname) {
  return DeleteFileA(pathname) - 1;
}
#define remove(pathname) unlink(pathname)

#if 0  /* Not needed by mininasm. */
LIBC_STATIC int rename(const char *oldpath, const char *newpath) {
  return MoveFileExA(oldpath, newpath, MOVEFILE_REPLACE_EXISTING) - 1;
}
LIBC_STATIC int chdir(const char *pathname) {
  return SetCurrentDirectoryA(pathname) - 1;
}
LIBC_STATIC int mkdir(const char *pathname, mode_t mode) {
  (void)mode;
  return CreateDirectoryA(pathname, NULL) - 1;
}
LIBC_STATIC int rmdir(const char *pathname) {
  return RemoveDirectoryA(pathname) - 1;
}
LIBC_STATIC pid_t getpid(void) {
  return GetCurrentProcessId();
}
#endif

#if 0
LIBC_STATIC void *sys_brk(void *addr) { return NULL; }  /* !! implement it */
#define CONFIG_MALLOC_FAR_USING_SYS_BRK 0
#endif

/* !!! No .bss is happening with: owcc -bwin32 -Wl,runtime -Wl,console=3.10 -o mininasm.swatw32.exe -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm_swatw32.c && ls -ld mininasm.swatw32.exe && cp -a mininasm.swatw32.exe s.exe */
/* !!! Use HeapAlloc(...). Or roll our own with VirtualAlloc? */
static char __libc_malloc_buf[1 << 16];  /* !!! Why does this .bss become part of the .exe by the OpenWatcom linker?? Also why not on Linux? */
static char *__libc_malloc_p = __libc_malloc_buf;

void *malloc(size_t size) {
  void *result;
  if (__libc_malloc_p + size > __libc_malloc_buf + sizeof(__libc_malloc_buf)) return 0;
  result = __libc_malloc_p;
  __libc_malloc_p += size;
  return result;
}

#define setmode(fd, mode) do {} while(0)

/* --- Startup code. */

/*static int __libc_argc;*/
static char *__libc_argv[512];  /* Uses 2048 bytes of memory. */

/* Parse command-line arguments to __libc_argc and __libc_argv.
 *
 * Similar to CommandLineToArgvW(...) in SHELL32.DLL, but doesn't aim for
 * 100% accuracy, especially that it doesn't support non-ASCII characters
 * beyond ANSI well, and that other implementations are also buggy (in
 * different ways).
 *
 * It treats only space and tab as whitespece (like the Wine version of
 * CommandLineToArgvA.c).
 *
 * This is based on the incorrect and incomplete description in:
 *  https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-commandlinetoargvw
 *
 * See https://nullprogram.com/blog/2022/02/18/ for a more detailed writeup
 * and a better installation.
 *
 * https://github.com/futurist/CommandLineToArgvA/blob/master/CommandLineToArgvA.c
 * has the 3*n rule, which Wine 1.6.2 doesn't seem to have. It also has special
 * parsing rules for argv[0] (the program name).
 *
 * There is the CommandLineToArgvW function in SHELL32.DLL available since
 * Windows NT 3.5 (not in Windows NT 3.1). For alternative implementations,
 * see:
 *
 * * https://github.com/futurist/CommandLineToArgvA
 *   (including a copy from Wine sources).
 * * http://alter.org.ua/en/docs/win/args/
 * * http://alter.org.ua/en/docs/win/args_port/
 */
static void __libc_parse_to_argv_and_argc(char *pw) {
  char **argvw = __libc_argv;  /* !! Check for overflow. */
  const char *p = pw;
  const char *q;
  char c;
  char is_quote = 0;
  /*__libc_argc = 0;*/  /* The caller should initialize it. */
  goto ignore_whitespace;
  for (;;) {
    if ((c = *p) == '\0') {
     after_arg:
      *pw++ = '\0';
     ignore_whitespace:
      for (; c = *p, c == ' ' || c == '\t'; ++p) {}
      if (c == '\0') break;
      /*++__libc_argc;*/
      *argvw++ = pw;
      if (argvw == __libc_argv + sizeof(__libc_argv) / sizeof(__libc_argv[0])) {  /* Next (or NULL) would overflow. */
        ExitProcess(250);  /* Indicate too many command-line arguments. */
      }
    } else {
      ++p;       
      if (c == '\\') {
        for (q = p; c = *q, c == '\\'; ++q) {}
        if (c == '"') {
          for (; p < q; p += 2) {
            *pw++ = '\\';
          }
          if (p != q) {
            is_quote ^= 1;
          } else {
            *pw++ = '"';
            ++p;  /* Skip over the '"'. */
          }
        } else {
          *pw++ = '\\';
          for (; p != q; ++p) {
            *pw++ = '\\';
          }
        }
      } else if (c == '"') {
        is_quote ^= 1;
      } else if (!is_quote && (c == ' ' || c == '\t')) {
        goto after_arg;
      } else {
        *pw++ = c;  /* Overwrite in-place. Subsequent calls to GetCommandLineA(...) will return garbage. !! Document it in the libc docs. */
      }
    }
  }
  *argvw = NULL;  /* Cannot overflow, already checked. */
}

#define CONFIG_MAIN_ARGV 1
extern int main_argv(char **argv);

__declspec(aborts) void __cdecl mainCRTStartup(void) {  /* !! why cdecl?? */
#if 0
  char *p;
  DWORD bw;
  HANDLE hfile = GetStdHandle(STD_OUTPUT_HANDLE);   
  write(2, "Foo\r\n", 5);
  WriteFile(hfile, "BOOT\r\n", 6, &bw, 0);
  ExitProcess(12);  /* Will exit with code 6 (!), rather than 12 with MWPESTUB. Strange. !!! report bug: declaring ExitProcess non-__declspec(aborts) fixes it (call becomes jmp) -- why?? what's wrong with our stack frame? */
#endif
  __libc_parse_to_argv_and_argc(GetCommandLineA());
  ExitProcess(main_argv(__libc_argv));
}

#define CONFIG_SKIP_LIBC 1
#include "mininasm.c"
