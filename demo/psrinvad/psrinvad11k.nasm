;
; psrinvad.nasm: port of the Space Invaders game to mininasm
; ported by pts@fazekas.hu at Wed Dec 21 23:07:44 CET 2022
;
; The version 1.1k was ported:
;
; * https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/repositories/1.3/games/psrinvad/1_1k.zip
; * https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/repositories/1.3/games/psrinvad.zip
;
; Project repository: http://gitlab.com/FDOS/games/psrinvad
;
; FreeDOS package entry:
; https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/repositories/1.3/pkg-html/psrinvad.1_1k.html
;
; Compile: nasm -O9 -f bin -o psrinvad.com psrinvad11k.nasm
; Minimum NASM version: 0.98.39.
;
; Compile: mininasm -O9 -f bin -o psrinvad.com psrinvad11k.nasm
;
; The generated program file psrinvad.com is identical to the official
; invaders.com.
;
; Please note that the original psrinvad.zip contails scripted ports to many
; assemblers (including NASM but excluding mininasm).
;

;-------------------------------;
; 9k Space Invaders Version 1.1 ;
;                               ;
; Copyright (c) by Paul S. Reid ;
;      All rights reserved.     ;
;-------------------------------;

                        ORG     100h

;----------------------------------------------------------------------------------------------------------------------------------
; 6k Space Invaders
;----------------------------------------------------------------------------------------------------------------------------------

Start:

                        MOV     AH,0
                        MOV     AL,13h
                        INT     10h

                        CALL    InstallNewInt9          ; Install game keyboard handler
; Seed random number generator with clock
                        MOV     AX,040h
                        MOV     ES,AX
                        MOV     AX,[ES:06ch]
                        MOV     word[Seed],AX
; Set color palette
                        MOV     AX,CS                   ; Segment of palette buffer
                        MOV     ES,AX                   ; in ES
                        MOV     DX,Palette              ; Offset of palette buffer in DX
                        MOV     AH,10h                  ; Function 10h (Get/set palette registers)
                        MOV     AL,12h                  ; Subfunction 12h (Set block of color registers)
                        MOV     BX,00h                  ; First color register to set
                        MOV     CX,05bh                 ; Number of color registers to set (255 = all of them)
                        INT     10h                     ; Set registers
; Draw top and bottom borders
                        MOV     AX,0a000h       ; Get segment of video memory
                        MOV     ES,AX           ; Store it in destination segment register
                        MOV     DI,0            ; Store address in destination register
                        MOV     CX,10240        ; 32 lines
DrawTop:                MOV     BX,0008fh       ; Random number between 0 and 20 in AX
                        MOV     word[TempStore],CX
                        CALL    Random          ; Call random routine
                        CMP     byte[RandomNumber],1
                        JNZ     NoStar
                        MOV     AL,12
                        JMP     DrawTop2
NoStar:                 MOV     AL,8
DrawTop2:               STOSB
                        MOV     CX,word[TempStore]
                        LOOP    DrawTop
                        MOV     DI,54400        ; Store address in destination register
                        MOV     CX,9600         ; 32 lines
DrawBottom:             MOV     BX,0008fh       ; Random number between 0 and 20 in AX
                        MOV     word[TempStore],CX
                        CALL    Random          ; Call random routine
                        CMP     byte[RandomNumber],1
                        JNZ     NoStar2
                        MOV     AL,12
                        JMP     DrawBottom2
NoStar2:                MOV     AL,8
DrawBottom2:            STOSB
                        MOV     CX,word[TempStore]
                        LOOP    DrawBottom
;Draw Invaders logo
                        MOV     AX,LogoOutline      ; Get address of sprite
                        MOV     BX,74               ; Get X position to draw sprite at
                        MOV     DL,0                ; Get Y position to draw sprite at
                        MOV     DH,10               ; Get color to draw sprite
                        CALL    DrawLogoLayer       ; Draw sprite
                        MOV     AX,LogoShadow       ; Get address of sprite
                        MOV     BX,74               ; Get X position to draw sprite at
                        MOV     DL,0                ; Get Y position to draw sprite at
                        MOV     DH,9                ; Get color to draw sprite
                        CALL    DrawLogoLayer       ; Draw sprite
                        MOV     AX,LogoLetters      ; Get address of sprite
                        MOV     BX,74               ; Get X position to draw sprite at
                        MOV     DL,0                ; Get Y position to draw sprite at
                        MOV     DH,11               ; Get color to draw sprite
                        CALL    DrawLogoLayer       ; Draw sprite

                        JMP     TitleScreen
; Clear video buffer
StartGame:              CALL    ResetGame

                        MOV     AX,CS           ; Get segment of video memory
                        MOV     ES,AX           ; Store it in destination segment register
                        MOV     DI,VideoBuffer  ; Store address in destination register
                        MOV     CX,21760        ; 136 lines (160 * 136)
                        MOV     AX,0
ClearAll2:              STOSW
                        LOOP    ClearAll2

                        CALL    DisplayStatus

; Outter game loop

RedrawBunkers:          CALL    DrawBunkers
                        MOV     byte[FirstFrame],1

; Inner game loop

NoExit:                 MOV     AX,PlayersShip      ; Get address of sprite
                        MOV     BX,word[PlayerX]          ; Get X position to draw sprite at
                        MOV     DL,130              ; Get Y position to draw sprite at
                        MOV     DH,1                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite
                        CALL    CheckPlayerDead
                        MOV     AX,Score
                        MOV     word[ScoreValueOffset],AX
                        MOV     word[ScoreXOffset],67
                        CALL    DisplayScore
                        CALL    UpdateHighScore
                        MOV     AX,HighS
                        MOV     word[ScoreValueOffset],AX
                        MOV     word[ScoreXOffset],161
                        CALL    DisplayScore
; Prepare for buffer blit
                        MOV     SI,VideoBuffer
                        MOV     DI,10560        ; Store address in destination register
                        MOV     AX,0a000h       ; Get segment of video memory
                        MOV     ES,AX           ; Store it in destination segment register
                        MOV     CX,21760        ; 150 lines (136 * 150)
; Check vertical retrace
                        MOV		DX,03DAh            ; Get vertical retrace port address in DX
;RetraceStart:           IN		AL,DX               ; Grab retrace information
;                        TEST	AL,8                ; Did it start yet?
;                        JNZ		RetraceStart        ; No, wait until it does
RetraceEnd:             IN		AL,DX               ; Grab retrace information again
                        TEST	AL,8                ; Did it end yet?
                        JZ		RetraceEnd          ; No, loop until it does
; Blit buffer to video memory
BlitAll:                MOVSW
                        LOOP    BlitAll

                        CMP     byte[FirstFrame],1
                        JNZ     NoFirstFrame
                        CALL    DrawInvaders
                        MOV     AX,GetReady
                        MOV     BX,82
                        MOV     DL,20
                        MOV     DH,7
                        CALL    PrintText
                        MOV     AH,0
                        INT     01ah
                        ADD     DL,18
                        MOV     byte[PauseCounter],DL
Wait1:                  MOV     AH,0
                        INT     01ah
                        CMP     DL,byte[PauseCounter]
                        JNZ     Wait1
                        MOV     AX,GetReady
                        MOV     BX,82
                        MOV     DL,20
                        MOV     DH,0
                        CALL    PrintText
                        MOV     byte[FirstFrame],0

NoFirstFrame:           CMP     byte[SoundToggle],1
                        JNZ     NoSoundToggle
                        MOV     byte[SoundToggle],0
                        XOR     byte[Sound],080h

NoSoundToggle:          CALL    EraseInvaders
                        DEC byte[MoveCount]
                        JNZ     NoInvaderMove
                        CALL    MoveInvaders

NoInvaderMove:          CMP     byte[FireToggle],1
                        JNZ     NoFire
                        CMP     word[MissileX],0
                        JNZ     NoFire
                        CALL    ShootPlayerMissile

NoFire:                 CALL    DrawInvaders

                        CMP     word[MissileX],0
                        JZ      NoMissile
                        CALL    MovePlayerMissile

                        CMP     byte[Collision],0
                        JZ      NoMissile
                        CALL    EraseInvaders
                        MOV     AX,Score
                        MOV     word[ScoreValueOffset],AX
                        MOV     word[ScoreXOffset],67
                        CALL    EraseScore
                        MOV     AX,HighS
                        MOV     word[ScoreValueOffset],AX
                        MOV     word[ScoreXOffset],161
                        CALL    EraseScore
                        CALL    CheckInvaderKill
                        CALL    DrawInvaders
                        MOV     byte[Collision],0     ; Reset collision flag

NoMissile:              CMP     byte[NextLevelToggle],0
                        JZ      NoNextLevel
                        CALL    NextLevel
                        JMP     RedrawBunkers

NoNextLevel:            CMP     byte[PlayerDead],0
                        JZ      NoPlayerDead
                        JMP     KillPlayer

NoPlayerDead:           MOV     BX,0ffffh       ; Random number between 0 and 20 in AX
                        CALL    Random          ; Call random routine
                        CMP     byte[RandomNumber],1
                        JNZ     NoMakeUFO
                        CMP     word[UFOX],0
                        JNZ     NoMakeUFO
                        DEC byte[UFOCounter]
                        CMP     byte[UFOCounter],0
                        JNZ     NoMakeUFO
                        MOV     byte[UFOCounter],6
                        MOV     word[UFOX],50

NoMakeUFO:              CMP     word[UFOX],0
                        JZ      NoUFO
                        CALL    MoveUFO

NoUFO:                  MOV     BX,word[BombFreq]     ; Random number between 0 and 20 in AX
                        CALL    Random          ; Call random routine
                        CMP     byte[RandomNumber],1
                        JNZ     NoInvaderBomb
                        CALL    InvaderBomb

NoInvaderBomb:          DEC byte[BombMove]
                        CMP     byte[BombMove],0
                        JNZ     NoMoveBombs
                        MOV     AL,byte[BombSpeed]
                        MOV     byte[BombMove],AL
                        CALL    MoveBombs

NoMoveBombs:            MOV     AX,PlayersShip      ; Get address of sprite
                        MOV     BX,word[PlayerX]          ; Get X position to draw sprite at
                        MOV     DL,130              ; Get Y position to draw sprite at
                        CALL    EraseSprite         ; Draw sprite

                        CMP     byte[LeftToggle],1
                        JNZ     NoLeft
                        CALL    MovePlayerLeft

NoLeft:                 CMP     byte[RightToggle],1
                        JNZ     NoRight
                        CALL    MovePlayerRight

NoRight:                CMP     byte[ExitToggle],1
                        JZ      Exit
                        JMP     NoExit

; Clean up and exit

Exit:                   CALL    RemoveNewInt9

                        MOV     AH,0
                        MOV     AL,3
                        INT     10h

                        MOV     AH,4Ch          ; Exit function
                        INT     21h             ; Call DOS for exit


;----------------------------------------------------------------------------------------------------------------------------------
; Update High Score
;----------------------------------------------------------------------------------------------------------------------------------

UpdateHighScore:

                        MOV     AL,byte[Score]
                        CMP     AL,byte[HighS]
                        JZ      NextDigit1
                        JA      Update
                        JMP     NoUpdate
NextDigit1:             MOV     AL,byte[Score+1]
                        CMP     AL,byte[HighS+1]
                        JZ      NextDigit2
                        JA      Update
                        JMP     NoUpdate
NextDigit2:             MOV     AL,byte[Score+2]
                        CMP     AL,byte[HighS+2]
                        JZ      NextDigit3
                        JA      Update
                        JMP     NoUpdate
NextDigit3:             MOV     AL,byte[Score+3]
                        CMP     AL,byte[HighS+3]
                        JZ      NextDigit4
                        JA      Update
                        JMP     NoUpdate
NextDigit4:             MOV     AL,byte[Score+4]
                        CMP     AL,byte[HighS+4]
                        JA      Update
                        JMP     NoUpdate

Update:                 MOV     AL,byte[Score]
                        MOV     byte[HighS],AL
                        MOV     AL,byte[Score+1]
                        MOV     byte[HighS+1],AL
                        MOV     AL,byte[Score+2]
                        MOV     byte[HighS+2],AL
                        MOV     AL,byte[Score+3]
                        MOV     byte[HighS+3],AL
                        MOV     AL,byte[Score+4]
                        MOV     byte[HighS+4],AL

NoUpdate:               RET


;----------------------------------------------------------------------------------------------------------------------------------
; Display Status
;----------------------------------------------------------------------------------------------------------------------------------

DisplayStatus:

; Display "SCORE"
                        MOV     AX,SCO              ; Get address of sprite
                        MOV     BX,30               ; Get X position to draw sprite at
                        MOV     DL,0                ; Get Y position to draw sprite at
                        MOV     DH,5                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite
                        MOV     AX,ORE              ; Get address of sprite
                        MOV     BX,46               ; Get X position to draw sprite at
                        MOV     DL,0                ; Get Y position to draw sprite at
                        MOV     DH,5                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite
                        MOV     AX,Score
                        MOV     word[ScoreValueOffset],AX
                        MOV     word[ScoreXOffset],67
                        CALL    DisplayScore
; Display "HIGH"
                        MOV     AX,HIG              ; Get address of sprite
                        MOV     BX,130              ; Get X position to draw sprite at
                        MOV     DL,0                ; Get Y position to draw sprite at
                        MOV     DH,5                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite
                        MOV     AX,GH               ; Get address of sprite
                        MOV     BX,146              ; Get X position to draw sprite at
                        MOV     DL,0                ; Get Y position to draw sprite at
                        MOV     DH,5                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite
                        MOV     AX,HighS
                        MOV     word[ScoreValueOffset],AX
                        MOV     word[ScoreXOffset],161
                        CALL    DisplayScore
