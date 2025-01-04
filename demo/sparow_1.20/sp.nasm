; -*- coding: us-ascii -*-
; Actual encoding is: microsoft-cp-866 (Russian).
;
; sp.nasm: NASM and mininasm source port of the Sparrow Commander 1.20
; port by pts@fazekas.hu at pts@fazekas.hu at Sat Jan  4 11:33:26 CET 2025
;
; Compile with NASM (>= 0.98.39): nasm -O999999999 -f bin -o spn.com sp.nasm 
; Compile with mininasm: mininasm -O999999999 -f bin -o spm.com sp.nasm
; sha256 output (both spn.com and spm.com) matches the original: 05d9e64e61c8f2a310195285119e6af88ace969e2b7a7ddcfb16ea19d7ac4b51
;
; This source port is based on file SP/SP.ASM in http://www.vgasoft.com/Sparrow/sp.zip
;
; Sparrow Commander is a lightweght clone of Norton Commander and Volkov
; Commander, for DOS.
;

bits 16
cpu 8086
org 100h

; Mimic 8086 instruction encoding in TASM.
; Use e.g. `dw ie_add_al_al' instead of `add al, al'.
ie_add_al_al equ 0c002h
ie_add_al_cl equ 0c102h
ie_add_cl_bl equ 0cb02h
ie_add_cl_bh equ 0cf02h
ie_add_dl_cl equ 0d102h
ie_add_dl_bl equ 0d302h
ie_add_dl_ah equ 0d402h
ie_add_bl_ah equ 0dc02h
ie_add_bl_bh equ 0df02h
ie_add_dh_al equ 0f002h
ie_add_ax_si equ 0c603h
ie_add_cx_bx equ 0cb03h
ie_add_cx_bp equ 0cd03h
ie_add_dx_cx equ 0d103h
ie_add_dx_bx equ 0d303h
ie_add_dx_bp equ 0d503h
ie_add_bx_cx equ 0d903h
ie_add_bp_di equ 0ef03h
ie_add_si_ax equ 0f003h
ie_add_si_cx equ 0f103h
ie_add_si_bx equ 0f303h
ie_add_si_bp equ 0f503h
ie_add_di_ax equ 0f803h
ie_add_di_cx equ 0f903h
ie_add_di_dx equ 0fa03h
ie_add_di_bx equ 0fb03h
ie_add_di_bp equ 0fd03h
ie_or_al_al equ 0c00ah
ie_or_cl_cl equ 0c90ah
ie_or_dl_dl equ 0d20ah
ie_or_bl_bl equ 0db0ah
ie_or_ah_ah equ 0e40ah
ie_or_ax_ax equ 0c00bh
ie_or_cx_cx equ 0c90bh
ie_or_dx_dx equ 0d20bh
ie_or_bx_bx equ 0db0bh
ie_or_bp_bp equ 0ed0bh
ie_or_si_si equ 0f60bh
ie_or_di_di equ 0ff0bh
ie_sub_al_dl equ 0c22ah
ie_sub_al_dh equ 0c62ah
ie_sub_cl_al equ 0c82ah
ie_sub_cl_dl equ 0ca2ah
ie_sub_cl_bl equ 0cb2ah
ie_sub_cl_ah equ 0cc2ah
ie_sub_cl_dh equ 0ce2ah
ie_sub_dl_cl equ 0d12ah
ie_sub_dl_bl equ 0d32ah
ie_sub_dl_dh equ 0d62ah
ie_sub_dl_bh equ 0d72ah
ie_sub_bl_dl equ 0da2ah
ie_sub_bl_bh equ 0df2ah
ie_sub_dh_bl equ 0f32ah
ie_sub_dh_ch equ 0f52ah
ie_sub_bh_cl equ 0f92ah
ie_sub_ax_ax equ 0c02bh
ie_sub_ax_cx equ 0c12bh
ie_sub_ax_bx equ 0c32bh
ie_sub_ax_si equ 0c62bh
ie_sub_cx_ax equ 0c82bh
ie_sub_cx_cx equ 0c92bh
ie_sub_cx_dx equ 0ca2bh
ie_sub_cx_bp equ 0cd2bh
ie_sub_cx_si equ 0ce2bh
ie_sub_cx_di equ 0cf2bh
ie_sub_dx_dx equ 0d22bh
ie_sub_dx_bp equ 0d52bh
ie_sub_dx_di equ 0d72bh
ie_sub_bx_cx equ 0d92bh
ie_sub_bx_bx equ 0db2bh
ie_sub_bx_di equ 0df2bh
ie_sub_bp_bx equ 0eb2bh
ie_sub_bp_bp equ 0ed2bh
ie_sub_bp_si equ 0ee2bh
ie_sub_si_ax equ 0f02bh
ie_sub_si_cx equ 0f12bh
ie_sub_si_si equ 0f62bh
ie_sub_si_di equ 0f72bh
ie_sub_di_ax equ 0f82bh
ie_sub_di_bx equ 0fb2bh
ie_sub_di_si equ 0fe2bh
ie_sub_di_di equ 0ff2bh
ie_xor_al_al equ 0c032h
ie_xor_cl_cl equ 0c932h
ie_xor_dl_dl equ 0d232h
ie_xor_bl_bl equ 0db32h
ie_xor_ah_ah equ 0e432h
ie_xor_ch_ch equ 0ed32h
ie_xor_dh_dh equ 0f632h
ie_xor_bh_bh equ 0ff32h
ie_xor_ax_ax equ 0c033h
ie_xor_cx_cx equ 0c933h
ie_xor_dx_dx equ 0d233h
ie_xor_bx_bx equ 0db33h
ie_xor_bp_bp equ 0ed33h
ie_cmp_al_cl equ 0c13ah
ie_cmp_al_dl equ 0c23ah
ie_cmp_al_dh equ 0c63ah
ie_cmp_al_bh equ 0c73ah
ie_cmp_cl_dl equ 0ca3ah
ie_cmp_cl_dh equ 0ce3ah
ie_cmp_cl_bh equ 0cf3ah
ie_cmp_dl_al equ 0d03ah
ie_cmp_dl_cl equ 0d13ah
ie_cmp_dl_dh equ 0d63ah
ie_cmp_bl_al equ 0d83ah
ie_cmp_bl_cl equ 0d93ah
ie_cmp_bl_bh equ 0df3ah
ie_cmp_dh_cl equ 0f13ah
ie_cmp_dh_dl equ 0f23ah
ie_cmp_dh_bh equ 0f73ah
ie_cmp_bh_bl equ 0fb3ah
ie_cmp_ax_cx equ 0c13bh
ie_cmp_ax_bp equ 0c53bh
ie_cmp_ax_di equ 0c73bh
ie_cmp_cx_bx equ 0cb3bh
ie_cmp_dx_cx equ 0d13bh
ie_cmp_bx_ax equ 0d83bh
ie_cmp_bp_ax equ 0e83bh
ie_cmp_bp_cx equ 0e93bh
ie_cmp_bp_bx equ 0eb3bh
ie_cmp_si_cx equ 0f13bh
ie_cmp_si_bx equ 0f33bh
ie_cmp_si_bp equ 0f53bh
ie_cmp_si_di equ 0f73bh
ie_cmp_di_si equ 0fe3bh
ie_mov_al_cl equ 0c18ah
ie_mov_al_dl equ 0c28ah
ie_mov_al_bl equ 0c38ah
ie_mov_al_ah equ 0c48ah
ie_mov_al_dh equ 0c68ah
ie_mov_al_bh equ 0c78ah
ie_mov_cl_al equ 0c88ah
ie_mov_cl_dl equ 0ca8ah
ie_mov_cl_bl equ 0cb8ah
ie_mov_cl_ah equ 0cc8ah
ie_mov_cl_dh equ 0ce8ah
ie_mov_cl_bh equ 0cf8ah
ie_mov_dl_al equ 0d08ah
ie_mov_dl_cl equ 0d18ah
ie_mov_dl_bl equ 0d38ah
ie_mov_dl_ch equ 0d58ah
ie_mov_dl_dh equ 0d68ah
ie_mov_bl_al equ 0d88ah
ie_mov_bl_cl equ 0d98ah
ie_mov_bl_dl equ 0da8ah
ie_mov_bl_ah equ 0dc8ah
ie_mov_bl_ch equ 0dd8ah
ie_mov_bl_dh equ 0de8ah
ie_mov_bl_bh equ 0df8ah
ie_mov_ah_al equ 0e08ah
ie_mov_ah_dl equ 0e28ah
ie_mov_ch_cl equ 0e98ah
ie_mov_ch_dl equ 0ea8ah
ie_mov_dh_cl equ 0f18ah
ie_mov_dh_dl equ 0f28ah
ie_mov_dh_bl equ 0f38ah
ie_mov_dh_ch equ 0f58ah
ie_mov_bh_al equ 0f88ah
ie_mov_bh_cl equ 0f98ah
ie_mov_bh_bl equ 0fb8ah
ie_mov_bh_ah equ 0fc8ah
ie_mov_ax_dx equ 0c28bh
ie_mov_ax_bx equ 0c38bh
ie_mov_ax_bp equ 0c58bh
ie_mov_ax_si equ 0c68bh
ie_mov_ax_di equ 0c78bh
ie_mov_cx_ax equ 0c88bh
ie_mov_cx_dx equ 0ca8bh
ie_mov_cx_bx equ 0cb8bh
ie_mov_cx_bp equ 0cd8bh
ie_mov_cx_si equ 0ce8bh
ie_mov_cx_di equ 0cf8bh
ie_mov_dx_ax equ 0d08bh
ie_mov_dx_cx equ 0d18bh
ie_mov_dx_si equ 0d68bh
ie_mov_dx_di equ 0d78bh
ie_mov_bx_ax equ 0d88bh
ie_mov_bx_cx equ 0d98bh
ie_mov_bx_dx equ 0da8bh
ie_mov_bx_bp equ 0dd8bh
ie_mov_bx_si equ 0de8bh
ie_mov_bx_di equ 0df8bh
ie_mov_bp_ax equ 0e88bh
ie_mov_bp_cx equ 0e98bh
ie_mov_bp_bx equ 0eb8bh
ie_mov_bp_si equ 0ee8bh
ie_mov_bp_di equ 0ef8bh
ie_mov_si_ax equ 0f08bh
ie_mov_si_cx equ 0f18bh
ie_mov_si_dx equ 0f28bh
ie_mov_si_bx equ 0f38bh
ie_mov_si_sp equ 0f48bh
ie_mov_si_bp equ 0f58bh
ie_mov_si_di equ 0f78bh
ie_mov_di_cx equ 0f98bh
ie_mov_di_dx equ 0fa8bh
ie_mov_di_bx equ 0fb8bh
ie_mov_di_bp equ 0fd8bh
ie_mov_di_si equ 0fe8bh

;███████████████████████████████████████████████████████████████████████████████
;			Program sp.com	(Sparrow)
;                       Author  Афанасьев Валерий Г.
;			Begin	12.12.1992
;                       End     02.10.1995
;
;███████████████████████████████████████████████████████████████████████████████
xor_byte        equ     0aah    ;байт кодировки sp.hlp
max_files_in_dir equ    1024    ;не превышать 1024 файлов в директории
begin_buf	equ	0b0h	;начало первого буфера клавиатуры в CS
size_wind	equ	9a0h	;максим. размер окна
st0d_met_stack	equ	0b9h	;смещение к стеку
st0d_com_line	equ	0c0h	;смещение буфера клавиатуры
st0d_com_line1	equ	142h	;смещение доп.буфера клавиатуры
st0d_path0	equ	1d3h	;смещение пути к левой панели
st0d_path1	equ	21ch	;смещение пути к правой панели
st0d_path_sp	equ	265h	;смещение к sp.com
st0d_array_drive equ	2b0h	;смещение к массиву дисков
st0d_one_begin_wind equ	2c8h	;смещение к началу экрана
begin_wind_mem	equ	3680			;начало буфера окна в памяти

start:

;начальная настройка системы

                mov     sp,stack0+st0d_met_stack
		mov	dx,phrase_ver
		call	phrase1
		mov	cl,4
		mov	bx,stack0+st0d_one_begin_wind	;смещение к началу экрана
		shr	bx,cl
		inc	bx
		mov	ah,4ah
		int	21h
		call	set_segm_data
		mov	ax,2524h	;новый вектор 24h
		mov	dx,int_24
		int	21h
		mov	ah,19h		;отчет о текущем дисководе
		int	21h
		add	al,"A"
		mov	si,stack0+st0d_path_sp
		mov	[si],al	;заслать текущий дисковод в путь0
		mov	word [si+1],5c3ah  ; "\:"
		dw ie_mov_di_si
		add	si,3
		mov	ah,30h
		int	21h
		mov	ch,80h
		cmp	al,2
		ja	met_300
version2:
;версия 2.x
		dw ie_mov_di_si
		mov	ah,47h
		cwd
		int	21h
		lodsb
		dw ie_or_al_al
		jz	met_303
		dw ie_xor_ax_ax
		repnz	scasb
		jmp	short met_303
met_300:
		mov	ax,[002ch]
		dw ie_or_ax_ax
		jz	version2
		mov	ds,ax
		dw ie_sub_si_si
met_301:
		lodsb
		cmp	al,1
		jnz	met_301
		inc	si
		lodsb
		and	al,11011111b
met_302:
		stosb
		lodsb
		dw ie_or_al_al
		jnz	met_302
		mov	al,5ch  ; (\)
		std
		repnz	scasb
		cld
		inc	di
		inc	di
met_303:
		push	cs
		pop	ds
		dec	di
		dec	di
		mov	al,5ch
		scasb
		jz	met_304
		stosb
met_304:
		mov	word [path_sp_end],di
		mov	al,"*"
		stosb
;Вторичный цикл при запуске внешних программ
body:
		call	indic
		mov	ah,19h		;отчет о текущем дисководе
		int	21h
		add	al,"A"
		mov	di,word [cs:met_path+bp]
		stosb
		mov	si,stack0+st0d_path_sp + 1
		movsw
		dw ie_mov_si_di
		mov	ah,47h
		cwd
		int	21h
		dw ie_xor_al_al
		mov	cx,64
		repnz	scasb
		dec	di
		dec	di
		mov	al,5ch
		scasb
		jz	met_305
		stosb
met_305:
		cmp	byte [met_keep_line],0
		jnz	met_06
		call	indic
		mov	si,[met_path+bp]
		xor	bp,2
		mov	di,[met_path+bp]
		mov	cx,64
		rep	movsb
met_06:
;сдвиг экрана
;		mov	dx,3d4h
;		mov	al,2
;		out	dx,al
;		inc	dx
;		mov	al,54h
;		out	dx,al
		call	set_dta
		cmp	byte [video_mode],7
		jz	met_02
		call	change_palette
met_02:
		dw ie_sub_di_di
		mov	es,[segm_data]
		mov	ds,[segm_wind]
		call	mov_wind
met_002:
		dw ie_xor_dx_dx
		dec	dx
		dw ie_xor_bx_bx
met_a7:
		inc	dx
		cmp	dl,26		;last drive
		jae	.met
		mov	ah,0eh
		int	21h
		mov	ah,19h
		int	21h
		dw ie_cmp_al_dl
		jnz	met_a7
		mov	byte [cs:stack0+st0d_array_drive + bx],al
		inc	bx
		jmp	met_a7
.met:
		dec	bx
		mov	byte [cs:act_drive+1],bl	;всего драйверов
met_0101:
		push	cs
		pop	ds
		call	clear_buf_key
		call	key_bar
		call	indic
	       	call	set_panel
met_080:
		xor	bp,2
met_80:
		call	set_panel
		dw ie_xor_ax_ax
		call	met_cur15   ;функция cursor, без провер. режима экрана
;ядро системы
		call	command_path
		mov	byte [keep_file],0ffh	;запрет поиска выделен.
		cmp	byte [act_screen],0
		jz	met_0
met_088:
;смена 1-ой и 2-ой страниц экрана

		call	begin_param8
		dw ie_sub_si_si
met30:
		mov	cx,153
met31:
		call	cga
.cycle:
		mov	ax,[es:di]
		movsw
		mov	[si-2],ax
		loop	.cycle
		cmp	di,153*24
		jb	met30
		mov	cl,(160*23-153*24)/2
		jz	met31
met_0:
		call	halt
met_00:
		dw ie_xor_cx_cx
		push	cs
		pop	ds
		dw ie_or_al_al		;функциональные клавиши
		jz	met_201
		cmp	al,8		;backspace
		jz	met_200
		cmp	al,9		;tab
		jz	met_201
		cmp	al,27		;esc
		jz	met_200
		cmp	al,0dh		;Enter
		jnz	met_03
		cmp	ah,28
		jnz	met_03
		call	key_enter
		jmp	short met_0
met_201:
		jmp	met_2
met_200:
		jmp	met_1
met_03:
		cmp	al,32
		jae	met_200
		cmp	ah,24		;Ctr+"O"
		jnz	met_01
		not	byte [act_screen]
		jmp	short met_088
met_01:
		cmp	ah,49		;Ctr+"N"	;снег
		jnz	met_0150
		not	byte [met_cga]
		jmp	short met_0
met_0150:
		cmp	ah,44		;Ctr+"Z"	;halt процессора
		jnz	met_101
		not	byte [hlt_ass]
		jmp	short met_0
met_101:
		cmp	ah,18		;Ctr+"E"
		jnz	met_04
		cmp	[met_keep_line],cl
		jz	met_0
		push	cs
		pop	es
		mov	si,stack0+st0d_com_line1
		mov	di,stack0+st0d_com_line
		dw ie_mov_bx_di
		mov	cl,[di-3]
		dw ie_add_di_cx
		add	cl,[si-1]
		dw ie_mov_ch_cl
		mov	[bx-2],cx
		dw ie_sub_cx_cx
		mov	cl,[si-1]
		inc	cx
		rep	movsb
		call	command_path
met_102:
		jmp	short met_0
met_04:
		cmp	byte [act_screen],cl
		jnz	met_102
		cmp	ah,37		;Ctr+"K"	- смена сортировок
		jnz	met_05
;сменить кодировку рамки
		mov	si,wind
		mov	di,winda
		call	coder
		not	byte [met_convert]
		jmp	short met_0103
met_05:
		cmp	ah,47		;Ctr+"V"	;смена видов сортировок
		jnz	met_0100
		not	byte [met_sort]
met_0103:
		mov	[keep_file],cl
		jmp	met_0101
met_0100:
		cmp	ah,28		;Ctr+Enter
		jnz	met_07
		call	ctr_enter
		jmp	short met_102
met_07:
		cmp	ah,38		;Ctr+"L"
		jnz	met_08
		not	byte [met_info]
		cmp	byte [met_info],cl
		jz	met_007
		call	info
		jmp	short met_102
met_007:
		call	indic
		mov	byte [keep_file],cl
		jmp	met_080
met_08:
		cmp	ah,19		;Ctr+"R"
		jnz	met_102
		call	indic
		mov	[70h],cl
		jmp	met_80
met_2:
		cmp	ah,75		;стрелка влево
		jz	met_3
		cmp	ah,77		;стрелка вправо
		jz	met_3
		cmp	ah,83		;удаление
		jz	met_3
		cmp	ah,68		;F10
		ja	met_simbol
		jz	met_f10
		cmp	ah,59
		jb	met_simbol	;F1
;нажаты клавиши доп. клавиатуры или функции F1-F10
		cmp	[act_screen],cl
		jnz	met_f1
		xchg	al,ah
		sub	al,59		;F1
		shl	ax,1
		dw ie_mov_bx_ax
		call	[met_func+bx]
		mov	byte [cs:met_renmov],0
met_f1:
		jmp	short met_sim4
met_1:
		cmp	ah,15
		jz	met_simbol
		cmp	ah,74		;-
		jz	met_simbol
		cmp	ah,78		;+
		jz	met_simbol

;набор в командной строке имени файла
met_3:
		mov	di,stack0+st0d_com_line
		call	accept
		jmp	short met_sim4
met_simbol:
;нажаты комбинации с ALT или управление курсором

		cmp	ah,16		;управл. курсором
		jb	met_sim3
		cmp	ah,51		;Alt + (Q - M)
		jb	met_sim2
		cmp	ah,83		;управл. курсором
		jbe	met_sim3
		cmp	[act_screen],cl
		jnz	met_sim4
		cmp	ah,120		;Alt + (1 - =)
		jb	met_sim0
		cmp	ah,131
		ja	met_sim4
met_sim2:
		call	alt_key
met_sim4:
		jmp	met_0
met_sim3:
		call	cursor
		jmp	short met_sim4
met_sim0:
		cmp	ah,87		;Shift+F4
		jnz	met_sim1
		call	new_edit
		jmp	short met_sim4
met_sim1:
		cmp	ah,92		;Shift+F9
		jnz	met_sim5
		call	setup
		jmp	short met_sim4
met_sim5:
		call	change_pos
		jmp	short met_sim4
met_f10:
;функция выхода с запросом
		mov	di,phrase_quit
		mov	si,sparrow
		call	needs
		jc	met_sim4
		call	flign
		mov	ah,4ch
		int	21h

needs:		;запрос
;входные ; si - сообщение над рамкой , di - в рамке
		mov	cx,0512h
                mov     dx,093eh
		mov	al,[ fon4 ]
		dw ie_mov_ah_al
		call	window
		xchg	si,di
                mov     dh,07h
		call	print_name
		mov	bl,[ fon3 ]
		dw ie_mov_bh_al
met_quit20:
		dw ie_mov_al_bl
		mov	si,phrase_yes
                mov     dx,0823h
		call	phrase
		dw ie_mov_al_bh
		mov	dl,29h
		mov	si,phrase_no
		call	phrase
		xchg	bl,bh
met_quit:
		call	halt
		cmp	ah,1
		jz	.met
		cmp	ah,77
		jz	met_quit20
		cmp	ah,75
		jz	met_quit20
		cmp	ah,21		;Yes
		jz	quit
		cmp	ah,49		;No
		jz	.met
		cmp	ah,28
		jnz	met_quit
		cmp	bl,[ fon4 ]
		jz	quit
.met:
		stc
quit:
		jmp	met_e762
change_palette:
		push	ds
		push	es
		push	ax
		dw ie_xor_ax_ax
		mov	ds,ax
		mov	al,[449h]
		mov	[cs:video_mode],al
		cmp	al,7
		jz	met_pal2				;нет
		cmp	al,3
		jz	met_pal6
		cmp	al,2
		jz	met_pal6
		mov	al,3
		int	10h
		jmp	short met_pal6
met_pal2:
		push	cs
		pop	ds
		mov	si,param_mda
		mov	di,segm_wind
		call	coder
met_pal6:
		pop	ax
		pop	es
		pop	ds
		ret
coder:
		push	cx
		push	cs
		pop	es
		mov	cx,11
.cycle:
		mov	al,[es:di]
		movsb
		mov	[si-1],al
		loop	.cycle
		pop	cx
		ret

set_panel:
		cmp	byte [keep_file],0
		jnz	met_81
		call	locat_name
		call	search_curs
met_81:
		call	inst_dir1
met_alt10:
		ret
alt_key:
		call	scan_xlat
		dw ie_mov_ah_al
		or	al,20h
		call	indic
		mov	bx,[num_pos0+bp]
		call	locat_name
		sub	si,48
		call	seg_dat
		dec	bx
met_alt1:
		inc	bx
		cmp	bx,[max_pos0+bp]
		jae	met_alt10
		add	si,48
		cmp	[si],al
		jz	met_alt2
		cmp	[si],ah
		jnz	met_alt1
met_alt2:
		mov	[num_pos0+bp],bx
		call	write_pan
do_cursor:
		dw ie_sub_ax_ax
		jmp	cursor		;сращивание ret
scan_xlat:
		push	ds
		push	cs
		pop	ds
		push	bx
		dw ie_mov_al_ah
		mov	bx,scan_tabl
		sub	bx,16
		cmp	al,120
		jb	met_scan1
		sub	bx,120-(16+35)
met_scan1:
		xlat
		pop	bx
		pop	ds
		ret
mov_wind:
		mov	ax,4
		dw ie_sub_si_si
.met:
		mov	cx,460
		call	cga
		rep	movsw		;сделать копию экрана в буфере
		dec	ax
		jnz	.met
		ret

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE NEW_EDIT
;создание нового файла для редактирования
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
new_edit:  ; proc near
		mov	si,dat_edit
		mov	di,create_file
		call	begin_param10
met_edit1:
		call	accept
		call	halt
met_edit2:
		cmp	ah,1
		jz	met_edit9
		cmp	ah,28
		jnz	met_edit1
		mov	dx,begin_buf
		dw ie_mov_si_dx
		call	search_file
		jnc	met_e03
		call	create_new_file
		jc	met_edit4
		dw ie_mov_bx_ax
		mov	ah,3eh
		int	21h
		call	clear_window
		jmp	short met_e1
met_edit4:
		call	error
met_edit9:
		call	clear_window
		call	command_path
		ret

search_file:
		mov	cl,00100111b
		mov	ah,4eh
		call	int_21
met_edit3:
		ret

;;new_edit	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE EDIT
;редактирование файла длиной до 64K
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
edit:  ; proc near
                call    this_subdir
		dw ie_mov_dx_si
		jnz	met_edit3
met_e1:
		call	search_file
		jc	met_e4
met_e03:
;переместить редактир. имя в область внешнего редактора ds:si - перемещаем. имя
		push	cs
		pop	es
		mov	di,ext_edit+2
		dw ie_mov_bx_di
		mov	al," "
		mov	cx,64
