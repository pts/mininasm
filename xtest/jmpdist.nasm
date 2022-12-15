;
; jmpdist.nsam: assembly input file with various jump distances
; by pts@fazekas.hu at Sat Nov  5 15:12:36 CET 2022
;
; $ nasm-0.98.39 -O0 -f bin -o jmpdist.nasm98.bin jmpdist.nasm
; $ ndisasm -b 16 -o 0x100 jmpdist.nasm98.bin >jmpdist.nasm98.ndisasm
;
; $ nasm-0.98.39 -O9 -DO9 -f bin -o jmpdist.nasm98o9.bin jmpdist.nasm
; $ ndisasm -b 16 -o 0x100 jmpdist.nasm98o9.bin >jmpdist.nasm98o9.ndisasm
;
; $ nasm-0.98.39 -O1 -f bin -o jmpdist.nasm98o1.bin jmpdist.nasm
; $ ndisasm -b 16 -o 0x100 jmpdist.nasm98o1.bin >jmpdist.nasm98o1.ndisasm
;
; $ nasm-2.13.02 -O0 -f bin -o jmpdist.nasm.bin jmpdist.nasm
; $ ndisasm -b 16 -o 0x100 jmpdist.nasm.bin >jmpdist.nasm.ndisasm
;
; $ nasm-2.13.02 -O9 -f bin -o jmpdist.nasmo9.bin jmpdist.nasm
; $ ndisasm -b 16 -o 0x100 jmpdist.nasmo9.bin >jmpdist.nasmo9.ndisasm
;
; $ nasm-2.13.02 -O1 -f bin -o jmpdist.nasmo1.bin jmpdist.nasm
; $ ndisasm -b 16 -o 0x100 jmpdist.nasmo1.bin >jmpdist.nasmo1.ndisasm
;
; $ ../mininasm -f bin -o jmpdist.mininasm.bin jmpdist.nasm
; $ ndisasm -b 16 -o 0x100 jmpdist.mininasm.bin >jmpdist.mininasm.ndisasm
;

		bits 16
		cpu 8086
		org 0x100

		; The optimizations by mininsam and NASM with -O3 are the same.
		; NASM with -O1 and -O2 does fewer optimizations than mininasm.
_start:		jmp .1
		jmp _start+0x42  ; Encoded as jmp short even with NASM with -O0.
		jc .1
		nop
.1:		jmp .2  ; Encoded as jmp near.
%ifdef O1  ; NASM (with -O0, but not -O1) error: short jump is out of range
		jc .2  ; Encoded as jnc + jmp near.
%endif
%ifdef O9  ; NASM (with -O0, but not -O1) error: short jump is out of range
		jc .2  ; Encoded as jnc + jmp near.