; Display lives
                        MOV     AX,PlayersShip      ; Get address of sprite
                        MOV     BX,266              ; Get X position to draw sprite at
                        MOV     DL,0                ; Get Y position to draw sprite at
                        MOV     DH,5                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite
                        MOV     AX,Equal            ; Get address of sprite
                        MOV     BX,278              ; Get X position to draw sprite at
                        MOV     DL,0                ; Get Y position to draw sprite at
                        MOV     DH,5                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite
                        MOV     AL,byte[Lives]
                        MOV     BX,285
                        MOV     DL,0
                        MOV     DH,5
                        CALL    DisplayDigit

                        RET


;----------------------------------------------------------------------------------------------------------------------------------
; Reset Game
;----------------------------------------------------------------------------------------------------------------------------------

ResetGame:

                        MOV     byte[Frame],0

                        MOV     word[InvadersX],275
                        MOV     byte[InvadersY],30
                        MOV     word[InvadersToggle],07ff0h
                        MOV     word[InvadersToggle+2],07ff0h
                        MOV     word[InvadersToggle+4],07ff0h
                        MOV     word[InvadersToggle+6],07ff0h
                        MOV     word[InvadersToggle+8],07ff0h
                        MOV     word[PlayerX],154
                        MOV     byte[LeftToggle],0
                        MOV     byte[RightToggle],0
                        MOV     byte[FireToggle],0
                        MOV     byte[ExitToggle],0
                        MOV     byte[NextLevelToggle],0
                        MOV     word[MissileX],0
                        MOV     byte[MissileY],0
                        MOV     word[UFOX],0
                        MOV     AX,CS           ; Get segment of video memory
                        MOV     ES,AX           ; Store it in destination segment register
                        MOV     DI,BombX
                        MOV     CX,22
                        MOV     AX,0
ClearLoop1:             STOSW
                        LOOP    ClearLoop1
                        MOV     DI,BombY
                        MOV     CX,22
ClearLoop2:             STOSB
                        LOOP    ClearLoop2
                        MOV     DI,BombType
                        MOV     CX,22
ClearLoop3:             STOSB
                        LOOP    ClearLoop3
                        MOV     word[BombFreq],010h
                        MOV     byte[MoveCount],1
                        MOV     byte[InvaderSpeed],55
                        MOV     byte[Direction],0
                        MOV     byte[Reversing],0
                        MOV     byte[Collision],0
                        MOV     byte[Score],48
                        MOV     byte[Score+1],48
                        MOV     byte[Score+2],48
                        MOV     byte[Score+3],48
                        MOV     byte[Score+4],48
                        MOV     byte[Lives],51
                        MOV     byte[BombMove],2
                        MOV     byte[BombSpeed],2
                        MOV     byte[PlayerDead],0
                        MOV     byte[GameOverToggle],0
                        MOV     byte[CurrentInvaderSpeed],55
                        MOV     byte[CurrentInvaderY],30
                        MOV     word[CurrentBombFreq],010h

                        RET


;----------------------------------------------------------------------------------------------------------------------------------
; Print Text
;----------------------------------------------------------------------------------------------------------------------------------

PrintText:

                        MOV     word[LetterCounter],AX
                        MOV     word[LetterXPos],BX
                        MOV     byte[LetterYPos],DL
                        MOV     byte[LetterColor],DH
                        SUB     word[LetterXPos],6

                        CMP     byte[KeyPress],1
                        JNZ     PrintNext

                        MOV     byte[KeyPress],0

                        CMP     byte[ExitToggle],1
                        JNZ     NotExit2
                        JMP     Exit

NotExit2:               CMP     byte[SoundToggle],1
                        JNZ     NotSound
                        MOV     byte[SoundToggle],0
                        XOR     byte[Sound],080h
                        JMP     PrintNext

NotSound:               CMP     byte[GameStart],1
                        JNZ     PrintNext
                        MOV     byte[GameStart],0
                        JMP     StartGame

PrintNext:              MOV     SI,word[LetterCounter]
                        LODSB
                        INC word[LetterCounter]
                        ADD     word[LetterXPos],6
                        CMP     AL,0
                        JZ      DonePrinting
                        CMP     AL,32
                        JZ      PrintNext
                        MOV     BX,word[LetterXPos]
                        MOV     DL,byte[LetterYPos]
                        MOV     DH,byte[LetterColor]
                        CALL    DisplayDigit
                        MOV     SI,VideoBuffer
                        MOV     DI,10560        ; Store address in destination register
                        MOV     AX,0a000h       ; Get segment of video memory
                        MOV     ES,AX           ; Store it in destination segment register
                        MOV     CX,21760        ; 150 lines (136 * 150)
                        MOV		DX,03DAh        ; Get vertical retrace port address in DX
RetraceEnd3:            IN		AL,DX           ; Grab retrace information again
                        TEST	AL,8            ; Did it end yet?
                        JZ		RetraceEnd3     ; No, loop until it does
BlitAll3:               MOVSW
                        LOOP    BlitAll3
                        JMP     PrintNext

DonePrinting:           RET

LetterCounter           DW      0
LetterXPos              DW      0
LetterYPos              DB      0
LetterColor             DB      0


;----------------------------------------------------------------------------------------------------------------------------------
; Title Screen - Never Returns!
;----------------------------------------------------------------------------------------------------------------------------------

TitleScreen:

; Clear video buffer
                        MOV     AX,CS           ; Get segment of video memory
                        MOV     ES,AX           ; Store it in destination segment register
                        MOV     DI,VideoBuffer  ; Store address in destination register
                        MOV     CX,21760        ; 136 lines (160 * 136)
                        MOV     AX,0
ClearAll:               STOSW
                        LOOP    ClearAll

                        MOV     byte[KeyPress],0
                        MOV     byte[GameStart],1

                        CALL    DisplayStatus

                        MOV     AX,InvadersTitle
                        MOV     BX,40
                        MOV     DL,20
                        MOV     DH,7
                        CALL    PrintText

                        MOV     AX,Copyright
                        MOV     BX,0
                        MOV     DL,30
                        MOV     DH,030h
                        CALL    PrintText

                        MOV     AX,UFO              ; Get address of sprite
                        MOV     DL,50               ; Get Y position to draw sprite at
                        MOV     DH,3                ; Get color to draw sprite
                        MOV     BX,100              ; Get X position to draw sprite at
                        CALL    DrawLetter          ; Draw sprite
                        MOV     AX,UFOScore
                        MOV     BX,137
                        MOV     DL,50
                        MOV     DH,7
                        CALL    PrintText

                        MOV     AX,TopInvader1      ; Get address of sprite
                        MOV     DL,60               ; Get Y position to draw sprite at
                        MOV     DH,010h             ; Get color to draw sprite
                        MOV     BX,103              ; Get X position to draw sprite at
                        CALL    DrawLetter          ; Draw sprite
                        MOV     AX,Row1Score
                        MOV     BX,137
                        MOV     DL,60
                        MOV     DH,7
                        CALL    PrintText

                        MOV     AX,MiddleInvader2   ; Get address of sprite
                        MOV     DL,70               ; Get Y position to draw sprite at
                        MOV     DH,020h             ; Get color to draw sprite
                        MOV     BX,103              ; Get X position to draw sprite at
                        CALL    DrawLetter          ; Draw sprite
                        MOV     AX,Row2Score
                        MOV     BX,137
                        MOV     DL,70
                        MOV     DH,7
                        CALL    PrintText

                        MOV     AX,MiddleInvader1   ; Get address of sprite
                        MOV     DL,80               ; Get Y position to draw sprite at
                        MOV     DH,030h             ; Get color to draw sprite
                        MOV     BX,103              ; Get X position to draw sprite at
                        CALL    DrawLetter          ; Draw sprite
                        MOV     AX,Row3Score
                        MOV     BX,137
                        MOV     DL,80
                        MOV     DH,7
                        CALL    PrintText

                        MOV     AX,BottomInvader1   ; Get address of sprite
                        MOV     DL,90               ; Get Y position to draw sprite at
                        MOV     DH,040h             ; Get color to draw sprite
                        MOV     BX,103              ; Get X position to draw sprite at
                        CALL    DrawLetter          ; Draw sprite
                        MOV     AX,Row4Score
                        MOV     BX,137
                        MOV     DL,90
                        MOV     DH,7
                        CALL    PrintText

                        MOV     AX,BottomInvader1   ; Get address of sprite
                        MOV     DL,100              ; Get Y position to draw sprite at
                        MOV     DH,050h             ; Get color to draw sprite
                        MOV     BX,103              ; Get X position to draw sprite at
                        CALL    DrawLetter          ; Draw sprite
                        MOV     AX,Row5Score
                        MOV     BX,137
                        MOV     DL,100
                        MOV     DH,7
                        CALL    PrintText

                        MOV     AX,StartDocs
                        MOV     BX,0
                        MOV     DL,119
                        MOV     DH,050h
                        CALL    PrintText

                        MOV     AX,Distribution
                        MOV     BX,4
                        MOV     DL,129
                        MOV     DH,7
                        CALL    PrintText

                        MOV     byte[GameStart],0

                        MOV     AH,0
                        INT     01ah
                        INC     DH
                        MOV     byte[PauseCounter],DH

GetKey:                 CMP     byte[KeyPress],1
                        JZ      KeyWasPressed

                        MOV     AH,0
                        INT     01ah
                        CMP     DH,byte[PauseCounter]
                        JNZ     GetKey
                        JMP     TitleScreen2

KeyWasPressed:          CMP     byte[ExitToggle],1
                        JNZ     NotExit
                        JMP     Exit

NotExit:                CMP     byte[SoundToggle],1
                        JNZ     NotSound2
                        MOV     byte[SoundToggle],0
                        XOR     byte[Sound],080h
                        JMP     GetKey

NotSound2:              JMP     StartGame


;----------------------------------------------------------------------------------------------------------------------------------
; Title Screen 2 - Never Returns!
;----------------------------------------------------------------------------------------------------------------------------------

TitleScreen2:

; Clear video buffer
                        MOV     AX,CS           ; Get segment of video memory
                        MOV     ES,AX           ; Store it in destination segment register
                        MOV     DI,VideoBuffer  ; Store address in destination register
                        MOV     CX,21760        ; 136 lines (160 * 136)
                        MOV     AX,0
ClearAllZ:              STOSW
                        LOOP    ClearAllZ

                        MOV     byte[KeyPress],0
                        MOV     byte[GameStart],1

                        CALL    DisplayStatus

                        MOV     AX,InvadersTitle
                        MOV     BX,40
                        MOV     DL,20
                        MOV     DH,7
                        CALL    PrintText

                        MOV     AX,Copyright
                        MOV     BX,0
                        MOV     DL,30
                        MOV     DH,030h
                        CALL    PrintText

                        MOV     AX,Dedication
                        MOV     BX,70
                        MOV     DL,50
                        MOV     DH,010h
                        CALL    PrintText

                        MOV     AX,ThankYou
                        MOV     BX,64
                        MOV     DL,70
                        MOV     DH,010h
                        CALL    PrintText

                        MOV     AX,SoundTog
                        MOV     BX,55
                        MOV     DL,90
                        MOV     DH,7
                        CALL    PrintText

                        MOV     AX,PlayKeys
                        MOV     BX,31
                        MOV     DL,100
                        MOV     DH,7
                        CALL    PrintText

                        MOV     AX,StartDocs
                        MOV     BX,0
                        MOV     DL,119
                        MOV     DH,050h
                        CALL    PrintText

                        MOV     AX,Distribution
                        MOV     BX,4
                        MOV     DL,129
                        MOV     DH,7
                        CALL    PrintText

                        MOV     byte[GameStart],0

                        MOV     AH,0
                        INT     01ah
                        INC     DH
                        MOV     byte[PauseCounter],DH

GetKey2:                CMP     byte[KeyPress],1
                        JZ      KeyWasPressed2

                        MOV     AH,0
                        INT     01ah
                        CMP     DH,byte[PauseCounter]
                        JNZ     GetKey2
                        JMP     TitleScreen

KeyWasPressed2:         CMP     byte[ExitToggle],1
                        JNZ     NotExitZ
                        JMP     Exit

NotExitZ:               CMP     byte[SoundToggle],1
                        JNZ     NotSound3
                        MOV     byte[SoundToggle],0
                        XOR     byte[Sound],080h
                        JMP     GetKey2

NotSound3:              JMP     StartGame


; Draw Letter with pause

DrawLetter:

                        CALL    DrawSprite      ; Draw sprite
; Prepare for buffer blit
                        MOV     SI,VideoBuffer
                        MOV     DI,10560        ; Store address in destination register
                        MOV     AX,0a000h       ; Get segment of video memory
                        MOV     ES,AX           ; Store it in destination segment register
                        MOV     CX,21760        ; 150 lines (136 * 150)
; Check vertical retrace
                        MOV		DX,03DAh        ; Get vertical retrace port address in DX
RetraceEnd2:            IN		AL,DX           ; Grab retrace information again
                        TEST	AL,8            ; Did it end yet?
                        JZ		RetraceEnd2     ; No, loop until it does
; Blit buffer to video memory
BlitAll2:               MOVSW
                        LOOP    BlitAll2

