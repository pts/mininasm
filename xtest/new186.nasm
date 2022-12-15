;
; new186.nasm: test instructions intruced in the 186
; by pts@fazekas.hu at Mon Dec 12 20:11:25 CET 2022
;
; $ nasm-0.98.39 -DO0=1 -O0 -f bin -o new186.nasm98.bin new186.nasm
; $ ndisasm -b 16 -o 0x100 new186.nasm98.bin >new186.nasm98.ndisasm
;
; $ nasm-0.98.39 -O9 -f bin -o new186.nasm98o9.bin new186.nasm
; $ ndisasm -b 16 -o 0x100 new186.nasm98o9.bin >new186.nasm98o9.ndisasm
;
; $ ../mininasm -DO0=1 -f bin -o new186.mininasm.bin new186.nasm
; $ ndisasm -b 16 -o 0x100 new186.mininasm.bin >new186.mininasm.ndisasm
;
; $ ../mininasm -O9 -f bin -o new186.mininasmo9.bin new186.nasm
; $ ndisasm -b 16 -o 0x100 new186.mininasmo9.bin >new186.mininasmo9.ndisasm
;

		bits 16
		org 0x100
		cpu 8086
		
		pop cs		; db 0x0f; It's not a valid instruction, but NASM generates it even for 8086.
		db 0xff

		cmp ax, [bx]
		cmp ax, -4
		cmp ax, 0xfffc
		cmp bx, -4+($-$)  ; Optimized for mininasm with -O1.
		cmp bx, 0xfffc  ; Optimized for mininasm with -O1.
		cmp bx, word -4  ; Immediate not optimized for mininasm with -O0 and -O1, because explicit size was given.
		cmp [bx+fwd.end-fwd], word -4  ; Immediate not optimized for -O0 and -O1, because explicit size was given.
		cmp word [bx+fwd.end-fwd], -4  ; Forward reference in the effective address for mininasm with -O0 or -O1, but immediate is optimized for mininasm -O1.
		cmp word [bx+fwd.end-fwd], 0xfffc  ; Forward reference in the effective address for mininasm with -O0 or -O1, but immediate is optimized for mininasm -O1. !!!
		cmp word [bx+3], fwd.end-fwd  ; Forward reference in the immediate, not optimized for mininasm with -O0 or -O1, but effective address is optimized for mininasm -O1.

		rol byte [bx+si], cl  ; db 0xd2, 0x00. Also valid for the 8086.
		rol word [bx+si], cl  ; db 0xd3, 0x00. Also valid for the 8086.
		shl byte [bx+si], 1
		;shl byte [bx+si], byte 1  ; NASM fails for this, but mininasm accepts it.
		sal word [bx+si], 1
		rol byte [bx], $-($-1)  ; Still 8086, because shift amount is 1.
%ifdef O01
		rol byte [bx+di], 1
%else
		rol byte [bx+di], fwd.end-fwd  ; Still 8086. This doesn't compile with -O0 or -O1 because of the forward references.
%endif

%ifndef CPU_8086
		cpu 286
%endif
		ud0		; Needs cpu 186. db 0x0f, 0xff
		;db 0x0f, 0xff
		nop
		ud1		; Needs cpu 186. db 0x0f, 0xb9
		;db 0x0f, 0xb9
		nop
		ud2		; Needs cpu 186. db 0x0f, 0x0b
		;db 0x0f, 0x0b
		nop
		;ud3
		nop
		;ud4
		nop
		;ud5
		nop
%ifndef CPU_8086
		cpu 186
%endif

		; --- >=186 instructions below.

%ifdef CPU_8086
		cpu 8086  ; It won't work.
%else
		cpu 186
