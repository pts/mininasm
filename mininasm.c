/*
 ** mininasm: NASM-compatible mini assembler for 8086, able to run on DOS and on modern systems
 ** mininasm modifications by pts@fazekas.hu at Wed May 18 21:39:36 CEST 2022
 **
 ** based on tinyasm by Oscar Toledo G, starting Oct/01/2019.
 **
 ** Compilation instructions (pick any one):
 **
 **   $ gcc -ansi -pedantic -s -Os -W -Wall -o mininasm mininasm.c ins.c bbprintf.c && ls -ld mininasm
 **
 **   $ g++ -ansi -pedantic -s -Os -W -Wall -o mininasm mininasm.c ins.c bbprintf.c && ls -ld mininasm
 **
 **   $ pts-tcc -s -O2 -W -Wall -o mininasm.tcc mininasm.c ins.c && ls -ld mininasm.tcc
 **
 **   $ dosmc -mt mininasm.c ins.c bbprintf.c && ls -ld mininasm.com
 **
 **   $ owcc -bdos -o mininasm.exe -mcmodel=l -Os -s -fno-stack-check -march=i86 -W -Wall -Wextra mininasm.c ins.c bbprintf.c && ls -ld mininasm.exe
 **
 **   $ owcc -bwin32 -Wl,runtime -Wl,console=3.10 -o mininasm.win32.exe -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm.c ins.c bbprintf.c nouser32.c && ls -ld mininasm.win32.exe
 **
 */

#ifdef __TINYC__  /* pts-tcc -s -O2 -W -Wall -o mininasm.tcc mininasm.c ins.c */
#ifdef __i386
#define ATTRIBUTE_NORETURN __attribute__((noreturn))
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned long uint32_t;
typedef char int8_t;
typedef short int16_t;
typedef long int32_t;
typedef unsigned int size_t;  /* TODO(pts): 64-bit tcc. */
typedef int ssize_t;  /* TODO(pts): 64-bit tcc. */
typedef int off_t;
#define NULL ((void*)0)
void *malloc(size_t size);
size_t strlen(const char *s);
int remove(const char *pathname);
void ATTRIBUTE_NORETURN exit(int status);
char *strcpy(char *dest, const char *src);
int strcmp(const char *s1, const char *s2);
char *strcat(char *dest, const char *src);
int memcmp(const void *s1, const void *s2, size_t n);
int isalpha(int c);
int isspace(int c);
int isdigit(int c);
int isxdigit(int c);
int tolower(int c);
int toupper(int c);
typedef char *va_list;  /* i386 only */
#define va_start(ap,last) ap = ((char *)&(last)) + ((sizeof(last)+3)&~3)  /* i386 only */
#define va_arg(ap,type) (ap += (sizeof(type)+3)&~3, *(type *)(ap - ((sizeof(type)+3)&~3)))  /* i386 only */
#define va_copy(dest, src) (dest) = (src)  /* i386 only */
#define va_end(ap)  /* i386 only */
ssize_t read(int fd, void *buf, size_t count);
ssize_t write(int fd, const void *buf, size_t count);
#define SEEK_SET 0  /* whence value below. */
#define SEEK_CUR 1
#define SEEK_END 2
off_t lseek(int fd, off_t offset, int whence);  /* Just 32-bit off_t. */
#define O_RDONLY 0  /* flags bitfield value below. */
#define O_WRONLY 1
#define O_RDWR 2
int open(const char *pathname, int flags, ...);  /* int mode */
int creat(const char *pathname, int mode);
int close(int fd);
#define open2(pathname, flags) open(pathname, flags)
#else
#error tcc is only supported on i386
#endif
#else
#ifdef __DOSMC__
#include <dosmc.h>  /* strcpy_far(...), strcmp_far(...) etc. */
#else /* Standard C. */
#include <ctype.h>
#include <fcntl.h>
#include <stdio.h>  /* remove(...) */
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#define open2(pathname, flags) open(pathname, flags)
#endif
#endif

#ifndef O_BINARY  /* Unix. */
#define O_BINARY 0
#endif

#if !defined(CONFIG_CPU_UNALIGN)
#if defined(_M_X64) || defined(_M_AMD64) || defined(__x86_64__) || defined(__amd64__) || defined(_M_IX86) || defined(__i386__)
#define CONFIG_CPU_UNALIGN 1  /* CPU supports unaligned memory access. i386 and amd64 do, arm and arm64 don't.  */
#else
#define CONFIG_CPU_UNALIGN 0
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


#define DEBUG

int line_number;

char *output_filename;
int output_fd;

char *listing_filename;
int listing_fd = -1;

typedef int value_t;

int assembler_step;  /* !! Change many variables from int to char. */
value_t default_start_address;
value_t start_address;
value_t address;
int first_time;

int instruction_addressing;
int instruction_offset;
int instruction_offset_width;

int instruction_register;

value_t instruction_value;
value_t instruction_value2;

#define MAX_SIZE        256

char part[MAX_SIZE];
char name[MAX_SIZE];
char expr_name[MAX_SIZE];
char global_label[MAX_SIZE];
const char *prev_p;
const char *p;

char *g;
char generated[8];

int errors;
int warnings;  /* !! remove this, currently there are no possible warnings */
int bytes;
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

extern const char *instruction_set[];

const char *reg1[16] = {
    "AL",
    "CL",
    "DL",
    "BL",
    "AH",
    "CH",
    "DH",
    "BH",
    "AX",
    "CX",
    "DX",
    "BX",
    "SP",
    "BP",
    "SI",
    "DI"
};