%endif
		;jc near .2  ; NASM (both -O0 and -O3) error: no instruction for this cpu level
		jmp .1  ; Encoded as jmp short even with NASM with -O0.
		jcxz .1
		loop .1

		; NASM with -O0 and -O9 differ on these.
		
		cmp bx, 2  ; NASM with -O9 optimizes it signed 8-bit immediate. NASM with -O0 doesn't optimize it, even though it could.
		cmp bx, word 2
		cmp bx, byte 2
		cmp bl, byte 1
		cmp bl, 1

		cmp ax, 2  ; NASM with -O9 optimizes it signed 8-bit immediate. NASM with -O0 doesn't optimize it, even though it could.
		cmp ax, word 2
		cmp ax, byte 2
		cmp al, byte 1
		cmp al, 1

		test bx, 2  ; NASM with -O9 optimizes it signed 8-bit immediate. NASM with -O0 doesn't optimize it, even though it could.
		test bx, word 2
		;test bx, byte 2  ; Error in both NASM 0.98.39 and mininasm.
		test bl, byte 1
		test bl, 1

		test ax, 2  ; NASM with -O9 optimizes it signed 8-bit immediate. NASM with -O0 doesn't optimize it, even though it could.
		test ax, word 2
		; test ax, byte 2  ; Error in both NASM 0.98.39 and mininasm.
		test al, byte 1
		test al, 1

		mov bx, 2  ; NASM with -O9 optimizes it signed 8-bit immediate. NASM with -O0 doesn't optimize it, even though it could.
		mov bx, word 2
		; mov bx, byte 2  ; Error in both NASM 0.98.39 and mininasm.
		mov bl, byte 1
		mov bl, 1

		cmp [bx], byte 1
		cmp [bp], word 1  ; TODO(pts): Test this with -O9 and non-strict word. That should emit an 8-bit immediate.
		test [bx], byte 1
		test [bp], word 1

		; cmp [bx], 1  ; Error in both NASM and mininasm, because size is not specified.
		; test [bx], 1  ; Error in both NASM and mininasm, because size is not specified.
		cmp bx, [bx+.1-_start]  ; NASM with -09 optimizes it to signed 8-bit offset. NASM with -O0 optimizes it, because all labels are defined.
		cmp word [bx+.1-_start], _start-.1  ; NASM with -09 optimizes both to signed 8-bit offset. NASM with -O0 optimizes the offset only, because all labels are defined.
		cmp byte [bx+.2-_end], _start-.1  ; NASM with -O9 optimizes it to signed 8-bit offset. NASM with -O0 doesn't optimize it (it emits 16-bit offset), because some labels are not defined.
		cmp bx, [bx+.2-_end]  ; NASM with -O9 optimizes it to signed 8-bit offset. NASM with -O0 doesn't optimize it (it emits 16-bit offset), because some labels are not defined.
		cmp bx, [bx+.2-.1]  ; Must use 16-bit offset.
		cmp bx, [.1-_start]  ; 16-bit offset, because absolute addresses have no 8-bit encoding.
		cmp bx, [0x80]  ; 16-bit offset, because it doesn't fit to signed 8-bit.
		cmp bx, [bp]
		cmp bx, [bp+7]
		cmp bx, [bp+0x34ab]
		cmp bx, [bx+.1-.1]  ; Both NASM with -O0 and -O9 optimize it to no offset (0-bit).
		cmp bx, [bp+si+.1-.1]  ; Both NASM with -O0 and -O9 optimize it to no offset (0-bit).
		cmp bx, [bp+.1-.1]  ; Both NASM with -O0 and -O9 optimize it to 8-bit offset, because that's the minimum for [bp].
		cmp byte [bx], _end-.2    ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 0-bit.
		cmp word [bx+0], _end-.2  ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 0-bit.
		cmp word [bx+1], .2  ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 8-bit.
		cmp word [bx+_end-.2], .2-_end  ; Both offset and immediate contain an undefined label, but eventually both will end up 8-bit with -O9.
		cmp word [bp], _end-.2    ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 0-bit.
		cmp byte [bp+0], _end-.2  ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 0-bit.
		test byte [bp+0], _end-.2  ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 0-bit.
		test word [bp], _end-.2  ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 0-bit.
		mov byte [bp+0], _end-.2  ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 0-bit.
		mov word [bp], _end-.2  ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 0-bit.
		cmp word [bx], word _end-.2  ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 0-bit.
		cmp word [bx], byte _end-.2  ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 0-bit.
		cmp byte [bx], byte _end-.2  ; NASM 0.98.39 and 0.99.06 -O0 have a quirk: they emit suboptimal output because of the undefined label in the immediate: 16-bit offset instead of 0-bit.
		cmp cx, _end-.2  ; NASM with -O9 optimizes it to signed 8-bit offset. NASM with -O0 doesn't optimize it (it emits 16-bit offset), because some labels are not defined.

		times 14 lock add word [cs:bx+0x1234], 0x5768  ; 8 bytes each, 112 bytes in total. Long enough so that short (signed 8-bit) jumps don't work.

.2:		ret
		jmp .1  ; Encoded as jmp near.
		jmp .2  ; Encoded as jmp short even with NASM with -O0.
		jc .1  ; Encoded as jnc + jmp near. This works even with `nasm -O0', because it jumps backwards.
		;jcxz .1  ; NASM (both -O0 and -O3) error: short jump is out of range
		;loop .1  ; NASM (both -O0 and -O3) error: short jump is out of range
_end:
