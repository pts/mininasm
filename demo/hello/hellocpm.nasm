;
; hellocpm.nasm: minimalistic hello-world CM/M-86 .cmd program
; by pts@fazekas.hu at Mon Jan 16 20:39:27 CET 2023
;
; Compile: nasm -O0 -f bin -o hellocpm.cmd hellocpm.nasm
; Works with NASM >= 0.98.39.
;
; Compile: mininasm -O0 -f bin -o hellocpm.cmd hellocpm.nasm
;
; The created executable program is 159 bytes.
;
; Compatibility:
;
; * It works on Digital Research CP/M-86 1.1.
; * It works on Digital Research DOS Plus 1.2.
;
; Here is how to run CP/M-86 1.1 on Linux with QEMU:
;
; * Download cpm86-at-1.img from
;   https://://github.com/tsupplis/cpm86-kernel/releases/download/v1.1-03-07/cpm86-at-1.img
; * Run: qemu-system-i386 -L isapc -m 1 -net none -soundhw pcspk -drive file=cpm86-at-1.img,format=raw,if=floppy
;
; Here is how to copy the program (as H.CMD) to a CP/M floppy image on Linux:
;
;   $ sudo apt-get install cpmtools  # cpmrm and cmpcp.
;   $ cpmrm -f ibmpc-514ss cpm86-at-1.img H.CMD
;   $ cpmcp -f ibmpc-514ss cpm86-at-1.img hellocpm.cmd 0:H.CMD
;

		bits 16
		cpu 8086
		org 0  ; Doesn't matter.

cpm86_header:  ; https://www.seasip.info/Cpm/cmdfile.html
group_descriptor0:
.type		db 1  ; Code.
.size_para	dw (code_end-code+0xf)>>4
.base_para	dw 0  ; Relocatable.
.min_size_para	dw (code_end-code+0xf)>>4
.max_size_para	dw 0
group_descriptor1:
.type		db 2  ; Data.
.size_para	dw 0
.base_para	dw 0  ; Relocatable.
.min_size_para	dw 0
.max_size_para	dw 0
		times 0x80-($-cpm86_header) db 0  ; Zero padding to end of header.

code:
_start:
		push cs
		pop ds  ; For C_WRITESTR (ds:dx).
		mov cl, 9  ; CP/M BDOS function C_WRITESTR. https://www.seasip.info/Cpm/bdos.html
		mov dx, msg-code
		int 0xe0  ; CP/M-86 BDOS syscall.
		mov cl, 0  ; CP/M BDOS function P_TERMCP.
		mov dl, 0  ; Free memory used by program.
		int 0xe0  ; CP/M-86 BDOS syscall.
msg		db 'Hello, World!', 13, 10, '$'

;%if ($-code-0x110)>>31
;		times 0x110-($-code) nop  ; 0x110 is the minimum code size if data is present.
;%endif		
;		times (code-$)&0xf nop  ; Align to paragraph boundary.
code_end:
