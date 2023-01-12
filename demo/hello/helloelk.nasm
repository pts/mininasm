;
; helloelk.nasm: minimalistic hello-world for ELKS
; by pts@fazekas.hu at Thu Jan 12 04:06:16 CET 2023
;
; Compile: nasm -O0 -f bin -o helloelk helloelk.nasm
; Works with NASM >= 0.98.39.
;
; Compile: mininasm -O0 -f bin -o helloelk helloelk.nasm
;
; The created executable program is 65 bytes.
;
; Compatibility:
;
; * ELKS 0.6.0: It works.
;   Get fd1440-fat.img as elks060.img from https://github.com/jbruchon/elks/releases/tag/v0.6.0
;   mcopy -m -o -i elks060.img helloelk ::bin/
;   qemu-system-i386 -L pc-1.0 -m 1 -net none -fda elks060.img
;   Then root <Enter>, then helloelk <Enter>.
; * ELKS 0.5.0: It works.
;   Get fd1440-fat.img as elks050.img from https://github.com/jbruchon/elks/releases/tag/v0.5.0
;   mcopy -m -o -i elks050.img helloelk ::bin/
;   qemu-system-i386 -L pc-1.0 -m 2 -net none -fda elks050.img
;   Then root <Enter>, then helloelk <Enter>.
; * ELKS 0.4.0: It works.
;   Get fd1440-fat.bin.zip, extract it to elks040.img from https://github.com/jbruchon/elks/releases/tag/v0.4.0
;   mcopy -m -o -i elks040.img helloelk ::bin/
;   qemu-system-i386 -L pc-1.0 -m 2 -net none -fda elks040.img
;   Then root <Enter>, then helloelk <Enter>.
; * ELKS 0.2.0: It works.
;   Get elks_0.2.0_images.zip, extract the full3 archive member to elks020.img from https://github.com/jbruchon/elks/releases/tag/v0.2.0
;   mkdir mp
;   sudo mount -t minix -o loop elks020.img mp
;   chmod +x helloelk
;   sudo cp -a helloelk mp/bin/
;   sudo umount mp
;   qemu-system-i386 -L pc-1.0 -m 2 -net none -fda elks020.img
;   Then root <Enter>, then helloelk <Enter>.
;

A_FLAG:
.A_EXEC	equ 0x10  ; Executable.
.A_SEP  equ 0x20  ; Separate I/D.

STACK_SIZE equ 0x400  ; 0x380 seems to be too low (fails with `helloelk: Out of space) in ELKS 0.2.0.

elks_header:  ; https://github.com/jbruchon/elks/blob/4ac1ff3fac33160769ca5a1a04aca3cd3d15d746/elks/arch/i86/tools/a.out.h#L6-L67
.a_magic	dw 0x0301  ; A_MAGIC.
.a_flags	db A_FLAG.A_SEP  ; ELKS 0.2.0 fails if |A_FLAG.A_EXEC (as in ELKS 0.6.0) is also specified.
.a_cpu		db 4  ; A_I8086
.a_hdrlen	db .end-elks_header
.a_unused	db 0
.a_version	dw 1  ; 1 for ELKS 0.6.0 yes(1), 0 for ELKS 0.2.0 yes(1). Ignored.
.a_text		dd section_text_end-section_text
.a_data		dd section_data_end-section_data
.a_bss		dd section_bss_end-section_bss
.a_entry	dd _start-section_text
.a_total	dd section_data_end-section_data+section_bss_end-section_bss+STACK_SIZE  ; ELKS 0.2.0 uses this as chmem to determine the stack size. ELKS 0.6.0 ignores it.
.a_syms		dd 0  ; Unused.
.end:

section_text:  ; Must follow elks_header.
_start:		mov ax, 4  ; __NR_write == 4.
		mov bx, 1  ; STDOUT_FILENO == 1.
		push bx
		xor cx, cx  ; mov cx, msg-section_data  ; (0).
		mov dx, msg.end-msg
		int 0x80  ; ELKS syscall.
		pop ax  ; __NR_exit == 1.
		xor bx, bx  ; EXIT_SUCCESS == 0.
		int 0x80  ; ELKS syscall.
section_text_end:

section_data:  ; Must follow section_text.
msg		db 'Hello, World!', 10
.end:
section_data_end:

absolute $
section_bss:  ; Must follow section_data.
;dummy		resb 1  ; db ?
section_bss_end:
