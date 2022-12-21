NASM source of a 1440 KiB FAT12 filesystem 3.5" floppy image containing a single file (HI.TXT)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This project demonstrates that mininasm can create a larger output file than
the available memory: on DOS at most 636 KiB is available, and the output
file size is 1440 KiB. (mininasm is limited only by the number of labels
and macros defined, and their name lengths.)

See the file floppy.nasm for compilation instructions (with NASM and
mininasm) and more details.

As an FYI, floppy.8 is provided for the A86 assembler, demonstrating that it
silently truncates the output file to <=32768 bytes, and it also modifies
the last few bytes before truncation.k

__END__
