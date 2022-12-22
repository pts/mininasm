port of the Floppy Bird (flpybird) game to mininasm
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
This version was ported:
https://gitlab.com/FreeDOS/games/flpybird/-/tree/27a2c3b198097aa9d88c5841833afad8affde51b/SOURCE/FLPYBIRD

Project repository: https://github.com/icebreaker/floppybird

To play the game, rename flpybird.com.golden to flpybird.com, and run
flpybird.com in a DOS emulator such as DOSBox. See more instructions in
the project repository.

To compile flpybird.com with mininasm or NASM from sources, follow the
instructions in com.asm.

This porting project demonstrates that `%include' and `%incbin' work well in
mininasm, even nested `%includes'.

Changes made in this port:

* The `../' prefix was dropped from the incbin pathnames in game/data.asm.
* `%define COM' was added to com.asm for covenience. Before that, the
 `-DCOM' flag had to be specified for `nasm'.
* Compilation instructions were added as comments to com.asm.
* Some `%define's were changed to `%assign' because `%define' bodies are
  restricted in mininasm.
* Some `%define's were changed to `equ' (and moved down in the source file)
  because `%define' bodies are restricted in mininasm.
* Instructions requiring `cpu 386' were changed to hand-coded `db' or `dw'
  bytes, because mininasm supports up to `cpu 286'. These instructions are
  `movsb', `je strict near ...', `jge strict near ...', `jle strict near
  ...'.
* A mininasm parsing bug of not allowing whitespace in front of a `:' in a
  label definition was worked around by moving that whitespace.
* A mininasm code generation bug for `dw ..., $' was worked around by
  splitting the arguments to separate `dw' instructions.

__END__
