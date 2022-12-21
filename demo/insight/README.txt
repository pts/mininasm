compiling the Insight real-mode DOS 16-bit debugger with mininasm
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
https://github.com/pts/insight-mininasm
is a case study of porting NASM assembly source code to
mininasm, more specifically making the NASM source code of the Insight
debugger compilable with mininasm (and also remaining compilable with NASM),
with the goal of producing the same insight.com executable program with NASM
and mininasm, both identical to the file officially released.

This goal has been reached, the commit history of the project shows the
journey. See more details in the README of
https://github.com/pts/insight-mininasm .

__END__

