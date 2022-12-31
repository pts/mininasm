;
; 2ktetris.nasm: port of SmallTetris v1.0 1992-09-03 to NASM and mininasm
; translated to NASM 0.98.39 by pts@fazekas.hu at Sat Dec 31 11:57:07 CET 2022
;
; SmallTetris was written by Tore Bastiansen.
;
; Compile: nasm -O9 -f bin -o 2ktetris.com 2ktetris.nasm
;
; Compile: mininasm -O9 -f bin -o 2ktetris.com 2ktetris.nasm
;
; The produced 2ktetris.com executable program is bitwise identical to the
; officially released tetris.com file produced by TASM+TLINK.
;
; Some specific changes:
;
; * tabs were converted to spaces using `expand -t 4'
; * instances of .code and .data section were grouped together (manual linking)
; * [...] was added manually, especially after `byte ptr' and `word ptr'
; * jump_table[bx]  -->  [jump_table+bx]
; * `ptr' and `offset' were removed automatically
; * proc was converted to `:'
; * endp lines were removed
; * `label' was converted to `:'
; * call dword ptr OldInt1c -->  call far [OldInt1c]
; * ds:... prefix was removed when it is the default
; * lea was manually converted to mov
; * random [...] had to be added after inaccurate ptr vs offset conversion
; * 2-byte encoding of `dw 0xe432  ; TASM xor ah, ah' etc. is different in TASM and NAsM
; * some alignment 0 bytes had to be added to simulate TASM+TLINK
;

    bits 16
    cpu 8086
    org 100h

LEVEL_WAIT_INIT equ     700
START_POS       equ     280

HISCORE_POS     equ     24
SCORE_POS       equ     264
LEVEL_POS       equ     424


PREVIEW_POS     equ     380

Start:
;   INITIALIZATION
;   **************

    cld

;   Test command line
    dw 0xdb33  ; TASM xor bx, bx
    dw 0xd232  ; TASM xor dl, dl
    mov     cl, byte [80h]            ; Command line length
cmd_loop:
    dw 0xc922  ; TASM and cl, cl                           ;cl=0?
    je      short cmd_loop_end
    mov     al, byte [81h+bx]
    dec     cl
    inc     bx
    cmp     al, ' '                          ;skip space
    jne     short not_space
    cmp     dl, 10
    jne     short cmd_loop
    dw 0xd232  ; TASM xor dl, dl
    jmp     short cmd_loop
not_space:
    cmp     dl, 0
    je      short get_minus
    push    ax
    mov     ax, word [StartLevel]
    mov     dl, 10
    mul     dl
    mov     word [StartLevel], ax
    pop     ax
    sub     al, '0'
    add     word [StartLevel], ax
    jmp     short cmd_loop
get_minus:
    cmp     al, '-'
    jne     cmd_error
    dw 0xc922  ; TASM and cl, cl
    je      cmd_error
    mov     al, byte [81h+bx]
    dec     cl
    inc     bx
    cmp     al, 'p'                          ; preview mode
    je      preview_mode
    cmp     al, 'l'
    jne     cmd_error
    inc     dx                              ; dx type boolean
    jmp     short cmd_loop
preview_mode:
    inc     word [PreView]
    jmp     short cmd_loop
cmd_loop_end:
    cmp     word [StartLevel], 0
    je      short set_level
    cmp     word [StartLevel], 17
    jbe     short level_ok
cmd_error:
    mov     dx, ErrorText
    mov     ah, 09h
    int     21h
    mov     ax, 0h
    int     21h
set_level:
    mov     word [StartLevel], 1
level_ok:

;   Get old int 1ch
    mov     ax, 351ch                       ; Function 35 interrupt 1c
    int     21h                             ; Get interrupt adress
    mov     word [OldInt1c], bx           ; 1c clock tick
    mov     ax, es
    mov     word [OldInt1c+2], ax

;   Store new int 1ch
    mov     dx, _NewInt1c            ; Set clock tick
    mov     ax, 251ch                       ; to point to NewInt1c
    int     21h

;   Set ctrl/break int
    mov     dx, quit
    mov     al, 23h
    int     21h

;   Play again starts here
restart:
    mov     ax, word [StartLevel]
    mov     word [Level], ax
    mov     word [Score], 0
    mov     word [Score+2], 0

    call    RandInit               ; Initialize random numbers
    call    InitScreen             ; Initialize screen

;   Print hiscore holder
    mov     ah, 02h
    mov     dl, 10
    int     21h
    mov     dl, 13
    int     21h
    mov     dx, HiScoreName
    mov     ah, 09h
    int     21h

;   Print first preview
    cmp     word [PreView], 0
    je      no_init_preview
    mov     ax, [OldRand]
    shl     ax, 1
    shl     ax, 1
    mov     [PreItem], ax
    mov     si, 1
    mov     di, PREVIEW_POS
    call    Print
no_init_preview:

;   Calculate clicks before next level change
    mov     ax, LEVEL_WAIT_INIT             ; wait level*700 clicks
    mov     dx, word [Level]              ; befor next level change
    mov     word [TimerInit], 18
    sub     word [TimerInit], dx
    mul     dx
    mov     word [LevelWait], ax           ; set LevelWait to 18-level

;   Print out level
    dw 0xd233  ; TASM xor dx, dx
    mov     ax, word [Level]               ; print level
    mov     di, LEVEL_POS
    call    PrintLong

;   Print Hiscore
    mov     dx, word [HiScore+2]
    mov     ax, word [HiScore]
    mov     di, HISCORE_POS
    call    PrintLong

;   Main loop
;   *********

    jmp     short while_kbhit
for_ever:
    cmp     word [Timer], 0
    jne     short while_kbhit
    mov     ax, word [TimerInit]
    mov     [Timer], ax
    call    Down                  ; go down
    dw 0xc00b  ; TASM or ax, ax
    jne     while_kbhit
    jmp     game_over

while_kbhit:
    mov     ah, 0bh
    int     21h
    dw 0xc00a  ; TASM or al, al
    je      short for_ever

    call    GetKey                 ; al=getkey

    cmp     al, 'p'
    jne     short not_p
    xor     word [PreView], 1
    jnz     short prev_on
    call    RemovePreView
    jmp     not_p
prev_on:
    call    PrintPreView
not_p:
    dw 0xc00a  ; TASM or al, al
    je      zero_key
    dw 0xe432  ; TASM xor ah, ah
    sub     ax, strict word '2'
    dw 0xd88b  ; TASM mov bx, ax
    cmp     bx, 7
    ja      short while_kbhit
    shl     bx, 1
    jmp     word [cs:jump_table2+bx]
zero_key:

    call    GetKey                 ; al=getkey

   ;                    switch(ch)
    cbw                                     ; ax=al
    sub     ax, strict word 72
    dw 0xd88b  ; TASM mov bx, ax
    cmp     bx, 8
    ja      short while_kbhit
    shl     bx, 1
    jmp     word [cs:jump_table+bx]
go_left:
    push    si
    mov     si, -2
    call    Move
    pop     si
    jmp     short while_kbhit
go_right:
    push    si
    mov     si, 2
    call    Move
    pop     si
    jmp     short while_kbhit
go_drop:
    call    Drop
    dw 0xc00b  ; TASM or ax, ax
    je      short game_over
    jmp     short while_kbhit
go_rotate:
    call    Rotate
    jmp     short while_kbhit
inc_level:
    cmp     word [Level], 17
    jge     short while_kbhit
    add     word [LevelWait], LEVEL_WAIT_INIT
    inc     word [Level]
    dec     word [TimerInit]
    dw 0xd233  ; TASM xor dx, dx
    mov     ax, word [Level]
    mov     di, LEVEL_POS
    call    PrintLong
    jmp     while_kbhit
game_over:
    mov     word [Timer], 0
    mov     byte [Paused], 1

;   Test for new hiscore
    mov     dx, word [Score+2]
    mov     ax, word [Score]
    cmp     word [HiScore+2], dx
    ja      no_hiscore
    jb      short new_hi
test_lsw:
    cmp     word [HiScore], ax
    jb      short new_hi
    jmp     short no_hiscore
new_hi:
    mov     word [HiScore], ax
    mov     word [HiScore+2], dx

;   Get name of hiscore holder
    mov     dx, EnterName
    mov     ah, 09h
    int     21h
    mov     dx, HiScoreData
    mov     ah, 0ah
    int     21h
    mov     bl, [HiScoreData+1]
    inc     bl
    dw 0xff32  ; TASM xor bh, bh
    mov     byte [HiScoreName+bx], 13
    inc     bl
    mov     byte [HiScoreName+bx], '$'


;   Get tetris filename
    push    ds
    mov     ah, 30h
    int     21h
    mov     ax, [002ch]
    mov     es, ax
    dw 0xff33  ; TASM xor di, di
    dw 0xc78b  ; TASM mov ax, di
    mov     cx, 07fffh
    cld
EnvLoop:
    repnz scasb
    cmp     [es:di], ah
    jne     EnvLoop
    or      ch, 10000000b
    neg     cx

    dw 0xf18b  ; TASM mov si, cx
    inc     si
    inc     si

    push    ds
    push    es
    pop     ds
    dw 0xd68b  ; TASM mov dx, si
    mov     ax, 3d00h + 010b                 ; 010b = read/write
    int     21h                             ; open tetris.com
    pop     ds

    dw 0xd88b  ; TASM mov bx, ax                           ; file handle
    mov     ax, 4200h                        ; lseek from start of file
    mov     dx, HiScoreName
    sub     dx, 0100h
    dw 0xc933  ; TASM xor cx, cx                           ; cx:dx=hiscorename
    int     21h

    mov     ah, 40h
    mov     cx, OldInt1c-HiScoreName ; number of bytes to write
    mov     dx,  HiScoreName
    int     21h

    mov     ah, 3eh                          ; close file
    int     21h

no_hiscore:
    call    GameOverPrompt
yesno:
    call    GetKey
    cmp     al, 'n'
    je      quit
    cmp     al, 'y'
    jne     yesno
;   Play again!
    jmp restart

;   Close down
;   **********
quit:
    mov     dx, word [OldInt1c]                    ; restore old
    mov     bx, word [OldInt1c+2]                  ; interrupt 1c vector
    push    ds
    mov     ds, bx
    mov     ax, 251ch
    int     21h
    pop     ds

    mov     ax, 0003h
    int     10h
;   Enter dos
    mov ax, 0
    int 21h

jump_table:
    dw      go_rotate
    dw      inc_level
    dw      while_kbhit
    dw      go_left
    dw      while_kbhit
    dw      go_right
    dw      while_kbhit
    dw      while_kbhit
    dw      go_drop
jump_table2:
    dw      go_drop
    dw      while_kbhit
    dw      go_left
    dw      go_rotate
    dw      go_right
    dw      while_kbhit
    dw      inc_level

_NewInt1c:
    push    ax
    push    bx
    push    cx
    push    dx
    push    di
    push    si
    push    bp
    push    ds
    push    es

    mov     bp, cs
    mov     ds, bp
    pushf
    call    far [OldInt1c]

    inc     word [RandSeed]
    cmp     word [Timer], 0
    je      short $pause
    cmp     byte [Paused], 0
    je      short pause_ok
    call    RemovePause
    mov     byte [Paused], 0
pause_ok:
    dec     word [Timer]
    dec     word [LevelWait]
    jne     short return
    mov     word [LevelWait], LEVEL_WAIT_INIT
    cmp     word [TimerInit], 0
    je      short return
    dec     word [TimerInit]
    inc     word [Level]
    dw 0xd233  ; TASM xor dx, dx
    mov     ax, word [Level]
    mov     di, LEVEL_POS
    call    PrintLong
    jmp     return
$pause:
    cmp     byte [Paused], 0
    jne     short return
    call    PrintPause
    mov     byte [Paused], 1
return:
    pop     es
    pop     ds
    pop     bp
    pop     si
    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax

    iret

Move:                  ; si=dPos
    push    si

    dw 0xf633  ; TASM xor si, si
    mov     ax, word [Item]
    add     ax, word [Rotated]
    mov     di, word [Pos]
    call    Print              ; remove old

    mov     ax, word [Item]
    add     ax, word [Rotated]
    mov     di, word [Pos]
    pop     si
    dw 0xfe03  ; TASM add di, si
    push    si
    call    TestSpace              ; test if room
    pop     si
    push    ax
    dw 0xc00b  ; TASM or ax, ax
    je      short no_room
    add     word [Pos], si             ; ok, add Pos
no_room:
    push    si
    mov     si, 1
    mov     ax, word [Item]
    add     ax, word [Rotated]
    mov     di, word [Pos]
    call    Print
    pop     si
    pop     ax
    ret

Rotate:
    push    si
    dw 0xf633  ; TASM xor si, si
    mov     ax, word [Item]
    add     ax, word [Rotated]
    mov     di, word [Pos]
    call    Print

    mov     ax, word [Rotated]
    inc     ax
    mov     bx, 4
    cwd
    idiv    bx
    mov     ax, word [Item]
    dw 0xc203  ; TASM add ax, dx
    mov     di, word [Pos]
    call    TestSpace
    dw 0xc00b  ; TASM or ax, ax
    je      short no_room1
    mov     ax, word [Rotated]
    inc     ax
    mov     bx, 4
    cwd
    idiv    bx
    mov     word [Rotated], dx
no_room1:

    mov     si, 1
    mov     ax, word [Item]
    add     ax, word [Rotated]
    mov     di, word [Pos]
    call    Print
    pop     si
    ret

Down:
    push    si
    mov     si, 80
    call    Move

    dw 0xc00b  ; TASM or ax, ax                       ; room?
    je      get_new                         ; no
    pop     si
    ret
get_new:
    mov     ax, word [Item]
    add     ax, word [Rotated]
    mov     di, word [Pos]
    call    Bottom         ; reached the bottom

    call    Rand7          ; get new item
    shl     ax, 1
    shl     ax, 1
    mov     word [Item], ax
    mov     word [Pos], START_POS
    mov     word [Rotated], 0

;   Calculate score
    mov     ax, word [Drops]
    shr     ax, 1
    add     ax, strict word 2
    sub     ax, [PreView]
    mov     dx, word [Level]
    mul     dx
    add     [Score], ax
    adc     [Score+2], dx
    mov     di, SCORE_POS
    mov     ax, [Score]
    mov     dx, [Score+2]
    call    PrintLong
    mov     word [Drops], 0

;   Test if new tetris can be printed
    mov     ax, word [Item]
    add     ax, word [Rotated]
    mov     di, word [Pos]
    call    TestSpace
    dw 0xc00b  ; TASM or ax, ax
    jne     place_new

;   There was no room. Return false!
    pop     si
    ret

;   There was room. Print tetris.
place_new:
    mov     si, 1
    mov     ax, word [Item]
    add     ax, word [Rotated]
    mov     di, word [Pos]
    call    Print
    mov     ax, word [TimerInit]
    mov     word [Timer], ax

;   Display preview tetris
    cmp     word [PreView], 0
    je      short no_preview
    call    RemovePreView
    call    PrintPreView
;   Return true.
no_preview:
    mov     ax, 1
    pop     si
    ret

Drop:
    push    si
    mov     si, 80
drop_more:
    call    Move
    inc     word [Drops]
    dw 0xc00b  ; TASM or ax, ax
    jne     drop_more

    call    Down
    pop     si
    ret

PrintPreView:
    mov     si, 1
    mov     ax, [OldRand]
    shl     ax, 1
    shl     ax, 1
    mov     [PreItem], ax
    mov     di, PREVIEW_POS
    call    Print
    ret

RemovePreView:
    dw 0xf633  ; TASM xor si, si
    mov     ax, [PreItem]
    mov     di, PREVIEW_POS
    call    Print
    ret


GetKey:
    mov      ah, 07h
    mov      dl, 0ffh
    int      21h
    ret

RandInit:
    dw 0xec8b  ; TASM mov bp, sp
    sub     sp, 4
    mov      ah, 02h
    int      1ah
    mov      [bp-2], cl
    mov      [bp-4], dh
    mov     ax, word [bp-2]
    imul    word [bp-4]
    mov     word [RandSeed], ax
    dw 0xe58b  ; TASM mov sp, bp
    call    Rand7
    ret

Rand7:
    mov     ax, word [RandSeed]
    imul    word [RandSeed]

    test    ax, 1
    je      short even_number
    add     ax, 3172
    mov     word [RandSeed], ax
    jmp     short skip_even
even_number:
    shl     ax, 1
    add     ax, [Score]
skip_even:
    mov     word [RandSeed], ax
    mov     bx, 7
    dw 0xd233  ; TASM xor dx, dx
    div     bx
    mov     ax, word [OldRand]
    mov     word [OldRand], dx
    ret

    db 0  ; TASM has added an alignment byte because of a new source file start.

InitScreen:
    mov ax, 0001h                        ; Screen mode 1
    int  10h

    dw 0xff33  ; TASM xor di, di
    mov     ax, 0b800h
    mov     es, ax
    mov     cx, 1000
    dw 0xc033  ; TASM xor ax, ax
    rep     stosw                               ; Fill screen with 0

    mov     ax, BORDER_CHAR+256*BORDER_COLOR     ; Horisontal lines
    mov     di, 28
    mov     cx, 12
    rep stosw                                   ; Upper
    mov     di, 28+24*80
    mov     cx, 12
    rep stosw                                   ; Lower

    mov     cx, 23
    mov     ax, BORDER_CHAR+256*BORDER_COLOR     ; Vertical lines
    mov     di, 80+28
loop_s1:
    mov     [es:di], ax
    add     di, 22
    mov     [es:di], ax
    add     di, 58
    loop    loop_s1


    push        es
    push        ds
    pop     es
    mov     cx, 25
    mov     di, RowFill
    mov     ax, 0
    rep stosb                                   ; Clear buffer
    pop     es

;   Print text
    mov     di, LOGO_POS
    mov     si, TetrisLogo
    call    PrintColorString
    mov     di, BY_POS
    call    PrintColorString
    mov     di, TORE_POS
    call    PrintColorString
    mov     di, BAST_POS
    call    PrintColorString
    mov     ah, 1
    mov     di, HISCORE_TEXT_POS
    call    PrintMonoString
    mov     di, SCORE_TEXT_POS
    call    PrintMonoString
    mov     di, LEVEL_TEXT_POS
    call    PrintMonoString
    mov     di, PREVIEW_TEXT_POS
    call    PrintMonoString
    ret

DeleteRow:                ;bx=Row

    mov     dx, 0b800h
    mov     es, dx

    dec     bx
    dw 0xcb8b  ; TASM mov cx, bx
    dw 0xc38b  ; TASM mov ax, bx

    mov     dx, 80
    imul    dx
    add     ax, strict word 30               ; ax=source offset

    dw 0xf08b  ; TASM mov si, ax
loop_d1:
    dw 0xfe8b  ; TASM mov di, si
    add     di, 80
    push    cx
    mov     cx, 10
    push    ds
    push    es
    pop     ds
    rep movsw
    pop     ds
    sub     si, 100

    mov     cl, byte [RowFill+bx]
    mov     byte [RowFill+1+bx], cl
    dec     bx

    pop     cx
    loop    loop_d1

    ret

Bottom:        ;ax=ItemNr          di=scroffset
    mov     dx, 0b800h
    mov     es, dx
    mov     dx, 06

    imul    dx
    add     ax, Items                       ; ax=ax*6

    dw 0xc933  ; TASM xor cx, cx                           ; for cx=0 to 3
loop_b1:
    dw 0xd88b  ; TASM mov bx, ax
    dw 0xd903  ; TASM add bx, cx
    push    ax
    mov     al, byte [bx+2]
    cbw
    shl     ax, 1
    dw 0xf803  ; TASM add di, ax
    dw 0xc78b  ; TASM mov ax, di
    dw 0xd233  ; TASM xor dx, dx
    mov     bx, 80
    div     bx
    dw 0xd88b  ; TASM mov bx, ax
    inc     byte [RowFill+bx]
    pop     ax
    inc     cx
    cmp     cx, 4
    jne     loop_b1

    dw 0xdb33  ; TASM xor bx, bx
loop_b2:
    cmp     byte [RowFill+bx], 10
    jne     not_full
    push    bx
    call    DeleteRow
    inc     word [RandSeed]
    pop     bx
not_full:
    inc     bx
    cmp     bx, 24
    jne     loop_b2

    ret

TestSpace:        ;ax= item_nr    di=scroffs
    mov     dx, 0b800h
    mov     es, dx
    mov     dx, 06
    imul    dx
    add     ax, Items                       ; ax=ax*6

    dw 0xd233  ; TASM xor dx, dx                           ; for dx=0 to 3
loop1:
    dw 0xd88b  ; TASM mov bx, ax
    dw 0xda03  ; TASM add bx, dx
    push    ax
    mov     al, byte [bx+2]
    cbw
    shl     ax, 1
    dw 0xf803  ; TASM add di, ax
    pop     ax
    cmp     word [es:di], 0
    jne     bad
    inc     dx
    cmp     dx, 4
    jne     loop1
    mov     ax, 01
    ret
bad:
    dw 0xc033  ; TASM xor ax, ax
    ret

Print:                    ;ax= item_nr    di=scroffs si=T/F
    mov     dx, 0b800h
    mov     es, dx
    mov     dx, 06
    imul    dx                          ; ax=ax*6
    add     ax, Items                   ; ax+=[_items]

    dw 0xd233  ; TASM xor dx, dx                       ; for dx=3 to 0

    cmp     si, 0
    je      loop2
    dw 0xd88b  ; TASM mov bx, ax
    mov     si, [bx]
loop2:
    dw 0xd88b  ; TASM mov bx, ax
    dw 0xda03  ; TASM add bx, dx
    push    ax
    mov     al, byte [bx+2]
    cbw
    shl     ax, 1
    dw 0xf803  ; TASM add di, ax
    pop     ax
    mov     [es:di], si
    inc     dx
    cmp     dx, 4
    jne     loop2
    ret

PrintLong:

    mov     bx, 0b800h
    mov     es, bx

    mov     bx, 10
more_digits:
    div     bx
    add     dx, '0'+256*7
    mov     [es:di], dx
    sub     di, 2
    mov     dx, 0
    cmp     ax, strict word 0
    jne     short more_digits
    ret

PrintColorString:
    mov     bx, 0b800h
    mov     es, bx
color_loop:
    mov     ax, [si]
    inc     si
    inc     si
    dw 0xc023  ; TASM and ax, ax
    jz      color_done
    mov     [es:di], ax
    inc     di
    inc     di
    jmp     color_loop
color_done:
    ret

PrintMonoString:
    mov     bx, 0b800h
    mov     es, bx
mono_loop:
    mov     al, [si]
    inc     si
    dw 0xc022  ; TASM and al, al
    jz      mono_done
    mov     [es:di], ax
    inc     di
    inc     di
    jmp     mono_loop
mono_done:
    ret

GameOverPrompt:
    mov     ah, 1
    mov     di, GAME_OVER_POS
    mov     si, GameOverText
    call    PrintMonoString
    mov     di, PLAY_AGAIN_POS
    call    PrintMonoString
    ret

RemovePause:
    dw 0xe432  ; TASM xor ah, ah
    mov     di, PAUSE_POS
    mov     si, RemovePauseText
    call    PrintMonoString
    ret

PrintPause:
    mov     ah, 1
    mov     di, PAUSE_POS
    mov     si, PauseText
    call    PrintMonoString
    ret

Timer       dw  0
LevelWait   dw  LEVEL_WAIT_INIT
Level       dw  1
StartLevel  dw  0
Pos         dw  START_POS
Item        dw  0
Rotated     dw  0
Drops       dw  0
RandSeed    dw  0
PreView     dw  0
Paused      db  0
ErrorText   db  'Bad arguments', 10, '$'
EnterName   db  'Enter name:', 10, 13, '$'
HiScoreData db  14, 0
;HiScoreName times 15 db '$'
HiScoreName db 'Siv M. ', 8fh, 'sen', 13, 13, '$$'
;HiScore     dd  0
HiScore     dd  9c3ch

; These could be in .bss (`absolute $').
OldInt1c 	dd 0
Score		dw 0, 0
OldRand		dw 0
PreItem		dw 0
TimerInit	dw 0

    db 0  ; TASM has added an alignment byte because of a new source file start.

