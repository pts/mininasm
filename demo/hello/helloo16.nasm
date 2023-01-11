;
; helloo16.nasm: minimalistic hello-world OS/2 16-bit 286 .exe
; by pts@fazekas.hu at Wed Jan 11 12:49:49 CET 2023
;
; Compile: nasm -O0 -f bin -o helloo16.exe helloo16.nasm
; Works with NASM >= 0.98.39.
;
; Compile: mininasm -O0 -f bin -o helloo16.exe helloo16.nasm
;
; The created executable program is 1581 bytes.
;
; Compatibility:
;
; * It works on Microsoft OS/2 1.0.
; * It works on IBM OS/2 1.0.
; * The DOS stub works on DOSBox 0.74.
;
; Based on and the executable program is bitwise identical to
; https://github.com/OS2World/DEV-SAMPLES-ASSEMBLER-Hello_World/blob/master/HELLO.EXE
;

		bits 16
		cpu 8086
		org 0

FILE_ALIGNMENT_SHIFT equ 9  ; TODO(pts): Change it to 1. 1 is the minimum.

mz_header:
.signature	db 'MZ'
.lastsize	dw 0x2d  ; TODO(pts): Incorrect, should be mz_memimage.end-mz_header.
.nblocks	dw 4  ; TODO(pts): Incorrect, should be 1.
.nreloc		dw 0
.hdrsize	dw (mz_memimage-mz_header)>>4
.minalloc	dw 0
.maxalloc	dw -1
.ss		dw 0
.sp		dw 0xb8
.checksum	dw 0
.ip		dw mz_memimage.start-mz_memimage
.cs		dw 0
.relocpos	dw 0x40  ; Irrelevant, since nreloc == 0.
.noverlay	dw 0
		times 0x3c-($-mz_header) db 0
		dd ne_header-$$
mz_memimage:
.start:		push cs
		pop ds
		mov dx, .msg-mz_memimage
		mov ah, 9
		int 0x21
		mov ax, 0x4c01
		int 0x21
.msg:		db 'This program cannot be run in DOS mode.', 13, 10, '$'
		times 0x80-($-mz_header) db 0

PFLAG:
.INST		equ 2

OSFLAG:
.UNKNOWN	equ 0  ; OS/2 1.0 works with this.
.OS2		equ 1

ne_header:
; https://wiki.osdev.org/NE
; https://www.fileformat.info/format/exe/corion-ne.htm
; https://program-transformation.org/Transform/NeFormat
; https://github.com/alexfru/Win16asm/blob/master/ne.inc
; https://bytepointer.com/resources/win16_ne_exe_format_win3.0.htm
.Signature	db 'NE'
.LinkerVer	db 5
.LinkerRev	db 0
.EntryTabOfs	dw EntryTab-ne_header
.EntryTabSize	dw EntryTab.end-EntryTab
.ChkSum		dd 0x2bde7720  ; TODO(pts): Can we use 0 instead?
.ProgramFlags	db PFLAG.INST
.ApplicationFlags db 0
.AutoDataSegNo	dw 2
.HeapInitSize	dw 0
.StackSize	dw 0  ; TODO(pts): Larger?
.InitIp 	dw _start-segment_code
.InitCsSegNo	dw 3
.InitSp:	dw 0x200
.InitSsSegNo	dw 1
.SegCnt 	dw (SegTab.end-SegTab)>>3
.ModCnt		dw (ModRefTab.end-ModRefTab)>>1
.NonResNameTabSize dw NonResNameTab.end-NonResNameTab
.SegTabOfs	dw SegTab-ne_header
.ResourceTabOfs	dw ResourceTab-ne_header
.ResNameTabOfs	dw ResNameTab-ne_header
.ModRefTabOfs	dw ModRefTab-ne_header
.ImpNameTabOfs	dw ImpNameTab-ne_header
.NonResNameTabOfs dd NonResNameTab-$$
.MovableEntryCnt dw 0
.SegAlignShift	dw FILE_ALIGNMENT_SHIFT
.ResourceSegCnt	dw 0
.OsFlags	db OSFLAG.UNKNOWN
.ExeFlags	db 0
.FastLoadOfs	dw 0
.FastLoadSize	dw 0
.Reserved	dw 0  ; Minimum code swap area size (?).
.ExpectedWinVer	dw 0

$SEG:
.DATA		equ 0x0001
.MOVABLE	equ 0x0010
.SHARABLE	equ 0x0020
.PRELOAD	equ 0x0040
.REL		equ 0x0100
.DPL3		equ 0x0c00
.DISCARDABLE	equ 0x1000

