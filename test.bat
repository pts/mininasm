mininasm -f bin test\input0.asm -o test\input0.img
mininasm -f bin test\input1.asm -o test\input1.img
mininasm -f bin test\input2.asm -o test\input2.img
mininasm -f bin test\fbird.asm -o test\fbird.img
mininasm -f bin test\invaders.asm -o test\invaders.img
mininasm -f bin test\pillman.asm -o test\pillman.img
mininasm -f bin test\rogue.asm -o test\rogue.img -l test\rogue.lst
mininasm -f bin test\rogue.asm -o test\rogue.com -l test\rogue.lst -dCOM_FILE=1
mininasm -f bin test\os.asm -o test\os.img -l test\os.lst
mininasm -f bin test\basic.asm -o test\basic.img -l test\basic.lst
mininasm -f bin test\include.asm -o test\include.com -l test\include.lst
mininasm -f bin test\bricks.asm -o test\bricks.img -l test\bricks.lst
mininasm -f bin test\doom.asm -o test\doom.img -l test\doom.lst
