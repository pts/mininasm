;
; hellos32.nasm: Win32 PE .exe stub in 60 bytes
; by pts@fazekas.hu at Tue Dec 20 18:00:11 CET 2022
;
; Compile: nasm -O0 -f bin -o hellos32.exe hellos32.nasm
;
; Compilation was tested and works with NASM 0.98.39, 0.99.06, 2.13.02, YASM
; 1.2, YASM 1.3, mininasm.
;
; Uses 0x3b80+0x200+0x100 bytes (<16 KiB) of conventional memory on DOS
; (including the PSP, excluding DOS buffers).
;

		bits 16  ; Can be omitted, NASM default.
		cpu 8086  ; Can be omitted.
		org 0x100  ; Can be omitted, the rest is independent of `org'.

exe:  ; DOS .exe header: http://justsolve.archiveteam.org/wiki/MS-DOS_EXE
.signature	db 'MZ'
.lastsize:      dw (end - .signature) & 0x1ff  ; The value 0 and 0x200 are equivalent here. Microsoft Linker 3.05 generates 0, so do we. Number of bytes in the last 0x200-byte block in the .exe file.
.nblocks:       dw (end - .signature  + 0x1ff) >> 9  ; Number of 0x200-byte blocks in .exe file (rounded up).
.nreloc		dw 0  ; No relocations.
.hdrsize	dw 0  ; Load .exe file to memory from the beginning.
..@code:
%if 1  ; Produces identical .exe output even if we change it to 0.
.minalloc:	mov ax, 0x903  ; AH := 9, AL := junk. The number 3 matters for minalloc, see below. TODO(pts): Decrease 3 to 1 if nblocks == 2, decrease it to 0 if nblocks >= 3.
.ss_minus_1:	mov dx, message+(0x100-$$)  ; (0x100-$$) to make it work with any `org'.
.sp:		int 0x21  ; Print the message to stdout. https://stanislavs.org/helppc/int_21-9.html
.checksum:	jmp strict short do_exit
%else
.minalloc	dw 0x03b8  ; To have enough room for the stack, we need minalloc >= ss+((sp+0xf)>>4)-0x20 == 0x315. kvikdos verifies it.
.maxalloc	dw 0xba09  ; Actual value doesn't matter.
.ss		dw 0x0118  ; Actual value doesn't matter as long as it matches minalloc. dw message
.sp		dw 0x21cd  ; Actual value doesn't matter. int 0x21
.checksum	dw 0x21eb  ; Actual value doesn't matter.
%endif
.ip		dw ..@code+(0x100-$$)  ; Entry point offset. (0x100-$$) to make it work with any `org'.
.cs		dw 0xfff0  ; CS := PSP upon entry.
%if 0
.relocpos	dw ?  ; Doesn't matter, overlaps with 2 bytes of message: 'He'.
.noverlay	dw ?  ; Doesn't matter. overlaps with 2 bytes of message: 'll'.
; End of 0x1c-byte .exe header.
%endif

; OpenWatcom stub message.
message		db 'This is a Win32 executable', 13, 10, '$'

do_exit:	mov ax, 0x4c01  ; Same exit code as in OpenWatcom stub.
		int 0x21

		times 60-($-$$) db 0  ; Pad to 60 bytes.
		;dd pe_header

end:
