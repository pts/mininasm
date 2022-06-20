/* Based on: https://www.menie.org/georges/embedded/printf-stdarg.c
 * Downloaded on 2022-05-27.
 *
 * Copyright 2001-2021 Georges Menie
 * https://www.menie.org/georges/embedded/small_printf_source_code.html
 * stdarg version contributed by Christian Ettinger
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * !! TODO(pts): See if https://www.sparetimelabs.com/tinyprintf/tinyprintf.php is any shorter.
 */

#ifdef __TINYC__
#if defined(__i386__) /* || defined(__amd64__)*/ || defined(__x86_64__)
#ifdef __i386__
typedef char *va_list;  /* i386 only */
#define va_start(ap, last) ap = ((char *)&(last)) + ((sizeof(last)+3)&~3)  /* i386 only */
#define va_arg(ap, type) (ap += (sizeof(type)+3)&~3, *(type *)(ap - ((sizeof(type)+3)&~3)))  /* i386 only */
#define va_copy(dest, src) (dest) = (src)  /* i386 only */
#define va_end(ap)  /* i386 only */
#endif
#ifdef __x86_64__  /* amd64. */
typedef struct {
  unsigned int gp_offset;
  unsigned int fp_offset;
  union {
    unsigned int overflow_offset;
    char *overflow_arg_area;
  };
  char *reg_save_area;
} __va_list_struct;
typedef __va_list_struct va_list[1];
void __va_start(__va_list_struct *ap, void *fp);
void *__va_arg(__va_list_struct *ap, int arg_type, int size, int align);
typedef va_list __gnuc_va_list;
#define va_start(ap, last) __va_start(ap, __builtin_frame_address(0))  /* amd64 only */
#define va_arg(ap, type) (*(type *)(__va_arg(ap, __builtin_va_arg_types(type), sizeof(type), __alignof__(type))))  /* amd64 only */
#define va_copy(dest, src) (*(dest) = *(src))  /* amd64 only */
#define va_end(ap)  /* amd64 only */
#endif
#else
#error tcc is only supported on i386 and amd64
#endif
#else
#include <stdarg.h>
#endif

#include "bbprintf.h"

void bbwrite1(struct bbprintf_buf *bbb, int c) {
  while (bbb->p == bbb->buf_end) {
    bbb->flush(bbb);
  }
  *bbb->p++ = c;
}

#define PAD_RIGHT 1
#define PAD_ZERO 2

static int prints(struct bbprintf_buf *bbb, const char *string, int width, int pad) {
  register int pc = 0, padchar = ' ';
  if (width > 0) {
    register int len = 0;
    register const char *ptr;
    for (ptr = string; *ptr; ++ptr) ++len;
    if (len >= width) width = 0;
    else width -= len;
    if (pad & PAD_ZERO) padchar = '0';
  }
  if (!(pad & PAD_RIGHT)) {
    for (; width > 0; --width) {
      bbwrite1(bbb, padchar);
      ++pc;
    }
  }
  for (; *string ; ++string) {
    bbwrite1(bbb, *string);
    ++pc;
  }
  for (; width > 0; --width) {
    bbwrite1(bbb, padchar);
    ++pc;
  }
  return pc;
}

/* the following should be enough for 32 bit int */
#define PRINT_BUF_LEN 12

static int printi(struct bbprintf_buf *bbb, int i, int b, int sg, int width, int pad, int letbase) {
  char print_buf[PRINT_BUF_LEN];
  register char *s;
  register int t, neg = 0, pc = 0;
  register unsigned int u = i;

  if (i == 0) {
    print_buf[0] = '0';
    print_buf[1] = '\0';
    return prints(bbb, print_buf, width, pad);
  }

  if (sg && b == 10 && i < 0) {
    neg = 1;
    u = -i;
  }

  s = print_buf + PRINT_BUF_LEN-1;
  *s = '\0';

  while (u) {
    t = u % b;
    if (t >= 10)
      t += letbase - '0' - 10;
    *--s = t + '0';
    u /= b;
  }

  if (neg) {
    if (width &&(pad & PAD_ZERO)) {
      bbwrite1(bbb, '-');
      ++pc;
      --width;
    }
    else {
      *--s = '-';
    }
  }

  return pc + prints(bbb, s, width, pad);
}

static int print(struct bbprintf_buf *bbb, const char *format, va_list args) {
  register int width, pad;
  register int pc = 0;
  char scr[2];

  for (; *format != 0; ++format) {
    if (*format == '%') {
      ++format;
      width = pad = 0;
      if (*format == '\0') break;
      if (*format == '%') goto out;
      if (*format == '-') {
        ++format;
        pad = PAD_RIGHT;
      }
      while (*format == '0') {
        ++format;
        pad |= PAD_ZERO;
      }
      for (; *format >= '0' && *format <= '9'; ++format) {
        width *= 10;
        width += *format - '0';
      }
      if (*format == 's') {
        register char *s = va_arg(args, char*);
        pc += prints(bbb, s?s:"(null)", width, pad);
        continue;
      }
      if (*format == 'd') {
        pc += printi(bbb, va_arg(args, int), 10, 1, width, pad, 'a');
        continue;
      }
      if (*format == 'x') {
        pc += printi(bbb, va_arg(args, int), 16, 0, width, pad, 'a');
        continue;
      }
      if (*format == 'X') {
        pc += printi(bbb, va_arg(args, int), 16, 0, width, pad, 'A');
        continue;
      }
      if (*format == 'u') {
        pc += printi(bbb, va_arg(args, int), 10, 0, width, pad, 'a');
        continue;
      }
      if (*format == 'c') {
        /* char are converted to int then pushed on the stack */
        scr[0] = (char)va_arg(args, int);
        if (width == 0) {  /* Print '\0'. */
          bbwrite1(bbb, scr[0]);
          ++pc;
        } else {
          scr[1] = '\0';
          pc += prints(bbb, scr, width, pad);
        }
        continue;
      }
    } else { out:
      bbwrite1(bbb, *format);
      ++pc;
    }
  }
  va_end(args);
  return pc;
}

int bbprintf(struct bbprintf_buf *bbb, const char *format, ...) {
  va_list args;
  va_start(args, format);
  return print(bbb, format, args);
}

int bbsprintf(char *out, const char *format, ...) {
  int result;
  struct bbprintf_buf bbb;
  va_list args;
  bbb.buf = bbb.buf_end = bbb.p = out;
  --bbb.buf_end;
  va_start(args, format);
  result = print(&bbb, format, args);
  *bbb.p = '\0';
  return result;
}

#if 0  /* Unused. */
int bbsnprintf(char *out, int size, const char *format, ...) {
  int result;
  struct bbprintf_buf bbb;
  va_list args;
  bbb.buf = bbb.p = out;
  bbb.buf_end = out + size - 1;
  va_start(args, format);
  result = print(&bbb, format, args);
  *bbb.p = '\0';
  return result;
}
#endif
