;
; helljw16.nasm: minimalistic hello-world Win16 Windows 3.0 8086 .exe
; by pts@fazekas.hu at Tue Dec 20 22:40:03 CET 2022
;
; Compile: nasm -O0 -f bin -o helljw16.exe helljw16.nasm
; The created executable program is 282 bytes.
;
; Compatibility:
;
; * It works on Windows 3.0.
; * It works on Windows 3.11.
; * It works on Windows NT 3.1.
; * It works on Windows 95.
; * The DOS stub works on DOSBox 0.74.
;
; See also: https://github.com/alexfru/Win16asm/blob/master/ne.inc
; See also: https://board.flatassembler.net/topic.php?t=21339
; See also: https://devblogs.microsoft.com/oldnewthing/20071203-00/?p=24323
; See also: https://bytepointer.com/resources/win16_ne_exe_format_win3.0.htm
;

		bits 16
		cpu 8086
		org 0

FILE_ALIGNMENT_SHIFT equ 1

mz_header:  ; DOS .exe header: http://justsolve.archiveteam.org/wiki/MS-DOS_EXE
.signature	db 'MZ'
.lastsize:      dw (.end - .signature) & 0x1ff  ; The value 0 and 0x200 are equivalent here. Microsoft Linker 3.05 generates 0, so do we. Number of bytes in the last 0x200-byte block in the .exe file.
.nblocks:       dw (.end - .signature  + 0x1ff) >> 9  ; Number of 0x200-byte blocks in .exe file (rounded up).
.nreloc		dw 0  ; No relocations.
.hdrsize	dw 0  ; Load .exe file to memory from the beginning.
..@code:
%if 1  ; Produces identical .exe output even if we change it to 0.
.minalloc:	mov ax, 0x903  ; AH := 9, AL := junk. The number 3 matters for minalloc, see below.
.ss_minus_1:	mov dx, .message+(0x100-$$)  ; (0x100-$$) to make it work with any `org'.
.sp:		int 0x21  ; Print the message to stdout. https://stanislavs.org/helppc/int_21-9.html
.checksum:	jmp strict short .do_exit
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
.message	db 'This is a Win16 executable.', 13, 10, '$'

.do_exit:	mov ax, 0x4c01  ; Same exit code as in OpenWatcom stub.
		int 0x21

		times 0x3c-($-$$) db 0  ; Pad to 60 bytes.
		dd ne_header-$$
.end:

PFLAG:
.INST		equ 2

AFLAG:
.WINCOMPAT	equ 2

OSFLAG:
.WINDOWS	equ 2  ; Win16.

..@0x0080:
ne_header:
.Signature	db 'NE'
.LinkerVer	db 5
.LinkerRev	db 1
.EntryTabOfs	dw EntryTab-ne_header
.EntryTabSize	dw EntryTab.end-EntryTab
.ChkSum 	dd 0  ; Always 0.
.ProgramFlags	db PFLAG.INST
.ApplicationFlags db AFLAG.WINCOMPAT
.AutoDataSegNo	dw 2
.HeapInitSize	dw 0
.StackSize	dw 0x100
.InitIp 	dw _start-segment_code
.InitCsSegNo	dw 1
.InitSp 	dw 0
.InitSsSegNo	dw 2
.SegCnt 	dw (SegTab.end-SegTab)>>3
.ModCnt 	dw (ModRefTab.end-ModRefTab)>>1
.NonResNameTabSize dw ..@NonResNameTab.end-..@NonResNameTab
.SegTabOfs	dw SegTab-ne_header
.ResourceTabOfs	dw ResourceTab-ne_header
.ResNameTabOfs	dw ResNameTab-ne_header
.ModRefTabOfs	dw ModRefTab-ne_header
.ImpNameTabOfs	dw ImpNameTab-ne_header
.NonResNameTabOfs dd ..@NonResNameTab-$$
.MovableEntryCnt dw 0
.SegAlignShift	dw FILE_ALIGNMENT_SHIFT
.ResourceSegCnt	dw 0
.OsFlags	db OSFLAG.WINDOWS
.ExeFlags	db 0
.FastLoadOfs	dw 0
.FastLoadSize	dw 0
.Reserved	dw 0
.ExpectedWinVer	dw 0x300

$SEG:
.DATA		equ 0x0001
.MOVABLE	equ 0x0010
.SHARABLE	equ 0x0020
.PRELOAD	equ 0x0040
.REL		equ 0x0100
.DPL3		equ 0x0c00
.DISCARDABLE	equ 0x1000

SegTab:
.seg1.fofs	dw (segment_code-$$)>>FILE_ALIGNMENT_SHIFT
.seg1.size	dw segment_code_end-segment_code
.seg1.flags	dw $SEG.REL | $SEG.PRELOAD | $SEG.DPL3
.seg1.minalloc	dw segment_code_end-segment_code
; It's unlikely that merging these two segments (and thus saving 2 bytes)
; would work, see https://retrocomputing.stackexchange.com/a/25936
; In fact, it doesn't work on Windows 3.1.
.seg2.fofs	dw (segment_data-$$)>>FILE_ALIGNMENT_SHIFT
.seg2.size	dw segment_data_end-segment_data
.seg2.flags	dw $SEG.DATA | $SEG.PRELOAD | $SEG.DPL3
.seg2.minalloc	dw segment_data_end-segment_data
.end:

ResourceTab:  ; Must be after SegTab.
.end:

ResNameTab:  ; Must be after ResourceTab.
..@NonResNameTab:
.entry0		db .entry0.end-.entry0-3, 'm', 0, 0  ; Module name, module description (NonResNameTab).
.entry0.end:
		db 0  ; End of table.
..@NonResNameTab.end:

ModRefTab:
.user:		dw ImpNameTab.mod1-ImpNameTab
.kernel:	dw ImpNameTab.mod2-ImpNameTab
.end:

ImpNameTab: ; Must be riht after ModRefTab.
		db 0
.mod1		db .mod1.end-$-1, 'USER'
.mod1.end:
.mod2		db .mod2.end-$-1, 'KERNEL'
.mod2.end:

EntryTab:  ; Must be right after ImpNameTab.
                db 0  ; Why?
                db 0
.end:

before_segment_code times ($$-$)&((1<<FILE_ALIGNMENT_SHIFT)-1) db 0
@0x0100:
segment_code:

_start:
		; No need to set BP to 0 or push BP in Windows 3.0, 3.1, 95,
		; Windows NT 3.1. Microsoft C compiler 8.00c libc does it.
..@reloc1	equ $+1
		call 0:0xffff  ; InitTask. 'INITTASK'.'KERNEL' @91 == @0x5b. Segment doesn't seem to matter, offset must be 0xffff.
		test ax, ax
		jz strict short .fail
		push di
		db 0x33, 0xc0  ; xor ax, ax
		push ax
..@reloc2	equ $+1
		call 0:0xffff  ; WaitEvent. 'WAITEVENT'.'KERNEL' @30 == @0x1e.
..@reloc3	equ $+1
		call 0:0xffff  ; InitApp. 'INITAPP'.'USER' @5.
		test ax, ax
		jz strict short .fail
		xor ax, ax
		push ax
		push cs
		mov bx, msg_hello-segment_code
		push bx
		push cs
		mov bx, msg_hi-segment_code
		push bx
		push ax
..@reloc0	equ $+1
		call 0x0:0xffff  ; MessageBox. 'MESSAGEBOX'.'USER' @1.
		mov ax, 0x4c00  ; EXIT_SUCCESS == 0.
		int 0x21
.fail:		mov ax,0x4c01  ; EXIT_FAILURE == 1.
		int 0x21

msg_hi		db 'Hi!', 0
msg_hello	db 'Hello, World!', 0

segment_code_end:

$AT:  ; .AddrType.
.OFFSET		equ 1
.SEGMENT	equ 2
.FARPTR		equ 3
.OFFSET16	equ 5

REL:  ; .RelType.
.IMPORDINAL	equ 1
.IMPNAME	equ 2

..@0x0150:

segment_code_relocs:
.count:		dw (.end-.count-2)>>3  ; Each relocation is 8 bytes, 1 line each below.
		dw $AT.FARPTR | REL.IMPORDINAL<<8, ..@reloc0  -segment_code, (ModRefTab.user  -ModRefTab+2)>>1, 1     ; 'MESSAGEBOX'.'USER' @1.
		dw $AT.FARPTR | REL.IMPORDINAL<<8, ..@reloc1  -segment_code, (ModRefTab.kernel-ModRefTab+2)>>1, 0x5b  ; 'INITTASK'.'KERNEL' @91 == @0x5b.
		dw $AT.FARPTR | REL.IMPORDINAL<<8, ..@reloc2  -segment_code, (ModRefTab.kernel-ModRefTab+2)>>1, 0x1e  ; 'WAITEVENT'.'KERNEL' @30 == @0x1e.
		dw $AT.FARPTR | REL.IMPORDINAL<<8, ..@reloc3  -segment_code, (ModRefTab.user  -ModRefTab+2)>>1, 5     ; 'INITAPP'.'USER' @5.
.end:

; We overlap this with mz_header.
;before_segment_data times ($$-$)&((1<<FILE_ALIGNMENT_SHIFT)-1) db 0
;segment_data:
;instancedata:
;		times (instancedata+0xa)-$ db 0
;.id0xa		dw 0  ; InitTask overwrites it to stack bottom.
;.id0xc		dw 0  ; InitTask overwrites it to stack bottom.
;.id0xe		dw 0  ; InitTask overwrites it to stack top.
;segment_data_end:
segment_data equ $$
segment_data_end equ segment_data+0x10

..@0x01ac:
fileend:

; __END__
