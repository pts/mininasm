;
; ifdef.nsam: ifdef assembly input file, without labels
; by pts@fazekas.hu at Mon Nov  7 23:48:38 CET 2022
;
; $ nasm-0.98.39 -O0 -f bin -o ifdef.nasm98.bin ifdef.nasm
; $ ndisasm -b 16 -o 0x100 ifdef.nasm98.bin >ifdef.nasm98.ndisasm
;
; $ nasm-0.98.39 -O9 -DO9 -f bin -o ifdef.nasm98o9.bin ifdef.nasm
; $ ndisasm -b 16 -o 0x100 ifdef.nasm98o9.bin >ifdef.nasm98o9.ndisasm
;
; $ nasm-0.98.39 -O1 -f bin -o ifdef.nasm98o1.bin ifdef.nasm
; $ ndisasm -b 16 -o 0x100 ifdef.nasm98o1.bin >ifdef.nasm98o1.ndisasm
;
; $ nasm-2.13.02 -O0 -f bin -o ifdef.nasm.bin ifdef.nasm
; $ ndisasm -b 16 -o 0x100 ifdef.nasm.bin >ifdef.nasm.ndisasm
;
; $ nasm-2.13.02 -O9 -f bin -o ifdef.nasmo9.bin ifdef.nasm
; $ ndisasm -b 16 -o 0x100 ifdef.nasmo9.bin >ifdef.nasmo9.ndisasm
;
; $ nasm-2.13.02 -O1 -f bin -o ifdef.nasmo1.bin ifdef.nasm
; $ ndisasm -b 16 -o 0x100 ifdef.nasmo1.bin >ifdef.nasmo1.ndisasm
;
; $ ../mininasm -f bin -o ifdef.mininasm.bin ifdef.nasm
; $ ndisasm -b 16 -o 0x100 ifdef.mininasm.bin >ifdef.mininasm.ndisasm
;

		bits 16
		cpu 8086
		;org 0x100

unrelated	equ 137
%ifdef FORCE_ERROR
		%assign FORCE_ERROR FORCE_ERROR
		%error FORCE_ERROR
%endif

%ifdef age  ; Not defined yet.
		db 'BAD8', 0/0
%endif

%ifdef answer  ; Not defined yet.
		db 'BAD1', 0/0
%else
%ifdef answer
		db 'BAD2', 0/0
%endif
%ifNdef answer
%else
		db 'BAD3', 0/0
%endif
answer equ 42
%define answer    answer  ; This is for NASM compatibility, `equ' does it for mininasm.
;%assign answer 42
%ifdef answer
		db 'GOOD'
%else
		db 'BAD4', 0/0
%endif
%IFNdef answer
		db 'BAD5', 0/0
%endif
%endif
%ifndef answer
		db 'BAD6', 0/0
%endif
%ifdef Answer  ; Answer and answer are different symbols.
		db 'BAD7', 0/0
%endif

		%define answer answer  ; OK, self-macro to self-macro.
		%define myself myself  ; OK, self-macro to undefined label.
		;%define answer 42  ; It's OK for NASM, but mininasm fails (to avoid ownership issues in reset_macros()) with: error: invalid macro override
		;%define unrelated 137  ; It's OK for NASM, but mininasm fails with: error: macro name conflicts with label
		;%assign answer answer  ; It's OK for NASM, but mininasm fails with: error: invalid macro override
		%define age 18
%if age-18
		db 'BAD9', 0/0
%endif
		%define age 21
%if 21-age
		db 'BAD10', 0/0
%endif
		%assign age age + answer
%if 21+answer-age
		db 'BAD11', 0/0
%endif

		%undef age
		;db age  ; Error in both NASM and mininasm.
%ifdef age
		db 'BAD112', 0/0
%endif
		%assign age 1+2
		%define age -+~~-12abH
%ifndef age
		db 'BAD113', 0/0
%endif
%if age-0x12ab
		db 'BAD114', 0/0
%endif

%ifdef DOT  ; Example invocation: mininasm "-DDOT='.'" ...
		db DOT
%endif
