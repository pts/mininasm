; -*- coding: cp437 -*-
;
; vcsetupm.nasm: assembly source of vcsetup.com in Volkov Commander 4.05
; ported to multiple assemblers by pts@fazekas.hu at 2026-05-24 09:51:59 CEST
; based on assembly source files written by Vsevolod V. Volkov in 1991--2000
;   downloaded from https://vc.vvv.kyiv.ua/download/src/vc405.zip
;
;; This is an 8086 (i86) assembly source file compatible with NASM >=0.98.39
;; and https://github.com/pts/mininasm >=v6 .
;
; Compilation commands:
;
;   nasm -O9999 -o vcsetup.com vcsetupm.nasm
;   nasm -O9999 -DSHW=1 -o vcsetups.com vcsetupm.nasm
;   mininasm -O9999 -o vcsetup.com vcsetupm.nasm
;   mininasm -O9999 -DSHW=1 -o vcsetups.com vcsetupm.nasm
;
; vcsetup.com is the freeware variant, vcsetups.com is the shareware
; variant.
;

;-------------------------------------------------------
;		Version :	14.06.2000
;-------------------------------------------------------

BITS 16
CPU 8086

;%macro _BOXHD 7
;  DW %1, %2, %3
;  DB %4, %5, %6, %7
;%endm
;%macro _BOXMN 8
;  DB %1, %2, %3, %4, %5
;  DW %6, %7, %8
;%endm

; --- TASM-comatible instruction encoding.
_ADC_AL_AL EQU 0C012h
_ADC_AX_AX EQU 0C013h
_ADC_BL_AL EQU 0D812h
_ADC_BP_DX EQU 0EA13h
_ADC_BX_BX EQU 0DB13h
_ADC_BX_CX EQU 0D913h
_ADC_BX_SI EQU 0DE13h
_ADC_CX_DX EQU 0CA13h
_ADC_DI_AX EQU 0F813h
_ADC_DI_BX EQU 0FB13h
_ADC_DX_CX EQU 0D113h
_ADC_DX_DX EQU 0D213h
_ADC_SI_BX EQU 0F313h
_ADD_AH_AL EQU 0E002h
_ADD_AH_BL EQU 0E302h
_ADD_AH_CH EQU 0E502h
_ADD_AH_CL EQU 0E102h
_ADD_AH_DH EQU 0E602h
_ADD_AL_AH EQU 0C402h
_ADD_AL_BH EQU 0C702h
_ADD_AL_CL EQU 0C102h
_ADD_AL_DH EQU 0C602h
_ADD_AL_DL EQU 0C202h
_ADD_AX_AX EQU 0C003h
_ADD_AX_BP EQU 0C503h
_ADD_AX_BX EQU 0C303h
_ADD_AX_CX EQU 0C103h
_ADD_AX_DI EQU 0C703h
_ADD_AX_DX EQU 0C203h
_ADD_AX_SI EQU 0C603h
_ADD_BH_AH EQU 0FC02h
_ADD_BH_AL EQU 0F802h
_ADD_BH_CH EQU 0FD02h
_ADD_BH_CL EQU 0F902h
_ADD_BH_DH EQU 0FE02h
_ADD_BH_DL EQU 0FA02h
_ADD_BL_AL EQU 0D802h
_ADD_BL_BL EQU 0DB02h
_ADD_BL_CH EQU 0DD02h
_ADD_BL_CL EQU 0D902h
_ADD_BL_DL EQU 0DA02h
_ADD_BP_AX EQU 0E803h
_ADD_BP_BP EQU 0ED03h
_ADD_BP_BX EQU 0EB03h
_ADD_BP_CX EQU 0E903h
_ADD_BP_DI EQU 0EF03h
_ADD_BP_SI EQU 0EE03h
_ADD_BX_AX EQU 0D803h
_ADD_BX_BP EQU 0DD03h
_ADD_BX_BX EQU 0DB03h
_ADD_BX_CX EQU 0D903h
_ADD_BX_DI EQU 0DF03h
_ADD_BX_DX EQU 0DA03h
_ADD_BX_SI EQU 0DE03h
_ADD_CH_AL EQU 0E802h
_ADD_CL_DH EQU 0CE02h
_ADD_CX_AX EQU 0C803h
_ADD_CX_BP EQU 0CD03h
_ADD_CX_CX EQU 0C903h
_ADD_CX_DI EQU 0CF03h
_ADD_CX_DX EQU 0CA03h
_ADD_DH_BH EQU 0F702h
_ADD_DI_AX EQU 0F803h
_ADD_DI_CX EQU 0F903h
_ADD_DI_DI EQU 0FF03h
_ADD_DI_DX EQU 0FA03h
_ADD_DL_CL EQU 0D102h
_ADD_DL_DH EQU 0D602h
_ADD_DX_AX EQU 0D003h
_ADD_DX_BX EQU 0D303h
_ADD_DX_CX EQU 0D103h
_ADD_DX_DI EQU 0D703h
_ADD_DX_SI EQU 0D603h
_ADD_SI_AX EQU 0F003h
_ADD_SI_BP EQU 0F503h
_ADD_SI_BX EQU 0F303h
_ADD_SI_CX EQU 0F103h
_ADD_SI_DI EQU 0F703h
_ADD_SI_DX EQU 0F203h
_AND_AX_DX EQU 0C223h
_CMP_AH_AL EQU 0E03Ah
_CMP_AH_CH EQU 0E53Ah
_CMP_AL_AH EQU 0C43Ah
_CMP_AL_BH EQU 0C73Ah
_CMP_AL_BL EQU 0C33Ah
_CMP_AL_CH EQU 0C53Ah
_CMP_AL_CL EQU 0C13Ah
_CMP_AL_DH EQU 0C63Ah
_CMP_AL_DL EQU 0C23Ah
_CMP_AX_BP EQU 0C53Bh
_CMP_AX_BX EQU 0C33Bh
_CMP_AX_CX EQU 0C13Bh
_CMP_AX_DI EQU 0C73Bh
_CMP_AX_DX EQU 0C23Bh
_CMP_AX_SI EQU 0C63Bh
_CMP_BH_BL EQU 0FB3Ah
_CMP_BH_CH EQU 0FD3Ah
_CMP_BH_DH EQU 0FE3Ah
_CMP_BH_DL EQU 0FA3Ah
_CMP_BL_CL EQU 0D93Ah
_CMP_BL_DL EQU 0DA3Ah
_CMP_BP_AX EQU 0E83Bh
_CMP_BP_BX EQU 0EB3Bh
_CMP_BP_CX EQU 0E93Bh
_CMP_BP_DI EQU 0EF3Bh
_CMP_BP_DX EQU 0EA3Bh
_CMP_BX_AX EQU 0D83Bh
_CMP_BX_CX EQU 0D93Bh
_CMP_BX_DX EQU 0DA3Bh
_CMP_BX_SI EQU 0DE3Bh
_CMP_CH_AH EQU 0EC3Ah
_CMP_CH_AL EQU 0E83Ah
_CMP_CH_BH EQU 0EF3Ah
_CMP_CH_BL EQU 0EB3Ah
_CMP_CH_CL EQU 0E93Ah
_CMP_CH_DH EQU 0EE3Ah
_CMP_CH_DL EQU 0EA3Ah
_CMP_CL_AH EQU 0CC3Ah
_CMP_CL_AL EQU 0C83Ah
_CMP_CL_BH EQU 0CF3Ah
_CMP_CL_BL EQU 0CB3Ah
_CMP_CL_CH EQU 0CD3Ah
_CMP_CL_DL EQU 0CA3Ah
_CMP_CX_AX EQU 0C83Bh
_CMP_CX_BP EQU 0CD3Bh
_CMP_CX_BX EQU 0CB3Bh
_CMP_CX_SI EQU 0CE3Bh
_CMP_DH_AH EQU 0F43Ah
_CMP_DH_AL EQU 0F03Ah
_CMP_DH_CH EQU 0F53Ah
_CMP_DH_DL EQU 0F23Ah
_CMP_DI_AX EQU 0F83Bh
_CMP_DI_BP EQU 0FD3Bh
_CMP_DI_BX EQU 0FB3Bh
_CMP_DI_CX EQU 0F93Bh
_CMP_DI_DX EQU 0FA3Bh
_CMP_DI_SI EQU 0FE3Bh
_CMP_DL_CL EQU 0D13Ah
_CMP_DX_AX EQU 0D03Bh
_CMP_DX_CX EQU 0D13Bh
_CMP_DX_DI EQU 0D73Bh
_CMP_SI_AX EQU 0F03Bh
_CMP_SI_BP EQU 0F53Bh
_CMP_SI_BX EQU 0F33Bh
_CMP_SI_CX EQU 0F13Bh
_CMP_SI_DI EQU 0F73Bh
_CMP_SI_DX EQU 0F23Bh
_MOV_AH_AL EQU 0E08Ah
_MOV_AH_BH EQU 0E78Ah
_MOV_AH_BL EQU 0E38Ah
_MOV_AH_CH EQU 0E58Ah
_MOV_AH_DH EQU 0E68Ah
_MOV_AH_DL EQU 0E28Ah
_MOV_AL_AH EQU 0C48Ah
_MOV_AL_BH EQU 0C78Ah
_MOV_AL_BL EQU 0C38Ah
_MOV_AL_CH EQU 0C58Ah
_MOV_AL_CL EQU 0C18Ah
_MOV_AL_DH EQU 0C68Ah
_MOV_AL_DL EQU 0C28Ah
_MOV_AX_BP EQU 0C58Bh
_MOV_AX_BX EQU 0C38Bh
_MOV_AX_CX EQU 0C18Bh
_MOV_AX_DI EQU 0C78Bh
_MOV_AX_DX EQU 0C28Bh
_MOV_AX_SI EQU 0C68Bh
_MOV_BH_AH EQU 0FC8Ah
_MOV_BH_AL EQU 0F88Ah
_MOV_BH_BL EQU 0FB8Ah
_MOV_BH_CH EQU 0FD8Ah
_MOV_BH_CL EQU 0F98Ah
_MOV_BH_DH EQU 0FE8Ah
_MOV_BH_DL EQU 0FA8Ah
_MOV_BL_AH EQU 0DC8Ah
_MOV_BL_AL EQU 0D88Ah
_MOV_BL_BH EQU 0DF8Ah
_MOV_BL_CL EQU 0D98Ah
_MOV_BP_AX EQU 0E88Bh
_MOV_BP_BX EQU 0EB8Bh
_MOV_BP_CX EQU 0E98Bh
_MOV_BP_DI EQU 0EF8Bh
_MOV_BP_DX EQU 0EA8Bh
_MOV_BP_SI EQU 0EE8Bh
_MOV_BP_SP EQU 0EC8Bh
_MOV_BX_AX EQU 0D88Bh
_MOV_BX_BP EQU 0DD8Bh
_MOV_BX_CX EQU 0D98Bh
_MOV_BX_DI EQU 0DF8Bh
_MOV_BX_DX EQU 0DA8Bh
_MOV_BX_SI EQU 0DE8Bh
_MOV_CH_AH EQU 0EC8Ah
_MOV_CH_AL EQU 0E88Ah
_MOV_CH_BH EQU 0EF8Ah
_MOV_CH_CL EQU 0E98Ah
_MOV_CH_DH EQU 0EE8Ah
_MOV_CH_DL EQU 0EA8Ah
_MOV_CL_AH EQU 0CC8Ah
_MOV_CL_AL EQU 0C88Ah
_MOV_CL_BH EQU 0CF8Ah
_MOV_CL_BL EQU 0CB8Ah
_MOV_CL_CH EQU 0CD8Ah
_MOV_CL_DH EQU 0CE8Ah
_MOV_CL_DL EQU 0CA8Ah
_MOV_CX_AX EQU 0C88Bh
_MOV_CX_BP EQU 0CD8Bh
_MOV_CX_BX EQU 0CB8Bh
_MOV_CX_DI EQU 0CF8Bh
_MOV_CX_DX EQU 0CA8Bh
_MOV_CX_SI EQU 0CE8Bh
_MOV_DH_AH EQU 0F48Ah
_MOV_DH_AL EQU 0F08Ah
_MOV_DH_BH EQU 0F78Ah
_MOV_DH_CL EQU 0F18Ah
_MOV_DH_DL EQU 0F28Ah
_MOV_DI_AX EQU 0F88Bh
_MOV_DI_BP EQU 0FD8Bh
_MOV_DI_BX EQU 0FB8Bh
_MOV_DI_CX EQU 0F98Bh
_MOV_DI_DX EQU 0FA8Bh
_MOV_DI_SI EQU 0FE8Bh
_MOV_DL_AH EQU 0D48Ah
_MOV_DL_AL EQU 0D08Ah
_MOV_DL_BH EQU 0D78Ah
_MOV_DL_BL EQU 0D38Ah
_MOV_DL_CH EQU 0D58Ah
_MOV_DL_CL EQU 0D18Ah
_MOV_DL_DH EQU 0D68Ah
_MOV_DX_AX EQU 0D08Bh
_MOV_DX_BP EQU 0D58Bh
_MOV_DX_BX EQU 0D38Bh
_MOV_DX_CX EQU 0D18Bh
_MOV_DX_DI EQU 0D78Bh
_MOV_DX_SI EQU 0D68Bh
_MOV_SI_AX EQU 0F08Bh
_MOV_SI_BP EQU 0F58Bh
_MOV_SI_BX EQU 0F38Bh
_MOV_SI_CX EQU 0F18Bh
_MOV_SI_DI EQU 0F78Bh
_MOV_SI_DX EQU 0F28Bh
_MOV_SP_BP EQU 0E58Bh
_OR_AH_AH EQU 0E40Ah
_OR_AH_DL EQU 0E20Ah
_OR_AL_AH EQU 0C40Ah
_OR_AL_AL EQU 0C00Ah
_OR_AL_BH EQU 0C70Ah
_OR_AL_BL EQU 0C30Ah
_OR_AL_CH EQU 0C50Ah
_OR_AX_AX EQU 0C00Bh
_OR_AX_BX EQU 0C30Bh
_OR_AX_DI EQU 0C70Bh
_OR_AX_DX EQU 0C20Bh
_OR_BH_BH EQU 0FF0Ah
_OR_BL_BL EQU 0DB0Ah
_OR_BP_BP EQU 0ED0Bh
_OR_BP_BX EQU 0EB0Bh
_OR_BP_DI EQU 0EF0Bh
_OR_BP_DX EQU 0EA0Bh
_OR_BX_AX EQU 0D80Bh
_OR_BX_BX EQU 0DB0Bh
_OR_BX_DX EQU 0DA0Bh
_OR_CH_CH EQU 0ED0Ah
_OR_CL_CL EQU 0C90Ah
_OR_CX_BX EQU 0CB0Bh
_OR_DI_AX EQU 0F80Bh
_OR_DI_DI EQU 0FF0Bh
_OR_DL_AL EQU 0D00Ah
_OR_DL_DL EQU 0D20Ah
_OR_DX_BX EQU 0D30Bh
_OR_DX_CX EQU 0D10Bh
_OR_DX_DX EQU 0D20Bh
_OR_SI_DX EQU 0F20Bh
_OR_SI_SI EQU 0F60Bh
_SBB_AX_CX EQU 0C11Bh
_SBB_BP_DX EQU 0EA1Bh
_SBB_BX_SI EQU 0DE1Bh
_SBB_CX_DX EQU 0CA1Bh
_SBB_CX_SI EQU 0CE1Bh
_SBB_DI_BX EQU 0FB1Bh
_SBB_DX_AX EQU 0D01Bh
_SBB_DX_BX EQU 0D31Bh
_SBB_SI_BX EQU 0F31Bh
_SUB_AH_AL EQU 0E02Ah
_SUB_AH_BH EQU 0E72Ah
_SUB_AH_CL EQU 0E12Ah
_SUB_AL_AH EQU 0C42Ah
_SUB_AL_BL EQU 0C32Ah
_SUB_AL_CH EQU 0C52Ah
_SUB_AL_CL EQU 0C12Ah
_SUB_AL_DL EQU 0C22Ah
_SUB_AX_BX EQU 0C32Bh
_SUB_AX_CX EQU 0C12Bh
_SUB_AX_DI EQU 0C72Bh
_SUB_AX_DX EQU 0C22Bh
_SUB_AX_SI EQU 0C62Bh
_SUB_BH_AL EQU 0F82Ah
_SUB_BH_BL EQU 0FB2Ah
_SUB_BH_CL EQU 0F92Ah
_SUB_BH_DH EQU 0FE2Ah
_SUB_BL_AH EQU 0DC2Ah
_SUB_BL_AL EQU 0D82Ah
_SUB_BL_CL EQU 0D92Ah
_SUB_BL_DL EQU 0DA2Ah
_SUB_BP_AX EQU 0E82Bh
_SUB_BP_BX EQU 0EB2Bh
_SUB_BX_AX EQU 0D82Bh
_SUB_BX_BP EQU 0DD2Bh
_SUB_BX_CX EQU 0D92Bh
_SUB_BX_DX EQU 0DA2Bh
_SUB_BX_SI EQU 0DE2Bh
_SUB_CH_AL EQU 0E82Ah
_SUB_CH_BH EQU 0EF2Ah
_SUB_CH_CL EQU 0E92Ah
_SUB_CL_AH EQU 0CC2Ah
_SUB_CL_AL EQU 0C82Ah
_SUB_CL_BL EQU 0CB2Ah
_SUB_CL_CH EQU 0CD2Ah
_SUB_CX_AX EQU 0C82Bh
_SUB_CX_BP EQU 0CD2Bh
_SUB_CX_BX EQU 0CB2Bh
_SUB_CX_DI EQU 0CF2Bh
_SUB_CX_DX EQU 0CA2Bh
_SUB_CX_SI EQU 0CE2Bh
_SUB_DH_DL EQU 0F22Ah
_SUB_DI_AX EQU 0F82Bh
_SUB_DI_BP EQU 0FD2Bh
_SUB_DI_BX EQU 0FB2Bh
_SUB_DI_CX EQU 0F92Bh
_SUB_DI_DX EQU 0FA2Bh
_SUB_DI_SI EQU 0FE2Bh
_SUB_DL_AL EQU 0D02Ah
_SUB_DL_CL EQU 0D12Ah
_SUB_DX_AX EQU 0D02Bh
_SUB_DX_CX EQU 0D12Bh
_SUB_DX_DI EQU 0D72Bh
_SUB_DX_SI EQU 0D62Bh
_SUB_SI_AX EQU 0F02Bh
_SUB_SI_BX EQU 0F32Bh
_SUB_SI_CX EQU 0F12Bh
_SUB_SI_DI EQU 0F72Bh
_SUB_SI_DX EQU 0F22Bh
_TEST_AL_CL EQU 0C184h
_XCHG_AH_AL EQU 0E086h
_XCHG_AH_CL EQU 0E186h
_XCHG_AH_DH EQU 0E686h
_XCHG_AL_AH EQU 0C486h
_XCHG_AL_CL EQU 0C186h
_XCHG_BH_AL EQU 0F886h
_XCHG_BL_AL EQU 0D886h
_XCHG_BL_BH EQU 0DF86h
_XCHG_BP_CX EQU 0E987h
_XCHG_BP_SI EQU 0EE87h
_XCHG_BX_CX EQU 0D987h
_XCHG_BX_DI EQU 0DF87h
_XCHG_BX_DX EQU 0DA87h
_XCHG_CX_DX EQU 0CA87h
_XCHG_CX_SI EQU 0CE87h
_XCHG_DI_CX EQU 0F987h
_XCHG_DI_DX EQU 0FA87h
_XCHG_DI_SI EQU 0FE87h
_XCHG_DX_BX EQU 0D387h
_XCHG_DX_DI EQU 0D787h
_XCHG_SI_DI EQU 0F787h
_XOR_AH_AL EQU 0E032h
_XOR_AL_BL EQU 0C332h
_XOR_AL_CL EQU 0C132h
_XOR_AX_AX EQU 0C033h
_XOR_AX_BX EQU 0C333h
_XOR_BP_AX EQU 0E833h
_XOR_BP_BP EQU 0ED33h
_XOR_BX_BX EQU 0DB33h
_XOR_CX_CX EQU 0C933h
_XOR_DI_AX EQU 0F833h
_XOR_DI_DI EQU 0FF33h
_XOR_DX_CX EQU 0D133h
_XOR_DX_DX EQU 0D233h
_XOR_SI_AX EQU 0F033h
_XOR_SI_SI EQU 0F633h

%ifdef SHW
SHWW EQU SHW
%else
SHWW EQU 2  ; Default: freeware.
%endif
%if SHWW&~1
  SHWW_LE_1 EQU 0
%else
  SHWW_LE_1 EQU 1
%endif

;%define PrgName 'Volkov Commander'
;%if SHWW_LE_1
;%define VcVers '4.05 shareware'
;%else
;%define VcVers '4.05 freeware'
;%endif
;%define HelpVer 'VC 4.05 Help'
VcApiVr EQU 42

MoDelay EQU 40  ; Mouse double click delay
MiliSec EQU 60  ; auto CD time : sec x 0.01
Sec EQU 0  ;                sec x 1
LenPath EQU 68  ; Length of path name
LenColr EQU 40  ; Length of color table
LenStr EQU 40  ; Length of string
MaxLins EQU 50  ; Maximum screen lines
NmbStrs EQU 32  ; Number of stars

;------------------ Global structures ------------------

; Country information structure definition.
CNTRY:  ; STRUC
.DateFmt: EQU 0  ; RESW 1  ; Date format
	; RESB 5  ; Currency
.Sep1000: EQU .DateFmt+(1)*2+(5)  ; RESB 2  ; Thousand separator
.DecSep: EQU .Sep1000+(2)  ; RESB 2  ; Decimal separator
.DateSep: EQU .DecSep+(2)  ; RESB 2  ; Date separator
.TimeSep: EQU .DateSep+(2)  ; RESB 2  ; Time separator
	; RESB 1  ; Currency format
	; RESB 1  ; Number of meaning digits in currency
.TimeFmt: EQU .TimeSep+(2)+(1)+(1)  ; RESB 1  ; Time format
.CaseMp: EQU .TimeFmt+(1)  ; RESW 2  ; Addres of case map. Far pointer.
	; RESB 2  ; Data separator
	; RESB 8  ; Reserved
CNTRY_size: EQU .CaseMp+(2)*2+(2)+(8)  ; ENDSTRUC

; The dialog box header structure definition.
BOXHD:  ; STRUC
.pDiBox: EQU 0  ; RESW 1  ; Pointer to DialBox structure
.BoxBase: EQU .pDiBox+(1)*2  ; RESW 1  ; The dialog box begin-center
.SubFunc: EQU .BoxBase+(1)*2  ; RESW 1  ; Subfunction
.bKeyBar: EQU .SubFunc+(1)*2  ; RESB 1  ; KeyBar
.bMenu: EQU .bKeyBar+(1)  ; RESB 1  ; 0FFh		; PutMnu
.bHelp: EQU .bMenu+(1)  ; RESB 1  ; 0			; HlpPage
.bFlags: EQU .bHelp+(1)  ; RESB 1  ; 0			; Flags
BOXHD_size: EQU .bFlags+(1)  ; ENDSTRUC

; The dialog box header structure definition.
BOXMN:  ; STRUC
.mType: EQU 0  ; RESB 1  ; Menu type
.mUp: EQU .mType+(1)  ; RESB 1  ; 0			; Up link
.mDown: EQU .mUp+(1)  ; RESB 1  ; 0			; Down link
.mLeft: EQU .mDown+(1)  ; RESB 1  ; 0			; Left link
.mRight: EQU .mLeft+(1)  ; RESB 1  ; 0			; Right link
.mBase: EQU .mRight+(1)  ; RESW 1  ; Menu base
.mPoint: EQU .mBase+(1)*2  ; RESW 1
.mCtrl: EQU .mPoint+(1)*2  ; RESW 1
BOXMN_size: EQU .mCtrl+(1)*2  ; ENDSTRUC
BOXMN_mSelTot EQU BOXMN.mCtrl  ; BYTE PTR.

; The star structure definition.
STAR:  ; STRUC
.StarMod: EQU 0  ; RESW 1  ; Low byte - counter, High - explosion
.StarPos: EQU .StarMod+(1)*2  ; RESW 1  ; Coordinates of star
STAR_size: EQU .StarPos+(1)*2  ; ENDSTRUC
STAR_StarClk EQU STAR.StarMod  ; BYTE PTR.  ; Time counter

;-------------------- WCB definition -------------------
WCBdef:  ; STRUC
.WinTyp: EQU 0  ; RESB 1
.BrfFul: EQU .WinTyp+(1)  ; RESB 1
.Visible: EQU .BrfFul+(1)  ; RESB 1
.Hidden: EQU .Visible+(1)  ; RESB 1
.MasTyp: EQU .Hidden+(1)  ; RESB 1
.SortTyp: EQU .MasTyp+(1)  ; RESB 1
.Ctrl_L: EQU .SortTyp+(1)  ; RESB 1
.DskMas: EQU .Ctrl_L+(1)  ; RESB 13
.WinPath: EQU .DskMas+(13)  ; RESB LenPath
WCBdef_size: EQU .WinPath+(LenPath)  ; ENDSTRUC

HlpData:  ; STRUC
.HlpMode: EQU 0  ; RESW 1
.HlpSize: EQU .HlpMode+(1)*2  ; RESW 1
.HlpLins: EQU .HlpSize+(1)*2  ; RESW 1
	; RESW 1
.HlpBkLn: EQU .HlpLins+(1)*2+(1)*2  ; RESW 1
.HlpOffs: EQU .HlpBkLn+(1)*2  ; RESW 2
.HlpFrst: EQU .HlpOffs+(2)*2  ; RESW 1
.HlpCur: EQU .HlpFrst+(1)*2  ; RESW 1
	; RESB 8
HlpData_size: EQU .HlpCur+(1)*2+(8)  ; ENDSTRUC

;------------------- Begin of program ------------------
;SECTION .CODE
ORG 100h
Base EQU 100h
;GLOBAL Start
Start:
	CLD
	MOV AX, 3000h  ; Check DOS version
	INT 21h
	DW _XCHG_AL_AH
	CMP AX, STRICT WORD 314h  ; 3.20 ?
	MOV DX, Vers_S
	MOV AL, 2
	JB Init01
	PUSH AX  ; Allocate segments
	MOV BX, 1000h
	MOV AH, 4Ah
	INT 21h
	POP AX
	JNC Init03
	MOV DX, Aloc_S  ; Not enough memory
	MOV AL, 1
Init01:	PUSH AX
	MOV AH, 9
	INT 21h
	POP AX
	CMP AH, 3
	JB Init02
	MOV AH, 4Ch
	INT 21h
Init02:	RET
Init03:	MOV SP, 0FFFEh

;--------------------- Output Report -------------------
	MOV AH, 0Fh
	INT 10h
	CMP AH, 80
	JNE Init04
	AND AL, 7Fh
	CMP AL, 2
	JE Init05
	CMP AL, 3
	JE Init05
	CMP AL, 7
	JE Init05
Init04:	MOV AX, 3
	INT 10h
Init05:	MOV DX, Init_S
	MOV AH, 9
	INT 21h

;------------------ Read configuration -----------------
	MOV ES, [2Ch]  ; Without adding DS: or Start-Base here, TASM 3.2 would report warning ``[Constant] assumed to mean immediate constant'', and then fail.
	MOV DX, NcPath
	DW _XOR_DI_DI
	MOV CL, 1
	MOV AL, 0
	MOV [IniStat], AL
Init10:	CMP AL, [ES:DI]
	JE Init11
	MOV SI, NcEnv
	MOV CX, 3
	PUSH DI
	REPE CMPSB
	POP DI
	JE Init11
	MOV CX, 0FFFFh
	REPNE SCASB
	JMP Init10
Init11:	PUSH CX
	PUSH CS
	PUSH ES
	POP DS
	POP ES
	LEA SI, [DI+3]
	DW _MOV_DI_DX
	MOV CX, LenPath-1
	PUSH DI
	REP MOVSB
	PUSH CS
	POP DS
	POP SI
	MOV [DI], CL
Init12:	DW _MOV_BX_SI
Init13:	LODSB
	CMP AL, '\'
	JE Init12
	CMP AL, ':'
	JE Init12
	CMP AL, 0
	JNE Init13
	DW _MOV_DI_SI
	DEC DI
	POP CX
	JCXZ Init14
	DW _MOV_DI_BX
Init14:	DW _CMP_DI_DX
	JBE Init15
	CMP BYTE [DI-1], ':'
	JE Init15
	MOV AL, '\'
	CMP AL, [DI-1]
	JE Init15
	STOSB
Init15:	PUSH DI  ; Read VC.HLP
	PUSH DX
	CALL RdHelp
	POP DX
	POP DI
	MOV SI, Init_F
	MOV CX, 13
	REP MOVSB
	MOV AX, 3D40h  ; Open VC.INI
	INT 21h
	JC Init18
	DW _MOV_BX_AX
	MOV DX, IniData
	MOV CX, IniLen+1
	MOV AH, 3Fh
	INT 21h
	PUSH AX
	PUSHF
	MOV AH, 3Eh
	INT 21h
	POP BP
	POP AX
	JC Init18
	PUSH BP
	POPF
	JC Init18
	INC BYTE [IniStat]
	DEC CX  ; Check VC.INI length
	DW _CMP_AX_CX
	JNE Init17
	DW _MOV_DI_DX  ; Check header
	MOV AL, 'V'
	PUSH CX
	MOV CX, 3
	REPE SCASB
	POP CX
	JNE Init17
	DEC CX  ; Check sum
	DEC CX
	DW _MOV_SI_DX
	DW _XOR_DX_DX
	MOV AH, 0
Init16:	LODSB
	DW _ADD_DX_AX
	LOOP Init16
	LODSW
	DW _CMP_AX_DX
	JE Init20
Init17:	INC BYTE [IniStat]  ; Bad data in VC.INI
Init18:	CALL Default_

;---------------- Initialize data segment --------------
Init20:	MOV SI, ColTab  ; Save source VC.INI
	MOV DI, SrcIni
	MOV CX, CmnIni
	REP MOVSB
	MOV AX, 3300h  ; Save BREAK status
	INT 21h
	MOV [BreakFl], DL
	MOV DL, 0
	MOV AX, 3301h
	INT 21h
	PUSH ES  ; Set break vectors
	MOV AX, 351Bh
	INT 21h
	MOV [BrkVct+0], BX
	MOV [BrkVct+2], ES
	MOV DX, CtrlC
	MOV AH, 25h
	INT 21h
	MOV AX, 2523h
	INT 21h
	POP ES

	MOV DX, Country  ; Country
	MOV AX, 3800h
	INT 21h
	MOV DI, TmpBuf  ; Lower case table
	MOV SI, LowTab
	MOV CX, 80h
	PUSH DI
	PUSH CX
Init21:	DW _MOV_AL_CL
	NEG AL
	MOV [SI], AL
	INC SI
	CALL FAR [Country+CNTRY.CaseMp]
	STOSB
	LOOP Init21
	POP CX
	POP SI
	MOV BH, 0
	MOV AH, 80h
Init22:	LODSB
	DW _CMP_AL_AH
	JE Init23
	CMP AL, 80h
	JB Init23
	DW _MOV_BL_AL
	MOV [BX+LowTab-128], AH
Init23:	INC AH
	LOOP Init22

	MOV BYTE [Quote], 0  ; Quote
	MOV BYTE [MnItem], 0  ; MnItem
	MOV BYTE [BarPrev], 0FFh  ; BarPrev

	MOV AH, 0Fh  ; Get screen mode
	INT 10h
	AND AL, 7Fh
	MOV [ScrMod], AL
	MOV [ScrPage], BH
	MOV AH, 3  ; Save cursor position
	INT 10h
	MOV [DosLin], DH
	CMP CH, 0Fh  ; Correct cursor size
	JBE Init24
	MOV CX, 607h
Init24:	CMP CX, 67h
	JNE Init25
	MOV CX, 607h
Init25:	CMP BYTE [ScrMod], 7
	JNE Init26
	CMP CX, 607h
	JNE Init26
	MOV CX, 0B0Ch
Init26:	MOV [CurType], CX
	MOV BYTE [TstEGA], 0  ; TstEGA
	MOV AH, 12h
	MOV BL, 10h
	INT 10h
	PUSH CX
	PUSH BX
	NOT BX
	NOT CX
	MOV AH, 12h
	MOV BL, 10h
	INT 10h
	POP AX
	POP DX
	DW _XOR_AX_BX
	DW _XOR_DX_CX
	DW _OR_AX_DX
	JNE Init27
	MOV BYTE [TstEGA], 1
Init27:	MOV AL, 25  ; Lines
	MOV DL, 0
	CMP DL, [TstEGA]
	JE Init28
	PUSH ES
	PUSH AX
	MOV BH, 0
	MOV AX, 1130h
	INT 10h
	POP AX
	POP ES
	DW _OR_DL_DL
	JE Init28
	INC DX
	MOV AL, MaxLins
	DW _CMP_AL_DL
	JBE Init28
	DW _MOV_AL_DL
Init28:	MOV [Lines], AL
	PUSH DS  ; Screen Offset
	DW _XOR_SI_SI
	MOV AH, 0Fh
	INT 10h
	DW _OR_BH_BH
	JE Init29
	MOV DS, SI
	MOV SI, [44Eh]
Init29:	POP DS
	MOV [Screen+0], SI
	MOV BX, 0B800h  ; Screen Segment
	CMP BYTE [ScrMod], 7
	JNE Init30
	MOV BX, 0B000h
Init30:	MOV [Screen+2], BX
	PUSH ES  ; Virtual screen buffer
	MOV ES, BX
	MOV AH, 0FEh
	INT 10h
	MOV AX, ES
	POP ES
	MOV CL, 0
	DW _CMP_AX_BX
	JE Init31
	MOV BYTE [Snow], 1
	MOV [Screen+2], AX
	MOV [Screen+0], DI
	MOV CL, 1
Init31:	MOV [TopView], CL
	MOV CX, 'ED'  ; Check DESQview
	MOV DX, 'QS'
	MOV AX, 2B01h
	INT 21h
	INC AX
	MOV [DesqVie], AL
	CALL SetSnow  ; Snow

	CALL HidCur  ; Hide cursor
	CALL SavScr  ; Save screen
	MOV SI, ScrBuf  ; Restore screen
	MOV DI, UserScr
	MOV AL, 80
	MUL BYTE [Lines]
	DW _MOV_CX_AX
	REP MOVSW

	MOV AX, 21h  ; Init mouse
	INT 33h
	CMP AX, STRICT WORD 21h
	JNE Init33
	DW _XOR_AX_AX
	INT 33h
Init33:	CMP AX, STRICT WORD 0FFFFh
	CMC
	MOV AL, 0
	DW _ADC_AL_AL
	MOV [Mouse], AL
	DW _OR_AL_AL
	JZ Init35
	MOV AL, 0
	CALL TypMous
	MOV DL, [Lines]
	CMP DL, 25
	JE Init34
	MOV DH, 0
	MOV CL, 3
	SHL DX, CL
	DEC DX
	DW _XOR_CX_CX
	MOV AX, 8
	INT 33h
Init34:	MOV AL, 1
	CALL CurMous
Init35:

	CMP BYTE [IniStat], 1
	JE Err3
	MOV DX, NoFnd_S
	JB Err1
	MOV DX, NoIni_S
Err1:	MOV BP, IniEr_B
	CALL Dialog
	JZ Err2
	JMP Exit
Err2:	MOV DI, SrcIni
	MOV AL, 0FFh
	REP STOSB
Err3:	JMP Register  ; !! This jump is not necessary, it jumps directly to the next instruction.

