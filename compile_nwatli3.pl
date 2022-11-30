#!/bin/sh --
eval 'PERL_BADLANG=x;export PERL_BADLANG;exec perl -x "$0" "$@";exit 1'
#!perl  # Start marker used by perl -x.
+0 if 0;eval("\n\n\n\n".<<'__END__');die$@if$@;__END__

#
# complie_nwatli3.pl: compile with OpenWatcom, link smarter to Linux i386 with NASM
# by pts@fazekas.hu at Sat Nov 26 05:24:32 CET 2022
#
#

BEGIN { $^W = 1 }
use integer;
use strict;

# This uses the OpenWatcom linker (wlink), which keeps the symbols, and
# doesn't optimize the section alignment (i.e. it inserts up to 4095 NUL
# bytes between section .text and .data).
#
# owcc -blinux -fnostdlib -Wl,option -Wl,start=_start_ -o mininasm.swatli3 -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm_swatli3.c && sstrip swatli3 && ls -ld mininasm.swatli3
#
# So we aim for something better, with shorter program file output.
#

# --- Merge C string literal by tail (e.g. merge "bar" and "foobar").

# Merge C string literal by tail (e.g. merge "bar" and "foobar").
#
# $outfh is the filehandle to write NASM assembly lines to.
#
# $rodata_strs is a reference to an array containing assembly source lines
# (`label:' and `db: ...') in `section .rodata.str1.1' (GCC, GNU as; already
# converted to db) or `CONST SEGMENT' (OpenWatcom WASM). It will be cleared
# as a side effect.
sub print_merged_strings_in_strdata($$$) {
  my($outfh, $rodata_strs, $is_db_canonical_gnu_as) = @_;
  return if !$rodata_strs or !@$rodata_strs;
  # Test data: my $strdata_test = "foo:\ndb 'ello', 0\ndb 0\ndb 'oth'\nmer:\ndb 'er', 1\ndb 2\ndb 0\ndb 3\ndb 0\ndb 4\ndb 'hell'\nbar:\ndb 'o', 0\nbaz:\ndb 'lo', 0, 'ello', 0, 'hell', 0, 'foo', ', ', 0, 15, 3, 0\nlast:";  @$rodata_strs = split(/\n/, $strdata_test);
  my $ofs = 0;
  my @labels;
  my $strdata = "";
  for my $str (@$rodata_strs) {
    if ($str =~ m@\A\s*db\s@i) {
      pos($str) = 0;
      if ($is_db_canonical_gnu_as) {  # Shortcut.
        while ($str =~ m@\d+|'([^']*)'@g) { $ofs += defined($1) ? length($1) : 1 }
        $strdata .= $str;
        $strdata .= "\n";
      } else {
        die if $str !~ s@\A\s*db\s+@@i;
        my $str0 = $str;
        my $has_error = 0;
        # Parse and canonicalize the db string, so that we can transform it later.
        $str =~ s@(-?)0[xX]([0-9a-fA-F]+)|(-?)([0-9][0-9a-fA-F]*)[hH]|(-?)(0(?!\d)|[1-9][0-9]*)|('[^']*')|(\s*,\s*)|([^\s',]+)@
          my $v;
          if (defined($1) or defined($3) or defined($5)) {
            ++$ofs;
            $v = defined($1) ? ($1 ? -hex($2) : hex($2)) & 255 :
                 defined($3) ? ($3 ? -hex($4) : hex($4)) & 255 :
                 defined($5) ? ($5 ? -int($6) : int($6)) & 255 : undef;
            ($v >= 32 and $v <= 126 and $v != 0x27) ? "'" . chr($v) . "'" : $v
          } elsif (defined($7)) { $ofs += length($6) - 2; $6 }
          elsif (defined($8)) { ", " }
          else { print STDERR "($9)"; $has_error = 1; "" }
        @ge;
        die "fatal: arg: syntax error in string literal db: $str0\n" if $has_error;
        #$str =~ s@', '@@g;  # This is incorrect, e.g. db 1, ', ', 2
        $strdata .= "db $str\n";
      }
    } elsif ($str =~ m@\s*([^\s:,]+)\s*:\s*\Z(?!\n)@) {
      push @labels, [$ofs, $1];
      #print STDERR ";;old: $1 equ strs+$ofs\n";
    } elsif ($str =~ m@\S@) {
      die "fatal: arg: unexpected string literal instruction: $str\n";
    }
  }
  # $strdata already has very strict syntax (because we have generated its
  # dbs), so we can do these regexp substitutions below safely.
  $strdata =~ s@([^:])\ndb @$1, @g;
  $strdata = "db " if !length($strdata);
  die "fatal: assert: missing db" if $strdata !~ m@\Adb@;
  die "fatal: assert: too many dbs" if $strdata =~ m@.db@s;
  $strdata =~ s@^db @db , @mg;
  $strdata =~ s@, 0(?=, )@, 0\ndb @g;  # Split lines on NUL.
  my $ss = 0;
  while (length($strdata) != $ss) {  # Join adjacent 'chars' arguments.
    $ss = length($strdata);
    $strdata =~ s@'([^']*)'(?:, '([^']*)')?@ my $x = defined($2) ? $2 : ""; "'$1$x'" @ge;
  }
  chomp($strdata);
  @$rodata_strs = split(/\n/, $strdata);
  my @sorteds;
  {
    my $i = 0;
    for my $str (@$rodata_strs) {
      my $rstr = reverse($str);
      substr($rstr, -3) = "";  # Remove "db ".
      substr($rstr, 0, 3) = "";  # Remove "0, ".
      $rstr =~ s@' ,\Z@@;
      push @sorteds, [$rstr, $i];
      ++$i;
    }
  }
  @sorteds = sort { $a->[0] cmp $b->[0] or $a->[1] <=> $b->[1] } @sorteds;
  my %mapi;
  for (my $i = 0; $i < $#sorteds; ++$i) {
    my $rstri = $sorteds[$i][0];
    my $rstri1 = $sorteds[$i + 1][0];
    if (length($rstri1) >= length($rstri) and substr($rstri1, 0, length($rstri)) eq $rstri) {
      $mapi{$sorteds[$i][1]} = $sorteds[$i + 1][1];
    }
  }
  my @ofss;
  my @oldofss;
  #%mapi = ();  # For debugging: don't merge anything.
  {
    my $i = 0;
    my $ofs = 0;
    my $oldofs = 0;
    my @sizes;
    for my $str (@$rodata_strs) {
      pos($str) = 0;
      my $size = 0;
      while ($str =~ m@\d+|'([^']*)'@g) { $size += defined($1) ? length($1) : 1 }
      push @sizes, $size;
      push @oldofss, $oldofs;
      $oldofs += $size;
      if (exists($mapi{$i})) {
        my $j = $mapi{$i};
        $j = $mapi{$j} while exists($mapi{$j});
        $mapi{$i} = $j;
        #print STDERR ";$i: ($str) -> ($rodata_strs->[$j]}\n";
        push @ofss, undef;
      } else {
        push @ofss, $ofs;
        $ofs += $size;
        #print STDERR "$str\n";
      }
      ++$i;
    }
    if (%mapi) {
      for ($i = 0; $i < @$rodata_strs; ++$i) {
        my $j = $mapi{$i};
        $ofss[$i] = $ofss[$j] + $sizes[$j] - $sizes[$i] if defined($j) and !defined($ofss[$i]);
      }
    }
    push @ofss, $ofs;
    push @oldofss, $oldofs;
  }
  {
    for my $str (@$rodata_strs) {
      die "fatal: assert: missing db-comma\n" if $str !~ s@\Adb , @db @;  # Modify in place.
      # !! if TODO(pts): length($str) > 500, then split to several `db's.
      $str .= "\n";
    }
    #print $outfh "section .rodata\n";  # Printed by the caller.
    print $outfh "__strs:\n";
    my $i = 0;
    my $pi = 0;
    for my $pair (@labels) {
      my($lofs, $label) = @$pair;
      ++$i while $i + 1 < @oldofss and $oldofss[$i + 1] <= $lofs;
      die "fatal: assert: bad oldoffs\n" if $i >= @oldofss;
      my $ofs = $lofs - $oldofss[$i] + $ofss[$i];
      for (; $pi < $i; ++$pi) {
        #print STDERR "$rodata_strs->[$pi]\n" if !exists($mapi{$pi});
        print $outfh $rodata_strs->[$pi] if !exists($mapi{$pi});
      }
      if ($lofs != $oldofss[$i] or exists($mapi{$i})) {
        if (exists($mapi{$i})) {
          # !! TODO(pts): Find a later, closer label, report relative offset there.
          #print STDERR "$label equ __strs+$ofs  ; old=$lofs\n";
          print $outfh "$label equ __strs+$ofs  ; old=$lofs\n";
        } else {
          my $dofs = $lofs - $oldofss[$i];
          #print $outfh "$label equ \$+$dofs\n";
          print STDERR "$label equ \$+$dofs\n";
        }
      } else {
        #print STDERR "$label:\n";
        print $outfh "$label:\n";
      }
    }
    for (; $pi < @$rodata_strs; ++$pi) {
      #print STDERR "$rodata_strs->[$pi]\n" if !exists($mapi{$pi});
      print $outfh $rodata_strs->[$pi] if !exists($mapi{$pi});
    }
  }
  @$rodata_strs = ();
}

