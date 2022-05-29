#include <dosmc.h>

#include "dosmclib.h"

_WCNORETURN static void unimplemented(const char *func) {
  static const STRING_WITHOUT_NUL(msg, "fatal: function not implemented: \n");
  write(2, msg, sizeof(msg) - 1);
  write(2, func, strlen(func));
  write(2, msg + sizeof(msg) - 1, 1);
  exit(126);
}

void *malloc(size_t size) { (void)size; unimplemented("malloc"); }
