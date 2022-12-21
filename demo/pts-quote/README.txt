pts-quote: a DOS program to display a random quote on the console
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This is a port of pts-quote assembly sources to mininasm (and NASM and
Yasm). The original assembly sources worked with A86, NASM and Yasm. This
port produces a bitwise identical executable program: quote63m.com.golden is
the same as
https://github.com/pts/pts-quote/blob/baefb04fecbaf9fbf37d0a69a837c2aa41fbbe38/quote63.com.orig

Below is a copy of
https://github.com/pts/pts-quote/blob/baefb04fecbaf9fbf37d0a69a837c2aa41fbbe38/README.txt

pts-quote: display a random quote on the console
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
pts-quote (PotterSoftware Quote Displayer) is a collection of command-line
tools for choosing and displaying a text quote (tagline, quote-of-the-day,
QotD) randomly from a text file and displaying it on the console. Currently
it is implemented in assembly language for DOS on the Intel 8086 and 286
architectures (and it can be run in DOSBox and QEMU on modern systems).

The inital assembly language implementation for DOS on the Intel 286
architecture was written in 1996 for Turbo Pascal 7.0 inline assembly and
the A86 3.22 assembler, with the last 1996 version being quote6.com.orig in
this repository. Maintenance work (mostly software archeology, porting to
the NASM 0.98.39 and Yasm 1.2.0 assemblers and bugfixes) resumed on
2022-03-18. See the file changelog.txt for more details.

How to try and run the latest version:

* Download the latest snapshot of the pts-quote repository.
* Copy quote63.com.orig to quote.com .
  To try the latest old version from 1996 instead, copy quote5.com.orig
  instead to quote.com .
