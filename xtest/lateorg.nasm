mov dx, CMDVAL
mov dx, [bx-CMDVAL]
mov dx, msg
mov word [bx+64], -1
;add bx, msg  ; TODO(pts): bugfix: Shorter encoding of msg than NASM 0.98.39 with -O9.
;add ax, msg  ; TODO(pts): bugfix: Different instruction encoding than NASM 0.98.39 with -O9.
;mov word [bx+msg], -1  ; TODO(pts): bugfix: Error in the `org' line: program origin redefined; NASM (0.98.39 and 2.13.02) with -O9 emit 2-byte offset for msg here.
;mov word [bx+msg], msg  ; TODO(pts): bugfix: Error in the `org' line: error: program origin redefined
ret
jmp $+15
jmp $-200
jmp msg
org $$-$
answer dw 42
msg db 'Hello, World!', 13, 10
