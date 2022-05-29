#include <dosmc.h>

#include "dosmclib.h"

_WCNORETURN static void unimplemented(const char *func) {
  static const STRING_WITHOUT_NUL(msg, "fatal: function not implemented: \n");
  write(2, msg, sizeof(msg) - 1);
  write(2, func, strlen(func));
  write(2, msg + sizeof(msg) - 1, 1);
  exit(126);
}

FILE *stderr;
void *malloc(size_t size) { (void)size; unimplemented("malloc"); }
FILE *fopen(const char *path, const char *mode) { (void)path; (void)mode; unimplemented("fopen"); }
size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream) { (void)ptr; (void)size; (void)nmemb; (void)stream; unimplemented("fread"); }
size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream) { (void)ptr; (void)size; (void)nmemb; (void)stream; unimplemented("fwrite"); }
char *fgets(char *s, int size, FILE *stream) { (void)s; (void)size; (void)stream; unimplemented("fgets"); }
int fclose(FILE *stream) { (void)stream; unimplemented("fclose"); }
