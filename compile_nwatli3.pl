#!/bin/sh --
eval 'PERL_BADLANG=x;export PERL_BADLANG;exec perl -x "$0" "$@";exit 1'
#!perl  # Start marker used by perl -x.
+0 if 0;eval("\n\n\n\n".<<'__END__');die$@if$@;__END__

#
# complie_nwatli3.pl: compile with OpenWatcom, link smarter to Linux i386 with NASM
# by pts@fazekas.hu at Sat Nov 26 05:24:32 CET 2022
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
# So we aim for something better.
#

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

my $nasm_infn = "mininasm_nwatli3.nasm";
print STDERR "info: converting $disasm_outfn to NASM format: $nasm_infn\n";
my $wasm_fh;
die "fatal: open: $disasm_outfn: $!\n" if !open($wasm_fh, "<", $disasm_outfn);
my $nasm_fh;
die "fatal: open: $nasm_infn: $!\n" if !open($nasm_fh, ">", $nasm_infn);
my $data_alignment = 4;  # 1 is 3 bytes smaller, 4 is faster. TODO(pts): Modify the owcc invocation as well.
print $nasm_fh "; .nasm source generated by $0\n";
print $nasm_fh "%include 'elf.inc.nasm'\n_elf_start 32, Linux, $data_alignment|sect_many|shentsize\n\n";
my $section = ".text";
my $segment = "";
my $bss_org = 0;
my $is_end = 0;
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
    print $nasm_fh "$_\n";
  } elsif (m@^[.]@) {
    if ($_ eq ".387" or $_ eq ".model flat") {  # Ignore.
    } elsif (m@^[.]386@) {
      print $nasm_fh "cpu 386\n";
    } else {
      die "fatal: unsupported WASM directive: $_\n" ;
    }
  } elsif (m@^[^\s:\[\],+\-*/]+:$@) {  # Label.  TODO(pts): Convert all labels, e.g. eax to $eax.
    print $nasm_fh "_start:\n" if $_ eq "_start_:";  # Add extra start label for entry point.
    print $nasm_fh "\$$_\n";
  } elsif (s@^(D[BWD])(?= )@@) {
    my $cmd = lc($1);
    s@\boffset FLAT:@\$@g;
    print $nasm_fh "$cmd$_\n";
  } elsif (m@^(_TEXT|CONST2?|_DATA|_BSS) SEGMENT @) {
    $segment = $1;
    $section = ($segment eq "_TEXT" ? ".text" : $segment eq "_BSS" ? ".bss" : ".data");
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
print $nasm_fh "\n_end\n";
die "fatal: close: $nasm_infn: $!\n" if !close($nasm_fh);
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
