; by pts@fazekas.hu at Thu Oct 27 14:02:43 UTC 2022
;
; $ nasm-0.98.39.static -O0 -f bin -o xchg.nasm98.bin xchg.nasm
; $ ndisasm -b 16 -o 0x100 xchg.nasm98.bin >xchg.nasm98.ndisasm
;
; $ ../mininasm -f bin -o xchg.mininasm.bin xchg.nasm
; $ ndisasm -b 16 -o 0x100 xchg.mininasm.bin >xchg.mininasm.ndisasm
;

		bits 16
		cpu 8086
		org 0x100

; perl -e 'my @R = qw(AL CL DL BL AH CH DH BH); for my $X (@R) { for my $Y (@R) { print lc("\t\txchg $X, $Y\n") } }'
x_byte:
		xchg al, al
		xchg al, cl
		xchg al, dl
		xchg al, bl
		xchg al, ah
		xchg al, ch
		xchg al, dh
		xchg al, bh
		xchg cl, al
		xchg cl, cl
		xchg cl, dl
		xchg cl, bl
		xchg cl, ah
		xchg cl, ch
		xchg cl, dh
		xchg cl, bh
		xchg dl, al
		xchg dl, cl
		xchg dl, dl
		xchg dl, bl
		xchg dl, ah
		xchg dl, ch
		xchg dl, dh
		xchg dl, bh
		xchg bl, al
		xchg bl, cl
		xchg bl, dl
		xchg bl, bl
		xchg bl, ah
		xchg bl, ch
		xchg bl, dh
		xchg bl, bh
		xchg ah, al
		xchg ah, cl
		xchg ah, dl
		xchg ah, bl
		xchg ah, ah
		xchg ah, ch
		xchg ah, dh
		xchg ah, bh
		xchg ch, al
		xchg ch, cl
		xchg ch, dl
		xchg ch, bl
		xchg ch, ah
		xchg ch, ch
		xchg ch, dh
		xchg ch, bh
		xchg dh, al
		xchg dh, cl
		xchg dh, dl
		xchg dh, bl
		xchg dh, ah
		xchg dh, ch
		xchg dh, dh
		xchg dh, bh
		xchg bh, al
		xchg bh, cl
		xchg bh, dl
		xchg bh, bl
		xchg bh, ah
		xchg bh, ch
		xchg bh, dh
		xchg bh, bh

; perl -e 'my @R = qw(AX CX DX BX SP BP SI DI); for my $X (@R) { for my $Y (@R) { print lc("\t\txchg $X, $Y\n") } }'
x_word:
		xchg ax, ax
		xchg ax, cx
		xchg ax, dx
		xchg ax, bx
		xchg ax, sp
		xchg ax, bp
		xchg ax, si
		xchg ax, di
		xchg cx, ax
		xchg cx, cx
		xchg cx, dx
		xchg cx, bx
		xchg cx, sp
		xchg cx, bp
		xchg cx, si
		xchg cx, di
		xchg dx, ax
		xchg dx, cx
		xchg dx, dx
		xchg dx, bx
		xchg dx, sp
		xchg dx, bp
		xchg dx, si
		xchg dx, di
		xchg bx, ax
		xchg bx, cx
		xchg bx, dx
		xchg bx, bx
		xchg bx, sp
		xchg bx, bp
		xchg bx, si
		xchg bx, di
		xchg sp, ax
		xchg sp, cx
		xchg sp, dx
		xchg sp, bx
		xchg sp, sp
		xchg sp, bp
		xchg sp, si
		xchg sp, di
		xchg bp, ax
		xchg bp, cx
		xchg bp, dx
		xchg bp, bx
		xchg bp, sp
		xchg bp, bp
		xchg bp, si
		xchg bp, di
		xchg si, ax
		xchg si, cx
		xchg si, dx
		xchg si, bx
		xchg si, sp
		xchg si, bp
		xchg si, si
		xchg si, di
		xchg di, ax
		xchg di, cx
		xchg di, dx
		xchg di, bx
		xchg di, sp
		xchg di, bp
		xchg di, si
		xchg di, di
