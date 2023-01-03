Styx by Windmill Software in 1983
Styx Remastered by Rob Sleath on 2004-09-04, (C) Andrew Jenner 1998--2004
NASM and mininasm port by pts@fazekas.hu on 2023-01-02

Styx was released by Windmill Software in 1983. It is a decent clone of the
arcade game Qix (also sometimes known as "Kix"). This is actually a
"remastered" version of the game that has been altered to work a bit better
on modern computers. Also the game was originally released bootable floppy
only game, but this version works like a normal DOS game. (As usual with
really old games, run with DOSBox, otherwise it'll probably run too fast in
Windows or not work at all.) NOTE: Move with the arrow keys and hold down
the F1 key to move your ball into the center area!

Styx game retro page: https://dosgames.com/game/styx/

Styx executable program download: https://dosgames.com/files/styx.zip

Styx remastered source code: http://www.digger.org/styxsrc.zip

Copy of the notes in styxsrc.txt follows.

All the code is in STYX1.ASM, STYX2.ASM, STYX3.ASM and PARSE.ASM. STYX1.ASM
contains most of the input/output routines and therefore most of the modified
code.

DATA.ASM contains most of the static data. Added static data is in the code
segment in STYX1.ASM. The data segment is a bit fragile - I think the
unlabelled data between p4 and p46 must start at offset 6 for the program to
work correctly - there may be other examples of DS data referenced by offset
rather than label. As with DIGGER, the stack is at the end of the DS segment,
so no data should be added there.

Because of the difficulties with the data segment, it proved impossible to
link in the C module (PARSECMD.C) directly, so I compiled it, disassembled it
and linked in the assembler code (PARSE.ASM). These two (should) do the same
thing.

The speed code works a bit differently to Digger, the ratio of current system
speed to an 8MHz 8086 is calculated and the delay loops multiplied up. Calls
to the delay subroutine were added to the routines to flash the "Game over"
message and play the little jingle at "Enter your initials" and on level
completion. This will make the game a little slower on older machines, but you
can always speed it up from the command line.

Known bugs and issues:
  Ball init makes sound on first game, even if sound is turned off at command
  line. This messes up Windows.

  Changing speed alters volume of some sound effects.

  May be other speed problems, routines which have no delay loops and therefore
  run too fast (serious) or speed 100 varying between machines (less serious,
  since you can change the speed with the command line).

  Don't know if it works on CGA and EGA machines yet.

Copyright
---------

Windmill Software holds the copyright to the original Styx source code and
binaries, and have exclusive rights to sell, license and produce the game in
its original form.

Rob Sleath has the right to use the Styx source code for development of
other projects. Styx Remastered is such a project. It was produced without
reference to the original Styx source by Windmill software, and without help
from the original developers of Styx in any capacity other than historical
advice. With the permission of Rob Sleath, Styx Remastered is Copyright (c)
Andrew Jenner 1998-2004.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

Copy of the Styx Remastered documentation follows.

                                The Styx file
                                -------------
                               by Andrew Jenner

Introduction
------------

"Styx was the guardian of the sacred oaths that bound the gods." In 1983, it
was trapped by a clever computer programmer but left to die in the graveyard of
CGA games. Now it's back again.

         In Greek mythology, Styx was the name of the river which was
         the entrance to the underworld. It was often described as
         the boundary river over which the aged ferryman Charon
         transported the shades of the dead. The river was
         personified as a daughter of the Titan Oceanus, and Styx was
         the guardian of the sacred oaths that bound the gods.

         The actual river, the modern name of which is the Mavroneri,
         is in northeastern Arcadia, Greece. It plunges over a 183m
         (600ft) cliff, then flows through a wild gorge. The ancient
         Greeks believed that its waters were poisonous, and the
         river was associated with the underworld from the time of
         Homer.

         (From "Styx", Microsoft (R) Encarta. Copyright (c) 1993
         Microsoft Corporation. Copyright (c) 1993 Funk & Wagnall's
         Corporation)


The Styx story
--------------

After completing the remastering of Digger, I got many emails thanking me for
restoring this great game. One of these Digger fans (Maarten Kramer) came
across my site whilst looking for another game, "Styx", also by Windmill
software. At this stage I didn't even know Windmill had created any other
games, and when I came across a copy of the original "Styx" (thanks to Daniel
Backman), I quickly became addicted and decided that this would have to be the
next remastering project.

The game used a little known "tweaked" mode of the original CGA which allowed
all 16 colours to be displayed on screen at the same time, although at a paltry
resolution of 160x100. This sounds awful, but it was quite effective on CGA
monitors (it was certainly a welcome change to be able to see all 16 colours at
once) and was ideal for games of this sort (as you can see when you play
it). Rather than redrawing all the graphics, as I did with Digger, I just
converted them directly, which made the operation a lot simpler.

After a fun packed week of sifting through assembly code, I finally got the
thing to work on all graphics adapters better than or equal to CGA, and at more
or less the correct speed.

The Styx website seems to have vanished, both from the web and my hard disk.
I'll try to get around to resurrecting it sometime.

How to play Styx
----------------

The keys you need to play the game are (might be considered spoiler):
Left, Right, Up, Down, Home, End, PgUp, PgDn, (or 1, 2, 3, 4, 6, 7, 8, 9 on the
numeric keypad) to move your ball, F1, Space to pause and F9 to toggle sound.
To exit either press F10 or hold down Alt and Ctrl and press Delete
(no, your computer will not reboot, I changed it to simply exit the to the
operating system). The numeric keypad is recommended (rather than the block of
four arrow keys found on most extended keyboards) because it is easier to move
diagonally. Sorry portable computer users, the game will be more difficult for
you not only because of this, but because the dots moving around the edge will
be harder to see on liquid crystal displays.

The object of the game is to move your ball into the central area (you can do
this while the F1 key is held down) and trap the Styx (the swirly lines in the
centre of the screen) by creating filled areas of colour. You get points for
filling in areas, the larger the area the more points. The area (in units of
.1% of the playing area) is multiplied by either 1, 5 or 10 (depending on the
colour of a little block in the top right of the screen) to calculate your
score. Your job is done when you have reclaimed 80% of the territory (each
extra full percentage point you get over this gets you a 1000 point bonus).

Not only must you avoid the Styx, but you must not let it touch the line you
are drawing before you are back on safe ground and the area has been filled in.
You must not stop in the middle, and you cannot cross over the line you have
drawn. Also, you must avoid the dots moving around the edge of the reclaimed
area. They can't touch you when you are in the central area, but then the Styx
can so nowhere is safe.

The game is hard and requires a lot more luck than Digger, but there is also a
lot of skill and strategy required.


Command line switches
---------------------

/S:n - Set speed to n. 100 is normal, smaller numbers (minimum 1) are faster.
/C   - Use CGA graphics - this is only needed if you have genuine CGA but the
       game isn't detecting your adapter properly. It nearly always should.
/V   - Use EGA/VGA graphics - this is only needed if you have a genuine EGA/VGA
       or better but the game isn't detecting your adapter properly. It nearly
       always should.
/Q   - Quiet mode, no sound after the initial ball creation on the first game.
/?   - Display this list

/S is optional (you can just specify a number) but harmless, and retained for
compatibility with Digger, which requires it only in otherwise ambigous
situations.

/Q doesn't completely disable sound, you can still toggle it with the F9 key.


Scoring System
--------------

* 1 point for every .1% of the screen covered with blue.

* 5 points for every .1% of the screen covered with red.

* 10 points for every .1% of the screen covered with green.
  (the colour you fill with is shown in the top right, and follows a cycle:
  long period of blue, medium period of red and short period of green).

* 1000 points for every full 1% of the screen covered over the 80% necessary
  to complete the level.

* I am not sure if this is an exhastive list. There may be an extra life at
  some point.


Maximum scores
--------------

Of course, the maximum possible theoretical score of 30000 is impossible to
achieve in practice, as you could not trap the Styx in a space even as small as
.1%, let alone smaller.

My best level 1 score was 95% solid green, 24500 points, and cannot be beaten
for sheer flukiness. For my first move of the game, I just cut off a little
corner with a diagonal line, and the Styx somehow got on the small side of it
and bounced around in the corner for long enough for me to draw the line. I was
very surprised to have completed the level!

Johnny Veliath got 27,810 using a clever method which will be revealed on the
Styx website once it gets resurrected.


Background music
----------------

You're right, there isn't any. But there is that curious random buzzing noise
that never seems to quite repeat itself, which almost sounds like there is a
fly trapped inside your computer. I believe this is done by creating
pseudo-random numbers using two of the computer's timing circuits (the clock
and the RAM refresh counter). Because these timers run at different speeds,
strange results ensue. If anyone knows better, let me know.


Help! It runs too fast (or too slow)
------------------------------------

This version of Styx calibrates the speed of your computer when you run it,
so it should run at the same speed on all machines.

You can, however, speed up or slow down the game depending on your personal
preference. To do this, simply specify the speed on the command line. The
default is 100, higher numbers give slower speeds, lower numbers (1 being the
lowest) give faster speeds.

It proved very difficult to get the calibration just right, and you may feel
that the default setting is wrong. If you can change it just by using a
different speed setting, do this. If you feel that there is a more serious
problem (that the ratio between speeds of certain game elements is badly wrong
on your machine, for example), you'd better contact me.

Unfortunately, the sound effects change slightly at different speeds (the
background sound, for example, will be quieter at higher speed).


Levels
------

Level one contains one Styx and one caterpillar.

Level two contains one Styx and two caterpillars, unfortunately moving in
opposite directions and thereby forcing you to periodically move into the
center of the screen to avoid them. You can't loiter about waiting at the edge
of this level for too long - you have to act, and be aggressive! This level was
slightly faster in the original, but it was going way too fast on the new
version so I took out that "feature".

Level three contains two Styxes (and two caterpillars?). If you manage to
segregate the Styxes though, one of them will disappear (although there is no
way to tell which one).

I'm not sure about later levels, although I have reason to believe the
caterpillars get longer.


Highest scores
--------------

My highest score is 30,418 - I reached level 3 using the original program.

Elad Verbin (elavd@bigfoot.com) got 51,607 with his cunning strategy.

Johnny Veliath from Canada (also a high scorer on Digger) got 53,434 and
reached level 3. His email address is "95019@ijsh.ednet.ns.ca".

Maarten Kramer of Holland got 64,065.

Adri Timp made 64,232, whilst his daughter Irina has scored 42,452.

If you can beat my score let me know and, if I believe you, I will list you
here. Get playing, this section is looking really empty!


Bugs
----

Most of these have arisen because of the way the original game uses the
hardware, and I that want to keep it as similar to the original as possible, in
terms of sound and gameplay)

* Crashes on when sound is on when running under Windows (3.1 enhanced mode
  or 95). I consider this to be a bug in Windows, not a bug in the game, the
  sound just wouldn't be right if I didn't reprogram the timer. MS-DOS mode
  under Windows 95 is okay, though ("Use default settings" will usually work).
  On my system it basically works if you exit with F10 when it crashes and
  restart it with the /Q option, but, as ever, Your Mileage May Vary.

* There is a pause for a few seconds before keyboard control is available
  after exiting with F10 under Windows 95 (not in MS-DOS mode) on some systems.
  If this happens, don't panic - it does come back. I'm still trying to figure
  out what's causing this.

* Very occasionally crashes on exit when Smartdrv is running and you got a
  high score on your last game. This is because Smartdrv delays saving the high
  score table for a second or so, and gets confused if you try to exit while it
  is doing its stuff. Solution: disable write-caching before running the game,
  or, if you get a high score and want to exit, wait until the scores have
  saved. If it does crash, run Scandisk immediately, or you may lose all your
  high scores.

* Ball init makes sound on first game, even if sound is turned off at command
  line. This messes up Windows.

* Changing speed alters volume of some sound effects, and timing of others.

* Don't know if it works on CGA and EGA machines yet.

* Joystick support is thoroughly untested. It may or may not exist at all.


What's New?
-----------

11 July 1999: Website converted into this text file due to redesign of Digger
website.
8 Aug 1998: Styx website created.
6 Aug 1998: Minor modifications and bug fixes, particularly to do with speed.
5 Aug 1998: Actual game completed.


Contact me
----------

My preferred contact method is email - my address is andrew@digger.org.
If you don't have access to email you can write me snail mail at:
  Andrew Jenner
  Queens' College
  Cambridge
  CB3 9ET
  ENGLAND
You can visit my website at "http://homepages.enterprise.net/berrypark/andrew",
if you're interested.

Stop press: Adri Timp is taking over the Styx file! So please email your
high scores and strategic tips to him at "adritimp@dds.nl". Hopefully Adri will
also soon be resurrecting the Styx website. Watch this space.

__END__
