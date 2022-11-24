#ifndef _BBPRINTF_H_
#define _BBPRINTF_H_ 1
/*#pragma once*/  /* __PACIFIC__ doesn't have it. It doesn't help us much, so we skip it. */

#ifndef CONFIG_BBPRINTF_STATIC
#define CONFIG_BBPRINTF_STATIC
#endif

struct bbprintf_buf {
  char *buf, *buf_end, *p;
  void *data;  /* Used by bbb.flush. */
  void (*flush)(struct bbprintf_buf *bbb);
};

CONFIG_BBPRINTF_STATIC int bbprintf(struct bbprintf_buf *bbb, const char *format, ...);

#if 0 /* Unused. */
/* out must not be NULL. */
CONFIG_BBPRINTF_STATIC int bbsprintf(char *out, const char *format, ...);
#endif

#if 0 /* Unused. */
/* out must not be NULL. size must be >= 1. */
CONFIG_BBPRINTF_STATIC int bbsnprintf(char *out, int size, const char *format, ...);
#endif

CONFIG_BBPRINTF_STATIC void bbwrite1(struct bbprintf_buf *bbb, int c);

#endif  /* _BBPRINTF_H_ */
