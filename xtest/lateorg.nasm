mov dx, CMDVAL
;mov dx, [bx-CMDVAL]  ; mininasm error: origin not yet defined
la1:
mov dx, msg
la2:
mov word [bx+64], -1
;mov word [bx+msg-$$], 1  ; mininasm error: origin not yet defined; NASM 0.98.39 with -O9 emits 1-byte displacement even if origin is known
;mov word [msg+bx-$$], 2  ; mininasm error: origin not yet defined; NASM 0.98.39 with -O9 emits 1-byte displacement even if origin is known
;mov word [msg+bx-la1], 3  ; mininasm error: origin not yet defined; NASM 0.98.39 with -O9 emits 1-byte displacement even if origin is known
;mov word [la2+bx-la1], 4  ; mininasm error: origin not yet defined; NASM 0.98.39 with -O9 emits 1-byte displacement even if origin is known
;mov word [msg+bx-$$+2*$$-$$-$$], 5  ; mininasm error: origin not yet defined; NASM 0.98.39 with -O9 emits 1-byte displacement even if origin is known
;mov word [bx+msg], -1  ; mininasm error: origin not yet defined; NASM (0.98.39 and 2.13.02) with -O9 emit 2-byte offset for msg here.
;mov word [bx+msg], msg  ; mininasm error: origin not yet defined; NASM (0.98.39 and 2.13.02) with -O9 emit 2-byte offset for msg here.

;add word [bx], msg  ; mininasm error: origin not yet defined; NASM (0.98.39 and 2.13.02) with -O9 emit 2-byte offset for msg here.
mov word [bx], msg
add word [bx], strict word msg
%ifdef O01
add word [bx], word msg
%endif

add bx, strict word msg
%ifdef O01
add bx, word msg
%endif
add ax, strict word msg
%ifdef O01
add ax, word msg
%endif
;add bx, msg  ; mininasm error: origin not yet defined; NASM 0.98.39 with -O9 does 2-byte encoding.
;add bx, msg-$$  ; mininasm error: origin not yet defined; NASM 0.98.39 with -O9 does 2-byte encoding (??).
;add ax, msg  ; mininasm error: origin not yet defined; NASM 0.98.39 with -O9 does 2-byte encoding.
;add ax, msg-$$  ; mininasm error: origin not yet defined; NASM 0.98.39 with -O9 does 2-byte encoding (??).

ret
dw msg
times 3 dw msg-$$
jmp $+15
jmp $-200
jmp msg

org $$-$
mov dx, [bx-CMDVAL]
answer dw 42
msg db 'Hello, World!', 13, 10
