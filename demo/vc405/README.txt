port of Volkov Commander 4.05 to mininasm
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Original TASM 4.x source:
https://web.archive.org/web/20260509124150id/https://vc.vvv.kyiv.ua/download/src/vc405.zip

Port to many assemblers, including mininasm:
https://github.com/pts/pts-vc405-port

See the source files vcm.nasm and vcsetupm.nasm for compilation instructions.

Porting notes compared to NASM 0.98.39:

* The following has been changed in the source code:
  * Source fragments of `section`s have been merged, and sections have been
    reordered. That's because mininasm doesn't support `section`.
  * Uses of `%define` macros with string (i.e. non-numeric) values have been
    inlined. That's because mininasm doesn't support `%define` with
    non-numeric values.
  * All (many) uses of the two short `%macro`s have been inlined.
     That's because mininasm doesn't support `%macro`.
  * `struc` member definitions have been changed to `equ` definitions with
    half-manual offset calculation.
    That's because mininasm doesn't support `struc`.
  * The `<=` and `!=` operators in `%if` conditions have been rewritten
    using arithmetic operators.
    That's because mininasm doesn't support `<=` or `!='.
* After the changes above, the resulting source files became compatible with
  both NASM 0.98.39 and mininasm v6, producing bytewise identical output
  (DOS .com program files) in optimized mode.