.cycle:
		scasb
		jae	met_e04
		loop	.cycle
		dw ie_mov_di_bx
		inc	di
met_e04:
		mov	byte [cs:di-1],al
		mov	[cs:drive_file],di
		mov	word [cs:name_disp],80h+30
met_e02:
		lodsb
		stosb
		dw ie_or_al_al
		jnz	met_e02
		push	cs
		pop	ds
		cmp	word [drive_file],ext_edit+3
		jz	met_e05
		xchg	bx,di
		dw ie_sub_bx_di
		dw ie_mov_cl_bl
		dw ie_mov_si_di
                jmp     common_edit             ;запуск через Menu
met_e05:
;если ошибка,то сменить атрибуты или создать файл
		mov	si,dat_edit
		call	begin_view
;ds = cs внутри функции
		mov	si,dat_save
		mov	di,160*24+18
		mov	cl,4
met_e2:
		movsb
		inc	di
		loop	met_e2
		mov	al,[ fon3 ]
		mov	si,dat_line
		mov	dx,0039h
		call	phrase
		mov	si,dat_col
		mov	dl,45h
		call	phrase
		mov	si,dat_char
		mov	dl,30h
		call	phrase
		call	insert
		mov	dx,[drive_file]
		mov	ax,3d00h	;открыть файл для чтения
		int	21h
		jnc	met_e3
met_e4:
		call	error
		jmp	short met_e999
met_e3:
;проверить наличие памяти для загрузки
		cmp	word [80h+28],0
		jnz	met_e5
		mov	cx,[80h+26]
		cmp	cx,[size_block]
		jbe	met_e6
met_e5:
		mov	al,8
		jmp	short met_e4
met_e6:
;считать файл
		mov	[handle0],ax
		mov	word [long_view_file],cx	;запомнить длину файла
		dw ie_mov_bp_cx
		call	beg_free_m
		cwd
		dw ie_mov_bx_ax
		mov	ah,3fh
		int	21h
		jc	met_e4
		call	close_file
		call	clear_window
		push	cs
		pop	es
		dw ie_xor_ax_ax
		mov	di,begin_txt
		mov	cx,9
		rep	stosw	;обнулить некоторые данные
		mov	dx,0100h
		mov	[cs:begin_buf-2],al
		mov	[cs:pos_curs],dx
		dw ie_sub_si_si
		call	seg_win
		call	set_pos_curs
met_e50:
		call	edit_screen
met_e899:
		call	set_cursor
		call	halt
		push	ax
		call	clear_cursor	;чтобы небыло видно, как тормозит вывод
		pop	ax
		cmp	ah,1		;Esc
		jnz	met_e900
		cmp	word [cs:met_edit],0	;небыло редактирования
		jz	met_e999
		call	begin_param4
		call	edit_quit
		jc	met_e899
		jz	met_e999
		call	save_file
met_e999:
		jmp	met_v30		;выход через view
met_e900:
		cmp	ah,68		;F10
		jz	met_e999
		cmp	ah,65		;F7
		jnz	met_e798
		call	begin_param4
		jmp	edit_search
met_e798:
		cmp	ah,90		;Shift+F7
		jnz	met_e904
		call	begin_param4
		push	cs
		pop	ds
		jmp	met_e784
met_e904:
		cmp	ah,60		;F2
		jnz	met_e902
		call	begin_param4
		call	save_file
		jmp	short met_e899
met_e902:
		cmp	ah,132		;ctr+PgUp
		jnz	met_e940
		call	begin_param4
		jmp	met_e680
met_e940:
		cmp	ah,83		;удалить символ справа
		jnz	met_e906
		mov	[cs:met_edit],ax
		call	move_txt
		call	edit_delete
		jc	met_e907
		jmp	short met_e899
met_e906:
		cmp	ah,14		;backspase
		jnz	met_e911
		cmp	al,8
		jnz	met_e911
		mov	[cs:met_edit],ax
		jmp	met_e607
met_e911:
		cmp	ah,82		;Insert
		jnz	met_e908
		not	byte [cs:met_ins]
		call	insert
		jmp	short met_e912
met_e908:
		cmp	al,19h		;Ctr + Y
		jnz	met_e905
		cmp	ah,15h		;скан-код " Y "
		jnz	met_e905
		call	begin_param3
		call	ctr_y
met_e907:
		mov	si,[cs:begin_pos_wind]
		jmp	met_e50

met_e905:
		cmp	al,0bh		;Ctr + K
		jnz	met_e975
		cmp	ah,25h		;скан-код " K "
		jnz	met_e975
		call	begin_param3
		call	ctr_k
met_e912:
		jmp	met_e899
met_e975:
		dw ie_or_al_al		;не введена буква
		jz	met_e903
		mov	[cs:met_edit],ax
		jmp	met_e600
met_e903:
		xchg	al,ah
		cmp	al,119
		ja	met_e912
		sub	al,71
		jc	met_e912
		cmp	al,81-71
		jbe	met_e639
		sub	al,115-71
		jc	met_e912
		add	al,11
met_e639:
		shl	ax,1
		dw ie_mov_bx_ax
		call	begin_param4
		call	out_dx_curs
		jmp	[cs:key_tabl_edit+bx]
met_e640:
		cmp	si,1
		ja	met_e642
		jz	met_e648
		jmp	short met_e912
met_e642:
		dw ie_sub_bx_bx		;условие выхода
		std
		dec	si
		call	mean_simbol
met_e643:
		dw ie_mov_di_si
		dec	di
		call	mean_simbol
		jnz	met_e647
		jnc	met_e644	;не начало файла
		cmp	word [si],0a0dh
		jnz	met_e646
		jmp	short met_e644
met_e647:
		dw ie_cmp_di_si
		jz	met_e643
		dw ie_mov_si_di
met_e644:
		inc	si
met_e648:
		inc	si
met_e646:
		cld
		jmp	short met_e654
met_e650:
		dw ie_mov_bx_bp		;условие окончания поиска
met_e653:
		dw ie_mov_di_si
		inc	di
		call	mean_simbol
		jz	met_e654	;обнаружен конец строки или файла
		dw ie_cmp_di_si
		jz	met_e653
		dec	si
met_e654:
		call	set_pos_simbol
		call	check
		dw ie_or_al_al
		jz	met_e652
		jmp	met_e541
met_e652:
		jmp	met_e549
met_e680:
		dw ie_sub_si_si
		mov	dx,100h
		mov	word [cs:begin_line],0
                jmp     met_e532

begin_param3:
		mov	[cs:met_edit],ax
begin_param4:
		call	move_erase
		call	move_txt
		ret

;--------------------------------- поиск фразы -------------------------------
edit_search:
		mov	si,dat_edit
		call	accept_search
		jc	met_e789
met_e784:
		mov	si,dat_edit
		call	print_search
		push	cs
		pop	es
		call	out_dx_curs
		dw ie_mov_bl_dh
		dw ie_xor_bh_bh
		dw ie_sub_cx_cx
		mov	dl,[cs:di-2]
		mov	dh,13
		inc	di		;подогнать под стандарт нач. условия
met_e785:
		dw ie_mov_cl_dl
		sub	di,begin_buf
		dec	di
		dw ie_sub_si_di
		mov	di,begin_buf
met_e799:
		dec	cx
		js	met_e797
		dw ie_cmp_si_bp
		jae	met_e786
		lodsb
		dw ie_cmp_al_dh
		jz	met_e783
met_e791:
		scasb
		jnz	met_e785
		jmp	short met_e799
met_e783:
		cmp	byte [si],0ah
		jnz	met_e791
		inc	bx
		inc	si
		mov	di,begin_buf
		jmp	short met_e791

;не найден совсем
met_e786:
		mov	si,dat_edit
		call	no_found
		call	halt
met_e789:
		call	clear_window
		call	out_dx_curs
                jmp     met_e503
;найден
met_e797:
		call	clear_window
		cmp	bx,23
		ja	met_e792
		dw ie_mov_dh_bl
		jmp	met_e654
met_e792:
		push	bx
		mov	bx,12
		push	si
		dw ie_xor_al_al
met_e721:
		dw ie_or_al_al
		jnz	met_e722
		call	str_search
		dec	bx
		jnz	met_e721
met_e722:
		pop	si
		pop	ax
		dw ie_sub_ax_bx
		sub	ax,strict word 12
		add	[cs:begin_line],ax
		push	bx
		call	set_pos_simbol
		call	check
		pop	bx
		add	bx,12
		dw ie_mov_dh_bl
		call	set_pos_curs
		call	set_old_param
		call	reversi_search
		dec	bx
met_e723:
		dec	si
		dec	si
		call	reversi_search
		dec	bx
		jnz	met_e723
met_e724:
		jmp	met_e50

;------------------------ поиск значащего символа ---------------------------
mean_simbol:
		dw ie_cmp_si_bx
		jz	end_mean1
		cmp	word [si],0a0dh
		jz	end_mean

		lodsb

		cmp	al,"0"
		jb	mean_simbol
		cmp	al,"9"+1
		jb	end_mean

		cmp	al,"A"
		jb	mean_simbol
		cmp	al,"Z"+1
		jb	end_mean

		cmp	al,"a"
		jb	mean_simbol
		cmp	al,"z"+1
		jb	end_mean

		cmp	byte [cs:met_convert],0ffh
		jz	mean_conv

		cmp	al,"А"
		jb	mean_simbol
		cmp	al,"п"+1
		jb	end_mean

		cmp	al,"р"
		jb	mean_simbol
met_mean:
		cmp	al,"ё"+1	;основная "ё"
		jae	mean_simbol
end_mean1:
		stc
end_mean:
		ret
mean_conv:
		cmp	al,"░"		;основная "А"
		jb	mean_simbol
		jmp	short met_mean

;----------------------------- запрос на выход ------------------------------
edit_quit:
		push	cs
		pop	ds
		mov	al,[ fon5 ]
		dw ie_mov_ah_al
		mov	cx,0611h
                mov     dx,093fh
		mov	si,dat_edit + 1
		call	window
		mov	dh,07h
		mov	si,last_save
		call	print_name
                inc     dh
		dw ie_mov_bl_al
		mov	bh,[ fon4 ]
		mov	cl,1
met_e755:
		dw ie_mov_al_bh
		test	cl,1
		jnz	e11
		dw ie_mov_al_bl
e11:
		mov	si,dat_save
		mov	dl,21
		call	phrase
		dw ie_mov_al_bh
		test	cl,2
		jnz	e12
		dw ie_mov_al_bl
e12:
		mov	si,not_save
		mov	dl,29
		call	phrase
		dw ie_mov_al_bh
		test	cl,4
		jnz	e13
		dw ie_mov_al_bl
e13:
		mov	si,cont_edit
		mov	dl,42
		call	phrase
		call	halt
		cmp	ah,1	;esc
		jz	e16
		cmp	ah,28	;enter
		jz	met_e757
		cmp	ah,75
		jnz	e14
		test	cl,1
		jz	e19
		or	cl,8
e19:
		shr	cl,1
		jmp	short met_e755
e14:
		cmp	ah,77
		jnz	met_e755
		shl	cl,1
		test	cl,7
		jnz	met_e755
		mov	cl,1
		jmp	short met_e755
met_e757:
		test	cl,1		;save
		jnz	met_e762
		test	cl,4		;cont
		jz	met_e762	;установлен zf - not save ,clc
e16:
		dw ie_or_cl_cl		;сбросить zf
		stc
met_e762:
		pushf
		call	clear_window
		popf
		ret

;------------------- изменение режима вставки/удаления --------------------
insert:
		push	ds
		push	cs
		pop	ds
		mov	dx,0018h
		mov	si,dat_ins
		cmp	[met_ins],dh		;0
		jz	met_e611
		mov	si,dat_over
met_e611:
		mov	al,[ fon3 ]
		call	phrase
		pop	ds
		ret

;---------------------------- удаление символа ----------------------------
edit_delete:
		call	out_dx_curs
		dw ie_cmp_si_bp
		jz	met_e691
		cmp	word [si],0a0dh
		jz	met_e690
		call	erase_sim
		call	set_pos_curs
met_e691:
		clc
		ret
met_e690:
		push	si
		dw ie_sub_ax_ax
		xchg	word [cs:pos_backspace],ax
		dw ie_mov_di_si
		inc	si
		inc	si
		dw ie_mov_cx_bp
		dw ie_sub_cx_si
		dw ie_add_si_ax
		call	movsb_cld
		dec	bp
		dec	bp
		pop	si
		call	set_pos_curs
		stc
		ret
str_search:
		push	dx
		dw ie_mov_cx_bp
		dw ie_sub_cx_si
		mov	dx,0a0dh
		call	scasb_cld
		pop	dx
		ret

;---------------------------- удалить строку ----------------------------
ctr_y:
		call	out_dx_curs
		mov	word [cs:begin_colon],0
		dw ie_xor_dl_dl
		call	set_old_param
		dw ie_mov_di_si
		call	reversi_search
		push	si
		xchg	di,si
		call	str_search
		dw ie_sub_bp_si
		dw ie_mov_cx_bp
		dw ie_add_bp_di
		call	movsb_cld
		pop	si
met_e976:
		call	set_pos_curs
		ret

;----------------------- удалить до конца строки ----------------------
ctr_k:
		call	out_dx_curs
		push	si
		dw ie_mov_di_si
		call	str_search
		dw ie_or_al_al
		jnz	met_e977
		dec	si
		dec	si
met_e977:
		dw ie_sub_bp_si
		dw ie_mov_cx_bp
		dw ie_add_bp_di
		call	movsb_cld
		pop	si
		call	edit_line
		jmp	short met_e976

;----------------------------- записать файл -----------------------
save_file:
		dw ie_sub_cx_cx		;обычные атрибуты
		call	met_e681
		call	create_new_file
		jc	met_e770
		dw ie_mov_bx_ax
		call	beg_free_m
		cwd
		dw ie_mov_cx_bp
		mov	ah,40h
		int	21h
		dw ie_cmp_ax_cx
		jz	met_e651
		mov	al,8
met_e770:
		call	error
met_e651:
		mov	ah,3eh
		int	21h
		mov	word [cs:met_edit],0
		dw ie_xor_ch_ch
		mov	cl,[cs:80h+21]	;старые атрибуты
met_e681:
		push	cs
		pop	ds
		mov	dx,[drive_file]
		mov	ax,4301h
		int	21h
		ret
create_new_file:
		dw ie_xor_cx_cx
		mov	ah,3ch
		call	int_21
		ret
;----------------------- ввод буквы в буфер ----------------------------
met_e600:
		mov	cx,[cs:size_block]
		dec	cx
		dec	cx
		dw ie_cmp_bp_cx
		jb	met_e601
		mov	al,8
		call	error
met_e605:
                jmp     met_e899
met_e601:
		mov	dl,byte [cs:pos_curs]
		call	set_old_param
		call	seg_dat				;в сегменте окна
		mov	si,[cs:pos_simbol]
		add	si,begin_wind_mem

;------------------------- введена Enter -------------------------
		call	move_erase
		cmp	ah,28
		jnz	met_e610
		cmp	al,13
		jnz	met_e610
		mov	ah,0ah
		mov	[si],ax
		inc	bp
		inc	bp
		add	word [cs:pos_simbol],2
;переход на стрелка вправо
		call	move_txt
		sub	word [cs:begin_txt],2
		mov	[cs:begin_colon],ax	;только бы <> 0
		call	out_dx_curs
		jmp	met_e550
met_e610:
;ввести символ в буфер
		cmp	byte [cs:met_ins],0
		jz	met_e631
		call	over
		jnc	met_e634		;не сдвигать экран
                jmp     short met_e613
met_e631:
		mov	[si],al
		inc	word [cs:pos_simbol]
		inc	bp
		call	out_dx_curs
		mov	cx,1
		cmp	al,9
		jnz	met_e645
		call	move_txt
		call	reversi_search
		dw ie_mov_ah_dl			;сохранить
		call	e558
		inc	cx
		call	e559
		dw ie_or_al_al
		jz	met_e649
		dw ie_xor_al_al
		dw ie_mov_cl_dl
		dw ie_sub_cl_ah
		dw ie_xor_ch_ch
		dec	dx		;чтобы компенсировать дальн. увеличение
met_e645:
;отобразить символ на экране
		cmp	dl,79
		jb	met_e602
		add	word [cs:begin_colon],10h
		sub	dl,0fh
met_e649:
		call	move_txt
met_e634:
		jmp	met_e549		;сдвинуть экран
;ввести символы в текст и сдвинуть экран

met_e602:
		call	e602
		mov	ah,[cs: fon0 ]
		dw ie_mov_bl_dl
		shl	bl,1
		dw ie_add_di_bx
		push	ax
		push	cx
		push	di
		mov	si,[cs:begin_txt]
		call	edit_line
		pop	di
		pop	cx
		pop	ax
		std
		rep	stosw
		cld
met_e613:
		jmp	met_e541	;не сдвигать экран


;-------------------- удаление одного символа на экране ----------------
met_e607:
		call	out_dx_curs
		call	move_txt
		dw ie_or_si_si
                jz      met_e501
		dec	si
		mov	[cs:begin_txt],si
		dw ie_or_dl_dl
		jnz	met_e630
		cmp	word [cs:begin_colon],0
		jz	met_e620
		inc	dx
met_e630:
		dec	dx
		call	erase_sim
		dw ie_or_al_al
		jz	met_e613
		call	move_erase
		call	check
                jmp     short met_e634
met_e620:
		call	move_erase
		dec	si
		call	reversi_search
		mov	cx,0fffeh
		call	e559
;удалить символы 0dh и 0ah
		push	si
		dw ie_mov_di_si
		inc	si
		inc	si
		dw ie_mov_cx_bp
		dw ie_sub_cx_di
		call	movsb_cld
		pop	si
		dec	bp
		dec	bp
		cmp	dh,1
		jz	met_e619
		dec	dh
                jmp     short met_e634
met_e619:
		call	set_pos_curs
		dec	word [cs:begin_line]
                jmp     short met_e663

;------------------------ на строку вверх -------------------------------

met_e510:
		call	reversi_search
		dw ie_or_si_si
		jz	met_e514
		dec	si
		dec	si
met_e514:
		call	reversi_search
		call	check_pos_cursor2
		cmp	dh,1
                jz      met_e512
		dec	dh
met_e606:
		dw ie_or_al_al
                jz      met_e545
met_e503:
		call	set_pos_curs
met_e501:
		jmp	met_e899
met_e512:
		mov	bx,[cs:begin_pos_wind]
		cmp	bx,2
                jb      met_e501
		dec	word [cs:begin_line]
		push	bx
		call	set_pos_curs
		pop	si
		dec	si
		dec	si
met_e663:
		call	reversi_search
                jmp     short met_e662

;-------------------------- к началу строки ---------------------------
met_e585:
		call	reversi_search
		dw ie_xor_dl_dl
		jmp	short met_e586
met_e555:
					;переход на строка вниз
		mov	word [cs:begin_colon],0
met_e502:
		inc	word [cs:begin_line]
		call	set_pos_curs
		mov	si,[cs:begin_pos_wind]
		call	str_search
                jmp     short met_e662

;------------------------ на строку вниз -------------------------------
met_e500:
		call	str_search
		dw ie_or_al_al
		jnz	met_e501		;конец файла
		call	check_pos_cursor2
		cmp	dh,23
		jae	met_e502
		inc	dh
                jmp     short met_e606

;------------------------------- вправо -------------------------------
met_e550:
		dw ie_cmp_si_bp
		jz	met_e541
		cmp	word [si],0a0dh
		jnz	met_e552
;обнаружен конец строки
		inc	si
		inc	si
		dw ie_xor_dl_dl
		cmp	dh,23
		jae	met_e555
		inc	dh
met_e586:				;переход из "к началу строки"
		cmp	word [cs:begin_colon],0
		jz	met_e541
		mov	word [cs:begin_colon],0
met_e549:
		call	set_old_param
met_e545:				;есть переходы
		call	set_pos_curs
		mov	si,[cs:begin_pos_wind]
met_e662:
                jmp     met_e50

met_e552:
;---------- некорректное действие (возможо dl=80), контролир. внутри функции
		inc	dx
		inc	si
		cmp	dl,80
		jae	met_e570
		cmp	byte [si-1],9
		jnz	met_e541		;сдвинуть
met_e570:
		push	si
		call	set_old_param
		call	reversi_search
		call	check_pos_cursor
		pop	si
met_e558:
		dw ie_or_al_al
		jz	met_e549	;сдвигать
met_e541:
		call	set_old_param
                jmp     met_e503

;-------------------------------- влево -------------------------------
met_e540:
		dw ie_or_si_si
		jz	met_e541
		dec	si
		dw ie_or_dl_dl
		jz	met_e542
		dec	dx
		cmp	byte [si],9
		jnz	met_e541
		call	e400
		jmp	short met_e558
met_e542:
		mov	cx,[cs:begin_colon]
		dw ie_or_cx_cx
		jz	met_e543
		mov	dl,10h-1
		sub	cx,10h
		jae	met_e401
		add	cx,10h
		dec	cx
		dw ie_mov_dl_cl
		dw ie_sub_cx_cx
met_e401:
		mov	[cs:begin_colon],cx
		call	e400
		jmp	short met_e549
met_e543:
		dec	si
		cmp	dh,1
		jnz	met_e544
		call	reversi_search
		dec	word [cs:begin_line]
		mov	[cs:begin_pos_wind],si
		mov	cx,0fffeh	;нельзя определить точно
		call	e559
		jmp	met_e549
met_e544:
		dec	dh
;------------------------- к концу строки -------------------------------

met_e580:
		call	reversi_search
		mov	cx,0fffeh	;внутри функции контроль
		call	e559		;внутри	  check_pos_curs
		jmp	short met_e558

;------------------------ к концу файла ---------------------------------
met_e660:
		mov	bx,17h
		dw ie_mov_dl_bl
		dw ie_sub_dl_dh
		inc	dx
		dw ie_mov_al_bh
		mov	[cs:end_pos_wind],bp
		cmp	word [ds:bp-2],0a0dh
		jnz	met_e978
		dec	bx
met_e978:
		dw ie_or_al_al
		jnz	met_e520
		call	str_search
		dec	dl		;было dl
		jnz	met_e978
met_e661:
		dw ie_or_al_al
		jnz	met_e522
		call	str_search
		inc	word [cs:begin_line]
		jmp	short met_e661

;------------------------ на экран вниз ---------------------------------
met_e520:
		mov	dx,0a0dh
		mov	bx,17h
		cmp	byte [cs:pos_curs+1],23	;нижняя строка
		jz	met_e525
		dw ie_mov_cx_bp
		dw ie_xor_al_al		;нач. условие
;определить последнюю строку, куда поместить курсор

		mov	si,[cs:begin_pos_wind]
		dw ie_sub_cx_si
met_e527:
		dw ie_or_al_al
		jnz	met_e529
		call	scasb_cld
		dec	bx
		jnz	met_e527
met_e529:
		mov	dx,1700h
		dw ie_sub_dh_bl
		mov	si,[cs:begin_point]
		cmp	word [cs:begin_colon],0
		jz	met_e537	;не сдвигать экран
		mov	word [cs:begin_colon],0
		jmp	met_e549
met_e525:
		call	str_search
		mov	[cs:end_pos_wind],si
		dw ie_or_al_al
		jz	met_e521
		jmp	met_e899
met_e521:
		dw ie_or_al_al
		jnz	met_e522
		call	scasb_cld
		inc	word [cs:begin_line]
		dec	bx
		jnz	met_e521
met_e522:
		mov	si,[cs:begin_point]
		mov	dx,1700h
		push	bx
		call	set_begin
		pop	bx
		mov	si,[cs:end_pos_wind]
		dw ie_or_bx_bx
		jz	met_e524
met_e523:
		dec	si
		dec	si
		call	reversi_search
		dec	bx
		jnz	met_e523
met_e524:
		jmp	met_e50

;------------------------ на экран вверх ---------------------------------

met_e530:
		mov	dx,100h
		mov	si,[cs:begin_pos_wind]
		cmp	byte [cs:pos_curs+1],1	;верхняя строка
		jz	met_e535
		cmp	word [cs:begin_colon],0
		jnz	met_e532
met_e537:
		jmp	met_e541
met_e535:
		mov	bx,[cs:begin_line]
		cmp	bx,23
		jbe	met_e534
		mov	bx,23
met_e534:
		sub	[cs:begin_line],bx
met_e531:
		dw ie_or_si_si
		jz	met_e532
		dec	si
		dec	si
		call	reversi_search
		dec	bx
		jnz	met_e531
met_e532:
		call	set_begin
		jmp	met_e50

;------------------------------- установка параметров ---------------
set_begin:
;dx - должен содержать позицию курсора

		mov	word [cs:begin_colon],0
		call	set_old_param
		call	set_pos_curs
		ret

;------------------------ построение экрана -----------------------------

edit_screen:
		cld
		mov	dx,0a0dh
		call	seg_win
		call	beg_free_m
		mov	[cs:begin_pos_wind],si
		mov	ah,[cs: fon0 ]
		mov	di,160
		dw ie_xor_bl_bl
met_e18:
		mov	byte [cs:cga_wait],0
met_e14:
		cmp	di,160*24
		jae	met_e25
		mov	cx,[cs:begin_colon]
		jcxz	met_e16
		call	scasb_tab
		call	cga
		dw ie_cmp_si_bp	;не переставлять, контроль длинной строки
		jae	met_e11
		dw ie_or_al_al
		jnz	met_e221
		inc	si
		inc	si
		mov	cx,80
		rep	stosw
		jmp	short met_e14