extern struct bbprintf_buf message_bbb;

void message(int error, const char *message);
void message_start(int error);
void message_end(void);
const char *match_register(const char *p, int width, int *value);
const char *match_expression(const char *p, int *value);
const char *match_expression_level1(const char *p, int *value);
const char *match_expression_level2(const char *p, int *value);
const char *match_expression_level3(const char *p, int *value);
const char *match_expression_level4(const char *p, int *value);
const char *match_expression_level5(const char *p, int *value);
const char *match_expression_level6(const char *p, int *value);

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
struct label MY_FAR *define_label(char *name, int value) {
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
            bbprintf(&message_bbb, "%-20s %04x\r\n", global_label, node->value);
            node = RBL_GET_RIGHT(node);
        }
    }
}

/*
 ** Avoid spaces in input
 */
const char *avoid_spaces(const char *p) {
    while (isspace(*p))
        p++;
    return p;
}

/*
 ** Match addressing
 */
const char *match_addressing(const char *p, int width) {
    int reg;
    int reg2;
    const char *p2;
    int *bits;

    bits = &instruction_addressing;
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
                if (reg == 3) {   /* BX */
                    *bits = 0x07;
                } else if (reg == 5) {  /* BP */
                    *bits = 0x46;
                    instruction_offset = 0;
                    instruction_offset_width = 1;
                } else if (reg == 6) {  /* SI */
                    *bits = 0x04;
                } else if (reg == 7) {  /* DI */
                    *bits = 0x05;
                } else {    /* Not valid */
                    return NULL;
                }
            } else if (*p == '+' || *p == '-') {
                if (*p == '+') {
                    p = avoid_spaces(p + 1);
                    p2 = match_register(p, 16, &reg2);
                } else {
                    p2 = NULL;
                }
                if (p2 != NULL) {
                    if ((reg == 3 && reg2 == 6) || (reg == 6 && reg2 == 3)) {   /* BX+SI / SI+BX */
                        *bits = 0x00;
                    } else if ((reg == 3 && reg2 == 7) || (reg == 7 && reg2 == 3)) {    /* BX+DI / DI+BX */
                        *bits = 0x01;
                    } else if ((reg == 5 && reg2 == 6) || (reg == 6 && reg2 == 5)) {    /* BP+SI / SI+BP */
                        *bits = 0x02;
                    } else if ((reg == 5 && reg2 == 7) || (reg == 7 && reg2 == 5)) {    /* BP+DI / DI+BP */
                        *bits = 0x03;
                    } else {    /* Not valid */
                        return NULL;
                    }
                    p = avoid_spaces(p2);
                    if (*p == ']') {
                        p++;
                    } else if (*p == '+' || *p == '-') {
                        p2 = match_expression(p, &instruction_offset);
                        if (p2 == NULL)
                            return NULL;
                        p = avoid_spaces(p2);
                        if (*p != ']')
                            return NULL;
                        p++;
                        if (instruction_offset >= -0x80 && instruction_offset <= 0x7f) {
                            instruction_offset_width = 1;
                            *bits |= 0x40;
                        } else {
                            instruction_offset_width = 2;
                            *bits |= 0x80;
                        }
                    } else {    /* Syntax error */
                        return NULL;
                    }
                } else {
                    if (reg == 3) {   /* BX */
                        *bits = 0x07;
                    } else if (reg == 5) {  /* BP */
                        *bits = 0x06;
                    } else if (reg == 6) {  /* SI */
                        *bits = 0x04;
                    } else if (reg == 7) {  /* DI */
                        *bits = 0x05;
                    } else {    /* Not valid */
                        return NULL;
                    }
                    p2 = match_expression(p, &instruction_offset);
                    if (p2 == NULL)
                        return NULL;
                    p = avoid_spaces(p2);
                    if (*p != ']')
                        return NULL;
                    p++;
                    if (instruction_offset >= -0x80 && instruction_offset <= 0x7f) {
                        instruction_offset_width = 1;
                        *bits |= 0x40;
                    } else {
                        instruction_offset_width = 2;
                        *bits |= 0x80;
                    }
                }
            } else {    /* Syntax error */
                return NULL;
            }
        } else {    /* No valid register, try expression (absolute addressing) */
            p2 = match_expression(p, &instruction_offset);
            if (p2 == NULL)
                return NULL;
            p = avoid_spaces(p2);
            if (*p != ']')
                return NULL;
            p++;
            *bits = 0x06;
            instruction_offset_width = 2;
        }
    } else {    /* Register */
        p = match_register(p, width, &reg);
        if (p == NULL)
            return NULL;
        *bits = 0xc0 | reg;
    }
    return p;
}

/*
 ** Check for a label character
 */
int islabel(int c) {
    return isalpha(c) || isdigit(c) || c == '_' || c == '.';
}

/*
 ** Match register
 */
const char *match_register(const char *p, int width, int *value) {
    char reg[3];
    int c;

    p = avoid_spaces(p);
    if (!isalpha(p[0]) || !isalpha(p[1]) || islabel(p[2]))
        return NULL;
    reg[0] = p[0];
    reg[1] = p[1];
    reg[2] = '\0';
    if (width == 8) {   /* 8-bit */
        for (c = 0; c < 8; c++)
            if (strcmp(reg, reg1[c]) == 0)
                break;
        if (c < 8) {
            *value = c;
            return p + 2;
        }
    } else {    /* 16-bit */
        for (c = 0; c < 8; c++)
            if (strcmp(reg, reg1[c + 8]) == 0)
                break;
        if (c < 8) {
            *value = c;
            return p + 2;
        }
    }
    return NULL;
}

