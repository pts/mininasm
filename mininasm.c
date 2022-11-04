/*
 ** mininasm: NASM-compatible mini assembler for 8086, able to run on DOS and on modern systems
 ** mininasm modifications by pts@fazekas.hu at Wed May 18 21:39:36 CEST 2022
 **
 ** based on Tinyasm by Oscar Toledo G, starting Oct/01/2019.
 **
 ** Compilation instructions (pick any one):
 **
 **   $ gcc -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o mininasm mininasm.c bbprintf.c && ls -ld mininasm
 **
 **   $ gcc -m32 -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o mininasm mininasm.c bbprintf.c && ls -ld mininasm.gcc32
 **
 **   $ g++ -ansi -pedantic -s -Os -W -Wall -o mininasm mininasm.c bbprintf.c && ls -ld mininasm
 **
 **   $ pts-tcc -s -O2 -W -Wall -o mininasm.tcc mininasm.c bbprintf.c && ls -ld mininasm.tcc
 **
 **   $ pts-tcc64 -m64 -s -O2 -W -Wall -o mininasm.tcc64 mininasm.c bbprintf.c && ls -ld mininasm.tcc64
 **
 **   $ dosmc -mt mininasm.c bbprintf.c && ls -ld mininasm.com
 **
 **   $ owcc -bdos -o mininasm.exe -mcmodel=c -Os -s -fstack-check -Wl,option -Wl,stack=1800 -march=i86 -W -Wall -Wextra mininasm.c bbprintf.c && ls -ld mininasm.exe
 **
 **   $ owcc -bwin32 -Wl,runtime -Wl,console=3.10 -o mininasm.win32.exe -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm.c bbprintf.c nouser32.c && ls -ld mininasm.win32.exe
 **
 **   $ i686-w64-mingw32-gcc -m32 -mconsole -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -march=i386 -o mininasm.win32msvcrt.exe mininasm.c bbprintf.c && ls -ld mininasm.win32msvcrt.exe
 **
 **   $ wine tcc.exe -m32 -mconsole -s -O2 -W -Wall -o mininasm.win32msvcrt_tcc.exe mininasm.c bbprintf.c && ls -ld mininasm.win32msvcrt_tcc.exe
 **
 */

#ifdef __TINYC__  /* Works with tcc, pts-tcc (Linux i386 target), pts-tcc64 (Linux amd64 target) and tcc.exe (Win32, Windows i386 target). */
#  if !defined(__i386__) /* && !defined(__amd64__)*/ && !defined(__x86_64__)
#    error tcc is supported only on i386 and amd64.  /* Because of ssize_t. */
#  endif
#  if (defined(_WIN32) && !defined(__i386)) || defined(_WIN64)
#    error Windows is supported only on i386.
#  endif
#  define ATTRIBUTE_NORETURN __attribute__((noreturn))
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
void ATTRIBUTE_NORETURN __cdecl exit(int status);
char *__cdecl strcpy(char *dest, const char *src);
int __cdecl strcmp(const char *s1, const char *s2);
char *__cdecl strcat(char *dest, const char *src);
void *__cdecl memcpy(void *dest, const void *src, size_t n);
int __cdecl memcmp(const void *s1, const void *s2, size_t n);
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
#  define open2(pathname, flags) open(pathname, flags)
#  ifdef _WIN32
#    define O_CREAT 0x100
#    define O_TRUNC 0x200
#    define O_BINARY 0x8000
#    define creat(filename, mode) open(filename, O_CREAT | O_TRUNC | O_WRONLY | O_BINARY, 0)  /* 0 to prevent Wine warning: fixme:msvcrt:MSVCRT__wsopen_s : pmode 0x406b9b ignored.  */
int __cdecl setmode(int _FileHandle,int _Mode);
#  endif
#else
#  ifdef __DOSMC__
#    include <dosmc.h>  /* strcpy_far(...), strcmp_far(...) etc. */
#  else /* Standard C. */
#    include <ctype.h>
#    include <fcntl.h>  /* open(...), O_BINARY. */
#    include <stdio.h>  /* remove(...) */
#    include <stdlib.h>
#    include <string.h>
#    if defined(_WIN32) || defined(_WIN64) || defined(MSDOS)  /* tcc.exe with Win32 target doesn't have <unistd.h>. For `owcc -bdos' and `owcc -bwin32', both <io.h> and <unistd.h> works. */
#      include <io.h>  /* setmode(...) */
#      define creat(filename, mode) open(filename, O_CREAT | O_TRUNC | O_WRONLY | O_BINARY, 0)  /* 0 to prevent Wine msvcrt.dll warning: `fixme:msvcrt:MSVCRT__wsopen_s : pmode 0x406b9b ignored.'. Also works with `owcc -bwin32' (msvcrtl.dll) and `owcc -bdos'. */
#    else
#      include <unistd.h>
#    endif
#    define open2(pathname, flags) open(pathname, flags)
#  endif
#endif

#ifndef O_BINARY  /* Unix. */
#define O_BINARY 0
#endif

#if !__SIZEOF_INT__  /* GCC has it, tried with GCC 4.8. */
#undef __SIZEOF_INT__
#ifdef __WATCOMC__
#ifdef _M_I86  /* OpenWatcom only defines this for 16-bit targets, e.g. `owcc -bdos', but not for `owcc -bwin32'. */
#define __SIZEOF_INT__ 2  /* Example: __DOSMC__. */
#else
#define __SIZEOF_INT__ 4
#endif
#ifdef _M_I386  /* OpenWatcom only defines this for 32-bit (and maybe 64-bit?) targets, e.g. `owcc -bwin32', but not for `owcc -bdos'. */
#endif
#else  /* Else __WATCOMC__. */
#ifdef _M_I86
#define __SIZEOF_INT__ 2
#else
#if defined(__TINYC__) && defined(__x86_64__)
#define __SIZEOF_INT__ 4
#else
#if defined(__linux) || defined(__i386__) || defined(__i386) || defined(__linux__) || defined(_WIN32)  /* For __TINYC__. */
#define __SIZEOF_INT__ 4
#endif
#endif
#endif
#endif  /* __WATCOMC__ */
#endif  /* !__SIZEOF_INT__ */

#if !defined(CONFIG_CPU_UNALIGN)
#if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__) || defined(_M_IX86) || defined(__i386__)
#define CONFIG_CPU_UNALIGN 1  /* CPU supports unaligned memory access. i386 and amd64 do, arm and arm64 don't.  */
#else
#define CONFIG_CPU_UNALIGN 0
#endif
#endif

#if !defined(CONFIG_SHIFT_OK_31)
#if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__) || defined(_M_IX86) || defined(__i386__)
#define CONFIG_SHIFT_OK_31 1  /* `x << 31' and `x >> 31' works in C. */
#else
#define CONFIG_SHIFT_OK_31 0
#endif
#endif

#ifndef CONFIG_BALANCED
#define CONFIG_BALANCED 1
#endif

#ifndef CONFIG_DOSMC_PACKED
#ifdef __DOSMC__
#define CONFIG_DOSMC_PACKED 1
#else
#define CONFIG_DOSMC_PACKED 0
#endif
#endif

#ifdef __DOSMC__
#if CONFIG_BALANCED
__LINKER_FLAG(stack_size__0x200)  /* Extra memory needed by balanced_tree_insert. */
#endif
__LINKER_FLAG(stack_size__0x180)  /* Specify -sc to dosmc, and run it to get the `max st:HHHH' value printed, and round up 0xHHHH to here. Typical value: 0x134. */
/* Below is a simple malloc implementation using an arena which is never
 * freed. Blocks are rounded up to paragraph (16-byte) boundary.
 */
