#! /bin/sh --
#
# build_minnasm.sh: creates minnnasm2.nasm from mininasm.c etc.
# by pts@fazekas.hu at Thu Dec 15 22:22:04 CET 2022
#
# The created minnnasm2.nasm can be compiled by NASM and mininasm, and the
# executable program will be identical to mininasm.com.
#
# The created minnnasm2.nasm has all the comments, except for the comments
# in the const, const2, data and bss sections.
#
set -ex

# For inlining bbprintf.c and bbprintf.h, otherwise `wdis -s' won't display
# the source code of these files.
perl -0777 -pe '
    1 while s`^[ \t]*#[ \t]*include "([^\r\n\"]+)"[ \t\r]*\n`
      my $fn = $1;
      print STDERR "info: including: $fn\n";
      my $fh;
      die if !open($fh, "<", $fn);
      my $str = join("", <$fh>);
      $str =~ s@\s+\Z(?!\n)@@;
      qq(\n/* Start of #include "$fn" */\n\n$str\n\n/* End of #include "$fn" */\n\n)
    `mge;
    ' <mininasm.c >minnnasm.c

if type dosmc >/dev/null 2>&1; then
  DOSMC=dosmc
else
  DOSMC="$HOME/prg/dosmc/dosmc"
fi


"$DOSMC" -mt -cpn -fm=minnnasm.map minnnasm.c  # Linking to minnnasm.com succeeds.
rm -f minnnasm.com
"$DOSMC" -mt -c -d1 minnnasm.c  # Creates minnnasm.obj, linking won't succeed because of debug symbols.
wdis -s -a -fi '-i=@' minnnasm.obj >minnnasm.wasm
rm -f minnnasm.c minnnasm.obj

# Convert from .wasm to .nasm assembly syntax.
# !! Convert db hex to db 'literal': perl -pe 's@([0-9a-f]+)H@ my $o = hex($1); ($o >= 32 and $o <= 126 and $o != 0x27) ? "\x27" . chr($o) . "\x27" : $o @ge; s@\x27, \x27@@g'
# Conversion of the _TEXT segment (output after ___section_mininasm_c_text: in minnnasm.nasm) is now fully automatic:
set +x
export PERL_CODE='
    use integer; use strict; BEGIN { $^W = 1 }

    # Copy over the initial comments.
    { my $fh;
      die "fatal: open minnnasm.nasm: $!\n" if !open($fh, "<", "minnnasm.nasm");
      while (<$fh>) {
        last if !m@^;@;
        y@\r@@d;
        print;
      }
      close($fh);
    }

print q~
		bits 16
		cpu 8086
		org 0x100  ; DOS .com file is loaded at CS:0x100.

; --- Startup code.
;
; Code in this section was written directly in WASM assmebly, and manually
; converted to NASM assembly.
;
; Based on https://github.com/pts/dosmc/blob/f716c6cd9ec8947e72f1f7ad7c746d8c5d28acc4/dosmc.dir/dosmc.pl#L1141-L1187
___section_startup_text:

___stack_size	equ 0x140  ; To estimate, specify -sc to dosmc (mininasm.c), and run it to get the `max st:HHHH'\'' value printed, and round up 0xHHHH to here. Typical value: 0x200.

_start:  ; Entry point of the DOS .com program.
		cld
		mov sp, ___initial_sp
		mov di, ___section_mininasm_c_bss
		mov cx, (___section_startup_ubss-___section_mininasm_c_bss+1)>>1
		xor ax, ax
		rep stosw
		mov di, argv_bytes
		mov bp, argv_pointers
		push bp
		push es
		lds si, [0x2c-2]  ; Environment segment within PSP.
		
		xor si, si
		lodsb
.next_entry:	test al, al
		jz .end_entries
.next_char:	test al, al
		lodsb
		jnz .next_char
		jmp short .next_entry
.end_entries:	inc si  ; Skip over a single byte.
		inc si  ; Skip over '\''\0'\''.
		; Now ds:si points to the program name as an uppercase, absolute pathname with extension (e.g. .EXE or .COM). We will use it as argv.
		
		; Copy program name to argv[0].
		mov [bp], di  ; argv[0] pointer.
		inc bp
		inc bp
		mov cx, 144  ; To avoid overflowing argv_bytes. See above why 144.
.next_copy:	dec cx
		jnz .argv0_limit_not_reached
		xor al, al
		stosb
		jmp short .after_copy
.argv0_limit_not_reached:
		lodsb
		stosb
		test al, al
		jnz .next_copy
.after_copy:
		
		; Now copy cmdline.
		pop ds  ; PSP.
		mov si, 0x80  ; Command-line size byte within PSP, usually space. 0..127, we trust it.
		lodsb
		xor ah, ah
		xchg bx, ax  ; bx := ax.
		mov byte [si+bx], 0
.scan_for_arg:	lodsb
		test al, al
		jz .after_cmdline
		cmp al, '\'' '\''
		je .scan_for_arg
		cmp al, 9  ; Tab.
		je .scan_for_arg
		mov [bp], di  ; Start new argv[...] element. Uses ss by default, good.
		inc bp
		inc bp
		stosb  ; First byte of argv[...].
.next_argv_byte:
		lodsb
		stosb
		test al, al
		jz .after_cmdline
		cmp al, '\'' '\''
		je .end_arg
		cmp al, 9  ; Tab.
		jne .next_argv_byte
.end_arg:	dec di
		xor al, al
		stosb  ; Replace whitespace with terminating '\''\0'\''.
		jmp short .scan_for_arg
		
.after_cmdline:	mov word [bp], 0  ; NULL at the end of argv.
		pop dx  ; argv_pointers. Final return value of dx.
		sub bp, dx
		xchg ax, bp  ; ax := bp.
		shr ax, 1  ; Set ax to argc, it'\''s final return value.
		call main_
		mov ah, 0x4c  ; dx: argv=NULL; EXIT, exit code in al
		int 0x21
		; This line is not reached.

; --- Main program code (from mininasm.c, bbprintf.h and bbprintf.c).
;
; Code in this section was written in C, compiled by wcc using dosmc,
; disassembled using `wdis -s -a'\'' and autoconverted from WASM to NASM
; syntax.
___section_mininasm_c_text:
~;
    my $is_text_segment = 0;
    while (<STDIN>) {
      if ($is_text_segment) {
        if (m@^\S+\t+ENDS\r?$@) { $is_text_segment = 0; last; }  # Extract _TEXT segment only.
        next if m@^\t*ASSUME\s@;
        s@[\r\n]+@@;
        my $comment = (s@(\s*;.*)@@ ? $1 : "");
        s@^\t(xchg|test)\t\t([a-z]{2}),([a-z]{2})$@\t$1\t\t$3,$2@;  # Swap register arguments of test and xchg, because wcc/wasm/wdis and nasm/ndisasm disagree on the order.
        #s@^\t(xchg|test)\t\t([^,]+),([a-z]{2}|(?![0-9a-f]+H?)[^,]+)$@\t$1\t\t$3,$2@;  # Swap r/r and r/m arguments of test and xchg. Not needed for r/m, the order of that does not matter.
        # Change e.g. (add ax, 0xffd4) to (add ax, -0x2c) as a workaround for optimizing to byte form by NASM 0.98.39 and NASM 0.99.06 with -O9.
        s@^\t(add|or|adc|sbb|and|sub|xor|cmp)\t\tax,([0-9][0-9a-f]*)H$@ my $i = hex($2); my $r2 = (($i >= 0xff80 and $i <= 0xffff) ? sprintf("-0%x", 0x10000 - $i) : $2); "\t$1\t\tax,${r2}H" @e;
        s@\bDGROUP:(?=\w|\@\$)@@g;
        s@\b([cdes]s:)\[@\[$1@g;
        if (m@ptr @ and !m@\bnear +ptr +@) {
          s@\bptr +((?:\@+\$+)?[.\w]+(?:[+][.\w]+)?)@[$1]@g;
        }
        s@\bptr\b *@@g;
        s@\boffset\b *@@g;
        s@\bles(\s+)(ax|bx|cx|dx|si|di|bp|sp),dword *\[@les$1$2,\[@;
        s@\b0([0-9a-f]*)H@0x$1@g;
        s@\b([1-9][0-9a-f]*)H@0x$1@g;
        s@^\t([a-z]+)\t+@\t\t$1 @;
        s@^\t([a-z]+)@\t\t$1@;
        s@,(?! )@, @ if m@^\t@;
        s@^[ \t]*(d[bwd])[ \t]+@\t\t\L$1 @i;
        print "$_$comment\n";
      } else {
        $is_text_segment = 1 if m@^_TEXT\t+SEGMENT\s@;
      }
    }
    
    print q`
; --- C library functions based on https://github.com/pts/dosmc/tree/master/dosmclib
;
; Code in this section was written directly in WASM assmebly, and manually
; converted to NASM assembly.
___section_libc_text:

`;
   my %libc = ("close_" => q#
; int close(int fd);
; Optimized for size. AX == fd.
; for Unix compatibility.
close_:		push bx
		xchg ax, bx		; BX := fd; AX := junk.
		mov ah, 0x3e
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		pop bx
		ret
#, "creat_" => q#
; int creat(const char *pathname, int mode);
; Optimized for size. AX == pathname, DX == mode.
; The value O_CREAT | O_TRUNC | O_WRONLY is used as flags.
; mode is ignored, except for bit 8 (read-only). Recommended value: 0644,
; for Unix compatibility.
creat_:		push cx
		xchg ax, dx		; DX := pathname; AX := mode.
		xor cx, cx
		test ah, 1
		jz .1
		inc cx			; CX := 1 means read-only.
.1:		mov ah, 0x3c
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		pop cx
		ret
#, "__I4D" => q#
; Implements `(long a) / (long b)'\'' and also computes the
; modulo (%).
;
; Implementation copied from
; open-watcom-2_0-c-linux-x86-2022-05-01/lib286/dos/clibs.lib:i4d.o
__I4D:		or dx, dx
		js .1
		or cx, cx
		js .0
		jmp __U4D
.0:		neg cx
		neg bx
		sbb cx, byte 0
		call __U4D
		neg dx
		neg ax
		sbb dx, byte 0
		ret
.1:		neg dx
		neg ax
		sbb dx, byte 0
		or cx, cx
		jns .2
		neg cx
		neg bx
		sbb cx, byte 0
		call __U4D
		neg cx
		neg bx
		sbb cx, byte 0
		ret
.2:		call __U4D
		neg cx
		neg bx
		sbb cx, byte 0
		neg dx
		neg ax
		sbb dx, byte 0
		ret
#, "__U4M" => q#
; Implements `(unsigned long a) * (unsigned long b)'\'' and `(long)a * (long b)'\''.
;
; Implementation copied from
; open-watcom-2_0-c-linux-x86-2022-05-01/lib286/dos/clibs.lib:i4m.o
__U4M:
__I4M:		xchg ax, bx
		push ax
		xchg ax, dx
		or ax, ax
		je .1
		mul dx
.1:		xchg ax, cx
		or ax, ax
		je .2
		mul bx
		add cx, ax
.2:		pop ax
		mul bx
		add dx, cx
		ret
#, "isalpha_" => q#
; int isalpha(int c);
; Optimized for size.
isalpha_:	or al, 32		; Covert to ASCII uppercase.
		sub al, '\''a'\''
		cmp al, '\''z'\'' - '\''a'\'' + 1
		mov ax, 0
		adc al, 0
		ret
#, "isdigit_" => q#
; int isdigit(int c);
; Optimized for size.
isdigit_:	sub al, '\''0'\''
		cmp al, '\''9'\'' - '\''0'\'' + 1
		mov ax, 0
		adc al, 0
		ret