/*
 ** Match expression (top tier)
 */
const char *match_expression(const char *p, int *value) {
    int value1;

    p = match_expression_level1(p, value);
    if (p == NULL)
        return NULL;
    while (1) {
        p = avoid_spaces(p);
        if (*p == '|') {    /* Binary OR */
            p++;
            value1 = *value;
            p = match_expression_level1(p, value);
            if (p == NULL)
                return NULL;
            *value |= value1;
        } else {
            return p;
        }
    }
}

/*
 ** Match expression
 */
const char *match_expression_level1(const char *p, int *value) {
    int value1;

    p = match_expression_level2(p, value);
    if (p == NULL)
        return NULL;
    while (1) {
        p = avoid_spaces(p);
        if (*p == '^') {    /* Binary XOR */
            p++;
            value1 = *value;
            p = match_expression_level2(p, value);
            if (p == NULL)
                return NULL;
            *value ^= value1;
        } else {
            return p;
        }
    }
}

/*
 ** Match expression
 */
const char *match_expression_level2(const char *p, int *value) {
    int value1;

    p = match_expression_level3(p, value);
    if (p == NULL)
        return NULL;
    while (1) {
        p = avoid_spaces(p);
        if (*p == '&') {    /* Binary AND */
            p++;
            value1 = *value;
            p = match_expression_level3(p, value);
            if (p == NULL)
                return NULL;
            *value &= value1;
        } else {
            return p;
        }
    }
}

/*
 ** Match expression
 */
const char *match_expression_level3(const char *p, int *value) {
    int value1;

    p = match_expression_level4(p, value);
    if (p == NULL)
        return NULL;
    while (1) {
        p = avoid_spaces(p);
        if (*p == '<' && p[1] == '<') { /* Shift to left */
            p += 2;
            value1 = *value;
            p = match_expression_level4(p, value);
            if (p == NULL)
                return NULL;
            *value = value1 << *value;
        } else if (*p == '>' && p[1] == '>') {  /* Shift to right */
            p += 2;
            value1 = *value;
            p = match_expression_level4(p, value);
            if (p == NULL)
                return NULL;
            *value = value1 >> *value;
        } else {
            return p;
        }
    }
}

/*
 ** Match expression
 */
const char *match_expression_level4(const char *p, int *value) {
    int value1;

    p = match_expression_level5(p, value);
    if (p == NULL)
        return NULL;
    while (1) {
        p = avoid_spaces(p);
        if (*p == '+') {    /* Add operator */
            p++;
            value1 = *value;
            p = match_expression_level5(p, value);
            if (p == NULL)
                return NULL;
            *value = value1 + *value;
        } else if (*p == '-') { /* Subtract operator */
            p++;
            value1 = *value;
            p = match_expression_level5(p, value);
            if (p == NULL)
                return NULL;
            *value = value1 - *value;
        } else {
            return p;
        }
    }
}

/*
 ** Match expression
 */
const char *match_expression_level5(const char *p, int *value) {
    int value1;
    char c;

    p = match_expression_level6(p, value);
    if (p == NULL)
        return NULL;
    while (1) {
        p = avoid_spaces(p);
        c = *p;
        if (c != '*' && c != '/' && c != '%') return p;
        p++;
        value1 = *value;
        p = match_expression_level6(p, value);
        if (p == NULL)
            return NULL;
        if (c == '*') {  /* Multiply operator */  
            *value = value1 * *value;
        } else if (c == '/') {  /* Division operator */
            if (*value == 0) {
                if (assembler_step == 2)
                    message(1, "division by zero");
                *value = 1;
            }
            *value = (unsigned) value1 / *value;
        } else /*if (*p == '%')*/ {  /* Module operator. */
            if (*value == 0) {
                if (assembler_step == 2)
                    message(1, "modulo by zero");
                *value = 1;
            }
            *value = value1 % *value;
        }
    }
}

/*
 ** Match expression (bottom tier)
 */
