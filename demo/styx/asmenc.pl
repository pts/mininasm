# perl -p asmenc.pl styx.nasm
if (!m@  ; A86 @) {
  s@\bXOR AX,AX\b@dw 0xc033  ; A86 XOR AX,AX@;
  s@\bMOV AX,DI\b@dw 0xc78b  ; A86 MOV AX,DI@;
  s@\bADD DX,AX\b@dw 0xd003  ; A86 ADD DX,AX@;
  s@\bMOV SP,BX\b@dw 0xe38b  ; A86 MOV SP,BX@;
  s@\bMOV SP,BP\b@dw 0xe58b  ; A86 MOV SP,BP@;
  s@\bMOV BP,SP\b@dw 0xec8b  ; A86 MOV BP,SP@;
  s@\bXOR CH,CH\b@dw 0xed32  ; A86 XOR CH,CH@;
  s@\bXOR SI,SI\b@dw 0xf633  ; A86 XOR SI,SI@;
  s@\bMOV DI,DX\b@dw 0xfa8b  ; A86 MOV DI,DX@;
  s@\bMOV DI,SP\b@dw 0xfc8b  ; A86 MOV DI,SP@;
  s@\bXOR DI,DI\b@dw 0xff33  ; A86 XOR DI,DI@;
}