* Copy quote_demo_dos.txt to quote.txt .
* Install DOSBox.
* Run `dosbox .' (without the quotes) in the repository directory.
* Within the DOSBox window, run: del quote.idx
* Within the DOSBox window, run: quote
  This should display a random quote with a colorful banner and a frame.
  Run it again to get a different random quote.

How to compile and build:

* Most users don't need to compile from source: there are many precompiled
  .com.orig and .exe.orig files in the pts-quote repository. Just copy one
  of the .com.orig files to quote.com or one of the .exe.orig files to
  quotex.exe, and run quote.com or quotex.exe on DOS or in a DOS emulator.
* Each .pas file is a Turbo Pascal 7.0 source file, and contains compile
  instructions near the beginning (to create a DOS .exe program). To
  compile, you need the Turbo Pascal 7.0 compiler (tpc.exe and its data
  files), and you have to run it on DOS or in a DOS emulator (e.g. DOSBox).
* Each .8 file is an assembly source file in the A86 dialect (works with A86
  versions 3.22 .. 4.05), and contains compile instructions near the
  beginning (to create a DOS .com program). To compile, you need the A86
  assembler (latest version 4.05 available on http://eji.com/a86.zip ), and
  you have to run it on DOS or in a DOS emulator (e.g. DOSBox).
* Each .nasm file is an assembly source file in the NASM dialect (works with
  NASM versions 0.98.39 .. 2.13.02 ... and Yasm versions 1.2.0 and 1.2.0,
  and possibly other versions of NASM and Yasm), and contains compile
  instructions near the beginning (to create a DOS .com program). To compile,
  you need the NASM or Yasm assembler (both available for free as packages
  for Linux and macOS, and executable programs available for Windows). You
  can run these assemblers directly on modern (2022) hardware, without the
  need for emulation. However, to run the compiled DOS .com program, you
  need a DOS emulator (such as DOSBox, see instructions above) or a very
  old system running DOS.

File format of the text file quote.txt as of version 2.63:

* Quotes are separated by one or more empty lines.
* Lines are separated by LF or CRLF (can be mixed). At the end of the
  file there may be 0 or more LF or CRLF.
* Each quote must fit to 4095 bytes (including the trailing empty line).
* If a line starts with --, it will be right-aligned without the -- ,
  and it will be highlighted.
* If a line starts with -&, it will be center-aligned without the -& ,
  and it will be highlighted.
* Otherwise lines must not start with - .
* The file quote.txt must be at most 61.25 MiB in size.
* The file quote.txt must contain at least 1 quote.
* Each 1024-byte block of quote.txt must contain at most 255 quotes. That
  can be ensured by making each quote at least 5 bytes long (including the
  trailing empty line).
* The maximum number of quotes in quote.txt is 15 993 600. This is because
  quote.idx can describe up to 62720 1024-byte blocks, with up to 255 quotes
  each.
* Each quote line must be at most 78 bytes (characters) long, excluding the
  LF or CRLF terminator. This is only verified when printing the individual
  quote.
* To check whether quote.txt contains any errors (except for line-too-long
  and quote-too-long), i.e. to validate it, run quote63.com with parameter
  "i" (without the quotes). This will also regenerate the index file
  quote.idx as a side effect. There are errors iff a line starting with E is
  printed.

Further restrictions on quote.txt imposed by some earlier versions:

* Each line including the last one must be terminated with a CRLF (\r\n,
  ASCII 10 + 13).
* Quotes are separated by an empty line (i.e. CRLF + CRLF), and the last
  line must also be empty.
* If the last empty line (i.e. CRLF + CRLF) is missing, then then versions
  before 2.60 will ignore such a last quote, versions 2.60 .. 2.62 will exit
  early without finishing.
* Quotes must not be empty (i.e. CRLF + CRLF must not be followed by CRLF).
* Each quote must fit to 4095 bytes (including the trailing CRLF + CRLF).
* The file quote.txt must be at most 55 MiB in size in versions <=2.62.
* The file quote.txt must contain at most 24160 quotes in versions <2.60.
* The file quote.txt must contain at most 65535 quotes in version 2.62.

About the index file quote.idx:

* The index file is autogenerated from quote.txt if it doesn't exist.
* If you modify quote.txt, delete quote.idx, there is no autodetection
  for regeneration.
* The index file contains file offset information to make it faster to find
  the random quote in quote.txt. The index file is binary.
* The file format of the index file depends on the version of the program.
  Versions 2.30 .. 2.5? use the verbose format 5, versions since 2.60 use
  the compact format 6. Delete quote.idx between using different versions.
* Format 5 (2..30 .. 2.5?) of quote.idx index file:
  * For each quote, encode its byte size (including the trailing CRLF +
    CRLF) as 1 or 2 8-bit unsigned integers. If the size is at most 239,
    emit it as 1 8-bit unsigned integer, otherwise emit 240 + the high 4
    bits as the first 8-bit unsigned integer, and then emit the low 8 bits
    as the second 8-bit unsigned integer. Equivalently, for decoding: read
    an 8-bit unsigned integer to hi. If it's at most 239, use it as the byte
    size of the next quote, otherwise read another 8-bit unsigned integer to
    hi, and use ((hi - 240) * 256 + lo) as the byte size of the next quote.
* Format 6 (2.6? ..) of quote.idx index file:
  * Emit the total number of quotes, as 2 bytes containing an 16-bit
    unsigned little-endian integer.
  * For each block of 1024 bytes (the last block may be shorter) in
    quote.txt, emit the number of quotes whose first byte this block
    contains, as a byte containing an 8-bit unsigned integer.
  * An invariant: the first 2 bytes (as a 16-bit unsigned little-endian
    integer) equals to the sum of the subsequent bytes (as 8-bit unsigned
    integers).

pts-quote is free software released under the GNU GPL v2 license. There is
NO WARRANTY. Use at your own risk.

About the choice of programming language:

* The goal was to create working, convenient and fast program ready for
  everyday use, and also to impress the user with the tiny size of the
  executable program.
* The source code in 1996 was written in Turbo Pascal 7.0 (.pas files) and
  A86 3.22 (.8 files), because the author was familiar with those at the
  time. More specifically, the first version was written in Turbo Pascal 7.0
  (source code lost by now), then it was ported to Turbo Pascal 7.0 inline
  assembly (see quote3.pas in the pts-quote repository), then it was ported
  to A86 assembly (see quote6.8) to make the executable program size smaller
  by removing the .exe header and the Turbo Pascal 7.0 runtime library.
* For the 2022 updates, some of the A86 source code (.8 files) was ported to
  NASM (.nasm files), because of the simplicity and versatilitiy of the NASM
  assembly languange and the good native availability of free assemblers
  (NASM and Yasm) on modern systems. The source code works with old and new
  versions of NASM: the earliest supported one is NASM 0.98.39 (released on
  2005-01-15).
* NASM output (with `nasm -O0 -f bin') is compact and deterministic, and
  with NASM it's possible (and easy most of the time) to generate
  byte-by-byte identical executable program output, matching the output of
  A86 and earlier NASM versions. This is great for reproducible builds.
* Many other assemblers (such as MASM, TASM, LZASM, Wasm, GNU as) can't
  produce a DOS .com executable program directly (but they produce an object
  file, from which the linker produces an executable). This would introduce
  complexity and inconvenience to the build and development process. NASM,
  Yasm, FASM and JWasm can produce a DOS .com executable program.

__END__
