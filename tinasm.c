/*
 ** tinasm: NASM-compatible mini assembler for 8086
 ** tinasm modifications by pts@fazekas.hu at Mon Jun 20 10:22:13 CEST 2022
 **
 ** Based on Tinyasm (8086/8088 assembler for DOS) by Oscar Toledo G:
 ** https://github.com/nanochess/tinyasm/commit/2f213d809b685ccc5bccf52e2dbdd25dceedadd7
 ** Tinyasm Creation date: Oct/01/2019.
 ** tinasm.c is a concatenation of tinyasm.c and ins.c from the commit above.
 **
 ** The goal of tinasm is to provide critical bugfixes, portability
 ** improvements (to more systems and C and C++ compilers) and deterministic
 ** cross-compilation over Tinyasm. For NASM compatibility improvements,
 ** memory usage optimizations, stack safety fixes, see mininasm.c in
 ** https://github.com/pts/mininasm instead.
 **
 ** Compilation instructions (pick any one):
 **
 **   $ gcc -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o tinasm tinasm.c && ls -ld tinasm
 **
 **   $ g++ -ansi -pedantic -s -Os -W -Wall -o tinasm tinasm.c && ls -ld tinasm
 **
 **   $ pts-tcc -s -O2 -W -Wall -o tinasm.tcc tinasm.c && ls -ld tinasm.tcc
 **
 **   $ pts-tcc64 -m64 -s -O2 -W -Wall -o tinasm.tcc64 tinasm.c && ls -ld tinasm.tcc64
 **
 **   $ owcc -bdos -o tinasm.exe -mcmodel=l -Os -s -fno-stack-check -march=i86 -W -Wall -Wextra tinasm.c && ls -ld tinasm.exe
 **
 **   $ owcc -bwin32 -Wl,runtime -Wl,console=3.10 -o tinasm.win32.exe -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra tinasm.c nouser32.c && ls -ld tinasm.win32.exe
 **
 **   $ i686-w64-mingw32-gcc -m32 -mconsole -ansi -pedantic -s -Os -W -Wall -march=i386 -o tinasm.win32msvcrt.exe tinasm.c && ls -ld tinasm.win32msvcrt.exe
 **
 **   $ wine tcc.exe -m32 -mconsole -s -O2 -W -Wall -o tinasm.win32msvcrt_tcc.exe tinasm.c && ls -ld tinasm.win32msvcrt_tcc.exe
 **
 **   (DeSmet C 3.1N may also work.)
 */

#ifdef __TINYC__  /* Works with tcc, pts-tcc (Linux i386 target), pts-tcc64 (Linux amd64 target) and tcc.exe (Win32, Windows i386 target). */
#  ifdef _WIN32
#    ifndef __i386__
#      error Windows is supported only on i386.
#    endif
#  else
#    ifdef _WIN64
#      error Windows is supported only on i386.
#    endif
#  endif
#  define ATTRIBUTE_NORETURN __attribute__((noreturn))
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef signed char int8_t;
typedef short int16_t;
typedef int int32_t;
#  ifdef __SIZE_TYPE__
typedef __SIZE_TYPE__ size_t;
#  else
typedef unsigned long size_t; /* Good for __i386__ (4 bytes) and __amd64__ (8 bytes). */
#  endif
#  define NULL ((void*)0)
#  ifdef _WIN32
struct _iobuf {
  char *_ptr;
  int _cnt;
  char *_base;
  int _flag;
  int _file;
  int _charbuf;
  int _bufsiz;
  char *_tmpfname;
};
typedef struct _iobuf FILE;
extern FILE (*_imp___iob)[];
#    define stderr (&(*_imp___iob) [2])
#    define __cdecl __attribute__((__cdecl__))
#  else
#    define __cdecl
  typedef struct FILE FILE;
  extern FILE *stderr;
#  endif
void *__cdecl malloc(size_t size);
size_t __cdecl strlen(const char *s);
int __cdecl fprintf(FILE *stream, const char *format, ...);
int __cdecl sprintf(char *str, const char *format, ...);
FILE *__cdecl fopen(const char *path, const char *mode);
size_t __cdecl fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
size_t __cdecl fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
char *__cdecl fgets(char *s, int size, FILE *stream);
int __cdecl fclose(FILE *stream);
int __cdecl remove(const char *pathname);
void ATTRIBUTE_NORETURN __cdecl exit(int status);
char *__cdecl strcpy(char *dest, const char *src);
int __cdecl strcmp(const char *s1, const char *s2);
char *__cdecl strcat(char *dest, const char *src);
int __cdecl memcmp(const void *s1, const void *s2, size_t n);
int __cdecl isalpha(int c);
int __cdecl isspace(int c);
int __cdecl isdigit(int c);
int __cdecl isxdigit(int c);
int __cdecl tolower(int c);
int __cdecl toupper(int c);
#  ifdef _WIN32
#    define O_BINARY 0x8000
int __cdecl setmode(int _FileHandle,int _Mode);
#  endif
#else
#  include <stdio.h>
#  include <stdlib.h>
#  include <string.h>
#  include <ctype.h>
#  ifdef MSDOS
#    include <fcntl.h>  /* O_BINARY. */
#    include <unistd.h>  /* setmode(...). */
#  endif
#  ifdef _WIN32
#    include <fcntl.h>  /* O_BINARY. */
#    include <io.h>  /* setmode(...). Also in <unistd.h> in some systems. */
#  endif
#endif