%endif

		pusha		; Needs cpu 186. db 0x60
		pushaw		; Needs cpu 186. db 0x60
		popa		; Needs cpu 186. db 0x61
		popaw		; Needs cpu 186. db 0x61
		insb		; db 0x6c
		insw		; db 0x6d
		outsb		; db 0x6e
		outsw		; db 0x6f
		leave		; db 0xc9

		; Encoding: db 0x6a; db imm8.
		; Encoding: db 0x68; dw imm16.
		; {Imm8S, 0, 0}, {    0x6a, X, WL_Suf|DefaultSize, CPU186|CPUNo64}},
		; {Imm16|Imm32, 0, 0}, {    0x68, X, WL_Suf|DefaultSize, CPU186|CPUNo64}},
		push 4		; db 0x6a, 4. NASM 2.13.02 -O9 optimizes it to push byte, -O0 doesn't. mininasm with -O1 also optimizes it.
		push 0x80	; db 0x68, 0x80, 0. Always push word, immediate too large.
		push 0xfffc	; NASM 2.13.02 -O9 optimizes it to push byte, -O0 doesn't. NASM 0.98.39 has its quirk. mininasm with -O1 also optimizes it.
		push -4		; NASM 2.13.02 -O9 optimizes it to push byte, -O0 doesn't. mininasm with -O1 also optimizes it.
		push byte 4	; NASM 2.13.02 -O9 optimizes it to push byte, -O0 respects the `byte'.
		push word 4	; NASM 2.13.02 -O9 optimizes it to push byte, -O0 respects the `word'. mininasm also respects the `word'.
		push strict word 4  ; Always push word.

		; Encoding: db 0xc8; dw arg1; db arg2.
		; {Imm16, Imm8, 0}, {    0xc8, X, WLQ_Suf|DefaultSize, CPU186}},
		enter 0x301, 3	; db 0xc8, 1, 2, 3
		;enter 0x301, byte 3  ; Error in NASM 2.13.02, mininasm accepts it.
		;enter word 0x301, 3  ; Error in NASM 2.13.02, mininasm accepts it.
		;enter word 0x301, byte 3  ; Error in NASM 2.13.02, mininasm accepts it.

		; Encoding: db 0x62, (r, m). Register in arg2 is not allowed. Same as lea.
		; Encoding of lea: db 0x8d, (r, m).
		; {WordReg, WordMem, 0}, { 0x62, X, WLQ_Suf|M, CPU186}},
		bound ax, [bx+si]  ; db 0x62, 0x00
		bound ax, [bx+si+1]  ; db 0x62, 0x40, 1
		bound ax, [0x201]  ; db 0x62, 0x06, 1, 2
		;bound [bx+si], ax  ; Error in NASM 2.13.02.
		;bound ax, 5  ; Error in NASM 2.13.02.
		;bound ax, bx  ; Error in NASM 2.13.02.
		;bound ax, dword [bx+si]  ; Error in NASM 2.13.02.
		;bound ax, word [bx+si]  ; Error in NASM 2.13.02. Similar to lea.

		; Encoding of byte arg1: db 0xc0, (inst, r/m), db shift_amount.
		; Encoding of byte arg2: db 0xc1, (inst, r/m), db shift_amount.
		; inst: rol=0, ror=1, rcl=2, rcr=3, shl=sal=4, shr=5, (nothing)=6, sar=7
		; {Imm8, Reg|AnyMem, 0}, { 0xc0, 0, BWLQ_Suf|W|M, CPU186}},
		rol byte [bx+si], fwd.end-fwd  ; In -O0, this becomes C0001, because it's impossible to tell whether the immediate is 1, because of the forward reference. 
		rol byte [bx+0+si], 2*(fwd.end-fwd)  ; C00004.
		rol byte [bx+si], byte 4          ; C00004
		rol byte [bx+si], byte 4          ; C00004
		rol byte [0x201], byte 0x3        ; C006010203
		ror byte [bx+si], byte 4          ; C00804
		ror byte [bx+si], byte 4          ; C00804
		rcl byte [bx+si], byte 4          ; C01004
		rcr byte [bx+si], byte 4          ; C01804
		shl byte [bx+si], byte 4          ; C02004
		sal byte [bx+si], byte 4          ; C02004
		shr byte [bx+si], byte 4          ; C02804
		sar byte [bx+si], byte 4          ; C03804
		rol byte [bx+si+0x1], byte 0x2    ; C0400102
		rol al, byte 4                    ; C0C004
		ror al,      4                    ; C0C804
		rcl al,      4                    ; C0D004
		rcr al,      4                    ; C0D804
		shl al,      4                    ; C0E004
		shr al,      4                    ; C0E804
		sar al, byte 4                    ; C0F804
		sar bh, byte 4                    ; C0FF04
		rol word [bx+si], byte 4          ; C10004
		rol word [0x201], byte 0x3        ; C106010203
		rol word [bx+si+0x1], byte 0x2    ; C1400102
		rol word [bx+si+0x1], byte 0xff   ; C14001FF
		;rol word [bx+si+0x1], word 0xff ; Error in NASM 2.13.02.

		; {Imm8S, WordReg|WordMem, WordReg},{    0x6b, X, WLQ_Suf|M, CPU186}},
		; {Imm8S, WordReg, 0},            {    0x6b, X, WLQ_Suf|M|FakeLastReg, CPU186}},
		; {Imm16|Imm32S|Imm32, WordReg|WordMem, WordReg},{    0x69, X, WLQ_Suf|M, CPU186}},
		; {Imm16|Imm32S|Imm32, WordReg, 0},{    0x69, X, WLQ_Suf|M|FakeLastReg, CPU186}},
		imul bx, 4                        ; With -O9: 6BDB04, same as `imul ax, ax, 4'.
		imul bx, -4                       ; With -O9: 6BDBFC, same as `imul ax, ax, -4'.
		imul bx, 0x80                     ; 69DB8000, same as `imul ax, ax, 0x80'.
		imul bx, fwd.end-fwd              ; With -O9: 6BDB01. With -O0: 69DB0100.
		;imul ax, [bx+si]                 ; Not even 186 or 286. db 0x0f,  0xaf,  00.
		imul ax, [bx+si], word 0x201      ; 69000102
		;imul al, [bx+si], word 0x201     ; Error in NASM 2.13.02.
		;imul al, [bx+si], byte 0x201     ; Error in NASM 2.13.02.
		;imul ax, byte [bx+si], byte 3    ; Error in NASM 2.13.02.
		imul ax, [bx+si+0x1], word 0x302  ; 6940010203
		imul ax, word [0x201], word 0x403 ; 690601020304
		imul ax, [bx+si], fwd.end-fwd     ; NASM with -O0 will use a word immediate because it doesn't optimize immediates.
		imul ax, [bx+si], byte fwd.end-fwd  ; NASM with -O0 will use a word displacement because of the quirk.
		imul ax, [bx+si], -4              ; NASM with -O0 will use a word immediate because it doesn't optimize immediates.
		imul ax, [bx+si], 0xfffc          ; NASM with -O0 will use a word immediate because of the other quirk.
		imul ax, [bx+si+0x1], byte +0x2   ; 6B400102
		imul ax, [0x201], byte +0x3       ; 6B06010203
		imul ax, word [0x201], byte +0x3  ; 6B06010203

%if 0  ; 286 protected mode instructions. Other arguments are also possible.
		cpu 286
		clts
		arpl ax, ax
		lar ax, ax
		lgdt [bx]
		lidt [bx]
		lldt ax
		lmsw ax
		lsl ax, ax
		ltr ax
		sgdt [bx]
		sidt [bx]
		sldt ax
		smsw ax
		str ax
		verr ax
		verw ax
%endif

%if 0  ; Some 8086 floating point instructions.
		cpu 8086
		fstsw [bx]
		fnstsw [bx]
%endif

%if 0  ; New in 286 since 186, in addition to the protected mode instructions.
		; These are all floating-point instructions not supported by mininasm.
		cpu 286
		;ffreep		; db 0xdf, 0xc1. Error in NASM 0.98.39, works in NASM 2.13.02.
		ffreep st2	; db 0xdf, 0xc0+float_reg. Not all CPUs support it.
		fstsw ax	; db 0x9b, 0xdf, 0xe0
		fnstsw ax	; db 0xdf, 0xe0
%endif

%if 0  ; New in 386 since 286, only a subset of the instructions.
		cpu 386  ; According to VASM 1.9a, these already work on a 286 (287).
		;fucom		; db 0xdd, 0xe1. Error in NASM 0.98.39, works in NASM 2.13.02.
		fucom st2	; db 0xdd, 0xe0+float_reg  ; float_reg is 0..7 == st0..st7
		;fucomp		; db 0xdd, 0xe9. Error in NASM 0.98.39, works in NASM 2.13.02.
		fucomp st2	; db 0xdd, 0xe8+float_reg  ; float_reg is 0..7 == st0..st7
		fucompp		; db 0xda, 0xe9
		fprem1		; db 0xd9, 0xf5
		fsincos		; db 0xd9, 0xfb
		fsin		; db 0xd9, 0xfe
		fcos		; db 0xd9, 0xff
%endif

fwd:		nop
.end:
