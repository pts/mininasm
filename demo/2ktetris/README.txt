port of SmallTetris v1.0 1992-09-03 to NASM and mininasm
SmallTetris by Tore Bastiansen
port by Péter Szabó pts@fazekas.hu

Download source: http://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/games/tetris/2ktetris.zip

Download source: https://archive.org/details/2ktetris

Originally SmallTetris was assembled with Turbo Assembler (TASM) 3.0. This
port (2ktetris.nasm) can be compiled by NASM (>= 0.98.39) and mininasm, both
producing the 2ktetris.com executable program bitwise identical to the
officially released tetris.com file produced by TASM+TLINK.

Remaining text is based on the officially released tetris.doc file.

Usage:
    Copy 2ktetris.com.golden to 2ktetris.com.

    How to start:
        2ktetris [-l n] [-p]
                  -l n: Starting level (1-17)
                  -p  : Turn on preview

    How to play:
        UpArrow     or 5    -       rotate
        DownArrow   or 2    -       drop
        LeftArrow   or 4    -       move left
        RigthArrow  or 6    -       move right
        PgUp        or 8    -       up one level
        p                   -       toggle preview
        Break       or ^C   -       quit

    Score:
        Each time you drop, your score is increased by:
        (fallheigth/2+2)*level or
        (fallheigth/2+1)*level if you use preview.

Note.
    USE ONLY A COLOR MONITOR


    SmallTetris was assembled with Turbo Assambler 3.0
    I'm sorry for the poorly documented source.
    This program was intended to be small (2k), not structured.

    Report bugs or ask questions to:
    Internet adress:    toreba@ifi.uio.no


        THIS IS A NOWARE PRODUCT FROM NORWAY
        DO WHAT YOU LIKE WITH THE SOURCE (DON'T LIE)
        NO RIGHTS RESERVED
        NO WARRANTEES
        NO CHARGE

__END__