met_e221:
		push	bx
		dw ie_sub_bx_cx
		dw ie_mov_cx_bx	;база	(не ставить cl,bl)
		mov	bh,80
		dw ie_sub_bh_cl	;сохранить остаток cx
		dw ie_xor_al_al
		rep	stosw
		dw ie_mov_cl_bh	;восстановить
		pop	bx
		add	bx,7
		and	bx,0fff8h
		sub	bx,[cs:begin_colon]
		jmp	short met_e17

;--------выход ----------------------------------
met_e11:					;
		mov	cx,160*24		;
		dw ie_sub_cx_di			;
		shr	cx,1
		call	clear_screen		;
                dw ie_xor_al_al
		rep	stosw			;
		call	set_screen
met_e25:					;
		ret				;
;------------------------------------------------

met_e16:
		mov	cl,1
		call	wait_cga
		mov	cx,80
met_e17:
		dw ie_cmp_si_bp
		jae	met_e11
		lodsb
		dw ie_cmp_al_dl	;enter
		jz	met_e8
		cmp	al,9	;tab
		jz	met_e9
met_e10:
		stosw
		loop	met_e17
met_e12:
		dw ie_mov_cx_bp
		dw ie_sub_cx_si
		call	scasb_cld
		jmp	met_e18
met_e8:
		cmp	[si],dh
		jnz	met_e10
		inc	si
		dw ie_xor_al_al
		rep	stosw
		jmp	met_e14
met_e9:
		call	tab_sm
		jbe	met_e224
		rep	stosw
		dw ie_mov_cl_bh
		jmp	short met_e17
met_e224:
		dw ie_add_cl_bh
		rep	stosw
		jmp	short met_e12

;---------------------- смещение от символа tab -------------------------
tab_sm:
		dw ie_mov_bh_cl
		dw ie_add_cl_bl
		dw ie_mov_al_cl
		dec	ax		;al
		and	al,0f8h
		dw ie_sub_cl_al
		dw ie_xor_al_al
		dw ie_sub_bh_cl
		ret

;--------------------- текущая позиция курсора --------------------------
;zf=1 - конец файла	;cf=1	- конец строки
out_dx_curs:
		mov	dx,[cs:pos_curs]
		mov	si,[cs:begin_txt]
beg_free_m:
		mov	ds,[cs:begin_free_memory]
		ret

;------------- переместить курсор в заданную позицию -------------------

set_pos_curs:

;изменяется ax
		mov	[cs:pos_curs],dx
		mov	[cs:begin_txt],si

		call	seg_win
		push	bx
		push	bp
		dw ie_sub_bx_bx
		mov	ah,02h
		int	10h
		pop	bp
		pop	bx
		call	cga
;колонка с курсором
		mov	di,156
		call	color1
		dw ie_mov_ax_dx
		dw ie_xor_ah_ah
		cwd
		add	ax,[cs:begin_colon]
		inc	ax
		call	number
;строка с курсором
		mov	di,134
		call	color1
		mov	al,byte [cs:pos_curs+1]
		cbw
		cwd
		add	ax,[cs:begin_line]
		call	number
;символ с курсором
		mov	di,110
		mov	cl,3
		call	color2
		call	beg_free_m
		dw ie_cmp_si_bp
		jb	met_out
		mov	byte [ds:bp],26	;последний символ файла
met_out:
		mov	al,[si]
		dw ie_xor_ah_ah
		cwd
		call	number
;длина файла
		mov	di,78
		call	color1
		dw ie_mov_ax_bp
		dw ie_sub_dx_dx
		call	number
		ret
color1:
		mov	cx,5
color2:
		std
		push	di
		mov	ah,[cs: fon3 ]
		mov	al," "
		rep	stosw
		pop	di
		cld
		ret

;-------- поиск конца строки прямой ----------------------------
;входные si - начало поиска, cx - длина поиска
;выходные si - конец поиска

scasb_cld:
		push	es
		mov	[cs:begin_point],si
		mov	es,[cs:begin_free_memory]
		xchg	di,si
		dw ie_mov_al_dl
met_e13:
		repnz	scasb
		jcxz	met_e23
		cmp	[es:di],dh
		jnz	met_e13
		dw ie_xor_al_al		;метка обнаружения
		dec	cx
		scasb
met_e23:
		xchg	si,di
		pop	es
		ret

;-------- поиск конца строки (только прямой) с учетом табуляции -----
;входные si - начало поиска, cx - длина поиска
;выходные si - конец поиска, bx - смещение от начала поиска с учетом tab

scasb_tab:
		push	di
		push	bp
		dw ie_sub_bx_bx
		xchg	bp,cx
		dw ie_sub_cx_si
		jcxz	met_e210
met_e206:
		dw ie_cmp_bp_bx
		jbe	met_e203
		inc	bx
		dw ie_mov_di_bx
		lodsb
		dw ie_cmp_al_dl
		jz	met_e204
		cmp	al,9
		jz	met_e228
met_e229:
		loop	met_e206
		dw ie_xor_al_al
		jmp	short met_e211
met_e228:
		dw ie_mov_di_bx
		add	bx,7
		and	bx,0fff8h
		jmp	short met_e229
met_e204:
		cmp	[si],dh
		jnz	met_e229
		dec	si
		dec	bx
met_e210:
		dw ie_xor_al_al
		jmp	short met_e214
met_e203:
		dw ie_mov_al_dl		;al <> 0
		jz	met_e214	;равенство предыдущего сравнения
met_e211:
		cmp	byte [cs:pred_point],0
		jz	met_e214
		dw ie_mov_bx_di
		dec	bx
		dec	si
met_e214:
		dw ie_mov_cx_bp
		pop	bp
		pop	di
		ret

;-------------- занести строку из буфера в текст ----------------
;на выходе si - новая позиция в тексте
move_txt:
		cmp	word [cs:pos_simbol],0
		jz	move_txt01
		push	ds
		push	es
		call	beg_free_m
		push	ds
		pop	es
		dw ie_mov_di_bp
		dw ie_mov_si_bp
		sub	si,[cs:pos_simbol]
		dw ie_mov_cx_si
		inc	cx
		sub	cx,[cs:begin_txt]
		std
		rep	movsb
		cld
		call	seg_dat
		mov	si,begin_wind_mem
		mov	di,[cs:begin_txt]
		mov	cx,[cs:pos_simbol]
		add	[cs:begin_txt],cx
		rep	movsb
		xchg	si,di
		mov	word [cs:pos_simbol],0
		pop	es
		pop	ds
move_txt01:
		ret

;------------------------- контроль позиции курсора -----------------------
check_pos_cursor2:
		not	byte [cs:pred_point]	;установить 0 - перем. на след.
		call	check_pos_cursor
		not	byte [cs:pred_point]
		ret
e558:
		mov	cx,[cs:old_begin_colon]
		add	cx,[cs:old_pos_curs]
		ret

;определяет допустимa-ли позиция курсора в строке. Если нет, исправляет ее.
;входные: si- начало строки

check_pos_cursor:
		call	e558
e559:					;внешний переход из "курсор влево"
		push	bx
		push	dx
		mov	dx,0a0dh
		call	scasb_tab
		pop	dx
		call	check
		pop	bx
		ret

check:
		mov	al,1			; <> 0
		mov	cx,[cs:old_begin_colon]
		dw ie_sub_bx_cx
		jb	met_e232
		cmp	[cs:begin_colon],cx
		jnz	met_e232
		dw ie_mov_dl_bl
		cmp	bx,79
		jbe	met_e505
met_e232:
		dw ie_xor_al_al
		dw ie_add_bx_cx
		mov	word [cs:begin_colon],0
		dw ie_mov_dl_bl
		sub	bx,80
		jb	met_e505
		add	bx,11h
		mov	[cs:begin_colon],bx
		mov	dl,79-10h
met_e505:
                ret

this_subdir:
		call	indic
		call	locat_name
		call	seg_dat
		test	byte [si-9],10h
		ret

e400:
		push	si
		call	set_old_param
		call	reversi_search
		call	check_pos_cursor2
		pop	si
		ret

set_old_param:
		push	word [cs:begin_colon]
		pop	word [cs:old_begin_colon]
		mov	byte [cs:old_pos_curs],dl	;только колонку
		ret
;обратный поиск
reversi_search:
		dw ie_or_si_si
		jz	met_e399
		push	dx
		mov	dx,0d0ah
		dw ie_mov_cx_si
		std
		call	scasb_cld
		pop	dx
		dw ie_or_si_si
		jnz	met_e546
		dec	si
		cmp	word [si+1],0a0dh
		jz	met_e546
		dec	si
		dec	si
met_e546:
		add	si,3
met_e399:
		cld
		ret

e602:
		dw ie_mov_bl_dh
		dw ie_xor_bh_bh
		dw ie_mov_di_bx
		call	mul_80
		shl	di,1
		ret

erase_sim:
		push	si
		push	es
		push	ds
		pop	es
		dw ie_mov_di_si
		dw ie_mov_cx_bp
		dw ie_sub_cx_si
		inc	si
met_e609:
		lodsb
		stosb
		cmp	al,0ah
		jz	met_e614
		loop	met_e609
		jmp	short met_e615
met_e614:
		cmp	byte [si-3],0dh
		jnz	met_e609
met_e615:
		dec	bp
		inc	word [cs:pos_backspace]
		pop	es
		pop	si
;	!!!сращивание хвостов!!!
;вывести на экран строку начиная с si
edit_line:
		push	si
		push	bp
		call	e602
		call	set_pos_simbol
		add	bx,[cs:pos_simbol]	;new
		dw ie_mov_ax_bx
		sub	ax,[cs:begin_colon]
		jb	met_e629	;необходим сдвиг экрана
		sub	bp,[cs:pos_simbol]
		dw ie_mov_dl_al
		mov	cx,80
		dw ie_sub_cl_al
		add	bx,8
		and	bx,0fff8h
		sub	bx,[cs:begin_colon]
		and	bl,7
		shl	al,1
		dw ie_add_di_ax
		mov	ah,[cs: fon0 ]
		call	cga
met_e622:
		dw ie_cmp_si_bp
		jae	met_e627
		lodsb
		cmp	al,0dh	;enter
		jz	met_e623
		cmp	al,9	;tab
		jz	met_e625
met_e624:
		stosw
		loop	met_e622
		jmp	short met_e627
met_e623:
		cmp	byte [si],0ah
		jnz	met_e624
		inc	si
		jmp	short met_e627
met_e625:
		call	tab_sm
		jbe	met_e626
		rep	stosw
		dw ie_mov_cl_bh
		jmp	met_e622
met_e626:
		dw ie_add_cl_bh
met_e627:
		dw ie_xor_al_al
		rep	stosw
met_e629:
		pop	bp
		pop	si
		ret

set_pos_simbol:
		push	bp
		dw ie_mov_bp_si
		call	reversi_search
		push	dx
		mov	dx,0a0dh
		mov	cx,0fffeh
		call	scasb_tab
		pop	dx
		pop	bp
		ret

move_erase:
		push	bx
		mov	bx,[cs:pos_backspace]
		dw ie_or_bx_bx
		jz	met_e616
		push	ax
		push	dx
		push	si
		push	ds
		call	beg_free_m
		mov	si,[cs:begin_txt]
		mov	dx,0a0dh
		dw ie_mov_cx_bp
		dw ie_sub_cx_si
		dw ie_add_cx_bx
		call	scasb_cld
		dw ie_cmp_si_bp
		jae	met_e621
		dw ie_mov_cx_bp
		dw ie_sub_cx_si
		dw ie_mov_di_si
		dw ie_add_si_bx
		call	movsb_cld
met_e621:
		mov	word [cs:pos_backspace],0
		pop	ds
		pop	si
		pop	dx
		pop	ax
met_e616:
		pop	bx
		ret

movsb_cld:
		push	es
		push	ds
		pop	es
		rep	movsb
		pop	es
		ret

;------------------ замена одного символа в тексте ---------------------
over:
		call	beg_free_m
		call	out_dx_curs
		call	move_txt
		cmp	word [si],0a0dh
		jnz	met_e635
		push	si
		mov	[si],al
		inc	si
		dw ie_mov_di_si
		dw ie_mov_cx_bp
		dw ie_sub_cx_si
		inc	si
		call	movsb_cld
		pop	si
		call	met_e632
		dec	bp
		clc
		ret
met_e635:
		mov	[si],al
		dw ie_cmp_si_bp
		jnz	met_e637
		inc	bp
met_e637:
		call	edit_line
met_e632:
		inc	si
		inc	dx
		cmp	dl,80
		jb	met_e633
		dec	dx
		add	word [cs:begin_colon],10h
		sub	dl,0fh
		clc
met_e633:
		ret

;edit		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE VIEW
;просмотр файла
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
view:  ; proc near
		call	this_subdir
                jnz     met_e633
		mov	si,dat_view
		mov	word [cs:name_disp],0
		call	begin_view
		mov	si,dat_cnv
		mov	di,160*24+82
		mov	cl,6
met_v78:
		movsb
		inc	di
		loop	met_v78
		call	seg_dat
		mov	ax,3d00h	;открыть файл для чтения
		call	int_21
		jnc	met_v2
		call	error
		jmp	met_v30
met_v2:
		push	cs
		pop	ds
		mov	[handle0],ax
		mov	al,02h		;указатель на конец
		call	file_indic
		mov	word [long_view_file],ax;запомнить длину файла
		mov	word [long_view_file+2],dx
		dw ie_xor_al_al	;указатель на начало
		call	file_indic
		dw ie_sub_si_si
		dw ie_sub_bp_bp
;считать файл в буфер

		call	read_view_file
		jnc	met_v5
		call	clear_window
		jmp	met_v30
met_v5:
		mov	byte [cs:begin_buf-2],0	;нач. усл. F7
		call	clear_window
		call	convert_file
met_v3:
		call	view_screen
		mov	bx,word [cs:size_file]
		push	ds
		pop	es
met_v14:
		call	halt
		cmp	ah,1
		jz	met_v30
		cmp	ah,64		;F6
		jnz	met_v76
		jmp	met_v69
met_v76:
		cmp	ah,65		;F7
		jnz	met_v90
		jmp	met_v75
met_v90:
		cmp	ah,90		;Shift+F7
		jnz	met_v95
		push	cs
		pop	ds
		cmp	byte [begin_buf-2],0	;ничего не введено
		jz	met_v14
		mov	ax,[begin_pos_wind]
		mov	di,[old_pos_wind]
		dw ie_cmp_ax_di
		ja	met_v106
		dw ie_cmp_si_di
		jb	met_v106
		xchg	ax,di
met_v106:
		xchg	si,ax
		jmp	met_v82
met_v95:
		cmp	ah,68		;F10
		jz	met_v30
		cmp	ah,81		;на экран вниз
		jz	met_v70
		cmp	ah,73		;на экран вверх
		jnz	met_v20
		jmp	met_v72
met_v20:
		cmp	ah,80		;на строку вниз
		jz	met_v71
		cmp	ah,72		;на строку вверх
		jnz	met_v25
		jmp	met_v73
met_v25:
		cmp	ah,71		;к началу файла
		jnz	met_v37
		dw ie_or_bx_bx
		jnz	met_v94
		dw ie_sub_si_si
		jmp	short met_v3
met_v37:
		cmp	ah,79		;to end
		jnz	met_v14
		jmp	met_v74
met_v30:
		call	clear_cursor
		push	cs
		pop	ds
		call	mov_out_wind
		mov	cx,80
                mov     ax,0720h
		rep	stosw
		call	close_file
		mov	word [keep_file],0	;объедин. keep и size
		pop	ax
		jmp	met_0101
met_v94:
		not	byte [cs:met_convert]
		jmp	short met_v69

;--------------------------------F6-------------------------------
met_v69:
		dw ie_xor_al_al		;файловый манипулятор на начало файла
		call	file_indic
		not	byte [cs:met_convert]
		mov	word [cs:size_file],0
		call	read_view_file
		jc	met_v30
		jmp	short met_v166

;---------------------на экран вниз-------------------------------
met_v70:
		dw ie_cmp_si_bp
		jb	met_v53
		call	read_view_file
		jc	met_v30
		jnz	met_v16		;флаг установлен в функции
met_v59:
		jmp	 met_v14
met_v53:
		push	si
		dw ie_mov_si_bp
		call	search_wind
		pop	di
		dw ie_cmp_di_si
		jae	met_v23
		dw ie_mov_si_di
met_v23:
		jmp	met_v3

;---------------------на строку вниз-------------------------------
met_v71:
		dw ie_cmp_si_bp
		jb	met_v43
		call	read_view_file
met_v130:
		jc	met_v30
		jz	met_v59		;флаг установлен внутри функии
met_v16:
		inc	word [cs:size_file]
met_v166:
		call	convert_file
		jmp	short met_v23
met_v43:
		mov	cx,80
		mov	si,[cs:begin_pos_wind]
met_v26:
		lodsb
		cmp	al,0dh	;enter
		jz	met_v118
		cmp	al,9	;tab
		jnz	met_v110
		dec	cx
		and	cl,0f8h
		inc	cx
met_v110:
		loop	met_v26
		jmp	short met_v23
met_v118:
		cmp	byte [si],0ah
		jnz	met_v26
		inc	si
		jmp	short met_v23

;---------------------на экран вверх-------------------------------
met_v72:
		mov	si,[cs:begin_pos_wind]
		dw ie_or_si_si
		jnz	met_v61
met_v52:
		call	move_forward
		jz	met_v23
met_v22:				;переход из ---строка вверх---
		call	read_view_file
		jc	met_v130
		call	convert_file
met_v108:
		dw ie_mov_si_bp
met_v61:
		call	search_wind
		jmp	short met_v23

;---------------------на строку вверх-------------------------------
met_v73:
		mov	si,[cs:begin_pos_wind]
		dw ie_or_si_si
		jnz	met_v33
		call	move_forward
		jnz	met_v22
		jmp	short met_v23
met_v33:
		mov	di,2
		call	search_wind1
		jmp	short met_v23

;---------------------to end file-------------------------------
met_v74:
		mov	dx,word [cs:long_view_file+2]
		mov	ax,word [cs:long_view_file]
		mov	cx,[cs:size_block]
		dw ie_or_dx_dx
		jnz	met_v50
		dw ie_cmp_ax_cx
		ja	met_v50
		dw ie_mov_ax_dx
		jmp	short met_v58
met_v50:
		div	cx
met_v58:
		dw ie_cmp_bx_ax		;на экране уже отображен конец
		jz	met_v108	;yes
		inc	ax
		mov	word [cs:size_file],ax
		jmp	short met_v52

;-------------------------------F7-------------------------------
met_v75:
		mov	si,dat_view
		call	accept_search
		mov	si,[begin_pos_wind]
		jc	met_v92
met_v82:
		mov	[old_size_file],bx
		push	word [ begin_colon]
		pop	word [old_begin_colon]
		push	word [begin_line]
		pop	word [old_begin_line]
		push	si
		mov	si,dat_view
		call	print_search
		pop	si
met_v84:
		push	cs		;не убирать -цикл
		pop	ds
		dw ie_mov_dx_si
		mov	si,begin_buf
		dw ie_xor_bx_bx
		mov	bl,[si-2]
		dec	bx
		lodsb
met_v85:
		mov	si,begin_buf+1
		dw ie_mov_di_dx
		dw ie_mov_cx_bp
		dw ie_sub_cx_di
		jcxz	met_v97
		repnz	scasb
		jnz	met_v97
		dw ie_mov_dx_di
		dw ie_mov_cx_bx
		rep	cmpsb
		jnz	met_v85
		dw ie_mov_si_di
;найден
		call	clear_window
		mov	[ old_pos_wind ],si
		not	byte [met_view_color]
		push	es
		pop	ds
		call	search_wind
met_v124:
		jmp	met_v3

;не найден совсем
met_v96:
		mov	si,dat_view
		call	no_found
		mov	ax,[ old_size_file ]
		mov	word [ size_file ],ax
		mov	dx,[ old_begin_colon ]
		mov	cx,[ old_begin_line ]
		mov	bx,[ handle0 ]
		mov	ax,4200h
		int	21h
		call	read_view_file
		jz	met_v123
		call	convert_file
met_v123:
		call	halt
met_v92:
		mov	si,[cs: begin_pos_wind ]
		call	clear_cursor
		call	clear_window
		jmp	short met_v124
met_v97:
;не найден пока
		call	read_view_file
		jz	met_v96
		call	check_esc
		jc	met_v96
		call	convert_file
		inc	word [cs: size_file ]
		jmp	met_v84		;set short
check_esc:
; cf=1 - была нажата "esc"

		mov	ah,1
		int	16h
		jz	met_v98
		cmp	ah,1
		jnz	met_v98
		stc
met_v98:
		ret

search_window:
;si - смещение к фразе view или edit
		push	bx
		mov	cx,071dh
		mov	dx,0a33h
		mov	di,begin_buf
		mov	bl,[di-2]
		shr	bl,1
		cmp	bl,7
		jna	met_v83
		sub	bl,7
		dw ie_sub_cl_bl
		dw ie_add_dl_bl
met_v83:
		dw ie_mov_ah_al
		inc	si
		call	window
		mov	dh,9
		mov	si,begin_buf
		call	print_name
		pop	bx
		ret
clear_cursor:
		mov	cx,200dh
		jmp	short met_set_curs
set_cursor:
		mov	cx,[cs:size_cursor]
met_set_curs:
		push	bp
		mov	ah,1
		int	10h
		pop	bp
		ret
begin_param10:
		call	long_window
		dw ie_mov_si_di
		mov	dx,0807h
		call	phrase
begin_param1:
		push	cs
		pop	es
		mov	di,begin_buf-3
		dw ie_sub_ax_ax
		stosb
		stosw
		ret
accept_search:
		push	cs
		pop	ds
		call	set_cursor
		mov	di,search_for
		call	begin_param10
met_v81:
		call	accept
		call	halt
		cmp	ah,28
		jz	met_v91
met_v107:
		cmp	ah,1
		jnz	met_v81
met_v87:
		stc
		ret
met_v91:
		cmp	byte [di-2],0	;ничего не введено
		jz	met_v87
		call	clear_window
		clc
		ret
print_search:
		call	clear_cursor
		mov	al,[ fon4 ]
		call	search_window
		mov	dh,8
		mov	si,searching_for
		call	print_name
		mov	es,[ begin_free_memory ]
		ret
no_found:
		push	cs
		pop	ds
		call	clear_window
		mov	al,[ fon5 ]
		call	search_window
		mov	dh,8
		mov	si,not_found
		call	print_name
		ret

;---------------------отображение на экране-------------------------------
view_screen:

		call	beg_free_m
		mov	[cs:begin_pos_wind],si
		call	seg_win
		mov	ah,[cs: fon0 ]
		mov	di,160
		call	clear_screen
		mov	dx,0a0dh
		cmp	word [cs:met_view_color],0	;выделять?
		jz	met_v4			;нет
		dw ie_mov_bx_bp
		mov	bp,[cs:old_pos_wind]
		mov	[cs:old_pos_wind],bx
		mov	bx,begin_buf
		mov	bl,[cs:bx-2]
		mov	[cs:met_view_color],bx
		dw ie_sub_bp_bx
met_v4:
		cmp	di,160*24
		jae	met_v11
		mov	cx,80
met_v7:
		dw ie_cmp_si_bp
		jae	met_v11
		lodsb
		dw ie_cmp_al_dl	;enter
		jz	met_v8
		cmp	al,9	;tab
		jz	met_v9
met_v10:
		stosw
		loop	met_v7
		jmp	short	met_v4
met_v8:
		cmp	[si],dh
		jnz	met_v10
		inc	si
		mov	al," "
		rep	stosw
		jmp	short met_v4
met_v9:
		mov	al," "
		dw ie_mov_bl_cl
		dec	bx
		and	bl,0f8h
		dw ie_sub_cl_bl
		rep	stosw
		dw ie_mov_cl_bl
		jcxz	met_v4
		jmp	short met_v7
met_v11:
		mov	bx,[cs:met_view_color]
		dw ie_or_bx_bx		;выделять?
		jz	met_v104	;нет
		cmp	bx,0ffh
		jnz	met_v103
;конец выделения
		mov	bx,[cs:old_pos_wind]
		mov	[cs:old_pos_wind],bp
		dw ie_mov_bp_bx
		mov	ah,[cs: fon0 ]
		mov	word [cs:met_view_color],0
		dw ie_xor_bh_bh
		jmp	short met_v7
;начало выделения
met_v103:
		add	bp,[cs:met_view_color]
		mov	ah,[cs: fon3 ]
		mov	word [cs:met_view_color],0ffh
		jmp	short met_v7
met_v104:
		mov	al," "
		mov	cx,160*24
		dw ie_sub_cx_di
		shr	cx,1
		rep	stosw
;отображение количество пройденных байт
		std
		mov	di,78*2
		mov	cx,10
		mov	ah,[cs: fon3 ]
		rep	stosw
		mov	ax,[cs:begin_colon]
		mov	dx,[cs:begin_line]
		dw ie_add_ax_si
		adc	dx,0
		mov	di,78*2
		call	number
		call	set_screen
		mov	al,[cs: fon3 ]
		call	color
		ret


clear_screen:
		call	cga
		mov	al,25h
                jmp     short met_vi_1
set_screen:
		mov	al,2dh
met_vi_1:
                cmp     byte [cs:met_cga],0
                jz      met_vi_2
                mov     dx,3d8h
		out	dx,al
met_vi_2:
		ret
search_wind:
		mov	di,23	;исправл. на 24 приведет к неполному просмотру