const char *match_expression_level6(const char *p, int *value) {
    value_t number;
    int c;
    unsigned shift;
    char *p2;
    struct label MY_FAR *label;

    p = avoid_spaces(p);
    if (*p == '(') {    /* Handle parenthesized expressions */
        p++;
        p = match_expression(p, value);
        if (p == NULL)
            return NULL;
        p = avoid_spaces(p);
        if (*p != ')')
            return NULL;
        p++;
        return p;
    }
    if (*p == '-') {    /* Simple negation */
        p++;
        p = match_expression_level6(p, value);
        if (p == NULL)
            return NULL;
        *value = -*value;
        return p;
    }
    if (*p == '+') {    /* Unary */
        p++;
        p = match_expression_level6(p, value);
        if (p == NULL)
            return NULL;
        return p;
    }
    if (p[0] == '0' && tolower(p[1]) == 'b') {  /* Binary */
        p += 2;
        number = 0;
        while (p[0] == '0' || p[0] == '1' || p[0] == '_') {
            if (p[0] != '_') {
                number <<= 1;
                if (p[0] == '1')
                    number |= 1;
            }
            p++;
        }
        *value = number;
        return p;
    }
    if (p[0] == '0' && tolower(p[1]) == 'x' && isxdigit(p[2])) {  /* Hexadecimal */
        p += 2;
        number = 0;
        while (isxdigit(p[0])) {
            c = toupper(p[0]);
            c = c - '0';
            if (c > 9)
                c -= 7;
            number = (number << 4) | c;
            p++;
        }
        *value = number;
        return p;
    }
    if (p[0] == '$' && isdigit(p[1])) {  /* Hexadecimal */
        /* This is nasm syntax, notice no letter is allowed after $ */
        /* So it's preferrable to use prefix 0x for hexadecimal */
        p += 1;
        number = 0;
        while (isxdigit(p[0])) {
            c = toupper(p[0]);
            c = c - '0';
            if (c > 9)
                c -= 7;
            number = (number << 4) | c;
            p++;
        }
        *value = number;
        return p;
    }
    if (p[0] == '\'' || p[0] == '"') {  /* Character constant */
        number = 0; shift = 0;
        for (c = *p++; *p != '\0' && *p != (char)c; ++p) {
            if (shift < sizeof(number) * 8) {
                number |= (unsigned char)*p << shift;
                shift += 8;
            }
        }
        *value = number;
        if (*p == '\0') {
            message(1, "Missing close quote");
        } else {
            ++p;
        }
        return p;
    }
    if (isdigit(*p)) {   /* Decimal */
        number = 0;
        while (isdigit(p[0])) {
            c = p[0] - '0';
            number = number * 10 + c;
            p++;
        }
        *value = number;
        return p;
    }
    if (*p == '$' && p[1] == '$') { /* Start address */
        p += 2;
        *value = start_address;
        return p;
    }
    if (*p == '$') { /* Current address */
        p++;
        *value = address;
        return p;
    }
    if (isalpha(*p) || *p == '_' || *p == '.') { /* Label */
        if (*p == '.') {
            strcpy(expr_name, global_label);
            p2 = expr_name;
            while (*p2)
                p2++;
        } else {
            p2 = expr_name;
        }
        while (isalpha(*p) || isdigit(*p) || *p == '_' || *p == '.')
            *p2++ = *p++;
        *p2 = '\0';
        for (c = 0; c < 16; c++)
            if (strcmp(expr_name, reg1[c]) == 0)
                return NULL;
        label = find_label(expr_name);
        if (label == NULL) {
            *value = 0;
            undefined++;
            if (assembler_step == 2) {
                message_start(1);
                /* This will be printed twice for `jmp', but once for `jc'. */
                bbprintf(&message_bbb, "Undefined label '%s'", expr_name);
                message_end();
            }
        } else {
            *value = label->value;
        }
        return p;
    }
    return NULL;
}

