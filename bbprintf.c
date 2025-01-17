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

#ifndef va_arg
#ifdef __TINYC__  /* Works with tcc, pts-tcc (Linux i386 target), pts-tcc64 (Linux amd64 target) and tcc.exe (Win32, Windows i386 target). */
#if defined(__i386__) /* || defined(__amd64__)*/ || defined(__x86_64__)
#ifdef __i386__
typedef char *va_list;  /* i386 only. */
#define va_start(ap, last) ap = ((char *)&(last)) + ((sizeof(last)+3)&~3)  /* i386 only. */
#define va_arg(ap, type) (ap += (sizeof(type)+3)&~3, *(type *)(ap - ((sizeof(type)+3)&~3)))  /* i386 only. */
#define va_copy(dest, src) (dest) = (src)  /* i386 only. */
#define va_end(ap)  /* i386 only. */
#endif
#ifdef __x86_64__  /* amd64. */
#ifdef _WIN32
#error Windows is supported only on i386.
#endif
#ifdef _WIN64
#error Windows is supported only on i386.
#endif
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
#define va_start(ap, last) __va_start(ap, __builtin_frame_address(0))  /* amd64 only. */
#define va_arg(ap, type) (*(type *)(__va_arg(ap, __builtin_va_arg_types(type), sizeof(type), __alignof__(type))))  /* amd64 only. */
#define va_copy(dest, src) (*(dest) = *(src))  /* amd64 only. */
#define va_end(ap)  /* amd64 only. */
#endif
#else
#error tcc is only supported on i386 and amd64.
#endif
#else
#include <stdarg.h>
#endif
#endif  /* !defined(va_arg) */

#if defined(__GNUC__) && defined(__i386__)  /* TODO(pts): Check MinGW GCC Win32 target. */
/* This is a size optimization. It only works on i386 and if the function
 * taking the `...' arguments is __attribute__((noinline)). It makes the
 * program 104 bytes shorter.
 */
#define BBVA_NOINLINE __attribute__((noinline))
typedef char *bbva_list;
#define bbva_start(ap, last) ((ap) = (char*)&(last) + ((sizeof(last)+3)&~3), (void)0)  /* i386 only. */
#define bbva_arg(ap, type) ((ap) += (sizeof(type)+3)&~3, *(type*)((ap) - ((sizeof(type)+3)&~3)))  /* i386 only. */
#define bbva_copy(dest, src) ((dest) = (src), (void)0)  /* i386 only. */
#define bbva_end(ap) /*((ap) = 0, (void)0)*/  /* i386 only. Adding the `= 0' back doesn't make a difference. */
#else
#define BBVA_NOINLINE
#define bbva_list va_list  /* This would change the executable program with __DOSMC__: `typedef va_list bbva_list;`. */
#define bbva_start(ap, last) va_start(ap, last)
#define bbva_arg(ap, type) va_arg(ap, type)
#define bbva_copy(dest, src) va_copy(dest, src)
#define bbva_end(ap) va_end(ap)
#endif

#ifndef CONFIG_BBPRINTF_LONG
#define CONFIG_BBPRINTF_LONG 0
#endif

#include "bbprintf.h"

CONFIG_BBPRINTF_STATIC void bbwrite1(struct bbprintf_buf *bbb, int c) {
  while (bbb->p == bbb->buf_end) {
    bbb->flush(bbb);
  }
  *bbb->p++ = c;
}

#define PAD_RIGHT 1
#define PAD_ZERO 2

#if CONFIG_BBPRINTF_LONG
/* This comment line is to pacify Borland C++ 3.0 compiler not recognizing the no-CR LF line break in the previous line upon a successful #if. */
#define BBPRINTF_INT long
#else
#define BBPRINTF_INT int
#endif