#, "isspace_" => q#
; int isspace(int c);
; Optimized for size.
isspace_:	sub al, 9
		cmp al, 13 - 9 + 1
		jc .done		; ASCII 9 .. 13 are whitespace.
		sub al, '\'' '\'' - 9		; ASCII '\'' '\'' is whitespace.
		cmp al, 1
.done:		mov ax, 0
		adc al, 0
		ret
#, "isxdigit_" => q#
; int isxdigit(int c);
; Optimized for size.
isxdigit_:	sub al, '\''0'\''
		cmp al, '\''9'\'' - '\''0'\'' + 1
		jc .done
		or al, 32		; Covert to ASCII uppercase.
		sub al, '\''a'\'' - '\''0'\''
		cmp al, '\''f'\'' - '\''a'\'' + 1
.done:		mov ax, 0
		adc al, 0
		ret
#, "lseek_" => q#
; off_t lseek(int fd, off_t offset, int whence);
; Optimized for size. AX == fd, CX:BX == offset, DX == whence.
lseek_:		xchg ax, bx		; BX := fd; AX := low offset.
		xchg ax, dx		; AX := whence; DX := low offset.
		mov ah, 0x42
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
		sbb dx, dx		; DX := -1.
.ok:		ret
#, "open2_" => q#
; int open(const char *pathname, int flags, int mode);
; int open2(const char *pathname, int flags);
; Optimized for size. AX == pathname, DX == flags, BX == mode.
; Unix open(2) is able to create new files (O_CREAT), in DOS please use
; creat() for that.
; mode is ignored. Recommended value: 0644, for Unix compatibility.
open2_:
open_:		xchg ax, dx		; DX := pathname; AX := junk.
		mov ah, 0x3d
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		ret
#, "read_" => q#
; ssize_t read(int fd, void *buf, size_t count);
; Optimized for size. AX == fd, DX == buf, BX == count.
read_:		push cx
		xchg ax, bx		; AX := count; BX := fd.
		xchg ax, cx		; CX := count; AX := junk.
		mov ah, 0x3f
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		pop cx
		ret
#, "unlink_" => q#
; int remove(const char *fn);
; int unlink(const char *fn);
; Optimized for size.
unlink_:
remove_:	xchg dx, ax		; DX := AX, AX := junk.
		mov ah, 0x41
		int 0x21
		sbb ax, ax		; AX := -1 on error (CF), 0 otherwise.
		ret
#, "strcmp_far_" => q#
; int strcmp_far(const char far *s1, const char far *s2);
; Assumes that offset in s1 and s2 doesn'\''t wrap around.
; Optimized for size. DX:AX == s1, CX:BX == s2.
strcmp_far_:	push si
		push ds
		mov ds, dx
		mov es, cx
		xchg si, ax		; SI := s1, AX := junk.
		xor ax, ax
		xchg bx, di
.next:		lodsb
		scasb
		jne .diff
		cmp al, 0
		je .done
		jmp short .next
.diff:		mov al, 1
		jnc .done
		neg ax
.done:		xchg bx, di		; Restore original DI.
		pop ds
		pop si
		ret
#, "strcpy_far_" => q#
; char far *strcpy_far(char far *dest, const char far *src);
; Assumes that offset in dest and src don'\''t wrap around.
; Optimized for size. DX:AX == s1, CX:BX == s2.
strcpy_far_:	push di
		push ds
		mov es, dx
		mov ds, cx
		xchg bx, si
		xchg di, ax		; DI := dest; AX := junk.
		push di
.again:		lodsb
		stosb
		cmp al, 0
		jne .again
		pop ax			; Will return dest.
		xchg bx, si		; Restore SI.
		pop ds
		pop di
		ret
#, "strlen_" => q#
; size_t strlen(const char *s);
; Optimized for size.
strlen_:	push si
		xchg si, ax		; SI := AX, AX := junk.
		mov ax, -1
.again:		cmp byte [si], 1
		inc si
		inc ax
		jnc .again
		pop si
		ret
