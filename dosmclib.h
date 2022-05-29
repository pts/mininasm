#ifndef _DOSMCLIB_H_
#define _DOSMCLIB_H_ 1
#pragma once

#include <dosmc.h>
typedef struct FILE FILE;
extern FILE *stderr;
void *malloc(size_t size);
FILE *fopen(const char *path, const char *mode);
size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
char *fgets(char *s, int size, FILE *stream);
int fclose(FILE *stream);

#endif  /* _DOSMCLIB_H_ */