static int print(struct bbprintf_buf *bbb, const char *format, bbva_list args) {
  register unsigned width, pad;
  register unsigned pc = 0;
  /* String buffer large enough for the longest %u and %x. */
  char print_buf[sizeof(BBPRINTF_INT) == 4 ? 11 : sizeof(BBPRINTF_INT) == 2 ? 6 : sizeof(BBPRINTF_INT) * 3 + 1];
  char c;
  unsigned BBPRINTF_INT u;
  unsigned b;
  unsigned char letbase, t;
  /*register*/ char *s;
  char neg;

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
      c = *format;
      s = print_buf;
      if (c == 's') {
        s = bbva_arg(args, char*);
        if (!s) s = (char*)"(null)";
       do_print_s:
        /* pc += prints(bbb, s, width, pad); */
        c = ' ';  /* padchar. */
        if (width > 0) {
          register unsigned len = 0;
          register const char *ptr;
          for (ptr = s; *ptr; ++ptr) ++len;
          if (len >= width) width = 0;
          else width -= len;
          if (pad & PAD_ZERO) c = '0';
        }
        if (!(pad & PAD_RIGHT)) {
          for (; width > 0; --width) {
            bbwrite1(bbb, c);
            ++pc;
          }
        }
        for (; *s ; ++s) {
          bbwrite1(bbb, *s);
          ++pc;
        }
        for (; width > 0; --width) {
          bbwrite1(bbb, c);
          ++pc;
        }
      } else if (c == 'c') {
        /* char are converted to int then pushed on the stack */
        s[0] = (char)bbva_arg(args, int);
        if (width == 0) {  /* Print '\0'. */
          bbwrite1(bbb, s[0]);
          ++pc;
        } else {
          goto do_print_1;
        }
      } else {
#if CONFIG_BBPRINTF_LONG
        if (c == 'l') {  /* !! TODO(pts): Keep u as `long' if sizeof(int) >= 4. This is for saving space and time if sizeof(long) > 4. */
          u = bbva_arg(args, unsigned long);
          c = *++format;
        } else {
          u = bbva_arg(args, unsigned);
        }
#else
        u = bbva_arg(args, unsigned);
#endif
        if (!(c == 'd' || c == 'u' || (c | 32) == 'x' )) goto done;  /* Assumes ASCII. */
        /* pc += printi(bbb, bbva_arg(args, int), (c | 32) == 'x' ? 16 : 10, c == 'd', width, pad, c == 'X' ? 'A' : 'a'); */
        /* This code block modifies `width', and it's fine to modify `width' and `pad'. */
        if (u == 0) {
          s[0] = '0';
         do_print_1:
          s[1] = '\0';
          goto do_print_s;
        } else {
          b = ((c | 32) == 'x') ? 16 : 10;
          letbase = ((c == 'X') ? 'A' : 'a') - '0' - 10;
          if (c == 'd' && b == 10 && (BBPRINTF_INT)u < 0) {
            neg = 1;
            u = -(BBPRINTF_INT)u;  /* Casting to BBPRINTF_INT to avoid Borland C++ 5.2 warning: Negating unsigned value. */
          } else {
            neg = 0;
          }
          s = print_buf + sizeof(print_buf) - 1;
          *s = '\0';
          while (u) {
            t = u % b;
            if (t >= 10) t += letbase;
            *--s = t + '0';
            u /= b;
          }
          if (neg) {
            if (width && (pad & PAD_ZERO)) {
              bbwrite1(bbb, '-');
              ++pc;
              --width;
            } else {
              *--s = '-';
            }
          }
          goto do_print_s;
        }
      }
    } else { out:
      bbwrite1(bbb, *format);
      ++pc;
    }
  }
 done:
  bbva_end(args);
  return pc;
}

CONFIG_BBPRINTF_STATIC BBVA_NOINLINE int bbprintf(struct bbprintf_buf *bbb, const char *format, ...) {
  bbva_list args;
  bbva_start(args, format);
  return print(bbb, format, args);
}

#if 0  /* Unused. */
CONFIG_BBPRINTF_STATIC BBVA_NOINLINE int bbsprintf(char *out, const char *format, ...) {
  int result;
  struct bbprintf_buf bbb;
  bbva_list args;
  bbb.buf = bbb.buf_end = bbb.p = out;
  --bbb.buf_end;
  bbva_start(args, format);
  result = print(&bbb, format, args);
  *bbb.p = '\0';
  return result;
}
#endif

#if 0  /* Unused. */
CONFIG_BBPRINTF_STATIC BBVA_NOINLINE int bbsnprintf(char *out, int size, const char *format, ...) {
  int result;
  struct bbprintf_buf bbb;
  bbva_list args;
  bbb.buf = bbb.p = out;
  bbb.buf_end = out + size - 1;
  bbva_start(args, format);
  result = print(&bbb, format, args);
  *bbb.p = '\0';
  return result;
}
#endif