SegTab:
.seg1.fofs	dw (segment_stack-$$)>>FILE_ALIGNMENT_SHIFT
.seg1.size	dw segment_stack_end-segment_stack
.seg1.flags	dw $SEG.DPL3 | $SEG.DATA
.seg1.minalloc	dw segment_stack_end-segment_stack+1
;
.seg2.fofs	dw (segment_data-$$)>>FILE_ALIGNMENT_SHIFT
.seg2.size	dw segment_data_end-segment_data
.seg2.flags	dw $SEG.DPL3 | $SEG.DATA
.seg2.minalloc	dw segment_data_end-segment_data+2  ; +2 because of the unused `bytesout dw 0'.
;
.seg3.fofs	dw (segment_code-$$)>>FILE_ALIGNMENT_SHIFT
.seg3.size	dw segment_code_end-segment_code
.seg3.flags	dw $SEG.DPL3 | $SEG.REL
.seg3.minalloc	dw segment_code_end-segment_code+2
.end:

ResourceTab:
.end:

ResNameTab:
		db 5, 'HELLO', 0, 0, 0  ; TODO(pts): Make it shorter.

ModRefTab:
.doscalls:	dw ImpNameTab.mod1-ImpNameTab
.viocalls:	dw ImpNameTab.mod2-ImpNameTab
.end:

ImpNameTab:
		db 0
.mod1		db .mod1.end-$-1, 'DOSCALLS'
.mod1.end:
.mod2		db .mod2.end-$-1, 'VIOCALLS'
.mod2.end:
.name1:		db .name1.end-$-1, 'VIOWRTTTY'  ; TODO(pts): Why not import by number?
.name1.end:

EntryTab:	db 0, 0
.end:

NonResNameTab:
.entry0:	db .entry0.end-.entry0-3, 'HELLO.EXE', 0, 0  ; Module description. TODO(pts): Make it shorter or merge.
.entry0.end:
		db 0  ; End of table.
.end:

before_segment_stack times ($$-$)&((1<<FILE_ALIGNMENT_SHIFT)-1) db 0
segment_stack:
		times 0x100-1 dw 0x73  ; TODO(pts): Can we do it without hardcoding it?
		db 0x73
segment_stack_end:

before_segment_data times ($$-$)&((1<<FILE_ALIGNMENT_SHIFT)-1) db 0
segment_data:
msg0		db 'Hello World !', '!', 10, 13  ; TODO(pts): 13, 10 or 10?
;bytesout	dw 0
.end:
segment_data_end:

before_segment_code times ($$-$)&((1<<FILE_ALIGNMENT_SHIFT)-1) db 0
segment_code:
		cpu 286  ; OS/2 (even 1.0) requires 286 (for protected mode), so we can use 286 instructions below.
_start:		pusha
		push ds
		mov si, msg0-segment_data  ; CharStr argument.
		push si  ; TODO(pts): Optimize this for size on cpu 286.
		push strict byte msg0.end-msg0  ; Length argument.
		push strict byte 0  ; VioHandle argument. must be 0 for non-GUI programs.
..@reloc1	equ $+1
		call 0x0:0xffff  ; VioWrtTTY.
		popa  ; TODO(pts): Why do we need this?
		mov ax, 1
		push ax		; ulAction argument. EXIT_PROCESS == 1.
		mov ax, 0
		push ax		; ulResult argument. EXIT_SUCCESS == 0.
..@reloc0	equ $+1
		db 0x9a, 0xff, 0xff ;call 0x0:0xffff  ; First 3 bytes only, trailing 2 \0s removed. DosExit.
segment_code_end:

$AT:  ; .AddrType.
.OFFSET		equ 1
.SEGMENT	equ 2
.FARPTR		equ 3
.OFFSET16	equ 5

$REL:  ; .RelType.
.IMPORDINAL	equ 1
.IMPNAME	equ 2

segment_code_relocs:
.count:		dw (.end-.count-2)>>3  ; Each relocation is 8 bytes, 1 line each below.
		dw $AT.FARPTR | $REL.IMPORDINAL<<8, ..@reloc0  -segment_code, (ModRefTab.doscalls-ModRefTab+2)>>1, 5     ; 'DOSCALLS'.'DOSEXIT' @5.
		dw $AT.FARPTR | $REL.IMPNAME<<8,    ..@reloc1  -segment_code, (ModRefTab.viocalls-ModRefTab+2)>>1, ImpNameTab.name1-ImpNameTab     ; 'VIOCALLS'.'VIOWRTTTY' @??.
.end:

; __END__
