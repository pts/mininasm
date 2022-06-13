/* owcc -bwin32 -Wl,runtime -Wl,console=3.10 -fnostdlib -s -Os -c nouser32.c */

/* Overrides lib386/nt/clib3r.lib / mbcupper.o
 * Source: https://github.com/open-watcom/open-watcom-v2/blob/master/bld/clib/mbyte/c/mbcupper.c
 * Overridden implementation calls CharUpperA in USER32.DLL:
 * https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-charuppera
 *
 * This function is a transitive dependency of _cstart() with main() in
 * OpenWatcom. By overridding it, we remove the transitive dependency of all
 * .exe files compiled with `owcc -bwin32' on USER32.DLL.
 *
 * This is a simplified implementation, it keeps non-ASCII characters intact.
 */
unsigned int _mbctoupper(unsigned int c) {
  return (c - 'a' + 0U <= 'z' - 'a' + 0U)  ? c + 'A' - 'a' : c;
}
