#! /bin/sh --
# by pts@azekas.hu at Tue Dec 13 04:50:47 CET 2022
set -ex

~/prg/dosmc/dosmc .  # Creates mininasm.com.

owcc -c -D__LIBCH__ -I../minilibc32 -blinux -fnostdlib -Os -fno-stack-check -march=i386 -W -Wall -Wextra -o mininasm.nwalli3.obj mininasm.c
../minilibc32/as2nasm.pl -o mininasm.nwalli3 mininasm.nwalli3.obj
cp -a mininasm.nwalli3 mininasm.li3

owcc -bwin32 -fnostdlib -Wl,option -Wl,start=_mainCRTStartup -Wl,option -Wl,dosseg -Wl,runtime -Wl,console=3.10 -o mininasm.swatw32.exe -Os -s -fno-stack-check -march=i386 -W -Wall -Wextra mininasm_swatw32.c
cp -a mininasm.swatw32.exe mininasm.win32.exe

ls -ld mininasm.com mininasm.li3 mininasm.win32.exe

: "$0" OK.
