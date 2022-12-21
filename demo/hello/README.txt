Small hello-world programs for various systems:

* helloc.nasm: DOS 8086, .com program
* helloe.nasm: DOS 8086, .exe program
* helloli3.nasm: Linux i386 ELF-32, maximum compatibility, doesn't overlap
  code and data with ELF headers
* hellofli3.nasm: Linux i386 ELF-32: compatible with Linux >=2.0, qemu-i386,
  Linux emulation layer in FreeBSD, `objdump -x'
* hellohli3.nasm: Linux i386 ELF-32: compatible with Linux >=2.0, qemu-i386
* hellos32.nasm: Win32 PE .exe stub in 60 bytes
* helljw16.nasm: Win16 Windows >=3.x 8086 .exe program

Corresponding precompiled *.golden files are provided. Remove the .golden
suffix from the filename for running.

Compile the .nasm sources above with NASM (see command-line in the comment
near the top of each file) or mininasm (https://github.com/pts/mininasm).

__END__
