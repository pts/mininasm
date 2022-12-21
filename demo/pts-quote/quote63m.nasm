; -*- coding: utf-8 -*-
;
; quote63m.nasm: PotterSoftware Quote Displayer V2.63 (NASM, Yasm, mininasm source code)
; (C) 2022-03-30 by EplPáj of PotterSoftware, Hungary
;
; Forked from https://github.com/pts/pts-quote/blob/0125ccf0fd4e23e3d3ea1a50874f4e0230ad08e9/quote63.8
; to make it compile in mininasm, and also dropped A86 compatibility.
;
; Compile it with NASM 0.98.39 .. 2.13.02 ...:
;
;   nasm -O0 -f bin -o quote63m.com quote63m.nasm
;
; Alternatively, compile it with Yasm 1.2.0 or 1.3.0:
;
;   yasm -O0 -f bin -o quote63m.com quote63m.nasm
;
; Alternatively, compile it with mininasm:
;
;   mininasm -O0 -f bin -o quote63m.com quote63m.nasm
;
; Compiles with NASM 0.98.39 or later. Produces identical output with NASM
; 2.13.02 (with both -O0 and -O9). Also it produces identical output with
; NASM, YASM and mininasm.
;
; See the README.txt and https://github.com/pts/pts-quote for a description
; of what it does.
;
; Memory layout:
;
; * 0...0x80: PSP (Program Segment Prefix), populated by DOS.
; * 0x80...0x100: String containing command-line arguments, populated by DOS.
;   It starts with the 8-bit variable named `param'.
; * 0x100... (at most 1276 bytes): .com file (code and data) loaded by DOS.
;   Entry point is at the beginning, has label _start for convenience.
; * 0x5fc...0x9fc (1024 bytes): Variable named buffer, file preread buffer.
;   When reading our quote, it continues and overlaps idxchw, idxc and index.
; * 0x9fc...0x9fe (2 bytes): Variable named idxchw, contains the high 16 bits
;   of total number of quotes.
; * 0x9fe...0xa00 (2 bytes): Variable named idxc, contains the low 16 bits
;   of total number of quotes. First 2 bytes of the quote.idx file.
; * 0xa00...0xff00 (62720 bytes): Array variable named index, index entries:
;   each byte contains the total number of quotes whose first byte is in the
;   corresponding 1024-byte block of quote.txt. Remaining bytes of the
;   quote.idx file.
; * 0xff00...0x10000 (256 bytes): Stack, it grows from high to low offsets.
;   Before jumping to 0x100, DOS pushes the exit address 0 within the PSP
;   (containing an `int 20h' instruction), so that a simple `ret' will exit
;   the program.
;

	org 100h
	bits 16
	cpu 8086

;=======Size-measuring constants.
_bss	equ 05FCh
buflen	equ 1024
idxlen	equ 0F500h  ; 61.25 KiB
quote_limit equ 4096  ; All quotes must be shorter than this. For compatibility with earlier versions.

;=======Uninitialized data (_bss).
buffer	equ _bss	;quote.txt file preread buffer. It overlaps idxchw, idxc and index when reading our quote.
idxchw	equ _bss+buflen  ;w  ; High 16 bits of total number of quotes.
idxc	equ _bss+buflen+2  ;w  ; Low 16 bits of total number of quotes.
index	equ _bss+buflen+4  ;Index table: 1 byte for each 1024-byte block of quote.txt.
param	equ 080h	;b  ; Number of bytes in command-line arguments, part of PSP.
qqq_w	equ 0F0h	;w  TODO: Move away from command-line arguments.
qqq_before equ 0F2h	;w  TODO: Move away from command-line arguments.

;=======Code (_code).
_start:
	; Vanity header. It is mostly a no-op at the beginning of a DOS .com file.
	; The version number digits after 2. can be arbitrary.
	db 'POTTERSOFTWARE_QUOTE_DISPLAYER_2.63', 13, 10, 26, 83h, 0c4h, 14h
	;db 'POTTERSOFTWARE_FORTUNE_TELLER_2.63', 13, 10, 26, 83h, 0c4h, 16h
	dw 0xdb33  ; xor bx, bx
	mov [idxc], bx
	mov [idxchw], bx
	mov bp, errorlevel		;Keep it cached to reduce code size below.

	cmp byte [param], 2
	je l18
	mov ax, 0E0Dh
	int 10h				;BH=0, Writeln.
	mov al, 00Ah
	int 10h
	mov si, headermsg
	call header			;Print blue header message.

l18:	mov ax, 3D00h
	mov dx, txtfn
	call error_int21h		;'A' Open .txt file quote.txt.
	push ax				;Save .txt filehandle.

	mov ax, 3D00h
	mov dx, idxfn
	int 21h				;Open index file quote.idx.
	mov dl, [param]
	adc dl, 0
	jnz gen				;If failed to open (CF set after int 21h above), then generate it.
	
;=======Reads the index file quote.idx.
	dw 0xd88b  ; mov bx, ax		;Some instructions are specified as dw to match the instruction encoding of A86 exactly.
	mov ah, 3Fh
	mov cx, idxlen+2
	mov dx, idxc
	call error_int21h		;'B' Read the index file.
	sub ax, strict word (2)
	call errorc			;'C' Index file too short (less than 2 bytes).
	xchg cx, ax			;Clobber AX, we don't care.
	mov ah, 3Eh
	int 21h				;Close the index file.
	pop bx				;Restore .txt filehandle.

;=======Recomputes idxchw:idxc by summing all byte values in the index.
;	We don't use the idxc value in the beginning of the index file
;	quote.idx, because it's 16-bit only, and we may need 32 bits.
;	Prerequisite: CX = number of 1024-block bytes in the index.
	dw 0xc033  ; xor ax, ax
	mov [idxc], ax			;Clear it after read above.
	mov si, index
	jcxz r2
r1:	lodsb
	add [idxc], ax
	adc word [idxchw], strict byte (0)
	loop r1
r2:	jmp strict near l5

;=======Starts generating the index file quote.idx.
gen:	mov byte [bp], 'G'
	pop bx				;Restore .txt filehandle.
	mov di, index
	mov ah, 0			;Initial state. Can be 1 or 2 later.

l2:	push ax
	mov ah, 3Fh			;Read next 1024-byte block.
	mov cx, 1024
	mov dx, buffer
	mov si, dx
	dec byte [bp]
	call error_int21h		;'G' Read from quote.txt during indexing.
	xchg cx, ax			;Clobbers AX. We don't care.
	pop ax
	jcxz l1
	mov dl, 0			;Number of quotes in this block.

l4:	lodsb
	cmp al, 13
	je l4next			;Skip over CR.
	cmp al, 10
	jne l4lt
	cmp ah, 1
	mov ah, 2			;State 1 --LF--> state 2.
	je l4next
	mov ah, 0
	jmp strict short l4next		;State 0,2 --LF--> state 0.
l4lt:	cmp ah, 0			;State 0 --letter--> increment, state 1.
	jne l4c				;State 1,2 --letter--> state 1.
l4q:	inc dl				;Count the quote within the block.
	jnz l4b
	mov byte [bp], 'D'
	jmp strict short error		;'D' Too many quotes start in a 1024-byte block.
l4b:	add word [idxc], strict byte (1)  ;Count the quote as total. Modifies CF (inc doesn't).
	adc word [idxchw], strict byte (0)
l4c:	mov ah, 1
l4next:	loop l4
	dw 0xc28a  ; mov al, dl
	stosb				;Add byte for current block to index.
	cmp di, index+idxlen
	jne l2
	mov byte [bp], 'F'
	jmp strict short error		;'F' quote.txt too long, index full.
	; Execution path not reached.

;=======Does a DOS system call (int 21h) and exits with error if it fails.
;	Call this function with `call'.
error_int21h:
	int 21h
	; Fall through to errorc.

;=======Exits with error if CF is set. Call this function with `call'.
errorc:	inc byte [bp]		;Keeps CF intact.
	jc error
retl:	ret				;Continue if there wasn't an error.
	; Fall through to error.

;=======Exits upon error with a nonzero errorlevel indicating failure.
error:	mov ah, 9
	mov dx, errormsg
	int 21h				;Write error message to stdout.
	mov ah, 04Ch
	mov al, [bp]
	int 21h				;Exit to DOS with errorlevel (status) in AL.
	; Execution path not reached.

;=======Rewrites the index file.
l1:	cmp byte [param], 5
	je l5
	push bx				;Save .txt filehandle.
	mov ah, 3Ch
	dw 0xc933  ; xor cx, cx			;Creates with attributes = 0.
	mov dx, idxfn
	call error_int21h		;'H' Open index file quote.idx for rewriting.
	dw 0xd88b  ; mov bx, ax
	mov ah, 40h
	lea cx, [di-idxc]		;CX := DI-ofs(index) == sizeof_index.
	mov dx, idxc
	call error_int21h		;'I' Write the index file.
	mov ah, 3Eh
	int 21h				;Close index file.
	pop bx				;Restore .txt filehandle.

;=======Continues after quote.idx has been read or generated.
l5:	mov byte [bp], 'L'
	mov ax, [idxc]
	or ax, [idxchw]
	jz error			;'L' No quotes in quote.txt.
	cmp byte [param], 2
	je retl				;Exit to DOS with int 20h.
	push bx				;Save handle of quote.txt.

;=======Generates 32-bit random seed in SI:DI. Clobbers flags, AX, BX, CX.
	mov ah, 0			;Read system clock counter to CX:DX.
	int 1ah
	dw 0xf18b  ; mov si, cx
	mov di, dx
	call mixes3_si_di
	mov ah, 2			;Read clock time to CX, DX.
	int 1ah
	add si, cx
	dw 0xfa13  ; adc di, dx
	call mixes3_si_di
	mov ah, 4			;Read clock date to CX, DX.
	int 1ah
	add si, cx
	dw 0xfa13  ; adc di, dx
	call mixes3_si_di
	mov cx, ds
	add si, cx
	dw 0xfa13  ; adc di, dx
	call mixes3_si_di
	; Now SI:DI is a 32-bit random number.

;=======Generates random CX:DX:=random(idxchw:idxc) from random seed SI:DI.
;       It does the multiplication (idxchw:idxc) * (SI:DI), and keeps the
;       highest 32 bits of the 64-bit result.
;       Clobbers flags, AX, BX, SI, DI.
	dw 0xc78b  ; mov ax, di
	mul word [idxchw]  ; DX:AX = ((idxchw*DI))  ; Since idxchw<100h, CX=DX<100h.
	dw 0xca8b  ; mov cx, dx
	xchg bx, ax  ; Clobbers AX. We don't care.
	xchg ax, di  ; Clobbers DI. We don't care.
	mul word [idxc]  ; DX:AX = ((idxc*DI))  ; Result ax will be ignored.
	dw 0xda03  ; add bx, dx
	adc cx, strict byte (0) 	 ; No overflow here since CX<100h.
	dw 0xc68b  ; mov ax, si
	mul word [idxc]  ; DX:AX = ((idxc*SI))
	add ax, bx  ; Result ax and bx will be ignored.
	adc cx, dx  ; Overflow goes to CF.
	pushf
	xchg ax, si  ; Clobbers SI, we don't care.
	mul word [idxchw]  ; DX:AX = ((idxchw*SI))
	popf
	xchg ax, dx
	adc dx, cx
	adc ax, strict word (0)
	xchg cx, ax  ; Clobbers AX. We don't care.
	; CX:DX:=random(idxchw:idxc)

;=======Finds block index (as SI-offset_index) of the quote with index CX:DX.
	pop bx				;Restore handle of quote.txt.
	mov si, index
	mov ah, 0
l7:	lodsb
	test cx, cx
	jnz l7b				;More than 65535 quotes, continue.
	cmp dx, ax
	js l6
l7b:	sub dx, ax
	sbb cx, strict byte (0)
	jmp strict short l7

;=======Seeks to the block of our quote with index CX:DX.
l6:	sub si, index+2			;SI := 1024-byte block index.
	push dx				;DX = quote index within block.
	mov ax, 4200h
	mov di, buffer
	jns l8
	dw 0xd233  ; xor dx, dx		;Our quote is in block 0, seeks to the beginning.
	dw 0xc933  ; xor cx, cx
	call error_int21h		;'M' Seek to the beginning of the index file.
	mov ax, 0A0Ah
	stosw				;Add sentinel LF+LF before the beginning, for state 1 --> state 0.
	; 1023 is the maximum size of the previous quote in the current (first)
	; block and (quote_limit-1) is the maximum size of our quote.
	mov cx, 1023+(quote_limit-1)
	jmp strict near l20		;TODO: Use jmp strict short.
l8:	; Set CX:DX to 1024 * SI + 1021.
	mov dx, si
	mov cl, 10
	rol dx, cl
	dw 0xca8b  ; mov cx, dx
	and cx, ((1 << 10) - 1)
	and dx, ((1 << 6) - 1) << 10
	add dx, 1021
	adc cx, strict byte (0)
	call error_int21h		;'M' Seek to 1024 * SI + 1021, near the end of the previous block.
	; 4 is the size of the end of the previous block, 1023 is the maximum size of
	; the previous quote in the current block and (quote_limit-1) is the maximum
	; size of our quote.
	mov cx, 3+1023+(quote_limit-1)

;=======Reads the blocks containing our quote (CX bytes in total).
l20:	mov dx, di
	mov ah, 3Fh
	call error_int21h		;'N' Read quote from .txt file.
	add ax, dx
	xchg ax, di			;DI := AX and clobber AX, but shorter.
	mov ax, 0A0Ah
	stosw				;Append sentinel LF+LF.
	; Now append 11,LF,LF quote_index times (at most 765 bytes), as a
	; final sentinel to stop processing even if the index file is buggy.
	pop cx
	push cx
	jcxz lclose
l9:	inc ax
	stosb
	dec ax
	stosw
	stosw
	loop l9

lclose:	mov ah, 3Eh
	int 21h				;Close .txt file.

	pop dx				;DX := quote index within block.
	mov si, buffer
	mov ah, 1			;Initial state. Can be 0 or 2 later.

p4:	lodsb
	cmp al, 13
	je p4				;Skip over CR.
	cmp al, 10
	jne p4lt
	cmp ah, 1
	mov ah, 2			;State 1 --LF--> state 2.
	je p4
	mov ah, 0
	jmp strict short p4		;State 0,2 --LF--> state 0.
p4lt:	cmp ah, 0			;State 0 --letter--> decrement, state 1.
	mov ah, 1
	jne p4				;State 1,2 --letter--> state 1.
	dec dx				;Count the quote within the block.
	jns p4
	mov di, si
	dec di				;DI:=offset(our_quote).
	mov word [di+quote_limit-1], 0A0Ah  ;Forcibly truncate at 4095 bytes.

;=======Prints our quote.
	mov ax, 00EDAh
	mov bx, 0BFh			;'┌┐'.
	call pline			;Draw the top side of the frame.
	inc byte [bp]

lld:    mov cx, 79
	mov al, 10			;LF.
	lea si, [di-1]
	repnz scasb			;Seek LF using DI.
	jz z5
	jmp strict near error		;'O' Line too long in quote.
z5:	sub cx, strict byte (78)	;Now: byte[di-1] == 10 (LF).
	cmp byte [di-2], 13		;Compare against CRLF, we try to match CR.
	jne z5b
	inc cx				;Replacing inc+neg by not wouldn't change ZF.
z5b:	neg cx				;CX := length(line); without CR.
	jnz y91

;=======Empty line: prints foooter and exits.
lle:	mov ax, 00EC0h
	mov bx, 0D9h			;└┘.
	call pline			;Draw the bottom side of the frame.
	mov si, footermsg
	call header			;Print blue footer message.
	mov bx, 7
	call fillc
	ret				;Exit to DOS with int 20h.

y91:	mov [si], cl			;Set length of Pascal string.

;=======Prints the Pascal string starting at SI with the correct color & alignment
;       according to the control codes found at [SI] and [SI+1]. Keeps DI intact.
	; Calculate the value of BEFORE first using up AnsiCh:
	; #0=Left '-'=Right '&'=Center alignment.
	push di
	lodsb				;AL:=length(s), AL<>0.
	mov dl, 0			;AnsiCh=dl is 0 by default.
	cmp byte [si], '-'
	jne yc
	dec ax				;If AnsiCh!=0, skip first 2 characters (-- or -&).
	dec ax
	dw 0xd08b  ; mov dx, ax
	inc si
	xchg [si], dl			;Copy Pascal string length to the next byte, get new AnsiCh.
	inc si
yc:     dec si
	mov ah, 0
	mov bx, 78
	mov cx, 15
	cmp dl, 0
	jne ya
	mov al, 0
	dw 0xdb33  ; xor bx, bx
	mov cx, 7
	jmp strict near yb		;TODO: Use jmp_short.
ya:     cmp dl, '&'
	jne yb
	mov bx, 39
	shr ax, 1
	mov cx, 10
yb:     sub bx, ax
	mov di, bx
	mov ax, 0Eh*256+0b3h		;'│' Start the line.
	mov bh, 0
	int 10h
	dw 0xd98b  ; mov bx, cx
	mov cx, 78
	call filld

        ; Displays the Pascal string at SI prefixed by DI spaces.
	lodsb				;Get length of Pascal string.
	mov cl, al
	mov ch, 0
	dw 0xd18b  ; mov dx, cx
	mov bh, 0
	dw 0xcf8b  ; mov cx, di
	jcxz y5
	mov ax, 256*0Eh+' '
y2:     int 10h
	loop y2
y5:     dw 0xca8b  ; mov cx, dx
	mov ah, 0Eh
y3:     lodsb
	int 10h
	loop y3
y8:     mov cx, 78
	sub cx, di
	sub cx, dx
	jcxz y7
	mov ax, 0Eh*256+' '
y4:     int 10h
	loop y4
y7:     mov ax, 0Eh*256+0b3h		;'│' The line ends by this, too.
	int 10h
	pop di

	jmp strict near lld		;Display next line of our quote.

;=======Does 10 mix3 iterations on SI:DI (used for both input and output).
; mix3 is a period 2**32-1 PNRG ([13,17,5]), to fill the seeds.
; Clobbers flags and AX.
;
; https://stackoverflow.com/a/54708697
; https://stackoverflow.com/a/70960914
;
; The iteration count of 10 was chosen empirically by looking at key
; values 0..19 and the upper 2 and 3 bits of mixes3(key). Even 6 and 7 are
; bad, 9 is much better, 10 is good enough.
;
; Equivalent to the following C code (with key == SI:DI).
;
;   uint32_t mix3(uint32_t key) {
;     key ^= (key << 13);
;     key ^= (key >> 17);
;     key ^= (key << 5);
;     return key;
;   }
;
;   uint32_t mixes3(uint32_t key) {
;     int itc;
;     for (itc = 10; itc > 0; --itc, key = mix3(key)) {}
;     return key;
;   }
mixes3_si_di:
	push bx
	push bp
	mov ah, 10			;Do 10 iterations of mix3.
ml0:	mov bx, di
	dw 0xee8b  ; mov bp, si
	mov al, 13
ml1:	shl bx, 1
	rcl bp, 1
	dec al
	jnz ml1
	dw 0xfb33  ; xor di, bx
	xor si, bp
	mov bx, si
	shr bx, 1
	dw 0xfb33  ; xor di, bx
	mov bx, di
	dw 0xee8b  ; mov bp, si
	mov al, 5
ml2:	shl bx, 1
	rcl bp, 1
	dec al
	jnz ml2
	dw 0xfb33  ; xor di, bx
	xor si, bp
	dec ah
	jnz ml0				;Continue with next iteration of mix3.
	pop bp
	pop bx
	ret

;=======Prints colorful header or footer line (func_Header).
;	Input is Pascal string at SI.
header:	mov bx, 16
	call fillc
	mov ax, 0Eh*256+0b2h		;'▓'.
	mov byte [ploop2], 48h		;Set to `dec ax' (48h).
	call ploop
	lodsb
	mov ah, 0
	dw 0xd08b  ; mov dx, ax
	shr ax, 1
	mov cx, 25
	dw 0xc82b  ; mov cx, ax
	dw 0xd98b  ; mov bx, cx
	mov ax, 0Eh*256+' '
	mov bh, 0
	jcxz y74
y75:    int 10h
	loop y75
y74:    mov cx, [si-1]
	mov ch, 0
y76:    lodsb
	int 10h
	loop y76
	mov cx, 50
	sub cx, bx
	sub cx, dx
	mov al, ' '
	jcxz y78
y77:    int 10h
	loop y77
y78:    mov al, 0b0h			;'░'.
	mov byte [ploop2], 40h		;Set to `inc ax' (40h).
	call ploop
	mov bx, 7
	;call fillc			;Optimized away.
	;ret				;Optimized away.
fillc:	mov cx, 80			;Print 80 spaces with attributes in BX.
filld:	mov ax, 920h			;Print CX spaces with attributes in BX.
	int 10h
	ret

;=======Prints a top or bottom border line (func_PrintLine).
;	Input: AL=left corner byte; BL=right corner byte; AH=0Eh; BH=0.
pline:	int 10h
	mov cx, 78
	mov al, 196			;'─'.
y70:    int 10h
	loop y70
	dw 0xc38a  ; mov al, bl
	int 10h
	ret

ploop:	mov cx, 3
y72:    int 10h
	int 10h
	int 10h
	int 10h
	int 10h
ploop2:	dec ax				;Self-modifying code will modify this to `dec ax' or `inc ax'.
	loop y72
	ret

;=======Data with initial value (_data).
txtfn:		db 'QUOTE.TXT',0
idxfn:		db 'QUOTE.IDX',0
headermsg:	db headermsg_size, 'PotterSoftware Fortune Teller 2.63'
headermsg_size	equ $-headermsg-1
footermsg:	db footermsg_size, 'Greetings to RP,TT,FZ/S,Blala,OGY,FC,VR,JCR.'
footermsg_size	equ $-footermsg-1
errormsg:	db 'E'  ; Continues below.
errorlevel:	db 'A'-1  ; '@'.
		db 13, 10, 7  ; 7 is beep.
		db '$'  ; End of string (for AH=9, int 21h).