search_wind1:
		mov	dx,0a0dh
		std
		dec	si
		jz	met_v45
		cmp	[si-1],dx
		jz	met_v294
met_v44:
		dec	di
		jz	met_v41
met_v294:
		mov	cx,80
met_v47:
		dw ie_or_si_si
		jz	met_v45
		lodsb
		dw ie_cmp_al_dh	;конец строки
		jz	met_v48
		cmp	al,9	;tab
		jnz	met_v40
		dec	cx
		and	cl,0f8h
		inc	cx
met_v40:
		loop	met_v47
		jmp	short	met_v44
met_v48:
		cmp	[si],dl
		jnz	met_v40
		dw ie_or_si_si
		jnz	met_v241
		dec	di
		jz	met_v242
		jmp	short met_v45
met_v241:
		dec	si
		jmp	short met_v44
met_v41:
		inc	si
		jcxz	met_v45
met_v242:
		inc	si
		inc	si
met_v45:
		cld
		ret

view_window:
		push	bp
		push	ds
		mov	cx,061ah
                mov     dx,0a36h
		mov	al,[cs: fon4 ]
		dw ie_mov_ah_al
		inc	si
		call	window
		cmp	word [cs:name_disp],0
		jz	met_vw0
		mov	si,[cs:name_disp]
		jmp	short met_vw1
met_vw0:
		call	indic
		call	locat_name
		call	seg_dat
met_vw1:
		mov	dh,9
		mov	al,[cs: fon4 ]
		call	print_name
		pop	ds
		pop	bp
		ret
read_view_file:
		push	bx
		push	es
		push	di
		call	check_end
		jz	met_v6
		mov	[cs:begin_colon],ax
		mov	[cs:begin_line],dx
		mov	cx,[cs:size_block]
		call	beg_free_m
		push	ds
		pop	es
		mov	ah,3fh		;чтение файла
		cwd
		int	21h
		jc	met_verror
		dw ie_or_ax_ax		;была ошибка при считывании
		jz	met_v6
		dw ie_mov_bp_ax		;предварит. длина файла
		dw ie_mov_si_ax
		push	si
		mov	di,2
		call	search_wind1	;не показывать последн. строку
		pop	di
		call	check_end	;файл вместился весь ?
		jz	met_v56		;да

		dw ie_mov_bp_si		;установить длину файла
		dw ie_sub_di_si		;длина удаляемой части
		dw ie_mov_cx_dx
		dw ie_mov_dx_ax
		dw ie_sub_dx_di		;уменьшить файловый манипулятор
		mov	ax,4200h
		int	21h
met_v56:
		dw ie_sub_si_si
		inc	bx		; clear ZF
met_v6:
		pop	di
		pop	es
		pop	bx
		ret
met_verror:
		pop	ax
		jmp	met_v30

check_end:
		mov	al,1
		call	file_indic
		cmp	word [cs:long_view_file+2],dx
		jnz	met_v55
		cmp	word [cs:long_view_file],ax
met_v55:
		ret

;Kонвертировать файл
;bp - длина файла
convert_file:
		cmp	byte [cs:met_convert],0
		jz	met_v54
		dw ie_or_bp_bp
		jz	met_v54
		push	ds
		push	es
		push	cs
		push	ds
		pop	es
		pop	ds
		mov	si,dat_view
		call	view_window
		mov	al,[ fon4 ]
		mov	si,dat_conv
		mov	dh,8
		call	print_name
		mov	bx,tabl - 128
		dw ie_mov_si_bp
met_v17:
		dec	si
		mov	al,[es:si]
		cmp	al,128
		jb	met_v18
		xlat
		mov	[es:si],al
met_v18:
		dw ie_or_si_si
		jnz	met_v17
		call	clear_window
		pop	es
		pop	ds
met_v54:
		ret
move_forward:
;передвинуть файловый манипулятор на один блок вперед
		mov	cx,word [cs:size_file]
		jcxz	met_v54
		dec	cx
		mov	ax,[cs:size_block]
		mul	cx
		xchg	ax,dx
		dw ie_mov_cx_ax
		push	bx
		mov	bx,[cs:handle0]
		mov	ax,4200h
		int	21h
		dec	word [cs:size_file]
		inc	bx		;close ZF
		pop	bx
		ret
begin_view:
						;не сохраняет	ds
		call	clear_cursor
		call	seg_win
		mov	al," "
		mov	ah,[cs: fon3 ]
		mov	cx,80
		dw ie_sub_di_di
		call	cga
		rep	stosw
		mov	ah,[cs: fon0 ]
		mov	cx,11*80
		rep	stosw
		mov	cx,12*80
		call	cga
		rep	stosw
		call	view_window

;исправить нижнюю линию
		push	si
		mov	al,[cs: fon3 ]
		mov	dx,0003h
		call	phrase
		mov	ax,[si-4]
		mov	dx,[si-2]
		mov	di,78
		call	number
		push	cs
		pop	ds
		mov	al,[ fon3 ]
		call	color
		mov	dx,40
		mov	si,bytes
		call	phrase
		mov	al,[ fon4 ]
		mov	si,dat_vie
		mov	dh,8
		call	print_name
		pop	dx		;обмен значениями
		mov	bx,9
		mov	ah,[ fon3 ]
		mov	al," "
		mov	di,160*24-2
met_v77:
		mov	cx,6
		add	di,4
		rep	stosw
		dec	bx
		jnz	met_v77

		mov	si,dat_search
		mov	di,160*24+98
		mov	cl,6
met_v79:
		movsb
		inc	di
		loop	met_v79
		ret

mov_out_wind:
		push	ds
		call	begin_param8
		call	mov_wind
		pop	ds
		ret
begin_param8:
		dw ie_sub_di_di
		call	seg_dat
seg_win:
		mov	es,[cs:segm_wind]
		ret
seg_dat:
		mov	ds,[cs:segm_data]
		ret
file_indic:
		mov	bx,[cs:handle0]
file_indic1:
		dw ie_xor_cx_cx
		mov	ah,42h
		cwd
		int	21h
		ret

;view		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE INT_24
;обработка критических ошибок, вызываемая DOS
;заменяет int 24h
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
int_24:  ; proc far
		dw ie_mov_ax_di
		add	ax,strict word 19		;преобразование кода ошибки
		mov	byte [cs:met_int_24],0
		call	error
		mov	al,1
		jnc	met_error51
		mov	byte [cs:met_int_24],al
		add	sp,6
		push	cs
		pop	ds
		call	set_dta
		pop	ax
		pop	bx
		pop	cx
		pop	dx
		pop	si
		pop	di
		pop	bp
		pop	ds
		pop	es
		mov	al,83		;фатальная ошибка
		stc
met_error51:
		retf 0002
;int_24		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE INT_21
;вызов функций
;перехватывает int 21h
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
int_21:  ; proc near
		push	bx
		push	es
		dw ie_sub_bx_bx
		mov	es,bx
		test	byte [es:410h],11000000b ;дисковых устройств два ?
		jnz	met_b4		;да
		push	ax
		push	dx
		cmp	ah,0eh		;выбор дискового устройства int 21h
		jnz	met_b0
		cmp	dl,1		;устройство A или B
		ja	met_b5		;нет
		dw ie_mov_bl_dl
		jmp	short met_b1
met_b0:
		dw ie_mov_bx_dx
		mov	bx,[bx]
		cmp	bh,":"
		jnz	met_b5
		or	bl,20h
		sub	bl,"a"
		cmp	bl,1		;устройсво A или B
		ja	met_b5		;нет
met_b1:
		cmp	bl,[es:504h]	;дисковод А или В выбран
		jz	met_b5		;да
		mov	[es:504h],bl
		mov	al,0f0h		;вывести сообщение о смене драйвера
;в bl находится имя драйвера, на которое надо перейти- A или B
		add	bl,"A"
		call	error
met_b5:
		pop	dx
		pop	ax
met_b4:
		pop	es
		pop	bx
		int	21h
		ret
;int_21		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE ACCEPT
;обработка клавиш
;входные;di-начало буфера
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
accept:  ; proc near
;ds должен быть равен cs
		cmp	ah,1			;Esc
		jnz	met_acc0
		mov	byte [cs:met_com],0
		call	command_path
		ret
met_acc0:
		push	bx
		push	si
		push	di
		push	bp
		push	es
		push	ds
		mov	bx,cs
		mov	ds,bx
		mov	es,bx
		dw ie_sub_bx_bx
		mov	bl,[di-2]
		mov	byte [di+bx],bh	;отметитить конец фразы
		push	di
		mov	dx,[di-3]
		xchg	dl,dh		;dl - конец фразы, dh - конец пути
		mov	cl,[di-1]
		dw ie_xor_ch_ch
		mov	bp,127		;определить размер буфера
		mov	bh,79		;длина экрана
		cmp	di,begin_buf
		jnz	met_acc01
		mov	bp,63		;определить размер буфера
		mov	bh,63
		cmp	ah,79		;в конец
		jnz	met_acc50
		dw ie_mov_dh_dl
		jmp	met_acc10
met_acc50:
		cmp	ah,71		;в начало
		jnz	met_acc01
		jmp	met_acc10
met_acc01:
;обработка клавиши BACKSPACE
		cmp	ah,14		;клавиша забой
		jnz	met_acc1
		dw ie_cmp_dh_cl		;dh-конец пути, cl-положение курсора
		jnz	met_acc02
		jmp	acc_quit
met_acc02:
		dec	dx
		dw ie_mov_dh_cl
		dec	dh		;dx-содер. новое полож. курсора и конца
		dw ie_add_di_cx
		dw ie_mov_si_di
		dec	di
		dw ie_sub_cx_bp
		neg	cx		;места в буфере
		rep	movsb
		jmp	short met_acc10
met_acc1:
		cmp	ah,83		;клавиша удаление
		jnz	met_acc2
		dw ie_cmp_cl_dl
		jnz	met_acc11
		jmp	acc_quit
met_acc11:
		dec	dx
		dw ie_mov_dh_cl		;dx-содер. новое полож. курсора и конца
		dw ie_add_di_cx
		dw ie_mov_si_di
		inc	si
		dw ie_sub_cx_bp
		neg	cx		;места в буфере
		dec	cx
		rep	movsb
		jmp	short met_acc10
;обработка клавиши стрелка вправо
met_acc2:
		cmp	ah,77
		jnz	met_acc4
		dw ie_cmp_dl_cl		;длина фразы и положение курсора
		ja	met_acc21
		jmp	acc_quit
met_acc21:
		dw ie_mov_dh_cl
		inc	dh
		jmp	short met_acc10

;обработка клавиши стрелка влево
met_acc4:
		cmp	ah,75
		jnz	met_acc8
		dw ie_cmp_dh_cl		;dh-конец пути, cl-положение курсора
		jb	met_acc41
		jmp	acc_quit
met_acc41:
		dw ie_mov_dh_cl
		dec	dh		;dh-полож. курсора, dl-конeц фразы
		jmp	short met_acc10

;обработка других клавиш
met_acc8:
		dw ie_mov_dh_cl		;положение курсора старое
		xchg	ax,bp
		dw ie_cmp_dl_al		;длина фразы и размер буфера
		jb	met_acc81
		dw ie_mov_dl_al
		xchg	ax,bp
		jmp	short met_acc10
met_acc81:
		xchg	ax,bp
		dw ie_or_al_al		;символ-признак только вывода
		jz	met_acc10
		inc	dx
		inc	dh		;новое
		dw ie_add_di_bp
		dec	di
		dw ie_mov_si_di
		dec	si
		dw ie_sub_cx_bp
		neg	cx
		dec	cx
		std
		rep	movsb
		cld
		mov	byte [si+1],al
met_acc10:
		pop	di
		mov	ah,byte [di-3]	;конец пути
		dw ie_cmp_dh_dl		;положение курсора и длина фразы
		jb	met_acc17
		dw ie_mov_dh_dl
met_acc17:
		dw ie_cmp_dh_bh		;сравн. полож.курсора с размер. экрана
		jbe	met_acc16
		dw ie_mov_bl_dh
		dw ie_sub_bl_bh
		dw ie_add_bl_ah		;начало фразы
		jmp	short met_acc18
met_acc16:
		dw ie_mov_bl_ah
met_acc18:
		mov	[di-2],dx
		dw ie_mov_al_dl		;сохранить длину фразы
		dw ie_mov_dl_dh		;положение символа с курсором
		dw ie_sub_dl_bl		;положение курсора новое на экране
		dw ie_add_dl_ah
		dw ie_mov_cl_bl
		call	seg_win
		mov	di,160*23
		mov	si,stack0+st0d_com_line
		mov	dh,23
		cmp	bp,127
		jz	met_acc83
		mov	di,160*9+16
		mov	si,begin_buf
		mov	dh,9
met_acc83:
		dw ie_add_si_cx
		dw ie_sub_cl_al	;длина выводимой фразы
		neg	cl
		dw ie_cmp_al_bh	;если длина фразы больше bh, то равна bh
		jb	met_acc12
		dw ie_mov_cl_bh
		dw ie_sub_cl_ah
met_acc12:
;очистить строку
		push	cx
		dw ie_mov_cl_ah	;длина пути
		shl	cl,1
		dw ie_add_di_cx
		dw ie_mov_cl_bh
		dw ie_sub_cl_ah
		inc	cx
		push	di
		mov	ax,0720h
		cmp	bh,63
		jnz	met_acc19
		mov	ah,[ fon3 ]
		add	dl,8		;начальное положение курсора
met_acc19:
		call	cga
		rep	stosw
		pop	di
		pop	cx
		jcxz	met_acc15
met_acc13:
		movsb
		inc	di
		loop	met_acc13
met_acc15:
		mov	ah,2
		dw ie_xor_bh_bh
		int	10h		;переместить курсор
;-------------------------
		push	di
acc_quit:
		pop	di
;-------------------------
		pop	ds
		pop	es
		pop	bp
		pop	di
		pop	si
		pop	bx
met_ent:
		ret
;accept		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE KEY_ENTER
;обработка клавиши Enter
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
key_enter:  ; proc near
		push	cs
		pop	es
		call	indic
		mov	si,stack0+st0d_com_line
		dw ie_sub_ax_ax
		mov	al,[si-2]
		cmp	[si-3],al	;длина строки и начало директории
		jnz	met_ent3
		cmp	byte [act_screen],ah
		jnz	met_ent		;выход, если на экране не оболочка
		mov	di,[met_path+bp]
		call	seg_dat
		dw ie_mov_dx_di
		call	locat_name
		mov	bl,[si-9]		;атрибут
		inc	di
;определение конца пути к файлу
met_ent0:
		inc	di
		cmp	byte [cs:di-2],5ch
		jnz	met_ent01
		dw ie_mov_cx_di
		dec	cx		;смещение к след. символу после "\"
met_ent01:
		cmp	byte [cs:di],"*"
		jnz	met_ent0

;сохранить предыдущую директорию
		jcxz	met_ent1
		cmp	byte [si],"."	;выход из поддиректории?
		jnz	met_ent1		;нет
		push	si
		push	di
		push	ds
		push	cs
		pop	ds
		mov	di,71h
		dw ie_mov_si_cx
		dw ie_sub_cx_cx
met_ent02:
		movsb
		inc	cx
		cmp	byte [si],5ch
		jnz	met_ent02
		inc	cx
		mov	[70h],cl
		mov	[es:di],ch
		pop	ds
		pop	di
		pop	si

;записать имя в path
met_ent1:
		test	bl,10h		;это директория
		jz	met_ent3
met_ent23:
		lodsb
		stosb
		dw ie_or_al_al
		jnz	met_ent23

;перейти в новую директорию
		push	cs
		pop	ds
		mov	ah,3bh		;установить новую директорию
		call	int_21
		jnc	met_ent111
		call	error
met_ent111:
		call	read_drive
		jmp	do_cursor	;сращивание ret
met_ent3:
		push	cs
		pop	ds
		call	locat_name
		call	search_curs
		dw ie_sub_cx_cx
		mov	si,stack0+st0d_com_line
		mov	bx,param_block
		mov	[bx+4],cs
		cmp	[si-3],al	;длина строки и начало директории
		jz	met_ent18
;запуск будет производиться через command.com
met_ent4:
		push	cs
		pop	ds
		call	keep_line
		mov	si,stack0+st0d_com_line
		mov	cl,[si-3]
		dw ie_add_si_cx
		dw ie_sub_ax_cx
		sub	si,4
		add	ax,strict word 4
		dw ie_mov_bp_ax
		mov	ah,"/"
		mov	[si],ax
		mov	word [si+2],"c "
		mov	word [si+bp],0dh		;Enter
		mov	[bx+2],si
		mov	ax,[002ch]		;сегмент окружения
		mov	dx,002ch		;указатель на 0
		dw ie_or_ax_ax
		jz	met_ent9
		mov	ds,ax
		dw ie_sub_si_si
met_ent8:
		mov	cx,8
		mov	di,comspec
		rep	cmpsb
		dw ie_mov_dx_si		;смещ. к имени command.com
		jcxz	met_ent9
		jmp	short met_ent8
;в коммандной строке ничего не вводилось, ввести из таблицы файлов
met_ent18:
		mov	word [bx+2],no_param
		call	indic
		call	locat_name
		mov	di,stack0+st0d_com_line
		mov	al,[di-2]
		dw ie_add_di_ax
		call	seg_dat
		dec	cx
met_ent10:
		inc	cx
		movsb
		cmp	[si-1],ah
		jnz	met_ent10
		mov	di,stack0+st0d_com_line
		dw ie_mov_dx_di
		dw ie_mov_ch_cl
		add	[es:di-2],cx
		dw ie_add_al_cl
		sub	si,4
		cmp	byte [si-1],"."
		jnz	met_ent12
met_ent22:
		mov	di,dat_com
		call	compare
		jz	met_ent21
		mov	di,dat_exe
		call	compare
		jz	met_ent21
		mov	di,dat_bat
		call	compare
		jnz	met_ent12
		call	command_path
		jmp	met_ent4
met_ent12:
		call	clear_path
		ret
met_ent21:
		call	command_path
		push	cs
		pop	ds
		call	keep_line
met_ent9:
		push	ds
		push	cs
		pop	ds
		call	flign
		push	dx
		mov	dx,return
		call	phrase1
		mov	es,[segm_data]
		mov	ah,49h
		int	21h
		pop	dx
		pop	ds
		push	cs
		pop	es
		push	dx
		mov	[cs:handle1],sp
		mov	ax,4b00h		;выполнить программу
		int	21h
		mov	dx,cs
		mov	ds,dx
		cli
		mov	ss,dx
		mov	sp,[handle1]
		sti
		pop	dx
		jnc	met_ent20
		cmp	dx,stack0+st0d_com_line
		jz	met_error0f1
		mov	al,0f1h			;нет command.com
met_error0f1:
		call	error
met_ent20:
		mov	dx,return
		call	phrase1
		call	phrase1
		call	clear_path
		call	command_path
		call	set_segm_data
		pop	ax
		jmp	body
set_segm_data:
		mov	ah,48h
		mov	bx,0ffffh
		int	21h
		push	cs
		pop	ds
		cmp	bh,3
		jae	met_set1
		mov	dx,quit_no_mem
		call	phrase1
		mov	ah,4ch
		int	21h
met_set1:
		mov	ah,48h
		int	21h
		mov	[segm_data],ax
		ret
flign:
		cmp	byte [act_screen],0
		jnz	met_ent25	;на экране не оболочка
		call	mov_out_wind
met_ent25:
                mov     ax,0720h        ;!!! не переставлять !!!
		call	seg_win
		mov	di,160*24
		mov	cx,80
		rep	stosw
		ret
phrase1:
		mov	ah,9
		int	21h
		ret
compare:
		push	si
		mov	cx,4
		rep	cmpsb
		pop	si
		ret
clear_path:
		push	cs
		pop	ds
		dw ie_sub_ax_ax
		mov	si,stack0+st0d_com_line
		mov	al,[si-3]
		dw ie_mov_bp_ax
		mov	byte [si+bp],ah	;0
		dw ie_mov_ah_al
		mov	[si-2],ax
		ret
;сохранить введенную строку в com
keep_line:
		push	si
		push	di
		push	cx
		mov	si,stack0+st0d_com_line
		dw ie_mov_di_si
		dw ie_sub_cx_cx
		mov	cl,[si-3]
		dw ie_add_si_cx
		sub	cl,[di-2]
		neg	cl
		mov	di,stack0+st0d_com_line1
		mov	byte [di-1],cl
		inc	cx
		rep	movsb
		mov	byte [met_keep_line] ,0ffh
		pop	cx
		pop	di
		pop	si
		ret
;key_enter	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE CURSOR
;клавиши управления курсором
;входные:ax - код нажатой клавиши, сгенерированный int 16h
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
cursor:  ; proc near
		cmp	byte [cs:act_screen],0
		jz	met_cur15	;выход, если на экране не оболочка
		ret
met_cur15:
		push	ds
		push	es
		call	begin_param8
		call	indic
;проверка правильности положения курсора на панели
		mov	dx,[num_pos0+bp]
		dw ie_or_dx_dx
		jz	met_contr5
		cmp	dx,[max_pos0+bp]
		jb	met_contr5
		mov	dx,[max_pos0+bp]
		dec	dx
		dw ie_mov_bx_dx
		sub	bx,17
		jns	met_contr4
		dw ie_sub_bx_bx
met_contr4:
		mov	[high_pos0+bp],bx
met_contr5:
		mov	bx,[met_dir0+bp]
;определяем обсолютное смещение строки с курсором на экране
		dw ie_mov_si_dx
		call	mul_48
		mov	al,[cs: fon0 ]
		call	cga
		cmp	word [max_pos0+bp],0
		jz	met_cur1
		cmp	ah,82		;Insert
		jnz	met_cur01
		test	byte [bx+si+1],10h
		jnz	met_cur35
		not	byte [bx+si]
		call	select_stat
met_cur35:
		mov	ah,80		;эмулируем нажатие стрелки вниз
met_cur01:
		cmp	byte [bx+si],0ffh	;файл выделен?
		jnz	met_cur1		;нет
		mov	al,[cs: fon1 ]
met_cur1:
		call	change_cursor
		cmp	byte [cs:met_info],0
		jnz	met_cur13
		cmp	ah,15			;Табуляция
		jnz	met_cur13
		xor	bp,2
		mov	bx,[met_dir0+bp]
		mov	dx,[num_pos0+bp]
		shr	bp,1
		mov	word [cs: act_pan ],bp
		dw ie_mov_cx_bp
		mov	byte [cs:act_drive],cl
		shl	bp,1
		call	write_path
		call	command_path
		call	set_new_dir
		mov	ah,15
		call	cga
met_cur13:
		mov	cx,[high_pos0+bp]
;----------------------------------------------
		dw ie_sub_si_si		;подготовка к roll_screen
		dw ie_or_bp_bp
		jz	met_cur11
		add	si,80
met_cur11:
		dw ie_mov_di_si
;----------------------------------------------
		cmp	ah,80		;стрелка вниз
		jnz	met_cur4
		dw ie_or_dx_dx
		jz	met_cur12
		inc	dx
		cmp	dx,word [max_pos0+bp]
		pushf
		dec	dx
		popf
		jae	met_cur40
met_cur12:
		inc	dx
		add	cx,18
		dw ie_cmp_dx_cx
		jb	met_cur40
		inc	word [high_pos0+bp]
		call	roll_up
met_cur40:
                jmp     met_cur8
met_cur4:
		cmp	ah,72		;стрелка вверх
		jnz	met_cur5
		dw ie_or_dx_dx
		jz	met_cur50
		dec	dx
		dw ie_cmp_dx_cx
		jae	met_cur50
		dec	word [high_pos0+bp]
		call	roll_down
met_cur50:
                jmp     short met_cur40
met_cur5:
		cmp	ah,71		;к началу
		jnz	met_cur18
		cwd
                jmp     short met_cur24
met_cur18:
		cmp	ah,79		;к концу
		jnz	met_cur19
		mov	dx,[max_pos0+bp]
		dec	dx
                jmp     short met_cur24
met_cur19:
		cmp	ah,73		;на страницу вверх
		jnz	met_cur23
		sub	dx,17
		ja	met_cur22
		cwd
                jmp     short met_cur24
met_cur22:
		cmp	dx,17
		ja	met_cur24
		mov	dx,17
                jmp     short met_cur24

met_cur23:
		mov	cx,[max_pos0+bp]	;используется далее !!!
		cmp	ah,81		;на страницу вниз
		jnz	met_cur25
		add	dx,17
		dec	cx
		dw ie_cmp_dx_cx
		jbe	met_cur24
		dw ie_mov_dx_cx
met_cur24:
		jmp	short met_cur48
met_cur25:
		cmp	ah,78			;"+"
		jnz	met_cur27
		jcxz	met_cur20
met_cur37:
		mov	si,2
		call	func_select
		cmp	ah,1			;Esc
		jz	met_cur20
		cmp	ah,28			;Enter
		jnz	met_cur37
met_cur26:
		test	byte [bx+si+1],10h
		jnz	met_cur36
		cmp	byte [bx+si],0
		jnz	met_cur36
		not	byte [bx+si]
met_cur36:
		add	si,48
		loop	met_cur26
		call	select_stat
met_cur20:
		jmp	short met_cur48
met_cur27:
		cmp	ah,74			;"-"
                jnz     met_cur8
		jcxz	met_cur28
met_cur39:
		dw ie_sub_si_si
		call	func_select
		cmp	ah,1			;Esc
		jz	met_cur28
		cmp	ah,28			;Enter
		jnz	met_cur39
met_cur29:
		mov	byte [bx+si],0
		add	si,48
		loop	met_cur29