# ---

my @compile_cmd = qw(owcc -blinux -fnostdlib -c -o mininasm.nwatli3.obj -Os -fno-stack-check -march=i386 -W -Wall -Wextra mininasm_swatli3.c);
print STDERR "info: running compile_cmd: @compile_cmd\n";
die "fatal: compile_cmd failed\n" if system(@compile_cmd);

my $disasm_outfn = "mininasm_nwatli3.wasm";
my @disasm_cmd = qw(wdis -a -fi -i=@ mininasm.nwatli3.obj);
print STDERR "info: running disasm_cmd: @disasm_cmd >$disasm_outfn\n";
{
  my $saveout;
  die if !open($saveout, ">&", \*STDOUT);
  die "fatal: open: $disasm_outfn\n: $!" if !open(STDOUT, ">", $disasm_outfn);
  die "fatal: disasm_cmd failed\n" if system(@disasm_cmd);
  die if !open(STDOUT, ">&", $saveout);
  close($saveout);
}

my $nasm_outfn = "mininasm_nwatli3.nasm";
print STDERR "info: converting $disasm_outfn to NASM format: $nasm_outfn\n";
my $wasm_fh;
die "fatal: open: $disasm_outfn: $!\n" if !open($wasm_fh, "<", $disasm_outfn);
my $nasm_fh;
die "fatal: open: $nasm_outfn: $!\n" if !open($nasm_fh, ">", $nasm_outfn);
my $data_alignment = 4;  # Configurable here. =1 is 3 bytes smaller, =4 is faster. TODO(pts): Modify the owcc invocation as well.
print $nasm_fh "; .nasm source generated by $0\n";
print $nasm_fh "%include 'elf.inc.nasm'\n_elf_start 32, Linux, $data_alignment|sect_many|shentsize\n\n";
my $section = ".text";
my $segment = "";
my $bss_org = 0;
my $is_end = 0;
my $do_merge_strings = 1;  # Configurable here.
my $rodata_strs = $do_merge_strings ? [] : undef;
my %segment_to_section = qw(_TEXT .text  CONST .rodata  CONST2 .rodata  _DATA .data  _BSS .bss);
while (<$wasm_fh>) {
  die "fatal: line after end ($.): $_\n" if $is_end;
  y@\r\n@@d;
  my $is_instr = s@^\t(?!\t)@@;  # Assembly instruction.
  s@;.*@@;
  s@^\s+@@;
  s@\s+@ @g;
  if ($is_instr) {
    die "$0: unsupported instruction in non-.text ($.): $_\n" if $section ne ".text";
    if (s~^(jmp|call) near ptr (?:FLAT:)?~$1 \$~) {
    } else {
      s@, *@, @g;
      s@ (byte|word|dword) ptr (?:(\[.*?\])|FLAT:([^,]+))@ " $1 " . (defined($2) ? $2 : "[\$$3]") @ge;
      s@([-+])FLAT:([^,]+)@$1\$$2@g;
      s@ offset FLAT:([^,]+)@ \$$1@g;
    }
    if ($rodata_strs and $segment eq "CONST") {  # C string literals.
      push @$rodata_strs, $_;
    } else {
      print $nasm_fh "$_\n";
    }
  } elsif (m@^[.]@) {
    if ($_ eq ".387" or $_ eq ".model flat") {  # Ignore.
    } elsif (m@^[.]386@) {
      print $nasm_fh "cpu 386\n";
    } else {
      die "fatal: unsupported WASM directive: $_\n" ;
    }
  } elsif (m@^[^\s:\[\],+\-*/]+:$@) {  # Label.  TODO(pts): Convert all labels, e.g. eax to $eax.
    if ($rodata_strs and $segment eq "CONST") {
      push @$rodata_strs, "\$$_";
    } else {
      print $nasm_fh "_start:\n" if $_ eq "_start_:";  # Add extra start label for entry point.
      print $nasm_fh "\$$_\n";
    }
  } elsif (s@^(D[BWD])(?= )@@) {
    my $cmd = lc($1);
    s@\boffset FLAT:@\$@g if !m@'@;
    if ($rodata_strs and $segment eq "CONST") {  # C string literals.
      push @$rodata_strs, $cmd . $_;
    } else {
      print $nasm_fh "$cmd$_\n";
    }
  } elsif (m@^(_TEXT|CONST2?|_DATA|_BSS) SEGMENT @) {
    $segment = $1;
    $section = $segment_to_section{$segment};
    print $nasm_fh "\nsection $section  ; $segment\n";
  } elsif (m@^(\S+) ENDS$@) {
    die "fatal: unexpected segment end: $1\n" if $1 ne $segment;
  } elsif (m@^ORG (?:([0-9])|([0-9][0-9a-fA-F]*)[hH])$@ and $section eq ".bss") {
    my $delta_bss_org = (defined($1) ? ($1 + 0) : hex($2)) - $bss_org;
    die "fatal: .bss org decreasing ($.): $_\n" if $delta_bss_org < 0;
    if ($delta_bss_org != 0) {
      print $nasm_fh "resb $delta_bss_org\n";
    }
    $bss_org += $delta_bss_org;
  } elsif (m@^ORG @) {
    die "fatal: bad WASM instruction ($.): $_\n";
  } elsif (m@^([^\s:\[\],+\-*/]+) LABEL BYTE$@ and $section eq ".bss") {
    print $nasm_fh "\$$1:\n";
  } elsif ($_ eq "END") {
    $is_end = 1;
  } elsif (!length($_) or m@^PUBLIC @ or m@^DGROUP GROUP@ or m@^ASSUME @) {  # Ignore.
  } else {
    die "fatal: unsupported WASM instruction ($.): $_\n" ;
  }
}
if ($rodata_strs and @$rodata_strs) {
  print $nasm_fh "\nsection $segment_to_section{CONST}  ; C strings.\n";
  print_merged_strings_in_strdata($nasm_fh, $rodata_strs, 0);
}
print $nasm_fh "\n_end\n";
die "fatal: close: $nasm_outfn: $!\n" if !close($nasm_fh);
die "fatal: close: $disasm_outfn: $!\n" if !close($wasm_fh);

# -O17 seems to be enough, -O16 isn't: ``error: phase error detected at end of assembly''.
# `nasm-0.99.06 -Ox' also works: it does all the passes necessary.
my @nasm_cmd = qw(nasm-0.98.39 -f bin -O999999999 -o mininasm.nwatli3 mininasm_nwatli3.nasm);
print STDERR "info: running nasm_cmd: @nasm_cmd\n";
die "fatal: nasm_cmd failed\n" if system(@nasm_cmd);

my @chmod_cmd = qw(chmod +x mininasm.nwatli3);
print STDERR "info: running chmod_cmd: @chmod_cmd\n";
die "fatal: chmod_cmd failed\n" if system(@chmod_cmd);

my $size = -s("mininasm.nwatli3");
die "fatal: missing file: mininasm.nwatli3\n" if !defined($size);
print STDERR "info: created mininasm.nwatli3 ($size bytes)\n";

__END__
