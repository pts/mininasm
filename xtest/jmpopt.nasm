; by pts@fazekas.hu at Thu Dec 15 17:37:30 CET 2022

start:		times 0xc1 jmp ..@@a
		times 0x80 nop
..@@a:		jcxz ..@@b  ; Out-of-range only in pass 2 in mininasm.
..@@b:		;jcxz start  ; Always out-of-range, mininasm and NASM would fail.

; Here is what's happening when compiling with mininasm:
;
; * In pass 0, all jumps are faked to be short jumps, and ..@@b becomes
;   0x81*2+0x100+2 == 0x204.
;
; * There is no pass 1, because there is no late `org' directive.
;
; * In pass 2, the `jmp's are already generated as `near', because ..@@a
;   is further away than +0x7f (the shortest delta is 0x204-0x81*3 == 0x81,
;   too much for a short jump). Thus ..@a becomes 0x81*3+0x100 == 0x283. The
;   delta the jcxz becomes 0x204-(0x283+2) == -0x80, which is too much for a
;   short jump. Thus the jczx doesn't fit in this pass.
;
;   Please note that since both the `jmp's and the `jcxz' are forward jumps,
;   the target label's value from the previous pass is used (0x204) together
;   with the address (`$') from the current pass, and that's very inaccurate
;   for the `jcxz', because in pass 0, all the `jmp's are short, but in pass
;   2, all `jmp's are near, causing an error of 0x81, enough to make the
;   `jcxz' not fit.
;
; * In pass 3, the `jmp's are still generated as `near', they are still too
;   far from 0x283. In `jcxz', the value from pass 2 (0x285) is used, ..@@a
;   is still 0x283, so a delta of 0x285-(0x283+2) == 0 is generated, which
;   fits, and the assembler concludes by finishing pass 3.
;
; This would be more interesting, producing 8 passes in total:
;
;    start: times 0xc1 jmp ..@@a
;           times 0x100 nop
;    ..@@a: jcxz ..@@b
;    ..@@b:
;
;    ; after pass 1: current_address=0x204
;    ; after pass 2: current_address=0x285 jrb=0x1  ; jcxz didn't fit here.
;    ; after pass 3: current_address=0x2b0 jrb=0x0
;    ; after pass 4: current_address=0x2be jrb=0x0
;    ; after pass 5: current_address=0x2c3 jrb=0x0
;    ; after pass 6: current_address=0x2c4 jrb=0x0
;    ; after pass 7: current_address=0x2c5 jrb=0x0
;    ; after pass 8: current_address=0x2c5 jrb=0x0
;