BLOCK   equ     254

COLOR1  equ     65
COLOR2  equ     36
COLOR3  equ     23
COLOR4  equ     19
COLOR5  equ     45
COLOR6  equ     78
COLOR7  equ     124

Items:
    db  BLOCK,  COLOR1, 176,  40,  40,  40
    db  BLOCK,  COLOR1, 214,   1,   1,   1
    db  BLOCK,  COLOR1, 176,  40,  40,  40
    db  BLOCK,  COLOR1, 214,   1,   1,   1

    db  BLOCK,  COLOR2, 215,  40,  40,   1
    db  BLOCK,  COLOR2, 217,  38,   1,   1
    db  BLOCK,  COLOR2, 215,   1,  40,  40
    db  BLOCK,  COLOR2, 215,   1,   1,  38

    db  BLOCK,  COLOR3, 217,  40,  39,   1
    db  BLOCK,  COLOR3, 215,   1,   1,  40
    db  BLOCK,  COLOR3, 215,   1,  39,  40
    db  BLOCK,  COLOR3, 255,  40,   1,   1

    db  BLOCK,  COLOR4, 215,   1,   1,  39
    db  BLOCK,  COLOR4, 215,  40,   1,  39
    db  BLOCK,  COLOR4, 216,  39,   1,   1
    db  BLOCK,  COLOR4, 216,  39,   1,  40

    db  BLOCK,  COLOR5, 215,   1,  39,   1
    db  BLOCK,  COLOR5, 215,   1,  39,   1
    db  BLOCK,  COLOR5, 215,   1,  39,   1
    db  BLOCK,  COLOR5, 215,   1,  39,   1

    db  BLOCK,  COLOR6, 215,   1,  40,   1
    db  BLOCK,  COLOR6, 216,  39,   1,  39
    db  BLOCK,  COLOR6, 215,   1,  40,   1
    db  BLOCK,  COLOR6, 216,  39,   1,  39

    db  BLOCK,  COLOR7, 216,   1,  38,   1
    db  BLOCK,  COLOR7, 216,  40,   1,  40
    db  BLOCK,  COLOR7, 216,   1,  38,   1
    db  BLOCK,  COLOR7, 216,  40,   1,  40