#, "__U4D" => q#
; Implements `(unsigned long a) / (unsigned long b)'\'' and also computes the
; modulo (%).
;
; Implementation copied from
; open-watcom-2_0-c-linux-x86-2022-05-01/lib286/dos/clibs.lib:i4d.o
__U4D:		or cx, cx
		jne .5
		dec bx
		je .4
		inc bx
		cmp bx, dx
		ja .3
		mov cx, ax
		mov ax, dx
		sub dx, dx
		div bx
		xchg ax, cx
.3:		div bx
		mov bx, dx
		mov dx, cx
		sub cx, cx
.4:		ret
.5:		cmp cx, dx
		jb .7
		jne .6
		cmp bx, ax
		ja .6
		sub ax, bx
		mov bx, ax
		sub cx, cx
		sub dx, dx
		mov ax, 1
		ret
.6:		sub cx, cx
		sub bx, bx
		xchg ax, bx
		xchg cx, dx
		ret
.7:		push bp
		push si
		sub si, si
		mov bp, si
.8:		add bx, bx
		adc cx, cx
		jb .11
		inc bp
		cmp cx, dx
		jb .8
		ja .9
		cmp bx, ax
		jbe .8
.9:		clc
.10:		adc si, si
		dec bp
		js .14
.11:		rcr cx, 1
		rcr bx, 1
		sub ax, bx
		sbb dx, cx
		cmc
		jb .10
.12:		add si, si
		dec bp
		js .13
		shr cx, 1
		rcr bx, 1
		add ax, bx
		adc dx, cx
		jae .12
		jmp short .10
.13:		add ax, bx
		adc dx, cx
.14:		mov bx, ax
		mov cx, dx
		mov ax, si
		xor dx, dx
		pop si
		pop bp
		ret
#, "write_" => q#
; ssize_t write(int fd, const void *buf, size_t count);
; Optimized for size. AX == fd, DX == buf, BX == count.
write_:		push cx
		xchg ax, bx		; AX := count; BX := fd.
		xchg ax, cx		; CX := count; AX := junk.
		mov ah, 0x40
		int 0x21
		jnc .ok
		sbb ax, ax		; AX := -1.
.ok:		pop cx
		ret
#);
    my %donefuncs;
    my %libc_aliases = ("__I4M" => "__U4M", "open_" => "open2_", "remove_" => "unlink_");
    { my $fh;
      die "fatal: open minnnasm.map: $!\n" if !open($fh, "<", "minnnasm.map");
      my $is_enabled = 0;
      while (<$fh>) {
        if (m@^symbol segment=_TEXT symbol=G\$(\S+) @) {
          if ($1 eq "main_") {
            $is_enabled = 1;
          } elsif (!$is_enabled) {
          } elsif (exists($libc{$1})) {
            if (!exists($donefuncs{$1})) {
              print $libc{$1};
              $donefuncs{$1} = 1;
            }
          } elsif (exists($libc_aliases{$1}) and exists($libc{$libc_aliases{$1}})) {
            if (!exists($donefuncs{$libc_aliases{$1}})) {
              print $libc{$libc_aliases{$1}};
              $donefuncs{$libc_aliases{$1}} = 1;
            }
          } else {
            die "fatal: missing libc function: $1\n";
          }
        }
      }
      close($fh);
    }

    my $section;
    my @sdatakeys = qw(const const2 data bss);
    my %sdata = map { $_ => "" } @sdatakeys;
    while (<STDIN>) {
      s@[\r\n]+@@;
      if (m@\A(CONST2?|_DATA|_BSS)[ \t]+SEGMENT[ \t]@) {
        $section = lc($1);
        $section =~ s@\A_+@@;
      } elsif (m@\A\w+[ \t]+ENDS\Z@) {
        $section = undef;
      } elsif (defined($section)) {
        $sdata{$section} .= "$_\n";
      }
    }
    for $section (@sdatakeys) {
      if ($section eq "bss") {
          print q#
; --- Variables initialized to 0 by _start.
___section_nobss_end:
		section .bss align=1
___section_bss:
		;resb (___section_startup_text-___section_nobss_end)&(2-1)  ; Align to multiple of 2. We don'\''t do it.

___section_mininasm_c_bss:
#;
        $_ = $sdata{$section};
        pos($_) = 0;
        my $org = 0;
        my $prev_org = undef;
        my $prev_label;
        while (m@\G    ORG ([0-9][0-9a-fA-F]*[hH]|([0-9]\d*))\n|(\S+)[ \t]+LABEL[ \t]+BYTE\n|(.*)\n?@gc) {
          if (defined($1)) {
            $org = defined($2) ? int($2) : hex(substr($1, 0, -1));
          } elsif (defined($3)) {
            if (defined($prev_label)) {
              die "fatal: consecutive labels\n" if !defined($prev_org);
              my $size = $org - $prev_org;
              print "$prev_label\t\tresb $size\n";
              $prev_org = undef;
            }
            $prev_label = $3; $prev_org = $org;
          } elsif (length($4)) {
            die "fatal: syntax error in bss: $4\n";
          }
        }
        if (defined($prev_label)) {
          die "fatal: consecutive labels\n" if !defined($prev_org);
          my $size = $org - $prev_org;
          print "$prev_label\t\tresb $size\n";
        }
      } else {
        my $split_long_line = sub {
          my($prefix, $instruction, $data) = @_;
          my $result = "$prefix$instruction";
          my $x = length($prefix) + length($instruction) + 1;
          my $comma = " ";
          pos($data) = 0;
          while ($data =~ m@\G((?:\x27[^\x27]*\x27|[^\x27, \t]+)),?[ \t]*@gc) {
            if ($x + length($comma) + length($1) >= 255) {
                $result .= "\n\t\t$instruction $1";
                $x = length($instruction) + length($1) + 3;
            } else {
                $result .= "$comma$1";
                $x += length($comma) + length($1);
            }
            $comma = ", ";
          }
          $result .= "\n";
          $result
          #die "($prefix)--($instruction)--($data)\n";
        };
        print "\n___section_mininasm_c_$section:\n\n";
        $_ = $sdata{$section};
        s@\boffset @@g;
        s@^    DB[ \t]+(.*)@    DB $1,@mg;
        s@,\n    DB @, @g;
        s@([0-9a-f]+)H@ my $o = hex($1); ($o >= 32 and $o <= 126 and $o != 0x27) ? "\x27" . chr($o) . "\x27" : $o @ge; s@\x27, \x27@@g;
        s@,\n@\n@g;
        s@:\n    (D[BWD])[ \t]+@\t\t\L$1 @g;
        s@^    (D[BWD])[ \t]+@\t\t\L$1 @mg;
        s@\s+\Z(?!\n)@\n@;
        s@^((?:\S+[ \t]+)?)(d[bwd])[ \t]+(.{255,})\n@ $split_long_line->($1, $2, $3) @mge;
        # TODO(pts): Split string literals if needed.
        die "fatal: line too long for mininasm: $_\n" if m@^(.{255,})@;
        print;
      }
    }
    print q#
; --- Uninitialized .bss used by _start.    ___section_startup_ubss:
___section_startup_ubss:

argv_bytes	resb 270
argv_pointers	resb 130

___section_ubss_end:

___initial_sp	equ ___section_startup_text+((___section_ubss_end-___section_bss+___section_nobss_end-___section_startup_text+___stack_size+1)&~1)  ; Word-align stack for speed.
___sd_top__	equ 0x10+((___initial_sp-___section_startup_text+0xf)>>4)  ; Round top of stack to next para, use para (16-byte).

; __END__
#;
'
set -x
perl -we 'eval($ENV{PERL_CODE});die$@if$@' <minnnasm.wasm >minnnasm2.nasm
unset PERL_CODE
rm -f minnnasm.wasm

: "$0" OK, created minnnasm2.nasm.