#ifndef __MOV_AX_PSP_MCB__
#error Missing __MOV_AX_PSP_MCB__, please compile .c file with dosmc directly.
#endif
struct {
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
#define MY_FAR far
/* strcpy_far(...) and strcmp_far(...) are defined in <dosmc.h>. */
#else  /* CONFIG_DOSMC. */
#define MY_FAR
#define strcpy_far(dest, src) strcpy(dest, src)
#define strcmp_far(s1, s2) strcmp(s1, s2)
#define malloc_far(size) malloc(size)
#define malloc_init() do {} while (0)
#if CONFIG_DOSMC_PACKED
#error CONFIG_DOSMC_PACKED needs __DOSMC__.
#endif
#endif  /* Else CONFIG_DOSMC. */

#include "bbprintf.h"

/* Example usage:
 * static const STRING_WITHOUT_NUL(msg, "Hello, World!\r\n$");
 * ... printmsgx(msg);
 */
#ifdef __cplusplus  /* We must reserve space for the NUL. */
#define MY_STRING_WITHOUT_NUL(name, value) char name[sizeof(value)] = value
#else
#define MY_STRING_WITHOUT_NUL(name, value) char name[sizeof(value) - 1] = value
#endif

/* We aim for compatibility with NASM 0.98.39, so we do signed by default.
 * Signed (sign-extended): NASM 0.99.06, Yasm 1.2.0, Yasm, 1.3.0.
 * Unsigned (zero-extended): NASM 0.98.39, NASM 2.13.02.
 */
#ifndef CONFIG_SHIFT_SIGNED
#define CONFIG_SHIFT_SIGNED 0
#endif

#define DEBUG

char *output_filename;
int output_fd;

char *listing_filename;
int listing_fd = -1;

#ifndef CONFIG_VALUE_BITS
#define CONFIG_VALUE_BITS 32
#endif

#undef IS_VALUE_LONG
#if CONFIG_VALUE_BITS == 16
#define IS_VALUE_LONG 0
typedef short value_t;  /* At least CONFIG_VALUE_BITS bits, preferably exactly. */
typedef unsigned short uvalue_t;  /* At least CONFIG_VALUE_BITS bits, preferably exactly. */
#define GET_VALUE(value) (value_t)(sizeof(short) == 2 ? (short)(value) : (short)(((short)(value) & 0x7fff) | -((short)(value) & 0x8000U)))  /* Sign-extended. */
#define GET_UVALUE(value) (uvalue_t)(sizeof(unsigned short) == 2 ? (unsigned short)(value) : (unsigned short)(value) & 0xffffU)
#else
#if CONFIG_VALUE_BITS == 32
#if __SIZEOF_INT__ >= 4
#define IS_VALUE_LONG 0
typedef int value_t;
typedef unsigned uvalue_t;
#else  /* sizeof(long) >= 4 is guaranteed by the C standard. */
#define IS_VALUE_LONG 1
typedef long value_t;
typedef unsigned long uvalue_t;
#endif
#define GET_VALUE(value) (value_t)(sizeof(value_t) == 4 ? (value_t)(value) : sizeof(int) == 4 ? (value_t)(int)(value) : sizeof(long) == 4 ? (value_t)(long)(value) : (value_t)(((long)(value) & 0x7fffffffL) | -((long)(value) & 0x80000000UL)))
#define GET_UVALUE(value) (uvalue_t)(sizeof(uvalue_t) == 4 ? (uvalue_t)(value) : sizeof(unsigned) == 4 ? (uvalue_t)(unsigned)(value) : sizeof(unsigned long) == 4 ? (uvalue_t)(unsigned long)(value) : (uvalue_t)(value) & 0xffffffffUL)
#else
#error CONFIG_VALUE_BITS must be 16 or 32.
#endif
#endif
typedef char assert_value_size[sizeof(value_t) * 8 >= CONFIG_VALUE_BITS];

uvalue_t line_number;

int assembler_step;  /* !! Change many variables from int to char. */
value_t default_start_address;
value_t start_address;
value_t address;
int first_time;

unsigned char instruction_addressing;
unsigned char instruction_offset_width;
value_t instruction_offset;

unsigned char instruction_register;

value_t instruction_value;

#define MAX_SIZE        256

char part[MAX_SIZE];
char expr_name[MAX_SIZE];
char global_label[MAX_SIZE];

char *g;
char generated[8];

uvalue_t errors;
uvalue_t warnings;  /* !! remove this, currently there are no possible warnings */
uvalue_t bytes;
int change;
int change_number;

#if CONFIG_DOSMC_PACKED
_Packed  /* Disable extra aligment byte at the end of `struct label'. */
#endif
struct label {
#if CONFIG_DOSMC_PACKED
    /* The fields .left_right_ofs, .left_seg and .right_seg together contain
     * 2 far pointers (tree_left and tree_right) and (if CONFIG_BALANCED is
     * true) the tree_red bit. .left_seg contains the 16-bit segment part of
     * tree_left, and .right_seg contains the 16-bit segment part of
     * tree_right. .left_right_ofs contains the offset of the far pointers
     * and the tree_red bit. It is assumed that far pointer offsets are 4
     * bits wide (0 <= offset <= 15), because malloc_far guarantees it
     * (with its and `and ax, 0fh' instruction).
     *
     * If CONFIG_BALANCED is false, bits of .left_right_ofs look like
     * LLLLRRRR, where LLLL is the 4-bit offset of tree_left, and RRRR is the
     * 4-bit offset of tree_right.
     *
     * If CONFIG_BALANCED is true, bits of .left_right_ofs look like
     * LLL1RRRE, where LLLM is the 4-bit offset of tree_left, RRRS is the
     * 4-bit offset of tree_right, 1 is 1, E is the tree_red bit value.
     * The lower M and S bits of the offsets are not stored, but they will
     * be inferred like below. The pointer with the offset LLL0 is either
     * correct or 1 less than the correct LLL1. If it's correct, then it points
     * to a nonzero .left_right_ofs (it has a 1 bit). If it's 1 less, then it
     * points to the all-zero NUL byte (the NUL terminator of the name in the
     * previous label). Thus by comparing the byte at offset LLL0 to zero,
     * we can infer whether M is 0 or 1. For this to work we
     * need that the very first struct label starts at an even offset; this
     * is guaranteed by malloc_far.
     */
    unsigned char left_right_ofs;
    unsigned left_seg, right_seg;
#else
    struct label MY_FAR *tree_left;
    struct label MY_FAR *tree_right;
#endif
    value_t value;
#if CONFIG_BALANCED && !CONFIG_DOSMC_PACKED
    char tree_red;  /* Is it a red node of the red-black tree? */
#endif
    char name[1];
};

struct label MY_FAR *label_list;
struct label MY_FAR *last_label;
int undefined;

extern const char instruction_set[];

/* [32] without the trailing \0 wouldn't work in C++. */
const char register_names[] = "ALCLDLBLAHCHDHBHAXCXDXBXSPBPSIDI";

extern struct bbprintf_buf message_bbb;

void message(int error, const char *message);
void message_start(int error);
void message_end(void);

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
#ifndef RB_LOG2_MAX_MEM_BYTES
#ifdef __DOSMC__
#define RB_LOG2_MAX_MEM_BYTES 20  /* 1 MiB. */
#else
#define RB_LOG2_MAX_MEM_BYTES (sizeof(void*) << 3)
#endif
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
typedef char assert_label_size[sizeof(struct label) == 5 /* left and right pointers, tree_red */ + sizeof(value_t) + 1 /* trailing NUL in ->name */];
#define RBL_IS_NULL(label) (FP_SEG(label) == 0)
#define RBL_IS_LEFT_NULL(label) ((label)->left_seg == 0)
#define RBL_IS_RIGHT_NULL(label) ((label)->right_seg == 0)
#if CONFIG_BALANCED
#define RBL_SET_LEFT_RIGHT_NULL(label) ((label)->left_right_ofs = 0x10, (label)->left_seg = (label)->right_seg = 0)
static struct label MY_FAR *RBL_GET_LEFT(struct label MY_FAR *label) {
    char MY_FAR *p = MK_FP((label)->left_seg, ((label)->left_right_ofs >> 4) & 0xe);
    if (*p == '\0') ++p;  /* Skip trailing NUL of previous label. */
    return (struct label MY_FAR*)p;
}
static struct label MY_FAR *RBL_GET_RIGHT(struct label MY_FAR *label) {
    char MY_FAR *p = MK_FP((label)->right_seg, (label)->left_right_ofs & 0xe);
    if (*p == '\0') ++p;  /* Skip trailing NUL of previous label. */
    return (struct label MY_FAR*)p;
}
static void RBL_SET_LEFT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
    label->left_seg = FP_SEG(ptr);
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
#define RBL_SET_LEFT_RIGHT_NULL(label) ((label)->left_right_ofs = (label)->left_seg = (label)->right_seg = 0)
static struct label MY_FAR *RBL_GET_LEFT(struct label MY_FAR *label) {
    char MY_FAR *p = MK_FP((label)->left_seg, (label)->left_right_ofs >> 4);
    return (struct label MY_FAR*)p;
}
static struct label MY_FAR *RBL_GET_RIGHT(struct label MY_FAR *label) {
    char MY_FAR *p = MK_FP((label)->right_seg, (label)->left_right_ofs & 0xf);
    return (struct label MY_FAR*)p;
}
static void RBL_SET_LEFT(struct label MY_FAR *label, struct label MY_FAR *ptr) {
    label->left_seg = FP_SEG(ptr);
    label->left_right_ofs = (label->left_right_ofs & 0x0f) | FP_OFF(ptr) << 4;  /* This assumes that 0 <= FP_OFF(ptr) <= 15. */
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
#define RBL_SET_LEFT_RIGHT_NULL(label) ((label)->tree_left = (label)->tree_right = NULL)
#define RBL_GET_LEFT(label) ((label)->tree_left)
#define RBL_GET_RIGHT(label) ((label)->tree_right)
#define RBL_SET_LEFT(label, ptr) ((label)->tree_left = (ptr))
#define RBL_SET_RIGHT(label, ptr) ((label)->tree_right = (ptr))
#if CONFIG_BALANCED
#define RBL_IS_RED(label) ((label)->tree_red)  /* Nonzero means true. */
#define RBL_COPY_RED(label, source_label) ((label)->tree_red = (source_label)->tree_red)
#define RBL_SET_RED_0(label) ((label)->tree_red = 0)
#define RBL_SET_RED_1(label) ((label)->tree_red = 1)
#endif  /* CONFIG_BALANCED. */
#endif  /* CONFIG_DOSMC_PACKED. */

/*
 ** Define a new label
 */
struct label MY_FAR *define_label(const char *name, value_t value) {
    struct label MY_FAR *label;

    /* Allocate label */
    label = (struct label MY_FAR*)malloc_far((size_t)&((struct label*)0)->name + 1 + strlen(name));
    if (RBL_IS_NULL(label)) {
        message(1, "Out of memory for label");
        exit(1);
        return NULL;
    }

    /* Fill label */
    RBL_SET_LEFT_RIGHT_NULL(label);
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
        static struct tree_path_entry path[RB_LOG2_MAX_NODES << 1];
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
 ** Find a label
 */
struct label MY_FAR *find_label(const char *name) {
    struct label MY_FAR *explore;
    int c;

    /* Follows a binary tree */
    explore = label_list;
    while (!RBL_IS_NULL(explore)) {
        c = strcmp_far(name, explore->name);
        if (c == 0)
            return explore;
        if (c < 0)
            explore = RBL_GET_LEFT(explore);
        else
            explore = RBL_GET_RIGHT(explore);
    }
    return NULL;
}

struct label MY_FAR *find_dollar_label(const char *name) {
    if (name[0] == '$') ++name;
    return find_label(name);
}

/*
 ** Print labels sorted to listing_fd (already done by binary tree).
 */
void print_labels_sorted_to_listing_fd(struct label MY_FAR *node) {
    struct label MY_FAR *pre;
    struct label MY_FAR *pre_right;
    /* Morris in-order traversal of binary tree: iterative (non-recursive,
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
            strcpy_far(global_label, node->name);
#if CONFIG_VALUE_BITS == 32
#if IS_VALUE_LONG
            bbprintf(&message_bbb, "%-20s %04x%04x\r\n", global_label, (unsigned)(GET_UVALUE(node->value) >> 16), (unsigned)(GET_UVALUE(node->value) & 0xffffu));
#else
            bbprintf(&message_bbb, "%-20s %08x\r\n", global_label, GET_UVALUE(node->value));
#endif
#else
            bbprintf(&message_bbb, "%-20s %04x\r\n", global_label, GET_UVALUE(node->value));
#endif
            node = RBL_GET_RIGHT(node);
        }
    }
}

/*
 ** Avoid spaces in input
 */
const char *avoid_spaces(const char *p) {
    for (; *p == ' '; p++) {}
    return p;
}

#ifndef CONFIG_MATCH_STACK_DEPTH
#define CONFIG_MATCH_STACK_DEPTH 100
#endif

/*
 ** Check for a non-first label character, same as in NASM.
 */
int islabel(int c) {
    return isalpha(c) || isdigit(c) || c == '_' || c == '.' || c == '@' || c == '?' || c == '$' || c == '~' || c == '#';
}

#if 0  /* Unused. */
/*
 ** Check for a first label character (excluding the leading '$' syntax), same as in NASM.
 */
int islabel1(int c) {
    return isalpha(c) || c == '_' || c == '.' || c == '@' || c == '?';
}
#endif

/*
 ** Returns NULL if not a label, otherwise after the label.
 */
const char *match_label_prefix(const char *p) {
    const char *p2;
    char c = *p++;
    if (c == '$') {
        c = *p++;
        if (isalpha(c)) goto goodc;
    } else if (isalpha(c)) {
        if (isalpha(p[0]) && !islabel(p[1])) {
            for (p2 = (char*)register_names; p2 != register_names + 32; p2 += 2) {
                if ((c & ~32) == p2[0] && (p[0] & ~32) == p2[1]) return NULL;  /* A register name is not a valid label name. */
            }
        }
        goto goodc;
    }
    if (c != '_' && c != '.' && c != '@' && c != '?') return NULL;
  goodc:
    for (; islabel(p[0]); ++p) {}
    return p;
}

/*
 ** Match expression at match_p, update (increase) match_p or set it to NULL on error.
 ** level == 0 is top tier, that's how callers should call it.
 ** Saves the result to `instruction_value'.
 */
const char *match_expression(const char *match_p) {
    static struct match_stack_item {
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
        struct label MY_FAR *label;
    /*} u;*/
    char c;
    unsigned char level;

    level = 0;
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
            message(1, "Missing close paren");
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
            message(1, "Expression too deep");  /* Stack overflow in match stack. */
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
        } else if (c == '0' && (match_p[1] | 32) == 'b') {  /* Binary */
            match_p += 2;
            /*value1 = 0;*/
            while (match_p[0] == '0' || match_p[0] == '1' || match_p[0] == '_') {
                if (match_p[0] != '_') {
                    value1 <<= 1;
                    if (match_p[0] == '1')
                        value1 |= 1;
                }
                match_p++;
            }
            goto check_nolabel;
        } else if (c == '0' && (match_p[1] | 32) == 'x') {  /* Hexadecimal */
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
            /*value1 = 0;*/
            for (; (unsigned char)(c = match_p[0] - '0') < 8; ++match_p) {
                value1 = (value1 << 3) | c;
            }
          check_nolabel:
            c = match_p[0];
            if (islabel(c)) goto bad_label;
        } else if (c == '\'' || c == '"') {  /* Character constant */
            /*value1 = 0;*/ shift = 0;
            for (++match_p; match_p[0] != '\0' && match_p[0] != c; ++match_p) {
                if (shift < sizeof(value_t) * 8) {
                    value1 |= (unsigned char)match_p[0] << shift;
                    shift += 8;
                }
            }
            if (match_p[0] == '\0') {
                message(1, "Missing close quote");
                goto match_error;
            } else {
                ++match_p;
            }
        } else if (isdigit(c)) {  /* Decimal */
            /*value1 = 0;*/
            for (p2 = (char*)match_p; (unsigned char)(c = match_p[0] - '0') <= 9; ++match_p) {
                value1 = value1 * 10 + c;
            }
            c = match_p[0];
            if (islabel(c)) {
                if (!isxdigit(c)) goto bad_label;
                match_p = p2;
                shift = 1;
                goto parse_hex;
            }
        } else if (c == '$') {
            c = *++match_p;
            if (c == '$') {  /* Start address ($$). */
                ++match_p;
                value1 = start_address;
                if (islabel(match_p[0])) { bad_label:
                    message(1, "bad label");
                }
            } else if (isdigit(c)) {
                /* This is nasm syntax, notice no letter is allowed after $ */
                /* So it's preferrable to use prefix 0x for hexadecimal */
                shift = 0;
                goto parse_hex0;
            } else if (islabel(c)) {
                goto label_expr;
            } else {  /* Current address ($). */
                value1 = address;
            }
        } else if (islabel(c) && c != '#' /* && c != '~' && c != '$' && !isdigit(c) */) {  /* Start of label. Naively matches c == '$' and c == '~' and isdigit(c) as well, but we've checked those above. */
            if (isalpha(match_p[1]) && !islabel(match_p[2])) {
                for (p2 = (char*)register_names; p2 != register_names + 32; p2 += 2) {
                    if ((c & ~32) == p2[0] && (match_p[1] & ~32) == p2[1]) goto match_error;  /* Using a register name as a label without a preceding `$' is an error. */
                }
            }
          label_expr:
            p2 = expr_name;
            if (c == '.') {
                strcpy(expr_name, global_label);
                while (*p2 != '\0')
                    p2++;
            }
            for (; islabel(match_p[0]); *p2++ = *match_p++) {}
            *p2 = '\0';
            label = find_label(expr_name);
            if (label == NULL) {
                /*value1 = 0;*/
                undefined++;
                if (assembler_step == 2) {
                    message_start(1);
                    /* This will be printed twice for `jmp', but once for `jc'. */
                    bbprintf(&message_bbb, "Undefined label '%s'", expr_name);
                    message_end();
                }
            } else {
                value1 = label->value;
            }
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
                } else if (c == '/') {  /* Division operator. */
                    match_p++;
                    MATCH_CASEI_LEVEL_TO_VALUE2(11, 6);
                    if (GET_UVALUE(value2) == 0) {
                        if (assembler_step == 2)
                            message(1, "division by zero");
                        value2 = 1;
                    }
                    value1 = GET_UVALUE(value1) / GET_UVALUE(value2);
                } else if (c == '%') {  /* Modulo operator. */
                    match_p++;
                    MATCH_CASEI_LEVEL_TO_VALUE2(12, 6);
                    if (GET_UVALUE(value2) == 0) {
                        if (assembler_step == 2)
                            message(1, "modulo by zero");
                        value2 = 1;
                    }
                    value1 = GET_UVALUE(value1) % GET_UVALUE(value2);
                } else {
                    break;
                }
            }
        }
        if (level <= 4) {
            while (1) {
                match_p = avoid_spaces(match_p);
                if ((c = match_p[0]) == '+') {  /* Add operator. */
                    match_p++;
                    MATCH_CASEI_LEVEL_TO_VALUE2(13, 5);
                    value1 += value2;
                } else if (c == '-') {  /* Subtract operator. */
                    match_p++;
                    MATCH_CASEI_LEVEL_TO_VALUE2(14, 5);
                    value1 -= value2;
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
                        MATCH_CASEI_LEVEL_TO_VALUE2(15, 4);
                        c = 1;
                    } else {
                        MATCH_CASEI_LEVEL_TO_VALUE2(16, 4);
                        c = 0;
                    }
                    if (GET_UVALUE(value2) > 31) {
                        /* 8086 processor (in 16-bit mode) uses all 8 bits of the shift amount.
                         * i386 and amd64 processors in both 16-bit and 32-bit mode uses the last 5 bits of the shift amount.
                         * amd64 processor in 64-bit mode uses the last 6 bits of the shift amount.
                         * To get deterministic output, we disallow shift amounts with more than 5 bits.
                         * NASM has nondeterministic output, depending on the host architecture (32-bit mode or 64-bit mode).
                         */
                        message(1, "shift by larger than 31");
                        value2 = 0;
#if !CONFIG_SHIFT_OK_31
                    } else if (sizeof(int) == 2 && sizeof(value_t) == 2 && GET_UVALUE(value2) > 15) {
                        /* We want `db 1 << 16' to emit 0, but if the host
                         * architecture uses only the last 4 bits of the shift
                         * amount, it would emit 1. Thus we forcibly emit 0 here.
                         */
#if CONFIG_SHIFT_SIGNED
                        value1 = c ? 0 : GET_VALUE(value1) >> 15;  /* Sign-extend value1 to CONFIG_VALUE_BITS. */
#else
                        value1 = 0;
#endif
#endif  /* CONFIG_SHIFT_OK_31 */
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
                    MATCH_CASEI_LEVEL_TO_VALUE2(17, 3);
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
                    MATCH_CASEI_LEVEL_TO_VALUE2(18, 2);
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
                    MATCH_CASEI_LEVEL_TO_VALUE2(19, 1);
                    value1 |= value2;
                } else {
                    break;
                }
            }
        }
    }
    if (msp != match_stack) goto do_pop;
    instruction_value = value1;
    return avoid_spaces(match_p);
}

/*
 ** Match register
 */
const char *match_register(const char *p, int width, unsigned char *reg) {
    const char *r0, *r, *r2;

    p = avoid_spaces(p);
    if (!isalpha(p[0]) || !isalpha(p[1]) || islabel(p[2]))
        return NULL;
    r0 = r = register_names + (width & 16);  /* Works for width == 8 and width == 16. */
    for (r2 = r + 16; r != r2; r += 2) {
        if ((p[0] & ~32) == r[0] && (p[1] & ~32) == r[1]) {
            *reg = (r - r0) >> 1;
            return p + 2;
        }
    }
    return NULL;
}

const unsigned char reg_to_addressing[8] = { 0, 0, 0, 7 /* BX */, 0, 6 /* BP */, 4 /* SI */, 5 /* DI */ };

/*
 ** Match addressing.
 ** As a side effect, it sets instruction_addressing, instruction_offset, instruction_offset_width.
 */
const char *match_addressing(const char *p, int width) {
    unsigned char reg, reg2, reg12;
    unsigned char *instruction_addressing_p = &instruction_addressing;  /* Using this pointer saves 20 bytes in __DOSMC__. */
    const char *p2;

    instruction_offset = 0;
    instruction_offset_width = 0;

    p = avoid_spaces(p);
    if (*p == '[') {
        p = avoid_spaces(p + 1);
        p2 = match_register(p, 16, &reg);
        if (p2 != NULL) {
            p = avoid_spaces(p2);
            if (*p == ']') {
                p++;
                if (reg == 5) {  /* BP. */
                    *instruction_addressing_p = 0x46;
                    /*instruction_offset = 0;*/  /* Already set. */
                    ++instruction_offset_width;
                } else {
                    if ((*instruction_addressing_p = reg_to_addressing[reg]) == 0) return NULL;
                }
            } else if (*p == '+' || *p == '-') {
                if (*p == '+') {
                    p = avoid_spaces(p + 1);
                    p2 = match_register(p, 16, &reg2);
                } else {
                    p2 = NULL;
                }
                if (p2 != NULL) {
                    reg12 = reg * reg2;
                    if (reg12 == 6 * 3) {  /* BX+SI / SI+BX. */
                    } else if (reg12 == 7 * 3) {  /* BX+DI / DI+BX. */
                    } else if (reg12 == 6 * 5) {  /* BP+SI / SI+BP. */
                    } else if (reg12 == 7 * 5) {  /* BP+DI / DI+BP. */
                    } else {  /* Not valid. */
                        return NULL;
                    }
                    *instruction_addressing_p = reg + reg2 - 9;  /* Magic formula for encoding any of BX+SI, BX+DI, BP+SI, BP+DI. */
                    p = avoid_spaces(p2);
                    if (*p == ']') {
                        p++;
                    } else if (*p == '+' || *p == '-') {
                        p = match_expression(p);
                        if (p == NULL)
                            return NULL;
                        instruction_offset = instruction_value;
                        if (*p != ']')
                            return NULL;
                        p++;
                      set_width:
                        ++instruction_offset_width;
                        if (instruction_offset >= -0x80 && instruction_offset <= 0x7f) {
                            *instruction_addressing_p |= 0x40;
                        } else {
                            ++instruction_offset_width;
                            *instruction_addressing_p |= 0x80;
                        }
                    } else {    /* Syntax error */
                        return NULL;
                    }
                } else {
                    if ((*instruction_addressing_p = reg_to_addressing[reg]) == 0) return NULL;
                    p = match_expression(p);
                    if (p == NULL)
                        return NULL;
                    instruction_offset = instruction_value;
                    if (*p != ']')
                        return NULL;
                    p++;
                    goto set_width;
                }
            } else {    /* Syntax error */
                return NULL;
            }
        } else {    /* No valid register, try expression (absolute addressing) */
            p = match_expression(p);
            if (p == NULL)
                return NULL;
            instruction_offset = instruction_value;
            if (*p != ']')
                return NULL;
            p++;
            *instruction_addressing_p = 0x06;
            instruction_offset_width = 2;
        }
    } else {    /* Register */
        p = match_register(p, width, &reg);
        if (p == NULL)
            return NULL;
        *instruction_addressing_p = 0xc0 | reg;
    }
    return p;
}

extern struct bbprintf_buf emit_bbb;

char emit_buf[512];

void emit_flush(struct bbprintf_buf *bbb) {
    const int size = emit_bbb.p - emit_buf;
    (void)bbb;  /* emit_bbb. */
    if (size) {
        if (write(output_fd, emit_buf, size) != size) {
            message(1, "error writing to output file");
            exit(3);
        }
        emit_bbb.p = emit_buf;
    }
}

struct bbprintf_buf emit_bbb = { emit_buf, emit_buf + sizeof(emit_buf), emit_buf, 0, emit_flush };

void emit_write(const char *s, int size) {
    int emit_free;
    while ((emit_free = emit_bbb.buf_end - emit_bbb.p) <= size) {
#ifdef __DOSMC__  /* A few byte smaller than memcpy(...). */
        emit_bbb.p = (char*)memcpy_newdest_inline(emit_bbb.p, s, emit_free);
#else
        memcpy(emit_bbb.p, s, emit_free);
        emit_bbb.p += emit_free;
#endif
        s += emit_free; size -= emit_free;
        emit_flush(0);
    }
#ifdef __DOSMC__  /* A few byte smaller than memcpy(...). */
    emit_bbb.p = (char*)memcpy_newdest_inline(emit_bbb.p, s, size);
#else
    memcpy(emit_bbb.p, s, size);
    emit_bbb.p += size;
#endif
}

void emit_bytes(const char *s, int size)  {
    address += size;
    if (assembler_step == 2) {
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
void emit_byte(int byte) {
    const char c = byte;
    emit_bytes(&c, 1);
}

/*
 ** Check for end of line
 */
const char *check_end(const char *p) {
    p = avoid_spaces(p);
    if (*p) {
        message(1, "extra characters at end of line");
        return NULL;
    }
    return p;
}

/* Returns bool (0 == false or 1 == true) indicating whether the
 * NUL-terminated string p matches the NUL-terminated pattern.
 *
 * The match is performed from left to right, one byte at a time.
 * A '*' in the pattern matches anything afterwards. An uppercase
 * letter in the pattern matches itself and the lowercase equivalent.
 * A '\0' in the pattern matches the '\0', and the matching stops
 * with true. Every other byte in the pattern matches itself, and the
 * matching continues.
 */
char casematch(const char *p, const char *pattern) {
    char c;
    for (; (c = *pattern++) != '*'; ++p) {
        if (c - 'A' + 0U <= 'Z' - 'A' + 0U) {
            if ((*p & ~32) != c) return 0;  /* Letters are matched case insensitively. */
        } else {
            if (*p != c) return 0;
            if (c == '\0') break;
        }
    }
    return 1;
}


/*
 ** Search for a match with instruction
 */
const char *match(const char *p, const char *pattern_and_encode) {
    int c;
    int bit;
    int qualifier;
    const char *p0;
    const char *error_base;
    static value_t segment_value;  /* Static just to pacify GCC 7.5.0 warning of uninitialized. */
    unsigned char unused_reg;
    char dc, dw;

    p0 = p;
  next_pattern:
    undefined = 0;
    for (error_base = pattern_and_encode; (dc = *pattern_and_encode++) != ' ';) {
        if (dc - 'j' + 0U <= 'm' - 'j' + 0U) {  /* Addressing: 'j': %d8, 'k': %d16, 'l': %db8, 'm': %dw16. */
            qualifier = 0;
            if (casematch(p, "WORD*") && !isalpha(p[4])) {
                p = avoid_spaces(p + 4);
                if (*p != '[')
                    goto mismatch;
                qualifier = 16;
            } else if (casematch(p, "BYTE*") && !isalpha(p[4])) {
                p = avoid_spaces(p + 4);
                if (*p != '[')
                    goto mismatch;
                qualifier = 8;
            }
            if (dc == 'j') {
                if (qualifier == 16) goto mismatch;
              match_addressing_8:
                /* It sets instruction_addressing, instruction_offset, instruction_offset_width. */
                p = match_addressing(p, 8);
            } else if (dc == 'k') {
                if (qualifier == 8) goto mismatch;
              match_addressing_16:
                /* It sets instruction_addressing, instruction_offset, instruction_offset_width. */
                p = match_addressing(p, 16);
            } else if (dc == 'l') {
                if (qualifier != 8 && match_register(p, 8, &unused_reg) == 0) goto mismatch;
                goto match_addressing_8;
            } else /*if (dc == 'm')*/ {
                if (qualifier != 16 && match_register(p, 16, &unused_reg) == 0) goto mismatch;
                goto match_addressing_16;
            }
        } else if (dc == 'q' || dc == 'r') {  /* Register, 8-bit (q) or 16-bit (r). */
            p = match_register(p, dc == 'q' ? 0 : 16, &instruction_register);  /* 0: anything without the 16 bit set. */
        } else if (dc == 'i') {  /* Unsigned immediate, 8-bit or 16-bit. */
            p = match_expression(p);
        } else if (dc == 'a' || dc == 'c') {  /* Address for jump, 8-bit. */
            p = avoid_spaces(p);
            qualifier = 0;
            if (casematch(p, "SHORT *")) {
                p += 5;
                qualifier = 1;
            }
            p = match_expression(p);
            if (p != NULL && qualifier == 0) {
                c = instruction_value - (address + 2);
                if (dc == 'c' && undefined == 0 && (c < -128 || c > 127))
                    goto mismatch;
            }
        } else if (dc == 'b') {  /* Address for jump, 16-bit. */
            p = avoid_spaces(p);
            if (casematch(p, "SHORT *")) {
                p = NULL;
            } else {
                p = match_expression(p);
            }
        } else if (dc == 's') {  /* Signed immediate, 8-bit. */
            p = avoid_spaces(p);
            qualifier = 0;
            if (casematch(p, "BYTE *")) {
                p += 4;
                qualifier = 1;
            }
            p = match_expression(p);
            if (p != NULL && qualifier == 0) {
                c = instruction_value;
                if (undefined != 0)
                    goto mismatch;
                if (undefined == 0 && (c < -128 || c > 127))
                    goto mismatch;
            }
        } else if (dc == 'f') {  /* FAR pointer. */
            if (casematch(p, "SHORT *")) {
                goto mismatch;
            }
            p = match_expression(p);
            if (p == NULL)
                goto mismatch;
            segment_value = instruction_value;
            if (*p != ':')
                goto mismatch;
            p = match_expression(p + 1);
        } else if (dc - 'a' + 0U <= 'z' - 'a' + 0U) {  /* Unexpected special (lowercase) character in pattern. */
            goto decode_internal_error;
        } else {
            if ((dc - 'A' + 0U <= 'Z' - 'A' + 0U ? *p & ~32 : *p) != dc) goto mismatch;  /* Case insensitive match for uppercase letters in pattern. */
            p++;
            if (dc == ',') p = avoid_spaces(p);  /* Allow spaces in p after comma in pattern and p. */
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
        } else if (dc == 'i') {
            c = instruction_value;
        } else if (dc == 'j') {
            c = instruction_value;
            instruction_offset = instruction_value >> 8;
            dw = 1;
        } else if (dc == 'a') {  /* Address for jump, 8-bit. */
            c = instruction_value - (address + 1);
            if (assembler_step == 2 && (c < -128 || c > 127))
                message(1, "short jump too long");
        } else if (dc == 'b') {  /* Address for jump, 16-bit. */
            c = instruction_value - (address + 2);
            instruction_offset = c >> 8;
            dw = 1;
        } else if (dc == 'f') {  /* Far (16+16 bit) jump or call. */
            emit_byte(instruction_value);
            c = instruction_value >> 8;
            instruction_offset = segment_value;
            dw = 2;
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
                        dw = instruction_offset_width;  /* 1 or 2. */
                    }
                } else { decode_internal_error:  /* assert(...). */
                    message_start(1);
                    bbprintf(&message_bbb, "decode: internal error (%s)", error_base);
                    message_end();
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
    return check_end(p);
}

const char *prev_p;
const char *p;

/*
 ** Separate a portion of entry up to the first space.
 ** First word gets copied to `part', and `p' is advanced after it.
 */
void separate(void) {
    char *p2;

    for (; *p == ' '; ++p) {}
    prev_p = p;
    p2 = part;
    for (; *p && *p != ' '; *p2++ = *p++) {}
    *p2 = '\0';
    for (; *p == ' '; ++p) {}
}

char message_buf[512];

void message_flush(struct bbprintf_buf *bbb) {
    const int size = message_bbb.p - message_buf;
    (void)bbb;  /* message_bbb. */
    if (size) {
        if (message_bbb.data) (void)!write(2 /* stderr */, message_buf, size);
        message_bbb.p = message_buf;
        if (listing_fd >= 0) {
            if (write(listing_fd, message_buf, size) != size) {
                listing_fd = -1;
                message(1, "error writing to listing file");
                exit(3);
            }
        }
    }
}

/* data = 0 means write to listing_fd only, = 1 means write to stderr + listing_fd. */
struct bbprintf_buf message_bbb = { message_buf, message_buf + sizeof(message_buf), message_buf, 0, message_flush };

const char *filename_for_message;

/*
 ** Generate a message
 ** !! Remove `error' argument, warning not supported yet.
 */
void message_start(int error) {
    const char *msg_prefix;
    if (!message_bbb.data) {
        message_flush(NULL);  /* Flush listing_fd. */
        message_bbb.data = (void*)1;
    }
    if (error) {
        msg_prefix = "error: ";
        if (GET_UVALUE(++errors) == 0) --errors;  /* Cappped at max uvalue_t. */
    } else {
        msg_prefix = "warning: ";
        if (GET_UVALUE(++warnings) == 0) --warnings;  /* Cappped at max uvalue_t. */
    }
    if (line_number) {
        bbprintf(&message_bbb, "%s:%u: %s", filename_for_message, (unsigned)line_number, msg_prefix);
    } else {
        bbprintf(&message_bbb, msg_prefix);  /* "%s" not needed, no `%' patterns in msg_prefix. */
    }
}

void message_end(void) {
    /* We must use \r\n, because this will end up on stderr, and on DOS
     * with O_BINARY, just a \n doesn't break the line properly.
     */
    bbprintf(&message_bbb, "\r\n");
    message_flush(NULL);
    message_bbb.data = (void*)0;  /* Write subsequent bytes to listing_fd only (no stderr). */
}

void message(int error, const char *message) {
    message_start(error);
    bbprintf(&message_bbb, "%s", message);
    message_end();
}

/*
 ** Process an instruction
 */
void process_instruction(void) {
    const char *p2 = NULL, *p3;
    char c;

    if (casematch(part, "DB")) {  /* Define 8-bit byte. */
        while (1) {
            p = avoid_spaces(p);
            if (*p == '\'' || *p == '"') {    /* ASCII text, quoted. */
                c = *p++;
                for (p2 = p; *p2 != '\0' && *p2 != c; ++p2) {}
                p3 = p2;
                if (*p3 == '\0') {
                    message(1, "Missing close quote");
                } else {
                    p3 = avoid_spaces(p3 + 1);
                    if (*p3 != ',' && *p3 != '\0') { --p; goto db_expr; }
                    emit_bytes(p, p2 - p);
                }
                p = p3;
            } else { db_expr:
                p = match_expression(p);
                if (p == NULL) {
                    message(1, "Bad expression");
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
    } else if ((c = casematch(part, "DW")) /* Define 16-bit word. */
#if CONFIG_VALUE_BITS == 32
               || casematch(part, "DD")  /* Define 32-bit quadword. */
              ) {
#endif
        while (1) {
            p = match_expression(p);
            if (p == NULL) {
                message(1, "Bad expression");
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
    while (part[0]) {   /* Match against instruction set */
        p2 = instruction_set;
        for (;;) {
            if (*p2 == '\0') {
                message_start(1);
                bbprintf(&message_bbb, "Unknown instruction '%s'", part);
                message_end();
                goto after_matches;
            }
            if (casematch(part, p2)) break;  /* Match actual instruction mnemonic name (part) against candidate from instruction_set (p2). */
            while (*p2++ != '\0') {}  /* Skip over instruction name. !! TODO(pts): Remove duplication. */
            while (*p2++ != '\0') {}  /* Skip over pattern_and_encode. */
        }
        while (*p2++ != '\0') {}  /* Skip over instruction name. */
        p3 = p;
        p = match(p, p2);
        if (p == NULL) {
            message_start(1);
            bbprintf(&message_bbb, "Error in instruction '%s %s'", part, p3);
            message_end();
            break;
        }
        separate();
    }
  after_matches: ;
}

/*
 ** Reset current address.
 ** Called anytime the assembler needs to generate code.
 */
void reset_address(void) {
    address = start_address = default_start_address;
}

/*
 ** Include a binary file
 */
void incbin(const char *fname) {
    int input_fd;
    int size;

    if ((input_fd = open2(fname, O_RDONLY | O_BINARY)) < 0) {
        message_start(1);
        bbprintf(&message_bbb, "Error: Cannot open '%s' for input", fname);
        message_end();
        return;
    }

    message_flush(NULL);  /* Because we reuse message_buf below. */
    g = NULL;  /* Doesn't make an actual difference, incbin is called too late to append to incbin anyway. */
    while ((size = read(input_fd, message_buf, sizeof(message_buf))) > 0) {
        emit_bytes(message_buf, size);
    }
    if (size < 0) {
        message_start(1);
        bbprintf(&message_bbb, "Error: Error reading from '%s'", fname);
        message_end();
    }
    close(input_fd);
}

/*
 ** Creates label named `part' with value `instruction_value'.
 */
void create_label(void) {
    if (assembler_step == 1) {
        if (find_label(part)) {
            message_start(1);
            bbprintf(&message_bbb, "Redefined label '%s'", part);
            message_end();
        } else {
            last_label = define_label(part, instruction_value);
        }
    } else {
        last_label = find_label(part);
        if (last_label == NULL) {
            message_start(1);
            bbprintf(&message_bbb, "Inconsistency, label '%s' not found", part);
            message_end();
        } else {
            if (last_label->value != instruction_value) {
#ifdef DEBUG
                  /*message_start(1); bbprintf(&message_bbb, "Woops: label '%s' changed value from %04x to %04x", last_label->name, last_label->value, instruction_value); message_end(); */
#endif
                change = 1;
            }
            last_label->value = instruction_value;
        }
    }
}

char line_buf[512];
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
char assembly_stack[512];
#else
struct assembly_info assembly_stack[(512 + sizeof(struct assembly_info) - 1) / sizeof(struct assembly_info)];
#endif
struct assembly_info *assembly_p;  /* = (struct assembly_info*)assembly_stack; */

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
    strcpy(assembly_p->input_filename, input_filename);
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
        /* TODO(pts): If DEBUG, assert it. */
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

#if CONFIG_VALUE_BITS == 32 && IS_VALUE_LONG  /* Example: __DOSMC__. */
#define FMT_05U "%05s"
#define GET_FMT_U_VALUE(value) get_fmt_u_value(value)  /* Only one of this works in a single bbprintf(...), because get_fmt_u_value(...) uses a static, global buffer. */
/* Returns uvalue_t formatted as a decimal, '\0'-terminated string.
 * The returned pointer points to within a static, global buffer.
 * We can't use bbprintf(...), because it supports only int size, and here sizeof(uvalue_t) > sizeof(int).
 */
static const char *get_fmt_u_value(uvalue_t u) {
    static char buf[sizeof(u) * 3 + 1];  /* Long enough for a decimal representation. */
    char *p = buf + sizeof(buf) - 1;
    *p = '\0';
    do {
        *--p = '0' + (unsigned char)(u % 10);
        u /= 10;
    } while (u != 0);
    return p;
}
#else
#define FMT_05U "%05u"
#define GET_FMT_U_VALUE(value) (value)
#endif

/*
 ** Do an assembler step
 */
void do_assembly(const char *input_filename) {
    struct assembly_info *aip;
    const char *p3;
    char *line;
    char *linep;
    char *liner;
    char *line_rend;
    uvalue_t level;
    uvalue_t avoid_level;
    int times;
    int base;
    int include;
    int align;
    int got;
    int input_fd;
    char pc;

    assembly_p = (struct assembly_info*)assembly_stack;  /* Clear the stack. */

  do_assembly_push:
    line_number = 0;  /* Global variable. */
    if (!(aip = assembly_push(input_filename))) {
        message(1, "assembly stack overflow, too many pending %INCLUDE files");
        return;
    }

  do_open_again:
    line_number = 0;  /* Global variable. */
    filename_for_message = aip->input_filename;
    if ((input_fd = open2(aip->input_filename, O_RDONLY | O_BINARY)) < 0) {
        message_start(1);
        bbprintf(&message_bbb, "cannot open '%s' for input", aip->input_filename);
        message_end();
        return;
    }
    if (aip->file_offset != 0 && lseek(input_fd, aip->file_offset, SEEK_SET) != aip->file_offset) {
        message_start(1);
        bbprintf(&message_bbb, "cannot seek in '%s'", input_filename);
        message_end();
        return;
    }
    level = aip->level;
    avoid_level = aip->avoid_level;
    line_number = aip->line_number;

    global_label[0] = '\0';
    base = 0;
    linep = line_rend = line_buf;
    for (;;) {  /* Read and process next line from input. */
        if (GET_UVALUE(++line_number) == 0) --line_number;  /* Cappped at max uvalue_t. */
        line = linep;
       find_eol:
        /* linep can be used as scratch from now on */
        for (p = line; p != line_rend && *p != '\n'; ++p) {}
        if (p == line_rend) {
            if (line != line_buf) {
                if (line_rend - line >= MAX_SIZE) goto line_too_long;
                /*if (line_rend - line > (int)(sizeof(line_buf) - (sizeof(line_buf) >> 2))) goto line_too_long;*/  /* Too much copy per line (thus too slow). This won't be triggered, because the `line_rend - line >= MAX_SIZE' check above triggers first. */
                for (liner = line_buf, p = line; p != line_rend; *liner++ = *p++) {}
                p = line_rend = liner;
                line = line_buf;
            }
           read_more:
            /* Now: p == line_rend. */
            if ((got = line_buf + sizeof(line_buf) - line_rend) <= 0) goto line_too_long;
            if ((got = read(input_fd, line_rend, got)) < 0) {
                message(1, "error reading assembly file");
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
                            message(1, "quoted NUL found");
                            *(char*)p = ' ';
                        }
                    } while (*p++ != pc);
                } else if (pc == ';') {
                    for (liner = (char*)p; p != line_rend; *(char*)p++ = ' ') {
                        if (*p == '\n') goto newline;
                    }
                    for (; liner != line && liner[-1] != '\n' && isspace(liner[-1]); --liner) {}  /* Remove whitespace preceding the comment. */
                    *liner = ';';  /* Process this comment again later. */
                    p = line_rend = liner + 1;
                    if (linep == line) { /* Reached end of the read buffer before the end of the single-line comment. Read more bytes of this comment. */
                        if (line_rend - linep >= MAX_SIZE) goto line_too_long;
                        goto read_more;
                    }
                } else if (pc == '\n') { newline:
                    linep = (char*)++p;
                } else if (pc == '\0' || isspace(pc)) {
                    *(char*)p++ = ' ';
                    for (liner = (char*)p; liner != line_rend && ((pc = *liner) == '\0' || (pc != '\n' && isspace(pc))); *liner++ = ' ') {}
                    if (liner == line_rend) line_rend = (char*)p;  /* Compress trailing whitespace bytes to a single space at the end of the buffer, so that they won't count against the line size (MAX_SIZE) at the end of the line. */
                } else {
                    /* TODO(pts): Experiment with converting runs of space to a single space, simplifying avoid_spaces(...). */
                    /* !! TODO(pts): nasm labels are case sensitive, but mininasm labels aren't; make $labels case sensitive in mininasm */
                    ++p;
                }
            }
            goto find_eol;
        }
        /* Now: *p == '\n'. */
        linep = (char*)p + 1;
        for (; p != line && p[-1] == ' '; --p) {}  /* Removes trailing \r and spaces. */
        *(char*)p = '\0';  /* Change trailing '\n' to '\0'. */
        /* fprintf(stderr, "line=(%s)\n", line); */
        if (p - line >= MAX_SIZE) { line_too_long:
            message(1, "assembly line too long");
            goto close_return;
        }

        base = address;
        g = generated;
        include = 0;

        p = avoid_spaces(line);
        if (p[0] == '\0') {  /* Empty line. */
            goto after_line;
        } else if (p[0] != '%') {
            if (avoid_level != 0 && level >= avoid_level) {
#ifdef DEBUG
                /* message_start(); bbprintf(&message_bbb, "Avoiding '%s'", line); message_end(); */
#endif
                goto after_line;
            }
            goto not_preproc;
        }

        /* Process preprocessor directive. Labels are not allowed here. */
        separate();
        if (casematch(part, "%IF")) {
            if (GET_UVALUE(++level) == 0) { if_too_deep:
                message(1, "%IF too deep");
                goto close_return;
            }
            if (avoid_level != 0 && level >= avoid_level)
                goto after_line;
            undefined = 0;
            p = match_expression(p);
            if (p == NULL) {
                message(1, "Bad expression");
            } else if (undefined) {
                message(1, "Cannot use undefined labels");
            }
            if (GET_UVALUE(instruction_value) != 0) {
                ;
            } else {
                avoid_level = level;
            }
            check_end(p);
        } else if (casematch(part, "%IFDEF")) {
            if (GET_UVALUE(++level) == 0) goto if_too_deep;
            if (avoid_level != 0 && level >= avoid_level)
                goto after_line;
            separate();
            if (find_dollar_label(part) != NULL) {
                ;
            } else {
                avoid_level = level;
            }
            check_end(p);
        } else if (casematch(part, "%IFNDEF")) {
            if (GET_UVALUE(++level) == 0) goto if_too_deep;
            if (avoid_level != 0 && level >= avoid_level)
                goto after_line;
            separate();
            if (find_dollar_label(part) == NULL) {
                ;
            } else {
                avoid_level = level;
            }
            check_end(p);
        } else if (casematch(part, "%ELSE")) {
            if (level == 1) {
                message(1, "%ELSE without %IF");
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
        } else if (casematch(part, "%ENDIF")) {
            if (avoid_level == level)
                avoid_level = 0;
            if (--level == 0) {
                message(1, "%ENDIF without %IF");
                goto close_return;
            }
            check_end(p);
        } else if (casematch(part, "%IF*") || casematch(part, "%ELIF*")) {
            /* We report this even if skipped. */
            message_start(1);
            bbprintf(&message_bbb, "Unknown preprocessor condition: %s", part);
            message_end();
            goto close_return;  /* There is no meaningful way to continue. */
        } else if (avoid_level != 0 && level >= avoid_level) {
        } else if (casematch(part, "%INCLUDE")) {
            separate();
            check_end(p);
            if ((part[0] != '"' && part[0] != '\'') || part[strlen(part) - 1] != part[0]) {
                message(1, "Missing quotes on %include");
                goto after_line;
            }
            include = 1;
        } else {
            message_start(1);
            bbprintf(&message_bbb, "Unknown preprocessor directive: %s", part);
            message_end();
        }
        goto after_line;
      not_preproc:

        /* Parse and process label, if any. */
        if ((p3 = match_label_prefix(p)) != NULL && (p3[0] == ':' || (p[0] == '$' && p3[0] == ' '))) {
            if (p[0] == '$') ++p;
            if (p[0] == '.') {
                times = strlen(global_label);
                strcpy(part, global_label);
                memcpy(part + times, p, p3 - p);
                part[times + (p3 - p)] = '\0';
            } else {
                memcpy(part, p, p3 - p);
                part[(p3 - p)] = '\0';
                strcpy(global_label, part);
            }
            p = avoid_spaces(p3 + 1);
            if (casematch(p, "EQU*") && !islabel(p[3])) {
                p = match_expression(p + 3);
                if (p == NULL) {
                    message(1, "bad expression");
                } else {
                    create_label();
                    check_end(p);
                }
                goto after_line;
            }
            if (first_time == 1) {  /* !! TODO(pts): Why only here? */
#ifdef DEBUG
                /*                        message_start(1); bbprintf(&message_bbb, "First time '%s'", line); message_end();  */
#endif
                first_time = 0;
                reset_address();
            }
            instruction_value = address;
            create_label();
        }

        /* Process command (non-preprocessor, non-label). */
        if (p[0] == '\0') {
            goto after_line;
        } else if (!isalpha(p[0])) {
            message(1, "Instruction expected");
            goto after_line;
        }
        separate();
        if (casematch(part, "USE16")) {
        } else if (casematch(part, "CPU")) {
            p = avoid_spaces(p);
            if (!casematch(p, "8086"))
                message(1, "Unsupported processor requested");
        } else if (casematch(part, "BITS")) {
            p = avoid_spaces(p);
            undefined = 0;
            p = match_expression(p);
            if (p == NULL) {
                message(1, "Bad expression");
            } else if (undefined) {
                message(1, "Cannot use undefined labels");
            } else if (GET_UVALUE(instruction_value) != 16) {
                message(1, "Unsupported BITS requested");
            } else {
                check_end(p);
            }
        } else if (casematch(part, "INCBIN")) {
            separate();
            check_end(p);
            if ((part[0] != '"' && part[0] != '\'') || part[strlen(part) - 1] != part[0]) {
                message(1, "Missing quotes on incbin");
                goto after_line;
            }
            include = 2;
        } else if (casematch(part, "ORG")) {
            p = avoid_spaces(p);
            undefined = 0;
            p = match_expression(p);
            if (p == NULL) {
                message(1, "Bad expression");
            } else if (undefined) {
                message(1, "Cannot use undefined labels");
            } else {
                if (first_time == 1) {
                    first_time = 0;
                    address = instruction_value;
                    start_address = instruction_value;
                    base = address;
                } else {
                    if (instruction_value < address) {
                        message(1, "Backward address");
                    } else {
                        while (address < instruction_value)
                            emit_byte(0);

                    }
                }
                check_end(p);
            }
        } else if (casematch(part, "ALIGN")) {
            p = avoid_spaces(p);
            undefined = 0;
            p = match_expression(p);
            if (p == NULL) {
                message(1, "Bad expression");
            } else if (undefined) {
                message(1, "Cannot use undefined labels");
            } else {
                align = address / instruction_value;
                align = align * instruction_value;
                align = align + instruction_value;
                while (address < align)
                    emit_byte(0x90);
                check_end(p);  /* TODO(pts): Support 2nd argument of align, e.g. nop. */
            }
        } else {
            if (first_time == 1) {
#ifdef DEBUG
                /* message_start(1); bbprintf(&message_bbb, "First time '%s'", line); message_end(); */
#endif
                first_time = 0;
                reset_address();
            }
            times = 1;
            if (casematch(part, "TIMES")) {
                undefined = 0;
                p = match_expression(p);
                if (p == NULL) {
                    message(1, "Bad expression");
                    goto after_line;
                }
                if (undefined) {
                    message(1, "Cannot use undefined labels");
                    goto after_line;
                }
                times = instruction_value;
                separate();
            }
            base = address;
            g = generated;
            p3 = prev_p;
            while (times) {
                p = p3;
                separate();
                process_instruction();
                times--;
            }
        }
      after_line:
        if (assembler_step == 2 && listing_fd >= 0) {
            if (first_time)
                bbprintf(&message_bbb /* listing_fd */, "      ");
            else
                bbprintf(&message_bbb /* listing_fd */, "%04X  ", base);
            p = generated;
            while (p < g) {
                bbprintf(&message_bbb /* listing_fd */, "%02X", *p++ & 255);
            }
            while (p < generated + sizeof(generated)) {
                bbprintf(&message_bbb /* listing_fd */, "  ");
                p++;
            }
            bbprintf(&message_bbb /* listing_fd */, "  " FMT_05U " %s\r\n", GET_FMT_U_VALUE(line_number), line);
        }
        if (include == 1) {
            if (linep != NULL && (aip->file_offset = lseek(input_fd, linep - line_rend, SEEK_CUR)) < 0) {
                message(1, "Cannot seek in source file");
                goto close_return;
            }
            close(input_fd);
            aip->level = level;
            aip->avoid_level = avoid_level;
            aip->line_number = line_number;
            part[strlen(part) - 1] = '\0';
            input_filename = part + 1;
            goto do_assembly_push;
        } else if (include == 2) {
            part[strlen(part) - 1] = '\0';
            incbin(part + 1);
        }
    }
    if (level != 1) {
        message(1, "pending %IF at end of file");
    }
  close_return:
    close(input_fd);
    if ((aip = assembly_pop(aip)) != NULL) goto do_open_again;  /* Continue processing the input file which %INCLUDE()d the current input file. */
    line_number = 0;  /* Global variable. */
}

/*
 ** Main program
 */
int main(int argc, char **argv) {
    int c;
    int d;
    const char *p;
    char *ifname;

#if (defined(MSDOS) || defined(_WIN32)) && !defined(__DOSMC__)
    setmode(2, O_BINARY);  /* STDERR_FILENO. */
#endif

#if 0
    malloc_init();
    message_start(1);
    bbprintf(&message_bbb, "malloc_p_para=0x%04x malloc_end_para=%04x", ((const unsigned*)&__malloc_struct__.malloc_p)[1], __malloc_struct__.malloc_end_para);
    message_end();
#endif

    /*
     ** If ran without arguments then show usage
     */
    if (argc == 1) {
        static const MY_STRING_WITHOUT_NUL(msg, "Typical usage:\r\nmininasm -f bin input.asm -o input.bin\r\n");
        (void)!write(2, msg, sizeof(msg));
        return 1;
    }

    /*
     ** Start to collect arguments
     */
    ifname = NULL;
    output_filename = NULL;
    listing_filename = NULL;
    default_start_address = 0;
    c = 1;
    while (c < argc) {
        if (argv[c][0] == '-') {    /* All arguments start with dash */
            d = argv[c][1] | 32;  /* Flags characters are case insensitive. */
            if (d == 'd') {  /* Define label */
                for (p = argv[c] + 2; *p && *p != '='; ++p) {}
                if (*p == '=') {
                    *(char*)p++ = 0;
                    undefined = 0;
                    p = match_expression(p);
                    if (p == NULL) {
                        message(1, "Bad expression");
                        return 1;
                    } else if (undefined) {
                        message(1, "Cannot use undefined labels");
                        return 1;
                    } else {
                        p = argv[c] + 2;
                        define_label(p + (p[0] == '$'), instruction_value);
                    }
                }
                c++;
            } else if (argv[c][2] != '\0' && (d == 'f' || d == 'o' || d == 'l')) {
                message_start(1);
                bbprintf(&message_bbb, "flag too long: %s", argv[c]);  /* Example: `-fbin' should be `-f bin'. */
                goto flag_error;
            } else if (d == 'f') { /* Format */
                c++;
                if (c >= argc) {
                    message(1, "no argument for -f");
                    return 1;
                } else {
                    if (casematch(argv[c], "BIN")) {
                        default_start_address = 0;
                    } else if (casematch(argv[c], "COM")) {
                        default_start_address = 0x0100;
                    } else {
                        message_start(1);
                        bbprintf(&message_bbb, "only 'bin', 'com' supported for -f (it is '%s')", argv[c]);
                        message_end();
                        return 1;
                    }
                    c++;
                }
            } else if (d == 'o') {  /* Object file name */
                c++;
                if (c >= argc) {
                    message(1, "no argument for -o");
                    return 1;
                } else if (output_filename != NULL) {
                    message(1, "already a -o argument is present");
                    return 1;
                } else {
                    output_filename = argv[c];
                    c++;
                }
            } else if (d == 'l') {  /* Listing file name */
                c++;
                if (c >= argc) {
                    message(1, "no argument for -l");
                    return 1;
                } else if (listing_filename != NULL) {
                    message(1, "already a -l argument is present");
                    return 1;
                } else {
                    listing_filename = argv[c];
                    c++;
                }
            } else {
                message_start(1);
                bbprintf(&message_bbb, "unknown argument %s", argv[c]);
              flag_error:
                message_end();
                return 1;
            }
        } else {
            if (ifname != NULL) {
                message_start(1);
                bbprintf(&message_bbb, "more than one input file name: %s", argv[c]);
                message_end();
                return 1;
            } else {
                ifname = argv[c];
            }
            c++;
        }
    }

    if (ifname == NULL) {
        message(1, "No input filename provided");
        return 1;
    }

    /*
     ** Do first step of assembly
     */
    assembler_step = 1;
    first_time = 1;
    malloc_init();
    do_assembly(ifname);
    message_flush(NULL);
    if (errors) { do_remove:
        remove(output_filename);
        if (listing_filename != NULL)
            remove(listing_filename);
    } else {
        /*
         ** Do second step of assembly and generate final output
         */
        if (output_filename == NULL) {
            message(1, "No output filename provided");
            return 1;
        }
        change_number = 0;
        do {
            change = 0;
            if (listing_filename != NULL) {
                if ((listing_fd = creat(listing_filename, 0644)) < 0) {
                    message_start(1);
                    bbprintf(&message_bbb, "couldn't open '%s' as listing file", output_filename);
                    message_end();
                    return 1;
                }
            }
            if ((output_fd = creat(output_filename, 0644)) < 0) {
                message_start(1);
                bbprintf(&message_bbb, "couldn't open '%s' as output file", output_filename);
                message_end();
                return 1;
            }
            assembler_step = 2;
            first_time = 1;
            address = start_address;
            do_assembly(ifname);

            if (listing_fd >= 0 && change == 0) {
                bbprintf(&message_bbb /* listing_fd */, "\r\n" FMT_05U " ERRORS FOUND\r\n", GET_FMT_U_VALUE(errors));
                bbprintf(&message_bbb /* listing_fd */, FMT_05U " WARNINGS FOUND\r\n\r\n", GET_FMT_U_VALUE(warnings));
                bbprintf(&message_bbb /* listing_fd */, FMT_05U " PROGRAM BYTES\r\n\r\n", GET_FMT_U_VALUE(GET_UVALUE(bytes)));
                if (label_list != NULL) {
                    bbprintf(&message_bbb /* listing_fd */, "%-20s VALUE/ADDRESS\r\n\r\n", "LABEL");
                    print_labels_sorted_to_listing_fd(label_list);
                }
            }
            emit_flush(0);
            close(output_fd);
            if (listing_filename != NULL) {
                message_flush(NULL);
                close(listing_fd);
            }
            if (change) {
                change_number++;
                if (change_number == 5) {
                    message(1, "Aborted: Couldn't stabilize moving label");
                }
            }
            if (errors) goto do_remove;
        } while (change) ;
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
const char instruction_set[] =
    "AAA\0" " 37\0"
    "AAD\0" "i D5i" ALSO " D50A\0"
    "AAM\0" "i D4i" ALSO " D40A\0"
    "AAS\0" " 3F\0"
    "ADC\0" "j,q 10drd" ALSO "k,r 11drd" ALSO "q,j 12drd" ALSO "r,k 13drd" ALSO "AL,i 14i" ALSO "AX,i 15j" ALSO "k,s 83dzozdi" ALSO "j,i 80dzozdi" ALSO "k,i 81dzozdj\0"
    "ADD\0" "j,q 00drd" ALSO "k,r 01drd" ALSO "q,j 02drd" ALSO "r,k 03drd" ALSO "AL,i 04i" ALSO "AX,i 05j" ALSO "k,s 83dzzzdi" ALSO "j,i 80dzzzdi" ALSO "k,i 81dzzzdj\0"
    "AND\0" "j,q 20drd" ALSO "k,r 21drd" ALSO "q,j 22drd" ALSO "r,k 23drd" ALSO "AL,i 24i" ALSO "AX,i 25j" ALSO "k,s 83dozzdi" ALSO "j,i 80dozzdi" ALSO "k,i 81dozzdj\0"
    "CALL\0" "FAR k FFdzood" ALSO "f 9Af" ALSO "k FFdzozd" ALSO "b E8b\0"
    "CBW\0" " 98\0"
    "CLC\0" " F8\0"
    "CLD\0" " FC\0"
    "CLI\0" " FA\0"
    "CMC\0" " F5\0"
    "CMP\0" "j,q 38drd" ALSO "k,r 39drd" ALSO "q,j 3Adrd" ALSO "r,k 3Bdrd" ALSO "AL,i 3Ci" ALSO "AX,i 3Dj" ALSO "k,s 83dooodi" ALSO "j,i 80dooodi" ALSO "k,i 81dooodj\0"
    "CMPSB\0" " A6\0"
    "CMPSW\0" " A7\0"
    "CS\0" " 2E+\0"
    "CWD\0" " 99\0"
    "DAA\0" " 27\0"
    "DAS\0" " 2F\0"
    "DEC\0" "r zozzor" ALSO "l FEdzzod" ALSO "m FFdzzod\0"
    "DIV\0" "l F6doozd" ALSO "m F7doozd\0"
    "DS\0" " 3E+\0"
    "ES\0" " 26+\0"
    "HLT\0" " F4\0"
    "IDIV\0" "l F6doood" ALSO "m F7doood\0"
    "IMUL\0" "l F6dozod" ALSO "m F7dozod\0"
    "IN\0" "AL,DX EC" ALSO "AX,DX ED" ALSO "AL,i E4i" ALSO "AX,i E5i\0"
    "INC\0" "r zozzzr" ALSO "l FEdzzzd" ALSO "m FFdzzzd\0"
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
    "JMP\0" "FAR k FFdozod" ALSO "f EAf" ALSO "k FFdozzd" ALSO "c EBa" ALSO "b E9b\0"
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
    "LDS\0" "r,k oozzzozodrd\0"
    "LEA\0" "r,k 8Ddrd\0"
    "LES\0" "r,k oozzzozzdrd\0"
    "LOCK\0" " F0+\0"
    "LODSB\0" " AC\0"
    "LODSW\0" " AD\0"
    "LOOP\0" "a E2a\0"
    "LOOPE\0" "a E1a\0"
    "LOOPNE\0" "a E0a\0"
    "LOOPNZ\0" "a E0a\0"
    "LOOPZ\0" "a E1a\0"
    "MOV\0" "AL,[i] A0j" ALSO "AX,[i] A1j" ALSO "[i],AL A2j" ALSO "[i],AX A3j" ALSO "j,q 88drd" ALSO "k,r 89drd" ALSO "q,j 8Adrd" ALSO "r,k 8Bdrd" ALSO "k,ES 8Cdzzzd" ALSO "k,CS 8Cdzzod" ALSO "k,SS 8Cdzozd" ALSO "k,DS 8Cdzood" ALSO "ES,k 8Edzzzd" ALSO "CS,k 8Edzzod" ALSO "SS,k 8Edzozd" ALSO "DS,k 8Edzood" ALSO "q,i ozoozri" ALSO "r,i ozooorj" ALSO "l,i oozzzoozdzzzdi" ALSO "m,i oozzzooodzzzdj\0"
    "MOVSB\0" " A4\0"
    "MOVSW\0" " A5\0"
    "MUL\0" "l F6dozzd" ALSO "m F7dozzd\0"
    "NEG\0" "l F6dzood" ALSO "m F7dzood\0"
    "NOP\0" " 90\0"
    "NOT\0" "l F6dzozd" ALSO "m F7dzozd\0"
    "OR\0" "j,q 08drd" ALSO "k,r 09drd" ALSO "q,j 0Adrd" ALSO "r,k 0Bdrd" ALSO "AL,i 0Ci" ALSO "AX,i 0Dj" ALSO "k,s 83dzzodi" ALSO "j,i 80dzzodi" ALSO "k,i 81dzzodj\0"
    "OUT\0" "DX,AL EE" ALSO "DX,AX EF" ALSO "i,AL E6i" ALSO "i,AX E7i\0"
    "PAUSE\0" " F390\0"
    "POP\0" "ES 07" ALSO "SS 17" ALSO "DS 1F" ALSO "r zozoor" ALSO "k 8Fdzzzd\0"
    "POPF\0" " 9D\0"
    "PUSH\0" "ES 06" ALSO "CS 0E" ALSO "SS 16" ALSO "DS 1E" ALSO "r zozozr" ALSO "k FFdoozd\0"
    "PUSHF\0" " 9C\0"
    "RCL\0" "j,1 D0dzozd" ALSO "k,1 D1dzozd" ALSO "j,CL D2dzozd" ALSO "k,CL D3dzozd\0"
    "RCR\0" "j,1 D0dzood" ALSO "k,1 D1dzood" ALSO "j,CL D2dzood" ALSO "k,CL D3dzood\0"
    "REP\0" " F3+\0"
    "REPE\0" " F3+\0"
    "REPNE\0" " F2+\0"
    "REPNZ\0" " F2+\0"
    "REPZ\0" " F3+\0"
    "RET\0" "i C2j" ALSO " C3\0"
    "RETF\0" "i CAj" ALSO " CB\0"
    "ROL\0" "j,1 D0dzzzd" ALSO "k,1 D1dzzzd" ALSO "j,CL D2dzzzd" ALSO "k,CL D3dzzzd\0"
    "ROR\0" "j,1 D0dzzod" ALSO "k,1 D1dzzod" ALSO "j,CL D2dzzod" ALSO "k,CL D3dzzod\0"
    "SAHF\0" " 9E\0"
    "SAR\0" "j,1 D0doood" ALSO "k,1 D1doood" ALSO "j,CL D2doood" ALSO "k,CL D3doood\0"
    "SBB\0" "j,q 18drd" ALSO "k,r 19drd" ALSO "q,j 1Adrd" ALSO "r,k 1Bdrd" ALSO "AL,i 1Ci" ALSO "AX,i 1Dj" ALSO "k,s 83dzoodi" ALSO "j,i 80dzoodi" ALSO "k,i 81dzoodj\0"
    "SCASB\0" " AE\0"
    "SCASW\0" " AF\0"
    "SHL\0" "j,1 D0dozzd" ALSO "k,1 D1dozzd" ALSO "j,CL D2dozzd" ALSO "k,CL D3dozzd\0"
    "SHR\0" "j,1 D0dozod" ALSO "k,1 D1dozod" ALSO "j,CL D2dozod" ALSO "k,CL D3dozod\0"
    "SS\0" " 36+\0"
    "STC\0" " F9\0"
    "STD\0" " FD\0"
    "STI\0" " FB\0"
    "STOSB\0" " AA\0"
    "STOSW\0" " AB\0"
    "SUB\0" "j,q 28drd" ALSO "k,r 29drd" ALSO "q,j 2Adrd" ALSO "r,k 2Bdrd" ALSO "AL,i 2Ci" ALSO "AX,i 2Dj" ALSO "k,s 83dozodi" ALSO "j,i 80dozodi" ALSO "k,i 81dozodj\0"
    "TEST\0" "j,q 84drd" ALSO "q,j 84drd" ALSO "k,r 85drd" ALSO "r,k 85drd" ALSO "AL,i A8i" ALSO "AX,i A9j" ALSO "l,i F6dzzzdi" ALSO "m,i F7dzzzdj\0"
    "WAIT\0" " 9B+\0"
    "XCHG\0" "AX,r ozzozr" ALSO "r,AX ozzozr" ALSO "q,j 86drd" ALSO "j,q 86drd" ALSO "r,k 87drd" ALSO "k,r 87drd\0"
    "XLAT\0" " D7\0"
    "XOR\0" "j,q 30drd" ALSO "k,r 31drd" ALSO "q,j 32drd" ALSO "r,k 33drd" ALSO "AL,i 34i" ALSO "AX,i 35j" ALSO "k,s 83doozdi" ALSO "j,i 80doozdi" ALSO "k,i 81doozdj\0"
;