met_cur28:
		call	select_stat
met_cur48:
		mov	[num_pos0+bp],dx
		cmp	word [max_pos0+bp],1
		jbe	met_cur21
		call	write_pan
met_cur8:
		cmp	word [max_pos0+bp],1
		ja	met_cur16
met_cur21:
		jz	met_cur17
                jmp     short cur_quit
met_cur17:
		dw ie_sub_dx_dx
met_cur16:
		dw ie_mov_si_dx
		call	mul_48
		mov	al,[cs: fon3 ]
		cmp	byte [bx+si],0ffh	;файл выделен?
		jnz	met_cur9		;нет
		mov	al,[cs: fon6 ]
met_cur9:
		call	change_cursor
		mov	[num_pos0+bp],dx
cur_quit:
		pop	es
		pop	ds
		ret

;функция запроса select/unselect
func_select:
		push	dx
		push	cx
		push	ds

		push	cs
		pop	ds
		mov	cx,061ch
                mov     dx,0a34h
		lea	si,[select+si]
		mov	al,[ fon4 ]
		dw ie_mov_ah_al
		call	window
		mov	dh,08
		add	si,9
		call	print_name
		dw ie_sub_si_si
		call	halt
		call	clear_window
		pop	ds
		pop	cx
		pop	dx
		ret

change_cursor:
		push	cx
		dw ie_mov_di_dx
		sub	di,[high_pos0+bp]
		add	di,2
		call	mul_80
		shl	di,1
		dw ie_or_bp_bp
		jz	met_cur0
		add	di,80
met_cur0:
		add	di,3		;фон второго символа в строке
		call	cga1
		mov	cx,38
met_cur3:
		stosb
		inc	di
		loop	met_cur3
		pop	cx
		ret
;прокрутка экрана вверх
roll_up:
		push	ds
		mov	ds,[cs:segm_wind]
		add	di,160*2
		add	si,160*3
		dw ie_sub_ax_ax
met_cur6:
		dec	ax
		jns	met_cur_a
		mov	ax,8
		call	cga
met_cur_a:
		mov	cx,40
		rep	movsw
		add	si,80
		add	di,80
		cmp	si,160*20
		jb	met_cur6
		dw ie_mov_si_dx
		call	write_line
		pop	ds
		ret
;прокрутка экрана вниз
roll_down:
		push	ds
		mov	ds,[cs:segm_wind]
		add	si,160*18
		add	di,160*19
		dw ie_sub_ax_ax
met_cur7:
		dec	ax
		jns	met_cur_b
		mov	ax,8
		call	cga
met_cur_b:
		mov	cx,40
		rep	movsw
		sub	si,160+80
		sub	di,160+80
		cmp	si,160*2
		jae	met_cur7
		dw ie_mov_si_dx
		call	write_line
		pop	ds
		ret

;cursor		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE COMMAND_PATH
;построение в 24 строке пути, вывод его в буфер, указатель на конец строки
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
command_path:  ; proc near
		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		push	bp
		call	indic
		push	cs
		push	cs
		pop	ds
		pop	es
		mov	bx,begin_buf
met_com7:
		dw ie_mov_di_bx
		mov	si,[met_path+bp]
;записать путь к файлу в буфер
		dw ie_sub_dx_dx
met_com01:
		inc	si
		inc	dx
		cmp	byte [si-1],0
		jz	met_com03
		cmp	byte [si-1],"*"
		jnz	met_com01
met_com03:
		dec	dx
		dw ie_sub_ax_ax
		cmp	byte [met_com],al
		jnz	met_com05
		dw ie_mov_dh_dl
		mov	byte [bx-3],dl	;номер символа после пути
		mov	word [bx-2],dx	;всего символов введено
met_com05:
		dw ie_mov_si_bx
		mov	dh,[bx-3]	;конец директории
		dw ie_sub_ax_ax
		dw ie_sub_cx_cx
		mov	cl,[bx-2]	;положение последнего символа
		dw ie_cmp_cl_dh
		jae	met_com82
		dw ie_mov_cl_dh		;положение послед. символа и конец дир.
		mov	[bx-2],cl
met_com82:
		dw ie_cmp_dl_dh
		jbe	met_com5
;обратный сдвиг
		mov	cl,127
		cmp	di,begin_buf
		jnz	met_com06
		mov	cl,79
met_com06:
		push	cx
		dw ie_add_si_cx
		dw ie_mov_di_si
		dw ie_mov_al_dl
		dw ie_sub_al_dh		;разность
		dw ie_sub_si_ax
		dw ie_sub_cl_dl
		inc	cx
		std
		rep	movsb
		cld
		pop	cx
		dw ie_mov_ah_al
		mov	si,[bx-2]
		dw ie_add_ax_si
		cmp	ah,79
		jbe	met_com12
		mov	ah,79
met_com12:
		dw ie_cmp_al_cl
		jb	met_com14
		dw ie_mov_al_cl
met_com14:
		mov	[bx-2],ax	;символ с курсором и последний
		jmp	short met_com6
met_com5:
;прямой сдвиг
		dw ie_mov_al_dh
		dw ie_add_si_ax
		dw ie_mov_di_si
		dw ie_sub_al_dl	;разность
		dw ie_sub_di_ax
		dw ie_sub_cl_dh
		rep	movsb
		dw ie_mov_ah_al
		sub	word [bx-2],ax
		cmp	byte [bx-1],79
		jb	met_com6
		add	byte [bx-1],al	;символ с курсором
;записать новый путь
met_com6:
		mov	byte [bx-3],dl	;номер символа после пути
		mov	si,word [met_path+bp]
		dw ie_mov_di_bx
		dw ie_mov_cl_dl
		rep	movsb
		cmp	bx,begin_buf
		jnz	met_com8
		mov	bx,stack0+st0d_com_line
		jmp	met_com7
;очистить 24 строку
met_com8:
		mov	byte [met_com],1	;метка, что проход не первый

;переслать путь на экран в 24 строку
		dw ie_mov_cl_dl
		call	seg_win
		mov	di,160*23
		mov	si,stack0+st0d_com_line
		mov	al,[fon2]
		call	cga
met_com02:
		movsb
		stosb
		loop	met_com02
		cmp	byte [es:di-2],5ch
		jnz	met_com04
		mov	byte [es:di-2],">"
met_com04:
		dw ie_xor_al_al		;метка вывода только строки
		mov	di,stack0+st0d_com_line
		call	accept
		pop	bp
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret
;command_path	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE SET_NEW_DIR
;установление текущей директории
;необходимо ставить после command_path
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
set_new_dir:  ; proc near
		push	ax
		push	dx
		push	si
		push	ds
		push	cs
		pop	ds
		mov	si,stack0+st0d_com_line
		call	set_drive
		dw ie_sub_ax_ax
		mov	al,[si-3]
		dw ie_add_si_ax
		cmp	byte [si-2],":"
		jz	met_com15
		dec	si
met_com15:
		mov	al,[si]
		mov	[si],ah	;0
		mov	dx,stack0+st0d_com_line
		push	ax
		mov	ah,3bh		;установить новую директорию
		int	21h
		pop	ax
		mov	[si],al
		pop	ds
		pop	si
		pop	dx
		pop	ax
		ret
;set_new_dir	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE MAKDIR
;создание директории на активной панели
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
makdir:  ; proc near
		mov	si,dat_mkdir
		mov	di,create_dir
		call	begin_param10
met_mak1:
		call	accept
		call	halt
met_mak2:
		cmp	ah,1
		jz	met_mak9
		cmp	ah,28
		jnz	met_mak1
		dw ie_mov_dx_di
		mov	ah,39h		;создать директорию
		call	int_21
		jnc	met_mak10
		call	error
met_mak9:
		call	clear_window
		call	command_path
		ret
met_mak10:
		call	clear_window
		mov	cx,10h		;поиск директории
		call	indic
		mov	ah,4eh
		call	int_21
		mov	dx,80h+30	;смещение к имени в DTA
		mov	ah,4eh
		int	21h
		jnc	met_mak8
		mov	[keep_file],ch	;0
		pop	ax
		jmp	met_080
met_mak8:
		dw ie_mov_si_dx
		mov	ax,met_de15
		push	ax
		push	ds
		jmp	met_de777
locat_name:
		mov	si,[num_pos0+bp]
		call	mul_48
		add	si,[met_dir0+bp]
		add	si,10
		ret
long_window:
		mov	cx,0704h
                mov     dx,0b4ch
		mov	al,[ fon4 ]
		dw ie_mov_ah_al
		inc	si
		call	window
		ret
;makdir		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE HELP
;построение помощи
;выходные :прерывание 16h
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
help:  ; proc near
		int3
		mov	si,sp_hlp
		call	load_sp_file
		jnc	met_hlp0
		mov	al,92h		; не обнаружен sp.mnu
		call	error
		ret
met_hlp0:
		mov	cx,0306h
		mov	dx,134ah
		mov	si,sparrow
		mov	ah,[cs: fon3 ]
		dw ie_mov_al_ah
		call	window
		call	seg_win
		mov	di,160*4+16
		dw ie_sub_si_si
		mov	bx,15
met_hlp1:
		mov	cx,40h
                test    bl,2
		jz	met_hlp2
		call	cga
met_hlp2:
                lodsb
                xor     al,xor_byte
                stosb
		inc	di
		loop	met_hlp2
		add	di,160-40h*2
		inc	si		;пропустить перевод строки и возврат к.
		inc	si
		dec	bx
		jnz	met_hlp1
		call	halt
		call	clear_window
		ret
;help		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;                       SUBROUTINE MENU
;выбор из меню
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
menu:  ; proc near
;найти на диске файл sp.mnu и загрузить его
		mov	si,sp_mnu
		call	load_sp_file
		jnc	met_us8
met_us48:
		mov	al,91h		; не обнаружен sp.mnu
		call	error
		ret
met_us8:
		dw ie_sub_si_si
		dw ie_sub_dx_dx
		mov	[ds:bp],dl
		mov	bx,20
met_us9:
		call	scasb_menu
		dw ie_or_al_al
		jnz	met_us10
		inc	dx
		push	si
		call	str_search
		pop	cx
		dw ie_sub_cx_si
		neg	cx
		dw ie_cmp_cx_bx
		jbe	met_us9
		dw ie_mov_bx_cx
		jmp	short met_us9
met_us10:
;определить размер файла и вывести рамку с содержимым
		dw ie_or_dx_dx
		jz	met_us48
		add	bx,4
		cmp	bx,80
		jbe	met_us11
		mov	bx,80
met_us11:
		mov	[cs:6eh],bl		;длина окна
		sub	byte [cs:6eh],3	;запомнить длину фразы
;определить размер окна
		shl	bl,1
		dw ie_mov_cx_bx
		dw ie_sub_ax_ax
;определить, сколько будет строчек в окне
met_us30:
		dw ie_add_cx_bx
		cmp	cx,size_wind
		jae	met_us32
		inc	ax
		dw ie_cmp_al_dl
		jb	met_us30
		inc	ax
met_us32:
		shr	bl,1
		mov	cx,0350h
		cmp	al,17
		jbe	met_us14
		dw ie_xor_ch_ch
		cmp	al,22
		jbe	met_us14
		mov	al,22
met_us14:
		mov	[cs:6fh],al	;запомнить количество строк
		dec	byte [cs:6fh]
		dw ie_mov_dh_ch
		dw ie_add_dh_al
		dw ie_sub_cl_bl
		shr	cl,1
		dw ie_mov_dl_cl
		dw ie_add_dl_bl
		mov	si,user_menu
		mov	al,[cs: fon3 ]
		dw ie_mov_ah_al
		call	window
;определить начало вывода на экран
		dw ie_mov_dl_ch
		dw ie_xor_dh_dh
		dw ie_mov_di_dx
		call	mul_80
		dw ie_mov_dl_cl
		dw ie_add_di_dx
		shl	di,1
		add	di,164	;сдвинуть на след. строку и две позиции
		push	di	;запомнить начальную позицию на зкране
		dw ie_mov_dx_di
		call	seg_win
		dw ie_sub_si_si
		mov	bh,[cs:6fh]
;вывод на экран
met_us15:
		call	cga
met_us20:
		dw ie_xor_cx_cx
		mov	cl,byte [cs:6eh]
met_us16:
		dw ie_cmp_si_bp
		jae	met_us50
		lodsb
		cmp	al,0dh
		jz	met_us17
		sub	al,9
		jz	met_us18
		add	al,9
met_us18:
		stosb
		inc	di
		loop	met_us16
met_us17:
		call	scasb_menu
		dw ie_or_al_al
		jnz	met_us50
		add	dx,160
		dw ie_mov_di_dx
		cmp	di,160*22
		jae	met_us50
		dec	bh
		jz	met_us50
		test	bh,1
		jz	met_us15
		jmp	short met_us20
met_us50:
		pop	di		;восстановить начальн. позиц.
		inc	di
		dw ie_mov_dx_di		;сохранить начальн. позиц.
		dw ie_sub_bx_bx
;установить курсор на верхний файл и отслеживая нажатие клавиш перемещать его
met_us52:
		dw ie_sub_cx_cx
		call	set_fon_line
		call	halt
		call	clear_fon_line
		dw ie_sub_si_si
		cmp	ah,28		;Enter
		jnz	met_us63
		jmp	met_us64
met_us63:
		cmp	ah,1		;Esc
		jnz	met_us80
		call	clear_window
		ret
met_us80:
		cmp	ah,80		;стрелка вниз
		jnz	met_us54
		add	di,160
		inc	bx
		cmp	bl,[cs:6fh]
		jb	met_us52
		dw ie_xor_bl_bl
		dw ie_mov_di_dx
		jmp	short met_us52
met_us54:
		cmp	ah,72		;стрелка вверх
		jnz	met_us60
		sub	di,160
		dec	bx
		jns	met_us52
		mov	bl,[cs:6fh]
		dw ie_xor_bh_bh
		dec	bx
		dw ie_mov_di_bx
		call	mul_80
		shl	di,1
		dw ie_add_di_dx
		jmp	short met_us52
met_us60:
		dw ie_or_al_al
		jnz	met_us74
;поиск F1 - F10
		sub	ah,59-"1"	;получим число
		cmp	ah,"1"		;F1
		jb	met_us52
		cmp	ah,":"		;F10
		ja	met_us52
		dw ie_sub_si_si
		mov	cx,"Ff"
met_us31:
		call	scasb_menu
		dw ie_or_al_al
		jnz	met_us52
		call	func_key
		jnc	met_us2
		add	si,4
		jmp	short met_us31
met_us45:
		jmp	met_us52
met_us74:
;поиск буквы
		cmp	al," "
		jb	met_us45
		dw ie_xor_ah_ah
		dw ie_mov_cl_al
		dw ie_mov_ch_cl
		cmp	al,"A"
		jb	met_us41
		cmp	al,"Z"
		jbe	met_us44
		cmp	al,"a"
		jb	met_us41
		cmp	al,"z"
		ja	met_us41
met_us44:
		or	cl,20h
		and	ch,11011111b
met_us41:
		call	scasb_menu
		dw ie_or_al_al
		jnz	met_us45
		call	key
		jnc	met_us2
		add	si,4
		jmp	short	met_us41

;определить функ. клавишу по ah, если соотв., то bh - номер строки и clc
func_key:
		cmp	[si],cl
		jz	met_fk1
		cmp	[si],ch
		jnz	met_fk8
met_fk1:
		cmp	[si+1],ah
		jz	met_fk6
		cmp	[si+3],ah	;определить F10
		jnz	met_fk8
met_fk6:
		dw ie_mov_bl_al
		shr	bl,1
		ret
met_fk8:
		stc
		ret
key:
		cmp	[si],cl
		jz	met_k1
		cmp	[si],ch
		jnz	met_fk8
met_k1:
		cmp	byte [si+1],":"
		jnz	met_fk8
		dw ie_mov_bl_ah
		shr	bl,1
		ret
;файл выбран, запустить через command.com
met_us64:
		call	clear_window
met_us66:
		call	scasb_menu
		add	si,4
		dec	bx
		jns	met_us66
met_us2:
		dw ie_sub_bx_bx
		call	str_search
		dec	si
met_us69:
		inc	si
		cmp	byte [si]," "
		jbe	met_us69
common_edit:
		push	cs
		pop	es
		mov	di,stack0+st0d_com_line
		dw ie_mov_bp_di
		mov	bl,[es:di-3]
		dw ie_add_di_bx
		cmp	cx,127
		jb	met_us70
		mov	cx,127
		dw ie_sub_cl_bl
met_us70:
		cmp	byte [si]," "
		jb	met_us72
		inc	bx
		movsb
		loop	met_us70
met_us72:
		push	cs
		pop	ds
		mov	byte [di],0
		dw ie_mov_bh_bl
		mov	[bp-2],bx
		call	command_path
		pop	ax
		call	key_enter	;запуск
set_fon_line:
		mov	al,[cs:fon2]
		mov	cl,[cs:6eh]	;длина строки
		call	cga1
met_us91:
		stosb
		inc	di
		loop	met_us91
		ret
clear_fon_line:
		push	ax
		mov	al,[cs: fon3 ]
		mov	cl,[cs:6eh]
		inc	cx
		std
		call	cga
met_us90:
		stosb
		dec	di
		loop	met_us90
		inc	di
		inc	di
		pop	ax
		cld
		ret
;занести в путь в окружение один из файлов mnu или hlp
;входной ds:si - смещение к имени файла
;выходной ds:dx - смещение к пути bp - длина считанная файла
load_sp_file:
		call	save_sp_name
		mov	ax,3d00h
		call	int_21
		mov	[cs:handle0],ax
		jc	met_us7
		call	beg_free_m
		cwd
		dw ie_mov_bx_ax
		mov	cx,[cs:size_block]
		mov	ah,3fh
		int	21h
		dw ie_mov_bp_ax
close_file:
		mov	bx,[cs:handle0]
close_file3:
		pushf
		mov	ah,3eh
		int	21h
		popf
met_us7:
		ret
save_sp_name:
		push	cs
		pop	es
		mov	dx,stack0+st0d_path_sp
		mov	di,[path_sp_end]
		mov	cx,7
		rep	movsb
		ret

scasb_menu:
		push	bx
		push	cx
		dw ie_xor_al_al
		dw ie_xor_bx_bx
met_us3:
		inc	bx
		cmp	bl,4
		jae	met_us5
		cmp	byte [si+bx],":"
		jnz	met_us3
		inc	bx
		cmp	byte [si+bx]," "
		jz	met_us4
		cmp	byte [si+bx],9	;tab
		jz	met_us4
met_us5:
		dw ie_xor_bl_bl
		call	str_search
		dw ie_or_al_al
		jz	met_us3
met_us4:
		pop	cx
		pop	bx
		ret

;menu            endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE SETUP
;запись текущего состояния программы на диск
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
setup:  ; proc near
		mov	si,dat_setup
		mov	di,phrase_setup
		call	needs
		jc	met_set10
		mov	si,sp_com
		call	save_sp_name
		call	create_new_file
		jc	met_set5
		dw ie_mov_bx_ax
		push	cs
		pop	ds
		mov	dx,100h
		dw ie_xor_bp_bp
		xchg	word [met_com],bp
		call	change_palette
		mov	cx,stack0
		dw ie_sub_cx_dx
		mov	ah,40h
		int	21h
		pushf
		call	change_palette
		popf
		xchg	word [met_com],bp
		jc	met_set5
		dw ie_cmp_ax_cx
		jz	met_set10
		mov	al,8
met_set5:
		call	error
met_set10:
		mov	ah,3eh
		int	21h
		call	command_path
		ret
;setup		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;                       SUBROUTINE EXEDIT
;выбор из меню
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
exedit:  ; proc near
		mov	si,dat_menu+1
		mov	di,extern_edit
		call	needs
		jnc	met_change1
		mov	di,ext_edit+2
		jmp	short met_change2
met_change1:
		mov	si,dat_edit
		mov	di,extern_edit+23
		call	begin_param10
met_men1:
		call	accept
		call	halt
met_men2:
		cmp	ah,1
		jz	met_change
		cmp	ah,28
		jnz	met_men1
		xchg	si,di
		mov	di,ext_edit+2
		push	cs
		pop	es
		dw ie_sub_cx_cx
		mov	cl,[si-2]
		rep	movsb
met_change2:
		mov	byte [di]," "
met_change:
		call	command_path
		call	clear_window
met_change3:
		ret
;exedit          endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE CHANGE_POS
;смена текущего диска
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
change_pos:  ; proc near
;вывести окно на сменяемую панель с общим числом дисководов
;определить необходимую длину рамки
		call	mul_2
		cmp	bl,6*2
		ja	met_cd10
		mov	bl,6*2
met_cd10:
		dw ie_sub_bp_bp
		mov	cx,0514h
		mov	dx,0914h
		cmp	ah,104  	;Alt + F1
		jz	met_cd11
		cmp	ah,105          ;Alt + F2
		jnz	met_change3	;quit
		mov	bp,40
met_cd11:
		mov	bh,byte [act_drive+1]	; all drives
		dw ie_sub_cl_bl
		jae	met_cd16
		dw ie_add_bl_bh
		add	bl,5
		dw ie_or_bp_bp
		jz	met_cd13
		mov	dl,80
		dw ie_mov_cl_dl
		dw ie_sub_cl_bl
		jmp	short	met_cd17

met_cd13:
		dw ie_xor_cl_cl
		dw ie_mov_dl_bl
		jmp	short	met_cd17

met_cd16:
		dw ie_add_dl_bl
		dw ie_add_cx_bp
		dw ie_add_dx_bp
met_cd17:
		mov	si,drive_letter
		mov	al,[ fon4 ]
		dw ie_mov_ah_al
		call	window
		dw ie_or_bp_bp
		jz	met_cd14
		mov	bp,2
met_cd14:
		mov	di,[ds:met_path+bp]
		dw ie_sub_dl_cl
		dw ie_sub_dl_bh
		dw ie_sub_dl_bh
		dw ie_sub_dl_bh
		shr	dl,1
		dw ie_add_dl_cl
		dec	dx			;dx - begin position drive A:
		sub	dh,2
		dw ie_mov_ch_dl
		mov	al,[di]
		sub	al,"A"
		push	cx
		push	bx
		dw ie_xor_cx_cx
		dw ie_mov_cl_bh
		dw ie_xor_bx_bx
.cycle1:
		cmp	byte [stack0+st0d_array_drive+bx],al
		jz	.exit_cycle1
		inc	bx
		loop	.cycle1
.exit_cycle1:
		dw ie_mov_al_bl
		pop	bx
		pop	cx
		dw ie_mov_bl_al
met_cd2:
		dw ie_mov_dl_ch
		dw ie_xor_cl_cl
		mov	si,stack0+st0d_array_drive
		push	si
met_cd19:
;bl - выделенный драйвер, cl - выводимый на экран драйвер bh - всего драйв.

		mov	al,byte [si]
		push	si
		mov	si,drive
		add	al,"A"
		mov	[si],al
		mov	al,[ fon4 ]
		dw ie_cmp_bl_cl
		jnz	met_cd20
		mov	al,[ fon3 ]
met_cd20:
		call	phrase
		pop	si

		add	dl,3
		inc	si
		inc	cx
		dw ie_cmp_cl_bh
		jbe	met_cd19
		pop	si

		call	halt
		cmp	ah,1		;Esc
		jz	met_cd_quit
		cmp	ah,28		;Enter
		jz	met_cd4
		cmp	ah,75		;стрелка влево
		jnz	met_cd3
		dec	bl		;имя драйвера равно "A"
		jns	met_cd2
		dw ie_mov_bl_bh
		jmp	short met_cd2
met_cd3:
		cmp	ah,77		;стрелка вправо
		jnz	met_cd5
		dw ie_cmp_bl_bh		;имя драйвера равно максимум.
		jnz	met_cd7		;да, увеличивать нельзя-повтор.
		dw ie_xor_bl_bl
		jmp	short met_cd2
met_cd7:
		inc	bx		;увеличить
		jmp	short met_cd2
met_cd5:
		call	scan_xlat
		sub	al,"A"
		push	cx
		push	bx
		dw ie_xor_cx_cx
		dw ie_mov_cl_bh
		dw ie_xor_bx_bx
		inc	cx
.cycle:
		cmp	byte [si+bx],al
		jz	.exit_cycle
		inc	bx
		loop	.cycle
.exit_cycle:
		dw ie_mov_al_bl
		pop	bx
		dw ie_or_cx_cx
		pop	cx
		jz	met_cd2
		dw ie_mov_bl_al
met_cd4:
		dw ie_xor_bh_bh
		mov	al,byte [si+bx]
		add	al,"A"
		mov	[di],al
;вызвать функцию просмотра и отображения на экране директории
		call	clear_window
		dw ie_sub_ax_ax
		cmp	[met_info],al
		jz	met_cd30
		mov	al,byte [act_pan]
		shl	al,1
		dw ie_cmp_bp_ax
		jz	met_cd30
		not	byte [met_info]
met_cd30:
		call	inst_dir1
		jmp	do_cursor
met_cd_quit:
		call	clear_window
		ret
mul_2:
		mov	bl,byte [act_drive+1]
		shl	bl,1
met_c00:
		ret

;change_pos	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE COPY
;копирование файлов с активной панели на другую
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
ren_mov:
		not	byte [met_renmov]

copy:  ; proc near

		call	indic
		cmp	[max_pos0+bp],cx
		jz	met_c00
		mov	[met_overwrite],cl
		call	begin_param8
		call	locat_name
		mov	di,[sum_sel0+bp]
		dw ie_or_di_di
		jnz	met_c2
		test	byte [si-9],10h		;директория
		jz	met_c2
		cmp	byte [cs:met_renmov],0ffh
		jnz	met_c00
		cmp	byte [si],"."		;корневая директория
		jz	met_c00
met_c2:
		push	si
		push	cs
		pop	ds
		cmp	byte [met_renmov],0ffh
		jnz	met_c13
		mov	si,dat_renmov
		call	long_window
		mov	si,dat_move
		jmp	short met_c16
met_c13:
		mov	si,dat_copy
		call	long_window
met_c16:
		mov	dx,0807h
		call	phrase
		dw ie_or_di_di
		jz	met_cop30
                mov     si,dat_delete_files
                mov     dl,0eh
		call	phrase
                push    ax
                mov     ax,[sum_sel0+bp]
		cwd
                mov     di,160*8+32
		call	number
                pop     ax
                mov     dx,0817h
		jmp	short met_c7
met_cop30:
		call	seg_dat
		mov	dl,0ch
		pop	si
		push	si
		dw ie_sub_bx_bx
		call	phrase
met_c3:
		inc	bx
		cmp	byte [si+bx-1],0
		jnz	met_c3
                dw ie_add_dx_bx
met_c7:
		push	cs
		push	cs
		pop	ds
		pop	es
                mov     si,dat_to
		call	phrase
		xor	bp,2
		mov	si,[met_path+bp]
		xor	bp,2
		mov	di,begin_buf
		dw ie_mov_bx_di
met_c4:
		lodsb
		stosb
		dw ie_or_al_al
		jz	met_c5
		sub	al,"*"
		jnz	met_c4
		mov	[di-1],al
met_c5:
		dw ie_sub_di_bx
		dec	di
		mov	[bx-2],di
		mov	[bx-3],al
		pop	si
		mov	di,begin_buf
		call	seg_dat
		cmp	word [sum_sel0+bp],0
		jnz	met_c50
		test	byte [si-9],10h
		jnz	met_c51
met_c50:
		call	accept
		call	halt
		cmp	ah,1	;esc
		jz	met_c10
		cmp	ah,28	;enter
		jz	met_c52
		cmp	ah,59	;не функциональная
		jae	met_c6
met_c51:
		push	ax
		call	begin_param1
		pop	ax
met_c6:
		call	accept
		call	halt
met_c8:
		cmp	ah,1
		jz	met_c10
		cmp	ah,28
		jnz	met_c6
met_c52:
		call	clear_window
;сделать курсор невидимым
		call	clear_cursor
		cmp	word [sum_sel0+bp],0
		jz	met_c9
		mov	cx,[max_pos0+bp]
		mov	si,[met_dir0+bp]
		add	si,10
met_c18:
		cmp	byte [si-10],0ffh
		jnz	met_c28
		call	copy_file
		jnc	met_c20
		cmp	ah,1
		jz	met_c12
		cmp	ah,31		;skip
		jz	met_c28
		call	error
		jmp	short met_c12
met_c20:
		mov	byte [si-10],0feh	;файл удален
met_c28:
		add	si,48
		loop	met_c18
		jmp	short met_c12
met_c9:
		call	copy_file
		jnc	met_c39
		cmp	ah,1
		jz	met_c10
		cmp	ah,31
		jz	met_c10
		call	error
met_c10:
		call	clear_window
		call	command_path
		jmp	short met_c31
met_c39:
		mov	byte [si-10],0feh
met_c12:
		mov	byte [cs:keep_file],0
		call	memory_free
		call	locat_name
		cmp	byte [cs:met_renmov],0ffh
		jnz	met_c26
;определить позицию курсора на активной панели
		mov	cx,1
		cmp	word [sum_sel0+bp],0
		jz	met_c30
		mov	cx,[max_pos0+bp]
		sub	cx,[num_pos0+bp]
		jcxz	met_c33
met_c37:
		cmp	byte [si-10],0feh	;файл удален
		jnz	met_c33
met_c30:
		add	si,48
		loop	met_c37
		jmp	short met_c33
met_c26:
		xor	bp,2
		call	locat_name
met_c33:
		call	inst_dir
		call	inst_dir2
;определить положение курсора, если переименовывалась директория
		test	byte [cs:attrib_file],10h
		jz	met_c34
		call	indic
		cmp	word [num_pos0+bp],0
		jz	met_c34
		dec	word [num_pos0+bp]
met_c34:
		call	do_cursor
		not	byte [cs:keep_file]
met_c31:
		call	set_cursor
		ret
inst_dir2:
		xor	bp,2
		call	locat_name
inst_dir:
		call	search_curs
inst_dir1:
		mov	si,[met_path+bp]

		dw ie_sub_ax_ax
		cmp	[cs:met_info],al
		jz	met_infoend
		mov	al,byte [cs:act_pan]
		dw ie_add_al_al
		dw ie_cmp_ax_bp
		jnz	met_read
		call	set_drive
		call	info
met_infoend:
		push	ds
		push	cs
		pop	ds
		dw ie_mov_dx_si
		mov	bl,"*"
met_c14:
		inc	si
		cmp	byte [si],bl
		jnz	met_c14
		cmp	byte [si-2],":"
		jz	met_c15
		dec	si
		mov	bl,5ch
met_c15:
		mov	byte [si],0
		mov	ah,3bh		;установить новую директорию
		call	int_21
		jnc	met_c116
		cmp	al,83
		jnz	met_c116
		mov	[noread],al
met_c116:
		mov	byte [si],bl
		call	read_drive

		pop	ds
met_read:
		ret
;copy		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE COPY_FILE
;копирование одного файла на противоположную панель
;si должен содержать смещение к старому имени файла
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
copy_file:  ; proc near
		push	es
		push	ds
		push	bx
		push	cx
		push	dx
		push	si
		mov	al,[si-9]
		mov	[cs:attrib_file],al
;занести информацию о рабочих дисках
		mov	di,[met_path+bp]
		mov	bl,[cs:di]
		sub	bl,"A"
		dw ie_mov_bh_bl
		mov	word [cs:drive_file],bx
		mov	di,begin_buf
		cmp	byte [cs:di+1],":"
		jnz	met_cop02
		test	al,10h	;директория
		jz	met_cop40
		mov	byte [cs:di],bl
		add	byte [cs:di],"A"
		jmp	short met_cop02
met_cop40:
		mov	bh,byte [cs:di]
		or	bh,20h
		sub	bh,"a"
		mov	byte [cs:drive_file+1],bh
met_cop02:
;записать имя выходного файла, если он принят по умолчанию

		mov	ah,0eh
		dw ie_mov_dl_bl
		call	int_21

		push	si
		dw ie_sub_ax_ax
		mov	al,[cs:di-2]
		dw ie_add_di_ax
		cmp	byte [cs:di-1],5ch
		jnz	met_cop1
met_cop01:
		lodsb
		stosb
		dw ie_or_al_al
		jnz	met_cop01
met_cop1:
		mov	cx,061ah
		mov	dx,0b36h
		mov	al,[cs: fon4 ]
		dw ie_mov_ah_al
		cmp	byte [cs:met_renmov],0ffh
		jnz	met_c27
		mov	si,dat_renmov+1
		call	window
		mov	si,dat_mov
		dw ie_cmp_bl_bh			;хранятся имена рабочих дисков
		jnz	met_c29			;если не равны, то делать move
;сделать переименование
		pop	si
		mov	dh,9
		mov	al,[cs: fon4 ]
		call	print_name
		push	cs
		pop	ds
		push	si
		mov	si,dat_ren
		mov	dh,8
		call	print_name
		pop	si
		call	check_esc
		jc	met_cop13
		mov	dx,begin_buf
		mov	cx,00110111b
		mov	ah,4eh		;поиск файла
		int	21h
		jc	met_cop19
		cmp	byte [cs:met_overwrite],0ffh
		jz	met_cop25
		call	compare_prn
		jbe	met_cop13
		mov	al,80
		call	error		;файл существует
		jc	met_cop13
met_cop25:
		call	compare_file
		jc	met_cop13
		call	delete_copy_file
met_cop19:
		call	seg_dat
		dw ie_mov_dx_si		;старое имя
		mov	di,begin_buf	;новое имя
		mov	ah,56h		;переименовать
		int	21h
		pushf
		xor	bp,2
		call	test_max_file
		ja	no_inc_file2
		inc	word [max_pos0+bp] ;для определения выдел. файлов
no_inc_file2:
		xor	bp,2
		popf
met_cop13:
		jmp	met_cop20
met_c27:
		mov	si,dat_copy+1
		call	window
		mov	si,dat_cop
met_c29:
		mov	dh,8
		push	ds
		push	cs
		pop	ds
		call	print_name
		pop	ds
;изобразить полоску
		dw ie_mov_ah_al
		mov	al,[cs:wind+10]
		mov	cx,24
		mov	di,1600+56
		call	seg_win
		call	cga1
		rep	stosw
		pop	si
;написать имя файла в рамке
		mov	dh,9
		mov	al,[cs: fon4 ]
		call	print_name
		dw ie_mov_dx_si
		mov	ax,3d00h	;открыть файл для чтения
		int	21h
		jc	met_cop13
		mov	[cs:handle0],ax
		mov	al,2		;указатель на конец
		call	file_indic
		dw ie_mov_si_ax		;запомнить длину файла di:si
		dw ie_mov_di_dx
		mov	word [cs:long_view_file],ax
		mov	word [cs:long_view_file + 2],dx
		dw ie_xor_al_al		;указатель на начало
		call	file_indic
;считать файл в буфер
		call	seg_win
		call	end_save
		call	beg_free_m
		mov	ah,3fh		;чтение файла
		cwd
		int	21h
		jc	met_cop6
		push	cs
		pop	ds
                call    read_indic
		mov	dx,begin_buf
		mov	cx,00110111b
		mov	ah,4eh		;поиск файла
		call	int_21
		jc	met_cop44
		cmp	byte [cs:met_overwrite],0ffh
		jz	met_cop41
		call	compare_prn
		jc	met_cop6	;con
		jz	met_cop44	;prn
		mov	al,80
		call	error		;файл существует
		jc	met_cop6
met_cop41:
		mov	bx,[cs:drive_file]
		dw ie_cmp_bh_bl
		jnz	met_cop4
		push	si
		dw ie_mov_si_sp
		mov	si,[si+2]
		call	compare_file
		pop	si
		jc	met_cop6
met_cop4:
		test	byte [80h+21],00000111b
		jz	met_cop44
		call	change_attrib
		jc	met_cop6
met_cop44:
		call	create_new_file
		jc	met_cop6
cycle:
		mov	[cs:handle1],ax
		dw ie_mov_bx_ax
		call	check_esc
		jnc	met_cop167
met_con1:
		call	delete_nocopy
		stc
met_cop6:
		jmp	short met_cop18

;указатель на конец

met_cop167:
		mov	al,2
		call	file_indic1
		call	beg_free_m
                dw ie_xor_dx_dx
		call	end_save
		mov	ah,40h
		int	21h
		jc	met_con1
met_cop32:
                call    write_indic
		dw ie_cmp_ax_cx
		jz	met_cop34
;нехватает памяти
		mov	al,8
		jmp	short met_con1
met_cop34:
		dw ie_sub_si_ax
		ja	met_cop10
		dec	di
		js	met_cop23
met_cop10:
		call	close_file3
		mov	bx,[cs:handle0]
		call	end_save
		call	set_drive0
		mov	ah,3fh		;чтение файла
		cwd
		int	21h
		jc	met_con1
                call    read_indic
		call	set_drive1
		push	cs
		pop	ds
		mov	dx,begin_buf
		mov	ax,3d02h	;открыть для записи
		int	21h
		jc	met_con1
		jmp	short cycle
met_cop23:
		push	cs
		pop	ds
		xor	bp,2
		call	test_max_file
		ja	no_inc_file1
		inc	word [max_pos0+bp] ;для определения выдел. файлов
no_inc_file1:
		xor	bp,2
		call	close_file1
		cmp	byte [met_renmov],0
		jz	met_cop18
		call	close_file0
		pop	dx
		push	dx
		call	seg_dat
		call	delete_copy_file
met_cop18:
		call	close_file0
met_cop20:
		call	met_e762	;clear_window
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ds
		pop	es
		ret

end_save:
		mov	cx,[cs:size_block]
		dw ie_or_di_di
		ja	met_cop12
		dw ie_cmp_si_cx
		ja	met_cop12
		dw ie_mov_cx_si
met_cop12:
		ret


delete_copy_file:
		call	change_attrib
		mov	ah,41h		;удалить фаил
		int	21h
		ret

change_attrib:
		dw ie_sub_cx_cx
		mov	ax,4301h	;изменить атрибуты
		call	int_21
met_cop21:
		ret

delete_nocopy:
		push	ax
		push	cs
		pop	ds
		call	close_file1
		mov	dx,begin_buf
		call	delete_copy_file
		pop	ax
		ret
close_file0:
		pushf
		push	ax
		cmp	byte [cs:met_renmov],0
		jz	met_cop117
		call	set_drive0
met_cop117:
		call	close_file
		jmp	short met_close0
close_file1:
		pushf
		push	ax
		call	set_drive1
		mov	bx,[handle0]
		mov	ax,5700h
		int	21h
		mov	bx,[handle1]
		mov	ax,5701h
		int	21h
		call	close_file3
		test	byte [cs:attrib_file],7
		jz	met_close0
		push	ds
		push	cs
		pop	ds
		mov	dx,begin_buf
		mov	ax,4301h	;изменить атрибуты
		dw ie_xor_cx_cx
		mov	cl,[attrib_file]
		int	21h
		pop	ds
met_close0:
		pop	ax
		popf
		ret
set_drive0:
		mov	dl,byte [cs:drive_file]
		jmp	short met_sd0
set_drive1:
		mov	dl,byte [cs:drive_file+1]
met_sd0:
		mov	ah,0eh
		call	int_21
		ret

compare_file:
;dx - begin_buf  ; si- смещение имени файла
		push	ds
		push	dx
		mov	ax,4300h	;считать атрибуты
		int	21h
		xor	cl,20h
		mov	ax,4301h	;изменить атрибуты
		int	21h
		call	seg_dat
		dw ie_mov_dx_si
		mov	ax,4300h
		int	21h
		cmp	cl,[cs:attrib_file]
		jz	met_cop43
		xor	cl,20h
		mov	ax,4301h
		int	21h
		mov	al,090h		;попытка удалить самого себя
		stc
met_cop43:
		pop	dx
		pop	ds
		ret

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;                       SUBROUTINE WRITE_INDIC, READ_INDIC
;изображение движущейся полоски копирования файла
;входные: long_view_file - длина файла, al - добавка длины
;di:si - сколько байт осталось считать
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄

read_indic:
                push    ax
                shr     ax,1
                jmp     short met_indic
write_indic:
		push	ax
met_indic:
                push    cx
		push	dx
		push	si
		push	di

                dw ie_sub_si_ax
		sbb	di,0		;проверить на переход через 0 ????

					;умножение на 24 di:si
                xchg    ax,di           ;сначала старший разряд di
		mov	cx,24		;24 - количество символов в полоске
		mul	cx
                dw ie_or_dx_dx           ;число больше ffff,ffff
                jnz     no_indic
		xchg	di,ax
		xchg	si,ax           ;затем младший разряд si
		mul	cx
		dw ie_add_di_dx           ;складываю два результата
		xchg	si,ax
		mov	ax,word [cs:long_view_file]
		mov	dx,word [cs:long_view_file + 2]
		xchg	ax,si           ;используем di:si для хранения dx:ax
		xchg	dx,di

		dw ie_or_di_di		;число не очень большое?
		jz	no_inc          ;да, уменьшать не будем

		mov	cx,0ffffh	;разделим числа на общий делитель
		div	cx
		xchg	si,ax		;возвратим в dx:ax длину файла
		xchg	di,dx
		div	cx		;cx=65535
		xchg	ax,si
                dw ie_xor_dx_dx

no_inc:
		dw ie_or_si_si
		jz	no_div
		div	si		;di:si*24 / dx:ax ;where dx=0
no_div:
		mov	cx,24
		dw ie_sub_cx_ax
                jb      no_indic
                mov     di,1600+56
                mov     ax,0720h
		call	cga1
		rep	stosw
no_indic:
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	ax
		ret
compare_prn:
		push	si
		push	di
		push	es
		push	cs
		pop	es
		mov	di,dat_prn
		mov	si,80h+30
		call	compare
		jz	met_prn
		mov	di,dat_con
		call	compare
		clc
		jnz	met_prn
		mov	ah,1
		stc
met_prn:
		pop	es
		pop	di
		pop	si
		ret

;copy_file	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE TEST_MAX_FILE
;контроль максимального количества файлов в панели.
;при переполнении cf=1
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
test_max_file:  ; proc near

		cmp	word [cs:max_pos0+bp],max_files_in_dir
		ret

;test_max_file	endp


;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE MEMORY_FREE
;определить размер свободной памяти.
;сохранить количество 16 байтных блоков в [ memory ]
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
memory_free:  ; proc near
		push	si
		push	cx
		push	ds
		push	cs
		pop	ds
		mov	si,[max_pos0]
		cmp	si,[max_pos1]
		ja	met_mem0
		mov	si,[max_pos1]
met_mem0:
		call	mul_48
		add	si,[met_dir1]
		add	si,48		;запас на 1 файл
		mov	[met_data],si
		mov	cl,4
		shr	si,cl
		add	si,[segm_data]	;первый свободный 16 байтный блок
		mov	[begin_free_memory],si
		int	12h		;размер памяти
		mov	cl,6
		shl	ax,cl
		dw ie_sub_ax_si
		cmp	ax,strict word 1000h
		jb	met_mem3
		mov	ax,0ffffh
		jmp	short met_mem2
met_mem3:
		mov	cl,4
		shl	ax,cl
met_mem2:
                mov     [size_block],ax
		pop	ds
		pop	cx
		pop	si
met_de60:
		ret
;memory_free	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE DELETE
;удаление директории или файлов на активной панели
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
delete:  ; proc near
		call	indic
		cmp	[max_pos0+bp],cx
		jz	met_de60
		call	locat_name
		call	seg_dat
		cmp	[sum_sel0+bp],cx
		jnz	met_de4
		cmp	byte [si],"."	;текущая директория
		jz	met_de60
met_de4:
		push	si
		push	ds
		push	cs
		pop	ds
                call    window_delete
		mov	dx,081dh
		mov	si,phrase_delete
		call	phrase
		pop	ds
		pop	si
		mov	dh,9
		cmp	word [sum_sel0+bp],0
		jnz	met_de9
		call	print_name
		call	delete_halt
		cmp	ah,1		;Esc
		jz	met_de6
		dw ie_mov_dx_si
		test	byte [si-9],10h		;директория
		jz	met_de5
;удалить директорию
		mov	ah,3ah		;удалить поддиректорию
		int	21h
		mov	al,6		;директория не пустая
		jc	delete_error

;записать файл для поиска, следующий за позицией курсора
met_de2:
		mov	byte [si-10],0feh	;метка удаления 0feh
		add	si,48
		mov	ax,[num_pos0+bp]
		inc	ax
		cmp	ax,[max_pos0+bp]
		jb	met_de222
		sub	si,96
met_de222:
		call	clear_window
		call	search_curs
		jmp	met_de15
;удалить один файл
met_de5:
		call	delete_file
		jnc	met_de2
delete_error:
		call	error
		jmp	short met_de222
;удалить группу файлов
met_de9:
;вывести в окно сообщение о удалении файлов
                mov     si,dat_delete_files
		push	ds
		push	cs
		pop	ds
		call	print_name
		pop	ds
		mov	ax,[sum_sel0+bp]
		cwd
		mov	di,160*9+74
		call	number
		call	delete_halt
		cmp	ah,1		;Esc
		jnz	met_de112
met_de6:
		call	clear_window
		ret
met_de112:
;определить новую позицию курсора
		mov	si,[met_dir0+bp]
		add	si,10
		mov	cx,[max_pos0+bp]
		mov	bx,0ffffh
met_de10:
		call	clear_window
;найти удаляемый файл
met_de11:
		call	check_esc
		jc	met_de15
		inc	bx
		mov	al,[si-10]
		cmp	bx,[max_pos0+bp]
		jae	met_de15
		cmp	bx,[num_pos0+bp]
		ja	met_de114
		jz	met_de113
		cmp	al,0ffh
		jz	met_de12
met_de113:
		cmp	al,0ffh
		jnz	met_de13
		inc	word [num_pos0+bp]
		jmp	short met_de12
met_de13:
		call	search_curs
		jmp	short met_de115
met_de114:
		cmp	al,0ffh
		jz	met_de12
met_de115:
		add	si,48
		jmp	short met_de11
met_de12:
		call	wind_delete
;удалить
		call	delete_file
		jc	met_de19
;установить в следующий файл позицию курсора
		mov	byte [si-10],0feh	;метка удаления 0feh
		add	si,48
;повторить поиск
		jmp	short met_de10
met_de19:
		call	clear_window
		call	error
met_de15:
		mov	byte [cs:keep_file],0
		call	inst_dir1
;сравнить панели, если одинаковые, то прочитать и вторую
		push	cs
		push	cs
		pop	ds
		pop	es
		mov	si,stack0+st0d_path0
		mov	di,stack0+st0d_path1
met_de16:
		cmp	byte [si],0
		jz	met_de17		;панели одинаковые?
		cmpsb
		jnz	met_de18		;нет
		jz	met_de16		;пока да
met_de17:
		call	inst_dir2
met_de18:
		not	byte [cs:keep_file]
		jmp	do_cursor
delete_file:
		dw ie_mov_dx_si
		mov	al,[si-9]
		mov	[cs:attrib_file],al
		call	delete_copy_file
		ret
search_curs:
; в si установить имя разыскиваемого файла
		push	ds
		call	seg_dat
met_de777:
		push	si
		push	ax
		mov	di,071h
		push	cs
		pop	es
met_de7:
		lodsb
		stosb
		cmp	di,71h+12
		ja	met_de8
		dw ie_or_al_al
		jnz	met_de7
met_de8:
		sub	di,71h
		xchg	ax,di
		mov	[es:70h],al
		pop	ax
		pop	si
		pop	ds
		ret
delete_halt:
		push	si
		push	ds
		push	cs
		pop	ds
		mov	bl,[ fon3 ]
		mov	bh,[ fon4 ]
met_de20:
		dw ie_mov_al_bl
		mov	si,dat_delete+1
		mov	dx,0a20h
		call	phrase
		dw ie_mov_al_bh
		mov	dl,28h
		mov	si,dat_cansel
		call	phrase
		xchg	bl,bh
met_de23:
		call	halt
		cmp	ah,1
		jz	met_de22
		cmp	ah,77
		jz	met_de20
		cmp	ah,75
		jz	met_de20
		cmp	ah,28
		jnz	met_de23
		cmp	bl,[ fon4 ]
		jz	met_de22		;истинно
		mov	ah,1			;ложно
met_de22:
		pop	ds
		pop	si
		ret
wind_delete:
		push	si
		push	ds
                call    window_delete
		mov	dh,8
		mov	si,dat_del
		call	print_name
		pop	ds
		pop	si
		mov	dh,9
		call	print_name
		ret
window_delete:
                push    cs
		pop	ds
                mov     cx,0619h
                mov     dx,0b37h
		mov	al,[ fon4 ]
		dw ie_mov_ah_al
		mov	si,dat_delete+1
		call	window
                ret


;delete		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE PRINT_NAME
;записать в рамке имя файла с центровкой в центре экрана
;входные:si- путь к имени, заканчиващийся нулем, dh-строка, al - фон
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
print_name:  ; proc near
		push	bx
		dw ie_sub_bx_bx
met_print0:
		inc	bx
		cmp	byte [si+bx-1],0
		jnz	met_print0
		mov	dl,80
		dw ie_sub_dl_bl
		shr	dl,1
		call	phrase
		pop	bx
		ret
;print_name	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE	READ_DRIVE
;входные: должен быть указан путь для поиска, bp - активная панель
;чтение текущего диска или директории и отображение его содержимого на панели
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
read_drive:  ; proc near
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
;сделать курсор невидимым
		call	clear_cursor
		call	frame
		call	seg_dat
		push	ds
		pop	es
		dw ie_sub_ax_ax
;записать имена всех выделенныех файлов текущей директории в область данных,
;если требуется оставить выделение
		cmp	byte [cs:keep_file],al
		jnz	met_keep3
		mov	bx,[met_dir0+bp]
		mov	di,[cs:met_data]
		mov	cx,[max_pos0+bp]
		add	bx,10
		mov	byte [di],0ffh  ;только бы не 0
		jcxz	met_keep003
met_keep0:
		dw ie_mov_si_bx
		cmp	byte [si-10],0ffh
		jnz	met_keep2
met_keep1:
		lodsb
		stosb
		dw ie_or_al_al
		jnz	met_keep1
met_keep2:
		add	bx,48
		loop	met_keep0
met_keep003:
		mov	word [di],ax
		dec	di
		mov	word [cs:keep_number],di
met_keep3:
		push	cs
		pop	ds
		mov	word [max_pos0+bp],ax
		mov	word [num_pos0+bp],ax
		mov	word [high_pos0+bp],ax
		mov	si,[met_path+bp]
		mov	di,[met_dir0+bp]
		mov	word [si+1],5c3ah  ; "\:"
		mov	word [si+3],002ah	;"*",0
		call	set_dta
		cmp	[noread],al
                jnz     met_exit_r2                  ;драйв. не читался
		call	set_drive
		add	si,3
		mov	ah,47h		;записать текущую директорию в path
		cwd			;дисковод текущий
		int	21h
                jnc      met_r39
