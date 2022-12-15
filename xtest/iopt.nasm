; by pts@fazekas.hu at Tue Nov 15 16:36:54 CET 2022
		bits 16
		cpu 8086
		org 0x100

		mov cx, [ds:78h]  ; `mov cx, [78h] would be shorter. TASM optimizes it.
		mov cx, [ss:bp+si+5]  ; mov cx, [bp+5] would be shorter. TASM optimizes it.
		lea cx, [$+78h]  ; `mov cx, $+78h' would be shorter. TASM optimizes it.
		lea cx, [bx]  ; `mov cx, bx' would be equivalent and of the same size. TASM keeps it.
		lea cx, [es:bx]  ; `mov cx, bx' and `lea cx, [bx]' would be shorter. TASM optimizes it to `lea cx, [bx]'.
		lea cx, [bp]  ; `mov cx, bp' would be shorter. TASM doesn't optimize it.
		lea cx, [si]  ; `mov cx, si' would be shorter. TASM doesn't optimize it.
		lea cx, [di]  ; `mov cx, di' would be shorter. TASM doesn't optimize it.
		lea cx, [ds:bx+5]
		lea cx, [es:bp+5]
		lea cx, [ss:di+5]
		lea cx, [cs:bp+si+5]
		les cx, [ds:bx]  ; `les cx, [bx]' would be shorter. TASM optimizes it.
		les cx, [ss:bp]  ; `les cx, [bp]' would be shorter. TASM optimizes it.
		nop
		lds cx, [es:bx]  ; Nothing to optimize here.
		mov cx, [es:78h]  ; Nothing to optimize here.
		mov cx, 78h
		mov cx, [bx]
		mov cx, [bp+5]
		mov cx, bx
		mov cx, bp
