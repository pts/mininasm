;
; by pts@fazekas.hu at Wed Nov  2 13:59:30 UTC 2022
;
; $ nasm-0.98.39 -O0 -f bin -o syntax.nasm98.bin syntax.nasm
; $ ndisasm -b 16 -o 0x100 syntax.nasm98.bin >syntax.nasm98.ndisasm
;
; $ nasm-0.98.39 -O9 -f bin -o syntax.nasm98o9.bin syntax.nasm
; $ ndisasm -b 16 -o 0x100 syntax.nasm98o9.bin >syntax.nasm98o9.ndisasm
;
; $ nasm-0.98.39 -O1 -f bin -o syntax.nasm98o1.bin syntax.nasm
; $ ndisasm -b 16 -o 0x100 syntax.nasm98o1.bin >syntax.nasm98o1.ndisasm
;
; $ nasm-2.13.02 -O0 -f bin -o syntax.nasm213.bin syntax.nasm
; $ ndisasm -b 16 -o 0x100 syntax.nasm213.bin >syntax.nasm213.ndisasm
;
; $ nasm-2.13.02 -O9 -f bin -o syntax.nasmo9.bin syntax.nasm
; $ ndisasm -b 16 -o 0x100 syntax.nasmo9.bin >syntax.nasmo9.ndisasm
;
; $ nasm-2.13.02 -O1 -f bin -o syntax.nasmo1.bin syntax.nasm
; $ ndisasm -b 16 -o 0x100 syntax.nasmo1.bin >syntax.nasmo1.ndisasm
;
; $ ../mininasm -f bin -o syntax.mininasm.bin syntax.nasm
; $ ndisasm -b 16 -o 0x100 syntax.mininasm.bin >syntax.mininasm.ndisasm
;

		bits		 16
		cPU	8086
		oRg  0x100

_start:		mov ax, $ax  ; This is a very long comment. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. ........................................................................................................................................................................................................
		%include 'empty.inc'
		%include 'empty.inc'  ; This is a very long comment. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. More characters follow. ........................................................................................................................................................................................................
		mov ax, $$+3
$ax:		; This label is a syntax error without the `$' prefix.
		mov ax, $.bx
.bx:		mov ax, $@$@@  ; `$$$@@' is a syntax error in nasm.
.value		equ $12aB
$.cX:		mov ax, @$@@  ; `$$$@@' is a syntax error in nasm.
		mOV ax, .cX
		mov ax, $ax.cX
$cmp		mov aX, _start
		mov ax, $cmp
		mov Ax, answer
@$@@:		mov ax, 0xc0Ee
		mov ax, 0c0dEh
		mov ax, 0Xc0Ee
		mov ax, 0c0dEH
		mov ax , $0c0de
%ifdef __NASM_MAJOR__
		mov ax, 10b
%else
		mov ax, 0b10  ; Binary. Syntax error in NASM 0.98.39.
%endif
		and bx, 0000000000111111b
		mov ax, 0b10h  ; Hex.
%ifdef __NASM_MAJOR__
		mov ax, 76o
%else
		mov ax, 0o76  ; Octal. Syntax error in NASM 0.98.39.
%endif
		mov ax, 76o
		;mav ax, 768o  ; Syntax error, no octal digit 8.
		mov ax, ax.value  ; $12AB, defined above. No need for `$' prefix.
		mov word ax, 129H
		mov word ax, 12Abh
		mov byte al, 12aBh & 0xff  ; Without the `& 0xff': NASM warning: byte value exceeds bounds
		;mov ax, equ
		;mov ax, dword
		;dec [bx]  ; Error in NASM.
		;dec byte  ; Error in NASM.
		dec bYTe [bx]
		dec wORd [bX]
		dec Bx
		dec word bx
		dec byte bh
		;dec byte bx  ; Disallowed in mininasm, but just a NASM warning: register size specification ignored
		;dec word bh  ; Disallowed in mininasm, but just a NASM warning: register size specification ignored

		jmp   short _start
		jmp near _start
		;jmp byte _start  ; Error in NASM.
		jmp word _start  ; Same as `jmp near _start'.
		jmp ax
		jmp word ax
		jmp [bx]
		;jc far  ; Error in NASM and mininasm.
		;jmp byte [bx]  ; Error in NASM.
		jmp word [bx]
		;jmp far _start  ; Error in NASM: error: binary output format does not support segment base references
		;jmp far ax  ; Error in NASM.
		jmp far [bx]
		;jmp dword ax  ; Error in NASM.
		;jmp dword [bx]  ; Error in NASM.
		jmp 0x1234:0xabcd
		;jmp far 0x1234:0xabcd  ; Error in NASM.
		;jmp dword 0x1234:0xabcd  ; Error in NASM.
		;call short _start  ; Error in NASM.
		call near _start
		;call byte _start  ; Error in NASM.
		call word _start  ; Same as `call near _start'.
		call ax
		call word ax
		call [bx]
		;call byte [bx]  ; Error in NASM.
		call word [bx]
		;call far _start  ; Error in NASM: error: binary output format does not support segment base references
		;call far ax  ; Error in NASM.
		call far [bx]
		;call dword ax  ; Error in NASM.
		;call dword [bx]  ; Error in NASM.
		call 0x1234:0xabcd
		;call far 0x1234:0xabcd  ; Error in NASM.

		cs nop
		ds nop
		es nop
		ss nop
		;mov ax, 1+cs  ; Error in NASM and mininasm.
		;mov ax, 1+bx  ; Error in NASM and mininasm.
		cs mov di, [_start]
		mov di, [cs:_start]
		;mov ds:[_start], sp  ; Error in NASM.
		cmp ax, [es:0x1234]
		mov ax, [  es  : 0x1234]
		mov al, [es:0x1234]
		mov word [ss:0x1234], ax
		mov [ss:0x1234], al

		; Instructions with many prefixes.
		wait  ; NASM 0.98.39 doesn't recognize wait as a prefix. NASM 2.13.02 does.
		rep   lock cs dec byte [bx]  ; rep cs   lock dec byte [bx]  ; The LOCK prefix can be prepended only to the following instructions and only to those forms of the instructions where the destination operand is a memory operand: ADD, ADC, AND, BTC, BTR, BTS, CMPXCHG, CMPXCH8B, DEC, INC, NEG, NOT, OR, SBB, SUB, XOR, XADD, and XCHG.
		repe  lock ds dec byte [bx]  ; ds repe  lock dec byte [bx]  ; NASM 0.98.39 and mininsam doesn't reorder prerfixes, NASM 2.13.02 does.
		repne lock es dec byte [bx]  ; repne es lock dec byte [bx]  ; NASM 0.99.02 fails for these: error: instruction has conflicting prefixes
		repnz lock ss dec byte [bx]  ; lock ss repnz dec byte [bx]
		repz  lock    dec byte [bx]  ; repz lock     dec byte [bx]
		;nop dec ax  ; Error in NASM and mininasm, because nop is not a prefix.

		lea ax, [si]
		lea ax, [ds:si]
		;lea ax, byte  [si]  ; Error in NASM and mininasm, because size qualifiers are not accepted.
		;lea ax, word  [si]  ; Error in NASM and mininasm, because size qualifiers are not accepted.
		;lea ax, dword [si]  ; Error in NASM and mininasm, because size qualifiers are not accepted.

		lds ax, [si]
		;lds ax, byte  [es:si]  ; Error in NASM and mininasm, because size qualifiers are not accepted.
		;lds ax, word  [si]  ; Error in NASM and mininasm, because size qualifiers are not accepted.
		;lds ax, dword [si]  ; Error in NASM and mininasm, because size qualifiers are not accepted.

		les ax, [ds:si]
		;les ax, byte  [si]  ; Error in NASM and mininasm, because size qualifiers are not accepted.
		;les ax, word  [si]  ; Error in NASM and mininasm, because size qualifiers are not accepted.
		;les ax, dword [si]  ; Error in NASM and mininasm, because size qualifiers are not accepted.

		mov ax, [ds:_]  ; `mov ax, [_] would be shorter.
		mov ax, [ss:bp+5]  ; mov ax, [bp+5] would be shorter.
		mov ax, [_]
		lea ax, [_]  ; `mov ax, _' would be shorter.
		mov ax, _
		lea ax, [bx]  ; `mov ax, bx' would be equivalent and of the same size.
		mov ax, bx
		lea ax, [es:bx]  ; `mov ax, bx' and `lea ax, [bx]' would be shorter.
		lea ax, [bp]  ; `mov ax, bp' would be shorter.
		mov ax, bp
		les ax, [ds:bx]  ; `les ax, [bx]' would be shorter.
		les ax, [ss:bp]  ; `les ax, [bp]' would be shorter.
		lds ax, [es:bx]

		; Test 32-bit unsigned arithmetic.
		mov ax, 23 / 10
		mov ax, 23/ -10
		mov ax, (-23 /10) & 0xffff
		mov ax, -23/-10
		mov ax, 0x80000000/-1
		mov ax, 23 % 10
		mov ax, 23% -10
		mov ax, -23 % 10
		mov ax, -23% -10
		mov ax, 0x80000000% -1  & 0xffff
		nop

		; Test 32-bit signed arithmetic.
		mov ax, 23 // 10
		mov ax, 23 // -10
		mov ax, -23 // 10
		mov ax, -23 // -10
		mov ax, 23 %% 10
		mov ax, 23%% -10
		mov ax, -23 %% 10
		mov ax, -23%% -10

		; Test syntax of [reg+displacement]
		mov ax, [123]
		mov ax, [bx]
		mov ax, [bx+123]
		mov ax, [bx+si+123]
		mov ax, [si+bx-123]
		mov ax, [bx+di-123]
		mov ax, [di+bx-123]
		mov ax, [bp-123]
		mov ax, [bp+si+123]
		mov ax, [si+bp-123]
		mov ax, [bp+di-123]
		mov ax, [di+bp-123]
		mov ax, [si-123]
		mov ax, [di+123]

		; Test syntax of [...displacement...] not in the end of effective address.
		mov ax, [-123+si]
		mov ax, [123+di]
		mov ax, [bx+si+123]
		mov ax, [1+bx+si-123]
		mov ax, [si-123+bx]
		mov ax, [bx-123+di]
		mov ax, [-123+di+bx]

		; Test immediate optimization.
		cmp ax, 0x80
		cmp ax, 4
		cmp ax, -4
		cmp ax, 0xfffc   ; -4. NASM 0.98.39 (but not NASM 2.13.02) with -O9 emits the `cmp ax, word -4' version, and mininasm copies this quirk.
		cmp ax, -0xfffc  ; 4.  NASM 0.98.39 (but not NASM 2.13.02) with -O9 emits the `cmp ax, word 4' version, and mininasm copies this quirk.
		cmp ax, 0x6fffc   ; -4. NASM 0.98.39 (but not NASM 2.13.02) with -O9 emits the `cmp ax, word -4' version, and mininasm copies this quirk. NASM 0.98.38 bounds check warning.
		cmp ax, -0x6fffc  ; 4.  NASM 0.98.39 (but not NASM 2.13.02) with -O9 emits the `cmp ax, word 4' version, and mininasm copies this quirk. NASM 0.98.38 bounds check warning.
		;
		cmp bx, 0x80
		cmp bx, 4
		cmp bx, -4
		cmp bx, 0xfffc   ; -4.
		cmp bx, -0xfffc  ; 4.
		cmp bx, 0x6fffc   ; -4.
		cmp bx, -0x6fffc  ; 4.
		;
		cmp ax, _-?+4  ; With forward reference.
		cmp ax, _-?+0xfffc  ; With forward reference.
		cmp bx, _-?+4  ; With forward reference.
		cmp bx, _-?+0xfffc  ; With forward reference.

co1		equ 3Bh
co2		equ 3B0h
%if co2-(co1<<4)
		db 0/0
%endif
%if co2-0x3b0
		db 0/0
%endif

%ifdef __MININASM__NOT
		db 0/0
%endif

jfoo:
.1:		jc .2
..@jbar:	jc .2  ; Doesn't change the global label, it remains `jfoo'.
junrelated1 	equ 41  ; An `equ' doesn't change the global label, it remains `jfoo'.
junrelated2:	equ 42  ; An `equ' doesn't change the global label, it remains `jfoo'.
;junrelated3	dd 0x90  ; This would change the global label to `junrelated3'.
.sub1		equ .1-jfoo  ; OK.
.sub2		equ .1-jfoo  ; OK.
.sub3		equ jfoo.1-jfoo  ; OK.
.sub4		equ jfoo.1-jfoo  ; OK.
.2:		jc .1
		jc jbaz
		jc jbaz.3
jbaz:		jc jfoo
		jc ..@jbar
		;jc jbar  ; Undefined label in NASM.
		jc .3
		jc jfoo.1
.3:		jc jfoo.2
		;jc ..@jbar.2  ; Undefined label in NASM.
		jc jbaz
..@jafter1	equ jfoo.1-$
..@jafter2	equ jbaz.3-jfoo

%if 0
.before_movs:	mov [bp-1], al
		mov [bp+1], al
		mov [bp-1], ax
		mov [bp+1], ax
		nop
		mov byte [bp-1], (.before_movs-$$+0x200) & 0xff
		mov byte [bp+1], (.before_movs-$$+0x200) & 0xff
		mov word [bp-1], .before_movs+0x200
		mov word [bp+1], .before_movs+0x200
		nop
		; Buggy in NASM 0.98.39.
		mov byte [bp-1], byte .after_movs
		mov byte [bp+1], byte .after_movs
		mov word [bp-1], .after_movs
		mov word [bp+1], .after_movs
		nop
		; Still buggy in NASM 0.98.39.
		mov byte [bp-1], byte .after_movs
		mov byte [bp+1], byte .after_movs
		mov word [bp-1], word .after_movs
		mov word [bp+1], word .after_movs
		nop
		; Buggy in NASM 0.98.39 and NASM 0.99.02, but optimized in NASM 2.13.02.
		mov byte [bx], byte .after_movs  ; This is also buggy, it has +0 offset encoded as 16-bit.
		mov byte [bx-0], byte .after_movs
		mov byte [bx+1], byte .after_movs
		mov word [bx-1], .after_movs
		mov word [bx+1], .after_movs
.after_movs:
%endif

; All label characters tried: a`~!@#$%^&*()-_=+[{]}\|,<.>/?:
@:
_:
.:
?:
a~#$@_.?:	mov [bp], di
		mov [bx + @-$$ + _-$$ + _.-$$ + ?-$$ + a~#$@_.?-$$], di
		mov [bx + $@-$$ + $_-$$ + $_.-$$ + $?-$$ + $a~#$@_.?-$$], di

		align 8  ; Good.
		dec ax
		align 8, inc ax
		;times 7*1 inc ax
		times 1+2 add al, 3
		;times -1 add al, 4  ; Negative TIMES value is an error in both NASM and mininasm.
		incbin 'syntaxi.bin'
		incbin 'syntaxi.bin', 2
		incbin 'syntaxi.bin',2, 3
		incbin 'syntaxi.bin', 2,0
		incbin 'syntaxi.bin', 2, 999999999
		%include "syntaxi.inc"
		nop

		; The next line has many trailing spaces.
		noplabel:nop                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
%if $$-_start
%ifndef UNDEFINED
		unknown instruction, skipped
%endif
%endif
%if 6*7
answer		equ(42)
%endif
data		db '\', "\", ; $ax  ; $ax is commented out here.
more_data:	db '', 'M'
		dw 0xdead
		dd 0xface432
		db 0, 1, $-$$
		times 3 db $-$$  ; Each `$' refers to the beginning of the lines.
		times 3 mov al, $-$$  ; Each `$' refers to the beginning of the lines.
.back:		times 3 jmp strict short .back  ; Each jump is relative to the current instruction.
