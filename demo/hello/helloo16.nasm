;
; helloo16.nasm: minimalistic hello-world OS/2 16-bit 286 .exe
; by pts@fazekas.hu at Wed Jan 11 12:49:49 CET 2023
;
; Compile: nasm -O0 -f bin -o helloo16.exe helloo16.nasm
; Works with NASM >= 0.98.39.
;
; Compile: mininasm -O0 -f bin -o helloo16.exe helloo16.nasm
;
; The created executable program is 222 bytes.
;
; Compatibility:
;
; * It works on Microsoft OS/2 1.0.
; * It works on IBM OS/2 1.0.
; * The DOS stub works on DOSBox 0.74.
;
; Based on
; https://github.com/OS2World/DEV-SAMPLES-ASSEMBLER-Hello_World/blob/master/HELLO.EXE
;

		bits 16
		cpu 8086
		org 0

FILE_ALIGNMENT_SHIFT equ 1 ; 1 is the minimum.
STACK_SIZE equ 0x200  ; A minimum of 0x150 is needed for OS/2 1.0.

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
.relocpos	dw 0x40  ; Value required by OS/2 1.0. 'Th' doesn't work.
;%if 0
;.noverlay	dw ?  ; Doesn't matter. overlaps with 2 bytes of message: 'll'.
;; End of 0x1c-byte .exe header.
;%endif
;
;; OpenWatcom stub message.
.message	db 'This is an OS/2 executable', 13, 10, '$'
;
.do_exit:	mov ax, 0x4c01  ; Same exit code as in OpenWatcom stub.
		int 0x21
.end:
		times 0x3c-($-$$) db 0  ; Pad to 60 bytes.
		dd ne_header-$$

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
.ChkSum		dd 0
.ProgramFlags	db PFLAG.INST
.ApplicationFlags db 0
.AutoDataSegNo	dw 1
.HeapInitSize	dw 0
.StackSize	dw STACK_SIZE  ; Do we need larger?
.InitIp 	dw _start-segment_code
.InitCsSegNo	dw 2
.InitSp:	dw segment_data_end-segment_data+STACK_SIZE
.InitSsSegNo	dw 1
.SegCnt 	dw (SegTab.end-SegTab)>>3
.ModCnt		dw (ModRefTab.end-ModRefTab)>>1
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
.seg2.fofs	dw (segment_data-$$)>>FILE_ALIGNMENT_SHIFT
.seg2.size	dw segment_data_end+2-segment_data ; Must not be 0 for OS/2 1.0.
.seg2.flags	dw $SEG.DPL3 | $SEG.DATA
.seg2.minalloc	dw segment_data_end-segment_data+STACK_SIZE
;
.seg3.fofs	dw (segment_code-$$)>>FILE_ALIGNMENT_SHIFT
.seg3.size	dw segment_code_end-segment_code
.seg3.flags	dw $SEG.DPL3 | $SEG.REL
.seg3.minalloc	dw segment_code_memend-segment_code+2
.end:

ResourceTab:
.end:

ResNameTab:  ; Must be after ResourceTab.
..@NonResNameTab:
.entry0		db .entry0.end-.entry0-3, 'm', 0, 0  ; Module name, module description (NonResNameTab).
.entry0.end:
		db 0  ; End of table.
..@NonResNameTab.end:

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

; TODO(pts): Reorder and merge tables.
EntryTab:	db 0, 0
.end:

before_segment_data times ($$-$)&((1<<FILE_ALIGNMENT_SHIFT)-1) db 0
segment_data:
segment_data_end:

before_segment_code times ($$-$)&((1<<FILE_ALIGNMENT_SHIFT)-1) db 0
segment_code:
		times segment_code-$ nop  ; Assert that we are at beginning of segment_code.
msg0		db 'Hello, World!', 10  ; No need for CRLF (13, 10) instead of LF (10).
.end:
_start:		cpu 286  ; OS/2 (even 1.0) requires 286 (for protected mode), so we can use 286 instructions below.
		; SI is initialized to 0. https://retrocomputing.stackexchange.com/q/26111 https://github.com/icculus/2ine/blob/490702cc45f53476eb2ef25bfb7501f852faf31d/lx_loader.c#L988-L1003
		; But we use BP, because according to RBIL, BP is always initialized to 0. https://fd.lod.bz/rbil/interrup/dos_kernel/214b.html
		;xor bp, bp
		push strict byte 1  ; ulAction argument of DosExit. EXIT_PROCESS == 1.
		push bp  ; ulResult argument of DosExit. EXIT_SUCCESS == 0.
		push cs
		push bp  ; push strict byte msg0-segment_code  ; CharStr argument, value is 0.
		push strict byte msg0.end-msg0  ; Length argument.
		push bp  ; VioHandle argument. must be 0 for non-GUI programs.
..@reloc1	equ $+1
		call 0x0:0xffff  ; VioWrtTTY.
..@reloc0	equ $+1
		db 0x9a, 0xff, 0xff ; call 0x0:0xffff  ; First 3 bytes only, trailing `db 0, 0' removed. DosExit.
segment_code_end:
segment_code_memend equ $+2  ; Implicit `db 0, 0'.

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
		dw $AT.FARPTR | $REL.IMPORDINAL<<8, ..@reloc0  -segment_code, (ModRefTab.doscalls-ModRefTab+2)>>1, 5   ; 'DOSCALLS'.'DOSEXIT' @5.
		dw $AT.FARPTR | $REL.IMPORDINAL<<8, ..@reloc1  -segment_code, (ModRefTab.viocalls-ModRefTab+2)>>1, 19  ; 'VIOCALLS'.'VIOWRTTTY' @19.
.end:

; __END__