BORDER_CHAR         equ     32
BORDER_COLOR        equ     29

HISCORE_TEXT_POS    equ     0
SCORE_TEXT_POS      equ     240
LEVEL_TEXT_POS      equ     400
LOGO_POS            equ     800
BY_POS              equ     970
TORE_POS            equ     1128
BAST_POS            equ     1202
PREVIEW_TEXT_POS    equ     134
GAME_OVER_POS       equ     934
PLAY_AGAIN_POS      equ     1654
PAUSE_POS           equ     934

TetrisLogo:
    db  'S', 1
    db  'm', 2
    db  'a', 3
    db  'l', 4
    db  'l', 5
    db  'T', 6
    db  'e', 7
    db  't', 8
    db  'r', 9
    db  'i', 10
    db  's', 11
    dw  0

    db  'b', 7
    db  'y', 7
    dw  0

    db  'T', 1
    db  'o', 2
    db  'r', 3
    db  'e', 4
    dw  0
    db  'B', 6
    db  'a', 7
    db  's', 8
    db  't', 9
    db  'i', 10
    db  'a', 11
    db  'n', 12
    db  's', 13
    db  'e', 14
    db  'n', 15
    dw  0

    db  'HISCORE:', 0
    db  'SCORE:', 0
    db  'LEVEL:', 0
    db  'Preview:', 0

GameOverText:
    db  'GAME OVER', 0
    db  'Play again?', 0
RemovePauseText:
    times 5 db ' '
    db  0
PauseText db    'PAUSE', 0

absolute $
RowFill     resb 25