void emit_bytes(const char *s, int size)  {
    address += size;
    if (assembler_step == 2) {
        if (write(output_fd, s, size) != size) {
            message(1, "error writing to output file");
            exit(3);
        }
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
 ** Search for a match with instruction
 */
const char *match(const char *p, const char *pattern, const char *decode) {
    const char *p2;
    int c;
    int d;
    int bit;
    int qualifier;
    const char *base;

    undefined = 0;
    while (*pattern) {
/*        fputc(*pattern, stdout);*/
        if (*pattern == '%') {  /* Special */
            pattern++;
            if (*pattern == 'd') {  /* Addressing */
                pattern++;
                qualifier = 0;
                if (memcmp(p, "WORD", 4) == 0 && !isalpha(p[4])) {
                    p = avoid_spaces(p + 4);
                    if (*p != '[')
                        return NULL;
                    qualifier = 16;
                } else if (memcmp(p, "BYTE", 4) == 0 && !isalpha(p[4])) {
                    p = avoid_spaces(p + 4);
                    if (*p != '[')
                        return NULL;
                    qualifier = 8;
                }
                if (*pattern == 'w') {
                    pattern++;
                    if (qualifier != 16 && match_register(p, 16, &d) == 0)
                        return NULL;
                } else if (*pattern == 'b') {
                    pattern++;
                    if (qualifier != 8 && match_register(p, 8, &d) == 0)
                        return NULL;
                } else {
                    if (qualifier == 8 && *pattern != '8')
                        return NULL;
                    if (qualifier == 16 && *pattern != '1')
                        return NULL;
                }
                if (*pattern == '8') {
                    pattern++;
                    p2 = match_addressing(p, 8);
                    if (p2 == NULL)
                        return NULL;
                    p = p2;
                } else if (*pattern == '1' && pattern[1] == '6') {
                    pattern += 2;
                    p2 = match_addressing(p, 16);
                    if (p2 == NULL)
                        return NULL;
                    p = p2;
                } else {
                    return NULL;
                }
            } else if (*pattern == 'r') {   /* Register */
                pattern++;
                if (*pattern == '8') {
                    pattern++;
                    p2 = match_register(p, 8, &instruction_register);
                    if (p2 == NULL)
                        return NULL;
                    p = p2;
                } else if (*pattern == '1' && pattern[1] == '6') {
                    pattern += 2;
                    p2 = match_register(p, 16, &instruction_register);
                    if (p2 == NULL)
                        return NULL;
                    p = p2;
                } else {
                    return NULL;
                }
            } else if (*pattern == 'i') {   /* Immediate */
                pattern++;
                if (*pattern == '8') {
                    pattern++;
                    p2 = match_expression(p, &instruction_value);
                    if (p2 == NULL)
                        return NULL;
                    p = p2;
                } else if (*pattern == '1' && pattern[1] == '6') {
                    pattern += 2;
                    p2 = match_expression(p, &instruction_value);
                    if (p2 == NULL)
                        return NULL;
                    p = p2;
                } else {
                    return NULL;
                }
            } else if (*pattern == 'a') {   /* Address for jump */
                pattern++;
                if (*pattern == '8') {
                    pattern++;
                    p = avoid_spaces(p);
                    qualifier = 0;
                    if (memcmp(p, "SHORT", 5) == 0 && isspace(p[5])) {
                        p += 5;
                        qualifier = 1;
                    }
                    p2 = match_expression(p, &instruction_value);
                    if (p2 == NULL)
                        return NULL;
                    if (qualifier == 0) {
                        c = instruction_value - (address + 2);
                        if (undefined == 0 && (c < -128 || c > 127) && memcmp(decode, "xeb", 3) == 0)
                            return NULL;
                    }
                    p = p2;
                } else if (*pattern == '1' && pattern[1] == '6') {
                    pattern += 2;
                    p = avoid_spaces(p);
                    if (memcmp(p, "SHORT", 5) == 0 && isspace(p[5]))
                        p2 = NULL;
                    else
                        p2 = match_expression(p, &instruction_value);
                    if (p2 == NULL)
                        return NULL;
                    p = p2;
                } else {
                    return NULL;
                }
            } else if (*pattern == 's') {   /* Signed immediate */
                pattern++;
                if (*pattern == '8') {
                    pattern++;
                    p = avoid_spaces(p);
                    qualifier = 0;
                    if (memcmp(p, "BYTE", 4) == 0 && isspace(p[4])) {
                        p += 4;
                        qualifier = 1;
                    }
                    p2 = match_expression(p, &instruction_value);
                    if (p2 == NULL)
                        return NULL;
                    if (qualifier == 0) {
                        c = instruction_value;
                        if (undefined != 0)
                            return NULL;
                        if (undefined == 0 && (c < -128 || c > 127))
                            return NULL;
                    }
                    p = p2;
                } else {
                    return NULL;
                }
            } else if (*pattern == 'f') {   /* FAR pointer */
                pattern++;
                if (memcmp(p, "SHORT", 5) == 0 && isspace(p[5])) {
                    return NULL;
                } else if (*pattern == '3' && pattern[1] == '2') {
                    pattern += 2;
                    p2 = match_expression(p, &instruction_value2);
                    if (p2 == NULL)
                        return NULL;
                    if (*p2 != ':')
                        return NULL;
                    p = p2 + 1;
                    p2 = match_expression(p, &instruction_value);
                    if (p2 == NULL)
                        return NULL;
                    p = p2;
                } else {
                    return NULL;
                }
            } else {
                return NULL;
            }
            continue;
        }
        if (toupper(*p) != *pattern)
            return NULL;
        p++;
        if (*pattern == ',')    /* Allow spaces after comma */
            p = avoid_spaces(p);
        pattern++;
    }

    /*
     ** Instruction properly matched, now generate binary
     */
    base = decode;
    while (*decode) {
        decode = avoid_spaces(decode);
        if (decode[0] == 'x') { /* Byte */
            c = toupper(decode[1]);
            c -= '0';
            if (c > 9)
                c -= 7;
            d = toupper(decode[2]);
            d -= '0';
            if (d > 9)
                d -= 7;
            c = (c << 4) | d;
            emit_byte(c);
            decode += 3;
        } else {    /* Binary */
            if (*decode == 'b')
                decode++;
            bit = 0;
            c = 0;
            d = 0;
            while (bit < 8) {
                if (decode[0] == '0') { /* Zero */
                    decode++;
                    bit++;
                } else if (decode[0] == '1') {  /* One */
                    c |= 0x80 >> bit;
                    decode++;
                    bit++;
                } else if (decode[0] == '%') {  /* Special */
                    decode++;
                    if (decode[0] == 'r') { /* Register field */
                        decode++;
                        if (decode[0] == '8')
                            decode++;
                        else if (decode[0] == '1' && decode[1] == '6')
                            decode += 2;
                        c |= instruction_register << (5 - bit);
                        bit += 3;
                    } else if (decode[0] == 'd') {  /* Addressing field */
                        if (decode[1] == '8')
                            decode += 2;
                        else
                            decode += 3;
                        if (bit == 0) {
                            c |= instruction_addressing & 0xc0;
                            bit += 2;
                        } else {
                            c |= instruction_addressing & 0x07;
                            bit += 3;
                            d = 1;
                        }
                    } else if (decode[0] == 'i' || decode[0] == 's') {
                        if (decode[1] == '8') {
                            decode += 2;
                            c = instruction_value;
                            break;
                        } else {
                            decode += 3;
                            c = instruction_value;
                            instruction_offset = instruction_value >> 8;
                            instruction_offset_width = 1;
                            d = 1;
                            break;
                        }
                    } else if (decode[0] == 'a') {
                        if (decode[1] == '8') {
                            decode += 2;
                            c = instruction_value - (address + 1);
                            if (assembler_step == 2 && (c < -128 || c > 127))
                                message(1, "short jump too long");
                            break;
                        } else {
                            decode += 3;
                            c = instruction_value - (address + 2);
                            instruction_offset = c >> 8;
                            instruction_offset_width = 1;
                            d = 1;
                            break;
                        }
                    } else if (decode[0] == 'f') {
                        decode += 3;
                        emit_byte(instruction_value);
                        c = instruction_value >> 8;
                        instruction_offset = instruction_value2;
                        instruction_offset_width = 2;
                        d = 1;
                        break;
                    } else {
                        message(1, "decode: internal error 2");
                        exit(2);
                    }
                } else {
                    message_start(1);
                    bbprintf(&message_bbb, "decode: internal error 1 (%s)", base);
                    message_end();
                    exit(2);
                    break;
                }
            }
            emit_byte(c);
            if (d == 1) {
                d = 0;
                if (instruction_offset_width >= 1) {
                    emit_byte(instruction_offset);
                }
                if (instruction_offset_width >= 2) {
                    emit_byte(instruction_offset >> 8);
                }
            }
        }
    }
    return p;
}

/*
 ** Make a string lowercase
 */
void to_lowercase(char *p) {
    while (*p) {
        *p = tolower(*p);
        p++;
    }
}

/*
 ** Separate a portion of entry up to the first space
 */
void separate(void) {
    char *p2;

    while (*p && isspace(*p))
        p++;
    prev_p = p;
    p2 = part;
    while (*p && !isspace(*p) && *p != ';')
        *p2++ = *p++;
    *p2 = '\0';
    while (*p && isspace(*p))
        p++;
}

/*
 ** Check for end of line
 */
void check_end(const char *p) {
    p = avoid_spaces(p);
    if (*p && *p != ';') {
        message(1, "extra characters at end of line");
    }
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

/*
 ** Generate a message
 */
void message_start(int error) {
    const char *msg_prefix;
    if (error) {
        msg_prefix = "Error: ";  /* !! Also display current input_filename. */
        errors++;
    } else {
        msg_prefix = "Warning: ";
        warnings++;
    }
    if (!message_bbb.data) {
        message_flush(NULL);  /* Flush listing_fd. */
        message_bbb.data = (void*)1;
    }
    bbprintf(&message_bbb, "%s", msg_prefix);
}

void message_end(void) {
    if (line_number) {
      /* We must use \r\n, because this will end up on stderr, and on DOS
       * with O_BINARY, just a \n doesn't break the line properly.
       */
      bbprintf(&message_bbb, " at line %u\r\n", line_number);
    } else {
      bbprintf(&message_bbb, "\r\n");
    }
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
void process_instruction()
{
    const char *p2 = NULL;
    const char *p3;
    int c;

    if (strcmp(part, "DB") == 0) {  /* Define byte */
        while (1) {
            p = avoid_spaces(p);
            if (*p == '\'' || *p == '"') {    /* ASCII text, quoted. */
                c = *p++;
                for (p2 = p; *p2 != '\0' && *p2 != (char)c; ++p2) {}
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
                p = match_expression(p, &instruction_value);
                if (p == NULL) {
                    message(1, "Bad expression");
                    break;
                }
                p = avoid_spaces(p);
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
    }
    if (strcmp(part, "DW") == 0) {  /* Define word */
        while (1) {
            p2 = match_expression(p, &instruction_value);
            if (p2 == NULL) {
                message(1, "Bad expression");
                break;
            }
            emit_byte(instruction_value);
            emit_byte(instruction_value >> 8);
            p = avoid_spaces(p2);
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
        c = 0;
        while (instruction_set[c] != NULL) {
            if (strcmp(part, instruction_set[c]) == 0) {
                p2 = instruction_set[c];
                while (*p2++) ;
                p3 = p2;
                while (*p3++) ;

                p2 = match(p, p2, p3);
                if (p2 != NULL) {
                    p = p2;
                    break;
                }
            }
            c++;
        }
        if (instruction_set[c] == NULL) {
            message_start(1);
            bbprintf(&message_bbb, "Undefined instruction '%s %s'", part, p);
            message_end();
            break;
        } else {
            p = p2;
            separate();
        }
    }
}

/*
 ** Reset current address.
 ** Called anytime the assembler needs to generate code.
 */
void reset_address()
{
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

char line_buf[512];

#if !CONFIG_CPU_UNALIGN
struct guess_align_assembly_info_helper { off_t o; char c; };
typedef char guess_align_assembly_info[sizeof(struct guess_align_assembly_info_helper) - sizeof(off_t)];
#endif

struct assembly_info {
    off_t file_offset;  /* Largest alignment first, to save size. */
    int level;
    int avoid_level;
    int line_number;
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
    assembly_p->level = 0;
    assembly_p->avoid_level = -1;
    assembly_p->line_number = 0;
    assembly_p->file_offset = 0;
    aip = assembly_p;
    assembly_p->zero = 0;
    strcpy(assembly_p->input_filename, input_filename);
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
        aip = (struct assembly_info*)(p - (char*)&((struct assembly_info*)0)->zero);
    }
    return aip;
}

/*
 ** Do an assembler step
 */
void do_assembly(const char *input_filename) {
    struct assembly_info *aip;
    const char *p2;
    const char *p3;
    char *line;
    char *linep;
    char *liner;
    char *line_rend;
    int level;
    int avoid_level;
    int times;
    int base;
    int include;
    int align;
    int got;
    int input_fd;

    assembly_p = (struct assembly_info*)assembly_stack;  /* Clear the stack. */

  do_assembly_push:
    line_number = 0;  /* Global variable. */
    if (!(aip = assembly_push(input_filename))) {
        message(1, "assembly stack overflow, too many pending %INCLUDE files");
        return;
    }

  do_open_again:
    line_number = 0;  /* Global variable. */
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
    while (linep) {  /* Read and process next line from input. */
        for (p = line = linep; p != line_rend && *p != '\n'; ++p) {}
        if (p == line_rend) {
            if (line != line_buf) {
                if (line_rend - line > (int)(sizeof(line_buf) - (sizeof(line_buf) >> 2))) goto line_too_long;  /* Too much copy per line (thus too slow). This won't be triggered, because the `>= MAX_SIZE' check triggers first. */
                for (liner = line_buf, p = line; p != line_rend; *liner++ = *p++) {}
                p = line_rend = liner;
                line = linep = line_buf;
            }
            if ((got = read(input_fd, line_rend, line_buf + sizeof(line_buf) - line_rend)) < 0) {
                message(1, "error reading assembly file");
                break;
            }
            if (got == 0) {  /* End of file (EOF). */
              if (line_rend == line_buf) break;
              *line_rend = '\0';
              linep = NULL;
              goto after_line_read;
            }
            line_rend += got;
            for (; p != line_rend && *p != '\n'; ++p) {}
            if (p == line_rend) goto line_too_long;
        }
        *(char*)p = '\0';  /* Change trailing '\n' to '\0'. */
        linep = (char*)p + 1;
       after_line_read:

        line_number++;
        p = line;
        while (*p) {
            if (*p == '\'' && *(p - 1) != '\\') {
                p++;
                while (*p && *p != '\'' && *(p - 1) != '\\')
                    p++;
            } else if (*p == '"' && *(p - 1) != '\\') {
                p++;
                while (*p && *p != '"' && *(p - 1) != '\\')
                    p++;
            } else if (*p == ';') {
                while (*p)
                    p++;
                break;
            }
            *(char*)p = toupper(*p);
            p++;
        }
        if (p != line && *(p - 1) == '\r')
            *(char*)--p = '\0';
        if (p - line >= MAX_SIZE) { line_too_long:
            message(1, "assembly line too long");
            break;
        }

        base = address;
        g = generated;
        include = 0;

        while (1) {
            p = line;
            separate();
            if (part[0] == '\0' && (*p == '\0' || *p == ';'))    /* Empty line */
                break;
            if (part[0] != '\0' && part[strlen(part) - 1] == ':') {  /* Label */
                part[strlen(part) - 1] = '\0';
                if (part[0] == '.') {
                    strcpy(name, global_label);
                    strcat(name, part);
                } else {
                    strcpy(name, part);
                    strcpy(global_label, name);
                }
                separate();
                if (avoid_level == -1 || level < avoid_level) {
                    if (strcmp(part, "EQU") == 0) {
                        p2 = match_expression(p, &instruction_value);
                        if (p2 == NULL) {
                            message(1, "bad expression");
                        } else {
                            if (assembler_step == 1) {
                                if (find_label(name)) {
                                    message_start(1);
                                    bbprintf(&message_bbb, "Redefined label '%s'", name);
                                    message_end();
                                } else {
                                    last_label = define_label(name, instruction_value);
                                }
                            } else {
                                last_label = find_label(name);
                                if (last_label == NULL) {
                                    message_start(1);
                                    bbprintf(&message_bbb, "Inconsistency, label '%s' not found", name);
                                    message_end();
                                } else {
                                    if (last_label->value != instruction_value) {
#ifdef DEBUG
/*                                        message_start(1); bbprintf(&message_bbb, "Woops: label '%s' changed value from %04x to %04x", last_label->name, last_label->value, instruction_value); message_end(); */
#endif
                                        change = 1;
                                    }
                                    last_label->value = instruction_value;
                                }
                            }
                            check_end(p2);
                        }
                        break;
                    }
                    if (first_time == 1) {
#ifdef DEBUG
                        /*                        message_start(1); bbprintf(&message_bbb, "First time '%s'", line); message_end();  */
#endif
                        first_time = 0;
                        reset_address();
                    }
                    if (assembler_step == 1) {
                        if (find_label(name)) {
                            message_start(1);
                            bbprintf(&message_bbb, "Redefined label '%s'", name);
                            message_end();
                        } else {
                            last_label = define_label(name, address);
                        }
                    } else {
                        last_label = find_label(name);
                        if (last_label == NULL) {
                            message_start(1);
                            bbprintf(&message_bbb, "Inconsistency, label '%s' not found", name);
                            message_end();
                        } else {
                            if (last_label->value != address) {
#ifdef DEBUG
/*                                message_start(1); bbprintf(&message_bbb, "Woops: label '%s' changed value from %04x to %04x", last_label->name, last_label->value, address); message_end(); */
#endif
                                change = 1;
                            }
                            last_label->value = address;
                        }

                    }
                }
            }
            if (strcmp(part, "%IF") == 0) {
                level++;
                if (avoid_level != -1 && level >= avoid_level)
                    break;
                undefined = 0;
                p = match_expression(p, &instruction_value);
                if (p == NULL) {
                    message(1, "Bad expression");
                } else if (undefined) {
                    message(1, "Cannot use undefined labels");
                }
                if (instruction_value != 0) {
                    ;
                } else {
                    avoid_level = level;
                }
                check_end(p);
                break;
            }
            if (strcmp(part, "%IFDEF") == 0) {
                level++;
                if (avoid_level != -1 && level >= avoid_level)
                    break;
                separate();
                if (find_label(part) != NULL) {
                    ;
                } else {
                    avoid_level = level;
                }
                check_end(p);
                break;
            }
            if (strcmp(part, "%IFNDEF") == 0) {
                level++;
                if (avoid_level != -1 && level >= avoid_level)
                    break;
                separate();
                if (find_label(part) == NULL) {
                    ;
                } else {
                    avoid_level = level;
                }
                check_end(p);
                break;
            }
            if (strcmp(part, "%ELSE") == 0) {
                if (avoid_level != -1 && level > avoid_level)
                    break;
                if (avoid_level == level) {
                    avoid_level = -1;
                } else if (avoid_level == -1) {
                    avoid_level = level;
                }
                check_end(p);
                break;
            }
            if (strcmp(part, "%ENDIF") == 0) {
                if (avoid_level == level)
                    avoid_level = -1;
                level--;
                check_end(p);
                break;
            }
            if (avoid_level != -1 && level >= avoid_level) {
#ifdef DEBUG
                /* message_start(); bbprintf(&message_bbb, "Avoiding '%s'", line); message_end(); */
#endif
                break;
            }
            if (strcmp(part, "USE16") == 0) {
                break;
            }
            if (strcmp(part, "CPU") == 0) {
                p = avoid_spaces(p);
                if (memcmp(p, "8086", 4) != 0)
                    message(1, "Unsupported processor requested");
                break;
            }
            if (strcmp(part, "BITS") == 0) {
                p = avoid_spaces(p);
                undefined = 0;
                p = match_expression(p, &instruction_value);
                if (p == NULL) {
                    message(1, "Bad expression");
                } else if (undefined) {
                    message(1, "Cannot use undefined labels");
                } else if (instruction_value != 16) {
                    message(1, "Unsupported BITS requested");
                } else {
                    check_end(p);
                }
                break;
            }
            if (strcmp(part, "%INCLUDE") == 0) {
                separate();
                check_end(p);
                if ((part[0] != '"' && part[0] != '\'') || part[strlen(part) - 1] != part[0]) {
                    message(1, "Missing quotes on %include");
                    break;
                }
                include = 1;
                break;
            }
            if (strcmp(part, "INCBIN") == 0) {
                separate();
                check_end(p);
                if ((part[0] != '"' && part[0] != '\'') || part[strlen(part) - 1] != part[0]) {
                    message(1, "Missing quotes on incbin");
                    break;
                }
                include = 2;
                break;
            }
            if (strcmp(part, "ORG") == 0) {
                p = avoid_spaces(p);
                undefined = 0;
                p = match_expression(p, &instruction_value);
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
                break;
            }
            if (strcmp(part, "ALIGN") == 0) {
                p = avoid_spaces(p);
                undefined = 0;
                p = match_expression(p, &instruction_value);
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
                    check_end(p);
                }
                break;
            }
            if (first_time == 1) {
#ifdef DEBUG
                /* message_start(1); bbprintf(&message_bbb, "First time '%s'", line); message_end(); */
#endif
                first_time = 0;
                reset_address();
            }
            times = 1;
            if (strcmp(part, "TIMES") == 0) {
                undefined = 0;
                p = match_expression(p, &instruction_value);
                if (p == NULL) {
                    message(1, "Bad expression");
                    break;
                }
                if (undefined) {
                    message(1, "Cannot use undefined labels");
                    break;
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
            break;
        }
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
            bbprintf(&message_bbb /* listing_fd */, "  %05d %s\r\n", line_number, line);
        }
        if (include == 1) {
            if (linep != NULL && (aip->file_offset = lseek(input_fd, linep - line_rend, SEEK_CUR)) < 0) {
                message(1, "Cannot seek in source file");
                close(input_fd);
                return;
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
    close(input_fd);
    if ((aip = assembly_pop(aip)) != NULL) goto do_open_again;  /* Continue processing the input file which %INCLUDE()d the current input file. */
}

/*
 ** Main program
 */
int main(int argc, char **argv) {
    int c;
    int d;
    const char *p;
    char *ifname;

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
            d = tolower(argv[c][1]);
            if (d == 'f') { /* Format */
                c++;
                if (c >= argc) {
                    message(1, "no argument for -f");
                    return 1;
                } else {
                    to_lowercase(argv[c]);
                    if (strcmp(argv[c], "bin") == 0) {
                        default_start_address = 0;
                    } else if (strcmp(argv[c], "com") == 0) {
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
            } else if (d == 'd') {  /* Define label */
                p = argv[c] + 2;
                while (*p && *p != '=') {
                    *(char*)p = toupper(*p);
                    p++;
                }
                if (*p == '=') {
                    *(char*)p++ = 0;
                    undefined = 0;
                    p = match_expression(p, &instruction_value);
                    if (p == NULL) {
                        message(1, "Bad expression");
                        return 1;
                    } else if (undefined) {
                        message(1, "Cannot use undefined labels");
                        return 1;
                    } else {
                        define_label(argv[c] + 2, instruction_value);
                    }
                }
                c++;
            } else {
                message_start(1);
                bbprintf(&message_bbb, "unknown argument %s", argv[c]);
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
    if (!errors) {

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
                bbprintf(&message_bbb /* listing_fd */, "\r\n%05d ERRORS FOUND\r\n", errors);
                bbprintf(&message_bbb /* listing_fd */, "%05d WARNINGS FOUND\r\n\r\n", warnings);
                bbprintf(&message_bbb /* listing_fd */, "%05d PROGRAM BYTES\r\n\r\n", bytes);
                if (label_list != NULL) {
                    bbprintf(&message_bbb /* listing_fd */, "%-20s VALUE/ADDRESS\r\n\r\n", "LABEL");
                    print_labels_sorted_to_listing_fd(label_list);
                }
            }
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
            if (errors) {
                remove(output_filename);
                if (listing_filename != NULL)
                    remove(listing_filename);
                return 1;
            }
        } while (change) ;

        return 0;
    }

    return 1;
}