#define DEBUG

#define GET_INT16(value) (int)(sizeof(short) == 2 ? (short)(value) : (short)(((short)(value) & 0x7fff) | -((short)(value) & 0x8000U)))  /* Sign-extended. */
#define GET_UINT16(value) (unsigned)(sizeof(unsigned short) == 2 ? (unsigned short)(value) : (unsigned short)(value) & 0xffffU)  /* Zero-extended. */

const char *input_filename;
unsigned line_number;

char *output_filename;
FILE *output;

char *listing_filename;
FILE *listing;

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

char line[MAX_SIZE];
char part[MAX_SIZE];
char name[MAX_SIZE];
char expr_name[MAX_SIZE];
char global_label[MAX_SIZE];
const char *prev_p;
const char *p;

char *g;
char generated[8];

unsigned errors;
unsigned warnings;
unsigned bytes;
int change;
int change_number;

struct label {
    struct label *left;
    struct label *right;
    int value;
    char name[1];
};

struct label *label_list;
struct label *last_label;
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

void message(int error, const char *message);

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
#define exit(status)	_exit(status)
#endif

/*
 ** Define a new label
 */
struct label *define_label(const char *name, int value) {
    struct label *label;
    struct label *explore;
    int c;
    
    /* Allocate label */
    label = (struct label*)malloc(sizeof(struct label) + strlen(name));
    if (label == NULL) {
        fprintf(stderr, "Out of memory for label\r\n");
        exit(1);
        return NULL;
    }
    
    /* Fill label */
    label->left = NULL;
    label->right = NULL;
    label->value = value;
    strcpy(label->name, name);
    
