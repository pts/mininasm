; by pts@fazekas.hu at Thu Oct 27 14:02:43 UTC 2022
;
; $ nasm-0.98.39 -w-number-overflow -O0 -f bin -o arbyte.nasm98.bin arbyte.nasm
; $ ndisasm -b 16 -o 0x100 arbyte.nasm98.bin >arbyte.nasm98.ndisasm
;
; $ nasm-0.98.39 -w-number-overflow -O9 -f bin -o arbyte.nasm98o9.bin arbyte.nasm
; $ ndisasm -b 16 -o 0x100 arbyte.nasm98o9.bin >arbyte.nasm98o9.ndisasm
;
; $ nasm-0.98.39 -w-number-overflow -O1 -f bin -o arbyte.nasm98o1.bin arbyte.nasm
; $ ndisasm -b 16 -o 0x100 arbyte.nasm98o1.bin >arbyte.nasm98o1.ndisasm
;
; $ nasm-2.13.02 -w-number-overflow -O0 -f bin -o arbyte.nasm.bin arbyte.nasm
; $ ndisasm -b 16 -o 0x100 arbyte.nasm.bin >arbyte.nasm.ndisasm
;
; $ nasm-2.13.02 -w-number-overflow -O9 -f bin -o arbyte.nasmo9.bin arbyte.nasm
; $ ndisasm -b 16 -o 0x100 arbyte.nasmo9.bin >arbyte.nasmo9.ndisasm
;
; $ nasm-2.13.02 -w-number-overflow -O1 -f bin -o arbyte.nasmo1.bin arbyte.nasm
; $ ndisasm -b 16 -o 0x100 arbyte.nasmo1.bin >arbyte.nasmo1.ndisasm
;
; $ ../mininasm -f bin -o arbyte.mininasm.bin arbyte.nasm
; $ ndisasm -b 16 -o 0x100 arbyte.mininasm.bin >arbyte.mininasm.ndisasm
;
; $ ../mininasm -O1 -f bin -o arbyte.mininasmo1.bin arbyte.nasm
; $ ndisasm -b 16 -o 0x100 arbyte.mininasmo1.bin >arbyte.mininasmo1.ndisasm
;
; $ ../mininasm -O9 -f bin -o arbyte.mininasmo9.bin arbyte.nasm
; $ ndisasm -b 16 -o 0x100 arbyte.mininasmo9.bin >arbyte.mininasmo9.ndisasm
;

		bits 16
		cpu 8086
		org 0x100

		add al, 3
		add byte al, 3
		add bl, 3
		add byte bl, 3
		mov al, 3
		mov byte al, 3
		mov bl, 3
		mov byte bl, 3
		add bl, 0x7f
		add bl, -0x80
		add bl, 0x8001 + 0x8004
		add bl, 0x80
		add bl, -0x81
		nop

		add ax, 3
		add word ax, 3
		add bx, 3
		add word bx, 3
		mov ax, 3
		mov word ax, 3
		mov bx, 3
		mov word bx, 3
		add bx, 0x7f
		add bx, -0x80  ; This can be optimized to `, byte 5' since bx is only 16-bit.
		add bx, 0x8001 + 0x8004  ; This can be optimized to `, byte 5' since bx is only 16-bit.
		inc ax
		add bx, 0x80  ; Too large, can't be optimized.
		add bx, -0x81  ; Too small, can't be optimized.
		add word [si], 3
		add [si], word 3
		add word [si], 0x8001 + 0x8004
		add word [si], 0x80
		nop

		add ax, byte 3
		add word ax, byte 3
		add bx, byte 3
		add word bx, byte 3
		add al, byte 3
		add byte al, byte 3
		add bl, byte 3
		add byte bl, byte 3
		;mov ax, byte 3  ; Error in NASM.
		;mov word ax, byte 3  ; Error in NASM.
		;mov bx, byte 3  ; Error in NASM.
		;mov word bx, byte 3  ; Error in NASM.
		add bx, byte 0x8001 + 0x8004
		inc bx
		add bx, byte 0x80
		add [si], byte 3
		add word [si], byte 3
		add word [si], byte 0x8001 + 0x8004
		add word [si], byte 0x80
		nop

		inc cx
		add ax, word 3
		add ax, word 0x80
		add bx, word 3
		mov ax, word 3
		mov bx, word 3
		add word ax, word 3
		add word ax, word 0x80
		add word bx, word 3
		mov word ax, word 3
		mov word bx, word 3
		;add al, word 3  ; Error in NASM.
		;add bl, word 3  ; Error in NASM.
		;mov al, word 3  ; Error in NASM.
		;mov bl, word 3  ; Error in NASM.
		add bx, word 0x8001 + 0x8004
		add bx, word 0x80
		nop

		add ax, strict byte 3
		add word ax, strict byte 3
		add bx, strict byte 3
		add word bx, strict byte 3
		;mov ax, strict byte 3  ; Error in NASM.
		;mov word ax, strict byte 3  ; Error in NASM.
		;mov bx, strict byte 3  ; Error in NASM.
		;mov word bx, strict byte 3  ; Error in NASM.
		add al, strict byte 3
		add byte al, strict byte 3
		add bl, strict byte 3
		add byte bl, strict byte 3
		mov al, strict byte 3
		mov byte al, strict byte 3
		mov bl, strict byte 3
		mov byte bl, strict byte 3
		add bx, strict byte 0x8001 + 0x8004
		add bx, strict byte 0x80
		add [si], strict byte 3
		add word [si], strict byte 3
		add word [si], strict byte 0x8001 + 0x8004
		add word [si], strict byte 0x80
		nop

		;add ax, strict 3  ; Error in mininasm, NASM allows it.
		add ax, strict word 3
		add word ax, strict word 3
		add ax, strict word 0x80
		add word ax, strict word 0x80
		add bx, strict word 3
		add word bx, strict word 3
		mov ax, strict word 3
		mov word ax, strict word 3
		mov bx, strict word 3
		mov word bx, strict word 3
		;add al, strict word 3  ; Error in NASM.
		;add byte al, strict word 3  ; Error in NASM.
		;add bl, strict word 3  ; Error in NASM.
		;add byte bl, strict word 3  ; Error in NASM.
		;mov al, strict word 3  ; Error in NASM.
		;mov byte al, strict word 3  ; Error in NASM.
		;mov bl, strict word 3  ; Error in NASM.
		;mov byte bl, strict word 3  ; Error in NASM.
		add bx, strict word 0x8001 + 0x8004
		add bx, strict word 0x80
		add [si], strict word 3
		add word [si], strict word 3
		add word [si], strict word 0x8001 + 0x8004
		add word [si], strict word 0x80
		nop

		; `last' is an undefined label, this prevents some optimizations for NASM with -O0.
		test bx, last
		test word [bx], last
		test word [bx+1], last
		test word [bx+last], 3
		;test word [bx+last], byte 3  ; Error in NASM and mininasm. test doesn't accept a byte immediate.
		mov bx, last
		mov word [bx], last
		mov word [bx+1], last
		mov word [bx+last], 3
		;mov word [bx+last], byte 3  ; Error in NASM and mininasm. mov doesn't accept a byte immediate.
		add bx, last
		add word [bx], last
		add word [bx+1], last
		add word [bx+last], 3
		add word [bx+last], byte 3
		add byte [bx], last
		add byte [bx+1], last
		add byte [bx+last], 3
		add byte [bx+last], byte 3

jumps:
.def:		jmp .undef
		jmp short .undef
		jmp strict short .undef
		;jmp strict .undef  ; Error in mininasm, NASM allows it.
		jmp near .undef
		jmp strict near .undef
		jmp .far
		;jmp short .far  ; Error in NASM: jump out of range.
		;jmp strict short .fark  ; Error in NASM: jump out of range.
		jmp near .far
		jmp strict near .far
		jc .undef
		jc short .undef
		jc strict short .undef
		;jc near .undef  ; Error in NASM.
		;jc strict near .undef  ; Error in NASM.
		loop .undef
		;loop short .undef  ; Error in NASM. mininasm allows it.
		;loop strict short .undef  ; Error in NASM. mininasm allows it.
		;loop near .undef  ; Error in NASM.
		;loop strict near .undef  ; Error in NASM.
		;
		jmp .def
		jmp short .def
		jmp strict short .def
		jmp near .def
		jmp strict near .def
		jc .def
		jc short .def
		jc strict short .def
		;jc near .def  ; Error in NASM.
		;jc strict near .def  ; Error in NASM.
		loop .def
.undef:		times 16 lock add word [cs:bx+0x1234], 0x5768  ; 8 bytes each, 128 bytes in total. Long enough so that short (signed 8-bit) jumps don't work.
.far:


last:
