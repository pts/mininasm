;
; floppy.nasm: NASM source of a 1440 KiB FAT12 filesystem 3.5" floppy image contining a single file (HI.TXT)
; by pts@fazekas.hu at Tue Dec 13 21:59:42 CET 2022
;
; Compile: nasm -f bin -O0 -o floppy.bin floppy.nasm
;
; Compile: mininasm -f bin -o floppy.bin floppy.nasm
;
; Can be compiled with NASM >=0.98.39 and mininasm (even on DOS 8086).
;
; This file demonstrates that mininasm can create a larger output file than
; the available memory: on DOS at most 636 KiB is available, and the output
; file size is 1440 KiB. (mininasm is limited only by the number of labels
; and macros defined, and their name lengths.)
;
; Output file size limits of various assemblers:
;
; * mininasm doesn't have a output file size limit. (This means is that the
;   file size can be up to 2 GiB - 1 byte, and available memory is not a
;   limiting factor.)
; * Tinyasm doesn't have an output file size limit, like mininasm.
; * Watcom Assembler (WASM) doesn't have an output file size limit.
; * NASM stores each output byte in memory.
; * JWasm for OMF .obj output doesn't have an output file size limit, but
;   for -bin output it stores all output bytes in memory, and it silently
;   overflows to video memory (0xa0000) on DOS.
; * A72 doesn't have an output file size limit, but it can't easily repeat:
;   it doesn't have `dup' or `times', and it's also very slow.
; * A86 can co about 32256 output bytes correctly, doesn't report error on
;   more, but output file incorrect and/or truncated.
; * Wolfware Assembler can do 10799 bytes, fails for more.
; * Turbo Assembler (TASM) 4.1 stores each output byte in memory, limit is
;   about 450 KiB. But it has efficient encoding of `db ... dup (value)'
;   in the .obj file, and it stores those bytes in memory RLE-compressed.
; * Microsoft Assembler (MASM) 6.00B stores each output byte in memory.
;   It has the /VM switch to use virtual memory (more than 640 KiB) on DOS.
; * FASM stores output bytes in memory quite inefficiently (about 41.874
;   bytes of memory usage per output byte, tested with `nop' instructions).
;
; This file also demonstrates these abstraction features of mininasm (and
; NASM): symbolic constants with `equ', symbolic constants with `%assign',
; conditional compilation (`%ifndef'), affecting the output from the command
; line (-DFAT_COUNT=1), complicated arithmetic expressions.
;
; By default, generates the same output on Linux as:
;
;   $ dd if=/dev/zero bs=81920 count=18 of=floppy.bin
;   $ mkfs.vfat floppy.bin
;

		bits 16
		cpu 8086

SECTOR_COUNT	equ 0xb40
SECTORS_PER_FAT	equ 9
SECTORS_PER_CLUSTER equ 1
RESERVED_SECTOR_COUNT equ 1  ; Minimum is 1, meaning the boot sector.
ROOT_DIR_ENTRY_MAX equ 0xe0
%ifndef FILE_START_CLUSTER  ; Override it in the command-line with `nasm -DFILE_START_CLUSTER=2' etc.
  %assign FILE_START_CLUSTER 0xb20  ; Minimum value is 2, clusters 0 and 1 are reserved.
%endif
%ifndef FAT_COUNT  ; Override it in the command-line with `nasm -DFAT_COUNT=1'.
  %assign FAT_COUNT 2
%endif

@0x00:
boot_sector:  ; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#Boot_Sector
.jump:		jmp strict short boot_code
		nop
.oem_name:	db 'mkfs.fat'
.bytes_per_sector: dw 0x200
.sectors_per_cluster: db SECTORS_PER_CLUSTER
.reserved_sector_count: dw RESERVED_SECTOR_COUNT
.fat_count:	db FAT_COUNT
.root_dir_entry_max: dw ROOT_DIR_ENTRY_MAX
.sector_count:	dw SECTOR_COUNT
.media_descriptor: db 0xf0  ; 3.5" HD floppy.
.sectors_per_fat: dw SECTORS_PER_FAT
.sectors_per_track: dw 18
.head_count:	dw 2
.hidden_sector_count: dd 0
.sector_count_big: dd 0  ; See .sector_count for real value.
.drive_number:	db 0
.reserved:	db 0
.extended_boot_signature: db 0x29
.volume_serial_number: dd 0x5b63e6c7  ; '5B63-E6C7'.
.volume_label:	db 'NO NAME    '
.filesystem_type: db 'FAT12   '

@0x3e:
boot_code:
.@0x3e:		push cs
.@0x3f:		pop ds
.@0x40:		mov si, 0x7c00+.message
.@0x43:		lodsb
.@0x44:		db 0x22, 0xc0  ; and al, al
.@0x46:		jz strict short .@0x53
.@0x48:		push si
.@0x49:		mov ah, 0xe
.@0x4b:		mov bx, 7
.@0x4e:		int 0x10
.@0x50:		pop si
.@0x51:		jmp strict short .@0x43
.@0x53:		db 0x32, 0xe4  ; xor ah, ah
.@0x55:		int 0x16
.@0x57:		int 0x19
.@0x59:		jmp strict short .@0x59
.@0x5b:
.message:	db 'This is not a bootable disk.  Please insert a bootable floppy and', 13, 10
		db 'press any key to try again ... ', 13, 10
boot_padding:	times $$+0x1fe-$ db 0
@0x1fe:
.boot_sector_signature:	db 0x55, 0xaa
		times $$+0x200-$ db 0

before_fat_padding: times $$+(RESERVED_SECTOR_COUNT<<9)-$ db 0

@0x200:
fat1:  ; https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#Cluster_map
.fat:		db 0xf0, 0xff, 0xff  ; Clusters 0 and 1.
		times .fat+FILE_START_CLUSTER+(FILE_START_CLUSTER>>1)-$ db 0
		dw 0xfff<<((FILE_START_CLUSTER&1)<<2)
		times fat1+(SECTORS_PER_FAT<<9)-$ db 0
%if FAT_COUNT-1  ; If not 1, then 2.
@0x1400:
fat2:
.fat:		db 0xf0, 0xff, 0xff  ; Clusters 0 and 1.
		times .fat+FILE_START_CLUSTER+(FILE_START_CLUSTER>>1)-$ db 0
		dw 0xfff<<((FILE_START_CLUSTER&1)<<2)
		times fat2+(SECTORS_PER_FAT<<9)-$ db 0
%endif

before_root_dir_padding: times boot_sector+((RESERVED_SECTOR_COUNT+SECTORS_PER_FAT*FAT_COUNT)<<9)-$ db 0  ; Empty.

@0x2600:
root_dir:
dirent1:  ; 0x20 bytes.  https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#Directory_entry
.file_name:	db 0xe5, '       '  ; 1st byte indicates dDeleted.
.extension:	db 'BIN'
.attributes:	db 0x20  ; Archive.
.attributes2:	db 0x00
.attributes3:	db 0x00
.create_time:	dw 0xaecb
.create_date:	dw 0x558d
.access_date:	dw 0x558d
.access_rights:	dw 0
.modify_time:	dw 0xaecb
.modify_date:	dw 0x558d
.first_cluster: dw 2
.size:		dd 0x163c00  ; In bytes.
dirent2:  ; 0x20 bytes.
.file_name:	db 'HI      '
.extension:	db 'TXT'
.attributes:	db 0x20  ; Archive.
.attributes2:	db 0x00
.attributes3:	db 0x00
.create_time:	dw 0xaed6
.create_date:	dw 0x558d
.access_date:	dw 0x558d
.access_rights:	dw 0
.modify_time:	dw 0xaed6
.modify_date:	dw 0x558d
.first_cluster: dw FILE_START_CLUSTER
.file_size:	dd file_data.end-file_data
root_dir_padding: times (((ROOT_DIR_ENTRY_MAX<<5)+0x200-1)&~(0x200-1))-($-root_dir) db 0

before_clusters_padding: times boot_sector+((RESERVED_SECTOR_COUNT+SECTORS_PER_FAT*FAT_COUNT+(((ROOT_DIR_ENTRY_MAX<<5)+0x200-1)>>9))<<9)-$ db 0  ; Empty.

@0x4200:
clusters:
empty_clusters_before: times clusters+((FILE_START_CLUSTER-2)<<9)-$ db 'B'
@0x167e00:
file_data:	db 'Hello, World!', 13, 10
.end:
.padding:	times (file_data-$)&((SECTORS_PER_CLUSTER<<9)-1) db 0  ; Pad to cluster size.
@0x168000:
CLUSTER_COUNT equ (SECTOR_COUNT-RESERVED_SECTOR_COUNT-SECTORS_PER_FAT*FAT_COUNT-(((ROOT_DIR_ENTRY_MAX<<5)+0x200-1)>>9))/SECTORS_PER_CLUSTER  ; Round down.
empty_clusters_after: times clusters+((CLUSTER_COUNT*SECTORS_PER_CLUSTER)<<9)-$ db 'C'

@0x168000_:
padding_sectors: times boot_sector+(SECTOR_COUNT<<9)-$ db 'C'

; __END__