NoKey:                  MOV     AH,0
                        INT     01ah
                        ADD     DL,3
                        MOV     byte[PauseCounter],DL
Wait2:                  MOV     AH,0
                        INT     01ah
                        CMP     DL,byte[PauseCounter]
                        JNZ     Wait2

                        RET


;----------------------------------------------------------------------------------------------------------------------------------
; Game Over - Never Returns!
;----------------------------------------------------------------------------------------------------------------------------------

GameOver:

                        MOV     byte[GameOverToggle],1

                        MOV     AX,GameOverMsg
                        MOV     BX,82
                        MOV     DL,20
                        MOV     DH,7
                        CALL    PrintText

                        MOV     byte[GameOverToggle],0
                        MOV     AH,0
                        INT     01ah
                        ADD     DL,180
                        MOV     byte[PauseCounter],DL
Wait3:                  MOV     AH,0
                        INT     01ah
                        CMP     DL,byte[PauseCounter]
                        JNZ     Wait3

                        JMP     TitleScreen


;----------------------------------------------------------------------------------------------------------------------------------
; Kill Player - Never returns!
;----------------------------------------------------------------------------------------------------------------------------------

KillPlayer:

                        MOV     AL,byte[Lives]
                        MOV     BX,285
                        MOV     DL,0
                        MOV     DH,0
                        CALL    DisplayDigit
                        DEC byte[Lives]
                        MOV     AL,byte[Lives]
                        MOV     BX,285
                        MOV     DL,0
                        MOV     DH,5
                        CALL    DisplayDigit

                        CMP     byte[Lives],48
                        JNZ     LifeLeft
; No life left - Wait for key before exiting game
                        JMP     GameOver
; Life left - Pause before continuing
LifeLeft:               MOV     AH,0
                        INT     01ah
                        ADD     DL,18
                        MOV     byte[PauseCounter],DL
Wait4:                  MOV     AH,0
                        INT     01ah
                        CMP     DL,byte[PauseCounter]
                        JNZ     Wait4
                        CALL    EraseInvaders
                        CALL    ResetLevel

                        MOV     BX,0
Search3:                CMP     byte[BombY+BX],0
                        JNZ     KillBomb2
                        JMP     NoFoundSlot1

KillBomb2:              MOV     word[KillBombs],BX
                        MOV     DL,byte[BombY+BX]       ; Get Y position to draw sprite at
                        CMP     byte[BombType+BX],0
                        JZ      AnimatedBomb4
                        MOV     AX,StraightMissile  ; Get address of sprite
                        JMP     AllDone4
AnimatedBomb4:          CMP     byte[Frame],1
                        JNZ     IsFrame004
                        MOV     AX,TwistedMissile1  ; Get address of sprite
                        JMP     AllDone4
IsFrame004:             MOV     AX,TwistedMissile2  ; Get address of sprite
AllDone4:               SHL     BX,1
                        MOV     BX,word[BombX+BX]       ; Get X position to draw sprite at
                        CALL    EraseSprite         ; Draw sprite
                        MOV     BX,word[KillBombs]
                        MOV     byte[BombY+BX],0        ; Get X position to draw sprite at

NoFoundSlot1:           INC     BX
                        CMP     BX,22
                        JZ      AllBombsDead
                        JMP     Search3

AllBombsDead:           JMP     RedrawBunkers

KillBombs               DW      0


;----------------------------------------------------------------------------------------------------------------------------------
; Drop Invader Bomb
;----------------------------------------------------------------------------------------------------------------------------------

InvaderBomb:

                        MOV     BX,0002h
                        CALL    Random
;------------------------------------------------------------------
;                        CMP     RandomNumber[0],0
;                        JNZ     NoGood
;                        MOV     DL,83
;                        MOV     AH,2
;                        INT     21h
;                        JMP     Good
;NoGood:                 MOV     DL,32
;                        MOV     AH,2
;                        INT     21h
;Good:                   MOV     DL,00dh
;                        MOV     AH,2
;                        INT     21h
;------------------------------------------------------------------
                        MOV     DH,byte[RandomNumber]
                        MOV     byte[TempRand],DH
                        MOV     BX,0000bh       ; Random number between 0 and 11 in AX
                        CALL    Random          ; Call random routine
                        MOV     AX,08000h
                        MOV     CH,0
                        MOV     CL,byte[RandomNumber]
                        INC     CX
LoopingZ:               SHR     AX,1
                        LOOP    LoopingZ
                        MOV     DL,0
                        TEST    word[InvadersToggle+8],AX
                        JZ      NoRow5Invader
                        MOV     DL,44
                        JMP     FoundY
NoRow5Invader:          TEST    word[InvadersToggle+6],AX
                        JZ      NoRow4Invader
                        MOV     DL,34
                        JMP     FoundY
NoRow4Invader:          TEST    word[InvadersToggle+4],AX
                        JZ      NoRow3Invader
                        MOV     DL,24
                        JMP     FoundY
NoRow3Invader:          TEST    word[InvadersToggle+2],AX
                        JZ      NoRow2Invader
                        MOV     DL,14
                        JMP     FoundY
NoRow2Invader:          TEST    word[InvadersToggle],AX
                        JZ      NoInvaders
                        MOV     DL,4

FoundY:                 MOV     AL,byte[RandomNumber]
                        MOV     AH,0
                        MOV     CL,16
                        MUL     CL

                        ADD     AX,word[InvadersX]
                        SUB     AX,200
                        ADD     DL,byte[InvadersY]

; AX Holds X, DL holds Y of bomb start position

                        MOV     BX,0
Search:                 CMP     byte[BombY+BX],0
                        JZ      FoundSlot
                        INC     BX
                        CMP     BX,22
                        JNZ     Search
                        JMP     NoInvaders

; BX Holds offset (bomb number)

FoundSlot:              MOV     byte[BombY+BX],DL
                        MOV     DH,byte[TempRand]
                        MOV     byte[BombType+BX],DH
                        SHL     BX,1
                        MOV     word[BombX+BX],AX

NoInvaders:             RET

TempRand                DB      0


;----------------------------------------------------------------------------------------------------------------------------------
; Move Invader Bombs
;----------------------------------------------------------------------------------------------------------------------------------

MoveBombs:

                        MOV     BX,0
Search2:                CMP     byte[BombY+BX],0
                        JNZ     GotSlot
                        JMP     NoFoundSlot

GotSlot:                MOV     word[TempCounter],BX
                        MOV     DL,byte[BombY+BX]       ; Get Y position to draw sprite at
                        CMP     byte[BombType+BX],0
                        JZ      AnimatedBomb1
                        MOV     AX,StraightMissile  ; Get address of sprite
                        JMP     AllDone1
AnimatedBomb1:          CMP     byte[Frame],1
                        JNZ     IsFrame001
                        MOV     AX,TwistedMissile1  ; Get address of sprite
                        JMP     AllDone1
IsFrame001:             MOV     AX,TwistedMissile2  ; Get address of sprite
AllDone1:               SHL     BX,1
                        MOV     BX,word[BombX+BX]       ; Get X position to draw sprite at
                        CALL    EraseSprite         ; Draw sprite
                        MOV     BX,word[TempCounter]
                        INC     byte[BombY+BX]
                        INC     byte[BombY+BX]
                        CMP     byte[BombY+BX],130
                        JNZ     DrawNextFrameA
                        MOV     byte[BombY+BX],0
                        JMP     NoFoundSlot
DrawNextFrameA:         MOV     DL,byte[BombY+BX]       ; Get Y position to draw sprite at
                        CMP     byte[BombType+BX],0
                        JZ      AnimatedBomb2
                        MOV     AX,StraightMissile  ; Get address of sprite
                        JMP     AllDone2
AnimatedBomb2:          CMP     byte[Frame],1
                        JNZ     IsFrame002
                        MOV     AX,TwistedMissile1  ; Get address of sprite
                        JMP     AllDone2
IsFrame002:             MOV     AX,TwistedMissile2  ; Get address of sprite
AllDone2:               SHL     BX,1
                        MOV     BX,word[BombX+BX]       ; Get X position to draw sprite at
                        MOV     DH,06h              ; Get color to draw sprite
                        MOV     byte[Collision],0
                        CALL    DrawSprite          ; Draw sprite
                        CMP     byte[Collision],1
                        JNZ     NoDeadPlayer
                        JMP     KillPlayer
NoDeadPlayer:           CMP     byte[Collision],2
                        JZ      KillBomb
                        CMP     byte[Collision],4
                        JNZ     NoAction
KillBomb:               MOV     BX,word[TempCounter]
                        MOV     DL,byte[BombY+BX]       ; Get Y position to draw sprite at
                        CMP     byte[BombType+BX],0
                        JZ      AnimatedBomb3
                        MOV     AX,StraightMissile  ; Get address of sprite
                        JMP     AllDone3
AnimatedBomb3:          CMP     byte[Frame],1
                        JNZ     IsFrame003
                        MOV     AX,TwistedMissile1  ; Get address of sprite
                        JMP     AllDone3
IsFrame003:             MOV     AX,TwistedMissile2  ; Get address of sprite
AllDone3:               SHL     BX,1
                        MOV     BX,word[BombX+BX]       ; Get X position to draw sprite at
                        CALL    EraseSprite         ; Draw sprite
                        MOV     BX,word[TempCounter]
                        MOV     byte[BombY+BX],0        ; Get X position to draw sprite at
                        CMP     byte[Collision],4
                        JNZ     NoAction
                        CALL    KillMissile
NoAction:               MOV     byte[Collision],0
                        MOV     BX,word[TempCounter]

NoFoundSlot:            INC     BX
                        CMP     BX,22
                        JZ      DoneMoveBombs
                        JMP     Search2

DoneMoveBombs:          RET

TempCounter             DW      0


;----------------------------------------------------------------------------------------------------------------------------------
; Move UFO
;----------------------------------------------------------------------------------------------------------------------------------

MoveUFO:

                        DEC byte[UFOMove]
                        CMP     byte[UFOMove],0
                        JNZ     DoneUFO
                        MOV     byte[UFOMove],2

                        MOV     AX,UFO              ; Get address of sprite
                        MOV     BX,word[UFOX]             ; Get X position to draw sprite at
                        MOV     DL,10               ; Get Y position to draw sprite at
                        CALL    EraseSprite         ; Draw sprite

                        INC word[UFOX]
                        CMP     word[UFOX],254
                        JNZ     DoNextUFOFrame
                        MOV     word[UFOX],0
                        JMP     DoneUFO

DoNextUFOFrame:         MOV     AX,UFO              ; Get address of sprite
                        MOV     BX,word[UFOX]             ; Get X position to draw sprite at
                        MOV     DL,10               ; Get Y position to draw sprite at
                        MOV     DH,3                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite

; Make sound

                        TEST    byte[Sound],080h
                        JZ      NoSound1

                        MOV     AL,0b6h
                        OUT     043h,AL
                        MOV     AL,090h
                        OUT     042h,AL
                        MOV     AL,000h
                        OUT     042h,AL
                        IN      AL,061h
                        OR      AL,3
                        OUT     061h,AL

NoSound1:               MOV     CX,08000h
TimerZ:                 LOOP    TimerZ

                        IN      AL,061h
                        AND     AL,0fch
                        OUT     061h,AL

DoneUFO:                RET

UFOMove                 DB      2
UFOCounter              DB      6


;----------------------------------------------------------------------------------------------------------------------------------
; Generate Random Number
;----------------------------------------------------------------------------------------------------------------------------------

Random:

                        MOV     AX,word[Seed]
                        MUL     BX
                        MOV     CX,65531
                        DIV     CX
                        MOV     word[Seed],DX
                        MOV     byte[RandomNumber],AL

                        RET

Seed                    DW      0
RandomNumber            DB      0


;----------------------------------------------------------------------------------------------------------------------------------
; Next Level
;----------------------------------------------------------------------------------------------------------------------------------

NextLevel:

                        DEC byte[CurrentInvaderSpeed]
                        ADD     byte[CurrentInvaderY],002h
                        CMP     word[CurrentBombFreq],002h
                        JZ      NoDecrease
                        DEC word[CurrentBombFreq]

NoDecrease:             CALL    ResetLevel

                        RET


; Reset Level

ResetLevel:

                        MOV     byte[PlayerDead],0
                        MOV     byte[NextLevelToggle],0
                        MOV     byte[Frame],0
                        MOV     word[InvadersX],275
                        MOV     AL,byte[CurrentInvaderY]
                        MOV     byte[InvadersY],AL
                        MOV     word[InvadersToggle],07ff0h
                        MOV     word[InvadersToggle+2],07ff0h
                        MOV     word[InvadersToggle+4],07ff0h
                        MOV     word[InvadersToggle+6],07ff0h
                        MOV     word[InvadersToggle+8],07ff0h
                        MOV     byte[MoveCount],1
                        MOV     AL,byte[CurrentInvaderSpeed]
                        MOV     byte[InvaderSpeed],AL
                        MOV     byte[Direction],0
                        MOV     byte[Reversing],0
                        MOV     byte[Collision],0
                        MOV     AX,word[CurrentBombFreq]
                        MOV     word[BombFreq],AX

                        RET

CurrentInvaderSpeed     DB      55
CurrentInvaderY         DB      30
CurrentBombFreq         DW      010h


;----------------------------------------------------------------------------------------------------------------------------------
; Increase Score
;----------------------------------------------------------------------------------------------------------------------------------

IncreaseScore:

RackScore:              CALL    ScorePlusOne
                        LOOP    RackScore

                        RET


; Bump score up by 1

ScorePlusOne:

                        INC     byte[Score+4]
                        CMP     byte[Score+4],58
                        JNZ     Done
                        MOV     byte[Score+4],48
                        INC     byte[Score+3]
                        CMP     byte[Score+3],58
                        JNZ     Done
                        MOV     byte[Score+3],48
                        INC     byte[Score+2]
                        CMP     byte[Score+2],58
                        JNZ     Done
                        MOV     byte[Score+2],48
                        INC     byte[Score+1]
                        CMP     byte[Score+1],58
                        JNZ     Done
                        MOV     byte[Score+1],48
                        INC byte[Score]
                        MOV     word[TempCX],CX
                        MOV     AL,byte[Lives]
                        MOV     BX,285
                        MOV     DL,0
                        MOV     DH,0
                        CALL    DisplayDigit
                        INC byte[Lives]
                        MOV     AL,byte[Lives]
                        MOV     BX,285
                        MOV     DL,0
                        MOV     DH,5
                        CALL    DisplayDigit
                        MOV     CX,word[TempCX]
                        CMP     byte[Score],58
                        JNZ     Done

Done:                   RET

TempCX                  DW      0


;----------------------------------------------------------------------------------------------------------------------------------
; Display Score
;----------------------------------------------------------------------------------------------------------------------------------

DisplayScore:

                        MOV     SI,word[ScoreValueOffset]
                        LODSB
                        MOV     BX,word[ScoreXOffset]
                        MOV     DL,0
                        MOV     DH,5
                        CALL    DisplayDigit

                        INC word[ScoreValueOffset]
                        ADD     word[ScoreXOffset],6

                        MOV     SI,word[ScoreValueOffset]
                        LODSB
                        MOV     BX,word[ScoreXOffset]
                        MOV     DL,0
                        MOV     DH,5
                        CALL    DisplayDigit

                        INC word[ScoreValueOffset]
                        ADD     word[ScoreXOffset],6

                        MOV     SI,word[ScoreValueOffset]
                        LODSB
                        MOV     BX,word[ScoreXOffset]
                        MOV     DL,0
                        MOV     DH,5
                        CALL    DisplayDigit

                        INC word[ScoreValueOffset]
                        ADD     word[ScoreXOffset],6

                        MOV     SI,word[ScoreValueOffset]
                        LODSB
                        MOV     BX,word[ScoreXOffset]
                        MOV     DL,0
                        MOV     DH,5
                        CALL    DisplayDigit

                        INC word[ScoreValueOffset]
                        ADD     word[ScoreXOffset],6

                        MOV     SI,word[ScoreValueOffset]
                        LODSB
                        MOV     BX,word[ScoreXOffset]
                        MOV     DL,0
                        MOV     DH,5
                        CALL    DisplayDigit

                        RET

ScoreXOffset            DW      0
ScoreValueOffset        DW      0


;----------------------------------------------------------------------------------------------------------------------------------
; Erase Score
;----------------------------------------------------------------------------------------------------------------------------------

EraseScore:

                        MOV     SI,word[ScoreValueOffset]
                        LODSB
                        MOV     BX,word[ScoreXOffset]
                        MOV     DL,0
                        MOV     DH,0
                        CALL    DisplayDigit

                        INC word[ScoreValueOffset]
                        ADD     word[ScoreXOffset],6

                        MOV     SI,word[ScoreValueOffset]
                        LODSB
                        MOV     BX,word[ScoreXOffset]
                        MOV     DL,0
                        MOV     DH,0
                        CALL    DisplayDigit

                        INC word[ScoreValueOffset]
                        ADD     word[ScoreXOffset],6

                        MOV     SI,word[ScoreValueOffset]
                        LODSB
                        MOV     BX,word[ScoreXOffset]
                        MOV     DL,0
                        MOV     DH,0
                        CALL    DisplayDigit

                        INC word[ScoreValueOffset]
                        ADD     word[ScoreXOffset],6

                        MOV     SI,word[ScoreValueOffset]
                        LODSB
                        MOV     BX,word[ScoreXOffset]
                        MOV     DL,0
                        MOV     DH,0
                        CALL    DisplayDigit

                        INC word[ScoreValueOffset]
                        ADD     word[ScoreXOffset],6

                        MOV     SI,word[ScoreValueOffset]
                        LODSB
                        MOV     BX,word[ScoreXOffset]
                        MOV     DL,0
                        MOV     DH,0
                        CALL    DisplayDigit

                        RET


;----------------------------------------------------------------------------------------------------------------------------------
; Display / Erase Digit In Decimal
;----------------------------------------------------------------------------------------------------------------------------------

DisplayDigit:

                        CALL    FindDigit
                        CALL    DrawSprite          ; Draw sprite

                        RET


FindDigit:

; Find Digit
                        CMP     AL,48
                        JNZ     NotZero
                        MOV     AX,Zero
                        JMP     GotDigit
NotZero:                CMP     AL,49
                        JNZ     NotOne
                        MOV     AX,One
                        JMP     GotDigit
NotOne:                 CMP     AL,50
                        JNZ     NotTwo
                        MOV     AX,Two
                        JMP     GotDigit
NotTwo:                 CMP     AL,51
                        JNZ     NotThree
                        MOV     AX,Three
                        JMP     GotDigit
NotThree:               CMP     AL,52
                        JNZ     NotFour
                        MOV     AX,Four
                        JMP     GotDigit
NotFour:                CMP     AL,53
                        JNZ     NotFive
                        MOV     AX,Five
                        JMP     GotDigit
NotFive:                CMP     AL,54
                        JNZ     NotSix
                        MOV     AX,Six
                        JMP     GotDigit
NotSix:                 CMP     AL,55
                        JNZ     NotSeven
                        MOV     AX,Seven
                        JMP     GotDigit
NotSeven:               CMP     AL,56
                        JNZ     NotEight
                        MOV     AX,Eight
                        JMP     GotDigit
NotEight:               CMP     AL,57
                        JNZ     NotNine
                        MOV     AX,Nine
                        JMP     GotDigit

NotNine:                CMP     AL,65
                        JNZ     NotA
                        MOV     AX,LetterA
                        JMP     GotDigit
NotA:                   CMP     AL,66
                        JNZ     NotB
                        MOV     AX,LetterB
                        JMP     GotDigit
NotB:                   CMP     AL,67
                        JNZ     NotC
                        MOV     AX,LetterC
                        JMP     GotDigit
NotC:                   CMP     AL,68
                        JNZ     NotD
                        MOV     AX,LetterD
                        JMP     GotDigit
NotD:                   CMP     AL,69
                        JNZ     NotE
                        MOV     AX,LetterE
                        JMP     GotDigit
NotE:                   CMP     AL,70
                        JNZ     NotF
                        MOV     AX,LetterF
                        JMP     GotDigit
NotF:                   CMP     AL,71
                        JNZ     NotG
                        MOV     AX,LetterG
                        JMP     GotDigit
NotG:                   CMP     AL,72
                        JNZ     NotH
                        MOV     AX,LetterH
                        JMP     GotDigit
NotH:                   CMP     AL,73
                        JNZ     NotI
                        MOV     AX,LetterI
                        JMP     GotDigit
NotI:                   CMP     AL,74
                        JNZ     NotJ
                        MOV     AX,LetterJ
                        JMP     GotDigit
NotJ:                   CMP     AL,75
                        JNZ     NotK
                        MOV     AX,LetterK
                        JMP     GotDigit
NotK:                   CMP     AL,76
                        JNZ     NotL
                        MOV     AX,LetterL
                        JMP     GotDigit
NotL:                   CMP     AL,77
                        JNZ     NotM
                        MOV     AX,LetterM
                        JMP     GotDigit
NotM:                   CMP     AL,78
                        JNZ     NotN
                        MOV     AX,LetterN
                        JMP     GotDigit
NotN:                   CMP     AL,79
                        JNZ     NotO
                        MOV     AX,LetterO
                        JMP     GotDigit
NotO:                   CMP     AL,80
                        JNZ     NotP
                        MOV     AX,LetterP
                        JMP     GotDigit
NotP:                   CMP     AL,81
                        JNZ     NotQ
                        MOV     AX,LetterQ
                        JMP     GotDigit
NotQ:                   CMP     AL,82
                        JNZ     NotR
                        MOV     AX,LetterR
                        JMP     GotDigit
NotR:                   CMP     AL,83
                        JNZ     NotS
                        MOV     AX,LetterS
                        JMP     GotDigit
NotS:                   CMP     AL,84
                        JNZ     NotT
                        MOV     AX,LetterT
                        JMP     GotDigit
NotT:                   CMP     AL,85
                        JNZ     NotU
                        MOV     AX,LetterU
                        JMP     GotDigit
NotU:                   CMP     AL,86
                        JNZ     NotV
                        MOV     AX,LetterV
                        JMP     GotDigit
NotV:                   CMP     AL,87
                        JNZ     NotW
                        MOV     AX,LetterW
                        JMP     GotDigit
NotW:                   CMP     AL,88
                        JNZ     NotX
                        MOV     AX,LetterX
                        JMP     GotDigit
NotX:                   CMP     AL,89
                        JNZ     NotY
                        MOV     AX,LetterY
                        JMP     GotDigit
NotY:                   CMP     AL,90
                        JNZ     NotZ
                        MOV     AX,LetterZ
                        JMP     GotDigit
NotZ:                   CMP     AL,61
                        JNZ     NotEqual
                        MOV     AX,Equal
                        JMP     GotDigit
NotEqual:               CMP     AL,40
                        JNZ     NotCopyright
                        MOV     AX,CopyrightSymbol
                        JMP     GotDigit
NotCopyright:           MOV     AX,Period

GotDigit:               RET


;----------------------------------------------------------------------------------------------------------------------------------
; Check If Player Is Dead
;----------------------------------------------------------------------------------------------------------------------------------

CheckPlayerDead:

                        CMP     word[InvadersToggle+8],0
                        JZ      NoRow5Left
                        CMP     byte[InvadersY],84
                        JNZ     NotDead
                        MOV     byte[PlayerDead],1
                        JMP     NotDead

NoRow5Left:             CMP     word[InvadersToggle+6],0
                        JZ      NoRow4Left
                        CMP     byte[InvadersY],94
                        JNZ     NotDead
                        MOV     byte[PlayerDead],1
                        JMP     NotDead

NoRow4Left:             CMP     word[InvadersToggle+4],0
                        JZ      NoRow3Left
                        CMP     byte[InvadersY],104
                        JNZ     NotDead
                        MOV     byte[PlayerDead],1
                        JMP     NotDead

NoRow3Left:             CMP     word[InvadersToggle+2],0
                        JZ      NoRow2Left
                        CMP     byte[InvadersY],114
                        JNZ     NotDead
                        MOV     byte[PlayerDead],1
                        JMP     NotDead

NoRow2Left:             CMP     byte[InvadersY],124
                        JNZ     NotDead
                        MOV     byte[PlayerDead],1

NotDead:                RET


;----------------------------------------------------------------------------------------------------------------------------------
; Check Invader Killed
;----------------------------------------------------------------------------------------------------------------------------------

CheckInvaderKill:

                        MOV     AL,byte[Collision]
                        AND     AL,0f0h
                        CMP     AL,050h
                        JNZ     NoRow5Kill
                        CALL    SpeedUpInvaders
                        MOV     CH,0
                        MOV     CL,byte[Collision]
                        AND     CL,00fh
                        INC     CL
                        MOV     AX,08000h
Shifting1:              SHR     AX,1
                        LOOP    Shifting1
                        XOR     word[InvadersToggle+8],AX
                        MOV     CX,5
                        CALL    IncreaseScore

                        JMP     NoRow1Kill

NoRow5Kill:             MOV     AL,byte[Collision]
                        AND     AL,0f0h
                        CMP     AL,040h
                        JNZ     NoRow4Kill
                        CALL    SpeedUpInvaders
                        MOV     CH,0
                        MOV     CL,byte[Collision]
                        AND     CL,00fh
                        INC     CL
                        MOV     AX,08000h
Shifting2:              SHR     AX,1
                        LOOP    Shifting2
                        XOR     word[InvadersToggle+6],AX
                        MOV     CX,10
                        CALL    IncreaseScore
                        JMP     NoRow1Kill

NoRow4Kill:             MOV     AL,byte[Collision]
                        AND     AL,0f0h
                        CMP     AL,030h
                        JNZ     NoRow3Kill
                        CALL    SpeedUpInvaders
                        MOV     CH,0
                        MOV     CL,byte[Collision]
                        AND     CL,00fh
                        INC     CL
                        MOV     AX,08000h
Shifting3:              SHR     AX,1
                        LOOP    Shifting3
                        XOR     word[InvadersToggle+4],AX
                        MOV     CX,15
                        CALL    IncreaseScore
                        JMP     NoRow1Kill

NoRow3Kill:             MOV     AL,byte[Collision]
                        AND     AL,0f0h
                        CMP     AL,020h
                        JNZ     NoRow2Kill
                        CALL    SpeedUpInvaders
                        MOV     CH,0
                        MOV     CL,byte[Collision]
                        AND     CL,00fh
                        INC     CL
                        MOV     AX,08000h
Shifting4:              SHR     AX,1
                        LOOP    Shifting4
                        XOR     word[InvadersToggle+2],AX
                        MOV     CX,20
                        CALL    IncreaseScore
                        JMP     NoRow1Kill

