#
# dosmclib/dosmc.pl: build script for mininasm with dosmc
# by pts@fazekas.hu at Fri May 27 22:56:48 CEST 2022
#
# Usage: dosmc .
# Output file: mininasm.com
#

BEGIN { $^W = 1 }
dosmc(qw(-mt -cpn mininasm.c));  # Creates mininasm.com.
my $size = -s("mininasm.com");
print STDERR "info: created mininasm.com ($size bytes)\n";