met_exit_r2:
                jmp     met_rd2
met_r39:
                mov     bx,100h         ;метка продолжения поиска поддиректор.
		cmp	byte [si],bl	;нахожусь в корневом каталоге
		jz	met_r00
		dw ie_xor_bh_bh
;поиск конца path
met_r0:
		lodsb
		dw ie_or_al_al
		jnz	met_r0
		mov	byte [si-1],5ch
		dec	word [max_pos0+bp]
		sub	di,48	;начальное смещение таблицы DIR умен. на 1 поз.
met_r00:
                mov     byte [met_root],bh
		mov	word [si],"*."
		mov	word [si+2],002ah
		mov	dx,[met_path+bp]
                mov     ah,4eh          ;поиск первого совпадающего файла
		mov	cx,00110111b	;атрибуты поиска
		int	21h
                jnc     met_r42
                cmp     bh,1            ;нахожусь в корне
                jz      met_exit_r2
		cmp	al,12h		;нет файлов
		jnz	met_exit_r2
                mov     byte [met_error],0ffh
		call	insert_dir
                jmp     short met_r53
met_r42:
                cmp     byte [80h +30 ],"."
                jz      met_r40
                cmp     bh,1            ;нахожусь в корне
                jz      met_r54
                call    insert_dir
		jmp	short met_rd3
met_r40:
                cmp     bh,1            ;нахожусь в корне
                jz      met_rd5
met_rd4:
		call	save_name
		add	di,24		;пропустить место под табл. друг. диска
met_rd5:
                mov     ah,4fh          ;поиск след. совпадающего файла
		mov	cx,00110111b	;атрибуты поиска
		int	21h
                jnc     met_r52
                mov     byte [met_error],0ffh
                jmp     short met_r53
met_r52:
                cmp     byte [met_root],1     ;нахожусь в корне
                jnz     met_rd6
                cmp     byte [80h +30 ],"."
                jz      met_r1
		jmp	short met_r54
met_rd6:
                cmp     byte [80h +30 ],"."
		jz	met_r54
met_rd3:
                call    insert_dir
		jmp	short met_r54
met_r53:
                call    insert_dir
                cmp     byte [met_error],0ffh
                jz      met_rd2
met_r1:
		mov	ah,4fh		;поиск следующей совпадающей директории
		mov	cx,00110111b	;атрибуты поиска
		int	21h
                jc      met_rd2
met_r54:
		cmp	di,[met_data]
		jb	met_r100
		mov	byte [keep_file],0ffh ;запретить поиск выделений
met_r100:
		call	save_name
		add	di,24		;пропустить место под табл. друг. диска
		call	test_max_file
                jbe     met_r1
met_rd2:
		push	es
		pop	ds
		call	sort
		call	write_pan
		call	write_path
		call	select_stat
		call	command_path
		cmp	byte [cs:noread],0
		jnz	met_rd22
		call	set_new_dir
met_rd22:
		mov	byte [cs:noread],0
		call	memory_free
		call	set_cursor
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		ret

insert_dir:
                call    save_netware
		add	di,48
		mov	si,dir_net
		mov	cx,13
		push	di
		rep	movsb
		pop	di
                mov     byte [es:di+23],cl
		ret

;функция записи информации о файле, увеличение указателя
save_name:
		mov	si,80h+20	;смещение имени файла в DTA
		mov	ah,byte [80h+21]
		mov	cx,10
		rep	movsb
		mov	cl,14
		test	ah,6
		jnz	met_r43
met_r44:
		test	ah,10h		;это директория
		jnz	met_r43		;да
		mov	al,byte [si]
		cmp	al,"A"
		jb	met_r43
		cmp	al,"Z"
		ja	met_r43
		add	byte [si],"a"-"A"
met_r43:
		movsb
		loop	met_r44
save_netware:
		dw ie_xor_al_al
		cmp	byte [keep_file],al ;разрешен поиск выделений
		jnz	met_keep9
		push	di
		mov	di,[met_data]
met_keep4:
		mov	si,80h+30
met_keep5:
		cmpsb
		jnz	met_keep6
		cmp	[si-1],al
		jnz	met_keep5
		not	al
		jmp	short met_keep8
met_keep6:
		dec	di
		mov	cl,13
		repnz	scasb
		cmp	di,[keep_number]
		jb	met_keep4
met_keep8:
		pop	di
met_keep9:
		mov	byte [es:di-24],al
		inc	word [max_pos0+bp]
		dw ie_or_bl_bl		;bl = 1 -найдена позиция курсора
		jnz	met_r21
		cmp	bh,1		;пропустить две позиции
		ja	met_r23
		inc	bh
		jmp	short met_r24
met_r23:
		inc	word [num_pos0+bp]
met_r24:
		mov	cl,byte [70h]
		jcxz	met_r25
		push	di
		mov	si,71h
		sub	di,14
		rep	cmpsb
		pop	di
		jnz	met_r21
met_r25:
		inc	bx
met_r21:
		ret

;функция вывода содержимого таблицы директории на экран
write_pan:
		push	cx
		call	seg_dat
		mov	si,[num_pos0+bp]
		dw ie_sub_cx_cx
		cmp	si,17
		jb	met_r15
		dw ie_mov_cx_si
		sub	cx,17
met_r15:
		mov	[high_pos0+bp],cx
		dw ie_mov_si_cx
		mov	cx,18
met_r4:
		test	cl,1
		jnz	met_r_a
		call	cga
met_r_a:
		call	write_line
		inc	si
		loop	met_r4
		pop	cx
		ret
set_drive:
		mov	dl,[cs:si]	;имя драйвера
		sub	dl,"A"
		mov	ah,0eh		;назначение активного устройства
		call	int_21
		ret

;read_drive	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE WRITE_LINE
;вывод на экран имени файла с параметрами
;входные:si-позиция в DIR	bp - активная панель
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
write_line:  ; proc near
		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		call	begin_param8
		dw ie_mov_di_si
		sub	di,[high_pos0+bp]
		dw ie_mov_cx_si		;используется для хранения поз. файла
		call	mul_48
		add	si,[met_dir0+bp]	;смещение к файлу в таблице DIR
		dw ie_mov_bx_bp
		shr	bx,1
		add	di,2
		shl	di,1
		dw ie_add_di_bx
		mov	al," "		;пробел
		mov	ah,[cs:wind+8]
		call	one_line
		cmp	cx,[max_pos0+bp] ;используется для очистки экрана
		jb	met_r9
		jmp	met_r80
met_r9:
		call	mul_80		;смещение к точке вывода имени
		add	di,2		;отступ вывода имени
		push	di		;для заполнения следующей графы
		dw ie_mov_bx_si		;сохраним базу
		add	si,10		;смещение к имени в таблице DIR
		mov	dl,byte [bx+1]
		mov	al,[cs: fon0 ]
		cmp	byte [bx],0ffh	;файл выделен?
		jnz	met_r45
;выделить строку
		push	di
		mov	al,[cs: fon1 ]
		mov	cx,38
met_r47:
		inc	di
		stosb
		loop	met_r47
		pop	di
met_r45:
		mov	cx,12		;длина имени + атрибут, не ставить cl
		cmp	word [si],".."
		jnz	met_r5
		movsb
		inc	di
		movsb
		dw ie_xor_ah_ah
		jmp	short met_r49
met_r5:
		lodsb
		dw ie_or_al_al
		jz	met_r49
		cmp	cl,3
		jz	met_r49
		cmp	al,"."
		jnz	met_r8
		lodsb
		sub	cl,3
		shl	cl,1
		dw ie_add_di_cx
		mov	cl,3
met_r8:
		stosb
		inc	di
		loop	met_r5
met_r49:
		pop	di		;начало вывода
		test	dl,6		;файл  скрытый или системный
		jz	met_r11
		mov	dh,[cs:wind+10]
		mov	byte [es:di+16],dh
met_r11:
		push	di
		add	di,26		;следующая колонка
		test	dl,10h		;это директория
		jz	met_r50		;нет
		push	cs
		pop	ds
		mov	cl,9
		mov	si,dat_sub_dir
		dw ie_or_ah_ah
		jnz	met_r10
		mov	si,dat_up_dir
met_r10:
		movsb
		inc	di
		loop	met_r10
		call	seg_dat
		jmp	short met_r51
met_r50:
;вывод длины файла
		add	di,16
		mov	ax,[bx+6]
		mov	dx,[bx+8]
		call	number
met_r51:
;вывод даты
		pop	di
		add	di,48
		mov	al,[bx+4]
		and	ax,strict word 00011111b
		cwd
		call	space
		mov	ax,[bx+4]
		and	ah,1
		mov	cl,5
		shr	ax,cl
		call	space
		dw ie_xor_ah_ah
		mov	al,[bx+5]
		shr	al,1
		add	al,80
		cmp	al,100
		jb	met_r16
		sub	al,100
met_r16:
		call	number
		add	di,6
		mov	byte [es:di+4],"0"
		mov	al,[bx+3]
		and	al,11111000b
		mov	cl,3
		shr	al,cl
		cbw
		cwd
		call	number
		mov	byte [es:di+2],":"
		add	di,6
		mov	ax,[bx+2]
		and	ax,strict word 0000011111100000b
		mov	cl,5
		shr	ax,cl
		cwd
		call	number
met_r80:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret
space:
		call	number
		mov	byte [es:di+2],"-"
		mov	byte [es:di+4],"0"
		add	di,6
		dw ie_sub_dx_dx
		ret

;write_line	endp


;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE FRAME
;построение панели
;входные; bp - указатель панели
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
frame:  ; proc near
		push	ds
		push	bp
		shr	bp,1
		dw ie_sub_bx_bx
		dw ie_or_bp_bp
		jz	met_fr2
		mov	bl,40
met_fr2:
		push	cs
		pop	ds
		dw ie_mov_cx_bx		;первый столбец,первая строка
		mov	dx,1628h	;23 строка,40 столбец
		dw ie_add_dl_bl
		mov	si,sparrow
		mov	ah,byte [ fon0 ]
		dw ie_mov_al_ah	;фон сообщения = фону поля
		call	window
		dw ie_mov_di_bp
		mov	ah,byte [wind+6]
		mov	al,byte [wind+1]
		call	one_line
		inc	di
		inc	di
		mov	ah,byte [wind+8]
		mov	al," "
		call	one_line
		mov	di,40
		dw ie_add_di_bp
		mov	ah,byte [wind+7]
		mov	al,byte [wind+9]
		call	one_line	;построение mini_status линии
		mov	al,byte [ fon1 ]
		mov	dx,0104h	;положение выводимой фразы
		dw ie_add_dl_bl
		mov	si,dat_name
		call	phrase		;построить надпись "Name"
		add	dl,12		;передвинуть позицию вывод. фразы
		mov	si,dat_size
		call	phrase
		add	dl,9
		mov	si,dat_date
		call	phrase
		add	dl,8
		mov	si,dat_time
		call	phrase
		pop	bp
		pop	ds
		ret
;frame		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE _WINDOW
;построение окна с рамкой и запоминание символов под окном в буфере
;входные:CH-строка начала;CL-колонка начала;DH-строка конца;DL-колонка конца
;	 SI-смещение к началу фразы,помещаемой в середине окна,которая дол-
;	 жна заканчиваться ASCII 0; AH-фон окна и символов,AL-фон фразы
;Внимание!  Минимальный размер окна 3*3
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
window:  ; proc near
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es

		push	ax		;запомнить байт атрибутов
		push	si		;запомнить смещение фразы
		dw ie_sub_bx_bx
		dw ie_mov_bl_ch		;строка начала окна
		dw ie_mov_di_bx
		call	mul_80
                shl     di,1            ;смещ. начала строки на экране
		dw ie_mov_bl_cl
		shl	bl,1		;смещ. начала окна в строке
		dw ie_add_di_bx		;смещ. начала окна на экране
		mov	word [cs: begin_wind ],di
		shr	bl,1
		dw ie_sub_dl_bl		;длина окна
		dw ie_sub_dh_ch		;высота окна
		mov	word [cs: long_wind ],dx	;размеры окна
;запомнить окно в буфере
		dw ie_mov_si_di		;начало окна на экране
		mov	di,word [cs: begin_buffer_wind ]
		mov	bx,80		;длина строки экрана
		dw ie_sub_bl_dl		;длина незаполненного окна
		shl	bl,1		;длина незаполненного окна в байтах
		dw ie_sub_cx_cx
		mov	es,[cs:segm_data]
		mov	ds,[cs:segm_wind]
		mov	byte [cs: cga_wait ],cl
met_a0:
		mov	cl,6
		call	wait_cga
		dw ie_mov_cl_dl		;длина окна
		rep	movsw
		dw ie_add_si_bx
		dec	dh		;запомнены все строчки
		jns	met_a0		;нет
;построение окна
		push	cs
		pop	ds
		call	seg_win
		mov	di,[begin_wind]	;начало окна на экране
		dw ie_mov_si_di			;запомнить начало окна
		add	si,160			;начало следующ. строки
		mov	al,byte [wind]	;символ рамки "╔"
		stosw
		dw ie_mov_cl_dl		;длина окна
		sub	cl,2		;без крайних элементов
		mov	al,byte [wind+1]	;символ "═"
		rep	stosw
		mov	al,byte [wind+2]	;символ "╗"
		stosw
		dw ie_mov_di_si		;начало следующей строки
		mov	dh,byte [long_wind+1] ;высота окна
		sub	dh,1		;без верхних и нижних строчек
		mov	al,byte [wind+3]	;символ "║"
met_a1:
		mov	cl,6
		call	wait_cga
		stosw
		dw ie_mov_cl_dl		;длина окна
		sub	cl,2		;без крайних элементов
		mov	al," "		;пробел
		rep	stosw
		mov	al,byte [wind+3]	;символ "║"
		stosw
		add	si,160
		dw ie_mov_di_si		;начало следующей строки
		dec	dh		;построены все строки окна
		jnz	met_a1		;нет
		mov	al,byte [wind+4]	;символ "╚"
		stosw
		dw ie_mov_cl_dl		;длина окна
		sub	cl,2		;без крайних элементов
		mov	al,byte [wind+1]	;символ "═"
		rep	stosw
		mov	al,byte [wind+5]	;символ "╝"
		stosw
		pop 	si		;восстановить смещение заголовка
		pop	ax		;восстановить байт атрибутов
		dw ie_xor_bx_bx
met_a2:
		inc	bx
		cmp	byte [si+bx],0	;последний байт фразы
		jnz	met_a2		;нет

		dw ie_mov_cl_bl		;длина фразы
		dw ie_sub_dl_bl		;начало фразы в первой строке окна
		and	dl,~1	;сделать число четным
		mov	di,word [ begin_wind ]
		dw ie_add_di_dx		;начало фразы на экране
		mov	byte [es:di-2]," "
met_a3:
		movsb
		stosb			;байт атрибутов
		loop	met_a3
		mov	byte [es:di]," "
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		ret
;window		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE CLEAR_WINDOW
;восстановление окна
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
clear_window:  ; proc near
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
;востановить окно из буфера
		call	begin_param8
		mov	di,[cs:begin_wind]
		mov	si,[cs:begin_buffer_wind]
		mov	dx,[cs:long_wind]
		dw ie_sub_cx_cx
		mov	[cs:cga_wait],cl
met_a15:
		mov	cl,6
		call	wait_cga
		dw ie_mov_cl_dl		;длина окна
		rep	movsw
		mov	cl,80
		dw ie_sub_cl_dl
		shl	cl,1
		dw ie_add_di_cx
		dec	dh		;запомнены все строчки
		jns	met_a15		;нет
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		ret
;clear_window	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE	MUL_80
;умножение di на 80
;входные:di,выходные:di*80
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
mul_80:  ; proc near
		push	cx
		mov	cl,4
		shl	di,cl		;умножить на 16
		dw ie_mov_cx_di		;запомнить результат в cx
		shl	di,1		;умножить на 2
		shl	di,1		;умножить на 2
		dw ie_add_di_cx		;получить в di номер строки * 80
		pop	cx
		ret
;mul_80		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE	SELECT_STAT
;вывод в статусную линию количества выделенных файлов
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
select_stat:  ; proc near
		push	ax
		push	bx
		push	cx
		push	dx
		push	si
		push	di
		push	ds
		push	es
		call	begin_param8
		dw ie_sub_si_si
		dw ie_sub_ax_ax
		cwd
		mov	bx,[met_dir0+bp]
		mov	cx,[max_pos0+bp]
		jcxz	met_sel5
;прибавить длину выделенного файла
met_cur53:
		cmp	byte [bx+si],0ffh
		jnz	met_cur54
		inc	di
		add	ax,[bx+si+6]
		adc	dx,[bx+si+8]
met_cur54:
		add	si,48
		loop	met_cur53
met_sel5:
		push	cs
		pop	ds
		mov	[dat_sel_ax0+bp],ax
		mov	[dat_sel_dx0+bp],dx
                mov     [sum_sel0+bp],di
		mov	al,[ fon1 ]
                dw ie_or_di_di
                jnz     met_sel0
		mov	al,[ fon0 ]
met_sel0:

		mov	si,select_line
                mov     di,21*160+22
		mov	dx,1501h
		dw ie_or_bp_bp
                jz      met_sel1
		add	di,80
		add	dl,40
met_sel1:
		call	phrase
		mov	ax,[dat_sel_ax0+bp]
		mov	dx,[dat_sel_dx0+bp]
		call	number
                add     di,22
		mov	ax,[sum_sel0+bp]
		cwd
		call	number
sel_quit:
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		ret

;select_stat	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE	HALT
;остановка процессора перед вводом с клавиатуры, аналог int 16h
;выходные:ax - как в int 16h
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
halt:  ; proc near
		sti
		cld
		dw ie_sub_ax_ax
		mov	[cs:met_int_24],al
		cmp	[cs:hlt_ass],al
                jnz     met_halt0
		int	16h
		ret
met_halt0:
		push	ds
		push	dx
		mov	ds,ax
		mov	dx,3f2h
		mov	al,00001111b
		out	dx,al
		mov	byte [043fh],ah	;двигатели выключены
		add	word [046ch],72	;измен. таймер
met_halt1:
		in	al,21h
		or	al,1
		out	21h,al		;запретить прерывания таймера
		hlt			;остановить процессор
		and	al,~1	;разрешить таймер
		out	21h,al
		mov	ah,1
		int	16h
                jz      met_halt1
		call	clear_buf_key
		pop	dx
		pop	ds
		ret
;halt		endp

;--------------------- очистить буфер клавиатуры ------------------------
clear_buf_key:
		push	ax
		push	ds
		dw ie_sub_ax_ax
		mov	ds,ax
		mov	al,[41ah]
		mov	[41ch],al
		pop	ds
		pop	ax
		ret

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE	NUMBER
;представление шестнадцатиричного числа в десятичном виде и вывод на экран
;входные:dx,ax- число; di- смещение на экране к концу числа
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
number:  ; proc near
		cmp	dx,2710h
                jbe     met_n1
                mov     al,"?"
                stosb
                dec     di
                ret
met_n1:
		push	cx
		push	bx
		push	si
		push	di
		push	es
		call	seg_win
		mov	cx,10000
		div	cx
		xchg	ax,dx
		dw ie_or_dx_dx
		jz	met_cc10
		dw ie_mov_bx_dx

		call	conv_bin_10
		dw ie_mov_ax_bx
met_cc9:
		dec	di
		dec	di
		mov	byte [es:di],"0"
		dec	si
		jnz	met_cc9
met_cc10:
		call	conv_bin_10
		pop	es
		pop	di
		pop	si
		pop	bx
		pop	cx
met_cc8:
		ret
conv_bin_10:
		mov	cx,10
		mov	si,4
cc20:
		cmp	ax,strict word 10
		jb	cc30
		dec	si
		dw ie_sub_dx_dx
		div	cx
		or	dl,"0"
		mov	[es:di],dl
		dec	di
		dec	di
		jmp	short cc20
cc30:
		or	al,"0"
		mov	[es:di],al
		ret
;number		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE	MUL_48
;умножение si на 48
;входные:si,выходные:si*48
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
mul_48:  ; proc near
		push	cx
		mov	cl,4
		shl	si,cl		;умножить на 16
		dw ie_mov_cx_si		;запомнить результат в cx
		shl	si,1		;умножить на 32
		dw ie_add_si_cx
		pop	cx
		ret
;mul_48		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;		SUBROUTINE	CGA
;ожидание, когда можно выводить на экран CGA изображение без ряби
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
cga:  ; proc near
		cmp	byte [cs:met_cga],0
		jz	met_cga2
		push	ax
		push	cx
		push	dx
		mov	dx,3dah	;порт состояния видео
c44d0:
		in	al,dx
		ror	al,1
		jc	c44d0
c44d5:
		sti
		mov	cx,14h
		cli
c44da:
		in	al,dx
		ror	al,1
		jnc	c44d5
		loop	c44da
		pop	dx
		pop	cx
		pop	ax
met_cga2:
		ret
cga1:
		cmp	byte [cs:met_cga],0
		jz	met_cga2
		push	ax
		push	dx
		mov	dx,3dah	;порт состояния видео
		cli
met_cga1:
		in	al,dx
		test	al,8
		jz	met_cga1
		pop	dx
		pop	ax
		ret

;входные; cl - задержка перед запуском
wait_cga:
		sub	byte [cs:cga_wait],1
		jnc	met_e19
		mov	byte [cs:cga_wait],cl
		call	cga
met_e19:
		ret

;cga		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;		SUBROUTINE	INDIC
;если текущая панель левая, то bp=0; если правая, то bp=2
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
indic:  ; proc near
		mov	bp,[cs: act_pan ]
		shl	bp,1
		ret
;indic		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE WRITE_PATH
;записать путь над активной панелью bp- активная панель
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
write_path:  ; proc near
		push	bx
		push	cx
		push	dx
		push	bp
		push	si
		push	di
		push	ds

		push	cs
		pop	ds
		mov	si,[met_path+bp]
		dw ie_mov_bx_bp
		shr	bl,1
		mov	byte [act_drive],bl
		mov	bp,0ffffh
		mov	bh,"*"
met_w0:
		inc	bp
		cmp	byte [si+bp],bh	;определить длину пути
		jnz	met_w0
		dw ie_sub_cx_cx
		cmp	bp,3
		jz	met_w1
		dec	bp
		mov	bh,5ch
		cmp	bp,36		;длина пути больше ширины панели
		jbe	met_w1		;нет
		mov	cl,byte [si]	;запомнить имя драйвера
		sub	bp,36
		dw ie_add_si_bp		;сдвинуть начало фразы к концу
		mov	bp,36
met_w1:
		mov	byte [si+bp],0
		push	bp
		mov	dx,20		;середина панели
		shr	bp,1
		inc	bp
		dw ie_sub_dx_bp		;начало вывода пути на экран
		dw ie_sub_di_di
		mov	bl,byte [act_drive]
		dw ie_or_bl_bl
		jz	met_w2
		add	dx,40		;правая панель
		inc	di
met_w2:
		mov	al,[wind+1]
		mov	ah,[wind+6]
		call	cga
		call	one_line
		mov	al,[ fon0 ]
		cmp	bl,byte [act_pan]
		jnz	met_w3
		call	seg_win
		xor	di,1
		call	mul_80
		mov	ah,[wind+0]
		xchg	al,ah
		scasw
		jnz	met_w9
		dw ie_mov_al_ah
		push	cx
		mov	cx,39
		inc	di
met_w4:
		stosb		;закрасить верхнюю строку активн. панели
		inc	di
		loop	met_w4
		pop	cx
met_w9:
		mov	al,[cs: fon3 ]
met_w3:
		dw ie_mov_bl_al
		call	phrase
		pop	bp
		mov	byte [si+bp],bh
		jcxz	met_w5
		dw ie_mov_al_bl
		mov	si,dat_path
		mov	byte [si],cl
		call	phrase
met_w5:
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	dx
		pop	cx
		pop	bx
		ret
;write_path	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;		SUBROUTINE	KEY_BAR
;вывод на экран строки ключевых клавиш
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
key_bar:  ; proc near
		push	ds
		push	es

		push	cs
		pop	ds
		call	seg_win
		mov	si,dat_help
		mov	di,160*24		;смещение последней строки
		mov	cx,80			;длина строки
		call	cga
met_kb1:
                lodsb
                mov     ah,[ fon3 ]
                cmp     al,"9"  ;не изменять фон букв
                ja      met_kb2
                or      al," "
                cmp     byte [si],"0"    ;изменить фон перед цифрой
                jb      met_kb2
		mov	ah,[ fon2 ]
met_kb2:
                stosw
                loop    met_kb1
		pop	es
		pop	ds
		ret
;key_bar		endp




;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;		SUBROUTINE	ONE_LINE
;вывод на экран одной строки,атрибуты: синий фон,голубые символы
;входные;di-позиция строки (0,1,2..),al-основной,ah-промежуточный байт
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
one_line:  ; proc near
		push	di
		push	es
		push	cx
		push	bx
		dw ie_mov_bl_ah
		mov	ah,[cs: fon0 ]
		dw ie_mov_bh_ah
		call	seg_win
		call	mul_80
                mov     cx,12
                call    step_line
		mov	cl,9
                call    step_line
		mov	cl,8
                call    step_line
		inc	di
		inc	di
		mov	cl,6
		rep	stosw
		pop	bx
		pop	cx
		pop	es
		pop	di
		ret
step_line:
                inc     di              ;пропустить первый символ рамки
                inc     di
		rep	stosw
		mov	word [es:di],bx	;вывести символ "│"
                ret