NoRow2Kill:             MOV     AL,byte[Collision]
                        AND     AL,0f0h
                        CMP     AL,010h
                        JNZ     NoRow1Kill
                        CALL    SpeedUpInvaders
                        MOV     CH,0
                        MOV     CL,byte[Collision]
                        AND     CL,00fh
                        INC     CL
                        MOV     AX,08000h
Shifting5:              SHR     AX,1
                        LOOP    Shifting5
                        XOR     word[InvadersToggle],AX
                        MOV     CX,25
                        CALL    IncreaseScore
                        JMP     NoUFOKill

NoRow1Kill:             CMP     byte[Collision],3
                        JNZ     NoUFOKill
                        MOV     AX,UFO              ; Get address of sprite
                        MOV     BX,word[UFOX]             ; Get X position to draw sprite at
                        MOV     DL,10               ; Get Y position to draw sprite at
                        CALL    EraseSprite         ; Draw sprite
                        MOV     word[UFOX],0
                        MOV     CX,100
                        CALL    IncreaseScore

NoUFOKill:              CMP     word[InvadersToggle],00000h
                        JNZ     NotAllDeadYet
                        CMP     word[InvadersToggle+2],00000h
                        JNZ     NotAllDeadYet
                        CMP     word[InvadersToggle+4],00000h
                        JNZ     NotAllDeadYet
                        CMP     word[InvadersToggle+6],00000h
                        JNZ     NotAllDeadYet
                        CMP     word[InvadersToggle+8],00000h
                        JNZ     NotAllDeadYet
                        MOV     byte[NextLevelToggle],1

NotAllDeadYet:          RET


; Speed up invaders upon a kill

SpeedUpInvaders:

                        CMP     byte[InvaderSpeed],1
                        JZ      NoSpeedIncrease
                        DEC byte[InvaderSpeed]

NoSpeedIncrease:        RET


;----------------------------------------------------------------------------------------------------------------------------------
; Move Invaders
;----------------------------------------------------------------------------------------------------------------------------------

MoveInvaders:

                        TEST    byte[Reversing],080h
                        JNZ     NoReverse

                        MOV     BX,250
                        MOV     AX,word[InvadersToggle]
                        OR      AX,word[InvadersToggle+2]
                        OR      AX,word[InvadersToggle+4]
                        OR      AX,word[InvadersToggle+6]
                        OR      AX,word[InvadersToggle+8]
                        MOV     CX,10
FindLeft:               SHL     AX,1
                        TEST    AX,08000h
                        JNZ     DoneLeft
                        SUB     BX,16
                        LOOP    FindLeft

DoneLeft:               MOV     DX,298
                        MOV     AX,word[InvadersToggle]
                        OR      AX,word[InvadersToggle+2]
                        OR      AX,word[InvadersToggle+4]
                        OR      AX,word[InvadersToggle+6]
                        OR      AX,word[InvadersToggle+8]
                        MOV     CX,10
                        SHR     AX,1
                        SHR     AX,1
                        SHR     AX,1
FindRight:              SHR     AX,1
                        TEST    AX,00001h
                        JNZ     DoneRight
                        ADD     DX,16
                        LOOP    FindRight

DoneRight:              CMP     word[InvadersX],DX
                        JZ      Reverse
                        CMP     word[InvadersX],BX
                        JNZ     NoReverse
Reverse:                XOR     byte[Direction],080h
                        ADD     byte[InvadersY],2
                        MOV     byte[Reversing],080h
                        JMP     Animate

NoReverse:              MOV     byte[Reversing],0
                        TEST    byte[Direction],080h
                        JZ      MoveInvadersLeft

                        INC word[InvadersX]
                        JMP     Animate

MoveInvadersLeft:       DEC word[InvadersX]

Animate:                XOR     byte[Frame],080h
                        MOV     AH,byte[InvaderSpeed]
                        MOV     byte[MoveCount],AH

; Make sound

                        TEST    byte[Sound],080h
                        JZ      NoSound2

                        MOV     AL,0b6h
                        OUT     043h,AL
                        MOV     AL,090h
                        OUT     042h,AL
                        MOV     AL,00Fh
                        OUT     042h,AL
                        IN      AL,061h
                        OR      AL,3
                        OUT     061h,AL

NoSound2:               MOV     CX,08000h
Timer1:                 LOOP    Timer1

                        IN      AL,061h
                        AND     AL,0fch
                        OUT     061h,AL

                        RET


;----------------------------------------------------------------------------------------------------------------------------------
; Shoot Player Missile
;----------------------------------------------------------------------------------------------------------------------------------

ShootPlayerMissile:

                        MOV     AX,word[PlayerX]
                        MOV     word[MissileX],AX
                        MOV     byte[MissileY],123

; Make sound

                        TEST    byte[Sound],080h
                        JZ      NoSound3

                        MOV     AL,0b6h
                        OUT     043h,AL
                        MOV     AL,090h
                        OUT     042h,AL
                        MOV     AL,001h
                        OUT     042h,AL
                        IN      AL,061h
                        OR      AL,3
                        OUT     061h,AL

NoSound3:               MOV     CX,08000h
Timer2:                 LOOP    Timer2

                        IN      AL,061h
                        AND     AL,0fch
                        OUT     061h,AL

                        RET


;----------------------------------------------------------------------------------------------------------------------------------
; Move Player Missile
;----------------------------------------------------------------------------------------------------------------------------------

MovePlayerMissile:

                        MOV     AX,StraightMissile  ; Get address of sprite
                        MOV     BX,word[MissileX]         ; Get X position to draw sprite at
                        MOV     DL,byte[MissileY]         ; Get Y position to draw sprite at
                        CALL    EraseSprite         ; Draw sprite

                        DEC byte[MissileY]
                        DEC byte[MissileY]

                        CMP     byte[MissileY],09
                        JNZ     DrawNextFrame
                        MOV     word[MissileX],0
                        JMP     MissileDead

DrawNextFrame:          MOV     AX,StraightMissile  ; Get address of sprite
                        MOV     BX,word[MissileX]         ; Get X position to draw sprite at
                        MOV     DL,byte[MissileY]         ; Get Y position to draw sprite at
                        MOV     DH,04h              ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite

                        CMP     byte[Collision],0
                        JZ      MissileDead
                        CMP     byte[Collision],4
                        JZ      MissileDead
                        CMP     byte[Collision],6
                        JZ      MissileDead
                        CALL    KillMissile

MissileDead:            RET


; Kill Player Missile

KillMissile:

                        MOV     AX,StraightMissile  ; Get address of sprite
                        MOV     BX,word[MissileX]         ; Get X position to draw sprite at
                        MOV     DL,byte[MissileY]         ; Get Y position to draw sprite at
                        CALL    EraseSprite         ; Draw sprite
                        MOV     word[MissileX],0

                        RET


;----------------------------------------------------------------------------------------------------------------------------------
; Move Player's Ship Left
;----------------------------------------------------------------------------------------------------------------------------------

MovePlayerLeft:

                        CMP     word[PlayerX],50
                        JZ      NoMoreLeft
                        DEC word[PlayerX]

NoMoreLeft:             RET


;----------------------------------------------------------------------------------------------------------------------------------
; Move Player's Ship Right
;----------------------------------------------------------------------------------------------------------------------------------

MovePlayerRight:

                        CMP     word[PlayerX],259
                        JZ      NoMoreRight
                        INC word[PlayerX]

NoMoreRight:            RET


;----------------------------------------------------------------------------------------------------------------------------------
; New Interrupt 9 Handler - Replaces normal keyboard handler during game play
;
; Interrupt 015h: Calling AH = 04fh (check for this - Int 15 also has other
;                                    subfuctions!)
;                 Routine will look at AL, where the caller (Int 9) will have
;                 placed the scan code.
;
;                 Place any new scan code for int 9 to process into AL and set
;                 carry flag before return.
;
;                 Just clear carry flag to have int 9 ignore the keypress.
;----------------------------------------------------------------------------------------------------------------------------------

; Installs new int 9 handler

InstallNewInt9:

                        MOV     AH,035h                         ; Ask for interrupt address function
                        MOV     AL,015h                         ; Interrupt we're asking for
                        INT     021h                            ; Ask for it
                        MOV     word[OldInt9Address],BX      ; Save current segment of interrupt
                        MOV     word[OldInt9Address+2],ES   ; Save current offset of interrupt

                        MOV     AH,025h                         ; Insert new address for interrupt function
                        MOV     AL,015h                         ; Interupt we want to change
                        MOV     DX,NewInt9Handler               ; New address to point to (this TSR)
                        INT     021h                            ; Set it

                        RET

OldInt9Address          DW 0,     0   ; Buffer for original interrupt address
StoreAX                 DW      0


; Removes new int 9 handler

RemoveNewInt9:

                        MOV     AX,word[cs:OldInt9Address+2]
                        MOV     DS,AX
                        MOV     AH,025h                         ; Insert new address for interrupt function
                        MOV     AL,015h                         ; Interupt we want to change
                        MOV     DX,word[cs:OldInt9Address]      ; New address to point to (this TSR)
                        INT     021h                            ; Set it

                        RET


; Actual routine to be called when int 9 is tripped

NewInt9Handler:

                        CMP     AH,04fh
                        JNZ     NotIntercept

                        TEST    AL,080h
                        JNZ     NoKeyPress
                        MOV     byte[cs:KeyPress],1

; Check left arrow

NoKeyPress:             CMP     AL,04Bh                 ; Has left arrow been pressed?
                        JNZ     NoLeftOn
                        MOV     byte[cs:LeftToggle],1

NoLeftOn:               CMP     AL,0CBh                 ; Has left arrow been released?
                        JNZ     NoLeftOff
                        MOV     byte[cs:LeftToggle],0

; Check right arrow

NoLeftOff:              CMP     AL,04Dh                 ; Has right arrow been pressed?
                        JNZ     NoRightOn
                        MOV     byte[cs:RightToggle],1

NoRightOn:              CMP     AL,0CDh                 ; Has right arrow been released?
                        JNZ     NoRightOff
                        MOV     byte[cs:RightToggle],0

; Check ctrl

NoRightOff:             CMP     AL,01Dh                 ; Has ctrl been pressed?
                        JNZ     NoFireOn
                        MOV     byte[cs:FireToggle],1

NoFireOn:               CMP     AL,09Dh                 ; Has ctrl been released?
                        JNZ     NoFireOff
                        MOV     byte[cs:FireToggle],0

; Check ESC

NoFireOff:              CMP     AL,001h                 ; Has ESC been pressed?
                        JNZ     NoESCOn
                        MOV     byte[cs:ExitToggle],1

NoESCOn:                CMP     AL,01fh
                        JNZ     NotIntercept
                        MOV     byte[cs:SoundToggle],1

