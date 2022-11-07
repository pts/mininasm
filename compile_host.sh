#!/bin/sh --
# by pts@fazekas.hu at Tue Nov  8 00:18:47 CET 2022
set -ex

gcc -DDEBUG -ansi -pedantic -s -Os -W -Wall -Wno-overlength-strings -o mininasm mininasm.c bbprintf.c
ls -ld mininasm
"$HOME/prg/dosmc/dosmc" -mt mininasm.c bbprintf.c  # Creates mininasm.com.
ls -ld mininasm.com

: "$0" OK.