;one_line	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;		SUBROUTINE	SORT
;сортировка файлов в алфавитном порядке
;входные: bp - номер панели, bl - 0 курсор установить на первом файле
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
sort:  ; proc near
		dw ie_sub_ax_ax
		dw ie_mov_bh_al
		dw ie_or_bl_bl
		jz	met_srt33
		cmp	[cs:70h],al
		jnz	met_srt3
		dw ie_xor_bl_bl
met_srt33:
		mov	[num_pos0+bp],ax
met_srt3:
		mov	[cs:6fh],bx		;[cs:70h]=0
		cmp	[cs:met_sort],al
		jnz	met_srt1
		ret
met_srt1:
		mov	dx,[met_dir0+bp]
		add	dx,10
		dw ie_mov_bx_dx
		call	locat_name
		mov	cx,[max_pos0+bp]
		cmp	cx,1		;количество файлов меньше 2
		jbe	met_srt12	;yes - quit
		push	bp
		dw ie_mov_bp_cx
		mov	byte [si+13],27	;метка файла с курсором
met_srt2:
		dec	bp
		jz	met_srt10
		dw ie_mov_si_dx
		add	dx,48
met_srt4:
		dw ie_mov_di_si
		add	di,48
;сравнить
		mov	cx,12
met_srt6:
		cmp	word [si],".."
		jz	met_srt2
		test	byte [si-9],10h
		jz	met_srt5
		test	byte [di-9],10h
		jz	met_srt2
		jmp	short met_srt11
met_srt5:
		test	byte [di-9],10h
		jnz	met_srt7
met_srt11:
		rep	cmpsb
		jbe	met_srt2	;не переставлять
;переставить
met_srt7:
		sub	si,22
		dw ie_add_si_cx
		dw ie_mov_di_si
		add	di,48
;если верхний файл директория, то не переставлять
		mov	cl,12
met_srt8:
		mov	ax,[es:di]
		movsw
		mov	[si-2],ax
		loop	met_srt8
		sub	si,14+48
		dw ie_cmp_si_bx
		jb	met_srt2
		jmp	short met_srt4
met_srt10:
		pop	bp
		dw ie_sub_cx_cx
		cmp	[cs:06fh],cl	;не искать место курсора
		jz	met_srt12
		dec	cx
met_srt9:
		inc	cx
		add	bx,48
		cmp	byte [bx+13-48],27
		jnz	met_srt9
met_srt12:
		mov	[num_pos0+bp],cx
		ret

;sort		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;		SUBROUTINE	PHRASE
;вывод на экран фразы, заканчивающейся ASCII 0
;входные;dh-строка,dl-столбец,al-фон,si-смещение к фразе
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
phrase:  ; proc near
                push    ax
                push    dx
		push	si
		push	di
		push	ds
		push	es
                xchg    al,ah
		call	seg_win
		dw ie_sub_di_di
		xchg	dh,dl		;поменять местами строку и столбец
                dw ie_mov_al_dh           ;сохранить столбец
		dw ie_xor_dh_dh
		dw ie_mov_di_dx		;строка
		call	mul_80
                dw ie_mov_dl_al           ;восстановить столбец
		dw ie_add_di_dx
                shl     di,1           ;абсолютное смещение на экране
                mov     al," "
		call	cga1
met_ph1:
		stosw
                lodsb
                dw ie_or_al_al
                jnz     met_ph1
                mov     al," "
		stosw
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	dx
                pop     ax
		ret
;phrase		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;		SUBROUTINE	INFO
;вывод информационной панели
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
info:  ; proc near
		push	ds
		push	cs
		pop	ds
		dw ie_sub_cx_cx
		call	seg_win
		mov	di,8
		cmp	byte [act_pan],cl
		jnz	met_inf0
		mov	cl,40
		inc	di
met_inf0:
		dw ie_mov_dl_cl
		add	dl,40
		mov	dh,22
		mov	si,dat_info
		mov	al,[ fon0 ]
		dw ie_mov_ah_al
		call	window
		sub	dl,38
		mov	dh,1
		mov	si,phrase_ver
		call	phrase
		mov	dh,2
		mov	si,phrase_copyright
		call	phrase
		mov	dh,3
		mov	si,phrase_town
		call	phrase
		mov	al,[wind+9]
		dw ie_mov_ah_al
		call	one_line
		add	dx,030fh
		mov	al,[ fon0 ]
		mov	si,byte_mem
		call	phrase
		int	12h
		mov	bx,1024
		mul	bx
		dw ie_mov_di_cx
		shl	di,1
		add	di,160*6+32
		call	number
		mov	al,[ fon1 ]
		call	color
		mov	dx,0712h
		dw ie_add_dx_cx
		mov	al,[ fon0 ]
		mov	si,byte_free
		call	phrase
		int	12h
		mov	bx,40h
		mul	bx
		mov	bx,[segm_data]
		dw ie_sub_ax_bx
		mov	bx,16
		mul	bx
		dw ie_mov_di_cx
		shl	di,1
		add	di,160*7+34
		call	number
		mov	al,[ fon1 ]
		call	color
		mov	dx,0812h
		dw ie_add_dx_cx
		mov	al,[ fon0 ]
		mov	si,byte_drive
		call	phrase
		inc	dh
		dec	dx
		call	phrase
		sub	dl,5
		mov	si,free
		call	phrase
		dec	dh
		mov	si,total
		call	phrase
		mov	ah,19h
		int	21h
		dw ie_mov_dx_ax
		add	al,"A"
		inc	dx
		dw ie_mov_di_cx
		shl	di,1
		add	di,160*8+68
		mov	ah,[fon1]
		mov	bl,":"
		stosw
		xchg	al,bl
		stosw
		add	di,154
		xchg	al,bl
		stosw
		xchg	al,bl
		stosw
		sub	di,160+48
		mov	ah,36h	;свободное пространство на диске
		int	21h
		dw ie_mov_si_dx
		mul	cx
		dw ie_mov_dx_si
		dw ie_mov_si_ax
		mul	dx
		call	cga
		call	number
		mov	al,[ fon1 ]
		call	color
		add	di,160
		dw ie_mov_ax_si
		mul	bx
		call	number
		mov	al,[ fon1 ]
		call	color
		pop	ds
		ret
;закраска в al цвет, di-конец цифры
color:
		std
		push	cx
		push	di
		mov	cx,9
		inc	di
		call	cga1
met_color0:
		stosb
		dec	di
		loop	met_color0
		pop	di
		pop	cx
		cld
met_ent5:
		ret
;info		endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;		SUBROUTINE	CTR+ENTER
;вывод в командную строку имени файла, выделенного курсором
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
ctr_enter:  ; proc near
;определить положение выделенного символа, если директория, то выход
                call    this_subdir
;		jnz	met_ent5		;да
		dw ie_sub_bx_bx
met_ent6:
		inc	bx
		cmp	byte [si+bx-1],0
		jnz	met_ent6
		dw ie_mov_cx_bx
		mov	ax,127
		mov	di,stack0+st0d_com_line
;сравнить длину со свободным местом
		add	bl,byte [cs:di-2]
		dw ie_cmp_bl_al
		ja	met_ent5
		dw ie_mov_bx_di
;сдвинуть от курсора на длину имени+1 в коммандной линии
		push	si
		dw ie_add_di_ax
		dw ie_mov_si_di
		dw ie_sub_si_cx
		sub	al,[cs:bx-1]	;положение курсора
		xchg	ax,cx
		dw ie_sub_cx_ax
		inc	cx
		push	cs
		push	cs
		pop	es
		pop	ds
		std
		rep	movsb
		cld
		dw ie_mov_di_si
		inc	di
;сдвинуть курсор на длину имени
		dw ie_mov_ah_al
		add	word [bx-2],ax	;символ с курсором и последний
		pop	si
;записать выделенный файл
		call	seg_dat
		dw ie_mov_cl_al
		rep	movsb
		mov	byte [es:di-1]," "
		mov	di,stack0+st0d_com_line
		dw ie_xor_al_al
		call	accept
		ret
;ctr_enter	endp

;▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
;			SUBROUTINE ERROR
;выдача соовщения о ошибке
;входные:al - код ошибки
;▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
error:  ; proc near
		cmp	byte [cs:met_int_24],0;фатальная ошибка уже обработана
		jz	met_error83
		mov	byte [cs:met_int_24],0
		stc
		ret
met_error83:
		push	bx
		push	cx
		push	dx
		push	si
		push	ds
		sti
		cld
		call	clear_buf_key
		push	cs
		pop	ds
		push	word [begin_wind]
		push	word [long_wind]
		add	word [begin_buffer_wind],size_wind-270h ;смест. буфер окна
		mov	si,dat_error
		cmp	al,80		;файл существует
		jz	met_errorf0
		cmp	al,0f0h		;вставить дискету
		jnz	met_error84
met_errorf0:
		mov	si,dat_warning
met_error84:
		push	ax
		mov	al,[ fon5 ]
		dw ie_mov_ah_al
		mov	cx,0a12h
                mov     dx,0f3eh
		call	window
		pop	ax
		mov	dh,0ch
		mov	si,create
met_error13:
		cmp	al,13h		;усторойство защищено от записи
		jnz	met_error15
		mov	si,no_write
		jmp	short met_error53
met_error15:
		cmp	al,15h		;дисковое усторойство не готово
		jnz	met_error1b
		mov	si,not_ready
		jmp	short met_error53
met_error1b:
		cmp	al,1bh		;диск не форматирован
		jnz	met_error1c
		mov	si,not_format
		jmp	short met_error53
met_error1c:
		cmp	al,1ch		;нет бумаги в принтере
		jnz	met_error1d
		mov	si,not_paper
		jmp	short met_error53
met_error1d:
		cmp	al,1dh		;no write
		jnz	met_error1e
		mov	si,not_write
		jmp	short met_error53
met_error1e:
		cmp	al,1eh		;диск не читаем
		jb	met_error53
		cmp	al,1fh
		ja	met_error53
		mov	si,not_read
		jmp	short met_error53

;определение кода  ошибки
met_error53:
		cmp	al,80
		jz	met_error58
		jmp	met_error54
met_error58:
		mov	al,[ fon5 ]
		mov	si,already_exists
		call	print_name
		inc	dh
		mov	si,write_old
		call	print_name
                inc     dh
		dw ie_mov_bl_al
		mov	bh,[ fon4 ]
		mov	cl,1
met_error55:
		dw ie_mov_al_bh
		test	cl,1
		jnz	e1
		dw ie_mov_al_bl
e1:
		mov	si,overwrite
		mov	dl,27
		call	phrase
		dw ie_mov_al_bh
		test	cl,2
		jnz	e2
		dw ie_mov_al_bl
e2:
		mov	si,all
		mov	dl,39
		call	phrase
		dw ie_mov_al_bh
		test	cl,4
		jnz	e3
		dw ie_mov_al_bl
e3:
		mov	si,skip
		mov	dl,45
		call	phrase
		call	halt
		cmp	ah,1	;esc
		jz	e6
		cmp	ah,28	;enter
		jz	met_error57
		cmp	ah,75
		jnz	e4
		test	cl,1
		jz	e9
		or	cl,8
e9:
		shr	cl,1
		jmp	short met_error55
e4:
		cmp	ah,77
		jnz	met_error55
		shl	cl,1
		test	cl,7
		jnz	e0
		mov	cl,1
e0:
		jmp	short met_error55
met_error57:
		test	cl,1
		jnz	e17
		test	cl,4
		jz	e7
		mov	ah,31		;skip
e6:
		stc
		jmp	short e17
e7:
		not	byte [met_overwrite]
e17:
		jmp	met_error62
met_error54:
		cmp	al,2
		jnz	met_error73
		mov	si,not_file
		jmp	short met_error63
met_error73:
		cmp	al,8
		jnz	met_error64
		mov	si,enough
		jmp	short met_error63
met_error64:
		cmp	al,90h		;удаление самого себя
		jnz	met_error65
		mov	si,inself
		jmp	short met_error63
met_error65:
		cmp	al,91h		;нет sp.mnu
		jnz	met_error66
		mov	si,phrase_user
		jmp	short met_error63
met_error66:
		cmp	al,92h		;нет sp.hlp
		jnz	met_error67
		mov	si,phrase_help
		jmp	short met_error63
met_error67:
		cmp	al,6		;попытка удаления не пустой директории
		jnz	met_errorf1
		mov	si,empty
		jmp	short met_error63
met_errorf1:
		cmp	al,0f1h
		jnz	met_error71
		mov	si,not_command
		jmp	short met_error63
met_error71:
		cmp	al,0f0h
		jnz	met_error59
		mov	si,insert_disk
		mov	[si+26],bl
met_error63:
		mov	al,[ fon5 ]
		call	print_name
		mov	si,ok
		mov	dh,0eh
		mov	al,[ fon4 ]
		call	print_name
		call	halt
		jmp	short met_error62

met_error59:
		mov	bl,[ fon4 ]
		mov	bh,[ fon5 ]
		dw ie_mov_al_bh
		call	print_name
met_error60:
		dw ie_mov_al_bl
		mov	si,dat_retry
		mov	dx,0e20h
		call	phrase
		dw ie_mov_al_bh
		mov	dl,29h
		mov	si,dat_abort
		call	phrase
		xchg	bl,bh
met_error61:
		call	halt
		cmp	ah,77
		jz	met_error60
		cmp	ah,75
		jz	met_error60
		cmp	ah,28
		jnz	met_error61
		cmp	bl,[ fon5 ]
		jz	met_error62	;retry
		stc			;abort
met_error62:
		pushf
		call	clear_window
		sub	word [begin_buffer_wind],size_wind-270h
		popf
		pop	word [long_wind]
		pop	word [begin_wind]
		pop	ds
		pop	si
		pop	dx
		pop	cx
		pop	bx
		ret
;error		endp
set_dta:
		mov	dx,80h
		mov	ah,1ah		;установка области DTA [cs:80h]
		int	21h
		ret
;положения символов	 012   3   45	6   7   8   9	10
wind		db	"╔═╗","║","╚╝","╤","┴","│","─","░"
winda		db	"РФС","Х","УТ","В","и","е","д","Ы"
tabl		db	"░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪┘┌█▄▌▐▀"
		db	"ЫЬЭезГДЕЖЧХСТЛМбгижйдкНОУРШЦЩФЪА"
		db	"БВЗИЙКПЮЯвалмнопрстуфхцчшщъыьэюяЁёЄєЇїЎў°∙·√№¤■"
scan_tabl	db	"QWERTYUIOP[]  ASDFGHJKL;'` \ZXCVBNM1234567890-="
key_tabl_edit	dw	met_e585	;"7"
		dw	met_e510	;"8"
		dw	met_e530	;"9"
		dw	met_e899	;"-"
		dw	met_e540	;"4"
		dw	met_e899	;"5"
		dw	met_e550	;"6"
		dw	met_e899	;"+"
		dw	met_e580	;"1"
		dw	met_e500	;"2"
		dw	met_e520	;"3"

		dw	met_e640	;ctr+"4"
		dw	met_e650	;ctr+"6"
		dw	met_e660	;ctr+"1"
		dw	met_e660	;ctr+"3"
		dw	met_e680	;ctr+"7"
met_func	dw	help
                dw      menu
		dw	view
		dw	edit
		dw	copy
		dw	ren_mov
		dw	makdir
		dw	delete
                dw      exedit

segm_wind	dw	0b800h		;сегмент экрана cga
size_cursor	dw	0607h		;форма курсора: 0a0bh - MDA

;****************************** цветной режим *****************************

fon0		db	00011011b	;синий фон, голубые символы
fon1		db	00011110b	;синий фон, желтые символы
fon2		db	00000111b 	;черный фон, белые символы
fon3		db	00110000b	;голубой фон, черные символы-инвер. MDA
fon4		db	01110000b	;белый фон, черные символы
fon5		db	01001111b	;красный фон, белые символы
fon6		db	00111110b	;голубой фон, желтые символы

;**************************** черно - белый режим *************************

;fon0		db	07h
;fon1		db	0fh
;fon2		db	07h
;fon3		db	70h
;fon4		db	07h
;fon5		db	70h
;fon6		db	01111111b	;белый фон, ярко-белые символы

;07h -обычный ; 0fh -выделенный; 9-подчеркнутый; 70h -инверсия для MDA
;7fh - выделенный для черно-белого режима
param_mda	dw	0b000h		;MDA экран
		dw	0a0bh		;размер курсора
		dw	0f07h	;смена фона выводимых символов
		dw	7007h
		dw	7007h
		db	09h
phrase_help	db	"There is no file "
sp_hlp		db	"SP.HLP",0		;код ошибки 92h
phrase_user	db	"There is no file "
sp_mnu		db	"SP.MNU",0		;код ошибки 91h
sp_com		db	"SP.COM",0
quit_no_mem	db	"Out of memory$"
phrase_menu	db	"External editor",0
phrase_ver      db      "The Sparrow Commander, Version 1.20",0,8,", "
phrase_copyright db     "Copyright (C) 1994  by Afanasyev V.",0,10,13
return		db	10,13,"$"
phrase_town	db	"Severodvinsk, Truda 20-76, 4-16-48.",0
not_ready	db	"Drive or device not ready",0
no_write	db	"Write protect error in drive",0
not_format	db	"The disk may not be formatted",0
not_read	db	"Can't read the drive",0
not_write	db	"Can't write the drive",0
not_paper	db	"Printer out of paper",0
not_command	db	"Can't find command.com",0
not_file	db	"Can't find the file",0
already_exists	db	"The file already exists.",0
write_old	db	"Do you wish to write over the old file?",0
last_save       db      "You've made changes since the last save.",0
empty		db	"Subdirectory it is not empty",0
inself		db	"You can't copy a file to inself",0
enough		db	"There isn't enough room to copy",0
create		db	"Can't open the file",0
phrase_quit	db	"Do you want to quit the Sparrow?",0
extern_edit	db	"Do you want to use the external editor?",0
phrase_setup	db	"Do you wish to save the current setup?",0
insert_disk	db	"Insert diskette for drive "
drive		db	"A",0
ok		db	"Ok",0
phrase_yes	db	"Yes",0
phrase_no	db	"No",0
sparrow		db	"The Sparrow",0
drive_letter	db	"Drive letter",0
select		db	"unselect",0
dat_select	db	"unselect all files?",0
select_line     db      "           bytes      selected files",0
dat_delete_files db     "   files",0
create_dir	db	"Create the directory",0
create_file	db	"Edit the file",0
search_for	db	"Search for the string",0
phrase_delete	db	"Do you wish to delete",0
not_save	db	"Don't save",0
cont_edit	db	"Continue editing",0
dat_del		db	"deleting the file",0
dat_cop		db	"copying the file",0
dat_mov		db	"moving the file",0
dat_ren		db	"renaming the file",0
dat_vie		db	"reading the file",0
dat_conv	db	"converting the file",0
searching_for	db	"searching for",0
not_found	db	"string not found",0
byte_free	db	"Bytes Free",0
byte_mem	db	"Bytes Memory",0
byte_drive	db	"bytes on drive",0
user_menu	db	"User Menu",0
bytes		db	"bytes",0
total		db	"total",0
free		db	"free",0
dat_path	db	"A:\..",0
dat_to		db	"to",0
overwrite	db	"Overwrite",0
skip		db	"Skip",0
all		db	"All",0
no_param	dw	0d00h
dat_sub_dir	db	"SUB-DIR"
dat_up_dir	db	"UP--DIR"
dat_help        db      "1Help",0,0,0
dat_user        db      "2Menu",0,0,0
dat_view        db      "3View",0,0,0
dat_edit        db      "4Edit",0,0,0
dat_copy        db      "5Copy",0,0,0
dat_renmov	db	"6RenMov",0
dat_mkdir       db      "7Mkdir",0,0
dat_delete	db	"8Delete",0
dat_menu        db      "9ExEdit",0
dat_quit        db      "10Quit",0,0,0
dat_cnv		db	"Convrt",0
dat_search	db	"Search",0
dat_name	db	"Name",0
dat_size	db	"Size",0
dat_date	db	"Date",0
dat_time	db	"Time",0
dat_cansel	db	"Cansel",0
dat_error	db	"Error",0
dat_warning	db	"Warning",0
dat_retry	db	"Retry",0
dat_abort	db	"Abort",0
dat_info	db	"Info",0
dat_move	db	"Move",0
dat_save	db	"Save",0
dat_col		db	"Col:",0
dat_line	db	"Line:",0
dat_char	db	"Ch:",0
dat_ins		db	"Ins",0
dat_over	db	"Over",0
dat_setup	db	"Setup",0
dat_com		db	"com",0
dat_exe		db	"exe",0
dat_bat		db	"bat",0
dat_prn		db	"PRN",0
dat_con		db	"CON",0
comspec		db	"COMSPEC="
met_cga		db	0		;0ffh - гасить снег cga
noread		db	0		;0ffh - ошибка при чтении диска
met_error       db      0               ;0ffh - признак ошибки int 21h
met_root        db      0               ;1 - признак ошибки int 21h
met_info	db	0		;0ffh - включена информац. панель
video_mode	db	0		;текущий видеорежим
met_int_24	db	0		;<>0 - происходил вызов 24h
cga_wait	db	0		;задержка запуска функции cga
met_ins		db	0		;0 - ins ; 1 - over; в view-мет. поиска
pred_point	db	0		;0ffh - на предыдущ. символ перед tab
	;совместное использование
met_com		db	0		;если равно 0, то первый проход прогр.
met_keep_line	db	0		;0ffh - запускалась хоть одна программа

met_sort	db	0ffh		;0ffh - сортировка по именам, 0 - нет
met_view_color	dw	0		;0ffh - выделять найденную комбинацию
met_convert	db	0		;0ffh - конвертор работает
met_overwrite	db	0		;0ffh - перезаписывать все файлы
met_renmov	db	0		;0ffh - удалять файлы после копирования
keep_file	db	0ffh		;0 - сохранять выделение, 0ffh - нет
size_file	dw	0		;сколько раз перемещ. файл. манипулятор
keep_number	dw	0		;смещение к концу выделенных файлов
end_pos_wind	dw	0		;конец экрана при view и edit
name_disp	dw	0		;смещ. имени в буфере 0b0h
drive_file	dw	0		;хранит имена драйверов при копировании
					;смещ. к редактируемому имени файла

	;совместное использование
begin_txt	dw	0		;смещ. курсора в тексте
begin_colon	dw	0		;начальная колонка на экране edit
old_begin_colon	dw	0		;предыдущ. значение начальн. колонки
begin_line	dw	0		;линия с курсором на экране edit
begin_pos_wind	dw	0		;начало экрана при view и edit
pos_simbol	dw 	0		;смещение введеного символа в буфере
old_pos_curs	dw	0		;предыдущ. колонка курсора
pos_backspace	dw	0		;колич. символов удаления backspace
met_edit	dw	0		;0 - редактирование не производилось

old_begin_line	dw	0		;линия с курсором на экране edit
begin_point	dw	0		;начальная точка поиска в строке
pos_curs	dw	0		;позиция курсора на экране
old_pos_wind	dw	0		;последнее положение при поиске view
begin_wind	dw	0		;смещение окна на экране
act_screen	db	0		;0-на экране оболочка, 0ffh-исходн.
hlt_ass		db	0		;0-нормально, 0ffh-состояние ожидания
old_size_file	dw	0		;последняя позиция при поиске
long_wind	dw	0		;размеры окна: low-длина,high-ширина
segm_data	dw	0		;сегмент данных программы
path_sp_end	dw	0		;место, куда вставить имя (SP.HLP ...)
met_path	dw	stack0+st0d_path0		;смещение пути к левой панели
		dw	stack0+st0d_path1		;смещение пути к правой панели
begin_buffer_wind dw	begin_wind_mem			;смещ. стертого окна
met_dir0	dw	begin_wind_mem+size_wind 	;смещ. таблицы dir0
met_dir1	dw	begin_wind_mem+size_wind+18h	;смещ. таблицы dir1
met_data	dw	0		;смещение данных
max_pos0	dw	0		;всего строк на левой панели
max_pos1	dw	0		;всего строк на правой панели
num_pos0	dw	0		;номер файла,содер. курсор на левой пан
num_pos1	dw	0		;номер файла,содер.курсор на правой пан
act_pan		dw	1		;панель, в которой находится курсор
act_drive	dw	0		;low:0,1-акт. позиц.;high-всего дисков
high_pos0	dw	0		;номер файла в верхней поз. экрана
high_pos1	dw	0		;номер файла в верхней поз. экрана
sum_sel0	dw	0		;количество выделенных файлов
sum_sel1	dw	0		;количество выделенных файлов
dat_sel_ax0	dw	0		;колич. байт в выделенных файлах
dat_sel_ax1	dw	0
dat_sel_dx0	dw	0
dat_sel_dx1	dw	0
begin_free_memory dw	0		;первый 16 байтный свободный блок
size_block	dw	0		;размер блока для копирования
handle0		dw	0		;номер открытого файла
handle1		dw	0		;номер открытого файла
attrib_file	db	0		;атрибут копируемого файла
long_incomp	dw	0		;длина скопированной части
long_view_file	dd	0		;длина просматриваемого файла
param_block	dw	0,0,0,0,0,0,0   ;вать корень '.'и '..'
dir_net		db	01,10h,0ah,49h,0e8h,01ch,0,0,0,0,'.','.',0
;активная позиция - панель, с которой происходит дисковая операция
ext_edit	db	13,10
                db      0,27,27,0,"Здесь вставляется имя внешнего редактора для команды ExEdit."
stack0:

; __END__
