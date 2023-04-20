mov dx, CMDVAL
;mov dx, [bx-15]  ; TODO(pts): Error: debug: oops: bad instr order fpos=0x3 added=0xb
;mov dx, [bx-CMDVAL]  ; TODO(pts): Error: debug: oops: bad instr order fpos=0x3 added=0xb
mov dx, msg
; mov word [bx+msg], msg  ; TODO(pts): Error: debug: oops: bad instr order fpos=0x3 added=0x4
; mov word [bx+msg], 0  ; TODO(pts): Error: debug: oops: bad instr order fpos=0x3 added=0x4
ret
jmp msg
org $$-$
answer dw 42
msg db 'Hello, World!', 13, 10
