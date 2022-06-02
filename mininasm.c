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
 **   $ pts-tcc -s -O2 -W -Wall -o mininasm.tcc mininasm.c ins.c && ls -ld mininasm.tcc
 **
 **   $ dosmc -mt mininasm.c ins.c bbprintf.c && ls -ld mininasm.com
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
typedef struct FILE FILE;
extern FILE *stderr;
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#define open2(pathname, flags) open(pathname, flags)
#endif
#endif

#ifndef O_BINARY  /* Unix. */
#define O_BINARY 0
#endif

#ifdef __DOSMC__
__LINKER_FLAG(stack_size__0x800)  /* !! Make sure it is enough. */
/* Below is a simple malloc implementation using an arena which is never
 * freed. Blocks are rounded up to paragraph (16-byte) boundary.
 * !! Don't round up blocks.
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
"mov ax, ds" \
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
#else
#define MY_FAR
#define strcpy_far(dest, src) strcpy(dest, src)
#define strcmp_far(s1, s2) strcmp(s1, s2)
#define malloc_far(size) malloc(size)
#define malloc_init() do {} while (0)
#endif

#include "bbprintf.h"

/* Example usage:
 * static const STRING_WITHOUT_NUL(msg, "Hello, World!\r\n$");
 * ... printmsgx(msg);
 */
#define MY_STRING_WITHOUT_NUL(name, value) char name[sizeof(value) - 1] = value


#define DEBUG

char *input_filename;
int line_number;

char *output_filename;
int output_fd;

char *listing_filename;
int listing_fd = -1;

int assembler_step;
int default_start_address;
int start_address;
int address;
int first_time;

int instruction_addressing;
int instruction_offset;
int instruction_offset_width;

int instruction_register;

int instruction_value;
int instruction_value2;

#define MAX_SIZE        256

char part[MAX_SIZE];
char name[MAX_SIZE];
char expr_name[MAX_SIZE];
char global_label[MAX_SIZE];
char *prev_p;
char *p;

char *g;
char generated[8];

int errors;
int warnings;  /* !! remove this, currently there are no possible warnings */
int bytes;
int change;
int change_number;

struct label {
    struct label MY_FAR *left;
    struct label MY_FAR *right;
    int value;
    char name[1];
};

struct label MY_FAR *label_list;
struct label MY_FAR *last_label;
int undefined;

extern char *instruction_set[];

