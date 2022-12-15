;
; simple.nsam: simple assembly input file, without labels
; by pts@fazekas.hu at Mon Nov  7 23:48:38 CET 2022
;
; $ nasm-0.98.39 -O0 -f bin -o simple.nasm98.bin simple.nasm
; $ ndisasm -b 16 -o 0x100 simple.nasm98.bin >simple.nasm98.ndisasm
;
; $ nasm-0.98.39 -O9 -DO9 -f bin -o simple.nasm98o9.bin simple.nasm
; $ ndisasm -b 16 -o 0x100 simple.nasm98o9.bin >simple.nasm98o9.ndisasm
;
; $ nasm-0.98.39 -O1 -f bin -o simple.nasm98o1.bin simple.nasm
; $ ndisasm -b 16 -o 0x100 simple.nasm98o1.bin >simple.nasm98o1.ndisasm
;
; $ nasm-2.13.02 -O0 -f bin -o simple.nasm.bin simple.nasm
; $ ndisasm -b 16 -o 0x100 simple.nasm.bin >simple.nasm.ndisasm
;
; $ nasm-2.13.02 -O9 -f bin -o simple.nasmo9.bin simple.nasm
; $ ndisasm -b 16 -o 0x100 simple.nasmo9.bin >simple.nasmo9.ndisasm
;
; $ nasm-2.13.02 -O1 -f bin -o simple.nasmo1.bin simple.nasm
; $ ndisasm -b 16 -o 0x100 simple.nasmo1.bin >simple.nasmo1.ndisasm
;
; $ ../mininasm -f bin -o simple.mininasm.bin simple.nasm
; $ ndisasm -b 16 -o 0x100 simple.mininasm.bin >simple.mininasm.ndisasm
;

		bits 16
		cpu 8086
		;org 0x100

		nop
		db 'Hello, World!'
		jmp $