;GLOBAL Register
Register:  ; PROC  ; Processes the --register command-line flag (`vcsetup --register' displays the registration dialog and saves the resulting registration info to vc.ini). Jumped to at initialization time, before Main00.
%if SHWW_LE_1
	MOV SI, 081h  ; SI := address of of command-line string in PSP.
RegisterNextSpace1:
	LODSB
	CMP AL, ' '
	JZ RegisterNextSpace1
	CMP AL, 9  ; TAB.
	JZ RegisterNextSpace1
	DEC SI
	MOV DI, DDReg_S  ; '--REGISTER',0. 10 non-zero bytes.
RegisterNextFlagChar:
	LODSB
	CALL UpCase
	SCASB
	JNE RegisterDone
	CMP BYTE [ES:DI], 0  ; !! The ES: segment prefix is not needed here, because DS == ES. (!! Double check.)
	JNZ RegisterNextFlagChar
RegisterNextSpace2:
	LODSB
	CMP AL, ' '
	JZ RegisterNextSpace2
	CMP AL, 9  ; TAB.
	JZ RegisterNextSpace2
	CMP AL, 13  ; CR.
	JNZ RegisterDone
	MOV SI, RRegTo
	MOV DI, TmpBufRRegTo
	MOV CX, RNumCp-RRegTo-1
	REP MOVSB
	MOV AL, 0
	STOSB
	MOV SI, RNumCp
	MOV DI, TmpBufRNumCp
	PUSH DI
	MOV CL, RChkSum-RNumCp-1
	REP MOVSB
	STOSB
	POP DI  ; DI := OFFSET TmpBufRNumCp.
	CMP AL, [DI]
	JNE RegisterGoodRNumCp  ; Jumps iff BYTE PTR [DI] is non-NUL.
	MOV WORD [DI], '1'  ; Default number of copies is 1.
RegisterGoodRNumCp:
	MOV DI, TmpBufRNumCpChar1  ; It will contain NUL if RNumCp is empty, otherwise it will contain its first character (byte).
	STOSB
	MOV BP, Reg1_B
	CALL Dialog
	JNZ RegisterJExit
	MOV SI, TmpBuf
	MOV DI, RRegTo
	MOV CX, RNumCp-RRegTo  ; Number of bytes in Registered user name.
	CALL RegisterMemzcpy
	MOV SI, TmpBufRNumCp
	MOV DI, RNumCp
	MOV CL, RChkSum-RNumCp  ; CH is already 0.
	CALL RegisterMemzcpy
RegisterJExit:
	JMP Exit
RegisterDone:
	JMP Main00
%endif
;Register ENDP

%if SHWW_LE_1
;GLOBAL Reg1Check
Reg1Check:  ; PROC  ; Checks whether the values entered in the Reg1 (registration info) dialog box are valid.
	CMP AL, 0
	JNE Reg1CheckDone
	MOV SI, TmpErr+64+3  ; !! How is this calculated?
	MOV DX, NCE1_S  ; 'Number of copies',0,'is empty.'.
	LODSB
	CMP AL, 0
	JE Reg1CheckFailed
	DEC SI
	MOV DX, RIC1_S  ; 'Invalid characters',0,'in number of copies.'.
	MOV AH, 0
Reg1CheckNextNumCpChar:
	LODSB
	CMP AL, 0
	JE Reg1CheckDoneNumCp
	CMP AL, '0'
	JE Reg1CheckNextNumCpChar
	MOV AH, 1
	JC Reg1CheckFailed
	CMP AL, '9'
	JA Reg1CheckFailed
	JMP SHORT Reg1CheckNextNumCpChar
Reg1CheckDoneNumCp:
	MOV DX, NCZ1_S  ; 'Number of copies',0,'must be greater than 0.'.
	DW _OR_AH_AH
	JZ Reg1CheckFailed
	DW _XOR_BX_BX
	DW _XOR_DI_DI
	MOV SI, TmpErr+128+3  ; !! How is this calculatd?
	MOV CX, 8
	MOV AH, 0
Reg1CheckNextCodeChar:
	PUSH CX
	MOV CL, 4
	DW _MOV_AL_BH
	SHL BX, CL
	SHL DI, CL
	SHR AX, CL
	DW _OR_DI_AX
	POP CX
	MOV DX, RCC1_S  ; 'Registration code must',0,'contain 8 characters.'.
	LODSB
	CMP AL, 0
	JZ Reg1CheckFailed
	CALL UpCase
	MOV DX, RCI1_S  ; 'Invalid characters',0,'in registration code.'.
	SUB AL, '0'
	JC Reg1CheckFailed
	CMP AL, '9'-'0'  ; TAB.
	JNA Reg1CheckGoodCodeChar
	SUB AL, 7
	CMP AL, 17-7
	JC Reg1CheckFailed
	CMP AL, 15
	JA Reg1CheckFailed
Reg1CheckGoodCodeChar:
	DW _OR_BX_AX
	LOOP Reg1CheckNextCodeChar
	DW _MOV_AX_BX
	DW _MOV_BX_DI
	MOV DI, RChkSum
	STOSW
	DW _MOV_AX_BX
	STOSW
	DW _XOR_AX_AX  ; Also sets CF := 0, indicating success.
	JMP SHORT Reg1CheckDone
Reg1CheckFailed:  ; OFfset of error message is in DX.
	DW _MOV_DI_DX
	MOV CH, 1
	MOV AL, 0
	REPNE SCASB
	MOV [Reg2_V], DI
	MOV BP, Reg2_B
	CALL Dialog
	STC  ; Sets CF := 1, indicating failure.
Reg1CheckDone:
	RET
;Reg1Check ENDP
%endif

%if SHWW_LE_1
;GLOBAL RegisterMemzcpy
RegisterMemzcpy:  ; PROC
	LODSB
	CMP AL, 0
	JNZ RegisterMemcpyNulAgain
	DEC SI
RegisterMemcpyNulAgain:
	STOSB
	LOOP RegisterMemzcpy
	RET
;RegisterMemzcpy ENDP
%endif

Main00:	MOV AL, 0
	CALL PutKey
	MOV BX, 528h
	MOV BP, Main_P
	CALL DialBox
	CALL Window
	PUSH SI
	MOV CH, [MnItem]
	MOV WORD [MousTim+2], 0FFFFh
	MOV BYTE [MousEnt], 0
Main01:	MOV AH, HstCu_C  ; Set cursor
	CALL Main40
	DW _MOV_AL_CH
	CBW
	DW _MOV_SI_AX
	MOV AL, [SI+MainHlp]
	MOV [HlpPage], AL
Main02:	PUSH CX
	CALL GetMous
	POP CX
	JNZ Main30
	MOV BYTE [MousEnt], 0
	MOV AL, 0  ; Input
	CALL Input
	CMP AH, 0FCh
	JE Main30
	MOV SI, Main_T
	CALL Case
	JMP Main02
Main10:	DW _MOV_AL_CH  ; Up
	CMP AL, 0
	JE Main13
	DEC AX
	JMP Main14
Main11:	DW _MOV_AL_DH  ; Down
	SUB AL, 6
	DW _CMP_CH_AL
	JAE Main12
	DW _MOV_AL_CH
	INC AX
	JMP Main14
Main12:	MOV AL, 0  ; Home, PgUp
	JMP Main14
Main13:	DW _MOV_AL_DH  ; End, PgDn
	SUB AL, 6
Main14:	DW _CMP_AL_CH
	JE Main02
	MOV AH, Hist_C
	CALL Main40
	DW _MOV_CH_AL
	JMP Main01
Main20:	MOV CH, 0  ; Configuration
	JMP Main32
Main21:	MOV CH, 1  ; Screen and Mouse
	JMP Main32
Main22:	MOV CH, 2  ; Panel options
	JMP Main32
Main23:	MOV CH, 3  ; Set Black & White palette
	JMP Main32
Main24:	MOV CH, 4  ; Set Color palette
	JMP Main32
Main25:	MOV CH, 5  ; Set Laptop palette
	JMP Main32
Main26:	MOV CH, 6  ; Set default configuration
	JMP Main32
Main27:	MOV CH, 7  ; Country info
	JMP Main32
Main30:	CALL Main50  ; Mouse
	CMP AH, 1
	JB Main02
	JE Main14
	CMP AH, 1Ch
	JE Main32
Main31:	MOV CH, 40h  ; Exit
Main32:	POP SI  ; Enter
	CALL ResWin
	CALL Window
	DW _MOV_AL_CH
	MOV [MnItem], AL
	MOV SI, Menu_T
	MOV AH, 1
	INC AX
	CALL Case
	JMP Exit

;GLOBAL Main40
Main40:  ; PROC NEAR
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	ADD BX, 209h
	DW _ADD_BH_CH
	MOV DH, 1
	SUB DL, 16
	DW _MOV_CL_DL
	MOV CH, 0
	CALL BasAdr
	CALL Color
	DW _MOV_AL_AH
	CALL MvsColr
	CALL Window
	POP AX
	POP BX
	POP CX
	POP DX
	RET
;Main40 ENDP

;GLOBAL Main50
Main50:  ; PROC NEAR  ; Mouse
	PUSH CX
	DW _XOR_SI_SI
Main51:	CALL GetMous
	JZ Main54
	DW _MOV_BP_CX
	CALL ClrKbd
	MOV AH, 'x'
	TEST AL, 3
	JZ Main52
	MOV AH, 0
Main52:	DW _MOV_CX_SI
	DW _MOV_SI_AX
	DW _CMP_AH_CH
	JE Main53
	DW _MOV_AL_AH
	CALL TypMous
Main53:	TEST SI, 3
	JZ Main51
	PUSH BX
	PUSH DX
	ADD BX, 204h
	SUB DX, 50Ah
	DW _MOV_CX_BP
	CALL InWind
	POP DX
	POP BX
	JC Main51
	JMP Main57
Main54:	MOV AL, 0
	CALL TypMous
	POP CX
	DW _MOV_AX_SI
	CMP AL, 2
	JE Main56
	CMP AL, 1
	JB Main56
	JNE Main55
	PUSH DX
	PUSH CX
	DW _MOV_CX_BP
	SUB DX, 102h
	CALL InWind
	POP CX
	POP DX
	JNC Main56
Main55:	MOV AH, 0FFh
	RET
Main56:	MOV AH, 0
	RET
Main57:	DW _SUB_CX_BX
	DW _MOV_AL_CH
	SUB AL, 2
	CBW
	DW _MOV_SI_AX
	PUSH DX
	PUSH BX
	PUSH AX
	ADD BX, 204h
	DW _ADD_BH_AL
	SUB DL, 10
	MOV DH, 1
	CALL DoublMo
	POP AX
	POP BX
	POP DX
	POP CX
	JNC Main58
	MOV AH, 1
	RET
Main58:	JE Main56
	MOV AL, 0
	CALL TypMous
	MOV AH, 1Ch
	RET
;Main50 ENDP

F02_00:	MOV BL, [KeyBar]
	MOV BP, Conf_B
	CALL Dialog
	CMP BYTE [KeyBar], 0
	JNZ F02_01
	DW _OR_BL_BL
	JZ F02_01
	MOV BH, [Lines]
	DEC BH
	MOV BL, 0
	MOV AL, 2*80
	MUL BH
	MOV SI, UserScr
	MOV DI, ScrBuf
	DW _ADD_SI_AX
	DW _ADD_DI_AX
	MOV CX, 80
	REP MOVSW
	MOV DX, 150h
	CALL Window
	MOV BYTE [BarPrev], 0FFh
F02_01:	JMP Main00

F03_00:	PUSH ES
	POP DS
	MOV DI, TmpBuf
	MOV AL, [ColTyp]
	STOSB
	STOSB
	MOV AH, [BlDelay]
	MOV SI, Delay_T-1
	MOV AL, 0-1
F03_01:	INC AL
	INC SI
	CMP AH, [CS:SI]
	JB F03_01
	STOSB
	STOSB
	MOV AL, [SnowMod]
	STOSB
	STOSB
	MOV BP, Scrn_B
	CALL Dialog
	JNE F03_02
	MOV SI, TmpBuf
	LODSW
	MOV [ColTyp], AL
	LODSW
	CBW
	DW _MOV_BX_AX
	MOV AL, [CS:BX+Delay_T]
	MOV [BlDelay], AL
	LODSW
	MOV [SnowMod], AL
F03_02:	CALL SetSnow
	JMP Main00

F04_00:	MOV DI, TmpBuf+9
	MOV AL, [DelayTm+1]
	CMP AL, 99
	JBE F04_01
	MOV AL, 99
F04_01:	CALL HexDec
	CMP AL, '0'
	JE F04_02
	STOSB
F04_02:	DW _MOV_AL_AH
	MOV AH, [Country+CNTRY.DecSep]
	STOSW
	MOV AL, [DelayTm]
	CMP AL, 99
	JBE F04_03
	MOV AL, 99
F04_03:	CALL HexDec
	STOSW
	MOV AL, 0
	STOSB
	MOV BP, PanOp_B
	CALL Dialog
	JMP Main00

;GLOBAL F04_10
F04_10:  ; PROC NEAR  ; Test delay time
	CMP AL, 0
	JNE F04_15
	MOV SI, TmpErr+3
	CALL FndLet
	CMP AL, 0
	JE F04_15
	DW _XOR_CX_CX
	CMP AL, [Country+CNTRY.DecSep]
	JE F04_11
	CALL TxtNum
	JC F04_18
	CMP AX, STRICT WORD 99
	JA F04_18
	DW _MOV_CH_AL
	PUSH SI
	CALL FndLet
	POP SI
	CMP AL, 0
	JE F04_17
	MOV AL, [SI]
	CMP AL, [Country+CNTRY.DecSep]
	JNE F04_18
	PUSH SI
	INC SI
	CALL FndLet
	POP SI
	CMP AL, 0
	JE F04_17
F04_11:	INC SI
	PUSH SI
	MOV CL, 0FFh
F04_12:	INC CL
	LODSB
	CMP AL, '0'
	JE F04_12
	POP SI
	CALL TxtNum
	JC F04_18
	PUSH AX
	CALL FndLet
	CMP AL, 0
	POP AX
	JNE F04_18
	CMP AX, STRICT WORD 10
	JAE F04_13
	MOV AH, 10
	MUL AH
F04_13:	CMP CL, 1
	MOV BX, 100
	JB F04_14
	MOV BX, 10
	JE F04_14
	MOV BL, 1
F04_14:	DW _CMP_AX_BX
	JB F04_16
	DW _XOR_DX_DX
	MOV SI, 10
	DIV SI
	JMP F04_14
F04_15:	RET
F04_16:	DW _MOV_CL_AL
F04_17:	MOV [DelayTm], CX
	MOV AL, 0
	CLC
	RET
F04_18:	MOV BP, NoTim_B
	CALL Dialog
	MOV BYTE [HlpPage], 3
	STC
	RET
;F04_10 ENDP

F05_00:	MOV SI, BwPal_S
	DW _XOR_BP_BP
	JMP F07_01

;------------------ Set Color palette ------------------
F06_00:	MOV SI, ColMd_S
	MOV BP, 1
	JMP F07_01

;----------------- Set Laptop palette ------------------
F07_00:	MOV SI, LapTp_S
	MOV BP, 2
F07_01:	MOV BYTE [HlpPage], 4
	PUSH SI  ; Color table
	MOV SI, ColMd_S
	CMP BYTE [ScrMod], 7
	JNE F07_02
	MOV SI, MonMd_S
F07_02:	PUSH SI
	MOV BX, 58
	MOV DH, [Lines]
	CMP BYTE [KeyBar], 0
	JZ F07_03
	DEC DH
F07_03:	MOV DL, 22
	CALL BasAdr
	PUSH DI
	DW _MOV_CL_DH
	MOV CH, 0
	MOV AH, Back_C
	CALL Color
	MOV [BackC], AH
	MOV AL, ' '
F07_04:	PUSH DI
	PUSH CX
	MOV CL, 22
	REP STOSW
	POP CX
	POP DI
	ADD DI, 2*80
	LOOP F07_04
	POP DI
	POP CX
	PUSH DI
	ADD DI, 2*(80+4)
	MOV SI, Mode_S
	CALL MovDz0
	DW _MOV_SI_CX
	CALL MovDz0
	POP DI
	POP CX
	PUSH DI
	ADD DI, 2*(160+1)
	MOV SI, Palet_S
	CALL MovDz0
	DW _MOV_SI_CX
	CALL MovDz0
	POP DI
	ADD DI, 2*(320+3)
	MOV CX, 16
	MOV AX, 'x'
F07_05:	PUSH DI
	PUSH CX
	MOV CX, 16
F07_06:	STOSW
	INC AH
	LOOP F07_06
	POP CX
	POP DI
	ADD DI, 2*80
	LOOP F07_05
	CALL Window

	MOV BX, 203h  ; Output window
	MOV DH, [Lines]
	SUB DH, 3
	MOV DL, 53
	MOV AH, HstCu_C
	CALL Color
	MOV [HstCuC], AH
	MOV AH, Hist_C
	CALL Color
	MOV [HistC], AH
	CALL MinBox
	CALL BasAdr
	ADD DI, 2*(80+19)
	MOV SI, Color_S
	MOV CX, 13
	CALL MvsBwc
	CALL Window
	DW _XOR_AX_AX
	DW _XOR_SI_SI
	MOV DI, Colrs_S
F07_07:	INC SI
	MOV CX, 0FFFFh
	REPNE SCASB
	CMP AL, [DI]
	JNE F07_07
	MOV [ColNum], SI
	MOV [ColCur], AX
	MOV WORD [ColFrst], 0FFF0h
	MOV [WinMous], AL
	MOV [MousEnt], AL
	MOV WORD [MousTim+2], 0FFFFh
	DW _XOR_SI_SI
	DW _XOR_DI_DI
	CALL ChgCur
	PUSH CX

F07_10:	DW _CMP_SI_DI  ; Test parameters
	JAE F07_11
	DW _MOV_DI_SI
F07_11:	DW _MOV_AL_DH
	SUB AL, 5
	CBW
	DW _ADD_AX_DI
	DW _CMP_SI_AX
	JB F07_12
	DW _SUB_AX_DI
	DW _MOV_DI_SI
	DW _SUB_DI_AX
	INC DI
F07_12:	DW _MOV_AX_DI
	XCHG SI, [ColCur]
	XCHG DI, [ColFrst]
	DW _SUB_AX_DI
	JNE F07_13
	CMP SI, [ColCur]
	JNE F07_13
	JMP F07_20
F07_13:	PUSH AX  ; Reset cursor
	CMP DI, 0FFF0h
	JE F07_14
	PUSH DX
	PUSH BX
	DW _MOV_AX_SI
	DW _SUB_AX_DI
	DW _ADD_BH_AL
	DW _MOV_CX_SI
	CALL F07_65
	ADD BX, 205h
	CALL F07_70
	SUB DL, 12
	MOV DH, 1
	CALL Window
	POP BX
	POP DX
F07_14:	POP CX
	JCXZ F07_18
	PUSH CX  ; Output lines
	PUSH BX
	MOV CX, [ColFrst]
	CALL F07_65
	DW _MOV_CL_DH
	SUB CL, 5
	MOV CH, 0
	ADD BX, 205h
F07_15:	CALL F07_70
	INC BH
	CMP BYTE [SI], 0
	LOOPNE F07_15
	POP BX
	POP CX
	PUSH DX  ; Output screen
	PUSH BX
	ADD BX, 205h
	SUB DX, 50Ch
	DW _MOV_AL_DH
	DEC AX
	MOV AH, 6
	CMP CX, 1
	JE F07_16
	CMP CX, -1
	JNE F07_17
	MOV AX, 700h
F07_16:	DW _MOV_CX_BX
	DEC DL
	DEC DH
	DW _ADD_DX_CX
	PUSH AX
	MOV AH, [HistC]
	DW _MOV_BH_AH
	POP AX
	PUSH AX
	MOV AL, 1
	CALL Int10m
	POP AX
	DW _MOV_BX_CX
	DW _ADD_BH_AL
	INC DX
	MOV DH, 1
F07_17:	CALL Window
	POP BX
	POP DX
F07_18:	PUSH DX  ; Set cursor
	PUSH BX
	MOV AX, [ColCur]
	SUB AX, [ColFrst]
	DW _ADD_BH_AL
	ADD BX, 205h
	CALL BasAdr
	MOV AH, [HstCuC]
	DW _MOV_AL_AH
	SUB DL, 12
	MOV DH, 1
	DW _MOV_CL_DL
	MOV CH, 0
	CALL MvsColr
	CALL Window
	POP BX
	POP DX
	MOV AX, [ColCur]  ; Cursor on color table
	MOV AH, 6
	MUL AH
	LEA SI, [BP+ColTab]
	DW _ADD_SI_BP
	DW _ADD_SI_AX
	CMP BYTE [ScrMod], 7
	JNE F07_19
	INC SI
F07_19:	MOV AL, [SI]
	CALL F07_75

F07_20:	CALL GetMous  ; Input
	JNZ F07_30
	MOV BYTE [WinMous], 0
	MOV BYTE [MousEnt], 0
	MOV AL, 2
	CALL Input
	CMP AH, 0FCh
	JE F07_30
	MOV SI, Color_T
	CALL Case
	JMP F07_20

F07_30:	CALL GetMous  ; Mouse support
F07_31:	CALL ClrKbd
	DW _MOV_SI_CX
	TEST AL, 4
	JZ F07_33
	MOV AL, 'x'
	CALL TypMous
F07_32:	CALL GetMous
	CALL ClrKbd
	TEST AL, 4
	JNZ F07_32
	PUSH AX
	MOV AL, 0
	CALL TypMous
	POP AX
	TEST AL, 3
	JZ F07_36
F07_33:	PUSH DX
	PUSH BX
	ADD BX, 204h
	SUB DX, 50Ah
	CALL InWind
	POP BX
	POP DX
	JNC F07_37
	CMP BYTE [WinMous], 0
	JZ F07_35
	DW _MOV_AL_BH
	ADD AL, 2
	DW _CMP_CH_AL
	JB F07_40
	DW _MOV_AL_BH
	DW _ADD_AL_DH
	SUB AL, 3
	DW _CMP_CH_AL
	JAE F07_41
F07_34:	JMP F07_20
F07_35:	TEST AL, 1
	JZ F07_34
	CALL GetMous
	JNZ F07_31
	DW _MOV_CX_SI
	PUSH DX
	SUB DX, 102h
	CALL InWind
	POP DX
	JNC F07_34
F07_36:	JMP F07_57
F07_37:	OR BYTE [WinMous], 1
	PUSH CX
	DW _SUB_CH_BH
	SUB CH, 2
	DW _MOV_CL_CH
	MOV CH, 0
	MOV DI, [ColFrst]
	DW _ADD_CX_DI
	MOV AX, [ColNum]
	DEC AX
	POP SI
	XCHG AX, CX
	DW _CMP_AX_CX
	JBE F07_39
	DW _MOV_SI_CX
F07_38:	JMP F07_10
F07_39:	PUSH DX
	PUSH BX
	XCHG AX, SI
	DW _MOV_BH_AH
	ADD BL, 4
	SUB DL, 10
	MOV DH, 1
	CALL DoublMo
	POP BX
	POP DX
	JC F07_38
	JE F07_34
	MOV BYTE [MousEnt], 0
	MOV WORD [MousTim+2], 0FFFFh
	MOV AL, 0
	CALL TypMous
	JMP Col00

F07_40:	CALL F07_60  ; Up
	DW _OR_SI_SI
	JE F07_47
	DEC SI
	JMP F07_10

F07_41:	CALL F07_60  ; Down
	INC SI
	CMP SI, [ColNum]
	JB F07_47
	DEC SI
	JMP F07_10

F07_42:	DW _XOR_SI_SI  ; Home
	JMP F07_10

F07_43:	DW _XOR_DI_DI  ; End
	MOV SI, [ColNum]
	DEC SI
	JMP F07_10

F07_44:	CALL F07_60  ; PgUp
	DW _OR_DI_DI
	JNE F07_45
	DW _XOR_SI_SI
	JMP F07_47
F07_45:	DEC AX
	DW _SUB_DI_AX
	JAE F07_46
	DW _XOR_DI_DI
F07_46:	DW _ADD_AX_DI
	DW _CMP_SI_AX
	JBE F07_47
	DW _MOV_SI_AX
F07_47:	JMP F07_10

F07_48:	CALL F07_60  ; PgDn
	MOV CX, [ColNum]
	PUSH SI
	DW _MOV_SI_CX
	DW _SUB_CX_AX
	JAE F07_49
	DW _XOR_CX_CX
F07_49:	DEC AX
	DW _CMP_DI_CX
	JB F07_50
	POP AX
	DW _OR_SI_SI
	JE F07_47
	DEC SI
	JMP F07_47
F07_50:	POP SI
	DW _ADD_DI_AX
	JC F07_51
	DW _CMP_DI_CX
	JBE F07_52
F07_51:	DW _MOV_DI_CX
F07_52:	DW _CMP_SI_DI
	JAE F07_47
	DW _MOV_SI_DI
	JMP F07_10

F07_53:	CALL F07_60  ; Default colors
	PUSH BP
	MOV BP, DfCol_B
	CALL Dialog
	POP BP
	MOV BYTE [HlpPage], 4
	JNZ F07_47
	DW _MOV_DI_BP
	DW _ADD_DI_DI
	CMP BYTE [ScrMod], 7
	JNE F07_54
	INC DI
F07_54:	LEA SI, [DI+Palets]
	LEA DI, [DI+ColTab]
	MOV CX, LenColr
F07_55:	MOV AL, [SI]
	MOV [DI], AL
	ADD SI, 6
	ADD DI, 6
	LOOP F07_55
	CALL F07_60
	JMP F07_10

F07_57:	CALL HidCur  ; Exit
	POP CX
	MOV AH, 1
	INT 10h
	MOV DL, 80
	MOV DH, [Lines]
	DW _MOV_AL_DL
	MUL DH
	DW _MOV_CX_AX
	MOV SI, UserScr
	MOV DI, ScrBuf
	REP MOVSW
	DW _XOR_BX_BX
	CALL Window
	JMP Main00

;GLOBAL F07_60
F07_60:  ; PROC NEAR  ; Get parameters
	MOV SI, [ColCur]
	MOV DI, [ColFrst]
	DW _MOV_AL_DH
	SUB AL, 5
	CBW
	RET
;F07_60 ENDP

;F07_65	PROC	NEAR			; Find line #CX
;GLOBAL F07_65
F07_65:
	MOV DI, Colrs_S
F07_66:	MOV AL, 0
	JCXZ F07_68
F07_67:	PUSH CX
	MOV CX, 0FFFFh
	REPNE SCASB
	POP CX
	LOOP F07_67
F07_68:	DW _MOV_SI_DI
	RET
;F07_65	ENDP

;GLOBAL F07_70
F07_70:  ; PROC NEAR  ; Put line from SI
	PUSH CX
	PUSH AX
	CALL BasAdr
	DW _MOV_CL_DL
	SUB CL, 12
	MOV CH, 0
	MOV AH, [HistC]
	JMP F07_72
F07_71:	LODSB
	CMP AL, 0
	JNE F07_73
	DEC SI
F07_72:	MOV AL, ' '
F07_73:	STOSW
	LOOP F07_71
	INC SI
	POP AX
	POP CX
	RET
;F07_70 ENDP

;GLOBAL F07_75
F07_75:  ; PROC NEAR  ; Current color name
	PUSH BP
	PUSH DX
	PUSH CX
	PUSH BX
	DW _MOV_AH_AL
	MOV CL, 4
	SHR AH, CL
	AND AX, STRICT WORD 0F0Fh
	PUSH AX
	ADD AX, STRICT WORD 43Dh
	CALL Cursor
	POP AX
	CMP BYTE [ColCur], ShadFl
	JNE F07_76
	CMP AX, STRICT WORD 1
	MOV AX, 0FF10h
	JB F07_76
	MOV AX, 11h
	JE F07_76
	MOV AX, 7
F07_76:	PUSH AX
	CALL F07_80
	MOV BP, ColNm_P
	MOV BX, 153Ah
	CALL BasAdr
	MOV AL, ' '
	MOV AH, [CS:BP]
	CALL Color
	MOV CX, 22
	REP STOSW
	POP CX
	PUSH CX
	MOV CH, 0
	MOV DI, ColNm_S
	PUSH DI
	PUSH AX
	CALL F07_66
	PUSH BX
	ADD BL, 11
	CALL CntLine
	POP BX
	MOV DX, 116h
	CALL Window
	INC BH
	CALL BasAdr
	POP AX
	MOV CX, 22
	REP STOSW
	POP DI
	POP CX
	CMP CH, 0FFh
	JE F07_77
	DW _MOV_CL_CH
	MOV CH, 0
	CALL F07_66
	PUSH DX
	PUSH BX
	DW _MOV_DX_SI
	MOV SI, On_S
	ADD BL, 11
	CALL CntLine
	POP BX
	POP DX
F07_77:	CALL Window
	CALL F07_80
	POP BX
	POP CX
	POP DX
	POP BP
	RET
;F07_75 ENDP

;GLOBAL F07_80
F07_80:  ; PROC NEAR  ; Change color Back_C
	MOV SI, BackC
	MOV AH, Back_C
;F07_80 ENDP

;GLOBAL F07_85
F07_85:  ; PROC NEAR  ; Change color
	PUSH DI
	CALL ColAddr
	XCHG AL, [DI]
	XCHG AL, [SI]
	XCHG AL, [DI]
	POP DI
	RET
;F07_85 ENDP

Col00:	PUSH DX
	PUSH BX
	DW _XOR_AX_AX
	XCHG AL, [Clock]
	XCHG AH, [KeyBar]
	PUSH AX
	MOV AL, [ColTyp]
	PUSH AX
	DW _XOR_BX_BX
	MOV DH, [Lines]
	MOV DL, 58
	MOV SI, WinBuf
	CALL SavWin
	PUSH SI
	PUSH DX
	PUSH BX
	DW _MOV_BH_DH
	DEC BH
	MOV BL, 58
	MOV DX, 116h
	MOV AH, [BackC]
	MOV AL, ' '
	DW _MOV_CL_DL
	MOV CH, 0
	CALL BasAdr
	REP STOSW
	CALL Window
	MOV CL, [Lines]
	MOV CH, 0
	SUB CL, 25
	JBE Col02
	MOV BX, 1900h
	CALL BasAdr
Col01:	PUSH DI
	PUSH CX
	MOV CX, 58
	MOV AX, 720h
	REP STOSW
	POP CX
	POP DI
	ADD DI, 2*80
	LOOP Col01
Col02:	DW _MOV_AX_BP
	MOV [ColTyp], AL
	MOV BX, [ColCur]
	MOV BL, [BX+ColPage]
	MOV BH, 0
	DEC BX
	DW _ADD_BX_BX
	DW _ADD_BX_BX
	MOV SI, [BX+PagTab+0]
	MOV BX, [BX+PagTab+2]
	MOV DI, ScrBuf
	MOV CX, 25
Col03:	PUSH DI
	PUSH CX
Col04:	MOV AX, [BX]
	INC BX
	CMP AL, 0
	JZ Col07
	INC BX
	DW _MOV_CL_AL
	MOV CH, 0
	CMP AH, 0FFh
	JNE Col05
	MOV AL, 7
	JMP Col06
Col05:	DW _MOV_AL_AH
	AND AH, 3Fh
	CALL Color
	TEST AL, 40h
	PUSHF
	AND AL, 80h
	DW _OR_AL_AH
	POPF
	JZ Col06
	MOV AH, ShadFl
	CALL Color
	CALL ShadCol
Col06:	DW _MOV_AH_AL
	CALL MvsBwc
	JMP Col04
Col07:	POP CX
	POP DI
	ADD DI, 2*80
	LOOP Col03
	POP BX
	POP DX
	CALL Window

	MOV AH, [ColCur]  ; Set color
	CALL Color
	DW _MOV_CL_AH
Col10:	DW _MOV_CH_CL
	PUSH CX
	CALL GetMous
	POP CX
	JNZ Col11
	MOV AL, 1
	CALL Input
	CMP AH, 0FCh
	JE Col11
	MOV SI, ColSt_T
	CALL Case
	JMP Col10
Col11:	PUSH CX  ; Mouse support
	CALL GetMous
	CALL ClrKbd
	TEST AL, 4
	JZ Col13
	MOV AL, 'x'
	CALL TypMous
Col12:	CALL GetMous
	CALL ClrKbd
	TEST AL, 4
	JNZ Col12
	PUSH AX
	MOV AL, 0
	CALL TypMous
	POP AX
	TEST AL, 3
	JZ Col18
Col13:	TEST AL, 2
	JZ Col15
	MOV AL, '๛'
	CALL TypMous
Col14:	CALL GetMous
	CALL ClrKbd
	TEST AL, 2
	JNZ Col14
	PUSH AX
	MOV AL, 0
	CALL TypMous
	POP AX
	TEST AL, 5
	JNZ Col15
	POP CX
	JMP Col50
Col15:	TEST AL, 1
	JZ Col16
	PUSH DX
	PUSH BX
	MOV BX, 43Dh
	MOV DX, 1010h
	CALL InWind
	POP BX
	POP DX
	JNC Col19
Col16:	POP CX
Col17:	JMP Col10
Col18:	POP CX
	JMP Col55
Col19:	DW _MOV_AX_CX
	POP CX
	SUB AX, 43Dh
	MOV CL, 4
	SHL AH, CL
	DW _OR_AL_AH
	DW _MOV_CL_AL
	JMP Col30

Col20:	TEST CL, 0Fh  ; Left
	JZ Col25
	DEC CL
	JMP Col30
Col21:	INC CL  ; Right
	TEST CL, 0Fh
	JNZ Col30
	SUB CL, 10h
	JMP Col30
Col22:	SUB CL, 10h  ; Up
	JMP Col30
Col23:	ADD CL, 10h  ; Down
	JMP Col30
Col24:	AND CL, 0F0h  ; Home
	JMP Col30
Col25:	OR CL, 0Fh  ; End
	JMP Col30
Col26:	AND CL, 0Fh  ; PgUp
	JMP Col30
Col27:	OR CL, 0F0h  ; PgDn
	JMP Col30
Col28:	MOV AH, [ColCur]  ; Default
	CALL ColAddr
	SUB DI, ColTab
	MOV CL, [DI+Palets]
Col30:	DW _CMP_CL_CH  ; Change color
	JE Col17
	DW _MOV_AL_CL
	CALL F07_75
	PUSH DX
	PUSH CX
	PUSH BX
	DW _MOV_CH_CL
	DW _MOV_SI_CX
	MOV BX, [ColCur]
	MOV BL, [BX+ColPage]
	MOV BH, 0
	DEC BX
	DW _ADD_BX_BX
	DW _ADD_BX_BX
	MOV BX, [BX+PagTab+2]
	MOV DI, ScrBuf
	MOV DX, 0FF00h
	MOV CX, 25
Col31:	PUSH DI
	PUSH DX
	PUSH CX
	MOV DL, 0
Col32:	MOV AX, [BX]
	INC BX
	CMP AL, 0
	JZ Col38
	INC BX
	DW _MOV_CL_AL
	MOV CH, 0
	DW _MOV_DH_AH
	CMP BYTE [ColCur], ShadFl
	JNE Col33
	CMP AH, 0FFh
	JE Col34
	TEST AH, 40h
	JZ Col34
	DW _MOV_AX_SI
	DW _MOV_AL_DH
	AND AL, 3Fh
	DW _XCHG_AL_AH
	CALL Color
	DW _XCHG_AL_AH
	JMP Col36
Col33:	AND AH, 3Fh
	CMP AH, [ColCur]
	JE Col35
Col34:	DW _ADD_DI_CX
	DW _ADD_DI_CX
	JMP Col32
Col35:	DW _MOV_AX_SI
	DW _MOV_AL_DH
	TEST AL, 40h
	PUSHF
	AND AL, 80h
	DW _OR_AL_AH
	POPF
	JZ Col37
	MOV AH, ShadFl
	CALL Color
Col36:	CALL ShadCol
Col37:	CALL MvsColr
	MOV DL, 1
	JMP Col32
Col38:	DW _OR_DL_DL
	POP CX
	POP DX
	POP DI
	JZ Col39
	DW _MOV_DL_CL
	CMP DH, 0FFh
	JNE Col39
	DW _MOV_DH_CL
Col39:	ADD DI, 2*80
	LOOP Col31
	CMP DH, 0FFh
	JE Col40
	MOV BX, 1900h
	DW _SUB_BH_DH
	DW _SUB_DH_DL
	INC DH
	MOV DL, 58
	CALL Window
Col40:	POP BX
	POP CX
	POP DX
	JMP Col10
Col50:	MOV AH, [ColCur]  ; Enter
	CALL ColAddr
	MOV [DI], CL
Col55:	MOV AH, [ColCur]  ; Esc
	CALL Color
	DW _MOV_AL_AH
	CALL F07_75
	POP SI
	CALL ResWin
	CALL Window
	POP AX
	MOV [ColTyp], AL
	POP AX
	MOV [Clock], AL
	MOV [KeyBar], AH
	POP BX
	POP DX
	JMP F07_20

F08_00:	MOV BP, Deflt_B
	CALL Dialog
	JNZ F08_01
	CALL Default_
F08_01:	JMP Main00

F09_00:	MOV SI, Inf05_S+4  ; Case table
	MOV DI, Inf06_S+7
	PUSH SI
	CALL F09_10
	POP SI
	MOV DI, Inf07_S+7
	CALL F09_20
	MOV SI, Inf09_S+7
	MOV DI, Inf10_S+7
	PUSH SI
	CALL F09_10
	POP SI
	MOV DI, Inf11_S+7
	CALL F09_20
	MOV AH, [Country+CNTRY.TimeSep]  ; Time format
	MOV AL, '9'
	MOV BX, (('0'*256)&0FF00H)+('0'&0FFH)  ; !!
	MOV CL, 'p'
	CMP BYTE [Country+CNTRY.TimeFmt], 0
	JZ F09_01
	DW _MOV_BL_AH
	MOV AX, '21'
	MOV CL, '0'
F09_01:	MOV DI, Inf02_S+6
	STOSW
	DW _MOV_AX_BX
	STOSW
	DW _MOV_AL_CL
	STOSB
	MOV AH, [Country+CNTRY.DateSep]  ; Date format
	MOV AL, 'M'
	MOV BX, (('Y'*256)&0FF00H)+('D'&0FFH)  ; !!
	CMP WORD [Country+CNTRY.DateFmt], 1
	JB F09_02
	DW _XCHG_BL_AL
	JE F09_02
	DW _XCHG_BH_AL
F09_02:	MOV DI, Inf02_S+22
	STOSB
	STOSW
	DW _MOV_AL_BL
	STOSB
	STOSW
	DW _MOV_AL_BH
	STOSB
	STOSB
	MOV AH, [Country+CNTRY.Sep1000]  ; Numbers format
	MOV DI, Inf02_S+39
	DW _OR_AH_AH
	JNE F09_03
	INC DI
F09_03:	MOV AL, '1'
	STOSB
	MOV CX, 3
	MOV AL, '0'
F09_04:	DW _XCHG_AL_AH
	STOSW
	DW _XCHG_AL_AH
	STOSB
	STOSB
	LOOP F09_04
	MOV BP, Info_B
	CALL Dialog
	JMP Main00

;GLOBAL F09_10
F09_10:  ; PROC NEAR
	MOV CX, 40
F09_11:	LODSB
	CALL UpCase
	STOSB
	LOOP F09_11
	RET
;F09_10 ENDP

;GLOBAL F09_20
F09_20:  ; PROC NEAR
	MOV CX, 40
F09_21:	LODSB
	CALL LowCase
	STOSB
	LOOP F09_21
	RET
;F09_20 ENDP

Exit:	MOV SI, SrcIni  ; Compare VC.INI with source
	MOV DI, ColTab
	MOV CX, CmnIni
	REPE CMPSB
	MOV BP, SvSt_B
	JE Exit1
	CALL Dialog
	JNZ Exit1
	DW _XOR_BP_BP
Exit1:	PUSH DS  ; Restore vector 1Bh
	LDS DX, [BrkVct]
	MOV AX, 251Bh
	INT 21h
	POP DS
	MOV SI, UserScr  ; Restore screen
	MOV DI, ScrBuf
	MOV DH, [Lines]
	MOV DL, 80
	DW _MOV_AL_DL
	MUL DH
	DW _MOV_CX_AX
	REP MOVSW
	DW _XOR_BX_BX
	CALL Window
	MOV AL, 0  ; Hide mouse
	CALL CurMous
	MOV CX, [CurType]  ; Restore cursor
	MOV AH, 1
	INT 10h
	MOV AH, [DosLin]
	MOV AL, 0
	CALL Cursor
	MOV DL, [BreakFl]  ; Restore BREAK status
	MOV AX, 3301h
	INT 21h
	DW _OR_BP_BP
	JZ Exit2
	JMP Exit7

Exit2:	MOV SI, IniData  ; Save VC.INI
	DW _MOV_DI_SI
	MOV CX, 3
	MOV AL, 'V'
	REP STOSB
	DW _XOR_BX_BX
	MOV CX, IniLen-2
	MOV AH, 0
Exit3:	LODSB
	DW _ADD_BX_AX
	LOOP Exit3
	MOV [SI], BX

	MOV DX, NcPath  ; Open VC.INI
	MOV AX, 4300h
	INT 21h
	JNC Exit4
	CMP AX, STRICT WORD 2
	JNE Exit5
	DW _XOR_AX_AX
Exit4:	OR CL, 20h
	MOV AH, 3Ch
	INT 21h
	JC Exit5
	DW _MOV_BX_AX
	MOV CX, IniLen
	MOV DX, IniData
	MOV AH, 40h
	INT 21h
	PUSHF
	PUSH AX
	MOV AH, 3Eh
	INT 21h
	POP BX
	POP DX
	JC Exit5
	PUSH DX
	POPF
	JC Exit5
	DW _CMP_BX_CX
	JE Exit6
Exit5:	MOV DX, StErr_S
	MOV AH, 9
	INT 21h

Exit6:	MOV CX, 'CV'  ; Save in resident VC
	MOV DX, 'MO'
	MOV AX, 2B02h
	INT 21h
	CMP AX, STRICT WORD VcApiVr*100h
	JNE Exit7
	DW _MOV_DI_BX
	SUB BX, ColTab
	MOV AL, [ES:BX+Active]
	MOV [Active], AL
	MOV AL, [ES:BX+Ctrl_O]
	MOV [Ctrl_O], AL
	MOV AL, [ES:BX+ChkTSR]
	MOV [ChkTSR], AL
	MOV AL, [ES:BX+LoadFl]
	XCHG AL, [LoadFl]
	MOV [ES:BX+LoadRes], AL
	MOV SI, ColTab
	MOV CX, CmnIni
	REP MOVSB

Exit7:	MOV AX, 4C00h  ; Exit
	INT 21h

CtrlC:	IRET

;--------------------- Default init --------------------
;GLOBAL Default_
Default_:  ; PROC NEAR
	MOV SI, Palets
	MOV DI, ColTab
	MOV CX, CmnIni
	REP MOVSB
	MOV SI, DefWCB
	MOV DI, WCB1
	MOV CX, WCBdef_size
	PUSH DI
	PUSH CX
	REP MOVSB
	MOV AH, 19h
	INT 21h
	ADD [WCB1+WCBdef.WinPath], AL
	POP CX
	POP SI
	MOV DI, WCB2
	REP MOVSB
	MOV [WCB1+WCBdef.Visible], CL
	RET
;Default_ ENDP

; --- include vcsthlp.inc

;-------------------------------------------------------
;		Version :	09.05.95
;-------------------------------------------------------

BegHlp EQU 55  ; First topic in help
NumHlp EQU 7  ; Number of entries

;GLOBAL RdHelp
RdHelp:  ; PROC NEAR
	MOV SI, Help_F  ; Open file
	MOV CX, 13
	REP MOVSB
	MOV AX, 3D40h
	INT 21h
	JC RdHlp2
	DW _MOV_BX_AX
	DW _XOR_CX_CX  ; Check header
	MOV DX, 8
	CALL SeekDsk
	JC RdHlp1
	MOV CX, 13
	MOV DX, HelpBuf+16
	CALL ReadDsk
	JC RdHlp1
	DW _MOV_DI_DX
	MOV SI, HlpHead
	REPE CMPSB
	JNE RdHlp1
	DW _XOR_CX_CX  ; Read pointer to index
	MOV DX, 194h
	CALL SeekDsk
	JC RdHlp1
	MOV CX, 4
	MOV DX, HelpBuf+HlpData.HlpOffs
	CALL ReadDsk
	JC RdHlp1
	CALL DeCode
	MOV DX, [HelpBuf+HlpData.HlpOffs+0]  ; Read index header
	MOV CX, [HelpBuf+HlpData.HlpOffs+2]
	CALL SeekDsk
	JC RdHlp1
	MOV CX, HlpData_size
	MOV DX, HelpBuf
	CALL ReadDsk
	JC RdHlp1
	CALL DeCode
	MOV CX, [HelpBuf+HlpData.HlpSize]  ; Read index
	MOV AX, 0FEE0h
	SUB AX, HelpBuf
	DW _CMP_AX_CX
	JNC RdHlp3
RdHlp1:	MOV AH, 3Eh
	INT 21h
RdHlp2:	MOV DX, HlpEr_S
	MOV AH, 9
	INT 21h
	JMP RdHlp5
RdHlp3:	MOV DX, HelpBuf+HlpData_size
	CALL ReadDsk
	JC RdHlp1
	CALL DeCode
	CMP WORD [HelpBuf+HlpData.HlpMode], 0
	JNE RdHlp1
	MOV DI, [HelpBuf+HlpData.HlpLins]  ; Read pages information
	SUB DI, BegHlp-1
	JBE RdHlp1
	MOV SI, 6*(BegHlp-1)
	MOV DX, [SI+HelpBuf+HlpData_size+2+0]
	MOV CX, [SI+HelpBuf+HlpData_size+2+2]
	CALL SeekDsk
	JC RdHlp1
	MOV DX, HelpBuf+2
	MOV CX, 0FEE0h
	DW _SUB_CX_DX
	CMP DI, NumHlp
	JBE RdHlp4
	MOV SI, 6*(BegHlp-1+NumHlp)
	MOV AX, [SI+HelpBuf+HlpData_size+2+0]
	MOV DI, [SI+HelpBuf+HlpData_size+2+2]
	MOV SI, 6*(BegHlp-1)
	SUB AX, [SI+HelpBuf+HlpData_size+2+0]
	SBB DI, [SI+HelpBuf+HlpData_size+2+2]
	JNE RdHlp4
	DW _CMP_CX_AX
	JBE RdHlp4
	DW _MOV_CX_AX
RdHlp4:	MOV AH, 3Fh
	INT 21h
	JC RdHlp1
	MOV [HelpBuf], AX
	CALL DeCode
	MOV AH, 3Eh
	INT 21h
	JC RdHlp2
RdHlp5:	RET
;RdHelp ENDP

;Help	PROC	NEAR
;GLOBAL Help
Help:
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	PUSH ES
	POP DS
	MOV AH, 0Fh
	INT 10h
	MOV AH, 3
	INT 10h
	PUSH DX
	CALL HidCur
	MOV AL, [HlpPage]  ; Help page offset
	MOV AH, 0
	PUSH AX
	CMP AL, 0FFh
	JE Help03
	DW _MOV_CX_AX
	MOV SI, HelpBuf
	LODSW
	DW _ADD_AX_SI
	DW _MOV_DX_AX
	DW _MOV_AX_SI
Help01:	DW _MOV_SI_AX
	ADD AX, STRICT WORD HlpData_size
	JC Help02
	DW _CMP_AX_DX
	JA Help02
	ADD AX, [SI+HlpData.HlpSize]
	JC Help02
	DW _CMP_AX_DX
	JA Help02
	LOOP Help01
	CMP WORD [SI+HlpData.HlpMode], 0
	JNZ Help04
Help02:	MOV BP, HlpEr_B
	CALL Dialog
Help03:	JMP Help41
Help04:	DW _MOV_BP_SI  ; Output window
	MOV BX, 204h
	MOV DH, [Lines]
	SUB DH, 3
	MOV DL, 74
	MOV SI, BoxBuf
	CALL SavWin
	PUSH SI
	MOV AH, Help_C
	CALL Color
	CALL MinBox
	PUSH DX
	PUSH BX
	CALL BasAdr
	PUSH DI
	ADD DI, 2*(80+33)
	MOV SI, Help_S
	MOV CX, 6
	CALL MvsBwc
	DW _ADD_BH_DH
	SUB BH, 5
	CALL BasAdr
	PUSH DI
	ADD DI, 2*(80+33)
	MOV SI, Ok_S
	MOV CX, 6
	CALL MvsBwc
	POP DI
	MOV CX, 3
	MOV DX, 64
	MOV AL, 'ฤ'
	MOV BX, (('ว'*256)&0FF00H)+('ถ'&0FFH)  ; !!
	CALL BoxLine
	POP DI
	ADD DI, 2*3*80
	CALL BoxLine
	POP BX
	POP DX
	PUSH BX
	LEA SI, [BP+HlpData_size]
	ADD BX, 205h
	CALL HlpLine
	POP BX
	CALL Window
	DW _XOR_AX_AX  ; Init vars
	MOV [WinMous], AL
	MOV [MousEnt], AL
	DEC AX
	MOV [HlpPage], AL
	MOV [MousTim+2], AX
	MOV WORD [DS:BP+HlpData.HlpFrst], 0FFF0h
	DW _XOR_DI_DI

Help10:	DW _MOV_AX_DI  ; Check first line
	XCHG DI, [DS:BP+HlpData.HlpFrst]
	DW _SUB_AX_DI
	JE Help20
	PUSH AX  ; Output lines
	PUSH BX
	MOV CX, [DS:BP+HlpData.HlpFrst]
	INC CX
	LEA DI, [BP+HlpData_size]
	MOV AL, 0
Help11:	PUSH CX
	MOV CH, 0FFh
	REPNE SCASB
	POP CX
	LOOP Help11
	DW _MOV_SI_DI
	DW _MOV_CL_DH
	SUB CL, 9
	ADD BX, 405h
Help12:	DW _MOV_DI_SI
	DW _SUB_DI_BP
	SUB DI, HlpData_size
	CMP DI, [DS:BP+HlpData.HlpSize]
	JB Help13
	DEC SI
Help13:	CALL HlpLine
	INC BH
	LOOP Help12
	POP BX
	POP CX
	PUSH DX  ; Output screen
	PUSH BX
	MOV AL, [Lines]
	SUB AL, 12
	ADD BX, 405h
	DW _MOV_DH_AL
	DEC AX
	MOV AH, 6
	CMP CX, 1
	JE Help14
	CMP CX, -1
	JNE Help15
	MOV AX, 700h
Help14:	DW _MOV_CX_BX
	MOV DL, 61
	DEC DH
	DW _ADD_DX_CX
	PUSH AX
	MOV AH, Help_C
	CALL Color
	DW _MOV_BH_AH
	POP AX
	PUSH AX
	MOV AL, 1
	CALL Int10m
	POP AX
	DW _MOV_BX_CX
	DW _ADD_BH_AL
	MOV DH, 1
Help15:	MOV DL, 62
	CALL Window
	POP BX
	POP DX

Help20:	CALL GetMous  ; Input
	JNZ Help22
	MOV BYTE [WinMous], 0
	MOV BYTE [MousEnt], 0
	PUSH BP
	PUSH DX
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 4
	ADD BL, 13
	MOV DX, 130h
	MOV BP, HlpMn_P
	MOV SI, HlpMn_D
	MOV CL, 0
	MOV AL, 2
	CALL MinMnu
	POP BX
	POP DX
	POP BP
	CMP AH, 0FCh
	JE Help21
	MOV DI, [DS:BP+HlpData.HlpFrst]
	MOV SI, Help_T
	CALL Case
	JMP Help20

Help21:	CALL GetMous  ; Mouse support
Help22:	CALL ClrKbd
	DW _MOV_SI_CX
	TEST AL, 4
	JZ Help24
	MOV AL, 'x'
	CALL TypMous
Help23:	CALL GetMous
	CALL ClrKbd
	TEST AL, 4
	JNZ Help23
	PUSH AX
	MOV AL, 0
	CALL TypMous
	POP AX
	TEST AL, 3
	JZ Help25
Help24:	PUSH DX
	PUSH BX
	ADD BX, 404h
	SUB DX, 90Ah
	CALL InWind
	POP BX
	POP DX
	JNC Help26
	CMP BYTE [WinMous], 0
	JNZ Help26
	TEST AL, 1
	JZ Help27
	CALL GetMous
	JNZ Help22
	DW _MOV_CX_SI
	PUSH DX
	SUB DX, 102h
	CALL InWind
	POP DX
	JNC Help27
Help25:	JMP Help40
Help26:	OR BYTE [WinMous], 1
	MOV DI, [DS:BP+HlpData.HlpFrst]
	DW _MOV_AL_DH
	SUB AL, 9
	CBW
	PUSH CX
	MOV CL, 3
	DIV CL
	POP CX
	DW _MOV_AH_BH
	ADD AH, 4
	DW _ADD_AH_AL
	DW _CMP_CH_AH
	JB Help30
	DW _MOV_AH_BH
	DW _ADD_AH_DH
	SUB AH, 5
	DW _SUB_AH_AL
	DW _CMP_CH_AH
	JAE Help32
Help27:	JMP Help20

Help30:	DW _OR_DI_DI  ; Up
	JE Help31
	DEC DI
Help31:	JMP Help10

Help32:	MOV AL, [Lines]  ; Down
	SUB AL, 11
	CBW
	DW _ADD_AX_DI
	CMP AX, [DS:BP+HlpData.HlpLins]
	JAE Help31
	INC DI
	JMP Help10

Help33:	MOV DI, [DS:BP+HlpData.HlpLins]  ; End
	MOV AL, [Lines]
	SUB AL, 11
Help34:	CBW
	DW _SUB_DI_AX
	JAE Help31

Help35:	DW _XOR_DI_DI  ; Home
	JMP Help10

Help36:	DW _OR_DI_DI  ; PgUp
	JE Help31
	MOV AL, [Lines]
	SUB AL, 13
	JMP Help34

Help37:	MOV AL, [Lines]  ; PgDn
	SUB AL, 12
	CBW
	MOV SI, [DS:BP+HlpData.HlpLins]
	DEC SI
	DW _SUB_SI_AX
	JB Help31
	DW _CMP_DI_SI
	JAE Help31
	DEC AX
	DW _ADD_DI_AX
	DW _CMP_DI_SI
	JBE Help31
	DW _MOV_DI_SI
	JMP Help10

Help40:	POP SI  ; Esc
	CALL ResWin
	CALL Window

Help41:	POP AX  ; Exit
	MOV [HlpPage], AL
	POP AX
	CALL Cursor
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;Help	ENDP

;GLOBAL HlpLine
HlpLine:  ; PROC NEAR
	PUSH BP
	PUSH DX
	PUSH AX
	CALL BasAdr
	MOV BP, Help_P
	SUB DL, 12
	PUSH DI
	PUSH CX
	DW _MOV_CL_DL
	MOV CH, 0
	MOV AH, [CS:BP]
	CALL Color
	MOV AL, ' '
	REP STOSW
	POP CX
	POP DI
	DW _MOV_AL_DL
	MOV BYTE [ES:TmpErr+1], 0
	MOV BYTE [ES:TmpErr+101], 0
	MOV DX, Empty_S
	CALL NgLine
	POP AX
	POP DX
	POP BP
	RET
;HlpLine ENDP

;GLOBAL SeekDsk
SeekDsk:  ; PROC NEAR
	PUSH SI
	DW _MOV_SI_DX
	MOV AX, 4200h
	INT 21h
	JC SkDsk1
	DW _XOR_SI_AX
	DW _XOR_DX_CX
	DW _OR_SI_DX
	JE SkDsk1
	STC
SkDsk1:	POP SI
	RET
;SeekDsk ENDP

;GLOBAL ReadDsk
ReadDsk:  ; PROC NEAR
	MOV AH, 3Fh
	INT 21h
	JC RdDsk1
	DW _CMP_AX_CX
	JE RdDsk1
	STC
RdDsk1:	RET
;ReadDsk ENDP

;GLOBAL DeCode
DeCode:  ; PROC NEAR
	PUSH SI
	PUSH CX
	DW _MOV_SI_DX
DeCod1:	XOR BYTE [SI], 1Ah
	INC SI
	LOOP DeCod1
	POP CX
	POP SI
	RET
;DeCode ENDP

; --- include vcstsub.inc

;--------------------- Subroutines ---------------------
;		Version :	17.09.1999
;-------------------------------------------------------

;----------------------- Timer -------------------------
;GLOBAL Timer
Timer:  ; PROC NEAR
	PUSH DS
	DW _XOR_CX_CX
	MOV DS, CX
	CLI
	MOV DX, [46Ch+0]
	MOV CX, [46Ch+2]
	STI
	POP DS
	RET
;Timer ENDP

;----------------- Clear keyboard buffer ---------------
;GLOBAL ClrKbd
ClrKbd:  ; PROC NEAR
	PUSH AX
	CMP BYTE [ES:ClrBuf], 0
	JZ ClrKb3
	JMP ClrKb2
ClrKb1:	MOV AH, 0
	INT 16h
ClrKb2:	MOV AH, 1
	INT 16h
	JNZ ClrKb1
ClrKb3:	POP AX
	RET
;ClrKbd ENDP

;----------------------- Go to CASE --------------------
;			CS:SI - address of case table
;			   AX - key code
;GLOBAL Case
Case:  ; PROC NEAR
	PUSH SI
	PUSH CX
	DW _OR_AH_AH
	JE Case3
Case1:	MOV CX, [CS:SI]
	ADD SI, 4
	JCXZ Case3
	DW _CMP_AL_CL
	JNE Case1
	DW _OR_CH_CH
	JE Case2
	DW _CMP_AH_CH
	JNE Case1
Case2:	POP CX
	ADD SP, 4
	JMP [CS:SI-2]
Case3:	POP CX
	POP SI
	RET
;Case ENDP

;----------------------- Set cursor --------------------
;			AL,AH - x, y
;GLOBAL Cursor
Cursor:  ; PROC NEAR
	PUSH DX
	PUSH BX
	PUSH AX
	DW _MOV_DX_AX
	MOV AH, 0Fh
	INT 10h
	MOV AH, 2
	INT 10h
	POP AX
	POP BX
	POP DX
	RET
;Cursor ENDP

;-------------- Get cursor size & set it ---------------
;	Return :	CX - cursor size
;GLOBAL ChgCur
ChgCur:  ; PROC NEAR
	PUSH BP
	PUSH DX
	PUSH BX
	MOV BH, 0
	MOV AH, 3
	INT 10h
	PUSH CX
	MOV CX, 0607h
	CMP BYTE [ES:ScrMod], 7
	JNE ChCur1
	MOV CX, 0B0Ch
ChCur1:	CMP BYTE [ES:ColTyp], 2
	JNE ChCur2
	MOV CH, 0
ChCur2:	MOV AH, 1
	INT 10h
	POP CX
	POP BX
	POP DX
	POP BP
	RET
;ChgCur ENDP

;------------------- Make hidden cursor ----------------
;GLOBAL HidCur
HidCur:  ; PROC NEAR
	PUSH AX
	MOV AX, 7F00h
	CALL Cursor
	POP AX
	RET
;HidCur ENDP

;--------------------- Beep sound ----------------------
;GLOBAL Beep
Beep:  ; PROC NEAR
	CMP BYTE [ES:ErrSnd], 0
	JE Beep1
	PUSH BP
	PUSH AX
	MOV AX, 0E07h
	INT 10h
	POP AX
	POP BP
Beep1:	RET
;Beep ENDP

;------------------------ Snow -------------------------
;GLOBAL SetSnow
SetSnow:  ; PROC NEAR
	MOV AH, 1
	CMP BYTE [TopView], 0
	JNZ SetSn3
	CMP BYTE [ScrMod], 7
	JE SetSn3
	CMP BYTE [SnowMod], 1
	JE SetSn3
	MOV DX, 03DAh
	MOV BX, 7FFFh
	JB SetSn1
	CMP BYTE [TstEGA], 0
	JNE SetSn3
SetSn1:	STI
	DEC BX
	JE SetSn3
	MOV CX, 7  ; Const2_1 ???
	CLI
SetSn2:	IN AL,DX
	TEST AL, 1
	JZ SetSn1
	LOOP SetSn2
	MOV AH, 0
SetSn3:	STI
	MOV [Snow], AH
	RET
;SetSnow ENDP

;--------------- Set type of mouse sursor --------------
;			   AL - cursor
;GLOBAL TypMous
TypMous:  ; PROC NEAR
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV CX, 0FFFFh
	MOV DX, 7700h
	CMP AL, 0
	JE TypMo1
	MOV CL, 0
	DW _MOV_DL_AL
TypMo1:	DW _XOR_BX_BX
	MOV AX, 0Ah
	INT 33h
	POP AX
	POP BX
	POP CX
	POP DX
	RET
;TypMous ENDP

;------------------- Set mouse cursor ------------------
;			   AL - set/reset
;GLOBAL CurMous
CurMous:  ; PROC NEAR
	CMP BYTE [ES:Mouse], 0
	JE CurMo1
	PUSH AX
	CMP AL, 1
	MOV AX, 1
	ADC AL, 0
	INT 33h
	POP AX
CurMo1:	RET
;CurMous ENDP

;------------------- Get mouse cursor ------------------
;	Return :	CH,CL - mouse cursor
;			   AX - mouse buttons
;GLOBAL GetMous
GetMous:  ; PROC NEAR
	PUSH DX
	PUSH BX
	DW _XOR_AX_AX
	CMP BYTE [ES:Mouse], 0
	STC
	JZ GetMo1
	MOV AX, 3
	INT 33h
	DW _MOV_AX_CX
	MOV CL, 3
	SHR AX, CL
	SHR DX, CL
	DW _MOV_CL_AL
	DW _MOV_CH_DL
	DW _MOV_AX_BX
	CMP BYTE [ES:LftMous], 0
	JE GetMo1
	DW _MOV_BH_BL
	SHR BL, 1
	SHL BH, 1
	AND BX, 201h
	AND AL, 4
	DW _OR_AL_BL
	DW _OR_AL_BH
GetMo1:	AND AX, STRICT WORD 7
	POP BX
	POP DX
	RET
;GetMous ENDP

;----------------- Mouse double click ------------------
;			BH,BL - base of selected point
;			DH,DL - size of selected point
;			   SI - cursor
;	Return :	   CY - continue
;			   NZ - action
;GLOBAL DoublMo
DoublMo:  ; PROC NEAR
	PUSH DX
	CMP BYTE [ES:MousEnt], 0
	JNE DblMo3
	MOV BYTE [ES:MousEnt], 1
	MOV AH, 2Ch
	INT 21h
	CMP WORD [ES:MousTim+2], 0FFFFh
	JE DblMo1
	CMP SI, [ES:MousPos]
	JE DblMo4
DblMo1:	ADD DL, MoDelay
	CMP DL, 100
	JB DblMo2
	INC DH
	CMP DH, 60
	JB DblMo2
	INC CL
	CMP CL, 60
	JB DblMo2
	INC CH
DblMo2:	MOV [ES:MousTim+0], DX
	MOV [ES:MousTim+2], CX
	MOV [ES:MousPos], SI
DblMo3:	POP DX
	STC
	RET
DblMo4:	CMP CX, [ES:MousTim+2]
	JA DblMo1
	JB DblMo5
	CMP DX, [ES:MousTim+0]
	JA DblMo1
DblMo5:	POP DX
	MOV CH, 0
DblMo6:	PUSH CX
	CALL GetMous
	CALL InWind
	POP CX
	PUSH AX
	MOV AL, 0
	JC DblMo7
	MOV AL, '๛'
DblMo7:	DW _CMP_AL_CH
	JE DblMo8
	DW _MOV_CH_AL
	CALL TypMous
DblMo8:	POP AX
	TEST AL, 7
	JNZ DblMo6
	DW _OR_CH_CH
	RET
;DoublMo ENDP

;--------------- Check cursor in window ----------------
;			CH,CL - cursor
;			BH,BL - begin of window
;			DH,DL - size of window
;	Return :	CY=0  - cursor inside the window
;GLOBAL InWind
InWind:  ; PROC NEAR
	PUSH DX
	PUSH CX
	DW _SUB_CH_BH
	JB InWin1
	DW _SUB_CL_BL
	JB InWin1
	DEC DH
	DW _CMP_DH_CH
	JB InWin1
	DEC DL
	DW _CMP_DL_CL
InWin1:	POP CX
	POP DX
	RET
;InWind ENDP

;------------------ INT 10h with mouse -----------------
;GLOBAL Int10m
Int10m:  ; PROC NEAR
	PUSH BP
	PUSH AX
	MOV AL, 0
	CALL CurMous
	POP AX
	INT 10h
	PUSH AX
	MOV AL, 1
	CALL CurMous
	POP AX
	POP BP
	RET
;Int10m ENDP

;------------- Convert coordinars to address -----------
;			BH,BL - coordinats
;	Return :	   DI - address
;GLOBAL BasAdr
BasAdr:  ; PROC NEAR
	PUSH BX
	PUSH AX
	MOV AL, 80
	MUL BH
	MOV BH, 0
	DW _ADD_AX_BX
	DW _ADD_AX_AX
	ADD AX, STRICT WORD ScrBuf
	DW _MOV_DI_AX
	POP AX
	POP BX
	RET
;BasAdr ENDP

;--------------- Shift windows in EGA lines ------------
;GLOBAL SftEGA
SftEGA:  ; PROC NEAR
	PUSH AX
	MOV AL, [ES:Lines]
	SUB AL, 25
	JBE SfEGA1
	SHR AL, 1
	DW _ADD_BH_AL
SfEGA1:	POP AX
	RET
;SftEGA ENDP

;---------------------- Save window --------------------
;			BH,BL - begin
;			DH,DL - size
;			   SI - address of buffer
;GLOBAL SavWin
SavWin:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	CLD
	CALL BasAdr
	DW _XCHG_SI_DI
	DW _MOV_CL_DH
	MOV CH, 0
	MOV DH, 0
	PUSH ES
	POP DS
SavWn1:	PUSH CX
	PUSH SI
	DW _MOV_CX_DX
	REP MOVSW
	POP SI
	POP CX
	ADD SI, 2*80
	LOOP SavWn1
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;SavWin ENDP

;--------------------- Restore window ------------------
;			BH,BL - begin
;			DH,DL - size
;			   SI - address of buffer
;GLOBAL ResWin
ResWin:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	CLD
	CALL BasAdr
	DW _MOV_CL_DH
	MOV CH, 0
	MOV DH, 0
	PUSH ES
	POP DS
ResWn1:	PUSH CX
	PUSH DI
	DW _MOV_CX_DX
	REP MOVSW
	POP DI
	POP CX
	ADD DI, 2*80
	LOOP ResWn1
	MOV BYTE [Quote], 0
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;ResWin ENDP

;--------------------- Output window -------------------
;			BH,BL - begin
;			DH,DL - size
;GLOBAL Window
Window:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	PUSH ES
	MOV AL, 0
	CALL CurMous
	PUSH ES
	POP DS
	MOV ES, [Screen+2]
	CALL BasAdr
	DW _MOV_SI_DI
	SUB DI, ScrBuf
	ADD DI, [Screen+0]
	MOV AL, [Snow]
	CMP DH, 1
	JE Wind1
	MOV BH, 0
	DW _ADD_BX_BX
	DW _SUB_SI_BX
	DW _SUB_DI_BX
	PUSH DI
	PUSH DX
	CALL MovScr
	POP AX
	MOV AL, 80
	MUL AH
	DW _MOV_CX_AX
	POP DI
	JMP Wind6
Wind1:	DW _MOV_CL_DL
	MOV CH, 0
	PUSH DI
	PUSH CX
	DW _MOV_AH_AL
	MOV DX, 03DAh
Wind2:	DW _OR_AH_AH
	JNZ Wind5
Wind3:	IN AL,DX
	TEST AL, 1
	JNZ Wind3
	CLI
Wind4:	IN AL,DX
	TEST AL, 1
	JZ Wind4
Wind5:	MOVSW
	STI
	LOOP Wind2
	POP CX
	POP DI
Wind6:	POP ES
	CMP BYTE [ES:TopView], 0
	JZ Wind7
	MOV AH, 0FFh
	INT 10h
Wind7:	MOV AL, 1
	CALL CurMous
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;Window ENDP

;------------------------ Save screen ------------------
;GLOBAL SavScr
SavScr:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV DS, [ES:Screen+2]
	MOV SI, [ES:Screen+0]
	MOV DI, ScrBuf
	MOV DH, [ES:Lines]
	MOV AL, [ES:Snow]
	CALL MovScr
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;SavScr ENDP

;-------------------- Move screen bytes ----------------
;			   DH - number of lines
;			   AL - snow
;			DS:SI => ES:DI
;GLOBAL MovScr
MovScr:  ; PROC NEAR
	CLD
	DW _MOV_BL_AL
	MOV DL, 7  ; Const1 ???
MovSc1:	DW _CMP_DH_DL
	JAE MovSc2
	DW _MOV_DL_DH
MovSc2:	MOV AX, 80
	MUL DL
	PUSH AX
	DW _OR_BL_BL
	JNZ MovSc6
	PUSH DX
	MOV DX, 03DAh
MovSc3:	IN AL,DX
	TEST AL, 1
	JNZ MovSc3
MovSc4:	STI
	MOV CX, 10  ; Const2 ???
	CLI
MovSc5:	IN AL,DX
	TEST AL, 1
	JZ MovSc4
	LOOP MovSc5
	POP DX
MovSc6:	POP CX
	REP MOVSW
	STI
	DW _SUB_DH_DL
	JNE MovSc1
	RET
;MovScr ENDP

;---------------------- Zooming box --------------------
;			BH,BL - begin
;			DH,DL - size
;			   AH - color
Diskret EQU 5
;GLOBAL MinBox
MinBox:  ; PROC NEAR
	PUSH DI
	PUSH CX
	PUSH AX
	MOV AL, 0
	MOV [ES:Quote], AL
	CMP AL, [ES:ZoomWin]
	JZ MinBx2
	PUSH AX
	MOV AH, ShadFl
	CALL ColAddr
	POP AX
	XCHG AL, [ES:DI]
	PUSH DI
	PUSH AX
	DW _XOR_DI_DI
	CALL MinBx3
	MOV CX, Diskret-1
MinBx1:	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	DW _MOV_AL_DL
	DW _MOV_AH_BL
	MOV CH, 11
	CALL MinBx5
	DW _MOV_DL_AL
	DW _MOV_BL_AH
	DW _MOV_AL_DH
	DW _MOV_AH_BH
	MOV CH, 5
	CALL MinBx5
	DW _MOV_DH_AL
	DW _MOV_BH_AH
	POP AX
	CALL ShadBox
	CALL MinBx3
	CALL Window
	POP BX
	POP CX
	POP DX
	LOOP MinBx1
	CALL MinBx3
	POP AX
	POP DI
	MOV [ES:DI], AL
MinBx2:	CALL ShadBox
	POP AX
	POP CX
	POP DI
	RET
;MinBox ENDP

;GLOBAL MinBx3
MinBx3:  ; PROC NEAR
	PUSH DX
	PUSH CX
	PUSH AX
MinBx4:	STI
	CALL Timer
	DW _CMP_DX_DI
	JE MinBx4
	DW _MOV_DI_DX
	POP AX
	POP CX
	POP DX
	RET
;MinBx3 ENDP

;GLOBAL MinBx5
MinBx5:  ; PROC NEAR
	PUSH AX
	DW _SUB_AL_CH
	SHR AL, 1
	MUL CL
	MOV CH, Diskret-1
	DIV CH
	DW _MOV_CH_AL
	POP AX
	DW _ADD_AH_CH
	DW _SUB_AL_CH
	DW _SUB_AL_CH
	RET
;MinBx5 ENDP

;-------------------- Box with shadow ------------------
;			BH,BL - begin
;			DH,DL - size
;			   AH - color
;GLOBAL ShadBox
ShadBox:  ; PROC NEAR
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	CALL BasAdr
	DW _MOV_CL_DH
	MOV CH, 0
	DW _MOV_SI_CX
	SUB DL, 10
	MOV DH, 0
	MOV CL, 3
	MOV BX, ((' '*256)&0FF00H)+(' '&0FFH)  ; !!
	MOV AL, ' '
	CALL BoxLine
	MOV BX, (('ษ'*256)&0FF00H)+('ป'&0FFH)  ; !!
	MOV AL, 'อ'
	CALL ShadLin
	SUB SI, 5
	JBE ShdBx2
	MOV BX, (('บ'*256)&0FF00H)+('บ'&0FFH)  ; !!
	MOV AL, ' '
ShdBx1:	CALL ShadLin
	DEC SI
	JNE ShdBx1
ShdBx2:	MOV BX, (('ศ'*256)&0FF00H)+('ผ'&0FFH)  ; !!
	MOV AL, 'อ'
	CALL ShadLin
	MOV BX, ((' '*256)&0FF00H)+(' '&0FFH)  ; !!
	MOV AL, ' '
	CALL ShadLin
	ADD DI, 2*2
	DW _MOV_CX_DX
	ADD CL, 8
ShdBx3:	CALL Shadow
	LOOP ShdBx3
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	RET
;ShadBox ENDP

;-------------------- One line of box ------------------
;			ES:DI - screen buffer
;			   AH - color
;		ณ   วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถ   ณ
;		 ภยู|ภฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤู|ภยู
;		 CX BH         DX(AL)      BL CX
;GLOBAL ShadLin
ShadLin:  ; PROC NEAR
	PUSH DI
	CALL BoxLn0
	CALL Shadow
	CALL Shadow
	POP DI
	ADD DI, 2*80
	RET
;ShadLin ENDP

;GLOBAL BoxLine
BoxLine:  ; PROC NEAR
	PUSH DI
	CALL BoxLn0
	POP DI
	ADD DI, 2*80
	RET
;BoxLine ENDP

;GLOBAL BoxLn0
BoxLn0:  ; PROC NEAR
	PUSH CX
	PUSH AX
	PUSH CX
	PUSH AX
	JCXZ BoxLn1
	MOV AL, ' '
	REP STOSW
BoxLn1:	DW _MOV_AL_BH
	STOSW
	POP AX
	DW _MOV_CX_DX
	REP STOSW
	DW _MOV_AL_BL
	STOSW
	POP CX
	JCXZ BoxLn2
	MOV AL, ' '
	REP STOSW
BoxLn2:	POP AX
	POP CX
	RET
;BoxLn0 ENDP

;---------------------- Put window ---------------------
;			BH,BL - begin-center
;			CS:DX - address of include line
;			CS:BP - pointer:
;				DB  NormCol,RevCol,BoldCol,UndrCol
;				DB  NumLns,NumVars
;				DW  SaveBuf
;				DW  Variable
;				DB  VarMode,VarLimit
;				. . .
;				DW  Line1
;				. . .
;	Return:		BH,BL - begin
;			DH,DL - size
;			   SI - address of save buffer
;GLOBAL DialBox
DialBox:  ; PROC NEAR
	PUSH DS
	PUSH DI
	PUSH CX
	PUSH AX
	CALL HidCur
	CALL SftEGA
	PUSH BP  ; Convert variables
	MOV AL, [CS:BP+5]
	AND AX, STRICT WORD 3
	JE DiBx01
	ADD BP, 8
	MOV DI, TmpErr+1
	PUSH AX
	CALL DiBx30
	POP AX
	DEC AX
	JE DiBx01
	ADD BP, 4
	MOV DI, TmpErr+101
	CALL DiBx30
DiBx01:	POP BP
	PUSH CS  ; Calculate size of window
	POP DS
	MOV CL, [DS:BP+4]
	MOV CH, 0
	PUSH BX
	LEA BX, [BP+8]
	MOV AL, [DS:BP+5]
	AND AL, 3
	MOV AH, 4
	MUL AH
	DW _ADD_BX_AX
	PUSH BX
	DW _XOR_DI_DI
DiBx10:	MOV SI, [BX]
	INC BX
	INC BX
	DW _OR_SI_SI
	JE DiBx11
	CALL LnStr
	DW _CMP_AX_DI
	JBE DiBx11
	DW _MOV_DI_AX
DiBx11:	LOOP DiBx10
	DW _XCHG_DX_DI
	MOV DH, [DS:BP+4]
	ADD DX, 40Ch
	POP CX
	POP BX
	PUSH BX  ; Put box
	DW _MOV_AL_DL
	DEC AX
	SHR AL, 1
	DW _SUB_BL_AL
	MOV SI, [DS:BP+6]
	CALL SavWin
	MOV AH, [DS:BP]
	CALL Color
	CALL MinBox
	POP AX
	PUSH SI  ; Output lines
	PUSH BX
	DW _MOV_BX_AX
	DW _MOV_SI_CX
	MOV CL, [DS:BP+4]
	MOV CH, 0
DiBx20:	INC BH
	PUSH SI
	PUSH DI
	PUSH DX
	MOV SI, [SI]
	DW _OR_SI_SI
	JE DiBx21
	DW _MOV_DX_DI
	CALL CntLine
	JMP DiBx22
DiBx21:	CALL BasAdr
	PUSH CX
	PUSH BX
	MOV DH, 0
	DW _MOV_AX_DX
	DEC AX
	AND AX, STRICT WORD 0FFFEh
	DW _SUB_DI_AX
	SUB DL, 10
	MOV CX, 3
	MOV BX, (('ว'*256)&0FF00H)+('ถ'&0FFH)  ; !!
	MOV AL, 'ฤ'
	MOV AH, [DS:BP]
	CALL Color
	CALL BoxLine
	POP BX
	POP CX
DiBx22:	POP DX
	POP DI
	POP SI
	INC SI
	INC SI
	LOOP DiBx20
	POP BX  ; Exit
	POP SI
	POP AX
	POP CX
	POP DI
	POP DS
	RET
;DialBox ENDP

;GLOBAL DiBx30
DiBx30:  ; PROC NEAR  ; Convert variable
	MOV SI, [CS:BP]
	MOV CX, LenPath+13
	PUSH CX
	PUSH DI
	REP MOVSB
	POP SI
	POP CX
	MOV AL, [CS:BP+2]
	TEST AL, 4
	JZ DiBx31
	CALL NormStr
DiBx31:	TEST AL, 2
	JZ DiBx32
	CALL PathLin
	TEST AL, 1
	JZ DiBx32
	CALL LetLin
DiBx32:	MOV AL, [CS:BP+3]
	CBW
	CALL ShrtLin
	RET
;DiBx30 ENDP

;--------------- Calculate string length ---------------
;			DS:SI - address of line
;			CS:DX - address of include line
;	Return :	   AX - length
;GLOBAL LnStr
LnStr:  ; PROC NEAR
	PUSH SI
	PUSH DI
	PUSH BX
	DW _XOR_BX_BX
LnStr0:	LODSW
	CMP AL, 0
	JE LnStr9
	CMP AL, '^'
	JE LnStr3
	CMP AL, 0FFh
	JE LnStr2
	DEC SI
LnStr1:	INC BX
	JMP LnStr0
LnStr2:	DW _MOV_AL_AH
	AND AL, 7Fh
	DEC AX
	SHL AH, 1
	CMC
	DW _ADC_BL_AL
	JMP LnStr0
LnStr3:	DW _MOV_AL_AH
	CMP AL, '^'
	JE LnStr1
	CALL UpCase
	CMP AL, 'V'
	JE LnStr5
	CMP AL, 'W'
	JE LnStr6
	CMP AL, 'I'
	JE LnStr7
	CMP AL, 'A'
	JE LnStr4
	CMP AL, 'C'
	JNE LnStr0
	INC BX
LnStr4:	INC SI
	INC SI
	JMP LnStr0
LnStr5:	PUSH ES
	MOV DI, TmpErr+1
	JMP LnStr8
LnStr6:	PUSH ES
	MOV DI, TmpErr+101
	JMP LnStr8
LnStr7:	PUSH ES
	PUSH CS
	POP ES
	DW _MOV_DI_DX
LnStr8:	PUSH DI
	PUSH CX
	MOV CX, 80
	MOV AL, 0
	REPNE SCASB
	DW _MOV_AX_DI
	POP CX
	POP DI
	POP ES
	DW _SUB_AX_DI
	DEC AX
	DW _ADD_BL_AL
	JMP LnStr0
LnStr9:	DW _MOV_AX_BX
	POP BX
	POP DI
	POP SI
	RET
;LnStr ENDP

;-------------------- Output NG line -------------------
;			DS:SI - address of line
;			ES:DI - address of screen buffer
;			CS:DX - address of include line
;			CS:BP - address of color table
;			   AL - limit
;GLOBAL NgLine
NgLine:  ; PROC NEAR
	PUSH CX
	PUSH BX
	PUSH AX
	DW _MOV_BL_AL
	MOV AH, [CS:BP]
	MOV BH, 0
NgLn01:	CALL Color
NgLn02:	LODSB
	CMP AL, 0
	JE NgLn04
	CMP AL, '^'
	JE NgLn07
	CMP AL, 0FFh
	JE NgLn05
NgLn03:	CALL NgLn30
	JMP NgLn02
NgLn04:	POP AX
	POP BX
	POP CX
	RET
NgLn05:	LODSB
	DW _MOV_CL_AL
	TEST AL, 80h
	MOV AL, ' '
	JZ NgLn50
	LODSB
NgLn50:	AND CX, 7Fh
	JE NgLn02
NgLn06:	CALL NgLn30
	LOOP NgLn06
	JMP NgLn02
NgLn07:	LODSB
	CMP AL, '^'
	JE NgLn03
	CALL UpCase
	CMP AL, 'V'
	JNE NgLn08
	PUSH SI
	MOV SI, TmpErr+1
	JMP NgLn09
NgLn08:	CMP AL, 'W'
	JNE NgLn13
	PUSH SI
	MOV SI, TmpErr+101
NgLn09:	PUSH DS
	PUSH ES
NgLn10:	POP DS
NgLn11:	LODSB
	CMP AL, 0
	JE NgLn12
	CALL NgLn30
	JMP NgLn11
NgLn12:	POP DS
	POP SI
	JMP NgLn02
NgLn13:	CMP AL, 'I'
	JNE NgLn14
	PUSH SI
	DW _MOV_SI_DX
	PUSH DS
	PUSH CS
	JMP NgLn10
NgLn14:	MOV CL, 0
	CMP AL, 'N'
	JE NgLn15
	MOV CL, 1
	CMP AL, 'R'
	JE NgLn15
	MOV CL, 2
	CMP AL, 'B'
	JE NgLn15
	MOV CL, 3
	CMP AL, 'U'
	JNE NgLn17
NgLn15:	DW _CMP_CL_BH
	JNE NgLn16
	MOV CL, 0
NgLn16:	MOV CH, 0
	PUSH BP
	DW _ADD_BP_CX
	MOV AH, [CS:BP]
	POP BP
	DW _MOV_BH_CL
	JMP NgLn01
NgLn17:	CMP AL, 'A'
	JE NgLn18
	CMP AL, 'C'
	JNE NgLn20
NgLn18:	DW _MOV_CL_AL
	LODSB
	CALL TstHex
	DW _MOV_CH_AL
	LODSB
	JC NgLn20
	CALL TstHex
	JC NgLn20
	PUSH CX
	MOV CL, 4
	SHL CH, CL
	DW _OR_AL_CH
	POP CX
	CMP CL, 'C'
	JE NgLn19
	JMP NgLn03
NgLn19:	DW _MOV_AH_AL
	MOV BH, 0
NgLn20:	JMP NgLn02
;NgLine ENDP

;GLOBAL NgLn30
NgLn30:  ; PROC NEAR
	DW _OR_BL_BL
	JE NgLn31
	STOSW
	DEC BL
NgLn31:	RET
;NgLn30 ENDP

;--------------------- Center line ---------------------
;			BH,BL - center
;			DS:SI - address of line
;			CS:DX - address of include line
;			CS:BP - address of color table
;GLOBAL CntLine
CntLine:  ; PROC NEAR
	PUSH DI
	PUSH AX
	CALL LnStr
	CALL BasAdr
	PUSH AX
	INC AX
	AND AX, STRICT WORD 0FFFEh
	DW _SUB_DI_AX
	POP AX
	CALL NgLine
	POP AX
	POP DI
	RET
;CntLine ENDP

;------------------------ Dialog -----------------------
;			CS:DX - address of include line
;			CS:BP - pointer:
;				DW  BoxPoint, BegCenter, SecondBox
;				DB  KeyBar, Menu, HlpPage, Status
;					DB  Type
;					DB  Up, Down, Left, Right
;					DW  Begin, Point, Control
;					...
;				DB  0
;				Status:	b0 - Beep
;					b1 - ClrKbd
;					b2 - SftEGA
;					b3 - F10-Tree
;					b4 - disable DialBox
;Dialog	PROC	NEAR
;GLOBAL Dialog
Dialog:
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	MOV BYTE [ES:Quote], 0
	CALL ChgCur
	PUSH CX
	PUSH BP  ; Output box
	MOV BX, [CS:BP+BOXHD.BoxBase]
	MOV AL, [CS:BP+BOXHD.bKeyBar]
	CALL PutKey
	TEST BYTE [CS:BP+BOXHD.bFlags], 10h
	JNZ Dial04
	MOV BP, [CS:BP+BOXHD.pDiBox]
	CALL DialBox
Dial04:	POP BP
	PUSH SI  ; Init
	PUSH DX
	LEA SI, [BP+BOXHD_size]
Dial11:	PUSH SI
	PUSH BX
	DW _MOV_AH_BL
	ADD BX, [CS:SI+BOXMN.mBase]
	CALL BasAdr
	MOV AL, [CS:SI+BOXMN.mType]
	CMP AL, 1  ; InpStr
	JNE Dial15
	MOV CX, [CS:SI+BOXMN.mCtrl]
	MOV SI, [CS:SI+BOXMN.mPoint]
	MOV DI, TmpErr
	MOV AL, 64
	MUL CH
	DW _ADD_DI_AX
	MOV CH, 0
	DW _XOR_AX_AX
	STOSW
	STOSB
	PUSH DI
	PUSH CX
	REP MOVSB
	STOSB
	POP CX
	POP SI
	MOV DI, [CS:BP+BOXHD.pDiBox]
	MOV AH, [CS:DI+1]
	CALL InSt10
	JMP Dial19
Dial15:	CMP AL, 2  ; Select
	JNE Dial16
	MOV BX, [CS:SI+BOXMN.mPoint]
	MOV AL, [ES:BX]
	MOV AH, 2*80
	MUL AH
	DW _ADD_DI_AX
	MOV BYTE [ES:DI], ''
	JMP Dial19
Dial16:	CMP AL, 3  ; FlipFlop
	JNE Dial17
	MOV BX, [CS:SI+BOXMN.mPoint]
	MOV SI, [CS:SI+BOXMN.mCtrl]
	LODSB
	MOV [ES:BX], AL
	CMP AL, 0
	JZ Dial19
	MOV BYTE [ES:DI], 'x'
	JMP Dial19
Dial17:	CMP AL, 4  ; MinMnu
	JNE Dial20
	DW _SUB_BL_AH
	CMP AH, 40
	JB Dial18
	ADD BL, 40
Dial18:	CALL BasAdr
	MOV BX, [CS:SI+BOXMN.mPoint]
	MOV CL, 0
	MOV [ES:BX], CL
	MOV SI, [CS:SI+BOXMN.mCtrl]
	MOV BX, [CS:BP+BOXHD.pDiBox]
	MOV AH, [CS:BX+2]
	CALL MnMn41
Dial19:	POP BX
	POP SI
	ADD SI, BOXMN_size
	JMP Dial11
Dial20:	POP BX  ; Output window
	POP SI
	CALL Window
	MOV AL, [CS:BP+BOXHD.bHelp]
	CMP AL, 0
	JE Dial21
	MOV [ES:HlpPage], AL
Dial21:	MOV AL, [CS:BP+BOXHD.bFlags]
	TEST AL, 1
	JZ Dial22
	CALL ClrKbd
Dial22:	TEST AL, 2
	JZ Dial30
	CALL Beep
Dial30:	LEA SI, [BP+BOXHD_size]  ; Menus
Dial31:	PUSH BP
	PUSH SI
	PUSH BX
	DW _MOV_AH_BL
	ADD BX, [CS:SI+BOXMN.mBase]
	DW _MOV_DI_BP
	MOV BP, [CS:BP+BOXHD.pDiBox]
	MOV AL, [CS:SI+BOXMN.mType]
	CMP AL, 1  ; InpStr
	JNE Dial33
	MOV CX, [CS:SI+BOXMN.mCtrl]
	MOV SI, TmpErr+3
	MOV AL, 64
	MUL CH
	DW _ADD_SI_AX
	MOV AL, [CS:DI+BOXHD.bKeyBar]
	MOV CH, 0
	MOV AH, [CS:BP+1]
	MOV DI, [ES:SI-3]
	CALL InpStr
	MOV [ES:SI-3], DI
	JMP Dial37
Dial33:	CMP AL, 2  ; Select
	JNE Dial34
	MOV AL, [CS:DI+BOXHD.bKeyBar]
	MOV AH, [CS:SI+BOXMN_mSelTot]
	MOV DI, [CS:SI+BOXMN.mPoint]
	MOV CX, [ES:DI]
	CALL Select
	MOV [ES:DI], CX
	JMP Dial37
Dial34:	CMP AL, 3  ; FlipFlop
	JNE Dial35
	MOV AL, [CS:DI+BOXHD.bKeyBar]
	MOV DI, [CS:SI+BOXMN.mPoint]
	MOV CL, [ES:DI]
	CALL FlipFl
	MOV [ES:DI], CL
	JMP Dial37
Dial35:	CMP AL, 4  ; MinMnu
	JNE Dial37
	DW _SUB_BL_AH
	CMP AH, 40
	JB Dial36
	ADD BL, 40
Dial36:	MOV AL, [CS:DI+BOXHD.bKeyBar]
	OR AL, 80h
	MOV DI, [CS:SI+BOXMN.mPoint]
	MOV CL, [ES:DI]
	MOV SI, [CS:SI+BOXMN.mCtrl]
	CALL MnMn60
	CALL MinMnu
	MOV [ES:DI], CL
Dial37:	POP BX  ; Exit
	POP DI
	POP BP
	CMP AH, 0FCh
	JE Dial40
	MOV SI, Dial_T
	CALL Case
	JMP Dial39
Dial38:	ADD DI, BOXMN_size  ; Tab
	CMP BYTE [CS:DI+BOXMN.mType], 0
	JNE Dial39
	LEA DI, [BP+BOXHD_size]
Dial39:	DW _MOV_SI_DI
	JMP Dial31
Dial55:	SUB DI, BOXMN_size  ; Shift-Tab
	LEA SI, [BP+BOXHD_size]
	DW _CMP_DI_SI
	JAE Dial39
Dial56:	ADD SI, BOXMN_size
	CMP BYTE [CS:SI+BOXMN.mType], 0
	JNE Dial56
	SUB SI, BOXMN_size
	JMP Dial31
Dial40:	POP DX  ; Mouse
	PUSH DX
	DW _XOR_SI_SI
Dial41:	CALL GetMous
	JNZ Dial42
	JMP Dial52
Dial42:	PUSH SI
	MOV AH, 0
	CMP AL, 1
	JNE Dial45
	PUSH DX
	SUB DX, 102h
	CALL InWind
	POP DX
	MOV AH, 0FFh
	JC Dial46
	LEA SI, [BP+BOXHD_size]
Dial43:	MOV AL, [CS:SI+BOXMN.mType]
	CBW
	CMP AL, 0
	JE Dial46
	PUSH DX
	PUSH BX
	DW _MOV_AH_BL
	ADD BX, [CS:SI+BOXMN.mBase]
	MOV DX, [CS:SI+BOXMN.mCtrl]
	CMP AL, 1
	JE Dial44
	CMP AL, 3
	JA Dial47
	DW _MOV_DH_DL
	CALL Slct20
	CMP AL, 2
	JE Dial48
Dial44:	MOV DH, 1
	JMP Dial48
Dial45:	MOV AH, '๛'
	CMP AL, 2
	JE Dial46
	MOV AH, 'x'
Dial46:	POP SI
	DW _MOV_AL_AH
	MOV AH, 0
	DW _CMP_AX_SI
	JE Dial41
	DW _MOV_SI_AX
	CMP AL, 0FFh
	CMC
	ADC AL, 0
	CALL TypMous
	JMP Dial41
Dial47:	DW _SUB_BL_AH
	PUSH SI
	DW _MOV_SI_DX
	CALL MnMn60
	POP SI
	CMP AH, 40
	JB Dial48
	ADD BL, 40
Dial48:	CALL InWind
	POP BX
	POP DX
	JNC Dial49
	ADD SI, BOXMN_size
	JMP Dial43
Dial49:	CMP BYTE [CS:DI+BOXMN.mType], 4
	JNE Dial51
	PUSH SI
	PUSH BX
	DW _MOV_AL_BL
	ADD BX, [CS:DI+BOXMN.mBase]
	DW _SUB_BL_AL
	CMP AL, 40
	JB Dial50
	ADD BL, 40
Dial50:	MOV SI, [CS:DI+BOXMN.mPoint]
	MOV CL, [ES:SI]
	MOV SI, [CS:DI+BOXMN.mCtrl]
	DW _MOV_DI_SI
	CALL MnMn60
	MOV SI, [CS:BP+BOXHD.pDiBox]
	MOV AH, [CS:SI+0]
	MOV AL, [CS:SI+2]
	CALL MnMn40
	POP BX
	POP SI
Dial51:	POP DI
	JMP Dial31
Dial52:	MOV AL, 0
	CALL TypMous
	CMP SI, '๛'&0FFH  ; !! AND 0FFH not needed by NASM.
	JE Dial70
	CMP SI, 'x'
	JE Dial53
	CMP SI, 0FFh
	JE Dial53
	DW _MOV_SI_DI
	JMP Dial31
Dial53:	JMP Dial81
Dial60:	MOV AL, [CS:DI+BOXMN.mUp]  ; Up
	JMP Dial65
Dial61:	MOV AL, [CS:DI+BOXMN.mDown]  ; Down
	JMP Dial65
Dial62:	MOV AL, [CS:DI+BOXMN.mLeft]  ; Left
	JMP Dial65
Dial63:	MOV AL, [CS:DI+BOXMN.mRight]  ; Right
	JMP Dial65
Dial64:	MOV AL, 80h  ; Home, PgUp
Dial65:	PUSH AX
	AND AL, 3Fh
	MOV AH, BOXMN_size
	MUL AH
	LEA SI, [BP+BOXHD_size]
	DW _ADD_SI_AX
	POP AX
	CMP BYTE [CS:SI+BOXMN.mType], 2
	JNE Dial67
	TEST AL, 80h
	JZ Dial67
	TEST AL, 40h
	MOV AL, 0
	JZ Dial66
	MOV AL, [CS:SI+BOXMN_mSelTot]
	DEC AX
Dial66:	MOV DI, [CS:SI+BOXMN.mPoint]
	MOV [ES:DI+1], AL
Dial67:	JMP Dial31
Dial68:	CALL Dial85  ; End
	CMP BYTE [CS:DI+BOXMN.mType], 4
	JNE Dial69
	MOV SI, [CS:DI+BOXMN.mPoint]
	MOV BYTE [ES:SI], 0
Dial69:	CALL Dial85  ; PgDn
	DW _MOV_SI_DI
	JMP Dial31
Dial70:	DW _XOR_AX_AX  ; Enter
	CMP BYTE [CS:DI+BOXMN.mType], 4
	JNE Dial71
	MOV SI, [CS:DI+BOXMN.mPoint]
	MOV AL, [ES:SI]
Dial71:	CMP WORD [CS:BP+BOXHD.SubFunc], 0
	JE Dial72
	PUSH BP
	PUSH DI
	PUSH BX
	CALL [CS:BP+BOXHD.SubFunc]
	POP BX
	POP SI
	POP BP
	JNC Dial72
	JMP Dial31
Dial72:	CMP AL, 0
	JNE Dial82
	LEA SI, [BP+BOXHD_size]
Dial73:	MOV AL, [CS:SI+BOXMN.mType]
	CMP AL, 0
	JE Dial82
	PUSH SI
	CMP AL, 1
	JNE Dial76
	MOV DI, [CS:SI+BOXMN.mPoint]
	MOV CX, [CS:SI+BOXMN.mCtrl]
	MOV SI, TmpErr+3
	MOV AL, 64
	MUL CH
	DW _ADD_SI_AX
	MOV CH, 0
	PUSH DS
	PUSH ES
	POP DS
	POP ES
	REP MOVSB
	PUSH DS
	PUSH ES
	POP DS
	POP ES
	MOV BYTE [DI], 0
	JMP Dial77
Dial76:	CMP AL, 3
	JNE Dial77
	MOV DI, [CS:SI+BOXMN.mPoint]
	MOV SI, [CS:SI+BOXMN.mCtrl]
	MOV AL, [ES:DI]
	MOV [SI], AL
Dial77:	POP SI
	ADD SI, BOXMN_size
	JMP Dial73
Dial78:	TEST BYTE [CS:BP+BOXHD.bFlags], 8  ; F10
	JZ Dial81
	MOV AH, 0
Dial79:	MOV AL, 1
	JMP Dial71
Dial80:	TEST BYTE [CS:BP+BOXHD.bFlags], 8  ; Alt-F10
	MOV AH, 1
	JNZ Dial79
	JMP Dial39
Dial81:	MOV AL, 0FFh  ; Esc
Dial82:	CALL HidCur
	POP DX  ; Restore window
	POP SI
	TEST BYTE [CS:BP+BOXHD.bFlags], 10h
	JNZ Dial83
	CALL ResWin
	CALL Window
Dial83:	POP CX
	PUSH BP
	PUSH AX
	MOV AH, 1
	INT 10h
	POP AX
	POP BP
	CMP AL, 0
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	RET
;Dialog	ENDP

;GLOBAL Dial85
Dial85:  ; PROC NEAR
	ADD DI, BOXMN_size
	CMP BYTE [CS:DI+BOXMN.mType], 0
	JNE Dial85
	SUB DI, BOXMN_size
	RET
;Dial85 ENDP

;--------------------- Input string --------------------
;			BH,BL - begin
;			ES:SI - string
;			   DI - cursor
;			   CX - length
;			   AH - number of color
;			   AL - key bar
;	Return :	   DI - cursor
;			   AX - key code
;InpStr	PROC	NEAR
;GLOBAL InpStr
InpStr:
	PUSH BP
	PUSH SI
	PUSH DX
	DW _MOV_DX_AX
InSt01:	DW _MOV_AH_DH
	CALL InSt10
	LEA AX, [BX+DI]
	CALL Cursor
	DW _MOV_AL_DL
	CALL Input
	CMP AH, 0FCh
	JE InSt05
	DW _MOV_BP_SI
	CMP BYTE [ES:Quote], 0
	JNZ InSt02
	MOV SI, InSt_T
	CALL Case
InSt02:	CMP BYTE [ES:BP-1], 0
	JNE InSt04
	MOV BYTE [ES:BP-1], 1
	CMP BYTE [ES:Quote], 0
	JNZ InSt03
	DW _OR_AH_AH
	JE InSt03
	CMP AL, ' '
	JB InSt04
	CMP AL, 7Fh
	JE InSt04
InSt03:	MOV BYTE [ES:BP], 0
InSt04:	DW _MOV_SI_BP
	DW _XCHG_DI_DX
	CALL EdLin
	DW _XCHG_DI_DX
	JMP InSt01
InSt05:	DW _XCHG_BP_CX
	CALL GetMous
	MOV AH, 0FCh
	DW _XCHG_BP_CX
	JZ InSt01
	CALL ClrKbd
	CMP AL, 1
	JNE InSt08
	PUSH DX
	DW _MOV_DL_CL
	MOV DH, 1
	DW _XCHG_BP_CX
	CALL InWind
	DW _XCHG_BP_CX
	POP DX
	JC InSt08
	MOV BYTE [ES:SI-1], 1
	DW _SUB_BP_BX
	PUSH DI
	PUSH CX
	DW _MOV_DI_SI
	MOV AL, 0
	REPNE SCASB
	DEC DI
	DW _SUB_DI_SI
	DW _CMP_BP_DI
	JBE InSt06
	DW _MOV_BP_DI
InSt06:	POP CX
	POP DI
	DW _CMP_BP_DI
	JE InSt05
	DW _MOV_DI_BP
	JMP InSt01
InSt07:	DW _OR_DI_DI
	JNE InSt02
InSt08:	POP DX
	POP SI
	POP BP
	RET
;InpStr	ENDP

;GLOBAL InSt10
InSt10:  ; PROC NEAR
	PUSH DI
	PUSH SI
	PUSH DX
	PUSH CX
	MOV DH, 1
	DW _MOV_DL_CL
	CALL BasAdr
	CALL Color
InSt11:
ES
	LODSB
	CMP AL, 0
	JE InSt12
	STOSW
	LOOP InSt11
InSt12:	JCXZ InSt13
	MOV AL, ' '
	REP STOSW
InSt13:	CALL Window
	POP CX
	POP DX
	POP SI
	POP DI
	RET
;InSt10 ENDP

;--------------------- Select case ---------------------
;			BH,BL - begin
;			   AL - key bar
;			   AH - total
;			   CL - current
;			   CH - cursor
;	Return :	   CL - current
;			   CH - cursor
;			   AX - key code
;Select	PROC	NEAR
;GLOBAL Select
Select:
	PUSH SI
	PUSH DI
	PUSH DX
	DW _MOV_DX_AX
	MOV AL, 0
Slct01:	PUSH AX  ; Cursor
	DW _MOV_AX_BX
	DW _ADD_AH_CH
	CALL Cursor
	POP AX
	CMP AL, 0
	JZ Slct03
	PUSH CX
Slct02:	CALL GetMous
	JNZ Slct02
	POP CX
Slct03:	DW _MOV_AL_DL  ; Input
	CALL Input
	CMP AH, 0FCh
	JE Slct04
	MOV SI, Slct_T
	CALL Case
	JMP Slct03
Slct04:	DW _XCHG_DI_CX  ; Mouse
	CALL GetMous
	MOV AH, 0FCh
	DW _XCHG_DI_CX
	JZ Slct03
	CALL ClrKbd
	CMP AL, 1
	JNE Slct13
	PUSH DX
	DEC BX
	CALL Slct20
	DW _XCHG_DI_CX
	CALL InWind
	DW _XCHG_DI_CX
	INC BX
	POP DX
	JC Slct13
	DW _MOV_AX_DI
	DW _SUB_AH_BH
	DW _CMP_AH_CH
	JE Slct04
	DW _MOV_CH_AH
	JMP Slct07
Slct05:	DW _CMP_CH_CL  ; Enter
	JNE Slct07
	JMP Slct13
Slct06:	DW _CMP_CH_CL  ; Space
	JNE Slct07
	INC CH
	DW _CMP_CH_DH
	JB Slct07
	MOV CH, 0
Slct07:	PUSH DX
	PUSH BX
	DW _MOV_AH_CH
	MOV DX, 101h
	DW _ADD_BH_CL
	CALL BasAdr
	MOV BYTE [ES:DI], ' '
	CALL Window
	DW _SUB_BH_CL
	DW _ADD_BH_AH
	CALL BasAdr
	MOV BYTE [ES:DI], ''
	CALL Window
	POP BX
	POP DX
	DW _MOV_CL_CH
Slct08:	JMP Slct01
Slct09:	DW _OR_CH_CH  ; Up
	JE Slct13
	DEC CH
	JMP Slct01
Slct10:	INC CH  ; Down
	DW _CMP_CH_DH
	JB Slct08
Slct11:	DW _MOV_CH_DH  ; End, PgDn
	DEC CH
	JMP Slct13
Slct12:	MOV CH, 0  ; Home, PgUp
Slct13:	POP DX
	POP DI
	POP SI
	RET
;Select	ENDP

;GLOBAL Slct20
Slct20:  ; PROC NEAR
	PUSH DI
	MOV DL, 0
	CALL BasAdr
Slct21:	CMP BYTE [ES:DI], ' '
	JNE Slct22
	CMP BYTE [ES:DI+2], ' '
	JE Slct23
Slct22:	INC DI
	INC DI
	INC DL
	JNE Slct21
Slct23:	POP DI
	RET
;Slct20 ENDP

;----------------------- Flip Flop ---------------------
;			BH,BL - begin
;			   AL - key bar
;			   CL - paremeter
;	Return :	   CL - paremeter
;			   AX - key code
;GLOBAL FlipFl
FlipFl:  ; PROC NEAR
	PUSH DI
	PUSH DX
	DW _MOV_CH_AL
	DW _MOV_AX_BX
	CALL Cursor
FlipF1:	DW _MOV_AL_CH
	CALL Input
	CMP AX, STRICT WORD 3920h
	JE FlipF2
	CMP AH, 0FCh
	JNE FlipF5
	DW _XCHG_DI_CX
	CALL GetMous
	MOV AH, 0FCh
	DW _XCHG_DI_CX
	JZ FlipF1
	CALL ClrKbd
	CMP AL, 1
	JNE FlipF5
	DEC BX
	CALL Slct20
	MOV DH, 1
	DW _XCHG_DI_CX
	CALL InWind
	DW _XCHG_DI_CX
	INC BX
	JC FlipF5
FlipF2:	CALL BasAdr
	MOV BYTE [ES:DI], ' '
	CMP CL, 0
	MOV CL, 0
	JNE FlipF3
	MOV BYTE [ES:DI], 'x'
	MOV CL, 1
FlipF3:	MOV DX, 101h
	CALL Window
	CMP AL, ' '
	JE FlipF1
	PUSH CX
FlipF4:	CALL GetMous
	JNZ FlipF4
	POP CX
	JMP FlipF1
FlipF5:	POP DX
	POP DI
	RET
;FlipFl ENDP

;------------------------ Menu -------------------------
;			CS:SI - control line
;			BH,BL - begin
;			DH,DL - size
;			   BP - color table
;			   AL - key bar
;			   CL - case
;	Return :	   CL - case
;			   AX - key code
;GLOBAL MinMnu
MinMnu:  ; PROC NEAR
	PUSH SI
	PUSH DI
	CALL HidCur
	DW _MOV_DI_SI
	DW _MOV_CH_AL
MnMn01:	MOV AH, [CS:BP+0]
	MOV AL, [CS:BP+1]
	CALL MnMn40
	DW _MOV_AL_CH
	AND AL, 7Fh
	CALL Input
	CALL MnMn10
	JC MnMn01
	CMP AH, 0FCh
	JE MnMn02
	PUSH AX
	MOV AH, [CS:BP+0]
	MOV AL, [CS:BP+2]
	CALL MnMn40
	POP AX
MnMn02:	POP DI
	POP SI
	RET
;MinMnu ENDP

;MnMn10	PROC	NEAR
;GLOBAL MnMn10
MnMn10:
	CMP AH, 0FCh
	JE MnMn11
	JMP MnMn19
MnMn11:	DW _XCHG_CX_SI
	CALL GetMous
	MOV AH, 0FCh
	DW _XCHG_CX_SI
	JZ MnMn16
	CMP AL, 1
	JNE MnMn18
	PUSH DX
	PUSH CX
	DW _MOV_CX_SI
	DW _MOV_SI_DI
	CALL MnMn60
	CALL InWind
	DW _MOV_SI_CX
	POP CX
	POP DX
	JC MnMn18
	DW _MOV_AX_SI
	DW _SUB_AX_BX
	DW _MOV_SI_DI
MnMn12:	CMP BYTE [CS:SI], 0
	JE MnMn11
	MOV AH, [CS:SI+1]
	DW _CMP_AL_AH
	JB MnMn11
	ADD AH, [CS:SI]
	DW _CMP_AL_AH
	JB MnMn13
	INC SI
	INC SI
	JMP MnMn12
MnMn13:	DW _MOV_AX_SI
	DW _SUB_AX_DI
	SHR AX, 1
	DW _CMP_AL_CL
	DW _MOV_CL_AL
	JNE MnMn16
	PUSH DX
	PUSH CX
	PUSH BX
	ADD BL, [CS:SI+1]
	MOV DL, [CS:SI]
	MOV DH, 1
	DW _XOR_SI_SI
MnMn14:	CALL GetMous
	JZ MnMn17
	CALL InWind
	MOV AL, '๛'
	JNC MnMn15
	MOV AL, 0
MnMn15:	MOV AH, 0
	DW _CMP_AX_SI
	JE MnMn14
	DW _MOV_SI_AX
	CALL TypMous
	JMP MnMn14
MnMn16:	STC
	RET
MnMn17:	MOV AL, 0
	CALL TypMous
	POP BX
	POP CX
	POP DX
	DW _OR_SI_SI
	JE MnMn16
	MOV AX, 1C0Dh
MnMn18:	JMP MnMn23
MnMn19:	MOV SI, MnMn_T
	CALL Case
	CALL UpCase
	CMP AL, 'A'
	JB MnMn23
	CMP AL, 'Z'
	JA MnMn23
	DW _MOV_SI_DI
MnMn20:	CMP BYTE [CS:SI], 0
	JE MnMn16
	PUSH DI
	PUSH CX
	MOV CX, [CS:SI]
	PUSH BX
	DW _ADD_BL_CH
	CALL BasAdr
	POP BX
	MOV CH, 0
	DEC DI
MnMn21:	INC DI
	SCASB
	LOOPNE MnMn21
	POP CX
	POP DI
	JE MnMn22
	INC SI
	INC SI
	JMP MnMn20
MnMn22:	DW _MOV_CX_SI
	DW _SUB_CX_DI
	SHR CX, 1
	MOV AX, 1C0Dh
MnMn23:	CLC
	RET
MnMn24:	DW _OR_CL_CL
	JE MnMn25
	DEC CX
	JMP MnMn16
MnMn25:	CALL MnMn50
	JE MnMn16
	INC CX
	JMP MnMn25
MnMn26:	CALL MnMn50
	JE MnMn27
	INC CX
	JMP MnMn16
MnMn27:	MOV CL, 0
	JMP MnMn16
MnMn28:	TEST CH, 80h
	JZ MnMn23
	MOV AX, 4900h
	MOV CL, 0
	JMP MnMn23
MnMn29:	TEST CH, 80h
	JZ MnMn23
	MOV AX, 5100h
MnMn30:	CALL MnMn50
	JE MnMn23
	INC CX
	JMP MnMn30
;MnMn10	ENDP

;GLOBAL MnMn40
MnMn40:  ; PROC NEAR
	PUSH CX
	DW _MOV_SI_DI
	CALL BasAdr
	CALL Color
	DW _XCHG_AL_AH
	DW _MOV_CL_DL
	MOV CH, 0
	PUSH DI
	CALL MvsColr
	POP DI
	POP CX
	PUSH CX
	PUSH SI
	CALL MnMn41
	POP SI
	POP CX
	CALL Window
	DW _MOV_DI_SI
	RET
;MnMn40 ENDP

;GLOBAL MnMn41
MnMn41:  ; PROC NEAR
	CALL Color
	DW _MOV_AL_AH
	MOV CH, 0
	DW _ADD_CX_CX
	DW _ADD_SI_CX
	MOV CL, [CS:SI+1]
	DW _ADD_CX_CX
	DW _ADD_DI_CX
	MOV CL, [CS:SI]
	CALL MvsColr
	RET
;MnMn41 ENDP

;GLOBAL MnMn50
MnMn50:  ; PROC NEAR
	PUSH DI
	PUSH CX
	MOV CH, 0
	DW _ADD_CX_CX
	DW _ADD_DI_CX
	CMP BYTE [CS:DI+2], 0
	POP CX
	POP DI
	RET
;MnMn50 ENDP

;GLOBAL MnMn60
MnMn60:  ; PROC NEAR
	PUSH SI
MnMn61:	MOV DX, [CS:SI]
	INC SI
	INC SI
	CMP BYTE [CS:SI], 0
	JNE MnMn61
	DW _ADD_DL_DH
	MOV DH, 1
	POP SI
	RET
;MnMn60 ENDP

;-------------------- Output key bar -------------------
;			   AL - Case
;GLOBAL PutKey
PutKey:  ; PROC NEAR
	CMP BYTE [ES:KeyBar], 0
	JNZ PutKy1
	MOV BYTE [ES:BarPrev], 0FFh
	RET
PutKy1:	PUSH BX
	PUSH AX
	DW _MOV_BL_AL
	MOV AH, 2
	INT 16h
	MOV AH, 3
	TEST AL, 8
	JNZ PutKy2
	DEC AH
	TEST AL, 4
	JNZ PutKy2
	DEC AH
	TEST AL, 3
	JNZ PutKy2
	DEC AH
PutKy2:	DW _MOV_AL_BL
	CALL PutKey0
	POP AX
	POP BX
	RET
;PutKey ENDP

;GLOBAL PutKey0
PutKey0:  ; PROC NEAR
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	SHL AL, 1
	SHL AL, 1
	DW _OR_AL_AH
	MOV AH, 0
	DW _MOV_BX_AX
	MOV AL, 0
	CMP BL, LenKeyB
	JAE PutKy3
	MOV AL, [CS:BX+KeyB_T]
PutKy3:	CMP AL, [ES:BarPrev]
	JE PutKy7
	MOV [ES:BarPrev], AL
	MOV AH, 10
	MUL AH
	DW _MOV_SI_AX
	MOV BH, [ES:Lines]
	DEC BH
	MOV BL, 0
	CALL BasAdr
	MOV AH, KeyTi_C
	CALL Color
	DW _MOV_DH_AH
	MOV AH, KeyNu_C
	CALL Color
	MOV DL, '1'
PutKy4:	DW _MOV_AL_DL
PutKy5:	STOSW
	DW _XCHG_AH_DH
	PUSH SI
	PUSH AX
	MOV CX, 6
	MOV AL, [CS:SI+KeyC_T]
	MUL CL
	ADD AX, STRICT WORD Key_S
	DW _MOV_SI_AX
	POP AX
	CALL MvsBwc
	POP SI
	INC SI
	DW _XCHG_AH_DH
	MOV AL, ' '
	STOSW
	INC DX
	CMP DL, '9'+1
	JB PutKy4
	JA PutKy6
	MOV AL, '1'
	STOSW
	MOV AL, '0'
	JMP PutKy5
PutKy6:	MOV DX, 150h
	CALL Window
PutKy7:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	RET
;PutKey0 ENDP

;------------------- Keyboard input --------------------
;			   AL - Key bar case
;	Return:		   AX - Key code
;GLOBAL Input
Input:  ; PROC NEAR
	PUSH AX
	CALL Input0
	CMP AX, STRICT WORD 3B00h
	JNE Input1
	CALL Help
	POP AX
	JMP Input
Input1:	INC SP
	INC SP
	RET
;Input ENDP

;GLOBAL Input0
Input0:  ; PROC NEAR
;USES	DS,SI,DI,DX,CX,BX
; IKeyBar, BlMouse, KbdFlgs, AltLock and ClkFlag are BYTE-sized arguments, but WASM and TASM (but not JWasm) allocate a WORD for them.
;LOCAL	IKeyBar	:WORD	,\ .
;	BlMouse	:WORD	,\ .
;	KbdFlgs	:WORD	,\ .
;	AltLock	:WORD	,\ .
;	ClkFlag	:WORD	,\ .
;	ClkBuf5	:WORD	,\ .
;	ClkBuf4	:WORD	,\ .
;	ClkBuf3	:WORD	,\ .
;	ClkBuf2	:WORD	,\ .
;	ClkBuf1	:WORD	,\ .
;	ClkBuf0	:WORD	,\ .
;	BlTimeHi:WORD	,\ .
;	BlTimeLo:WORD	,\ .
;	AltTimeHi:WORD  ,\ .
;	AltTimeLo:WORD
; BP-relative negative addresses of local variables of Input0.
Input0__IKeyBar EQU 2  ; BYTE.
Input0__BlMouse EQU 4  ; BYTE.
Input0__KbdFlgs EQU 6  ; BYTE.
Input0__AltLock EQU 8  ; BYTE.
Input0__ClkFlag EQU 0Ah  ; BYTE.
Input0__ClkBuf EQU 16h  ; WORD:6.
Input0__BlTime EQU 1Ah  ; DWORD.
Input0__AltTime EQU 1Eh  ; DWORD.
	PUSH BP
	DW _MOV_BP_SP
	SUB SP, 1Eh
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH ES
	POP DS
	MOV [BP-Input0__IKeyBar], AL
	MOV AH, 1
	INT 16h
	JZ Inpt02
	MOV AH, 0
	INT 16h
Inpt01:	JMP Inpt41
Inpt02:	DW _XOR_AX_AX
	CALL GetMous
	MOV AH, 0FCh
	TEST AL, 7
	JNZ Inpt01
	CALL Timer
	MOV [BP-Input0__AltTime+0], DX
	MOV [BP-Input0__AltTime+2], CX
	PUSH ES
	PUSH SS
	POP ES
	MOV SI, ScrBuf+2*74
	LEA DI, [BP-Input0__ClkBuf]
	MOV CX, 6
	REP MOVSW
	POP ES
	MOV AH, 2
	INT 16h
	MOV [BP-Input0__KbdFlgs], AL
	MOV BYTE [BP-Input0__AltLock], 0
Inpt03:	MOV BYTE [BP-Input0__ClkFlag], 0
	MOV BYTE [BP-Input0__BlMouse], 0
Inpt04:	MOV CX, 0FFFFh
	CMP BYTE [BlDelay], 0
	JE Inpt05
	MOV AH, 2Ch
	INT 21h
	ADD CL, [BlDelay]
	CMP CL, 60
	JB Inpt05
	SUB CL, 60
	INC CH
Inpt05:	MOV [BP-Input0__BlTime+0], DX
	MOV [BP-Input0__BlTime+2], CX
Inpt10:	MOV AL, [BP-Input0__IKeyBar]
	CALL PutKey
	CALL LeaveTm
	CMP BYTE [BlDelay], 0
	JE Inpt20
	MOV AH, 2Ch
	INT 21h
	CMP CH, 0
	JNE Inpt11
	CMP BYTE [BP-Input0__BlTime+3], 24
	JB Inpt11
	MOV [BP-Input0__BlTime+3], CH
Inpt11:	CMP CX, [BP-Input0__BlTime+2]
	JB Inpt20
	JA Inpt12
	CMP DX, [BP-Input0__BlTime+0]
	JB Inpt20
Inpt12:	CALL Blank
	DW _XOR_BX_BX
	MOV DH, [Lines]
	MOV DL, 80
	CALL Window
Inpt13:	DW _XOR_AX_AX
	CALL GetMous
	TEST AL, 7
	JNZ Inpt13
	JMP Inpt03
Inpt20:	CMP BYTE [Clock], 0
	JE Inpt30
	MOV DI, ScrBuf+2*75
	MOV AH, 2Ch
	INT 21h
	DW _MOV_AL_CH
	MOV AH, 0
	CMP BYTE [Country+CNTRY.TimeFmt], 0
	JNZ Inpt22
	DEC DI
	DEC DI
	MOV BL, 12
	DIV BL
	CMP AH, 0
	JNE Inpt21
	MOV AH, 12
Inpt21:	CMP AL, 0
	DW _MOV_AL_AH
	MOV BH, 'a'
	JE Inpt22
	MOV BH, 'p'
Inpt22:	MOV BL, ' '
	CMP DL, 50
	JB Inpt23
	MOV BL, [Country+CNTRY.TimeSep]
Inpt23:	CMP BL, [BP-Input0__ClkFlag]
	JE Inpt30
	MOV [BP-Input0__ClkFlag], BL
	CALL HexDec
	DW _MOV_DX_AX
	DW _MOV_AL_CL
	CALL HexDec
	DW _MOV_CX_AX
	MOV AH, Clock_C
	CALL Color
	DW _MOV_AL_DL
	CMP AL, '0'
	JNE Inpt24
	MOV AL, ' '
Inpt24:	STOSW
	DW _MOV_AL_DH
	STOSW
	DW _MOV_AL_BL
	STOSW
	DW _MOV_AL_CL
	STOSW
	DW _MOV_AL_CH
	STOSW
	CMP BYTE [Country+CNTRY.TimeFmt], 0
	JNZ Inpt25
	DW _MOV_AL_BH
	STOSW
Inpt25:	MOV BX, 74
	MOV DX, 106h
	CALL Window
Inpt30:	CMP WORD [AutoTim+0], 0FFFFh
	JE Inpt31
	DW _MOV_BX_DX
	MOV AH, 2Ch
	INT 21h
	DW _XCHG_BX_DX
	MOV AX, 0FE00h
	CMP CX, [AutoTim+0]
	JB Inpt31
	JA Inpt32
	CMP BX, [AutoTim+2]
	JAE Inpt32
Inpt31:	CALL Rnd
	MOV AH, 1
	INT 16h
	JZ Inpt33
	MOV AH, 0
	INT 16h
Inpt32:	JMP Inpt40
Inpt33:	DW _XOR_AX_AX
	CALL GetMous
	MOV AH, 0FCh
	TEST AL, 7
	JNZ Inpt32
	MOV AH, 2
	INT 16h
	DW _MOV_BL_AL
	XCHG BL, [BP-Input0__KbdFlgs]
	CMP BYTE [DesqVie], 0
	JNZ Inpt34
	CMP BYTE [AltBar], 0
	JZ Inpt34
	PUSH BX
	PUSH AX
	CALL Timer
	DW _MOV_AX_CX
	DW _MOV_BX_DX
	XCHG DX, [BP-Input0__AltTime+0]
	XCHG CX, [BP-Input0__AltTime+2]
	DW _SUB_BX_DX
	DW _SBB_AX_CX
	CMP BX, 3
	CMC
	DW _ADC_AX_AX
	POP AX
	POP BX
	JNE Inpt34
	DW _MOV_AH_BL
	DW _XOR_AH_AL
	JZ Inpt34
	CMP AH, 8
	JNE Inpt34
	MOV BH, 1
	TEST AL, 8
	JNZ Inpt38
	CMP BYTE [BP-Input0__AltLock], 0
	JE Inpt34
	MOV AX, 0FD00h
	JMP Inpt40
Inpt34:	AND BL, 0F0h
	DW _XOR_AL_BL
	JNZ Inpt37
	DW _XOR_CX_CX
	CALL GetMous
	MOV DX, 102h
	MOV BX, 78
	CALL InWind
	JC Inpt35
	CMP BYTE [BP-Input0__BlMouse], 0
	JE Inpt36
	JMP Inpt12
Inpt35:	MOV BYTE [BP-Input0__BlMouse], 1
Inpt36:	MOV BH, [Lines]
	DEC BH
	CALL InWind
	JNC Inpt39
	JMP Inpt10
Inpt37:	TEST AL, 0F7h
	JZ Inpt39
	MOV BH, 0
Inpt38:	MOV [BP-Input0__AltLock], BH
Inpt39:	JMP Inpt04
Inpt40:	CMP BYTE [Clock], 0
	JZ Inpt41
	PUSH DS
	PUSH SS
	POP DS
	LEA SI, [BP-Input0__ClkBuf]
	MOV DI, ScrBuf+2*74
	MOV CX, 6
	REP MOVSW
	POP DS
	MOV BX, 74
	MOV DX, 106h
	CALL Window
Inpt41:	MOV WORD [AutoTim+0], 0FFFFh
	CMP AH, 0FCh
	JNE Inpt55
	CMP BYTE [KeyBar], 0
	JZ Inpt55
	CALL GetMous
	MOV AH, 0FCh
	INC CH
	CMP CH, [Lines]
	JNE Inpt55
	DEC CH
	DW _MOV_BL_CL
	AND BX, 0F8h
	DW _XOR_SI_SI
	DW _XOR_DI_DI
Inpt50:	PUSH BX
	MOV BH, [Lines]
	DEC BH
	MOV DX, 108h
	CALL InWind
	POP DX
	DW _MOV_BH_AL
	MOV AL, 0
	JC Inpt51
	DW _OR_DI_DI
	JZ Inpt52
	MOV AL, '๛'
Inpt51:	MOV AH, 0
	DW _CMP_AX_SI
	JE Inpt52
	DW _MOV_SI_AX
	CALL TypMous
Inpt52:	MOV AH, 3
	TEST BH, 2
	JNZ Inpt54
	MOV AH, 1
	TEST BH, 4
	JNZ Inpt54
	MOV AH, 0
	TEST BH, 1
	JZ Inpt56
Inpt54:	MOV AL, [BP-Input0__IKeyBar]
	CALL PutKey0
	CALL GetMous
	DW _OR_DI_DI
	JNZ Inpt50
	PUSH BX
	CMP BL, 72
	CMC
	ADC BL, 1
	DW _MOV_BH_CH
	CALL BasAdr
	POP BX
	CMP BYTE [DI], ' '
	JNE Inpt50
	MOV AH, 0FCh
Inpt55:	CLC
	JMP Inpt59
Inpt56:	CMP AL, 0
	JE Inpt57
	MOV AL, 0
	CALL TypMous
	MOV AH, 68h
	TEST DH, 2
	JNZ Inpt58
	MOV AH, 54h
	TEST DH, 4
	JNZ Inpt58
	MOV AH, 3Bh
	TEST DH, 1
	JNZ Inpt58
Inpt57:	JMP Inpt02
Inpt58:	MOV CL, 3
	SHR BL, CL
	DW _ADD_AH_BL
	MOV AL, 0
	STC
Inpt59:
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	DW _MOV_SP_BP
	POP BP
	RET
;Input0 ENDP

;GLOBAL LeaveTm
LeaveTm:  ; PROC NEAR
	INT 28h
	CMP BYTE [DesqVie], 0
	JZ LvTm1
	MOV AX, 101Ah
	INT 15h
	MOV AX, 1000h
	INT 15h
	MOV AX, 1025h
	INT 15h
LvTm1:	RET
;LeaveTm ENDP

;--------------------- Blank screen --------------------
;GLOBAL Blank
Blank:  ; PROC NEAR
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV AL, 0
	CALL CurMous
	MOV AH, 0Fh
	INT 10h
	MOV AH, 3
	INT 10h
	PUSH CX
	PUSH DX
	MOV CX, 2000h
	MOV AH, 1
	INT 10h
	DW _XOR_CX_CX
	MOV DH, [Lines]
	DEC DH
	MOV DL, 79
	MOV AH, Sky1_C
	CALL Color
	DW _MOV_BH_AH
	MOV AX, 600h
	INT 10h
	MOV DI, Stars
	MOV CX, NmbStrs*STAR_size/2
	DW _XOR_AX_AX
	REP STOSW
	DW _XOR_CX_CX
	CALL GetMous
	DW _MOV_SI_CX
	MOV AH, 2
	INT 16h
	DW _MOV_CL_AL
	DW _XOR_DI_DI
Blnk01:	PUSH SI
	PUSH CX
	CALL Rnd
	MOV BL, [ES:Lines]
	MOV BH, 0
	MUL BX
	DW _MOV_CL_DL
	CALL Rnd
	MOV BX, 80
	MUL BX
	DW _MOV_DH_CL
	CALL Rnd
	MOV CL, 3
	ROR AX, CL
	CMP AL, 100
	JB Blnk05
	DW _MOV_BL_AL
	CALL Rnd
	MOV CL, 5
	ROR AL, CL
	CMP AL, 50
	JB Blnk05
	DW _OR_AL_AH
	AND AL, 1
	DW _MOV_BH_AL
	MOV SI, Stars
	MOV CX, NmbStrs
	DW _XOR_BP_BP
Blnk02:	LODSW
	DW _OR_AX_AX
	LODSW
	JNE Blnk03
	DW _OR_BP_BP
	JNE Blnk04
	DW _MOV_BP_SI
	JMP Blnk04
Blnk03:	DW _CMP_AX_DX
	JE Blnk05
Blnk04:	LOOP Blnk02
	DW _OR_BP_BP
	JE Blnk05
	MOV [DS:BP-STAR_size+STAR.StarMod], BX
	MOV [DS:BP-STAR_size+STAR.StarPos], DX
	MOV AH, 0Fh
	INT 10h
	MOV AH, 2
	INT 10h
	MOV AH, Sky1_C
	CALL Color
	DW _MOV_BL_AH
	MOV CX, 1
	MOV AL, [ES:StarTab+0]
	MOV AH, 9
	INT 10h
Blnk05:	MOV SI, Stars
	MOV CX, NmbStrs
Blnk06:	PUSH CX
	LODSW
	DW _MOV_BX_AX
	LODSW
	DW _OR_BX_BX
	JE Blnk09
	DW _MOV_DX_AX
	DEC BX
	MOV [SI-STAR_size+STAR_StarClk], BL
	MOV AL, [ES:StarTab+1]
	CMP BL, 12
	JE Blnk08
	MOV AL, [ES:StarTab+2]
	CMP BL, 9
	JNE Blnk07
	DW _OR_BH_BH
	JE Blnk08
	MOV BL, 0
Blnk07:	MOV AL, [ES:StarTab+3]
	CMP BL, 6
	JE Blnk08
	MOV AL, [ES:StarTab+4]
	CMP BL, 3
	JE Blnk08
	DW _OR_BL_BL
	JNE Blnk09
	DW _XOR_AX_AX
	MOV [SI-STAR_size+STAR.StarMod], AX
	MOV [SI-STAR_size+STAR.StarPos], AX
	MOV AL, ' '
Blnk08:	PUSH AX
	MOV AH, 0Fh
	INT 10h
	MOV AH, 2
	INT 10h
	POP AX
	MOV AH, Sky2_C
	CALL Color
	DW _MOV_BL_AH
	MOV CX, 1
	MOV AH, 9
	INT 10h
Blnk09:	POP CX
	LOOP Blnk06
	POP CX
	POP SI
Blnk10:	MOV AH, 1
	INT 16h
	JNZ Blnk13
	MOV AH, 2
	INT 16h
	DW _XCHG_AL_CL
	AND AL, 0F0h
	DW _XOR_AL_CL
	JNZ Blnk14
	DW _MOV_BX_CX
	DW _XOR_AX_AX
	DW _XOR_CX_CX
	CALL GetMous
	TEST AL, 7
	JNZ Blnk14
	PUSH BX
	MOV BX, 76
	MOV DX, 204h
	CALL InWind
	POP BX
	JC Blnk11
	DW _MOV_SI_CX
Blnk11:	DW _CMP_CX_SI
	JNE Blnk14
	CALL Timer
	DW _MOV_CX_BX
	DW _XCHG_DX_DI
	DW _CMP_DX_DI
	JE Blnk12
	JMP Blnk01
Blnk12:	CALL LeaveTm
	JMP Blnk10
Blnk13:	MOV AH, 0
	INT 16h
Blnk14:	MOV AH, 0Fh
	INT 10h
	POP DX
	MOV AH, 2
	INT 10h
	POP CX
	MOV AH, 1
	INT 10h
	MOV AL, 1
	CALL CurMous
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	RET
;Blank ENDP

;GLOBAL Rnd
Rnd:  ; PROC NEAR
	PUSH DX
	PUSH CX
	PUSH BX
	MOV BX, 3
	MOV AX, [ES:Rand1]
	MUL BX
	DW _MOV_CX_AX
	MOV AX, [ES:Rand2]
	MOV [ES:Rand1], AX
	MUL BX
	DW _ADD_AX_CX
	ADD AX, STRICT WORD 23457
	MOV [ES:Rand2], AX
	POP BX
	POP CX
	POP DX
	RET
;Rnd ENDP

;----------------------- Edit line ---------------------
;			ES:SI - begin of line
;			   DX - cursor
;			   CX - length of line
;			   AX - key code
;	Return :	 CY=0 - no change
;			 CY=1 - change
;			   DX - cursor
;EdLin	PROC	NEAR
;GLOBAL EdLin
EdLin:
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH CX
	PUSH AX
	PUSH ES
	POP DS
	DW _MOV_DI_SI
	CMP BYTE [Quote], 0
	JNZ E00_03
	MOV SI, EdKeys
	CALL Case
	DW _OR_AX_AX
	JE E00_04
	DW _OR_AH_AH
	JE E00_01
	CMP AL, ' '
	JB E00_04
E00_01:	DW _CMP_DX_CX  ; Symbols
	JB E00_02
	CALL Beep
	JMP E00_04
E00_02:	PUSH DI
	DW _ADD_DI_CX
	DW _MOV_SI_DI
	DEC SI
	PUSH DI
	DW _SUB_CX_DX
	STD
	REP MOVSB
	CLD
	POP DI
	MOV BYTE [DI], 0
	POP SI
	DW _ADD_SI_DX
	MOV [SI], AL
	INC DX
	JMP E00_06
E00_03:	MOV BYTE [Quote], 0
	CMP AL, 0
	JNE E00_01
E00_04:	CLC
	JMP E00_07
E00_05:	LODSB
	STOSB
	CMP AL, 0
	JNE E00_05
E00_06:	STC
E00_07:	POP AX
	POP CX
	POP DI
	POP SI
	POP DS
	RET

E01_00:	DW _OR_DX_DX  ; Left,   ^S
	JE E00_04
	DEC DX
	JMP E00_06
E02_00:	DW _ADD_DI_DX  ; Right,  ^D
	CMP BYTE [DI], 0
	JE E00_04
	INC DX
	JMP E00_06
E03_00:	CALL EdSub1  ; ^Left,  ^A
	JMP E00_06
E04_00:	CALL EdSub2  ; ^Right, ^F
	JMP E00_06
E05_00:	DW _XOR_DX_DX  ; Home
	JMP E00_06
E06_00:	DW _MOV_SI_DI  ; End
	MOV AL, 0
	INC CX
	REPNE SCASB
	DEC DI
	DW _MOV_DX_DI
	DW _SUB_DX_SI
	JMP E00_06
E07_00:	DW _OR_DX_DX  ; BackSpace
	JE E00_04
	DEC DX
E08_00:	DW _ADD_DI_DX  ; Del, ^G
	CMP BYTE [DI], 0
	JE E00_04
	LEA SI, [DI+1]
	JMP E00_05
E09_00:	DW _XOR_DX_DX  ; ^Y
E10_00:	DW _ADD_DI_DX  ; ^K
	MOV BYTE [ES:DI], 0
	JMP E00_06
E11_00:	CALL EdSub1  ; ^BackSpace, ^W
	JMP E00_05
E12_00:	PUSH DX  ; ^T
	CALL EdSub2
	POP DX
	JMP E00_05
E13_00:	MOV BYTE [Quote], 1  ; ^Q
	JMP E00_04
;EdLin	ENDP

;GLOBAL EdSub1
EdSub1:  ; PROC NEAR
	DW _ADD_DI_DX
	DW _MOV_SI_DI
ES1_01:	DW _OR_DX_DX
	JE ES1_03
	DEC DX
	DEC DI
	MOV AL, [ES:DI]
	CALL CmpSym
	JE ES1_01
ES1_02:	DW _OR_DX_DX
	JE ES1_03
	DEC DX
	DEC DI
	MOV AL, [ES:DI]
	CALL CmpSym
	JNE ES1_02
	INC DX
	INC DI
ES1_03:	DW _CMP_SI_DI
	RET
;EdSub1 ENDP

;GLOBAL EdSub2
EdSub2:  ; PROC NEAR
	DW _ADD_DI_DX
	DW _MOV_SI_DI
ES2_01:	CMP BYTE [ES:SI], 0
	JE ES2_03
	INC SI
	INC DX
	MOV AL, [ES:SI]
	CALL CmpSym
	JE ES2_01
ES2_02:	CMP BYTE [ES:SI], 0
	JE ES2_03
	INC SI
	INC DX
	MOV AL, [ES:SI]
	CALL CmpSym
	JNE ES2_02
ES2_03:	DW _CMP_SI_DI
	RET
;EdSub2 ENDP

;-------------------- Compare symbol -------------------
;			   AL - Symbol
;GLOBAL CmpSym
CmpSym:  ; PROC NEAR
	PUSH ES
	PUSH DI
	PUSH CX
	PUSH CS
	POP ES
	MOV DI, CtEn_T
	MOV CX, 10
	REPNE SCASB
	POP CX
	POP DI
	POP ES
	RET
;CmpSym ENDP

;----------------------- Get color ---------------------
;			   AH - color number
;	Return :	   AH - color
;GLOBAL Color
Color:  ; PROC NEAR
	PUSH DI
	CALL ColAddr
	MOV AH, [ES:DI]
	POP DI
	RET
;Color ENDP

;GLOBAL ColAddr
ColAddr:  ; PROC NEAR
	PUSH AX
	MOV AL, 6
	MUL AH
	DW _MOV_DI_AX
	MOV AL, [ES:ColTyp]
	CMP AL, 3
	JB ColAd1
	MOV AL, 1
ColAd1:	CBW
	DW _ADD_AX_AX
	CMP BYTE [ES:ScrMod], 7
	JNE ColAd2
	INC AX
ColAd2:	DW _ADD_DI_AX
	ADD DI, ColTab
	POP AX
	RET
;ColAddr ENDP

;------------------------- Shadow ----------------------
;			ES:DI - address of screen buffer
;GLOBAL Shadow
Shadow:  ; PROC NEAR
	PUSH AX
	INC DI
	MOV AL, [ES:DI]
	MOV AH, ShadFl
	CALL Color
	CALL ShadCol
	STOSB
	POP AX
	RET
;Shadow ENDP

;GLOBAL ShadCol
ShadCol:  ; PROC NEAR
	CMP AH, 1
	JB Shadw1
	PUSHF
	AND AL, 8Fh
	XOR AL, 8
	POPF
	JE Shadw1
	MOV AL, 7
Shadw1:	RET
;ShadCol ENDP

;-------------------- Moving strings -------------------
;			CS:SI(B) -> ES:DI(W)
;GLOBAL MvsBwc
MvsBwc:  ; PROC NEAR
CS
	LODSB
	STOSW
	LOOP MvsBwc
	RET
;MvsBwc ENDP

;			(Color) -> ES:DI(W)
;GLOBAL MvsColr
MvsColr:  ; PROC NEAR
	INC DI
	STOSB
	LOOP MvsColr
	RET
;MvsColr ENDP
;			CS:SI(B) -> ES:DI(W)
;MovDz	PROC	NEAR
;GLOBAL MovDz
MovDz:
	CALL BasAdr
MovDz0:	LODSB
	CMP AL, 0
	JE MovDz1
	STOSB
	INC DI
	JMP MovDz0
MovDz1:	RET
;MovDz	ENDP

;--------------------- Upper letter --------------------
;			   AL - letter
;	Return :	   AL - letter
;GLOBAL UpCase
UpCase:  ; PROC NEAR
	CMP AL, 'a'
	JB UpCas1
	CMP AL, 'z'
	JA UpCas1
	SUB AL, 20h
UpCas1:	CALL FAR [ES:Country+CNTRY.CaseMp]
	RET
;UpCase ENDP

;--------------------- Lower letter --------------------
;			   AL - letter
;	Return :	   AL - letter
;GLOBAL LowCase
LowCase:  ; PROC NEAR
	CMP AL, 'A'
	JB LoCas2
	CMP AL, 'Z'
	JA LoCas1
	ADD AL, 20h
	RET
LoCas1:	CMP AL, 80h
	JB LoCas2
	PUSH BX
	DW _MOV_BL_AL
	MOV BH, 0
	MOV AL, [ES:BX+LowTab-128]
	POP BX
LoCas2:	RET
;LowCase ENDP

;------------------------ Cut path ---------------------
;			DS:SI - path
;GLOBAL CutPath
CutPath:  ; PROC NEAR
	PUSH BX
	PUSH AX
CutPt1:	DW _MOV_BX_SI
CutPt2:	LODSB
	CMP AL, ':'
	JE CutPt1
	CMP AL, '\'
	JE CutPt1
	CMP AL, 0
	JNE CutPt2
	DW _MOV_SI_BX
	POP AX
	POP BX
	RET
;CutPath ENDP

;--------------------- Normal string -------------------
;			ES:SI - address of string
;GLOBAL NormStr
NormStr:  ; PROC NEAR
	PUSH SI
	PUSH DI
	PUSH BX
	PUSH AX
	DW _MOV_DI_SI
NrmSt1:
ES
	LODSB
	CMP AL, ' '
	JE NrmSt1
	DEC SI
NrmSt2:	DW _MOV_BX_DI
NrmSt3:
ES
	LODSB
	STOSB
	CMP AL, ' '
	JE NrmSt3
	CMP AL, 0
	JNE NrmSt2
	MOV [ES:BX], AL
	POP AX
	POP BX
	POP DI
	POP SI
	RET
;NormStr ENDP

;---------------------- Higher letter ------------------
;			ES:SI - address of string
;GLOBAL PathLin
PathLin:  ; PROC NEAR
	PUSH DI
	PUSH AX
	DW _MOV_DI_SI
PthLn1:	MOV AL, [ES:DI]
	CALL UpCase
	STOSB
	CMP AL, 0
	JNE PthLn1
	POP AX
	POP DI
	RET
;PathLin ENDP

;----------------- Higher & lower letters --------------
;			ES:SI - address of string
;GLOBAL LetLin
LetLin:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH AX
	CALL PathLin
	PUSH ES
	POP DS
	CALL CutPath
	DW _MOV_DI_SI
LetLn1:	LODSB
	CALL LowCase
	STOSB
	CMP AL, 0
	JNE LetLn1
	POP AX
	POP DI
	POP SI
	POP DS
	RET
;LetLin ENDP

;-------------------- Shirter string -------------------
;			ES:SI - address of string
;			   AX - limit
;GLOBAL ShrtLin
ShrtLin:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH CX
	PUSH AX
	PUSH AX
	DW _MOV_DI_SI
	MOV CX, 256
	MOV AL, 0
	REPNE SCASB
	DEC DI
	DW _SUB_DI_SI
	POP CX
	DW _SUB_DI_CX
	JBE ShtLn3
	PUSH ES
	POP DS
	DW _XCHG_SI_DI
	CMP BYTE [DI+1], ':'
	JNE ShtLn1
	INC DI
	INC DI
	DEC CX
	DEC CX
ShtLn1:	CMP BYTE [DI], '\'
	JNE ShtLn2
	INC DI
	DEC CX
ShtLn2:	MOV AL, '.'
	STOSB
	STOSB
	STOSB
	DEC CX
	DEC CX
	DW _ADD_SI_DI
	REP MOVSB
ShtLn3:	POP AX
	POP CX
	POP DI
	POP SI
	POP DS
	RET
;ShrtLin ENDP

;-------------------- Text hex number ------------------
;			   AL - ASCII byte
;	Return :	   AL - hex number, CY=0
;				     error, CY=1
;GLOBAL TstHex
TstHex:  ; PROC NEAR
	CMP AL, '0'
	JB TstHx2
	CMP AL, '9'
	JA TstHx1
	SUB AL, '0'
	RET
TstHx1:	CALL UpCase
	CMP AL, 'A'
	JB TstHx2
	CMP AL, 'F'
	JA TstHx2
	SUB AL, 'A'-10
	RET
TstHx2:	STC
	RET
;TstHex ENDP

;----------------- Convert hex to dec ------------------
;GLOBAL HexDec
HexDec:  ; PROC NEAR
	PUSH CX
	MOV AH, 0
	MOV CL, 10
	DIV CL
	ADD AX, STRICT WORD '00'
	POP CX
	RET
;HexDec ENDP

;--------------------- Number input --------------------
;			ES:SI - string
;	Return :	   AX - number
;			 CY=1 - error
;GLOBAL TxtNum
TxtNum:  ; PROC NEAR
	PUSH DX
	PUSH BX
	CLD
	PUSH SI
	DW _XOR_BX_BX
TxtNm1:
ES
	LODSB
	SUB AL, '0'
	JB TxtNm3
	CMP AL, 9
	JA TxtNm3
	PUSH AX
	MOV AX, 10
	MUL BX
	DW _MOV_BX_AX
	POP AX
	DW _OR_DX_DX
	JNE TxtNm2
	CBW
	DW _ADD_BX_AX
	JNC TxtNm1
TxtNm2:	MOV BX, 0FFFFh
	JMP TxtNm1
TxtNm3:	DEC SI
	POP AX
	DW _CMP_AX_SI
	CMC
	DW _MOV_AX_BX
	POP BX
	POP DX
	RET
;TxtNum ENDP

;----------------------- Find text ---------------------
;			DS:SI - string
;GLOBAL FndLet
FndLet:  ; PROC NEAR
	LODSB
	CMP AL, ' '
	JE FndLet
	CMP AL, 9
	JE FndLet
	DEC SI
	RET
;FndLet ENDP

; --- continue vcsetup.wasm

;SECTION .DATA
	TIMES ($$-$)&1 DB 0  ; EVEN

Back_C EQU 0
Cursr_C EQU 1
Slct_C EQU 2
CurSl_C EQU 3
Title_C EQU 4
KeyNu_C EQU 5
KeyTi_C EQU 6
Menu_C EQU 7
MnCur_C EQU 8
MnuBx_C EQU 9
MnuTx_C EQU 10
MnuBr_C EQU 11
MnuCu_C EQU 12
MnuCB_C EQU 13
MnuDr_C EQU 14
MnuMi_C EQU 15
Box_C EQU 16
BoxBr_C EQU 17
BoxCu_C EQU 18
Conf_C EQU 19
CnfRe_C EQU 20
CnfBo_C EQU 21
CnfUn_C EQU 22
Hist_C EQU 23
HstCu_C EQU 24
HlBrd_C EQU 25
HlpMn_C EQU 26
Help_C EQU 27
HlpBo_C EQU 28
HlpRe_C EQU 29
HlpUn_C EQU 30
Err_C EQU 31
ErInv_C EQU 32
ErBr_C EQU 33
Clock_C EQU 34
Arrow_C EQU 35
Sky1_C EQU 36
Sky2_C EQU 37
ShadFl EQU 38
Palets	DB 07h,07h,1Bh,07h,07h,07h  ;  0 - Main windows
	DB 70h,70h,30h,70h,70h,70h  ;  1 - Cursor
	DB 0Fh,0Fh,1Eh,0Fh,0Fh,0Fh  ;  2 - Selected files
	DB 7Fh,09h,3Eh,09h,70h,70h  ;  3 - Cursor for selected files
	DB 0Fh,0Fh,1Eh,0Fh,0Fh,0Fh  ;  4 - "Name   Size ..."
	DB 07h,07h,07h,07h,07h,07h  ;  5 - Key bar numbers
	DB 70h,70h,30h,70h,70h,70h  ;  6 - Key bar titles
	DB 70h,70h,30h,70h,70h,70h  ;  7 - Menu bar
	DB 0Fh,0Fh,0Fh,0Fh,0Fh,0Fh  ;  8 - Menu bar cursor
	DB 70h,70h,30h,70h,70h,70h  ;  9 - Menu box border
	DB 70h,70h,3Fh,70h,70h,70h  ; 10 - Menu box text
	DB 7Fh,70h,3Eh,70h,70h,70h  ; 11 - Menu box high letters
	DB 07h,0Fh,0Fh,0Fh,0Fh,0Fh  ; 12 - Menu box text cursor
	DB 0Fh,0Fh,0Eh,0Fh,0Fh,0Fh  ; 13 - Menu box high letters cursor
	DB 70h,70h,30h,70h,70h,70h  ; 14 - Menu box dark lines
	DB 70h,70h,33h,70h,70h,70h  ; 15 - Menu box dark lines '-'
	DB 07h,07h,70h,07h,07h,07h  ; 16 - Function box
	DB 0Fh,0Fh,7Eh,0Fh,0Fh,0Fh  ; 17 - Function box bright
	DB 70h,70h,30h,70h,70h,70h  ; 18 - Function box cursor
	DB 07h,07h,3Fh,07h,07h,07h  ; 19 - Configuration window
	DB 70h,70h,0Fh,70h,70h,70h  ; 20 - Configuration cursor
	DB 0Fh,0Fh,3Eh,0Fh,0Fh,0Fh  ; 21 - Configuration window bright
	DB 7Fh,09h,0Eh,09h,70h,70h  ; 22 - Configuration cursor bright
	DB 70h,70h,3Fh,70h,70h,70h  ; 23 - History window
	DB 07h,07h,0Fh,07h,07h,07h  ; 24 - History cursor
	DB 07h,07h,13h,07h,07h,07h  ; 25 - Menu help border
	DB 70h,70h,30h,70h,70h,70h  ; 26 - Menu help window
	DB 07h,07h,30h,07h,07h,07h  ; 27 - Help window
	DB 0Fh,0Fh,3Fh,0Fh,0Fh,0Fh  ; 28 - Help window bold
	DB 70h,70h,0Fh,70h,70h,70h  ; 29 - Help reversive
	DB 0Fh,09h,3Eh,09h,0Fh,0Fh  ; 30 - Help underline
	DB 07h,07h,4Fh,07h,07h,07h  ; 31 - Error windows
	DB 70h,70h,70h,70h,70h,70h  ; 32 - Error window cursor
	DB 0Fh,0Fh,4Eh,0Fh,0Fh,0Fh  ; 33 - Error window bright
	DB 70h,70h,30h,70h,70h,70h  ; 34 - Clock
	DB 0Fh,0Fh,1Eh,0Fh,0Fh,0Fh  ; 35 - Arrows in view/edit
	DB 07h,07h,0Bh,07h,07h,07h  ; 36 - Screen blank
	DB 0Fh,0Fh,0Fh,0Fh,0Fh,0Fh  ; 37 - Screen blank light stars
	DB 02h,02h,01h,02h,00h,00h  ; 38 - Shadow flag
	DB 02h,02h,02h,02h,02h,02h  ; 39 - Blink / High background / None
DefInit	DB 1  ; FulScr
	DB 0  ; MenuVs
	DB 1  ; KeyBar
	DB 1  ; Prompt
	DB 1  ; InsDwn
	DB 0  ; AutoMnu
	DB 1  ; MiniSta
	DB 0  ; Clock
	DB 1  ; AutoCD
	DB 1  ; AutoSav
	DB 1  ; ColTyp
	DB 5  ; BlDelay
	DB 1  ; LoadFl
	DB 1  ; UnSlct
	DB 1  ; ErrSnd
	DB 0  ; LftMous
	DB 1  ; ZoomWin
	DB 1  ; AltBar
	DB 1  ; EscBar
	DB 0  ; ExecTyp
	DB 0  ; AutoSiz
	DB 1  ; HidDirs
	DB 1  ; QuitAck
	DB 2  ; SnowMod
	DB 1  ; AltView
	DB 1  ; AltEdit
	DB 1  ; ClrBuf
	DB 1  ; Active
	DB 0  ; Ctrl_O
	DB 1  ; ChkTSR
	DB 1  ; ChgTree
	DB 1  ; DriveB
	DB MiliSec, Sec  ; DelayTm
	DB '๚๙'  ; StarTab
TIMES 51 DB 0  ; Reserved
DefWCB	DB 0  ; WinTyp
	DB 0  ; BrfFul
	DB 1  ; Visible
	DB 1  ; Hidden
	DB 0  ; MasTyp
	DB 8  ; SortTyp
	DB 0  ; Ctrl_L
TIMES 13 DB 0  ; DskMas
	DB 'A:\',0  ; WinPath

IniEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW WinBuf
	DW NcPath
	DB 7, 64
	DW Err_S
	DW StFil_S
	DW Inc_S
	DW OkEx_S
IniEr_B	DW IniEr_P, 928h, 0  ; _BOXHD
	    DB 1, 0FFh, 0FFh, 5
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 422h, TmpErr, OkEx_D
	DB 0
OkEx_D	DB 4, 0
	DB 6, 5
	DB 0

%if SHWW_LE_1
Reg1_P	DB Conf_C, CnfRe_C, CnfBo_C, 0
	DB 9, 0
	DW WinBuf
	DW SReg_S  ; ' Register ',0
	DW RN_S  ; 'Registration name',0FFh,23,0
	DW Empty_S  ; '',0
	DW NC_S  ; 'Number of copies',0FFh,24,0
	DW Empty_S  ; '',0
	DW RC_S  ; 'Registration code',0FFh,23,0
	DW Empty_S  ; '',0
	DW 0
	DW OkCn_S  ; String containing OK and Cancel.
Reg1_B	DW Reg1_P, 528h, Reg1Check  ; _BOXHD
	    DB 3, 4, 0FFh, 0
	DB 1, 3, 1, 0, 0  ; _BOXMN
	    DW 305h, TmpBufRRegTo, 28h
	DB 1, 0, 2, 1, 1  ; _BOXMN
	    DW 505h, TmpBufRNumCp, 105h
	DB 1, 1, 3, 2, 2  ; _BOXMN
	    DW 705h, TmpBufRNumCpChar1, 208h
	DB 4, 2, 0, 3, 3  ; _BOXMN  ; Ok / Cancel
	    DW 91Eh, TmpBufROkCancel, OkCn_D
	DB 0  ; End of BOXMNs.

Reg2_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 0
	DW BoxBuf
	DW SReg_S  ; ' Register ',0
	DW Inc_S  ; '^I'
Reg2_V	DW 0
	DW OkMn_S  ; ' Ok ',0
Reg2_B	DW Reg2_P, 0C28h, 0  ; _BOXHD
	    DB 1, 0FFh, 0FFh, 0
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 426h, TmpErr+240, OkMn_D
	DB 0  ; End of BOXMNs.
%endif

MainHlp	DB 1, 2, 3, 4, 4, 4, 5, 6, 7
Main_P	DB Hist_C, 0, 0, 0
	DB 10, 0
	DW WinBuf
	DW SetUp_S
	DW Main1_S
	DW Main2_S
	DW Main3_S
	DW Main4_S
	DW Main5_S
	DW Main6_S
	DW Main7_S
	DW Main8_S
	DW Main9_S
Main_T	DW 4800h, Main10
	DW 5000h, Main11
	DW 4700h, Main12
	DW 4F00h, Main13
	DW 4900h, Main12
	DW 5100h, Main13
	DW 000Dh, Main32
	DW 001Bh, Main31
	DW 4400h, Main31
	DW 3C00h, Main20
	DW 3D00h, Main21
	DW 3E00h, Main22
	DW 3F00h, Main23
	DW 4000h, Main24
	DW 4100h, Main25
	DW 4200h, Main26
	DW 4300h, Main27
	DW 0
Menu_T	DW 1, F02_00
	DW 2, F03_00
	DW 3, F04_00
	DW 4, F05_00
	DW 5, F06_00
	DW 6, F07_00
	DW 7, F08_00
	DW 8, F09_00
	DW 0

OkCn_D	DB 6, 0
	DB 10, 9
	DB 0
Conf_P	DB Conf_C, CnfRe_C, CnfBo_C, 0
	DB 17, 0
	DW WinBuf
	DW Cnf00_S
	DW Cnf01_S
	DW Cnf02_S
	DW Cnf03_S
	DW Cnf04_S
	DW Cnf05_S
	DW Cnf06_S
	DW Cnf07_S
	DW Cnf08_S
	DW Cnf09_S
	DW Cnf10_S
	DW Cnf11_S
	DW Cnf12_S
	DW Cnf13_S
	DW Cnf14_S
	DW 0
	DW OkCn_S
Conf_B	DW Conf_P, 228h, 0  ; _BOXHD
	    DB 1, 4, 1, 0
	DB 3, 18, 1, 0, 10  ; _BOXMN  ; Auto menus
	    DW 30Ah, TmpBuf+ 0, AutoMnu
	DB 3, 0, 2, 1, 11  ; _BOXMN  ; Path prompt
	    DW 40Ah, TmpBuf+ 1, Prompt
	DB 3, 1, 3, 2, 12  ; _BOXMN  ; Key bar
	    DW 50Ah, TmpBuf+ 2, KeyBar
	DB 3, 2, 4, 3, 12  ; _BOXMN  ; Menu bar
	    DW 60Ah, TmpBuf+ 3, MenuVs
	DB 3, 3, 5, 4, 12  ; _BOXMN  ; Full screen
	    DW 70Ah, TmpBuf+ 4, FulScr
	DB 3, 4, 6, 5, 13  ; _BOXMN  ; Clock
	    DW 80Ah, TmpBuf+ 5, Clock
	DB 3, 5, 7, 6, 14  ; _BOXMN  ; Confirm on quit
	    DW 90Ah, TmpBuf+ 6, QuitAck
	DB 3, 6, 8, 7, 15  ; _BOXMN  ; Error sound
	    DW 0A0Ah, TmpBuf+ 7, ErrSnd
	DB 3, 7, 9, 8, 16  ; _BOXMN  ; Auto save setup
	    DW 0B0Ah, TmpBuf+ 8, AutoSav
	DB 3, 8, 10, 9, 17  ; _BOXMN  ; Show logical drive B:
	    DW 0C0Ah, TmpBuf+ 9, DriveB
	DB 3, 9, 11, 0, 10  ; _BOXMN  ; Memory allocation
	    DW 329h, TmpBuf+10, LoadFl
	DB 3, 10, 12, 1, 11  ; _BOXMN  ; Quick execute
	    DW 429h, TmpBuf+11, ExecTyp
	DB 3, 11, 13, 2, 12  ; _BOXMN  ; TSR manager
	    DW 529h, TmpBuf+12, ChkTSR
	DB 3, 12, 14, 5, 13  ; _BOXMN  ; Alt selects menu
	    DW 829h, TmpBuf+13, AltBar
	DB 3, 13, 15, 6, 14  ; _BOXMN  ; Esc toggles on/off
	    DW 929h, TmpBuf+14, EscBar
	DB 3, 14, 16, 7, 15  ; _BOXMN  ; Alternative viewer
	    DW 0A29h, TmpBuf+15, AltView
	DB 3, 15, 17, 8, 16  ; _BOXMN  ; Alternative editor
	    DW 0B29h, TmpBuf+16, AltEdit
	DB 3, 16, 18, 9, 17  ; _BOXMN  ; Clear kbd buffer
	    DW 0C29h, TmpBuf+17, ClrBuf
	DB 4, 17, 0, 17, 18  ; _BOXMN  ; Ok / Cancel
	    DW 111Eh, TmpBuf+18, OkCn_D
	DB 0

Scrn_P	DB Conf_C, CnfRe_C, CnfBo_C, 0
	DB 18, 0
	DW WinBuf
	DW Scr00_S
	DW Scr01_S
	DW Scr02_S
	DW Scr03_S
	DW Scr04_S
	DW Scr05_S
	DW Scr06_S
	DW Scr07_S
	DW Scr08_S
	DW Scr09_S
	DW Scr10_S
	DW Scr11_S
	DW Scr12_S
	DW Scr13_S
	DW Scr14_S
	DW Scr15_S
	DW 0
	DW OkCn_S
Scrn_B	DW Scrn_P, 228h, 0  ; _BOXHD
	    DB 1, 4, 2, 0
	DB 2, 6, 81h, 0, 82h  ; _BOXMN  ; Screen colors
	    DW 30Ah, TmpBuf+0, 3
	DB 2, 0C0h, 6, 1, 3  ; _BOXMN  ; Screen blank delay
	    DW 80Ah, TmpBuf+2, 6
	DB 2, 0C1h, 3, 80h, 2  ; _BOXMN  ; Screen output
	    DW 323h, TmpBuf+4, 3
	DB 3, 0C2h, 4, 81h, 3  ; _BOXMN  ; Zooming boxes
	    DW 823h, TmpBuf+6, ZoomWin
	DB 1, 3, 5, 81h, 4  ; _BOXMN  ; Menu bar visible
	    DW 936h, StarTab , 5
	DB 3, 4, 6, 81h, 5  ; _BOXMN  ; Left-handed mouse
	    DW 0C23h, TmpBuf+7, LftMous
	DB 4, 5, 80h, 6, 6  ; _BOXMN  ; Ok / Cancel
	    DW 121Eh, TmpBuf+9, OkCn_D
	DB 0
Delay_T	DB 40, 20, 5, 3, 1, 0

PanOp_P	DB Conf_C, CnfRe_C, CnfBo_C, 0
	DB 17, 0
	DW WinBuf
	DW Pan00_S
	DW Pan01_S
	DW Pan02_S
	DW Pan03_S
	DW Pan04_S
	DW Pan05_S
	DW Pan06_S
	DW Pan07_S
	DW Pan08_S
	DW Pan09_S
	DW Pan10_S
	DW Pan11_S
	DW Pan12_S
	DW Pan13_S
	DW Pan14_S
	DW 0
	DW OkCn_S
PanOp_B	DW PanOp_P, 228h, F04_10  ; _BOXHD
	    DB 1, 4, 3, 0
	DB 3, 8, 1, 0, 0  ; _BOXMN  ; Mini status
	    DW 30Ah, TmpBuf+0, MiniSta
	DB 3, 0, 2, 1, 1  ; _BOXMN  ; Auto dir size
	    DW 40Ah, TmpBuf+1, AutoSiz
	DB 3, 1, 3, 2, 2  ; _BOXMN  ; Ins moves down
	    DW 50Ah, TmpBuf+2, InsDwn
	DB 3, 2, 4, 3, 3  ; _BOXMN  ; Unselect
	    DW 60Ah, TmpBuf+3, UnSlct
	DB 3, 3, 5, 4, 4  ; _BOXMN  ; Auto change dir
	    DW 90Ah, TmpBuf+4, AutoCD
	DB 3, 4, 6, 5, 5  ; _BOXMN  ; Show hidden dirs
	    DW 0A0Ah, TmpBuf+5, HidDirs
	DB 3, 5, 7, 6, 6  ; _BOXMN  ; Auto rescan tree
	    DW 0B0Ah, TmpBuf+6, ChgTree
	DB 1, 6, 8, 7, 7  ; _BOXMN  ; Delay time
	    DW 0C25h, TmpBuf+9, 5
	DB 4, 7, 0, 8, 8  ; _BOXMN  ; Ok / Cancel
	    DW 111Eh, TmpBuf+7, OkCn_D
	DB 0
NoTim_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 0
	DW BoxBuf
	DW Pan00_S
	DW NoTm1_S
	DW NoTm2_S
	DW OkMn_S
NoTim_B	DW NoTim_P, 0C28h, 0  ; _BOXHD
	    DB 1, 0FFh, 0FFh, 0
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 426h, TmpErr+240, OkMn_D
	DB 0
OkMn_D	DB 4, 0
	DB 0

ColNm_P	DB Back_C
DfCol_P	DB Box_C, BoxCu_C, BoxCu_C, 0
	DB 4, 0
	DW BoxBuf
	DW Color_S
	DW DfCo1_S
	DW DfCo2_S
	DW YesNo_S
DfCol_B	DW DfCol_P, 728h, 0  ; _BOXHD
	    DB 1, 0FFh, 0FFh, 4
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 423h, TmpErr, YesNo_D
	DB 0
Color_T	DW 4800h, F07_40
	DW 5000h, F07_41
	DW 4700h, F07_42
	DW 4F00h, F07_43
	DW 4900h, F07_44
	DW 5100h, F07_48
	DW 4200h, F07_53
	DW 001Bh, F07_57
	DW 4400h, F07_57
	DW 000Dh, Col00
	DW 0

Colr1_T	DB 16,Back_C, 8,Cursr_C, 10,Back_C, 2,Clock_C, 1,Clock_C+80h, 3,Clock_C, 18,0FFh, 0
	DB 1,Back_C, 12,Title_C, 1,Back_C, 9,Title_C, 1,Back_C, 8,Title_C, 1,Back_C, 6,Title_C, 1,Back_C, 18,0FFh, 0
	DB 40,Back_C, 18,0FFh, 0
	DB 57,Back_C, 1,0FFh, 0
	DB 57,Back_C, 1,0FFh, 0
	DB 3,Back_C, 20,Box_C, 34,Back_C, 1,0FFh, 0
	DB 3,Back_C, 20,Box_C, 4,Back_C, 14,Slct_C, 16,Back_C, 1,0FFh, 0
	DB 3,Back_C, 15,Box_C, 4,BoxBr_C, 1,Box_C, 34,Back_C, 1,0FFh, 0
	DB 3,Back_C, 13,Box_C, 3,BoxCu_C, 4,Box_C, 4,Back_C, 14,CurSl_C, 16,Back_C, 1,0FFh, 0
	DB 3,Back_C, 20,Box_C, 34,Back_C, 1,0FFh, 0
	DB 3,Back_C, 20,Box_C, 1,Back_C, 33,Hist_C, 1,0FFh, 0
	DB 5,Back_C, 18,Back_C+40h, 1,Back_C, 33,Hist_C, 1,0FFh, 0
	DB 23,Back_C, 1,Back_C, 8,Hist_C, 20,HstCu_C, 5,Hist_C, 1,0FFh, 0
	DB 23,Back_C, 1,Back_C, 33,Hist_C, 1,0FFh, 0
	DB 1,Back_C, 22,Cursr_C, 1,Back_C, 33,Hist_C, 1,0FFh, 0
	DB 23,Back_C, 1,Back_C, 33,Hist_C, 1,0FFh, 0
	DB 1,Back_C, 22,CurSl_C, 1,Back_C, 33,Hist_C, 1,0FFh, 0
	DB 1,Back_C, 22,Slct_C, 3,Back_C, 31,Back_C+40h, 1,0FFh, 0
	DB 1,Back_C, 22,Slct_C, 4,Back_C, 14,Cursr_C, 16,Back_C, 1,0FFh, 0
	DB 57,Back_C, 1,0FFh, 0
	DB 57,Back_C, 1,0FFh, 0
	DB 4,Back_C, 19,Slct_C, 34,Back_C, 1,0FFh, 0
	DB 57,Back_C, 1,0FFh, 0
	DB 23,0FFh, 34,Back_C, 1,0FFh, 0
	DB 1,KeyNu_C, 6,KeyTi_C, 2,KeyNu_C, 6,KeyTi_C, 2,KeyNu_C, 6,KeyTi_C, 34,Back_C, 1,0FFh, 0
Colr2_T	DB 2,Menu_C, 8,MnCur_C, 47,Menu_C, 1,0FFh, 0
	DB 2,Sky1_C, 25,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 2,MnuTx_C, 1,MnuBr_C, 20,MnuTx_C, 1,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 2,MnuTx_C, 1,MnuBr_C, 20,MnuTx_C, 1,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 2,MnuTx_C, 1,MnuBr_C, 20,MnuTx_C, 1,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 2,MnuTx_C, 1,MnuBr_C, 20,MnuTx_C, 1,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 2,MnuCu_C, 1,MnuCB_C, 20,MnuCu_C, 1,MnuBx_C, 8,Sky1_C, 1,Sky2_C, 21,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 25,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 2,MnuTx_C, 1,MnuBr_C, 20,MnuTx_C, 1,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 3,MnuTx_C, 1,MnuBr_C, 19,MnuTx_C, 1,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 4,MnuTx_C, 1,MnuBr_C, 18,MnuTx_C, 1,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 2,MnuTx_C, 1,MnuBr_C, 20,MnuTx_C, 1,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 2,MnuTx_C, 1,MnuBr_C, 20,MnuTx_C, 1,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 25,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 2,MnuTx_C, 1,MnuBr_C, 20,MnuTx_C, 1,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 1,MnuDr_C, 1,MnuMi_C, 21,MnuDr_C, 1,MnuBx_C, 19,Sky1_C, 1,Sky2_C, 10,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 1,MnuBx_C, 2,MnuTx_C, 1,MnuBr_C, 20,MnuTx_C, 1,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 2,Sky1_C, 25,MnuBx_C, 30,Sky1_C, 1,0FFh, 0
	DB 57,Sky1_C, 1,0FFh, 0
	DB 45,Sky1_C, 1,Sky2_C, 11,Sky1_C, 1,0FFh, 0
	DB 57,Sky1_C, 1,0FFh, 0
	DB 34,Sky1_C, 1,Sky2_C, 22,Sky1_C, 1,0FFh, 0
	DB 57,Sky1_C, 1,0FFh, 0
	DB 57,Sky1_C, 1,0FFh, 0
	DB 57,Sky1_C, 1,0FFh, 0
Colr3_T	DB 12,Menu_C, 45,Conf_C, 1,0FFh, 0
	DB 1,Arrow_C, 11,Back_C, 45,Conf_C, 1,0FFh, 0
	DB 1,Arrow_C, 11,Back_C, 45,Conf_C, 1,0FFh, 0
	DB 1,Arrow_C, 11,Back_C, 8,Conf_C, 14,CnfUn_C, 20,Conf_C, 1,CnfBo_C, 2,Conf_C, 1,0FFh, 0
	DB 12,Back_C, 45,Conf_C, 1,0FFh, 0
	DB 6,Back_C, 51,Err_C, 1,0FFh, 0
	DB 6,Back_C, 51,Err_C, 1,0FFh, 0
	DB 6,Back_C, 51,Err_C, 1,0FFh, 0
	DB 6,Back_C, 51,Err_C, 1,0FFh, 0
	DB 6,Back_C, 44,Err_C, 1,ErInv_C, 6,Err_C, 1,0FFh, 0
	DB 6,Back_C, 51,Err_C, 1,0FFh, 0
	DB 6,Back_C, 49,Err_C, 2,Err_C+40h, 1,0FFh, 0
	DB 8,Back_C, 4,Back_C+40h, 5,Conf_C+40h, 19,Err_C, 8,ErBr_C, 11,Err_C, 2,Conf_C+40h, 1,0FFh, 0
	DB 12,Back_C, 5,Conf_C, 38,Err_C, 2,Conf_C+40h, 1,0FFh, 0
	DB 12,HlBrd_C, 5,Conf_C, 38,Err_C, 2,Conf_C+40h, 1,0FFh, 0
	DB 12,HlpMn_C, 5,Conf_C, 8,Err_C, 8,ErInv_C, 22,Err_C, 2,Conf_C+40h, 1,0FFh, 0
	DB 12,HlpMn_C, 5,Conf_C, 38,Err_C, 2,Conf_C+40h, 1,0FFh, 0
	DB 12,HlpMn_C, 5,Conf_C, 38,Err_C, 2,Conf_C+40h, 1,0FFh, 0
	DB 12,HlpMn_C, 7,Conf_C, 38,Conf_C+40h, 1,0FFh, 0
	DB 12,HlpMn_C, 19,Conf_C, 12,CnfRe_C, 14,Conf_C, 1,0FFh, 0
	DB 12,HlpMn_C, 24,Conf_C, 13,CnfBo_C, 8,Conf_C, 1,0FFh, 0
	DB 12,HlpMn_C, 45,Conf_C, 1,0FFh, 0
	DB 14,HlpMn_C, 20,HlpMn_C+40h, 23,Conf_C, 1,0FFh, 0
	DB 34,HlBrd_C, 23,Conf_C, 1,0FFh, 0
	DB 1,KeyNu_C, 6,KeyTi_C, 2,KeyNu_C, 6,KeyTi_C, 2,KeyNu_C, 6,KeyTi_C, 2,KeyNu_C, 6,KeyTi_C, 2,KeyNu_C, 1,KeyTi_C, 23,Conf_C, 1,0FFh, 0
Colr4_T	DB 58,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 5,Help_C, 16,HlpBo_C, 36,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 24,Help_C, 6,HlpUn_C, 27,Help_C, 1,0FFh, 0
	DB 29,Help_C, 3,HlpUn_C, 25,Help_C, 1,0FFh, 0
	DB 6,Help_C, 5,HlpUn_C, 26,Help_C, 20,HlpRe_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 8,Help_C, 13,HlpBo_C, 36,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 8,Help_C, 18,HlpBo_C, 31,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 12,Help_C, 8,HlpRe_C, 37,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 57,Help_C, 1,0FFh, 0
	DB 32,0FFh, 25,Help_C, 1,0FFh, 0
	DB 32,0FFh, 25,Help_C, 1,0FFh, 0
	DB 58,0FFh, 0

ColPage	TIMES 7 DB 1
TIMES 9 DB 2
TIMES 3 DB 1
TIMES 4 DB 3
TIMES 2 DB 1
TIMES 2 DB 3
TIMES 4 DB 4
TIMES 3 DB 3
TIMES 1 DB 1
TIMES 1 DB 3
TIMES 2 DB 2
TIMES 1 DB 1
PagTab	DW Page1_S, Colr1_T
	DW Page2_S, Colr2_T
	DW Page3_S, Colr3_T
	DW Page4_S, Colr4_T
ColSt_T	DW 4B00h, Col20
	DW 4D00h, Col21
	DW 4800h, Col22
	DW 5000h, Col23
	DW 4700h, Col24
	DW 4F00h, Col25
	DW 4900h, Col26
	DW 5100h, Col27
	DW 4200h, Col28
	DW 000Dh, Col50
	DW 001Bh, Col55
	DW 4400h, Col55
	DW 0

Deflt_P	DB Box_C, BoxCu_C, BoxCu_C, 0
	DB 4, 0
	DW WinBuf
	DW SetUp_S
	DW Def1_S
	DW Def2_S
	DW YesNo_S
Deflt_B	DW Deflt_P, 728h, 0  ; _BOXHD
	    DB 1, 0FFh, 5, 4
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 423h, TmpErr, YesNo_D
	DB 0
YesNo_D	DB 5, 0
	DB 4, 6
	DB 0

Info_P	DB Conf_C, CnfRe_C, CnfBo_C, 0
	DB 18, 0
	DW WinBuf
	DW Inf00_S
	DW Inf01_S
	DW Inf02_S
	DW Inf03_S
	DW Inf04_S
	DW Inf05_S
	DW Inf06_S
	DW Inf07_S
	DW Inf08_S
	DW Inf09_S
	DW Inf10_S
	DW Inf11_S
	DW Inf12_S
	DW Inf13_S
	DW Inf14_S
	DW Inf15_S
	DW 0
	DW Ok_S
Info_B	DW Info_P, 228h, 0  ; _BOXHD
	    DB 1, 4, 6, 0
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 1225h, TmpBuf, Ok_D
	DB 0
Ok_D	DB 6, 0
	DB 0

SvSt_P	DB Box_C, BoxCu_C, BoxCu_C, 0
	DB 4, 0
	DW WinBuf
	DW SvSt0_S
	DW SvSt1_S
	DW SvSt2_S
	DW SvSt3_S
SvSt_B	DW SvSt_P, 528h, 0  ; _BOXHD
	    DB 1, 4, 7, 0
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 420h, TmpBuf, SvSt_D
	DB 0
SvSt_D	DB 6, 0
	DB 8, 7
	DB 0

HlpMn_P	DB Help_C, HlpRe_C, HlpRe_C
Help_P	DB Help_C, HlpRe_C, HlpBo_C, HlpUn_C
HlpMn_D	DB 6, 20
	DB 0
Help_T	DW 4800h, Help30
	DW 5000h, Help32
	DW 4700h, Help35
	DW 4F00h, Help33
	DW 4900h, Help36
	DW 5100h, Help37
	DW 000Dh, Help40
	DW 001Bh, Help40
	DW 4400h, Help40
	DW 0
HlpEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 3, 0
	DW BoxBuf
	DW Help_S
	DW HlEr1_S
	DW OkMn_S
HlpEr_B	DW HlpEr_P, 928h, 0  ; _BOXHD
	    DB 2, 0FFh, 0FFh, 2
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 326h, TmpErr, OkMn_D
	DB 0

Dial_T	DW 0009h, Dial38
	DW 0F00h, Dial55
	DW 4800h, Dial60
	DW 5000h, Dial61
	DW 4B00h, Dial62
	DW 4D00h, Dial63
	DW 4700h, Dial64
	DW 4F00h, Dial68
	DW 4900h, Dial64
	DW 5100h, Dial69
	DW 000Dh, Dial70
	DW 001Bh, Dial81
	DW 4400h, Dial78
	DW 7100h, Dial80
	DW 0

InSt_T	DW 0009h, InSt08
	DW 0F00h, InSt08
	DW 4B00h, InSt07
	DW 4800h, InSt08
	DW 5000h, InSt08
	DW 4900h, InSt08
	DW 5100h, InSt08
	DW 0011h, InSt04
	DW 000Dh, InSt08
	DW 001Bh, InSt08
	DW 4400h, InSt08
	DW 7100h, InSt08
	DW 0

Slct_T	DW 0020h, Slct06
	DW 0009h, Slct13
	DW 0F00h, Slct13
	DW 4B00h, Slct13
	DW 4D00h, Slct13
	DW 4800h, Slct09
	DW 5000h, Slct10
	DW 4700h, Slct12
	DW 4F00h, Slct11
	DW 4900h, Slct12
	DW 5100h, Slct11
	DW 000Dh, Slct05
	DW 001Bh, Slct13
	DW 4400h, Slct13
	DW 0

MnMn_T	DW 4B00h, MnMn24
	DW 4D00h, MnMn26
	DW 0008h, MnMn24
	DW 0020h, MnMn26
	DW 4700h, MnMn28
	DW 4F00h, MnMn29
	DW 0

KeyB_T	DB 1, 0, 0, 0  ;  0
	DB 2, 0, 0, 0  ;  1
	DB 3, 0, 0, 0  ;  2
	DB 4, 0, 0, 0  ;  3
LenKeyB EQU $ - KeyB_T

KeyC_T	DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ;  0
	DB 1, 2, 3, 4, 5, 6, 7, 8, 9, 10  ;  1
	DB 1, 0, 0, 0, 0, 0, 0, 0, 0, 10  ;  2
	DB 1, 0, 0, 0, 0, 0, 0, 8, 0, 10  ;  3
	DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 10  ;  4

EdKeys	DW 0013h, E01_00  ; ^S
	DW 4B00h, E01_00  ; Left
	DW 0004h, E02_00  ; ^D
	DW 4D00h, E02_00  ; Right
	DW 0001h, E03_00  ; ^A
	DW 7300h, E03_00  ; ^Left
	DW 0006h, E04_00  ; ^F
	DW 7400h, E04_00  ; ^Right
	DW 4700h, E05_00  ; Home
	DW 4F00h, E06_00  ; End
	DW 7700h, E05_00  ; ^Home
	DW 7500h, E06_00  ; ^End
	DW 0008h, E07_00  ; BackSpace
	DW 0007h, E08_00  ; ^G
	DW 5300h, E08_00  ; Del
	DW 0019h, E09_00  ; ^Y
	DW 000Bh, E10_00  ; ^K
	DW 0017h, E11_00  ; ^W
	DW 007Fh, E11_00  ; ^BackSpace
	DW 0014h, E12_00  ; ^T
	DW 0011h, E13_00  ; ^Q
	DW 0

CtEn_T	DB ' +:.,><|\',9

;SECTION .CONST
	TIMES ($$-$)&1 DB 0  ; EVEN

	DB 13,10
Init_S	DB 'The ','Volkov Commander',' Setup, Version '  ; PrgName.
%if SHWW_LE_1
	DB '4.05 shareware'  ; VcVers.
%else
	DB '4.05 freeware'  ; VcVers.
%endif
%if SHWW_LE_1
	DB 13,10, 'Copyright (C) 1991-2000 by VVV, Kiev.'
%else
	DB 13,10, 'Copyright (C) 1991-2000 Vsevolod V. Volkov'
%endif
	DB 13,10
	DB 13,10, '$'
Vers_S	DB 13,10, 'This program requires DOS 3.20 or later.'
	DB 13,10, '$'
Aloc_S	DB 13,10, 'Program too big to fit in memory'
	DB 13,10, '$'
Init_F	DB 'VC.INI'
Empty_S	DB 0
NcEnv	DB 'VC='
NcParm	DB 0,'Socha',0
	DW 11Fh

;------------------------ Error ------------------------
Err_S	DB ' Error ',0
StFil_S	DB 'The setup file ^V',0
NoFnd_S	DB 'not found.',0
NoIni_S	DB 'contains data that is not correct.',0
OkEx_S	DB 'Ok',0FFh,3,'Exit',0
Inc_S	DB '^I',0
Var_S	DB '^V',0

; --- Registration menu.
%if SHWW_LE_1
DDReg_S	DB '--REGISTER',0  ; 10 bytes.
SReg_S	DB ' Register ',0
RN_S	DB 'Registration name',0FFh,23,0
NC_S	DB 'Number of copies',0FFh,24,0
RC_S	DB 'Registration code',0FFh,23,0
NCE1_S	DB 'Number of copies',0
NCE2_S	DB 'is empty.',0
RIC1_S	DB 'Invalid characters',0
RIC2_S	DB 'in number of copies.',0
NCZ1_S	DB 'Number of copies',0
NCZ2_S	DB 'must be greater than 0.',0
RCC1_S	DB 'Registration code must',0
RCC2_S	DB 'contain 8 characters.',0
RCI1_S	DB 'Invalid characters',0
RCI2_S	DB 'in registration code.',0
%endif

;---------------------- Main Menu ----------------------
SetUp_S	DB ' Setup ',0
Main1_S	DB 'F2   Configuration', 0FFh,13,0
Main2_S	DB 'F3   Screen and Mouse', 0FFh,10,0
Main3_S	DB 'F4   Panel options', 0FFh,13,0
Main4_S	DB 'F5   Set Black & White palette ',0
Main5_S	DB 'F6   Set Color palette', 0FFh,9,0
Main6_S	DB 'F7   Set Laptop palette', 0FFh,8,0
Main7_S	DB 'F8   Set default configuration ',0
Main8_S	DB 'F9   Country info', 0FFh,14,0
Main9_S	DB 'F10  Exit', 0FFh,22,0

;-------------------- Configuration --------------------
Cnf00_S	DB ' Configuration ',0
Cnf01_S	DB ' ฺ ^bGeneral options^b ',0FFh,80h+10,'ฤฟ  ฺ ^bExecute options^b ' ,0FFh,80h+15,'ฤฟ ',0
Cnf02_S	DB ' ณ  [ ] Auto menus' ,0FFh,11,'ณ  ณ  [ ] Memory allocation' ,0FFh, 9,'ณ ',0
Cnf03_S	DB ' ณ  [ ] Path prompt' ,0FFh,10,'ณ  ณ  [ ] Quick execute commands',0FFh, 4,'ณ ',0
Cnf04_S	DB ' ณ  [ ] Key bar' ,0FFh,14,'ณ  ณ  [ ] TSR manager' ,0FFh,15,'ณ ',0
Cnf05_S	DB ' ณ  [ ] Menu bar visible' ,0FFh, 5,'ณ  ภ' ,0FFh,80h+32,'ฤู ',0
Cnf06_S	DB ' ณ  [ ] Full screen' ,0FFh,10,'ณ  ฺ ^bKeyboard options^b ' ,0FFh,80h+14,'ฤฟ ',0
Cnf07_S	DB ' ณ  [ ] Clock' ,0FFh,16,'ณ  ณ  [ ] Alt alone selects menu',0FFh, 4,'ณ ',0
Cnf08_S	DB ' ณ  [ ] Confirmation on quit ' ,'ณ  ณ  [ ] Esc toggles screen on/off ' ,'ณ ',0
Cnf09_S	DB ' ณ  [ ] Error sound' ,0FFh,10,'ณ  ณ  [ ] Alternative viewer' ,0FFh, 8,'ณ ',0
Cnf10_S	DB ' ณ  [ ] Auto save setup' ,0FFh, 6,'ณ  ณ  [ ] Alternative editor' ,0FFh, 8,'ณ ',0
Cnf11_S	DB ' ณ  [ ] Show logical drive B:ณ  ณ  [ ] Clear keyboard buffer' ,0FFh, 5,'ณ ',0
Cnf12_S	DB ' ภ' ,0FFh,80h+27,'ฤู  ภ' ,0FFh,80h+32,'ฤู ',0
Cnf13_S	DB 'Press ^r Space ^r to change an option, ^r  ^r and ^r  ^r',0
Cnf14_S	DB 'to move between options',0
OkCn_S	DB '[ Ok ]',0FFh,3,'[ Cancel ]',0

;------------------ Screen and Mouse -------------------
Scr00_S	DB ' Screen and Mouse ',0
Scr01_S	DB ' ฺ ^bScreen colors^b ',0FFh,80h+6,'ฤฟ  ฺ ^bScreen output^b ' ,0FFh,80h+14,'ฤฟ ',0
Scr02_S	DB ' ณ  ( ) Black & White  ' ,'ณ  ณ  ( ) Synchronized access' ,0FFh, 4,'ณ ',0
Scr03_S	DB ' ณ  ( ) Color' ,0FFh,10,'ณ  ณ  ( ) Asynchronized access',0FFh, 3,'ณ ',0
Scr04_S	DB ' ณ  ( ) Laptop' ,0FFh,9,'ณ  ณ  ( ) Auto detect' ,0FFh,12,'ณ ',0
Scr05_S	DB ' ภ' ,0FFh,80h+21,'ฤู  ภ' ,0FFh,80h+29,'ฤู ',0
Scr06_S	DB ' ฺ ^bScreen blank delay^b ','ฤฟ  ฺ ^bOther options^b ',0FFh,80h+14,'ฤฟ ',0
Scr07_S	DB ' ณ  ( ) 40 minutes' ,0FFh, 5,'ณ  ณ  [ ] Zooming boxes' ,0FFh,10,'ณ ',0
Scr08_S	DB ' ณ  ( ) 20 minutes' ,0FFh, 5,'ณ  ณ  Screen saver chars:' ,0FFh, 8,'ณ ',0
Scr09_S	DB ' ณ  ( )  5 minutes' ,0FFh, 5,'ณ  ภ' ,0FFh,80h+29,'ฤู ',0
Scr10_S	DB ' ณ  ( )  3 minutes' ,0FFh, 5,'ณ  ฺ ^bMouse options^b ',0FFh,80h+14,'ฤฟ ',0
Scr11_S	DB ' ณ  ( )  1 minute' ,0FFh, 6,'ณ  ณ  [ ] Left-handed mouse' ,0FFh, 6,'ณ ',0
Scr12_S	DB ' ณ  ( ) Off' ,0FFh,12,'ณ  ภ' ,0FFh,80h+29,'ฤู ',0
Scr13_S	DB ' ภ' ,0FFh,80h+21,'ฤู',0FFh,34,0
Scr14_S	DB 'Press ^r Space ^r to change an option, ^r  ^r and ^r  ^r',0
Scr15_S	DB 'to move between options',0

;-------------------- Panel options --------------------
Pan00_S	DB ' Panel options ',0
Pan01_S	DB ' ฺ ^bFile panel options^b ' ,0FFh,80h+18,'ฤฟ ',0
Pan02_S	DB ' ณ  [ ] Mini status line' ,0FFh,16,'ณ ',0
Pan03_S	DB ' ณ  [ ] Auto directory size' ,0FFh,13,'ณ ',0
Pan04_S	DB ' ณ  [ ] Ins moves down' ,0FFh,18,'ณ ',0
Pan05_S	DB ' ณ  [ ] Unselect during group operation ' ,'ณ ',0
Pan06_S	DB ' ภ' ,0FFh,80h+38,'ฤู ',0
Pan07_S	DB ' ฺ ^bTree panel options^b ' ,0FFh,80h+18,'ฤฟ ',0
Pan08_S	DB ' ณ  [ ] Auto change directory' ,0FFh,11,'ณ ',0
Pan09_S	DB ' ณ  [ ] Show hidden subdirectories',0FFh, 6,'ณ ',0
Pan10_S	DB ' ณ  [ ] Auto rescan tree' ,0FFh,16,'ณ ',0
Pan11_S	DB ' ณ  Auto change dir time delay:' ,0FFh, 9,'ณ ',0
Pan12_S	DB ' ภ' ,0FFh,80h+38,'ฤู ',0
Pan13_S	DB 'Press ^r Space ^r to change an option,',0
Pan14_S	DB 'arrows to move between options',0
NoTm1_S	DB 'Illegal format of',0
NoTm2_S	DB 'auto change dir time delay.',0
OkMn_S	DB ' Ok ',0

;------------- Set Black & White palette ---------------
Color_S	DB ' Color Setup ',0
Mode_S	DB 'Mode: ',0
Palet_S	DB 'Palette: ',0
BwPal_S	DB 'Black&White',0
LapTp_S	DB 'LapTop',0
ColMd_S	DB 'Color',0
MonMd_S	DB 'Monochrome',0
DfCo1_S	DB 'Do you wish to set default colors',0
DfCo2_S	DB 'for current palette?',0
Colrs_S	DB 'Panels',0
	DB 'Current pointer',0
	DB 'Selected files',0
	DB 'Selected pointer',0
	DB 'Title in file panel',0
	DB 'Key bar numbers',0
	DB 'Key bar text',0
	DB 'Pull-down menu bar',0
	DB 'Pull-down menu pointer',0
	DB 'Pull-down menu border',0
	DB 'Pull-down menu text',0
	DB 'Pull-down menu bright',0
	DB 'Pull-down menu current bar',0
	DB 'Pull-down menu current bright',0
	DB 'Pull-down menu unaccessable lines',0
	DB 'Pull-down menu minus',0
	DB 'Dialog box text',0
	DB 'Dialog box bright text',0
	DB 'Dialog box reverse text',0
	DB 'Configuration boxes text',0
	DB 'Configuration boxes reverse text',0
	DB 'Configuration boxes bright text',0
	DB 'Configuration boxes bright reverse text',0
	DB 'History box text',0
	DB 'History box pointer',0
	DB 'Mini help in .EXT file editor border',0
	DB 'Mini help in .EXT file editor text',0
	DB 'Help box text',0
	DB 'Help box bright text',0
	DB 'Help box reverse text',0
	DB 'Help box underline text',0
	DB 'Error box text',0
	DB 'Error box reverse text',0
	DB 'Error box bright text',0
	DB 'Clock',0
	DB 'Arrows in viewer and editor',0
	DB 'Stars',0
	DB 'Explosing stars',0
	DB 'Shadow',0
	DB 0
On_S	DB 'on ^I',0
ColNm_S	DB 'Black',0
	DB 'Blue',0
	DB 'Green',0
	DB 'Cyan',0
	DB 'Red',0
	DB 'Magenta',0
	DB 'Brown',0
	DB 'White',0
	DB 'Gray',0
	DB 'Bright Blue',0
	DB 'Bright Green',0
	DB 'Bright Cyan',0
	DB 'Bright Red',0
	DB 'Pink',0
	DB 'Yellow',0
	DB 'Bright White',0
	DB 'No shadow',0
	DB 'Inv brightness',0

;---------------------- Set color ----------------------
Page1_S	DB 'ษออออออออออออัออ C:\DOS ออออออออัอ 4:55p                  '
	DB 'บ    Name    ณ   Size  ณ  Date  ณ Time บ                  '
	DB 'บ..          ณUP--DIRณ10-29-91ณ 2:55pบ                  '
	DB 'บcommand  comณ    54619ษออออออออออออออออ Tree อออออออออออ '
	DB 'บappend   exeณ     8170บ \                                '
	DB 'บas                    บ รฤฤDOS                           '
	DB 'บat   ษออออออ Drive letบ รฤÝVC          Þ                 '
	DB 'บba   บ    Choose left บ รฤฤTOOLS                         '
	DB 'บch   บ  A   B   C   D บ รฤÝARC         Þ                 '
	DB 'บch   ศออออออออออออออออบ รฤฤTEST                          '
	DB 'บco                    บ                                  '
	DB 'บdebug    exeณ    15718บ   ษอออออออ User Menu อออออออป    '
	DB 'บdeltree  exeณ     7930บ   บ F1  Archives...         บ    '
	DB 'บdiskcomp comณ     7249บ   บ F2  Format floppy disk  บ    '
	DB 'บdiskcopy comณ     8763บ   บ F4  Edit file           บ    '
	DB 'บdoskey   comณ     4729บ   ศอออออออออออออออออออออออออผ    '
	DB 'บedlin    exeณ    10007บ                                  '
	DB 'บexe2bin  exeณ     6755บ รฤฤDOCS                          '
	DB 'บexpand   exeณ    16129บ ภฤ TMP                           '
	DB 'บfasthelp exeณ     8199บ                                  '
	DB 'วฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤบ                                  '
	DB 'บ   32,891 bytes in 3 sบ                                  '
	DB 'ศออออออออออออออออออออออบ                                  '
	DB 'C:\DOS>                วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ '
	DB '1Help   2Menu   3View  บC:\DOS                            '
Page2_S	DB '    Left    Files    Commands    Options    Right         '
	DB '  ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ                               '
	DB '  ณ  Brief                ณ                ๚         ๚    '
	DB '  ณ  Full                 ณ                               '
	DB '  ณ  Info                 ณ       ๚                       '
	DB '  ณ  Tree                 ณ                               '
	DB '  ณ๛ On/Off       Ctrl-F1 ณ                      ๚       '
	DB '  ณ ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ ณ                               '
	DB '  ณ  Name                 ณ                               '
	DB '  ณ  eXtension            ณ                               '
	DB '  ณ  tiMe                 ณ                               '
	DB '  ณ  Size                 ณ            ๚                  '
	DB '  ณ  Unsorted             ณ                        ๚      '
	DB '  ณ ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ ณ                               '
	DB '  ณ  Re-read              ณ                               '
	DB '  ณ -fiLter...            ณ                              '
	DB '  ณ  Drive...     Alt-F1  ณ                               '
	DB '  ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู          ๚                    '
	DB '                                                   ๚      '
	DB '                                             ๙            '
	DB '                          ๚                               '
	DB '       ๚                                                 '
	DB '                                                          '
	DB '                    ๚                    ๚                '
	DB '                                                          '
Page3_S	DB 'Edit: C:\VC\                                              '
	DB 'asm:    tas   ษอออออออออออ Choose Directory อออออออออออป '
	DB 'obj:    lin   บ  รฤฤTOOLS                              บ '
	DB 'sys:    dl    บ  รฤ ARC                               บ '
	DB 'zip:    pkun   บ  รฤฤTEST                               บ '
	DB 'arc:                                                      '
	DB 'ice:     ษออออออออออออออออออ Error ออออออออออออออออออป    '
	DB "lzh:     บ      Can't read the disk in drive A:      บ    "
	DB 'arj:     บ  Press ENTER to try again, ESC to abort,  บ    '
	DB '         บ or enter a different drive letter here A: บ    '
	DB '         ศอออออออ                                         '
	DB '                    ษอออออออออออ Delete อออออออออออป      '
	DB '               บ    บ       You are DELETING       บ    บ '
	DB '               บ    บ 5 files and 1 directory from บ    บ '
	DB 'ÜÜÜÜÜÜÜÜÜÜÜÜ   บ    บ            C:\TMP            บ    บ '
	DB ' ษออออออออออ   บ    บ     Delete   All   Cancel    บ    บ '
	DB ' บ Format of   บ    ศออออออออออออออออออออออออออออออผ    บ '
	DB ' บ             วฤ                                      ฤถ '
	DB " บ ' comment   บ C:\ARC                                 บ "
	DB ' บ txt: edit   บ Speed search: ARC                      บ '
	DB ' บ     cls    ศออออออออออออออออออฺ Screen colors ฤฤฤฤฤฤฟ '
	DB ' บ  ภฤฤฤฤฤฤฤ                      ณ  ( ) Black & White  ณ '
	DB ' ศออออออออออออออออออออออออออออออออณ  () Color          ณ '
	DB '฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿ณ  ( ) Laptop         ณ '
	DB '1Help   2Save   3       4Hex    5 ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู '
Page4_S	DB '                                                          '
	DB '                                                          '
	DB '   ษอออออออออออออออออออออออออออออ Help ออออออออออออออออออ '
	DB '   บ Configuration...                                     '
	DB '   วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ   ษอออออออออออออออออออออ '
	DB '   บ  This dialog box  allows yo   บ               The Vo '
	DB '   บ  options.  Use the cursor k   วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ '
	DB '   บ  to change, and use the Spa   บ  About the Commander '
	DB '   บ  Enter to accept the dialog   บ  Keyboard reference  '
	DB '   บ                               บ  View -- Keyboard re '
	DB '   บ  ฺ Screen colors ฤฤฤฤฤฤฟ  T   บ  View -- Status line '
	DB '   บ  ณ  ( ) Black & White  ณ  w   บ  Edit -- Keyboard re '
	DB '   บ  ณ  () Color          ณ  t   บ  Edit -- Status line '
	DB '   บ  ณ  ( ) Laptop         ณ  l   บ  Left/Right menu     '
	DB '   บ  ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู  c   บ       Brief/Full     '
	DB '   บ                               บ       Info           '
	DB '   บ  ฺ Screen blank delay ฤฟ  T   บ       Tree           '
	DB '   บ  ณ  ( ) 40 minutes     ณ  b   บ       On/Off         '
	DB '   วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ   บ       Sorting order  '
	DB '   บ        [ Next ]   [ Previou   บ       Re-read a pane '
	DB '   ศออออออออออออออออออออออออออออ   วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ '
	DB '                                   บ                      '
	DB '                                   ศอออออออออออออออออออออ '
	DB '                                                          '
	DB '                                                          '

;-------------- Set default configuration --------------
Def1_S	DB 'Do you wish to reset all options',0
Def2_S	DB 'to default value?',0
YesNo_S	DB 'Yes',0FFh,3,'No',0

;-------------------- Country info ---------------------
Inf00_S	DB ' Country info ',0
Inf01_S	DB ' ฺ ^bTime format^b ฤฟ ฺ ^bDate format^b ฤฤฟ ฺ ^bNumbers format^b ฤฟ ',0
Inf02_S	DB ' ณ             ', ' ณ ณ              ', ' ณ ณ                ', ' ณ ',0
Inf03_S	DB ' ภ',0FFh,80h+14, 'ฤู ภ',0FFh,80h+15, 'ฤู ภ',0FFh,80h+17, 'ฤู ',0
Inf04_S	DB ' ฺ ^bCharacters table^b ' ,0FFh,80h+34, 'ฤฟ ',0
Inf05_S	DB ' ณ',0FFh,6, '€…‘’“”•–— กขฃคฅฆง' ,0FFh,6,'ณ ',0
Inf06_S	DB ' ณ',0FFh,3,'ฺฤ                                        ' ,0FFh,6,'ณ ',0
Inf07_S	DB ' ณ',0FFh,3,'ณ                                          ฤฟ',0FFh,3,'ณ ',0
Inf08_S	DB ' ณ',0FFh,3,'ณ' ,0FFh,44,'ณ',0FFh,3,'ณ ',0
Inf09_S	DB ' ณ',0FFh,3,'ณ  จฉชซฌญฎฏเแโใไๅๆ็่้๊๋์ํ๎๏๐๑๒๓๔๕๖๗๘๙๚๛üýþ   ณ',0FFh,3,'ณ ',0
Inf10_S	DB ' ณ',0FFh,3,'รฤ                                          ณ',0FFh,3,'ณ ',0
Inf11_S	DB ' ณ',0FFh,3,'ณ                                          ฤด',0FFh,3,'ณ ',0
Inf12_S	DB ' ณ',0FFh,3,'ภฤฤฤฤ ^bUpper case',0FFh,14,'Lower case^b ฤฤฤฤู',0FFh,3,'ณ ',0
Inf13_S	DB ' ภ',0FFh,80h+52, 'ฤู ',0
Inf14_S	DB 'The country information is determined by',0
Inf15_S	DB 'the ^bcountry=^b statement in the ^bconfig.sys^b file.',0
Ok_S	DB '[ Ok ]',0

;------------------------ Exit -------------------------
SvSt0_S	DB ' Setup ',0
SvSt1_S	DB 'Do you wish to save',0
SvSt2_S	DB 'the current setup?',0
SvSt3_S	DB 'Save',0FFh,3,'Cancel',0
StErr_S	DB 'There was an error while saving the setup file',13,10,'$'

Help_F	DB 'VC.HLP',0
HlpHead	DB 'VC 4.05 Help' ,0  ; HelpVer.
HlpEr_S	DB 'Error reading data from the help file.',13,10,'$'
Help_S	DB ' Help ',0
HlEr1_S	DB 'Help contents is not available',0

Key_S	DB '      '  ;  0
	DB 'Help  '  ;  1
	DB 'Config'  ;  2
	DB 'Screen'  ;  3
	DB 'Panels'  ;  4
	DB 'B&W   '  ;  5
	DB 'Color '  ;  6
	DB 'Laptop'  ;  7
	DB 'Reset '  ;  8
	DB 'Cntry '  ;  9
	DB 'Quit  '  ; 10

;SECTION .DATA?
	ABSOLUTE $
	RESB ($$-$)&1  ; EVEN

IniData	RESB 3  ; 'VVV' header
WCB1	RESB WCBdef_size  ; Left window control block
WCB2	RESB WCBdef_size  ; Right window control block
ColTab	RESB 6*LenColr  ; Color table (6 pallets)
FulScr	RESB 1  ; Full screen
MenuVs	RESB 1  ; Menu always visible
KeyBar	RESB 1  ; Key bar
Prompt	RESB 1  ; Path prompt
InsDwn	RESB 1  ; Ins moves down
AutoMnu	RESB 1  ; Auto user menus
MiniSta	RESB 1  ; Mini status
Clock	RESB 1  ; Clock
AutoCD	RESB 1  ; Auto change dir
AutoSav	RESB 1  ; Auto save setup
ColTyp	RESB 1  ; Monochrome / Color / LapTop
BlDelay	RESB 1  ; Screen blank delay
LoadFl	RESB 1  ; Small mode
UnSlct	RESB 1  ; Unselect files when group operation
ErrSnd	RESB 1  ; Beep when error
LftMous	RESB 1  ; Left handed mouse
ZoomWin	RESB 1  ; Zomming windows
AltBar	RESB 1  ; Alt alone selects menu
EscBar	RESB 1  ; Esc toggles panels on/off
ExecTyp	RESB 1  ; Exec command without COMMAND.COM
AutoSiz	RESB 1  ; Auto calculate directory sizes
HidDirs	RESB 1  ; Show hidden subdirs in tree panel
QuitAck	RESB 1  ; Confirmation on Quit
SnowMod	RESB 1  ; Snow mode (2=auto)
AltView	RESB 1  ; Alt-F3 - external viewer
AltEdit	RESB 1  ; Alt-F4 - external editor
ClrBuf	RESB 1  ; Clear buffer flag
Active	RESB 1  ; Active panel
Ctrl_O	RESB 1  ; Visible status of unactive panel
ChkTSR	RESB 1  ; TSR manager
ChgTree	RESB 1  ; Auto rescan tree
DriveB	RESB 1  ; Show logical drive B:
DelayTm	RESB 2  ; Auto change dir delay time
StarTab	RESB 5  ; Star table
RRegTo	RESB 29h  ; Registered user name, NUL-padded, at least 1 NUL
RNumCp	RESB 6  ; Registered number of copies, ASCII decimal, NUL-padded, at least 1 NUL
RChkSum	RESW 2  ; Checksum covering RRegTo and RNumCp
CmnIni EQU $ - ColTab  ; Sise of main data' part of VC.INI
LoadRes	RESB 1  ; Original LoadFl
	RESB 1  ; Check sum, starts at the previous byte.
IniLen EQU $ - IniData  ; Length of VC.INI
	RESB 1

IniStat	RESB 1  ; 0 - not found, 1 - Ok, 2 - bad
MnItem	RESB 1  ; Item of main menu
CurType	RESW 1  ; Shape of cursor
SrcIni	RESB CmnIni  ; Source VC.INI

ScrMod	RESB 1  ; Screen mode
Mouse	RESB 1  ; 1 if Mouse was found
BreakFl	RESB 1  ; Break DOS's status
DosLin	RESB 1  ; Line number of DOS's command line
ScrPage	RESB 1  ; Current screen page number
TstEGA	RESB 1  ; 1 if EGA or VGA present
Lines	RESB 1  ; Number of lines on screen
Snow	RESB 1  ; Snow on/off
TopView	RESB 1  ; TopView output
DesqVie	RESB 1  ; running under DESQVIEW
Quote	RESB 1  ; Quote next character
BarPrev	RESB 1  ; Previous Key Bar
WinMous	RESB 1
MousEnt	RESB 1
HlpPage	RESB 1
BackC	RESB 1
HistC	RESB 1
HstCuC	RESB 1
ColCur	RESW 1
ColFrst	RESW 1
ColNum	RESW 1
Rand1	RESW 1
Rand2	RESW 1
MousPos	RESW 1
MousTim	RESW 2
AutoTim	RESW 2
Screen	RESW 2  ; Address of screen
BrkVct	RESW 2  ; Original vector 1Bh
NcPath	RESB LenPath+13  ; The path from VC= variable
Country	RESB CNTRY_size  ; Country information
LowTab	RESB 128  ; Lower case table
TmpBuf	RESB 256
TmpBufRRegTo EQU TmpBuf+0  ; Used by the Reg1 dialog box.
TmpBufRNumCp EQU TmpBuf+30h  ; Used by the Reg1 dialog box.
TmpBufRNumCpChar1 EQU TmpBuf+40h  ; Used by the Reg1 dialog box.
TmpBufROkCancel EQU TmpBuf+50h  ; Used by the Reg1 dialog box.
TmpErr	RESB 256
Stars	RESW 2*NmbStrs
ScrBuf	RESW MaxLins * 80
UserScr	RESW MaxLins * 80
WinBuf	RESW (MaxLins-2) * 77
BoxBuf	RESW (MaxLins-2) * 77
HelpBuf	RESB HlpData_size

; __END__
