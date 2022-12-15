;
; cjump.asm: tests for conditional jumps
; by pts@fazekas.hu at Thu Oct 27 14:02:43 UTC 2022
;
; $ nasm-0.98.39.static -O0 -f bin -o cjump.nasm98.bin cjump.nasm
; $ ndisasm -b 16 -o 0x100 cjump.nasm98.bin >cjump.nasm98.ndisasm
;
; $ ../mininasm -f bin -o cjump.mininasm.bin cjump.nasm
; $ ndisasm -b 16 -o 0x100 cjump.mininasm.bin >cjump.mininasm.ndisasm
;
; All these have an int8_t offset, instruction size is 2 bytes.
;
; Some of these are synonyms to each other.
;

		bits 16
		cpu 8086
		org 0x100

_start:
.to:
		ja .to
		jae .to
		jb .to
		jbe .to
		jc .to
		jcxz .to
		je .to
		jg .to
		jge .to
		jl .to
		jle .to
		jna .to
		jnae .to
		jnb .to
		jnbe .to
		jnc .to
		jne .to
		jng .to
		jnge .to
		jnl .to
		jnle .to
		jno .to
		jnp .to
		jns .to
		jnz .to
		jo .to
		jp .to
		jpe .to
		jpo .to
		js .to
		jz .to
		loop .to
		loope .to
		loopne .to
		loopnz .to
		loopz .to
; Last comment without newline.