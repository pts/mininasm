;
; helloc.nasm: the world's smallest hello-world DOS .com program, 24 bytes
; by pts@fazekas.hu at Sat Dec 17 04:07:52 CET 2022
;
; Compile: nasm -O0 -f bin -o helloc.com helloc.nasm
;
; Compilation was tested and works with NASM 0.98.39, 0.99.06, 2.13.02, YASM
; 1.2, YASM 1.3, mininasm.
;
; Requirements:
;
; * It must be a DOS .com program not starting with bytes "MZ" without the
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
; Uses 0x10000 bytes (64 KiB) of conventional memory on DOS
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

start:		
		;xchg ax, bp  ; AH := 9, AH := junk, BP := junk. Works on kvikdos, DOSBox and FreeDOS. Doesn't work on MS-DOS or PC DOS earlier than 4.00. The value of BP was different b
		mov ah, 9  ; This works everywhere, but it is 1 byte longer than `xchg ax, bp'.
		mov dx, message+(0x100-start)  ; (0x100-exe) to make it work with any `org'.
		int 0x21  ; Print the message to stdout. https://stanislavs.org/helppc/int_21-9.html
		ret  ; Exit. Jumps to PSP:0 which contains `int 0x20'. Requires CS == PSP and a .com program with 0 pushed. https://stanislavs.org/helppc/program_segment_prefix.html https://stanislavs.org/helppc/int_20.html

message		db 'Hello, World!', 13, 10, '$'