    /* Populate binary tree */
    if (label_list == NULL) {
        label_list = label;
    } else {
        explore = label_list;
        while (1) {
            c = strcmp(label->name, explore->name);
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
struct label *find_label(const char *name) {
    struct label *explore;
    int c;
    
    /* Follows a binary tree */
    explore = label_list;
    while (explore != NULL) {
        c = strcmp(name, explore->name);
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
 ** Sort recursively labels (already done by binary tree)
 */
void sort_labels(struct label *node) {
    if (node->left != NULL)
        sort_labels(node->left);
    fprintf(listing, "%-20s %04x\r\n", node->name, GET_UINT16(node->value));
    if (node->right != NULL)
        sort_labels(node->right);
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

void inc_u16_capped(unsigned *p) {
    ++*p;
    if (GET_INT16(*p) == 0) --*p;  /* Capped at 0xffff. */
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
 ** Read character for string or character literal
 **
 ** This is incompatible with NASM (any version 0.98.39 and 2.13.2) and Yasm
 ** (1.2.0 and 1.3.0). These assemblers don't process backslashes in '...'
 ** or "..." string literals.
 */
const char *read_character(const char *p, int *c) {
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
    int value1, am;
    
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
            am = GET_INT16(*value);
            if (am < 0) { shift_by_negative:
                message(1, "shift by negative");
                return NULL;
            }
            /* Checking (am > 15) to avoid i386 quirk: (x << 32) == x. */
            *value = (am > 15) ? 0 : value1 << am;
        } else if (*p == '>' && p[1] == '>') {  /* Shift to right */
            p += 2;
            value1 = *value;
            p = match_expression_level4(p, value);
            if (p == NULL)
                return NULL;
            am = GET_INT16(*value);
            if (am) goto shift_by_negative;
            /* Checking (am > 15) to avoid i386 quirk: (x >> 32) == x. */
            *value = GET_INT16(value1) >> ((am > 15) ? 15 : am);
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
            if (GET_UINT16(*value) == 0) {
                if (assembler_step == 2)
                    message(1, "division by zero");
                *value = 1;
            }
            *value = GET_UINT16(value1) / GET_UINT16(*value);
        } else if (*p == '%') { /* Modulo operator */
            p++;
            value1 = *value;
            p = match_expression_level6(p, value);
            if (p == NULL)
                return NULL;
            if (GET_UINT16(*value) == 0) {
                if (assembler_step == 2)
                    message(1, "modulo by zero");
                *value = 1;
            }
            /* Since '/' uses unsigned division, '%' must also use it,
             * otherwise this wouldn't hold: (a % b) == a - (a / b) * b.
             */
            *value = GET_UINT16(value1) % GET_UINT16(*value);
        } else {
            return p;
        }
    }
}

/*
 ** Match expression (bottom tier)
 */
const char *match_expression_level6(const char *p, int *value) {
    int number;
    int c;
    char *p2;
    struct label *label;
    
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
    if (p[0] == '0' && tolower(p[1]) == 'x' && isxdigit(p[2])) {	/* Hexadecimal */
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
    if (p[0] == '$' && isdigit(p[1])) {	/* Hexadecimal */
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
                fprintf(stderr, "Error: undefined label '%s' at line %u\r\n", expr_name, line_number);
                inc_u16_capped(&errors);
            }
        } else {
            *value = label->value;
        }
        return p;
    }
    return NULL;
}

/*
 ** Emit one byte to output
 */
void emit_byte(int byte) {
    char buf[1];
    
    if (assembler_step == 2) {
        if (g != NULL && g < generated + sizeof(generated))
            *g++ = byte;
        buf[0] = byte;
        /* Cannot use fputc because DeSmet C expands to CR LF */
        fwrite(buf, 1, 1, output);
        bytes++;
    }
    address++;
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
        if (*pattern == '%') {	/* Special */
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
                        fprintf(stderr, "decode: internal error 2\r\n");
                    }
                } else {
                    fprintf(stderr, "decode: internal error 1 (%s)\r\n", base);
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
        fprintf(stderr, "Error: extra characters at end of line %d\r\n", line_number);
        inc_u16_capped(&errors);
    }
}

/*
 ** Generate a message
 */
void message(int error, const char *message) {
    if (error) {
        fprintf(stderr, "Error: %s at line %d\r\n", message, line_number);
        inc_u16_capped(&errors);
    } else {
        fprintf(stderr, "Warning: %s at line %d\r\n", message, line_number);
        ++warnings;
        if (GET_INT16(warnings) == 0) ++warnings;
    }
    if (listing != NULL) {
        if (error) {
            fprintf(listing, "Error: %s at line %d\r\n", message, line_number);
        } else {
            fprintf(listing, "Warning: %s at line %d\r\n", message, line_number);
        }
    }
}

/*
 ** Process an instruction
 */
void process_instruction() {
    const char *p2 = NULL;
    const char *p3;
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
                    fprintf(stderr, "Error: unterminated string at line %d\r\n", line_number);
                }
            } else {
                p2 = match_expression(p, &instruction_value);
                if (p2 == NULL) {
                    fprintf(stderr, "Error: bad expression at line %d\r\n", line_number);
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
                fprintf(stderr, "Error: bad expression at line %d\r\n", line_number);
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
            char m[25 + MAX_SIZE];
            
            sprintf(m, "Undefined instruction '%s %s'", part, p);
            message(1, m);
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
void reset_address() {
    address = start_address = default_start_address;
}

/*
 ** Include a binary file
 */
void incbin(const char *fname) {
    FILE *input;
    char buf[256];
    int size;
    int i;
    
    input = fopen(fname, "rb");
    if (input == NULL) {
        sprintf(buf, "Error: Cannot open '%s' for input", fname);
        message(1, buf);
        return;
    }
    
    while ((size = fread(buf, 1, 30, input)) > 0) {
        for (i = 0; i < size; i++) {
            emit_byte(buf[i]);
        }
    }
    
    fclose(input);
}

/*
 ** Do an assembler step
 */
void do_assembly(const char *fname) {
    FILE *input;
    const char *p2;
    const char *p3;
    const char *pfname;
    int level;
    int avoid_level;
    int times;
    int base;
    int pline;
    int include;
    int align;

    input = fopen(fname, "rb");
    if (input == NULL) {
        fprintf(stderr, "Error: cannot open '%s' for input\r\n", fname);
        inc_u16_capped(&errors);
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
    while (fgets(line, sizeof(line), input)) {
        inc_u16_capped(&line_number);
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
        if (p > line && *(p - 1) == '\n')
            p--;
        if (p > line && *(p - 1) == '\r')
            p--;
        *(char*)p = '\0';

        base = address;
        g = generated;
        include = 0;

        while (1) {
            p = line;
            separate();
            if (part[0] == '\0' && (*p == '\0' || *p == ';'))    /* Empty line */
                break;
            if (part[0] != '\0' && part[strlen(part) - 1] == ':') {	/* Label */
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
                                    char m[18 + MAX_SIZE];
                                    
                                    sprintf(m, "Redefined label '%s'", name);
                                    message(1, m);
                                } else {
                                    last_label = define_label(name, instruction_value);
                                }
                            } else {
                                last_label = find_label(name);
                                if (last_label == NULL) {
                                    char m[33 + MAX_SIZE];
                                    
                                    sprintf(m, "Inconsistency, label '%s' not found", name);
                                    message(1, m);
                                } else {
                                    if (last_label->value != instruction_value) {
#ifdef DEBUG
/*                                        fprintf(stderr, "Woops: label '%s' changed value from %04x to %04x\r\n", last_label->name, last_label->value, instruction_value);*/
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
                        /*                        fprintf(stderr, "First time '%s' at line %d\r\n", line, line_number);*/
#endif
                        first_time = 0;
                        reset_address();
                    }
                    if (assembler_step == 1) {
                        if (find_label(name)) {
                            char m[18 + MAX_SIZE];
                            
                            sprintf(m, "Redefined label '%s'", name);
                            message(1, m);
                        } else {
                            last_label = define_label(name, address);
                        }
                    } else {
                        last_label = find_label(name);
                        if (last_label == NULL) {
                            char m[33 + MAX_SIZE];
                            
                            sprintf(m, "Inconsistency, label '%s' not found", name);
                            message(1, m);
                        } else {
                            if (last_label->value != address) {
#ifdef DEBUG
/*                                fprintf(stderr, "Woops: label '%s' changed value from %04x to %04x\r\n", last_label->name, last_label->value, address);*/
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
                    inc_u16_capped(&errors);
                } else if (undefined) {
                    message(1, "Undefined labels");
                    inc_u16_capped(&errors);
                }
                if (GET_INT16(instruction_value) != 0) {
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
                /*fprintf(stderr, "Avoiding '%s'\r\n", line);*/
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
            if (strcmp(part, "%INCLUDE") == 0) {
                separate();
                check_end(p);
                if (part[0] != '"' || part[strlen(part) - 1] != '"') {
                    message(1, "Missing quotes on %include");
                    break;
                }
                include = 1;
                break;
            }
            if (strcmp(part, "INCBIN") == 0) {
                separate();
                check_end(p);
                if (part[0] != '"' || part[strlen(part) - 1] != '"') {
                    message(1, "Missing quotes on incbin");
                    break;
                }
                include = 2;
                break;
            }
            if (strcmp(part, "ORG") == 0) {
                p = avoid_spaces(p);
                undefined = 0;
                p2 = match_expression(p, &instruction_value);
                if (p2 == NULL) {
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
                    check_end(p2);
                }
                break;
            }
            if (strcmp(part, "ALIGN") == 0) {
                p = avoid_spaces(p);
                undefined = 0;
                p2 = match_expression(p, &instruction_value);
                if (p2 == NULL) {
                    message(1, "Bad expression");
                } else if (undefined) {
                    message(1, "Cannot use undefined labels");
                } else {
                    align = address / instruction_value;
                    align = align * instruction_value;
                    align = align + instruction_value;
		    while (address < align)
		        emit_byte(0x90);
                    check_end(p2);
                }
                break;
            }
            if (first_time == 1) {
#ifdef DEBUG
                /*fprintf(stderr, "First time '%s' at line %d\r\n", line, line_number);*/
#endif
                first_time = 0;
                reset_address();
            }
            times = 1;
            if (strcmp(part, "TIMES") == 0) {
                undefined = 0;
                p2 = match_expression(p, &instruction_value);
                if (p2 == NULL) {
                    message(1, "bad expression");
                    break;
                }
                if (undefined) {
                    message(1, "non-constant expression");
                    break;
                }
                times = instruction_value;
                p = p2;
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
        if (assembler_step == 2 && listing != NULL) {
            if (first_time)
                fprintf(listing, "      ");
            else
                fprintf(listing, "%04X  ", base);
            p = generated;
            while (p < g) {
                fprintf(listing, "%02X", *p++ & 255);
            }
            while (p < generated + sizeof(generated)) {
                fprintf(listing, "  ");
                p++;
            }
            fprintf(listing, "  %05d %s\r\n", line_number, line);
        }
        if (include == 1) {
            part[strlen(part) - 1] = '\0';
            do_assembly(part + 1);
        }
        if (include == 2) {
            part[strlen(part) - 1] = '\0';
            incbin(part + 1);
        }
    }
    fclose(input);
    line_number = pline;
    input_filename = pfname;
}

/*
 ** Main program
 */
int main(int argc, char **argv) {
    int c;
    int d;
    const char *p;
    const char *ifname;

#ifdef MSDOS
    setmode(2, O_BINARY);  /* STDERR_FILENO. */
#else
#ifdef _WIN32
    setmode(2, O_BINARY);  /* STDERR_FILENO. */
#endif
#endif
    
    /*
     ** If ran without arguments then show usage
     */
    if (argc == 1) {
        fprintf(stderr, "Typical usage:\r\n");
        fprintf(stderr, "tinasm -f bin input.asm -o input.bin\r\n");
        exit(1);
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
                    fprintf(stderr, "Error: no argument for -f\r\n");
                    exit(1);
                } else {
                    to_lowercase(argv[c]);
                    if (strcmp(argv[c], "bin") == 0) {
                        default_start_address = 0;
                    } else if (strcmp(argv[c], "com") == 0) {
                        default_start_address = 0x0100;
                    } else {
                        fprintf(stderr, "Error: only 'bin', 'com' supported for -f (it is '%s')\r\n", argv[c]);
                        exit(1);
                    }
                    c++;
                }
            } else if (d == 'o') {  /* Object file name */
                c++;
                if (c >= argc) {
                    fprintf(stderr, "Error: no argument for -o\r\n");
                    exit(1);
                } else if (output_filename != NULL) {
                    fprintf(stderr, "Error: already a -o argument is present\r\n");
                    exit(1);
                } else {
                    output_filename = argv[c];
                    c++;
                }
            } else if (d == 'l') {  /* Listing file name */
                c++;
                if (c >= argc) {
                    fprintf(stderr, "Error: no argument for -l\r\n");
                    exit(1);
                } else if (listing_filename != NULL) {
                    fprintf(stderr, "Error: already a -l argument is present\r\n");
                    exit(1);
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
                        fprintf(stderr, "Error: wrong label definition\r\n");
                        exit(1);
                    } else if (undefined) {
                        fprintf(stderr, "Error: non-constant label definition\r\n");
                        exit(1);
                    } else {
                        define_label(argv[c] + 2, instruction_value);
                    }
                }
                c++;
            } else {
                fprintf(stderr, "Error: unknown argument %s\r\n", argv[c]);
                exit(1);
            }
        } else {
            if (ifname != NULL) {
                fprintf(stderr, "Error: more than one input file name: %s\r\n", argv[c]);
                exit(1);
            } else {
                ifname = argv[c];
            }
            c++;
        }
    }
    
    if (ifname == NULL) {
        fprintf(stderr, "No input filename provided\r\n");
        exit(1);
    }
    
    /*
     ** Do first step of assembly
     */
    assembler_step = 1;
    first_time = 1;
    do_assembly(ifname);
    if (!errors) {
        
        /*
         ** Do second step of assembly and generate final output
         */
        if (output_filename == NULL) {
            fprintf(stderr, "No output filename provided\r\n");
            exit(1);
        }
        change_number = 0;
        do {
            change = 0;
            if (listing_filename != NULL) {
                listing = fopen(listing_filename, "wb");
                if (listing == NULL) {
                    fprintf(stderr, "Error: couldn't open '%s' as listing file\r\n", output_filename);
                    exit(1);
                }
            }
            output = fopen(output_filename, "wb");
            if (output == NULL) {
                fprintf(stderr, "Error: couldn't open '%s' as output file\r\n", output_filename);
                exit(1);
            }
            assembler_step = 2;
            first_time = 1;
            address = start_address;
            do_assembly(ifname);
            
            if (listing != NULL && change == 0) {
                fprintf(listing, "\r\n%05u ERRORS FOUND\r\n", errors);
                fprintf(listing, "%05u WARNINGS FOUND\r\n\r\n", warnings);
                fprintf(listing, "%05u PROGRAM BYTES\r\n\r\n", GET_UINT16(bytes));
                if (label_list != NULL) {
                    fprintf(listing, "%-20s VALUE/ADDRESS\r\n\r\n", "LABEL");
                    sort_labels(label_list);
                }
            }
            fclose(output);
            if (listing_filename != NULL)
                fclose(listing);
            if (change) {
                change_number++;
                if (change_number == 5) {
                    fprintf(stderr, "Aborted: Couldn't stabilize moving label\r\n");
                    inc_u16_capped(&errors);
                }
            }
            if (errors) {
                remove(output_filename);
                if (listing_filename != NULL)
                    remove(listing_filename);
                exit(1);
            }
        } while (change) ;

        exit(0);
    }

    exit(1);
}

/*
 ** This should have been 3 entries per line but DeSmet C only allows 500 strings per module.
 */

/*
 ** Notice some instructions are sorted by less byte usage first.
 */
const char *instruction_set[] = {
    "ADD\0%d8,%r8\0x00 %d8%r8%d8",
    "ADD\0%d16,%r16\0x01 %d16%r16%d16",
    "ADD\0%r8,%d8\0x02 %d8%r8%d8",
    "ADD\0%r16,%d16\0x03 %d16%r16%d16",
    "ADD\0AL,%i8\0x04 %i8",
    "ADD\0AX,%i16\0x05 %i16",
    "PUSH\0ES\0x06",
    "POP\0ES\0x07",
    "OR\0%d8,%r8\0x08 %d8%r8%d8",
    "OR\0%d16,%r16\0x09 %d16%r16%d16",
    "OR\0%r8,%d8\0x0a %d8%r8%d8",
    "OR\0%r16,%d16\0x0b %d16%r16%d16",
    "OR\0AL,%i8\0x0c %i8",
    "OR\0AX,%i16\0x0d %i16",
    "PUSH\0CS\0x0e",
    "ADC\0%d8,%r8\0x10 %d8%r8%d8",
    "ADC\0%d16,%r16\0x11 %d16%r16%d16",
    "ADC\0%r8,%d8\0x12 %d8%r8%d8",
    "ADC\0%r16,%d16\0x13 %d16%r16%d16",
    "ADC\0AL,%i8\0x14 %i8",
    "ADC\0AX,%i16\0x15 %i16",
    "PUSH\0SS\0x16",
    "POP\0SS\0x17",
    "SBB\0%d8,%r8\0x18 %d8%r8%d8",
    "SBB\0%d16,%r16\0x19 %d16%r16%d16",
    "SBB\0%r8,%d8\0x1a %d8%r8%d8",
    "SBB\0%r16,%d16\0x1b %d16%r16%d16",
    "SBB\0AL,%i8\0x1c %i8",
    "SBB\0AX,%i16\0x1d %i16",
    "PUSH\0DS\0x1e",
    "POP\0DS\0x1f",
    "AND\0%d8,%r8\0x20 %d8%r8%d8",
    "AND\0%d16,%r16\0x21 %d16%r16%d16",
    "AND\0%r8,%d8\0x22 %d8%r8%d8",
    "AND\0%r16,%d16\0x23 %d16%r16%d16",
    "AND\0AL,%i8\0x24 %i8",
    "AND\0AX,%i16\0x25 %i16",
    "ES\0\0x26",
    "DAA\0\0x27",
    "SUB\0%d8,%r8\0x28 %d8%r8%d8",
    "SUB\0%d16,%r16\0x29 %d16%r16%d16",
    "SUB\0%r8,%d8\0x2a %d8%r8%d8",
    "SUB\0%r16,%d16\0x2b %d16%r16%d16",
    "SUB\0AL,%i8\0x2c %i8",
    "SUB\0AX,%i16\0x2d %i16",
    "CS\0\0x2e",
    "DAS\0\0x2f",
    "XOR\0%d8,%r8\0x30 %d8%r8%d8",
    "XOR\0%d16,%r16\0x31 %d16%r16%d16",
    "XOR\0%r8,%d8\0x32 %d8%r8%d8",
    "XOR\0%r16,%d16\0x33 %d16%r16%d16",
    "XOR\0AL,%i8\0x34 %i8",
    "XOR\0AX,%i16\0x35 %i16",
    "SS\0\0x36",
    "AAA\0\0x37",
    "CMP\0%d8,%r8\0x38 %d8%r8%d8",
    "CMP\0%d16,%r16\0x39 %d16%r16%d16",
    "CMP\0%r8,%d8\0x3a %d8%r8%d8",
    "CMP\0%r16,%d16\0x3b %d16%r16%d16",
    "CMP\0AL,%i8\0x3c %i8",
    "CMP\0AX,%i16\0x3d %i16",
    "DS\0\0x3e",
    "AAS\0\0x3f",
    "INC\0%r16\0b01000%r16",
    "DEC\0%r16\0b01001%r16",
    "PUSH\0%r16\0b01010%r16",
    "POP\0%r16\0b01011%r16",
    "JO\0%a8\0x70 %a8",
    "JNO\0%a8\0x71 %a8",
    "JB\0%a8\0x72 %a8",
    "JC\0%a8\0x72 %a8",
    "JNB\0%a8\0x73 %a8",
    "JNC\0%a8\0x73 %a8",
    "JZ\0%a8\0x74 %a8",
    "JNZ\0%a8\0x75 %a8",
    "JE\0%a8\0x74 %a8",
    "JNE\0%a8\0x75 %a8",
    "JBE\0%a8\0x76 %a8",
    "JA\0%a8\0x77 %a8",
    "JS\0%a8\0x78 %a8",
    "JNS\0%a8\0x79 %a8",
    "JPE\0%a8\0x7a %a8",
    "JPO\0%a8\0x7b %a8",
    "JL\0%a8\0x7C %a8",
    "JGE\0%a8\0x7D %a8",
    "JLE\0%a8\0x7E %a8",
    "JG\0%a8\0x7F %a8",
    "ADD\0%d16,%s8\0x83 %d16000%d16 %s8",
    "OR\0%d16,%s8\0x83 %d16001%d16 %s8",
    "ADC\0%d16,%s8\0x83 %d16010%d16 %s8",
    "SBB\0%d16,%s8\0x83 %d16011%d16 %s8",
    "AND\0%d16,%s8\0x83 %d16100%d16 %s8",
    "SUB\0%d16,%s8\0x83 %d16101%d16 %s8",
    "XOR\0%d16,%s8\0x83 %d16110%d16 %s8",
    "CMP\0%d16,%s8\0x83 %d16111%d16 %s8",
    "ADD\0%d8,%i8\0x80 %d8000%d8 %i8",
    "OR\0%d8,%i8\0x80 %d8001%d8 %i8",
    "ADC\0%d8,%i8\0x80 %d8010%d8 %i8",
    "SBB\0%d8,%i8\0x80 %d8011%d8 %i8",
    "AND\0%d8,%i8\0x80 %d8100%d8 %i8",
    "SUB\0%d8,%i8\0x80 %d8101%d8 %i8",
    "XOR\0%d8,%i8\0x80 %d8110%d8 %i8",
    "CMP\0%d8,%i8\0x80 %d8111%d8 %i8",
    "ADD\0%d16,%i16\0x81 %d16000%d16 %i16",
    "OR\0%d16,%i16\0x81 %d16001%d16 %i16",
    "ADC\0%d16,%i16\0x81 %d16010%d16 %i16",
    "SBB\0%d16,%i16\0x81 %d16011%d16 %i16",
    "AND\0%d16,%i16\0x81 %d16100%d16 %i16",
    "SUB\0%d16,%i16\0x81 %d16101%d16 %i16",
    "XOR\0%d16,%i16\0x81 %d16110%d16 %i16",
    "CMP\0%d16,%i16\0x81 %d16111%d16 %i16",
    "TEST\0%d8,%r8\0x84 %d8%r8%d8",
    "TEST\0%r8,%d8\0x84 %d8%r8%d8",
    "TEST\0%d16,%r16\0x85 %d16%r16%d16",
    "TEST\0%r16,%d16\0x85 %d16%r16%d16",
    
    "MOV\0AL,[%i16]\0xa0 %i16",
    "MOV\0AX,[%i16]\0xa1 %i16",
    "MOV\0[%i16],AL\0xa2 %i16",
    "MOV\0[%i16],AX\0xa3 %i16",
    "MOV\0%d8,%r8\0x88 %d8%r8%d8",
    "MOV\0%d16,%r16\0x89 %d16%r16%d16",
    "MOV\0%r8,%d8\0x8a %d8%r8%d8",
    "MOV\0%r16,%d16\0x8b %d16%r16%d16",
    
    "MOV\0%d16,ES\0x8c %d16000%d16",
    "MOV\0%d16,CS\0x8c %d16001%d16",
    "MOV\0%d16,SS\0x8c %d16010%d16",
    "MOV\0%d16,DS\0x8c %d16011%d16",
    "LEA\0%r16,%d16\0x8d %d16%r16%d16",
    "MOV\0ES,%d16\0x8e %d16000%d16",
    "MOV\0CS,%d16\0x8e %d16001%d16",
    "MOV\0SS,%d16\0x8e %d16010%d16",
    "MOV\0DS,%d16\0x8e %d16011%d16",
    "POP\0%d16\0x8f %d16000%d16",
    "NOP\0\0x90",
    "XCHG\0AX,%r16\0b10010%r16",
    "XCHG\0%r16,AX\0b10010%r16",
    "XCHG\0%d8,%r8\0x86 %d8%r8%d8",
    "XCHG\0%r8,%d8\0x86 %d8%r8%d8",
    "XCHG\0%d16,%r16\0x87 %d16%r16%d16",
    "XCHG\0%r16,%d16\0x87 %d16%r16%d16",
    "CBW\0\0x98",
    "CWD\0\0x99",
    "WAIT\0\0x9b",
    "PUSHF\0\0x9c",
    "POPF\0\0x9d",
    "SAHF\0\0x9e",
    "LAHF\0\0x9f",
    "MOVSB\0\0xa4",
    "MOVSW\0\0xa5",
    "CMPSB\0\0xa6",
    "CMPSW\0\0xa7",
    "TEST\0AL,%i8\0xa8 %i8",
    "TEST\0AX,%i16\0xa9 %i16",
    "STOSB\0\0xaa",
    "STOSW\0\0xab",
    "LODSB\0\0xac",
    "LODSW\0\0xad",
    "SCASB\0\0xae",
    "SCASW\0\0xaf",
    "MOV\0%r8,%i8\0b10110%r8 %i8",
    "MOV\0%r16,%i16\0b10111%r16 %i16",
    "RET\0%i16\0xc2 %i16",
    "RET\0\0xc3",
    "LES\0%r16,%d16\0b11000100 %d16%r16%d16",
    "LDS\0%r16,%d16\0b11000101 %d16%r16%d16",
    "MOV\0%db8,%i8\0b11000110 %d8000%d8 %i8",
    "MOV\0%dw16,%i16\0b11000111 %d16000%d16 %i16",
    "RETF\0%i16\0xca %i16",
    "RETF\0\0xcb",
    "INT3\0\0xcc",
    "INT\0%i8\0xcd %i8",
    "INTO\0\0xce",
    "IRET\0\0xcf",
    "ROL\0%d8,1\0xd0 %d8000%d8",
    "ROR\0%d8,1\0xd0 %d8001%d8",
    "RCL\0%d8,1\0xd0 %d8010%d8",
    "RCR\0%d8,1\0xd0 %d8011%d8",
    "SHL\0%d8,1\0xd0 %d8100%d8",
    "SHR\0%d8,1\0xd0 %d8101%d8",
    "SAR\0%d8,1\0xd0 %d8111%d8",
    "ROL\0%d16,1\0xd1 %d16000%d16",
    "ROR\0%d16,1\0xd1 %d16001%d16",
    "RCL\0%d16,1\0xd1 %d16010%d16",
    "RCR\0%d16,1\0xd1 %d16011%d16",
    "SHL\0%d16,1\0xd1 %d16100%d16",
    "SHR\0%d16,1\0xd1 %d16101%d16",
    "SAR\0%d16,1\0xd1 %d16111%d16",
    "ROL\0%d8,CL\0xd2 %d8000%d8",
    "ROR\0%d8,CL\0xd2 %d8001%d8",
    "RCL\0%d8,CL\0xd2 %d8010%d8",
    "RCR\0%d8,CL\0xd2 %d8011%d8",
    "SHL\0%d8,CL\0xd2 %d8100%d8",
    "SHR\0%d8,CL\0xd2 %d8101%d8",
    "SAR\0%d8,CL\0xd2 %d8111%d8",
    "ROL\0%d16,CL\0xd3 %d16000%d16",
    "ROR\0%d16,CL\0xd3 %d16001%d16",
    "RCL\0%d16,CL\0xd3 %d16010%d16",
    "RCR\0%d16,CL\0xd3 %d16011%d16",
    "SHL\0%d16,CL\0xd3 %d16100%d16",
    "SHR\0%d16,CL\0xd3 %d16101%d16",
    "SAR\0%d16,CL\0xd3 %d16111%d16",
    "AAM\0\0xd4 x0a",
    "AAD\0\0xd5 x0a",
    "XLAT\0\0xd7",
    "LOOPNZ\0%a8\0xe0 %a8",
    "LOOPNE\0%a8\0xe0 %a8",
    "LOOPZ\0%a8\0xe1 %a8",
    "LOOPE\0%a8\0xe1 %a8",
    "LOOP\0%a8\0xe2 %a8",
    "JCXZ\0%a8\0xe3 %a8",
    "IN\0AL,DX\0xec",
    "IN\0AX,DX\0xed",
    "OUT\0DX,AL\0xee",
    "OUT\0DX,AX\0xef",
    "IN\0AL,%i8\0xe4 %i8",
    "IN\0AX,%i8\0xe5 %i8",
    "OUT\0%i8,AL\0xe6 %i8",
    "OUT\0%i8,AX\0xe7 %i8",
    "CALL\0FAR %d16\0xff %d16011%d16",
    "JMP\0FAR %d16\0xff %d16101%d16",
    "CALL\0%f32\0x9a %f32",
    "JMP\0%f32\0xea %f32",
    "CALL\0%d16\0xff %d16010%d16",
    "JMP\0%d16\0xff %d16100%d16",
    "JMP\0%a8\0xeb %a8",
    "JMP\0%a16\0xe9 %a16",
    "CALL\0%a16\0xe8 %a16",
    "LOCK\0\0xf0",
    "REPNZ\0\0xf2",
    "REPNE\0\0xf2",
    "REPZ\0\0xf3",
    "REPE\0\0xf3",
    "REP\0\0xf3",
    "HLT\0\0xf4",
    "CMC\0\0xf5",
    "TEST\0%db8,%i8\0xf6 %d8000%d8 %i8",
    "NOT\0%db8\0xf6 %d8010%d8",
    "NEG\0%db8\0xf6 %d8011%d8",
    "MUL\0%db8\0xf6 %d8100%d8",
    "IMUL\0%db8\0xf6 %d8101%d8",
    "DIV\0%db8\0xf6 %d8110%d8",
    "IDIV\0%db8\0xf6 %d8111%d8",
    "TEST\0%dw16,%i16\0xf7 %d8000%d8 %i16",
    "NOT\0%dw16\0xf7 %d8010%d8",
    "NEG\0%dw16\0xf7 %d8011%d8",
    "MUL\0%dw16\0xf7 %d8100%d8",
    "IMUL\0%dw16\0xf7 %d8101%d8",
    "DIV\0%dw16\0xf7 %d8110%d8",
    "IDIV\0%dw16\0xf7 %d8111%d8",
    "CLC\0\0xf8",
    "STC\0\0xf9",
    "CLI\0\0xfa",
    "STI\0\0xfb",
    "CLD\0\0xfc",
    "STD\0\0xfd",
    "INC\0%db8\0xfe %d8000%d8",
    "DEC\0%db8\0xfe %d8001%d8",
    "INC\0%dw16\0xff %d16000%d16",
    "DEC\0%dw16\0xff %d16001%d16",
    "PUSH\0%d16\0xff %d16110%d16",
    NULL,NULL,NULL
};
