;
; helloe.nasm: the world's smallest hello-world DOS .exe program, 40 bytes
; by pts@fazekas.hu at Sat Dec 17 01:29:35 CET 2022
;
; Compile: nasm -O0 -f bin -o helloe.exe helloe.nasm
;
; Compilation was tested and works with NASM 0.98.39, 0.99.06, 2.13.02, YASM
; 1.2, YASM 1.3, mininasm.
;
; Requirements:
;
; * It must be a DOS .exe program starting with bytes "MZ" without the
;   quotes.
; * It must work on DOS running on a 8086 CPU (186, 286, 386 and newer
;   instructions are not allowed).
; * It must work on DOSBox 0.74-3 or later.
; * It must work on FreeDOS 1.2 or 1.3.
; * It must work on PC DOS 2.00.
; * It must work on MS-DOS 6.22.
; * It must print the 15 bytes "Hello, World!\r\n" without the quotes, \r
;   meaning CR (byte value 13), \n meaning LF (byte value 10) to stdout or
;   to the screen.
; * It must exit to DOS with exit code 0 (EXIT_SUCCESS).
;
; Writing a 40-byte DOS .exe seems impossible, because the DOS .exe header
; is 28 bytes, the message is 15 bytes, so it's at least 43 bytes, and we
; also need the code to print and exit. This solution works because it
; overlaps the code (and also the message) with the DOS .exe header.
;
; See a longer analysis of this code at https://stackoverflow.com/a/74831674
;
; Uses 0x3b80+0x200+0x100 bytes (<16 KiB) of conventional memory on DOS
; (including the PSP, excluding DOS buffers).
;
; Tested and found working on:
;
; * kvikdos
; * DOSBox 0.74-4
; * FreeDOS 1.2
; * PC DOS 2.00
; * MS-DOS 3.00
; * MS-DOS 3.31
; * MS-DOS 4.00
; * MS-DOS 4.01
; * MS-DOS 6.22
;

		bits 16  ; Can be omitted, NASM default.
		cpu 8086  ; Can be omitted.
		org 0x100  ; Can be omitted, the rest is independent of `org'.

exe:  ; DOS .exe header: http://justsolve.archiveteam.org/wiki/MS-DOS_EXE
.signature	db 'MZ'
.lastsize	dw end-exe  ; Number of bytes in the last 0x200-byte block in the .exe file. For us, total file size.
.nblocks	dw 1  ; Number of 0x200-byte blocks in .exe file (rounded up).
.nreloc		dw 0  ; No relocations.
.hdrsize	dw 0  ; Load .exe file to memory from the beginning.
..@code:
%if 1  ; Produces identical .exe output even if we change it to 0.
.minalloc:	mov ax, 0x903  ; AH := 9, AL := junk. The number 3 matters for minalloc, see below.
.ss_minus_1:	mov dx, message+(0x100-exe)  ; (0x100-exe) to make it work with any `org'.
.sp:		int 0x21  ; Print the message to stdout. https://stanislavs.org/helppc/int_21-9.html
.checksum:	int 0x20  ; Exit. Requires CS == PSP. https://stanislavs.org/helppc/int_20.html
%else
.minalloc	dw 0x03b8  ; To have enough room for the stack, we need minalloc >= ss+((sp+0xf)>>4)-0x20 == 0x315. kvikdos verifies it.
.maxalloc	dw 0xba09  ; Actual value doesn't matter.
.ss		dw 0x0118  ; Actual value doesn't matter as long as it matches minalloc. dw message
.sp		dw 0x21cd  ; Actual value doesn't matter. int 0x21
.checksum	dw 0x20cd  ; Actual value doesn't matter. int 0x20
%endif
.ip		dw ..@code+(0x100-exe)  ; Entry point offset. (0x100-exe) to make it work with any `org'.
.cs		dw 0xfff0  ; CS := PSP upon entry.
%if 0
.relocpos	dw ?  ; Doesn't matter, overlaps with 2 bytes of message: 'He'.
.noverlay	dw ?  ; Doesn't matter. overlaps with 2 bytes of message: 'll'.
; End of 0x1c-byte .exe header.
%endif

message		db 'Hello, World!', 13, 10, '$'
end:
