; by pts@fazekas.hu at Fri Nov 18 18:59:42 CET 2022
;
; $ nasm-0.98.39 -O9 -f bin -o cmpax.nasm98o9.bin cmpax.nasm
; $ ndisasm -b 16 -o 0x100 cmpax.nasm98o9.bin >cmpax.nasm98o9.ndisasm
;
; $ nasm-0.99.06 -O9 -f bin -o cmpax.nasm99o9.bin cmpax.nasm
; $ ndisasm -b 16 -o 0x100 cmpax.nasm99o9.bin >cmpax.nasm99o9.ndisasm
;
; $ nasm-2.13.02 -O9 -f bin -o cmpax.nasm213o9.bin cmpax.nasm
; $ ndisasm -b 16 -o 0x100 cmpax.nasm213o9.bin >cmpax.nasm213o9.ndisasm
;

		bits 16
		cpu 8086
		org 0x100

		;- 83F8FF  cmp ax,byte -0x1  ; ndisasm
		;+ 3DFFFF  cmp ax,0xffff
		cmp ax, 1
		cmp ax, -1
		add ax, -0x2c
		cmp ax, 0xffff  ; Kept in word form by NASM 0.98.39 and 0.99.06, but changed to byte form by NASM 2.13.02 (!!!).
		cmp ax, 0xffd4  ; Kept in word form by NASM 0.98.39 and 0.99.06, but changed to byte form by NASM 2.13.02 (!!!).

		;- 83C0D4  add ax,byte -0x2c
		;+ 05D4FF  add ax,0xffd4
		add ax, 1
		add ax, -1
		add ax, -0x2c
		add ax, 0xffff  ; Kept in word form by NASM 0.98.39 and 0.99.06, but changed to byte form by NASM 2.13.02 (!!!).
		add ax, 0xffd4  ; Kept in word form by NASM 0.98.39 and 0.99.06, but changed to byte form by NASM 2.13.02 (!!!).

		add dx, 1  ; Always in byte form, it's shorter.
		add dx, -1  ; Always in byte form, it's shorter.
		add dx, -0x2c  ; Always in byte form, it's shorter.
		add dx, 0xffff  ; Always in byte form, it's shorter.
		add dx, 0xffd4  ; Always in byte form, it's shorter.
