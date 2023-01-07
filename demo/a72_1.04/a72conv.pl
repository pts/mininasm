use integer;
use strict;
BEGIN { $^W = 1 }
print "; Source file autoconverted from a72 to NASM syntax.\n";
print "; Compile: nasm -O9 -f bin -o prog.com prog.asm\n\n";
print "bits 16\ncpu 8086\norg 100h\n";
my $is_bss = 0;
while (<STDIN>) {
  s@\r+@@g;
  if (!$is_bss and (m@(?:\A|\s)d[bw]\s[?]@i or m@(?:\A|\s)ds\s@i)) {
    $is_bss = 1;
    print "absolute \$\n";
  }
  if (s@\A((?:\w+\s+)?)ds(?=\s)@${1}resb@i) {
  } elsif (s@\A((?:\w+\s+)?)d([bw])\s([\s?,]+)$@ my $a3 = $3; my $c = ($a3 =~ y/?//) << (lc($2) eq "w"); "${1}resb $c\n" @ie) {
  } elsif (!m@[\x27"]@) {
    s@\boffset\b@@gi;
    s@\bptr\b@@gi;
    s@\beven\b@align 2@i;
    s@\b(REL|MM0|INVD)\b@\$$1@g;  # Keywords in NASM.
    if (1) {  # To make NASM output bitwise identical to A72 output.
      s@\bjmp\s+(PARAM|G5)\b@jmp strict near $1@i;  # Only when compiling A72.
      s@\b(adc|add|and|sub|cmp|or|sbb|sub|xor)\s+ax,\s*(?=([abcd]x|[bs]p|[sd]i)|[^\[])@ defined($2) ? "$1 ax, " : "$1 ax, strict word " @ie;
      s@\badd\s+ah,\s*al\b@dw 0xe002  ; A72 add ah,al@i;
      s@\badd\s+ax,\s*dx\b@dw 0xc203  ; A72 add ax,dx@i;
      s@\badd\s+dx,\s*ax\b@dw 0xd003  ; A72 add dx,ax@i;
      s@\badd\s+dx,\s*cx\b@dw 0xd103  ; A72 add dx,cx@i;
      s@\badd\s+bp,\s*ax\b@dw 0xe803  ; A72 add bp,ax@i;
      s@\badd\s+si,\s*cx\b@dw 0xf103  ; A72 add si,cx@i;
      s@\badd\s+si,\s*dx\b@dw 0xf203  ; A72 add si,dx@i;
      s@\badd\s+si,\s*bx\b@dw 0xf303  ; A72 add si,bx@i;
      s@\badd\s+di,\s*ax\b@dw 0xf803  ; A72 add di,ax@i;
      s@\badd\s+di,\s*cx\b@dw 0xf903  ; A72 add di,cx@i;
      s@\bor\s+al,\s*ah\b@dw 0xc40a  ; A72 or al,ah@i;
      s@\bor\s+dl,\s*al\b@dw 0xd00a  ; A72 or dl,al@i;
      s@\bor\s+ah,\s*ah\b@dw 0xe40a  ; A72 or ah,ah@i;
      s@\bor\s+ch,\s*cl\b@dw 0xe90a  ; A72 or ch,cl@i;
      s@\bsub\s+al,\s*cl\b@dw 0xc12a  ; A72 sub al,cl@i;
      s@\bsub\s+cl,\s*ah\b@dw 0xcc2a  ; A72 sub cl,ah@i;
      s@\bsub\s+ax,\s*cx\b@dw 0xc12b  ; A72 sub ax,cx@i;
      s@\bsub\s+ax,\s*bp\b@dw 0xc52b  ; A72 sub ax,bp@i;
      s@\bsub\s+ax,\s*di\b@dw 0xc72b  ; A72 sub ax,di@i;
      s@\bsub\s+cx,\s*ax\b@dw 0xc82b  ; A72 sub cx,ax@i;
      s@\bsub\s+cx,\s*dx\b@dw 0xca2b  ; A72 sub cx,dx@i;
      s@\bsub\s+cx,\s*bp\b@dw 0xcd2b  ; A72 sub cx,bp@i;
      s@\bsub\s+cx,\s*si\b@dw 0xce2b  ; A72 sub cx,si@i;
      s@\bsub\s+bp,\s*cx\b@dw 0xe92b  ; A72 sub bp,cx@i;
      s@\bsub\s+bp,\s*bx\b@dw 0xeb2b  ; A72 sub bp,bx@i;
      s@\bsub\s+di,\s*cx\b@dw 0xf92b  ; A72 sub di,cx@i;
      s@\bxor\s+al,\s*al\b@dw 0xc032  ; A72 xor al,al@i;
      s@\bxor\s+cl,\s*cl\b@dw 0xc932  ; A72 xor cl,cl@i;
      s@\bxor\s+dl,\s*dl\b@dw 0xd232  ; A72 xor dl,dl@i;
      s@\bxor\s+ah,\s*ah\b@dw 0xe432  ; A72 xor ah,ah@i;
      s@\bxor\s+ch,\s*ch\b@dw 0xed32  ; A72 xor ch,ch@i;
      s@\bxor\s+ax,\s*ax\b@dw 0xc033  ; A72 xor ax,ax@i;
      s@\bxor\s+cx,\s*cx\b@dw 0xc933  ; A72 xor cx,cx@i;
      s@\bxor\s+dx,\s*dx\b@dw 0xd233  ; A72 xor dx,dx@i;
      s@\bxor\s+bx,\s*bx\b@dw 0xdb33  ; A72 xor bx,bx@i;
      s@\bcmp\s+al,\s*ah\b@dw 0xc43a  ; A72 cmp al,ah@i;
      s@\bcmp\s+cl,\s*bl\b@dw 0xcb3a  ; A72 cmp cl,bl@i;
      s@\bcmp\s+ax,\s*cx\b@dw 0xc13b  ; A72 cmp ax,cx@i;
      s@\bcmp\s+cx,\s*bp\b@dw 0xcd3b  ; A72 cmp cx,bp@i;
      s@\bcmp\s+bp,\s*si\b@dw 0xee3b  ; A72 cmp bp,si@i;
      s@\btest\s+cl,\s*ch\b@dw 0xe984  ; A72 test cl,ch@i;
      s@\btest\s+ch,\s*cl\b@dw 0xe984  ; A72 test ch,cl@i;
      s@\bmov\s+al,\s*dl\b@dw 0xc28a  ; A72 mov al,dl@i;
      s@\bmov\s+al,\s*bl\b@dw 0xc38a  ; A72 mov al,bl@i;
      s@\bmov\s+al,\s*ah\b@dw 0xc48a  ; A72 mov al,ah@i;
      s@\bmov\s+al,\s*ch\b@dw 0xc58a  ; A72 mov al,ch@i;
      s@\bmov\s+ah,\s*al\b@dw 0xe08a  ; A72 mov ah,al@i;
      s@\bmov\s+ax,\s*dx\b@dw 0xc28b  ; A72 mov ax,dx@i;
      s@\bmov\s+ax,\s*si\b@dw 0xc68b  ; A72 mov ax,si@i;
      s@\bmov\s+ax,\s*di\b@dw 0xc78b  ; A72 mov ax,di@i;
      s@\bmov\s+cx,\s*ax\b@dw 0xc88b  ; A72 mov cx,ax@i;
      s@\bmov\s+cx,\s*dx\b@dw 0xca8b  ; A72 mov cx,dx@i;
      s@\bmov\s+cx,\s*bx\b@dw 0xcb8b  ; A72 mov cx,bx@i;
      s@\bmov\s+cx,\s*bp\b@dw 0xcd8b  ; A72 mov cx,bp@i;
      s@\bmov\s+cx,\s*di\b@dw 0xcf8b  ; A72 mov cx,di@i;
      s@\bmov\s+dx,\s*si\b@dw 0xd68b  ; A72 mov dx,si@i;
      s@\bmov\s+bx,\s*ax\b@dw 0xd88b  ; A72 mov bx,ax@i;
      s@\bmov\s+bp,\s*ax\b@dw 0xe88b  ; A72 mov bp,ax@i;
      s@\bmov\s+bp,\s*si\b@dw 0xee8b  ; A72 mov bp,si@i;
      s@\bmov\s+bp,\s*di\b@dw 0xef8b  ; A72 mov bp,di@i;
      s@\bmov\s+si,\s*ax\b@dw 0xf08b  ; A72 mov si,ax@i;
      s@\bmov\s+si,\s*dx\b@dw 0xf28b  ; A72 mov si,dx@i;
      s@\bmov\s+si,\s*bx\b@dw 0xf38b  ; A72 mov si,bx@i;
      s@\bmov\s+si,\s*bp\b@dw 0xf58b  ; A72 mov si,bp@i;
      s@\bmov\s+si,\s*di\b@dw 0xf78b  ; A72 mov si,di@i;
      s@\bmov\s+di,\s*dx\b@dw 0xfa8b  ; A72 mov di,dx@i;
      s@\bmov\s+di,\s*bp\b@dw 0xfd8b  ; A72 mov di,bp@i;
   }
  }
  print;
}