; Clear keyboard buffer (BIOS routine is still called, and it annoyingly beeps when it's buffer is full)



NotIntercept:
                        MOV     word[cs:StoreAX],AX
                        MOV     AX,[01ch]
                        MOV     [01ah],AX
                        MOV     AX,word[cs:StoreAX]

;                        MOV     AX,040h
;                        MOV     ES,AX
;                        MOV     DS,AX
;                        MOV     DI,01ah
;                        MOV     SI,01ch
;                        MOVSW

                        CLC

; Call original interrupt routine

;                        CALL    OldInt9Address  ; Call normal interrupt routine

                        IRET
;                        RET     2       ; Return from TSR


;---------------------------------------------------------------------
;                        JMP     StartPrint
;CharacterTable          DB		"0123456789ABCDEF"
;StartPrint:             MOV     AL,RandomNumber[0]
;                        MOV     CX,04h
;Looper1:                SHR     AL,1
;                        LOOP    Looper1
;                        MOV     SI,CharacterTable
;                        MOV     AH,0
;                        ADD     SI,AX
;                        CLD
;                        LODSB
;                        MOV     DL,AL
;                        MOV     AH,2
;                        INT     21h
;                        MOV     AL,RandomNumber[0]
;                        AND     AL,0fh
;                        MOV     SI,CharacterTable
;                        MOV     AH,0
;                        ADD     SI,AX
;                        CLD
;                        LODSB
;                        MOV     DL,AL
;                        MOV     AH,2
;                        INT     21h
;                        MOV     DL,00dh
;                        MOV     AH,2
;                        INT     21h
;---------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------------------------------------
; Draw Bunkers
;----------------------------------------------------------------------------------------------------------------------------------

DrawBunkers:

                        MOV     word[BunkerXL],70
                        MOV     byte[BunkerYL],100
                        CALL    DrawBunker

                        MOV     word[BunkerXL],122
                        MOV     byte[BunkerYL],100
                        CALL    DrawBunker

                        MOV     word[BunkerXL],174
                        MOV     byte[BunkerYL],100
                        CALL    DrawBunker

                        MOV     word[BunkerXL],226
                        MOV     byte[BunkerYL],100
                        CALL    DrawBunker

                        RET


; Draw Single Bunker

DrawBunker:

                        MOV     AX,BunkerLeftTop    ; Get address of sprite
                        MOV     BX,word[BunkerXL]         ; Get X position to draw sprite at
                        MOV     DL,byte[BunkerYL]         ; Get Y position to draw sprite at
                        MOV     DH,2                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite

                        ADD     byte[BunkerYL],7

                        MOV     AX,BunkerLeftMiddle ; Get address of sprite
                        MOV     BX,word[BunkerXL]         ; Get X position to draw sprite at
                        MOV     DL,byte[BunkerYL]         ; Get Y position to draw sprite at
                        MOV     DH,2                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite

                        ADD     byte[BunkerYL],7

                        MOV     AX,BunkerLeftBottom ; Get address of sprite
                        MOV     BX,word[BunkerXL]         ; Get X position to draw sprite at
                        MOV     DL,byte[BunkerYL]         ; Get Y position to draw sprite at
                        MOV     DH,2                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite

                        ADD     word[BunkerXL],16
                        SUB     byte[BunkerYL],14

                        MOV     AX,BunkerRightTop   ; Get address of sprite
                        MOV     BX,word[BunkerXL]         ; Get X position to draw sprite at
                        MOV     DL,byte[BunkerYL]         ; Get Y position to draw sprite at
                        MOV     DH,2                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite

                        ADD     byte[BunkerYL],7

                        MOV     AX,BunkerRightMiddle; Get address of sprite
                        MOV     BX,word[BunkerXL]         ; Get X position to draw sprite at
                        MOV     DL,byte[BunkerYL]         ; Get Y position to draw sprite at
                        MOV     DH,2                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite

                        ADD     byte[BunkerYL],7

                        MOV     AX,BunkerRightBottom; Get address of sprite
                        MOV     BX,word[BunkerXL]         ; Get X position to draw sprite at
                        MOV     DL,byte[BunkerYL]         ; Get Y position to draw sprite at
                        MOV     DH,2                ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite

						RET                     ; Done drawing, return to caller

BunkerXL                DW      0
BunkerYL                DB      0


;----------------------------------------------------------------------------------------------------------------------------------
; Draw Invaders
;----------------------------------------------------------------------------------------------------------------------------------

DrawInvaders:

                        MOV     AX,word[InvadersX]
                        MOV     word[InvadersXL],AX
                        MOV     AL,byte[InvadersY]
                        MOV     byte[InvadersYL],AL
                        MOV     SI,InvadersToggle ; Setup source pointer to sprite data

                        MOV     byte[ColorL],010h
                        TEST    byte[Frame],80h
                        JZ      FrameIsZero1
                        MOV     AX,TopInvader2
                        JMP     Skip1
FrameIsZero1:           MOV     AX,TopInvader1
Skip1:                  MOV     word[SpriteAddressL],AX
                        CLD                     ; Make sure we increment SI
                        LODSW                   ; Get 2 bytes from invaders alive toggles
                        MOV     word[Temporary2L],SI
                        CALL    DrawInvaderRow

                        MOV     byte[ColorL],020h
                        TEST    byte[Frame],80h
                        JZ      FrameIsZero2
                        MOV     AX,MiddleInvader2
                        JMP     Skip2
FrameIsZero2:           MOV     AX,MiddleInvader1
Skip2:                  MOV     word[SpriteAddressL],AX
                        MOV     SI,word[Temporary2L]
                        CLD                     ; Make sure we increment SI
                        LODSW                   ; Get 2 bytes from invaders alive toggles
                        MOV     word[Temporary2L],SI
                        CALL    DrawInvaderRow

                        MOV     byte[ColorL],030h
                        TEST    byte[Frame],80h
                        JZ      FrameIsZero3
                        MOV     AX,MiddleInvader1
                        JMP     Skip3
FrameIsZero3:           MOV     AX,MiddleInvader2
Skip3:                  MOV     word[SpriteAddressL],AX
                        MOV     SI,word[Temporary2L]
                        CLD                     ; Make sure we increment SI
                        LODSW                   ; Get 2 bytes from invaders alive toggles
                        MOV     word[Temporary2L],SI
                        CALL    DrawInvaderRow

                        MOV     byte[ColorL],040h
                        TEST    byte[Frame],80h
                        JZ      FrameIsZero4
                        MOV     AX,BottomInvader2
                        JMP     Skip4
FrameIsZero4:           MOV     AX,BottomInvader1
Skip4:                  MOV     word[SpriteAddressL],AX
                        MOV     SI,word[Temporary2L]
                        CLD                     ; Make sure we increment SI
                        LODSW                   ; Get 2 bytes from invaders alive toggles
                        MOV     word[Temporary2L],SI
                        CALL    DrawInvaderRow

                        MOV     byte[ColorL],050h
                        MOV     SI,word[Temporary2L]
                        CLD                     ; Make sure we increment SI
                        LODSW                   ; Get 2 bytes from invaders alive toggles
                        MOV     word[Temporary2L],SI
                        CALL    DrawInvaderRow

                        MOV     byte[Collision],0     ; No collision detection on invaders - Causes problems when invaders get to bunkers

						RET                     ; Done drawing, return to caller

InvadersXL              DW      0
InvadersYL              DB      0
Temporary2L             DW      0


; Draw Row of Invaders

DrawInvaderRow:

                        SHL     AX,1
                        MOV     byte[CounterL],11
DrawRow:                TEST    AX,8000h        ; Check left most bit
                        JZ      BitIsZero1      ; Jump if bit is 0
                        MOV     word[Temporary1L],AX
                        MOV     AX,word[SpriteAddressL]   ; Get address of sprite
                        MOV     BX,word[InvadersXL]       ; Get X position to draw sprite at
                        SUB     BX,200
                        MOV     DL,byte[InvadersYL]       ; Get Y position to draw sprite at
                        MOV     DH,byte[ColorL]           ; Get color to draw sprite
                        CALL    DrawSprite          ; Draw sprite
                        MOV     AX,word[Temporary1L]
BitIsZero1:             SHL     AX,1            ; Shift data left for next bit
                        ADD     word[InvadersXL],16
                        DEC byte[CounterL]
                        INC byte[ColorL]
                        JNZ     DrawRow

                        ADD     byte[InvadersYL],10
                        MOV     AX,word[InvadersX]
                        MOV     word[InvadersXL],AX

						RET                     ; Done drawing, return to caller

CounterL                DB      0
SpriteAddressL          DW      0
ColorL                  DB      0
Temporary1L             DW      0


;----------------------------------------------------------------------------------------------------------------------------------
; Erase Invaders
;----------------------------------------------------------------------------------------------------------------------------------

EraseInvaders:

                        MOV     AX,word[InvadersX]
                        MOV     word[InvadersXL],AX
                        MOV     AL,byte[InvadersY]
                        MOV     byte[InvadersYL],AL
                        MOV     SI,InvadersToggle ; Setup source pointer to sprite data

                        TEST    byte[Frame],80h
                        JZ      FrameIsZeroA
                        MOV     AX,TopInvader2
                        JMP     SkipA
FrameIsZeroA:           MOV     AX,TopInvader1
SkipA:                  MOV     word[SpriteAddressL],AX
                        CLD                     ; Make sure we increment SI
                        LODSW                   ; Get 2 bytes from invaders alive toggles
                        MOV     word[Temporary2L],SI
                        CALL    EraseInvaderRow

                        TEST    byte[Frame],80h
                        JZ      FrameIsZeroB
                        MOV     AX,MiddleInvader2
                        JMP     SkipB
FrameIsZeroB:           MOV     AX,MiddleInvader1
SkipB:                  MOV     word[SpriteAddressL],AX
                        MOV     SI,word[Temporary2L]
                        CLD                     ; Make sure we increment SI
                        LODSW                   ; Get 2 bytes from invaders alive toggles
                        MOV     word[Temporary2L],SI
                        CALL    EraseInvaderRow

                        TEST    byte[Frame],80h
                        JZ      FrameIsZeroC
                        MOV     AX,MiddleInvader1
                        JMP     SkipC
FrameIsZeroC:           MOV     AX,MiddleInvader2
SkipC:                  MOV     word[SpriteAddressL],AX
                        MOV     SI,word[Temporary2L]
                        CLD                     ; Make sure we increment SI
                        LODSW                   ; Get 2 bytes from invaders alive toggles
                        MOV     word[Temporary2L],SI
                        CALL    EraseInvaderRow

                        TEST    byte[Frame],80h
                        JZ      FrameIsZeroD
                        MOV     AX,BottomInvader2
                        JMP     SkipD
FrameIsZeroD:           MOV     AX,BottomInvader1
SkipD:                  MOV     word[SpriteAddressL],AX
                        MOV     SI,word[Temporary2L]
                        CLD                     ; Make sure we increment SI
                        LODSW                   ; Get 2 bytes from invaders alive toggles
                        MOV     word[Temporary2L],SI
                        CALL    EraseInvaderRow

                        MOV     SI,word[Temporary2L]
                        CLD                     ; Make sure we increment SI
                        LODSW                   ; Get 2 bytes from invaders alive toggles
                        MOV     word[Temporary2L],SI
                        CALL    EraseInvaderRow

						RET                     ; Done drawing, return to caller


; Erase Row of Invaders

EraseInvaderRow:

                        SHL     AX,1
                        MOV     byte[CounterL],11
DrawRowA:               TEST    AX,8000h        ; Check left most bit
                        JZ      BitIsZeroA      ; Jump if bit is 0
                        MOV     word[Temporary1L],AX
                        MOV     AX,word[SpriteAddressL]   ; Get address of sprite
                        MOV     BX,word[InvadersXL]       ; Get X position to draw sprite at
                        SUB     BX,200
                        MOV     DL,byte[InvadersYL]       ; Get Y position to draw sprite at
                        CALL    EraseSprite         ; Draw sprite
                        MOV     AX,word[Temporary1L]
BitIsZeroA:             SHL     AX,1            ; Shift data left for next bit
                        ADD     word[InvadersXL],16
                        DEC byte[CounterL]
                        JNZ     DrawRowA

                        ADD     byte[InvadersYL],10
                        MOV     AX,word[InvadersX]
                        MOV     word[InvadersXL],AX

						RET                     ; Done drawing, return to caller


;----------------------------------------------------------------------------------------------------------------------------------
; Draw Logo Layer
;----------------------------------------------------------------------------------------------------------------------------------

DrawLogoLayer:

                        MOV     SI,AX           ; Setup source pointer to sprite data
                        MOV     AL,DL           ; Get Y position of sprite in AL
                        MOV     AH,0            ; Zero high byte of AX for following shifts
                        SHL     AX,1            ; Calculate Y position * 320 (find address of row)
                        SHL     AX,1            ; Y Position shifted left 6 times + Y Position shifted left 8 times
                        SHL     AX,1
                        SHL     AX,1
                        SHL     AX,1
                        SHL     AX,1
                        MOV     CX,AX
                        SHL     CX,1
                        SHL     CX,1
                        ADD     AX,CX
                        ADD     AX,BX           ; Add X position to address
                        MOV     DI,AX           ; Store address in destination register
                        MOV     AX,0a000h       ; Get segment of video memory
                        MOV     ES,AX           ; Store it in destination segment register

                        MOV     byte[Row],5

DoNextRow:              MOV     byte[Column],11

DoNextSprite:           MOV     DL,7            ; Do 7 lines of sprite
                        CLD                     ; Make sure we increment SI and DI
DrawLinesZ:             LODSW                   ; Get 2 bytes from sprite data (16 bits = 1 line of sprite image)
                        MOV     BX,AX           ; Transfer data to an unused register
                        MOV     CX,16           ; Scan all 16 bits
DoLineZ:                TEST    BX,8000h        ; Check left most bit
                        JZ      BitIsZeroZ      ; Jump if bit is 0
                        MOV     AL,DH           ; Bit is 1, get color of sprite
                        STOSB                   ; And draw the pixel on the screen
                        JMP     SkipZ           ; Skip the bit is 0 stuff
BitIsZeroZ:             INC     DI              ; Bit was 0, increment destination register
SkipZ:                  SHL     BX,1            ; Shift data left for next bit
                        LOOP    DoLineZ         ; Keep going until no more bits to check
                        ADD     DI,304          ; Increment address to next screen line (320 - 16 bits)
                        DEC     DL              ; Decrease line count
                        JNZ     DrawLinesZ      ; Draw lines until no more lines left to draw

                        SUB     DI,2224         ; Do next sprite in row
                        DEC byte[Column]
                        CMP     byte[Column],0
                        JNZ     DoNextSprite

                        ADD     DI,2064         ; Do next sprite in row
                        DEC byte[Row]
                        CMP     byte[Row],0
                        JNZ     DoNextRow

						RET                     ; Done drawing, return to caller

Column                  DB      0
Row                     DB      0


;----------------------------------------------------------------------------------------------------------------------------------
; Draw Sprite
;----------------------------------------------------------------------------------------------------------------------------------

DrawSprite:

                        MOV     SI,AX           ; Setup source pointer to sprite data
                        MOV     AL,DL           ; Get Y position of sprite in AL
                        MOV     AH,0            ; Zero high byte of AX for following shifts
                        SHL     AX,1            ; Calculate Y position * 320 (find address of row)
                        SHL     AX,1            ; Y Position shifted left 6 times + Y Position shifted left 8 times
                        SHL     AX,1
                        SHL     AX,1
                        SHL     AX,1
                        SHL     AX,1
                        MOV     CX,AX
                        SHL     CX,1
                        SHL     CX,1
                        ADD     AX,CX
                        MOV     CX,VideoBuffer  ; Get address of video buffer
                        ADD     AX,CX           ; Add offset to video buffer
                        ADD     AX,BX           ; Add X position to address
                        MOV     DI,AX           ; Store address in destination register
                        MOV     AX,CS           ; Get segment of video memory
                        MOV     ES,AX           ; Store it in destination segment register

                        MOV     DL,7            ; Do 7 lines
                        CLD                     ; Make sure we increment SI and DI
DrawLines:              LODSW                   ; Get 2 bytes from sprite data (16 bits = 1 line of sprite image)
                        MOV     BX,AX           ; Transfer data to an unused register
                        MOV     CX,16           ; Scan all 16 bits
DoLine:                 TEST    BX,8000h        ; Check left most bit
                        JZ      BitIsZero       ; Jump if bit is 0
                        CMP     byte[Collision],0
                        JNZ     NoCollision
                        MOV     AL,[ES:DI]
                        CMP     AL,0
                        JZ      NoCollision
                        MOV     byte[Collision],AL
NoCollision:            MOV     AL,DH           ; Bit is 1, get color of sprite
                        STOSB                   ; And draw the pixel on the screen
                        JMP     Skip            ; Skip the bit is 0 stuff
BitIsZero:              INC     DI              ; Bit was 0, increment destination register
Skip:                   SHL     BX,1            ; Shift data left for next bit
                        LOOP    DoLine          ; Keep going until no more bits to check
                        ADD     DI,304          ; Increment address to next screen line (320 - 16 bits)
                        DEC     DL              ; Decrease line count
                        JNZ     DrawLines       ; Draw lines until no more lines left to draw

						RET                     ; Done drawing, return to caller


;----------------------------------------------------------------------------------------------------------------------------------
; Erase Sprite
;----------------------------------------------------------------------------------------------------------------------------------

EraseSprite:

                        MOV     SI,AX           ; Setup source pointer to sprite data
                        MOV     AL,DL           ; Get Y position of sprite in AL
                        MOV     AH,0            ; Zero high byte of AX for following shifts
                        SHL     AX,1            ; Calculate Y position * 320 (find address of row)
                        SHL     AX,1            ; Y Position shifted left 6 times + Y Position shifted left 8 times
                        SHL     AX,1
                        SHL     AX,1
                        SHL     AX,1
                        SHL     AX,1
                        MOV     CX,AX
                        SHL     CX,1
                        SHL     CX,1
                        ADD     AX,CX
                        MOV     CX,VideoBuffer  ; Get address of video buffer
                        ADD     AX,CX           ; Add offset to video buffer
                        ADD     AX,BX           ; Add X position to address
                        MOV     DI,AX           ; Store address in destination register
                        MOV     AX,CS           ; Get segment of video memory
                        MOV     ES,AX           ; Store it in destination segment register

                        MOV     DL,7            ; Do 7 lines
                        CLD                     ; Make sure we increment SI and DI
DrawLines2:             LODSW                   ; Get 2 bytes from sprite data (16 bits = 1 line of sprite image)
                        MOV     BX,AX           ; Transfer data to an unused register
                        MOV     CX,16           ; Scan all 16 bits
DoLine2:                TEST    BX,8000h        ; Check left most bit
                        JZ      BitIsZero2      ; Jump if bit is 0
                        MOV     AL,0            ; Bit is 1, get color of sprite
                        STOSB                   ; And draw the pixel on the screen
                        JMP     SkipAA          ; Skip the bit is 0 stuff
BitIsZero2:             INC     DI              ; Bit was 0, increment destination register
SkipAA:                 SHL     BX,1            ; Shift data left for next bit
                        LOOP    DoLine2         ; Keep going until no more bits to check
                        ADD     DI,304          ; Increment address to next screen line (320 - 16 bits)
                        DEC     DL              ; Decrease line count
                        JNZ     DrawLines2      ; Draw lines until no more lines left to draw

						RET                     ; Done drawing, return to caller


;----------------------------------------------------------------------------------------------------------------------------------
; Sprite data
;----------------------------------------------------------------------------------------------------------------------------------

TopInvader1             DW      0c00h,1e00h,2d00h,3f00h,1200h,2100h,1200h
TopInvader2             DW      0c00h,1e00h,2d00h,3f00h,1200h,2100h,4080h

MiddleInvader1          DW      2100h,9e40h,0ad40h,7f80h,3f00h,2100h,4080h
MiddleInvader2          DW      2100h,1e00h,2d00h,7f80h,0bf40h,0a140h,1200h

BottomInvader1          DW      01e00h,7f80h,0ccc0h,0ffc0h,2100h,4c80h,2100h
BottomInvader2          DW      01e00h,7f80h,0ccc0h,0ffc0h,2100h,4c80h,8040h

TwistedMissile1         DW      0000h,0000h,0000h,0800h,0400h,0800h,0400h
TwistedMissile2         DW      0000h,0000h,0000h,0400h,0800h,0400h,0800h

UFO                     DW      0ff0h,0ff0h,0ffffh,0ffffh,0ffffh,7ffeh,3ffch

PlayersShip             DW      0400h,0e00h,7fc0h,0ffe0h,0ffe0h,0ffe0h,0000h

StraightMissile         DW      0000h,0000h,0000h,0400h,0400h,0400h,0400h

BunkerLeftTop           DW      0fffh,1fffh,3fffh,7fffh,0ffffh,0ffffh,0ffffh
BunkerLeftMiddle        DW      0ffffh,0ffffh,0ffffh,0ffffh,0ffffh,0ffffh,0ffffh
BunkerLeftBottom        DW      0ff81h,0fe00h,0fc00h,0f800h,0f800h,0f000h,0000h
BunkerRightTop          DW      0f000h,0f800h,0fc00h,0fe00h,0ff00h,0ff00h,0ff00h
BunkerRightMiddle       DW      0ff00h,0ff00h,0ff00h,0ff00h,0ff00h,0ff00h,0ff00h
BunkerRightBottom       DW      0ff00h,7f00h,3f00h,1f00h,1f00h,0f00h,0000h

SCO                     DW      071c7h,08a28h,08208h,07208h,00a08h,08a28h,071c7h
ORE                     DW      03cf8h,0a280h,0a280h,0bcf0h,0a280h,0a280h,022f8h

HIG                     DW      08be7h,08888h,08888h,0f88bh,08888h,08888h,08be7h
GH                      DW      02200h,0a200h,02200h,0be00h,0a200h,0a200h,02200h

Zero                    DW      3800h,4400h,4c00h,5400h,6400h,4400h,3800h
One                     DW      1000h,3000h,1000h,1000h,1000h,1000h,3800h
Two                     DW      3800h,4400h,0400h,1800h,2000h,4000h,7c00h
Three                   DW      3800h,4400h,0400h,1800h,0400h,4400h,3800h
Four                    DW      4400h,4400h,4400h,7c00h,0400h,0400h,0400h
Five                    DW      7c00h,4000h,4000h,7800h,0400h,4400h,3800h
Six                     DW      3800h,4400h,4000h,7800h,4400h,4400h,3800h
Seven                   DW      7c00h,0400h,0800h,1000h,1000h,1000h,1000h
Eight                   DW      3800h,4400h,4400h,3800h,4400h,4400h,3800h
Nine                    DW      3800h,4400h,4400h,3c00h,0400h,4400h,3800h

Equal                   DW      0000h,0000h,7c00h,0000h,7c00h,0000h,0000h
Period                  DW      0000h,0000h,0000h,0000h,0000h,0000h,1000h
CopyrightSymbol         DW      1e00h,2100h,4c80h,4880h,4c80h,2100h,1e00h

LetterA                 DW      3800h,4400h,4400h,7c00h,4400h,4400h,4400h
LetterB                 DW      7800h,4400h,4400h,7800h,4400h,4400h,7800h
LetterC                 DW      3800h,4400h,4000h,4000h,4000h,4400h,3800h
LetterD                 DW      7800h,4400h,4400h,4400h,4400h,4400h,7800h
LetterE                 DW      7c00h,4000h,4000h,7800h,4000h,4000h,7c00h
LetterF                 DW      7c00h,4000h,4000h,7800h,4000h,4000h,4000h
LetterG                 DW      3800h,4400h,4000h,5c00h,4400h,4400h,3800h
LetterH                 DW      4400h,4400h,4400h,7c00h,4400h,4400h,4400h
LetterI                 DW      7c00h,1000h,1000h,1000h,1000h,1000h,7c00h
LetterJ                 DW      0400h,0400h,0400h,0400h,0400h,4400h,3800h
LetterK                 DW      4400h,4800h,5000h,6000h,5000h,4800h,4400h
LetterL                 DW      4000h,4000h,4000h,4000h,4000h,4000h,7c00h
LetterM                 DW      4400h,6c00h,5400h,4400h,4400h,4400h,4400h
LetterN                 DW      4400h,6400h,5400h,4c00h,4400h,4400h,4400h
LetterO                 DW      3800h,4400h,4400h,4400h,4400h,4400h,3800h
LetterP                 DW      7800h,4400h,4400h,7800h,4000h,4000h,4000h
LetterQ                 DW      3800h,4400h,4400h,4400h,4400h,4c00h,3c00h
LetterR                 DW      7800h,4400h,4400h,7800h,4400h,4400h,4400h
LetterS                 DW      3800h,4400h,4000h,3800h,0400h,4400h,3800h
LetterT                 DW      7c00h,1000h,1000h,1000h,1000h,1000h,1000h
LetterU                 DW      4400h,4400h,4400h,4400h,4400h,4400h,3800h
LetterV                 DW      4400h,4400h,4400h,4400h,4400h,2800h,1000h
LetterW                 DW      4400h,4400h,4400h,4400h,5400h,6c00h,4400h
LetterX                 DW      4400h,4400h,2800h,1000h,2800h,4400h,4400h
LetterY                 DW      4400h,4400h,2800h,1000h,1000h,1000h,1000h
LetterZ                 DW      7c00h,0400h,0800h,1000h,2000h,4000h,7c00h

LogoOutline             DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,007ffh,01800h,02000h,04000h,040ffh,0403fh
                        DW      00000h,0e3ffh,01400h,00c00h,00400h,00607h,0fa03h
                        DW      00000h,0f80fh,00610h,00120h,000a0h,0c0e0h,0c0c1h
                        DW      00000h,0fc00h,00200h,00101h,00102h,00082h,08084h
                        DW      00000h,01fffh,06000h,08000h,00060h,000a0h,0011fh
                        DW      00000h,003ffh,08400h,04800h,04800h,0500fh,0900fh
                        DW      00000h,0ff80h,00040h,00040h,00080h,0ff00h,0c000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h

                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      02000h,01c00h,003fch,00fc3h,0103eh,01000h,00800h
                        DW      0e200h,01900h,00503h,00301h,00281h,00280h,00440h
                        DW      00181h,00682h,0f903h,00100h,00200h,08207h,04408h
                        DW      08044h,04048h,0c028h,00028h,00018h,0e018h,0100ch
                        DW      00100h,00200h,00200h,0047eh,00381h,00001h,00003h
                        DW      02000h,02000h,0403fh,04020h,0803fh,08000h,00000h
                        DW      02000h,02000h,0c000h,00000h,0f000h,00800h,00800h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h

                        DW      00000h,00000h,00000h,01fe0h,02011h,02009h,01009h
                        DW      00000h,00000h,00000h,0fc0fh,00310h,000d0h,00038h
                        DW      00700h,000ffh,00000h,0f1feh,00a01h,00600h,00300h
                        DW      03840h,0c03fh,00000h,00fe0h,01010h,09010h,05010h
                        DW      04408h,083f0h,00000h,07fe0h,08010h,08008h,08004h
                        DW      0100bh,00ff0h,00000h,00fffh,01000h,01000h,01000h
                        DW      0000dh,0fff0h,00000h,0f80fh,00610h,00110h,00090h
                        DW      00000h,0ffffh,00000h,0fff8h,00005h,00005h,0000ah
                        DW      01000h,0e000h,00000h,0ffffh,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,0803fh,060c0h,01100h,00a00h
                        DW      00000h,00000h,00000h,0ff00h,00080h,00040h,00040h

                        DW      01005h,00804h,00802h,00402h,00401h,00201h,00200h
                        DW      00008h,0800ch,08003h,08000h,080c0h,04070h,0c04ch
                        DW      00280h,00140h,00140h,000a0h,00090h,00048h,00044h
                        DW      02809h,02809h,01809h,00c0ah,0040ah,00406h,00206h
                        DW      00002h,00002h,00001h,00600h,00500h,00780h,00000h
                        DW      0100fh,01009h,0100ah,0900ah,0900ah,0500ch,0300ch
                        DW      000a0h,000a0h,000a0h,000a0h,000c0h,000c0h,000c0h
                        DW      03ff2h,03f04h,00084h,00084h,0ff08h,08008h,0ffc8h
                        DW      001c0h,001c0h,00000h,00000h,003c0h,00240h,00440h
                        DW      00a07h,00a07h,03100h,040e0h,0201ch,017e6h,00818h
                        DW      0e040h,09f80h,07000h,00800h,00400h,00400h,00400h

                        DW      00100h,00100h,00080h,0007fh,00000h,00000h,00000h
                        DW      0a023h,06020h,06010h,09fe0h,00000h,00000h,00000h
                        DW      00022h,0c021h,03010h,00fe0h,00000h,00000h,00000h
                        DW      00004h,00004h,0c004h,03ffbh,00000h,00000h,00000h
                        DW      00000h,003e0h,00420h,0f81fh,00000h,00000h,00000h
                        DW      03000h,01000h,01000h,0efffh,00000h,00000h,00000h
                        DW      00140h,00680h,01880h,0e07fh,00000h,00000h,00000h
                        DW      00030h,00030h,00050h,0ff8fh,00000h,00000h,00000h
                        DW      00420h,00410h,00810h,0f00fh,00000h,00000h,00000h
                        DW      00800h,00800h,00c00h,0f3ffh,00000h,00000h,00000h
                        DW      00400h,00800h,07000h,08000h,00000h,00000h,00000h

LogoLetters             DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,007ffh,01fffh,03fffh,03f00h,03fc0h
                        DW      00000h,00000h,0e3ffh,0f3ffh,0fbffh,0f9f8h,001fch
                        DW      00000h,00000h,0f80fh,0fe1fh,0ff1fh,03f3fh,03f3eh
                        DW      00000h,00000h,0fc00h,0fe00h,0fe01h,0ff01h,07f03h
                        DW      00000h,00000h,01fffh,07fffh,0ff9fh,0ff1fh,0fe00h
                        DW      00000h,00000h,003ffh,087ffh,087ffh,08ff0h,00ff0h
                        DW      00000h,00000h,0ff80h,0ff80h,0ff00h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h

                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      01fffh,003ffh,00003h,00000h,00fc1h,00fffh,007ffh
                        DW      001ffh,0e0ffh,0f8fch,0fcfeh,0fc7eh,0fc7fh,0f83fh
                        DW      0fe7eh,0f87ch,000fch,000ffh,001ffh,001f8h,083f0h
                        DW      07f83h,03f87h,03fc7h,0ffc7h,0ffe7h,01fe7h,00ff3h
                        DW      0fe00h,0fc00h,0fc00h,0f800h,0fc7eh,0fffeh,0fffch
                        DW      01fffh,01fffh,03fc0h,03fc0h,07fc0h,07fffh,0ffffh
                        DW      0c000h,0c000h,00000h,00000h,00000h,0f000h,0f000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h

                        DW      00000h,00000h,00000h,00000h,01fe0h,01ff0h,00ff0h
                        DW      00000h,00000h,00000h,00000h,0fc0fh,0ff0fh,0ffc7h
                        DW      000ffh,00000h,00000h,00000h,0f1feh,0f9ffh,0fcffh
                        DW      0c03fh,00000h,00000h,00000h,00fe0h,00fe0h,08fe0h
                        DW      083f0h,00000h,00000h,00000h,07fe0h,07ff0h,07ff8h
                        DW      00ff0h,00000h,00000h,00000h,00fffh,00fffh,00fffh
                        DW      0fff0h,00000h,00000h,00000h,0f80fh,0fe0fh,0ff0fh
                        DW      0ffffh,00000h,00000h,00000h,0fff8h,0fff8h,0fff1h
                        DW      0e000h,00000h,00000h,00000h,0ffffh,0ffffh,0ffffh
                        DW      00000h,00000h,00000h,00000h,0803fh,0e0ffh,0f1ffh
                        DW      00000h,00000h,00000h,00000h,0ff00h,0ff80h,0ff80h

                        DW      00ff8h,007f8h,007fch,003fch,003feh,001feh,001ffh
                        DW      0fff7h,07ff3h,07ffch,07fffh,07f3fh,03f8fh,03f83h
                        DW      0fc7fh,0fe3fh,0fe3fh,0ff1fh,0ff0fh,0ff87h,0ff83h
                        DW      0c7f0h,0c7f0h,0e7f0h,0f3f1h,0fbf1h,0fbf9h,0fdf9h
                        DW      0fffch,0fffch,0fffeh,0f9ffh,0f8ffh,0f87fh,0ffffh
                        DW      00ff0h,00ff0h,00ff1h,00ff1h,00ff1h,08ff3h,0cff3h
                        DW      0ff1fh,0ff1fh,0ff1fh,0ff1fh,0ff3fh,0ff3fh,0ff3fh
                        DW      0c001h,0c003h,0ff03h,0ff03h,00007h,00007h,00007h
                        DW      0fe3fh,0fe3fh,0ffffh,0ffffh,0fc3fh,0fc3fh,0f83fh
                        DW      0f1f8h,0f1f8h,0c0ffh,0801fh,0c003h,0e001h,0f7e7h
                        DW      01f80h,00000h,08000h,0f000h,0f800h,0f800h,0f800h

                        DW      000ffh,000ffh,0007fh,00000h,00000h,00000h,00000h
                        DW      01fc0h,09fc0h,09fe0h,00000h,00000h,00000h,00000h
                        DW      0ffc1h,03fc0h,00fe0h,00000h,00000h,00000h,00000h
                        DW      0fffbh,0fffbh,03ffbh,00000h,00000h,00000h,00000h
                        DW      0ffffh,0f81fh,0f81fh,00000h,00000h,00000h,00000h
                        DW      0cfffh,0efffh,0efffh,00000h,00000h,00000h,00000h
                        DW      0fe3fh,0f87fh,0e07fh,00000h,00000h,00000h,00000h
                        DW      0ffcfh,0ffcfh,0ff8fh,00000h,00000h,00000h,00000h
                        DW      0f81fh,0f80fh,0f00fh,00000h,00000h,00000h,00000h
                        DW      0f7ffh,0f7ffh,0f3ffh,00000h,00000h,00000h,00000h
                        DW      0f800h,0f000h,08000h,00000h,00000h,00000h,00000h

LogoShadow              DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      01fffh,07800h,0e000h,0c000h,08000h,00000h,00000h
                        DW      087ffh,00400h,00000h,00000h,00000h,00000h,00000h
                        DW      0f00fh,00410h,00000h,00000h,00000h,00000h,00000h
                        DW      0fc00h,00200h,00000h,00000h,00000h,00000h,00000h
                        DW      00fffh,02000h,08000h,00000h,00000h,00000h,00000h
                        DW      080ffh,0c000h,04000h,00000h,00000h,00000h,00000h
                        DW      0ffe0h,00060h,00000h,00000h,00000h,00000h,03000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h

                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,03c00h,0303ch,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00001h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,08000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,0003fh,00381h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,0001fh,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,0fc00h,00c00h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h

                        DW      00000h,00000h,0ff03h,0e003h,04002h,04002h,02000h
                        DW      00000h,00000h,0f03fh,00030h,00000h,00000h,00000h
                        DW      00000h,00000h,0c3fch,00200h,00000h,00000h,00000h
                        DW      00000h,00000h,01fc0h,01000h,00000h,00000h,00000h
                        DW      00000h,00000h,07fe0h,00010h,00008h,00004h,00000h
                        DW      00000h,00000h,00fffh,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,0f807h,00600h,00100h,00000h,00000h
                        DW      00000h,00000h,0fffch,00004h,00000h,00000h,00000h
                        DW      00000h,00000h,03fffh,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,0e007h,07800h,01c00h,00c00h,00400h
                        DW      00000h,00000h,0ffe0h,000f0h,00070h,00030h,00000h

                        DW      02000h,01001h,01001h,00800h,00800h,00400h,00400h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00001h,00000h,00000h,00200h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,04000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00080h,00000h,00000h,00000h,07fe0h,00020h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00200h
                        DW      00000h,00000h,00000h,03800h,01ce0h,00818h,00000h
                        DW      00000h,06000h,00f00h,00700h,00300h,00300h,00200h

                        DW      00200h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      04000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h
                        DW      00000h,00000h,00000h,00000h,00000h,00000h,00000h

;----------------------------------------------------------------------------------------------------------------------------------
; Variables
;----------------------------------------------------------------------------------------------------------------------------------

PauseCounter            DB      0
GameStart               DB      0
Frame                   DB      0
InvadersX               DW      275
InvadersY               DB      30
InvadersToggle          DW      07ff0h,07ff0h,07ff0h,07ff0h,07ff0h
PlayerX                 DW      154
LeftToggle              DB      0
RightToggle             DB      0
FireToggle              DB      0
ExitToggle              DB      0
SoundToggle             DB      0
KeyPress                DB      0
Sound                   DB      080h
NextLevelToggle         DB      0
MissileX                DW      0
MissileY                DB      0
UFOX                    DW      0
BombX                   DW      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
BombY                   DB      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
BombType                DB      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
BombFreq                DW      010h
MoveCount               DB      1
InvaderSpeed            DB      55
Direction               DB      0
Reversing               DB      0
Collision               DB      0
Score                   DB      48,48,48,48,48
HighS                   DB      48,48,48,48,48
FirstFrame              DB      0
Lives                   DB      48
BombMove                DB      2
BombSpeed               DB      2
PlayerDead              DB      0
GameOverToggle          DB      0
InvadersTitle           DB      "S  P  A  C  E     I  N  V  A  D  E  R  S",0
Copyright               DB      "COPYRIGHT (  1995 BY PAUL S REID. ALL RIGHTS RESERVED",0
UFOScore                DB      "=   100 POINTS",0
Row1Score               DB      "=    25 POINTS",0
Row2Score               DB      "=    20 POINTS",0
Row3Score               DB      "=    15 POINTS",0
Row4Score               DB      "=    10 POINTS",0
Row5Score               DB      "=     5 POINTS",0
StartDocs               DB      "ANY KEY TO START GAME. ESC AT ANY TIME TO EXIT TO DOS",0
Dedication              DB      "...DEDICATED TO MY WIFE DEB...",0
ThankYou                DB      "THANKS TO BRENT KYLE AND TOM SWAN",0
SoundTog                DB      "PRESS S TO TOGGLE SOUND AT ANY TIME",0
PlayKeys                DB      "LEFT AND RIGHT CURSOR TO MOVE. CTRL TO FIRE",0
Distribution            DB      ".THIS GAME AND SOURCE CODE ARE FREELY DISTRIBUTABLE.",0
GameOverMsg             DB      "G  A  M  E      O  V  E  R",0
GetReady                DB      "G  E  T      R  E  A  D  Y",0
TempStore               DW      0
Palette                 DB      00,00,00    ; Background
                        DB      21,63,63    ; Player's Ship
                        DB      63,21,21    ; Bunker
                        DB      63,21,21    ; UFO
                        DB      63,63,63    ; Missiles
                        DB      21,63,21    ; Status Letters
                        DB      63,63,00    ; Bombs
                        DB      63,63,63    ; DOS text (just for diagnostic printing if required)
                        DB      12,00,21    ; Top and bottom border backgrounds
                        DB      33,00,42    ; Logo shadow color
                        DB      00,00,00    ; Logo outline color
                        DB      63,63,00    ; Logo letters color
                        DB      41,41,41    ; Logo stars
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      21,63,21    ; Row 1 invader 1
                        DB      21,63,21    ; Row 1 invader 2
                        DB      21,63,21    ; Row 1 invader 3
                        DB      21,63,21    ; Row 1 invader 4
                        DB      21,63,21    ; Row 1 invader 5
                        DB      21,63,21    ; Row 1 invader 6
                        DB      21,63,21    ; Row 1 invader 7
                        DB      21,63,21    ; Row 1 invader 8
                        DB      21,63,21    ; Row 1 invader 9
                        DB      21,63,21    ; Row 1 invader 10
                        DB      21,63,21    ; Row 1 invader 11
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      21,63,21    ; Row 2 invader 1
                        DB      21,63,21    ; Row 2 invader 2
                        DB      21,63,21    ; Row 2 invader 3
                        DB      21,63,21    ; Row 2 invader 4
                        DB      21,63,21    ; Row 2 invader 5
                        DB      21,63,21    ; Row 2 invader 6
                        DB      21,63,21    ; Row 2 invader 7
                        DB      21,63,21    ; Row 2 invader 8
                        DB      21,63,21    ; Row 2 invader 9
                        DB      21,63,21    ; Row 2 invader 10
                        DB      21,63,21    ; Row 2 invader 11
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      21,63,63    ; Row 3 invader 1
                        DB      21,63,63    ; Row 3 invader 2
                        DB      21,63,63    ; Row 3 invader 3
                        DB      21,63,63    ; Row 3 invader 4
                        DB      21,63,63    ; Row 3 invader 5
                        DB      21,63,63    ; Row 3 invader 6
                        DB      21,63,63    ; Row 3 invader 7
                        DB      21,63,63    ; Row 3 invader 8
                        DB      21,63,63    ; Row 3 invader 9
                        DB      21,63,63    ; Row 3 invader 10
                        DB      21,63,63    ; Row 3 invader 11
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      21,63,63    ; Row 4 invader 1
                        DB      21,63,63    ; Row 4 invader 2
                        DB      21,63,63    ; Row 4 invader 3
                        DB      21,63,63    ; Row 4 invader 4
                        DB      21,63,63    ; Row 4 invader 5
                        DB      21,63,63    ; Row 4 invader 6
                        DB      21,63,63    ; Row 4 invader 7
                        DB      21,63,63    ; Row 4 invader 8
                        DB      21,63,63    ; Row 4 invader 9
                        DB      21,63,63    ; Row 4 invader 10
                        DB      21,63,63    ; Row 4 invader 11
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      00,00,00
                        DB      63,21,63    ; Row 5 invader 1
                        DB      63,21,63    ; Row 5 invader 2
                        DB      63,21,63    ; Row 5 invader 3
                        DB      63,21,63    ; Row 5 invader 4
                        DB      63,21,63    ; Row 5 invader 5
                        DB      63,21,63    ; Row 5 invader 6
                        DB      63,21,63    ; Row 5 invader 7
                        DB      63,21,63    ; Row 5 invader 8
                        DB      63,21,63    ; Row 5 invader 9
                        DB      63,21,63    ; Row 5 invader 10
                        DB      63,21,63    ; Row 5 invader 11

VideoBuffer             DB      0