char *reg1[16] = {
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

struct bbprintf_buf message_bbb;
void message(int error, const char *message);
void message_start(int error);
void message_end(void);
char *match_register(), *match_expression(),
     *match_expression_level1(), *match_expression_level2(),
     *match_expression_level3(), *match_expression_level4(),
     *match_expression_level5(), *match_expression_level6();

#ifdef __DESMET__
/* Work around bug in DeSmet 3.1N runtime: closeall() overflows buffer and clobbers exit status */
#define exit(status) _exit(status)
#endif

/*
 ** Define a new label
 */
struct label MY_FAR *define_label(name, value)
    char *name;
    int value;
{
    struct label MY_FAR *label;
    struct label MY_FAR *explore;
    int c;

    /* Allocate label */
    label = (struct label MY_FAR*)malloc_far((size_t)&((struct label*)0)->name + 1 + strlen(name));
    if (label == NULL) {
        message(1, "Out of memory for label");
        exit(1);
        return NULL;
    }

    /* Fill label */
    label->left = NULL;
    label->right = NULL;
    label->value = value;
    strcpy_far(label->name, name);

    /* Populate binary tree */
    if (label_list == NULL) {
        label_list = label;
    } else {
        explore = label_list;
        while (1) {
            c = strcmp_far(label->name, explore->name);
            if (c < 0) {
                if (explore->left == NULL) {
                    explore->left = label;
                    break;
                }
                explore = explore->left;
            } else if (c > 0) {
                if (explore->right == NULL) {
                    explore->right = label;
                    break;
                }
                explore = explore->right;
            }
        }
    }
    return label;
}

/*
 ** Find a label
 */
struct label MY_FAR *find_label(name)
    char *name;
{
    struct label MY_FAR *explore;
    int c;

    /* Follows a binary tree */
    explore = label_list;
    while (explore != NULL) {
        c = strcmp_far(name, explore->name);
        if (c == 0)
            return explore;
        if (c < 0)
            explore = explore->left;
        else
            explore = explore->right;
    }
    return NULL;
}

/*
 ** Print labels sorted to listing_fd (already done by binary tree).
 */
void print_labels_sorted_to_listing_fd(node)
    struct label MY_FAR *node;
{
    /* !! Limit recursion depth for stack usage by doing iteration of only left or right node. */
    if (node->left != NULL)
        print_labels_sorted_to_listing_fd(node->left);
    strcpy_far(global_label, node->name);
    bbprintf(&message_bbb, "%-20s %04x\r\n", global_label, node->value);
    if (node->right != NULL)
        print_labels_sorted_to_listing_fd(node->right);
}

/*
 ** Avoid spaces in input
 */
char *avoid_spaces(p)
    char *p;
{
    while (isspace(*p))
        p++;
    return p;
}

/*
 ** Match addressing
 */
char *match_addressing(p, width)
    char *p;
    int width;
{
    int reg;
    int reg2;
    char *p2;
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
int islabel(c)
    int c;
{
    return isalpha(c) || isdigit(c) || c == '_' || c == '.';
}

/*
 ** Match register
 */
char *match_register(p, width, value)
    char *p;
    int width;
    int *value;
{
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
 ** Read character for string or character literal
 */
char *read_character(p, c)
    char *p;
    int *c;
{
    if (*p == '\\') {
        p++;
        if (*p == '\'') {
            *c = '\'';
            p++;
        } else if (*p == '\"') {
            *c = '"';
            p++;
        } else if (*p == '\\') {
            *c = '\\';
            p++;
        } else if (*p == 'a') {
            *c = 0x07;
            p++;
        } else if (*p == 'b') {
            *c = 0x08;
            p++;
        } else if (*p == 't') {
            *c = 0x09;
            p++;
        } else if (*p == 'n') {
            *c = 0x0a;
            p++;
        } else if (*p == 'v') {
            *c = 0x0b;
            p++;
        } else if (*p == 'f') {
            *c = 0x0c;
            p++;
        } else if (*p == 'r') {
            *c = 0x0d;
            p++;
        } else if (*p == 'e') {
            *c = 0x1b;
            p++;
        } else if (*p >= '0' && *p <= '7') {
            *c = 0;
            while (*p >= '0' && *p <= '7') {
                *c = *c * 8 + (*p - '0');
                p++;
            }
        } else {
            p--;
            message(1, "bad escape inside string");
        }
    } else {
        *c = *p;
        p++;
    }
    return p;
}

/*
 ** Match expression (top tier)
 */
char *match_expression(p, value)
    char *p;
    int *value;
{
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
char *match_expression_level1(p, value)
    char *p;
    int *value;
{
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
char *match_expression_level2(p, value)
    char *p;
    int *value;
{
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
char *match_expression_level3(p, value)
    char *p;
    int *value;
{
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
char *match_expression_level4(p, value)
    char *p;
    int *value;
{
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
char *match_expression_level5(p, value)
    char *p;
    int *value;
{
    int value1;

    p = match_expression_level6(p, value);
    if (p == NULL)
        return NULL;
    while (1) {
        p = avoid_spaces(p);
        if (*p == '*') {    /* Multiply operator */
            p++;
            value1 = *value;
            p = match_expression_level6(p, value);
            if (p == NULL)
                return NULL;
            *value = value1 * *value;
        } else if (*p == '/') { /* Division operator */
            p++;
            value1 = *value;
            p = match_expression_level6(p, value);
            if (p == NULL)
                return NULL;
            if (*value == 0) {
                if (assembler_step == 2)
                    message(1, "division by zero");
                *value = 1;
            }
            *value = (unsigned) value1 / *value;
        } else if (*p == '%') { /* Modulo operator */
            p++;
            value1 = *value;
            p = match_expression_level6(p, value);
            if (p == NULL)
                return NULL;
            if (*value == 0) {
                if (assembler_step == 2)
                    message(1, "modulo by zero");
                *value = 1;
            }
            *value = value1 % *value;
        } else {
            return p;
        }
    }
}

/*
 ** Match expression (bottom tier)
 */
char *match_expression_level6(p, value)
    char *p;
    int *value;
{
    int number;
    int c;
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
    if (p[0] == '\'') { /* Character constant */
        p++;
        p = read_character(p, value);
        if (p[0] != '\'') {
            message(1, "Missing apostrophe");
        } else {
            p++;
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
char *match(p, pattern, decode)
    char *p;
    char *pattern;
    char *decode;
{
    char *p2;
    int c;
    int d;
    int bit;
    int qualifier;
    char *base;

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
void to_lowercase(p)
    char *p;
{
    while (*p) {
        *p = tolower(*p);
        p++;
    }
}

/*
 ** Separate a portion of entry up to the first space
 */
void separate(void)
{
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
void check_end(p)
    char *p;
{
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
        msg_prefix = "Error: ";
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
      bbprintf(&message_bbb, " at line %d\r\n", line_number);
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
    char *p2 = NULL;
    char *p3;
    int c;

    if (strcmp(part, "DB") == 0) {  /* Define byte */
        while (1) {
            p = avoid_spaces(p);
            if (*p == '"') {    /* ASCII text */
                p++;
                while (*p && *p != '"') {
                    p = read_character(p, &c);
                    emit_byte(c);
                }
                if (*p) {
                    p++;
                } else {
                    message(1, "unterminated string");
                }
            } else {
                p2 = match_expression(p, &instruction_value);
                if (p2 == NULL) {
                    message(1, "bad expression");
                    break;
                }
                emit_byte(instruction_value);
                p = p2;
            }
            p = avoid_spaces(p);
            if (*p == ',') {
                p++;
                continue;
            }
            check_end(p);
            break;
        }
        return;
    }
    if (strcmp(part, "DW") == 0) {  /* Define word */
        while (1) {
            p2 = match_expression(p, &instruction_value);
            if (p2 == NULL) {
                message(1, "bad expression");
                break;
            }
            emit_byte(instruction_value);
            emit_byte(instruction_value >> 8);
            p = avoid_spaces(p2);
            if (*p == ',') {
                p++;
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
void incbin(fname)
    char *fname;
{
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

/*
 ** Do an assembler step
 */
void do_assembly(fname)
    char *fname;
{
    char *p2;
    char *p3;
    char *pfname;
    char *line;
    char *linep;
    char *liner;
    char *line_rend;
    int level;
    int avoid_level;
    int times;
    int base;
    int pline;
    int include;
    int align;
    int got;
    int input_fd;

    malloc_init();

    if ((input_fd = open2(fname, O_RDONLY | O_BINARY)) < 0) {
        message_start(1);
        bbprintf(&message_bbb, "cannot open '%s' for input", fname);
        message_end();
        return;
    }

    pfname = input_filename;
    pline = line_number;
    input_filename = fname;
    level = 0;
    avoid_level = -1;
    global_label[0] = '\0';
    line_number = 0;
    base = 0;
    linep = line_rend = line_buf;
    while (linep) {  /* Read and process next line from input. */
        for (p = line = linep; p != line_rend && *p != '\n'; ++p) {}
        if (p == line_rend) {
            if (line != line_buf) {
                if (line_rend - line > (int)(sizeof(line_buf) - (sizeof(line_buf) >> 2))) goto line_too_long;  /* Too much copy per line (thus too slow). This won't be triggered, because the `>= MAX_SIZE' check triggers first. */
                for (liner = line_buf, p = line; p != line_rend; *liner++ = *p++) {}
                line_rend = p = liner;
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
        *p = '\0';  /* Change trailing '\n' to '\0'. */
        linep = p + 1;
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
            *p = toupper(*p);
            p++;
        }
        if (p != line && *(p - 1) == '\r')
            *--p = '\0';
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
            if (linep != NULL && lseek(input_fd, linep - line_rend, SEEK_CUR) < 0) {
                message(1, "Cannot seek in source file");
            } else {
                part[strlen(part) - 1] = '\0';
                /* !! impose a limit on recursion depth for an upper limit of stack use */
                do_assembly(part + 1);
                /* Clear line read buffer, it has been clobbered by the inner do_assembly(...) call. */
                if (linep) linep = line_rend = line_buf;
            }
        } else if (include == 2) {
            part[strlen(part) - 1] = '\0';
            incbin(part + 1);
        }
    }
    close(input_fd);
    line_number = pline;
    input_filename = pfname;
}

/*
 ** Main program
 */
int main(argc, argv)
    int argc;
    char *argv[];
{
    int c;
    int d;
    char *p;
    char *ifname;

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
                    *p = toupper(*p);
                    p++;
                }
                if (*p == '=') {
                    *p++ = 0;
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
