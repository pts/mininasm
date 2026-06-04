; -*- coding: cp437 -*-
;
; vcm.nasm: assembly source of vc.com in Volkov Commander 4.05
; ported to multiple assemblers by pts@fazekas.hu at 2026-05-24 09:51:59 CEST
; based on assembly source files written by Vsevolod V. Volkov in 1991--2000
;   downloaded from https://vc.vvv.kyiv.ua/download/src/vc405.zip
;
;; This is an 8086 (i86) assembly source file compatible with NASM >=0.98.39
;; and https://github.com/pts/mininasm .
;
; Compilation commands:
;
;   nasm -O9999 -o vc.com vcm.nasm
;   nasm -O9999 -DSHW=1 -o vcs.com vcm.nasm
;   nasm -O9999 -DSHW=3 -o vcf.com vcm.nasm
;   mininasm -O9999 -o vc.com vcm.nasm
;   mininasm -O9999 -DSHW=1 -o vcs.com vcm.nasm
;   mininasm -O9999 -DSHW=3 -o vcf.com vcm.nasm
;
; vc.com is the freeware variant, vcs.com is the shareware variant, vcf.com
; is the freeware variant with some unused code removed.
;

;-------------------------------------------------------
;		   Idea :	15.05.1991
;		  Begin :	16.05.1991
;		Version :	16.06.2000
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
;%define HelpVer 'VC 4.05 Help'
;%define VcVers '4.05'
;%if SHWW_LE_1
;%define VcSuff 'shareware'
;%else
;%define VcSuff 'freeware'
;%endif
VcApiVr EQU 42

MoDelay EQU 40  ; Mouse double click delay
MiliSec EQU 60  ; auto CD time : sec x 0.01
Sec EQU 0  ;                sec x 1
LenStk EQU 100h  ; Stack size
LenPath EQU 68  ; Length of path name
LenColr EQU 40  ; Length of color table
LenHist EQU 512  ; Length of hisory buffer
LenExt EQU 512  ; Length of extension file buffer
LenMenu EQU 4000  ; Length of menu buffer
LenStr EQU 64  ; Length of path & file string
LenCmd EQU 124  ; Length of command line
LenBat EQU 1000  ; Length of full command line
LenHelp EQU 3000  ; Maximal length of help page
MinFls EQU 256  ; Minimum files in window
MinTree EQU 768  ; Minimum tree size
MinView EQU 8000  ; Minimum view buffer size
MaxLins EQU 50  ; Maximum screen lines
MaxProg EQU 18  ; Maximal resident quantaty
NmbStrs EQU 32  ; Number of stars

;------------------ Global structures ------------------

; DTA structure definition.
DTAs:  ; STRUC
	; RESB 15h
.FilAttr: EQU 0+(15h)  ; RESB 1
.FilTime: EQU .FilAttr+(1)  ; RESW 1
.FilDate: EQU .FilTime+(1)*2  ; RESW 1
.FilSize: EQU .FilDate+(1)*2  ; RESW 2
.FilName: EQU .FilSize+(2)*2  ; RESB 13
	; RESB 1
DTAs_size: EQU .FilName+(13)+(1)  ; ENDSTRUC

; Execute program block structure definition.
EPBs:  ; STRUC
.EnvSeg: EQU 0  ; RESW 1  ; Segment of new environment
.CmdLine: EQU .EnvSeg+(1)*2  ; RESW 2  ; Pointer to command line
.FCB1: EQU .CmdLine+(2)*2  ; RESW 2  ; Pointer to FCB1
.FCB2: EQU .FCB1+(2)*2  ; RESW 2  ; Pointer to FCB2
EPBs_size: EQU .FCB2+(2)*2  ; ENDSTRUC

; Country information structure definition.
CNTRY:  ; STRUC
.DateFmt: EQU 0  ; RESW 1  ; Date format
	; RESB 5  ; Currency
.Sep1000: EQU .DateFmt+(1)*2+(5)  ; RESB 2  ; Thousand separator
	; RESB 2  ; Decimal separator
.DateSep: EQU .Sep1000+(2)+(2)  ; RESB 2  ; Date separator
.TimeSep: EQU .DateSep+(2)  ; RESB 2  ; Time separator
	; RESB 1  ; Currency format
	; RESB 1  ; Number of meaning digits in currency
.TimeFmt: EQU .TimeSep+(2)+(1)+(1)  ; RESB 1  ; Time format
.CaseMp: EQU .TimeFmt+(1)  ; RESW 2  ; Addres of case map. Far pointer.
	; RESB 2  ; Data separator
	; RESB 8  ; Reserved
CNTRY_size: EQU .CaseMp+(2)*2+(2)+(8)  ; ENDSTRUC

; File entry in DskBuf.
FILENT:  ; STRUC
.NameF: EQU 0  ; RESB 13
.AttrF: EQU .NameF+(13)  ; RESB 1
.TimeF: EQU .AttrF+(1)  ; RESW 1
.DateF: EQU .TimeF+(1)*2  ; RESW 1
.SizeF: EQU .DateF+(1)*2  ; RESW 2
.NumbF: EQU .SizeF+(2)*2  ; RESW 1
FILENT_size: EQU .NumbF+(1)*2  ; ENDSTRUC

; Subdirectory entry of NCD file.
DIRENT:  ; STRUC
.DirName: EQU 0  ; RESB 13  ; Subdirectory name in ASCIIZ
.DirLevel: EQU .DirName+(13)  ; RESB 1  ; Subdirectory level
.DirShift: EQU .DirLevel+(1)  ; RESB 1  ; 1 in next entry - there is branch
.DirCont: EQU .DirShift+(1)  ; RESB 1  ; 0 - end of branch 'À', 1 - 'Ã'
DIRENT_size: EQU .DirCont+(1)  ; ENDSTRUC
DirRecu EQU DIRENT.DirName+12  ; BYTE PTR.

; Structure of NCD file.
DIRTREE:  ; STRUC
.TreHead: EQU 0  ; RESB 5  ; Tree file header 'PNCI',0
.TreeLen: EQU .TreHead+(5)  ; RESW 1  ; Number of subdirectories
.TreSum1: EQU .TreeLen+(1)*2  ; RESW 1  ; Check sum of the header
.TreSum2: EQU .TreSum1+(1)*2  ; RESW 1  ; Check sum of the list
DIRTREE_size: EQU .TreSum2+(1)*2  ; ENDSTRUC
DIRTREE_TreList EQU DIRTREE.TreSum2  ; BYTE PTR. List of subdirectories
TreeErr EQU DIRTREE.TreHead+0  ; BYTE PTR.
TreeLev EQU DIRTREE.TreHead+1  ; BYTE PTR.

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

;--------------------- Data segment --------------------
MD:  ; STRUC  ; Name used to be MainDat, but TASM 3.2 fails with `Out of memory' if used too much with such a long name.
.ColTab: EQU 0  ; RESB 6*LenColr  ; Color table (6 pallets)
.FulScr: EQU .ColTab+(6*LenColr)  ; RESB 1  ; Full screen
.MenuVs: EQU .FulScr+(1)  ; RESB 1  ; Menu always visible
.KeyBar: EQU .MenuVs+(1)  ; RESB 1  ; Key bar
.Prompt: EQU .KeyBar+(1)  ; RESB 1  ; Path prompt
.InsDwn: EQU .Prompt+(1)  ; RESB 1  ; Ins moves down
.AutoMnu: EQU .InsDwn+(1)  ; RESB 1  ; Auto user menus
.MiniSta: EQU .AutoMnu+(1)  ; RESB 1  ; Mini status
.Clock: EQU .MiniSta+(1)  ; RESB 1  ; Clock
.AutoCD: EQU .Clock+(1)  ; RESB 1  ; Auto change dir
.AutoSav: EQU .AutoCD+(1)  ; RESB 1  ; Auto save setup
.ColTyp: EQU .AutoSav+(1)  ; RESB 1  ; Monochrome / Color / LapTop
.BlDelay: EQU .ColTyp+(1)  ; RESB 1  ; Screen blank delay
.LoadFl: EQU .BlDelay+(1)  ; RESB 1  ; Small mode
.UnSlct: EQU .LoadFl+(1)  ; RESB 1  ; Unselect files when group operation
.ErrSnd: EQU .UnSlct+(1)  ; RESB 1  ; Beep when error
.LftMous: EQU .ErrSnd+(1)  ; RESB 1  ; Left handed mouse
.ZoomWin: EQU .LftMous+(1)  ; RESB 1  ; Zomming windows
.AltBar: EQU .ZoomWin+(1)  ; RESB 1  ; Alt alone selects menu
.EscBar: EQU .AltBar+(1)  ; RESB 1  ; Esc toggles panels on/off
.ExecTyp: EQU .EscBar+(1)  ; RESB 1  ; Exec command without COMMAND.COM
.AutoSiz: EQU .ExecTyp+(1)  ; RESB 1  ; Auto calculate directory sizes
.HidDirs: EQU .AutoSiz+(1)  ; RESB 1  ; Show hidden subdirs in tree panel
.QuitAck: EQU .HidDirs+(1)  ; RESB 1  ; Confirmation on Quit
.SnowMod: EQU .QuitAck+(1)  ; RESB 1  ; Snow mode (2=auto)
.AltView: EQU .SnowMod+(1)  ; RESB 1  ; Alt-F3 - external viewer
.AltEdit: EQU .AltView+(1)  ; RESB 1  ; Alt-F4 - external editor
.ClrBuf: EQU .AltEdit+(1)  ; RESB 1  ; Clear buffer flag
.Active: EQU .ClrBuf+(1)  ; RESB 1  ; Active panel
.Ctrl_O: EQU .Active+(1)  ; RESB 1  ; Visible status of unactive panel
.ChkTSR: EQU .Ctrl_O+(1)  ; RESB 1  ; TSR manager
.ChgTree: EQU .ChkTSR+(1)  ; RESB 1  ; Auto rescan tree
.DriveB: EQU .ChgTree+(1)  ; RESB 1  ; Show logic drive B: in 1 floppy system
.DelayTm: EQU .DriveB+(1)  ; RESB 2  ; Auto change dir delay time
.StarTab: EQU .DelayTm+(2)  ; RESB 5  ; Star table
.RRegTo: EQU .StarTab+(5)  ; RESB 29h  ; Registered user name, NUL-padded, at least 1 NUL
.RNumCp: EQU .RRegTo+(29h)  ; RESB 6  ; Registered number of copies, ASCII decimal, NUL-padded, at least 1 NUL
.RChkSum: EQU .RNumCp+(6)  ; RESW 2  ; Checksum covering RRegTo and RNumCp
.LoadRes: EQU .RChkSum+(2)*2  ; RESB 1  ; Original LoadFl
.ScrMod: EQU .LoadRes+(1)  ; RESB 1  ; Current screen mode
.Mouse: EQU .ScrMod+(1)  ; RESB 1  ; 1 if Mouse was found
.BreakFl: EQU .Mouse+(1)  ; RESB 1  ; Break DOS's status
.MenuFl: EQU .BreakFl+(1)  ; RESB 1  ; 1 to bring user menu automatically
.SelMas: EQU .MenuFl+(1)  ; RESB 13  ; Wildcard for selection
.HstBuf: EQU .SelMas+(13)  ; RESB LenHist  ; History buffer
.ExtMain: EQU .HstBuf+(LenHist)  ; RESB LenExt  ; Buffer for the main extension file
.EPB: EQU .ExtMain+(LenExt)  ; RESB EPBs_size  ; Execute program block
.MouseX: EQU .EPB+(EPBs_size)  ; RESW 1  ; Mouse cursor X
.MouseY: EQU .MouseX+(1)*2  ; RESW 1  ; Mouse cursor Y
.BatAdr: EQU .MouseY+(1)*2  ; RESW 1  ; Pointer to command in buffer
.BatPoin: EQU .BatAdr+(1)*2  ; RESW 1  ; Pointer to command
.LastMnu: EQU .BatPoin+(1)*2  ; RESW 1  ; The last pull down menu item
.OvlPth: EQU .LastMnu+(1)*2  ; RESW 1  ; Pointer to file name in environment
.ComSpec: EQU .OvlPth+(1)*2  ; RESW 1  ; Pointer to COMSPEC= in environment
.CrnPath: EQU .ComSpec+(1)*2  ; RESB LenPath  ; Current directory in the tree panel
.ViewFil: EQU .CrnPath+(LenPath)  ; RESB LenStr+1  ; Source filename
.ToFile: EQU .ViewFil+(LenStr+1)  ; RESB LenStr+1  ; Target filename
.FindStr: EQU .ToFile+(LenStr+1)  ; RESB LenStr+1  ; FileFind wildcard
.SrchStr: EQU .FindStr+(LenStr+1)  ; RESB LenStr+1  ; String for search
.DosChg: EQU .SrchStr+(LenStr+1)  ; RESB 5  ; Reserved for change drive or /C_
.DosBuf: EQU .DosChg+(5)  ; RESB LenBat  ; Command line

.DosLin: EQU .DosBuf+(LenBat)  ; RESB 1  ; Line number of DOS's command line
.DosCol: EQU .DosLin+(1)  ; RESB 1  ; Current column of DOS's command line
.BegCol: EQU .DosCol+(1)  ; RESB 1  ; Start position of DOS's command line
.OutCol: EQU .BegCol+(1)  ; RESB 1  ; Start position for output com. line
.ScrPage: EQU .OutCol+(1)  ; RESB 1  ; Current screen page number
.TstEGA: EQU .ScrPage+(1)  ; RESB 1  ; 1 if EGA or VGA present
.Lines: EQU .TstEGA+(1)  ; RESB 1  ; Number of lines on screen
.Snow: EQU .Lines+(1)  ; RESB 1  ; Snow on/off
.TopView: EQU .Snow+(1)  ; RESB 1  ; TopView output
.DesqVie: EQU .TopView+(1)  ; RESB 1  ; Running under DESQview
.WinLeav: EQU .DesqVie+(1)  ; RESB 1  ; Leave time under Windows
.CrntCol: EQU .WinLeav+(1)  ; RESB 1  ; Color which DOS currently uses
.Quote: EQU .CrntCol+(1)  ; RESB 1  ; Quote next character
.BarPrev: EQU .Quote+(1)  ; RESB 1  ; Previous Key Bar
.SftErr: EQU .BarPrev+(1)  ; RESB 1  ; Shift error boxes down
.BlocEr: EQU .SftErr+(1)  ; RESB 1  ; Disable critical error box
.PathEr: EQU .BlocEr+(1)  ; RESB 1  ; Error when reading current path
.FlagCD: EQU .PathEr+(1)  ; RESB 1  ; 1 when needs auto CD
.TreeTyp: EQU .FlagCD+(1)  ; RESB 1
.WinMous: EQU .TreeTyp+(1)  ; RESB 1
.MousEnt: EQU .WinMous+(1)  ; RESB 1
.OldFlg: EQU .MousEnt+(1)  ; RESB 1
.HlpPage: EQU .OldFlg+(1)  ; RESB 1
.ZoomOne: EQU .HlpPage+(1)  ; RESB 1
.OneFile: EQU .ZoomOne+(1)  ; RESB 1  ; Do one file and exit
.ErrDat: EQU .OneFile+(1)  ; RESB 1
.VerDOS: EQU .ErrDat+(1)  ; RESW 1
.WCBcrn: EQU .VerDOS+(1)*2  ; RESW 1
.WCBsec: EQU .WCBcrn+(1)*2  ; RESW 1
.WCB1seg: EQU .WCBsec+(1)*2  ; RESW 1
.WCB2seg: EQU .WCB1seg+(1)*2  ; RESW 1
.ViewSeg: EQU .WCB2seg+(1)*2  ; RESW 1
.FreMem1: EQU .ViewSeg+(1)*2  ; RESW 1
.FreMem2: EQU .FreMem1+(1)*2  ; RESW 1
.Memorys: EQU .FreMem2+(1)*2  ; RESW 1
.HstAdr: EQU .Memorys+(1)*2  ; RESW 1
.TreAdr: EQU .HstAdr+(1)*2  ; RESW 1
.TreFrst: EQU .TreAdr+(1)*2  ; RESW 1
.TreCrnt: EQU .TreFrst+(1)*2  ; RESW 1
.ClstSiz: EQU .TreCrnt+(1)*2  ; RESW 1
.Total: EQU .ClstSiz+(1)*2  ; RESW 1
.FreeDsk: EQU .Total+(1)*2  ; RESW 1
.InfoLen: EQU .FreeDsk+(1)*2  ; RESW 1
.Rand1: EQU .InfoLen+(1)*2  ; RESW 1
.Rand2: EQU .Rand1+(1)*2  ; RESW 1
.FncAddr: EQU .Rand2+(1)*2  ; RESW 1
.MousPos: EQU .FncAddr+(1)*2  ; RESW 1
.MousTim: EQU .MousPos+(1)*2  ; RESW 2
.AutoTim: EQU .MousTim+(2)*2  ; RESW 2
.Screen: EQU .AutoTim+(2)*2  ; RESW 2  ; Address of screen
.ErrVct: EQU .Screen+(2)*2  ; RESW 2  ; Original vector 24h
.BrkVct: EQU .ErrVct+(2)*2  ; RESW 2  ; Original vector 1Bh
.Volume: EQU .BrkVct+(2)*2  ; RESB 12  ; Volume label
.DosPth: EQU .Volume+(12)  ; RESB LenPath  ; The current path
.NcPath: EQU .DosPth+(LenPath)  ; RESB LenPath  ; The path from VC= variable
.TempDir: EQU .NcPath+(LenPath)  ; RESB LenPath  ; The path from TEMP= variable
.Country: EQU .TempDir+(LenPath)  ; RESB CNTRY_size  ; Country information
.DTA: EQU .Country+(CNTRY_size)  ; RESB DTAs_size  ; Data tramsnir area
.LowTab: EQU .DTA+(DTAs_size)  ; RESB 128  ; Lower case table
.TmpBuf: EQU .LowTab+(128)  ; RESB 256
.TmpErr: EQU .TmpBuf+(256)  ; RESB 256
.Stars: EQU .TmpErr+(256)  ; RESB STAR_size*(NmbStrs)
.MenuBuf: EQU .Stars+(STAR_size*(NmbStrs))  ; RESB LenMenu
.InfBuf: EQU .MenuBuf+(LenMenu)  ; RESB (MaxLins-13)* 38
	; RESB 1  ; EVEN alignment. !! Make it automatic.
.ScrBuf: EQU .InfBuf+((MaxLins-13)* 38)+(1)  ; RESW MaxLins * 80
.UserScr: EQU .ScrBuf+(MaxLins * 80)*2  ; RESW (MaxLins-1) * 80
.WinBuf: EQU .UserScr+((MaxLins-1) * 80)*2  ; RESW (MaxLins-2) * 77
.ErrBuf: EQU .WinBuf+((MaxLins-2) * 77)*2  ; RESW (MaxLins-2) * 77
.ErrBuf1: EQU .ErrBuf+((MaxLins-2) * 77)*2  ; RESW (MaxLins-2) * 77
.HelpBuf: EQU .ErrBuf1+((MaxLins-2) * 77)*2  ; RESB LenHelp
.TreeBuf: EQU .HelpBuf+(LenHelp)  ; RESB MinTree*DIRENT_size+DIRTREE_size
MD_size: EQU .TreeBuf+(MinTree*DIRENT_size+DIRTREE_size)  ; ENDSTRUC
MD_ResIni EQU MD.RRegTo  ; Reserved, registration info.
MD_RStr EQU MD.RRegTo  ; Start of registration string data.
MD_RStrEnd EQU MD.RChkSum  ; End of registration string data.
MD_CmnIni EQU MD.LoadRes  ; End of main data' part saved in VC.INI
MD_LoadSiz EQU MD.DosBuf  ; WORD PTR.  ; WASM ignores `WORD PTR' here.
MD_CmnSave EQU MD.DosLin  ; End of main data' part saved in memory
MD_TmpBuf EQU MD.TmpBuf  ; Needed by TASM 2.0 in DB ... DUP(?) in EdData below.
MD_HelpBuf EQU MD.HelpBuf  ; Needed by TASM 2.0 in DB ... DUP(?) in HlpData below.
MD_MnuList EQU MD.TmpBuf+0  ; BYTE PTR.  ; List of hot keys
MD_MnuMous EQU MD.TmpBuf+200  ; BYTE PTR.  ; Mouse status
MD_BlkList EQU MD.WinBuf
MD_MemList EQU MD.MenuBuf
EditBuf EQU MD.MenuBuf  ; Edit line buffer
UndoBuf EQU MD.ErrBuf  ; Undo buffer
CpVar1 EQU MD.TmpBuf+120  ; BYTE PTR.  ; Variable 1  ; TASM32 5.3 needs this parentheses for `-CpVar1'.
CpVar2 EQU MD.TmpBuf+140  ; BYTE PTR.  ; Variable 2
CpInpt EQU MD.TmpBuf+0  ; BYTE PTR.  ; Input buffer
CpMenu EQU MD.TmpBuf+230  ; BYTE PTR.  ; Menu variable
CpSrc EQU MD.TmpBuf+0  ; BYTE PTR.  ; Source filename
CpDest EQU MD.TmpBuf+130  ; BYTE PTR.  ; Destination filename  ; TASM32 5.3 needs this parentheses for `-CpVar1'.
FncChg EQU MD.TmpBuf+91  ; BYTE PTR.  ; There was writing
SplitFl EQU MD.TmpBuf+94  ; BYTE PTR.  ; Split flag
CpCase EQU MD.TmpBuf+87  ; BYTE PTR.  ; Case: pathname, filename or none
CpAll EQU MD.TmpBuf+90  ; BYTE PTR.  ; Copy / rename all
CopyMov EQU MD.TmpBuf+100  ; BYTE PTR.  ; Copy / Move / Rename
CpBgNam EQU MD.TmpBuf+102  ; WORD PTR.  ; Start address of source filename
CpDev1 EQU MD.TmpBuf+86  ; BYTE PTR.  ; Source is a device
CpDev2 EQU MD.TmpBuf+104  ; BYTE PTR.  ; Destination is a device
CpTree1 EQU MD.TmpBuf+88  ; BYTE PTR.  ; Source tree was changed
CpTree2 EQU MD.TmpBuf+89  ; BYTE PTR.  ; Destination tree was changed
CpHndl1 EQU MD.TmpBuf+116  ; WORD PTR.  ; Source handle
CpHndl2 EQU MD.TmpBuf+118  ; WORD PTR.  ; Destination handle
CpReadLo EQU MD.TmpBuf+106  ; WORD PTR.
CpReadHi EQU MD.TmpBuf+106+2  ; WORD PTR.
CpWriteLo EQU MD.TmpBuf+110  ; WORD PTR.
CpWriteHi EQU MD.TmpBuf+110+2  ; WORD PTR.
CpSizeLo EQU MD.TmpBuf+96  ; WORD PTR.
CpSizeHi EQU MD.TmpBuf+96+2  ; WORD PTR.
CpAttr EQU MD.TmpBuf+120  ; WORD PTR.  ; File attribute
CpDate EQU MD.TmpBuf+122  ; WORD PTR.  ; File date
CpTime EQU MD.TmpBuf+124  ; WORD PTR.  ; File time
CpCont EQU MD.TmpBuf+128  ; WORD PTR.  ; Start segment to continue copying
CpCntBg EQU MD.TmpBuf+126  ; WORD PTR.  ; Base of the per cent counter
CpCntSz EQU MD.TmpBuf+95  ; BYTE PTR.  ; Length of the per cent counter
HexLen EQU MD.HelpBuf+190  ; WORD PTR.  ; Count of hex pattern
TmpMous EQU MD.TmpBuf+0  ; WORD PTR.
AttrDat EQU MD.TmpBuf+96  ; WORD PTR.
AttrTim EQU MD.TmpBuf+98  ; WORD PTR.
ListFlg EQU MD.TmpBuf  ; BYTE PTR.

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

.CurAdr: EQU .WinPath+(LenPath)  ; RESW 1
.First: EQU .CurAdr+(1)*2  ; RESW 1
.EndBuf: EQU .First+(1)*2  ; RESW 1

.ExtBuf: EQU .EndBuf+(1)*2  ; RESB LenExt
.EndFul: EQU .ExtBuf+(LenExt)  ; RESW 1
.ChgFlg: EQU .EndFul+(1)*2  ; RESB 1
.SizDir: EQU .ChgFlg+(1)  ; RESB 1

.DskBuf: EQU .SizDir+(1)  ; RESB MinFls * FILENT_size
WCBdef_size: EQU .DskBuf+(MinFls * FILENT_size)  ; ENDSTRUC
WCBdef_WCBini EQU WCBdef.CurAdr  ; End of WCB part saved in VC.INI
WCBdef_WCBsave EQU WCBdef.ExtBuf  ; End of WCB part saved in memory

EdData:  ; STRUC
	; RESB MD_TmpBuf+100
.EdOffst: EQU 0+(MD_TmpBuf+100)  ; RESW 2  ; Offset of begin of the current line
.EdEndBf: EQU .EdOffst+(2)*2  ; RESW 2  ; Offset of end of part of current line
.EdSizLn: EQU .EdEndBf+(2)*2  ; RESW 1  ; Length of part of line in buffer
.EdUpdat: EQU .EdSizLn+(1)*2  ; RESB 1  ; Update line buffer
.EdWhole: EQU .EdUpdat+(1)  ; RESB 1  ; The whole line allocates buffer
.EdCursr: EQU .EdWhole+(1)  ; RESW 1  ; Offset of the cursor in line buffer
.EdCol1: EQU .EdCursr+(1)*2  ; RESW 1  ; Cursor position for Up & Down
.EdUpDwn: EQU .EdCol1+(1)*2  ; RESB 1  ; Up & Down flag
.EdHex1: EQU .EdUpDwn+(1)  ; RESB 1  ; Cursor digit pointer for Up & Down
.EdScrn: EQU .EdHex1+(1)  ; RESB 1  ; Output all edit window
.EdCurLn: EQU .EdScrn+(1)  ; RESB 1  ; It doesn't need to output line
.EdUndo: EQU .EdCurLn+(1)  ; RESW 1  ; Length of line in undo buffer
	; RESB 77
.EdWrite: EQU .EdUndo+(1)*2+(77)  ; RESB 1  ; File was written
.EdSpace: EQU .EdWrite+(1)  ; RESW 1  ; Edit buffer size in paragraphs
	; RESB 1
.EdStat: EQU .EdSpace+(1)*2+(1)  ; RESB 1  ; Status line
.EdHexAs: EQU .EdStat+(1)  ; RESB 1  ; Hex / ASCII field in HEX mode
.EdHxCur: EQU .EdHexAs+(1)  ; RESB 1  ; Cursor points 1 or 2 digit in HEX
.EdLen: EQU .EdHxCur+(1)  ; RESW 2  ; Size of file in edit buffer
.EdCol: EQU .EdLen+(2)*2  ; RESW 1  ; Cursor position
.EdLine: EQU .EdCol+(1)*2  ; RESW 1  ; Cursor line
	; RESW 1
.EdTxHex: EQU .EdLine+(1)*2+(1)*2  ; RESB 1  ; Text / Hex mode
.EdChng: EQU .EdTxHex+(1)  ; RESB 1  ; File was changed
	; RESW 2
.EdCol0: EQU .EdChng+(1)+(2)*2  ; RESW 1  ; First column displayed on the screen
.EdLin0: EQU .EdCol0+(1)*2  ; RESW 1  ; First line displayed on the screen
	; RESW 1
.EdBase: EQU .EdLin0+(1)*2+(1)*2  ; RESW 1  ; The base of the edit window
.EdSize: EQU .EdBase+(1)*2  ; RESW 1  ; The size of the edit window
.EdFirst: EQU .EdSize+(1)*2  ; RESW 2  ; Offset of first line on the screen
.EdShape: EQU .EdFirst+(2)*2  ; RESW 1  ; Original cursor shape
EdData_size: EQU .EdShape+(1)*2  ; ENDSTRUC
EditBuf_EdHelp EQU EdData.EdOffst  ; Mini help

HlpData:  ; STRUC
	; RESB MD_HelpBuf
.HlpHndl: EQU 0+(MD_HelpBuf)  ; RESW 1
.HlpMode: EQU .HlpHndl+(1)*2  ; RESW 1
.HlpSize: EQU .HlpMode+(1)*2  ; RESW 1
.HlpLins: EQU .HlpSize+(1)*2  ; RESW 1
	; RESW 1
.HlpBkLn: EQU .HlpLins+(1)*2+(1)*2  ; RESW 1
.HlpOffs: EQU .HlpBkLn+(1)*2  ; RESW 2
.HlpFrst: EQU .HlpOffs+(2)*2  ; RESW 1
.HlpCur: EQU .HlpFrst+(1)*2  ; RESW 1
	; RESB 10
.HlpBkFr: EQU .HlpCur+(1)*2+(10)  ; RESW 1
HlpData_size: EQU .HlpBkFr+(1)*2  ; ENDSTRUC
HlpData_HlpPrms EQU HlpData.HlpMode

ViewDat:  ; STRUC
	; RESB MD_TmpBuf+200
.ViSpace: EQU 0+(MD_TmpBuf+200)  ; RESW 1  ; Edit buffer size in paragraphs
.ViewEdit: EQU .ViSpace+(1)*2  ; RESB 1  ; View / Edit
.ViStatus: EQU .ViewEdit+(1)  ; RESB 1  ; Output status line
.ViLoaded: EQU .ViStatus+(1)  ; RESW 1  ; Bytes loaded in buffer
.ViLen: EQU .ViLoaded+(1)*2  ; RESW 2  ; Size of file
.ViOffset: EQU .ViLen+(2)*2  ; RESW 2  ; Offset of first loaded byte in buffer
.ViKeyBar: EQU .ViOffset+(2)*2  ; RESW 1  ; Saved KeyBar & Clock
.ViTxHex: EQU .ViKeyBar+(1)*2  ; RESB 1  ; Text / Hex mode
.ViWrap: EQU .ViTxHex+(1)  ; RESB 1  ; Wrap / Unwrap
.ViFirst: EQU .ViWrap+(1)  ; RESW 1  ; Offset of first line of screen
.ViHandle: EQU .ViFirst+(1)*2  ; RESW 1  ; File handle
.ViCol: EQU .ViHandle+(1)*2  ; RESW 1  ; First column displayed on the screen
.ViPoint: EQU .ViCol+(1)*2  ; RESW 1  ; Point to address of first line
.ViEndTab: EQU .ViPoint+(1)*2  ; RESW 1  ; Point to end of line table
.ViBase: EQU .ViEndTab+(1)*2  ; RESW 1  ; View window base
.ViSize: EQU .ViBase+(1)*2  ; RESW 1  ; View window size
.ViSrPan: EQU .ViSize+(1)*2  ; RESB 1  ; String was found in Hex/ASCII panel
.ViSrLen: EQU .ViSrPan+(1)  ; RESB 1  ; Length of the found string
.ViTmp1: EQU .ViSrLen+(1)  ; RESW 1  ; First byte of search string
.ViTmp2: EQU .ViTmp1+(1)*2  ; RESW 1  ; Last byte of search string
.ViSearch: EQU .ViTmp2+(1)*2  ; RESW 2  ; Saerch offset
.Vi100pc: EQU .ViSearch+(2)*2  ; RESB 1  ; 100% was displayed
ViewDat_size: EQU .Vi100pc+(1)  ; ENDSTRUC

MemData:  ; STRUC
	; RESB MD_TmpBuf+100
.MemCur: EQU 0+(MD_TmpBuf+100)  ; RESW 1
.MemFrst: EQU .MemCur+(1)*2  ; RESW 1
.MemMenu: EQU .MemFrst+(1)*2  ; RESB 1
.MemMous: EQU .MemMenu+(1)  ; RESB 1
.MemTmp: EQU .MemMous+(1)  ; RESB 8
MemData_size: EQU .MemTmp+(8)  ; ENDSTRUC

FndData:  ; STRUC
	; RESB MD_TmpBuf+100
.FndCur: EQU 0+(MD_TmpBuf+100)  ; RESW 1  ; Current line
.FndFrst: EQU .FndCur+(1)*2  ; RESW 1  ; First output line
.FndNumb: EQU .FndFrst+(1)*2  ; RESW 1  ; MD.Total number of lines
.FndSize: EQU .FndNumb+(1)*2  ; RESW 1  ; Max. number of files
.FndBg: EQU .FndSize+(1)*2  ; RESW 1  ; Base of the window
.FndSz: EQU .FndBg+(1)*2  ; RESW 1  ; Size of the window
.FndFls: EQU .FndSz+(1)*2  ; RESW 1  ; Number of found files
.FndMode: EQU .FndFls+(1)*2  ; RESB 1  ; 0-auto scroll; 1-allow move cursor
.FndDir: EQU .FndMode+(1)  ; RESB 1  ; Not first file in subdirectory
.FndMenu: EQU .FndDir+(1)  ; RESB 1  ; Menu item
.FndDrv: EQU .FndMenu+(1)  ; RESB 1  ; Drive letter
FndData_size: EQU .FndDrv+(1)  ; ENDSTRUC

; Release data and data save segment, starting at LastRes.
LAST:  ; STRUC
;--------------------- Release data --------------------
.IntTab: EQU 0  ; RESB 256*4
.SavePtr: EQU .IntTab+(256*4)  ; RESW 2  ; Far pointer. !! Is it used, or can it be removed?
.Vect21: EQU .SavePtr+(2)*2  ; RESW 2  ; Far pointer.
.Vect22: EQU .Vect21+(2)*2  ; RESW 2  ; Far pointer.
.Vect27: EQU .Vect22+(2)*2  ; RESW 2  ; Far pointer.
.Counter: EQU .Vect27+(2)*2  ; RESW 1
.PrgList: EQU .Counter+(1)*2  ; RESW MaxProg
.NameBuf: EQU .PrgList+(MaxProg)*2  ; RESB 12

;------------------ Data save segment ------------------
.WCB1sav: EQU .NameBuf+(12)  ; RESB WCBdef_WCBsave+13*MinFls  ; WCB1
.WCB2sav: EQU .WCB1sav+(WCBdef_WCBsave+13*MinFls)  ; RESB WCBdef_WCBsave+13*MinFls  ; WCB2
.ComnIni: EQU .WCB2sav+(WCBdef_WCBsave+13*MinFls)  ; RESB MD_CmnSave  ; Common data
.DataSav: EQU .ComnIni+(MD_CmnSave)  ; RESB LenStk  ; Local stack. Variable unused.
LAST_size: EQU .DataSav+(LenStk)  ; ENDSTRUC

;SECTION .CODE
ORG 100h
Base EQU 100h
;GLOBAL Start
Start:
	JMP STRICT NEAR Alloc0

;------------------- Begin of program ------------------
RunPar	DW 0
ChkFile	DW 0
Command	DB 'COMMAND.COM', 0
OvlPrm	DB 10, 'VVV', 0, 0, 0, 0, 0, 0, 0, 0Dh
NoRun_S	DB 'There is not enough memory to run this command', 13,10,0
FnFil_S	DB 13,10, "Can't find the file: ", 0
BadFl_S	DB 13,10, "Bad or missing ", 0
Retr_S	DB 13,10, "Press ENTER to try again or ESC to abort", 13,10,0
Aloc_S	DB 'Program too big to fit in memory', 13,10,0

;------------------- Execute commands ------------------

Exec:	TEST BYTE [LastRes+LAST.ComnIni+MD.LoadFl], 7Fh
	JZ Exec01
	CALL GetStat
	MOV AH, 49h
	INT 21h
	CALL SetStat
Exec01:	PUSH DS
	POP ES
	MOV AX, LastRes+LAST.ComnIni+MD.DosBuf
	MOV [LastRes+LAST.ComnIni+MD.BatAdr], AX
Exec02:	CLD
	MOV DL, [LastRes+LAST.ComnIni+MD.BreakFl]
	MOV AX, 3301h
	INT 21h
	MOV DI, [LastRes+LAST.ComnIni+MD.BatAdr]
	LEA SI, [DI-4]
	PUSH DI
	MOV CX, 0FFFFh
	MOV AL, 0
	REPNE SCASB
	MOV [LastRes+LAST.ComnIni+MD.BatAdr], DI
	POP DI
	MOV CX, LenCmd
	REPNE SCASB
	DEC DI
	MOV BYTE [DI], 0Dh
	LEA CX, [DI-1]
	CMP AL, [LastRes+LAST.ComnIni+MD.ExecTyp]
	JE Exec04
	INC SI
	INC SI
	INC SI
	DW _SUB_CX_SI
	MOV [SI], CL
	CMP BYTE [LastRes+LAST.ComnIni+MD.DosChg+1], 0
	JE Exec03
	MOV [LastRes+LAST.ComnIni+MD.BatPoin], SI
	MOV SI, LastRes+LAST.ComnIni+MD.DosChg
	INT 2Eh
	CLI
	MOV SP, CS
	MOV SS, SP
	MOV SP, VcStack
	STI
	PUSH CS
	POP DS
	MOV SI, [LastRes+LAST.ComnIni+MD.BatPoin]
	MOV BYTE [LastRes+LAST.ComnIni+MD.DosChg+1], 0
Exec03:	INT 2Eh
	CLI
	MOV SP, CS
	MOV SS, SP
	MOV SP, VcStack
	STI
	CALL SetBrk0
	JMP Exec07
Exec04:	DW _SUB_CX_SI
	MOV CH, '/'
	MOV [SI], CX
	MOV WORD [SI+2], 'C '
	MOV BX, LastRes+LAST.ComnIni+MD.EPB
	MOV [BX+EPBs.CmdLine+0], SI
	MOV [BX+EPBs.CmdLine+2], DS
Exec05:	MOV DI, Command
	MOV DX, [LastRes+LAST.ComnIni+MD.ComSpec]
	DW _OR_DX_DX
	JE Exec06
	MOV DS, [2Ch]
	MOV AX, 4B00h
	INT 21h
	CALL SetBrk0
	JNC Exec07
	MOV DS, [ES:2Ch]
	MOV DI, [ES:LastRes+LAST.ComnIni+MD.ComSpec]

	CMP AX, STRICT WORD 3
	JBE Exec06
	MOV SI, NoRun_S
	PUSH CS
	CALL OutStr0
	JMP Exec10
Exec06:	MOV SI, FnFil_S
	CALL NotFind
	PUSH ES
	POP DS
	JNC Exec05
	JMP Exec10
Exec07:	PUSH ES
	POP DS
	MOV BX, [LastRes+LAST.ComnIni+MD.BatAdr]
	CMP BYTE [BX], 0
	JE Exec10
	CMP BYTE [BX], '@'
	JNE Exec08
	INC BX
	MOV [LastRes+LAST.ComnIni+MD.BatAdr], BX
	JMP Exec02
Exec08:	MOV DI, LastRes+LAST.IntTab
	PUSH DI
	MOV AX, 0A0Dh
	STOSW
	MOV AH, 19h
	INT 21h
	DW _MOV_DL_AL
	INC DX
	ADD AL, 'A'
	STOSB
	CMP BYTE [LastRes+LAST.ComnIni+MD.Prompt], 0
	JE Exec09
	MOV AX, ':\'
	STOSW
	DW _MOV_SI_DI
	MOV AH, 47h
	INT 21h
	MOV CX, 0FFFFh
	MOV AL, 0
	REPNE SCASB
	DEC DI
Exec09:	MOV AX, '>'
	STOSW
	POP SI
	PUSH CS
	CALL OutStr
	MOV SI, [LastRes+LAST.ComnIni+MD.BatAdr]
	PUSH CS
	CALL OutStr
	MOV AX, 0E0Dh
	INT 10h
	MOV AX, 0E0Ah
	INT 10h
	JMP Exec02
Exec10:	MOV AL, [LastRes+LAST.ComnIni+MD.LoadRes]
	XCHG AL, [LastRes+LAST.ComnIni+MD.LoadFl]
	TEST AL, 7Fh
	JNZ Exec11
	JMP STRICT NEAR Exec15  ; !! SHORT would fit.
Exec11:	CALL GetStat  ; Load VC.COM
	MOV CL, 4
	MOV BX, LastPtr-1
	SHR BX, CL
	SUB BX, (((Init00-Start+Base)>>4)-1)
	MOV AH, 48h
	INT 21h
	CALL SetStat
	SUB AX, STRICT WORD (((Init00-Start+Base)>>4))
	MOV [CS:RunPar], AX
	JNC Exec12
	JMP AlocEr
Exec12:	DW _XOR_AX_AX
	MOV WORD [LastRes+LAST.ComnIni+MD_LoadSiz], LastPtr
	MOV SI, OvlPrm
	MOV BL, [CS:SI]
	MOV BH, 0
	MOV [CS:SI+BX-1], CS
	MOV BX, LastRes+LAST.ComnIni+MD.EPB
	MOV [ES:BX+EPBs.CmdLine+0], SI
	MOV [ES:BX+EPBs.CmdLine+2], CS
	MOV DX, [ES:LastRes+LAST.ComnIni+MD.OvlPth]
	MOV DS, [CS:2Ch]
	MOV AX, 4B00h
	INT 21h
	PUSH CS
	POP ES
	CLD
	JNC Exec14
	CMP AL, 3
	JA AlocEr
Exec13:	MOV DI, [ES:LastRes+LAST.ComnIni+MD.OvlPth]  ; Error: VC.COM not found
	MOV DS, [CS:2Ch]
	MOV SI, BadFl_S
	CALL NotFind
	JNC Exec12
	MOV AL, 1
	JMP Exit00
Exec14:	MOV AH, 4Dh
	INT 21h
	DW _OR_AX_AX
	JNE Exec13
	PUSH ES
	POP DS
	MOV AX, [LastRes+LAST.ComnIni+MD_LoadSiz]
	CMP AX, [ChkFile]
	JNE Exec13
Exec15:	PUSH WORD [CS:RunPar]
	MOV AX, Init11
	PUSH AX
	RETF

AlocEr:	MOV SI, Aloc_S
	PUSH CS
	CALL OutStr0
	MOV AL, 1
Exit00:	MOV BX, [CS:LastRes+LAST.Vect22+0]
	MOV [CS:0Ah+0], BX
	DW _XOR_BX_BX
	XCHG BX, [CS:LastRes+LAST.Vect22+2]
	MOV [CS:0Ah+2], BX
Exit01:	PUSH AX
	PUSH CS
	POP ES
	MOV DL, [ES:LastRes+LAST.ComnIni+MD.BreakFl]
	MOV AX, 3301h
	INT 21h
	MOV CX, [ES:LastRes+LAST.Counter]
	JCXZ Exit03
Exit02:	MOV SI, [ES:LastRes+LAST.Counter]
	SHL SI, 1
	MOV DS, [ES:SI+LastRes+LAST.PrgList-2]
	PUSH CS
	CALL Release
	LOOP Exit02
Exit03:	CMP BYTE [ES:LastRes+LAST.ComnIni+MD.ChkTSR], 0
	JZ Exit04
	LDS DX, [ES:LastRes+LAST.Vect21]
	MOV AX, 2521h
	INT 21h
	LDS DX, [ES:LastRes+LAST.Vect27]
	MOV AX, 2527h
	INT 21h
Exit04:	POP AX
	CMP WORD [ES:LastRes+LAST.Vect22+2], 0
	JNE Exit05
	MOV AH, 4Ch
	INT 21h
Exit05:	JMP FAR [ES:LastRes+LAST.Vect22]

;GLOBAL NotFind
NotFind:  ; PROC NEAR
	PUSH DS
	PUSH CS
	CALL OutStr0
	POP DS
	DW _MOV_SI_DI
	PUSH CS
	CALL OutStr
	PUSH DS
	MOV SI, Retr_S
	PUSH CS
	CALL OutStr0
	POP DS
NotFn1:	MOV AH, 0
	INT 16h
	CMP AL, 0Dh
	JE NotFn2
	CMP AL, 1Bh
	JNE NotFn1
	STC
NotFn2:	RET
;NotFind ENDP

;OutStr0	PROC	NEAR
;GLOBAL OutStr0
OutStr0:
	PUSH CS
	POP DS
OutStr:	PUSH BP
	PUSH BX
	MOV BL, 7
	LODSB
	MOV AH, 0Eh
	INT 10h
	POP BX
	POP BP
	CMP BYTE [SI], 0
	JNE OutStr
	RETF
;OutStr0	ENDP

;GLOBAL SetBrk0
SetBrk0:  ; PROC NEAR
	CLD
	PUSH SS
	POP ES
	POP BP
	PUSH CS
	PUSH BP
;SetBrk0 ENDP

;GLOBAL SetBrk
SetBrk:  ; PROC NEAR
	PUSH DS
	PUSH AX
	PUSHF
	PUSH SS
	POP DS
	MOV AX, 3300h
	INT 21h
	MOV [LastRes+LAST.ComnIni+MD.BreakFl], DL
	MOV DL, 0
	MOV AX, 3301h
	INT 21h
	MOV DX, CtrlC
	MOV AX, 2523h
	INT 21h
	POPF
	POP AX
	POP DS
	RETF
;SetBrk ENDP

;GLOBAL GetStat
GetStat:  ; PROC NEAR
	MOV CX, 0FFFFh
	MOV AX, 5802h
	INT 21h
	JC GetSt1
	DW _MOV_CL_AL
	MOV AX, 5800h
	INT 21h
	DW _MOV_CH_AL
	MOV BX, 1
	MOV AX, 5803h
	INT 21h
	MOV BX, 80h
	MOV AX, 5801h
	INT 21h
GetSt1:	DW _MOV_BP_CX
	RET
;GetStat ENDP

;GLOBAL SetStat
SetStat:  ; PROC NEAR
	PUSH AX
	PUSHF
	CMP BP, 0FFFFh
	JE SetSt1
	DW _MOV_BX_BP
	DW _MOV_BL_BH
	MOV BH, 0
	MOV AX, 5801h
	INT 21h
	DW _MOV_BX_BP
	MOV BH, 0
	MOV AX, 5803h
	INT 21h
SetSt1:	POPF
	POP AX
	RET
;SetStat ENDP

CtrlC:	IRET

;New21	PROC	FAR			; INT 21h
;GLOBAL New21
New21:
	CMP AH, 4Bh
	JE Fnc4B
	CMP AH, 31h
	JE Fnc31
	CMP AH, 49h
	JE Fnc49
	CMP AH, 2Bh
	JE VCapi
Old21:	JMP FAR [CS:LastRes+LAST.Vect21]
Fnc4B:	CALL ExeProg
	JMP Old21
Fnc31:	CALL AddProg
	JNC Old21
	MOV AH, 4Ch
	JMP Old21
Fnc49:	CALL FreeBlk
	JMP Old21
VCapi:	CMP CX, 'CV'
	JNE Old21
	CMP DX, 'MO'
	JNE Old21
	PUSH CS
	POP ES
	CMP AL, 1
	MOV BX, LastRes+LAST.WCB1sav
	JB VCapi1
	MOV BX, LastRes+LAST.WCB2sav
	JE VCapi1
	MOV BX, LastRes+LAST.ComnIni
VCapi1:	MOV AX, VcApiVr*100h
	CLC
	RETF 2
;New21	ENDP

;GLOBAL New27
New27:  ; PROC FAR  ; INT 27h
	ADD DX, 0Fh
	SHR DX, 1
	SHR DX, 1
	SHR DX, 1
	SHR DX, 1
	CALL AddProg
	JNC New27a
	MOV AH, 0
	JMP Old21
New27a:	SHL DX, 1
	SHL DX, 1
	SHL DX, 1
	SHL DX, 1
	JMP FAR [CS:LastRes+LAST.Vect27]
;New27 ENDP

;------------- Save vectors & program name -------------
;			DS:DX - file name
;GLOBAL ExeProg
ExeProg:  ; PROC NEAR
	PUSH ES
	PUSH SI
	PUSH DI
	PUSH CX
	PUSH AX
	CLD
	PUSH CS
	POP ES
	PUSH DS  ; Copy vectors & SAVE PTR
	DW _XOR_SI_SI
	MOV DS, SI
	MOV DI, LastRes+LAST.IntTab
	MOV CX, 256*2
	CLI
	REP MOVSW
	MOV SI, 4A8h
	MOVSW
	MOVSW
	STI
	POP DS
	DW _MOV_SI_DX  ; Save file name
ExPrg1:	DW _MOV_CX_SI
ExPrg2:	LODSB
	CMP AL, ':'
	JE ExPrg1
	CMP AL, '\'
	JE ExPrg1
	CMP AL, 0
	JNE ExPrg2
	DW _MOV_SI_CX
	MOV DI, LastRes+LAST.NameBuf
	MOV CX, 12
	REP MOVSB
	POP AX
	POP CX
	POP DI
	POP SI
	POP ES
	RET
;ExeProg ENDP

;------------- Add resident program to list ------------
;			   DX - number of paragraphs
;GLOBAL AddProg
AddProg:  ; PROC NEAR
	PUSH DS
	PUSH ES
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH CX
	PUSH BX
	PUSH AX
	STI
	CMP WORD [CS:LastRes+LAST.Counter], MaxProg
	JB AdPrg1
	MOV AX, 0E07h
	INT 10h
	PUSH CS
	POP DS
	MOV SI, LastRes+LAST.IntTab
	DW _XOR_DI_DI
	MOV ES, DI
	MOV CX, 2*256
	CLD
	CLI
	REP MOVSW
	MOV DI, 4A8h
	MOVSW
	MOVSW
	STI
	STC
	JMP AdPrg6
AdPrg1:	MOV AH, 62h  ; Get current PSP
	INT 21h
	MOV ES, BX
	CALL FreeBlk
	DW _MOV_BX_DX
	ADD BX, (2+12+1+5*256+4+2 +15)>>4
	MOV AH, 4Ah
	INT 21h
	CMC
	JNC AdPrg6
	MOV AX, ES
	MOV CX, ES
	DW _ADD_CX_DX
	MOV ES, CX
	PUSH CS
	POP DS
	CLD
	CLI
	DW _XOR_DI_DI  ; PSP -> PrgSeg
	STOSW
	MOV SI, LastRes+LAST.NameBuf  ; File name -> PrgSeg
	MOV CX, 12
	REP MOVSB
	PUSH DX  ; Changed vectors -> PrgSeg
	PUSH DI
	INC DI
	DW _XOR_BX_BX
	DW _XOR_DX_DX
	MOV DS, BX
	MOV SI, LastRes+LAST.IntTab
AdPrg2:
CS
	LODSW
	DW _MOV_CX_AX
CS
	LODSW
	CMP CX, [BX+0]  ; Offset.
	JNE AdPrg3
	CMP AX, [BX+2]  ; Segment.
	JE AdPrg4
AdPrg3:	CMP DL, 22h
	JE AdPrg4
	PUSH AX  ; Save vector
	DW _MOV_AL_DL
	STOSB
	DW _MOV_AX_CX
	STOSW
	POP AX
	STOSW
	INC DH
AdPrg4:	ADD BX, 4
	INC DL
	JNE AdPrg2
	POP BX
	MOV [ES:BX], DH
	PUSH CS
	POP DS
	POP DX
	MOVSW  ; SAVE PTR -> PrgSeg
	MOVSW
	DW _MOV_CX_DI  ; check sum -> PrgSeg
	DW _XOR_SI_SI
	DW _XOR_BX_BX
	MOV AH, 0
AdPrg5:
ES
	LODSB
	DW _ADD_BX_AX
	LOOP AdPrg5
	DW _MOV_AX_BX
	STOSW
	MOV BX, [LastRes+LAST.Counter]  ; Save PrgSeg
	SHL BX, 1
	MOV [BX+LastRes+LAST.PrgList], ES
	INC WORD [LastRes+LAST.Counter]
	STI  ; Add PrgSeg size
	DEC DI
	MOV CL, 4
	SHR DI, CL
	INC DI
	DW _ADD_DX_DI
AdPrg6:	POP AX
	POP BX
	POP CX
	POP DI
	POP SI
	POP BP
	POP ES
	POP DS
	RET
;AddProg ENDP

;------------------ Free memory block ------------------
;			   ES - segment for diallocation
;GLOBAL FreeBlk
FreeBlk:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH CX
	PUSH AX
	CLD
	MOV SI, LastRes+LAST.PrgList
	DW _MOV_DI_SI
	MOV CX, [CS:LastRes+LAST.Counter]
	JCXZ FreBl3
FreBl1:	MOV DS, [CS:SI]
	CALL ChkBlk
CS
	LODSW
	JNE FreBl2
	PUSH AX
	MOV AX, ES
	CMP AX, [0]
	POP AX
	JE FreBl2
	MOV [CS:DI], AX
	INC DI
	INC DI
FreBl2:	LOOP FreBl1
	DW _SUB_SI_DI
	SHR SI, 1
	SUB [CS:LastRes+LAST.Counter], SI
FreBl3:	POP AX
	POP CX
	POP DI
	POP SI
	POP DS
	RET
;FreeBlk ENDP

;---------------------- Check sum ----------------------
;			   DS - PrgSeg
;GLOBAL ChkBlk
ChkBlk:  ; PROC NEAR
	PUSH SI
	PUSH DI
	PUSH CX
	MOV AL, [0Eh]
	MOV AH, 5
	MUL AH
	ADD AX, STRICT WORD 2+12+1+4
	DW _MOV_CX_AX
	DW _XOR_SI_SI
	DW _XOR_DI_DI
	MOV AH, 0
ChkBl1:	LODSB
	DW _ADD_DI_AX
	LOOP ChkBl1
	CMP DI, [SI]
	POP CX
	POP DI
	POP SI
	RET
;ChkBlk ENDP

;------------------- Release programs ------------------
;			   DS - PrgSeg
;GLOBAL Release
Release:  ; PROC NEAR
	PUSH DS
	PUSH ES
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	CALL GetStat
	CLD
	CALL ChkBlk  ; Check sum
	JNE Relea5
	DW _XOR_AX_AX  ; Restore vectors
	MOV ES, AX
	MOV SI, 0Eh
	LODSB
	DW _MOV_CX_AX
	CLI
	JCXZ Relea2
Relea1:	LODSB
	DW _MOV_DI_AX
	SHL DI, 1
	SHL DI, 1
	MOVSW
	MOVSW
	LOOP Relea1
Relea2:	MOV DI, 4A8h  ; Restore SAVE PTR
	MOVSW
	MOVSW
	STI
	MOV SI, [0]  ; Release blocks
	MOV AH, 52h
	INT 21h
	MOV DS, [ES:BX-2]
Relea3:	CMP SI, [1]
	JNE Relea4
	MOV AX, DS
	INC AX
	MOV ES, AX
	MOV AH, 49h
	INT 21h
Relea4:	MOV AX, DS
	INC AX
	ADD AX, [3]
	CMP BYTE [0], 'M'
	MOV DS, AX
	JE Relea3
Relea5:	CALL SetStat
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP ES
	POP DS
	RETF
;Release ENDP

LastRes:
;LastRes LAST <>  ; It is here, but we don't allocate space.
VcStack EQU LastRes+LAST_size
LastDat EQU LastRes+LAST_size

;--------------------- Main module ---------------------
Alloc0:	CLD
	MOV SI, 100h
	MOV CX, LastPtr-100h
	DW _XOR_BX_BX
	DW _XOR_DX_DX
	MOV AH, 0
Alloc1:	LODSB
	DW _ADD_BX_AX
	LOOP Alloc1
	MOV SI, 80h
	MOV DI, OvlPrm
	MOV CL, [DI]
	DEC CX
	REPE CMPSB
	JNE Alloc3
	LODSW
	CMP BYTE [SI], 0Dh
	JNE Alloc3
	MOV ES, AX
	XCHG BX, [ES:LastRes+LAST.ComnIni+MD_LoadSiz]
	MOV ES, [ES:RunPar]
	MOV SI, Init00
	DW _MOV_DI_SI
	DW _MOV_CX_BX
	DW _SUB_CX_SI
	REP MOVSB
	MOV AX, 4C00h
	SUB BX, LastPtr
	JE Alloc2
	INC AX
Alloc2:	INT 21h
Alloc3:	MOV [ChkFile], BX
	MOV AH, 30h  ; Check DOS version
	INT 21h
	CMP AL, 3
	JB Alloc4
	DW _XCHG_AL_AH
	CMP AX, STRICT WORD 314h
	JAE Alloc5
	MOV SI, Vers_S
	PUSH CS
	CALL OutStr0
	MOV AX, 4C02h
	INT 21h
Alloc4:	RET
Alloc5:	DW _XOR_BP_BP  ; Allocate segments
	MOV BX, ((LastDat-Start+Base-1)>>4)+1
	MOV DX, DS
	DW _ADD_DX_BX
	INC DX
	PUSH DX
	MOV DX, LastPtr-1
	DW _MOV_SI_DX
	SUB DX, (Init00-Start+Base)&0FFF0h
	DW _MOV_DI_DX
	PUSH DX
	MOV CL, 4
	SHR DX, CL
	INC DX
	POP CX
	INC CX
	PUSH BX
	DW _ADD_BX_DX
	INC BX
	MOV AH, 4Ah
	INT 21h
	POP BX
	POP ES
	JNC Alloc6
	DW _XCHG_BX_DX  ; Allocate transit block
	MOV AH, 48h
	INT 21h
	DW _XCHG_BX_DX
	JC Alloc9
	MOV ES, AX
	STD
	REP MOVSB
	CLD
	MOV SP, VcStack
	PUSH ES
	PUSH CS  ; Compress resident block
	POP ES
	MOV AH, 4Ah
	INT 21h
	POP ES
	JMP Alloc7
Alloc6:	STD
	CLI
	PUSH CS
	POP SS
	MOV SP, VcStack
	REP MOVSB
	CLD

;-------- Split into resident and transit parts --------
	MOV AX, ES
	DEC AX
	PUSH AX
	MOV AX, CS
	DEC AX
	MOV DS, AX
	MOV AL, 'M'
	XCHG AL, [0]
	XCHG BX, [3]
	SUB BX, [3]
	DEC BX
	POP DS
	MOV [0], AL
	MOV [1], CS
	MOV [3], BX
	STI
	PUSH CS
	POP DS
Alloc7:	MOV AX, ES
	SUB AX, STRICT WORD (Init00-Start+Base)>>4
	MOV [RunPar], AX
	PUSH AX
	CALL SetStat
	MOV AX, Init00
	PUSH AX
	RETF

Alloc9:	MOV SI, Aloc_S  ; Error
	PUSH CS
	CALL OutStr0
	CALL SetStat
	MOV AX, 4C01h
	INT 21h

;------------------ Read configuration -----------------
Init00:	MOV ES, [2Ch]
	MOV DI, LastRes+LAST.WCB1sav+WCBdef_WCBsave
	DW _MOV_DX_DI
	CALL MainPth
	PUSH DI
	PUSH DX
	MOV SI, Init_F
	MOV BP, LastRes+LAST.ComnIni - (3 + 2*WCBdef_WCBini)
	MOV CX, 3 + 2*WCBdef_WCBini + MD_CmnIni + 2 + 1
	CALL ReadOne
	MOV BX, 0
	JC Init03
	DEC CX
	DW _SUB_AX_CX
	JNE Init02
	DEC CX
	DEC CX
	DW _MOV_SI_BP
	DW _XOR_DX_DX
Init01:	LODSB
	DW _ADD_DX_AX
	LOOP Init01
	LODSW
	DW _CMP_AX_DX
	JNE Init02
	DW _MOV_DI_BP
	MOV AL, 'V'
	MOV CL, 3
	REPE SCASB
	JNE Init02
	DW _MOV_SI_DI
	MOV DI, LastRes+LAST.WCB1sav
	MOV CL, WCBdef_WCBini
	PUSH CX
	REP MOVSB
	POP CX
	MOV DI, LastRes+LAST.WCB2sav
	REP MOVSB
	JMP Init04
Init02:	MOV BL, 1

;--------------------- Default init --------------------
Init03:	PUSH DS
	PUSH CS
	POP DS
	MOV SI, Palets
	MOV DI, LastRes+LAST.ComnIni
	MOV CX, MD_ResIni
	REP MOVSB
	MOV CL, MD_CmnIni-MD_ResIni
	MOV AL, 0
	REP STOSB
	MOV SI, DefWCB
	MOV DI, LastRes+LAST.WCB1sav
	MOV CL, WCBdef_WCBini
	REP MOVSB
	POP DS
	MOV AH, 19h
	INT 21h
	DW _MOV_DL_AL
	INC DX
	ADD AL, 'A'
	MOV DI, LastRes+LAST.WCB1sav+WCBdef.WinPath
	STOSB
	MOV AX, ':\'
	STOSW
	DW _MOV_SI_DI
	MOV AL, 0
	STOSB
	MOV AH, 47h
	INT 21h
	MOV SI, LastRes+LAST.WCB1sav
	MOV DI, LastRes+LAST.WCB2sav
	MOV CX, WCBdef_WCBini
	REP MOVSB
	MOV [LastRes+LAST.WCB1sav+WCBdef.Visible], CL

;--------------------- Output Report -------------------
Init04:	CALL ChkMode
	JZ Init05
	MOV AX, 3
	INT 10h
Init05:
%if SHWW_LE_1  ; Compute checksum of RRegTo and RNumCp.
	DW _XOR_DI_DI
	DW _XOR_BP_BP
	MOV SI, LastRes+LAST.ComnIni+MD_RStr
	MOV CX, MD_RStrEnd-MD_RStr
	MOV AH, 0
SHW1:	RCL DI, 1
	RCR BP, 1
	INC DI
	DEC BP
	LODSB
	DW _ADC_DI_AX
	PUSHF
	DW _XOR_BP_AX
	POPF
	LOOP SHW1
	LODSW
	DW _XOR_DI_AX
	LODSW
	DW _XOR_BP_AX
	DW _OR_BP_DI  ; Make BP 0 iff registered.
%endif
	PUSH CS  ; Output message
	POP DS
	MOV DX, LastRes+LAST.ComnIni+MD.ExtMain  ; 0x2941
	DW _MOV_DI_DX
	MOV SI, Title_S+2
	CALL MvzLin0
%if SHWW_LE_1
	DW _OR_BP_BP
	JZ SHW2  ; Skip printing `shareware' if registered.
%endif
	MOV SI, Suff_S
	CALL MvzLin0
SHW2:	MOV SI, Copyr_S
	CALL MvzLin0
%if SHWW_LE_1
	DW _OR_BP_BP
	JNZ SHW3
	MOV SI, RegTo_S
	MOV BP, LastRes+LAST.ComnIni+MD.RRegTo
	CALL Mvz2lin
	MOV SI, NumCp_S
	MOV BP, LastRes+LAST.ComnIni+MD.RNumCp
	CALL Mvz2lin
SHW3:
%endif
	MOV SI, CrLf_S
	CALL MvzLin0
	PUSH ES
	POP DS
	MOV AH, 9
	INT 21h
	DW _OR_BL_BL  ; Error in INI file
	JE Init09
	MOV SI, NoIni_S
	CALL OutStr1

;--------------- Read main extension file --------------
Init09:	POP DX
	POP DI
	MOV SI, Ext_F
	MOV BP, LastRes+LAST.ComnIni+MD.ExtMain
	MOV CX, LenExt-1
	CALL ReadOne
	JC Init10
	DW _ADD_BP_AX
Init10:	MOV BYTE [DS:BP], 1Ah

;---------------- Initialize main data -----------------
	MOV BX, LastRes+LAST.ComnIni
	MOV SI, LastRes+LAST.WCB1sav
	MOV DI, LastRes+LAST.WCB2sav
	MOV AX, WCBdef.DskBuf
	MOV [SI+WCBdef.CurAdr], AX
	MOV [DI+WCBdef.CurAdr], AX
	MOV [SI+WCBdef.First], AX
	MOV [DI+WCBdef.First], AX
	MOV [SI+WCBdef.EndBuf], AX
	MOV [DI+WCBdef.EndBuf], AX
	DW _XOR_AX_AX
	MOV [LastRes+LAST.Counter], AX
	MOV [BX+MD.CrnPath], AL
	MOV [BX+MD.ViewFil], AL
	MOV [BX+MD.ToFile], AL
	MOV [BX+MD.SrchStr], AL
	MOV [BX+MD.HstBuf], AX
	MOV WORD [BX+MD.LastMnu], 1
	DEC AX
	MOV [BX+MD.MouseX], AX
	MOV [BX+MD.MouseY], AX
	MOV [BX+MD.LoadRes], AL
	MOV AL, [BX+MD.AutoMnu]
	MOV [BX+MD.MenuFl], AL
	PUSH DS
	PUSH CS
	POP DS
	MOV SI, Mask_S+1
	LEA DI, [BX+MD.SelMas]
	MOV CX, 4
	REP MOVSB
	MOV SI, Mask_S
	LEA DI, [BX+MD.FindStr]
	MOV CL, 5
	REP MOVSB
	POP DS
	MOV AX, SetBrk
	CALL CallPSP
	MOV AX, Exit01
	XCHG AX, [0Ah+0]
	MOV [LastRes+LAST.Vect22+0], AX
	MOV AX, DS
	XCHG AX, [0Ah+2]
	MOV [LastRes+LAST.Vect22+2], AX
	CMP BYTE [BX+MD.ChkTSR], 0
	JZ Init11
	MOV AX, 3521h
	INT 21h
	MOV [LastRes+LAST.Vect21+0], BX
	MOV [LastRes+LAST.Vect21+2], ES
	DW _XOR_AX_AX
	MOV ES, AX
	CLI
	MOV WORD [ES:4*21h+0], New21
	MOV [ES:4*21h+2], DS
	STI
	MOV AX, 3527h
	INT 21h
	MOV [LastRes+LAST.Vect27+0], BX
	MOV [LastRes+LAST.Vect27+2], ES
	MOV DX, New27
	MOV AH, 25h
	INT 21h

;------------ Allocate Secondary Data Segment ----------
Init11:	MOV AX, CS
	ADD AX, STRICT WORD (Init00-Start+Base)>>4
	MOV ES, AX
	MOV BX, 0FFFFh
	MOV AH, 4Ah
	INT 21h
	DW _MOV_SI_BX
	CMP AX, STRICT WORD 8
	JE Init12
	DW _XOR_SI_SI
Init12:	MOV CL, 4
	MOV BX, LastPtr-1
	SHR BX, CL
	SUB BX, ((Init00-Start+Base)>>4)-1
	MOV AH, 4Ah
	INT 21h
	PUSH DS
	POP ES
	MOV BX, 0FFFFh
	MOV AH, 48h
	INT 21h
	MOV AH, 48h
	INT 21h
	MOV ES, AX
	MOV DX, ((MD_size-1)>>4)+1
	MOV DI, ((WCBdef_size -1)>>4)+1
	MOV AX, (( MinView -1)>>4)+1
	DW _ADD_AX_DX
	DW _ADD_AX_DI
	DW _ADD_AX_DI
	DW _CMP_AX_BX
	JBE Init13
	MOV AX, AlocEr
	PUSH SS
	PUSH AX
	RETF
Init13:	MOV [ES:MD.FreMem2], BX
	DW _CMP_SI_BX
	JAE Init14
	DW _MOV_SI_BX
Init14:	MOV [ES:MD.FreMem1], SI
	MOV AX, ES
	DW _ADD_AX_DX
	MOV [ES:MD.WCB1seg], AX
	DW _ADD_AX_DI
	MOV [ES:MD.WCB2seg], AX
	DW _ADD_AX_DI
	MOV [ES:MD.ViewSeg], AX
	MOV [CS:SecDat], ES

;------------------ Restore data segment ---------------
	CLD
	DW _XOR_DI_DI
	MOV SI, LastRes+LAST.ComnIni
	MOV CX, MD_CmnSave
	REP MOVSB
	PUSH ES
	MOV ES, [ES:MD.WCB1seg]
	MOV SI, LastRes+LAST.WCB1sav
	CALL Expand
	POP ES
	PUSH ES
	MOV ES, [ES:MD.WCB2seg]
	MOV SI, LastRes+LAST.WCB2sav
	CALL Expand
	POP DS

;------------------- Set Error Vectors -----------------
	CALL HookVct
	PUSH ES
	POP DS

;------------------ Set Display Segment ----------------
	CALL ChkMode
	JZ Init17
	DW _MOV_BL_AH
	MOV CX, 2000h
	MOV AH, 1
	INT 10h
	PUSH DS
	MOV SI, Retrn_S
	CALL OutStr1
	INC SI
	CMP BL, 80
	JB Init15
	INC SI
	INC SI
Init15:	CALL OutStr1
	POP DS
Init16:	MOV AH, 0
	INT 16h
	CMP AL, 0Dh
	JNE Init16
	MOV AL, [MD.ScrMod]
	MOV AH, 0
	INT 10h
	MOV AH, 0Fh
	INT 10h
	AND AL, 7Fh
Init17:	MOV [MD.ScrMod], AL
	MOV [MD.ScrPage], BH

;------------------ Correct cursor size ----------------
	MOV AH, 3
	INT 10h
	CMP CH, 0Fh
	JBE Init18
	MOV CX, 607h
Init18:	CMP CX, 67h
	JNE Init19
	MOV CX, 607h
Init19:	CMP BYTE [MD.ScrMod], 7
	JNE Init20
	CMP CX, 607h
	JNE Init20
	MOV CX, 0B0Ch
Init20:	MOV AH, 1
	INT 10h

;---------------- Initialize data segment --------------
IniSave EQU LastRes+LAST.WCB1sav

	MOV DX, MD.Country  ; Country
	MOV AX, 3800h
	INT 21h
	MOV DI, MD.TmpBuf  ; Lower case table
	MOV SI, MD.LowTab
	MOV CX, 80h
	PUSH DI
	PUSH CX
Init21:	DW _MOV_AL_CL
	NEG AL
	MOV [SI], AL
	INC SI
	CALL FAR [MD.Country+CNTRY.CaseMp]
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
	MOV [BX+MD.LowTab-128], AH
Init23:	INC AH
	LOOP Init22
	AND BYTE [MD.LoadFl], 7Fh
	MOV AX, [SS:2]  ; Memorys
	MOV [MD.Memorys], AX
	DW _XOR_AX_AX
	MOV [SS:IniSave], AL
	MOV [MD.DosBuf], AL  ; DosBuf
	MOV BX, MD.EPB  ; EPB
	MOV [BX+EPBs.EnvSeg], AX
	MOV WORD [BX+EPBs.FCB1+0], 5Ch
	MOV [BX+EPBs.FCB1+2], ES
	MOV WORD [BX+EPBs.FCB2+0], 6Ch
	MOV [BX+EPBs.FCB2+2], ES
	MOV ES, [SS:2Ch]  ; ComSpec
	PUSH DS
	PUSH CS
	POP DS
	DW _XOR_DI_DI
Init24:	CMP AL, [ES:DI]
	JE Init25
	MOV SI, Comsp
	MOV CX, 8
	REPE CMPSB
	JE Init26
	DEC DI
	MOV CH, 0FFh
	REPNE SCASB
	JMP Init24
Init25:	DW _XOR_DI_DI
Init26:	POP DS
	MOV [MD.ComSpec], DI
	DW _XOR_DI_DI  ; OvlPth
Init27:	CMP AL, [ES:DI]
	JE Init28
	MOV CH, 0FFh
	REPNE SCASB
	JMP Init27
Init28:	ADD DI, 3
	MOV [MD.OvlPth], DI
	MOV DI, MD.NcPath  ; NcPath
	PUSH ES
	PUSH DI
	CALL MainPth
	POP SI
	CALL PathLin
	POP ES
	MOV DI, MD.TempDir  ; TempDir
	MOV SI, TempEnv
	MOV CX, 5
	CALL MnPth0
	DW _XOR_AX_AX
	MOV [MD.DosCol], AL  ; DosCol
	MOV [MD.BegCol], AL  ; BegCol
	MOV [MD.OutCol], AL  ; OutCol
	MOV [MD.Quote], AL  ; Quote
	MOV [MD.SftErr], AL  ; SftErr
	MOV [MD.BlocEr], AL  ; BlocEr
	MOV [MD.TstEGA], AL  ; TstEGA
	MOV [MD.WinMous], AL  ; WinMous
	MOV [MD.WinLeav], AL  ; WinLeav
	MOV WORD [MD.HstAdr], MD.HstBuf  ; HstAdr
	MOV BYTE [MD.BarPrev], 0FFh  ; BarPrev
	MOV AH, 19h  ; DosChg
	INT 21h
	MOV [MD.DosChg], AL
	MOV AH, 12h  ; TstEGA
	MOV BX, 0FF10h
	INT 10h
	CMP BX, 0FF10h
	JE Init29
	MOV BYTE [MD.TstEGA], 1
Init29:	MOV AL, 25  ; Lines
	MOV DL, 0
	CMP [MD.TstEGA], DL
	JE Init30
	PUSH ES
	PUSH AX
	MOV BH, 0
	MOV AX, 1130h
	INT 10h
	POP AX
	POP ES
	DW _OR_DL_DL
	JE Init30
	INC DX
	MOV AL, MaxLins
	DW _CMP_AL_DL
	JBE Init30
	DW _MOV_AL_DL
Init30:	MOV [MD.Lines], AL
	MOV AH, 1  ; Snow
	CMP BYTE [MD.ScrMod], 7
	JE Init33
	CMP BYTE [MD.SnowMod], 1
	JE Init33
	MOV DX, 03DAh
	MOV BX, 8000h
	JB Init31
	CMP [MD.TstEGA], BL
	JNE Init33
Init31:	STI
	DEC BX
	JE Init33
	MOV CX, 7  ; Const2_1 ???
	CLI
Init32:	IN AL,DX
	TEST AL, 1
	JZ Init31
	LOOP Init32
	MOV AH, 0
Init33:	STI
	MOV [MD.Snow], AH
	CALL ScrOffs  ; Screen Offset
	MOV BX, 0B800h  ; Screen Segment
	CMP BYTE [MD.ScrMod], 7
	JNE Init34
	MOV BH, 0B0h
Init34:	MOV ES, BX  ; Virtual screen buffer
	MOV AH, 0FEh
	INT 10h
	MOV CX, ES
	PUSH DS
	POP ES
	MOV AL, 0
	DW _CMP_CX_BX
	JE Init35
	MOV AL, 1
	MOV [MD.Snow], AL
Init35:	MOV [MD.Screen+2], CX
	MOV [MD.TopView], AL
	MOV CX, 'ED'  ; Check DESQWIEV
	MOV DX, 'QS'
	MOV AX, 2B01h
	INT 21h
	INC AX
	MOV [MD.DesqVie], AL
	DW _XOR_BX_BX  ; VerDOS
	MOV AX, 3306h
	INT 21h
	XCHG AX, BX
	DW _OR_AX_AX
	JNE Init36
	MOV AH, 30h
	INT 21h
Init36:	CMP AX, STRICT WORD 4
	JNE Init37
	CMP BH, 0FFh
	JNE Init37
	MOV AH, 1
Init37:	MOV [MD.VerDOS], AX
	MOV SI, [MD.WCB1seg]  ; WCBseg
	MOV DI, [MD.WCB2seg]
	PUSH DS
	MOV DS, SI
	MOV BYTE [WCBdef.ChgFlg], 1
	MOV DS, DI
	MOV BYTE [WCBdef.ChgFlg], 1
	POP DS
	CMP BYTE [MD.Active], 0
	JE Init38
	DW _XCHG_DI_SI
Init38:	MOV [MD.WCBcrn], SI
	MOV [MD.WCBsec], DI

;---------------------- Set DOS color ------------------
	CALL CurNl
	MOV AX, 0E0Dh
	INT 10h
	MOV AX, 0E0Ah
	INT 10h
	CALL CurNl
	MOV AH, 8
	INT 10h
	PUSH AX
	MOV DL, ' '
	MOV AH, 6
	INT 21h
	MOV AX, 0E0Dh
	INT 10h
	MOV AH, 8
	INT 10h
	MOV [MD.CrntCol], AH
	POP AX
	DW _MOV_BL_AH
	MOV CX, 1
	MOV AH, 9
	INT 10h

;----------------------- Set cursor --------------------
Init40:	PUSH ES
	POP DS
	MOV AH, 0Fh
	INT 10h
	MOV AH, 3
	INT 10h
	CMP BYTE [MD.KeyBar], 0
	JE Init41
	MOV AL, [MD.Lines]
	DEC AX
	DW _CMP_DH_AL
	JB Init41
	DW _MOV_DH_AL
	DEC DH
	MOV AX, 0E0Ah
	INT 10h
Init41:	DW _MOV_AL_DH
	MOV [MD.MenuBuf], AL
	PUSH DS
	MOV DS, [MD.WCBcrn]
	CMP BYTE [WCBdef.Visible], 0
	POP DS
	JE Init42
	CALL BegBX
	CALL SizDX
	DW _ADD_DH_BH
	DW _CMP_AL_DH
	JAE Init42
	DW _MOV_AL_DH
Init42:	MOV [MD.DosLin], AL
	CALL HidCur

;--------------------- Save Screen ---------------------
	CALL SavScr
	CALL IniMous

;------------------ Save Main Windows ------------------
	MOV SI, MD.ScrBuf
	MOV DI, MD.UserScr
	MOV AL, [MD.Lines]
	DEC AX
	MOV AH, 80
	MUL AH
	DW _MOV_CX_AX
	REP MOVSW

;----------------------- Auto file ---------------------
	CMP BYTE [MD.LoadRes], 0FFh
	JNE Init49
	MOV BYTE [MD.LoadRes], 0
	PUSH SS
	POP DS
	MOV SI, 81h
	CALL FndLet
	CALL Init46
	JE Init49
	MOV DI, MD.DosBuf
Init43:	LODSB
	CALL Init46
	JE Init45
	CMP AL, 9
	JNE Init44
	MOV AL, ' '
Init44:	STOSB
	JMP Init43
Init45:	PUSH ES
	POP DS
	DW _XOR_AX_AX
	STOSW
	MOV AL, [MD.MenuBuf]
	DEC AX
	MOV [MD.DosLin], AL
	MOV AL, 81h
	XCHG AL, [MD.LoadFl]
	MOV [MD.LoadRes], AL
	JMP F21_31

;Init46	PROC	NEAR
;GLOBAL Init46
Init46:
	CMP AL, 0
	JE Init47
	CMP AL, 0Dh
	JE Init47
	CMP AL, 0Ah
Init47:	RET
;Init46	ENDP

%if SHWW-3  ; Not short freeware.
;GLOBAL Mvz2lin
Mvz2lin:  ; PROC NEAR  ; This procedure is only used in the shareware varsion.
	PUSH DS
	CALL MvzLin0
	PUSH ES
	POP DS
	DW _MOV_SI_BP
	CALL MvzLin0
	POP DS
	RET
;Mvz2lin ENDP
%endif

;GLOBAL CurNl
CurNl:  ; PROC NEAR
	MOV AH, 0Fh
	INT 10h
	MOV AH, 3
	INT 10h
	MOV AH, [MD.Lines]
	DW _CMP_DH_AH
	JB Init47
	DEC AH
	MOV AL, 0
	JMP Cursor
;CurNl ENDP

Init49:

;---------------- Output menu & key bar ----------------
	MOV AL, 0
	CALL PutMnu
	MOV AL, 0FFh
	CALL PutKey

;--------------------- Main windows --------------------
Init50:	CALL HidCur
	MOV SI, [ES:MD.WCBcrn]
	MOV DI, [ES:MD.WCBsec]
	MOV DS, DI
	MOV AL, [WCBdef.WinTyp]
	MOV DS, SI
	CMP AL, [WCBdef.WinTyp]
	JAE Init51
	MOV DS, DI
	DW _XCHG_SI_DI
Init51:	DW _XOR_BX_BX
	MOV DH, [ES:MD.Lines]
	MOV DL, 80
	MOV CL, 0
	CMP [WCBdef.ChgFlg], CL
	JE Init53
Init52:	MOV BYTE [ES:MD.BlocEr], 1
	CALL SetPth
	MOV BYTE [ES:MD.BlocEr], 0
Init53:	CALL PutPrm
	DW _XOR_AX_AX
	CMP [WCBdef.Visible], AL
	JNZ Init54
	JMP Init70
Init54:	CALL Panel
	CMP [WCBdef.ChgFlg], AL
	JE Init60
	CALL Window
	CMP [WCBdef.WinTyp], AL
	PUSH DS
	PUSH ES
	POP DS
	POP ES
	JNE Init55
	PUSH SI
	PUSH CX
	MOV SI, MD.DosPth
	MOV DI, WCBdef.WinPath
	CALL StrLen
	PUSH SI
	PUSH DI
	REPE CMPSB
	POP DI
	POP SI
	MOV CX, LenPath
	REP MOVSB
	POP CX
	POP SI
	MOV [MD.OldFlg], AL
	JNE Init55
	MOV BYTE [MD.OldFlg], 1
Init55:	CMP [MD.PathEr], AL
	PUSH DS
	PUSH ES
	POP DS
	POP ES
	JE Init56
	CALL Init90
	JMP Init59
Init56:	DW _OR_CL_CL
	JNE Init57
	CMP [ES:MD.OldFlg], AL
	JE Init57
	MOV AL, 1
Init57:	CMP BYTE [WCBdef.WinTyp], 0
	JNE Init58
	MOV BYTE [ES:MD.BlocEr], 1
Init58:	CALL ReDir
	MOV BYTE [ES:MD.BlocEr], 0
	JNC Init60
Init59:	MOV AH, 1
	DW _OR_CL_CL
	JNE Init60
	MOV CL, [WCBdef.WinPath]
Init60:	CALL PutPath
	CALL PutFls
	DW _OR_AH_AH
	JE Init62
	CALL Window
	CMP BYTE [WCBdef.WinTyp], 0
	JNE Init70
	MOV AL, [WCBdef.WinPath]
	CALL ErrRdy
	CMP AL, 0
	JE Init70
	DW _OR_CL_CL
	JNE Init61
	DW _MOV_CL_AL
Init61:	SUB AL, 'A'
	DW _MOV_DL_AL
	MOV AH, 0Eh
	INT 21h
	JMP Init52
Init62:	CMP CL, [WCBdef.WinPath]
	JNE Init70
	MOV CL, 0
Init70:	CALL InvWCB
	MOV AL, 1
	CMP BYTE [WCBdef.Visible], 0
	JNE Init71
	JMP Init80
Init71:	CALL Panel
	MOV AH, 0
	CMP [WCBdef.ChgFlg], AH
	JE Init77
	CALL Window
	CMP [WCBdef.WinTyp], AH
	JNE Init72
	CMP CL, [WCBdef.WinPath]
	JNE Init74
	MOV [WCBdef.WinPath+3], AH
	JMP Init73
Init72:	CMP [ES:MD.PathEr], AH
	JE Init75
Init73:	CALL Init90
	JMP Init76
Init74:	MOV BYTE [ES:MD.BlocEr], 1
Init75:	CALL ReDir
	MOV BYTE [ES:MD.BlocEr], 0
	JNC Init77
Init76:	MOV AH, 1
Init77:	CALL PutPath
	CALL PutFls
	CMP BYTE [WCBdef.WinTyp], 0
	JNE Init80
	DW _OR_AH_AH
	JE Init80
	CALL Window
	MOV AL, [WCBdef.WinPath]
	CALL ErrRdy
	CMP AL, 0
	JE Init80
	MOV SI, WCBdef.WinPath+3
	MOV BYTE [SI], 0
	DW _MOV_CL_AL
	MOV [WCBdef.WinPath], AL
	SUB AL, 'A'-1
	DW _MOV_DL_AL
	CALL Fantom
	JC Init78
	MOV AH, 47h
	MOV BYTE [ES:MD.BlocEr], 1
	CALL Intr21
	MOV BYTE [ES:MD.BlocEr], 0
	JC Init78
	MOV CL, 0
Init78:	MOV AL, 0
	JMP Init71
Init80:	MOV DS, [ES:MD.WCBcrn]
	JMP Func02

;GLOBAL Init90
Init90:  ; PROC NEAR
	PUSH DS
	PUSH AX
	DW _XOR_AX_AX
	CMP [WCBdef.WinTyp], AL
	JNE Init91
	MOV AX, WCBdef.DskBuf
	MOV [WCBdef.EndBuf], AX
	MOV [WCBdef.EndFul], AX
	MOV [WCBdef.CurAdr], AX
	MOV [WCBdef.First], AX
	JMP Init93
Init91:	CMP BYTE [WCBdef.WinTyp], 2
	PUSH ES
	POP DS
	JNE Init92
	MOV [MD.Total], AX
	MOV [MD.FreeDsk], AX
	MOV WORD [MD.ClstSiz], 1
	MOV [MD.Volume], AL
	DEC AX
	MOV [MD.InfoLen], AX
	JMP Init93
Init92:	JA Init93  ; ???
	MOV DI, MD.TreeBuf+DIRTREE_TreList
	PUSH DI
	PUSH CX
	MOV CX, 16
	REP STOSB
	POP CX
	POP DI
	MOV BYTE [DI+DIRENT.DirName], '\'
	MOV BYTE [DI+DIRENT.DirShift], 1
	MOV WORD [MD.TreeBuf+DIRTREE.TreeLen], 1
	MOV AX, MD.TreeBuf+DIRTREE_TreList
	MOV [MD.TreFrst], AX
	MOV [MD.TreAdr], AX
Init93:	POP AX
	POP DS
	RET
;Init90 ENDP

;GLOBAL OutStr1
OutStr1:  ; PROC NEAR
	PUSH CS
	POP DS
	MOV AX, OutStr
	JMP CallPSP
;OutStr1 ENDP

;-------------------------------------------------------
Func01:	CALL Panel
	CALL PutPath
	CALL PutFls
Func02:	DW _XOR_BX_BX
	MOV DH, [ES:MD.Lines]
	MOV DL, 80
Func03:	CALL Window
Func04:	DW _XOR_AX_AX
	CALL PutMnu
	PUSH ES
	POP DS
	MOV [MD.OneFile], AL
	MOV [MD.FlagCD], AL
	MOV [MD.MousEnt], AL
	DEC AX
	MOV [MD.MousTim+2], AX
Func05:	CALL MakeIni
	PUSH SS
	POP ES
	MOV DI, IniSave
	CMP WORD [ES:DI], 'VV'
	JNE Func06
	PUSH CX
	MOV AX, WCBdef.WinPath+3
	MOV CX, LenPath
	PUSH CX
	CALL Func15
	POP CX
	MOV AX, WCBdef.WinPath+3+WCBdef_WCBini
	CALL Func15
	POP CX
	MOV BX, MD.Active+3+2*WCBdef_WCBini
	MOV AL, [SI+BX]
	MOV [ES:DI+BX], AL
	MOV BX, MD.Ctrl_O+3+2*WCBdef_WCBini
	MOV AL, [SI+BX]
	MOV [ES:DI+BX], AL
	PUSH SI
	PUSH DI
	PUSH CX
	DEC CX
	DEC CX
	REPE CMPSB
	POP CX
	POP DI
	POP SI
	JE Func06
	CMP BYTE [MD.AutoSav], 0
	JZ Func06
	PUSH DS
	POP ES
	CALL HidCur
	MOV BYTE [MD.BlocEr], 1
	CALL SaveSet
	MOV BYTE [MD.BlocEr], 0
Func06:	PUSH SS
	POP ES
	REP MOVSB
	PUSH DS
	POP ES
Func07:	CALL Cursor1
	MOV DS, [ES:MD.WCBcrn]
	PUSH DS
	DW _XOR_AX_AX
	CMP [ES:MD.AutoCD], AL
	JZ Func09
	CMP BYTE [WCBdef.WinTyp], 1
	JNE Func09
	CMP [WCBdef.Visible], AL
	JZ Func09
	PUSH ES
	POP DS
	MOV DI, MD.DosPth
	CALL StrLen
	MOV SI, MD.CrnPath
	REPE CMPSB
	JE Func09
	CMP [MD.FlagCD], AL
	JZ Func09
	MOV AH, 2Ch
	INT 21h
	ADD DL, [MD.DelayTm+0]
	CMP DL, 100
	JB Func08
	SUB DL, 100
	INC DH
Func08:	ADD DH, [MD.DelayTm+1]
	CMP DH, 60
	JB Func10
	SUB DH, 60
	INC CX
	CMP CL, 60
	JB Func10
	SUB CL, 60
	INC CH
	CMP CH, 24
	JB Func10
	MOV CH, 0
	JMP Func10
Func09:	MOV CX, 0FFFFh
Func10:	POP DS
	MOV [ES:MD.AutoTim+0], CX
	MOV [ES:MD.AutoTim+2], DX
	DW _XOR_CX_CX
	MOV [ES:MD.HlpPage], CL
	XCHG CH, [ES:MD.MenuFl]
	MOV AX, 3C00h
	DW _OR_CH_CH
	JNE Func12
	CALL GetMous
	JNZ Func21
	MOV AL, 0
	MOV [ES:MD.WinMous], AL
	MOV [ES:MD.MousEnt], AL
	CMP [ES:MD.TstEGA], AL
	JNE Func11
	MOV AL, 9
Func11:	CALL Input
	CMP AH, 0FCh
	JE Func20
	CMP BYTE [WCBdef.Visible], 0
	JZ Func12
	CMP BYTE [WCBdef.WinTyp], 1
	JA Func12
	CMP AL, 0
	JNE Func12
	DW _XCHG_AL_AH
	PUSH ES
	PUSH CS
	POP ES
	MOV DI, AltSr_T
	MOV CX, 12+10+9+7
	REPNE SCASB
	POP ES
	DW _XCHG_AL_AH
	JNE Func12
	JMP F77_00
Func12:	CMP AH, 0FCh
	JE Func20
	CMP BYTE [ES:MD.Quote], 0
	JNZ Func14
	MOV SI, FncTab
	CALL Case
Func14:	JMP F73_00

;GLOBAL Func15
Func15:  ; PROC NEAR
	PUSH SI
	PUSH DI
	DW _ADD_SI_AX
	DW _ADD_DI_AX
	REP MOVSB
	POP DI
	POP SI
	RET
;Func15 ENDP

Func20:	CALL GetMous  ; Mouse support
Func21:	CALL ClrKbd
	CMP BYTE [ES:MD.WinMous], 0
	JNZ Func30
	CMP CX, 2  ; Panels on/off
	JAE Func25
	MOV BL, 0
Func22:	CALL GetMous
	JZ Func24
	MOV AL, 0
	CMP CX, 2
	JAE Func23
	MOV AL, 'þ'
Func23:	DW _CMP_AL_BL
	JE Func22
	DW _MOV_BL_AL
	CALL TypMous
	JMP Func22
Func24:	MOV AL, 0
	CALL TypMous
	DW _OR_BL_BL
	JE Func35
	JMP F11_00

Func25:	DW _OR_CH_CH  ; Pull down menu
	JNE Func26
	JMP F39_00
Func26:	CALL BegBX
	CALL SizDX
	DW _ADD_DH_BH
	DW _CMP_CH_DH
	JAE Func35

	CMP CL, 40  ; Change panel
	JAE Func27
	MOV DS, [ES:MD.WCB1seg]
	CMP BYTE [ES:MD.Active], 0
	JE Func30
	JMP Func28
Func27:	MOV DS, [ES:MD.WCB2seg]
	CMP BYTE [ES:MD.Active], 0
	JNE Func30
Func28:	MOV DS, [ES:MD.WCBcrn]
	JMP F20_00

Func30:	TEST AL, 3
	JZ Func35
	CMP BYTE [WCBdef.Visible], 0
	JZ Func35
	CMP BYTE [WCBdef.WinTyp], 2
	JB Func40
	JNE Func35
	CALL BegBX  ; Edit 'dirinfo'
	CALL SizDX
	ADD BX, 0B01h
	SUB DX, 0C02h
	CALL InWind
	JC Func35
	JMP F34_10
Func35:	JMP Func07


Func40:	OR BYTE [ES:MD.WinMous], 1  ; Move the cursor
	MOV [ES:TmpMous], CX
	PUSH AX
	CALL AdrNum
	POP BP
	CALL BegBX
	DW _CMP_CL_BL
	JB Func35
	PUSH BX
	ADD BL, 40
	DW _CMP_CL_BL
	POP BX
	JAE Func35
	INC BH
	CMP BYTE [WCBdef.WinTyp], 0
	JNE Func41
	INC BH
Func41:	DW _SUB_CH_BH
	JB Func50
	DW _CMP_CH_AL
	JAE Func55
	DW _SUB_CL_BL  ; Set cursor position
	CMP CL, 39
	JAE Func35
	MOV BL, [WCBdef.WinTyp]
	OR BL, [WCBdef.BrfFul]
	JNE Func42
	DW _XCHG_AL_CL
	CBW
	MOV BL, 13
	DIV BL
	DW _XCHG_AH_CL
	MUL AH
	DW _ADD_CH_AL
Func42:	DW _OR_CL_CL
	JE Func35
	DW _MOV_AL_CH
	CBW
	DW _ADD_AX_DI
	DW _MOV_SI_AX
	DW _CMP_SI_DX
	JBE Func43
	DW _MOV_SI_DX
	JMP Func45
Func43:	TEST BP, 1
	JNZ Func60
Func45:	JMP F00_60

Func50:	DW _MOV_SI_DI  ; Scroll up
	JMP F00_05

Func55:	MOV BL, [WCBdef.WinTyp]  ; Scroll down
	OR BL, [WCBdef.BrfFul]
	JNE Func56
	MOV AH, 3
	MUL AH
Func56:	DEC AX
	DW _MOV_SI_DI
	DW _ADD_SI_AX
	DW _CMP_SI_DX
	JBE Func57
	DW _MOV_SI_DX
Func57:	JMP F01_05

Func60:	MOV CX, [ES:TmpMous]  ; Double click
	CALL BegBX
	INC BX
	DW _MOV_BH_CH
	MOV DX, 126h
	MOV CH, 0
	MOV AL, [WCBdef.WinTyp]
	OR AL, [WCBdef.BrfFul]
	JNE Func61
	DW _MOV_AL_CL
	DW _SUB_AL_BL
	CBW
	MOV CL, 13
	DIV CL
	MUL CL
	DW _ADD_BL_AL
	MOV DL, 12
Func61:	CALL DoublMo
	JC Func45
	JNE Func62
	JMP Func04
Func62:	MOV AL, 0
	CALL TypMous
	JMP F21_10

; --- include vcfunc.inc

;-------------------------------------------------------
;		Version :	07.06.2000
;-------------------------------------------------------

;GLOBAL AdrNum
AdrNum:  ; PROC NEAR
	CMP BYTE [WCBdef.WinTyp], 0
	JNE AdrNm1
	MOV AX, [WCBdef.CurAdr]
	CALL FilNum
	DW _MOV_SI_AX
	MOV AX, [WCBdef.First]
	CALL FilNum
	DW _MOV_DI_AX
	MOV AX, [WCBdef.EndBuf]
	CALL FilNum
	DW _MOV_DX_AX
	CALL LnsAX
	JMP AdrNm2
AdrNm1:	MOV AX, [ES:MD.TreAdr]
	CALL TreNum
	DW _MOV_SI_AX
	MOV AX, [ES:MD.TreFrst]
	CALL TreNum
	DW _MOV_DI_AX
	CALL SizDX
	DW _MOV_AL_DH
	SUB AL, 4
	CBW
	MOV DX, [ES:MD.TreeBuf+DIRTREE.TreeLen]
AdrNm2:	DW _OR_DX_DX
	JE AdrNm3
	DEC DX
AdrNm3:	DW _MOV_BX_AX
	RET
;AdrNum ENDP

;FilNum	PROC	NEAR
;GLOBAL FilNum
FilNum:
	SUB AX, STRICT WORD WCBdef.DskBuf
	MOV BX, FILENT_size
	JMP TreNm1
TreNum:	SUB AX, STRICT WORD MD.TreeBuf+DIRTREE_TreList
	MOV BX, DIRENT_size
TreNm1:	DW _XOR_DX_DX
	DIV BX
	RET
;FilNum	ENDP

;NumAdr	PROC	NEAR
;GLOBAL NumAdr
NumAdr:
	CMP BYTE [WCBdef.WinTyp], 0
	JNE NumAd1
	MOV AX, FILENT_size
	MUL SI
	ADD AX, STRICT WORD WCBdef.DskBuf
	DW _MOV_SI_AX
	RET
NumAd1:	MOV AX, DIRENT_size
	MUL SI
	ADD AX, STRICT WORD MD.TreeBuf+DIRTREE_TreList
	DW _MOV_SI_AX
	RET
;NumAdr	ENDP

;GLOBAL ChgAdr
ChgAdr:  ; PROC NEAR
	CMP BYTE [WCBdef.WinTyp], 0
	JNE ChgAd1
	XCHG SI, [WCBdef.CurAdr]
	XCHG DI, [WCBdef.First]
	RET
ChgAd1:	XCHG SI, [ES:MD.TreAdr]
	XCHG DI, [ES:MD.TreFrst]
	RET
;ChgAdr ENDP

;GLOBAL F00_50
F00_50:  ; PROC NEAR
	CALL ChgAdr
	CALL CorPar
	DW _MOV_CX_DI
	MOV AX, FILENT_size
	MOV BX, [WCBdef.First]
	MOV DX, [WCBdef.CurAdr]
	CMP BYTE [WCBdef.WinTyp], 0
	JE F00_51
	MOV AX, 16
	MOV BX, [ES:MD.TreFrst]
	MOV DX, [ES:MD.TreAdr]
	DW _CMP_SI_DX
	JE F00_51
	MOV BYTE [ES:MD.FlagCD], 1
F00_51:	DW _SUB_CX_BX
	JE F00_52
	MOV BL, 7
	DW _CMP_CX_AX
	JE F00_53
	MOV BL, 6
	NEG AX
	DW _CMP_CX_AX
	JE F00_53
	CALL PutFls
	CALL BegBX
	CALL SizDX
	JMP F00_58
F00_52:	DW _CMP_SI_DX
	JNE F00_53
	JMP F00_59
F00_53:	CALL ChgAdr
	MOV AL, 0
	CALL SetCur
	CALL ChgAdr
	CALL PutFls
	JCXZ F00_57
	DW _MOV_AL_BL
	PUSH AX
	CALL BegBX
	LEA CX, [BX+201h]
	CALL SizDX
	SUB DH, 4
	CMP BYTE [WCBdef.WinTyp], 0
	JE F00_54
	DEC CH
	DEC DH
	JMP F00_55
F00_54:	CMP BYTE [ES:MD.MiniSta], 0
	JZ F00_55
	SUB DH, 2
F00_55:	MOV DL, 38-1
	DW _ADD_DX_CX
	MOV AH, Back_C
	CALL Color
	DW _MOV_BH_AH
	DW _MOV_AH_AL
	MOV AL, 1
	CALL Int10m
	POP AX
	DW _MOV_BX_CX
	CMP AL, 7
	JE F00_56
	DW _MOV_BH_DH
F00_56:	MOV DX, 126h
	CALL Window
F00_57:	MOV AL, 1
	CALL SetCur
	MOV AL, [WCBdef.WinTyp]
	OR AL, [ES:MD.MiniSta]
	JZ F00_59
	CALL BegBX
	CALL SizDX
	DW _ADD_BH_DH
	SUB BH, 2
	INC BL
	MOV DX, 126h
F00_58:	CALL Window
F00_59:	RET
;F00_50 ENDP

F00_60:	TEST BP, 2  ; Scroll & select
	JZ F00_63
	CMP BYTE [WCBdef.WinTyp], 0
	JNE F00_70
	PUSH SI
	CALL NumAdr
	DW _MOV_BX_SI
	POP SI
	CMP BX, [WCBdef.EndBuf]
	JAE F00_70
	CMP BYTE [BX+FILENT.NameF], '.'
	JE F00_70
	TEST BYTE [ES:MD.WinMous], 2
	JNZ F00_61
	OR BYTE [ES:MD.WinMous], 2
	TEST BYTE [BX+FILENT.AttrF], 40h
	JNZ F00_61
	OR BYTE [ES:MD.WinMous], 4
F00_61:	MOV AL, [BX+FILENT.AttrF]
	AND AL, 0BFh
	TEST BYTE [ES:MD.WinMous], 4
	JZ F00_62
	OR AL, 40h
F00_62:	CMP AL, [BX+FILENT.AttrF]
	JE F00_70
	MOV [BX+FILENT.AttrF], AL
	CALL F08_10
	JMP F00_70
F00_63:	AND BYTE [ES:MD.WinMous], 1

F00_70:	CALL NumAdr
	DW _XCHG_SI_DI
	CALL NumAdr
	DW _XCHG_SI_DI
	CALL F00_50
F00_80:	JMP Func07

F00_00:	CMP BYTE [WCBdef.Visible], 0  ; Up
	JNZ F00_01
	JMP F25_00
F00_01:	CMP BYTE [WCBdef.WinTyp], 1
	JA F00_80
	CALL AdrNum
	DW _XOR_BP_BP
F00_05:	DW _OR_SI_SI
	JE F00_06
	DEC SI
F00_06:	JMP F00_60

F01_00:	CMP BYTE [WCBdef.Visible], 0  ; Down
	JNZ F01_01
	JMP F26_00
F01_01:	CMP BYTE [WCBdef.WinTyp], 1
	JA F00_80
	CALL AdrNum
	DW _XOR_BP_BP
F01_05:	DW _CMP_SI_DX
	JAE F01_06
	INC SI
F01_06:	JMP F00_60

F02_00:	MOV AL, 0  ; Left
	CMP AL, [WCBdef.Visible]
	JZ F02_10
	CMP AL, [WCBdef.WinTyp]
	JNE F02_10
	CMP AL, [WCBdef.BrfFul]
	JNE F02_10
	CALL AdrNum
	DW _MOV_AX_SI
	DW _SUB_AX_DI
	DW _CMP_AX_BX
	JB F02_02
	DW _SUB_SI_BX
F02_01:	JMP F00_70
F02_02:	DW _SUB_SI_BX
	JAE F02_03
	DW _XOR_SI_SI
F02_03:	DW _SUB_DI_BX
	JAE F02_01
	JMP F06_01
F02_10:	JMP F73_00

F03_00:	MOV AL, 0  ; Right
	CMP AL, [WCBdef.Visible]
	JZ F02_10
	CMP AL, [WCBdef.WinTyp]
	JNE F02_10
	CMP AL, [WCBdef.BrfFul]
	JNZ F02_10
	CALL AdrNum
	DW _MOV_AX_SI
	DW _SUB_AX_DI
	CALL F03_30
	DW _MOV_BP_BX
	DW _ADD_BP_BP
	DW _CMP_AX_BP
	JB F02_01
	DW _XCHG_SI_DI
	CALL F03_30
	DW _XCHG_SI_DI
	DW _ADD_BP_BX
	DW _MOV_AX_DX
	DW _SUB_AX_DI
	INC AX
	DW _CMP_AX_BP
	JAE F02_01
	DW _OR_DI_DI
	JE F02_01
	JMP F07_01

;GLOBAL F03_30
F03_30:  ; PROC NEAR
	DW _ADD_SI_BX
	DW _CMP_SI_DX
	JBE F03_31
	DW _MOV_SI_DX
F03_31:	RET
;F03_30 ENDP

F04_00:	CMP BYTE [WCBdef.Visible], 0  ; PgUp
	JZ F05_10
	CMP BYTE [WCBdef.WinTyp], 1
	JA F05_10
	CALL F04_30
	DW _OR_DI_DI
	JNE F04_01
	JMP F06_01
F04_01:	DW _SUB_DI_BX
	JAE F04_02
	DW _XOR_DI_DI
F04_02:	DW _ADD_BX_DI
	DW _CMP_BX_SI
	JAE F04_03
	DW _MOV_SI_BX
F04_03:	JMP F00_70

;GLOBAL F04_30
F04_30:  ; PROC NEAR
	CALL AdrNum
	MOV AL, [WCBdef.WinTyp]
	OR AL, [WCBdef.BrfFul]
	DW _MOV_AX_BX
	JNZ F04_31
	DW _ADD_BX_AX
	DW _ADD_BX_AX
F04_31:	DEC BX
	RET
;F04_30 ENDP

F05_00:	CMP BYTE [WCBdef.Visible], 0  ; PgDn
	JZ F05_10
	CMP BYTE [WCBdef.WinTyp], 1
	JA F05_10
	CALL F04_30
	DW _MOV_CX_DI
	DW _XCHG_SI_DI
	CALL F03_30
	DW _XCHG_SI_DI
	DW _MOV_AX_DX
	DW _SUB_AX_BX
	JAE F05_01
	DW _XOR_AX_AX
F05_01:	DW _CMP_DI_AX
	JBE F05_02
	DW _MOV_DI_AX
F05_02:	DW _CMP_DI_CX
	JBE F05_04
	DW _CMP_DI_SI
	JBE F05_03
	DW _MOV_SI_DI
F05_03:	JMP F00_70
F05_04:	JMP F07_01
F05_10:	JMP Func07

F06_00:	CMP BYTE [WCBdef.Visible], 0  ; Home
	JZ F06_10
	CMP BYTE [WCBdef.WinTyp], 1
	JA F06_10
	CALL AdrNum
F06_01:	DW _XOR_SI_SI
	DW _XOR_DI_DI
	JMP F00_70
F06_10:	JMP F73_00

F07_00:	CMP BYTE [WCBdef.Visible], 0  ; End
	JZ F06_10
	CMP BYTE [WCBdef.WinTyp], 1
	JA F06_10
	CALL AdrNum
F07_01:	DW _MOV_SI_DX
	DW _MOV_DI_DX
	JMP F00_70

F08_00:	CALL FilePan  ; Ins
	JNC F05_10
	MOV SI, [WCBdef.CurAdr]
	CMP SI, [WCBdef.EndBuf]
	JAE F05_10
	PUSH SI
	CMP BYTE [ES:MD.InsDwn], 0
	JZ F08_01
	ADD SI, FILENT_size
	CMP SI, [WCBdef.EndBuf]
	JAE F08_01
	PUSH DS
	DW _XOR_AX_AX
	MOV DS, AX
	AND BYTE [418h], 7Fh
	POP DS
F08_01:	POP SI
	CMP BYTE [SI+FILENT.NameF], '.'
	JE F08_02
	XOR BYTE [SI+FILENT.AttrF], 40h
F08_02:	CALL F08_10
	CMP BYTE [ES:MD.InsDwn], 0
	JZ F05_10
	JMP F01_01

;GLOBAL F08_10
F08_10:  ; PROC NEAR
	MOV AL, 1
	CALL SetCur
	CMP BYTE [ES:MD.MiniSta], 0
	JZ F08_11
	CALL PutFls
	CALL BegBX
	CALL SizDX
	DW _ADD_BH_DH
	SUB BH, 2
	INC BX
	MOV DX, 126h
	CALL Window
F08_11:	RET
;F08_10 ENDP

F76_00:	CMP BYTE [ES:MD.DosBuf], 0  ; Grey *
	JNE F76_02
F76_01:	MOV DX, Inv_S
	JMP F10_01
F76_02:	JMP F73_00

F09_00:	MOV DX, Sel_S  ; Grey +
	JMP F10_01

F10_00:	MOV DX, Unsl_S  ; Grey -
F10_01:	CALL FilePan
	JNC F76_02
	PUSH DS
	PUSH ES
	POP DS
	MOV BP, Sel_B
	CALL Dialog
	POP DS
	JNE F10_08
	MOV SI, MD.SelMas
	CMP BYTE [ES:SI], 0
	JE F10_08
	PUSH DS
	PUSH ES
	POP DS
	MOV DI, MD.TmpBuf
	CALL Convert
	POP DS
	MOV CH, 0
	MOV SI, WCBdef.DskBuf
F10_03:	CMP SI, [WCBdef.EndBuf]
	JAE F10_07
	CMP BYTE [SI+FILENT.NameF], '.'
	JE F10_06
	CALL TstMas
	JNC F10_06
	CMP DX, Unsl_S
	JNE F10_04
	MOV CH, 1
	AND BYTE [SI+FILENT.AttrF], 0BFh
	JMP F10_06
F10_04:	TEST BYTE [SI+FILENT.AttrF], 10h
	JNZ F10_06
	MOV CH, 1
	CMP DX, Sel_S
	JNE F10_05
	OR BYTE [SI+FILENT.AttrF], 40h
	JMP F10_06
F10_05:	XOR BYTE [SI+FILENT.AttrF], 40h
F10_06:	ADD SI, FILENT_size
	JMP F10_03
F10_07:	DW _OR_CH_CH
	JNZ F10_09
	PUSH ES
	POP DS
	MOV BP, ErSel_B
	CALL Dialog
F10_08:	JMP Func04
F10_09:	JMP Func01

F78_00:	CALL FilePan  ; ^M - restore marks
	JNC F10_08
	MOV SI, WCBdef.DskBuf
F78_01:	CMP SI, [WCBdef.EndBuf]
	JAE F10_09
	CMP BYTE [SI+FILENT.NameF], '.'
	JE F78_02
	TEST BYTE [SI+FILENT.AttrF], 80h
	JZ F78_02
	OR BYTE [SI+FILENT.AttrF], 40h
F78_02:	ADD SI, FILENT_size
	JMP F78_01

F11_00:	CMP BYTE [WCBdef.Visible], 0  ; ^O
	PUSH DS
	MOV DS, [ES:MD.WCBsec]
	JZ F11_01
	MOV AL, [WCBdef.Visible]  ; Panels Off
	MOV [ES:MD.Ctrl_O], AL
	MOV BYTE [WCBdef.Visible], 0
	POP DS
	MOV BYTE [WCBdef.Visible], 0
	CALL BegBX
	CALL SizDX
	MOV BL, 0
	MOV DL, 80
	CALL ResUser
	JMP Func03
F11_01:	MOV AL, [ES:MD.Ctrl_O]  ; Panels On
	MOV [WCBdef.Visible], AL
	MOV AH, [WCBdef.ChgFlg]
	POP DS
	MOV BYTE [WCBdef.Visible], 1
	CMP BYTE [WCBdef.ChgFlg], 0
	JNZ F11_02
	CMP AL, 0
	JZ F11_03
	CMP AH, 0
	JZ F11_03
F11_02:	CALL PutMnu3
F11_03:	JMP Init50

F12_00:	CMP BYTE [WCBdef.Visible], 0  ; ^P
	PUSH DS
	MOV DS, [ES:MD.WCBsec]
	MOV CL, 0
	JNZ F14_01
	POP DS
	JMP Func05

F13_00:	PUSH DS  ; ^F1
	MOV DS, [ES:MD.WCB1seg]
	MOV CL, 1
	JMP F14_01

F14_00:	PUSH DS  ; ^F2
	MOV DS, [ES:MD.WCB2seg]
	MOV CL, 5
F14_01:	JMP M06_00

F15_00:	CMP BYTE [WCBdef.Visible], 0  ; ^U
	JNZ F15_01
	JMP Func04
F15_01:	MOV AX, [ES:MD.WCB1seg]
	XCHG AX, [ES:MD.WCB2seg]
	MOV [ES:MD.WCB1seg], AX
	MOV BX, MD.Active
	CALL InvVar
	CALL BegBX
	CALL SizDX
	MOV BL, 0
	MOV DL, 80
	CALL ResUser
	JMP Init50

F16_00:	PUSH ES  ; ^B
	POP DS
	MOV BH, [MD.Lines]
	DEC BH
	CMP BYTE [MD.KeyBar], 0
	JZ F16_02
	DW _XOR_AX_AX
	MOV [MD.KeyBar], AL
	MOV BYTE [MD.BarPrev], 0FFh
	CALL ClsLine
	MOV DX, 150h
	CALL Window
F16_01:	JMP Func04
F16_02:	MOV BYTE [MD.KeyBar], 1
	CMP BH, [MD.DosLin]
	JNE F16_01
	CALL BegBX
	CALL SizDX
	MOV BL, 0
	MOV DL, 80
	CALL ResUser
	CALL Window
	CALL Cursor1
	CALL SavMous
	MOV AL, 0
	CALL CurMous
	JMP Init40

F17_00:	PUSH DS  ; ^R
F17_01:	MOV AL, [WCBdef.WinTyp]
	CMP AL, 0
	JE F17_04
	CMP AL, 2
	JA F17_03
	JE F17_02
	MOV SI, MD.DosPth
	CALL DelTr0
	JC F17_03
F17_02:	MOV CH, 5
	DW _SUB_CH_AL
	JMP M03_00
F17_03:	POP DS  ; ???
	JMP Func04
F17_04:	MOV SI, [WCBdef.EndBuf]
	MOV [WCBdef.CurAdr], SI
	MOV [SI], AL
	MOV SI, WCBdef.DskBuf
F17_05:	CMP SI, [WCBdef.EndBuf]
	JAE F17_06
	AND BYTE [SI+FILENT.AttrF], 0BFh
	ADD SI, FILENT_size
	JMP F17_05
F17_06:	MOV BYTE [WCBdef.ChgFlg], 1
	MOV CL, [WCBdef.SortTyp]
	MOV CH, [WCBdef.BrfFul]
	JMP M01_01

F79_00:	MOV AL, 1  ; ^Z - tree
	JMP F18_01

F18_00:	MOV AL, 2  ; ^L - info
F18_01:	CMP BYTE [WCBdef.Visible], 0
	JE F18_03
	PUSH DS
	CMP AL, [WCBdef.WinTyp]
	JE F18_02
	CALL InvWCB
	CMP BYTE [WCBdef.Visible], 0
	JZ F17_02
	CMP AL, [WCBdef.WinTyp]
	JNE F17_02
F18_02:	MOV AL, [WCBdef.Ctrl_L]
	CMP AL, 0
	JE F17_06
	JMP F17_02
F18_03:	JMP Func04

F20_00:	PUSH DS  ; Tab
	CALL InvWCB
	MOV AX, DS
	CMP BYTE [WCBdef.Visible], 0
	POP DS
	JNZ F20_01
	JMP Func05
F20_01:	XCHG AX, [ES:MD.WCBcrn]
	CALL PutPath
	CALL PutFls
	XCHG AX, [ES:MD.WCBcrn]
	CALL F20_02
	CALL PutPath
	JMP Func01

;GLOBAL F20_02
F20_02:  ; PROC NEAR
	DW _XOR_BX_BX
	MOV DH, [ES:MD.Lines]
	MOV DL, 80
	CMP BYTE [WCBdef.WinTyp], 0
	MOV DS, [ES:MD.WCBsec]
	JNE F20_03
	CMP BYTE [WCBdef.WinTyp], 0
	JNE F20_03
	CMP BYTE [ES:MD.PathEr], 0
	JNZ F20_04
	PUSH ES
	MOV ES, [ES:MD.WCBcrn]
	MOV SI, WCBdef.WinPath
	DW _MOV_DI_SI
	CALL StrLen
	REPE CMPSB
	POP ES
	JNE F20_04
	JMP F20_08
F20_03:	CMP BYTE [ES:MD.PathEr], 0
	JZ F20_08
	CALL HidCur
	CALL Window
	JMP F20_07
F20_04:	CALL HidCur
	CALL Window
	MOV AL, [WCBdef.WinPath]
	SUB AL, 'A'-1
	CALL Fantom
	JC F20_05
	MOV DX, WCBdef.WinPath
	MOV AH, 3Bh
	CALL Intr21
	JNC F20_06
	CMP AX, STRICT WORD 3
	JE F20_06
F20_05:	MOV SI, WCBdef.WinPath
	MOV DI, MD.DosPth
	MOV CX, 3
	REP MOVSB
	MOV AL, 0
	STOSB
	MOV BYTE [ES:MD.PathEr], 1
	MOV BYTE [WCBdef.ChgFlg], 1
	MOV DL, [WCBdef.WinPath]
	SUB DL, 'A'
	MOV AH, 0Eh
	INT 21h
	JMP F20_08
F20_06:	MOV DL, [WCBdef.WinPath]
	SUB DL, 'A'
	MOV AH, 0Eh
	INT 21h
F20_07:	CALL SetPth
F20_08:	CALL PutPrm
	MOV AX, [ES:MD.WCBcrn]
	XCHG AX, [ES:MD.WCBsec]
	MOV [ES:MD.WCBcrn], AX
	MOV DS, AX
	MOV BX, MD.Active
	CALL InvVar
	RET
;F20_02 ENDP

F21_00:	CMP BYTE [ES:MD.DosBuf], 0  ; Enter
	JNE F21_01
	CMP BYTE [WCBdef.Visible], 0
	JNZ F21_10
F21_01:	JMP F21_25
F21_10:	CMP BYTE [WCBdef.WinTyp], 1  ; Tree
	JNE F21_20
	PUSH DS
	PUSH ES
	POP DS
	CMP WORD [MD.TreeBuf+DIRTREE.TreeLen], 0
	JE F21_12
	CALL HidCur
	MOV AL, [MD.DosPth]
	SUB AL, 'A'-1
	CALL Fantom
	JC F21_12
	MOV DX, MD.CrnPath+2
	CMP BYTE [MD.CrnPath+3], 0
	JE F21_11
	CALL SetDTA
	MOV CX, 37h
	MOV AH, 4Eh
	CALL Intr21
	JC F21_12
	TEST BYTE [MD.DTA+DTAs.FilAttr], 10h
	JZ F21_12
F21_11:	MOV AH, 3Bh
	CALL Intr21
	JC F21_12
	POP DS
	JMP F24_02
F21_12:	POP DS
F21_13:	JMP Func04
F21_20:	CMP BYTE [WCBdef.WinTyp], 0  ; Files
	JNE F21_13
	MOV SI, [WCBdef.CurAdr]
	CMP SI, [WCBdef.EndBuf]
	JAE F21_13
	TEST BYTE [SI+FILENT.AttrF], 10h
	JZ F21_21
	JMP F23_02
F21_21:	CALL TstExe
	JC F21_22
	MOV SI, WCBdef.ExtBuf  ; Test extension
	MOV DI, MD.MenuBuf
	MOV CX, LenMenu-1
	REP MOVSB
	MOV AL, 1Ah
	STOSB
	MOV SI, [WCBdef.CurAdr]
	CALL FindExt
	JC F21_13
	DEC SI
	MOV BYTE [ES:SI], ' '
	DW _XOR_BP_BP
	JMP Run_00
F21_22:	MOV BX, [WCBdef.CurAdr]  ; Run file from panel
	DW _XOR_DX_DX
	MOV SI, MD.DosBuf
	MOV [ES:SI], DL
	MOV CX, LenCmd-1
	MOV AH, 0
F21_23:	MOV AL, [BX]
	CMP AL, 0
	JE F21_24
	INC BX
	CALL EdLin
	JC F21_23
F21_24:	MOV [ES:MD.DosCol], DL
	CALL DosCom
	CALL Cursor1
F21_25:	MOV DI, MD.DosBuf  ; Run command from DOS line
	PUSH DI
	MOV CX, 256
	MOV AL, 0
	REPNE SCASB
	POP SI
	DW _MOV_CX_DI
	DW _SUB_CX_SI
	STOSB
	CMP CX, 1
	JE F21_30
	MOV DI, MD.HstBuf+1
	PUSH CX
	PUSH DS
	PUSH ES
	POP DS
	REPE CMPSB
	POP DS
	POP BX
	JE F21_30
	MOV DI, MD.HstBuf+LenHist-1
	DW _MOV_SI_DI
	DW _SUB_SI_BX
	MOV CX, LenHist
	DW _SUB_CX_BX
	PUSH DS
	PUSH ES
	POP DS
	STD
	REP MOVSB
	CLD
	MOV SI, MD.DosBuf
	MOV DI, MD.HstBuf+1
	DW _MOV_CX_BX
	REP MOVSB
	POP DS
	MOV AL, 0
F21_26:	CMP AL, [ES:DI]
	JE F21_30
	DW _MOV_SI_DI
	MOV CX, 256
	REPNE SCASB
	CMP DI, MD.HstBuf+LenHist
	JB F21_26
	MOV [ES:SI], AL
F21_30:	MOV AL, [ES:MD.LoadFl]
	AND AL, 7Fh
	MOV [ES:MD.LoadRes], AL
	MOV AH, 2
	INT 16h
	TEST AL, 3
	JZ F21_31
	MOV BX, MD.LoadFl
	MOV AH, [ES:BX]
	AND BYTE [ES:BX], 7Fh
	CALL InvVar
	AND AH, 80h
	OR [ES:BX], AH
F21_31:	CALL RestVct
	PUSH ES
	POP DS
	CALL SavMous
	PUSH SS
	POP ES
	DW _XOR_SI_SI
	MOV DI, LastRes+LAST.ComnIni
	MOV CX, MD_CmnSave
	REP MOVSB
	PUSH DS
	MOV DS, [MD.WCB1seg]
	MOV DI, LastRes+LAST.WCB1sav
	CALL F21_40
	POP DS
	PUSH DS
	MOV DS, [MD.WCB2seg]
	MOV DI, LastRes+LAST.WCB2sav
	CALL F21_40
	POP ES
	CALL Quit
	INC DH
	TEST BYTE [MD.LoadFl], 80h
	JNZ F21_32
	CALL PutPrm
F21_32:	CALL Window
	CALL Cursor1
	MOV AH, 49h
	INT 21h
	MOV AL, 0
	CALL CurMous
	PUSH SS
	PUSH SS
	POP DS
	POP ES
	MOV BX, LastRes+LAST.ComnIni
	CMP BYTE [BX+MD.DosBuf], 0
	JNE F21_33
	MOV AL, [BX+MD.LoadRes]
	MOV [BX+MD.LoadFl], AL
	JMP Init11
F21_33:	MOV AX, 0E0Dh
	INT 10h
	TEST BYTE [BX+MD.LoadFl], 80h
	JNZ F21_34
	MOV AX, 0E0Ah
	INT 10h
F21_34:	MOV AH, 19h
	INT 21h
	MOV AH, 0
	CMP AL, [BX+MD.DosChg]
	JE F21_35
	ADD AL, 'A'
	DW _MOV_AH_AL
F21_35:	MOV AL, 2
	MOV [BX+MD.DosChg+0], AX
	MOV WORD [BX+MD.DosChg+2], 0D3Ah
	MOV AX, CS
	ADD AX, STRICT WORD (Init00-Start+Base)>>4
	MOV ES, AX
	MOV AX, Exec
	PUSH DS
	PUSH AX
	RETF

;GLOBAL F21_40
F21_40:  ; PROC NEAR
	MOV AX, [WCBdef.EndBuf]
	MOV CX, WCBdef.DskBuf+MinFls*FILENT_size
	DW _CMP_AX_CX
	JBE F21_42
	DW _MOV_AX_CX
	MOV [WCBdef.EndBuf], AX
	CMP AX, [WCBdef.CurAdr]
	JA F21_42
	PUSH ES
	PUSH DI
	PUSH DS
	POP ES
	MOV CX, FILENT_size
	DW _MOV_DI_AX
	DW _SUB_DI_CX
	MOV SI, [WCBdef.First]
	DW _CMP_SI_DI
	JB F21_41
	DW _SUB_DI_CX
	MOV [WCBdef.First], DI
	AND BYTE [SI+FILENT.AttrF], 3Fh
	PUSH CX
	REP MOVSB
	POP CX
F21_41:	MOV SI, [WCBdef.CurAdr]
	MOV [WCBdef.CurAdr], DI
	AND BYTE [SI+FILENT.AttrF], 3Fh
	REP MOVSB
	POP DI
	POP ES
F21_42:	DW _XOR_SI_SI
	MOV CX, WCBdef_WCBsave
	REP MOVSB
	MOV SI, WCBdef.DskBuf
	DW _SUB_AX_SI
	DW _XOR_DX_DX
	MOV CX, FILENT_size
	DIV CX
	DW _MOV_CX_AX
	JCXZ F21_44
F21_43:	PUSH SI
	PUSH CX
	MOV CX, 12
	REP MOVSB
	INC SI
	MOVSB
	POP CX
	POP SI
	ADD SI, FILENT_size
	LOOP F21_43
F21_44:	RET
;F21_40 ENDP

F22_00:	MOV SI, WCBdef.DskBuf  ; ^PgUp
	CMP BYTE [SI+FILENT.NameF], '.'
	JE F23_01
F22_01:	JMP Func05

F23_00:	MOV SI, [WCBdef.CurAdr]  ; ^PgDn
F23_01:	CALL FilePan
	JNC F22_01
	CMP SI, [WCBdef.EndBuf]
	JAE F22_01
	TEST BYTE [SI+FILENT.AttrF], 10h
	JZ F22_01
F23_02:	CALL HidCur  ; Change Directory
	MOV AL, [WCBdef.WinPath]
	SUB AL, 'A'-1
	CALL Fantom
	JC F23_05
	DW _MOV_DX_SI
	MOV AH, 3Bh
	CALL Intr21
	JC F23_05
	CMP BYTE [SI+FILENT.NameF], '.'
	JNE F24_02
	MOV DI, WCBdef.DskBuf
	LEA BX, [DI+FILENT_size]
	MOV [WCBdef.CurAdr], DI
	MOV [WCBdef.First], BX
	MOV [WCBdef.EndBuf], BX
	MOV BYTE [BX+FILENT.NameF], 0
	MOV SI, WCBdef.WinPath
	CALL CutPath
	PUSH ES
	PUSH DS
	POP ES
	PUSH SI
	MOV CX, 12
	REP MOVSB
	MOV AX, 1000h
	STOSW
	POP DI
	CMP DI, WCBdef.WinPath+3
	JBE F23_04
	DEC DI
F23_04:	STOSB
	POP ES
	JMP F24_02
F23_05:	JMP Func04

F24_00:	CALL HidCur  ; ^\ .
	MOV AL, [ES:MD.DosPth]
	SUB AL, 'A'-1
	CALL Fantom
	JC F23_05
	MOV DX, CDir_S
	PUSH DS
	PUSH CS
F24_01:	POP DS
	MOV AH, 3Bh
	CALL Intr21
	POP DS
	JC F23_05
	MOV WORD [WCBdef.EndBuf], WCBdef.DskBuf
F24_02:	CALL SetPth
	MOV AH, 0
	MOV AL, [WCBdef.WinTyp]
	CMP AL, 1
	JE F24_03
	MOV BYTE [WCBdef.ChgFlg], 1
	JMP F24_04
F24_03:	CMP BYTE [WCBdef.ChgFlg], 0
	JNE F24_04
	MOV AH, 1
F24_04:	CALL InvWCB
	OR AL, [WCBdef.WinTyp]
	JZ F24_07
	CMP BYTE [WCBdef.WinTyp], 1
	JE F24_05
	MOV BYTE [WCBdef.ChgFlg], 1
	JMP F24_06
F24_05:	CMP BYTE [WCBdef.ChgFlg], 0
	JNE F24_06
	MOV AH, 1
F24_06:	CMP AH, 0
	JE F24_07
	PUSH ES
	POP DS
	CALL TrCr10
F24_07:	JMP Init50

F25_00:	MOV DI, [ES:MD.HstAdr]  ; ^E
	MOV CX, 256
	MOV AL, 0
	REPNE SCASB
	CMP AL, [ES:DI]
	JNE F26_02
	MOV DI, [ES:MD.HstAdr]
	JMP F26_02

F26_00:	MOV DI, [ES:MD.HstAdr]  ; ^X
	DEC DI
	CMP DI, MD.HstBuf
	JB F26_01
	JE F26_02
	DEC DI
	MOV CX, 256
	MOV AL, 0
	STD
	REPNE SCASB
	CLD
	INC DI
F26_01:	INC DI
F26_02:	DW _MOV_BX_DI
	JMP F27_06

F27_00:	MOV DL, [ES:MD.DosCol]  ; ^Enter
	MOV DH, 0
	DW _MOV_SI_DX
	ADD SI, MD.DosBuf
	CMP BYTE [ES:MD.DosBuf], 0
	JE F27_05
	MOV DI, [ES:MD.HstAdr]
	CMP DL, 0
	JE F27_03
	MOV AL, [ES:SI-1]
	CALL CmpSym
	JE F27_05
	CMP AL, '@'
	JE F27_05
	JMP F27_03
F27_01:	CMP BYTE [ES:DI], 0
	JE F27_04
	DW _MOV_BX_DI
	MOV SI, MD.DosBuf
F27_02:
ES
	LODSB
	CMP AL, 0
	JE F27_06
	CALL UpCase
	DW _MOV_AH_AL
	MOV AL, [ES:DI]
	INC DI
	CALL UpCase
	DW _CMP_AL_AH
	JE F27_02
F27_03:	MOV CX, 256
	MOV AL, 0
	REPNE SCASB
	JMP F27_01
F27_04:	CMP DL, 0
	JNE F27_11
F27_05:	CALL FilePan
	JNC F27_11
	MOV SI, [WCBdef.CurAdr]
	CMP SI, [WCBdef.EndBuf]
	JAE F27_11
	MOV DI, MD.TmpBuf
	DW _MOV_BX_DI
	MOV CX, 13
	REP MOVSB
	JMP F27_07
F27_06:	MOV [ES:MD.HstAdr], BX
	DW _XOR_DX_DX
	MOV [ES:MD.DosBuf], DX
F27_07:	DW _MOV_DI_BX
	MOV SI, MD.DosBuf
	MOV CX, LenCmd-1
	MOV AH, 0
F27_08:	MOV AL, [ES:BX]
	CMP AL, 0
	JE F27_09
	INC BX
	CALL EdLin
	JC F27_08
	JMP F27_10
F27_09:	CMP DI, MD.TmpBuf
	JNE F27_10
	MOV AL, ' '
	CALL EdLin
F27_10:	MOV [ES:MD.DosCol], DL
	CALL DosCom
F27_11:	JMP Func05

F80_00:	CALL FilePan  ; ^I - insert files
	JNC F27_11
	CALL TotSel
	DW _MOV_BP_BX
	DW _OR_BP_DX
	JNE F80_01
	MOV SI, [WCBdef.CurAdr]
	CMP SI, [WCBdef.EndBuf]
	JAE F27_11
	CMP BYTE [SI+FILENT.NameF], '.'
	JE F27_11
F80_01:	MOV DI, WCBdef.DskBuf
	PUSH DI
F80_02:	CMP DI, [WCBdef.EndBuf]
	JAE F80_03
	AND BYTE [DI+FILENT.AttrF], 7Fh
	ADD DI, FILENT_size
	JMP F80_02
F80_03:	POP DI
	DW _OR_BP_BP
	JNE F80_04
	DW _MOV_DI_SI
	JMP F80_05
F80_04:	CMP DI, [WCBdef.EndBuf]
	JAE F80_10
	TEST BYTE [DI+FILENT.AttrF], 40h
	JZ F80_12
F80_05:	PUSH DI
	MOV AL, 0
	PUSH ES
	PUSH DS
	POP ES
	MOV CX, 0FFFFh
	PUSH CX
	REPNE SCASB
	NOT CX
	DW _MOV_BX_CX
	POP CX
	POP ES
	MOV DI, MD.DosBuf
	REPNE SCASB
	NOT CX
	MOV DX, LenCmd
	DW _SUB_DX_CX
	POP DI
	TEST BYTE [DI+FILENT.AttrF], 10h
	JZ F80_06
	ADD BX, 4
F80_06:	DW _CMP_BX_DX
	JA F80_10
	DW _MOV_BX_DI
	MOV SI, MD.DosBuf
	MOV CX, LenCmd-1
	MOV DL, [ES:MD.DosCol]
	MOV DH, 0
	MOV AH, 0
F80_07:	MOV AL, [BX]
	CMP AL, 0
	JE F80_08
	CALL EdLin
	INC BX
	JMP F80_07
F80_08:	TEST BYTE [DI+FILENT.AttrF], 10h
	JZ F80_11
	MOV BX, Mask_S
F80_09:	MOV AL, [CS:BX]
	CMP AL, 0
	JE F80_11
	CALL EdLin
	INC BX
	JMP F80_09
F80_10:	CALL DosCom
	JMP Func01
F80_11:	MOV AL, ' '
	CALL EdLin
	MOV [ES:MD.DosCol], DL
	DW _OR_BP_BP
	JE F80_10
	AND BYTE [DI+FILENT.AttrF], 0BFh
	OR BYTE [DI+FILENT.AttrF], 80h
F80_12:	ADD DI, FILENT_size
	JMP F80_04

F30_00:	CMP BYTE [ES:MD.QuitAck], 0  ; F10 - quit
	JZ F30_01
	MOV DX, Name_S
	MOV BP, Quit_B
	CALL Dialog
	JE F30_01
	JMP Func04
F30_01:	JMP Exit

F42_00:	CALL F42_10  ; Shift-F2 - main user menu
	JMP F32_01

;GLOBAL F42_10
F42_10:  ; PROC NEAR
	PUSH ES
	POP DS
	MOV BYTE [MD.HlpPage], 17
	CALL HidCur
	MOV AL, 2
	CALL PutMnu
	RET
;F42_10 ENDP

F32_00:	PUSH CS  ; F2 - user menu
	POP DS
	MOV SI, Menu_F
	MOV DI, MD.TmpBuf
	DW _MOV_DX_DI
	MOV CX, 13
	REP MOVSB
	CALL F42_10
	CALL ChgDisk
	JC F32_04
	MOV AL, 40h
	CALL OpenFil
	JNC F32_05
	CMP AL, 2
	JE F32_01
	CMP AL, 5
	JNE F32_04
F32_01:	MOV SI, Menu_F
	MOV DI, MD.TmpBuf
	CALL MainFil
F32_02:	MOV DX, MD.TmpBuf
	CALL ChgDisk
	JC F32_04
	MOV AL, 40h
	CALL OpenFil
	JNC F32_05
	CMP AL, 3
	JA F32_04
F32_03:	MOV BP, UsrEr_B
	CALL Dialog
F32_04:	JMP Func04
F32_05:	PUSH ES
	POP DS
	DW _MOV_BX_AX
	MOV DX, MD.MenuBuf
	MOV CX, LenMenu-1
	MOV AH, 3Fh
	CALL Intr21
	PUSHF
	PUSH AX
	MOV AH, 3Eh
	CALL Intr21
	POP BX
	POP CX
	JC F32_04
	PUSH CX
	POPF
	JC F32_04
	MOV SI, MD.MenuBuf
	MOV BYTE [BX+SI], 1Ah
	CALL FndItem
	JC F32_03
	MOV CL, 0  ; Output
	DW _XOR_DX_DX
	MOV BP, MD.TmpBuf+100
	PUSH BP
F32_10:	PUSH DX
	MOV CH, 0
	DW _XOR_BX_BX
	MOV [DS:BP], BX
	MOV AX, [SI]
	CMP AL, ' '
	JBE F32_15
	CMP AL, 0FFh
	JE F32_15
	CMP AL, 7Fh
	JE F32_15
	CALL UpCase
	CMP AH, ':'
	JE F32_13
	CMP AL, 'F'
	JNE F32_15
	CMP AH, '1'
	JB F32_15
	CMP AH, '9'
	JA F32_15
	DW _MOV_BH_AH
	ADD BH, 3Bh-'1'
	MOV DX, [SI+2]
	CMP DL, ':'
	JE F32_12
	CMP AH, '1'
	JNE F32_15
	CMP DH, ':'
	JNE F32_15
	CMP DL, '2'
	JA F32_15
	MOV BH, 44h
	CMP DL, '0'
	JE F32_11
	JB F32_15
	DW _MOV_BH_DL
	ADD BH, 85h-'1'
F32_11:	INC BX
F32_12:	INC BX
	MOV AL, 0
F32_13:	INC BX
	INC BX
	DW _MOV_AH_BH
	MOV [DS:BP], AX
	MOV BH, 0
	DW _ADD_SI_BX
F32_14:	LODSB
	CMP AL, ' '
	JE F32_14
	CMP AL, 9
	JE F32_14
	DEC SI
	DW _CMP_BL_CL
	JBE F32_15
	DW _MOV_CL_BL
F32_15:	CALL IsCrLfS
	JE F32_16
	DEC SI
	CMP AL, 1Ah
	JE F32_16
	CMP CH, 80
	JAE F32_15
	INC CH
	JMP F32_15
F32_16:	POP DX
	DW _CMP_CH_DL
	JBE F32_17
	DW _MOV_DL_CH
F32_17:	INC BP
	INC BP
	INC DH
	CMP AL, 1Ah
	JE F32_18
	MOV AL, [MD.Lines]
	SUB AL, 6
	DW _CMP_DH_AL
	JAE F32_18
	CALL FndItem
	JC F32_18
	JMP F32_10
F32_18:	POP BP
	DW _ADD_DL_CL
	CMP DL, 63
	JBE F32_19
	MOV DL, 63
F32_19:	CMP DL, 11
	JAE F32_20
	MOV DL, 11
F32_20:	ADD DX, 50Eh
	MOV BX, 0C28h
	CALL SftEGA
	DW _MOV_CH_BH
	DW _MOV_AX_DX
	INC AH
	DEC AL
	SHR AH, 1
	SHR AL, 1
	DW _SUB_BX_AX
	SUB CH, 7
	DW _CMP_BH_CH
	JBE F32_21
	DW _MOV_BH_CH
F32_21:	MOV SI, MD.WinBuf
	CALL SavWin
	MOV AH, Hist_C
	CALL Color
	CALL MinBox
	PUSH SI
	MOV SI, User_S
	PUSH BX
	INC BH
	MOV BL, 34
	CALL BasAdr
	POP BX
	PUSH CX
	MOV CX, 11
	CALL MvsBwc
	POP CX
	PUSH DX
	PUSH BX
	SUB DH, 5
	ADD BX, 205h
	MOV SI, MD.MenuBuf
F32_22:	CALL FndItem
	CALL BasAdr
	CMP WORD [DS:BP], 0
	JE F32_25
	PUSH DI
	LODSB
F32_23:	CALL UpCase
	STOSB
	INC DI
	LODSB
	CMP AL, ':'
	JNE F32_23
	POP DI
F32_24:	LODSB
	CMP AL, ' '
	JE F32_24
	CMP AL, 9
	JE F32_24
	DEC SI
F32_25:	MOV CH, 0
	DW _ADD_DI_CX
	DW _ADD_DI_CX
	INC DI
	INC DI
	DW _MOV_CH_DL
	SUB CH, 14
	DW _SUB_CH_CL
F32_26:	CALL IsCrLfS
	JE F32_28
	DEC SI
	CMP AL, 1Ah
	JE F32_29
	CMP CH, 0
	JE F32_26
	CMP AL, 9
	JNE F32_27
	MOV AL, ' '
F32_27:	STOSB
	INC DI
	DEC CH
	JMP F32_26
F32_28:	INC BP
	INC BP
	INC BH
	DEC DH
	JA F32_22
F32_29:	POP BX
	POP DX
	CALL Window
	MOV CH, 0
	MOV WORD [MD.MousTim+2], 0FFFFh
	MOV BYTE [MD.MousEnt], 0
F32_30:	MOV AH, HstCu_C  ; Set cursor
	CALL F32_60
F32_31:	PUSH CX
	CALL GetMous
	POP CX
	JNZ F32_45
	MOV BYTE [MD.MousEnt], 0
	MOV AL, 1  ; Input
	CALL Input0
	JC F32_33
	CMP AH, 0FCh
	JE F32_45
	MOV SI, User_T
	CALL Case
	CMP AL, 0
	JE F32_32
	MOV AH, 0
	CALL UpCase
F32_32:	PUSH CX
	MOV DI, MD.TmpBuf+100
	DW _MOV_CL_DH
	SUB CL, 5
	MOV CH, 0
	REPNE SCASW
	POP CX
	JNE F32_33
	DW _MOV_AX_DI
	SUB AX, STRICT WORD MD.TmpBuf+102
	SHR AL, 1
	DW _MOV_CH_AL
	JMP F32_50
F32_33:	CMP AX, STRICT WORD 3B00h  ; F1
	JNE F32_35
	CALL Help
F32_34:	JMP F32_31
F32_35:	CMP AX, STRICT WORD 4400h  ; F10
	JNE F32_31
	JMP F32_55
F32_36:	DW _MOV_AL_CH  ; Up
	CMP AL, 0
	JE F32_39
	DEC AX
	JMP F32_40
F32_37:	DW _MOV_AL_DH  ; Down
	SUB AL, 6
	DW _CMP_CH_AL
	JAE F32_38
	DW _MOV_AL_CH
	INC AX
	JMP F32_40
F32_38:	MOV AL, 0  ; Home, PgUp
	JMP F32_40
F32_39:	DW _MOV_AL_DH  ; End, PgDn
	SUB AL, 6
F32_40:	DW _CMP_AL_CH
	JE F32_31
	MOV AH, Hist_C
	CALL F32_60
	DW _MOV_CH_AL
	JMP F32_30
F32_45:	CALL F32_70  ; Mouse
	CMP AH, 1
	JB F32_34
	JE F32_40
	CMP AH, 1Ch
	JNE F32_55
F32_50:	MOV SI, MD.MenuBuf  ; Enter
	INC CH
F32_51:	CALL FndItem
F32_52:	CALL IsCrLfS
	JE F32_53
	CMP AL, 1Ah
	JE F32_55
	DEC SI
	JMP F32_52
F32_53:	DEC CH
	JNE F32_51
	DW _MOV_DI_SI
	DW _XOR_AX_AX
F32_55:	POP SI  ; Esc
	CALL ResWin
	CALL Window
	DW _OR_AX_AX
	JE F32_56
	MOV BYTE [MD.MenuFl], 0
	JMP Func04
F32_56:	DW _MOV_SI_DI
	CALL F34_30
	JC F32_57
	DW _XOR_BP_BP
	CALL F34_40
	JNC F32_57
	JMP F32_02
F32_57:	MOV AL, [MD.AutoMnu]
	MOV [MD.MenuFl], AL
	JMP Run_00

;GLOBAL F32_60
F32_60:  ; PROC NEAR
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	ADD BX, 205h
	DW _ADD_BH_CH
	MOV DH, 1
	SUB DL, 12
	DW _ADD_BL_CL
	DW _SUB_DL_CL
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
;F32_60 ENDP

;GLOBAL F32_70
F32_70:  ; PROC NEAR  ; Mouse
	PUSH CX
	DW _XOR_SI_SI
F32_71:	CALL GetMous
	JZ F32_74
	DW _MOV_BP_CX
	CALL ClrKbd
	MOV AH, 'x'
	TEST AL, 3
	JZ F32_72
	MOV AH, 0
F32_72:	DW _MOV_CX_SI
	DW _MOV_SI_AX
	DW _CMP_AH_CH
	JE F32_73
	DW _MOV_AL_AH
	CALL TypMous
F32_73:	TEST SI, 3
	JZ F32_71
	PUSH BX
	PUSH DX
	ADD BX, 204h
	SUB DX, 50Ah
	DW _MOV_CX_BP
	CALL InWind
	POP DX
	POP BX
	JC F32_71
	JMP F32_77
F32_74:	MOV AL, 0
	CALL TypMous
	POP CX
	DW _MOV_AX_SI
	CMP AL, 2
	JE F32_76
	CMP AL, 1
	JB F32_76
	JNE F32_75
	PUSH DX
	PUSH CX
	DW _MOV_CX_BP
	SUB DX, 102h
	CALL InWind
	POP CX
	POP DX
	JNC F32_76
F32_75:	MOV AH, 0FFh
	RET
F32_76:	MOV AH, 0
	RET
F32_77:	DW _SUB_CX_BX
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
	JNC F32_78
	MOV AH, 1
	RET
F32_78:	JE F32_76
	MOV AL, 0
	CALL TypMous
	MOV AH, 1Ch
	RET
;F32_70 ENDP

F61_00:	PUSH DS  ; Alt F1
	MOV DS, [ES:MD.WCB1seg]
	MOV CL, 1
	JMP F62_01

F62_00:	PUSH DS  ; Alt F2
	MOV DS, [ES:MD.WCB2seg]
	MOV CL, 5
F62_01:	PUSH CX
	CALL HidCur
	DW _MOV_AL_CL
	CALL PutMnu
	MOV DI, MD.TmpBuf
	MOV AL, 'A'
F62_02:	CALL TstDrv
	JNZ F62_05
	CMP AL, 'B'
	JA F62_04
	CMP BYTE [ES:MD.DriveB], 0  ; Who sets this?
	JNZ F62_04
	PUSH AX
	SUB AL, 'A'-1
	DW _MOV_BL_AL
	MOV BH, 3
	DW _SUB_BH_BL
	MOV AX, 440Eh
	INT 21h
	JNC F62_03
	MOV AL, 0
F62_03:	DW _CMP_AL_BH
	POP AX
	JE F62_05
F62_04:	STOSB
F62_05:	INC AX
	CMP AL, 'Z'
	JBE F62_02
	SUB DI, MD.TmpBuf
	DW _MOV_BP_DI
	DW _XOR_CX_CX
	CMP DI, 14
	JA F62_06
	INC CX
	DW _ADD_BP_DI
	DEC BP
	CMP DI, 9
	JA F62_06
	INC CX
	DW _ADD_BP_DI
	INC BP
	CMP DI, 7
	JA F62_06
	INC CX
	DW _ADD_BP_DI
	DEC BP
F62_06:	CALL BegBX
	MOV DX, 18
	CMP BL, 1
	CMC
	ADC DL, 0
	ADD BL, 21
	DW _CMP_BP_DX
	JBE F62_07
	DW _MOV_DX_BP
F62_07:	ADD DL, 10+2
	PUSH DX
	INC DX
	SHR DL, 1
	DW _SUB_BL_DL
	POP DX
	MOV BH, 5
	MOV DH, 6+1
	CALL SftEGA
	MOV SI, MD.WinBuf
	CALL SavWin
	MOV AH, Box_C
	CALL Color
	CALL MinBox
	PUSH SI
	PUSH DI
	PUSH CX
	PUSH BX
	DW _MOV_AL_BH
	CALL BegBX
	ADD BL, 13
	INC AX
	DW _MOV_BH_AL
	CALL BasAdr
	MOV SI, DrLe_S
	MOV CX, 14
	CALL MvsBwc
	CMP BL, 30
	MOV BL, 11
	JB F62_08
	ADD BL, 39
F62_08:	INC BH
	CALL BasAdr
	MOV SI, Choo_S
	MOV CX, 7
	CALL MvsBwc
	PUSH AX
	MOV AH, BoxBr_C
	CALL Color
	MOV CX, 4
	MOV SI, Left_S
	CMP BL, 30
	JB F62_09
	MOV SI, Rght_S
	INC CX
F62_09:	CALL MvsBwc
	POP AX
	MOV SI, Driv_S
	MOV CX, 7
	CALL MvsBwc
	POP BX
	POP DI
	POP CX
	PUSH DX
	PUSH BX
	DW _MOV_AL_BH
	CALL BegBX
	DW _MOV_BH_AL
	ADD BX, 314h
	INC BP
	SHR BP, 1
	DW _SUB_BX_BP
	DW _MOV_DX_DI
	CMP DX, 2
	JB F62_10
	INC BX
F62_10:	CALL BasAdr
	MOV SI, MD.TmpBuf
	PUSH DI
	PUSH CX
F62_11:
ES
	LODSB
	STOSW
	DW _ADD_DI_DX
	DW _ADD_DI_DX
	LOOP F62_11
	POP CX
	POP DI
	DW _MOV_BP_DX
	POP BX
	POP DX
	MOV AL, [WCBdef.WinPath]
	PUSH DI
	PUSH CX
	MOV DI, MD.TmpBuf
	REPNE SCASB
	LEA AX, [DI-1-MD.TmpBuf]
	POP CX
	POP DI
	JNE F62_12
	DW _MOV_CH_AL
F62_12:	MOV BYTE [ES:MD.HlpPage], 15
	DW _OR_BP_BP
	JE F62_15
	DEC DI
	DEC DI
F62_15:	PUSH DI  ; Cursor
	PUSH CX
	CALL BasAdr
	ADD DI, 2*(3*80+4)
	DW _MOV_CL_DL
	MOV CH, 0
	SUB CL, 8+2
	MOV AH, Box_C
	CALL Color
	DW _MOV_AL_AH
	CALL MvsColr
	POP CX
	POP DI
	PUSH DI
	LEA AX, [BP+2]
	DW _ADD_AX_BP
	MUL CH
	DW _ADD_DI_AX
	INC DI
	MOV AH, BoxCu_C
	CALL Color
	DW _MOV_AL_AH
	STOSB
	DW _OR_BP_BP
	JE F62_16
	INC DI
	STOSB
	INC DI
	STOSB
F62_16:	POP DI
	CALL Window
F62_20:	PUSH DX
	PUSH CX
	CALL GetMous
	JZ F62_24
	DW _XOR_DX_DX
F62_21:	AND DL, 80h
	DW _OR_DL_AL
	MOV AL, 'x'
	TEST DL, 4
	JNZ F62_27
	MOV AL, 'û'
	TEST DL, 2
	JNZ F62_27
	PUSH DX
	PUSH BX
	DW _MOV_AX_DI
	SUB AX, STRICT WORD MD.ScrBuf
	SHR AX, 1
	MOV BL, 80
	DIV BL
	DW _XCHG_AH_AL
	DW _MOV_BX_AX
	MOV AL, 0
	MOV DX, 101h
	DW _OR_BP_BP
	JE F62_22
	INC DX
	INC DX
F62_22:	CALL InWind
	JNC F62_23
	DW _ADD_BX_BP
	INC BX
	INC AX
	CMP AL, 27
	JB F62_22
	STC
F62_23:	POP BX
	POP DX
	JC F62_26
	POP CX
	PUSH CX
	DW _CMP_AL_CL
	JAE F62_26
	TEST DL, 80h
	JNZ F62_25
	OR DL, 80h
	DW _CMP_AL_CH
	JE F62_25
	POP CX
	POP DX
	DW _MOV_CH_AL
	JMP F62_15
F62_24:	POP CX
	POP DX
	JMP F62_30
F62_25:	DW _CMP_AL_CH
	MOV AL, 'û'
	JE F62_27
F62_26:	MOV AL, 0
F62_27:	DW _CMP_AL_DH
	JE F62_28
	DW _MOV_DH_AL
	CALL TypMous
F62_28:	CALL GetMous
	JNZ F62_21
	MOV AL, 0
	CALL TypMous
	DW _MOV_AX_DX
	POP CX
	POP DX
	TEST AL, 4
	JNZ F62_37
	TEST AL, 2
	JNZ F62_36
	DW _OR_AH_AH
	JNE F62_36
	PUSH DX
	PUSH CX
	SUB DX, 102h
	CALL GetMous
	CALL InWind
	POP CX
	POP DX
	JC F62_37
F62_30:	MOV AL, 1  ; Input
	CALL Input
	MOV SI, Drive_T
	CALL Case
	CMP AL, 80h  ; Letter
	JAE F62_33
	CALL UpCase
	PUSH DI
	PUSH CX
	MOV CH, 0
	MOV DI, MD.TmpBuf
	REPNE SCASB
	POP CX
	POP DI
	JNE F62_33
	JMP F62_40
F62_31:	CMP CH, 0  ; Left
	JE F62_32
	DEC CH
	JMP F62_33
F62_32:	DW _MOV_CH_CL  ; End
	DEC CH
F62_33:	JMP F62_15
F62_34:	INC CH  ; Right
	DW _CMP_CH_CL
	JB F62_33
F62_35:	MOV CH, 0  ; Home
	JMP F62_33
F62_36:	DW _MOV_AL_CH  ; Enter
	CBW
	DW _MOV_DI_AX
	MOV AL, [ES:MD.TmpBuf+DI]
	JMP F62_40
F62_37:	MOV AL, 0  ; Esc
F62_40:	POP SI
	CALL ResWin
	CALL Window
	POP CX
F62_41:	CMP AL, 0
	JE F62_46
	CALL HidCur
	DW _MOV_BH_AL
	SUB AL, 'A'-1
	DW _MOV_DL_AL
	DW _MOV_BL_AL
	MOV AX, 440Fh
	INT 21h
	MOV SI, WCBdef.WinPath+3
	MOV BYTE [ES:MD.BlocEr], 1
	MOV AH, 47h
	CALL Intr21
	JC F62_42
	MOV [WCBdef.WinPath], BH
	LEA DX, [SI-3]
	MOV AH, 3Bh
	CALL Intr21
F62_42:	MOV BYTE [ES:MD.BlocEr], 0
	JNC F62_43
	DW _MOV_AL_BH
	CALL ErrRdy
	JMP F62_41
F62_43:	PUSH DS
	MOV AX, DS
	CMP AX, [ES:MD.WCBcrn]
	JE F62_44
	CALL InvWCB
	CALL FilePan
	JC F62_45
F62_44:	DW _MOV_DL_BL
	DEC DX
	MOV AH, 0Eh
	INT 21h
F62_45:	POP DS
	MOV BYTE [WCBdef.WinTyp], 0
	MOV BYTE [WCBdef.ChgFlg], 1
	MOV BYTE [ES:MD.BlocEr], 1
	MOV AX, WCBdef.DskBuf
	MOV [WCBdef.CurAdr], AX
	MOV [WCBdef.EndBuf], AX
	JMP M06_10
F62_46:	POP DS
	JMP Func04

F68_00:	CALL HidCur  ; Alt F8 - History
	CALL PutMnu3
	PUSH ES
	POP DS
	MOV DX, 51Fh
	MOV DI, MD.HstBuf
	MOV AH, [MD.Lines]
	SUB AH, 3
	MOV AL, 0
F68_01:	DW _MOV_SI_DI
	MOV CX, 256
	REPNE SCASB
	DW _MOV_BX_DI
	DW _SUB_BX_SI
	DW _CMP_BL_DL
	JBE F68_02
	DW _MOV_DL_BL
	CMP DL, 65+1
	JBE F68_02
	MOV DL, 65+1
F68_02:	INC DH
	DW _CMP_DH_AH
	JAE F68_03
	CMP AL, [DI]
	JNE F68_01
F68_03:	ADD DL, 10+2-1
	MOV BX, 0D28h
	DW _MOV_AX_DX
	INC AH
	DEC AX
	SHR AH, 1
	SHR AL, 1
	DW _SUB_BX_AX
	CALL SftEGA
	MOV SI, MD.WinBuf
	CALL SavWin
	MOV AH, Hist_C
	CALL Color
	CALL MinBox
	PUSH SI
	PUSH BX
	INC BH
	MOV BL, 35
	CALL BasAdr
	POP BX
	MOV SI, Hist_S
	MOV CX, 9
	CALL MvsBwc
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 4
	ADD BL, 5
	CALL BasAdr
	POP BX
	MOV SI, MD.HstBuf
	DW _MOV_CL_DL
	SUB CL, 12
	MOV CH, 0
	PUSH DX
	SUB DH, 5
	DW _XOR_BP_BP
F68_04:	PUSH DI
	PUSH CX
	CMP SI, [MD.HstAdr]
	JA F68_05
	INC BP
F68_05:	LODSB
	CMP AL, 0
	JE F68_06
	JCXZ F68_05
	STOSW
	DEC CX
	JMP F68_05
F68_06:	POP CX
	POP DI
	SUB DI, 2*80
	DEC DH
	JA F68_04
	POP DX
	CALL Window
	MOV BYTE [MD.HlpPage], 33
	DW _MOV_CL_BH
	DW _ADD_CL_DH
	SUB CL, 3
	DW _SUB_CX_BP
	MOV WORD [MD.MousTim+2], 0FFFFh
	MOV BYTE [MD.MousEnt], 0
F68_07:	MOV AH, HstCu_C  ; Set cursor
	CALL F68_30
F68_08:	PUSH CX
	CALL GetMous
	POP CX
	JNZ F68_11
	MOV BYTE [MD.MousEnt], 0
	MOV AL, 1  ; Input
	CALL Input
	CMP AH, 0FCh
	JE F68_11
	MOV SI, Hist_T
	CALL Case
	CALL UpCase
	DW _MOV_AH_AL
	DW _MOV_CH_CL
F68_09:	INC CH
	DW _MOV_AL_BH
	DW _ADD_AL_DH
	SUB AL, 4
	DW _CMP_CH_AL
	JB F68_10
	DW _CMP_CH_CL
	JE F68_08
	DW _MOV_CH_BH
	ADD CH, 2
F68_10:	DW _CMP_CH_CL
	JE F68_08
	PUSH BX
	DW _MOV_BH_CH
	ADD BL, 5
	CALL BasAdr
	POP BX
	MOV AL, [DI]
	CALL UpCase
	DW _CMP_AL_AH
	JNE F68_09
	DW _MOV_AL_CH
	JMP F68_12
F68_11:	CALL F32_70  ; Mouse
	CMP AH, 1
	JB F68_08
	JA F68_19
	DW _ADD_AL_BH
	ADD AL, 2
F68_12:	DW _CMP_AL_CL  ; Delete cursor
	JE F68_08
	MOV AH, Hist_C
	PUSH AX
	CALL F68_30
	POP CX
	JMP F68_07
F68_13:	DW _MOV_AL_CL  ; Up
	DEC AL
	DW _MOV_AH_BH
	INC AH
	DW _CMP_AL_AH
	JNE F68_12
F68_14:	DW _MOV_AL_BH  ; End
	DW _ADD_AL_DH
	SUB AL, 4
	JMP F68_12
F68_15:	DW _MOV_AL_CL  ; Down
	INC AL
	DW _MOV_AH_BH
	DW _ADD_AH_DH
	SUB AH, 3
	DW _CMP_AL_AH
	JNE F68_12
F68_16:	DW _MOV_AL_BH  ; Home
	ADD AL, 2
	JMP F68_12
F68_19:	MOV AL, 0Dh
F68_20:	POP SI  ; Exit
	CALL ResWin
	CALL Window
	CMP AH, 1Ch
	JNE F68_28
	PUSH AX
	DW _MOV_AL_BH
	DW _ADD_AL_DH
	SUB AL, 4
	DW _SUB_AL_CL
	CBW
	DW _MOV_CX_AX
	DW _XOR_AX_AX
	MOV DI, MD.HstBuf
	JCXZ F68_22
F68_21:	PUSH CX
	MOV CX, 256
	REPNE SCASB
	POP CX
	LOOP F68_21
F68_22:	MOV [MD.DosBuf], AL
	DW _XOR_DX_DX
	DW _XOR_BP_BP
	DW _MOV_BX_DI
F68_25:	MOV SI, MD.DosBuf
	MOV CX, LenCmd-1
F68_26:	MOV AL, [BX]
	CMP AL, 0
	JE F68_90
	INC BX
	CALL EdLin
	JC F68_26
	JMP F68_27
F68_90:	DW _MOV_AX_BP
	CMP AL, 0
	JE F68_27
	CMP AL, [BX-1]
	JE F68_27
	CALL EdLin
F68_27:	MOV [ES:MD.DosCol], DL
	CALL DosCom
	CALL Cursor1
	POP AX
	CMP AL, 0Dh
	JNE F68_28
	DW _OR_DL_DL
	JE F68_28
	JMP F21_25
F68_28:	JMP Func04

;GLOBAL F68_30
F68_30:  ; PROC NEAR  ; Cursor
	PUSH DX
	PUSH CX
	PUSH BX
	DW _MOV_BH_CL
	ADD BL, 4
	CALL BasAdr
	SUB DL, 10
	MOV DH, 1
	DW _MOV_CL_DL
	MOV CH, 0
	CALL Color
	DW _MOV_AL_AH
	CALL MvsColr
	CALL Window
	POP BX
	POP CX
	POP DX
	RET
;F68_30 ENDP

F81_00:	MOV DS, [ES:MD.WCB1seg]  ; ^[ - insert left path
	JMP F82_01

F82_00:	MOV DS, [ES:MD.WCB2seg]  ; ^] - insert right path
F82_01:	MOV BX, WCBdef.WinPath
	CMP BYTE [WCBdef.WinTyp], 1
	JA F68_28
	JB F82_02
	PUSH ES
	POP DS
	MOV BX, MD.CrnPath
F82_02:	MOV DL, [ES:MD.DosCol]
	MOV DH, 0
	MOV AL, 0
	MOV BP, '\'
	PUSH AX
	JMP F68_25

F74_00:	CMP BYTE [ES:MD.DosBuf], 0  ; Esc
	JNE F74_01
	CMP BYTE [ES:MD.EscBar], 0
	JZ F74_01
	JMP F11_00
F74_01:	MOV AX, 1519h

F73_00:	MOV SI, MD.DosBuf  ; Input command line
	MOV DL, [ES:MD.DosCol]
	MOV DH, 0
	MOV CX, LenCmd-1
	CALL EdLin
	JNC F73_01
	MOV [ES:MD.DosCol], DL
	CALL DosCom
F73_01:	JMP Func05

F75_00:	CMP BYTE [WCBdef.WinTyp], 1  ; Auto CD / Quick view
	JNE F75_01
	JMP F21_10
F75_01:	JMP Func04

F77_00:	MOV SI, MD.WinBuf  ; Speed search
	PUSH SI
	PUSH AX
	MOV AL, 11
	CALL PutKey
	CALL BegBX
	CALL SizDX
	DW _ADD_BH_DH
	DEC BH
	ADD BL, 8
	MOV DX, 318h
	CALL SavWin
	PUSH DX
	CALL BasAdr
	PUSH DI
	DW _XOR_CX_CX
	DEC DX
	DEC DX
	MOV DH, 0
	MOV SI, 1
	MOV BP, AltSr_P
	MOV AH, [CS:BP]
	CALL Color
	CALL BoxDubl
	POP DI
	POP DX
	PUSH DS
	PUSH CS
	POP DS
	ADD DI, 2*82
	MOV SI, AltSr_S
	MOV AL, 50
	CALL NgLine
	POP DS
	CALL Window
	POP AX
	DW _XOR_CX_CX
	MOV [ES:MD.MenuBuf+228], CX
	MOV [ES:MD.MenuBuf+230], CL
	XCHG CL, [ES:MD.KeyBar]
	PUSH CX
	JMP F77_02
F77_01:	PUSH BX
	ADD BX, 10Ah
	MOV CX, 12
	MOV SI, MD.MenuBuf+230
	MOV AH, [CS:BP+1]
	CALL InSt10
	MOV AX, [ES:MD.MenuBuf+228]
	DW _ADD_AX_BX
	CALL Cursor
	POP BX
	CALL Input
F77_02:	CMP AH, 0FCh
	JE F77_20
	CMP AH, 0F0h
	JAE F77_01
	MOV SI, Srch_T
	CALL Case
	CMP AL, 0
	JNE F77_03
	PUSH ES
	PUSH CS
	POP ES
	MOV DI, AltSr_T
	MOV CX, 12+10+9+7
	DW _XCHG_AL_AH
	REPNE SCASB
	DW _XCHG_AL_AH
	POP ES
	JNE F77_20
	SUB DI, AltSr_T+1
	MOV AL, [CS:DI+Ascii_T]
	JMP F77_10
F77_03:	CMP AL, ' '
	JB F77_20
F77_10:	PUSH BP
	PUSH DX
	PUSH BX
	PUSH DS
	MOV SI, [WCBdef.CurAdr]
	MOV DI, [WCBdef.First]
	MOV BP, [WCBdef.EndBuf]
	MOV BX, WCBdef.DskBuf
	MOV DX, FILENT_size
	CMP BYTE [WCBdef.WinTyp], 0
	JE F77_11
	PUSH ES
	POP DS
	MOV SI, [MD.TreAdr]
	MOV DI, [MD.TreFrst]
	MOV BP, [MD.TreeBuf+DIRTREE.TreeLen]
	MOV CL, 4
	SHL BP, CL
	MOV BX, MD.TreeBuf+DIRTREE_TreList
	DW _ADD_BP_BX
	MOV DX, 16
F77_11:	PUSH DI
	CALL Search
	POP DI
	POP DS
	JZ F77_12
	CALL F00_50
F77_12:	POP BX
	POP DX
	POP BP
	JMP F77_01
F77_15:	DW _XOR_AX_AX
F77_20:	POP CX
	MOV [ES:MD.KeyBar], CL
	POP SI
	CALL ResWin
	CALL Window
	CALL Cursor1
	JMP Func12

Run_00:	PUSH ES
	POP DS
	MOV BYTE [ListFlg], 0
	MOV DI, MD.DosBuf
Run_01:	MOV AX, [SI]
	CALL IsCrLf
	JE Run_02
	CMP AL, ' '
	JE Run_04
	CMP AL, 9
	JE Run_04
	CMP AL, "'"
	JNE Run_03
Run_02:	CALL IsCrLfS
	JE Run_01
	DEC SI
	CMP AL, 1Ah
	JNE Run_02
Run_03:	JMP Run_30
Run_04:	CALL FndLet
	MOV AX, [SI]
	CALL IsCrLf
	JE Run_02
	CMP AL, 1Ah
	JE Run_03
	MOV CX, LenCmd-1
	CMP DI, MD.DosBuf
	JA Run_05
	CMP AL, '@'
	JNE Run_05
	OR BYTE [MD.LoadFl], 80h
	MOV BYTE [SI], ' '
Run_05:	CALL IsCrLfS
	JE Run_07
	DEC SI
	CMP AL, 1Ah
	JE Run_07
	JCXZ Run_05
	CMP AL, '!'
	JE Run_10
	CMP AL, 9
	JNE Run_06
	MOV AL, ' '
Run_06:	STOSB
	CMP DI, MD.DosBuf+LenBat-2
	JAE Run_03
	DEC CX
	JMP Run_05
Run_07:	MOV BYTE [DI], 0
	INC DI
	CMP DI, MD.DosBuf+LenBat-2
	JAE Run_03
	CMP AL, 1Ah
	JE Run_03
	JMP Run_01
Run_10:	MOV AX, [SI]
	CMP AL, '!'
	JNE Run_11
	INC SI
	JMP Run_06
Run_11:	CMP AL, ':'
	JNE Run_12
	MOV AL, [MD.DosPth]
	JMP Run_06
Run_12:	CMP AL, '@'
	JNE Run_14
	INC SI
	CMP BYTE [ListFlg], 0
	JNZ Run_13
	CALL FileLst
	MOV BYTE [ListFlg], 1
	JNC Run_13
	CALL Beep
Run_13:	MOV BX, MD.TmpBuf+100
	MOV AH, 1
	JMP Run_15
Run_14:	CMP AL, '\'
	JNE Run_18
	INC SI
	CMP BYTE [MD.PathEr], 0
	JNE Run_16
	MOV AH, 0
	MOV BX, MD.DosPth+2
Run_15:	MOV AL, [BX]
	CMP AL, 0
	JE Run_17
	INC BX
	STOSB
	CMP DI, MD.DosBuf+LenBat-2
	JAE Run_30
	LOOP Run_15
Run_16:	JMP Run_05
Run_17:	DW _OR_AH_AH
	JNE Run_16
	MOV AL, '\'
	CMP AL, [BX-1]
	JE Run_16
	JMP Run_06
Run_18:	MOV DX, '.'
	CMP AX, STRICT WORD '.!'
	JNE Run_19
	INC SI
	INC SI
	MOV DL, 0
Run_19:	PUSH SI
	DW _OR_BP_BP
	JE Run_21
	MOV SI, MD.ViewFil
	PUSH SI
	CALL CutPath
	DW _MOV_BX_SI
	POP SI
	DW _SUB_BX_SI
	JE Run_22
Run_20:	MOVSB
	CMP DI, MD.DosBuf+LenBat-2
	JAE Run_30
	DEC BX
	JNE Run_20
	JMP Run_22
Run_21:	MOV DS, [MD.WCBcrn]
	CMP DH, [WCBdef.Visible]
	JZ Run_23
	CMP DH, [WCBdef.WinTyp]
	JNE Run_23
	MOV SI, [WCBdef.CurAdr]
	CMP SI, [WCBdef.EndBuf]
	JAE Run_23
Run_22:	LODSB
	DW _CMP_AL_DL
	JE Run_23
	DW _CMP_AL_DH
	JE Run_23
	STOSB
	CMP DI, MD.DosBuf+LenBat-2
	JAE Run_30
	LOOP Run_22
Run_23:	PUSH ES
	POP DS
	POP SI
	JMP Run_05
Run_30:	DW _XOR_AX_AX
	STOSB
	MOV [ES:MD.DosBuf+LenBat-2], AX
	MOV DI, MD.DosBuf
	MOV CX, 256
	REPNE SCASB
	LEA DX, [DI-1-MD.DosBuf]
	MOV [ES:MD.DosCol], DL
	CALL DosCom
	CALL Cursor1
	CMP AL, [ES:MD.DosBuf]
	JNE Run_31
	JMP Func04
Run_31:	TEST BYTE [ES:MD.LoadFl], 80h
	JZ Run_32
	MOV BH, [ES:MD.DosLin]
	CALL ClsLine
Run_32:	JMP F21_30

;GLOBAL FileLst
FileLst:  ; PROC NEAR
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH CX
	MOV SI, MD.TempDir
	MOV DI, MD.TmpBuf+100
	PUSH DI
	MOV CX, LenPath
	CALL MvzLine
	PUSH CS
	POP DS
	MOV SI, List_F
	MOV CX, 13
	REP MOVSB
	PUSH ES
	POP DS
	POP DX
	CALL ChgDisk
	JC FiLs01
	MOV CX, 20h  ; Delete VC.LST
	MOV AX, 4301h
	CALL Intr21
	JNC FiLs02
	CMP AX, STRICT WORD 2
	JE FiLs03
	CMP AX, STRICT WORD 5
	JE FiLs02
FiLs01:	JMP FiLs18
FiLs02:	MOV AH, 41h
	CALL Intr21
	JC FiLs01
FiLs03:	MOV DS, [ES:MD.WCBcrn]
	CALL FilePan
	JNC FiLs01
	PUSH DX
	CALL TotSel
	DW _MOV_BP_DX
	DW _OR_BP_BX
	POP DX
	JNE FiLs10
	MOV SI, [WCBdef.CurAdr]
	CMP SI, [WCBdef.EndBuf]
	JAE FiLs01
	CMP BYTE [SI+FILENT.NameF], '.'
	JZ FiLs01
FiLs10:	PUSH DS  ; Create VC.LST
	PUSH ES
	POP DS
	MOV CX, 20h
	MOV AH, 3Ch
	CALL Intr21
	POP DS
	JC FiLs18
	DW _MOV_BX_AX
	MOV SI, [WCBdef.CurAdr]
	DW _OR_BP_BP
	JE FiLs13
	MOV SI, WCBdef.DskBuf
FiLs12:	CMP SI, [WCBdef.EndBuf]
	JAE FiLs20
	TEST BYTE [SI+FILENT.AttrF], 40h
	JZ FiLs16
FiLs13:	DW _MOV_DX_SI
	PUSH ES
	PUSH DS
	POP ES
	DW _MOV_DI_DX
	MOV CX, 0FFFFh
	MOV AL, 0
	REPNE SCASB
	POP ES
	NOT CX
	DEC CX
	MOV AH, 40h
	CALL Intr21
	JC FiLs17
	TEST BYTE [SI+FILENT.AttrF], 10h
	JZ FiLs15
	PUSH DS
	PUSH CS
	POP DS
	MOV DX, Mask_S
	MOV CX, 4
	MOV AH, 40h
	CALL Intr21
	POP DS
	JC FiLs17
FiLs15:	PUSH DS
	PUSH CS
	POP DS
	MOV DX, CrLf_S
	MOV CX, 2
	MOV AH, 40h
	CALL Intr21
	POP DS
	JC FiLs17
FiLs16:	ADD SI, FILENT_size
	JMP FiLs12
FiLs17:	MOV AH, 3Eh
	CALL Intr21
FiLs18:	STC
	JMP FiLs23
FiLs20:	MOV AH, 3Eh
	CALL Intr21
	JC FiLs18
	MOV SI, WCBdef.DskBuf
FiLs21:	CMP SI, [WCBdef.EndBuf]
	JAE FiLs23
	AND BYTE [SI+FILENT.AttrF], 7Fh
	TEST BYTE [SI+FILENT.AttrF], 40h
	JZ FiLs22
	AND BYTE [SI+FILENT.AttrF], 3Fh
	OR BYTE [SI+FILENT.AttrF], 80h
FiLs22:	ADD SI, FILENT_size
	JMP FiLs21
FiLs23:	POP CX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;FileLst ENDP

F40_00:	MOV CX, [ES:MD.LastMnu]  ; Shift F10 - pull down menu
	JMP F39_01

F39_00:	MOV CX, 1  ; F9 - pull down menu
	CMP CH, [WCBdef.Visible]
	JE F39_01
	CMP CH, [ES:MD.Active]
	JE F39_01
	MOV CL, 5
F39_01:	CALL HidCur
	PUSH DS
	PUSH ES
	POP DS
	DW _XOR_BX_BX
	MOV DX, 150h
	MOV SI, MD.ErrBuf
	CALL SavWin
	MOV AL, 1
	CALL PutKey
F39_02:	CALL F40_40
	JZ F39_04
	DW _OR_AH_AH
	JNE F39_04
	CALL F40_50
	DW _MOV_CL_AL
	CMP AL, 0
	JNE F39_04
	MOV AL, 0
	CALL PtMnu1
	MOV CH, 0
F39_03:	CALL F40_40
	JZ F39_06
	CALL ClrKbd
	DW _OR_AH_AH
	JNE F39_03
	CALL F40_50
	CMP AL, 0
	JE F39_03
F39_04:	CMP CH, 0
	JE F39_07
F39_05:	JMP F39_51
F39_06:	JMP F39_85
F39_07:	DW _MOV_AL_CL
	CALL PtMnu1
F39_10:	MOV AL, 8  ; Input
	MUL CL
	DW _MOV_SI_AX
	MOV SI, [CS:SI+MnuTab-2]
	DW _MOV_AL_CH
	CMP AL, 0FFh
	JE F39_11
	DW _ADD_SI_AX
F39_11:	MOV AL, [CS:SI]
	MOV [MD.HlpPage], AL
	CALL F40_40  ; Check mouse
	JZ F39_15
	CALL ClrKbd
	DW _OR_AH_AH
	JNE F39_17
	CALL F40_50
	DW _OR_CH_CH
	JE F39_14
	DW _CMP_AL_CL
	JNE F39_13
F39_12:	MOV AL, 0FFh
	JMP F39_41
F39_13:	MOV SI, MD.WinBuf
	CALL ResWin
	CMP AL, 0
	JNE F39_14
	CALL Window
F39_14:	DW _MOV_CL_AL
	MOV CH, 0FFh
	CMP AL, 0
	JNE F39_05
	JMP F39_02
F39_15:	TEST SI, 7
	JZ F39_18
	DW _OR_AH_AH
	JNE F39_16
	CMP CH, 0FFh
	JNE F39_18
	JMP F39_39
F39_16:	DW _MOV_AX_SI
	MOV [MD_MnuMous], AL
	JMP F39_44
F39_17:	DW _OR_CH_CH
	JE F39_10
	PUSH DX
	PUSH CX
	PUSH BX
	ADD BX, 101h
	SUB DX, 304h
	DW _MOV_CX_AX
	CALL InWind
	POP BX
	POP CX
	POP DX
	JC F39_12
	DW _MOV_AL_AH
	DEC AX
	CBW
	DW _MOV_SI_AX
	CMP BYTE [SI+MD_MnuList-1], 0
	JE F39_12
	JMP F39_41
F39_18:	MOV AL, 1
	CALL Input
	MOV SI, MenuTab
	CALL Case
	CALL UpCase  ; Letters
	CMP CH, 0
	JNE F39_21
	PUSH CX
	PUSH CS
	POP ES
	MOV DI, MnuKey
	MOV CX, 5
	REPNE SCASB
	PUSH DS
	POP ES
	POP CX
	JNE F39_20
	DW _MOV_AX_DI
	SUB AX, STRICT WORD MnuKey
	DW _MOV_CL_AL
	JMP F39_50
F39_20:	CMP AX, STRICT WORD 4400h
	JNE F39_31
	JMP F39_46
F39_21:	MOV DI, KeyTab
F39_22:	PUSH CS
	POP ES
	SCASW
	PUSH DS
	POP ES
	JNE F39_98
	CMP CL, [CS:DI]
	JE F39_24
F39_98:	INC DI
	INC DI
	CMP DI, KeyTabE
	JB F39_22
F39_23:	CMP AL, 0
	JE F39_20
	PUSH CX
	MOV DI, MD_MnuList
	DW _MOV_CL_DH
	SUB CL, 3
	MOV CH, 0
	REPNE SCASB
	POP CX
	JNE F39_31
	DW _MOV_AX_DI
	SUB AX, STRICT WORD MD_MnuList
	DW _MOV_CH_AL
	JMP F39_44
F39_24:	MOV AL, [CS:DI+1]
	CBW
	DW _MOV_SI_AX
	CMP AH, [SI+MD_MnuList-1]
	JE F39_23
	MOV CX, [CS:DI]
	JMP F39_44
F39_25:	DEC CL  ; Left
	JNE F39_27
	MOV CL, 5
	JMP F39_27
F39_26:	INC CX  ; Right
	CMP CL, 5
	JBE F39_27
	MOV CL, 1
F39_27:	DW _OR_CH_CH
	JNE F39_28
	JMP F39_07
F39_28:	MOV SI, MD.WinBuf
	CALL ResWin
F39_29:	JMP F39_50
F39_30:	DW _OR_CH_CH  ; Home, PgUp
	JNE F39_39
F39_31:	JMP F39_10
F39_32:	DW _OR_CH_CH  ; End, PgDn
	JNE F39_35
	JMP F39_10
F39_33:	DW _OR_CH_CH  ; Up
	JE F39_31
	DW _MOV_AL_CH
F39_34:	DEC AL
	JNE F39_36
F39_35:	DW _MOV_AL_DH
	SUB AL, 3
F39_36:	CBW
	DW _MOV_SI_AX
	CMP AH, [SI+MD_MnuList-1]
	JE F39_34
	JMP F39_41
F39_37:	DW _OR_CH_CH  ; Down
	JE F39_29
	DW _MOV_AL_CH
F39_38:	INC AX
	DW _MOV_AH_DH
	SUB AH, 2
	DW _CMP_AL_AH
	JB F39_40
F39_39:	MOV AL, 1
F39_40:	CBW
	DW _MOV_SI_AX
	CMP AH, [SI+MD_MnuList-1]
	JE F39_38
F39_41:	DW _CMP_AL_CH
	JE F39_31
	PUSH AX  ; Delete cursor
	MOV AH, MnuTx_C
	MOV AL, MnuBr_C
	CALL F40_10
	POP AX
	DW _MOV_CH_AL
F39_42:	MOV AH, MnuCu_C  ; Set cursor
	MOV AL, MnuCB_C
	CALL F40_10
	JMP F39_10
F39_43:	CMP CH, 0  ; Enter
	JE F39_50
F39_44:	MOV SI, MD.WinBuf
	CALL ResWin
	CALL Window
F39_45:	JMP F39_85
F39_46:	CMP CH, 0  ; Esc, Alt
	JE F39_45
	MOV SI, MD.WinBuf
	CALL ResWin
	CALL Window
	MOV CH, 0
	CMP AX, STRICT WORD 0FD00h
	JNE F39_45
	JMP F39_10
F39_50:	MOV CH, 1  ; Window
F39_51:	DW _MOV_AL_CL
	CALL PtMnu1
	PUSH CX
	DEC CX
	MOV AL, 8
	MUL CL
	DW _MOV_SI_AX
	ADD SI, MnuTab
CS
	LODSW
	DW _MOV_BX_AX
CS
	LODSW
	DW _MOV_DX_AX
CS
	LODSW
	MOV SI, MD.WinBuf
	CALL SavWin
	DW _MOV_SI_AX
	CALL BasAdr
	PUSH DI
	PUSH DX
	PUSH BX
	MOV AH, MnuBx_C
	CALL Color
	PUSH DX
	SUB DL, 4
	MOV DH, 0
	DW _XOR_CX_CX
	MOV BX, (('Ú'*256)&0FF00H)+('¿'&0FFH)  ; !!
	MOV AL, 'Ä'
	CALL BoxLine
	POP CX
	DW _MOV_CL_CH
	SUB CL, 3
	MOV CH, 0
	MOV BX, MD_MnuList
	MOV AL, '³'
F39_52:	PUSH DI
	PUSH CX
	PUSH AX
	MOV BYTE [BX], 0
	STOSW
	MOV AL, ' '
	STOSW
	DW _MOV_CX_DX
	DEC CX
	DEC CX
	CMP BYTE [CS:SI], 0
	JNE F39_53
	INC SI
	MOV AL, 'Ä'
	REP STOSW
	JMP F39_56
F39_95:
CS
	LODSB
	DW _SUB_CL_AL
	PUSH CX
	DW _MOV_CL_AL
	MOV CH, 0
	MOV AL, ' '
	REP STOSW
	POP CX
	JMP F39_54
F39_53:	MOV AH, MnuTx_C
	CALL Color
	MOV [DI-1], AH
F39_54:
CS
	LODSB
	CMP AL, 0FFh
	JE F39_95
	PUSH SI
	MOV SI, Ctrl_S
	CMP AL, '^'
	JE F39_96
	MOV SI, Alt_S
	CMP AL, '@'
	JNE F39_97
F39_96:
CS
	LODSB
	CMP AL, '-'
	JE F39_97
	STOSW
	DEC CX
	JMP F39_96
F39_97:	POP SI
	PUSH AX
	CMP AL, 'Z'
	JA F39_55
	CMP AL, 'A'
	JB F39_55
	CMP BYTE [BX], 0
	JNE F39_55
	MOV [BX], AL
	MOV AH, MnuBr_C
	CALL Color
F39_55:	STOSW
	POP AX
	DEC CX
	CMP BYTE [CS:SI], 0
	JNE F39_54
	INC SI
	JCXZ F39_56
	MOV AL, ' '
	REP STOSW
F39_56:	MOV AL, ' '
	STOSW
	POP AX
	STOSW
	CALL Shadow
	CALL Shadow
	INC BX
	POP CX
	POP DI
	ADD DI, 2*80
;LOOP	F39_52  ; Delta is longer than 7 bits, so we generate LOOP+JMPS+JMP.
	LOOP JF39_52
	JMP SHORT JSF39_52
JF39_52:
	JMP F39_52
JSF39_52:
	PUSH DI
	MOV AL, 'À'
	STOSW
	DW _MOV_CX_DX
	MOV AL, 'Ä'
	REP STOSW
	MOV AL, 'Ù'
	STOSW
	CALL Shadow
	CALL Shadow
	POP DI
	ADD DI, 2*82
	DW _MOV_CX_DX
	INC CX
	INC CX
F39_57:	CALL Shadow
	LOOP F39_57
	POP BX
	POP DX
	POP DI
	POP CX
	CMP CL, 4
	JNE F39_58
	ADD DI, 2*561  ; Options
	MOV AL, [MD.AutoMnu]
	CALL F40_20
	MOV AL, [MD.Prompt]
	CALL F40_20
	MOV AL, [MD.KeyBar]
	CALL F40_20
	MOV AL, [MD.FulScr]
	CALL F40_20
	MOV AL, [MD.AutoSiz]
	CALL F40_20
	MOV AL, [MD.MiniSta]
	CALL F40_20
	MOV AL, [MD.Clock]
	CALL F40_20
	MOV AL, [MD.LoadFl]
	CALL F40_20
	JMP F39_80
F39_58:	POP DS
	PUSH DS
	MOV AH, 0
	CMP CL, 2
	JNE F39_61
	CMP AH, [WCBdef.Visible]  ; Files
	JE F39_59
	CMP AH, [WCBdef.WinTyp]
	JE F39_60
F39_59:	MOV AL, 10
	CALL F40_30
	MOV AL, 12
	CALL F40_30
	MOV AL, 13
	CALL F40_30
	MOV AL, 14
	CALL F40_30
	MOV AL, 15
	CALL F40_30
F39_60:	JMP F39_80
F39_61:	CMP CL, 3
	JNE F39_67
	CMP AH, [WCBdef.Visible]  ; Commands
	JNE F39_63
	MOV AL, 9
	CALL F40_30
F39_62:	MOV AL, 4
	CALL F40_30
	JMP F39_64
F39_63:	CMP AH, [WCBdef.WinTyp]
	JNE F39_62
	CALL InvWCB
	CMP AH, [WCBdef.Visible]
	JE F39_64
	CMP AH, [WCBdef.WinTyp]
	JE F39_65
F39_64:	MOV AL, 11
	CALL F40_30
F39_65:	CMP AH, [ES:MD.TstEGA]
	JNE F39_66
	MOV AL, 7
	CALL F40_30
F39_66:	JMP F39_80
F39_67:	MOV DS, [ES:MD.WCB1seg]  ; Left / Right
	CMP CL, 1
	JE F39_68
	MOV DS, [ES:MD.WCB2seg]
	INC BYTE [ES:DI+2* 422]
	INC BYTE [ES:DI+2*1221]
F39_68:	PUSH DI
	ADD DI, 2*401
	CMP AH, [WCBdef.Visible]
	JE F39_71
	SUB DI, 2*320
	MOV AL, [WCBdef.WinTyp]
	CMP AL, 0
	JNE F39_69
	CMP AH, [WCBdef.BrfFul]
	JMP F39_70
F39_69:	ADD DI, 2*160
	CMP AL, 2
	JE F39_71
	ADD DI, 2*80
	CMP AL, 1
F39_70:	JE F39_71
	ADD DI, 2*80
F39_71:	MOV BYTE [ES:DI], 'û'
	POP DI
	CMP AH, [WCBdef.Visible]
	JE F39_73
	CMP AH, [WCBdef.WinTyp]
	JNE F39_73
	MOV AL, [WCBdef.SortTyp]
	CMP AL, 4
	JBE F39_72
	MOV AL, 4
F39_72:	MOV AH, 2*80
	MUL AH
	DW _MOV_BP_AX
	MOV BYTE [ES:DI+BP+2*561], 'û'
	JMP F39_74
F39_73:	MOV AL, 14
	CALL F40_30
F39_74:	MOV AH, 0
	PUSH DS
	CALL InvWCB
	CMP AH, [WCBdef.Visible]
	JE F39_75
	CMP BYTE [WCBdef.WinTyp], 1
	JNE F39_75
	MOV AL, 4
	CALL F40_30
F39_75:	POP DS
F39_80:	PUSH ES
	POP DS
	PUSH DX
	PUSH BX
	MOV BX, 100h
	MOV DX, 1550h
	CALL Window
	POP BX
	POP DX
	CMP CH, 0FFh
	JNE F39_81
	JMP F39_10
F39_81:	DW _MOV_AL_CH
	CBW
	DW _MOV_SI_AX
	CMP AH, [SI+MD_MnuList-1]
	JNE F39_82
	INC CH
	DW _MOV_AL_DH
	SUB AL, 2
	DW _CMP_CH_AL
	JB F39_81
	MOV CH, 1
	JMP F39_81
F39_82:	JMP F39_42

F39_85:	DW _XOR_BX_BX  ; Exit
	MOV DX, 150h
	MOV SI, MD.ErrBuf
	CALL ResWin
	CALL Window
	POP DS
	DW _MOV_AX_CX
	DW _OR_AH_AH
	JE F39_91
	CMP AH, 0FFh
	JE F39_91
	MOV [ES:MD.LastMnu], AX
	MOV DI, [ES:MD.WCB1seg]
	CMP AL, 5
	JNE F39_86
	MOV AL, 1
	MOV DI, [ES:MD.WCB2seg]
F39_86:	CMP AL, 1
	JNE F39_87
	PUSH DS
	MOV DS, DI
F39_87:	CMP AL, 2
	JNE F39_90
	CMP AH, 9
	JAE F39_90
	PUSH AX
	MOV AH, 2
	INT 16h
	DW _MOV_DL_AL
	POP AX
	TEST DL, 4
	JNZ F39_89
	TEST DL, 3
	JNZ F39_88
	TEST BYTE [ES:MD_MnuMous], 4
	JNZ F39_89
	TEST BYTE [ES:MD_MnuMous], 2
	JZ F39_90
F39_88:	MOV AL, 5
	JMP F39_90
F39_89:	MOV AL, 6
F39_90:	DW _MOV_BL_AL
	DW _ADD_BL_BL
	MOV BH, 0
	MOV SI, [CS:BX+Menu_T-2]
	DW _MOV_BL_AH
	DEC BX
	DW _ADD_BL_BL
	JMP [CS:BX+SI]
F39_91:	JMP Func04

;GLOBAL F40_10
F40_10:  ; PROC NEAR
	PUSH DX
	PUSH CX
	PUSH BX
	CMP CH, 0FFh
	JE F40_11
	PUSH AX
	DW _MOV_AL_CH
	CBW
	DW _MOV_SI_AX
	POP AX
	PUSH AX
	DW _MOV_BH_CH
	INC BH
	INC BL
	MOV DH, 1
	SUB DL, 4
	DW _MOV_CL_DL
	MOV CH, 0
	CALL Color
	DW _MOV_AL_AH
	CALL BasAdr
	PUSH DI
	PUSH CX
	CALL MvsColr
	POP CX
	POP DI
	MOV AL, [SI+MD_MnuList-1]
	REPNE SCASW
	POP AX
	DW _MOV_AH_AL
	CALL Color
	MOV [DI-1], AH
	CALL Window
F40_11:	POP BX
	POP CX
	POP DX
	RET
;F40_10 ENDP

;GLOBAL F40_20
F40_20:  ; PROC NEAR
	CMP AL, 0
	JE F40_21
	MOV BYTE [DI], 'û'
F40_21:	ADD DI, 2*80
	RET
;F40_20 ENDP

;GLOBAL F40_30
F40_30:  ; PROC NEAR  ; Dark line
	PUSH DI
	PUSH CX
	PUSH BX
	PUSH AX
	CBW
	DW _MOV_BX_AX
	MOV [ES:BX+MD_MnuList-1], AH
	MOV BL, 2*80
	MUL BL
	DW _ADD_DI_AX
	INC DI
	INC DI
	DW _MOV_BX_DI
	CMP CL, 2
	JE F40_31
	CMP CL, 3
	JE F40_31
	INC BX
	INC BX
F40_31:	MOV AH, MnuDr_C
	CALL Color
	DW _MOV_AL_AH
	DW _MOV_CL_DL
	SUB CL, 4
	MOV CH, 0
	CALL MvsColr
	MOV AH, MnuMi_C
	CALL Color
	MOV AL, '-'
	MOV [ES:BX], AX
	POP AX
	POP BX
	POP CX
	POP DI
	RET
;F40_30 ENDP

;GLOBAL F40_40
F40_40:  ; PROC NEAR  ; Get mouse cursor
	PUSH CX
	DW _XOR_AX_AX
	CALL GetMous
	XCHG AL, [MD_MnuMous]
	DW _MOV_SI_AX
	DW _MOV_AX_CX
	POP CX
	RET
;F40_40 ENDP

;GLOBAL F40_50
F40_50:  ; PROC NEAR  ; Menu position
	PUSH SI
	PUSH BX
	DW _MOV_AH_AL
	MOV SI, PtMnu_S
	DW _XOR_BX_BX
	LODSB
F40_51:	DW _MOV_AL_BL
	INC AX
	INC AX
	DW _CMP_AH_AL
	JB F40_54
	INC BH
	CMP BH, 5
	JA F40_53
CS
	LODSB
	DW _ADD_BL_AL
F40_52:
CS
	LODSB
	INC BX
	INC AL
	JNZ F40_52
	DEC BX
	JMP F40_51
F40_53:	MOV BH, 0
F40_54:	DW _MOV_AL_BH
	POP BX
	POP SI
	RET
;F40_50 ENDP

M01_00:	DEC CH  ; Brief / Full
	MOV CL, [WCBdef.SortTyp]
M01_01:	CALL HidCur
	CMP BYTE [WCBdef.WinTyp], 0
	JE M01_03
	MOV BP, DS
	CMP BP, [ES:MD.WCBcrn]
	JNE M01_02
	CALL M02_10
	JNC M01_02
	POP DS
	JMP Init50
M01_02:	MOV BYTE [WCBdef.WinTyp], 0
	MOV BYTE [WCBdef.ChgFlg], 1
M01_03:	DW _MOV_AL_CL
	XCHG [WCBdef.SortTyp], AL
	MOV [WCBdef.BrfFul], CH
	DW _CMP_AL_CL
	JE M01_04
	CMP BYTE [WCBdef.ChgFlg], 0
	JNZ M01_04
	JMP M16_11
M01_04:	JMP M03_05

;GLOBAL M02_10
M02_10:  ; PROC NEAR
	PUSH AX
	MOV AL, [WCBdef.WinPath]
	SUB AL, 'A'-1
	CALL Fantom
	JC M02_12
	MOV DX, WCBdef.WinPath
	MOV AH, 3Bh
	CALL Intr21
	JNC M02_11
	CMP AX, STRICT WORD 3
	STC
	JNE M02_12
M02_11:	MOV DL, [WCBdef.WinPath]
	SUB DL, 'A'
	MOV AH, 0Eh
	INT 21h
	CALL SetPth
	PUSHF
	CALL PutPrm
	POPF
M02_12:	POP AX
	RET
;M02_10 ENDP

M03_00:	CALL HidCur  ; Info / Tree
	MOV CL, 5
	DW _SUB_CL_CH
	JNE M03_01
	MOV CL, 3
M03_01:	CMP BYTE [WCBdef.Visible], 0
	JZ M03_02
	CMP CL, [WCBdef.WinTyp]
	JE M03_04
M03_02:	MOV DI, DS
	CMP DI, [ES:MD.WCBcrn]
	JNE M03_03
	CALL InvWCB
	CALL FilePan
	JNC M03_03
	CALL M02_10
	JNC M03_03
	POP DS
	JMP Func04
M03_03:	MOV DS, DI
	MOV AL, [WCBdef.WinTyp]
	DW _CMP_AL_CL
	JE M03_04
	MOV [WCBdef.Ctrl_L], AL
M03_04:	MOV [WCBdef.WinTyp], CL
	MOV BYTE [WCBdef.ChgFlg], 1
	CMP CL, 1
	JNE M03_05
	MOV BYTE [ES:MD.CrnPath], 0
M03_05:	MOV AX, DS
	MOV CL, 1
	CMP AX, [ES:MD.WCB1seg]
	JE M03_06
	MOV CL, 5
M03_06:	JMP M06_10

M06_00:	MOV AL, 0  ; Panel on/off
	CMP AL, [WCBdef.Visible]
	JZ M06_10
	MOV [WCBdef.Visible], AL  ; Panel off
	CALL BegBX
	CALL SizDX
	CALL ResUser
	MOV [ES:MD.Ctrl_O], AL
	MOV DI, DS
	MOV SI, [ES:MD.WCBcrn]
	DW _CMP_SI_DI
	JNE M06_01
	MOV DS, [ES:MD.WCBsec]
	CMP AL, [WCBdef.Visible]
	JZ M06_01
	MOV DS, SI
	DW _MOV_AL_CL
	CALL PutMnu
	CALL F20_02
	CALL PutPath
	CALL PutFls
M06_01:	POP DS
	JMP Func02
M06_10:	CALL HidCur  ; Panels On
	MOV BYTE [WCBdef.Visible], 1
	MOV DI, DS
	MOV AX, [ES:MD.WCBcrn]
	DW _CMP_AX_DI
	JE M06_11
	MOV DS, AX
	CMP BYTE [WCBdef.Visible], 0
	MOV DS, DI
	JNZ M06_11
	POP DS
	DW _MOV_AL_CL
	CALL PutMnu
	PUSH CX
	CALL F20_02
	POP CX
	PUSH DS
M06_11:	CMP BYTE [WCBdef.ChgFlg], 0
	JZ M06_12
	DW _MOV_AL_CL
	CALL PutMnu
	CALL TstInfo
M06_12:	POP DS
	JMP Init50

M08_00:	DW _MOV_CL_CH  ; Sort
	SUB CL, 7
	MOV CH, [WCBdef.BrfFul]
	JMP M01_01

M16_00:	CALL FilePan  ; Filter...
	JNC M16_02
	PUSH DS
M16_01:	MOV BP, Filt_B
	CALL Dialog
	JE M16_11
	POP DS
M16_02:	JMP Func04

M16_10:	CALL FilePan  ; Ctrl-H - hidden files
	JNC M16_02
	PUSH DS
	PUSH ES
	PUSH DS
	POP ES
	MOV BX, WCBdef.Hidden
	CALL InvVar
	POP ES
M16_11:	CALL M16_20
	JMP M03_05

;GLOBAL M16_20
M16_20:  ; PROC NEAR
	MOV SI, [WCBdef.CurAdr]
	MOV DI, MD.MenuBuf
	MOV CX, 13
	PUSH CX
	REP MOVSB
	POP CX
	MOV SI, [WCBdef.First]
	REP MOVSB
	MOV BX, [WCBdef.EndBuf]
	CALL SetMask
	CALL Sort
	MOV CX, WCBdef.DskBuf
	DW _MOV_DX_CX
	DW _CMP_BX_CX
	JBE M16_13
	MOV DI, MD.MenuBuf
	CALL FnFile
	JNC M16_12
	DW _MOV_CX_SI
M16_12:	MOV DI, MD.MenuBuf+13
	CALL FnFile
	JNC M16_13
	DW _MOV_DX_SI
M16_13:	MOV [WCBdef.CurAdr], CX
	MOV [WCBdef.First], DX
	RET
;M16_20 ENDP

M21_00:	CALL Help  ; Help
	JMP Func04

M41_00:	CALL PutMnu3  ; Alt F10 - Tree
	MOV BYTE [ES:MD.HlpPage], 28
	MOV AL, 16
	CALL ChTree
	JC M41_01
	PUSH DS
	PUSH ES
	MOV DX, MD.TmpBuf
	JMP F24_01
M41_01:	JMP Init50

M42_00:	CALL FilePan  ; Alt F6 - Directory sizes
	JNC M42_01
	MOV AL, [WCBdef.WinPath]
	MOV AH, 0
	PUSH DS
	PUSH ES
	POP DS
	MOV [ES:MD.TmpBuf], AX
	CALL PutMnu3
	MOV BX, 528h
	MOV BP, DiSiz_P
	CALL DialBox
	POP DS
	CALL Window
	PUSH SI
	PUSH DX
	PUSH BX
	CALL DirSize
	CALL M16_20
	POP BX
	POP DX
	POP SI
	CALL ResWin
	CALL Window
M42_01:	JMP Init50

F69_00:	CMP BYTE [ES:MD.TstEGA], 0  ; Alt F9 - EGA lines
	JNE F69_01
	JMP Func04
F69_01:	CALL Quit
	MOV BH, [MD.DosLin]
	CALL ClsLine
	CALL SavMous
	MOV AL, 0
	CALL CurMous
	MOV BYTE [MD.BarPrev], 0FFh
	MOV BYTE [MD.ScrPage], 0
	PUSH ES
	MOV BH, 0
	MOV CL, 16
	MOV AX, 1130h
	INT 10h
	PUSH CX
	MOV AL, [MD.ScrMod]
	MOV AH, 0
	INT 10h
	POP AX
	CMP AL, 14
	JB F69_03
	MOV AX, 1112h
	INT 10h
	MOV AH, 12h
	MOV BL, 20h
	INT 10h
F69_03:	MOV DL, 0
	MOV BH, 0
	MOV AX, 1130h
	INT 10h
	POP ES
	MOV AL, 25
	DW _OR_DL_DL
	JE F69_04
	INC DX
	MOV AL, MaxLins
	DW _CMP_AL_DL
	JBE F69_04
	DW _MOV_AL_DL
F69_04:	DW _MOV_DL_AL
	XCHG AL, [MD.Lines]
	CLD
	MOV DI, MD.ScrBuf
	MOV AH, 2*80
	DW _CMP_AL_DL
	JB F69_06
	JE F69_07
	DW _SUB_AL_DL
	SUB [MD.DosLin], AL
	JA F69_05
	MOV BYTE [MD.DosLin], 1
F69_05:	MUL AH
	DW _MOV_SI_DI
	DW _ADD_SI_AX
	MOV AL, 80
	MUL DL
	DW _MOV_CX_AX
	REP MOVSW
	JMP F69_07
F69_06:	DW _SUB_DL_AL
	MUL AH
	DW _ADD_DI_AX
	MOV AL, 80
	MUL DL
	DW _MOV_CX_AX
	MOV AH, [MD.CrntCol]
	MOV AL, ' '
	REP STOSW
F69_07:	MOV SI, MD.ScrBuf
	MOV DI, MD.UserScr
	MOV CX, (MaxLins-1)*80
	REP MOVSW
	CALL ScrOffs
	CMP BYTE [MD.Mouse], 0
	JE F69_09
	MOV AL, [MD.Lines]
	CBW
	MOV CL, 3
	SHL AX, CL
	DEC AX
	CMP [MD.MouseY], AX
	JBE F69_08
	MOV [MD.MouseY], AX
F69_08:	CALL IniMous
F69_09:	JMP M60_02

M49_00:	CALL FilePan  ; Compare directories
	JNC M49_01
	CALL InvWCB
	CALL FilePan
	JNC M49_01
	MOV CL, 0
	CALL M49_10
	CALL InvWCB
	CALL M49_10
	CMP CL, 0
	JNE M49_02
	MOV BP, CmpDi_B
	CALL Dialog
M49_01:	JMP Func04
M49_02:	JMP M60_02

;GLOBAL M49_10
M49_10:  ; PROC NEAR
	MOV SI, WCBdef.DskBuf
M49_11:	CMP SI, [WCBdef.EndBuf]
	JAE M49_14
	TEST BYTE [SI+13], 10h
	JNZ M49_13
	PUSH DS
	PUSH SI
	MOV DI, MD.TmpBuf
	PUSH DI
	PUSH CX
	MOV CX, 13
	REP MOVSB
	POP CX
	POP DI
	CALL InvWCB
	CALL FnFile
	MOV AL, [SI+13]
	MOV BX, [SI+14]
	MOV DX, [SI+16]
	POP SI
	POP DS
	JNC M49_12
	TEST AL, 10h
	JNZ M49_12
	CMP DX, [SI+16]
	JB M49_12
	JA M49_13
	CMP BX, [SI+14]
	JAE M49_13
M49_12:	OR BYTE [SI+13], 40h
	MOV CL, 1
M49_13:	ADD SI, FILENT_size
	JMP M49_11
M49_14:	RET
;M49_10 ENDP

M60_00:	PUSH ES  ; Configuration
	POP DS
	MOV DI, MD.TmpBuf
	MOV AL, [MD.ColTyp]
	STOSB
	STOSB
	MOV AH, [MD.BlDelay]
	MOV SI, Delay_T-1
	MOV AL, 0-1
M60_01:	INC AL
	INC SI
	CMP AH, [CS:SI]
	JB M60_01
	STOSB
	STOSB
	MOV CL, [MD.MenuVs]
	MOV DX, Chk1_S
	MOV BP, Conf_B
	CALL Dialog
	JNE M61_01
	MOV SI, MD.TmpBuf
	LODSW
	MOV [MD.ColTyp], AL
	LODSW
	CBW
	DW _MOV_BX_AX
	MOV AL, [CS:BX+Delay_T]
	MOV [MD.BlDelay], AL
	DW _XOR_BX_BX
	MOV DH, [MD.Lines]
	SUB DH, 2
	MOV DL, 80
	CALL ResUser
	MOV AL, 0
	CALL PutMnu
M60_02:	CALL PutPrm
	CMP BYTE [WCBdef.Visible], 0
	JZ M61_01
	JMP Init50

M61_00:	PUSH ES  ; Advanced options
	POP DS
	MOV DX, Chk2_S
	MOV BP, Sets_B
	CALL Dialog
M61_01:	JMP Func04

M53_00:	MOV BX, Menu_F  ; Menu file edit
	MOV SI, User_S
	MOV DX, UsMnu_S
	MOV AL, 38
	JMP M64_02

M62_00:	MOV BX, Ext_F  ; Extension file edit
	MOV AL, 42
	JMP M64_01

M63_00:	MOV BX, ViewE_F  ; Viewer file
	MOV AL, 43
	JMP M64_01

M64_00:	MOV BX, EditE_F  ; Editor file
	MOV AL, 44
M64_01:	MOV SI, ExFl_S
	MOV DX, ExtFl_S
M64_02:	MOV [ES:MD.HlpPage], AL
	PUSH CX
	DW _MOV_AL_CL
	CALL PutMnu
	PUSH CS
	POP DS
	MOV DI, MD.TmpBuf
	MOV CX, 80
	REP MOVSB
	PUSH ES
	POP DS
	MOV BP, MnLoc_B
	CALL Dialog
	CMP AL, 2
	JB M64_03
	POP CX
	JMP Func04
M64_03:	PUSH CS
	POP DS
	DW _MOV_SI_BX
	MOV DI, MD.TmpBuf
	PUSH DI
	MOV CX, 13
	PUSH DI
	REP MOVSB
	POP DI
	PUSH ES
	POP DS
	DW _MOV_SI_BX
	CMP AL, 0
	JNE M64_04
	CALL MainFil
M64_04:	POP SI
	CALL LetLin
	MOV DI, MD.ViewFil
	MOV CX, LenStr
	REP MOVSB
	MOV AL, 0
	STOSB
	POP AX
	MOV DL, 1
	JMP V00_01

M66_00:	MOV BX, MD.AutoMnu  ; Auto menus
M66_01:	CALL InvVar
	JMP M60_02

M67_00:	MOV BX, MD.Prompt  ; Path prompt
	JMP M66_01

M69_00:	CALL BegBX  ; Full screen
	CALL SizDX
	MOV BL, 0
	MOV DL, 80
	CALL ResUser
	MOV BX, MD.FulScr
	CALL InvVar
	JMP M60_02

M70_00:	MOV BX, MD.AutoSiz  ; Auto directory sizes
	CMP BYTE [ES:BX], 0
	JNZ M66_01
	PUSH DS
	MOV BYTE [WCBdef.ChgFlg], 1
	CALL InvWCB
	MOV BYTE [WCBdef.ChgFlg], 1
	POP DS
	JMP M66_01

M71_00:	MOV BX, MD.MiniSta  ; Mini status
	JMP M66_01

M72_00:	MOV BX, MD.Clock  ; Clock
	JMP M66_01

M73_00:	MOV BX, MD.LoadFl  ; Memory allocation
	JMP M66_01

M75_00:	MOV BP, SvSt_B  ; Save setup
	CALL Dialog
	JNE M75_01
	CALL SaveSet
	JNC M75_01
	CMP AX, STRICT WORD 53h
	JE M75_01
	MOV BP, SetEr_B
	CALL Dialog
M75_01:	JMP Func04

F37_00:	CMP BYTE [WCBdef.WinTyp], 1  ; F7 - make directory
	JNE F47_00
	CMP BYTE [WCBdef.Visible], 0
	JZ F47_00
	MOV BP, MkDi2_B
	JMP F47_01
F37_01:	JMP Func04

F47_00:	MOV BP, MkDi1_B  ; Shift F7 - make directory
F47_01:	PUSH ES
	POP DS
	MOV SI, MD.TmpBuf
	MOV BYTE [SI], 0
	MOV DX, CrDir_S
	CALL Dialog
	JNE F37_01
	CMP BYTE [SI], 0
	JE F37_01
	DW _MOV_DX_SI
	CALL CutPath
	MOV DI, MD.TmpBuf+100
	CALL Convert
	DW _XCHG_SI_DI
	CALL UnConv
	CMP BP, MkDi2_B
	JNE F47_02
	DW _MOV_SI_DX
	CALL CutPath
	DW _CMP_SI_DX
	JNE F47_03
	PUSH DX
	MOV SI, MD.CrnPath+2
	MOV DI, MD.TmpBuf+100
	MOV CX, LenPath
	DW _MOV_DX_DI
	CALL MvzLine
	POP SI
	CALL AddFile
	PUSH SI
	MOV CX, 13
	REP MOVSB
	POP SI
F47_02:	CALL ChgDisk
	JC F47_04
	MOV AH, 39h
	CALL Intr21
	JNC F47_05
	CMP AX, STRICT WORD 53h
	JE F47_04
F47_03:	MOV SI, MD.TmpBuf
	MOV DI, MD.TmpBuf+130
	MOV CX, LenPath+13
	REP MOVSB
	MOV DX, MkDir_S
	MOV BP, MkErr_B
	CALL Dialog
F47_04:	JMP Func04
F47_05:	DW _MOV_SI_DX
	CMP BP, MkDi2_B
	JNE F47_06
	MOV DI, MD.CrnPath+2
	PUSH DI
	MOV CX, LenPath-2
	REP MOVSB
	MOV AL, 0
	STOSB
	POP SI
	CALL PathLin
	JMP F47_07
F47_06:	CALL CutPath
	DW _CMP_SI_DX
	JNE F47_07
	CALL PathLin
	MOV ES, [ES:MD.WCBcrn]
	MOV AX, [ES:WCBdef.EndBuf]
	DW _MOV_DI_AX
	MOV [ES:WCBdef.CurAdr], AX
	ADD AX, STRICT WORD FILENT_size
	MOV [ES:WCBdef.EndBuf], AX
	MOV CX, 12
	REP MOVSB
	MOV AX, 1000h
	STOSW
	PUSH DS
	POP ES
F47_07:	DW _MOV_SI_DX
	CALL DelTree
	JMP FncEx1

F38_00:	MOV AL, 0  ; F8 - delete
	MOV [ES:MD.TmpBuf+90], AL
	MOV [ES:MD.TmpBuf+91], AL
	MOV [ES:MD.TmpBuf+92], AL
	MOV WORD [ES:MD.FncAddr], F38_40
	CMP [WCBdef.Visible], AL
	JZ F38_03
	CMP BYTE [WCBdef.WinTyp], 1
	JB F38_04
	JNE F38_03
	PUSH ES  ; Delete from tree panel
	POP DS
	MOV SI, MD.CrnPath
	CMP BYTE [SI+3], 0
	JE F38_02
	MOV DI, MD.TmpBuf
	MOV CX, LenPath
	REP MOVSB
	MOV DX, Subdi_S
	MOV BP, DelDi_B
	CALL Dialog
	JNE F38_05
	MOV [MD.ZoomOne], AL
	MOV AL, 10h
	CALL F38_40
	CMP AL, 0
	JE F38_02
	MOV SI, MD.CrnPath
	CALL CutPath
	CMP SI, MD.CrnPath+3
	JBE F38_01
	DEC SI
F38_01:	MOV BYTE [SI], 0
F38_02:	JMP FncExt
F38_03:	JMP F48_00
F38_04:	CALL TotSel
	DW _MOV_AX_BX
	DW _OR_AX_DX
	MOV DI, MD.TmpBuf
	JE F38_06
	CMP BYTE [ES:MD.OneFile], 0
	JNZ F38_06
	CALL FilDir  ; Delete selected files
	MOV SI, WCBdef.WinPath
	MOV DI, MD.TmpBuf+100
	MOV CX, LenPath
	REP MOVSB
	PUSH ES
	POP DS
	MOV BP, DelSe_B
	JMP F38_08
F38_05:	JMP Func04
F38_06:	MOV SI, [WCBdef.CurAdr]  ; Delete file / directory
	CMP SI, [WCBdef.EndBuf]
	JAE F38_02
	CMP BYTE [SI+FILENT.NameF], '.'
	JE F38_02
	MOV DX, Empty_S
	MOV BP, DelFi_B
	TEST BYTE [SI+FILENT.AttrF], 10h
	JZ F38_07
	MOV DX, Subdi_S
	MOV BP, DelDi_B
F38_07:	MOV CX, 13
	REP MOVSB
	PUSH ES
	POP DS
F38_08:	CALL Dialog
	JNE F38_05
	JMP FncSel

;GLOBAL F38_10
F38_10:  ; PROC NEAR
	CMP AL, 0
	JNE F38_11
	MOV BP, DelCo_B
	CALL Dialog
	CMP AL, 1
	JA F38_11
	MOV [MD.TmpBuf+90], AL
	MOV AL, 0
F38_11:	CLC
	RET
;F38_10 ENDP

;GLOBAL F38_40
F38_40:  ; PROC NEAR  ; Delete file or directory
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH ES
	POP DS
	TEST AL, 10h
	JZ F38_41
	JMP STRICT NEAR F38_50  ; !! SHORT would fit.
F38_41:	MOV DX, Empty_S
	MOV BX, 528h
	MOV BP, DelFl_P
	CALL OncZoom
	PUSH SI
	PUSH DX
	PUSH BX
	MOV DX, MD.TmpBuf
	CALL ChgDisk
	JC F38_45
	MOV AH, 41h
	CALL Intr21
	JNC F38_46
	CMP AX, STRICT WORD 5
	JNE F38_42
	MOV AX, 4300h
	CALL Intr21
	JC F38_42
	MOV AL, 0
	TEST CL, 1
	JZ F38_42
	PUSH DX
	MOV DX, Del_S
	MOV BP, RdOnl_B
	CALL Dialog
	POP DX
	CMP AL, 1
	JE F38_44
	JA F38_45
	MOV CX, 20h
	MOV AX, 4301h
	CALL Intr21
	JC F38_42
	MOV BYTE [MD.TmpBuf+91], 1
	MOV AH, 41h
	CALL Intr21
	JNC F38_46
F38_42:	DW _MOV_SI_DX
	MOV DI, MD.TmpBuf+130
	MOV CX, LenPath+13
	REP MOVSB
	MOV DX, Del_S
	MOV BP, DelEr_B
F38_43:	CMP AX, STRICT WORD 53h
	JE F38_45
	CALL Dialog
	JNZ F38_45
F38_44:	DW _XOR_AX_AX
	JMP F38_56
F38_45:	JMP F38_53
F38_46:	JMP F38_55
F38_50:	MOV BX, 528h
	MOV DX, Del_S
	MOV BP, DelDr_P
	CALL OncZoom
	PUSH SI
	PUSH DX
	PUSH BX
	MOV DX, MD.TmpBuf
	CALL ChgDisk
	JC F38_45
	CALL F38_60
;JNC	F38_54
	JC JSF38_54  ; !! SHORT would fit.
	JMP STRICT NEAR F38_54
JSF38_54:
	MOV DX, Del_S
	MOV BP, CntDi_B
	CMP AX, STRICT WORD 100
	JAE F38_51
	CMP AL, 5
	JNE F38_43
F38_51:	CMP BYTE [MD.TmpBuf+90], 0
	JNE F38_52
	MOV BP, NoEmp_B
	CALL Dialog
	CMP AL, 1
	JA F38_44
	JB F38_52
	MOV BYTE [MD.TmpBuf+90], 1
F38_52:	POP BX
	POP DX
	POP SI
	CALL ResWin
	CALL Window
	MOV DI, MD.TmpBuf
	MOV CX, LenPath+13
	MOV AL, 0
	REPNE SCASB
	DEC DI
	PUSH DI
	PUSH CS
	POP DS
	MOV SI, Mask_S
	MOV CX, 5
	REP MOVSB
	POP DI
	CALL F38_70
	MOV BYTE [ES:DI], 0
	DW _OR_AH_AH
	JNZ F38_57
	CALL DirFunc
	PUSH ES
	POP DS
	DW _OR_AH_AH
	JNZ F38_57
	MOV BX, 528h
	MOV DX, Del_S
	MOV BP, DelDr_P
	CALL OncZoom
	PUSH SI
	PUSH DX
	PUSH BX
	MOV DX, MD.TmpBuf
	CALL F38_60
	JNC F38_54
	CMP AX, STRICT WORD 53h
	JE F38_53
	JMP F38_44
F38_53:	MOV AX, 100h
	JMP F38_56
F38_54:	MOV BYTE [MD.TmpBuf+91], 1
	CMP BYTE [MD.TmpBuf+92], 0
	JNZ F38_55
	MOV BYTE [MD.TmpBuf+92], 1
	MOV SI, MD.TmpBuf
	CALL DelTree
	JNC F38_55
	CMP AX, STRICT WORD 53h
	JE F38_53
F38_55:	MOV AX, 1
F38_56:	POP BX
	POP DX
	POP SI
	CALL ResWin
	CALL Window
F38_57:	OR [ES:MD.TmpBuf+91], AL
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;F38_40 ENDP

;GLOBAL F38_60
F38_60:  ; PROC NEAR
	MOV AH, 3Ah
	CALL Intr21
	JNC F38_61
	CMP AX, STRICT WORD 10h
	STC
	JNE F38_61
	DW _MOV_SI_DX
	MOV DI, MD.TmpErr
	MOV AH, 60h
	CALL Intr21
	JC F38_61
	PUSH SI
	PUSH DI
	DW _XCHG_SI_DI
	MOV CX, LenPath+13
	REP MOVSB
	POP DI
	POP SI
	DW _MOV_DX_DI
	MOV AX, '.'
	STOSB
	STOSW
	MOV AH, 3Bh
	CALL Intr21
	JC F38_61
	DW _MOV_DX_SI
	MOV AH, 3Ah
	CALL Intr21
F38_61:	RET
;F38_60 ENDP

;GLOBAL F38_70
F38_70:  ; PROC NEAR  ; Delete files
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH ES
	POP DS
	MOV DI, MD.TmpBuf+200
	MOV AL, 0FFh
	STOSB
	ADD DI, 5
	MOV AL, 26h
	STOSB
	MOV AX, [MD.TmpBuf]
	CMP AH, ':'
	JE F38_71
	MOV AL, 'A'-1
F38_71:	SUB AL, 'A'-1
	STOSB
	MOV SI, MD.TmpBuf
	CALL CutPath
	DW _MOV_CX_SI
	DEC DI
	MOV AX, 2902h
	INT 21h
	CMP AL, 1
	MOV AX, 0
	JE F38_72
	JMP F38_80
F38_72:	MOV DX, DelFs_S
	MOV BX, 528h
	MOV BP, DelFl_P
	CALL OncZoom
	PUSH SI
	PUSH DX
	PUSH BX
	DW _MOV_SI_CX
	MOV DX, MD.TmpBuf
	CALL ChgDisk
	JC F38_76
	MOV DI, MD.TmpBuf+100
	MOV BYTE [DI], 0
	CMP SI, MD.TmpBuf
	JBE F38_77
	CMP BYTE [SI-1], '\'
	JNE F38_77
	PUSH SI
	MOV AL, [MD.TmpBuf+200+7]
	DW _MOV_DL_AL
	CMP AL, 0
	JE F38_73
	ADD AL, 'A'-1
	MOV AH, ':'
	STOSW
F38_73:	MOV AL, '\'
	STOSB
	DW _MOV_SI_DI
	MOV AH, 47h
	CALL Intr21
	POP SI
	JC F38_75
	CMP SI, MD.TmpBuf+1
	JBE F38_74
	CMP BYTE [SI-2], ':'
	JE F38_74
	DEC SI
F38_74:	MOV BL, 0
	XCHG BL, [SI]
	MOV DX, MD.TmpBuf
	MOV AH, 3Bh
	CALL Intr21
	MOV [SI], BL
	JNC F38_77
F38_75:	CMP AX, STRICT WORD 53h
	JE F38_76
	DW _XOR_AX_AX
	JMP F38_79
F38_76:	MOV AX, 100h
	JMP F38_79
F38_77:	MOV BYTE [MD.TmpBuf+91], 1
	MOV DX, MD.TmpBuf+200
	MOV AH, 13h
	CALL Intr21
	CMP BYTE [MD.TmpBuf+100], 0
	JE F38_78
	DW _MOV_BL_AL
	MOV DX, MD.TmpBuf+100
	MOV AH, 3Bh
	CALL Intr21
	JC F38_76
	DW _MOV_AL_BL
F38_78:	INC AX
	CBW
F38_79:	POP BX
	POP DX
	POP SI
	CALL ResWin
	CALL Window
F38_80:	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;F38_70 ENDP

F48_00:	PUSH ES  ; Shift F8 - delete
	POP DS
	MOV BP, DlMas_B
	CALL Dialog
	JNE F48_03
	MOV SI, MD.ViewFil
	MOV DI, MD.TmpBuf
	MOV CX, LenStr+1
	PUSH DI
	REP MOVSB
	POP SI
	CALL NormStr
	CALL LetLin
	CMP BYTE [SI], 0
	JE F48_03
	CALL CutPath
	CMP WORD [SI], '.'
	JE F48_01
	PUSH SI
	MOV DI, MD.TmpBuf+100
	MOV AH, 29h
	INT 21h
	POP SI
	CMP AL, 1
	JNE F48_04
	INC DI
	MOV CX, 11
	MOV AL, '?'
	REPE SCASB
	JNE F48_04
F48_01:	PUSH CS
	POP DS
	DW _MOV_DI_SI
	MOV SI, Mask_S+1
	MOV CX, 4
	REP MOVSB
	PUSH ES
	POP DS
	MOV SI, MD.TmpBuf
	DW _MOV_DI_SI
	CALL CutPath
	DW _XCHG_SI_DI
	DW _CMP_SI_DI
	JNE F48_02
	PUSH CS
	POP DS
	MOV SI, DlWr4_S
F48_02:	MOV DI, MD.TmpBuf+100
	MOV CX, LenPath+13
	REP MOVSB
	PUSH ES
	POP DS
	MOV BP, DlWrn_B
	CALL Dialog
	JE F48_04
F48_03:	JMP Func04
F48_04:	MOV AL, 0
	MOV [MD.ZoomOne], AL
	MOV [MD.TmpBuf+90], AL
	MOV [MD.TmpBuf+91], AL
	MOV [MD.TmpBuf+92], AL
	MOV WORD [MD.FncAddr], F38_40
	CALL F38_70
	DW _OR_AH_AH
	JNZ F48_06
	DW _XOR_BX_BX
	CMP AL, 0
	JNZ F48_05
	MOV BX, Del_S
F48_05:	JMP FncMs1
F48_06:	JMP FncExt

F58_00:	MOV BYTE [ES:MD.OneFile], 1  ; ^F8 - delete one file
	JMP F38_00

M30_00:	CALL FilePan  ; Attributes...
	JNC M30_02
	CALL TotSel
	DW _OR_BX_DX
	JE M30_03
M30_01:	MOV DI, MD.TmpBuf  ; Selected files
	MOV CX, 100
	MOV AL, 0
	REP STOSB
	PUSH ES
	POP DS
	MOV DX, Empty_S
	MOV BP, StAt2_B
	CALL Dialog
	JNE M30_02
	MOV SI, MD.TmpBuf
	CALL M30_82
	DW _MOV_AH_AL
	MOV SI, MD.TmpBuf+10
	CALL M30_82
	NOT AL
	JMP M30_07
M30_02:	JMP Func04
M30_03:	MOV SI, [WCBdef.CurAdr]  ; One file
	CMP SI, [WCBdef.EndBuf]
	JAE M30_02
	CMP BYTE [SI+FILENT.NameF], '.'
	JE M30_02
	MOV CL, [SI+FILENT.AttrF]
	TEST CL, 10h
	JNZ M30_01
	MOV DI, MD.TmpBuf
	MOV AL, 1
	CALL M30_80
	MOV AL, 20h
	CALL M30_80
	MOV AL, 2
	CALL M30_80
	MOV AL, 4
	CALL M30_80
	MOV AX, [SI+FILENT.DateF]
	CALL PutDate
	MOV DI, MD.TmpBuf+15
	CMP BL, ' '
	JNE M30_04
	DEC DI
M30_04:	CALL BufDate
	MOV AL, 0
	STOSB
	MOV AX, [SI+FILENT.TimeF]
	CALL PutTime
	MOV DI, MD.TmpBuf+30
	CMP BL, ' '
	JNE M30_05
	DEC DI
M30_05:	CALL BufTime
	CMP AL, ' '
	JNE M30_06
	DEC DI
M30_06:	MOV AL, 0
	STOSB
	MOV DI, MD.TmpBuf+100
	MOV CX, 13
	REP MOVSB
	PUSH ES
	POP DS
	MOV DX, Attr8_S
	MOV BP, StAt1_B
	CALL Dialog
	JNE M30_08
	MOV SI, MD.TmpBuf
	CALL M30_82
	DW _MOV_AH_AL
M30_07:	MOV [MD.TmpBuf+94], AX
	MOV WORD [MD.FncAddr], M30_50
	JMP FncSel
M30_08:	JMP Func04

;GLOBAL M30_50
M30_50:  ; PROC NEAR  ; Set attributes
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH ES
	POP DS
	TEST AL, 10h
	JZ M30_51
	CALL DirFunc
	JMP M30_59
M30_51:	MOV BX, 528h
	MOV BP, StAtr_P
	CALL OncZoom
	PUSH SI
	PUSH DX
	PUSH BX
	MOV DX, MD.TmpBuf
	CALL ChgDisk
	JC M30_55
	MOV AX, 4300h
	CALL Intr21
	JC M30_56
	DW _MOV_DI_CX
	MOV AX, [AttrDat]
	AND AX, [AttrTim]
	INC AX
	JE M30_54
	AND CL, 0FEh
	MOV AX, 4301h
	CALL Intr21
	JC M30_56
	MOV BYTE [MD.TmpBuf+91], 1
	MOV AL, 41h
	CALL OpenFil
	JC M30_56
	DW _MOV_BX_AX
	PUSH DX
	MOV AX, 5700h
	CALL Intr21
	MOV AX, [AttrDat]
	CMP AX, STRICT WORD 0FFFFh
	JE M30_52
	DW _MOV_DX_AX
M30_52:	MOV AX, [AttrTim]
	CMP AX, STRICT WORD 0FFFFh
	JE M30_53
	DW _MOV_CX_AX
M30_53:	MOV AX, 5701h
	CALL Intr21
	POP DX
	MOV AH, 3Eh
	CALL Intr21
	JC M30_56
M30_54:	DW _MOV_CX_DI
	AND CL, [MD.TmpBuf+94]
	OR CL, [MD.TmpBuf+95]
	MOV AX, 4301h
	CALL Intr21
	JC M30_56
	MOV AX, 1
	JMP M30_58
M30_55:	MOV AX, 100h
	JMP M30_58
M30_56:	CMP AX, STRICT WORD 53h
	JE M30_55
	MOV DX, NoFnd_S
	CMP AX, STRICT WORD 3
	JBE M30_57
	MOV DX, NoAtr_S
M30_57:	MOV BP, AtrEr_B
	CALL Dialog
	JNE M30_55
	DW _XOR_AX_AX
M30_58:	OR [MD.TmpBuf+91], AL
	POP BX
	POP DX
	POP SI
	CALL ResWin
	CALL Window
M30_59:	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;M30_50 ENDP

;GLOBAL M30_60
M30_60:  ; PROC NEAR  ; Test date & time
	CMP AL, 0
	JNE M30_76
	MOV WORD [AttrDat], 0FFFFh
	MOV WORD [AttrTim], 0FFFFh
	MOV SI, MD.DosBuf+LenCmd+10+3
	CALL FndLet
	CMP AL, 0
	JE M30_70
	CALL TxtNum
	JC M30_62
	DW _MOV_CX_AX
	CALL FndLet
	CMP AL, [MD.Country+CNTRY.DateSep]
	JNE M30_61
	INC SI
	CALL FndLet
	CALL TxtNum
	JC M30_62
	DW _MOV_DX_AX
	CALL FndLet
	CMP AL, [MD.Country+CNTRY.DateSep]
M30_61:  ;JNE	M30_67
	JE JSM30_67  ; !! SHORT would fit.
	JMP STRICT NEAR M30_67
JSM30_67:
	INC SI
	CALL FndLet
	CALL TxtNum
M30_62:	JC M30_67
	DW _MOV_BX_AX
	CALL FndLet
	CMP AL, 0
	JNE M30_67
	CMP WORD [MD.Country+CNTRY.DateFmt], 0
	JE M30_63
	DW _XCHG_CX_DX
	CMP WORD [MD.Country+CNTRY.DateFmt], 1
	JE M30_63
	DW _XCHG_BX_DX
M30_63:	SUB BX, 1980
	JAE M30_64
	ADD BX, 1980
	CMP BX, 100
	JAE M30_67
	SUB BL, 80
	JAE M30_64
	ADD BL, 100
M30_64:	CMP BX, 128
	JAE M30_67
	CMP CX, 12
	JA M30_67
	CMP CL, 1
	JB M30_67
	DW _MOV_AX_CX
	CMP AL, 7
	JBE M30_65
	INC AX
M30_65:	AND AL, 1
	ADD AL, 30
	CMP CL, 2
	JNE M30_66
	MOV AL, 28
	TEST BL, 3
	JNZ M30_66
	INC AX
M30_66:	DW _CMP_DX_AX
	JA M30_67
	DW _OR_DX_DX
	JE M30_67
	DW _MOV_AL_CL
	MOV AH, 0
	MOV CL, 5
	SHL AX, CL
	SHL BL, 1
	DW _ADD_AL_DL
	DW _ADD_AH_BL
	MOV [AttrDat], AX
	JMP M30_70
M30_67:	JMP M30_75
M30_70:	MOV SI, MD.DosBuf+LenCmd+10+100+3
	CALL FndLet
	CMP AL, 0
	JE M30_76
	DW _XOR_CX_CX
	DW _XOR_BX_BX
	CALL TxtNum
	JC M30_67
	DW _MOV_DX_AX
	CALL FndLet
	CMP AL, [MD.Country+CNTRY.TimeSep]
	JNE M30_71
	INC SI
	CALL FndLet
	CALL TxtNum
	JC M30_67
	CMP AX, STRICT WORD 60
	JAE M30_67
	DW _MOV_CH_AL
	CALL FndLet
	CMP AL, [MD.Country+CNTRY.TimeSep]
	JNE M30_71
	INC SI
	CALL FndLet
	CALL TxtNum
	JC M30_67
	CMP AX, STRICT WORD 60
	JAE M30_67
	DW _MOV_BL_AL
	CALL FndLet
M30_71:	CMP AL, 0
	JE M30_72
	CALL UpCase
	DW _MOV_BH_AL
	INC SI
	CALL FndLet
	CMP AL, 0
	JNE M30_67
M30_72:	MOV AX, 24
	CMP BH, 0
	JE M30_73
	MOV AL, 12
	CMP BH, 'A'
	JE M30_73
	MOV CL, 12
	CMP BH, 'P'
	JNE M30_75
M30_73:	DW _CMP_DX_AX
	JA M30_75
	JNE M30_74
	DW _XOR_DX_DX
M30_74:	DW _MOV_AH_DL
	DW _ADD_AH_CL
	MOV CL, 3
	SHL AH, CL
	DW _MOV_AL_BL
	SHR AL, 1
	DW _MOV_BH_CH
	MOV BL, 0
	SHR BX, CL
	DW _ADD_AX_BX
	MOV [AttrTim], AX
	MOV AL, 0
	CLC
	JMP M30_76
M30_75:	MOV BP, NoDat_B
	CALL Dialog
	STC
M30_76:	RET
;M30_60 ENDP

;GLOBAL M30_80
M30_80:  ; PROC NEAR
	DW _TEST_AL_CL
	MOV AL, 0
	JZ M30_81
	MOV AL, 1
M30_81:	STOSB
	RET
;M30_80 ENDP

;GLOBAL M30_82
M30_82:  ; PROC NEAR
	PUSH BX
	MOV AL, 0
	MOV BL, 1
	CALL M30_83
	MOV BL, 20h
	CALL M30_83
	MOV BL, 2
	CALL M30_83
	MOV BL, 4
	CALL M30_83
	POP BX
	RET
;M30_82 ENDP

;GLOBAL M30_83
M30_83:  ; PROC NEAR
	CMP BYTE [SI], 0
	JE M30_84
	DW _OR_AL_BL
M30_84:	INC SI
	RET
;M30_83 ENDP

F54_00:	CALL HidCur  ; Change label
	PUSH ES
	POP DS
	MOV DX, MD.DosPth
	CALL ChgDisk
	MOV SI, MD.Volume
	CALL GetVol
	JNC F54_02
	MOV DI, MD.TmpBuf
	MOV AL, '\'
	STOSB
	MOV CX, 12
	PUSH SI
	PUSH CX
	REP MOVSB
	POP CX
	POP SI
	MOV DI, MD.TmpBuf+20
	MOV BYTE [DI], 0
	CMP BYTE [MD.Volume], 0
	JE F54_01
	MOV AX, ' "'
	STOSW
	CALL MvzLine
	MOV AX, '"'
	STOSW
F54_01:	MOV BP, Label_B
	CALL Dialog
	JNE F54_02
	MOV DX, MD.TmpBuf+20
	MOV SI, MD.Volume
	DW _MOV_DI_DX
	MOV AL, 0FFh
	STOSB
	ADD DI, 5
	MOV AX, 8
	STOSW
	MOV CX, 12
	PUSH CX
	CALL MvzLine
	POP CX
	MOV AL, ' '
	REP STOSB
	CMP BYTE [MD.TmpBuf+1], 0
	JNE F54_03
	CMP BYTE [MD.Volume], 0
	JE F54_02
	MOV BP, DelVo_B
	CALL Dialog
	JNE F54_02
	MOV AH, 13h
	CALL Intr21
	JMP FncExt
F54_02:	JMP Func04
F54_03:	MOV AH, 13h
	CALL Intr21
	MOV AX, [MD.TmpBuf+11]
	MOV [MD.TmpBuf+12], AX
	MOV AX, [MD.TmpBuf+9]
	MOV [MD.TmpBuf+10], AX
	MOV BYTE [MD.TmpBuf+9], '.'
	MOV DX, MD.TmpBuf
	MOV CX, 8
	MOV AH, 3Ch
	CALL Intr21
	JC F54_04
	DW _MOV_BX_AX
	MOV AH, 3Eh
	CALL Intr21
	JMP FncExt
F54_04:	MOV AX, [MD.TmpBuf+10]
	MOV [MD.TmpBuf+9], AX
	MOV AX, [MD.TmpBuf+12]
	MOV [MD.TmpBuf+11], AX
	MOV BP, ErVol_B
	CALL Dialog
	JMP FncExt

FncMas:	PUSH ES  ; Masked files
	POP DS
	MOV AL, 0
	MOV [MD.ZoomOne], AL
	MOV [MD.TmpBuf+91], AL
FncMs1:	CALL SetDTA
	MOV DX, MD.TmpBuf
	MOV CX, 37h
	MOV AH, 4Eh
	JMP FncMs4
FncMs2:	TEST BYTE [MD.DTA+DTAs.FilAttr], 16h
	JNZ FncMs3
	DW _XOR_BX_BX
	MOV SI, MD.TmpBuf
	CALL CutPath
	DW _MOV_DI_SI
	MOV SI, MD.DTA+DTAs.FilName
	MOV CX, 13
	REP MOVSB
	CALL TstBrk
	JC FncMs8
	MOV AL, 0
	CALL [MD.FncAddr]
	PUSH ES
	POP DS
	OR [MD.TmpBuf+91], AL
	CMP AH, 0
	JNZ FncMs8
FncMs3:	MOV AH, 4Fh
FncMs4:	CALL ChgDisk
	JC FncMs8
	CALL Intr21
	JNC FncMs2
	CMP AX, STRICT WORD 12h
	JE FncMs5
	CMP AX, STRICT WORD 3
	JA FncMs8
FncMs5:	DW _OR_BX_BX
	JZ FncMs8
	DW _MOV_DX_BX
	MOV BX, 's'
	MOV SI, MD.TmpBuf
FncMs6:	LODSB
	CMP AL, '*'
	JE FncMs7
	CMP AL, '?'
	JE FncMs7
	CMP AL, 0
	JNE FncMs6
	MOV BL, 0
FncMs7:	MOV [MD.TmpBuf+100], BX
	MOV BP, NoFnc_B
	CALL Dialog
FncMs8:	JMP FncExt

;DelTree	PROC	NEAR
;GLOBAL DelTree
DelTree:
	CMP BYTE [ES:MD.ChgTree], 0
	JZ DelTr5
DelTr0:	PUSH DS
	MOV AX, [ES:SI]
	CMP AH, ':'
	JE DelTr1
	MOV AL, [ES:MD.DosPth]
DelTr1:	MOV DX, MD.TmpErr
	DW _MOV_DI_DX
	MOV AH, ':'
	STOSW
	MOV SI, Tree_F
	MOV CX, 13+1
	PUSH CS
	POP DS
	REP MOVSB
	PUSH ES
	POP DS
	MOV BYTE [MD.BlocEr], 1
	MOV AL, 11h
	CALL OpenFil
	JNC DelTr3
	CMP AX, STRICT WORD 5
	STC
	JNE DelTr4
DelTr2:	CALL Beep
	CLC
	JMP DelTr4
DelTr3:	DW _MOV_BX_AX
	DW _MOV_SI_DX
	MOV BYTE [SI], 0
	MOV CX, 1
	MOV AH, 40h
	CALL Intr21
	PUSHF
	PUSH AX
	MOV AH, 3Eh
	CALL Intr21
	POP AX
	POP BX
	JC DelTr4
	PUSH BX
	POPF
	JC DelTr4
	DW _CMP_AX_CX
	JNE DelTr2
DelTr4:	MOV BYTE [MD.BlocEr], 0
	POP DS
DelTr5:	RET
;DelTree	ENDP

F36_00:	MOV CL, 1  ; Rename / Move
	JMP F35_01
F36_01:	CALL F35_40
	MOV BP, MkErr_B
	CALL Dialog
F36_02:	JMP Func04
F36_03:	PUSH ES
	POP DS
	MOV SI, [MD.TreAdr]
	MOV DI, CpDest
	MOV CX, 13
	PUSH DI
	REP MOVSB
	POP SI
	MOV BP, Renam_B
	CALL Dialog
	CMP AL, 0
	JNE F36_02
	DW _MOV_BX_SI
	CALL CutPath
	DW _CMP_SI_BX
	JNE F36_01
	MOV SI, MD.CrnPath
	MOV DI, CpInpt
	MOV CX, LenPath
	PUSH DI
	REP MOVSB
	POP SI
	PUSH SI
	CALL CutPath
	DW _MOV_DI_SI
	DW _MOV_SI_BX
	MOV CX, 13
	REP MOVSB
	POP SI
	DW _MOV_DI_SI
	MOV CX, LenStr+1
	PUSH CX
	REPNE SCASB
	POP CX
	JNE F36_01
	MOV DI, MD.ToFile
	REP MOVSB
	MOV BYTE [CopyMov], 3
F36_04:	MOV SI, MD.CrnPath
	MOV DI, CpSrc
	PUSH DI
	MOV CX, LenPath
	REP MOVSB
	POP SI
	CALL CutPath
	MOV [CpBgNam], SI
	CALL F35_70
	MOV [MD.ZoomOne], AL
	MOV AL, 10h
	CALL C00_00
	CMP AL, 0
	JZ F36_06
	PUSH ES
	POP DS
	CMP BYTE [CopyMov], 0
	JE F36_06
	MOV DI, MD.CrnPath
	DW _MOV_SI_DI
	MOV CX, LenPath+13
	MOV AL, 0
	REPNE SCASB
	DEC DI
	DW _MOV_CX_DI
	DW _SUB_CX_SI
	MOV DI, MD.DosPth
	REPE CMPSB
	JNE F36_05
	PUSH DI
	MOV SI, MD.ToFile
	MOV DI, CpInpt
	MOV CX, LenStr+1
	CALL MvzLine
	POP SI
	MOV CX, LenPath
	REP MOVSB
	MOV DX, CpInpt+2
	MOV AH, 3Bh
	CALL Intr21
F36_05:	MOV SI, MD.ToFile
	MOV DI, MD.CrnPath
	MOV CX, LenStr+1
	REP MOVSB
F36_06:	JMP FncExt

F35_00:	MOV CL, 0  ; Copy
F35_01:	MOV [ES:CopyMov], CL
	MOV AL, 20
	DW _ADD_AL_CL
	MOV [ES:MD.HlpPage], AL
	CMP BYTE [WCBdef.Visible], 0
	JZ F35_03
	CMP BYTE [WCBdef.WinTyp], 1
	JNE F35_02
	MOV AX, [ES:MD.TreAdr]
	CMP AX, STRICT WORD MD.TreeBuf+DIRTREE_TreList
	JBE F35_11
	DW _OR_CL_CL
	JE F35_04
	JMP F36_03
F35_02:	JA F35_03
	DW _XOR_BX_BX
	DW _XOR_DX_DX
	CMP [ES:MD.OneFile], BL
	JNZ F35_12
	CALL TotSel
	DW _MOV_AX_BX
	DW _OR_AX_DX
	JNE F35_04
F35_12:	MOV SI, [WCBdef.CurAdr]
	CMP SI, [WCBdef.EndBuf]
	JAE F35_11
	CMP BYTE [SI+FILENT.NameF], '.'
	JNE F35_04
F35_11:	JMP Func04
F35_03:	JMP F45_01
F35_04:	CALL F35_50
	CMP BYTE [WCBdef.WinTyp], 1
	JE F35_05
	MOV SI, [WCBdef.CurAdr]
	MOV CX, 13
	DW _MOV_AX_BX
	DW _OR_AX_DX
	JE F35_06
	CALL FilDir
	DEC DI
	JMP F35_07
F35_05:	PUSH DI
	PUSH ES
	POP DS
	MOV SI, MD.CrnPath
	MOV DI, MD.TmpErr
	PUSH DI
	MOV CX, LenPath+13
	REP MOVSB
	POP SI
	MOV AX, LenStr-10
	CALL ShrtLin
	POP DI
	MOV CX, LenStr
F35_06:	MOV AL, '"'
	STOSB
	CALL MvzLine
	MOV AL, '"'
	STOSB
F35_07:	PUSH CS
	POP DS
	MOV SI, CopTo_S+2
	MOV CX, 3
	REP MOVSB
	MOV CX, CpVar2+LenStr
	DW _SUB_CX_DI
	JBE F35_08
	MOV AL, ' '
	REP STOSB
F35_08:	MOV AL, 0
	STOSB
	PUSH ES
	POP DS
	CALL F35_40
	MOV BP, Copy1_B
	CALL Dialog
	CMP AL, 0
	JNE F35_09
	MOV SI, CpInpt
	MOV DI, MD.ToFile
	MOV CX, LenStr+1
	REP MOVSB
	CMP BYTE [MD.ToFile], 0
	JE F35_09
	PUSH DS
	MOV DS, [MD.WCBcrn]
	CMP BYTE [WCBdef.WinTyp], 1
	POP DS
	JE F35_10
	CALL F35_70
	MOV WORD [CpBgNam], CpSrc
	JMP FncSel
F35_09:	JMP Init50
F35_10:	JMP F36_04

F46_00:	MOV CL, 1  ; Rename / Move...
	JMP F45_01
F45_00:	MOV CL, 0  ; Copy...
F45_01:	MOV [ES:CopyMov], CL
	MOV AL, 20
	DW _ADD_AL_CL
	MOV [ES:MD.HlpPage], AL
	CALL F35_50
	PUSH CS
	POP DS
	MOV SI, CopFi_S+12
	MOV CX, 4
	REP MOVSB
	PUSH ES
	POP DS
	CALL F35_40
	MOV BP, Copy2_B
	CALL Dialog
	CMP AL, 0
	JNE F45_02
	MOV SI, CpInpt
	MOV DI, MD.ToFile
	MOV CX, LenStr+1
	PUSH CX
	REP MOVSB
	POP CX
	MOV SI, MD.ViewFil
	MOV DI, CpSrc
	REP MOVSB
	MOV AL, 0
	CMP AL, [MD.ViewFil]
	JE F45_02
	CMP AL, [MD.ToFile]
	JE F45_02
	MOV SI, CpSrc
	CALL CutPath
	MOV [CpBgNam], SI
	CALL F35_70
	CALL F35_40
	DW _MOV_BX_DX
	JMP FncMas
F45_02:	JMP Init50

F55_00:	MOV CL, 0  ; ^F5 - copy file
	JMP F56_01

F56_00:	MOV CL, 1  ; ^F6 - rename or move file
F56_01:	MOV BYTE [ES:MD.OneFile], 1
	JMP F35_01

;GLOBAL F35_40
F35_40:  ; PROC NEAR
	MOV DX, Copy0_S
	CMP BYTE [ES:CopyMov], 0
	JE F35_41
	MOV DX, Move0_S
	CMP BYTE [ES:CopyMov], 2
	JBE F35_41
	MOV DX, Ren0_S
F35_41:	RET
;F35_40 ENDP

;GLOBAL F35_50
F35_50:  ; PROC NEAR  ; Set default target path
	CMP BYTE [ES:MD.OneFile], 0
	JZ F35_51
	CMP BYTE [ES:CopyMov], 0
	JNZ F35_54
F35_51:	PUSH DS
	CALL InvWCB
	CMP BYTE [WCBdef.Visible], 0
	JZ F35_53
	CMP BYTE [WCBdef.WinTyp], 1
	JAE F35_52
	MOV SI, WCBdef.WinPath
	JMP F35_57
F35_52:	JA F35_53
	MOV SI, MD.CrnPath
	JMP F35_56
F35_53:	CMP BYTE [ES:CopyMov], 0
	JE F35_55
	DW _MOV_AX_BX
	DW _OR_AX_DX
	JNE F35_55
	POP DS
F35_54:	PUSH DS
	MOV SI, [WCBdef.CurAdr]
	CMP SI, [WCBdef.EndBuf]
	JAE F35_55
	CMP BYTE [SI+FILENT.NameF], '.'
	JNE F35_57
F35_55:	MOV SI, MD.ToFile
F35_56:	PUSH ES
	POP DS
F35_57:	MOV DI, CpInpt
	MOV CX, LenStr
	REP MOVSB
	MOV AL, 0
	STOSB
	MOV SI, Copy0_S
	MOV BP, Copy0_S+1
	MOV AX, 5
	CMP BYTE [ES:CopyMov], 0
	JE F35_58
	MOV SI, Ren0_S
	MOV BP, RnMv_S
	MOV AL, 15
F35_58:	PUSH CS
	POP DS
	MOV DI, CpVar1
	MOV CX, CpVar2-CpVar1
	REP MOVSB
	PUSH AX
	PUSH DI
	MOV CX, LenStr
	MOV AL, ' '
	REP STOSB
	MOV AL, 0
	STOSB
	POP DI
	POP CX
	DW _MOV_SI_BP
	REP MOVSB
	POP DS
	RET
;F35_50 ENDP

;F35_60	PROC	NEAR			; Tree
;GLOBAL F35_60
F35_60:
	ADD BH, 2
F35_61:	ADD BX, 305h
	CMP AL, 1
	JE F35_62
	CLC
	RET
F35_62:	MOV SI, MD.DosPth
	MOV DI, MD.MenuBuf+350
	MOV CX, LenPath
	PUSH SI
	PUSH DI
	PUSH CX
	REP MOVSB
	DW _OR_AH_AH
	JZ F35_63
	MOV SI, MD.DosBuf+LenCmd+10+3
	MOV DI, MD.TmpBuf
	PUSH DI
	MOV CX, LenStr+1
	REP MOVSB
	POP SI
	CALL NormStr
	MOV AX, [SI]
	CMP AH, ':'
	JNE F35_63
	CALL UpCase
	SUB AL, 'A'
	DW _MOV_DL_AL
	MOV AH, 0Eh
	INT 21h
	CALL SetPth
	JC F35_64
F35_63:	MOV AL, 28
	CALL ChTree
F35_64:	POP CX
	POP SI
	POP DI
	PUSHF
	MOV DL, [SI]
	REP MOVSB
	SUB DL, 'A'
	MOV AH, 0Eh
	INT 21h
	POPF
	JC F35_66
	MOV SI, MD.TmpBuf
	MOV DI, MD.DosBuf+LenCmd+10+3
	MOV CX, LenPath+13
	PUSH CX
	PUSH DI
	CALL MvzLine
	POP SI
	MOV AX, '\'
	CMP AL, [DI-1]
	JE F35_65
	STOSW
F35_65:	POP CX
	DW _MOV_DI_SI
	MOV AL, 0
	MOV [SI+LenStr], AL
	REPNE SCASB
	DEC DI
	DW _SUB_DI_SI
	MOV [MD.DosBuf+LenCmd+10], DI
	MOV BYTE [MD.DosBuf+LenCmd+10+2], 1
	MOV CX, LenStr
	MOV BP, Copy1_B
	MOV BP, [CS:BP]
	MOV AH, [CS:BP+1]
	CALL InSt10
	STC
F35_66:	RET
;F35_60	ENDP

;GLOBAL F35_70
F35_70:  ; PROC NEAR  ; Init variables
	MOV AL, 0
	MOV [CpCase], AL
	MOV [CpDev2], AL
	MOV [CpTree1], AL
	MOV [CpTree2], AL
	MOV [CpAll], AL
	MOV [FncChg], AL
	MOV WORD [MD.FncAddr], C00_00
	RET
;F35_70 ENDP

;GLOBAL C00_00
C00_00:  ; PROC NEAR  ; Copy file
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH ES
	POP DS
	MOV BYTE [MD.SftErr], 1
	DW _MOV_BP_AX  ; Set target name
	MOV DX, CpDest
	MOV SI, MD.ToFile
	DW _MOV_DI_DX
	MOV CX, LenPath+13
	REP MOVSB
	DW _MOV_SI_DX
	CALL PathLin
	CMP BYTE [CopyMov], 3
	JE C00_01
	DW _MOV_SI_DX
	CALL CutPath
	DW _MOV_BX_SI
	CMP BYTE [SI], 0
	JE C00_05
	CMP WORD [SI], '..'
	JNE C00_03
	PUSH SI
	INC SI
	INC SI
	CALL FndLet
	POP SI
	CMP AL, 0
	JNE C00_03
	ADD SI, 3
	JMP C00_04
C00_01:	JMP C00_20
C00_02:	JMP C00_13
C00_03:	LODSB
	CMP AL, '?'
	JE C00_02
	CMP AL, '*'
	JE C00_02
	CMP AL, 0
	JNE C00_03
	DW _MOV_DI_DX
	MOV CX, LenPath+13
	REPNE SCASB
	PUSH DI
	DW _MOV_CX_DI
	DW _SUB_CX_DX
	DW _MOV_DI_DX
	MOV DS, [ES:MD.WCBsec]
	MOV SI, WCBdef.WinPath
	REPE CMPSB
	POP SI
	PUSH ES
	POP DS
	JNE C00_06
C00_04:	MOV BYTE [SI-1], '\'
C00_05:	DW _MOV_DI_SI
	MOV SI, [CpBgNam]
	LEA AX, [SI-CpSrc]
	JMP C00_18
C00_06:	MOV AL, [CpCase]
	CMP AL, 0
	JNE C00_12
	CALL ChgDisk
	JC C00_09
	MOV AL, 40h
	CALL OpenFil
	JNC C00_07
	CMP AX, STRICT WORD 53h
	JNE C00_08
	JMP C00_09
C00_07:	PUSH DX
	PUSH BX
	DW _MOV_BX_AX
	MOV AX, 4400h
	CALL Intr21
	MOV AH, 3Eh
	CALL Intr21
	DW _MOV_AX_DX
	POP BX
	POP DX
	TEST AL, 80h
	JZ C00_08
	MOV BYTE [CpDev2], 1
	JMP C00_11
C00_08:	MOV AX, 4300h
	CALL Intr21
	JNC C00_10
	CMP AX, STRICT WORD 53h
	MOV AL, 1
	JNE C00_12
C00_09:	MOV AX, 100h
	JMP C00_81
C00_10:	MOV AL, 2
	TEST CL, 10h
	JNZ C00_12
C00_11:	MOV AL, 3
C00_12:	MOV [CpCase], AL
	CMP AL, 2
	JE C00_04
	JA C00_20
C00_13:	DW _MOV_SI_BX
	MOV DI, MD.TmpErr
	PUSH DI
	CALL Convert
	MOV SI, [CpBgNam]
	PUSH SI
C00_14:	LODSB
	CMP AL, 0
	JE C00_15
	CMP AL, '\'
	JNE C00_14
C00_15:	DEC SI
	DW _MOV_DX_SI
	MOV BYTE [SI], 0
	POP SI
	MOV DI, MD.TmpErr+20
	CALL Convert
	DW _MOV_SI_DX
	MOV [SI], AL
	POP SI
	PUSH SI
	MOV CX, 11
C00_16:	CMP BYTE [SI], '?'
	JNE C00_17
	MOV AL, [DI]
	MOV [SI], AL
C00_17:	INC SI
	INC DI
	LOOP C00_16
	POP SI
	DW _MOV_DI_BX
	CALL UnConv
	DW _MOV_SI_DX
	LEA AX, [DI-CpDest]
C00_18:	MOV CX, LenPath+13
	DW _SUB_CX_AX
	JBE C00_19
	REP MOVSB
C00_19:	MOV AL, 0
	STOSB
C00_20:	MOV SI, CpDest
	DW _MOV_DI_SI
	MOV CX, LenPath+12
	MOV AL, 0
	REPNE SCASB
	CMP BYTE [CpDev2], 0  ; Rename or move ?
	JNZ C00_21
	CMP BYTE [CopyMov], 2
	JE C00_21
	JA C00_23
	CMP BYTE [CopyMov], 0
	JE C00_21
	MOV AX, [CpSrc]
	CALL C00_30
	JE C00_21
	DW _MOV_BL_AL
	MOV AX, [CpDest]
	CALL C00_30
	JE C00_21
	DW _CMP_AL_BL
	JE C00_23
C00_21:	TEST BP, 10h
	JNZ C00_22
	JMP C20_00  ; Copy/Move file
C00_22:	MOV AL, 1
	JMP C30_00  ; Copy/Move dir
C00_23:	TEST BP, 10h
	JZ C10_00  ; Rename file
	MOV AL, 0
	JMP C30_00  ; Rename dir

;GLOBAL C00_30
C00_30:  ; PROC NEAR
	CMP AX, STRICT WORD '\\'
	JE C00_32
	CALL UpCase
	CMP AH, ':'
	JE C00_31
	MOV AL, [MD.DosPth]
C00_31:	DW _OR_AL_AL
C00_32:	RET
;C00_30 ENDP

C10_00:	MOV BYTE [CopyMov], 3  ; Renaming file
	MOV BX, 528h
	MOV BP, RenFi_P
	CALL OncZoom
	PUSH SI
	PUSH DX
	PUSH BX
	MOV AL, 0
	JCXZ C10_01
	CALL C40_00
	JNE C10_02
	JMP C10_14
C10_01:	JMP C10_07
C10_02:	MOV DX, CpDest
	CALL ChgDisk
	JC C10_04
	DW _MOV_DI_DX
	MOV DX, CpSrc
	MOV AH, 56h
	CALL Intr21
	JNC C10_06
	CMP AX, STRICT WORD 53h
	JE C10_04
	CMP AX, STRICT WORD 5
	JNE C10_08
	DW _MOV_DX_DI
	MOV AX, 4300h
	CALL Intr21
	JC C10_07
	MOV AL, 0
	TEST CL, 10h
	JNZ C10_07
	CMP BYTE [CpAll], 0
	JNZ C10_03
	PUSH DX
	MOV DX, Ren0_S
	MOV BP, OvrCo_B
	CALL Dialog
	POP DX
	CMP AL, 2
	JE C00_90
	JA C10_11
	MOV [CpAll], AL
C10_03:	MOV AH, 41h
	CALL Intr21
	JNC C10_05
	CMP AX, STRICT WORD 5
	JNE C10_09
	CALL C50_00
	CALL F35_40
	MOV BP, Prot_B
	CALL Dialog
	CMP AL, 0
	JNE C10_11
	DW _MOV_DX_DI
	MOV CX, 20h
	MOV AX, 4301h
	CALL Intr21
	JC C10_09
	MOV BYTE [FncChg], 1
	MOV AH, 41h
	CALL Intr21
	JC C10_09
	JMP C10_05
C10_04:	MOV AX, 100h
	JMP C00_80
C10_05:	MOV DX, CpSrc
	MOV AH, 56h
	CALL Intr21
C10_06:	JNC C10_12
C10_07:	MOV BP, RenEr_B
	JMP C10_10
C10_08:	MOV BYTE [CopyMov], 2
C00_90:	POP BX
	POP DX
	POP SI
	CALL ResWin
	CALL Window
	JMP C20_00
C10_09:	MOV DX, Ren0_S
	MOV BP, DelEr_B
C10_10:	CMP AX, STRICT WORD 53h
	JE C10_04
	CALL Dialog
	JNZ C10_04
C10_11:	DW _XOR_AX_AX
	JMP C00_80
C10_12:	DW _MOV_SI_DX
	CALL LetLin
	DW _MOV_SI_DI
	CALL LetLin
C10_13:	DW _MOV_SI_DX
	CALL CutPath
	DW _CMP_SI_DX
	JNE C10_14
	DW _MOV_SI_DI
	CALL CutPath
	DW _CMP_SI_DI
	JNE C10_14
	PUSH DI
	MOV DS, [MD.WCBcrn]
	DW _MOV_DI_DX
	CALL FnFile
	POP DI
	DW _XCHG_SI_DI
	PUSH DS
	PUSH ES
	POP DS
	POP ES
	JNC C10_14
	MOV CX, 12
	REP MOVSB
	MOV AL, 0
	STOSB
C10_14:	PUSH DS
	POP ES
	MOV AX, 1
	JMP C00_80

C20_00:	CALL C50_00  ; Copy / Move file
	MOV BP, CopFi_P
	CMP BYTE [CopyMov], 0
	JE C20_01
	MOV BP, MovFi_P
C20_01:	MOV BX, 428h
	CALL OncZoom
	PUSH SI
	PUSH DX
	PUSH BX
	ADD BX, 605h
	SUB DL, 12
	MOV DH, 1
	MOV [CpCntBg], BX
	MOV [CpCntSz], DL
	PUSH CX
	CALL BasAdr
	DW _MOV_CL_DL
	MOV CH, 0
	MOV AH, [CS:BP]
	CALL Color
	MOV AL, '°'
	REP STOSW
	CALL Window
	POP CX
	JCXZ C20_04
	CALL C40_00
	MOV BP, Itslf_B
	JE C20_05
	MOV DX, CpSrc
	CALL ChgDisk
	JC C20_06
	MOV AL, 40h
	CALL OpenFil
	JNC C20_07
C20_02:	CMP AX, STRICT WORD 53h
	JE C20_06
C20_03:	MOV SI, CpSrc
	CALL LetLin
	MOV DI, CpDest
	MOV CX, LenPath+13
	REP MOVSB
C20_04:	MOV BP, OpnEr_B
C20_05:	CALL F35_40
	CALL Dialog
	JNZ C20_06
	DW _XOR_AX_AX
	JMP C00_80
C20_06:	MOV AX, 100h
	JMP C00_80
C20_07:	MOV [CpHndl1], AX
	DW _MOV_BX_AX
	PUSH DX
	MOV AX, 4400h
	CALL Intr21
	DW _MOV_AX_DX
	POP DX
	AND AL, 81h
	CMP AL, 81h
	JE C20_03
	AND AL, 80h
	MOV [CpDev1], AL
	MOV AX, 0FFFFh
	MOV [CpSizeLo], AX
	MOV [CpSizeHi], AX
	MOV WORD [CpAttr], 20h
	JNZ C20_08
	MOV AX, 4300h
	CALL Intr21
	JC C20_02
	AND CX, 27h
	OR CL, 20h
	MOV [CpAttr], CX
	DW _XOR_CX_CX
	DW _XOR_DX_DX
	MOV AX, 4202h
	CALL Intr21
	MOV [CpSizeLo], AX
	MOV [CpSizeHi], DX
	DW _XOR_CX_CX
	DW _XOR_DX_DX
	MOV AX, 4200h
	CALL Intr21
C20_08:	MOV AX, 5700h
	CALL Intr21
	MOV [CpDate], DX
	MOV [CpTime], CX
	DW _XOR_AX_AX
	MOV [CpReadLo], AX
	MOV [CpReadHi], AX
	MOV [CpWriteLo], AX
	MOV [CpWriteHi], AX
	MOV [CpHndl2], AX
	MOV [CpCont], AX
	MOV [SplitFl], AL
C20_10:	MOV AX, ES  ; Reading
	ADD AX, [ES:MD.FreMem2]
	SUB AX, [ES:MD.ViewSeg]
	AND AL, 0E0h
	DW _MOV_SI_AX
	DW _MOV_AL_AH
	MOV AH, 0
	MOV CL, 4
	SHL SI, CL
	SHR AX, CL
	DW _MOV_DI_AX
	MOV DS, [ES:MD.ViewSeg]
	MOV BX, [ES:CpHndl1]
	MOV DX, CpSrc
	CALL ChgDisk
	JC C20_14
C20_11:	CALL TstBrk
	JC C20_14
	DW _XOR_DX_DX
	MOV CX, 8000h
	DW _OR_DI_DI
	JNE C20_12
	DW _CMP_CX_SI
	JBE C20_12
	DW _MOV_CX_SI
C20_12:	DW _XOR_AX_AX
	JCXZ C20_13
	MOV AH, 3Fh
	CALL Intr21
	JC C20_14
C20_13:	ADD [ES:CpReadLo], AX
	ADC WORD [ES:CpReadHi], 0
	CALL PerCent
	DW _OR_AX_AX
	JE C20_15
	DW _ADD_DX_AX
	DW _SUB_CX_AX
	JNE C20_12
	MOV DX, DS
	ADD DX, 800h
	MOV DS, DX
	DW _SUB_SI_AX
	SBB DI, 0
	DW _MOV_AX_SI
	DW _OR_AX_DI
	JNE C20_11
	JMP C20_20
C20_14:	JMP C20_45
C20_15:	MOV AH, 3Eh
	CALL Intr21
	MOV WORD [ES:CpHndl1], 0
	CMP BYTE [ES:CpDev1], 0
	JZ C20_20
	MOV AX, [ES:CpReadLo]
	MOV BX, [ES:CpReadHi]
	MOV [ES:CpSizeLo], AX
	MOV [ES:CpSizeHi], BX
	DW _OR_AX_BX
	JE C20_14
	CALL PerCent
C20_20:	MOV DX, CpDest  ; Open target file
	CALL ChgDisk
	JC C20_24
	CMP WORD [ES:CpHndl2], 0
	JNE C20_23
C20_21:	PUSH ES
	POP DS
	CALL C50_00
	MOV DX, CpDest
	CMP BYTE [ES:CpDev2], 0
	JZ C20_25
	MOV AL, 11h
	CALL OpenFil
	JNC C20_22
	JMP C20_30
C20_22:	MOV [ES:CpHndl2], AX
	MOV BYTE [ES:FncChg], 1
	PUSH DX
	DW _MOV_BX_AX
	MOV AX, 4400h
	CALL Intr21
	AND DL, 82h
	CMP DL, 82h
	POP DX
	MOV AL, 0
	JZ C20_30
C20_23:	JMP C20_40
C20_24:	JMP C20_45
C20_25:	MOV AX, 4300h
	CALL Intr21
	JNC C20_26
	CMP AX, STRICT WORD 3
	JA C20_30
	JMP C20_34
C20_26:	CMP BYTE [ES:CpAll], 0
	JNZ C20_27
	CMP BYTE [ES:CopyMov], 3
	JE C20_36
	PUSH DX
	CALL F35_40
	MOV BP, OvrCo_B
	CALL Dialog
	POP DX
	CMP AL, 1
	JA C20_35
	OR [ES:CpAll], AL
C20_27:	TEST CL, 1
	JZ C20_28
	PUSH DX
	CALL F35_40
	MOV BP, Prot_B
	CALL Dialog
	POP DX
	CMP AL, 0
	JNE C20_32
	MOV CX, 20h
	MOV AX, 4301h
	CALL Intr21
	JC C20_29
	MOV BYTE [ES:FncChg], 1
C20_28:	MOV AH, 41h
	CALL Intr21
	JNC C20_33
C20_29:	MOV BP, DelEr_B
	JMP C20_31
C20_30:	MOV BP, OpnEr_B
C20_31:	CMP AX, STRICT WORD 53h
	JE C20_24
	CALL F35_40
	CALL Dialog
	JNZ C20_24
C20_32:	DW _XOR_AX_AX
	PUSH AX
	JMP C20_46
C20_33:	MOV BYTE [ES:FncChg], 1
C20_34:	MOV CX, 20h
	MOV AH, 3Ch
	CALL Intr21
	JC C20_30
	JMP C20_22
C20_35:	CMP AL, 2
	JNE C20_32
C20_36:	MOV AX, 4300h
	CALL Intr21
	JC C20_30
	AND CX, 27h
	OR CL, 20h
	MOV [ES:CpAttr], CX
	MOV AL, 12h
	CALL OpenFil
	JNC C20_37
	CMP AX, STRICT WORD 5
	JNE C20_30
	PUSH DX
	CALL F35_40
	MOV BP, Prot_B
	CALL Dialog
	POP DX
	CMP AL, 0
	JNE C20_32
	MOV CX, 20h
	MOV AX, 4301h
	CALL Intr21
	JC C20_30
	MOV BYTE [ES:FncChg], 1
	MOV AL, 12h
	CALL OpenFil
	JC C20_30
C20_37:	MOV BYTE [ES:FncChg], 1
	MOV [ES:CpHndl2], AX
	DW _MOV_BX_AX
	MOV AX, 5700h
	CALL Intr21
	MOV [ES:CpDate], DX
	MOV [ES:CpTime], CX
	DW _XOR_CX_CX
	DW _XOR_DX_DX
	MOV AX, 4202h
	CALL Intr21
	DW _MOV_SI_AX
	DW _MOV_DI_DX
	DW _OR_AX_DX
	JE C20_40
	SUB SI, 1
	SBB DI, 0
	DW _MOV_DX_SI
	DW _MOV_CX_DI
	MOV AX, 4200h
	CALL Intr21
	MOV DX, MD.TmpErr
	MOV CX, 1
	MOV AH, 3Fh
	CALL Intr21
	JNC C20_38
	JMP C20_45
C20_38:	CMP BYTE [ES:MD.TmpErr], 1Ah
	JNE C20_40
	DW _MOV_DX_SI
	DW _MOV_CX_DI
	MOV AX, 4200h
	CALL Intr21
C20_40:	MOV SI, [ES:CpReadLo]  ; Writing
	MOV DI, [ES:CpReadHi]
	SUB SI, [ES:CpWriteLo]
	SBB DI, [ES:CpWriteHi]
	MOV DS, [ES:MD.ViewSeg]
	MOV BX, [ES:CpHndl2]
	DW _XOR_AX_AX
	XCHG AX, [ES:CpCont]
	DW _OR_AX_AX
	JE C20_41
	MOV DS, AX
C20_41:	CALL TstBrk
	JC C20_45
	MOV CX, 8000h
	DW _OR_DI_DI
	JNE C20_42
	DW _CMP_CX_SI
	JBE C20_42
	DW _MOV_CX_SI
C20_42:	DW _XOR_AX_AX
	JCXZ C20_43
	DW _XOR_DX_DX
	MOV AH, 40h
	CALL Intr21
	JC C20_45
	DW _OR_AX_AX
	JE C20_50
C20_43:	ADD [ES:CpWriteLo], AX
	ADC WORD [ES:CpWriteHi], 0
	CALL PerCent
	DW _SUB_SI_AX
	SBB DI, 0
	MOV CL, 4
	SHR AX, CL
	MOV DX, DS
	DW _ADD_DX_AX
	MOV DS, DX
	DW _MOV_AX_SI
	DW _OR_AX_DI
	JNE C20_41
	CMP WORD [ES:CpHndl1], 0
	JE C20_44
	JMP C20_10
C20_44:	JMP C20_70
C20_45:	MOV AX, 100h  ; Terminate
	PUSH AX
	MOV BYTE [ES:MD.BlocEr], 1
	MOV BX, [ES:CpHndl2]
	DW _OR_BX_BX
	JE C20_46
	MOV DX, CpDest
	CALL ChgDisk
	JC C20_46
	MOV AH, 3Eh
	CALL Intr21
	PUSH DS
	PUSH ES
	POP DS
	MOV AH, 41h
	CALL Intr21
	POP DS
C20_46:	MOV BX, [ES:CpHndl1]
	DW _OR_BX_BX
	JE C20_47
	MOV AH, 3Eh
	CALL Intr21
C20_47:	MOV BYTE [ES:MD.BlocEr], 0
	POP AX
	JMP C00_80
C20_50:	PUSH CX  ; Not enough room
	MOV DX, [ES:CpDest]
	CMP DH, ':'
	JE C20_51
	MOV DL, [ES:MD.DosPth]
C20_51:	SUB DL, 'A'-1
	MOV AH, 36h
	CALL Intr21
	POP BP
	CMP AX, STRICT WORD 0FFFFh
	JE C20_52
	MUL CX
	MUL BX
	DW _OR_DX_DX
	JNE C20_52
	DW _CMP_AX_BP
	JAE C20_52
	DW _MOV_CX_AX
	DW _XOR_DX_DX
	MOV BX, [ES:CpHndl2]
	MOV AH, 40h
	CALL Intr21
	JNC C20_53
	JMP C20_45
C20_52:	DW _XOR_AX_AX
C20_53:	MOV DX, DS
	PUSH ES
	POP DS
	ADD [CpWriteLo], AX
	ADC WORD [CpWriteHi], 0
	CALL PerCent
	MOV CL, 4
	SHR AX, CL
	DW _ADD_AX_DX
	MOV [CpCont], AX
	MOV BX, [CpHndl2]
	CALL SetDate
	DW _XOR_CX_CX
	DW _XOR_DX_DX
	MOV AX, 4202h
	CALL Intr21
	DW _MOV_SI_AX
	DW _OR_SI_DX
	MOV AH, 3Eh
	CALL Intr21
	JC C20_56
	MOV DX, CpDest
	DW _OR_SI_SI
	JNE C20_54
	MOV AH, 41h
	CALL Intr21
	JNC C20_55
	JMP C20_45
C20_54:	MOV CX, [ES:CpAttr]
	MOV AX, 4301h
	CALL Intr21
	JNC C20_55
	CMP AX, STRICT WORD 5
	JNE C20_56
C20_55:	CALL F35_40
	MOV BP, Cont_B
	CALL Dialog
	CMP AL, 1
	JE C20_60
	MOV DX, CpDest
	MOV AH, 41h
	CALL Intr21
	JNC C20_56
	CMP AX, STRICT WORD 5
	JNE C20_56
	MOV CX, 20h
	MOV AX, 4301h
	CALL Intr21
	JC C20_56
	MOV AH, 41h
	CALL Intr21
C20_56:	MOV WORD [CpHndl2], 0
	JMP C20_45
C20_60:	MOV AX, [CpWriteLo]
	OR AX, [CpWriteHi]
	MOV AL, 1
	JNE C20_61
	INC AX
C20_61:	MOV [SplitFl], AL
	MOV DX, MD.TmpErr
	MOV SI, CpDest
	DW _MOV_DI_DX
	MOV CX, LenPath+13
	REP MOVSB
	DW _MOV_SI_DX
	CALL CutPath
	DW _CMP_SI_DX
	JBE C20_67
	DEC SI
	CMP BYTE [SI], '\'
	JNE C20_67
	DW _CMP_SI_DX
	JBE C20_67
	CMP BYTE [SI-1], ':'
	JE C20_67
	MOV BYTE [SI], 0
	MOV AX, 4300h
	CALL Intr21
	JNC C20_67
	CMP AX, STRICT WORD 53h
	JE C20_56
	DW _MOV_SI_DX
	CMP BYTE [SI+1], ':'
	JNE C20_62
	INC SI
	INC SI
C20_62:	CMP BYTE [SI], '\'
	JNE C20_63
	INC SI
C20_63:	LODSB
	CMP AL, 0
	JE C20_64
	CMP AL, '\'
	JNE C20_63
	MOV BYTE [SI-1], 0
	JMP C20_63
C20_64:	MOV [SI], AL
C20_65:	MOV AH, 39h
	CALL Intr21
	JNC C20_66
	CMP AX, STRICT WORD 53h
	JE C20_56
C20_66:	DW _MOV_DI_DX
	MOV CX, LenPath+13
	MOV AL, 0
	REPNE SCASB
	SCASB
	JE C20_67
	MOV BYTE [DI-2], '\'
	JMP C20_65
C20_67:	JMP C20_21
C20_70:	PUSH ES  ; Close target file
	POP DS
	CALL SetDate
	MOV AH, 3Eh
	CALL Intr21
	JC C20_74
	CMP BYTE [CpDev2], 0
	JNE C20_71
	MOV DX, CpDest
	MOV CX, [CpAttr]
	MOV AX, 4301h
	CALL Intr21
	JNC C20_71
	CMP AX, STRICT WORD 5
	JNE C20_74
C20_71:	CMP BYTE [CopyMov], 0
	JE C20_73
	MOV DX, CpSrc
	CALL ChgDisk
	JC C20_74
	MOV AH, 41h
	CALL Intr21
	JNC C20_73
	CMP AX, STRICT WORD 5
	JNE C20_72
	PUSH DX
	CALL F35_40
	MOV BP, RdOnl_B
	CALL Dialog
	POP DX
	CMP AL, 1
	JE C20_73
	JA C20_74
	MOV CX, 20h
	MOV AX, 4301h
	CALL Intr21
	JC C20_72
	MOV AH, 41h
	CALL Intr21
	JNC C20_73
C20_72:	CMP AX, STRICT WORD 53h
	JE C20_74
	MOV SI, CpSrc
	MOV DI, CpDest
	MOV CX, LenPath+13
	REP MOVSB
	CALL F35_40
	MOV BP, DelEr_B
	CALL Dialog
	JNZ C20_74
C20_73:	MOV AX, 1
	JMP C00_80
C20_74:	MOV AX, 100h
	JMP C00_80

C30_00:	CMP BYTE [CpDev2], 0  ; Copy or move directory
	JE C30_01
	JMP C30_30
C30_01:	MOV BP, CopDi_P
	CMP BYTE [CopyMov], 0
	JE C30_02
	MOV BP, MovDi_P
C30_02:	CALL F35_40
	MOV BX, 428h
	CALL OncZoom
	PUSH SI
	PUSH DX
	PUSH BX
	JCXZ C30_14
	PUSH AX  ; Rename
	CALL C40_00
	POP AX
	JE C30_12
	CMP BYTE [CopyMov], 0
	JE C30_20
	DW _OR_AL_AL
	JNE C30_20
	MOV DX, CpDest
	CALL ChgDisk
	JC C30_15
	DW _MOV_DI_DX
	MOV DX, CpSrc
	MOV AH, 56h
	CALL Intr21
	JNC C30_10
	CMP AX, STRICT WORD 53h
	JE C30_15
	JMP C30_20
C30_10:	MOV BYTE [FncChg], 1
	CMP BYTE [CpTree1], 0
	JNE C30_12
	MOV SI, CpSrc
	CALL DelTree
	JNC C30_11
	CMP AX, STRICT WORD 53h
	JE C30_15
C30_11:	MOV BYTE [CpTree1], 1
	MOV BYTE [CpTree2], 1
C30_12:	MOV DX, CpSrc
	MOV DI, CpDest
	DW _MOV_SI_DX
	CALL PathLin
	DW _MOV_SI_DI
	CALL PathLin
	JMP C10_13
C30_13:	CMP AX, STRICT WORD 53h
	JE C30_15
C30_14:	CALL F35_40
	MOV BP, MkErr_B
	CALL Dialog
	DW _XOR_AX_AX
	JMP C00_80
C30_15:	MOV AX, 100h
	JMP C00_80
C30_20:	MOV DX, CpSrc  ; Make directory
	CALL ChgDisk
	JC C30_15
	MOV AX, 4300h
	CALL Intr21
	JC C30_13
	MOV DX, CpDest
	CALL ChgDisk
	JC C30_15
	MOV AH, 39h
	CALL Intr21
	JNC C30_21
	CMP AX, STRICT WORD 53h
	JE C30_15
	MOV AX, 4300h
	CALL Intr21
	JC C30_13
	TEST CL, 10h
	JZ C30_14
	JMP C30_22
C30_21:	MOV BYTE [FncChg], 1
	AND CX, 27h
	MOV AX, 4301h
	CALL Intr21
	JC C30_13
	CMP BYTE [CpTree2], 0
	JNE C30_22
	MOV BYTE [CpTree2], 1
	DW _MOV_SI_DX
	CALL DelTree
	JNC C30_22
	CMP AX, STRICT WORD 53h
	JE C30_15
C30_22:	CMP BYTE [CopyMov], 0  ; Delete directory
	JE C30_23
	MOV DX, CpSrc
	CALL ChgDisk
	JC C30_15
	MOV AH, 3Ah
	CALL Intr21
	JNC C30_41
	CMP AX, STRICT WORD 53h
	JE C30_15
	CMP AX, STRICT WORD 5
	JE C30_23
	CMP AX, STRICT WORD 10h
	JE C30_23
	JMP C30_44
C30_23:	POP BX
	POP DX
	POP SI
	CALL ResWin
	CALL Window
C30_30:	CALL DirFunc  ; Copy / move files in the directory
	PUSH ES
	POP DS
	OR [FncChg], AL
	CMP AH, 0
	JNZ C30_31
	CMP AH, [CopyMov]
	JNE C30_40
C30_31:	JMP C00_81
C30_40:	MOV BYTE [MD.SftErr], 0  ; Delete directory
	MOV BX, 528h
	MOV DX, Move0_S
	MOV BP, DelDr_P
	CALL OncZoom
	PUSH SI
	PUSH DX
	PUSH BX
	MOV DX, CpSrc
	CALL ChgDisk
	JC C30_45
	MOV AH, 3Ah
	CALL Intr21
	JC C30_43
C30_41:	MOV BYTE [FncChg], 1
	CMP BYTE [CpTree1], 0
	JNE C30_42
	MOV BYTE [CpTree1], 1
	DW _MOV_SI_DX
	CALL DelTree
	JNC C30_42
	CMP AX, STRICT WORD 53h
	JE C30_45
C30_42:	MOV AX, 1
	JMP C00_80
C30_43:	CMP AX, STRICT WORD 53h
	JE C30_45
	CMP AX, STRICT WORD 5
	JNE C30_46
	DW _MOV_DI_DX
	MOV CH, 1
	MOV AL, 0
	REPNE SCASB
	DEC DI
	PUSH DI
	PUSH DS
	PUSH CS
	POP DS
	MOV SI, Mask_S
	MOV CX, 5
	REP MOVSB
	POP DS
	MOV CX, 37h
	MOV AH, 4Eh
	CALL Intr21
	POP DI
	MOV BYTE [DI], 0
	JNC C30_44
	CMP AX, STRICT WORD 53h
	JE C30_45
C30_46:	MOV DX, Move0_S
	MOV BP, CntDi_B
	CALL Dialog

C30_44:	DW _XOR_AX_AX
	JMP C00_80
C30_45:	MOV AX, 100h

C00_80:	POP BX  ; Exit
	POP DX
	POP SI
	CALL ResWin
	CALL Window
C00_81:	MOV BYTE [ES:MD.SftErr], 0
	CMP BYTE [ES:CopyMov], 0
	JE C00_82
	MOV BYTE [ES:CopyMov], 1
C00_82:	CMP AH, 1
	CMC
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	RET
;C00_00 ENDP

;GLOBAL C40_00
C40_00:  ; PROC NEAR  ; Compare source & destination
	PUSH DS
	PUSH ES
	POP DS
	MOV SI, CpSrc
	MOV DI, MD.TmpErr
	PUSH DI
	CALL C40_05
	MOV SI, CpDest
	MOV DI, MD.TmpErr+100
	PUSH DI
	CALL C40_05
	POP DI
	POP SI
	MOV CX, LenPath+13
	MOV AL, 0
	PUSH DI
	REPNE SCASB
	DW _MOV_CX_DI
	POP DI
	DW _SUB_CX_DI
	REPE CMPSB
	POP DS
	RET
;C40_00 ENDP

;GLOBAL C40_05
C40_05:  ; PROC NEAR
	PUSH SI
	DW _MOV_BX_DI
	MOV SI, MD.DosPth
	MOV CX, LenPath
	CALL MvzLine
	CALL AddFile
	POP SI
;C40_05 ENDP

;GLOBAL C40_10
C40_10:  ; PROC NEAR
	MOV AX, [SI]
	CMP AH, ':'
	JNE C40_11
	CALL UpCase
	CMP AL, [BX]
	JNE C40_12
	INC SI
	INC SI
C40_11:	CMP BYTE [SI], '\'
	JNE C40_13
	LEA DI, [BX+2]
	JMP C40_13
C40_12:	DW _MOV_DI_BX
C40_13:	DW _MOV_AX_DI
	DW _SUB_AX_BX
	MOV CX, LenPath+13
	PUSH CX
	DW _SUB_CX_AX
	REP MOVSB
	POP CX
	MOV AL, 0
	STOSB
	DW _MOV_SI_BX
	CALL NormStr
	CALL PathLin
	DW _MOV_DI_BX
	REPNE SCASB
	DEC DI
	DEC DI
	CMP BYTE [DI], '.'
	JNE C40_14
	STOSB
C40_14:	RET
;C40_10 ENDP

;GLOBAL C50_00
C50_00:  ; PROC NEAR
	MOV SI, CpDest
	CMP BYTE [ES:CpDev2], 0
	JNZ C50_01
	CALL LetLin
	RET
C50_01:	CALL PathLin
	RET
;C50_00 ENDP

;GLOBAL SetDate
SetDate:  ; PROC NEAR
	CMP BYTE [SplitFl], 1
	JZ SetDt1
	MOV DX, [CpDate]
	MOV CX, [CpTime]
	MOV AX, 5701h
	CALL Intr21
SetDt1:	RET
;SetDate ENDP

;GLOBAL PerCent
PerCent:  ; PROC NEAR
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
	MOV AX, [CpReadLo]
	MOV BX, [CpReadHi]
	DW _XOR_DX_DX
	ADD AX, [CpWriteLo]
	ADC BX, [CpWriteHi]
	ADC DX, 0
	DW _XOR_SI_SI
	DW _XOR_DI_DI
	DW _XOR_BP_BP
	MOV CL, [CpCntSz]
	MOV CH, 0
	PUSH CX
PerCn1:	DW _ADD_SI_AX
	DW _ADC_DI_BX
	DW _ADC_BP_DX
	LOOP PerCn1
	POP CX
	MOV AX, [CpSizeLo]
	MOV BX, [CpSizeHi]
	DW _MOV_DX_AX
	DW _OR_DX_BX
	JE PerCn3
	PUSH CX
	DW _XOR_DX_DX
	DW _ADD_AX_AX
	DW _ADC_BX_BX
	DW _ADC_DX_DX
	MOV CX, 0FFFFh
PerCn2:	INC CX
	DW _SUB_SI_AX
	DW _SBB_DI_BX
	DW _SBB_BP_DX
	JAE PerCn2
	POP AX
	DW _CMP_CX_AX
	JBE PerCn3
	DW _MOV_CX_AX
PerCn3:	MOV DL, [CpCntSz]
	MOV DH, 1
	MOV BX, [CpCntBg]
	CALL BasAdr
	MOV AH, [DI+1]
	MOV AL, 'Û'
	REP STOSW
	CALL Window
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;PerCent ENDP

F43_00:	DW _XOR_AX_AX  ; View...
	JMP F44_01

F44_00:	MOV AX, 1  ; Edit...
F44_01:	PUSH ES
	POP DS
	MOV DX, ViFl_S+1
	CMP AL, 0
	JZ F44_02
	MOV DX, EdFl_S+1
F44_02:	PUSH AX
	ADD AL, 18
	MOV [MD.HlpPage], AL
	MOV BP, ViFil_B
	CALL Dialog
	POP AX
	JNE F44_03
	CMP BYTE [MD.ViewFil], 0
	JE F44_03
	JMP F34_11
F44_03:	JMP Func04

F63_00:	MOV AX, 100h  ; Internal viewer
	JMP F34_01

F64_00:	MOV AX, 101h  ; Internal editor
	JMP F34_01

F33_00:	DW _XOR_AX_AX  ; View
	JMP F34_01

F34_00:	MOV AX, 1  ; Edit
F34_01:	CMP BYTE [WCBdef.Visible], 0
	JZ F44_01
	CMP BYTE [WCBdef.WinTyp], 0
	JNE F34_02
	MOV SI, [WCBdef.CurAdr]
	CMP SI, [WCBdef.EndBuf]
	JAE F44_03
	TEST BYTE [SI+FILENT.AttrF], 10h
	JNZ F44_03
	MOV DI, MD.ViewFil
	MOV CX, 13
	REP MOVSB
	JMP F34_11
F34_02:	CMP AL, 0
	JZ F44_01
	CMP BYTE [WCBdef.WinTyp], 2
	JNE F44_01
F34_10:	CALL BegBX  ; Edit 'dirinfo'
	CALL SizDX
	PUSH CS
	POP DS
	MOV SI, DrIn_F
	MOV DI, MD.ViewFil
	MOV CX, 13
	PUSH DI
	REP MOVSB
	POP SI
	CALL LetLin
	PUSH ES
	POP DS
	ADD BX, 0B02h
	SUB DX, 0C04h
	MOV [ViewDat.ViBase], BX
	MOV [ViewDat.ViSize], DX
	DEC BH
	ADD BL, 15
	MOV DX, 106h
	CALL BasAdr
	MOV SI, EdFl_S
	MOV CX, 6
	MOV AH, Slct_C
	CALL Color
	CALL MvsBwc
	MOV DL, 1
	MOV AL, 2
	JMP V00_02
F34_11:	MOV BX, MD.AltView
	CMP AL, 0
	JE F34_12
	MOV BX, MD.AltEdit
F34_12:	CMP BYTE [ES:BX], 0
	JNE F34_13
	DW _OR_AH_AH
	MOV AH, 0
	JNE F34_13
	MOV AH, 1
F34_13:	DW _MOV_BL_AL
	DW _OR_AH_AH
	JNZ F34_15
	CALL HidCur  ; Load extension file
	MOV AL, 2
	CALL PutMnu
	MOV BP, ViewE_F
	DW _OR_BL_BL
	JZ F34_14
	MOV BP, EditE_F
F34_14:	MOV DX, MD.TmpBuf
	PUSH CS
	POP DS
	DW _MOV_SI_BP
	DW _MOV_DI_DX
	MOV CX, 13
	REP MOVSB
	PUSH ES
	POP DS
	CALL ChgDisk
	JC F34_17
	MOV AL, 40h
	CALL OpenFil
	JNC F34_18
	CMP AL, 2
	JNE F34_17
	DW _MOV_SI_BP
	DW _MOV_DI_DX
	CALL MainFil
	CALL ChgDisk
	JNC F34_16
F34_15:	DW _MOV_DL_BL
	JMP V00_00
F34_16:	MOV AL, 40h
	CALL OpenFil
	JNC F34_18
	CMP AL, 3
	JBE F34_15
F34_17:	JMP Func04
F34_18:	DW _MOV_DI_BX
	DW _MOV_BX_AX
	MOV DX, MD.MenuBuf
	MOV CX, LenMenu-1
	MOV AH, 3Fh
	CALL Intr21
	PUSHF
	PUSH AX
	MOV AH, 3Eh
	CALL Intr21
	POP BX
	POP CX
	JC F34_17
	PUSH CX
	POPF
	JC F34_17
	MOV BYTE [MD.MenuBuf+BX], 1Ah
	DW _MOV_BX_DI
	MOV SI, MD.ViewFil  ; Test extension file
	CALL CutPath
	CALL FindExt
	DW _OR_SI_SI
	JE F34_15
	CALL F34_30
	JC F34_15
	MOV BP, 1
	PUSH BX
	CALL F34_40
	POP BX
	JC F34_20
	MOV AL, ' '
	STOSB
	JMP Run_00
F34_20:	CALL ChgDisk  ; Standard viewer
	JC F34_21
	MOV CX, 27h
	MOV AH, 4Eh
	CALL Intr21
	JNC F34_22
	CMP AX, STRICT WORD 53h
	JE F34_21
	JMP F34_15
F34_21:	JMP Func04
F34_22:	MOV SI, MD.ViewFil
	MOV DI, MD.TmpBuf+100+1
	MOV CX, LenStr+1
	PUSH DI
	CALL MvzLine
	POP SI
	DW _MOV_AX_DI
	DW _SUB_AX_SI
	ADD AL, 45
	MOV [MD.TmpBuf+100], AL
	MOV AL, 0
	MOV BP, Viewr_P
	CMP BL, 0
	JE Aexec0
	MOV BP, Editr_P
Aexec0:	PUSH AX
	MOV BX, 528h
	CALL DialBox
	CALL Window
	MOV [MD.TmpBuf+95], BX
	MOV [MD.TmpBuf+97], DX
	MOV BH, 0
	MOV AH, 3
	INT 10h
	MOV [MD.TmpBuf+93], CX
	PUSH CS
	POP DS
	MOV SI, ViewPar
	MOV CX, 9
	PUSH DI
	REP MOVSB
	MOV CX, 36
	MOV AL, 0
	REP STOSB
	MOV AL, 0Dh
	STOSB
	PUSH ES
	POP DS
	POP DI
	POP AX
	MOV [DI+15], AL
	MOV AL, [MD.ColTyp]
	MOV [DI+9], AL
	CMP BYTE [MD.Mouse], 0
	JE Aexec1
	MOV BYTE [DI+11], 0FFh
	MOV AL, [MD.LftMous]
	MOV [DI+12], AL
	MOV BYTE [DI+13], 1
Aexec1:	MOV BX, [MD.ViewSeg]
	MOV AX, ES
	DW _SUB_BX_AX
	ADD BX, ((MinView-1)>>4)+1
	MOV AH, 4Ah
	INT 21h
	MOV BX, MD.EPB
	MOV WORD [BX+EPBs.CmdLine+0], MD.TmpBuf+100
	MOV [BX+EPBs.CmdLine+2], ES
	MOV DX, MD.TmpBuf
	DW _MOV_SI_DX
	CALL LetLin
	MOV AX, 4B00h
	CALL Intr21
	PUSHF
	PUSH AX
	MOV BX, 0FFFFh
	MOV AH, 4Ah
	INT 21h
	MOV AH, 4Ah
	INT 21h
	CALL HidCur
	PUSH ES
	POP DS
	CALL SavMous
	CALL IniMous
	POP AX
	POPF
	JNC Aexec3
	CMP AX, STRICT WORD 53h
	JE Aexec3
	MOV DX, RunEr_S
	CMP AX, STRICT WORD 8
	JE Aexec2
	CMP AX, STRICT WORD 7
	JE Aexec2
	MOV DX, Run1_S
	MOV SI, Run2_S
	PUSH CS
	POP DS
	MOV DI, MD.TmpBuf
	MOV CX, 80
	REP MOVSB
	PUSH ES
	POP DS
Aexec2:	MOV BP, RunEr_B
	CALL Dialog
Aexec3:	MOV BX, [MD.TmpBuf+95]
	MOV DX, [MD.TmpBuf+97]
	MOV SI, MD.WinBuf
	CALL ResWin
	DW _XOR_BX_BX
	MOV DL, 80
	MOV DH, [MD.Lines]
	CALL Window
	MOV CX, [MD.TmpBuf+93]
	MOV AH, 1
	INT 10h
	JMP FncEx1

;GLOBAL F34_30
F34_30:  ; PROC NEAR
	CALL FndLet
	CALL IsCrLfS
	JE F34_31
	DEC SI
	CMP AL, 1Ah
	JE F34_33
	DEC SI
	CLC
	RET
F34_31:	MOV AX, [SI]
	CMP AL, ' '
	JE F34_30
	CMP AL, 9
	JE F34_30
	CALL IsCrLf
	JE F34_32
	CMP AL, "'"
	JNE F34_33
F34_32:	CALL IsCrLfS
	JE F34_31
	DEC SI
	CMP AL, 1Ah
	JNE F34_32
F34_33:	STC
	RET
;F34_30 ENDP

;GLOBAL F34_40
F34_40:  ; PROC NEAR
	DW _MOV_DI_SI
	MOV AX, [SI]
	CMP AH, ':'
	JNE F34_41
	CALL UpCase
	CMP AL, 'A'
	JB F34_45
	CMP AL, 'Z'
	JA F34_45
	INC SI
	INC SI
F34_41:	LODSW
	DEC SI
	CMP AL, '!'
	JE F34_45
	CALL IsCrLf
	JE F34_42
	CMP AL, 1Ah
	JE F34_42
	CMP AL, ' '
	JE F34_42
	CMP AL, 9
	JNE F34_41
F34_42:	DEC SI
	PUSH SI
	SUB SI, 4
	MOV BX, Menu_F+1
	MOV CX, 1
	DW _OR_BP_BP
	JNZ F34_43
	MOV CX, 4
F34_43:	LODSB
	CALL UpCase
	INC BX
	CMP AL, [CS:BX]
	LOOPE F34_43
	POP SI
	JNE F34_45
	PUSH SI
	CALL F34_30
	POP SI
	JNC F34_45
	MOV BYTE [SI], 0
	DW _SUB_SI_DI
	CMP SI, LenPath+12
	JAE F34_45
	DW _MOV_SI_DI
	CALL CutPath
	DW _CMP_SI_DI
	MOV DX, MD.TmpBuf
	DW _MOV_SI_DX
	JNE F34_44
	CALL CutPath
F34_44:	DW _XCHG_SI_DI
	MOV CX, LenPath+13
	REP MOVSB
	STC
	RET
F34_45:	DEC DI
	DW _MOV_SI_DI
	CLC
	RET
;F34_40 ENDP

V00_00:	MOV AL, 2
V00_01:	MOV WORD [ES:ViewDat.ViBase], 100h
	MOV BL, 80
	MOV BH, [ES:MD.Lines]
	SUB BH, 2
	MOV [ES:ViewDat.ViSize], BX
V00_02:	MOV BYTE [ES:MD.WinMous], 0
	CALL PutMnu
	PUSH ES
	POP DS
	MOV [ViewDat.ViewEdit], DL
	DW _OR_DL_DL
	MOV DX, ViFl_S
	JZ V00_03
	MOV DX, EdFl_S
V00_03:	MOV BX, 528h
	MOV BP, RdFil_P
	CALL DialBox
	CALL Window
	DW _MOV_CX_DX
	MOV DX, MD.ViewFil
	CALL ChgDisk
	JC V00_05
	MOV AL, 40h
	CALL OpenFil
	JNC V00_06
	CMP AX, STRICT WORD 53h
	JE V00_05
	MOV DX, ViFl_S
	CMP BYTE [ViewDat.ViewEdit], 0
	JZ V00_04
	CMP AX, STRICT WORD 2
	MOV AX, 0FFFFh
	JE V00_06
	MOV DX, EdFl_S
V00_04:	MOV BP, FndEr_B
	CALL Dialog
V00_05:	DW _MOV_DX_CX
	CALL ResWin
	CALL Window
	JMP Func04
V00_06:	CALL TstBrk
	JC V00_05
	PUSH SI
	PUSH CX
	PUSH BX
	MOV [ViewDat.ViHandle], AX
	DW _MOV_BX_AX
	CMP BX, 0FFFFh
	JE V00_07
	DW _XOR_CX_CX
	DW _XOR_DX_DX
	MOV AX, 4202h
	CALL Intr21
	JNC V00_08
V00_07:	DW _XOR_DX_DX
	DW _XOR_AX_AX
V00_08:	MOV [ViewDat.ViLen+0], AX
	MOV [ViewDat.ViLen+2], DX
	DW _XOR_CX_CX
	DW _XOR_DX_DX
	MOV AX, 4200h
	CALL Intr21
	MOV AL, [MD.Clock]
	MOV AH, [MD.KeyBar]
	MOV [ViewDat.ViKeyBar], AX
	POP AX
	POP DX
	POP SI
	CMP BYTE [ViewDat.ViewEdit], 0
	JZ V00_10
	JMP T00_00
V00_10:	MOV AX, ES
	ADD AX, [MD.FreMem2]
	SUB AX, [MD.ViewSeg]
	CMP AX, STRICT WORD 0FFEh
	JBE V00_11
	MOV AX, 0FFEh
V00_11:	MOV CL, 4
	SHL AX, CL
	MOV [ViewDat.ViSpace], AX
	DW _MOV_CX_AX
	MOV DS, [MD.ViewSeg]
	DW _XOR_DX_DX
	CALL V55_00
	PUSH DS
	PUSH ES
	POP DS
	DW _XOR_AX_AX
	CMP AX, [ViewDat.ViLen+2]
	JNE V00_12
	MOV CX, [ViewDat.ViLen+0]
V00_12:	MOV [ViewDat.ViLoaded], CX
	MOV [ViewDat.ViOffset+0], AX
	MOV [ViewDat.ViOffset+2], AX
	MOV [ViewDat.ViFirst], AX
	MOV [ViewDat.ViCol], AX
	MOV [ViewDat.ViTxHex], AL
	MOV [MD.Clock], AL
	MOV BYTE [MD.KeyBar], 1
	MOV BYTE [ViewDat.ViWrap], 1
	MOV WORD [ViewDat.ViSearch+0], 0FFF0h
	MOV WORD [ViewDat.ViSearch+2], 0FFFFh
	MOV BYTE [MD.HlpPage], 3
	CMP BYTE [ViewDat.ViSize+0], 79
;JB	V00_14
	JNB JSV00_14  ; !! SHORT would fit.
	JMP STRICT NEAR V00_14
JSV00_14:
	MOV DI, MD.ScrBuf+0  ; Status line
	MOV AH, Menu_C
	CALL Color
	MOV CX, 80
	MOV AL, ' '
	REP STOSW
	MOV SI, ViFl_S+1
	MOV DI, MD.ScrBuf+0
	MOV CX, 4
	CALL MvsBwc
	MOV AL, ':'
	STOSW
	MOV SI, Col_S
	MOV DI, MD.ScrBuf+2*40
	MOV CX, 3
	CALL MvsBwc
	PUSH AX
	MOV SI, MD.ViewFil
	MOV DI, MD.TmpBuf
	MOV CX, LenPath+13
	PUSH DI
	REP MOVSB
	POP SI
	CALL LetLin
	MOV AX, 33
	CALL ShrtLin
	MOV DI, MD.ScrBuf+2*6
	CALL MovDz0
	MOV DI, MD.TmpBuf
	DW _MOV_SI_DI
	MOV CX, [ViewDat.ViLen+0]
	MOV BX, [ViewDat.ViLen+2]
	MOV AL, 3
	CALL Number
	MOV DI, MD.ScrBuf+2*51
	CALL MovDz0
	POP AX
	MOV SI, Byts_S
	MOV CX, 6
	CMP WORD [ViewDat.ViLen+0], 1
	JNE V00_13
	CMP WORD [ViewDat.ViLen+2], 0
	JNE V00_13
	DEC CX
V00_13:	CALL MvsBwc
	MOV BYTE [MD.ScrBuf+2*78], '%'
	MOV AL, 1
V00_14:	MOV [ViewDat.ViStatus], AL
	POP DS
V00_15:	DW _XOR_SI_SI
	MOV DI, [ES:ViewDat.ViSpace]
	CALL V60_00

V00_20:	CALL V25_00  ; Output screen
	CALL V30_00
	JNC V00_30
V00_21:	CALL V40_00
	JNC V00_30
	MOV AX, [ES:ViewDat.ViSpace]
	SHR AX, 1
	CMP [ES:ViewDat.ViFirst], AX
	JB V00_30
	CALL V50_00  ; Continue read
V00_22:	CALL V30_00

V00_30:	CALL GetMous  ; Mouse
	JNZ V00_31
	MOV BYTE [ES:MD.WinMous], 0
	JMP V00_40
V00_31:	CALL ClrKbd
	MOV BX, [ES:ViewDat.ViBase]
	MOV DX, [ES:ViewDat.ViSize]
	CMP BYTE [ES:MD.WinMous], 0
	JNZ V00_32
	CALL InWind
	JC V00_30
V00_32:	MOV BYTE [ES:MD.WinMous], 1
	PUSH BX
	DW _MOV_AL_DH
	CBW
	MOV BL, 3
	DIV BL
	DW _ADD_BH_AL
	DW _CMP_CH_BH
	POP BX
	JAE V00_33
	JMP V05_00
V00_33:	DW _ADD_BH_DH
	DW _SUB_BH_AL
	DW _CMP_CH_BH
	JB V00_34
	JMP V06_00
V00_34:	DW _MOV_AL_DL
	SHR AL, 1
	SHR AL, 1
	DW _ADD_BL_AL
	DW _CMP_CL_BL
	JAE V00_35
	JMP V01_00
V00_35:	DW _SUB_BL_AL
	DW _ADD_BL_DL
	DW _SUB_BL_AL
	DW _CMP_CL_BL
	JB V00_40
	JMP V03_00

V00_40:	MOV AL, 3  ; Input
	CMP BYTE [ES:ViewDat.ViTxHex], 0
	JNZ V00_41
	INC AX
	CMP BYTE [ES:ViewDat.ViWrap], 0
	JZ V00_41
	INC AX
V00_41:	CALL Input
	CALL ClrKbd
	CMP AH, 0FCh
	JE V00_42
	MOV SI, View_T
	CALL Case
V00_42:	JMP V00_30

V01_00:	MOV BX, 1  ; Left
	JMP V02_01

V02_00:	MOV BX, 40  ; ^Left
V02_01:	CMP BYTE [ES:ViewDat.ViTxHex], 0
	JNZ V00_42
	MOV AX, [ES:ViewDat.ViCol]
	DW _OR_AX_AX
	JE V00_42
	DW _SUB_AX_BX
	JAE V02_02
	DW _XOR_AX_AX
V02_02:	CMP AX, [ES:ViewDat.ViCol]
	JE V00_42
	MOV [ES:ViewDat.ViCol], AX
	JMP V00_20

V03_00:	MOV BX, 1  ; Right
	JMP V04_01

V04_00:	MOV BX, 40  ; ^Right
V04_01:	CMP BYTE [ES:ViewDat.ViTxHex], 0
	JNZ V00_42
	MOV AX, [ES:ViewDat.ViCol]
	MOV CX, 0FFFFh-80
	DW _CMP_AX_CX
	JAE V00_42
	DW _ADD_AX_BX
	DW _CMP_AX_CX
	JB V02_02
	DW _MOV_AX_CX
	JMP V02_02

V05_00:	CALL V20_00  ; Up
	DW _MOV_AX_SI
	OR AX, [ES:ViewDat.ViOffset+0]
	OR AX, [ES:ViewDat.ViOffset+2]
	JE V00_42
	CALL PrevLin
	JC V05_01
	DW _OR_SI_SI
	JNE V05_02
	MOV AX, [ES:ViewDat.ViSpace]
	SHR AX, 1
	CMP AX, [ES:ViewDat.ViFirst]
	JBE V05_02
V05_01:	MOV AX, [ES:ViewDat.ViOffset+0]
	OR AX, [ES:ViewDat.ViOffset+2]
	JE V05_02
	CALL V51_00
	CALL V20_00
	CALL PrevLin
	MOV [ES:ViewDat.ViFirst], SI
	MOV [ES:ViewDat.ViPoint], BX
	CALL V25_00
	JMP V00_22
V05_02:	PUSH DS
	PUSH ES
	POP DS
	MOV [ViewDat.ViFirst], SI
	MOV [ViewDat.ViPoint], BX
	CALL V25_00
	MOV BX, [ViewDat.ViBase]
	PUSH BX
	ADD BH, [ViewDat.ViSize+1]
	DEC BH
	MOV DX, -2*80
	MOV AX, 700h
	CALL T71_00
	POP BX
	CALL V31_00
	POP DS
	CALL V20_00
	DW _MOV_BP_SI
	CALL NextLin
	DW _XCHG_BP_SI
	JNC V05_03
	MOV BP, [ES:ViewDat.ViLoaded]
V05_03:	MOV AL, 0
	CALL V32_00
	PUSH BX
	MOV BX, [ES:EdData.EdBase]
	MOV DL, [ES:EdData.EdSize+0]
	MOV DH, 1
	CALL Window
	POP BX
	MOV CL, [ES:ViewDat.ViSize+1]
	MOV CH, 0
V05_04:	CALL NextLin
	JC V06_05
	LOOP V05_04
V05_05:	JMP V00_30

V06_00:	CMP BYTE [ES:ViewDat.Vi100pc], 0  ; Down
	JNZ V05_05
	CALL V20_00
	CALL NextLin
	JNC V06_01
	CALL V50_00
	DW _XOR_SI_SI
	MOV BX, [ES:ViewDat.ViSpace]
	DEC BX
	DEC BX
	STC
V06_01:	MOV [ES:ViewDat.ViFirst], SI
	MOV [ES:ViewDat.ViPoint], BX
	JNC V06_02
	CALL V25_00
	JMP V00_22
V06_02:	CALL V25_00
	PUSH DS
	PUSH ES
	POP DS
	MOV BX, [ViewDat.ViBase]
	PUSH BX
	MOV DX, 2*80
	MOV AX, 600h
	CALL T71_00
	POP BX
	ADD BH, [ViewDat.ViSize+1]
	DEC BH
	CALL V31_00
	MOV AL, [ViewDat.ViSize+1]
	CBW
	DEC AX
	POP DS
	DW _MOV_CX_AX
	CALL V20_00
V06_03:	CALL NextLin
	JC V06_05
	LOOP V06_03
	DW _MOV_BP_SI
	CALL NextLin
	DW _XCHG_BP_SI
	JNC V06_04
	MOV BP, [ES:ViewDat.ViLoaded]
V06_04:	PUSHF
	CALL V32_00
	MOV BX, [ES:ViewDat.ViBase]
	DW _ADD_BH_AL
	MOV DL, [ES:ViewDat.ViSize+0]
	MOV DH, 1
	CALL Window
	POPF
	JNC V06_06
V06_05:	CALL V40_00
	JMP V00_21
V06_06:	JMP V00_30

V07_00:	CALL V20_00  ; PgUp
	DW _MOV_AX_SI
	OR AX, [ES:ViewDat.ViOffset+0]
	OR AX, [ES:ViewDat.ViOffset+2]
	JE V06_06
	MOV CL, [ES:ViewDat.ViSize+1]
	MOV CH, 0
	DEC CX
	DEC CX
V07_01:	CALL PrevLin
	JC V07_02
	LOOP V07_01
	DW _OR_SI_SI
	JNE V07_04
V07_02:	MOV AX, [ES:ViewDat.ViSpace]
	SHR AX, 1
	CMP AX, [ES:ViewDat.ViFirst]
	JBE V07_04
	MOV AX, [ES:ViewDat.ViOffset+0]
	OR AX, [ES:ViewDat.ViOffset+2]
	JE V07_04
	CALL V51_00
	CALL V20_00
	MOV CL, [ES:MD.Lines]
	SUB CL, 4
	MOV CH, 0
V07_03:	CALL PrevLin
	JC V07_04
	LOOP V07_03
V07_04:	MOV [ES:ViewDat.ViFirst], SI
	MOV [ES:ViewDat.ViPoint], BX
	CALL V25_00
	JMP V00_22

V08_00:	CMP BYTE [ES:ViewDat.Vi100pc], 0  ; PgDn
	JNZ V06_06
	CALL V20_00
	MOV DI, MD.TmpBuf-2
	MOV CL, [ES:ViewDat.ViSize+1]
	MOV CH, 0
	DEC CX
	DEC CX
V08_01:	CALL NextLin
	JC V08_06
	INC DI
	INC DI
	MOV [ES:DI], SI
	LOOP V08_01
	MOV CL, [ES:ViewDat.ViSize+1]
	DEC CX
V08_02:	CALL NextLin
	JC V08_03
	LOOP V08_02
	JMP V08_05
V08_03:	MOV AX, [ES:ViewDat.ViOffset+0]
	MOV BX, [ES:ViewDat.ViOffset+2]
	ADD AX, [ES:ViewDat.ViLoaded]
	ADC BX, 0
	CMP BX, [ES:ViewDat.ViLen+2]
	JB V08_05
	JA V08_04
	CMP AX, [ES:ViewDat.ViLen+0]
	JB V08_05
V08_04:	DW _ADD_CX_CX
	DW _SUB_DI_CX
	JC V09_01
	CMP DI, MD.TmpBuf
	JB V09_01
V08_05:	MOV SI, [ES:DI]
	MOV [ES:ViewDat.ViFirst], SI
	JMP V00_20
V08_06:	CALL V50_00
	MOV WORD [ES:ViewDat.ViFirst], 0
	MOV BX, [ES:ViewDat.ViSpace]
	DEC BX
	DEC BX
	MOV [ES:ViewDat.ViPoint], BX
	JMP V00_20

V09_00:	MOV AX, [ES:ViewDat.ViOffset+0]  ; Home
	OR AX, [ES:ViewDat.ViOffset+2]
	JNZ V09_02
	MOV AX, [ES:ViewDat.ViFirst]
	OR AX, [ES:ViewDat.ViCol]
	JE V09_01
	MOV WORD [ES:ViewDat.ViFirst], 0
	MOV WORD [ES:ViewDat.ViCol], 0
	JMP V00_20
V09_01:	JMP V00_30
V09_02:	MOV WORD [ES:ViewDat.ViOffset+0], 0
	MOV WORD [ES:ViewDat.ViOffset+2], 0
	MOV WORD [ES:ViewDat.ViFirst], 0
	MOV WORD [ES:ViewDat.ViCol], 0
	MOV CX, [ES:ViewDat.ViSpace]
	CMP WORD [ES:ViewDat.ViLen+2], 0
	JNE V09_03
	MOV AX, [ES:ViewDat.ViLen+0]
	DW _CMP_CX_AX
	JBE V09_03
	DW _MOV_CX_AX
V09_03:	MOV [ES:ViewDat.ViLoaded], CX
	MOV BX, [ES:ViewDat.ViHandle]
	PUSH CX
	DW _XOR_DX_DX
	DW _XOR_CX_CX
	MOV AX, 4200h
	CALL Intr21
	POP CX
	DW _XOR_DX_DX
	CALL V55_00
	JMP V00_15

V10_00:	CMP BYTE [ES:ViewDat.Vi100pc], 0  ; End
	JNZ V09_01
	MOV AX, [ES:ViewDat.ViLen+0]
	MOV BX, [ES:ViewDat.ViLen+2]
	SUB AX, [ES:ViewDat.ViOffset+0]
	SBB BX, [ES:ViewDat.ViOffset+2]
	DW _OR_BX_BX
	JNE V10_01
	CMP AX, [ES:ViewDat.ViLoaded]
	JBE V10_03
V10_01:	MOV AX, [ES:ViewDat.ViLen+0]
	MOV BX, [ES:ViewDat.ViLen+2]
	DW _MOV_DX_AX
	AND DX, 0Fh
	MOV CX, [ES:ViewDat.ViSpace]
	SHR CX, 1
	SUB CX, 10h
	DW _ADD_CX_DX
	DW _SUB_AX_CX
	SBB BX, 0
	MOV [ES:ViewDat.ViOffset+0], AX
	MOV [ES:ViewDat.ViOffset+2], BX
	MOV [ES:ViewDat.ViLoaded], CX
	MOV WORD [ES:ViewDat.ViFirst], 0
	MOV BX, [ES:ViewDat.ViHandle]
	MOV SI, [ES:ViewDat.ViOffset+0]
	MOV DI, [ES:ViewDat.ViOffset+2]
	DW _MOV_DX_SI
	DW _MOV_CX_DI
	MOV AX, 4200h
	CALL Intr21
	DW _CMP_AX_SI
	JNE V10_02
	DW _CMP_DX_DI
	JNE V10_02
	DW _XOR_DX_DX
	MOV CX, [ES:ViewDat.ViLoaded]
	CALL V55_00
V10_02:	DW _XOR_SI_SI
	MOV DI, [ES:ViewDat.ViSpace]
	CALL V60_00
V10_03:	MOV BX, [ES:ViewDat.ViEndTab]
	MOV SI, [BX]
	MOV CL, [ES:ViewDat.ViSize+1]
	MOV CH, 0
	DEC CX
	CMP BYTE [ES:ViewDat.ViTxHex], 0
	JE V10_04
	MOV SI, [ES:ViewDat.ViLoaded]
	DEC SI
V10_04:	CALL PrevLin
	JC V10_05
	LOOP V10_04
V10_05:	MOV [ES:ViewDat.ViFirst], SI
	MOV [ES:ViewDat.ViPoint], BX
	JMP V00_20

V11_00:	MOV BX, ViewDat.ViTxHex  ; F4 - ASCII / Hex
	CALL InvVar
	JMP V00_20

V12_00:	CMP BYTE [ES:ViewDat.ViTxHex], 0  ; F2 - Wrap / Unwrap
	JNZ V12_01
	MOV BX, ViewDat.ViWrap
	CALL InvVar
	JMP V00_20
V12_01:	JMP V00_30

V13_00:	MOV BX, [ES:ViewDat.ViHandle]  ; Esc
	MOV AH, 3Eh
	CALL Intr21
	MOV CL, 0
V13_01:	CALL Quit
	MOV AX, [ES:ViewDat.ViKeyBar]
	MOV [ES:MD.Clock], AL
	MOV [ES:MD.KeyBar], AH
	MOV DS, [ES:MD.WCB1seg]
	CMP BYTE [WCBdef.Visible], 0
	JZ V13_02
	CALL Panel
	CALL PutPath
	CALL PutFls
V13_02:	OR [WCBdef.ChgFlg], CL
	MOV DS, [ES:MD.WCB2seg]
	CMP BYTE [WCBdef.Visible], 0
	JZ V13_03
	CALL Panel
	CALL PutPath
	CALL PutFls
V13_03:	OR [WCBdef.ChgFlg], CL
	CALL PutPrm
	MOV AL, 0
	CALL PutMnu
	MOV AL, 0FFh
	CALL PutKey
	DW _XOR_BX_BX
	MOV DH, [ES:MD.Lines]
	MOV DL, 80
	CALL Window
	MOV BYTE [ES:MD.WinMous], 0
	JMP Init50

V14_00:	PUSH DS  ; F7 - search
	PUSH ES
	POP DS
	MOV DX, ViFl_S
	MOV BP, Srch_B
	CALL Dialog
	POP DS
	JE V15_00
V14_01:	JMP V00_30

V15_00:	CMP BYTE [ES:MD.SrchStr], 0  ; Continue search
	JE V14_01
	MOV DX, ViFl_S
	CALL V80_00
	PUSH SI
	PUSH DX
	PUSH BX
	MOV SI, [ES:ViewDat.ViFirst]
	CMP WORD [ES:ViewDat.ViSearch+2], 0FFFFh
	JE V15_01
	MOV BX, [ES:ViewDat.ViPoint]
	CALL NextLin
	JNC V15_01
	MOV SI, [ES:ViewDat.ViLoaded]
V15_01:	MOV AX, [ES:ViewDat.ViOffset+0]
	MOV BX, [ES:ViewDat.ViOffset+2]
	DW _ADD_AX_SI
	ADC BX, 0
	MOV [ES:ViewDat.ViSearch+0], AX
	MOV [ES:ViewDat.ViSearch+2], BX
	MOV CX, [ES:ViewDat.ViLoaded]
	DW _SUB_CX_SI
	JB V15_04
	DW _MOV_DX_SI
	CALL V82_00
	JNC V15_02
	JMP V15_06
V15_02:	DW _MOV_DI_SI
	DW _SUB_DI_DX
	MOV AH, 0
	JMP V15_10
V15_03:	JMP V15_22
V15_04:	CALL TstBrk
	MOV AL, 2
	JC V15_03
	MOV AX, [ES:ViewDat.ViSearch+0]
	MOV BX, [ES:ViewDat.ViSearch+2]
	MOV CX, [ES:ViewDat.ViLen+0]
	MOV DX, [ES:ViewDat.ViLen+2]
	DW _SUB_CX_AX
	DW _SBB_DX_BX
	JB V15_07
	PUSH DX
	DW _OR_DX_CX
	POP DX
	JE V15_07
	DW _OR_DX_DX
	MOV DX, LenMenu
	JNE V15_05
	DW _CMP_DX_CX
	JBE V15_05
	DW _MOV_DX_CX
V15_05:	PUSH DX
	MOV BX, [ES:ViewDat.ViHandle]
	MOV DX, [ES:ViewDat.ViSearch+0]
	MOV CX, [ES:ViewDat.ViSearch+2]
	MOV AX, 4200h
	CALL Intr21
	POP CX
	CMP AX, [ES:ViewDat.ViSearch+0]
	JNE V15_07
	CMP DX, [ES:ViewDat.ViSearch+2]
	JNE V15_07
	PUSH DS
	PUSH ES
	POP DS
	MOV DX, MD.MenuBuf
	MOV AH, 3Fh
	CALL Intr21
	POP DS
	DW _MOV_CX_AX
	MOV AL, 2
	JC V15_03
	DW _MOV_SI_DX
	PUSH DS
	PUSH ES
	POP DS
	CALL V82_00
	POP DS
	LEA DI, [SI-MD.MenuBuf]
	MOV AH, 1
	JNC V15_10
V15_06:	SUB CX, [ES:MD.HelpBuf+90]
	JB V15_07
	INC CX
	ADD [ES:ViewDat.ViSearch+0], CX
	ADC WORD [ES:ViewDat.ViSearch+2], 0
	JMP V15_04
V15_07:	PUSH DS
	PUSH ES
	POP DS
	MOV DX, ViFl_S
	MOV BP, SrEr_B
	CALL Dialog
	POP DS
	MOV AL, 3
	JMP V15_22
V15_10:	MOV [ES:ViewDat.ViSrPan], AL
	MOV BX, [ES:MD.HelpBuf+90]
	CMP AL, 0
	JNZ V15_11
	MOV BX, [ES:HexLen]
V15_11:	MOV [ES:ViewDat.ViSrLen], BL
	DW _SUB_DI_BX
	ADD [ES:ViewDat.ViSearch+0], DI
	ADC WORD [ES:ViewDat.ViSearch+2], 0
	DW _OR_AH_AH
	JZ V15_15
	MOV AX, [ES:ViewDat.ViSearch+0]
	MOV BX, [ES:ViewDat.ViSearch+2]
	SUB AX, STRICT WORD 2000
	SBB BX, 0
	JAE V15_12
	DW _XOR_AX_AX
	DW _XOR_BX_BX
V15_12:	AND AX, STRICT WORD 0FFF0h
	MOV [ES:ViewDat.ViOffset+0], AX
	MOV [ES:ViewDat.ViOffset+2], BX
	MOV CX, [ES:ViewDat.ViLen+0]
	MOV DX, [ES:ViewDat.ViLen+2]
	DW _SUB_CX_AX
	DW _SBB_DX_BX
	MOV AX, [ES:ViewDat.ViSpace]
	DW _OR_DX_DX
	JNE V15_13
	DW _CMP_AX_CX
	JBE V15_13
	DW _MOV_AX_CX
V15_13:	MOV [ES:ViewDat.ViLoaded], AX
	MOV BX, [ES:ViewDat.ViHandle]
	MOV SI, [ES:ViewDat.ViOffset+0]
	MOV DI, [ES:ViewDat.ViOffset+2]
	DW _MOV_DX_SI
	DW _MOV_CX_DI
	MOV AX, 4200h
	CALL Intr21
	DW _CMP_AX_SI
	JNE V15_14
	DW _CMP_DX_DI
	JNE V15_14
	DW _XOR_DX_DX
	MOV CX, [ES:ViewDat.ViLoaded]
	CALL V55_00
V15_14:	DW _XOR_SI_SI
	MOV DI, [ES:ViewDat.ViSpace]
	CALL V60_00
V15_15:	MOV CX, [ES:ViewDat.ViSearch+0]
	SUB CX, [ES:ViewDat.ViOffset+0]
	MOV [ES:ViewDat.ViFirst], CX
	CMP BYTE [ES:ViewDat.ViTxHex], 0
	JNZ V15_21
	CALL V20_00
	DW _SUB_CX_SI
	JB V15_21
	DW _XOR_BX_BX
	JCXZ V15_18
V15_16:	LODSB
	CMP AL, 9
	JNE V15_17
	OR BL, 7
V15_17:	INC BX
	LOOP V15_16
V15_18:	MOV AX, [ES:ViewDat.ViCol]
	DW _CMP_BX_AX
	JA V15_19
	DW _OR_BX_BX
	JE V15_20
	DEC BX
	JMP V15_20
V15_19:	ADD BL, [ES:ViewDat.ViSrLen]
	ADC BH, 0
	ADD AL, [ES:ViewDat.ViSize+0]
	ADC AH, 0
	DW _SUB_BX_AX
	JB V15_21
	DW _ADD_BX_AX
	SUB BL, [ES:ViewDat.ViSize+0]
	SBB BH, 0
	INC BX
V15_20:	MOV [ES:ViewDat.ViCol], BX
V15_21:	MOV AL, 0
V15_22:	POP BX
	POP DX
	POP SI
	CALL ResWin
	CALL Window
	CMP AL, 0
	JZ V15_24
	MOV WORD [ES:ViewDat.ViSearch+0], 0FFF0h
	MOV WORD [ES:ViewDat.ViSearch+2], 0FFFFh
	JMP V00_30
V15_24:	JMP V00_20

;GLOBAL NextLin
NextLin:  ; PROC NEAR  ; Find next line
	PUSH DX
	PUSH AX
	DW _MOV_DX_SI
	CMP BYTE [ES:ViewDat.ViTxHex], 0
	JZ NxLin1
	AND SI, 0FFF0h
	ADD SI, 10h
	CMP [ES:ViewDat.ViLoaded], SI
	JBE NxLin4
	JMP NxLin6
NxLin1:	INC BX
	INC BX
	CMP SI, [BX-2]
	JAE NxLin2
	MOV BX, [ES:ViewDat.ViSpace]
NxLin2:	CMP BX, [ES:ViewDat.ViEndTab]
	JBE NxLin4
	DEC BX
	DEC BX
	CMP SI, [BX]
	JAE NxLin2
	MOV SI, [BX]
	CMP BYTE [ES:ViewDat.ViWrap], 0
	JNZ NxLin5
NxLin3:	MOV SI, [BX]
	CALL IsCrLf0
	JE NxLin5
	DEC BX
	DEC BX
	CMP BX, [ES:ViewDat.ViEndTab]
	JAE NxLin3
NxLin4:	DW _MOV_SI_DX
	MOV BX, [ES:ViewDat.ViSpace]
	DEC BX
	DEC BX
	STC
	JMP NxLin6
NxLin5:	CMP [ES:ViewDat.ViLoaded], SI
	JB NxLin4
NxLin6:	POP AX
	POP DX
	RET
;NextLin ENDP

;GLOBAL PrevLin
PrevLin:  ; PROC NEAR  ; Find previous line
	PUSH DX
	PUSH AX
	DW _MOV_DX_SI
	CMP BYTE [ES:ViewDat.ViTxHex], 0
	JZ PrLin1
	AND SI, 0FFF0h
	JE PrLin7
	SUB SI, 10h
	JMP PrLin8
PrLin1:	INC BX
	INC BX
	CMP SI, [BX-2]
	JAE PrLin2
	MOV BX, [ES:ViewDat.ViSpace]
PrLin2:	CMP BX, [ES:ViewDat.ViEndTab]
	JBE PrLin7
	DEC BX
	DEC BX
	CMP SI, [BX]
	JE PrLin3
	JA PrLin2
	INC BX
	INC BX
PrLin3:	CMP WORD [BX], 0
	JE PrLin7
	INC BX
	INC BX
	MOV SI, [BX]
	CMP BYTE [ES:ViewDat.ViWrap], 0
	JNZ PrLin8
	DEC BX
	DEC BX
PrLin4:	MOV SI, [BX]
	DW _OR_SI_SI
	JE PrLin8
	CALL IsCrLf0
	JE PrLin5
	INC BX
	INC BX
	JMP PrLin4
PrLin5:	INC BX
	INC BX
PrLin6:	MOV SI, [BX]
	DW _OR_SI_SI
	JE PrLin8
	CALL IsCrLf0
	JE PrLin8
	INC BX
	INC BX
	JMP PrLin6
PrLin7:	DW _MOV_SI_DX
	MOV BX, [ES:ViewDat.ViSpace]
	DEC BX
	DEC BX
	STC
PrLin8:	POP AX
	POP DX
	RET
;PrevLin ENDP

;GLOBAL V20_00
V20_00:  ; PROC NEAR  ; Find first line of screen
	PUSH AX
	MOV SI, [ES:ViewDat.ViFirst]
	CMP BYTE [ES:ViewDat.ViTxHex], 0
	JNZ V20_04
	MOV BX, [ES:ViewDat.ViPoint]
	INC BX
	INC BX
	CMP SI, [BX-2]
	JAE V20_01
	MOV BX, [ES:ViewDat.ViSpace]
V20_01:	CMP BX, [ES:ViewDat.ViEndTab]
	JBE V20_02
	DEC BX
	DEC BX
	CMP SI, [BX]
	JAE V20_01
	INC BX
	INC BX
V20_02:	MOV SI, [BX]
	CMP BYTE [ES:ViewDat.ViWrap], 0
	JNZ V20_05
V20_03:	MOV SI, [BX]
	DW _OR_SI_SI
	JE V20_05
	CALL IsCrLf0
	JE V20_05
	INC BX
	INC BX
	JMP V20_03
V20_04:	AND SI, 0FFF0h
	MOV BX, [ES:ViewDat.ViSpace]
	DEC BX
	DEC BX
V20_05:	MOV [ES:ViewDat.ViPoint], BX
	POP AX
	RET
;V20_00 ENDP

;GLOBAL V25_00
V25_00:  ; PROC NEAR  ; Output status line
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	PUSH ES
	POP DS
	MOV BYTE [ViewDat.Vi100pc], 0
	CMP BYTE [ViewDat.ViStatus], 0
;JZ	V25_05
	JNZ JSV25_05  ; !! SHORT would fit.
	JMP STRICT NEAR V25_05
JSV25_05:
	MOV DI, MD.TmpBuf  ; Col nnn
	PUSH DI
	DW _XOR_CX_CX
	CMP [ViewDat.ViTxHex], CL
	JNZ V25_01
	MOV CX, [ViewDat.ViCol]
V25_01:	DW _XOR_BX_BX
	MOV AL, 1
	CALL Number
	POP SI
	MOV DI, MD.ScrBuf+2*44
	PUSH DI
	MOV AX, [DI]
	MOV AL, ' '
	MOV CX, 7
	REP STOSW
	POP DI
	CALL MovDz0
	DW _XOR_DX_DX  ; %
	DW _XOR_SI_SI
	DW _XOR_DI_DI
	MOV AX, [ViewDat.ViOffset+0]
	MOV BX, [ViewDat.ViOffset+2]
	ADD AX, [ViewDat.ViFirst]
	DW _ADC_BX_SI
	MOV CX, 100
V25_02:	DW _ADD_DX_AX
	DW _ADC_SI_BX
	ADC DI, 0
	LOOP V25_02
	MOV AX, [ViewDat.ViLen+0]
	MOV BX, [ViewDat.ViLen+2]
	DW _MOV_CX_AX
	DW _OR_CX_BX
	JE V25_04
	MOV CX, 0FFFFh
V25_03:	INC CX
	DW _SUB_DX_AX
	DW _SBB_SI_BX
	SBB DI, 0
	JNB V25_03
V25_04:	DW _XOR_BX_BX
	MOV DI, MD.TmpBuf
	MOV AL, 3
	CALL Number
	MOV SI, MD.TmpBuf+10
	MOV BX, 75
	CALL MovDz
	DW _XOR_BX_BX
	MOV DX, 150h
	CALL Window
V25_05:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;V25_00 ENDP

;GLOBAL V30_00
V30_00:  ; PROC NEAR  ; Output screen
	PUSH BP
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV BX, [ES:ViewDat.ViBase]
	CALL BasAdr
	MOV CL, [ES:ViewDat.ViSize+1]  ; Clear view window
	MOV CH, 0
	PUSH CX
	MOV AL, 0
V30_01:	PUSH CX
	CALL T70_00
	POP CX
	INC AX
	LOOP V30_01
	POP CX
	MOV AL, 0
	CALL V20_00
	DW _MOV_BP_SI
V30_02:	DW _MOV_SI_BP
	CALL NextLin
	DW _XCHG_BP_SI
	JC V30_03
	CALL V32_00
	INC AX
	LOOP V30_02
	JMP V30_05
V30_03:	MOV BP, [ES:ViewDat.ViLoaded]
	CALL V40_00
	JNC V30_04
	DW _CMP_SI_BP
	JAE V30_04
	DEC BP
	MOV AH, [DS:BP]
	CMP AH, 0Dh
	JE V30_04
	CMP AH, 0Ah
	JE V30_04
	INC BP
V30_04:	CALL V32_00
	STC
V30_05:	PUSHF
	MOV BX, [ES:ViewDat.ViBase]
	MOV DX, [ES:ViewDat.ViSize]
	CALL Window
	POPF
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP BP
	RET
;V30_00 ENDP

;GLOBAL V31_00
V31_00:  ; PROC NEAR  ; Clear line
	CALL BasAdr
	MOV CL, [EdData.EdSize+0]
	MOV CH, 0
	MOV AH, Back_C
	CALL Color
	MOV AL, ' '
	REP STOSW
	RET
;V31_00 ENDP

;GLOBAL V32_00
V32_00:  ; PROC NEAR  ; Output line #AL
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV BX, [ES:ViewDat.ViBase]
	DW _ADD_BH_AL
	CALL BasAdr
	MOV CX, 0FFFFh
	MOV AX, [ES:ViewDat.ViSearch+0]
	MOV BX, [ES:ViewDat.ViSearch+2]
	ADD AX, STRICT WORD 1
	ADC BX, 0
	SUB AX, [ES:ViewDat.ViOffset+0]
	SBB BX, [ES:ViewDat.ViOffset+2]
	JNE V32_01
	DW _MOV_CX_AX
	DW _MOV_DX_AX
	ADD DL, [ES:ViewDat.ViSrLen]
	ADC DH, 0
	DEC DX
V32_01:	MOV [ES:ViewDat.ViTmp1], CX
	MOV [ES:ViewDat.ViTmp2], DX
	CMP BYTE [ES:ViewDat.ViTxHex], 0
	JZ V32_02
	JMP V32_10
V32_02:	DW _XOR_DX_DX  ; Text view
	DW _MOV_AX_BP
	DW _SUB_AX_SI
	JB V32_03
	CMP AX, STRICT WORD 2
	JB V32_03
	DEC BP
	DEC BP
	MOV AX, [DS:BP]
	CALL IsCrLf
	JE V32_03
	INC BP
	INC BP
V32_03:	DW _CMP_SI_BP
	JAE V32_06
	LODSB
	DW _MOV_CX_SI
	DW _MOV_BX_DX
	INC DX
	CMP AL, 9
	JNE V32_04
	MOV AL, ' '
	TEST DL, 7
	JZ V32_04
	DEC SI
V32_04:	SUB BX, [ES:ViewDat.ViCol]
	JB V32_03
	CMP BL, [ES:ViewDat.ViSize+0]
	JAE V32_05
	DW _ADD_BX_BX
	MOV [ES:DI+BX], AL
	CMP CX, [ES:ViewDat.ViTmp1]
	JB V32_03
	CMP CX, [ES:ViewDat.ViTmp2]
	JA V32_03
	CMP BYTE [ES:ViewDat.ViSrPan], 0
	JZ V32_03
	MOV AH, Cursr_C
	CALL Color
	MOV [ES:DI+BX], AX
	JMP V32_03
V32_05:	MOV BL, [ES:ViewDat.ViSize+0]
	MOV BH, 0
	DW _ADD_BX_BX
	MOV AH, Arrow_C
	CALL Color
	MOV AL, 1Ah
	MOV [ES:DI+BX-2], AX
V32_06:	CMP WORD [ES:ViewDat.ViCol], 0
	JE V32_07
	MOV AH, Arrow_C
	CALL Color
	MOV AL, 1Bh
	MOV [ES:DI], AX
V32_07:	JMP V32_16
V32_10:	MOV BX, [ES:ViewDat.ViOffset+0]  ; Hex view
	MOV CX, [ES:ViewDat.ViOffset+2]
	DW _ADD_BX_SI
	ADC CX, 0
	INC DI
	INC DI
	DW _MOV_AL_CH
	CALL HexByt
	DW _MOV_AL_CL
	CALL HexByt
	DW _MOV_AL_BH
	CALL HexByt
	DW _MOV_AL_BL
	CALL HexByt
	ADD DI, 4  ; Bytes
	LEA BX, [DI+2*52]
	MOV CX, 16
	MOV AH, Cursr_C
	CALL Color
V32_11:	DW _CMP_SI_BP
	JAE V32_16
	LODSB
	MOV [ES:BX], AL
	CMP AL, 0
	JNE V32_12
	MOV BYTE [ES:BX], '.'
V32_12:	INC BX
	INC BX
	CALL HexByt
	INC DI
	INC DI
	CMP SI, [ES:ViewDat.ViTmp1]
	JB V32_14
	CMP SI, [ES:ViewDat.ViTmp2]
	JA V32_14
	CMP BYTE [ES:ViewDat.ViSrPan], 0
	JZ V32_13
	MOV [ES:BX-1], AH
	JMP V32_14
V32_13:	MOV [ES:DI-3], AH
	MOV [ES:DI-5], AH
	CMP SI, [ES:ViewDat.ViTmp1]
	JE V32_14
	CMP CL, 16
	JAE V32_14
	MOV [ES:DI-7], AH
	MOV [ES:DI-9], AH
V32_14:	DW _MOV_AL_CL
	AND AL, 3
	CMP AL, 1
	JNE V32_15
	INC DI
	INC DI
V32_15:	LOOP V32_11
V32_16:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	RET
;V32_00 ENDP

;GLOBAL V40_00
V40_00:  ; PROC NEAR  ; Test 100%
	PUSH DS
	PUSH DX
	PUSH BX
	PUSH AX
	PUSH ES
	POP DS
	MOV AX, [ViewDat.ViOffset+0]
	MOV BX, [ViewDat.ViOffset+2]
	ADD AX, [ViewDat.ViLoaded]
	ADC BX, 0
	CMP BX, [ViewDat.ViLen+2]
	JA V40_01
	JB V40_02
	CMP AX, [ViewDat.ViLen+0]
	JB V40_02
V40_01:	MOV BYTE [ViewDat.Vi100pc], 1
	CMP BYTE [ViewDat.ViStatus], 0
	JZ V40_02
	MOV BYTE [MD.ScrBuf+2*75], '1'
	MOV BYTE [MD.ScrBuf+2*76], '0'
	MOV BYTE [MD.ScrBuf+2*77], '0'
	MOV BX, 75
	MOV DX, 103h
	CALL Window
	CLC
V40_02:	POP AX
	POP BX
	POP DX
	POP DS
	RET
;V40_00 ENDP

;GLOBAL V50_00
V50_00:  ; PROC NEAR  ; Read next part
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV DX, [ES:ViewDat.ViSpace]
	SHR DX, 1
	ADD [ES:ViewDat.ViOffset+0], DX
	ADC WORD [ES:ViewDat.ViOffset+2], 0
	SUB [ES:ViewDat.ViFirst], DX
	MOV SI, [ES:ViewDat.ViSpace]
	DEC SI
	DEC SI
	DW _MOV_DI_SI
	MOV WORD [DI], 0
V50_01:	CMP SI, [ES:ViewDat.ViEndTab]
	JB V50_02
	MOV AX, [SI]
	DEC SI
	DEC SI
	DW _SUB_AX_DX
	JBE V50_01
	DEC DI
	DEC DI
	MOV [DI], AX
	JMP V50_01
V50_02:	MOV [ES:ViewDat.ViEndTab], DI
	DW _MOV_SI_DX
	MOV AX, [ES:ViewDat.ViLen+0]
	MOV BX, [ES:ViewDat.ViLen+2]
	SUB AX, [ES:ViewDat.ViOffset+0]
	SBB BX, [ES:ViewDat.ViOffset+2]
	JNE V50_03
	DW _CMP_DI_AX
	JBE V50_03
	DW _MOV_DI_AX
V50_03:	MOV CX, [ES:ViewDat.ViLoaded]
	MOV [ES:ViewDat.ViLoaded], DI
	MOV BX, [ES:ViewDat.ViEndTab]
	PUSH ES
	PUSH DS
	POP ES
	DW _XOR_DI_DI
	DW _SUB_CX_SI
	JE V50_04
	REP MOVSB
V50_04:	POP ES
	DW _MOV_CX_BX
	DW _SUB_CX_DI
	MOV BX, [ES:ViewDat.ViHandle]
	PUSH DI
	PUSH CX
	MOV SI, [ES:ViewDat.ViOffset+0]
	DW _ADD_SI_DI
	MOV DI, [ES:ViewDat.ViOffset+2]
	ADC DI, 0
	DW _MOV_DX_SI
	DW _MOV_CX_DI
	MOV AX, 4200h
	CALL Intr21
	DW _CMP_AX_SI
	POP CX
	POP AX
	JNE V50_05
	DW _CMP_DX_DI
	JNE V50_05
	DW _MOV_DX_AX
	CALL V55_00
V50_05:	MOV DI, [ES:ViewDat.ViEndTab]
	MOV SI, [DI]
	INC DI
	INC DI
	CALL V60_00
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	RET
;V50_00 ENDP

;GLOBAL V51_00
V51_00:  ; PROC NEAR  ; Read previous part
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV DX, [ES:ViewDat.ViSpace]
	SHR DX, 1
	CMP WORD [ES:ViewDat.ViOffset+2], 0
	JNE V51_01
	MOV AX, [ES:ViewDat.ViOffset+0]
	DW _CMP_DX_AX
	JBE V51_01
	DW _MOV_DX_AX
V51_01:	SUB [ES:ViewDat.ViOffset+0], DX
	SBB WORD [ES:ViewDat.ViOffset+2], 0
	ADD [ES:ViewDat.ViFirst], DX
	MOV BX, [ES:ViewDat.ViSpace]
	MOV AX, [ES:ViewDat.ViLoaded]
	DW _ADD_AX_DX
	JC V51_02
	DW _CMP_AX_BX
	JAE V51_02
	DW _MOV_BX_AX
V51_02:	MOV [ES:ViewDat.ViLoaded], BX
	MOV DI, [ES:ViewDat.ViSpace]
	DW _MOV_BX_DI
	DW _XOR_CX_CX
	DEC BX
	DEC BX
	CMP BX, [ES:ViewDat.ViEndTab]
	JBE V51_03
	MOV CX, [BX-2]
V51_03:	DW _ADD_CX_DX
	PUSH CX
	DW _MOV_SI_DI
	DW _SUB_SI_DX
	DW _MOV_CX_SI
	DEC SI
	DEC DI
	PUSH ES
	PUSH DS
	POP ES
	STD
	REP MOVSB
	POP ES
	CLD
	PUSH DX
	MOV BX, [ES:ViewDat.ViHandle]
	MOV SI, [ES:ViewDat.ViOffset+0]
	MOV DI, [ES:ViewDat.ViOffset+2]
	DW _MOV_DX_SI
	DW _MOV_CX_DI
	MOV AX, 4200h
	CALL Intr21
	POP CX
	DW _CMP_AX_SI
	JNE V51_04
	DW _CMP_DX_DI
	JNE V51_04
	DW _XOR_DX_DX
	CALL V55_00
V51_04:	DW _XOR_SI_SI
	MOV DI, [ES:ViewDat.ViSpace]
	CALL V60_00
	POP SI
V51_05:	CMP DI, [ES:ViewDat.ViEndTab]
	JBE V51_06
	DEC DI
	DEC DI
	CMP SI, [DI]
	JE V51_06
	JA V51_05
	INC DI
	INC DI
	CALL V60_00
V51_06:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	RET
;V51_00 ENDP

;GLOBAL V55_00
V55_00:  ; PROC NEAR  ; Read block
	PUSH ES
	PUSH DI
	PUSH CX
	PUSH DS
	POP ES
	DW _MOV_DI_DX
	MOV AL, 0
	REP STOSB
	POP CX
	POP DI
	POP ES
	MOV AH, 3Fh
	CALL Intr21
	RET
;V55_00 ENDP

;GLOBAL V60_00
V60_00:  ; PROC NEAR  ; Format text
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH BX
	PUSH AX
	MOV DX, [ES:ViewDat.ViLoaded]
V60_01:	DW _XOR_BX_BX
	DW _CMP_SI_DI
	JAE V60_02
	DEC DI
	DEC DI
	MOV [DI], SI
	DW _CMP_DI_DX
	JAE V60_03
V60_02:	DW _MOV_DX_DI
V60_03:	DW _CMP_SI_DX
	JAE V60_06
	LODSW
	DW _CMP_SI_DX
	JA V60_04
	CALL IsCrLf
	JE V60_01
V60_04:	DEC SI
	CMP AL, 9
	JNE V60_05
	OR BL, 7
V60_05:	INC BX
	CMP BX, 80
	JB V60_03
	JA V60_01
	MOV AX, [SI]
	CALL IsCrLf
	JE V60_03
	DW _CMP_SI_DX
	JB V60_01
V60_06:	MOV [ES:ViewDat.ViLoaded], DX
	MOV [ES:ViewDat.ViEndTab], DI
	MOV AX, [ES:ViewDat.ViSpace]
	DEC AX
	DEC AX
	MOV [ES:ViewDat.ViPoint], AX
	POP AX
	POP BX
	POP DX
	POP DI
	POP SI
	RET
;V60_00 ENDP

;GLOBAL V80_00
V80_00:  ; PROC NEAR
	PUSH DS
	PUSH ES
	POP DS
	MOV BX, 528h
	MOV BP, SrFor_P
	CALL DialBox
	CALL Window
	CALL V81_00
	POP DS
	RET
;V80_00 ENDP

;GLOBAL V81_00
V81_00:  ; PROC NEAR
	PUSH SI
	MOV SI, MD.SrchStr
	MOV DI, MD.HelpBuf
	MOV CX, LenStr+1
	PUSH DI
	CALL MvzLine
	POP SI
	CALL PathLin
	DW _SUB_DI_SI
	MOV [SI+90], DI
	MOV WORD [HexLen], 0
	CMP BYTE [ViewDat.ViTxHex], 0
	JZ V81_04
	MOV SI, MD.SrchStr
	MOV DI, MD.HelpBuf+100
V81_01:	LODSB
	CMP AL, ' '
	JE V81_01
	CMP AL, 0
	JE V81_05
	CALL TstHex
	JC V81_04
	MOV [DI], AL
	INC WORD [HexLen]
	LODSB
	CMP AL, 0
	JE V81_05
	CALL TstHex
	JC V81_02
	MOV AH, [DI]
	MOV CL, 4
	SHL AH, CL
	DW _ADD_AL_AH
	MOV [DI], AL
	INC SI
V81_02:	DEC SI
	INC DI
V81_03:	LODSB
	CMP AL, ' '
	JE V81_03
	CMP AL, ','
	JE V81_01
	DEC SI
	JMP V81_01
V81_04:	MOV WORD [HexLen], 0
V81_05:	POP SI
	RET
;V81_00 ENDP

;GLOBAL V82_00
V82_00:  ; PROC NEAR  ; Search
	PUSH DX
	PUSH CX
	PUSH BX
	MOV DX, [ES:MD.HelpBuf+90]
	SUB DX, [ES:HexLen]
	SUB CX, [ES:MD.HelpBuf+90]
	JAE V82_01
	DW _ADD_DX_CX
	CMC
	JC V82_07
	DW _XOR_CX_CX
	INC DX
	JMP V82_06
V82_01:	INC CX
V82_02:	PUSH CX
	DW _MOV_BX_SI
	MOV DI, MD.HelpBuf
	MOV CX, [ES:DI+90]
V82_03:	LODSB
	CALL UpCase
	SCASB
	LOOPE V82_03
	MOV AL, 1
	JE V82_05
	DW _MOV_SI_BX
V82_04:	MOV DI, MD.HelpBuf+100
	MOV CX, [ES:DI+90]
	JCXZ V82_05
	REPE CMPSB
	MOV AL, 0
V82_05:	POP CX
	JE V82_07
	LEA SI, [BX+1]
	LOOP V82_02
V82_06:	SUB DX, 1
	JC V82_07
	INC CX
	PUSH CX
	DW _MOV_BX_SI
	JMP V82_04
V82_07:	POP BX
	POP CX
	POP DX
	RET
;V82_00 ENDP

T00_00:	DW _MOV_BP_BX
	DW _MOV_DI_AX
	MOV AX, ES
	ADD AX, [MD.FreMem2]
	SUB AX, [MD.ViewSeg]
	MOV [EdData.EdSpace], AX
	DW _MOV_BL_AH
	MOV BH, 0
	DW _XCHG_BX_DI
	MOV CL, 4
	SHL AX, CL
	SHR DI, CL
	CMP DI, [EdData.EdLen+2]
	JB T00_01
	JA T00_03
	CMP AX, [EdData.EdLen+0]
	JA T00_03
T00_01:	PUSH BP  ; File too large
	MOV BP, BigFi_B
	CALL Dialog
	POP BP
	JE T00_02
	JMP T00_10
T00_02:	PUSH CS
	POP DS
	INC BH
	MOV BL, 37
	MOV SI, ViFl_S
	CALL MovDz
	PUSH ES
	POP DS
	MOV DX, 106h
	CALL Window
	DW _MOV_BX_BP
	JMP V00_10
T00_03:	MOV SI, MD.ViewFil  ; Extension or menu file ?
	CALL CutPath
	MOV DI, MD.TmpBuf
	MOV CX, 13
	PUSH DI
	CALL MvzLine
	STOSB
	POP SI
	CALL PathLin
	DW _MOV_CX_DI
	DW _SUB_CX_SI
	DW _MOV_DI_SI
	PUSH CS
	POP DS
	MOV AX, 0A01h
	MOV SI, Menu_F
	CALL T64_00
	JE T00_04
	MOV AL, 2
	MOV SI, Ext_F
	CALL T64_00
	JE T00_04
	MOV SI, ViewE_F
	CALL T64_00
	JE T00_04
	MOV SI, EditE_F
	CALL T64_00
	JE T00_04
	DW _XOR_AX_AX
T00_04:	PUSH ES
	POP DS
	MOV [EditBuf_EdHelp], AL
	SUB [EdData.EdSize+1], AH
	CMP BP, 0FFFFh  ; New file ?
	JNE T00_06
	MOV AL, [MD.Lines]
	SUB AL, 2
	CMP AL, [EdData.EdSize+1]
	JA T00_05
	MOV BP, NewFi_B
	CALL Dialog
	JNE T00_10
T00_05:	JMP T00_13
T00_06:	PUSH DX  ; Read file
	PUSH BX
	DW _MOV_BX_BP
	MOV SI, [EdData.EdLen+0]
	MOV DI, [EdData.EdLen+2]
	MOV DS, [MD.ViewSeg]
T00_07:	MOV CX, 0FF00h
	DW _OR_DI_DI
	JNE T00_08
	DW _CMP_SI_CX
	JAE T00_08
	DW _MOV_CX_SI
T00_08:	DW _XOR_DX_DX
	MOV AH, 3Fh
	CALL Intr21
	JC T00_09
	CALL TstBrk
	JC T00_09
	DW _CMP_AX_CX
	JNE T00_11
	MOV AX, DS
	ADD AX, STRICT WORD 0FF0h
	MOV DS, AX
	DW _SUB_SI_CX
	SBB DI, 0
	DW _MOV_AX_SI
	DW _OR_AX_DI
	JNE T00_07
	JMP T00_12
T00_09:	POP BX
	POP DX
T00_10:	MOV SI, MD.WinBuf
	CALL ResWin
	CALL Window
	JMP V13_00
T00_11:	DW _SUB_SI_AX
	SBB DI, 0
	SUB [ES:EdData.EdLen+0], SI
	SBB [ES:EdData.EdLen+2], DI
T00_12:	MOV AH, 3Eh
	CALL Intr21
	POP BX
	POP DX
T00_13:	MOV SI, MD.WinBuf
	CALL ResWin
	CALL Window
	PUSH ES
	POP DS
	MOV AL, 0
	CMP BYTE [EdData.EdSize+0], 79
	JB T00_14
	MOV DI, MD.ScrBuf  ; Status line
	MOV AH, Menu_C
	CALL Color
	MOV AL, ' '
	MOV CX, 80
	REP STOSW
	PUSH CS
	POP DS
	MOV SI, EdFl_S+1
	DW _XOR_BX_BX
	CALL MovDz
	DEC DI
	DEC DI
	MOV AL, ':'
	STOSB
	MOV SI, Line_S
	MOV BX, 41
	CALL MovDz
	MOV SI, Col_S
	MOV BL, 52
	CALL MovDz
	MOV SI, FrBuf_S
	MOV BL, 70
	CALL MovDz
	PUSH ES
	POP DS
	CALL T74_00
	MOV AL, 1
T00_14:	MOV [EdData.EdStat], AL
	CMP BYTE [EditBuf_EdHelp], 0  ; Mini Help
	JE T00_16
	MOV BP, EdtH_P
	MOV BX, [EdData.EdBase]
	ADD BH, [EdData.EdSize+1]
	CALL BasAdr
	MOV AH, HlBrd_C
	CALL Color
	MOV CX, 80
	PUSH CX
	PUSH AX
	MOV AL, 'Ü'
	REP STOSW
	MOV AH, [CS:BP]
	CALL Color
	MOV CX, 1
	MOV DX, 76
	MOV SI, 6
	CALL BoxDubl
	POP AX
	POP CX
	MOV AL, 'ß'
	REP STOSW
	MOV SI, EdtH1_S
	CMP BYTE [EditBuf_EdHelp], 1
	JE T00_15
	MOV SI, EdtH2_S
T00_15:	PUSH CS
	POP DS
	PUSH BX
	INC BH
	MOV BL, 40
	CALL CntLine
	INC BH
	MOV BL, 3
	CALL T76_00
	MOV SI, EdtH_S
	MOV BL, 46
	CALL T76_00
	PUSH ES
	POP DS
	POP BX
	MOV DX, 0A50h
	CALL Window
T00_16:	DW _XOR_AX_AX  ; Init vars
	MOV [MD.Quote], AL
	MOV [EdData.EdWrite], AL
	MOV [EdData.EdHexAs], AL
	MOV [EdData.EdHxCur], AL
	MOV [EdData.EdTxHex], AL
	MOV [EdData.EdChng], AL
	MOV [EdData.EdUpDwn], AL
	MOV [EdData.EdCurLn], AL
	MOV [EdData.EdLine], AX
	MOV [EdData.EdCol0], AX
	MOV [EdData.EdLin0], AX
	MOV [EdData.EdFirst+0], AX
	MOV [EdData.EdFirst+2], AX
	MOV [EdData.EdOffst+0], AX
	MOV [EdData.EdOffst+2], AX
	MOV [EdData.EdCursr], AX
	MOV [EdData.EdUndo], AX
	MOV [MD.Clock], AL
	MOV BYTE [MD.KeyBar], 1
	MOV BYTE [EdData.EdScrn], 1
	MOV BYTE [MD.HlpPage], 5
	CALL T50_00
	CALL ChgCur
	MOV [EdData.EdShape], CX

T00_20:	CALL T57_02  ; Screen
	PUSH ES
	POP DS
	MOV BH, 0
	MOV [EdData.EdCol], AX
	CMP [EdData.EdUpDwn], BH
	JNZ T00_21
	MOV [EdData.EdCol1], AX
	MOV DL, [EdData.EdHxCur]
	MOV [EdData.EdHex1], DL
T00_21:	MOV [EdData.EdUpDwn], BH
	MOV DX, [EdData.EdLine]
	MOV SI, [EdData.EdCol0]
	MOV DI, [EdData.EdLin0]
	CMP [EdData.EdTxHex], BH
	JNZ T00_24
	DW _CMP_AX_SI
	JB T00_22
	JA T00_23
	DW _OR_SI_SI
	JE T00_24
T00_22:	DW _MOV_SI_AX
	DW _OR_AX_AX
	JE T00_24
	DEC SI
	JMP T00_24
T00_23:	MOV BL, [EdData.EdSize+0]
	DEC BX
	LEA CX, [BX+SI]
	DW _CMP_AX_CX
	JB T00_24
	DEC BX
	DW _MOV_SI_AX
	DW _SUB_SI_BX
T00_24:	DW _CMP_DX_DI
	JAE T00_25
	DW _MOV_DI_DX
	JMP T00_26
T00_25:	MOV BL, [EdData.EdSize+1]
	LEA CX, [BX+DI]
	DW _CMP_DX_CX
	JB T00_26
	DEC BX
	DW _MOV_DI_DX
	DW _SUB_DI_BX
	JAE T00_26
	DW _XOR_DI_DI
T00_26:	DW _MOV_CX_DI
	XCHG SI, [EdData.EdCol0]
	XCHG DI, [EdData.EdLin0]
	DW _SUB_CX_DI
	JE T00_33
	PUSH SI
	PUSH CX
	PUSHF
	MOV AX, [EdData.EdLine]
	SUB AX, [EdData.EdLin0]
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	CALL T61_00
	DW _XOR_DI_DI
	POPF
	JB T00_28
	DW _CMP_CX_AX
	JA T00_29
	CALL T62_00
T00_27:	CALL T53_00
	LOOP T00_27
	JMP T00_31
T00_28:	DW _XOR_BX_BX
	DW _XOR_DX_DX
	CMP [ES:EdData.EdLin0], BX
	JE T00_32
	NEG CX
	DW _CMP_CX_AX
	JA T00_29
	DW _MOV_AX_CX
	CALL T62_00
T00_29:	DW _MOV_CX_AX
	JCXZ T00_31
	DEC DI
T00_30:	CALL T54_00
	LOOP T00_30
T00_31:	CALL T60_00
T00_32:	PUSH ES
	POP DS
	MOV [EdData.EdFirst+0], BX
	MOV [EdData.EdFirst+2], DX
	POP CX
	POP SI
T00_33:	CMP BYTE [EdData.EdScrn], 0
	JNZ T00_38
	CMP SI, [EdData.EdCol0]
	JNE T00_40
	JCXZ T00_36
	MOV BX, [EdData.EdBase]
	CMP CX, 1
	JNE T00_34
	MOV AH, 6
	MOV DX, 2*80
	JMP T00_35
T00_34:	CMP CX, -1
	JNE T00_40
	ADD BH, [EdData.EdSize+1]
	DEC BH
	MOV AH, 7
	MOV DX, -2*80
T00_35:	MOV AL, 0
	CALL T71_00
	MOV BYTE [EdData.EdCurLn], 0
T00_36:	CMP BYTE [EdData.EdCurLn], 0
	JNZ T00_37
	CALL T73_00
T00_37:	JMP T00_49

T00_38:	MOV CL, [ES:EdData.EdSize+1]  ; Clear edit window
	MOV CH, 0
	MOV AL, 0
T00_39:	PUSH CX
	CALL T70_00
	POP CX
	INC AX
	LOOP T00_39

T00_40:	CALL ClrKbd  ; Output screen
	MOV CL, [EdData.EdSize+1]
	MOV CH, 0
	MOV AL, 0
	CALL T62_00
	DW _MOV_BP_SI
T00_41:	DW _MOV_SI_BP
	CALL T63_00
	JE T00_45
	JC T00_46
	CALL T53_10
	JNC T00_43
	DW _MOV_SI_BP
	CALL T60_00
	CALL T61_00
	DW _MOV_BP_SI
	CALL T53_10
	JNC T00_43
	DW _MOV_SI_BP
	MOV BP, 0FFFFh
	CALL T72_00
T00_42:	MOV SI, DS
	ADD SI, 0FF0h
	MOV DS, SI
	DW _XOR_SI_SI
	CALL T53_10
	JC T00_42
	DW _XCHG_BP_SI
	JMP T00_44
T00_43:	DW _XCHG_BP_SI
	CALL T72_00
T00_44:	INC AX
	LOOP T00_41
	JMP T00_48
T00_45:	CMP BYTE [ES:EdData.EdTxHex], 0
	JNZ T00_46
	CALL T60_00
	SUB BX, 2
	SBB DX, 0
	JB T00_48
	CALL T61_00
	PUSH AX
	CALL IsCrLfS
	POP AX
	JMP T00_47
T00_46:	CMP BYTE [ES:EdData.EdTxHex], 0
	JZ T00_48
	TEST SI, 0Fh
T00_47:	JNE T00_48
	DW _XOR_BP_BP
	CALL T72_00
T00_48:	PUSH ES
	POP DS
	CALL T73_10
	MOV BX, [EdData.EdBase]
	MOV DX, [EdData.EdSize]
	CALL Window
T00_49:	MOV BYTE [EdData.EdScrn], 0
	MOV BYTE [EdData.EdCurLn], 0

	CMP BYTE [EdData.EdStat], 0  ; Status line
	JNZ T00_51
	JMP T00_60
T00_51:	MOV SI, MD.ScrBuf
	MOV DI, MD.TmpErr
	MOV CX, 80
	PUSH SI
	PUSH DI
	PUSH CX
	REP MOVSW
	MOV AL, ' '
	CMP [EdData.EdChng], CL
	JZ T00_52
	MOV AL, '*'
T00_52:	MOV [MD.ScrBuf+2*38], AL
	MOV AL, ' '
	CMP [MD.Quote], CL
	JZ T00_53
	MOV AL, '"'
T00_53:	MOV [MD.ScrBuf+2*39], AL
	MOV AH, [MD.ScrBuf+1]
	MOV CX, [EdData.EdLine]
	MOV DI, MD.ScrBuf+2*46
	CALL T75_00
	MOV CX, [EdData.EdCol]
	MOV DI, MD.ScrBuf+2*56
	CALL T75_00
	PUSH AX
	MOV AX, [EdData.EdSpace]
	ADD AX, [MD.ViewSeg]
	MOV DS, AX
	DW _XOR_SI_SI
	CALL T60_00
	PUSH ES
	POP DS
	SUB BX, [EdData.EdLen+0]
	SBB DX, [EdData.EdLen+2]
	CMP [EdData.EdTxHex], CL
	JNZ T00_54
	MOV AX, [EdData.EdEndBf+0]
	MOV CX, [EdData.EdEndBf+2]
	SUB AX, [EdData.EdOffst+0]
	SBB CX, [EdData.EdOffst+2]
	SUB AX, [EdData.EdSizLn]
	DW _SBB_CX_SI
	DW _ADD_BX_AX
	DW _ADC_DX_CX
	CMP DX, 10h
	JB T00_54
	DW _MOV_BX_SI
	DW _MOV_DX_SI
T00_54:	DW _MOV_CX_BX
	DW _MOV_BX_DX
	MOV DI, MD.TmpBuf
	MOV AL, 3
	CALL Number
	POP AX
	MOV SI, MD.TmpBuf+6
	MOV DI, MD.ScrBuf+2*62
	MOV CX, 7
	CALL MvsBwe
	POP CX
	POP SI
	POP DI
	REPE CMPSW
	JE T00_60
	DW _XOR_BX_BX
	MOV DX, 150h
	CALL Window

T00_60:	MOV CL, 0  ; Cursor
	MOV AX, [EdData.EdCol]
	SUB AX, [EdData.EdCol0]
	CMP [EdData.EdTxHex], CL
	JZ T00_61
	ADD AL, 63
	CMP [EdData.EdHexAs], CL
	JNZ T00_61
	SUB AL, 63
	DW _MOV_DL_AL
	DW _ADD_AL_DL
	DW _ADD_AL_DL
	SHR DL, 1
	SHR DL, 1
	DW _ADD_AL_DL
	ADD AL, 11
	CMP [EdData.EdHxCur], CL
	JZ T00_61
	INC AX
T00_61:	MOV BX, [EdData.EdLine]
	SUB BX, [EdData.EdLin0]
	DW _MOV_AH_BL
	ADD AX, [EdData.EdBase]
	CALL Cursor

T00_70:	CALL GetMous  ; Mouse
	JNZ T00_71
	MOV BYTE [MD.WinMous], 0
	JMP T00_80
T00_71:	CALL ClrKbd
	MOV BYTE [EdData.EdCurLn], 1
	MOV BX, [EdData.EdBase]
	MOV DX, [EdData.EdSize]
	CMP BYTE [MD.WinMous], 0
	JZ T00_73
	DW _CMP_CH_BH
	JAE T00_72
	JMP T09_00
T00_72:	PUSH BX
	DW _ADD_BH_DH
	DW _CMP_CH_BH
	POP BX
	JB T00_73
	JMP T10_00
T00_73:	CALL InWind
	JC T00_70
	MOV BYTE [MD.WinMous], 1
	MOV BYTE [EdData.EdHex1], 0
	DW _SUB_CX_BX
	DW _MOV_AL_CL
	CBW
	CMP BYTE [EdData.EdTxHex], 0
	JNZ T00_74
	ADD AX, [EdData.EdCol0]
	MOV BX, [EdData.EdLine]
	SUB BX, [EdData.EdLin0]
	DW _CMP_CH_BL
	JNE T00_77
	DEC DX
	DW _CMP_CL_DL
	JB T00_77
	MOV CX, 100h
	JMP T06_10
T00_74:	CMP AL, 63
	JAE T00_76
	MOV BYTE [EdData.EdHexAs], 0
	SUB AL, 11
	JB T00_75
	MOV BL, 13
	DIV BL
	SHL AL, 1
	SHL AL, 1
	PUSH AX
	DW _MOV_AL_AH
	CMP AL, 12
	CMC
	SBB AL, 0
	CBW
	MOV BL, 3
	DIV BL
	POP BX
	MOV [EdData.EdHex1], AH
	DW _OR_AL_BL
	CBW
	JMP T00_77
T00_75:	DW _XOR_AX_AX
	JMP T00_77
T00_76:	MOV BYTE [EdData.EdHexAs], 1
	SUB AL, 63
	CMP AL, 16
	JB T00_77
	MOV AL, 15
T00_77:	MOV [EdData.EdCol1], AX
	DW _MOV_CL_CH
	MOV CH, 0
	MOV AX, [EdData.EdLine]
	SUB AX, [EdData.EdLin0]
	DW _SUB_CX_AX
	MOV AL, 1
	JAE T00_78
	NEG CX
	MOV AL, 0
T00_78:	JMP T10_02

T00_80:	MOV CL, 0  ; Input
	MOV AL, 10
	CMP [EdData.EdStat], CL
	JZ T00_81
	MOV AL, 6
	CMP [EdData.EdTxHex], CL
	JNZ T00_81
	INC AX
T00_81:	CALL Input
	CMP [MD.DesqVie], CL
	JNZ T00_82
	CALL ClrKbd
T00_82:	CALL HidCur
	CMP AH, 0FCh
	JE T01_02
	CMP [MD.Quote], CL
	JZ T00_83
	MOV [MD.Quote], CL
	CMP AL, 0
	JE T01_02
	CMP [EdData.EdTxHex], CL
	JZ T01_03
	JMP T01_10
T00_83:	MOV SI, Edit_T
	CALL Case

T01_00:	CMP AL, 0  ; Edit
	JE T01_02
	CMP [EdData.EdTxHex], CL
	JNZ T01_10
	CMP AL, 0Dh  ; ASCII Edit
	JNE T01_01
	JMP T02_00
T01_01:	DW _OR_AH_AH
	JE T01_03
	CMP AL, ' '
	JAE T01_03
T01_02:	JMP T00_20
T01_03:	CMP WORD [EdData.EdSizLn], LenEdit
	JB T01_04
	CALL T51_00
	CALL T50_00
T01_04:	INC WORD [EdData.EdSizLn]
	MOV BX, [EdData.EdCursr]
	ADD BX, EditBuf
	MOV SI, EditBuf+LenEdit-2
	MOV DI, EditBuf+LenEdit-1
	DW _MOV_CX_SI
	DW _SUB_CX_BX
	INC CX
	JCXZ T01_05
	STD
	REP MOVSB
	CLD
T01_05:	MOV [BX], AL
	MOV BYTE [EdData.EdUpdat], 1
	JMP T01_20
T01_10:	MOV BX, [EdData.EdOffst+0]  ; Hex Edit
	MOV DX, [EdData.EdOffst+2]
	ADD BX, [EdData.EdCursr]
	ADC DX, 0
	CALL T61_00
	CMP [ES:EdData.EdHexAs], CL
	JNZ T01_12
	CALL TstHex
	JC T01_02
	MOV AH, 0Fh
	CMP [ES:EdData.EdHxCur], CL
	JNZ T01_11
	MOV CL, 4
	SHL AX, CL
T01_11:	NOT AH
	AND AH, [SI]
	DW _OR_AL_AH
T01_12:	MOV [SI], AL
	CALL T63_01
	JNC T01_15
	CMP BYTE [ES:EdData.EdHexAs], 0
	JNZ T01_13
	AND BYTE [SI], 0F0h
T01_13:	MOV AX, DS
	PUSH ES
	POP DS
	CMP SI, 0Fh
	JB T01_14
	SUB AX, [MD.ViewSeg]
	INC AX
	CMP AX, [EdData.EdSpace]
	JB T01_14
	CALL Beep
	JMP T01_15
T01_14:	ADD WORD [EdData.EdLen+0], 1
	ADC WORD [EdData.EdLen+2], 0
	TEST WORD [EdData.EdLen+0], 0Fh
	JNE T01_15
	MOV AX, [EdData.EdLine]
	SUB AX, [EdData.EdLin0]
	INC AX
	CMP AL, [EdData.EdSize+1]
	JAE T01_15
	INC WORD [EdData.EdLine]
	ADD WORD [EdData.EdOffst+0], 10h
	CALL T73_00
	SUB WORD [EdData.EdOffst+0], 10h
	DEC WORD [EdData.EdLine]
T01_15:	CALL T73_00
T01_20:	PUSH ES
	POP DS
	MOV BYTE [EdData.EdChng], 1
	JMP T06_00

T02_00:	CMP WORD [EdData.EdSizLn], LenEdit-1  ; Enter
	JB T02_01
	CALL T51_00
	CALL T50_00
T02_01:	ADD WORD [EdData.EdSizLn], 2
	MOV BX, [EdData.EdCursr]
	ADD BX, EditBuf
	MOV SI, EditBuf+LenEdit-3
	MOV DI, EditBuf+LenEdit-1
	DW _MOV_CX_SI
	DW _SUB_CX_BX
	INC CX
	JCXZ T02_02
	STD
	REP MOVSB
	CLD
T02_02:	MOV WORD [BX], 0A0Dh
	MOV BYTE [EdData.EdUpdat], 1
	CALL T51_00
T02_03:	CALL T50_00
	CALL T73_00
	MOV AX, [EdData.EdLine]
	SUB AX, [EdData.EdLin0]
	INC AX
	INC AX
	CMP AL, [EdData.EdSize+1]
	JAE T02_04
	DEC AX
	MOV BX, [EdData.EdBase]
	ADD BH, [EdData.EdSize+1]
	DEC BH
	MOV AH, 7
	MOV DX, -2*80
	CALL T71_00
T02_04:	JMP T06_14

T03_00:	CMP BYTE [EdData.EdTxHex], 0  ; Tab
	JZ T03_10
	MOV BX, EdData.EdHexAs
	CALL InvVar
	JMP T00_20
T03_10:	JMP T01_03

T04_00:	MOV BYTE [MD.Quote], 1  ; Quote
	JMP T00_20

T05_00:	DW _XOR_CX_CX  ; Left
	CMP [EdData.EdTxHex], CL
	JZ T05_10
	CMP [EdData.EdHexAs], CL
	JNZ T05_01
	CMP [EdData.EdHxCur], CL
	JZ T05_01
	MOV [EdData.EdHxCur], CL
	JMP T00_20
T05_01:	MOV AL, 0
	CMP [EdData.EdHexAs], CL
	JNZ T05_02
	MOV AL, 1
T05_02:	CMP [EdData.EdCursr], CX
	JE T05_05
	MOV [EdData.EdHxCur], AL
T05_03:	DEC WORD [EdData.EdCursr]
T05_04:	JMP T00_20
T05_05:	MOV AX, [EdData.EdOffst+0]
	OR AX, [EdData.EdOffst+2]
	JE T05_04
	MOV BYTE [EdData.EdHxCur], 1
	JMP T05_11
T05_10:	CMP [EdData.EdCursr], CX
	JNE T05_03
T05_11:	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	MOV DI, [EdData.EdLine]
	CALL T61_00
	CALL T54_00
	JC T05_04
	CALL T51_00
	CALL T60_00
	PUSH ES
	POP DS
	MOV [EdData.EdLine], DI
	MOV [EdData.EdOffst+0], BX
	MOV [EdData.EdOffst+2], DX
	JMP T14_11

T06_00:	DW _XOR_CX_CX  ; Right
	CMP [EdData.EdTxHex], CL
	JZ T06_10
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	MOV DI, [EdData.EdCursr]
	DW _ADD_BX_DI
	DW _ADC_DX_CX
	CALL T63_01
	JC T06_02
	CMP [EdData.EdHexAs], CL
	JNZ T06_01
	CMP [EdData.EdHxCur], CL
	JNZ T06_01
	INC BYTE [EdData.EdHxCur]
	JMP T00_20
T06_01:	MOV [EdData.EdHxCur], CL
	INC DI
	CMP DI, 10h
	JAE T06_14
	MOV [EdData.EdCursr], DI
T06_02:	JMP T00_20
T06_10:	MOV AX, [EdData.EdCursr]
	CMP AX, [EdData.EdSizLn]
	JB T06_11
	CMP [EdData.EdWhole], CL
	JNZ T06_13
	CALL T51_00
	CALL T50_00
T06_11:	CALL T57_02
	CMP AX, LenEdit-100-1
	JAE T06_12
	INC WORD [EdData.EdCursr]
T06_12:	JMP T00_20
T06_13:	DW _OR_CH_CH
	JNZ T06_12
T06_14:	CALL T51_00
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	MOV DI, [EdData.EdLine]
	CALL T61_00
	CALL T53_00
	JC T06_15
	CALL T60_00
	PUSH ES
	POP DS
	MOV [EdData.EdLine], DI
	MOV [EdData.EdOffst+0], BX
	MOV [EdData.EdOffst+2], DX
	MOV WORD [EdData.EdCursr], 0
T06_15:	CALL T50_00
	JMP T00_20

T07_00:	CMP BYTE [EdData.EdTxHex], 0  ; ^Left
	JNZ T08_03
	MOV DI, EditBuf
	MOV DX, [EdData.EdCursr]
	CALL EdSub1
	JMP T08_02

T08_00:	CMP BYTE [EdData.EdTxHex], 0  ; ^Right
	JNZ T08_03
	MOV DI, EditBuf
	MOV DX, [EdData.EdCursr]
	CALL T55_00
	MOV [EdData.EdCursr], DX
T08_01:	CALL T57_00
	MOV DX, [EdData.EdSizLn]
	DW _SUB_DX_CX
	CMP DX, [EdData.EdCursr]
	JAE T08_03
T08_02:	MOV [EdData.EdCursr], DX
T08_03:	JMP T00_20

T09_00:	MOV AL, 0  ; Up
	JMP T10_01

T10_00:	MOV AL, 1  ; Down
T10_01:	MOV CX, 1
T10_02:	CALL T51_00
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	MOV DI, [EdData.EdLine]
	CALL T61_00
	JCXZ T10_06
T10_03:	CMP AL, 0
	JNZ T10_04
	CALL T54_00
	JMP T10_05
T10_04:	CALL T53_00
T10_05:	JC T10_06
	LOOP T10_03
T10_06:	CALL T60_00
	PUSH ES
	POP DS
	MOV [EdData.EdLine], DI
	MOV [EdData.EdOffst+0], BX
	MOV [EdData.EdOffst+2], DX
	MOV BYTE [EdData.EdUpDwn], 1
	MOV DX, [EdData.EdCol1]
	DW _XOR_CX_CX
	CMP [EdData.EdTxHex], CL
	JNZ T10_10
	INC DX
	JMP T14_12
T10_10:	MOV [EdData.EdCursr], DX
	MOV AL, [EdData.EdHex1]
	MOV [EdData.EdHxCur], AL
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	CALL T61_00
	CALL T53_10
	PUSH ES
	POP DS
	JC T10_11
	TEST SI, 0Fh
	JZ T10_12
T10_11:	AND SI, 0Fh
	CMP SI, [EdData.EdCursr]
	JA T10_12
	MOV [EdData.EdCursr], SI
	MOV [EdData.EdHxCur], CL
T10_12:	JMP T00_20

T11_00:	MOV AL, 0  ; PgUp
	JMP T12_01

T12_00:	MOV AL, 1  ; PgDn
T12_01:	CALL T51_00
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	MOV DI, [EdData.EdLine]
	MOV CL, [EdData.EdSize+1]
	MOV CH, 0
	DEC CX
	CALL T61_00
	MOV BX, [ES:EdData.EdLine]
	SUB BX, [ES:EdData.EdLin0]
	CMP AL, 0
	JNZ T12_02
	DW _OR_BX_BX
	JE T12_03
	DW _MOV_CX_BX
	JMP T12_03
T12_02:	DW _CMP_CX_BX
	JBE T12_03
	DW _SUB_CX_BX
T12_03:	CMP AL, 0
	JNZ T12_04
	CALL T54_00
	JMP T12_05
T12_04:	CALL T53_00
T12_05:	JC T12_06
	LOOP T12_03
T12_06:	DW _XOR_CX_CX
	CMP DI, [ES:EdData.EdLine]
	JE T12_07
	CALL T60_00
	PUSH ES
	POP DS
	MOV [EdData.EdLine], DI
	MOV [EdData.EdOffst+0], BX
	MOV [EdData.EdOffst+2], DX
	MOV [EdData.EdCursr], CX
	MOV [EdData.EdHxCur], CL
T12_07:	CALL T50_00
	JMP T00_20

T13_00:	MOV WORD [EdData.EdCursr], 0  ; Home
	MOV BYTE [EdData.EdHxCur], 0
	JMP T00_20

T14_00:	DW _XOR_CX_CX  ; End
	CMP [EdData.EdTxHex], CL
	JZ T14_10
	MOV [EdData.EdHxCur], CL
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	CALL T61_00
	CALL T53_10
	JC T14_01
	AND SI, 0Fh
	JNZ T14_01
	MOV SI, 0Fh
	INC BYTE [ES:EdData.EdHxCur]
T14_01:	MOV [ES:EdData.EdCursr], SI
T14_02:	JMP T00_20
T14_10:	CALL T57_00
	JAE T14_13
	CMP BYTE [EdData.EdWhole], 0
	JNZ T14_13
	CALL T51_00
T14_11:	CMP BYTE [EdData.EdTxHex], 0
	JNZ T14_00
	MOV DX, LenEdit-100
T14_12:	CALL T50_00
	CALL T57_01
T14_13:	MOV AX, [EdData.EdSizLn]
	DW _SUB_AX_CX
	MOV [EdData.EdCursr], AX
	JMP T00_20

T15_00:	DW _XOR_CX_CX  ; ^Home, ^PgUp
	CALL T51_00
	MOV [EdData.EdOffst+0], CX
	MOV [EdData.EdOffst+2], CX
	CALL T50_00
	MOV [EdData.EdCursr], CX
	MOV [EdData.EdLine], CX
	MOV [EdData.EdHxCur], CL
	JMP T00_20

T16_00:	CMP BYTE [EdData.EdTxHex], 0  ; ^End, ^PgDn
	JNZ T16_10
	CALL T51_00
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	MOV DI, [EdData.EdLine]
	CALL T61_00
T16_01:	CALL T53_00
	JNC T16_01
	CALL T60_00
	JMP T16_11
T16_10:	MOV BX, [EdData.EdLen+0]
	MOV DX, [EdData.EdLen+2]
	CALL T61_00
	MOV DI, DS
	SUB DI, [ES:MD.ViewSeg]
	AND BX, 0FFF0h
T16_11:	PUSH ES
	POP DS
	MOV [EdData.EdLine], DI
	MOV [EdData.EdOffst+0], BX
	MOV [EdData.EdOffst+2], DX
	JMP T14_11

T20_00:	CMP BYTE [EdData.EdTxHex], 0  ; Del
	JNZ T20_04
	MOV AL, 1
	MOV BX, [EdData.EdCursr]
	CMP BX, [EdData.EdSizLn]
	JAE T20_05
T20_01:	LEA DI, [BX+EditBuf]
	LEA SI, [DI+1]
T20_02:	PUSH SI
	PUSH DI
	DW _MOV_CX_SI
	DW _SUB_CX_DI
	MOV [EdData.EdUndo], CX
	DW _MOV_AX_CX
	DW _MOV_SI_DI
	MOV DI, UndoBuf
	REP MOVSB
	POP DI
	POP SI
	MOV CX, [EdData.EdSizLn]
	ADD CX, EditBuf
	DW _SUB_CX_SI
	JBE T20_03
	REP MOVSB
T20_03:	SUB [EdData.EdSizLn], AX
	MOV BYTE [EdData.EdUpdat], 1
	MOV BYTE [EdData.EdChng], 1
T20_04:	JMP T00_20
T20_05:	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	CALL T61_00
	CALL T53_00
	JC T20_04
	CALL T60_00
	PUSH ES
	POP DS
	MOV WORD [EdData.EdUndo], 2
	MOV WORD [UndoBuf], 0A0Dh
T20_06:	MOV [EdData.EdEndBf+0], BX
	MOV [EdData.EdEndBf+2], DX
	MOV BYTE [EdData.EdUpdat], 1
	CALL T51_00
	CALL T50_00
	DW _OR_AX_AX
	JZ T20_10
	CALL T73_00
	MOV AX, [EdData.EdLine]
	PUSH AX
	SUB AX, [EdData.EdLin0]
	PUSH AX
	INC AX
	CMP AL, [EdData.EdSize+1]
	JAE T20_07
	MOV BX, [EdData.EdBase]
	DW _ADD_BH_AL
	MOV AH, 6
	MOV DX, 2*80
	CALL T71_00
T20_07:	MOV CL, [EdData.EdSize+1]
	MOV CH, 0
	DEC CX
	POP AX
	POP DI
	DW _SUB_CX_AX
	JBE T20_10
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	CALL T61_00
	MOV BX, [ES:EdData.EdLen+0]
	MOV DX, [ES:EdData.EdLen+2]
T20_08:	CALL T53_00
	JC T20_09
	LOOP T20_08
	CALL T60_00
T20_09:	PUSH ES
	POP DS
	DW _ADD_DI_CX
	XCHG BX, [EdData.EdOffst+0]
	XCHG DX, [EdData.EdOffst+2]
	XCHG DI, [EdData.EdLine]
	CALL T50_00
	CALL T73_00
	XCHG BX, [EdData.EdOffst+0]
	XCHG DX, [EdData.EdOffst+2]
	XCHG DI, [EdData.EdLine]
	CALL T50_00
T20_10:	JMP T00_20

T21_00:	DW _XOR_CX_CX  ; BackSpace
	CMP [EdData.EdTxHex], CL
	JZ T21_10
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	ADD BX, [EdData.EdCursr]
	DW _ADC_DX_CX
	DW _MOV_AX_BX
	DW _OR_AX_DX
	JE T20_10
	CALL T63_01
	JNC T21_02
	MOV AX, 1
	MOV [EdData.EdChng], AL
	SUB [EdData.EdLen+0], AX
	SBB [EdData.EdLen+2], CX
	TEST BL, 0Fh
	JNE T21_01
	MOV AX, [EdData.EdLine]
	SUB AX, [EdData.EdLin0]
	CALL T70_00
	MOV DL, [EdData.EdSize+0]
	MOV DH, 1
	CALL Window
T21_01:	MOV AL, 0
	JMP T05_02
T21_02:	JMP T05_00
T21_10:	MOV BX, [EdData.EdCursr]
	DW _OR_BX_BX
	JE T21_11
	DEC BX
	MOV [EdData.EdCursr], BX
	JMP T20_01
T21_11:	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	MOV DI, [EdData.EdLine]
	CALL T61_00
	CALL T54_00
	JC T21_13
	CALL T51_00
	CALL T60_00
	PUSH ES
	POP DS
	MOV [EdData.EdOffst+0], BX
	MOV [EdData.EdOffst+2], DX
	MOV [EdData.EdLine], DI
	CALL T50_00
	CALL T57_00
	MOV AX, [EdData.EdSizLn]
	DW _SUB_AX_CX
	MOV [EdData.EdCursr], AX
	MOV AX, [EdData.EdLine]
	DW _MOV_BX_AX
	INC AX
	SUB AX, [EdData.EdLin0]
	JNE T21_12
	MOV [EdData.EdLin0], BX
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	MOV [EdData.EdFirst+0], BX
	MOV [EdData.EdFirst+2], DX
T21_12:	JMP T20_05
T21_13:	JMP T00_20

T22_00:	CMP BYTE [EdData.EdTxHex], 0  ; ^BS
	JNZ T21_13
	MOV DI, EditBuf
	MOV DX, [EdData.EdCursr]
	CALL EdSub1
	JE T21_13
	MOV [EdData.EdCursr], DX
	JMP T20_02

T23_00:	CMP BYTE [EdData.EdTxHex], 0  ; ^T
	JNZ T21_13
	MOV DI, EditBuf
	MOV DX, [EdData.EdCursr]
	CALL T55_00
	JE T21_13
	JMP T20_02

T24_00:	CMP BYTE [EdData.EdTxHex], 0  ; ^K
	JNZ T24_03
	CMP BYTE [EdData.EdWhole], 0
	JNZ T24_02
	CALL T51_00
	CALL T50_00
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	CALL T61_00
	CALL T53_00
	MOV BX, [ES:EdData.EdLen+0]
	MOV DX, [ES:EdData.EdLen+2]
	JC T24_01
	CALL T60_00
	SUB BX, 2
	SBB DX, 0
T24_01:	PUSH ES
	POP DS
	MOV [EdData.EdEndBf+0], BX
	MOV [EdData.EdEndBf+2], DX
	MOV BYTE [EdData.EdWhole], 1
T24_02:	MOV SI, [EdData.EdSizLn]
	MOV DI, [EdData.EdCursr]
	DW _CMP_DI_SI
	JAE T24_03
	ADD SI, EditBuf
	ADD DI, EditBuf
	JMP T20_02
T24_03:	JMP T00_20

T25_00:	CMP BYTE [EdData.EdTxHex], 0  ; ^Y
	JNZ T24_03
	CMP BYTE [EdData.EdWhole], 0
	JNZ T25_01
	CALL T51_00
	CALL T50_00
T25_01:	MOV SI, EditBuf
	MOV DI, UndoBuf
	MOV CX, [EdData.EdSizLn]
	PUSH CX
	REP MOVSB
	POP SI
	LEA AX, [SI+2]
	MOV [EdData.EdUndo], AX
	MOV WORD [SI+UndoBuf], 0A0Dh
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	CALL T61_00
	CALL T53_00
	MOV BX, [ES:EdData.EdLen+0]
	MOV DX, [ES:EdData.EdLen+2]
	JC T25_02
	CALL T60_00
T25_02:	PUSH ES
	POP DS
	MOV WORD [ES:EdData.EdSizLn], 0
	MOV WORD [ES:EdData.EdCursr], 0
	MOV AL, 1
	JMP T20_06

T26_00:	CMP BYTE [EdData.EdTxHex], 0  ; ^U
	JNZ T26_03
	MOV CX, [EdData.EdUndo]
	JCXZ T26_03
	CMP CX, 2
	JB T26_01
	DW _MOV_BX_CX
	MOV AX, [BX+UndoBuf-2]
	CALL IsCrLf
	JE T26_04
T26_01:	MOV AX, LenEdit+1
	DW _SUB_AX_CX
	CMP [EdData.EdSizLn], AX
	MOV AL, 0
	JAE T26_04
	ADD [EdData.EdSizLn], CX
	MOV SI, EditBuf+LenEdit-1
	DW _MOV_DI_SI
	DW _SUB_SI_CX
	PUSH CX
	MOV BX, [EdData.EdCursr]
	ADD BX, EditBuf-1
	DW _MOV_CX_SI
	DW _SUB_CX_BX
	JBE T26_02
	STD
	REP MOVSB
	CLD
T26_02:	POP CX
	ADD [EdData.EdCursr], CX
	LEA DI, [SI+1]
	MOV SI, UndoBuf
	REP MOVSB
	MOV BYTE [EdData.EdUpdat], 1
	JMP T08_01
T26_03:	JMP T00_20
T26_04:	CALL T51_00
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	PUSH DX
	PUSH BX
	ADD BX, [EdData.EdCursr]
	ADC DX, 0
	MOV [EdData.EdOffst+0], BX
	MOV [EdData.EdOffst+2], DX
	MOV [EdData.EdEndBf+0], BX
	MOV [EdData.EdEndBf+2], DX
	MOV SI, UndoBuf
	MOV DI, EditBuf
	MOV [EdData.EdSizLn], CX
	PUSH CX
	REP MOVSB
	POP CX
	MOV BYTE [EdData.EdUpdat], 1
	CALL T51_00
	POP BX
	POP DX
	MOV [EdData.EdOffst+0], BX
	MOV [EdData.EdOffst+2], DX
	CMP AL, 0
	JZ T26_05
	JMP T02_03
T26_05:	CALL T50_00
	ADD [EdData.EdCursr], CX
	JMP T08_01

T30_00:	CMP BYTE [EdData.EdSize+0], 80  ; F4 - ASCII / Hex
	JB T30_12
	CALL T51_00
	DW _XOR_DX_DX
	MOV [EdData.EdCol0], DX
	MOV BYTE [EdData.EdScrn], 1
	MOV BX, EdData.EdTxHex
	CALL InvVar
	JZ T30_10
	MOV [EdData.EdHxCur], DL  ; ASCII to Hex
	MOV BX, [EdData.EdCursr]
	ADD BX, [EdData.EdOffst+0]
	ADC DX, [EdData.EdOffst+2]
	CALL T61_00
	MOV [ES:EdData.EdCursr], SI
	DW _XOR_SI_SI
	CALL T60_00
	MOV AX, DS
	PUSH ES
	POP DS
	SUB AX, [MD.ViewSeg]
	MOV [EdData.EdLine], AX
	MOV [EdData.EdLin0], AX
	MOV [EdData.EdOffst+0], BX
	MOV [EdData.EdOffst+2], DX
	JMP T30_11
T30_10:	MOV AX, [EdData.EdOffst+0]  ; Hex to ASCII
	MOV CX, [EdData.EdOffst+2]
	ADD AX, [EdData.EdCursr]
	DW _ADC_CX_DX
	DW _XOR_BX_BX
	DW _XOR_DI_DI
	CALL T56_00
	MOV AX, [EdData.EdLine]
	MOV [EdData.EdLin0], AX
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
T30_11:	MOV [EdData.EdFirst+0], BX
	MOV [EdData.EdFirst+2], DX
T30_12:	JMP T00_20

T31_00:	MOV DX, EdFl_S  ; F7 - search
	MOV BP, Srch_B
	CALL Dialog
	JNE T30_12

T32_00:	CMP BYTE [MD.SrchStr], 0  ; Shift F7 - continue search
	JE T30_12
	CALL T51_00
	MOV DX, EdFl_S
	CALL V80_00
	PUSH SI
	PUSH DX
	PUSH BX
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	ADD BX, [EdData.EdCursr]
	ADC DX, 0
T32_01:	CALL TstBrk
	JC T32_04
	MOV AX, [ES:EdData.EdLen+0]
	MOV CX, [ES:EdData.EdLen+2]
	DW _SUB_AX_BX
	DW _SBB_CX_DX
	MOV CX, 8000h
	JB T32_03
	JA T32_02
	DW _CMP_AX_CX
	JAE T32_02
	DW _MOV_CX_AX
T32_02:	CALL T61_00
	CALL V82_00
	JNC T32_05
	SUB CX, [ES:MD.HelpBuf+90]
	JB T32_03
	INC CX
	DW _ADD_BX_CX
	ADC DX, 0
	JMP T32_01
T32_03:	PUSH ES
	POP DS
	MOV DX, EdFl_S
	MOV BP, SrEr_B
	CALL Dialog
T32_04:	JMP T32_07
T32_05:	CALL TstBrk
	JC T32_04
	CALL T60_00
	PUSH ES
	POP DS
	CMP BYTE [EdData.EdTxHex], 0
	JZ T32_06
	MOV [EdData.EdHexAs], AL
	MOV BYTE [EdData.EdHxCur], 0
	DW _MOV_AX_BX
	AND AX, STRICT WORD 0FFF0h
	MOV [EdData.EdOffst+0], AX
	MOV [EdData.EdOffst+2], DX
	CALL T61_00
	MOV AX, DS
	PUSH ES
	POP DS
	SUB AX, [MD.ViewSeg]
	MOV [EdData.EdLine], AX
	AND BX, 0Fh
	MOV [EdData.EdCursr], BX
	JMP T32_07
T32_06:	DW _MOV_AX_BX
	DW _MOV_CX_DX
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	MOV DI, [EdData.EdLine]
	CALL T56_00
T32_07:	CALL T50_00
	POP BX
	POP DX
	POP SI
	CALL ResWin
	CALL Window
	JMP T00_20

T33_00:	MOV BP, SavAs_B  ; Shift F2 - save...
	CALL Dialog
	JE T34_00
	JMP T00_20

T34_00:	CALL T80_00  ; F2 - save
	JC T34_01
	MOV BYTE [EdData.EdChng], 0
T34_01:	CMP BYTE [EdData.EdStat], 0
	JZ T34_02
	CALL T74_00
T34_02:	JMP T00_20

T35_00:	CMP BYTE [EdData.EdChng], 0  ; F10, Esc - quit
	JZ T35_02
	MOV BP, SavCn_B
	CALL Dialog
	CMP AL, 1
	JE T35_02
	JA T35_03
T35_01:	CALL T80_00  ; Shift F10 - save & quit
	JC T35_03
T35_02:	MOV CX, [EdData.EdShape]
	MOV AH, 1
	INT 10h
	MOV CL, [EdData.EdWrite]
	JMP V13_01
T35_03:	JMP T00_20

;GLOBAL T50_00
T50_00:  ; PROC NEAR  ; Read string in buffer
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	PUSH ES
	POP DS
	CMP BYTE [EdData.EdTxHex], 0
	JNZ T50_05
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	CALL T61_00
	MOV DI, EditBuf
	MOV CX, LenEdit-100
	PUSH SI
	PUSH CX
	REP MOVSB
	POP CX
	POP SI
	MOV BYTE [ES:EdData.EdWhole], 1
	DW _XOR_DI_DI
	CALL T63_01
	JC T50_04
	DW _MOV_AX_SI
	CALL T53_10
	JC T50_03
	DW _MOV_DI_SI
	DW _SUB_DI_AX
	CMP DI, 2
	JB T50_04
	CALL IsCrLf0
	JNE T50_02
	DEC DI
	DEC DI
T50_02:	DW _CMP_DI_CX
	JBE T50_04
T50_03:	DW _MOV_DI_CX
	MOV BYTE [ES:EdData.EdWhole], 0
T50_04:	DW _ADD_BX_DI
	ADC DX, 0
	MOV [ES:EdData.EdEndBf+0], BX
	MOV [ES:EdData.EdEndBf+2], DX
	MOV [ES:EdData.EdSizLn], DI
	MOV BYTE [ES:EdData.EdUpdat], 0
T50_05:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;T50_00 ENDP

;GLOBAL T51_00
T51_00:  ; PROC NEAR  ; Updata line from buffer
	CMP BYTE [ES:EdData.EdTxHex], 0
	JNZ T51_01
	CMP BYTE [ES:EdData.EdUpdat], 0
	JNZ T51_02
T51_01:	RET
T51_02:	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	PUSH ES
	POP DS
	MOV BYTE [EdData.EdUpdat], 0
	MOV BYTE [EdData.EdChng], 1
	MOV BX, [EdData.EdEndBf+0]
	MOV DX, [EdData.EdEndBf+2]
	SUB BX, [EdData.EdOffst+0]
	SBB DX, [EdData.EdOffst+2]
	MOV CX, [EdData.EdSizLn]
	JNE T51_10
	DW _CMP_BX_CX
	JA T51_10
	JB T51_20
	JMP T51_40
T51_10:	DW _SUB_BX_CX  ; Compress
	SBB DX, 0
	PUSH DX
	PUSH BX
	MOV BX, [EdData.EdOffst+0]
	MOV DX, [EdData.EdOffst+2]
	DW _ADD_BX_CX
	ADC DX, 0
	CALL T61_00
	MOV BP, DS
	DW _MOV_DI_SI
	MOV BX, [ES:EdData.EdEndBf+0]
	MOV DX, [ES:EdData.EdEndBf+2]
	CALL T61_00
	MOV AX, [ES:EdData.EdLen+0]
	MOV CX, [ES:EdData.EdLen+2]
	DW _SUB_AX_BX
	DW _SBB_CX_DX
	DW _MOV_DX_CX
	MOV BX, 0FF0h
	CLD
	JMP T51_30
T51_20:	DW _SUB_CX_BX  ; Expand
	PUSH CX
	MOV BX, [ES:EdData.EdLen+0]
	MOV DX, [ES:EdData.EdLen+2]
	DW _ADD_BX_CX
	ADC DX, 0
	CALL T61_00
	MOV BP, DS
	MOV AX, [ES:EdData.EdSpace]
	ADD AX, [ES:MD.ViewSeg]
	DW _CMP_BP_AX
	JB T51_22
	MOV BYTE [ES:EdData.EdScrn], 1
	CALL Beep
	DW _MOV_BP_AX
	DEC BP
	MOV SI, 0Fh
	MOV DS, BP
	CALL T60_00
	PUSH DX
	PUSH BX
	SUB BX, [ES:EdData.EdOffst+0]
	SUB DX, [ES:EdData.EdOffst+2]
	JNE T51_21
	CMP BX, [ES:EdData.EdSizLn]
	JAE T51_21
	MOV [ES:EdData.EdSizLn], BX
T51_21:	POP BX
	POP DX
	POP AX
	DW _MOV_AX_BX
	SUB AX, [ES:EdData.EdLen+0]
	PUSH AX
T51_22:	SUB BP, 0FFFh
	LEA DI, [SI-10h]
	DW _SUB_BX_CX
	SBB DX, 0
	CALL T61_00
	MOV AX, DS
	SUB AX, STRICT WORD 0FFFh
	MOV DS, AX
	ADD SI, 0FFF0h
	DEC SI
	DEC DI
	POP AX
	DW _XOR_CX_CX
	NEG AX
	JE T51_23
	DEC CX
T51_23:	PUSH CX
	PUSH AX
	SUB BX, [ES:EdData.EdEndBf+0]
	SBB DX, [ES:EdData.EdEndBf+2]
	JB T51_34
	DW _MOV_AX_BX
	MOV BX, -0FF0h
	STD
T51_30:	MOV CX, 0FF00h  ; Move
	DIV CX
	PUSH ES
	MOV ES, BP
	DW _MOV_CX_AX
	JCXZ T51_32
T51_31:	PUSH SI
	PUSH DI
	PUSH CX
	MOV CX, 0FF00h
	REP MOVSB
	POP CX
	POP DI
	POP SI
	MOV AX, DS
	DW _ADD_AX_BX
	MOV DS, AX
	DW _ADD_BP_BX
	MOV ES, BP
	LOOP T51_31
T51_32:	DW _MOV_CX_DX
	JCXZ T51_33
	REP MOVSB
T51_33:	POP ES
T51_34:	POP BX
	POP DX
	SUB [ES:EdData.EdLen+0], BX
	SBB [ES:EdData.EdLen+2], DX
T51_40:	CLD  ; Updata line
	MOV BX, [ES:EdData.EdOffst+0]
	MOV DX, [ES:EdData.EdOffst+2]
	CALL T61_00
	PUSH DS
	PUSH ES
	POP DS
	POP ES
	DW _MOV_DI_SI
	MOV SI, EditBuf
	MOV CX, [EdData.EdSizLn]
	JCXZ T51_41
	REP MOVSB
T51_41:	PUSH DS
	POP ES
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;T51_00 ENDP

;GLOBAL T53_00
T53_00:  ; PROC NEAR  ; Find next line
	PUSH DX
	PUSH BX
	PUSH AX
	PUSH DS
	PUSH SI
	INC DI
	JE T53_07
	CALL T63_00
	JC T53_07
	CMP BYTE [ES:EdData.EdTxHex], 0
	JZ T53_03
	CALL T53_10
	JNC T53_01
	CALL T60_00
	CALL T61_00
	CALL T53_10
T53_01:	TEST SI, 0Fh
	JNE T53_07
T53_02:	POP AX
	POP AX
	JMP T53_08
T53_03:	CALL T60_00
	PUSH DX
	PUSH BX
T53_04:	CALL T53_10
	JNC T53_05
	CALL T60_00
	CALL T61_00
	CALL T53_10
	JNC T53_05
	MOV AX, DS
	ADD AX, STRICT WORD 0FF0h
	MOV DS, AX
	JMP T53_04
T53_05:	CALL T60_00
	POP AX
	DW _SUB_BX_AX
	POP AX
	DW _SBB_DX_AX
	JNE T53_06
	CMP BX, 1
	JBE T53_07
T53_06:	CALL IsCrLf0
	JE T53_02
T53_07:	POP SI
	POP DS
	DEC DI
	STC
T53_08:	POP AX
	POP BX
	POP DX
	RET
;T53_00 ENDP

;GLOBAL T53_10
T53_10:  ; PROC NEAR
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	CALL T63_00
	JC T53_16
	DW _MOV_DI_SI
	CMP BYTE [ES:EdData.EdTxHex], 0
	JZ T53_11
	OR SI, 0Fh  ; Hex
	INC SI
	JE T53_15
	CALL T63_00
	JNC T53_16
	CALL T60_00
	SUB BX, [ES:EdData.EdLen+0]
	DW _SUB_SI_BX
	JMP T53_16
T53_11:	CALL T60_00  ; Text
	MOV AX, [ES:EdData.EdLen+0]
	MOV CX, [ES:EdData.EdLen+2]
	DW _SUB_AX_BX
	DW _SBB_CX_DX
	MOV CX, 0FFFEh
	JNE T53_12
	DW _ADD_AX_SI
	JC T53_12
	DW _CMP_AX_CX
	JAE T53_12
	DW _MOV_CX_AX
T53_12:	DW _CMP_SI_CX
	JAE T53_14
	LODSW
	DW _CMP_SI_CX
	JA T53_13
	CALL IsCrLf
	JE T53_16
T53_13:	DEC SI
	JMP T53_12
T53_14:	CALL T63_00
	CMC
	JNC T53_16
T53_15:	DW _MOV_SI_DI
	STC
T53_16:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	RET
;T53_10 ENDP

;GLOBAL T54_00
T54_00:  ; PROC NEAR  ; Find previous line
	PUSH BP
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	DW _MOV_BX_SI
	MOV DX, DS
	DW _OR_DI_DI
	JE T54_15
	MOV AX, DS
	CMP BYTE [ES:EdData.EdTxHex], 0
	JZ T54_01
	CMP AX, [ES:MD.ViewSeg]
	JBE T54_15
	DEC AX
	MOV DS, AX
	JMP T54_14
T54_01:	CMP AX, [ES:MD.ViewSeg]
	JA T54_02
	DW _OR_SI_SI
	JE T54_15
T54_02:	DW _XOR_BP_BP
	CALL T60_00
	PUSH BX
	SUB SI, 2
	JA T54_08
	JMP T54_09
T54_03:	CMP AX, 800h
	JBE T54_04
	MOV AX, 800h
T54_04:	MOV CX, DS
	DW _SUB_CX_AX
	MOV DS, CX
	MOV CL, 4
	SHL AX, CL
	DW _ADD_SI_AX
T54_05:	MOV AX, [SI-2]
	DW _OR_BP_BP
	JNE T54_06
	CALL IsCrLf
	JNE T54_07
	INC BP
	DW _MOV_BX_AX
	JMP T54_07
T54_06:	DW _XCHG_BL_BH
	DW _CMP_AX_BX
	JNE T54_10
T54_07:	DEC SI
T54_08:	CMP SI, 2
	JAE T54_05
T54_09:	MOV AX, DS
	SUB AX, [ES:MD.ViewSeg]
	JA T54_03
	DW _XOR_SI_SI
	DEC SI
T54_10:	INC SI
	POP AX
	DW _MOV_CX_DX
	CALL T60_00
T54_11:	PUSH DX
	PUSH BX
	PUSH DI
	DW _XOR_DI_DI
	CALL T61_00
	CALL T53_00
	CALL T60_00
	POP DI
	DW _CMP_DX_CX
	JA T54_13
	JB T54_12
	DW _CMP_BX_AX
	JAE T54_13
T54_12:	POP BP
	POP BP
	JMP T54_11
T54_13:	POP BX
	POP DX
	CALL T61_00
T54_14:	DEC DI
	JMP T54_16
T54_15:	DW _MOV_SI_BX
	MOV DS, DX
	STC
T54_16:	POP AX
	POP BX
	POP CX
	POP DX
	POP BP
	RET
;T54_00 ENDP

;GLOBAL T55_00
T55_00:  ; PROC NEAR  ; Next word
	DW _ADD_DI_DX
	DW _MOV_SI_DI
T55_01:	CALL T55_10
	JAE T55_03
	INC SI
	INC DX
	MOV AL, [ES:SI]
	CALL CmpSym
	JE T55_01
T55_02:	CALL T55_10
	JAE T55_03
	INC SI
	INC DX
	MOV AL, [ES:SI]
	CALL CmpSym
	JNE T55_02
T55_03:	DW _CMP_SI_DI
	RET
;T55_00 ENDP

;GLOBAL T55_10
T55_10:  ; PROC NEAR
	CMP DX, [ES:EdData.EdSizLn]
	JB T55_11
	CMP BYTE [ES:EdData.EdWhole], 0
	JNZ T55_11
	CALL T51_00
	CALL T50_00
T55_11:	CMP DX, [ES:EdData.EdSizLn]
	RET
;T55_10 ENDP

;GLOBAL T56_00
T56_00:  ; PROC NEAR  ; Calculte coordinats
	CALL T61_00
T56_01:	MOV [ES:EdData.EdOffst+0], BX
	MOV [ES:EdData.EdOffst+2], DX
	MOV [ES:EdData.EdLine], DI
	CALL T53_00
	JC T56_02
	CALL T60_00
	DW _CMP_DX_CX
	JB T56_01
	JA T56_02
	DW _CMP_BX_AX
	JBE T56_01
T56_02:	PUSH ES
	POP DS
	CALL T50_00
	SUB AX, [EdData.EdOffst+0]
	SBB CX, [EdData.EdOffst+2]
	JE T56_03
	MOV AX, 0FFFFh
T56_03:	PUSH AX
	CALL T57_00
	MOV AX, [EdData.EdSizLn]
	DW _SUB_AX_CX
	POP BX
	DW _CMP_BX_AX
	JBE T56_04
	DW _MOV_BX_AX
T56_04:	MOV [EdData.EdCursr], BX
	RET
;T56_00 ENDP

;T57_00	PROC	NEAR			; Calculate cursor position
;GLOBAL T57_00
T57_00:
	MOV DX, LenEdit-100
T57_01:	MOV CX, [ES:EdData.EdSizLn]
	JMP T57_03
T57_02:	MOV AX, [ES:EdData.EdCursr]
	CMP BYTE [ES:EdData.EdTxHex], 0
	JNZ T57_07
	DW _MOV_CX_AX
	MOV DX, 0FFFFh
T57_03:	DW _XOR_BX_BX
	JCXZ T57_06
	MOV SI, EditBuf
T57_04:
ES
	LODSB
	CMP AL, 9
	DW _MOV_AX_BX
	JNE T57_05
	OR BX, 7
T57_05:	INC BX
	DW _CMP_BX_DX
	JAE T57_07
	LOOP T57_04
T57_06:	DW _MOV_AX_BX
T57_07:	RET
;T57_00	ENDP

;GLOBAL T60_00
T60_00:  ; PROC NEAR  ; DS:SI -> DX BX
	PUSH CX
	MOV CL, 4
	MOV BX, DS
	SUB BX, [ES:MD.ViewSeg]
	DW _MOV_DL_BH
	MOV DH, 0
	SHL BX, CL
	SHR DX, CL
	DW _ADD_BX_SI
	ADC DX, 0
	POP CX
	RET
;T60_00 ENDP

;T62_00	PROC	NEAR			; Address of first line of screen
;GLOBAL T62_00
T62_00:
	MOV BX, [ES:EdData.EdFirst+0]
	MOV DX, [ES:EdData.EdFirst+2]
T61_00:	PUSH DX  ; DX BX -> DS:[SI]
	PUSH CX
	PUSH AX
	DW _MOV_SI_BX
	AND SI, 0Fh
	DW _MOV_AX_BX
	MOV CL, 4
	SHR AX, CL
	SHL DL, CL
	DW _OR_AH_DL
	ADD AX, [ES:MD.ViewSeg]
	MOV DS, AX
	POP AX
	POP CX
	POP DX
	RET
;T62_00	ENDP

;T63_00	PROC	NEAR			; Last byte ?
;GLOBAL T63_00
T63_00:
	CALL T60_00
T63_01:	CMP DX, [ES:EdData.EdLen+2]
	JNE T63_02
	CMP BX, [ES:EdData.EdLen+0]
T63_02:	CMC
	RET
;T63_00	ENDP

;GLOBAL T64_00
T64_00:  ; PROC NEAR  ; Compare strings
	PUSH DI
	PUSH CX
	REPE CMPSB
	POP CX
	POP DI
	RET
;T64_00 ENDP

;GLOBAL T70_00
T70_00:  ; PROC NEAR  ; Clear line #AL
	PUSH AX
	MOV BX, [ES:EdData.EdBase]
	DW _ADD_BH_AL
	CALL BasAdr
	PUSH DI
	MOV CL, [ES:EdData.EdSize+0]
	MOV CH, 0
	MOV AH, Back_C
	CALL Color
	MOV AL, ' '
	REP STOSW
	POP DI
	POP AX
	RET
;T70_00 ENDP

;GLOBAL T71_00
T71_00:  ; PROC NEAR  ; Scroll screen up / down
	CALL BasAdr
	DW _MOV_SI_DI
	DW _ADD_SI_DX
	MOV CL, [EdData.EdSize+1]
	DW _SUB_CL_AL
	MOV CH, 0
	DEC CX
	JCXZ T71_02
	PUSH AX
T71_01:	PUSH DI
	PUSH SI
	PUSH CX
	MOV CL, [EdData.EdSize+0]
	REP MOVSW
	POP CX
	POP SI
	POP DI
	DW _ADD_SI_DX
	DW _ADD_DI_DX
	LOOP T71_01
	MOV AH, Back_C
	CALL Color
	DW _MOV_BH_AH
	POP AX
	MOV CX, [EdData.EdBase]
	MOV DX, [EdData.EdSize]
	DW _ADD_DX_CX
	SUB DX, 101h
	DW _ADD_CH_AL
	MOV AL, 1
	CALL Int10m
T71_02:	RET
;T71_00 ENDP

;GLOBAL T72_00
T72_00:  ; PROC NEAR  ; Output line #AL
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	CALL T70_00
	CMP BYTE [ES:EdData.EdTxHex], 0
	JNZ T72_10
	DW _XOR_DX_DX  ; Text edit
	CMP BP, 2
	JB T72_01
	DEC BP
	DEC BP
	MOV AX, [DS:BP]
	CALL IsCrLf
	JE T72_01
	INC BP
	INC BP
T72_01:	DW _CMP_SI_BP
	JAE T72_04
	LODSB
	CMP AL, 9
	JNE T72_02
	OR DL, 7
	MOV AL, ' '
T72_02:	DW _MOV_BX_DX
	INC DX
	SUB BX, [ES:EdData.EdCol0]
	JB T72_01
	CMP BL, [ES:EdData.EdSize+0]
	JAE T72_03
	DW _ADD_BX_BX
	MOV [ES:DI+BX], AL
	JMP T72_01
T72_03:	MOV AH, Arrow_C
	CALL Color
	MOV AL, 1Ah
	MOV BL, [ES:EdData.EdSize+0]
	MOV BH, 0
	DEC BX
	DW _ADD_BX_BX
	MOV [ES:DI+BX], AX
T72_04:	CMP WORD [ES:EdData.EdCol0], 0
	JE T72_14
	MOV AH, Arrow_C
	CALL Color
	MOV AL, 1Bh
	MOV [ES:DI], AX
	JMP T72_14
T72_10:	INC DI  ; Hex edit
	INC DI
	CALL T60_00
	DW _MOV_AL_DH
	CALL HexByt
	DW _MOV_AL_DL
	CALL HexByt
	DW _MOV_AL_BH
	CALL HexByt
	DW _MOV_AL_BL
	CALL HexByt
	ADD DI, 2*2
	LEA BX, [DI+2*52]
	MOV CX, 16
T72_11:	DW _CMP_SI_BP
	JAE T72_14
	LODSB
	MOV [ES:BX], AL
	CMP AL, 0
	JNE T72_12
	MOV BYTE [ES:BX], '.'
T72_12:	INC BX
	INC BX
	CALL HexByt
	INC DI
	INC DI
	DW _MOV_AL_CL
	AND AL, 3
	CMP AL, 1
	JNE T72_13
	INC DI
	INC DI
T72_13:	LOOP T72_11
T72_14:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	RET
;T72_00 ENDP

;GLOBAL T73_00
T73_00:  ; PROC NEAR  ; Output current line
	PUSH DX
	PUSH BX
	CALL T73_10
	CALL Window
	POP BX
	POP DX
	RET
;T73_00 ENDP

;GLOBAL T73_10
T73_10:  ; PROC NEAR
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH CX
	PUSH AX
	PUSH ES
	POP DS
	MOV AX, [EdData.EdLine]
	SUB AX, [EdData.EdLin0]
	MOV BX, [EdData.EdBase]
	DW _ADD_BH_AL
	MOV DL, [EdData.EdSize+0]
	MOV DH, 1
	PUSH DX
	PUSH BX
	CMP BYTE [EdData.EdTxHex], 0
	JNZ T73_12
	PUSH AX  ; Text
	MOV BX, [EdData.EdSizLn]
	SUB BX, [EdData.EdCursr]
	MOV AL, [EdData.EdSize+0]
	CBW
	ADD AX, [EdData.EdCol0]
	SUB AX, [EdData.EdCol]
	DW _CMP_BX_AX
	JAE T73_11
	CMP BYTE [EdData.EdWhole], 0
	JNZ T73_11
	CALL T51_00
	CALL T50_00
T73_11:	MOV SI, EditBuf
	MOV BP, [EdData.EdSizLn]
	DW _ADD_BP_SI
	POP AX
	CALL T70_00
	DW _CMP_SI_BP
	JB T73_13
	JMP T73_14
T73_12:	MOV BX, [EdData.EdOffst+0]  ; Hex
	MOV DX, [EdData.EdOffst+2]
	CALL T61_00
	DW _MOV_BP_SI
	CALL T53_10
	DW _XCHG_BP_SI
T73_13:	CALL T72_00
T73_14:	POP BX
	POP DX
	POP AX
	POP CX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;T73_10 ENDP

;GLOBAL T74_00
T74_00:  ; PROC NEAR  ; Put file name to status line
	MOV SI, MD.ViewFil
	MOV DI, MD.TmpBuf
	MOV CX, LenStr+1
	PUSH DI
	REP MOVSB
	POP SI
	MOV AX, 31
	DW _MOV_CX_AX
	CALL ShrtLin
	CALL LetLin
	MOV DI, MD.ScrBuf+2*6
	PUSH DI
	MOV AH, [DI+1]
	MOV AL, ' '
	REP STOSW
	POP DI
	CALL MovDz0
	RET
;T74_00 ENDP

;GLOBAL T75_00
T75_00:  ; PROC NEAR  ; Output number
	INC CX
	DW _XOR_BX_BX
	PUSH DI
	MOV DI, MD.TmpBuf
	PUSH DI
	MOV AL, 0
	CALL Number
	MOV CX, 5
	MOV AL, ' '
	PUSH CX
	REP STOSB
	POP CX
	POP SI
	POP DI
	CALL MvsBwe
	RET
;T75_00 ENDP

;GLOBAL T76_00
T76_00:  ; PROC NEAR
	PUSH BX
	MOV CX, 6
	MOV AL, 0FFh
T76_01:	CALL BasAdr
	CALL NgLine
	INC BH
	LOOP T76_01
	POP BX
	RET
;T76_00 ENDP

;GLOBAL T80_00
T80_00:  ; PROC NEAR  ; Save file
	CALL T51_00
	CALL T50_00
	MOV BX, 528h
	MOV BP, SavFi_P
	CALL DialBox
	CALL Window
	PUSH SI
	PUSH DX
	PUSH BX
	MOV DX, MD.ViewFil
	CALL ChgDisk
	JC T80_06
	MOV AX, 4300h
	CALL Intr21
	JNC T80_01
	CMP AX, STRICT WORD 2
	JNE T80_03
	DW _XOR_CX_CX
T80_01:	AND CX, 3Fh
	OR CL, 20h
	DW _MOV_BX_CX
	TEST CL, 1
	JZ T80_02
	MOV SI, MD.ViewFil
	MOV DI, MD.TmpBuf+130
	MOV CX, LenStr+1
	PUSH DI
	REP MOVSB
	POP SI
	CALL LetLin
	PUSH DX
	MOV DX, EdFl_S
	MOV BP, Prot_B
	CALL Dialog
	POP DX
	JNE T80_06
	DW _MOV_CX_BX
	AND CL, 0FEh
	MOV AX, 4301h
	CALL Intr21
	JC T80_03
	MOV BYTE [EdData.EdWrite], 1
T80_02:	MOV AH, 3Ch
	CALL Intr21
	JNC T80_07
T80_03:	CMP AX, STRICT WORD 0FFh
	JNE T80_04
	MOV DX, MD.ViewFil
	MOV AH, 41h
	CALL Intr21
	JNC T80_05
T80_04:	CMP AX, STRICT WORD 53h
	JE T80_06
T80_05:	MOV BP, SavEr_B
	CALL Dialog
T80_06:	STC
	JMP T80_13
T80_07:	MOV BYTE [EdData.EdWrite], 1
	PUSH BX
	DW _MOV_BX_AX
	MOV AX, 4400h
	CALL Intr21
	JC T80_11
	TEST DL, 80h
	JZ T80_08
	MOV AH, 1
	TEST DL, 2
	JNZ T80_11
	POP CX
	MOV CX, 0FFFFh
	PUSH CX
T80_08:	MOV SI, [EdData.EdLen+0]
	MOV DI, [EdData.EdLen+2]
	MOV DS, [MD.ViewSeg]
T80_09:	MOV CX, 0FF00h
	DW _OR_DI_DI
	JNE T80_10
	DW _CMP_SI_CX
	JAE T80_10
	DW _MOV_CX_SI
T80_10:	DW _XOR_DX_DX
	MOV AH, 40h
	CALL Intr21
	JC T80_11
	DW _CMP_AX_CX
	MOV AX, 0FFh
	JNE T80_11
	MOV AX, DS
	ADD AX, STRICT WORD 0FF0h
	MOV DS, AX
	DW _SUB_SI_CX
	SBB DI, 0
	DW _MOV_AX_SI
	DW _OR_AX_DI
	JNE T80_09
T80_11:	PUSH ES
	POP DS
	POP CX
	PUSH AX
	PUSHF
	MOV AH, 3Eh
	CALL Intr21
	POP BX
	POP DI
	JC T80_12
	DW _MOV_AX_DI
	PUSH BX
	POPF
	JC T80_12
	INC CX
	JCXZ T80_13
	DEC CX
	MOV DX, MD.ViewFil
	MOV AX, 4301h
	CALL Intr21
	JNC T80_13
	CMP AX, STRICT WORD 5
	JE T80_13
T80_12:	JMP T80_03
T80_13:	POP BX
	POP DX
	POP SI
	PUSHF
	CALL ResWin
	CALL Window
	MOV SI, MD.ViewFil  ; Save main extension file
	LODSW
	CMP AH, ':'
	JE T80_14
	MOV AL, [MD.DosPth]
	DEC SI
	DEC SI
T80_14:	MOV DI, MD.TmpBuf
	PUSH DI
	CALL UpCase
	STOSB
	SUB AL, 'A'-1
	DW _MOV_DL_AL
	MOV AX, ':\'
	STOSW
	DW _XCHG_SI_DI
	MOV AH, 47h
	CALL Intr21
	POP DX
	JC T80_17
	DW _XCHG_DI_SI
	DEC DI
	MOV CX, LenPath+13
	CMP BYTE [SI], '\'
	JE T80_15
	PUSH CX
	MOV AL, 0
	REPNE SCASB
	POP CX
	DEC DI
	CALL AddFile
T80_15:	DW _ADD_CX_DX
	DW _SUB_CX_DI
	JBE T80_17
	REP MOVSB
	DW _MOV_DI_DX
	DW _MOV_SI_DI
	CALL PathLin
	CALL CutPath
	DW _MOV_CX_SI
	DW _SUB_CX_DI
	MOV SI, MD.NcPath
	REPE CMPSB
	JNE T80_17
	LODSB
	CMP AL, 0
	JNE T80_17
	PUSH CS
	POP DS
	MOV SI, Ext_F
	MOV CX, 7
	REPE CMPSB
	PUSH ES
	POP DS
	JNE T80_17
	DW _XOR_SI_SI
	MOV CX, LenExt-1
	CMP SI, [EdData.EdLen+2]
	JNE T80_16
	CMP CX, [EdData.EdLen+0]
	JBE T80_16
	MOV CX, [EdData.EdLen+0]
T80_16:	MOV DS, [MD.ViewSeg]
	MOV DI, MD.ExtMain
	REP MOVSB
	MOV AL, 1Ah
	STOSB
	PUSH ES
	POP DS
T80_17:	POPF
	RET
;T80_00 ENDP

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
	MOV AH, 1
	XCHG AH, [MD.BlocEr]
	MOV AL, [MD.HlpPage]
	PUSH AX
	CMP AL, 0FFh
	JE Help02
	CALL HidCur
	MOV DX, MD.HelpBuf  ; Reading
	MOV SI, Help_F
	DW _MOV_DI_DX
	CALL MainFil
	CALL ChgDisk
	JC Help02
	MOV AL, 40h
	CALL OpenFil
	JC Help02
	MOV [HlpData.HlpHndl], AX
	DW _MOV_BX_AX
	DW _XOR_CX_CX
	MOV DX, 8
	CALL SeekDsk
	JC Help01
	MOV CX, 13
	MOV DX, MD.HelpBuf+16
	CALL ReadDsk
	JC Help01
	PUSH CS
	POP DS
	DW _MOV_DI_DX
	MOV SI, HlpHead
	REPE CMPSB
	PUSH ES
	POP DS
	JNE Help01
	DW _XOR_CX_CX
	MOV DX, 194h
	CALL SeekDsk
	JC Help01
	MOV CX, 4
	MOV DX, HlpData.HlpOffs
	CALL ReadDsk
	JC Help01
	CALL DeCode
	MOV WORD [HlpData.HlpBkLn], 0
	CMP BYTE [MD.HlpPage], 0
	JE Help04
	CALL RdEntry
	JNC Help03
Help01:	MOV BP, HlpEr_B
	CALL Dialog
	JMP Help67
Help02:	JMP Help68
Help03:	CMP WORD [HlpData.HlpMode], 0
	JNE Help05
	MOV AL, [MD.HlpPage]
	CBW
	DEC AX
	CALL Help70
Help04:	CALL RdEntry
	JC Help01
Help05:	MOV BX, 204h  ; Output window
	MOV DH, [MD.Lines]
	SUB DH, 3
	MOV DL, 74
	MOV SI, MD.ErrBuf1
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
	MOV CX, 3
	MOV DX, 64
	MOV AL, 'Ä'
	MOV BX, (('Ç'*256)&0FF00H)+('¶'&0FFH)  ; !!
	CALL BoxLine
	POP DI
	ADD DI, 2*3*80
	CALL BoxLine
	POP BX
	POP DX
	CALL Window
	DW _XOR_CX_CX
	MOV [HlpData.HlpBkFr], CX
	MOV BYTE [MD.HlpPage], 0FFh
	MOV [MD.WinMous], CL
	MOV [MD.MousEnt], CL
	MOV WORD [MD.MousTim+2], 0FFFFh

Help06:	PUSH BX  ; Output first line & menu line
	PUSH DX
	MOV SI, HlpData_size
	CMP WORD [HlpData.HlpMode], 0
	JNE Help07
	PUSH CS
	POP DS
	MOV SI, Title_S
Help07:	ADD BX, 205h
	CALL Help77
	MOV DX, 13Eh
	CALL Window
	PUSH CS
	POP DS
	POP DX
	MOV SI, HlMn2_S
	MOV AX, [ES:HlpData.HlpOffs+0]
	AND AX, [ES:HlpData.HlpOffs+2]
	INC AX
	JNE Help08
	MOV CL, 0
	MOV SI, HlMn1_S
Help08:	DW _ADD_BH_DH
	SUB BH, 6
	CALL Help77
	PUSH ES
	POP DS
	CALL Help71
	MOV WORD [HlpData.HlpFrst], 0FFF0h
	POP BX

Help10:	DW _CMP_SI_DI  ; Test parameters
	JAE Help11
	DW _MOV_DI_SI
Help11:	DW _MOV_AL_DH
	SUB AL, 9
	CBW
	DW _ADD_AX_DI
	DW _CMP_SI_AX
	JB Help12
	DW _SUB_AX_DI
	DW _MOV_DI_SI
	DW _SUB_DI_AX
	INC DI
Help12:	DW _MOV_AX_DI
	XCHG SI, [HlpData.HlpCur]
	XCHG DI, [HlpData.HlpFrst]
	DW _SUB_AX_DI
	JNE Help14
	CMP WORD [HlpData.HlpMode], 0
	JNE Help13
	CMP SI, [HlpData.HlpCur]
	JNE Help14
Help13:	JMP Help25
Help14:	PUSH CX  ; Reset cursor
	PUSH AX
	CMP DI, 0FFF0h
	JE Help15
	PUSH DX
	PUSH BX
	DW _MOV_AX_SI
	DW _SUB_AX_DI
	DW _ADD_BH_AL
	DW _MOV_CX_SI
	CALL Help72
	ADD BX, 405h
	CALL Help77
	MOV DX, 13Eh
	CALL Window
	POP BX
	POP DX
Help15:	POP CX
	JCXZ Help20
	PUSH CX  ; Output lines
	PUSH BX
	MOV CX, [HlpData.HlpFrst]
	CALL Help72
	DW _MOV_CL_DH
	SUB CL, 9
	MOV CH, 0
	ADD BX, 405h
Help16:	LEA DI, [SI-HlpData_size]
	CMP DI, [HlpData.HlpSize]
	JB Help17
	DEC SI
Help17:	CALL Help77
	INC BH
	LOOP Help16
	POP BX
	POP CX
	PUSH DX  ; Output screen
	PUSH BX
	CALL Help71
	ADD BX, 405h
	DW _MOV_DH_AL
	DEC AX
	MOV AH, 6
	CMP CX, 1
	JE Help18
	CMP CX, -1
	JNE Help19
	MOV AX, 700h
Help18:	DW _MOV_CX_BX
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
Help19:	MOV DL, 62
	CALL Window
	POP BX
	POP DX
Help20:	CMP WORD [HlpData.HlpMode], 0  ; Set cursor
	JNE Help21
	PUSH DX
	PUSH BX
	MOV AX, [HlpData.HlpCur]
	SUB AX, [HlpData.HlpFrst]
	DW _ADD_BH_AL
	ADD BX, 405h
	CALL BasAdr
	MOV AH, HlpRe_C
	CALL Color
	DW _MOV_AL_AH
	MOV CX, 62
	CALL MvsColr
	MOV DX, 13Eh
	CALL Window
	POP BX
	POP DX
Help21:	POP CX

Help25:	PUSH CX  ; Input
	CALL GetMous
	POP CX
	JNZ Help30
	MOV BYTE [MD.WinMous], 0
	MOV BYTE [MD.MousEnt], 0
	PUSH DX
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 4
	ADD BL, 12
	MOV DX, 130h
	MOV BP, HlpMn_P
	MOV SI, HlMn1_D
	MOV AX, [HlpData.HlpOffs+0]
	AND AX, [HlpData.HlpOffs+2]
	INC AX
	JE Help26
	MOV SI, HlMn2_D
Help26:	MOV AL, 2
	CALL MinMnu
	POP BX
	POP DX
	CMP AH, 0FCh
	JE Help30
	MOV SI, Help_T
	CALL Case
	JMP Help25

Help30:	PUSH CX  ; Mouse support
	CALL GetMous
Help31:	CALL ClrKbd
	DW _MOV_SI_CX
	TEST AL, 4
	JZ Help33
	MOV AL, 'x'
	CALL TypMous
Help32:	CALL GetMous
	CALL ClrKbd
	TEST AL, 4
	JNZ Help32
	PUSH AX
	MOV AL, 0
	CALL TypMous
	POP AX
	TEST AL, 3
	JZ Help40
Help33:	PUSH DX
	PUSH BX
	ADD BX, 404h
	SUB DX, 90Ah
	CALL InWind
	POP BX
	POP DX
	JNC Help41
	CMP BYTE [MD.WinMous], 0
	JZ Help39
	MOV AL, 0
	CMP WORD [HlpData.HlpMode], 0
	JZ Help35
Help34:	DW _MOV_AL_DH
	SUB AL, 9
	CBW
	PUSH CX
	MOV CL, 3
	DIV CL
	POP CX
Help35:	DW _MOV_AH_BH
	ADD AH, 4
	DW _ADD_AH_AL
	DW _CMP_CH_AH
	JB Help37
	DW _MOV_AH_BH
	DW _ADD_AH_DH
	SUB AH, 5
	DW _SUB_AH_AL
	DW _CMP_CH_AH
	JAE Help38
Help36:	POP CX
	JMP Help25
Help37:	POP CX
	JMP Help50
Help38:	POP CX
	JMP Help53
Help39:	TEST AL, 1
	JZ Help36
	CALL GetMous
	JNZ Help31
	DW _MOV_CX_SI
	PUSH DX
	SUB DX, 102h
	CALL InWind
	POP DX
	JNC Help36
Help40:	POP CX
	JMP Help66
Help41:	OR BYTE [MD.WinMous], 1
	CMP WORD [HlpData.HlpMode], 0
	JNZ Help34
	PUSH CX
	DW _SUB_CH_BH
	SUB CH, 4
	DW _MOV_CL_CH
	MOV CH, 0
	MOV DI, [HlpData.HlpFrst]
	DW _ADD_CX_DI
	MOV BP, [HlpData.HlpLins]
	DEC BP
	POP SI
	DW _XCHG_BP_CX
	DW _CMP_BP_CX
	JBE Help43
	DW _MOV_SI_CX
Help42:	POP CX
	JMP Help10
Help43:	PUSH DX
	PUSH BX
	DW _MOV_AX_SI
	DW _MOV_SI_BP
	DW _MOV_BH_AH
	ADD BL, 4
	SUB DL, 10
	MOV DH, 1
	CALL DoublMo
	POP BX
	POP DX
	JC Help42
	JE Help36
	MOV BYTE [MD.MousEnt], 0
	MOV WORD [MD.MousTim+2], 0FFFFh
	MOV AL, 0
	CALL TypMous
	POP CX
	JMP Help60

Help50:	CALL Help71  ; Up
	DW _MOV_AX_SI
	CMP WORD [HlpData.HlpMode], 0
	JE Help51
	DW _MOV_AX_DI
Help51:	DW _OR_AX_AX
	JE Help52
	DEC AX
	DW _MOV_SI_AX
Help52:	JMP Help10

Help53:	CALL Help71  ; Down
	DW _ADD_AX_DI
	CMP WORD [HlpData.HlpMode], 0
	JNE Help54
	DW _MOV_AX_SI
	INC AX
Help54:	CMP AX, [HlpData.HlpLins]
	JAE Help52
	DW _MOV_SI_AX
	JMP Help10

Help55:	DW _XOR_SI_SI  ; Home
	JMP Help10

Help56:	DW _XOR_DI_DI  ; End
	MOV SI, [HlpData.HlpLins]
	DW _OR_SI_SI
	JE Help52
	DEC SI
	JMP Help10

Help57:	CALL Help71  ; PgUp
	CALL PgUp
	JMP Help10

Help58:	CALL Help71  ; PgDn
	MOV BP, [HlpData.HlpLins]
	CALL PgDn
	JMP Help10

Help60:	CALL Help71  ; Enter
	MOV AX, [HlpData.HlpOffs+0]
	AND AX, [HlpData.HlpOffs+2]
	INC AX
	JNE Help61
	DW _OR_CL_CL
	JNE Help66
	CMP WORD [HlpData.HlpMode], 0
	JNE Help52
	MOV AX, [HlpData.HlpCur]
	JMP Help63
Help61:	MOV BYTE [HlpData.HlpMode], 1
	CMP CL, 2
	JE Help64
	JA Help66
	CALL RdEntry
	JC Help65
	MOV AX, [HlpData.HlpCur]
	DW _OR_CL_CL
	JNE Help62
	INC AX
	CMP AX, [HlpData.HlpLins]
	JB Help63
	DW _XOR_AX_AX
	JMP Help63
Help62:	SUB AX, STRICT WORD 1
	JAE Help63
	MOV AX, [HlpData.HlpLins]
	DEC AX
Help63:	CALL Help70
Help64:	CALL RdEntry
	JC Help65
	JMP Help06

Help65:	MOV BP, HlpEr_B  ; Error
	CALL Dialog

Help66:	POP SI  ; Esc
	CALL ResWin
	CALL Window

Help67:	MOV BX, [HlpData.HlpHndl]  ; Exit
	MOV AH, 3Eh
	CALL Intr21
Help68:	POP AX
	MOV [MD.HlpPage], AL
	MOV [MD.BlocEr], AH
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

;GLOBAL Help70
Help70:  ; PROC NEAR
	DW _ADD_AX_AX
	DW _MOV_SI_AX
	DW _ADD_SI_AX
	DW _ADD_SI_AX
	MOV AX, [SI+HlpData_size+2+0]
	MOV [HlpData.HlpOffs+0], AX
	MOV AX, [SI+HlpData_size+2+2]
	MOV [HlpData.HlpOffs+2], AX
	RET
;Help70 ENDP

;GLOBAL Help71
Help71:  ; PROC NEAR
	MOV SI, [HlpData.HlpCur]
	MOV DI, [HlpData.HlpFrst]
	MOV AL, [MD.Lines]
	SUB AL, 12
	CBW
	DW _MOV_BP_AX
	RET
;Help71 ENDP

;GLOBAL Help72
Help72:  ; PROC NEAR
	MOV SI, HlpData_size
	INC CX
	CMP WORD [HlpData.HlpMode], 0
	JNE Help73
	DEC CX
	MOV AX, [HlpData.HlpLins]
	DW _ADD_AX_AX
	DW _ADD_SI_AX
	DW _ADD_SI_AX
	DW _ADD_SI_AX
Help73:	DW _MOV_DI_SI
	MOV AL, 0
	JCXZ Help75
Help74:	PUSH CX
	MOV CX, 0FFFFh
	REPNE SCASB
	POP CX
	LOOP Help74
Help75:	DW _MOV_SI_DI
	RET
;Help72 ENDP

;GLOBAL Help77
Help77:  ; PROC NEAR
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
	MOV BYTE [ES:MD.TmpErr+1], 0
	MOV BYTE [ES:MD.TmpErr+101], 0
	MOV DX, Empty_S
	CALL NgLine
	POP AX
	POP DX
	POP BP
	RET
;Help77 ENDP

;GLOBAL RdEntry
RdEntry:  ; PROC NEAR
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	MOV SI, [HlpData.HlpBkLn]
	MOV DI, [HlpData.HlpBkFr]
	CMP WORD [HlpData.HlpMode], 0
	JNE RdEnt1
	MOV AX, [HlpData.HlpFrst]
	MOV [HlpData.HlpBkFr], AX
	DW _XOR_SI_SI
	DW _XOR_DI_DI
RdEnt1:	MOV BX, [HlpData.HlpHndl]
	MOV DX, [HlpData.HlpOffs+0]
	MOV CX, [HlpData.HlpOffs+2]
	CALL SeekDsk
	JC RdEnt2
	MOV CX, 1Ah
	MOV DX, HlpData_HlpPrms
	CALL ReadDsk
	JC RdEnt2
	CALL DeCode
	MOV CX, [HlpData.HlpSize]
	CMP CX, LenHelp-20h
	CMC
	JC RdEnt2
	MOV DX, HlpData_size
	CALL ReadDsk
	JC RdEnt2
	CALL DeCode
	MOV AX, [HlpData.HlpMode]
	SUB [HlpData.HlpLins], AX
	MOV [HlpData.HlpFrst], DI
	MOV [HlpData.HlpCur], SI
RdEnt2:	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	RET
;RdEntry ENDP

;GLOBAL SeekDsk
SeekDsk:  ; PROC NEAR
	PUSH SI
	DW _MOV_SI_DX
	MOV AX, 4200h
	CALL Intr21
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
	CALL Intr21
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

F65_00:	CALL HidCur  ; Alt F5 - memory info
	PUSH ES
	POP DS
	MOV BYTE [MD.HlpPage], 30
	MOV AX, 5802h  ; MCB analisis
	INT 21h
	PUSH AX
	PUSHF
	JC F65_01
	MOV BX, 1
	MOV AX, 5803h
	INT 21h
F65_01:	MOV SI, MD_BlkList
	DW _MOV_DI_SI
	MOV AX, SegDOS
	STOSW
	STOSW
	PUSH AX
	MOV AH, 52h
	INT 21h
	MOV AX, [ES:BX-2]
	PUSH DS
	POP ES
	POP BX
	MOV DS, AX
	INC AX
	JMP F65_04
F65_02:	INC AX
	MOV BX, [1]
	MOV CX, ES
	DW _CMP_AX_CX
	JNE F65_03
	DW _XOR_BX_BX
F65_03:	CMP BYTE [ES:MD.LoadFl], 0
	JE F65_04
	PUSH AX
	SUB AX, STRICT WORD (Init00-Start+Base)>>4
	CMP AX, [SS:RunPar]
	POP AX
	JNE F65_04
	DW _XOR_BX_BX
F65_04:	STOSW
	DW _MOV_AX_BX
	STOSW
	MOV AX, DS
	ADD AX, [3]
	INC AX
	CMP BYTE [0], 'M'
	MOV DS, AX
	JE F65_02
	INC AX
	STOSW
	DW _XOR_AX_AX
	STOSW
	PUSH ES
	POP DS
	STOSW
	POPF
	POP BX
	JC F65_05
	MOV BH, 0
	MOV AX, 5803h
	INT 21h
F65_05:	MOV DI, MD_MemList  ; Program analisis
	PUSH DI
	DW _MOV_DX_SI
F65_06:	CMP DI, MD_MemList+LenMenu-(7+12+1+MaxVect)
	JAE F65_09
	LODSW
	DW _MOV_BX_AX
	LODSW
	DW _OR_AX_AX
	JE F65_10
	DW _CMP_AX_BX
	JE F65_12
	DW _MOV_BP_DX
F65_07:	CMP AX, [DS:BP]
	JE F65_08
	ADD BP, 4
	CMP WORD [DS:BP+4], 0
	JNE F65_07
	MOV BP, 1
	MOV CX, [SI]
	DW _SUB_CX_BX
	DEC CX
	PUSH SI
	DW _MOV_SI_DX
	JMP F65_13
F65_08:	CMP WORD [SI+4], 0
	JNE F65_06
F65_09:	DW _XOR_AX_AX
	STOSB
	STOSW
	JMP F65_31
F65_10:	INC AX  ; Free block
	CMP WORD [SI+2], 0
	JNE F65_11
	CMP WORD [SI+4], 0
	JE F65_11
	ADD SI, 4
	JMP F65_10
F65_11:	DW _MOV_BP_AX
	MOV CX, [SI]
	DW _SUB_CX_BX
	DEC CX
	JMP F65_15
F65_12:	PUSH SI  ; Program block
	DW _MOV_SI_DX
	DW _XOR_BP_BP
	DW _XOR_CX_CX
F65_13:	LODSW
	CMP BX, [SI]
	JNE F65_14
	INC BP
	ADD CX, [SI+2]
	DW _SUB_CX_AX
	DEC CX
F65_14:	LODSW
	CMP WORD [SI+4], 0
	JNE F65_13
	POP SI
F65_15:	MOV AL, 0
	STOSB
	DW _MOV_AX_BX
	STOSW
	DW _MOV_AX_BP
	STOSW
	DW _MOV_AX_CX
	STOSW
	MOV BYTE [ES:DI+12], 0
	PUSH SI  ; Searching for name
	PUSH CS
	POP DS
	CMP WORD [ES:SI-2], 0  ; Free memory
	JNE F65_16
	MOV SI, FrMem_S
	JMP F65_28
F65_16:	CMP BX, SegDOS  ; DOS area
	JNE F65_18
	PUSH CS
	POP DS
	MOV SI, DosMe_S
	MOV CX, 4
	REP MOVSB
	MOV AX, [ES:MD.VerDOS]
	MOV CX, 12-4-4
	DW _MOV_BL_AH
	CALL HexDec
	CMP AL, '0'
	JE F65_17
	STOSB
	DEC CX
F65_17:	DW _MOV_AL_AH
	STOSB
	MOV AL, '.'
	STOSB
	DW _MOV_AL_BL
	CALL HexDec
	STOSW
	JMP F65_29
F65_18:	PUSH SS  ; Releasable program
	POP DS
	MOV SI, LastRes+LAST.PrgList
	MOV CX, [LastRes+LAST.Counter]
	JCXZ F65_21
F65_19:	PUSH DS
	LODSW
	MOV DS, AX
	CMP BX, [0]
	POP DS
	LOOPNE F65_19
	JNE F65_21
	OR BYTE [ES:DI-7], 1
	MOV DS, AX
	PUSH DI  ; Vectors
	ADD DI, 12
	MOV SI, 14
	MOVSB
	MOV CX, MaxVect
F65_20:	MOVSB
	LODSW
	LODSW
	LOOP F65_20
	POP DI
	MOV SI, 2
	JMP F65_28
F65_21:	POP SI  ; System area
	PUSH SI
	DW _MOV_AX_BX
	XCHG AX, [ES:SI-2]
	CMP AX, STRICT WORD 8
	JA F65_22
	PUSH CS
	POP DS
	MOV SI, Syst_S
	JMP F65_28
F65_22:	DW _CMP_AX_BX  ; Other programs
	JNE F65_25
	MOV DS, BX  ; Check environment
	MOV CX, [2Ch]
	JCXZ F65_24
	DW _CMP_BX_CX
	JE F65_24
	PUSH ES
	POP DS
	DW _MOV_SI_DX
F65_23:	CMP WORD [SI+4], 0
	JE F65_24
	LODSW
	DW _CMP_AX_CX
	LODSW
	JNE F65_23
	DEC CX
	MOV DS, CX
	MOV SI, 11h
	CMP BX, [1]
	JE F65_26
F65_24:	CMP BYTE [ES:MD.VerDOS], 4  ; Check DOS version
	JAE F65_39
	PUSH DX
	MOV AX, 4452h
	INT 21h
	POP DX
	JC F65_25
	CMP AL, 65h
	JB F65_25
F65_39:	DW _MOV_AX_BX
	DEC AX
	MOV DS, AX
	MOV SI, 8
	PUSH DI
	MOV DI, MemData.MemTmp
	PUSH DI
	MOV CX, 8
	REP MOVSB
	MOV AL, 0
	STOSB
	PUSH ES
	POP DS
	POP SI
	POP DI
	JMP F65_28
F65_25:	PUSH CS  ; Unknown program
	POP DS
	MOV SI, Unknw_S
	JMP F65_28
F65_26:	DEC SI  ; Get name from environment
	LODSW
	DW _OR_AX_AX
	JNE F65_26
	INC SI
	INC SI
	CMP WORD [SI-2], 1
	JE F65_27
	CMP BYTE [ES:MD.VerDOS], 4
	JAE F65_24
	MOV DS, BX
	CMP BX, [16h]
	JNE F65_24
	PUSH SS
	POP DS
	MOV SI, Command
F65_27:	CALL CutPath
	CMP BYTE [SI], 0
	JE F65_24
F65_28:	MOV CX, 12
F65_29:	LODSB
	CMP AL, 0
	JNE F65_30
	DEC SI
	MOV AL, ' '
F65_30:	STOSB
	LOOP F65_29
	ADD DI, MaxVect+1
	PUSH ES
	POP DS
	POP SI
	JMP F65_08
F65_31:	POP BP  ; Vectors
	DW _XOR_SI_SI
	MOV DS, SI
	MOV CX, 4
F65_32:	LODSW
	SHR AX, CL
	DW _MOV_DI_AX
	LODSW
	DW _ADD_AX_DI  ; AX = vector address
	DW _MOV_BX_DX
	CMP AX, [ES:BX]
	JB F65_35
F65_33:	CMP WORD [ES:BX+4], 0
	JE F65_35
	ADD BX, 4
	CMP AX, [ES:BX]
	JAE F65_33
	MOV DI, [ES:BX-2]  ; DI = owner
	DW _MOV_BX_BP
F65_34:	MOV AX, [ES:BX+1]
	ADD BX, 7+12+1+MaxVect
	DW _OR_AX_AX
	JE F65_35
	DW _CMP_AX_DI
	JNE F65_34
	SUB BX, MaxVect+1
	TEST BYTE [ES:BX-7-12], 1
	JNZ F65_35  ; BX = vector list
	INC BYTE [ES:BX]
	MOV AL, [ES:BX]
	CMP AL, MaxVect+1
	JAE F65_35
	MOV AH, 0
	DW _ADD_BX_AX
	MOV [ES:BX], CH
F65_35:	INC CH
	JNE F65_32
	PUSH ES
	POP DS

	CALL PutMnu3  ; Output window
	MOV BP, Memo_P
	MOV BX, 203h
	MOV DH, [MD.Lines]
	SUB DH, 3
	MOV DL, 76
	MOV SI, MD.WinBuf
	CALL SavWin
	MOV AH, [CS:BP]
	CALL Color
	CALL MinBox
	PUSH SI
	PUSH CS
	POP DS
	PUSH BX
	INC BH
	MOV BL, 40
	MOV SI, Mem0_S
	CALL CntLine
	POP BX
	CALL BasAdr
	ADD DI, 2*165
	PUSH DI
	DW _MOV_AL_DL
	SUB AL, 12
	MOV SI, Mem1_S
	CALL NgLine
	POP SI
	ADD SI, 2*75
	PUSH DX
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 5
	PUSH BX
	CALL BasAdr
	DW _XCHG_SI_DI
	SUB DL, 10
	MOV DH, 0
	MOV CX, 3
	MOV BX, (('Ç'*256)&0FF00H)+('¶'&0FFH)  ; !!
	MOV AL, 'Ä'
	CALL BoxLine
	DW _MOV_DI_SI
	CALL BoxLine
	POP BX
	INC BH
	MOV BL, 40
	MOV SI, Mem2_S
	CALL CntLine
	POP BX
	POP DX
	PUSH ES
	POP DS
	CALL Window
	DW _XOR_BP_BP
	DW _XOR_DI_DI
	MOV WORD [MemData.MemCur], 2
	MOV WORD [MemData.MemFrst], 2
	MOV BYTE [MemData.MemMenu], 0
	MOV BYTE [MemData.MemMous], 0
	MOV BYTE [MD.WinMous], 0
	MOV BYTE [MD.MousEnt], 0
	MOV WORD [MD.MousTim+2], 0FFFFh

F65_40:	DW _MOV_CX_DI  ; Test parameters
	DW _CMP_BP_DI
	JAE F65_41
	DW _MOV_DI_BP
F65_41:	DW _MOV_AL_DH
	SUB AL, 9
	CBW
	DW _ADD_AX_DI
	DW _CMP_BP_AX
	JB F65_42
	DW _SUB_AX_DI
	DW _MOV_DI_BP
	DW _SUB_DI_AX
	INC DI
F65_42:	TEST BYTE [MemData.MemMous], 2
	JZ Mous53
	CALL MemAddr
	TEST BYTE [SI], 1
	JZ Mous54
	TEST BYTE [MD.WinMous], 2
	JNZ Mous51
	OR BYTE [MD.WinMous], 2
	TEST BYTE [SI], 2
	JNZ Mous51
	OR BYTE [MD.WinMous], 4
Mous51:	MOV AL, [SI]
	AND AL, 1
	TEST BYTE [MD.WinMous], 4
	JZ Mous52
	OR AL, 2
Mous52:	CMP AL, [SI]
	JE Mous54
	MOV [SI], AL
	DW _CMP_DI_CX
	JNE Mous54
	MOV AX, 2
	CALL MemCurs
	JMP Mous54
Mous53:	AND BYTE [MD.WinMous], 1
Mous54:	DW _MOV_AX_DI
	XCHG BP, [MemData.MemCur]
	XCHG DI, [MemData.MemFrst]
	DW _SUB_AX_DI
	JNE F65_43
	CMP BP, [MemData.MemCur]
	JNE F65_43
	JMP F65_48
F65_43:	PUSH AX  ; Reset cursor
	DW _XOR_AX_AX
	CALL MemCurs
	POP CX
	JCXZ F65_47
	PUSH CX  ; Output lines
	PUSH BX
	MOV BP, [MemData.MemFrst]
	CALL MemAddr
	DW _MOV_CL_DH
	SUB CL, 9
	MOV CH, 0
	ADD BX, 405h
F65_44:	CALL MemItem
	INC BH
	LOOP F65_44
	POP BX
	POP CX
	PUSH DX  ; Output screen
	PUSH BX
	ADD BX, 405h
	SUB DH, 9
	DW _MOV_AL_DH
	DEC AX
	MOV AH, 6
	CMP CX, 1
	JE F65_45
	CMP CX, -1
	JNE F65_46
	MOV AX, 700h
F65_45:	DW _MOV_CX_BX
	MOV DL, 63
	DEC DH
	DW _ADD_DX_CX
	PUSH AX
	MOV AH, [CS:Memo_P]
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
F65_46:	MOV DL, 64
	CALL Window
	POP BX
	POP DX
F65_47:	MOV BP, [MemData.MemCur]  ; Set cursor
	MOV DI, [MemData.MemFrst]
	MOV AX, 2
	CALL MemCurs
F65_48:	CALL GetMous  ; Input
	JNZ Mous01
	MOV BYTE [MD.WinMous], 0
	MOV BYTE [MD.MousEnt], 0
F65_49:	PUSH DX
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 4
	ADD BL, 25
	MOV DX, 118h
	MOV BP, Memo1_P
	MOV SI, Memo_D
	MOV CL, [MemData.MemMenu]
	MOV AL, 1
	CALL MinMnu
	MOV [MemData.MemMenu], CL
	POP BX
	POP DX
	MOV BP, [MemData.MemCur]
	MOV DI, [MemData.MemFrst]
	CMP AH, 0FCh
	JE Mous00
	MOV BYTE [MemData.MemMous], 0
	MOV SI, Memo_T
	CALL Case
	JMP F65_48

Mous00:	CALL GetMous  ; Mouse support
Mous01:	CALL ClrKbd
	DW _MOV_SI_CX
	TEST AL, 4
	JZ Mous09
	MOV AL, 'x'
	CALL TypMous
Mous07:	CALL GetMous
	CALL ClrKbd
	TEST AL, 4
	JNZ Mous07
	PUSH AX
	MOV AL, 0
	CALL TypMous
	POP AX
	TEST AL, 3
	JNZ Mous09
	JMP F65_83
Mous09:	MOV [MemData.MemMous], AL
	PUSH DX
	PUSH BX
	ADD BX, 404h
	SUB DX, 90Ah
	CALL InWind
	POP BX
	POP DX
	JNC Mous10
	CMP BYTE [MD.WinMous], 0
	JZ Mous06
	MOV BP, [MemData.MemCur]
	MOV DI, [MemData.MemFrst]
	DW _MOV_AL_BH
	ADD AL, 4
	DW _CMP_CH_AL
	JAE Mous02
	JMP F65_50
Mous02:	DW _MOV_AL_BH
	DW _ADD_AL_DH
	SUB AL, 5
	DW _CMP_CH_AL
	JB Mous05
	JMP F65_52
Mous06:	TEST AL, 1
	JZ Mous05
	PUSH DX
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 4
	MOV BL, 28
	MOV DX, 118h
	CALL InWind
	POP BX
	POP DX
	JC Mous08
	JMP F65_49
Mous08:	CALL GetMous
	JNZ Mous01  ; This is a -0x80 relative jump. TASM 5.3 generates the longer JZ+JMP without the `SHORT' here. TASM 4.1 generates the JNZ correctly with or without `SHORT'.
	DW _MOV_CX_SI
	PUSH DX
	SUB DX, 102h
	CALL InWind
	POP DX
	JNC Mous05
	JMP F65_83
Mous05:	JMP F65_48
Mous10:	OR BYTE [MD.WinMous], 1
	PUSH CX
	DW _SUB_CH_BH
	SUB CH, 4
	DW _MOV_CL_CH
	MOV CH, 0
	MOV DI, [MemData.MemFrst]
	DW _ADD_CX_DI
	DW _XOR_BP_BP
	CALL MemEnd
	DEC BP
	POP SI
	DW _XCHG_BP_CX
	DW _CMP_BP_CX
	JBE Mous12
	DW _MOV_BP_CX
	JMP F65_40
Mous12:	TEST AL, 2
	JNZ F65_51
	PUSH DX
	PUSH BX
	DW _MOV_AX_SI
	DW _MOV_SI_BP
	DW _MOV_BH_AH
	ADD BL, 4
	SUB DL, 10
	MOV DH, 1
	CALL DoublMo
	POP BX
	POP DX
	JC F65_51
	JE Mous05
	MOV BYTE [MD.MousEnt], 0
	MOV WORD [MD.MousTim+2], 0FFFFh
	MOV AL, 0
	CALL TypMous
	CALL MemAddr
	TEST BYTE [SI], 1
	JZ Mous05
	DW _MOV_CX_BP
	DW _XOR_BP_BP
Mous15:	CALL MemAddr
	CMP WORD [SI+1], 0
	JE Mous16
	AND BYTE [SI], 1
	INC BP
	JMP Mous15
Mous16:	JMP F65_73

F65_50:	DW _OR_BP_BP  ; Up
	JE F65_51
	DEC BP
F65_51:	JMP F65_40

F65_52:	INC BP  ; Down
	CALL MemAddr
	CMP WORD [SI+1], 0
	JNE F65_51
	DEC BP
	JMP F65_40

F65_54:	DW _XOR_BP_BP  ; Home
	JMP F65_40

F65_55:	CALL MemEnd  ; End
	DEC BP
	JMP F65_40

F65_56:	DW _MOV_AL_DH  ; PgUp
	SUB AL, 9
	CBW
	DW _MOV_SI_BP
	CALL PgUp
	DW _MOV_BP_SI
	JMP F65_40

F65_57:	PUSH BP  ; PgDn
	CALL MemEnd
	POP SI
	DW _MOV_AL_DH
	SUB AL, 9
	CBW
	CALL PgDn
	DW _MOV_BP_SI
	JMP F65_40

F65_60:	CALL MemAddr  ; Ins
	TEST BYTE [SI], 1
	JZ F65_61
	XOR BYTE [SI], 2
	MOV AX, 2
	CALL MemCurs
F65_61:	CMP BYTE [MD.InsDwn], 0
	JNE F65_52
	JMP F65_40

F65_62:	MOV AX, 2FFh  ; Grey +
	JMP F65_64

F65_63:	MOV AX, 0FDh  ; Grey -
F65_64:	MOV SI, MD_MemList
F65_65:	TEST BYTE [SI], 1
	JZ F65_66
	AND [SI], AL
	OR [SI], AH
F65_66:	ADD SI, 7+12+1+MaxVect
	CMP WORD [SI+1], 0
	JNE F65_65
	ADD WORD [MemData.MemFrst], 2
	MOV AX, [MemData.MemFrst]
	MOV [MemData.MemCur], AX
F65_67:	PUSH ES
	POP DS
	JMP F65_40

F65_70:	CMP CL, 0  ; Enter
	JE F65_71
	JMP F65_83
F65_71:	DW _MOV_CX_BP
	DW _XOR_BP_BP
F65_72:	CALL MemAddr
	CMP WORD [SI+1], 0
	JE F65_73
	TEST BYTE [SI], 2
	JNZ F65_74
	INC BP
	JMP F65_72
F65_73:	DW _MOV_BP_CX
	CALL MemAddr
	TEST BYTE [SI], 1
	JZ F65_67
	OR BYTE [SI], 2
F65_74:	DW _MOV_BP_CX
	MOV DI, MD.ErrBuf
	MOV CX, 256
	MOV AL, 0
	REP STOSB
	PUSH SS
	POP DS
	MOV CX, [LastRes+LAST.Counter]
	JCXZ F65_67
	DW _MOV_AX_CX
	DW _ADD_AX_AX
	ADD AX, STRICT WORD LastRes+LAST.PrgList-2
	DW _MOV_DI_AX
	PUSH DS  ; Save mouse cursor
	PUSH DX
	CALL SavMous
	MOV AL, 0
	CALL CurMous
	CALL RestVct  ; Restore vectors
	POP DX
	POP DS
F65_76:	PUSH DS  ; Release
	PUSH CX
	MOV DS, [DI]
	MOV AX, [0]
	DW _XOR_BP_BP
F65_77:	CALL MemAddr
	CMP WORD [ES:SI+1], 0
	JE F65_82
	INC BP
	CMP AX, [ES:SI+1]
	JNE F65_77
	TEST BYTE [ES:SI], 2
	JZ F65_80
	MOV CL, [14]
	MOV CH, 0
	JCXZ F65_79
	MOV SI, 15
F65_78:	MOV AL, [SI]
	MOV AH, 0
	DW _MOV_BP_AX
	CMP BYTE [ES:BP+MD.ErrBuf], 0
	JNE F65_80
	ADD SI, 5
	LOOP F65_78
F65_79:	MOV AX, Release
	CALL CallPSP
	JMP F65_82
F65_80:	MOV CL, [14]
	MOV CH, 0
	JCXZ F65_82
	MOV SI, 15
F65_81:	MOV AL, [SI]
	MOV AH, 0
	DW _MOV_BP_AX
	MOV BYTE [ES:BP+MD.ErrBuf], 1
	ADD SI, 5
	LOOP F65_81
F65_82:	POP CX
	POP DS
	DEC DI
	DEC DI
	LOOP F65_76
	PUSH DX  ; Set vectors
	PUSH BX
	PUSH ES
	POP DS
	CALL HookVct
	MOV AX, 2523h
	INT 21h
	CALL IniMous  ; Restore mouse
	POP BX
	POP DX

F65_83:	POP SI  ; Exit
	CALL ResWin
	DW _XOR_BX_BX
	MOV DH, [ES:MD.Lines]
	MOV DL, 0
	CALL Window
	JMP Func04

;GLOBAL MemAddr
MemAddr:  ; PROC NEAR  ; Set address
	PUSH DX
	PUSH AX
	MOV AX, 7+12+1+MaxVect
	MUL BP
	ADD AX, STRICT WORD MD_MemList
	DW _MOV_SI_AX
	POP AX
	POP DX
	RET
;MemAddr ENDP

;GLOBAL MemColr
MemColr:  ; PROC NEAR  ; Set color
	PUSH DI
	MOV DI, Memo_P
	DW _ADD_DI_AX
	MOV AL, ' '
	TEST BYTE [SI], 1
	JZ MemCo1
	MOV AL, ''
	TEST BYTE [SI], 2
	JZ MemCo1
	INC DI
	MOV AL, 'û'
MemCo1:	MOV AH, [CS:DI]
	CALL Color
	POP DI
	RET
;MemColr ENDP

;GLOBAL MemCurs
MemCurs:  ; PROC NEAR  ; Set/Reset cursor
	PUSH DI
	PUSH DX
	PUSH BX
	DW _MOV_CX_BP
	DW _SUB_CX_DI
	DW _ADD_BH_CL
	ADD BX, 405h
	SUB DL, 12
	DW _MOV_CL_DL
	MOV CH, 0
	CALL MemAddr
	CALL MemColr
	CALL BasAdr
	MOV [DI], AL
	DW _MOV_AL_AH
	CALL MvsColr
	MOV DH, 1
	CALL Window
	POP BX
	POP DX
	POP DI
	RET
;MemCurs ENDP

;GLOBAL MemEnd
MemEnd:  ; PROC NEAR  ; Find end
	INC BP
	CALL MemAddr
	CMP WORD [SI+1], 0
	JNE MemEnd
	RET
;MemEnd ENDP

;GLOBAL MemItem
MemItem:  ; PROC NEAR  ; Output item
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	CALL BasAdr
	DW _XOR_AX_AX
	CALL MemColr
	DW _MOV_CL_DL
	SUB CL, 12
	MOV CH, 0
	PUSH DI
	PUSH AX
	MOV AL, ' '
	REP STOSW
	POP AX
	POP DI
	CMP WORD [SI+1], 0
	JNE MemIt1
	JMP MemIt4
MemIt1:	INC SI
	STOSW
	INC DI
	INC DI
	LODSB
	PUSH AX
	LODSB
	CALL HexByt
	POP AX
	CALL HexByt
	PUSH DI
	LODSW
	DW _XOR_BX_BX
	DW _MOV_CX_AX
	MOV DI, MD.TmpBuf
	MOV AL, 2
	CALL Number
	LODSW
	DW _MOV_BL_AH
	MOV BH, 0
	MOV CL, 4
	SHR BL, CL
	SHL AX, CL
	DW _MOV_CX_AX
	MOV DI, MD.TmpBuf+20
	MOV AL, 3
	CALL Number
	POP DI
	PUSH SI
	MOV SI, MD.TmpBuf+4
	MOV CX, 6
	MOV AH, [DI+1]
	CALL MvsBwe
	MOV SI, MD.TmpBuf+23
	MOV CX, 10
	CALL MvsBwe
	POP SI
	ADD DI, 2*3
	MOV CX, 12
	CALL MvsBwe
	LODSB
	MOV CX, MaxVect
	PUSH SI
	ADD DI, 2*2
MemIt2:	CMP AL, 0
	JE MemIt3
	INC DI
	INC DI
	PUSH AX
	LODSB
	CALL HexByt
	POP AX
	DEC AX
	LOOP MemIt2
	JE MemIt3
	SUB DI, 2*2
	MOV AL, '.'
	STOSB
	INC DI
	STOSB
	INC DI
	STOSB
MemIt3:	POP SI
	ADD SI, MaxVect
MemIt4:	POP BX
	POP CX
	POP DX
	POP DI
	RET
;MemItem ENDP

F67_00:	CALL HidCur  ; Alt F7 - file find
	CALL PutMnu3
	MOV BP, Find_P
	MOV BX, 203h
	MOV DH, [ES:MD.Lines]
	SUB DH, 3
	MOV DL, 76
	MOV SI, MD.WinBuf
	CALL SavWin
	MOV AH, [CS:BP]
	CALL Color
	CALL MinBox
	PUSH SI
	PUSH CS
	POP DS
	PUSH BX
	INC BH
	MOV BL, 40
	MOV SI, Find0_S
	CALL CntLine
	POP BX
F67_01:	PUSH CS  ; Clear window
	POP DS
	PUSH BX
	ADD BH, 2
	DW _MOV_CL_DH
	SUB CL, 5
	MOV CH, 0
	MOV SI, (('º'*256)&0FF00H)+('º'&0FFH)  ; !!
	MOV AL, ' '
	MOV BP, Find_P
	MOV AH, [CS:BP]
	CALL Color
F67_02:	CALL StdLine
	LOOP F67_02
	SUB BH, 5
	MOV SI, (('Ç'*256)&0FF00H)+('¶'&0FFH)  ; !!
	MOV AL, 'Ä'
	CALL StdLine
	MOV AL, 25
	ADD BL, 5
	CALL BasAdr
	MOV SI, Find1_S
	CALL NgLine
	ADD BH, 2
	CALL BasAdr
	MOV SI, Find2_S
	CALL NgLine
	PUSH ES
	POP DS
	POP BX
	CALL Window
	PUSH DX  ; Input parameters
	PUSH BX
	DW _ADD_BH_DH
	MOV DH, 9
	DW _SUB_BH_DH
	MOV BP, Find_B
	CALL Dialog
	POP BX
	POP DX
	JE F67_03
	JMP F67_25
F67_03:	MOV BP, Find_P  ; Clear window
	MOV AH, [CS:BP]
	CALL Color
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 8
	MOV SI, (('º'*256)&0FF00H)+('º'&0FFH)  ; !!
	MOV AL, ' '
	CALL StdLine
	CALL StdLine
	INC BH
	CALL StdLine
	CALL StdLine
	SUB BH, 3
	MOV SI, (('Ç'*256)&0FF00H)+('¶'&0FFH)  ; !!
	MOV AL, 'Ä'
	CALL StdLine
	PUSH CS
	POP DS
	MOV AL, 25
	ADD BL, 5
	CALL BasAdr
	MOV SI, Find3_S
	CALL NgLine
	INC BH
	MOV BL, 40
	MOV SI, Find5_S
	CALL CntLine
	POP BX
	CALL Window
	PUSH ES  ; Find files
	POP DS
	MOV [FndData.FndBg], BX
	MOV [FndData.FndSz], DX
	DW _XOR_AX_AX
	MOV [FndData.FndCur], AX
	MOV [FndData.FndFrst], AX
	MOV [FndData.FndNumb], AX
	MOV [FndData.FndFls], AX
	MOV [FndData.FndMode], AL
	MOV [FndData.FndMenu], AL
	MOV [MD.WinMous], AL
	MOV [MD.MousEnt], AL
	MOV WORD [MD.MousTim+2], 0FFFFh
	MOV [ViewDat.ViTxHex], AL
	MOV AX, ES
	ADD AX, [MD.FreMem2]
	SUB AX, [MD.ViewSeg]
	DW _MOV_DL_AH
	MOV DH, 0
	MOV CL, 4
	SHL AX, CL
	SHR DX, CL
	MOV CX, LenFnf
	DIV CX
	DEC AX
	MOV [FndData.FndSize], AX
	MOV BYTE [FndData.FndDrv], 'A'
F67_08:	MOV DX, MD.TmpErr
	MOV SI, MD.FindStr
	DW _MOV_DI_DX
	LODSW
	STOSW
V1 EQU '*:'
	CMP AX, STRICT WORD V1
	JNE F67_09
	DW _MOV_AX_SI
	CALL CutPath
	DW _CMP_AX_SI
	DW _MOV_SI_AX
	JNE F67_09
	MOV AL, '\'
	STOSB
F67_09:	MOV CX, LenPath+13-2
	REP MOVSB
	DW _MOV_SI_DX
	CALL NormStr
	CMP BYTE [SI], 0
	JE F67_14
	CALL CutPath
	MOV WORD [SI], 'A'
	PUSH BX
	DW _MOV_SI_DX
	MOV BP, [SI]
	CMP BP, '*:'
	JNE F67_15
F67_10:	MOV CL, [FndData.FndDrv]
	MOV [SI], CL
	INC BYTE [FndData.FndDrv]
	SUB CL, 'A'
	MOV CH, 0
	DW _XOR_BX_BX
	MOV AX, 150Bh
	INT 2Fh
	CMP BX, 0ADADh
	JNE F67_11
	DW _OR_AX_AX
	JNE F67_13
F67_11:	DW _MOV_BX_CX
	INC BX
	MOV AX, 4409h
	INT 21h
	JC F67_12
	TEST DH, 10h
	JNZ F67_15
F67_12:	MOV AX, 4408h
	INT 21h
	JC F67_13
	CMP AL, 1
	JE F67_15
F67_13:	CMP BYTE [FndData.FndDrv], 'Z'
	JBE F67_10
	POP BX
	JMP F67_18
F67_14:	MOV DX, [FndData.FndSz]
	JMP F67_25
F67_15:	POP BX
	DW _MOV_DX_SI
	CALL ChgDisk
	JC F67_14
	MOV DI, MD.TmpBuf
	LODSW
	CMP AH, ':'
	JE F67_16
	DEC SI
	DEC SI
	MOV AX, [MD.DosPth]
F67_16:	CALL UpCase
	STOSW
	SUB AL, 'A'-1
	DW _MOV_DL_AL
	MOV CX, LenPath+13
	MOV AL, '\'
	CMP AL, [SI]
	JE F67_17
	STOSB
	DW _XCHG_SI_DI
	MOV AH, 47h
	CALL Intr21
	DW _XCHG_SI_DI
	JC F67_19
	MOV AL, 0
	REPNE SCASB
	DEC DI
	CALL AddFile
F67_17:	REP MOVSB
	MOV AL, 0
	STOSB
	MOV SI, MD.TmpBuf
	CALL CutPath
	MOV BYTE [SI], 0
	MOV WORD [MD.FncAddr], FindFil
	MOV AL, 10h
	CALL FindFil
	DW _OR_AH_AH
	JNZ F67_18
	CMP BP, '*:'
	JNE F67_18
	CMP BYTE [FndData.FndDrv], 'Z'
	JA F67_18
	JMP F67_08
F67_18:	TEST BYTE [FndData.FndMode], 2
	JZ F67_19
	MOV AL, [FndData.FndMenu]
	CMP AL, 0
	JE F67_19
	MOV DX, [FndData.FndSz]
	JMP F67_23
F67_19:	MOV DI, MD.TmpBuf  ; Output NNN files found
	PUSH DI
	MOV CX, [FndData.FndFls]
	DW _XOR_BX_BX
	MOV AL, 1
	CALL Number
	PUSH CS
	POP DS
	MOV SI, FnFl6_S
	MOV CX, 15
	CALL MvzLine
	CMP WORD [ES:FndData.FndFls], 1
	JNE F67_20
	DEC DI
F67_20:	MOV SI, FnFl7_S
	MOV CX, 15
	REP MOVSB
	PUSH ES
	POP DS
	POP SI
	MOV BX, [FndData.FndBg]
	MOV DX, [FndData.FndSz]
	PUSH DX
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 5
	ADD BL, 5
	CALL BasAdr
	SUB DL, 12
	MOV DH, 0
	DW _MOV_CX_DX
	MOV AH, [DI+1]
	MOV AL, 0
	PUSH DI
	REP STOSW
	POP DI
	MOV BP, Find_P
	DW _MOV_AX_DX
	CALL NgLine
	MOV DH, 1
	CALL Window
	POP BX
	POP DX
	PUSH BX
	PUSH CS
	POP DS
	MOV SI, Find6_S
	DW _ADD_BH_DH
	SUB BH, 4
	MOV BL, 40
	CALL CntLine
	PUSH ES
	POP DS
	POP BX
	MOV BYTE [FndData.FndMenu], 1
	MOV BP, [FndData.FndCur]
	MOV DI, [FndData.FndFrst]
	DW _OR_BP_BP
	JE F67_21
	MOV AH, [CS:Find_P+1]
	CALL FndCurs
F67_21:	CALL GetMous  ; Dialog
	MOV AH, 0FCh
	JNZ F67_22
	MOV BYTE [MD.WinMous], 0
	MOV BYTE [MD.MousEnt], 0
	PUSH DX
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 4
	ADD BL, 18
	MOV DX, 125h
	MOV BP, FnFl_P
	MOV SI, Find6_D
	MOV CL, [FndData.FndMenu]
	MOV AL, [CS:Find_B+BOXHD.bKeyBar]
	CALL MinMnu
	MOV [FndData.FndMenu], CL
	POP BX
	POP DX
F67_22:	MOV CL, 1
	CALL FndMove
	DW _OR_AH_AH
	JE F67_21
F67_23:	CMP AL, 1
	JE F67_30
	JA F67_25
	JMP F67_01
F67_25:	POP SI
	CALL ResWin
	CALL Window
F67_26:	JMP Func04
F67_30:	POP SI  ; Go to ...
	CALL ResWin
	CALL Window
	CMP WORD [FndData.FndNumb], 0
	JE F67_26
	MOV BP, [FndData.FndCur]
F67_31:	DW _MOV_AX_BP
	CALL FndAdr
	DEC BP
	CMP BYTE [SI], ' '
	JE F67_31
	DW _MOV_DX_SI
	CALL ChgDisk
	JC F67_35
	MOV AH, 3Bh
	CALL Intr21
	JC F67_35
	MOV DL, [SI]
	SUB DL, 'A'
	MOV AH, 0Eh
	INT 21h
	PUSH ES  ; Set cursor
	PUSH DS
	MOV DS, [ES:MD.WCBcrn]
	CMP BYTE [WCBdef.WinTyp], 0
	JE F67_32
	CALL InvWCB
F67_32:	PUSH DS
	POP ES
	POP DS
	MOV DI, WCBdef.WinPath
	MOV CX, LenPath+1
	REP MOVSB
	PUSH ES
	POP DS
	POP ES
	MOV DI, WCBdef.DskBuf
	LEA BX, [DI+FILENT_size]
	MOV [WCBdef.CurAdr], DI
	MOV [WCBdef.First], BX
	MOV [WCBdef.EndBuf], BX
	MOV BYTE [DI+FILENT.NameF], 0
	MOV BYTE [BX+FILENT.NameF], 0
	PUSH ES
	PUSH DS
	MOV AX, [ES:FndData.FndCur]
	CALL FndAdr
	CMP BYTE [SI], ' '
	JNE F67_33
	POP ES
	PUSH DI
	ADD SI, 3
	MOV CX, 12
	REP MOVSB
	MOV AL, 0
	STOSB
	POP SI
	CALL NormStr
	PUSH ES
F67_33:	POP DS
	POP ES
	MOV AH, 19h
	INT 21h
	ADD AL, 'A'
	CMP AL, [ES:MD.DosPth]
	JNE F67_34
	JMP F24_02
F67_34:	JMP FncEx1
F67_35:	JMP Func04

;GLOBAL FindFil
FindFil:  ; PROC NEAR  ; Find files
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	TEST AL, 10h
	JZ FnFl10
	PUSH ES  ; Output 'Sanning: PATH'
	POP DS
	CALL FndStat
	DW _MOV_DI_DX  ; Find files
	MOV CX, LenPath+13
	MOV AL, 0
	REPNE SCASB
	DEC DI
	DW _MOV_SI_DI
	DW _SUB_SI_DX
	CMP SI, LenFnf
	JB FnFl11
FnFl10:	DW _XOR_AX_AX
	JMP FnFl51
FnFl11:	MOV AL, [DI-1]
	CMP AL, ':'
	JE FnFl12
	CMP AL, '\'
	JE FnFl12
	MOV AL, '\'
	STOSB
FnFl12:	MOV SI, MD.FindStr
	CALL CutPath
	PUSH DI
	MOV DI, MD.TmpErr+20
	PUSH DI
	MOV BX, Mask_S+1
FnFl13:	LODSB
	CMP AL, 0
	JE FnFl15
	CMP AL, '.'
	JNE FnFl14
	MOV BX, Mask_S+4
FnFl14:	STOSB
	JMP FnFl13
FnFl15:	PUSH CS
	POP DS
	DW _MOV_SI_BX
	MOV CX, 4
	REP MOVSB
	PUSH ES
	POP DS
	POP SI
	MOV DI, MD.TmpErr
	CALL Convert
	DW _MOV_SI_DI
	POP DI
	CALL UnConv
	MOV BYTE [FndData.FndDir], 0
	JMP FnFl40
FnFl20:	TEST BYTE [FndData.FndDir], 1  ; First file in directory
	JNZ FnFl30
	OR BYTE [FndData.FndDir], 1
	MOV AX, [FndData.FndNumb]
	DW _OR_AX_AX
	JE FnFl22
	INC AX
	INC AX
	CMP AX, [FndData.FndSize]
	JB FnFl21
	JMP FnFl43  ; Out of memory ???
FnFl21:	MOV DI, MD.TmpErr
	MOV CX, LenFnf
	MOV AL, 0
	REP STOSB
	CALL FndStuf
FnFl22:	MOV SI, MD.TmpBuf
	MOV DI, MD.TmpErr
	MOV CX, LenPath+13
	PUSH DI
	REP MOVSB
	POP DI
	DW _MOV_SI_DI
	CALL CutPath
	DW _MOV_AX_SI
	DW _SUB_AX_DI
	CMP AX, STRICT WORD 3
	JBE FnFl23
	DEC SI
FnFl23:	MOV BYTE [SI], 0
	DW _MOV_SI_DI
	CALL PathLin
	MOV CX, LenFnf
	CALL FilZero
	CALL FndStuf
FnFl30:	MOV DI, MD.TmpErr  ; Find next file
	MOV CX, LenFnf
	MOV AL, ' '
	PUSH DI
	REP STOSB
	POP DI
	ADD DI, 3
	PUSH DI
	MOV SI, MD.DTA+DTAs.FilName
	MOV AH, [MD.DTA+DTAs.FilAttr]
FnFl31:	LODSB
	CMP AL, 0
	JE FnFl33
	TEST AH, 10h
	JNZ FnFl32
	CALL LowCase
FnFl32:	STOSB
	JMP FnFl31
FnFl33:	POP DI
	ADD DI, 14
	TEST AH, 10h
	JZ FnFl34
	PUSH CS
	POP DS
	ADD DI, 6
	MOV SI, SubDir+1
	MOV CX, 7
	REP MOVSB
	PUSH ES
	POP DS
	JMP FnFl35
FnFl34:	MOV CX, [MD.DTA+DTAs.FilSize+0]
	MOV BX, [MD.DTA+DTAs.FilSize+2]
	MOV AL, 3
	CALL Number
	MOV BYTE [DI], ' '
FnFl35:	ADD DI, 3
	SHL AH, 1
	SHL AH, 1
	MOV AL, 'A'
	CALL FnFl60
	SHL AH, 1
	SHL AH, 1
	MOV AL, 'S'
	CALL FnFl60
	MOV AL, 'H'
	CALL FnFl60
	MOV AL, 'R'
	CALL FnFl60
	ADD DI, 3
	MOV AX, [MD.DTA+DTAs.FilDate]
	CALL PutDate
	CALL BufDate
	ADD DI, 3
	MOV AX, [MD.DTA+DTAs.FilTime]
	CALL PutTime
	CALL BufTime
	CALL FndStuf
	JC FnFl43  ; Out of memory ???
	INC WORD [FndData.FndFls]
FnFl40:	CALL FndBack
	JNC FnFl43
	MOV DX, MD.TmpBuf
	CALL ChgDisk
	JC FnFl43
	MOV AH, 4Fh
	TEST BYTE [FndData.FndDir], 2
	JNZ FnFl41
	OR BYTE [FndData.FndDir], 2
	MOV CX, 37h
	MOV AH, 4Eh
FnFl41:	CALL SetDTA
	CALL Intr21
	JNC FnFl44
	CMP AX, STRICT WORD 53h
	JE FnFl43
	JMP FnFl50
FnFl42:	CMP AX, STRICT WORD 53h
	JNE FnFl40
FnFl43:	MOV AX, 100h
	JMP FnFl51
FnFl44:	CMP BYTE [MD.DTA+DTAs.FilName], '.'
	JE FnFl40
	CMP BYTE [MD.SrchStr], 0  ; Find by contents
	JE FnFl47
	CALL V81_00
	MOV DX, MD.TmpBuf
	DW _MOV_SI_DX
	CALL CutPath
	DW _MOV_DI_SI
	MOV SI, MD.DTA+DTAs.FilName
	MOV CX, 13
	REP MOVSB
	CALL FndStat
	MOV AL, 40h
	CALL OpenFil
	JC FnFl42
	DW _MOV_BX_AX
	MOV AX, ES
	ADD AX, [MD.FreMem2]
	SUB AX, [MD.ViewSeg]
	MOV BP, 8000h+80
	TEST AH, 0F0h
	JNZ FnFl45
	MOV CL, 4
	SHL AX, CL
	DW _CMP_AX_BP
	JAE FnFl45
	DW _MOV_BP_AX
FnFl45:	CMP BP, 4000
	JB FnFl48  ; Out of memory ???
	MOV AX, [FndData.FndNumb]
	INC AX
	CALL FndAdr
FnFl46:	CALL FndBack
	JNC FnFl48
	DW _MOV_CX_BP
	DW _XOR_DX_DX
	MOV AH, 3Fh
	CALL Intr21
	JC FnFl48
	DW _MOV_CX_AX
	DW _XOR_SI_SI
	CALL V82_00
	JNC FnFl49
	DW _CMP_CX_BP
	JB FnFl49
	MOV AX, 4201h
	MOV CX, -1
	MOV DX, -80
	CALL Intr21
	JMP FnFl46
FnFl47:	JMP FnFl20
FnFl48:	PUSH ES
	POP DS
	MOV AH, 3Eh
	CALL Intr21
	JMP FnFl43
FnFl49:	PUSHF
	PUSH ES
	POP DS
	MOV AH, 3Eh
	CALL Intr21
	POPF
	JNC FnFl47
	JMP FnFl40
FnFl50:	MOV SI, MD.TmpBuf  ; Exit
	CALL CutPath
	MOV BYTE [SI], 0
	CALL DirFunc
FnFl51:	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;FindFil ENDP

;GLOBAL FnFl60
FnFl60:  ; PROC NEAR
	SHL AH, 1
	JC FnFl61
	MOV AL, '.'
FnFl61:	STOSB
	RET
;FnFl60 ENDP

;GLOBAL FndBack
FndBack:  ; PROC NEAR  ; Background movement
	PUSH DS
	PUSH BP
	PUSH BX
	PUSH ES
	POP DS
FndBk1:	CALL GetMous
	MOV AH, 0FCh
	JNZ FndBk2
	MOV AH, 1
	INT 16h
	STC
	JZ FndBk5
	MOV AH, 0
	INT 16h
	DW _OR_AX_AX
	JE FndBk5
	CMP AX, STRICT WORD 2E03h
	JE FndBk5
	CMP AX, STRICT WORD 011Bh
	JE FndBk5
	CMP AX, STRICT WORD 3B00h
	JE FndBk4
FndBk2:	MOV BX, [FndData.FndBg]
	MOV DX, [FndData.FndSz]
	PUSH DX
	PUSH BX
	CMP BYTE [MD.WinMous], 0
	JNZ FndBk3
	DW _ADD_BH_DH
	SUB BH, 4
	ADD BL, 21
	MOV DX, 11Fh
	MOV BP, FnFl_P
	MOV DI, Find5_D
	MOV CH, 0
	MOV CL, [FndData.FndMenu]
	CALL MnMn10
	MOV [FndData.FndMenu], CL
	JNC FndBk3
	MOV AH, [CS:BP+0]
	MOV AL, [CS:BP+1]
	CALL MnMn40
FndBk3:	POP BX
	POP DX
	JC FndBk1
	MOV CL, 1
	CALL FndMove
	DW _OR_AH_AH
	JZ FndBk1
	OR BYTE [FndData.FndMode], 2
	MOV [FndData.FndMenu], AL
	JMP FndBk5
FndBk4:	CALL Help
	JMP FndBk1
FndBk5:	MOV BYTE [MD.WinMous], 0
	MOV BYTE [MD.MousEnt], 0
	POP BX
	POP BP
	POP DS
	RET
;FndBack ENDP

;GLOBAL FndStuf
FndStuf:  ; PROC NEAR  ; Add line
	PUSH DX
	PUSH BX
	PUSH ES
	POP DS
	MOV AX, [FndData.FndNumb]
	CMP [FndData.FndSize], AX
	JB FndSt4
	INC WORD [FndData.FndNumb]
	MOV DX, LenFnf
	MUL DX
	DW _MOV_DI_AX
	AND DI, 0Fh
	MOV CL, 4
	SHR AX, CL
	SHL DL, CL
	DW _OR_AH_DL
	ADD AX, [MD.ViewSeg]
	MOV ES, AX
	MOV SI, MD.TmpErr
	MOV CX, LenFnf
	REP MOVSB
	PUSH DS
	POP ES
	MOV BX, [FndData.FndBg]
	MOV DX, [FndData.FndSz]
	TEST BYTE [FndData.FndMode], 1
	JNZ FndSt1
	MOV CL, 0
	MOV AX, 4F00h
	CALL FndMove
	JMP FndSt3
FndSt1:	MOV BP, [FndData.FndNumb]
	DEC BP
	MOV DI, [FndData.FndFrst]
	DW _MOV_AX_BP
	DW _SUB_AX_DI
	ADD AX, STRICT WORD 8
	DW _OR_AH_AH
	JNE FndSt3
	DW _CMP_AL_DH
	JAE FndSt3
	MOV AH, [CS:Find_P]
	DW _OR_BP_BP
	JNE FndSt2
	MOV AH, [CS:Find_P+1]
FndSt2:	CALL FndCurs
FndSt3:	CLC
FndSt4:	POP BX
	POP DX
	RET
;FndStuf ENDP

;FndMove	PROC	NEAR			; Move the cursor
;GLOBAL FndMove
FndMove:
	MOV BP, [FndData.FndCur]
	MOV DI, [FndData.FndFrst]
	CMP AH, 0FCh
	JE FnMv00
	MOV SI, Find_T
	CALL Case
	JMP FnMv30
FnMv00:	PUSH CX
	CALL GetMous  ; Mouse support
FnMv01:	CALL ClrKbd
	DW _MOV_SI_CX
	TEST AL, 4
	JZ FnMv03
	MOV AL, 'x'
	CALL TypMous
FnMv02:	CALL GetMous
	CALL ClrKbd
	TEST AL, 4
	JNZ FnMv02
	PUSH AX
	MOV AL, 0
	CALL TypMous
	POP AX
	TEST AL, 3
	JNZ FnMv03
	POP CX
	JMP FnMv32
FnMv03:	PUSH DX
	PUSH BX
	ADD BX, 204h
	SUB DX, 80Ah
	CALL InWind
	POP BX
	POP DX
	JNC FnMv08
	CMP BYTE [MD.WinMous], 0
	JZ FnMv05
	MOV BP, [FndData.FndCur]
	MOV DI, [FndData.FndFrst]
	DW _MOV_AL_BH
	ADD AL, 2
	DW _CMP_CH_AL
	JAE FnMv04
	POP CX
	JMP FnMv12
FnMv04:	DW _MOV_AL_BH
	DW _ADD_AL_DH
	SUB AL, 6
	DW _CMP_CH_AL
	JB FnMv06
	POP CX
	JMP FnMv13
FnMv05:	TEST AL, 1
	JZ FnMv06
	CALL GetMous
	JNZ FnMv01
	DW _MOV_CX_SI
	PUSH DX
	SUB DX, 102h
	CALL InWind
	POP DX
	JNC FnMv06
	POP CX
	JMP FnMv32
FnMv06:	POP CX
FnMv07:	JMP FnMv30
FnMv08:	OR BYTE [MD.WinMous], 1
	MOV BP, [FndData.FndNumb]
	DW _OR_BP_BP
	JE FnMv06
	PUSH CX
	DW _SUB_CH_BH
	SUB CH, 2
	DW _MOV_CL_CH
	MOV CH, 0
	MOV DI, [FndData.FndFrst]
	DW _ADD_CX_DI
	DEC BP
	POP SI
	DW _XCHG_BP_CX
	DW _CMP_BP_CX
	JBE FnMv09
	DW _MOV_BP_CX
	POP CX
	JMP FnMv20
FnMv09:	PUSH DX
	PUSH BX
	DW _MOV_AX_SI
	DW _MOV_SI_BP
	DW _MOV_BH_AH
	ADD BL, 2
	SUB DL, 10
	MOV DH, 1
	CALL DoublMo
	POP BX
	POP DX
	POP CX
	JC FnMv20
	JE FnMv07
	MOV AL, 0
	CALL TypMous
	MOV AX, 101h
	RET
FnMv10:	DW _XOR_BP_BP  ; Home
	JMP FnMv20
FnMv11:	MOV BP, [FndData.FndNumb]  ; End
FnMv12:	DW _OR_BP_BP  ; Up
	JE FnMv20
	DEC BP
	JMP FnMv20
FnMv13:	INC BP  ; Down
	CMP BP, [FndData.FndNumb]
	JB FnMv20
	DEC BP
	JMP FnMv20
FnMv14:	DW _MOV_AL_DH  ; PgUp
	SUB AL, 8
	CBW
	DW _MOV_SI_BP
	CALL PgUp
	DW _MOV_BP_SI
	JMP FnMv20
FnMv15:	DW _MOV_SI_BP  ; PgDn
	MOV BP, [FndData.FndNumb]
	DW _MOV_AL_DH
	SUB AL, 8
	CBW
	CALL PgDn
	DW _MOV_BP_SI
FnMv20:	MOV AL, [FndData.FndMode]  ; Test parameters
	PUSH AX
	OR [FndData.FndMode], CL
	DW _CMP_BP_DI
	JAE FnMv21
	DW _MOV_DI_BP
FnMv21:	DW _MOV_AL_DH
	SUB AL, 8
	CBW
	DW _ADD_AX_DI
	DW _CMP_BP_AX
	JB FnMv22
	DW _SUB_AX_DI
	DW _MOV_DI_BP
	DW _SUB_DI_AX
	INC DI
FnMv22:	POP AX
	DW _MOV_CX_DI
	XCHG BP, [FndData.FndCur]
	XCHG DI, [FndData.FndFrst]
	DW _SUB_CX_DI
	JNE FnMv24
	TEST BYTE [FndData.FndMode], 1
	JZ FnMv23
	CMP BP, [FndData.FndCur]
	JNE FnMv24
	TEST AL, 1
	JZ FnMv23
	JMP FnMv30
FnMv23:	JMP FnMv28
FnMv24:	MOV AH, [CS:Find_P]  ; Reset cursor
	CALL FndCurs
	JCXZ FnMv23
	PUSH CX  ; Output lines
	PUSH BX
	DW _MOV_CL_DH
	SUB CL, 8
	MOV CH, 0
	ADD BX, 205h
	MOV AX, [FndData.FndFrst]
FnMv25:	CALL FndLine
	INC AX
	INC BH
	LOOP FnMv25
	POP BX
	POP CX
	PUSH DX  ; Output screen
	PUSH BX
	ADD BX, 205h
	SUB DH, 8
	DW _MOV_AL_DH
	DEC AX
	MOV AH, 6
	CMP CX, 1
	JE FnMv26
	CMP CX, -1
	JNE FnMv27
	MOV AX, 700h
FnMv26:	DW _MOV_CX_BX
	MOV DL, 63
	DEC DH
	DW _ADD_DX_CX
	PUSH AX
	MOV AH, [CS:Find_P]
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
FnMv27:	MOV DL, 64
	CALL Window
	POP BX
	POP DX
FnMv28:	CMP WORD [FndData.FndNumb], 0  ; Set cursor
	JE FnMv30
	MOV BP, [FndData.FndCur]
	MOV DI, [FndData.FndFrst]
	MOV AH, [CS:Find_P]
	TEST BYTE [FndData.FndMode], 1
	JZ FnMv29
	MOV AH, [CS:Find_P+1]
FnMv29:	CALL FndCurs
FnMv30:	DW _XOR_AX_AX  ; Exit
	RET
FnMv31:	MOV AL, [FndData.FndMenu]  ; Enter
	MOV AH, 1
	RET
FnMv32:	MOV AX, 1FFh  ; Esc
	RET
;FndMove	ENDP

;GLOBAL FndCurs
FndCurs:  ; PROC NEAR  ; Set/Reset cursor
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	DW _MOV_CX_BP
	DW _SUB_CX_DI
	DW _ADD_BH_CL
	ADD BX, 205h
	PUSH AX
	DW _MOV_AX_BP
	CALL FndLine
	POP AX
	SUB DL, 12
	DW _MOV_CL_DL
	MOV CH, 0
	CALL BasAdr
	CALL Color
	DW _MOV_AL_AH
	CALL MvsColr
	MOV DH, 1
	CALL Window
	POP BX
	POP CX
	POP DX
	POP DI
	RET
;FndCurs ENDP

;GLOBAL FndLine
FndLine:  ; PROC NEAR  ; Output item
	PUSH DS
	PUSH DI
	PUSH CX
	PUSH AX
	CALL FndAdr
	CALL BasAdr
	MOV AH, [CS:Find_P]
	CALL Color
	MOV CX, LenFnf-1
FndLn1:	LODSB
	STOSW
	LOOP FndLn1
	POP AX
	POP CX
	POP DI
	POP DS
	RET
;FndLine ENDP

;GLOBAL FndAdr
FndAdr:  ; PROC NEAR
	PUSH DX
	PUSH CX
	MOV DX, LenFnf
	MUL DX
	DW _MOV_SI_AX
	AND SI, 0Fh
	MOV CL, 4
	SHR AX, CL
	SHL DL, CL
	DW _OR_AH_DL
	ADD AX, [ES:MD.ViewSeg]
	MOV DS, AX
	POP CX
	POP DX
	RET
;FndAdr ENDP

;GLOBAL FndStat
FndStat:  ; PROC NEAR
	MOV SI, MD.TmpBuf
	MOV DI, MD.TmpErr
	MOV CX, LenPath+13
	PUSH SI
	PUSH DI
	REP MOVSB
	POP SI
	MOV AX, LenFnf-11
	DW _MOV_DL_AL
	MOV DH, 1
	CALL ShrtLin
	CALL PathLin
	MOV BX, [FndData.FndBg]
	ADD BH, [FndData.FndSz+1]
	SUB BH, 5
	ADD BL, 5+10
	CALL BasAdr
	DW _MOV_CL_DL
	MOV CH, 0
FnFl01:	LODSB
	CMP AL, 0
	JNE FnFl02
	DEC SI
	MOV AL, ' '
FnFl02:	STOSB
	INC DI
	LOOP FnFl01
	CALL Window
	POP DX
	RET
;FndStat ENDP

; --- continue vc.asm

;------------------------ Exit -------------------------
Exit:	CALL RstVc1
	CALL Quit
	MOV BH, [MD.DosLin]
	CALL ClsLine
	DW _XOR_BX_BX
	MOV DH, [MD.Lines]
	MOV DL, 80
	CALL Window
	MOV AL, 0
	CALL CurMous
	MOV AH, [MD.DosLin]
	DEC AH
	CALL Cursor
	MOV AX, Exit00
	PUSH SS
	PUSH AX
	MOV AL, 0
	RETF

;------------------------ Quit -------------------------
;GLOBAL Quit
Quit:  ; PROC NEAR
	PUSH ES
	POP DS
	MOV BH, [MD.Lines]
	DEC BH
	CMP BYTE [MD.KeyBar], 0
	JE Quit01
	CALL ClsLine
Quit01:	DW _MOV_DH_BH
	DW _XOR_BX_BX
	MOV DL, 80
	CALL ResUser
	RET
;Quit ENDP

;--------------- Restore and Hook vectots --------------
;RestVct	PROC	NEAR
;GLOBAL RestVct
RestVct:
	LDS DX, [ES:MD.ErrVct]
	MOV AX, 2524h
	INT 21h
RstVc1:	LDS DX, [ES:MD.BrkVct]
	MOV AX, 251Bh
	INT 21h
	RET
;RestVct	ENDP

;GLOBAL HookVct
HookVct:  ; PROC NEAR
	PUSH DS
	MOV AX, 3524h
	INT 21h
	MOV [MD.ErrVct+0], BX
	MOV [MD.ErrVct+2], ES
	MOV AX, 351Bh
	INT 21h
	MOV [MD.BrkVct+0], BX
	MOV [MD.BrkVct+2], ES
	PUSH CS
	POP DS
	MOV DX, FatErr
	MOV AX, 2524h
	INT 21h
	PUSH SS
	POP DS
	MOV DX, CtrlC
	MOV AX, 251Bh
	INT 21h
	POP ES
	RET
;HookVct ENDP

FatErr:	PUSH DS
	PUSH ES
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	CLD
	MOV DS, [CS:SecDat]
	PUSH DS
	POP ES
	MOV BL, [MD.ErrDat]
	OR BL, [MD.BlocEr]
	JZ FtErr1
	MOV AL, 3
	JMP FtErr9
FtErr1:	PUSH AX
	PUSH ES
	PUSH DI
	MOV DS, BP
	DW _MOV_BX_SI
	TEST BYTE [BX+5], 80h
	PUSH CS
	POP DS
	MOV DI, MD.TmpErr+1
	MOV SI, Err_S+1
	MOV CX, 6
	REP MOVSB
	JNZ FtErr2
	MOV SI, OnDr_S
	MOV CL, 11
	REP MOVSB
	ADD [ES:DI-2], AL
	TEST AH, 80h
	JZ FtErr3
	POP DI
	MOV DI, FatEr_S
	DW _XOR_AX_AX
	JMP FtErr5
FtErr2:	MOV SI, OnDv_S
	MOV CL, 10
	REP MOVSB
	MOV DS, BP
	LEA SI, [BX+10]
	MOV CL, 8
	PUSH DI
	PUSH CX
	REP MOVSB
	MOV AL, ' '
	STOSB
	POP CX
	POP DI
	INC CX
	REPNE SCASB
	DEC DI
	MOV AX, ':'
	STOSW
FtErr3:	PUSH CS
	POP ES
	POP CX
	DW _XOR_AX_AX
	MOV DI, Errs_S
	JCXZ FtErr5
	CMP CX, 15h
	JB FtErr4
	MOV CX, 15h
FtErr4:	PUSH CX
	MOV CL, 80
	REPNE SCASB
	POP CX
	LOOP FtErr4
FtErr5:	POP ES
	POP CX
	PUSH ES
	POP DS
	DW _XOR_BX_BX
	XCHG BL, [MD.Clock]
	XCHG BH, [MD.BlDelay]
	MOV CL, [MD.HlpPage]
	DEC AX
	MOV [MD.AutoTim+0], AX
	MOV BP, FtEr1_B
	TEST CH, 10h
	JNZ FtErr6
	MOV BP, FtEr2_B
FtErr6:	DW _MOV_DX_DI
	CALL Dialog
	TEST CH, 10h
	JZ FtErr7
	CMP AL, 0
	MOV AL, 1
	JE FtErr8
FtErr7:	MOV AL, 3
FtErr8:	MOV [MD.Clock], BL
	MOV [MD.BlDelay], BH
	MOV [MD.HlpPage], CL
	CMP AL, 1
	JE FtErr9
	MOV BYTE [MD.ErrDat], 1
FtErr9:	CBW
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP ES
	POP DS
	IRET

;-------------------- Not ready error ------------------
;			   AL - Drive letter
;	Return:		   AL - Drive letter
;ErrRdy	PROC	NEAR
;GLOBAL ErrRdy
ErrRdy:
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
	CBW
	MOV [MD.TmpErr+1], AX
	DW _MOV_CL_AL
	MOV AL, 2
	CALL PutKey
	MOV BP, NoRd_P
	MOV BX, 528h
	CALL DialBox
	CALL Window
	PUSH SI
	LEA AX, [BX+42Ch]
	CALL Cursor
	CALL ClrKbd
	CALL Beep
	MOV BYTE [MD.HlpPage], 0FFh
	CALL BasAdr
	ADD DI, 2*364
ErRdy1:	MOV AL, 2
	CALL Input
	CMP AH, 0FCh
	JE ErRdy2
	MOV SI, Ready_T
	CALL Case
	CMP AL, 80h
	JAE ErRdy1
	CALL UpCase
	CMP AL, 'A'
	JB ErRdy1
	CMP AL, 'Z'
	JA ErRdy1
	CALL TstDrv
	JNZ ErRdy1
	MOV [DI], AL
	DW _MOV_CL_AL
	PUSH DX
	PUSH BX
	ADD BX, 42Ch
	MOV DX, 101h
	CALL Window
	POP BX
	POP DX
	JMP ErRdy1
ErRdy2:	PUSH CX
	DW _XOR_SI_SI
ErRdy3:	CALL GetMous
	JZ ErRdy5
	DW _MOV_BP_CX
	MOV AH, 0
	CMP AL, 1
	JE ErRdy4
	MOV AH, 'û'
	CMP AL, 2
	JE ErRdy4
	MOV AH, 'x'
ErRdy4:	DW _MOV_CX_SI
	DW _MOV_SI_AX
	DW _CMP_AH_CH
	JE ErRdy3
	DW _MOV_AL_AH
	CALL TypMous
	JMP ErRdy3
ErRdy5:	POP CX
	MOV AL, 0
	CALL TypMous
	DW _MOV_AX_SI
	CMP AL, 2
	JE ErRdy7
	CMP AL, 1
	JNE ErRdy6
	PUSH DX
	PUSH CX
	DW _MOV_CX_BP
	SUB DX, 102h
	CALL InWind
	POP CX
	POP DX
	JNC ErRdy1
ErRdy6:	MOV CL, 0
ErRdy7:	CALL HidCur
	POP SI
	CALL ResWin
	CALL Window
	DW _MOV_BL_CL
	SUB BL, 'A'-1
	MOV AX, 440Fh
	INT 21h
	POP AX
	DW _MOV_AL_CL
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;ErrRdy	ENDP

;MainPth	PROC	NEAR
;GLOBAL MainPth
MainPth:
	MOV SI, NcEnv
	MOV CX, 3
MnPth0:	PUSH DS
	PUSH DI
	PUSH CS
	POP DS
	DW _XOR_DI_DI
	MOV AL, 0
MnPth1:	CMP AL, [ES:DI]
	JE MnPth2
	PUSH DI
	PUSH SI
	PUSH CX
	REPE CMPSB
	POP CX
	POP SI
	POP DI
	JE MnPth3
	PUSH CX
	MOV CH, 0FFh
	REPNE SCASB
	POP CX
	JMP MnPth1
MnPth2:	LEA SI, [DI+3]
	PUSH ES
	POP DS
	POP DI
	POP ES
	CMP DI, MD.TempDir
	JNE MnPth9
	PUSH ES
	POP DS
	MOV SI, MD.NcPath
MnPth9:	MOV CX, LenPath
	PUSH DI
	PUSH CX
	REP MOVSB
	POP CX
	POP SI
	PUSH ES
	POP DS
	CALL CutPath
	DW _MOV_DI_SI
	JMP MnPth4
MnPth3:	DW _MOV_SI_DI
	DW _ADD_SI_CX
	PUSH ES
	POP DS
	POP DI
	POP ES
	MOV CX, LenPath-2
	CALL MvzLine
	CALL AddFile
MnPth4:	PUSH ES
	POP DS
	MOV BYTE [DI], 0
	RET
;MainPth	ENDP

;GLOBAL ReadOne
ReadOne:  ; PROC NEAR
	PUSH CX
	PUSH CS
	POP DS
	MOV CX, 13
	REP MOVSB
	PUSH ES
	POP DS
	MOV AX, 3D20h
	INT 21h
	POP CX
	JC RdOne1
	DW _MOV_BX_AX
	DW _MOV_DX_BP
	MOV AH, 3Fh
	INT 21h
	PUSHF
	PUSH AX
	MOV AH, 3Eh
	INT 21h
	POP AX
	POP DX
	JC RdOne1
	PUSH DX
	POPF
RdOne1:	RET
;ReadOne ENDP

;GLOBAL Expand
Expand:  ; PROC NEAR
	DW _XOR_DI_DI
	MOV CX, WCBdef_WCBsave
	REP MOVSB
	MOV DI, WCBdef.DskBuf
	MOV AX, [ES:WCBdef.EndBuf]
	DW _SUB_AX_DI
	DW _XOR_DX_DX
	MOV CX, FILENT_size
	DIV CX
	DW _MOV_CX_AX
	JCXZ Expnd2
Expnd1:	PUSH DI
	PUSH CX
	MOV CX, 12
	REP MOVSB
	MOV AL, 0
	STOSB
	MOVSB
	POP CX
	POP DI
	ADD DI, FILENT_size
	LOOP Expnd1
Expnd2:	RET
;Expand ENDP

; --- include vcsub1.inc

;--------------------- Subroutines ---------------------
;		Version :	09.09.1999
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
	CMP BYTE [ES:MD.ClrBuf], 0
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

;---------------------- Break test ---------------------
;	Return :	CY=1 - break
;GLOBAL TstBrk
TstBrk:  ; PROC NEAR
	PUSH BX
	PUSH AX
	MOV BL, 1
TstBr1:	MOV AH, 1
	INT 16h
	JZ TstBr3
	DW _OR_AX_AX
	JE TstBr2
	CMP AX, STRICT WORD 2E03h
	JE TstBr2
	CMP AX, STRICT WORD 011Bh
	JE TstBr2
	CMP AX, STRICT WORD 4400h
	JNE TstBr3
TstBr2:	MOV AH, 0
	INT 16h
	MOV BL, 0
	JMP TstBr1
TstBr3:	CMP BL, 1
	POP AX
	POP BX
	RET
;TstBrk ENDP

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

;------------------ Check video mode -------------------
;			   ZR - ok
;GLOBAL ChkMode
ChkMode:  ; PROC NEAR
	MOV AH, 0Fh
	INT 10h
	CMP AH, 80
	JNE ChkMd1
	AND AL, 7Fh
	CMP AL, 2
	JE ChkMd1
	CMP AL, 3
	JE ChkMd1
	CMP AL, 7
ChkMd1:	RET
;ChkMode ENDP

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

;------------------ Set cursor on prompt ---------------
;GLOBAL Cursor1
Cursor1:  ; PROC NEAR
	PUSH AX
	MOV AL, [ES:MD.DosCol]
	SUB AL, [ES:MD.OutCol]
	ADD AL, [ES:MD.BegCol]
	MOV AH, [ES:MD.DosLin]
	CALL Cursor
	POP AX
	RET
;Cursor1 ENDP

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
	CMP BYTE [ES:MD.ScrMod], 7
	JNE ChCur1
	MOV CX, 0B0Ch
ChCur1:	CMP BYTE [ES:MD.ColTyp], 2
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

;----------------------- Beep sound --------------------
;GLOBAL Beep
Beep:  ; PROC NEAR
	CMP BYTE [ES:MD.ErrSnd], 0
	JE Beep1
	PUSH BP
	PUSH AX
	MOV AX, 0E07h
	INT 10h
	POP AX
	POP BP
Beep1:	RET
;Beep ENDP

;---------------------- Init mouse ---------------------
;GLOBAL IniMous
IniMous:  ; PROC NEAR
	MOV AX, 21h
	INT 33h
	CMP AX, STRICT WORD 21h
	JNE IniMo1
	DW _XOR_AX_AX
	INT 33h
IniMo1:	CMP AX, STRICT WORD 0FFFFh
	CMC
	MOV AL, 0
	DW _ADC_AL_AL
	MOV [ES:MD.Mouse], AL
	DW _OR_AL_AL
	JNE IniMo2
	MOV AX, 0FFFFh
	MOV [ES:MD.MouseX], AX
	MOV [ES:MD.MouseY], AX
	RET
IniMo2:	MOV AL, 0
	CALL TypMous
	MOV DL, [ES:MD.Lines]
	CMP DL, 25
	JE IniMo3
	MOV DH, 0
	MOV CL, 3
	SHL DX, CL
	DEC DX
	DW _XOR_CX_CX
	MOV AX, 8
	INT 33h
IniMo3:	MOV CX, [ES:MD.MouseX]
	MOV DX, [ES:MD.MouseY]
	DW _MOV_AX_CX
	DW _AND_AX_DX
	INC AX
	JE IniMo4
	MOV AX, 4
	INT 33h
IniMo4:	MOV AL, 1
	CALL CurMous
	RET
;IniMous ENDP

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

;------------------ Save mouse cursor ------------------
;GLOBAL SavMous
SavMous:  ; PROC NEAR
	CMP BYTE [ES:MD.Mouse], 0
	JE SavMo1
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV AX, 3
	INT 33h
	MOV [ES:MD.MouseX], CX
	MOV [ES:MD.MouseY], DX
	POP AX
	POP BX
	POP CX
	POP DX
SavMo1:	RET
;SavMous ENDP

;------------------- Set mouse cursor ------------------
;			   AL - set/reset
;GLOBAL CurMous
CurMous:  ; PROC NEAR
	CMP BYTE [ES:MD.Mouse], 0
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
	CMP BYTE [ES:MD.Mouse], 0
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
	CMP BYTE [ES:MD.LftMous], 0
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
	CMP BYTE [ES:MD.MousEnt], 0
	JNE DblMo3
	MOV BYTE [ES:MD.MousEnt], 1
	MOV AH, 2Ch
	INT 21h
	CMP WORD [ES:MD.MousTim+2], 0FFFFh
	JE DblMo1
	CMP SI, [ES:MD.MousPos]
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
DblMo2:	MOV [ES:MD.MousTim+0], DX
	MOV [ES:MD.MousTim+2], CX
	MOV [ES:MD.MousPos], SI
DblMo3:	POP DX
	STC
	RET
DblMo4:	CMP CX, [ES:MD.MousTim+2]
	JA DblMo1
	JB DblMo5
	CMP DX, [ES:MD.MousTim+0]
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
	MOV AL, 'û'
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
	ADD AX, STRICT WORD MD.ScrBuf
	DW _MOV_DI_AX
	POP AX
	POP BX
	RET
;BasAdr ENDP

;-------------------- Screen Offset --------------------
;GLOBAL ScrOffs
ScrOffs:  ; PROC NEAR
	PUSH DS
	DW _XOR_DI_DI
	MOV AH, 0Fh
	INT 10h
	DW _OR_BH_BH
	JE ScrOf1
	MOV DS, DI
	MOV DI, [44Eh]
ScrOf1:	POP DS
	MOV [MD.Screen+0], DI
	RET
;ScrOffs ENDP

;--------------- Shift windows in EGA lines ------------
;GLOBAL SftEGA
SftEGA:  ; PROC NEAR
	PUSH AX
	MOV AL, [ES:MD.Lines]
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
	MOV BYTE [MD.Quote], 0
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;ResWin ENDP

;----------------- Restore user screen -----------------
;			BH,BL - begin
;			DH,DL - size
;GLOBAL ResUser
ResUser:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	CLD
	PUSH ES
	POP DS
	CALL BasAdr
	LEA SI, [DI-MD.ScrBuf+MD.UserScr]
	DW _MOV_CL_DH
	MOV CH, 0
	MOV DH, 0
ResUs1:	PUSH SI
	PUSH DI
	PUSH CX
	DW _MOV_CX_DX
	REP MOVSW
	POP CX
	POP DI
	POP SI
	ADD SI, 2*80
	ADD DI, 2*80
	LOOP ResUs1
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;ResUser ENDP

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
	MOV ES, [MD.Screen+2]
	CALL BasAdr
	DW _MOV_SI_DI
	SUB DI, MD.ScrBuf
	ADD DI, [MD.Screen+0]
	MOV AL, [MD.Snow]
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
	CMP BYTE [ES:MD.TopView], 0
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
	MOV DS, [ES:MD.Screen+2]
	MOV SI, [ES:MD.Screen+0]
	MOV DI, MD.ScrBuf
	MOV DH, [ES:MD.Lines]
	MOV AL, [ES:MD.Snow]
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
	MOV [ES:MD.Quote], AL
	CMP AL, [ES:MD.ZoomWin]
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
	MOV BX, (('É'*256)&0FF00H)+('»'&0FFH)  ; !!
	MOV AL, 'Í'
	CALL ShadLin
	SUB SI, 5
	JBE ShdBx2
	MOV BX, (('º'*256)&0FF00H)+('º'&0FFH)  ; !!
	MOV AL, ' '
ShdBx1:	CALL ShadLin
	DEC SI
	JNE ShdBx1
ShdBx2:	MOV BX, (('È'*256)&0FF00H)+('¼'&0FFH)  ; !!
	MOV AL, 'Í'
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

;-------------------------- Box ------------------------
;			ES:DI - screen buffer
;			   AH - color
;		    ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
;		    º                 º   ¿
;		    º                 º   Ã SI
;		    º                 º   Ù
;		    ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
;		 ÀÂÙ ÀÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÙ ÀÂÙ
;		  CX         DX         CX
;GLOBAL BoxDubl
BoxDubl:  ; PROC NEAR
	PUSH SI
	PUSH BX
	PUSH AX
	MOV AL, 'Í'
	MOV BX, (('É'*256)&0FF00H)+('»'&0FFH)  ; !!
	CALL BoxLine
	MOV AL, ' '
	MOV BX, (('º'*256)&0FF00H)+('º'&0FFH)  ; !!
BoxDb1:	CALL BoxLine
	DEC SI
	JNE BoxDb1
	MOV AL, 'Í'
	MOV BX, (('È'*256)&0FF00H)+('¼'&0FFH)  ; !!
	CALL BoxLine
	POP AX
	POP BX
	POP SI
	RET
;BoxDubl ENDP

;-------------------- One line of box ------------------
;			ES:DI - screen buffer
;			   AH - color
;		³   ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶   ³
;		 ÀÂÙ|ÀÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÙ|ÀÂÙ
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

;GLOBAL StdLine
StdLine:  ; PROC NEAR
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	CALL BasAdr
	SUB DL, 10
	MOV DH, 0
	MOV CX, 3
	DW _MOV_BX_SI
	CALL BoxLine
	POP BX
	POP CX
	POP DX
	POP DI
	INC BH
	RET
;StdLine ENDP

;------------------- Zoom box only once ----------------
;GLOBAL OncZoom
OncZoom:  ; PROC NEAR
	PUSH AX
	MOV AL, [ES:MD.ZoomWin]
	CMP BYTE [ES:MD.ZoomOne], 0
	JZ OncZo1
	MOV BYTE [ES:MD.ZoomWin], 0
OncZo1:	CALL DialBox
	CALL Window
	MOV [ES:MD.ZoomWin], AL
	MOV BYTE [ES:MD.ZoomOne], 1
	POP AX
	RET
;OncZoom ENDP

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
	MOV DI, MD.TmpErr+1
	PUSH AX
	CALL DiBx30
	POP AX
	DEC AX
	JE DiBx01
	ADD BP, 4
	MOV DI, MD.TmpErr+101
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
	MOV BX, (('Ç'*256)&0FF00H)+('¶'&0FFH)  ; !!
	MOV AL, 'Ä'
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
	MOV DI, MD.TmpErr+1
	JMP LnStr8
LnStr6:	PUSH ES
	MOV DI, MD.TmpErr+101
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
	MOV SI, MD.TmpErr+1
	JMP NgLn09
NgLn08:	CMP AL, 'W'
	JNE NgLn13
	PUSH SI
	MOV SI, MD.TmpErr+101
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
;				DB  MD.KeyBar, Menu, MD.HlpPage, Status
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
	MOV BYTE [ES:MD.Quote], 0
	CALL ChgCur
	PUSH CX
	PUSH BP  ; Output box
	MOV AL, [CS:BP+BOXHD.bMenu]
	TEST BYTE [CS:BP+BOXHD.bFlags], 10h
	JNZ Dial01
	MOV BX, [CS:BP+BOXHD.BoxBase]
	CMP AL, 1
	JNE Dial01
	MOV CX, DS
	CMP CX, [ES:MD.WCB1seg]
	JE Dial01
	MOV AL, 5
	ADD BL, 40
Dial01:	CMP AL, 0FFh
	JE Dial02
	CALL PutMnu
Dial02:	MOV AL, [CS:BP+BOXHD.bKeyBar]
	CALL PutKey
	TEST BYTE [CS:BP+BOXHD.bFlags], 4
	JZ Dial03
	ADD BH, [ES:MD.SftErr]
Dial03:	TEST BYTE [CS:BP+BOXHD.bFlags], 10h
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
	MOV DI, MD.DosBuf+LenCmd+10
	TEST CH, 1
	JZ Dial14
	ADD DI, 100
Dial14:	MOV CH, 0
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
	MOV [ES:MD.HlpPage], AL
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
	MOV AL, [CS:DI+BOXHD.bKeyBar]
	MOV CX, [CS:SI+BOXMN.mCtrl]
	MOV SI, MD.DosBuf+LenCmd+10+3
	TEST CH, 1
	JZ Dial32
	ADD SI, 100
Dial32:	MOV CH, 0
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
Dial45:	MOV AH, 'û'
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
	CMP SI, 'û'&0FFH  ; !! AND 0FFH not needed by NASM.
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
	MOV SI, MD.DosBuf+LenCmd+10+3
	TEST CH, 1
	JZ Dial74
	ADD SI, 100
Dial74:	TEST CH, 2
	JZ Dial75
	CALL NormStr
Dial75:	MOV CH, 0
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
	MOV AH, 1
Dial79:	MOV AL, 1
	JMP Dial71
Dial80:	TEST BYTE [CS:BP+BOXHD.bFlags], 8  ; Alt-F10
	MOV AH, 0
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
	CMP BYTE [ES:MD.Quote], 0
	JNZ InSt02
	MOV SI, InSt_T
	CALL Case
InSt02:	CMP BYTE [ES:BP-1], 0
	JNE InSt04
	MOV BYTE [ES:BP-1], 1
	CMP BYTE [ES:MD.Quote], 0
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
	MOV AL, 'û'
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
	MOV AL, [ES:MD.ColTyp]
	CMP AL, 3
	JB ColAd1
	MOV AL, 1
ColAd1:	CBW
	DW _ADD_AX_AX
	CMP BYTE [ES:MD.ScrMod], 7
	JNE ColAd2
	INC AX
ColAd2:	DW _ADD_DI_AX
	ADD DI, MD.ColTab
	POP AX
	RET
;ColAddr ENDP

;------------------------- Shadow ----------------------
;			ES:DI - address of screen buffer
;GLOBAL Shadow
Shadow:  ; PROC NEAR
	PUSH AX
	INC DI
	MOV AH, ShadFl
	CALL Color
	MOV AL, [ES:DI]
	CMP AH, 1
	JB Shadw1
	PUSHF
	AND AL, 8Fh
	XOR AL, 8
	POPF
	JE Shadw1
	MOV AL, 7
Shadw1:	STOSB
	POP AX
	RET
;Shadow ENDP

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
;			ES:SI(B) -> ES:DI(W)
;GLOBAL MvsBwe
MvsBwe:  ; PROC NEAR
ES
	LODSB
	STOSW
	LOOP MvsBwe
	RET
;MvsBwe ENDP
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
;			Add file name
;GLOBAL AddFile
AddFile:  ; PROC NEAR
	MOV AL, '\'
	CMP AL, [ES:DI-1]
	JE AddFl1
	STOSB
AddFl1:	RET
;AddFile ENDP
;			DS:SI(B) -> ES:DI(B)
;GLOBAL MvzLin0
MvzLin0:  ; PROC NEAR
	MOV CX, LenPath
;MvzLin0 ENDP

;GLOBAL MvzLine
MvzLine:  ; PROC NEAR
	PUSH DI
	PUSH CX
	REP MOVSB
	POP CX
	POP DI
	MOV AL, 0
	REPNE SCASB
	DEC DI
	RET
;MvzLine ENDP
;			Clear rest of line DS:SI, legth CX
;GLOBAL FilZero
FilZero:  ; PROC NEAR
	PUSH ES
	PUSH DI
	PUSH DS
	POP ES
	DW _MOV_DI_SI
	MOV AL, 0
	REPNE SCASB
	JCXZ FilZr1
	REP STOSB
FilZr1:	POP DI
	POP ES
	RET
;FilZero ENDP

;--------------------- Check CrLf ----------------------
;			   AX - word
;	Return :	   ZR - yes
;GLOBAL IsCrLf0
IsCrLf0:  ; PROC NEAR
	DEC SI
	DEC SI
;IsCrLf0 ENDP

;GLOBAL IsCrLfS
IsCrLfS:  ; PROC NEAR
	LODSW
;IsCrLfS ENDP

;GLOBAL IsCrLf
IsCrLf:  ; PROC NEAR
	CMP AX, STRICT WORD 0D0Ah
	JE IsCrL1
	CMP AX, STRICT WORD 0A0Dh
IsCrL1:	RET
;IsCrLf ENDP

;-------------------- String length --------------------
;			ES:DI - string
;	Return :	   CX - length
;GLOBAL StrLen
StrLen:  ; PROC NEAR
	PUSH DI
	MOV CX, 0FFFFh
	MOV AL, 0
	REPNE SCASB
	NOT CX
	POP DI
	RET
;StrLen ENDP

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
UpCas1:	CALL FAR [ES:MD.Country+CNTRY.CaseMp]
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
	MOV AL, [ES:BX+MD.LowTab-128]
	POP BX
LoCas2:	RET
;LowCase ENDP

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

;----------------------- Main file ---------------------
;			NcPath + CS:SI -> ES:DI
;GLOBAL MainFil
MainFil:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH ES
	POP DS
	MOV SI, MD.NcPath
	MOV CX, LenPath
	CALL MvzLine
	POP SI
	PUSH CS
	POP DS
	MOV CX, 13
	REP MOVSB
	POP DS
	RET
;MainFil ENDP

;-------------- Output number into buffer --------------
;			ES:DI - address of buffer
;			BX CX - number
;			   AL - mode: b0-coma, b1-spaces
;GLOBAL Number
Number:  ; PROC NEAR
	PUSH BP
	PUSH SI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	DW _MOV_DH_AL
	CMP BYTE [ES:MD.Country+CNTRY.Sep1000], 0
	JNE Numb01
	TEST AL, 1
	JZ Numb01
	AND DH, 0FEh
	JZ Numb01
	MOV AL, ' '
	STOSB
	STOSB
	STOSB
Numb01:	MOV DL, 0
	MOV BP, 0CA00h  ; 1.000.000.000
	MOV SI, 3B9Ah
	CALL Numb10
	CALL Numb20
	MOV BP, 0E100h  ;   100.000.000
	MOV SI, 5F5h
	CALL Numb10
	MOV BP, 9680h  ;    10.000.000
	MOV SI, 98h
	CALL Numb10
	MOV BP, 4240h  ;     1.000.000
	MOV SI, 0Fh
	CALL Numb10
	CALL Numb20
	MOV BP, 86A0h  ;       100.000
	MOV SI, 1
	CALL Numb10
	MOV BP, 10000  ;        10.000
	DW _XOR_SI_SI
	CALL Numb10
	MOV BP, 1000  ;         1.000
	CALL Numb10
	CALL Numb20
	MOV BP, 100  ;           100
	CALL Numb10
	MOV BP, 10  ;            10
	CALL Numb10
	MOV AL, '0'  ;             1
	DW _ADD_AL_CL
	MOV AH, 0
	STOSW
	DEC DI
	POP AX
	POP BX
	POP CX
	POP DX
	POP SI
	POP BP
	RET
;Number ENDP

;GLOBAL Numb10
Numb10:  ; PROC NEAR
	MOV AL, '0'-1
Numb11:	INC AX
	DW _SUB_CX_BP
	DW _SBB_BX_SI
	JNC Numb11
	DW _ADD_CX_BP
	DW _ADC_BX_SI
	CMP AL, '0'
	JE Numb21
	MOV DL, 1
	STOSB
	RET
;Numb10 ENDP

;Numb20	PROC	NEAR
;GLOBAL Numb20
Numb20:
	TEST DH, 1
	JZ Numb23
	MOV AL, [ES:MD.Country+CNTRY.Sep1000]
Numb21:	DW _OR_DL_DL
	JNZ Numb22
	TEST DH, 2
	JZ Numb23
	MOV AL, ' '
Numb22:	STOSB
Numb23:	RET
;Numb20	ENDP

;-------------------- Output hex byte ------------------
;			   AL - code
;GLOBAL HexByt
HexByt:  ; PROC NEAR
	PUSH CX
	PUSH AX
	MOV CL, 4
	SHR AL, CL
	CALL HexCod
	POP AX
	CALL HexCod
	POP CX
	RET
;HexByt ENDP

;GLOBAL HexCod
HexCod:  ; PROC NEAR
	AND AL, 0Fh
	ADD AL, '0'
	CMP AL, '9'
	JBE HexCd1
	ADD AL, 7
HexCd1:	STOSB
	INC DI
	RET
;HexCod ENDP

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

;---------------------- Number input -------------------
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

;--------------- Convert name & extension --------------
;			DS:SI - address of file
;			ES:DI - convert buffer
;GLOBAL Convert
Convert:  ; PROC NEAR
	PUSH SI
	PUSH DI
	PUSH CX
	PUSH AX
	CLD
	MOV CX, 8
	MOV AH, '.'
	CALL Conv10
Conv01:	LODSB
	CMP AL, '.'
	JE Conv02
	CMP AL, 0
	JNE Conv01
	DEC SI
Conv02:	MOV CX, 3
	MOV AH, 0
	CALL Conv10
	POP AX
	POP CX
	POP DI
	POP SI
	RET
;Convert ENDP

;GLOBAL Conv10
Conv10:  ; PROC NEAR
	LODSB
	CMP AL, 0
	JE Conv11
	DW _CMP_AL_AH
	JE Conv11
	CMP AL, '*'
	JE Conv12
	CALL UpCase
	STOSB
	LOOP Conv10
	RET
Conv11:	MOV AL, ' '
	JMP Conv13
Conv12:	MOV AL, '?'
Conv13:	REP STOSB
	DEC SI
	RET
;Conv10 ENDP

;-------------- Unconvert name & extension -------------
;			DS:SI - convert buffer
;			ES:DI - address of file
;GLOBAL UnConv
UnConv:  ; PROC NEAR
	PUSH CX
	PUSH BX
	PUSH AX
	DW _MOV_BX_DI
	MOV CX, 8
	CALL UnCnv1
	MOV AL, '.'
	STOSB
	MOV CX, 3
	CALL UnCnv1
	MOV BYTE [ES:DI], 0
	POP AX
	POP BX
	POP CX
	RET
;UnConv ENDP

;GLOBAL UnCnv1
UnCnv1:  ; PROC NEAR
	LODSB
	STOSB
	CMP AL, ' '
	JE UnCnv2
	DW _MOV_BX_DI
UnCnv2:	LOOP UnCnv1
	DW _MOV_DI_BX
	RET
;UnCnv1 ENDP

;--------------------- Test mask file ------------------
;			DS:SI - address of file
;			ES:DI - converted mask
;	Return :	 CY=1 - yes
;			 CY=0 - no
;GLOBAL TstMas
TstMas:  ; PROC NEAR
	PUSH SI
	PUSH DI
	PUSH CX
	PUSH AX
	PUSH DI
	MOV DI, MD.TmpBuf+20
	PUSH DI
	CALL Convert
	POP DI
	POP SI
	MOV CX, 11
TstMs1:
ES
	LODSB
	CMP AL, '?'
	JNE TstMs2
	INC DI
	JMP TstMs3
TstMs2:	SCASB
	CLC
	JNE TstMs4
TstMs3:	LOOP TstMs1
	STC
TstMs4:	POP AX
	POP CX
	POP DI
	POP SI
	RET
;TstMas ENDP

;------------------------ Set MD.DTA ----------------------
;GLOBAL SetDTA
SetDTA:  ; PROC NEAR
	PUSH DS
	PUSH DX
	PUSH AX
	PUSH ES
	POP DS
	MOV DX, MD.DTA
	MOV AH, 1Ah
	INT 21h
	POP AX
	POP DX
	POP DS
	RET
;SetDTA ENDP

;------------------- Test drive letter -----------------
;			   AL - drive letter
;	Return :	   ZR - yes
;			   NZ - no
;GLOBAL TstDrv
TstDrv:  ; PROC NEAR
	PUSH DX
	PUSH AX
	SUB AL, 'A'
	DW _MOV_DL_AL
	MOV AH, 19h
	INT 21h
	PUSH AX
	MOV AH, 0Eh
	INT 21h
	MOV AH, 19h
	INT 21h
	DW _CMP_AL_DL
	POP DX
	PUSHF
	MOV AH, 0Eh
	INT 21h
	POPF
	POP AX
	POP DX
	RET
;TstDrv ENDP

;--------------- Int 21h with fatal error --------------
;GLOBAL Intr21
Intr21:  ; PROC NEAR
	PUSH DS
	MOV DS, [CS:SecDat]
	MOV BYTE [MD.ErrDat], 0
	POP DS
	INT 21h
	PUSHF
	PUSH DS
	MOV DS, [CS:SecDat]
	CMP BYTE [MD.ErrDat], 0
	POP DS
	JNE I21_02
	POPF
	JNC I21_01
	PUSH DS
	PUSH ES
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	DW _XOR_BX_BX
	MOV AH, 59h
	INT 21h
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP ES
	POP DS
	STC
I21_01:	RET
I21_02:	POPF
	MOV AX, 53h
	STC
	RET
;Intr21 ENDP

;------------------- Invert variable -------------------
;			ES:BX - address of variable
;GLOBAL InvVar
InvVar:  ; PROC NEAR
	CMP BYTE [ES:BX], 1
	MOV AL, 0
	ADC AL, 0
	MOV [ES:BX], AL
	RET
;InvVar ENDP

;----------------------- Check sum ---------------------
;			DS:SI - address
;			   CX - length
;	Return :	   AX - check sum
;GLOBAL ChkSum
ChkSum:  ; PROC NEAR
	PUSH SI
	PUSH CX
	PUSH BX
	DW _XOR_BX_BX
	MOV AH, 0
ChkSm1:	LODSB
	DW _ADD_BX_AX
	LOOP ChkSm1
	LODSW
	DW _CMP_AX_BX
	DW _MOV_AX_BX
	POP BX
	POP CX
	POP SI
	RET
;ChkSum ENDP

;----------------- CALL to PSP segment -----------------
;			   AX - offset in PSP
;GLOBAL CallPSP
CallPSP:  ; PROC NEAR
	POP BP
	PUSH CS
	PUSH BP
	PUSH SS
	PUSH AX
	RETF
;CallPSP ENDP

;----------------------- Page Up -----------------------
;GLOBAL PgUp
PgUp:  ; PROC NEAR
	DW _OR_DI_DI
	JNE PgUp1
	DW _XOR_SI_SI
	JMP PgUp3
PgUp1:	DEC AX
	DW _SUB_DI_AX
	JAE PgUp2
	DW _XOR_DI_DI
PgUp2:	DW _ADD_AX_DI
	DW _CMP_SI_AX
	JBE PgUp3
	DW _MOV_SI_AX
PgUp3:	RET
;PgUp ENDP

;---------------------- Page Down ----------------------
;GLOBAL PgDn
PgDn:  ; PROC NEAR
	PUSH SI
	DW _MOV_SI_BP
	DW _SUB_BP_AX
	JAE PgDn1
	DW _XOR_BP_BP
PgDn1:	DEC AX
	DW _CMP_DI_BP
	JB PgDn2
	POP AX
	DW _OR_SI_SI
	JE PgDn5
	DEC SI
	JMP PgDn5
PgDn2:	POP SI
	DW _ADD_DI_AX
	JC PgDn3
	DW _CMP_DI_BP
	JBE PgDn4
PgDn3:	DW _MOV_DI_BP
PgDn4:	DW _CMP_SI_DI
	JAE PgDn5
	DW _MOV_SI_DI
PgDn5:	RET
;PgDn ENDP

; --- include vcsub2.inc

;--------------------- Subroutines ---------------------
;		Version :	16.10.1999
;-------------------------------------------------------

;------------------ Begin of main windows --------------
;			   DS - WCBseg
;	Return :	BH,BL - Begin
;GLOBAL BegBX
BegBX:  ; PROC NEAR
	MOV BX, DS
	CMP BX, [ES:MD.WCB1seg]
	MOV BX, 0
	JE BegBX1
	MOV BL, 40
BegBX1:	CMP BH, [ES:MD.MenuVs]
	JZ BegBX2
	INC BH
BegBX2:	RET
;BegBX ENDP

;----------------- Size of main windows ----------------
;	Return :	DH,DL - Size
;GLOBAL SizDX
SizDX:  ; PROC NEAR
	MOV DH, [ES:MD.Lines]
	SHR DH, 1
	ADD DH, 3
	CMP BYTE [ES:MD.Lines], 25
	JBE SizDX1
	INC DH
SizDX1:	CMP BYTE [ES:MD.FulScr], 0
	JZ SizDX2
	MOV DH, [ES:MD.Lines]
	SUB DH, 2
	CMP BYTE [ES:MD.MenuVs], 0
	JZ SizDX2
	DEC DH
SizDX2:	MOV DL, 40
	RET
;SizDX ENDP

;------------------ Files in main windows --------------
;GLOBAL LnsAX
LnsAX:  ; PROC NEAR
	PUSH DX
	CALL SizDX
	DW _MOV_AL_DH
	CBW
	SUB AL, 3
	CMP AH, [ES:MD.MiniSta]
	JZ LnsAX1
	SUB AL, 2
LnsAX1:	POP DX
	RET
;LnsAX ENDP

;------------------- Clear screen line -----------------
;			   BH - line
;GLOBAL ClsLine
ClsLine:  ; PROC NEAR
	PUSH CX
	MOV BL, 0
	CALL BasAdr
	MOV CX, 80
	MOV AH, [MD.CrntCol]
	MOV AL, ' '
	REP STOSW
	POP CX
	RET
;ClsLine ENDP

;GLOBAL PutKey
PutKey:  ; PROC NEAR
	CMP BYTE [ES:MD.KeyBar], 0
	JNZ PutKy1
	MOV BYTE [ES:MD.BarPrev], 0FFh
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
PutKy3:	CMP AL, [ES:MD.BarPrev]
	JE PutKy7
	MOV [ES:MD.BarPrev], AL
	MOV AH, 10
	MUL AH
	DW _MOV_SI_AX
	MOV BH, [ES:MD.Lines]
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
	INC DX
	CMP DL, '9'+1
	JA PutKy6
	DW _XCHG_AH_DH
	MOV AL, ' '
	STOSW
	JB PutKy4
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

;-------------------- Output menu bar ------------------
;			   AL - Case
;GLOBAL PutMnu3
PutMnu3:  ; PROC NEAR
	MOV AL, 3
;PutMnu3 ENDP

;PutMnu	PROC	NEAR
;GLOBAL PutMnu
PutMnu:
	CMP BYTE [ES:MD.MenuVs], 0
	JNZ PtMnu1
	RET
PtMnu1:	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	PUSH CS
	POP DS
	CBW
	DW _MOV_CX_AX
	DW _XOR_BX_BX
	CALL BasAdr
	MOV SI, PtMnu_S
	PUSH SI
	MOV BP, PtMnu_B
	MOV AL, 80
	CALL NgLine
	POP SI
	CMP CL, 5
	JA PtMnu4
	JCXZ PtMnu4
	MOV BL, -2
PtMnu2:	LODSB
	INC BX
	CMP AL, 0FFh
	JNE PtMnu2
	LODSB
	DEC BX
	DW _ADD_BL_AL
	LOOP PtMnu2
	MOV BH, 0
	MOV CX, 4-1
PtMnu3:	LODSB
	INC CX
	CMP AL, 0FFh
	JNE PtMnu3
	CALL BasAdr
	MOV AH, MnCur_C
	CALL Color
	DW _MOV_AL_AH
	CALL MvsColr
PtMnu4:	DW _XOR_BX_BX
	MOV DX, 150h
	CALL Window
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;PutMnu	ENDP

;--------------------- Output prompt -------------------
;GLOBAL PutPrm
PutPrm:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH BX
	PUSH AX
	CALL BegBX
	CALL SizDX
	DW _ADD_DH_BH
	PUSH ES
	POP DS
	MOV BH, [MD.DosLin]
	DW _CMP_BH_DH
	JAE PutPr1
	PUSH DS
	MOV DS, [MD.WCBcrn]
	CMP BYTE [WCBdef.Visible], 0
	POP DS
	JZ PutPr1
	DW _MOV_BH_DH
	MOV [MD.DosLin], BH
PutPr1:	MOV BL, 0
	CALL BasAdr
	MOV AH, [MD.CrntCol]
	MOV SI, MD.DosPth
	LODSB
	STOSW
	INC BX
	CMP BYTE [MD.Prompt], 0
	JZ PutPr3
PutPr2:	LODSB
	CMP AL, 0
	JE PutPr3
	STOSW
	INC BX
	JMP PutPr2
PutPr3:	CMP BYTE [MD.PathEr], 0
	JZ PutPr4
	MOV AL, '?'
	STOSW
	INC BX
PutPr4:	MOV AL, '>'
	STOSW
	INC BX
	MOV [MD.BegCol], BL
	CALL DosCom
	POP AX
	POP BX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;PutPrm ENDP

;------------------ Output command line ----------------
;GLOBAL DosCom
DosCom:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	PUSH ES
	POP DS
	MOV AL, [MD.DosCol]
	DW _MOV_BH_AL
	MOV BL, 0
	SUB AL, 5
	JB DosCm1
	MOV BL, [MD.OutCol]
	DW _CMP_AL_BL
	JAE DosCm1
	DW _MOV_BL_AL
DosCm1:	MOV CX, 79
	SUB CL, [MD.BegCol]
	DW _SUB_BH_CL
	JB DosCm2
	DW _CMP_BH_BL
	JBE DosCm2
	DW _MOV_BL_BH
DosCm2:	MOV [MD.OutCol], BL
	MOV BH, 0
	LEA SI, [BX+MD.DosBuf]
	INC CX
	MOV BH, [MD.DosLin]
	MOV BL, [MD.BegCol]
	CALL BasAdr
	MOV AH, [MD.CrntCol]
DosCm3:	LODSB
	CMP AL, 0
	JNE DosCm4
	DEC SI
	MOV AL, ' '
DosCm4:	STOSW
	LOOP DosCm3
	MOV BL, 0
	MOV DX, 150h
	CALL Window
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;DosCom ENDP

;------------------------ Panel ------------------------
;			   DS - WCBseg
;GLOBAL Panel
Panel:  ; PROC NEAR
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV BP, Panel_P
	CALL BegBX
	CALL BasAdr
	CALL SizDX
	DW _MOV_DL_DH
	MOV DH, 0
	DW _MOV_SI_DX
	DEC SI
	DEC SI
	DW _XOR_CX_CX
	MOV DX, 40-2
	MOV AH, [CS:BP]
	CALL Color
	CALL BoxDubl
	MOV AL, 'Ä'
	SUB DI, 2*3*80
	CMP BYTE [WCBdef.WinTyp], 1
	JE Panel1
	CMP BYTE [WCBdef.WinTyp], 3
	JE Panel1
	CMP BYTE [WCBdef.WinTyp], 2
	JNE Panel2
	PUSH CS
	POP DS
	ADD BX, 114h
	MOV SI, Title_S+2
	CALL CntLine
	CALL BasAdr
	ADD DI, 2*(80-20)
	MOV BX, (('Ç'*256)&0FF00H)+('¶'&0FFH)  ; !!
	CALL BoxLine
	ADD DI, 2*7*80
Panel1:	MOV BX, (('Ç'*256)&0FF00H)+('¶'&0FFH)  ; !!
	CALL BoxLine
Panel2:	CMP BYTE [WCBdef.WinTyp], 0
	JNE Panel6
	CALL BasAdr
	PUSH DI
	ADD DI, 2*85
	MOV SI, Brief_S
	MOV BX, Brief_T
	CMP BYTE [WCBdef.BrfFul], 0
	JZ Panel3
	MOV SI, Full_S
	MOV BX, Full_T
Panel3:	PUSH CS
	POP DS
	MOV AL, 33
	CALL NgLine
	POP DI
	PUSH AX
	CALL LnsAX
	INC AX
	DW _MOV_CX_AX
	POP AX
	DW _MOV_SI_BX
	MOV AL, 'Ñ'
	CALL Panel8
	MOV AL, '³'
Panel4:	CALL Panel8
	LOOP Panel4
	MOV AL, 'Ï'
	CMP BYTE [ES:MD.MiniSta], 0
	JZ Panel5
	PUSH DI
	MOV BX, (('Ç'*256)&0FF00H)+('¶'&0FFH)  ; !!
	MOV AL, 'Ä'
	DW _XOR_CX_CX
	CALL BoxLine
	POP DI
	MOV AL, 'Á'
Panel5:	CALL Panel8
Panel6:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;Panel ENDP

;GLOBAL Panel8
Panel8:  ; PROC NEAR
	PUSH SI
	MOV BH, 0
Panel9:	MOV BL, [SI]
	DW _ADD_BL_BL
	MOV [ES:DI+BX], AX
	INC SI
	CMP BH, [SI]
	JNE Panel9
	ADD DI, 2*80
	POP SI
	RET
;Panel8 ENDP

;------------------- Set directory mask ----------------
;			   DS - WCBseg
;GLOBAL SetMask
SetMask:  ; PROC NEAR
	PUSH SI
	PUSH DI
	PUSH CX
	PUSH BX
	PUSH AX
	MOV DI, MD.TmpBuf
	MOV AL, '?'
	MOV CX, 11
	PUSH DI
	REP STOSB
	POP DI
	MOV SI, WCBdef.DskMas
	CMP BYTE [SI], 0
	JE SetMs1
	CALL Convert
SetMs1:	MOV SI, WCBdef.DskBuf
	MOV BX, [WCBdef.EndFul]
	DW _CMP_SI_BX
	JAE SetMs9
SetMs2:	SUB BX, FILENT_size
SetMs3:	CMP BYTE [WCBdef.Hidden], 0
	JNZ SetMs4
	TEST BYTE [SI+13], 6
	JNZ SetMs6
SetMs4:	TEST BYTE [SI+13], 10h
	JNZ SetMs8
	CMP BYTE [WCBdef.MasTyp], 0
	JZ SetMs5
	CALL TstExe
	JNC SetMs6
SetMs5:	CALL TstMas
	JC SetMs8
SetMs6:	DW _CMP_SI_BX
	JE SetMs9
	PUSH SI
	PUSH BX
	MOV CX, FILENT_size
SetMs7:	MOV AL, [SI]
	XCHG AL, [BX]
	MOV [SI], AL
	INC SI
	INC BX
	LOOP SetMs7
	POP BX
	POP SI
	AND BYTE [BX+13], 3Fh
	JMP SetMs2
SetMs8:	ADD SI, FILENT_size
	DW _CMP_SI_BX
	JBE SetMs3
SetMs9:	MOV [WCBdef.EndBuf], SI
	POP AX
	POP BX
	POP CX
	POP DI
	POP SI
	RET
;SetMask ENDP

;------------------ Test executable file ---------------
;			DS:SI - address of file
;	Return :	CY = 1 - executable file
;			CY = 0 - no
;GLOBAL TstExe
TstExe:  ; PROC NEAR
	PUSH ES
	PUSH SI
	PUSH DI
	PUSH CX
	PUSH AX
TstEx1:	LODSB
	CMP AL, 0
	JE TstEx3
	CMP AL, '.'
	JNE TstEx1
	PUSH CS
	POP ES
	MOV DI, Ext_S
	MOV CX, 3
TstEx2:	PUSH SI
	PUSH DI
	PUSH CX
	MOV CX, 3
	REPE CMPSB
	POP CX
	POP DI
	POP SI
	STC
	JE TstEx3
	ADD DI, 3
	LOOP TstEx2
	CLC
TstEx3:	POP AX
	POP CX
	POP DI
	POP SI
	POP ES
	RET
;TstExe ENDP

;----------------------- File sort ---------------------
;			   DS - WCBseg
;GLOBAL Sort
Sort:  ; PROC NEAR
	PUSH ES
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	PUSH DS  ; Convert all
	POP ES
	MOV SI, WCBdef.DskBuf
Sort01:	MOV AL, 0
	MOV CX, 13
	DW _MOV_DI_SI
	REPNE SCASB
	JCXZ Sort02
	DEC DI
	PUSH DI
	MOV AL, ' '
	REP STOSB
	POP CX
	DW _SUB_CX_SI
	MOV AL, '.'
	CMP AL, [SI]
	JE Sort02
	DW _MOV_DI_SI
	REPNE SCASB
	JNE Sort02
	MOV AX, [DI]
	MOV BL, [DI+2]
	MOV [SI+9], AX
	MOV [SI+11], BL
	DEC DI
	LEA CX, [SI+8]
	DW _SUB_CX_DI
	JCXZ Sort02
	MOV AL, ' '
	REP STOSB
Sort02:	ADD SI, FILENT_size
	CMP SI, [WCBdef.EndBuf]
	JB Sort01
	MOV BX, [WCBdef.EndBuf]  ; Shell sort
	SUB BX, WCBdef.DskBuf
Sort10:	MOV CX, FILENT_size
	DW _MOV_AX_BX
	DW _XOR_DX_DX
	DIV CX
	SHR AX, 1
	MUL CX
	DW _MOV_BX_AX
	DW _OR_BX_BX
	JE Sort15
	MOV CX, [WCBdef.EndBuf]
Sort11:	DW _XOR_DX_DX
	MOV SI, WCBdef.DskBuf
Sort12:	LEA DI, [SI+BX]
	DW _CMP_DI_CX
	JAE Sort14
	PUSH CX
	CALL CmpPar
	JNC Sort13
	DW _MOV_DX_DI
	MOV DI, [WCBdef.EndFul]
	MOV CX, FILENT_size
	PUSH SI
	PUSH CX
	REP MOVSB
	POP CX
	POP DI
	PUSH DI
	DW _MOV_SI_DX
	PUSH CX
	REP MOVSB
	POP CX
	MOV SI, [WCBdef.EndFul]
	DW _MOV_DI_DX
	REP MOVSB
	POP SI
Sort13:	POP CX
	ADD SI, FILENT_size
	JMP Sort12
Sort14:	DW _MOV_CX_DX
	DW _OR_DX_DX
	JNE Sort11
	JMP Sort10
Sort15:	MOV DI, WCBdef.DskBuf  ; Unconvert all
Sort20:	DW _MOV_SI_DI
	MOV CX, 8
	DW _MOV_BX_SI
Sort21:	LODSB
	CMP AL, ' '
	JE Sort22
	DW _MOV_BX_SI
Sort22:	LOOP Sort21
	MOV AL, '.'
	MOV AH, [DI+9]
	MOV DX, [DI+10]
	MOV [BX], AX
	MOV [BX+2], DX
	DW _MOV_SI_BX
	INC SI
	MOV CX, 3
Sort23:	LODSB
	CMP AL, ' '
	JE Sort24
	DW _MOV_BX_SI
Sort24:	LOOP Sort23
	MOV BYTE [BX], 0
	ADD DI, FILENT_size
	CMP DI, [WCBdef.EndBuf]
	JB Sort20
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP ES
	RET
;Sort ENDP

;GLOBAL CmpPar
CmpPar:  ; PROC NEAR
	MOV AL, [WCBdef.SortTyp]
	CMP AL, 4
	JB CmpPr0
	MOV AX, [DI+22]
	CMP AX, [SI+22]
	RET
CmpPr0:	MOV CL, [SI+13]
	MOV CH, [DI+13]
	TEST CL, 10h
	JNZ CmpPr1
	TEST CH, 10h
	JZ CmpPr2
	STC
	RET
CmpPr1:	TEST CH, 10h
	JZ CmpPr9
	CMP BYTE [SI], '.'
	JE CmpPr9
	CMP BYTE [DI], '.'
	STC
	JE CmpPr9
	JMP CmpPr4
CmpPr2:	TEST CL, 4
	JNZ CmpPr3
	TEST CH, 4
	JZ CmpPr4
	STC
	RET
CmpPr3:	TEST CH, 4
	JZ CmpPr9
CmpPr4:	CMP AL, 0
	JNE CmpPr6
CmpPr5:	PUSH SI
	PUSH DI
	DW _XCHG_SI_DI
	MOV CX, 8
	REPE CMPSB
	POP DI
	POP SI
	JNE CmpPr9
	CALL CmpExt
	RET
CmpPr6:	CMP AL, 1
	JNE CmpPr7
	CALL CmpExt
	JE CmpPr5
	RET
CmpPr7:	CMP AL, 2
	JNE CmpPr8
	MOV AX, [SI+16]
	CMP AX, [DI+16]
	JNE CmpPr9
	MOV AX, [SI+14]
	CMP AX, [DI+14]
	JE CmpPr5
	RET
CmpPr8:	MOV AX, [SI+20]
	CMP AX, [DI+20]
	JNE CmpPr9
	MOV AX, [SI+18]
	CMP AX, [DI+18]
	JE CmpPr5
CmpPr9:	RET
;CmpPar ENDP

;GLOBAL CmpExt
CmpExt:  ; PROC NEAR
	PUSH SI
	PUSH DI
	DW _XCHG_SI_DI
	ADD SI, 9
	ADD DI, 9
	MOV CX, 3
	REPE CMPSB
	POP DI
	POP SI
	RET
;CmpExt ENDP

;----------------------- Find file ---------------------
;			ES:DI - File
;			   DS - WCBseg
;	Return :	   SI - Address of file , CF=1
;				Not found ,       CF=0
;GLOBAL FnFile
FnFile:  ; PROC NEAR
	MOV SI, WCBdef.DskBuf
FnFil1:	CMP SI, [WCBdef.EndBuf]
	JAE FnFil3
	PUSH SI
	PUSH DI
FnFil2:	CMPSB
	JNE FnFil4
	CMP BYTE [SI-1], 0
	JNE FnFil2
	POP DI
	POP SI
	STC
FnFil3:	RET
FnFil4:	POP DI
	POP SI
	ADD SI, FILENT_size
	JMP FnFil1
;FnFile ENDP

;--------------- Output path in the middle -------------
;			   DS - WCBseg
;GLOBAL PutPath
PutPath:  ; PROC NEAR
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	CALL BegBX
	ADD BL, 20
	MOV BP, PutPt_P
	MOV AX, DS
	CMP AX, [ES:MD.WCBcrn]
	JNE PutPt1
	INC BP
PutPt1:	CMP BYTE [WCBdef.WinTyp], 0
	JE PutPt2
	MOV SI, Tree_S
	CMP BYTE [WCBdef.WinTyp], 2
	JA PutPt7
	JNE PutPt6
	MOV SI, Info_S
	JMP PutPt6
PutPt2:	CALL PtPt10
	MOV AL, 38
	CMP BH, 0
	JNE PutPt5
	CMP BYTE [ES:MD.Clock], 0
	JZ PutPt5
	MOV CX, DS
	CMP CX, [ES:MD.WCB2seg]
	JNE PutPt5
	MOV AX, 1C20h
	CMP BYTE [ES:MD.Country+CNTRY.TimeFmt], 0
	JE PutPt3
	MOV AX, 1E21h
PutPt3:	DW _MOV_CX_DI
	DW _SUB_CX_SI
	DW _CMP_CL_AH
	JB PutPt5
	DW _CMP_CL_AL
	JBE PutPt4
	DW _MOV_CL_AL
PutPt4:	DW _SUB_CL_AH
	SHR CL, 1
	INC CX
	DW _SUB_BL_CL
PutPt5:	CBW
	DEC AX
	INC SI
	CALL ShrtLin
	MOV SI, Var_S
PutPt6:	PUSH CS
	POP DS
	CALL CntLine
PutPt7:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;PutPath ENDP

;GLOBAL PtPt10
PtPt10:  ; PROC NEAR
	MOV DI, MD.TmpErr+1
	PUSH DI
	MOV SI, WCBdef.WinPath
	MOV AL, ' '
	STOSB
	MOV CX, LenPath
	CALL MvzLine
	MOV SI, WCBdef.DskMas
	CMP BYTE [SI], 0
	JE PtPt11
	MOV CX, 13
	CALL AddFile
	CALL MvzLine
	POP SI
	CALL LetLin
	PUSH SI
PtPt11:	CMP BYTE [WCBdef.MasTyp], 0
	JZ PtPt12
	PUSH DS
	PUSH CS
	POP DS
	MOV SI, Progs_S
	MOV CX, 25
	CALL MvzLine
	POP DS
PtPt12:	MOV AX, ' '
	STOSW
	DEC DI
	POP SI
	RET
;PtPt10 ENDP

;-------------------- Output file name -----------------
;			DS:SI - address of disk buffer
;			ES:DI - address of screen buffer
;			   AH - color
;GLOBAL PutName
PutName:  ; PROC NEAR
	PUSH SI
	PUSH CX
	PUSH BX
	MOV CX, 12
	CMP BYTE [SI], '.'
	JE PutNm3
	MOV BL, [SI+13]
	MOV BH, '.'
	MOV CX, 8
	CALL PutNm5
	MOV AL, ' '
	TEST BL, 6
	JZ PutNm1
	MOV AL, '°'
PutNm1:	CMP BYTE [ES:MD.ColTyp], 2
	JNE PutNm2
	TEST BL, 40H
	JZ PutNm2
	MOV AL, 'Þ'
	TEST BL, 6
	JZ PutNm2
	MOV AL, 'Û'
PutNm2:	STOSW
	MOV CX, 3
	LODSB
	CMP AL, 0
	JNE PutNm3
	DEC SI
PutNm3:	MOV BH, 0
	CALL PutNm5
	POP BX
	POP CX
	POP SI
	RET
;PutName ENDP

;GLOBAL PutNm5
PutNm5:  ; PROC NEAR
	LODSB
	CMP AL, 0
	JE PutNm6
	DW _CMP_AL_BH
	JNE PutNm7
PutNm6:	DEC SI
	MOV AL, ' '
PutNm7:	STOSW
	LOOP PutNm5
	RET
;PutNm5 ENDP

;--------------- Output size, date & time --------------
;			DS:SI - address of disk buffer
;			ES:DI - address of screen buffer
;			   AH - color
;GLOBAL SzDtTm
SzDtTm:  ; PROC NEAR
	INC DI
	DW _MOV_AL_AH
	STOSB
	CALL PutSize
	INC DI
	DW _MOV_AL_AH
	STOSB
	CALL PutDat0
	INC DI
	DW _MOV_AL_AH
	STOSB
	CALL PutTim0
	RET
;SzDtTm ENDP

;----------------------- Output size -------------------
;			DS:SI - address of disk buffer
;			ES:DI - address of screen buffer
;			   AH - color
;GLOBAL PutSize
PutSize:  ; PROC NEAR
	PUSH SI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	TEST BYTE [SI+13], 10h
	JZ PutSz2
	MOV DX, UpDir
	CMP BYTE [SI], '.'
	JE PutSz1
	CMP BYTE [WCBdef.SizDir], 0
	JNZ PutSz2
	MOV DX, SubDir
PutSz1:	DW _MOV_SI_DX
	MOV CX, 9
	CALL MvsBwc
	JMP PutSz4
PutSz2:	PUSH DI
	MOV CX, [SI+18]
	MOV BX, [SI+20]
	MOV SI, MD.TmpBuf
	DW _MOV_DI_SI
	MOV AL, 2
	CALL Number
	DW _MOV_DI_SI
	CMP BYTE [ES:SI], ' '
	JE PutSz3
	MOV CX, 10
	MOV AL, '9'
	REP STOSB
PutSz3:	POP DI
	INC SI
	MOV CX, 9
	CALL MvsBwe
PutSz4:	POP AX
	POP BX
	POP CX
	POP DX
	POP SI
	RET
;PutSize ENDP

;---------------------- Output date --------------------
;			DS:SI - address of disk buffer
;			ES:DI - address of screen buffer
;			   AH - color
;GLOBAL PutDat0
PutDat0:  ; PROC NEAR
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV AX, [SI+16]
	CALL PutDate
	POP AX
	PUSH AX
	DW _MOV_AL_BL
	STOSW
	DW _MOV_AL_BH
	STOSW
	MOV AL, [ES:MD.Country+CNTRY.DateSep]
	STOSW
	PUSH AX
	DW _MOV_AL_DL
	STOSW
	DW _MOV_AL_DH
	STOSW
	POP AX
	STOSW
	DW _MOV_AL_CL
	STOSW
	DW _MOV_AL_CH
	STOSW
	POP AX
	POP BX
	POP CX
	POP DX
	RET
;PutDat0 ENDP

;GLOBAL PutDate
PutDate:  ; PROC NEAR
	PUSH AX
	AND AX, STRICT WORD 1Fh
	CALL HexDec
	DW _MOV_DX_AX
	POP AX
	MOV CL, 5
	SHR AX, CL
	PUSH AX
	AND AX, STRICT WORD 0Fh
	CALL HexDec
	DW _MOV_BX_AX
	POP AX
	MOV CL, 4
	SHR AX, CL
	AND AX, STRICT WORD 7Fh
	ADD AL, 80
	MOV CL, 100
	DIV CL
	DW _MOV_CL_AH
	ADD AL, 19
	CALL HexDec
	XCHG CX, AX
	CALL HexDec
	CMP WORD [ES:MD.Country+CNTRY.DateFmt], 1
	JE PutDt1
	JB PutDt2
	XCHG DX, AX
PutDt1:	DW _XCHG_DX_BX
PutDt2:	XCHG CX, AX
	JA PutDt3
	CMP BL, '0'
	JNE PutDt3
	MOV BL, ' '
PutDt3:	RET
;PutDate ENDP

;GLOBAL BufDate
BufDate:  ; PROC NEAR
	CMP WORD [ES:MD.Country+CNTRY.DateFmt], 1
	JBE BufDt1
	STOSW
BufDt1:	XCHG AX, BX
	STOSW
	MOV AL, [ES:MD.Country+CNTRY.DateSep]
	STOSB
	PUSH AX
	DW _MOV_AX_DX
	STOSW
	POP AX
	STOSB
	JA BufDt2
	DW _MOV_AX_BX
	STOSW
BufDt2:	DW _MOV_AX_CX
	STOSW
	RET
;BufDate ENDP

;---------------------- Output time --------------------
;			DS:SI - address of disk buffer
;			ES:DI - address of screen buffer
;			   AH - color
;GLOBAL PutTim0
PutTim0:  ; PROC NEAR
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV AX, [SI+14]
	CALL PutTime
	POP AX
	PUSH AX
	CMP CH, ' '
	JNE PutTm1
	DW _MOV_AL_CH
	STOSW
PutTm1:	DW _MOV_AL_BL
	STOSW
	DW _MOV_AL_BH
	STOSW
	MOV AL, [ES:MD.Country+CNTRY.TimeSep]
	STOSW
	DW _MOV_AL_DL
	STOSW
	DW _MOV_AL_DH
	STOSW
	CMP CH, ' '
	JE PutTm2
	DW _MOV_AL_CH
	STOSW
PutTm2:	POP AX
	POP BX
	POP CX
	POP DX
	RET
;PutTim0 ENDP

;GLOBAL PutTime
PutTime:  ; PROC NEAR
	PUSH AX
	AND AX, STRICT WORD 1Fh
	DW _ADD_AX_AX
	CALL HexDec
	DW _MOV_BX_AX
	POP AX
	MOV CL, 5
	SHR AX, CL
	PUSH AX
	AND AX, STRICT WORD 3Fh
	CALL HexDec
	DW _MOV_DX_AX
	POP AX
	MOV CL, 6
	SHR AX, CL
	AND AX, STRICT WORD 1Fh
	MOV CH, ' '
	CMP BYTE [ES:MD.Country+CNTRY.TimeFmt], 0
	JNE PutTm6
	MOV CL, 12
	DIV CL
	DW _OR_AH_AH
	JNE PutTm5
	MOV AH, 12
PutTm5:	CMP AL, 0
	DW _MOV_AL_AH
	MOV CH, 'a'
	JE PutTm6
	MOV CH, 'p'
PutTm6:	CALL HexDec
	CMP AL, '0'
	JNE PutTm7
	MOV AL, ' '
PutTm7:	XCHG BX, AX
	RET
;PutTime ENDP

;GLOBAL BufTime
BufTime:  ; PROC NEAR
	XCHG AX, BX
	STOSW
	MOV AL, [ES:MD.Country+CNTRY.TimeSep]
	STOSB
	PUSH AX
	DW _MOV_AX_DX
	STOSW
	POP AX
	STOSB
	DW _MOV_AX_BX
	STOSW
	DW _MOV_AL_CH
	STOSB
	RET
;BufTime ENDP

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

;--------------- Correct first parameter ---------------
;			   DS - WCBseg
;GLOBAL CorPar
CorPar:  ; PROC NEAR
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	CMP BYTE [WCBdef.WinTyp], 1
	JA CorPr5
	CALL AdrNum
	DW _CMP_SI_DI
	JAE CorPr1
	DW _MOV_DI_SI
CorPr1:	MOV CL, [WCBdef.WinTyp]
	OR CL, [WCBdef.BrfFul]
	JNZ CorPr2
	DW _MOV_CX_AX
	DW _ADD_AX_CX
	DW _ADD_AX_CX
CorPr2:	DEC AX
	DW _MOV_CX_SI
	DW _SUB_CX_DI
	DW _SUB_CX_AX
	JBE CorPr3
	DW _ADD_DI_CX
CorPr3:	DW _SUB_DX_DI
	DW _SUB_AX_DX
	JBE CorPr4
	DW _SUB_DI_AX
	JAE CorPr4
	DW _XOR_DI_DI
CorPr4:	DW _XCHG_SI_DI
	CALL NumAdr
	DW _XCHG_SI_DI
	CALL NumAdr
	CALL ChgAdr
CorPr5:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	RET
;CorPar ENDP

;--------------- Set cursor in main window -------------
;			   DS - WCBseg
;			 AL=0 - reset cursor
;			 AL=1 - set cursor
;GLOBAL SetCur
SetCur:  ; PROC NEAR
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV AH, Back_C
	CMP AL, 0
	JZ SetCr0
	MOV AH, Cursr_C
SetCr0:	PUSH AX
	CALL AdrNum
	POP AX
	DW _MOV_CX_SI
	DW _SUB_CX_DI
	CMP BYTE [WCBdef.WinTyp], 1
	JA SetCr3
	JE SetCr4
	MOV SI, [WCBdef.CurAdr]
	CMP SI, [WCBdef.EndBuf]
	JAE SetCr3
	PUSH AX
	DW _MOV_AX_BX
	CALL BegBX
	ADD BX, 201h
	MOV DL, 38
	CMP BYTE [WCBdef.BrfFul], 0
	JNZ SetCr1
	XCHG AX, CX
	DIV CL
	DW _MOV_CL_AH
	MOV AH, 13
	MUL AH
	DW _ADD_BL_AL
	MOV DL, 12
SetCr1:	DW _ADD_BH_CL
	POP AX
	CALL BasAdr
	MOV CL, [SI+13]
	LEA SI, [DI+16]
	MOV BYTE [ES:SI], ' '
	TEST CL, 6
	JZ SetCr2
	MOV BYTE [ES:SI], '°'
SetCr2:	TEST CL, 40h
	JZ SetCr8
	CMP BYTE [ES:MD.ColTyp], 2
	JNE SetCr7
	MOV BYTE [ES:SI], 'Þ'
	TEST CL, 6
	JZ SetCr7
	MOV BYTE [ES:SI], 'Û'
	JMP SetCr7
SetCr3:	JMP SetCr9
SetCr4:	CMP SI, [ES:MD.TreeBuf+DIRTREE.TreeLen]
	JAE SetCr3
	CALL BegBX
	ADD BX, 118h
	DW _ADD_BH_CL
	MOV SI, [ES:MD.TreAdr]
	MOV CL, [ES:SI+DIRENT.DirLevel]
	CMP CL, 11
	JA SetCr5
	SUB BL, 17h
	DW _ADD_BL_CL
	DW _ADD_BL_CL
	CMP BYTE [ES:MD.TreeTyp], 0
	JZ SetCr5
	DW _ADD_BL_CL
SetCr5:	CALL BasAdr
	MOV BYTE [ES:DI], ' '
	MOV DL, 3
	CMP SI, MD.TreeBuf+DIRTREE_TreList
	JBE SetCr6
	MOV DL, 14
	CMP AL, 0
	JNZ SetCr6
	PUSH AX
	MOV AH, Back_C
	CALL Color
	MOV AL, 'Ä'
	STOSW
	POP AX
	DEC DX
SetCr6:	CMP SI, [ES:MD.TreCrnt]
	JNE SetCr8
SetCr7:	MOV AH, Slct_C
	CMP AL, 0
	JZ SetCr8
	MOV AH, CurSl_C
SetCr8:	CALL Color
	MOV DH, 1
	DW _MOV_CL_DL
	MOV CH, 0
	DW _MOV_AL_AH
	CALL MvsColr
	INC DX
	CALL Window
SetCr9:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	RET
;SetCur ENDP

;----------------------- Test info ---------------------
;GLOBAL TstInfo
TstInfo:  ; PROC NEAR
	PUSH DS
	PUSH AX
	MOV AL, [WCBdef.WinTyp]
	CALL InvWCB
	CMP AL, [WCBdef.WinTyp]
	JAE TstIn1
	MOV BYTE [WCBdef.ChgFlg], 1
TstIn1:	POP AX
	POP DS
	RET
;TstInfo ENDP

;-------------- BX files and DX directories ------------
;			   BX - number of files
;			   DX - number of directories
;			ES:DI - buffer
;GLOBAL FilDir
FilDir:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH CX
	PUSH AX
	PUSH CS
	POP DS
	DW _OR_DX_DX
	JE FilDi2
	PUSH BX
	DW _XOR_BX_BX
	DW _MOV_CX_DX
	MOV AL, 1
	CALL Number
	POP BX
	MOV SI, FilDi_S
	MOV CX, 6
	REP MOVSB
	CMP DX, 1
	JNE FilDi1
	DEC DI
FilDi1:	DW _OR_BX_BX
	JE FilDi3
	MOV CX, 5
	REP MOVSB
FilDi2:	PUSH BX
	DW _MOV_CX_BX
	DW _XOR_BX_BX
	MOV AL, 1
	CALL Number
	POP BX
	MOV SI, FilDi_S+11
	MOV CX, 12
	REP MOVSB
	CMP BX, 1
	JNE FilDi3
	SUB DI, 3
	MOVSB
FilDi3:	MOV AL, 0
	STOSB
	POP AX
	POP CX
	POP SI
	POP DS
	RET
;FilDir ENDP

;------------ Selected files and directories -----------
;	Return :	   DX - files
;			   BX - directories
;GLOBAL TotSel
TotSel:  ; PROC NEAR
	PUSH SI
	MOV SI, WCBdef.DskBuf
	DW _XOR_BX_BX
	DW _XOR_DX_DX
TotSe1:	CMP SI, [WCBdef.EndBuf]
	JAE TotSe3
	TEST BYTE [SI+13], 40h
	JZ TotSe2
	INC DX
	TEST BYTE [SI+13], 10h
	JZ TotSe2
	DEC DX
	INC BX
TotSe2:	ADD SI, FILENT_size
	JMP TotSe1
TotSe3:	POP SI
	RET
;TotSel ENDP

;---------------------- Another WCB --------------------
;GLOBAL InvWCB
InvWCB:  ; PROC NEAR
	PUSH AX
	MOV AX, DS
	MOV DS, [ES:MD.WCB1seg]
	CMP AX, [ES:MD.WCB1seg]
	JNE In1WCB
	MOV DS, [ES:MD.WCB2seg]
In1WCB:	POP AX
	RET
;InvWCB ENDP

;------------ Find iten in extension file ------------
;			DS:SI - file buffer
;	Return :	ES:SI - address of item
;FndItem	PROC	NEAR
;GLOBAL FndItem
FndItem:
	MOV AX, [SI]
	CMP AL, " "
	JE FndIt1
	CMP AL, 9
	JE FndIt1
	CMP AL, "'"
	JE FndIt1
	CALL IsCrLf
	JE FndIt1
	CMP AL, 1Ah
	JE FndIt2
	CLC
	RET
FndIt1:	CALL IsCrLfS
	JE FndItem
	DEC SI
	CMP AL, 1Ah
	JNE FndIt1
FndIt2:	STC
	RET
;FndItem	ENDP

;------------ Find string in extension file ------------
;			DS:SI - file
;	Return :	ES:SI - string, 0 - if not found
;GLOBAL FindExt
FindExt:  ; PROC NEAR
	MOV DI, MD.TmpErr
	MOV CX, 3
FnEx01:	LODSB
	CMP AL, '.'
	JE FnEx02
	CMP AL, 0
	JNE FnEx01
	DEC SI
FnEx02:	LODSB
	CMP AL, 0
	JNE FnEx03
	DEC SI
	MOV AL, ' '
FnEx03:	STOSB
	LOOP FnEx02
	PUSH DS
	PUSH ES
	POP DS
	MOV SI, MD.MenuBuf
FnEx04:	CALL FndItem
	JC FnEx13
FnEx05:	MOV DI, MD.TmpErr
	MOV CX, 3
FnEx06:	LODSB
	CMP AL, ':'
	JE FnEx10
	CMP AL, 9
	JE FnEx11
	CMP AL, '*'
	JE FnEx09
	CMP AL, '?'
	JE FnEx08
	CALL LowCase
	CMP AL, [DI]
	JNE FnEx12
FnEx08:	INC DI
	LOOP FnEx06
FnEx09:	CALL IsCrLfS
	JE FnEx04
	DEC SI
	CMP AL, 1Ah
	JE FnEx13
	CMP AL, ':'
	JNE FnEx09
	POP DS
	RET
FnEx10:	DEC SI
FnEx11:	MOV AL, ' '
	REPE SCASB
	JE FnEx09
FnEx12:	CALL FndIt1
	JNC FnEx05
FnEx13:	DW _XOR_SI_SI
	POP DS
	STC
	RET
;FindExt ENDP

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
	JNZ Inpt01
	CALL Timer
	MOV [BP-Input0__AltTime+0], DX
	MOV [BP-Input0__AltTime+2], CX
	PUSH ES
	PUSH SS
	POP ES
	MOV SI, MD.ScrBuf+2*74
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
	CMP BYTE [MD.BlDelay], 0
	JE Inpt05
	MOV AH, 2Ch
	INT 21h
	ADD CL, [MD.BlDelay]
	CMP CL, 60
	JB Inpt05
	SUB CL, 60
	INC CH
Inpt05:	MOV [BP-Input0__BlTime+0], DX
	MOV [BP-Input0__BlTime+2], CX
Inpt10:	MOV AL, [BP-Input0__IKeyBar]
	CALL PutKey
	CALL LeaveTm
	CMP BYTE [MD.BlDelay], 0
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
	MOV DH, [MD.Lines]
	MOV DL, 80
	CALL Window
Inpt13:	DW _XOR_AX_AX
	CALL GetMous
	JNZ Inpt13
	JMP Inpt03
Inpt20:	CMP BYTE [MD.Clock], 0
	JE Inpt30
	MOV DI, MD.ScrBuf+2*75
	MOV AH, 2Ch
	INT 21h
	DW _MOV_AL_CH
	MOV AH, 0
	CMP BYTE [MD.Country+CNTRY.TimeFmt], 0
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
	MOV BL, [MD.Country+CNTRY.TimeSep]
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
	CMP BYTE [MD.Country+CNTRY.TimeFmt], 0
	JNZ Inpt25
	DW _MOV_AL_BH
	STOSW
Inpt25:	MOV BX, 74
	MOV DX, 106h
	CALL Window
Inpt30:	CMP WORD [MD.AutoTim+0], 0FFFFh
	JE Inpt31
	DW _MOV_BX_DX
	MOV AH, 2Ch
	INT 21h
	DW _XCHG_BX_DX
	MOV AX, 0FE00h
	CMP CX, [MD.AutoTim+0]
	JB Inpt31
	JA Inpt32
	CMP BX, [MD.AutoTim+2]
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
	JNZ Inpt32
	MOV AH, 2
	INT 16h
	DW _MOV_BL_AL
	XCHG BL, [BP-Input0__KbdFlgs]
	CMP BYTE [MD.DesqVie], 0
	JNZ Inpt34
	CMP BYTE [MD.AltBar], 0
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
Inpt36:	MOV BH, [MD.Lines]
	DEC BH
	CALL InWind
	JNC Inpt39
	JMP Inpt10
Inpt37:	TEST AL, 0F7h
	JZ Inpt39
	MOV BH, 0
Inpt38:	MOV [BP-Input0__AltLock], BH
Inpt39:	JMP Inpt04
Inpt40:	CMP BYTE [MD.Clock], 0
	JZ Inpt41
	PUSH DS
	PUSH SS
	POP DS
	LEA SI, [BP-Input0__ClkBuf]
	MOV DI, MD.ScrBuf+2*74
	MOV CX, 6
	REP MOVSW
	POP DS
	MOV BX, 74
	MOV DX, 106h
	CALL Window
Inpt41:	MOV WORD [MD.AutoTim+0], 0FFFFh
	CMP AH, 0FCh
	JNE Inpt55
	CMP BYTE [MD.KeyBar], 0
	JZ Inpt55
	CALL GetMous
	MOV AH, 0FCh
	INC CH
	CMP CH, [MD.Lines]
	JNE Inpt55
	DEC CH
	DW _MOV_BL_CL
	AND BX, 0F8h
	DW _XOR_SI_SI
	DW _XOR_DI_DI
Inpt50:	PUSH BX
	MOV BH, [MD.Lines]
	DEC BH
	MOV DX, 108h
	CALL InWind
	POP DX
	DW _MOV_BH_AL
	MOV AL, 0
	JC Inpt51
	DW _OR_DI_DI
	JZ Inpt52
	MOV AL, 'û'
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
	CMP BYTE [MD.WinLeav], 0
	JNZ Leave1
	MOV AX, 1680h
	INT 2Fh
	CMP AL, 80h
	JNZ Leave1
	MOV BYTE [MD.WinLeav], 1
Leave1:	CMP BYTE [MD.DesqVie], 0
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
	MOV DH, [MD.Lines]
	DEC DH
	MOV DL, 79
	MOV AH, Sky1_C
	CALL Color
	DW _MOV_BH_AH
	MOV AX, 600h
	INT 10h
	MOV DI, MD.Stars
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
	MOV BL, [ES:MD.Lines]
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
	MOV SI, MD.Stars
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
	MOV AL, [ES:MD.StarTab]
	MOV AH, 9
	INT 10h
Blnk05:	MOV SI, MD.Stars
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
	MOV AL, [ES:MD.StarTab+1]
	CMP BL, 12
	JE Blnk08
	MOV AL, [ES:MD.StarTab+2]
	CMP BL, 9
	JNE Blnk07
	DW _OR_BH_BH
	JE Blnk08
	MOV BL, 0
Blnk07:	MOV AL, [ES:MD.StarTab+3]
	CMP BL, 6
	JE Blnk08
	MOV AL, [ES:MD.StarTab+4]
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
	MOV AX, [ES:MD.Rand1]
	MUL BX
	DW _MOV_CX_AX
	MOV AX, [ES:MD.Rand2]
	MOV [ES:MD.Rand1], AX
	MUL BX
	DW _ADD_AX_CX
	ADD AX, STRICT WORD 23457
	MOV [ES:MD.Rand2], AX
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
	CMP BYTE [MD.Quote], 0
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
E00_03:	MOV BYTE [MD.Quote], 0
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
E13_00:	MOV BYTE [MD.Quote], 1  ; ^Q
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

;-------------------- Search name ----------------------
;			   SI - current address
;			   BX - begin
;			   BP - end
;			   DX - add
;			   AX - key code
;	Return :	Z = 0 - not found
;			Z = 1 - found
;			   SI - new address
;GLOBAL Search
Search:  ; PROC NEAR
	PUSH SI
	CMP AL, 0Ah
	JNE Srch01
	DW _ADD_SI_DX
	DW _CMP_SI_BP
	JB Srch01
	DW _MOV_SI_BX
Srch01:	PUSH SI
	PUSH DS
	PUSH ES
	POP DS
	MOV SI, MD.MenuBuf+228
	MOV DI, MD.MenuBuf+208
	MOV CX, 15
	REP MOVSB
	POP DS
	CMP AL, 0Ah
	JE Srch02
	PUSH DX
	MOV CX, 12
	MOV SI, MD.MenuBuf+210
	MOV DX, [ES:MD.MenuBuf+208]
	CALL EdLin
	MOV [ES:MD.MenuBuf+208], DX
	POP DX
Srch02:	PUSH DS
	PUSH ES
	POP DS
	MOV SI, MD.MenuBuf+210
	MOV DI, MD.MenuBuf
	MOV CX, 13
	PUSH DI
	CALL MvzLine
	DW _MOV_CX_DI
	POP DI
	DW _SUB_CX_DI
	POP DS
	DW _MOV_SI_DI
	CALL PathLin
	POP SI
	POP AX
	JCXZ Srch06
	DW _CMP_BP_BX
	JBE Srch07
Srch03:	PUSH SI
	PUSH DI
	PUSH CX
	PUSH AX
Srch04:	LODSB
	CALL UpCase
	SCASB
	LOOPE Srch04
	POP AX
	POP CX
	POP DI
	POP SI
	JE Srch06
	DW _ADD_SI_DX
	DW _CMP_SI_BP
	JB Srch05
	DW _MOV_SI_BX
Srch05:	DW _CMP_SI_AX
	JNE Srch03
	JMP Srch07
Srch06:	PUSH DS
	PUSH ES
	POP DS
	PUSH SI
	MOV SI, MD.MenuBuf+208
	MOV DI, MD.MenuBuf+228
	MOV CX, 15
	REP MOVSB
	POP SI
	POP DS
Srch07:	DW _CMP_SI_AX
	RET
;Search ENDP

;----------------- Check file panel --------------------
;GLOBAL FilePan
FilePan:  ; PROC NEAR
	CMP BYTE [WCBdef.Visible], 0
	JZ FilPn1
	CMP BYTE [WCBdef.WinTyp], 1
FilPn1:	RET
;FilePan ENDP

; --- include vcsub3.inc

;-------------------------------------------------------
;		Version :	09.09.1999
;-------------------------------------------------------

;-------------- Read directory with save ---------------
;			    DS - WCBseg
;			AL = 0 - Without save
;ReDir	PROC	NEAR
;GLOBAL ReDir
ReDir:
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV BYTE [WCBdef.ChgFlg], 1
	CMP BYTE [WCBdef.WinTyp], 0
	JE ReDr00
	JMP RdTree
ReDr00:	PUSH AX  ; Expand WCB
	MOV BP, ES
	ADD BP, [ES:MD.FreMem2]
	MOV AX, MinView-1
	MOV CL, 4
	SHR AX, CL
	INC AX
	DW _SUB_BP_AX
	MOV CX, DS
	ADD CX, 1000h
	MOV AX, DS
	MOV BX, [ES:MD.WCB1seg]
	DW _CMP_AX_BX
	JB ReDr03
	MOV BX, [ES:MD.WCB2seg]
	DW _CMP_AX_BX
	JB ReDr03
	DW _CMP_BP_CX
	JBE ReDr02
	DW _MOV_BP_CX
ReDr02:	MOV [ES:MD.ViewSeg], BP
	JMP ReDr08
ReDr03:	MOV AX, [ES:MD.ViewSeg]
	DW _SUB_AX_BX
	DW _SUB_BP_AX
	DW _CMP_BP_CX
	JBE ReDr04
	DW _MOV_BP_CX
ReDr04:	PUSH AX
	DW _ADD_AX_BP
	MOV [ES:MD.ViewSeg], AX
	POP AX
	MOV CL, 4
	SHL AX, CL
	DW _MOV_CX_AX
	DW _MOV_SI_AX
	DEC SI
	DW _MOV_DI_SI
	PUSH DS
	PUSH ES
	MOV DS, BX
	MOV ES, BP
	STD
	REP MOVSB
	CLD
	POP ES
	POP DS
	CMP BX, [ES:MD.WCB1seg]
	JNE ReDr05
	MOV [ES:MD.WCB1seg], BP
ReDr05:	CMP BX, [ES:MD.WCB2seg]
	JNE ReDr06
	MOV [ES:MD.WCB2seg], BP
ReDr06:	CMP BX, [ES:MD.WCBcrn]
	JNE ReDr07
	MOV [ES:MD.WCBcrn], BP
ReDr07:	CMP BX, [ES:MD.WCBsec]
	JNE ReDr08
	MOV [ES:MD.WCBsec], BP
ReDr08:	MOV AX, DS  ; Save old files
	DW _SUB_BP_AX
	CMP BP, 0FFFh
	JBE ReDr09
	MOV BP, 0FFFh
ReDr09:	MOV CL, 4
	SHL BP, CL
	SUB BP, FILENT_size + FILENT_size
	POP AX
	MOV SI, WCBdef.DskBuf
	DW _XOR_DI_DI
	PUSH SI
	PUSH DI
	PUSH AX
	MOV BX, [ES:MD.ViewSeg]
	MOV AX, ES
	DW _SUB_BX_AX
	MOV AX, [ES:MD.FreMem2]
	DW _SUB_AX_BX
	CMP AX, STRICT WORD 0FFFh
	JBE ReDr10
	MOV AX, 0FFFh
ReDr10:	MOV CL, 4
	SHL AX, CL
	MOV CX, FILENT_size
	DW _XOR_DX_DX
	DIV CX
	MUL CX
	MOV CX, [WCBdef.EndBuf]
	DW _SUB_CX_SI
	MOV BX, [WCBdef.CurAdr]
	MOV DX, [WCBdef.First]
	DW _CMP_CX_AX
	JBE ReDr11
	DW _MOV_CX_AX
	DW _ADD_AX_SI
	SUB AX, STRICT WORD FILENT_size
	DW _CMP_BX_AX
	JBE ReDr11
	DW _MOV_BX_AX
	DW _CMP_DX_AX
	JBE ReDr11
	DW _MOV_DX_AX
ReDr11:	PUSH CX
	PUSH ES
	MOV ES, [ES:MD.ViewSeg]
	REP MOVSB
	POP ES
	POP CX
	ADD CX, WCBdef.DskBuf
	DW _XCHG_BX_CX
	POP AX
	MOV AH, 0  ; Read directory
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
ReDr20:	MOV SI, WCBdef.WinPath
	MOV DI, MD.TmpBuf
	DW _MOV_DX_DI
	CALL MvzLin0
	CALL AddFile
	PUSH DS
	PUSH CS
	POP DS
	MOV SI, Mask_S+1
	CALL MvzLin0
	POP DS
	DW _XOR_BX_BX
	MOV DI, WCBdef.DskBuf
	CMP BL, [WCBdef.WinPath+3]
	JE ReDr21
	PUSH ES
	PUSH DS
	POP ES
	MOV AL, '.'
	STOSB
	STOSB
	MOV CX, FILENT_size-2
	MOV AL, 0
	REP STOSB
	MOV BYTE [DI-FILENT_size+13], 10h
	MOV WORD [DI-FILENT_size+16], 182Fh
	INC BX
	POP ES
ReDr21:	MOV AL, [WCBdef.WinPath]
	SUB AL, 'A'-1
	CALL Fantom
	JC ReDr26
	CALL SetDTA
	PUSH DS
	PUSH ES
	POP DS
	POP ES
	MOV CX, 37h
	MOV AH, 4Eh
	CALL Intr21
	JNC ReDr27
	PUSH DS
	PUSH ES
	POP DS
	POP ES
	CMP AX, STRICT WORD 12h
	JNE ReDr22
	JMP ReDr34
ReDr22:	CMP AX, STRICT WORD 3
	JNE ReDr26
	POP AX
	MOV AL, 0
	INC AH
	CMP AH, 2
	PUSH AX
	JA ReDr26
	JB ReDr24
ReDr23:	MOV AL, [ES:MD.DosPth]
	MOV [WCBdef.WinPath+0], AL
	MOV BYTE [WCBdef.WinPath+3], 0
ReDr24:	MOV AL, [WCBdef.WinPath+0]
	SUB AL, 'A'-1
	CALL Fantom
	JC ReDr26
	MOV SI, WCBdef.WinPath+3
	DW _MOV_DL_AL
	MOV AH, 47h
	CALL Intr21
	JC ReDr25
	JMP ReDr20
ReDr25:	CMP AX, STRICT WORD 0Fh
	JE ReDr23
ReDr26:	POP AX
	MOV AL, 0
	PUSH AX
	JMP ReDr35
ReDr27:	MOV BYTE [MD.BlocEr], 0  ; Save entry
	MOV SI, MD.DTA+DTAs.FilName
	MOV AH, [MD.DTA+DTAs.FilAttr]
	CMP BYTE [SI], '.'
	JNE ReDr28
	TEST AH, 10h
	JZ ReDr28
	CMP BYTE [WCBdef.WinPath+3], 0
	JE ReDr32
	PUSH DI
	AND BYTE [MD.DTA+DTAs.FilAttr], 0F9h
	MOV DI, WCBdef.DskBuf+FILENT.AttrF
	JMP ReDr31
ReDr28:	MOV [ES:DI+FILENT.NumbF], BX
	INC BX
	LEA CX, [DI+FILENT_size]
	PUSH CX
	MOV CX, 13
ReDr29:	LODSB
	TEST AH, 10h
	JNZ ReDr30
	PUSH ES
	PUSH DS
	POP ES
	CALL LowCase
	POP ES
ReDr30:	STOSB
	LOOP ReDr29
ReDr31:	MOV SI, MD.DTA+DTAs.FilAttr
	AND BYTE [SI], 3Fh
	MOV CX, 9
	REP MOVSB
	POP DI
ReDr32:	MOV AH, 4Fh  ; Find next
	CALL Intr21
	JC ReDr33
	DW _CMP_DI_BP
	JB ReDr27
	CALL Beep
ReDr33:	PUSH DS
	PUSH ES
	POP DS
	POP ES
	JNC ReDr34
	CMP AX, STRICT WORD 12h
	JNE ReDr35
ReDr34:	MOV BYTE [WCBdef.ChgFlg], 0
ReDr35:	MOV [WCBdef.EndFul], DI
	MOV [WCBdef.EndBuf], DI
	MOV SI, WCBdef.DskBuf
	MOV [WCBdef.CurAdr], SI
	MOV [WCBdef.First], SI
	MOV BYTE [ES:MD.BlocEr], 0
	CMP BYTE [WCBdef.ChgFlg], 0  ; Read local extension file
	JNZ ReDr42
	PUSH DS
	PUSH ES
	POP DS
	MOV DX, MD.TmpBuf
	DW _MOV_SI_DX
	CALL CutPath
	PUSH CS
	POP DS
	DW _MOV_DI_SI
	MOV SI, Ext_F
	CALL MvzLin0
	PUSH ES
	POP DS
	MOV AL, 40h
	CALL OpenFil
	POP DS
	JC ReDr41
	DW _MOV_BX_AX
	MOV DX, WCBdef.ExtBuf
	MOV CX, LenExt-1
	MOV AH, 3Fh
	CALL Intr21
	PUSHF
	PUSH AX
	MOV AH, 3Eh
	CALL Intr21
	POP BX
	POP CX
	JC ReDr41
	PUSH CX
	POPF
	JC ReDr41
	MOV BYTE [BX+WCBdef.ExtBuf], 1Ah
	JMP ReDr45
ReDr41:	CMP AL, 53h
	JNE ReDr42
	MOV BYTE [WCBdef.ChgFlg], 1
ReDr42:	MOV SI, MD.ExtMain
	MOV DI, WCBdef.ExtBuf
	MOV CX, LenExt
	PUSH DS
	PUSH ES
	POP DS
	POP ES
	REP MOVSB
	PUSH DS
	PUSH ES
	POP DS
	POP ES
ReDr45:	MOV AL, 0  ; Scan directory sizes
	MOV [WCBdef.SizDir], AL
	CMP AL, [WCBdef.ChgFlg]
	JNZ ReDr46
	CMP AL, [ES:MD.AutoSiz]
	JZ ReDr46
	CALL DirSize
ReDr46:	CALL SetMask
	CALL Sort
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	DW _SUB_BX_SI  ; Restore cursor, selection
	DW _SUB_CX_SI
	DW _SUB_DX_SI
	PUSH ES
	MOV ES, [ES:MD.ViewSeg]
	JMP ReDr53
ReDr50:	MOV AH, [ES:DI+FILENT.AttrF]
	AND AH, 0C0h
	JZ ReDr52
	CMP AL, 0
	JNZ ReDr51
	AND AH, 80h
	JZ ReDr52
ReDr51:	CALL FnFile
	JNC ReDr52
	OR [SI+FILENT.AttrF], AH
ReDr52:	ADD DI, FILENT_size
ReDr53:	DW _CMP_DI_BX
	JB ReDr50
	CMP AL, 0
	JZ ReDr55
	DW _MOV_DI_CX
	CALL NearFl
	MOV CX, [WCBdef.CurAdr]
	JNC ReDr54
	DW _MOV_CX_SI
	MOV [WCBdef.CurAdr], CX
ReDr54:	DW _MOV_DI_DX
	CALL NearFl
	JNC ReDr55
	MOV [WCBdef.First], SI
ReDr55:	POP ES
	MOV DI, [WCBdef.EndFul]  ; Compress WCB
	ADD DI, FILENT_size
	MOV CL, 4
	DEC DI
	MOV DX, WCBdef_size - 1
	DW _CMP_DI_DX
	JAE ReDr60
	DW _MOV_DI_DX
ReDr60:	SHR DI, CL
	INC DI
	MOV AX, DS
	DW _ADD_DI_AX
	DW _MOV_BP_DI
	MOV BX, [ES:MD.WCB1seg]
	DW _CMP_AX_BX
	JB ReDr61
	MOV BX, [ES:MD.WCB2seg]
	DW _CMP_AX_BX
	JAE ReDr65
ReDr61:	MOV AX, [ES:MD.ViewSeg]
	DW _SUB_AX_BX
	DW _MOV_DX_BP
	DW _ADD_BP_AX
	SHL AX, CL
	DW _MOV_CX_AX
	MOV SI, 0
	DW _MOV_DI_SI
	PUSH DS
	PUSH ES
	MOV DS, BX
	MOV ES, DX
	CLD
	REP MOVSB
	POP ES
	POP DS
	CMP BX, [ES:MD.WCB1seg]
	JNE ReDr62
	MOV [ES:MD.WCB1seg], DX
ReDr62:	CMP BX, [ES:MD.WCB2seg]
	JNE ReDr63
	MOV [ES:MD.WCB2seg], DX
ReDr63:	CMP BX, [ES:MD.WCBcrn]
	JNE ReDr64
	MOV [ES:MD.WCBcrn], DX
ReDr64:	CMP BX, [ES:MD.WCBsec]
	JNE ReDr65
	MOV [ES:MD.WCBsec], DX
ReDr65:	MOV [ES:MD.ViewSeg], BP
	CALL CorPar
ReDr70:	CMP BYTE [WCBdef.ChgFlg], 1  ; Exit
	CMC
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	RET
;ReDir	ENDP

RdTree:	CMP BYTE [WCBdef.WinTyp], 1
	JE RdTre0
	JMP RdInfo
RdTre0:	CALL ReadTre
	JC RdTre1
	MOV BYTE [WCBdef.ChgFlg], 0
RdTre1:	JMP ReDr70

;GLOBAL ReadTre
ReadTre:  ; PROC NEAR
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	CLD
	PUSH ES
	POP DS

	MOV BP, MD.TreeBuf+MinTree*DIRENT_size+DIRTREE_size  ; ??? Expand

	MOV AL, [MD.DosPth]
	SUB AL, 'A'-1
	CALL Fantom
	JC RdTr01
	PUSH DS  ; Reading TREEINFO
	PUSH CS
	POP DS
	MOV DX, Tree_F
	MOV AL, 40h
	CALL OpenFil
	POP DS
	JNC RdTr02
	CMP AX, STRICT WORD 53h
;JNE	RdTr10
	JE JSRdTr10  ; !! SHORT would fit.
	JMP STRICT NEAR RdTr10
JSRdTr10:
RdTr01:	MOV DI, MD.TreeBuf+DIRTREE_TreList
	PUSH DI
	MOV CX, DIRENT_size
	MOV AL, 0
	REP STOSB
	POP DI
	MOV BYTE [DI+DIRENT.DirName], '\'
	MOV BYTE [DI+DIRENT.DirShift], 1
	MOV WORD [MD.TreeBuf+DIRTREE.TreeLen], 1
	MOV BYTE [MD.TreeBuf+TreeErr], 0
	JMP RdTr40
RdTr02:	DW _MOV_BX_AX
	MOV DX, MD.TreeBuf
	DW _MOV_CX_BP
	DW _SUB_CX_DX
	MOV AH, 3Fh
	CALL Intr21
	PUSHF
	PUSH AX
	MOV AH, 3Eh
	CALL Intr21
	POP AX
	POP SI
	JC RdTr01
	PUSH SI
	POPF
	JC RdTr01
	DW _CMP_AX_CX  ; MD.TreeBuf overflow ???
	JAE RdTr10
	PUSH DS
	PUSH CS
	POP DS
	MOV SI, TreBeg
	MOV DI, MD.TreeBuf+DIRTREE.TreHead
	MOV CX, 5
	PUSH DI
	REPE CMPSB
	POP SI
	POP DS
	JNE RdTr10
	MOV BX, [DI]
	MOV CL, 7
	PUSH AX
	CALL ChkSum
	CMP AX, [DI+2]
	POP AX
	JNE RdTr10
	MOV CL, 4
	SHL BX, CL
	SUB AX, STRICT WORD 11
	DW _CMP_AX_BX
	JNE RdTr10
	DW _MOV_CX_BX
	MOV SI, MD.TreeBuf+DIRTREE_TreList
	CALL ChkSum
	CMP AX, [SI+BX]
	JNE RdTr10
	JMP RdTr40
RdTr10:	MOV DI, MD.TreeBuf  ; Scanning tree
	DW _MOV_CX_BP
	DW _SUB_CX_DI
	MOV AL, 0
	REP STOSB
	MOV [MD.ZoomOne], AL
	PUSH CS
	POP DS
	MOV DI, MD.MenuBuf+40
	MOV SI, Mask_S
	MOV CX, 5
	REP MOVSB
	PUSH ES
	POP DS
	MOV BYTE [MD.TreeBuf+DIRTREE_TreList+DIRENT.DirName], '\'
	MOV BYTE [MD.TreeBuf+DIRTREE_TreList+DIRENT.DirShift], 1
	MOV DI, MD.TreeBuf+DIRTREE_TreList+DIRENT_size
RdTr11:	INC WORD [MD.TreeBuf+DIRTREE.TreeLen]
	MOV CX, [MD.TreeBuf+DIRTREE.TreeLen]
	CMP CX, 5
	JB RdTr13
	JA RdTr12
	PUSH BP
	MOV AL, [MD.DosPth]
	CBW
	MOV [MD.MenuBuf], AX
	MOV BX, 728h
	MOV BP, Tree_P
	CALL OncZoom
	POP BP
RdTr12:	PUSH DI
	PUSH BX
	DW _XOR_BX_BX
	MOV SI, MD.MenuBuf
	DW _MOV_DI_SI
	MOV AL, 1
	CALL Number
	POP BX
	PUSH BP
	PUSH BX
	ADD BH, 4
	MOV BL, 28h
	MOV BP, Tree_P
	CALL CntLine
	POP BX
	POP BP
	PUSH DX
	PUSH BX
	ADD BH, 4
	MOV DH, 1
	CALL Window
	POP BX
	POP DX
	POP DI
RdTr13:	PUSH DX
	PUSH BX
	CMP WORD [MD.TreeBuf+DIRTREE.TreeLen], 1
	JE RdTr15
RdTr14:	MOV AH, 4Fh
	JMP RdTr16
RdTr15:	CALL SetDTA
	MOV DX, MD.MenuBuf+40
	MOV CX, 37h
	MOV AH, 4Eh
RdTr16:	CALL TstBrk
	MOV AL, 2
	JC RdTr18
	CALL Intr21
	JC RdTr17
	TEST BYTE [MD.DTA+DTAs.FilAttr], 10h
	JZ RdTr14
	CMP BYTE [MD.HidDirs], 0
	JNZ RdTr29
	TEST BYTE [MD.DTA+DTAs.FilAttr], 2
	JNZ RdTr14
RdTr29:	MOV SI, MD.DTA+DTAs.FilName
	CMP BYTE [SI], '.'
	JE RdTr14
	LEA AX, [BP-(MD.TreeBuf+DIRTREE_size+DIRENT_size)]
	MOV CL, 4
	SHR AX, CL
	CMP AX, [MD.TreeBuf+DIRTREE.TreeLen]
	JA RdTr20
	CALL Beep
	MOV AL, 0
	JMP RdTr18
RdTr17:	CMP AX, STRICT WORD 53h
	JNE RdTr22
	MOV AL, 1
RdTr18:	MOV [MD.TreeBuf+TreeErr], AL
	MOV SI, DirRecu+MD.TreeBuf+DIRTREE_TreList
RdTr19:	MOV BYTE [SI], 0
	ADD SI, 16
	DW _CMP_SI_BP
	JB RdTr19
	JMP RdTr26
RdTr20:	LEA CX, [BP-DIRENT_size]
	DW _SUB_CX_DI
	JBE RdTr80
	PUSH SI
	PUSH DI
	LEA DI, [BP-1]
	LEA SI, [DI-DIRENT_size]
	STD
	REP MOVSB
	CLD
	POP DI
	POP SI
RdTr80:	MOV CX, 12
	PUSH DI
	PUSH CX
	REP MOVSB
	POP CX
	POP SI
	CALL FilZero
	MOV AL, 0FFh
	STOSB
	MOV AL, [MD.TreeBuf+TreeLev]
	INC AX
	STOSB
	INC DI
	INC DI
	CMP AL, [DI-2*DIRENT_size+DIRENT.DirLevel]
	MOV AL, 1
	JNE RdTr21
	MOV BYTE [DIRENT.DirCont+DI-2*DIRENT_size], 1
	MOV AL, 0
RdTr21:	MOV [DI-DIRENT_size+DIRENT.DirShift], AL
	MOV BYTE [DIRENT.DirCont+DI-DIRENT_size], 0
	POP BX
	POP DX
	JMP RdTr11
RdTr22:	MOV AL, 0
	CMP AL, [DI-DIRENT_size+DirRecu]
	JNE RdTr23
	CMP AL, [DI+DirRecu]
	JNE RdTr24
	JMP RdTr26
RdTr23:	SUB DI, 16
	CMP AL, [DI-DIRENT_size+DirRecu]
	JNE RdTr23
RdTr24:	MOV [DI+DirRecu], AL
	MOV CL, [DI+DIRENT.DirLevel]
	MOV [MD.TreeBuf+TreeLev], CL
	MOV CH, 0
	PUSH DI
	MOV DI, MD.MenuBuf+40
RdTr25:	PUSH CX
	MOV CX, 20
	MOV AL, '\'
	REPNE SCASB
	POP CX
	LOOP RdTr25
	POP SI
	PUSH SI
	MOV CX, 13
	CALL MvzLine
	PUSH CS
	POP DS
	MOV SI, Mask_S
	MOVSB
	DW _MOV_AX_DI
	MOV CX, 4
	REP MOVSB
	PUSH ES
	POP DS
	POP DI
	ADD DI, 16
	CMP AX, MD.MenuBuf+40+LenPath
	JA RdTr22
	JMP RdTr15
RdTr26:	POP BX
	POP DX
	CMP WORD [MD.TreeBuf+DIRTREE.TreeLen], 5
	JB RdTr30
	MOV SI, MD.ErrBuf
	CALL ResWin
	CALL Window
RdTr30:	CMP BYTE [MD.TreeBuf+TreeErr], 0  ; Delete TREEINFO
	JNE RdTr31
	CMP WORD [ES:MD.TreeBuf+DIRTREE.TreeLen], 5
	JAE RdTr32
	PUSH DS
	PUSH CS
	POP DS
	MOV DX, Tree_F
	MOV AH, 41h
	CALL Intr21
	POP DS
RdTr31:	JMP RdTr40
RdTr32:	CALL TstBrk  ; Save TREEINFO
	JC RdTr31
	MOV BX, 728h
	MOV BP, TrSav_P
	CALL OncZoom
	PUSH SI
	PUSH DX
	PUSH BX
	PUSH CS
	POP DS
	MOV SI, TreBeg
	MOV DI, MD.TreeBuf+DIRTREE.TreHead
	MOV CX, 5
	PUSH DI
	REP MOVSB
	PUSH ES
	POP DS
	POP SI
	MOV BX, [DI]
	INC DI
	INC DI
	MOV CL, 7
	CALL ChkSum
	STOSW
	MOV CL, 4
	SHL BX, CL
	DW _MOV_CX_BX
	DW _MOV_SI_DI
	CALL ChkSum
	MOV [SI+BX], AX
	DW _MOV_BX_CX
	ADD BX, 11
	PUSH CS
	POP DS
	MOV DX, Tree_F
	MOV AX, 4300h
	CALL Intr21
	JNC RdTr34
	CMP AX, STRICT WORD 2
	JNE RdTr37
	DW _XOR_CX_CX
RdTr34:	OR CL, 20h
	MOV BYTE [ES:MD.BlocEr], 1
	MOV AH, 3Ch
	CALL Intr21
	JNC RdTr36
	CMP AX, STRICT WORD 5
	JNE RdTr37
RdTr35:	CALL Beep
	JMP RdTr37
RdTr36:	PUSH ES
	POP DS
	DW _MOV_CX_BX
	DW _MOV_BX_AX
	MOV DX, MD.TreeBuf
	MOV AH, 40h
	CALL Intr21
	PUSHF
	PUSH AX
	MOV AH, 3Eh
	CALL Intr21
	POP AX
	POP BX
	JC RdTr37
	PUSH BX
	POPF
	JC RdTr37
	DW _CMP_AX_CX
	JNE RdTr35
RdTr37:	MOV BYTE [ES:MD.BlocEr], 0
	POP BX
	POP DX
	POP SI
	CALL ResWin
	CALL Window
RdTr40:	CALL TreeCur  ; Set cursor
	MOV AL, [ES:MD.TreeBuf+TreeErr]
	DEC AX
	CMP AL, 1
; ??? Compress
	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;ReadTre ENDP

;GLOBAL TreeCur
TreeCur:  ; PROC NEAR  ; Set cursor
	PUSH DS
	PUSH ES
	POP DS
	MOV AX, MD.TreeBuf+DIRTREE_TreList
	MOV [MD.TreFrst], AX
	MOV [MD.TreAdr], AX
	CALL TrCr11
	JNC TrCr01
	CALL TrCr10
	JC TrCr02
TrCr01:	CALL SizDX
	DW _MOV_AL_DH
	SUB AL, 4
	CALL TrCr20
TrCr02:	POP DS
	RET
;TreeCur ENDP

;TrCr10	PROC	NEAR
;GLOBAL TrCr10
TrCr10:
	MOV SI, MD.DosPth
	MOV DI, MD.CrnPath
	MOV CX, LenPath
	REP MOVSB
TrCr11:	MOV AL, [MD.DosPth]
	CMP AL, [MD.CrnPath]
	JNE TrCr15
	MOV DI, MD.MenuBuf
	MOV AH, ':'
	STOSW
	MOV AX, '\'
	STOSW
	MOV SI, MD.TreeBuf+DIRTREE_TreList
	MOV CX, [MD.TreeBuf+DIRTREE.TreeLen]
	JCXZ TrCr15
TrCr19:	PUSH SI
	PUSH CX
	MOV CL, [SI+13]
	MOV CH, 0
	JCXZ TrCr13
	MOV DI, MD.MenuBuf
	MOV AL, '\'
TrCr12:	PUSH CX
	MOV CX, 20
	REPNE SCASB
	POP CX
	LOOP TrCr12
	MOV CX, 13
	CALL MvzLine
	MOV AX, '\'
	STOSW
TrCr13:	MOV DI, MD.CrnPath
	PUSH DI
	MOV CX, 100
	MOV AL, 0
	REPNE SCASB
	POP SI
	DW _MOV_CX_DI
	DW _SUB_CX_SI
	DEC CX
	MOV DI, MD.MenuBuf
	REPE CMPSB
	POP CX
	POP SI
	JNE TrCr14
	SCASB
	JE TrCr16
	SCASB
	JE TrCr16
TrCr14:	ADD SI, 16
	LOOP TrCr19
TrCr15:	STC
	JMP TrCr17
TrCr16:	MOV [MD.TreAdr], SI
	CLC
TrCr17:	RET
;TrCr10	ENDP

;GLOBAL TrCr20
TrCr20:  ; PROC NEAR
	MOV SI, [MD.TreAdr]
	AND AL, 7Eh
	CBW
	MOV CL, 3
	SHL AX, CL
	DW _SUB_SI_AX
	MOV AX, MD.TreeBuf+DIRTREE_TreList
	JB TrCr21
	DW _CMP_SI_AX
	JB TrCr21
	DW _MOV_AX_SI
TrCr21:	MOV [MD.TreFrst], AX
	RET
;TrCr20 ENDP

RdInfo:	PUSH DS
	CMP BYTE [WCBdef.WinTyp], 2
	JE RdInf0
	JMP RdInf4
RdInf0:	PUSH ES
	POP DS
	MOV WORD [MD.ClstSiz], 1
	MOV WORD [MD.Total], 0
	MOV WORD [MD.FreeDsk], 0
	MOV WORD [MD.InfoLen], 0FFFFh
	MOV BYTE [MD.Volume], 0
	MOV AL, [MD.DosPth]
	SUB AL, 'A'-1
	DW _MOV_DL_AL
	CALL Fantom
	JC RdInf4
	MOV AH, 36h
	CALL Intr21
	JC RdInf4
	CMP AX, STRICT WORD 0FFFFh
	JE RdInf4
	MOV [MD.Total], DX
	MOV [MD.FreeDsk], BX
	MUL CX
	MOV [MD.ClstSiz], AX
	PUSH CS
	POP DS
	MOV DX, DrIn_F
	MOV AL, 40h
	CALL OpenFil
	PUSH ES
	POP DS
	JNC RdInf1
	CMP AX, STRICT WORD 2
	JE RdInf2
	JMP RdInf4
RdInf1:	DW _MOV_BX_AX
	MOV DX, MD.InfBuf
	MOV CX, (MaxLins-13)*38
	MOV AH, 3Fh
	CALL Intr21
	PUSHF
	PUSH AX
	MOV AH, 3Eh
	CALL Intr21
	POP AX
	POP CX
	JC RdInf4
	PUSH CX
	POPF
	JC RdInf4
	MOV [MD.InfoLen], AX
RdInf2:	MOV SI, MD.Volume
	CALL GetVol
	JNC RdInf3
	CMP AX, STRICT WORD 53h
	JE RdInf4
RdInf3:	POP DS
	MOV BYTE [WCBdef.ChgFlg], 0
	PUSH DS
RdInf4:	POP DS
	JMP ReDr70

;---------------------- Output files -------------------
;			   DS - WCBseg
;PutFls	PROC	NEAR
;GLOBAL PutFls
PutFls:
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	CMP BYTE [WCBdef.WinTyp], 0
	JE PtFs00
	JMP PutTre
PtFs00:	CALL CorPar
	CALL LnsAX
	DW _MOV_CX_AX
	CALL BegBX
	ADD BX, 201h
	DW _MOV_DL_BH
	DW _ADD_DL_CL
	DW _MOV_DH_CL
	MOV SI, [WCBdef.First]
	CMP BYTE [WCBdef.BrfFul], 0
	JNZ PtFs01
	DW _ADD_CX_AX
	DW _ADD_CX_AX
PtFs01:	CMP SI, [WCBdef.EndBuf]
	JAE PtFs06
	MOV AH, Back_C
	MOV AL, Slct_C
	CMP SI, [WCBdef.CurAdr]
	JNE PtFs02
	MOV DI, DS
	CMP DI, [ES:MD.WCBcrn]
	JNE PtFs02
	MOV AH, Cursr_C
	MOV AL, CurSl_C
PtFs02:	TEST BYTE [SI+FILENT.AttrF], 40h
	JZ PtFs03
	DW _MOV_AH_AL
PtFs03:	CALL Color
	CALL BasAdr
	CALL PutName
	INC BH
	CMP BYTE [WCBdef.BrfFul], 0
	JZ PtFs04
	CALL SzDtTm
	JMP PtFs05
PtFs04:	DW _CMP_BH_DL
	JB PtFs05
	DW _SUB_BH_DH
	ADD BL, 13
PtFs05:	ADD SI, FILENT_size
	LOOP PtFs01
PtFs06:	CMP BYTE [ES:MD.MiniSta], 0
	JZ PtFs07
	CALL BegBX
	CALL SizDX
	DW _ADD_BH_DH
	SUB BH, 2
	DW _MOV_BP_BX
	INC BX
	CALL BasAdr
	PUSH DI
	MOV AH, Back_C
	CALL Color
	MOV AL, ' '
	MOV CX, 38
	REP STOSW
	POP DI
	DW _XOR_DX_DX
	DW _XOR_CX_CX
	DW _XOR_BX_BX
	MOV SI, WCBdef.DskBuf
	CMP SI, [WCBdef.EndBuf]
	JB PtFs08
PtFs07:	JMP PtFs15
PtFs08:	TEST BYTE [SI+FILENT.AttrF], 40h
	JZ PtFs10
	CMP BYTE [WCBdef.SizDir], 0
	JNZ PtFs09
	TEST BYTE [SI+FILENT.AttrF], 10h
	JNZ PtFs10
PtFs09:	ADD CX, [SI+FILENT.SizeF+0]
	ADC BX, [SI+FILENT.SizeF+2]
	INC DX
PtFs10:	ADD SI, FILENT_size
	CMP SI, [WCBdef.EndBuf]
	JB PtFs08
	DW _OR_DX_DX
	JNE PtFs11
	MOV SI, [WCBdef.CurAdr]
	PUSH SI
	PUSH DI
	CALL MovDz0
	POP DI
	ADD DI, 2*12
	POP SI
	CALL SzDtTm
	JMP PtFs15
PtFs11:	MOV DI, MD.TmpBuf
	PUSH DI
	MOV AL, 1
	CALL Number
	PUSH CS
	POP DS
	MOV SI, BytIn_S
	CMP CX, 1
	MOV CX, 6
	REP MOVSB
	JNE PtFs12
	DW _OR_BX_BX
	JNE PtFs12
	DEC DI
PtFs12:	MOV CX, 4
	REP MOVSB
	DW _XOR_BX_BX
	DW _MOV_CX_DX
	MOV AL, 1
	CALL Number
	MOV CX, 15
	REP MOVSB
	CMP DX, 1
	JNE PtFs13
	DEC DI
PtFs13:	PUSH ES
	POP DS
	MOV BYTE [DI], 0
	POP SI
	DW _SUB_DI_SI
	CMP DI, 36
	JBE PtFs14
	DW _MOV_DI_SI
	MOV CX, 25
	MOV AL, [CS:BytIn_S+1]
	REPNE SCASB
	DEC DI
	DEC DI
	PUSH SI
	DW _MOV_SI_DI
	CMP BYTE [MD.Country+CNTRY.Sep1000], 1
	CMC
	SBB DI, 3
	MOV AL, 'K'
	STOSB
	MOV CX, 40
	REP MOVSB
	POP SI
PtFs14:	DW _MOV_BX_BP
	ADD BL, 20
	MOV BP, PtFs_P
	CALL CntLine
PtFs15:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;PutFls	ENDP

PutTre:	CMP BYTE [WCBdef.WinTyp], 1
	JE PtTre0
	JMP PutInf
PtTre0:	CALL CorPar
	MOV BP, PutTr_P
	CALL BegBX
	CALL SizDX
	CALL PutTree
	JMP PtFs15

;GLOBAL PutTree
PutTree:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV [ES:MD.MenuBuf+48], DS
	PUSH ES
	POP DS
	DW _MOV_AX_BX
	DW _ADD_AH_DH
	SUB AH, 2
	INC AX
	MOV [MD.MenuBuf+46], AX
	DW _XOR_AX_AX
	MOV [MD.TreCrnt], AX
	MOV CX, [MD.TreeBuf+DIRTREE.TreeLen]
	JCXZ PtTr02
	MOV SI, MD.TreeBuf+DIRTREE_TreList
PtTr01:	CMP BYTE [ES:SI+13], 7
	JA PtTr02
	ADD SI, 16
	LOOP PtTr01
	INC AX
PtTr02:	MOV [MD.TreeTyp], AL
	MOV DI, MD.MenuBuf
	PUSH DI
	MOV CX, 40
	MOV AL, 0
	REP STOSB
	MOV DI, MD.MenuBuf+50
	MOV AX, [MD.DosPth]
	STOSW
	MOV AX, '\'
	STOSW
	ADD BX, 102h
	CALL BasAdr
	POP BX
	MOV SI, MD.TreeBuf+DIRTREE_TreList
	MOV AX, [MD.TreFrst]
	DW _SUB_AX_SI
	MOV CL, 4
	SHR AX, CL
	DW _MOV_CX_AX
	MOV AX, [MD.TreeBuf+DIRTREE.TreeLen]
	DW _SUB_AX_CX
	DW _MOV_CL_DH
	SUB CL, 4
	MOV CH, 0
	DW _CMP_CX_AX
	JBE PtTr10
	DW _MOV_CX_AX
	DW _OR_AX_AX
	JNE PtTr10
	JMP PtTr35
PtTr10:	PUSH DI
	PUSH SI
	PUSH CX
	PUSH BX
	DW _MOV_DX_DI
	DEC DI
	DEC DI
	MOV AH, [CS:BP]
	CALL Color
	MOV AL, ' '
	MOV CX, 38
	REP STOSW
	DW _MOV_DI_DX
	MOV CL, [SI+13]
	MOV CH, 0
	JCXZ PtTr18
	DEC CX
	JCXZ PtTr15
	MOV AL, '³'
PtTr11:	CMP SI, [MD.TreFrst]
	JB PtTr14
	CMP BX, MD.MenuBuf+10
	JA PtTr14
	JE PtTr13
	CMP BYTE [BX], 0
	JE PtTr12
	STOSB
	DEC DI
PtTr12:	ADD DI, 2*2
	CMP BYTE [MD.TreeTyp], 0
	JE PtTr14
PtTr13:	INC DI
	INC DI
PtTr14:	INC BX
	LOOP PtTr11
PtTr15:	MOV AL, 'Ã'
	CMP BYTE [SI+15], 0
	JNE PtTr16
	MOV AL, 'À'
	MOV BYTE [BX], 0
PtTr16:	INC BX
	CMP SI, [ES:MD.TreFrst]
	JB PtTr18
	CMP BX, MD.MenuBuf+12
	JAE PtTr17
	STOSB
	DEC DI
PtTr17:	INC DI
	INC DI
	MOV AL, 'Ä'
	STOSB
	INC DI
	CMP BYTE [MD.TreeTyp], 0
	JE PtTr18
	STOSB
	INC DI
PtTr18:	CMP BYTE [SI+16+14], 0
	JE PtTr19
	MOV BYTE [BX], 1
PtTr19:	MOV CL, [SI+13]
	MOV CH, 0
	JCXZ PtTr21
	PUSH SI
	PUSH DI
	MOV DI, MD.MenuBuf+50
	MOV AL, '\'
PtTr20:	PUSH CX
	MOV CX, 20
	REPNE SCASB
	POP CX
	LOOP PtTr20
	MOV CX, 13
	CALL MvzLine
	MOV AX, '\'
	STOSW
	POP DI
	POP SI
PtTr21:	CMP SI, [MD.TreFrst]
	JAE PtTr22
	JMP PtTr33
PtTr22:	MOV CX, 12
	CMP SI, MD.TreeBuf+DIRTREE_TreList
	JNE PtTr23
	MOV CX, 1
PtTr23:	PUSH SI
	PUSH DI
	PUSH CX
	MOV SI, MD.MenuBuf+50
	MOV DI, MD.DosPth
	PUSH DI
	MOV CX, 100
	MOV AL, 0
	REPNE SCASB
	DW _MOV_CX_DI
	POP DI
	DW _SUB_CX_DI
	DEC CX
	REPE CMPSB
	JNE PtTr24
	CMP AL, [SI]
	JE PtTr24
	CMP AL, [SI+1]
PtTr24:	POP CX
	POP DI
	POP SI
	MOV AX, [CS:BP]
	JNE PtTr25
	MOV [MD.TreCrnt], SI
	MOV AX, [CS:BP+2]
	PUSH AX
	DW _MOV_AH_AL
	CALL Color
	DW _MOV_BX_DX
	MOV AL, ''
	MOV [BX+2*36], AX
	POP AX
PtTr25:	DW _XCHG_AH_AL
	CMP SI, [MD.TreAdr]
	JE PtTr26
	CALL Color
	JMP PtTr31
PtTr26:	MOV BX, [MD.MenuBuf+48]
	CMP BX, [ES:MD.WCBcrn]
	MOV BX, (('Ý'*256)&0FF00H)+('Þ'&0FFH)  ; !!
	JNE PtTr27
	MOV BX, ((' '*256)&0FF00H)+(' '&0FFH)  ; !!
	DW _MOV_AH_AL
PtTr27:	CALL Color
	DW _MOV_AL_BH
	MOV [DI-2], AX
	PUSH DI
	PUSH SI
	PUSH CX
	DW _ADD_DI_CX
	DW _ADD_DI_CX
	DW _MOV_AL_BL
	MOV [DI], AX
	MOV SI, MD.MenuBuf+50
	MOV DI, MD.MenuBuf+140
	MOV CX, LenPath+13
	PUSH DI
	PUSH CX
	REP MOVSB
	POP CX
	POP DI
	DW _MOV_SI_DI
	MOV AL, 0
	CMP AL, [DI+3]
	JE PtTr28
	REPNE SCASB
	DEC DI
	DEC DI
	STOSB
PtTr28:	PUSH SI
	MOV DI, MD.CrnPath
	MOV CX, LenPath
	REP MOVSB
	POP SI
	MOV CX, 38
	PUSH AX
	DW _MOV_AX_CX
	CALL ShrtLin
	POP AX
	MOV BX, [MD.MenuBuf+46]
	CALL BasAdr
PtTr29:	LODSB
	CMP AL, 0
	JNE PtTr30
	DEC SI
	MOV AL, ' '
PtTr30:	STOSB
	INC DI
	LOOP PtTr29
	POP CX
	POP SI
	POP DI
PtTr31:	LODSB
	CMP AL, 0
	JNE PtTr32
	DEC SI
	MOV AL, ' '
PtTr32:	STOSW
	LOOP PtTr31
PtTr33:	POP BX
	POP CX
	POP SI
	POP DI
	INC CX
	CMP SI, [MD.TreFrst]
	JB PtTr34
	DEC CX
	ADD DI, 2*80
PtTr34:	ADD SI, 16
	LOOP PtTr36
PtTr35:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
PtTr36:	JMP PtTr10
;PutTree ENDP

PutInf:	CMP BYTE [WCBdef.WinTyp], 2
	JE PtIn00
	JMP PtFs15
PtIn00:	CALL BegBX
	ADD BX, 314h
	PUSH DS
	PUSH ES
	POP DS
	MOV AX, [MD.Memorys]
	MOV DX, PtIn2_S
	CALL PtIn20
	MOV AX, [MD.FreMem2]
	CMP BYTE [ES:MD.LoadFl], 0
	JE PtIn01
	MOV AX, [MD.FreMem1]
PtIn01:	MOV DX, PtIn3_S
	CALL PtIn20
	MOV AL, [MD.DosPth]
	MOV AH, 0
	MOV [MD.TmpErr+101], AX
	MOV SI, MD.Volume
	MOV DX, PtInB_S
	CMP BYTE [SI], 0
	JE PtIn19
	MOV DX, PtInA_S
PtIn19:	MOV DI, MD.TmpErr+1
	MOV CX, 12
	REP MOVSB
	MOV SI, PtIn4_S
	CALL PtIn23
	MOV DX, PtIn6_S
	MOV AX, [MD.Total]
	CALL PtIn21
	MOV DX, PtIn7_S
	MOV AX, [MD.FreeDsk]
	CALL PtIn21
	POP DS
	PUSH DS
	CALL InvWCB
	CALL FilePan
	JNC PtIn06
	PUSH DS
	PUSH BX
	MOV SI, WCBdef.DskBuf
	DW _XOR_BX_BX
	DW _XOR_CX_CX
	DW _XOR_DX_DX
PtIn02:	CMP SI, [WCBdef.EndBuf]
	JAE PtIn07
	TEST BYTE [SI+FILENT.AttrF], 10h
	JNZ PtIn05
	INC CX
	PUSH CX
	PUSH DX
	MOV AX, [SI+(FILENT.SizeF+0)]
	MOV DX, [SI+(FILENT.SizeF+2)]
	MOV CX, [ES:MD.ClstSiz]
	CMP CX, 1
	JBE PtIn04
	PUSH AX
	DW _MOV_AX_DX
	DW _XOR_DX_DX
	DIV CX
	PUSH DX
	MUL CX
	DW _ADD_BX_AX
	POP DX
	POP AX
	DIV CX
	DW _OR_DX_DX
	JE PtIn03
	INC AX
PtIn03:	MUL CX
PtIn04:	DW _MOV_CX_DX
	POP DX
	DW _ADD_DX_AX
	DW _ADC_BX_CX
	POP CX
PtIn05:	ADD SI, FILENT_size
	JMP PtIn02
PtIn06:	JMP PtIn11
PtIn07:	PUSH BX
	DW _XOR_BX_BX
	MOV DI, MD.TmpErr+1
	MOV AL, 1
	CALL Number
	POP BX
	PUSH CX
	DW _MOV_CX_DX
	MOV DI, MD.TmpErr+101
	MOV AL, 1
	CALL Number
	POP AX
	PUSH CS
	POP DS
	MOV SI, PtIn8_S
	MOV DI, MD.TmpBuf
	PUSH DI
	MOV CX, 12
	REP MOVSB
	CMP AX, STRICT WORD 1
	JNE PtIn08
	DEC DI
PtIn08:	MOV CX, 5
	REP MOVSB
	CMP AX, STRICT WORD 1
	JE PtIn09
	DEC DI
PtIn09:	MOV CX, 13
	REP MOVSB
	DW _OR_BX_BX
	JNE PtIn10
	CMP DX, 1
	JNE PtIn10
	DEC DI
PtIn10:	MOV CX, 4
	REP MOVSB
	POP SI
	POP BX
	PUSH ES
	POP DS
	MOV BP, PtIn_P
	CALL CntLine
	POP DS
	INC BH
	CALL PtPt10
	INC SI
	MOV AX, 38-1
	CALL ShrtLin
	PUSH CS
	POP DS
	MOV SI, Var_S
	CALL CntLine
	DEC BH
PtIn11:	PUSH ES
	POP DS
	ADD BH, 4
	CALL SizDX
	DW _MOV_CL_DH
	SUB CL, 12
	MOV CH, 0
	MOV DX, [MD.InfoLen]
	CMP DX, 0FFFFh
	JNE PtIn12
	PUSH CS
	POP DS
	MOV SI, PtIn9_S
	MOV BP, PtIn_P
	CALL CntLine
	JMP PtIn17
PtIn12:	SUB BX, 112h
	CALL BasAdr
	MOV SI, MD.InfBuf
	DW _ADD_DX_SI
PtIn13:	PUSH DI
	PUSH CX
	MOV CX, 36
PtIn14:	CALL IsCrLfS
	JE PtIn16
	DEC SI
	DW _CMP_SI_DX
	JA PtIn16
	JCXZ PtIn14
	CMP AL, 9
	JNE PtIn15
	MOV AH, 36
	DW _SUB_AH_CL
	AND AH, 7
	MOV AL, 8
	DW _SUB_AL_AH
	CBW
	DW _ADD_DI_AX
	DW _ADD_DI_AX
	DW _SUB_CX_AX
	JAE PtIn14
	DW _XOR_CX_CX
	JMP PtIn14
PtIn15:	STOSB
	INC DI
	DEC CX
	JMP PtIn14
PtIn16:	POP CX
	POP DI
	DW _CMP_SI_DX
	JA PtIn17
	ADD DI, 2*80
	LOOP PtIn13
PtIn17:	POP DS
	JMP PtFs15

;PtIn20	PROC	NEAR
;GLOBAL PtIn20
PtIn20:
	PUSH BX
	DW _MOV_BL_AH
	MOV BH, 0
	MOV CL, 4
	SHL AX, CL
	SHR BX, CL
	MOV SI, PtIn1_S
	JMP PtIn22
PtIn21:	PUSH BX
	PUSH DX
	MUL WORD [ES:MD.ClstSiz]
	DW _MOV_BX_DX
	POP DX
	MOV SI, PtIn5_S
PtIn22:	DW _MOV_CX_AX
	MOV DI, MD.TmpErr+1
	MOV AL, 1
	CALL Number
	POP BX
PtIn23:	PUSH DS
	PUSH CS
	POP DS
	MOV BP, PtIn_P
	CALL CntLine
	POP DS
	INC BH
	RET
;PtIn20	ENDP

;--------------------- Find near file ------------------
;			ES:DI - File
;			   BX - End
;			   DS - WCBseg
;	Return :	   SI - Address of file , CF=1
;				Not found ,       CF=0
;GLOBAL NearFl
NearFl:  ; PROC NEAR
	PUSH DI
	DW _CMP_DI_BX
	JAE NrFl03
NrFl01:	CALL FnFile
	JC NrFl03
	ADD DI, FILENT_size
	DW _CMP_DI_BX
	JB NrFl01
	POP DI
	PUSH DI
NrFl02:	CALL FnFile
	JC NrFl03
	SUB DI, FILENT_size
	JAE NrFl02
	CLC
NrFl03:	POP DI
	RET
;NearFl ENDP

;----------------------- Set Path ----------------------
;	Return :	CY=1 - Error
;GLOBAL SetPth
SetPth:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH AX
	PUSH ES
	POP DS
	MOV BYTE [MD.PathEr], 1
	MOV AH, 19h
	INT 21h
	DW _MOV_DL_AL
	MOV DI, MD.DosPth
	ADD AL, 'A'
	STOSB
	MOV AX, ':\'
	STOSW
	DW _MOV_SI_DI
	MOV AL, 0
	STOSB
	INC DX
	DW _MOV_AL_DL
	CALL Fantom
	JC SetPt1
	MOV AH, 47h
	CALL Intr21
	JC SetPt1
	MOV BYTE [MD.PathEr], 0
SetPt1:	POP AX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;SetPth ENDP

;---------------------- Save setup ---------------------
;GLOBAL SaveSet
SaveSet:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	CALL MakeIni
	DW _MOV_BX_CX
	MOV DX, MD.TmpBuf
	MOV SI, Init_F
	DW _MOV_DI_DX
	CALL MainFil
	CALL ChgDisk
	JC SavSt2
	MOV AX, 4300h
	CALL Intr21
	JNC SavSt1
	CMP AX, STRICT WORD 2
	JNE SavSt3
	DW _XOR_CX_CX
SavSt1:	OR CL, 20h
	MOV AH, 3Ch
	CALL Intr21
	JC SavSt4
	DW _MOV_CX_BX
	DW _MOV_BX_AX
	MOV DX, MD.MenuBuf
	MOV AH, 40h
	CALL Intr21
	PUSHF
	PUSH AX
	MOV AH, 3Eh
	CALL Intr21
	POP BX
	POP DX
	JC SavSt4
	DW _MOV_AX_BX
	PUSH DX
	POPF
	JC SavSt4
	DW _CMP_AX_CX
	JE SavSt4
SavSt2:	MOV AL, 0
SavSt3:	STC
SavSt4:	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;SaveSet ENDP

;GLOBAL MakeIni
MakeIni:  ; PROC NEAR
	PUSH DI
	PUSH AX
	MOV DI, MD.MenuBuf
	PUSH DI
	MOV AL, 'V'
	STOSB
	STOSB
	STOSB
	MOV DS, [ES:MD.WCB1seg]
	CALL MkIni1
	MOV DS, [ES:MD.WCB2seg]
	CALL MkIni1
	PUSH ES
	POP DS
	MOV SI, 0
	MOV CX, MD_CmnIni
	REP MOVSB
	POP SI
	DW _MOV_CX_DI
	DW _SUB_CX_SI
	CALL ChkSum
	STOSW
	INC CX
	INC CX
	POP AX
	POP DI
	RET
;MakeIni ENDP

;GLOBAL MkIni1
MkIni1:  ; PROC NEAR
	MOV SI, WCBdef.DskMas
	MOV CX, 13
	CALL FilZero
	MOV SI, WCBdef.WinPath
	MOV CX, LenPath
	CALL FilZero
	DW _XOR_SI_SI
	MOV CX, WCBdef_WCBini
	REP MOVSB
	RET
;MkIni1 ENDP

;-------------------- Fantom Diskette ------------------
;			AL - Disk ID
;GLOBAL Fantom
Fantom:  ; PROC NEAR
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
	DW _MOV_BL_AL
	MOV AX, 440Eh
	INT 21h
	JC Fantm1
	CMP AL, 0
	JE Fantm1
	DW _CMP_AL_BL
	JE Fantm1
	DW _MOV_BH_AL
	MOV AX, 440Fh
	INT 21h
	JC Fantm1
	DW _CMP_AL_BH
	JE Fantm1
	DW _XCHG_BL_BH
	MOV AX, 440Fh
	INT 21h
	JC Fantm1
	DW _XCHG_BL_BH
	DW _MOV_AL_BL
	CBW
	ADD AL, 'A'-1
	MOV [MD.TmpErr+1], AX
	MOV CL, [MD.HlpPage]
	MOV BP, Fant_B
	CALL Dialog
	MOV [MD.HlpPage], CL
	STC
	JNE Fantm2
	MOV AX, 440Fh
	INT 21h
Fantm1:	CLC
Fantm2:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;Fantom ENDP

;GLOBAL ChgDisk
ChgDisk:  ; PROC NEAR
	PUSH BX
	PUSH AX
	DW _MOV_BX_DX
	MOV AX, [ES:BX]
	CMP AH, ':'
	JE ChDsk1
	MOV AL, [ES:MD.DosPth]
ChDsk1:	CALL UpCase
	SUB AL, 'A'-1
	CALL Fantom
	POP AX
	POP BX
	RET
;ChgDisk ENDP

;ChTree	PROC	NEAR
;GLOBAL ChTree
ChTree:
	PUSH DS
	PUSH BP
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	CALL HidCur
	DW _MOV_BL_AL
	MOV BH, 2
	MOV DL, 50
	MOV DH, [ES:MD.Lines]
	SUB DH, 3
	MOV SI, MD.WinBuf
	CALL SavWin
	MOV BP, ChTr_P
	MOV AH, [CS:BP]
	CALL Color
	CALL MinBox
	PUSH SI
	MOV DS, [ES:MD.WCB1seg]
	CMP BYTE [WCBdef.WinTyp], 1
	JNE ChTr01
	MOV BYTE [WCBdef.ChgFlg], 1
ChTr01:	MOV DS, [ES:MD.WCB2seg]
	CMP BYTE [WCBdef.WinTyp], 1
	JNE ChTr02
	MOV BYTE [WCBdef.ChgFlg], 1
ChTr02:	PUSH ES
	POP DS
	MOV SI, MD.CrnPath
	MOV DI, MD.MenuBuf+250
	MOV CX, LenPath
	REP MOVSB
ChTr59:	PUSH BX
	PUSH CS
	POP DS
	ADD BX, 118h
	MOV SI, ChTr0_S
	CALL CntLine
	POP BX
	PUSH DX
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 6
	CALL BasAdr
	MOV CX, 3
	SUB DL, 10
	MOV DH, 0
	MOV BX, (('Ç'*256)&0FF00H)+('¶'&0FFH)  ; !!
	MOV AL, 'Ä'
	CALL BoxLine
	MOV SI, ChTr1_S
	ADD DI, 2*5
	MOV AL, 38
	PUSH DI
	CALL NgLine
	POP DI
	ADD DI, 2*80
	CALL NgLine
	POP BX
	POP DX
	CALL Window
	PUSH ES
	POP DS
	MOV BYTE [MD.CrnPath], 0
	CALL ReadTre
	DW _MOV_AL_DH
	SUB AL, 8
	CALL TrCr20
	MOV SI, [MD.TreeBuf+DIRTREE.TreeLen]
	DW _MOV_AL_DH
	SUB AL, 8
	CBW
	DW _SUB_SI_AX
	JAE ChTr03
	DW _XOR_SI_SI
ChTr03:	PUSH DX
	CALL NumAd1
	POP DX
	CMP SI, [MD.TreFrst]
	JAE ChTr04
	MOV [MD.TreFrst], SI
ChTr04:	MOV WORD [MD.MousTim+2], 0FFFFh
	MOV BYTE [MD.MousEnt], 0
	MOV BP, [MD.TreAdr]
	MOV DI, [MD.TreFrst]
	ADD BP, 2*16
	ADD DI, 2*16
	XCHG BP, [MD.TreAdr]
	XCHG DI, [MD.TreFrst]
	JMP ChTr11

ChTr10:	PUSH DX  ; Convert adresses
	DW _MOV_SI_BP
	CALL NumAd1
	DW _MOV_BP_SI
	DW _MOV_SI_DI
	CALL NumAd1
	DW _MOV_DI_SI
	POP DX
ChTr11:	CMP BP, [MD.TreAdr]  ; Clear search line
	JE ChTr12
	DW _XOR_AX_AX
	MOV [MD.MenuBuf+228], AX
	MOV [MD.MenuBuf+230], AL
ChTr12:	DW _CMP_BP_DI  ; Test parameters
	JAE ChTr13
	DW _MOV_DI_BP
ChTr13:	DW _MOV_AL_DH
	SUB AL, 9
	MOV AH, 16
	MUL AH
	DW _MOV_SI_BP
	DW _SUB_SI_DI
	DW _CMP_SI_AX
	JBE ChTr14
	DW _MOV_DI_BP
	DW _SUB_DI_AX
ChTr14:	DW _MOV_CX_DI
	XCHG BP, [MD.TreAdr]
	XCHG DI, [MD.TreFrst]
	DW _SUB_CX_DI
	JNE ChTr15
	CMP BP, [MD.TreAdr]
	JNE ChTr15
	JMP ChTr20
ChTr15:	PUSH BP  ; Put lines
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	MOV BP, ChTr_P
	CALL BasAdr
	ADD DI, 2*165
	DW _MOV_CL_DH
	SUB CL, 8
	MOV CH, 0
	MOV AH, [CS:BP]
	CALL Color
	MOV AL, ' '
ChTr16:	PUSH DI
	PUSH CX
	MOV CX, 38
	REP STOSW
	POP CX
	POP DI
	ADD DI, 2*80
	LOOP ChTr16
	ADD BX, 104h
	SUB DX, 40Ah
	MOV DS, [ES:MD.WCBcrn]
	CALL PutTree
	PUSH ES
	POP DS
	POP BX
	POP CX
	POP DX
	POP DI
	POP BP
	JCXZ ChTr18  ; Output window
	PUSH DX
	PUSH BX
	ADD BX, 205h
	SUB DX, 80Ch
	DW _MOV_AL_DH
	DEC AX
	MOV AH, 6
	CMP CX, 16
	JE ChTr17
	MOV AX, 700h
	CMP CX, -16
	JE ChTr17
	CALL Window
	POP BX
	POP DX
	JMP ChTr19
ChTr17:	NEG CX
	DW _ADD_BP_CX
	DW _MOV_CX_BX
	DW _ADD_DX_CX
	SUB DX, 101h
	PUSH AX
	MOV AH, [CS:ChTr_P]
	CALL Color
	DW _MOV_BH_AH
	POP AX
	PUSH AX
	MOV AL, 1
	CALL Int10m
	POP AX
	POP BX
	POP DX
	CBW
	MOV CL, 4
	SHL AX, CL
	CALL ChTr50
ChTr18:	DW _MOV_AX_BP
	DW _SUB_AX_DI
	CALL ChTr50
	MOV AX, [MD.TreAdr]
	SUB AX, [MD.TreFrst]
	CALL ChTr50
ChTr19:	PUSH DX  ; Output mini status
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 5
	ADD BL, 5
	MOV DX, 126h
	CALL Window
	POP BX
	POP DX
ChTr20:	PUSH DX  ; Output search line
	PUSH BX
	DW _ADD_BH_DH
	SUB BH, 4
	ADD BL, 19
	CMP BYTE [MD.WinMous], 0
	JNZ ChTr21
	MOV CX, 12
	MOV SI, MD.MenuBuf+230
	MOV AH, [CS:ChTr_P+1]
	CALL InSt10
ChTr21:	DW _MOV_AX_BX
	ADD AX, [MD.MenuBuf+228]
	CALL Cursor
	MOV AX, [MD.TreAdr]  ; Input
	CALL TreNum
	DW _MOV_BP_AX
	MOV AX, [MD.TreFrst]
	CALL TreNum
	DW _MOV_DI_AX
	POP BX
	POP DX
	CALL GetMous
	MOV CX, [MD.TreeBuf+DIRTREE.TreeLen]
	JNZ ChTr22
	MOV BYTE [MD.MousEnt], 0
	MOV BYTE [MD.WinMous], 0
	MOV AL, 14
	CALL Input
	CMP AH, 0FCh
	JE ChTr22
	MOV SI, ChTr_T
	CALL Case

	PUSH DX  ; Letters
	PUSH BX
	DW _MOV_BP_CX
	MOV CL, 4
	SHL BP, CL
	MOV BX, MD.TreeBuf+DIRTREE_TreList
	DW _ADD_BP_BX
	MOV DX, 16
	MOV SI, [MD.TreAdr]
	CALL Search
	POP BX
	POP DX
	JZ ChTr20
	DW _MOV_BP_SI
	MOV DI, [MD.TreFrst]
	JMP ChTr12
ChTr22:	JMP ChTr60

ChTr30:	DW _XOR_BP_BP  ; Home
	JMP ChTr10

ChTr32:	MOV BP, [MD.TreeBuf+DIRTREE.TreeLen]  ; End

ChTr35:	DW _OR_BP_BP  ; Up
	JE ChTr38
	DEC BP
	JMP ChTr10

ChTr37:	INC BP  ; Down
	CMP BP, [MD.TreeBuf+DIRTREE.TreeLen]
	JAE ChTr38
	JMP ChTr10
ChTr38:	JMP ChTr20

ChTr40:	DW _MOV_AL_DH  ; PgUp
	SUB AL, 8
	CBW
	DW _MOV_SI_BP
	CALL PgUp
	DW _MOV_BP_SI
	JMP ChTr10

ChTr42:	DW _MOV_AL_DH  ; PgDn
	SUB AL, 8
	CBW
	DW _MOV_SI_BP
	MOV BP, [MD.TreeBuf+DIRTREE.TreeLen]
	CALL PgDn
	DW _MOV_BP_SI
	JMP ChTr10

ChTr55:	PUSH DX  ; Rescan
	PUSH BX
	ADD BX, 205h
	SUB DX, 80Ch
	DW _MOV_CL_DH
	MOV CH, 0
	MOV BP, ChTr_P
	MOV AH, [CS:BP]
	CALL Color
	MOV AL, ' '
ChTr56:	PUSH CX
	CALL BasAdr
	DW _MOV_CL_DL
	REP STOSW
	INC BH
	POP CX
	LOOP ChTr56
	PUSH AX
	CALL DelTr0
	POP AX
	POP BX
	POP DX
	JMP ChTr59

ChTr60:	DW _XOR_SI_SI  ; Mouse
ChTr61:	CALL GetMous
	JZ ChTr65
	DW _MOV_BP_CX
	CALL ClrKbd
	MOV AH, 'x'
	TEST AL, 3
	JZ ChTr62
	MOV AH, 0
ChTr62:	DW _MOV_CX_SI
	DW _MOV_SI_AX
	DW _CMP_AH_CH
	JE ChTr63
	DW _MOV_AL_AH
	CALL TypMous
ChTr63:	TEST SI, 3
	JZ ChTr61
	PUSH BX
	PUSH DX
	ADD BX, 204h
	SUB DX, 80Ah
	DW _MOV_CX_BP
	CALL InWind
	POP DX
	POP BX
	JNC ChTr67
	CMP BYTE [MD.WinMous], 0
	JZ ChTr61
	DW _MOV_BP_DI
	DW _MOV_AL_BH
	ADD AL, 2
	DW _CMP_CH_AL
	JAE ChTr64
	JMP ChTr35
ChTr64:	DW _MOV_AL_BH
	DW _ADD_AL_DH
	SUB AL, 6
	DW _CMP_CH_AL
	JB ChTr61
	DW _MOV_AL_DH
	SUB AL, 9
	CBW
	DW _ADD_BP_AX
	JMP ChTr37
ChTr65:	MOV AL, 0
	CALL TypMous
	DW _MOV_AX_SI
	CMP AL, 2
	JE ChTr66
	CMP AL, 1
	JB ChTr66
	JNE ChTr46
	CMP BYTE [MD.WinMous], 0
	JNZ ChTr66
	PUSH DX
	PUSH CX
	DW _MOV_CX_BP
	SUB DX, 102h
	CALL InWind
	POP CX
	POP DX
	JC ChTr46
ChTr66:	JMP ChTr20
ChTr67:	MOV BYTE [MD.WinMous], 1
	DW _SUB_CX_BX
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
	JNC ChTr69
	DW _ADD_AX_DI
	MOV BP, [MD.TreeBuf+DIRTREE.TreeLen]
	DEC BP
	DW _CMP_BP_AX
	JBE ChTr68
	DW _MOV_BP_AX
ChTr68:	JMP ChTr10
ChTr69:	JE ChTr66
	MOV AL, 0
	CALL TypMous
	MOV AX, 1C0Dh

ChTr45:	MOV SI, MD.CrnPath  ; Enter
	MOV DI, MD.TmpBuf
	MOV CX, LenPath
	REP MOVSB
	MOV BYTE [DI], 0

ChTr46:	CALL HidCur  ; Esc
	MOV SI, MD.MenuBuf+250
	MOV DI, MD.CrnPath
	MOV CX, LenPath
	REP MOVSB
	POP SI
	CALL ResWin
	CALL Window
	CMP AL, 0Dh
	JE ChTr47
	STC
ChTr47:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP BP
	POP DS
	RET
;ChTree	ENDP

;GLOBAL ChTr50
ChTr50:  ; PROC NEAR
	PUSH DX
	PUSH BX
	MOV CL, 4
	SHR AX, CL
	DW _ADD_BH_AL
	ADD BX, 205h
	MOV DX, 126h
	CALL Window
	POP BX
	POP DX
	RET
;ChTr50 ENDP

;GLOBAL DirSize
DirSize:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	MOV WORD [ES:MD.FncAddr], DiSi10
	MOV SI, WCBdef.WinPath
	MOV DI, MD.TmpBuf
	MOV CX, LenPath
	CALL MvzLine
	MOV SI, WCBdef.DskBuf
	MOV AX, '\'
	CMP AL, [ES:DI-1]
	JE DiSi01
	STOSW
DiSi01:	CMP SI, [WCBdef.EndFul]
	JAE DiSi03
	TEST BYTE [SI+13], 10h
	JZ DiSi02
	CMP BYTE [SI], '.'
	JE DiSi02
	MOV WORD [ES:MD.TmpBuf+90], 0
	MOV WORD [ES:MD.TmpBuf+92], 0
	PUSH SI
	PUSH DS
	PUSH ES
	POP DS
	MOV SI, MD.TmpBuf
	CALL CutPath
	DW _MOV_DI_SI
	POP DS
	POP SI
	PUSH SI
	MOV CX, 13
	REP MOVSB
	POP SI
	MOV AL, 10h
	CALL [ES:MD.FncAddr]
	CMP AH, 0
	JNZ DiSi04
	MOV AX, [ES:MD.TmpBuf+90]
	MOV [SI+18], AX
	MOV AX, [ES:MD.TmpBuf+92]
	MOV [SI+20], AX
DiSi02:	ADD SI, FILENT_size
	JMP DiSi01
DiSi03:	MOV BYTE [WCBdef.SizDir], 1
DiSi04:	POP AX
	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;DirSize ENDP

;GLOBAL DiSi10
DiSi10:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH BX
	TEST AL, 10h
	JZ DiSi11
	CALL DirFunc
	JMP DiSi13
DiSi11:	MOV AX, [ES:MD.DTA+DTAs.FilSize+0]
	MOV BX, [ES:MD.DTA+DTAs.FilSize+2]
	ADD AX, [ES:MD.TmpBuf+90]
	ADC BX, [ES:MD.TmpBuf+92]
	JNC DiSi12
	MOV AX, 0FFFFh
	MOV BX, 0FFFFh
DiSi12:	MOV [ES:MD.TmpBuf+90], AX
	MOV [ES:MD.TmpBuf+92], BX
	DW _XOR_AX_AX
DiSi13:	POP BX
	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;DiSi10 ENDP

;GLOBAL GetVol
GetVol:  ; PROC NEAR
	PUSH DS
	PUSH SI
	PUSH DI
	PUSH DX
	PUSH CX
	PUSH ES
	POP DS
	MOV BYTE [SI], 0
	PUSH SI
	MOV SI, MD.TmpErr
	MOV WORD [SI], 'A'
	MOV DI, MD.TmpErr+100
	MOV AH, 60h
	CALL Intr21
	POP SI
	JC GetVl6
	MOV AX, '\\'
	SCASW
	JNE GetVl2
	MOV CX, 100
	REPNE SCASB
	DW _XCHG_SI_DI
	MOV CX, 11
GetVl1:	LODSB
	CMP AL, '\'
	JE GetVl5
	STOSB
	LOOP GetVl1
	CLC
	JMP GetVl5
GetVl2:	DW _MOV_DI_SI
	CALL SetDTA
	PUSH CS
	POP DS
	MOV DX, Mask_S
	MOV CX, 8
	MOV AH, 4Eh
	CALL Intr21
	JC GetVl5
	PUSH ES
	POP DS
	MOV SI, MD.DTA+DTAs.FilName
	CALL Convert
	DW _MOV_SI_DI
	MOV CX, 11
GetVl3:	LODSB
	CMP AL, ' '
	JE GetVl4
	DW _MOV_DI_SI
GetVl4:	LOOP GetVl3
	STC
GetVl5:	MOV BYTE [ES:DI], 0
GetVl6:	POP CX
	POP DX
	POP DI
	POP SI
	POP DS
	RET
;GetVol ENDP

;GLOBAL OpenFil
OpenFil:  ; PROC NEAR
	PUSH BX
	MOV AH, 3Dh
	DW _MOV_BX_AX
	CALL Intr21
	JNC OpnFl1
	CMP AX, STRICT WORD 20h
	STC
	JNE OpnFl1
	DW _MOV_AX_BX
	AND AL, 0Fh
	CALL Intr21
OpnFl1:	POP BX
	RET
;OpenFil ENDP

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
	DB 'úù'  ; StarTab
DefWCB	DB 0  ; WinTyp
	DB 0  ; BrfFul
	DB 1  ; Visible
	DB 1  ; Hidden
	DB 0  ; MasTyp
	DB 8  ; SortTyp
	DB 0  ; Ctrl_L
	DB 0  ; DskMas
FncTab	DW 4800h, F00_00  ; Up
	DW 5000h, F01_00  ; Down
	DW 4B00h, F02_00  ; Left
	DW 4D00h, F03_00  ; Right
	DW 4900h, F04_00  ; PgUp
	DW 5100h, F05_00  ; PgDn
	DW 4700h, F06_00  ; Home
	DW 4F00h, F07_00  ; End
	DW 5200h, F08_00  ; Ins     - select / unselect
	DW 4E2Bh, F09_00  ; Grey +  - select group
	DW 4A2Dh, F10_00  ; Grey -  - unselect group
	DW 372Ah, F76_00  ; Grey *  - invert group
	DW 0F09h, F20_00  ; Tab     - change active panel
	DW 1C0Dh, F21_00  ; Enter   - run / change directory
	DW 000Ah, F27_00  ; ^Enter  - history command
	DW 011Bh, F74_00  ; Esc     - clear command line / on/off
	DW 000Dh, F78_00  ; ^M      - restore marks
	DW 000Fh, F11_00  ; ^O      - on/off panels
	DW 0010h, F12_00  ; ^P      - on/off unactive panel
	DW 5E00h, F13_00  ; ^F1     - on/off left panel
	DW 5F00h, F14_00  ; ^F2     - on/off right panel
	DW 0015h, F15_00  ; ^U      - swap panels
	DW 0002h, F16_00  ; ^B      - on/off key bar
	DW 0012h, F17_00  ; ^R      - re-read
	DW 0006h, M16_00  ; ^F      - filter
	DW 2308h, M16_10  ; ^H      - hidden files
	DW 0001h, M30_00  ; ^A      - attributes
	DW 0003h, M49_00  ; ^C      - compare directories
	DW 000Ch, F18_00  ; ^L      - info
	DW 001Ah, F79_00  ; ^Z      - tree
	DW 8400h, F22_00  ; ^PgUp   - CD ..
	DW 7600h, F23_00  ; ^PgDn   - change directory
	DW 001Ch, F24_00  ; ^\      - CD \ .
	DW 0005h, F25_00  ; ^E      - previous history command
	DW 0018h, F26_00  ; ^X      - next history command
	DW 0009h, F80_00  ; ^I	  - insert files
	DW 001Bh, F81_00  ; ^[	  - insert left path
	DW 001Dh, F82_00  ; ^]	  - insert right path
	DW 4400h, F30_00  ; F10     - quit
	DW 3C00h, F32_00  ; F2      - user menu
	DW 3D00h, F33_00  ; F3      - view
	DW 3E00h, F34_00  ; F4      - edit
	DW 3F00h, F35_00  ; F5      - copy
	DW 4000h, F36_00  ; F6      - rename / move
	DW 4100h, F37_00  ; F7      - make directory
	DW 4200h, F38_00  ; F8      - delete
	DW 4300h, F39_00  ; F9      - pull down menu
	DW 5D00h, F40_00  ; Shift F10 - pull down menu
	DW 5500h, F42_00  ; Shift F2  - main menu...
	DW 5600h, F43_00  ; Shift F3  - view...
	DW 5700h, F44_00  ; Shift F4  - edit...
	DW 5800h, F45_00  ; Shift F5  - copy...
	DW 5900h, F46_00  ; Shift F6  - rename/move...
	DW 5A00h, F47_00  ; Shift F7  - make directory...
	DW 5B00h, F48_00  ; Shift F8  - delete...
	DW 5C00h, M75_00  ; Shift F9  - save setup
	DW 6100h, F54_00  ; ^F4     - change label
	DW 6200h, F55_00  ; ^F5     - copy file
	DW 6300h, F56_00  ; ^F6     - rename/move file
	DW 6500h, F58_00  ; ^F8     - delete file
	DW 6800h, F61_00  ; Alt F1  - change left drive
	DW 6900h, F62_00  ; Alt F2  - change right drive
	DW 6A00h, F63_00  ; Alt F3  - internal viewer
	DW 6B00h, F64_00  ; Alt F4  - internal editer
	DW 6C00h, F65_00  ; Alt F5  - memory info
	DW 6D00h, M42_00  ; Alt F6  - directory sizes
	DW 6E00h, F67_00  ; Alt F7  - file find
	DW 6F00h, F68_00  ; Alt F8  - history
	DW 7000h, F69_00  ; Alt F9  - EGA lines
	DW 7100h, M41_00  ; Alt F10 - Tree
	DW 0FD00h, F39_00  ; Alt     - pull down menu
	DW 0FE00h, F75_00  ;         - auto CD / quick view
	DW 0

Sel_P	DB Box_C, BoxCu_C, 0, 0
	DB 3, 0
	DW MD.WinBuf
	DW IncSp_S
	DW Sel1_S
	DW Empty_S
Sel_B	DW Sel_P, 528h, 0  ; _BOXHD
	    DB 1, 2, 25, 0
	DB 1 , 0, 0, 0, 0  ; _BOXMN
	    DW 305h, MD.SelMas, 20Ch
	DB 0
ErSel_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.WinBuf
	DW MD.SelMas
	DB 4, 50
	DW IncSp_S
	DW ErSel_S
	DW Kov_S
	DW Ok_S
ErSel_B	DW ErSel_P, 528h, 0  ; _BOXHD
	    DB 1, 0FFh, 0, 0
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 426h, MD.TmpBuf, OkMn_D
	DB 0

YesNo_D	DB 5, 0
	DB 4, 6
	DB 0
Quit_P	DB Box_C, BoxCu_C, BoxCu_C, 0
	DB 3, 0
	DW MD.WinBuf
	DW Quit1_S
	DW Quit2_S
	DW YesNo_S
Quit_B	DW Quit_P, 528h, 0  ; _BOXHD
	    DB 1, 2, 26, 0
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 323h, MD.TmpBuf, YesNo_D
	DB 0

UsrEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.TmpBuf
	DB 7, 64
	DW User_S
	DW User1_S
	DW Var_S
	DW Ok_S
UsrEr_B	DW UsrEr_P, 528h, 0  ; _BOXHD
	    DB 1, 0FFh, 0, 2
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 426h, MD.TmpBuf, OkMn_D
	DB 0
User_T	DW 4800h, F32_36
	DW 5000h, F32_37
	DW 4700h, F32_38
	DW 4F00h, F32_39
	DW 4900h, F32_38
	DW 5100h, F32_39
	DW 000Dh, F32_50
	DW 001Bh, F32_55
	DW 0

Drive_T	DW 0008h, F62_31
	DW 4B00h, F62_31
	DW 0020h, F62_34
	DW 4D00h, F62_34
	DW 4700h, F62_35
	DW 4F00h, F62_32
	DW 000Dh, F62_36
	DW 001Bh, F62_37
	DW 4400h, F62_37
	DW 0

Hist_T	DW 4800h, F68_13
	DW 5000h, F68_15
	DW 4700h, F68_16
	DW 4900h, F68_16
	DW 4F00h, F68_14
	DW 5100h, F68_14
	DW 1C0Ah, F68_20
	DW 1C0Dh, F68_20
	DW 001Bh, F68_20
	DW 4400h, F68_20
	DW 0

AltSr_P	DB Box_C, BoxCu_C
AltSr_T	DB 78h, 79h, 7Ah, 7Bh, 7Ch, 7Dh, 7Eh, 7Fh, 80h, 81h, 82h, 83h
	DB 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h
	DB 1Eh, 1Fh, 20h, 21h, 22h, 23h, 24h, 25h, 26h
	DB 2Ch, 2Dh, 2Eh, 2Fh, 30h, 31h, 32h
Ascii_T	DB '1234567890-='
	DB 'qwertyuiop'
	DB 'asdfghjkl'
	DB 'zxcvbnm'
Srch_T	DW 0013h, F77_10  ; ^S
	DW 0004h, F77_10  ; ^D
	DW 0001h, F77_10  ; ^A
	DW 0006h, F77_10  ; ^F
	DW 0008h, F77_10  ; BackSpace
	DW 0007h, F77_10  ; ^G
	DW 5300h, F77_10  ; Del
	DW 000Bh, F77_10  ; ^K
	DW 0019h, F77_10  ; ^Y
	DW 0017h, F77_10  ; ^W
	DW 007Fh, F77_10  ; ^BackSpace
	DW 0014h, F77_10  ; ^T
	DW 0011h, F77_10  ; ^Q
	DW 000Ah, F77_10  ; ^Enter
	DW 001Bh, F77_15  ; Esc
	DW 0

; --- include vcmenu.inc

;-------------------------------------------------------
;		Version :	10.01.2000
;-------------------------------------------------------

MnuTab	DW 102h, 121Bh, MenuLn1, MnuHlp1
	DW 10Ah, 141Eh, MenuLn2, MnuHlp2
	DW 113h, 1023h, MenuLn3, MnuHlp3
	DW 11Fh, 1322h, MenuLn4, MnuHlp4
	DW 12Ah, 121Bh, MenuLn1, MnuHlp1
MnuHlp1	DB 7, 8, 8, 9,10,11, 0,12,12,12,12,12, 0,13,14,15
MnuHlp2	DB 16, 0,17,18,19,20,21,22,23, 0,24, 0,25,25,25,25, 0,26
MnuHlp3	DB 27,28,29,30,31,32,33,34, 0,35,36,37, 0,38
MnuHlp4	DB 39,40,41,42,43,44, 0,45,46,47,48,49,50,51,52, 0,53
MnuKey	DB 'LFCOR'

KeyTab	DW 5E00h,0501h, 1312h,0D01h, 2106h,0E01h, 6800h,0F01h
	DW 3B00h,0102h, 3C00h,0202h, 3D00h,0302h, 3E00h,0402h
	DW 3F00h,0502h, 4000h,0602h, 4100h,0702h, 4200h,0802h
	DW 1E01h,0A02h, 4E2Bh,0C02h, 4A2Dh,0D02h, 372Ah,0E02h
	DW 320Dh,0F02h, 4400h,1102h, 7100h,0103h, 6100h,0203h
	DW 6C00h,0303h, 6D00h,0403h, 6E00h,0503h, 6F00h,0603h
	DW 7000h,0703h, 1615h,0903h, 180Fh,0A03h, 2E03h,0B03h
	DW 3002h,0904h, 5C00h,1004h, 5F00h,0505h, 1312h,0D05h
	DW 2106h,0E05h, 6900h,0F05h
KeyTabE:  ; JWasm fails here with `Use of register assumed to ERROR' for `:' instead of `LABEL BYTE'.

Menu_T	DW Menu1_T
	DW Menu2_T
	DW Menu3_T
	DW Menu4_T
	DW MenuS_T
	DW MenuC_T
Menu1_T	DW M01_00  ; Brief
	DW M01_00  ; Full
	DW M03_00  ; Info
	DW M03_00  ; Tree
	DW M06_00  ; On/Off
	DW 0
	DW M08_00  ; Name
	DW M08_00  ; Extension
	DW M08_00  ; Time
	DW M08_00  ; Size
	DW M08_00  ; Unsorted
	DW 0
	DW F17_01  ; Re-read
	DW M16_01  ; Filter...
	DW F62_01  ; Drive...
Menu2_T	DW M21_00  ; Help
	DW F32_00  ; Menu
	DW F33_00  ; View
	DW F34_00  ; Edit
	DW F35_00  ; Copy
	DW F36_00  ; Rename or move
	DW F37_00  ; Make directory
	DW F38_00  ; Delete
	DW 0
	DW M30_00  ; File attributes
	DW 0
	DW F09_00  ; Gray +
	DW F10_00  ; Gray -
	DW F76_01  ; Gray *
	DW F78_00  ; ^M
	DW 0
	DW F30_00  ; Quit
Menu3_T	DW M41_00  ; Tree
	DW F54_00  ; Volume label
	DW F65_00  ; Memory info
	DW M42_00  ; Directory sizes
	DW F67_00  ; Find file
	DW F68_00  ; History
	DW F69_00  ; EGA lines
	DW 0
	DW F15_00  ; Swap panels
	DW F11_00  ; Panels on/off
	DW M49_00  ; Compare directories
	DW 0
	DW M53_00  ; Menu file edit
Menu4_T	DW M60_00  ; Configuration...
	DW M61_00  ; Advanced options...
	DW M62_00  ; Extension file edit...
	DW M63_00  ; Viewer...
	DW M64_00  ; Editor...
	DW 0
	DW M66_00  ; Auto menus
	DW M67_00  ; Path prompt
	DW F16_00  ; Key bar
	DW M69_00  ; Full screen
	DW M70_00  ; Auto directory sizes
	DW M71_00  ; Mini status
	DW M72_00  ; Clock
	DW M73_00  ; Memory location
	DW 0
	DW M75_00  ; Save setup
MenuS_T	DW M21_00  ; Help
	DW F42_00  ; Menu
	DW F43_00  ; View...
	DW F44_00  ; Edit...
	DW F45_00  ; Copy...
	DW F46_00  ; Rename or move...
	DW F47_00  ; Make directory...
	DW F48_00  ; Delete...
MenuC_T	DW M21_00  ; Help
	DW F32_00  ; Menu
	DW F33_00  ; View...
	DW F34_00  ; Edit...
	DW F55_00  ; Copy...
	DW F56_00  ; Rename or move...
	DW F37_00  ; Make directory...
	DW F58_00  ; Delete...

MenuTab	DW 4B00h, F39_25  ; Left
	DW 4D00h, F39_26  ; Right
	DW 4700h, F39_30  ; Home
	DW 4900h, F39_30  ; PgUp
	DW 4F00h, F39_32  ; End
	DW 5100h, F39_32  ; PgDn
	DW 4800h, F39_33  ; Up
	DW 5000h, F39_37  ; Down
	DW 1C0Dh, F39_43  ; Enter
	DW 000Ah, F39_43  ; ^Enter
	DW 001Bh, F39_46  ; Esc
	DW 0FD00h,F39_46  ; Alt
	DW 0

Filt_P	DB Box_C, BoxCu_C, Box_C, 0
	DB 7, 0
	DW MD.WinBuf
	DW Filt0_S
	DW Filt1_S
	DW Filt2_S
	DW Filt3_S
	DW Filt4_S
	DW 0
	DW OkCn_S
Filt_B	DW Filt_P, 514h, 0  ; _BOXHD
	    DB 1, 1, 14, 0
	DB 1, 3, 1, 0, 0  ; _BOXMN  ; Custom
	    DW 30Eh, WCBdef.DskMas , 20Ch
	DB 3, 0, 2, 1, 1  ; _BOXMN  ; Hidden files
	    DW 407h, MD.TmpBuf , WCBdef.Hidden
	DB 3, 1, 3, 2, 2  ; _BOXMN  ; Executable files
	    DW 507h, MD.TmpBuf+1, WCBdef.MasTyp
	DB 4, 2, 0, 3, 3  ; _BOXMN  ; Ok / Cancel
	    DW 70Ah, MD.TmpBuf+2, OkCn_D
	DB 0
OkCn_D	DB 6, 0
	DB 10, 9
	DB 0

DiSiz_P	DB Box_C, 0, 0, 0
	DB 3, 1
	DW MD.WinBuf
	DW MD.TmpBuf
	DB 0, 25
	DW Tree_S
	DW DiSi1_S
	DW DiSi2_S

CmpDi_P	DB Box_C, BoxCu_C, BoxCu_C, 0
	DB 4, 0
	DW MD.WinBuf
	DW Cmp0_S
	DW Cmp1_S
	DW Cmp2_S
	DW Ok_S
CmpDi_B	DW CmpDi_P, 728h, 0  ; _BOXHD
	    DB 1, 3, 37, 0
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 426h, MD.TmpBuf, OkMn_D
	DB 0

Conf_P	DB Conf_C, CnfRe_C, CnfBo_C, 0
	DB 18, 0
	DW MD.WinBuf
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
	DW Cnf15_S
	DW 0
	DW OkCn_S
Conf_B	DW Conf_P, 228h, 0  ; _BOXHD
	    DB 1, 4, 40, 0
	DB 2, 9, 81h, 0, 2  ; _BOXMN  ; Screen colors
	    DW 30Ah, MD.TmpBuf , 3
	DB 2, 0C0h, 9, 1, 4  ; _BOXMN  ; Screen blank delay
	    DW 80Ah, MD.TmpBuf+2 , 6
	DB 3, 9, 3, 80h, 2  ; _BOXMN  ; Ins moves down
	    DW 323h, MD.TmpBuf+4 , MD.InsDwn
	DB 3, 2, 4, 80h, 3  ; _BOXMN  ; Auto change dir
	    DW 423h, MD.TmpBuf+5 , MD.AutoCD
	DB 3, 3, 5, 81h, 4  ; _BOXMN  ; Menu bar visible
	    DW 723h, MD.TmpBuf+6 , MD.MenuVs
	DB 3, 4, 6, 81h, 5  ; _BOXMN  ; Auto save setup
	    DW 823h, MD.TmpBuf+7 , MD.AutoSav
	DB 3, 5, 7, 81h, 6  ; _BOXMN  ; Confirmation on quit
	    DW 923h, MD.TmpBuf+8 , MD.QuitAck
	DB 3, 6, 8, 81h, 7  ; _BOXMN  ; Zooming boxes
	    DW 0A23h, MD.TmpBuf+9 , MD.ZoomWin
	DB 3, 7, 9, 81h, 8  ; _BOXMN  ; Left-handed mouse
	    DW 0D23h, MD.TmpBuf+10, MD.LftMous
	DB 4, 8, 80h, 9, 9  ; _BOXMN  ; Ok / Cancel
	    DW 121Eh, MD.TmpBuf+11, OkCn_D
	DB 0
Delay_T	DB 40, 20, 5, 3, 1, 0

Sets_P	DB Conf_C, CnfRe_C, CnfBo_C, 0
	DB 15, 0
	DW MD.WinBuf
	DW Set00_S
	DW Set01_S
	DW Set02_S
	DW Set03_S
	DW Set04_S
	DW Set05_S
	DW Set10_S
	DW Set07_S
	DW Set08_S
	DW Set09_S
	DW Set10_S
	DW Set11_S
	DW Set12_S
	DW 0
	DW OkCn_S
Sets_B	DW Sets_P, 328h, 0  ; _BOXHD
	    DB 1, 4, 41, 0
	DB 3, 6, 1, 0, 0  ; _BOXMN  ; Alt selects menu
	    DW 30Ah, MD.TmpBuf+0, MD.AltBar
	DB 3, 0, 2, 1, 1  ; _BOXMN  ; Esc toggles panels
	    DW 40Ah, MD.TmpBuf+1, MD.EscBar
	DB 3, 1, 3, 2, 2  ; _BOXMN  ; Alternative viewer
	    DW 50Ah, MD.TmpBuf+2, MD.AltView
	DB 3, 2, 4, 3, 3  ; _BOXMN  ; Alternative editor
	    DW 60Ah, MD.TmpBuf+3, MD.AltEdit
	DB 3, 3, 5, 4, 4  ; _BOXMN  ; Quick execute cmds
	    DW 90Ah, MD.TmpBuf+4, MD.ExecTyp
	DB 3, 4, 6, 5, 5  ; _BOXMN  ; Clear buffer
	    DW 0A0Ah, MD.TmpBuf+5, MD.ClrBuf
	DB 4, 5, 0, 6, 6  ; _BOXMN  ; Ok / Cancel
	    DW 0F1Eh, MD.TmpBuf+6, OkCn_D
	DB 0

MnLoc_P	DB Box_C, BoxCu_C, BoxCu_C, 0
	DB 4, 1
	DW MD.WinBuf
	DW MD.TmpBuf
	DB 0, 50
	DW Var_S
	DW MnLc1_S
	DW MnLc2_S
	DW MnLc3_S
MnLoc_B	DW MnLoc_P, 528h, 0  ; _BOXHD
	    DB 1, 0FFh, 0, 0
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 41Ch, MD.TmpBuf, MnLoc_D
	DB 0
MnLoc_D	DB 6, 0
	DB 7, 7
	DB 8,15
	DB 0

SvSt_P	DB Box_C, BoxCu_C, BoxCu_C, 0
	DB 4, 0
	DW MD.WinBuf
	DW SvSt0_S
	DW SvSt1_S
	DW SvSt2_S
	DW SvSt3_S
SvSt_B	DW SvSt_P, 528h, 0  ; _BOXHD
	    DB 1, 4, 53, 0
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 420h, MD.TmpBuf, SvSt_D
	DB 0
SetEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 0
	DW MD.ErrBuf
	DW SvSt0_S
	DW StEr1_S
	DW StEr2_S
	DW Ok_S
SetEr_B	DW SetEr_P, 928h, 0  ; _BOXHD
	    DB 1, 0FFh, 0, 2
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 426h, MD.TmpErr, OkMn_D
	DB 0
SvSt_D	DB 6, 0
	DB 8, 7
	DB 0

MkDi1_P	DB Box_C, BoxCu_C, 0, 0
	DB 3, 0
	DW MD.WinBuf
	DW MkDir_S
	DW MkDi1_S
	DW Empty_S
MkDi1_B	DW MkDi1_P, 528h, 0
	DB 1, 2, 22, 0
	DB 1
	DB 0, 0, 0, 0
	DW 305h, MD.TmpBuf, 200h+LenStr
	DB 0
MkDi2_P	DB Box_C, BoxCu_C, 0, 0
	DB 3, 0
	DW MD.WinBuf
	DW MkDir_S
	DW Inc_S
	DW Empty_S
MkDi2_B	DW MkDi2_P, 528h, 0
	DB 1, 2, 22, 0
	DB 1
	DB 0, 0, 0, 0
	DW 305h, MD.TmpBuf, 20Ch
	DB 0
MkErr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.TmpBuf+130
	DB 6, 64
	DW Inc_S
	DW MkErr_S
	DW Var_S
	DW Ok_S
MkErr_B	DW MkErr_P, 928h, 0
	DB 1, 0FFh, 0, 6
	DB 4
	DB 0, 0, 0, 0
	DW 426h, MD.TmpBuf+200, OkMn_D
	DB 0

DelCa_D	DB 8, 0
	DB 8, 9
	DB 0
DelAl_D	DB 8, 0
	DB 5, 9
	DB 8,15
	DB 0
DelSk_D	DB 8, 0
	DB 6, 9
	DB 8,16
	DB 0
DelFl_P	DB Box_C, 0, 0, 0
	DB 3, 1
	DW MD.WinBuf
	DW MD.TmpBuf
	DB 7, 64
	DW Del_S
	DW DelFl_S
	DW Var_S
DelDr_P	DB Box_C, 0, 0, 0
	DB 3, 1
	DW MD.WinBuf
	DW MD.TmpBuf
	DB 6, 64
	DW Inc_S
	DW DelDr_S
	DW Var_S
DlMas_P	DB Box_C, BoxCu_C, 0, 0
	DB 3, 0
	DW MD.WinBuf
	DW Del_S
	DW DlMas_S
	DW Empty_S
DlMas_B	DW DlMas_P, 528h, 0
	DB 1, 2, 23, 0
	DB 1
	DB 0, 0, 0, 0
	DW 305h, MD.ViewFil, LenStr
	DB 0
DelSe_P	DB Box_C, BoxCu_C, BoxCu_C, 0
	DB 4, 1
	DW MD.WinBuf
	DW MD.TmpBuf
	DB 0, 64
	DW Del_S
	DW DelSl_S
	DW Var_S
	DW DelCa_S
DelSe_B	DW DelSe_P, 528h, F38_10
	DB 1, 2, 23, 1
	DB 4
	DB 0, 0, 0, 0
	DW 41Fh, MD.TmpBuf+200, DelCa_D
	DB 0
DelCo_P	DB Err_C, ErInv_C, ErInv_C, ErBr_C
	DB 5, 2
	DW MD.ErrBuf
	DW MD.TmpBuf
	DB 0, 64
	DW MD.TmpBuf+100
	DB 6, 64
	DW Del_S
	DW DlSel_S
	DW From_S
	DW Var2_S
	DW DelAl_S
DelCo_B	DW DelCo_P, 928h, 0
	DB 1, 0FFh, 0, 1
	DB 4
	DB 0, 0, 0, 0
	DW 51Ch, MD.TmpBuf+100, DelAl_D
	DB 0
DelFi_P	DB Box_C, BoxCu_C, BoxCu_C, 0
	DB 4, 1
	DW MD.WinBuf
	DW MD.TmpBuf
	DB 7, 64
	DW Del_S
	DW Del1_S
	DW Var_S
	DW DelCa_S
DelFi_B	DW DelFi_P, 528h, 0
	DB 1, 2, 23, 1
	DB 4
	DB 0, 0, 0, 0
	DW 41Fh, MD.TmpBuf+100, DelCa_D
	DB 0
DelDi_P	DB Box_C, BoxCu_C, BoxCu_C, 0
	DB 4, 1
	DW MD.WinBuf
	DW MD.TmpBuf
	DB 6, 62
	DW Del_S
	DW Del1_S
	DW Kov_S
	DW DelCa_S
DelDi_B	DW DelDi_P, 528h, 0
	DB 1, 2, 23, 1
	DB 4
	DB 0, 0, 0, 0
	DW 41Fh, MD.TmpBuf+100, DelCa_D
	DB 0
RdOnl_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 5, 1
	DW MD.ErrBuf
	DW MD.TmpBuf
	DB 7, 64
	DW Inc_S
	DW RdOn_S
	DW Var_S
	DW StDel_S
	DW DelSk_S
RdOnl_B	DW RdOnl_P, 928h, 0
	DB 1, 0FFh, 0, 5
	DB 4
	DB 0, 0, 0, 0
	DW 51Ch, MD.TmpBuf+230, DelSk_D
	DB 0
NoEmp_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 5, 1
	DW MD.ErrBuf
	DW MD.TmpBuf
	DB 6, 64
	DW Del_S
	DW NoEmp_S
	DW Var_S
	DW StDel_S
	DW DelAl_S
NoEmp_B	DW NoEmp_P, 928h, 0
	DB 1, 0FFh, 0, 1
	DB 4
	DB 0, 0, 0, 0
	DW 51Ch, MD.TmpBuf+100, DelAl_D
	DB 0
DlWrn_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 5, 1
	DW MD.ErrBuf
	DW MD.TmpBuf+100
	DB 4, 64
	DW Del_S
	DW DlWr1_S
	DW DlWr2_S
	DW DlWr3_S
	DW DelCa_S
DlWrn_B	DW DlWrn_P, 528h, 0
	DB 1, 0FFh, 0, 1
	DB 4
	DB 0, 0, 0, 0
	DW 51Fh, MD.TmpBuf+100, DelCa_D
	DB 0
DelEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.TmpBuf+130
	DB 7, 64
	DW Inc_S
	DW CnDl_S
	DW Var_S
	DW OkCan_S
DelEr_B	DW DelEr_P, 928h, 0
	DB 1, 0FFh, 0, 6
	DB 4
	DB 0, 0, 0, 0
	DW 422h, MD.TmpBuf+230, OkCan_D
	DB 0
CntDi_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.TmpBuf
	DB 6, 64
	DW Inc_S
	DW CnSb_S
	DW Var_S
	DW OkCan_S
CntDi_B	DW CntDi_P, 928h, 0
	DB 1, 0FFh, 0, 2
	DB 4
	DB 0, 0, 0, 0
	DW 422h, MD.TmpBuf+100, OkCan_D
	DB 0

StAt1_P	DB Box_C, BoxCu_C, Box_C, BoxBr_C
	DB 9, 1
	DW MD.WinBuf
	DW MD.TmpBuf+100
	DB 7, 62
	DW Attr_S
	DW Attr1_S
	DW Kov_S
	DW Attr3_S + 5
	DW Attr4_S + 5
	DW Attr5_S + 5
	DW Attr6_S + 5
	DW 0
	DW Attr7_S
StAt1_B	DW StAt1_P, 428h, M30_60
	DB 1, 2, 24, 0
	DB 3  ; Read only
	DB 6, 1, 0, 4
	DW 407h, MD.TmpBuf+0, MD.TmpBuf+0
	DB 3  ; Archive
	DB 0, 2, 1, 4
	DW 507h, MD.TmpBuf+1, MD.TmpBuf+1
	DB 3  ; Hidden
	DB 1, 3, 2, 5
	DW 607h, MD.TmpBuf+2, MD.TmpBuf+2
	DB 3  ; System
	DB 2, 6, 3, 5
	DW 707h, MD.TmpBuf+3, MD.TmpBuf+3
	DB 1  ; Date
	DB 3, 5, 1, 4
	DW 517h, MD.TmpBuf+15, 00Ah
	DB 1  ; Time
	DB 4, 6, 3, 5
	DW 717h, MD.TmpBuf+30, 10Ah
	DB 4  ; Set / Cancel
	DB 5, 0, 6, 6
	DW 91Eh, MD.TmpBuf+8, SetCa_D
	DB 0
StAt2_P	DB Box_C, BoxCu_C, Box_C, BoxBr_C
	DB 9, 0
	DW MD.WinBuf
	DW Attr_S
	DW Attr1_S
	DW Attr2_S
	DW Attr3_S
	DW Attr4_S
	DW Attr5_S
	DW Attr6_S
	DW 0
	DW Attr7_S
StAt2_B	DW StAt2_P, 428h, M30_60
	DB 1, 2, 24, 0
	DB 3  ; Read only
	DB 10, 1, 0, 4
	DW 407h, MD.TmpBuf+0, MD.TmpBuf+0
	DB 3  ; Archive
	DB 0, 2, 1, 5
	DW 507h, MD.TmpBuf+1, MD.TmpBuf+1
	DB 3  ; Hidden
	DB 1, 3, 2, 6
	DW 607h, MD.TmpBuf+2, MD.TmpBuf+2
	DB 3  ; System
	DB 2, 10, 3, 7
	DW 707h, MD.TmpBuf+3, MD.TmpBuf+3
	DB 3  ; Read only
	DB 3, 5, 0, 8
	DW 40Ch, MD.TmpBuf+10, MD.TmpBuf+10
	DB 3  ; Archive
	DB 4, 6, 1, 8
	DW 50Ch, MD.TmpBuf+11, MD.TmpBuf+11
	DB 3  ; System
	DB 5, 7, 2, 9
	DW 60Ch, MD.TmpBuf+12, MD.TmpBuf+12
	DB 3  ; Hidden
	DB 6, 10, 3, 9
	DW 70Ch, MD.TmpBuf+13, MD.TmpBuf+13
	DB 1  ; Date
	DB 7, 9, 5, 8
	DW 51Ch, MD.TmpBuf+15, 00Ah
	DB 1  ; Time
	DB 8, 10, 7, 9
	DW 71Ch, MD.TmpBuf+30, 10Ah
	DB 4  ; Set / Cancel
	DB 9, 0, 10, 10
	DW 91Eh, MD.TmpBuf+8, SetCa_D
	DB 0
StAtr_P	DB Box_C, 0, 0, 0
	DB 3, 1
	DW MD.WinBuf
	DW MD.TmpBuf
	DB 7, 64
	DW Attr_S
	DW StAtr_S
	DW Var_S
NoDat_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 0
	DW MD.ErrBuf
	DW Attr_S
	DW NoDt1_S
	DW NoDt2_S
	DW Ok_S
NoDat_B	DW NoDat_P, 0C28h, 0
	DB 1, 0FFh, 0, 0
	DB 4
	DB 0, 0, 0, 0
	DW 426h, MD.TmpBuf+100, OkMn_D
	DB 0
AtrEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.TmpBuf
	DB 7, 64
	DW Attr_S
	DW Inc_S
	DW Var_S
	DW OkCan_S
AtrEr_B	DW AtrEr_P, 928h, 0
	DB 1, 0FFh, 0, 2
	DB 4
	DB 0, 0, 0, 0
	DW 422h, MD.TmpBuf+100, OkCan_D
	DB 0
SetCa_D	DB 7, 0
	DB 10, 10
	DB 0

Label_P	DB Box_C, BoxCu_C, 0, 0
	DB 3, 1
	DW MD.WinBuf
	DW MD.TmpBuf+20
	DB 0, 30
	DW Lab0_S
	DW Lab1_S
	DW Empty_S
Label_B	DW Label_P, 528h, 0
	DB 1, 3, 29, 0
	DB 1
	DB 0, 0, 0, 0
	DW 305h, MD.TmpBuf+1, 20Bh
	DB 0
DelVo_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.Volume
	DB 0, 15
	DW Lab0_S
	DW Lab2_S
	DW Lab3_S
	DW DelCa_S
DelVo_B	DW DelVo_P, 728h, 0
	DB 1, 0FFh, 0, 5
	DB 4
	DB 0, 0, 0, 0
	DW 41Fh, MD.TmpBuf+100, DelCa_D
	DB 0
ErVol_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.TmpBuf+1
	DB 6, 15
	DW Lab0_S
	DW ErVol_S
	DW Var_S
	DW Ok_S
ErVol_B	DW ErVol_P, 728h, 0
	DB 1, 0FFh, 0, 2
	DB 4
	DB 0, 0, 0, 0
	DW 426h, MD.TmpBuf+100, OkMn_D
	DB 0

PthEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.TmpBuf
	DB 6, 64
	DW Err_S
	DW PthEr_S
	DW Var_S
	DW Ok_S
PthEr_B	DW PthEr_P, 528h, 0
	DB 1, 0FFh, 0, 6
	DB 4
	DB 0, 0, 0, 0
	DW 426h, MD.TmpBuf+200, OkMn_D
	DB 0

;ASSUME CS:DGROUP  ; Without this, JWasm can't put code labels to .DATA, and it would fail with `Use of register assumed to ERROR'.

;GLOBAL DirFunc
DirFunc:  ; PROC NEAR  ; Find files in directory
	PUSH ES
	POP DS
	MOV DI, MD.TmpBuf
	DW _MOV_DX_DI
	MOV CX, LenPath
	DW _XOR_AX_AX
	REPNE SCASB
	JE DiFu01
	CMP WORD [ES:MD.FncAddr], DiSi10
	JE DiFu00
	MOV BP, PthEr_B
	CALL Dialog
DiFu00:	DW _XOR_AX_AX
	JMP DiFu14
DiFu01:	DEC DI
	PUSH CS
	POP DS
	MOV SI, Mask_S+1
	DW _CMP_DI_DX
	JE DiFu02
	MOV AL, [ES:DI-1]
	CMP AL, ':'
	JE DiFu02
	CMP AL, '\'
	JE DiFu02
	DEC SI
DiFu02:	MOV CX, 5
	REP MOVSB
	PUSH ES
	POP DS
	CALL SetDTA
	MOV BX, 1
	MOV CX, 37h
	MOV AH, 4Eh
	JMP DiFu05
DiFu03:	MOV SI, MD.DTA+DTAs.FilName
	CMP BYTE [SI], '.'
	JE DiFu04
	DW _MOV_DI_SI
	MOV SI, MD.TmpBuf
	CALL CutPath
	DW _XCHG_SI_DI
	MOV CX, 13
	REP MOVSB
	CALL TstBrk
	JC DiFu06
	MOV AL, [0+MD.DTA+DTAs.FilAttr]
	CALL [MD.FncAddr]
	PUSH ES
	POP DS
	CMP AH, 0
	JNZ DiFu06
	CMP AL, 0
	JNZ DiFu04
	MOV BL, 0
DiFu04:	MOV AH, 4Fh
DiFu05:	CALL ChgDisk
	JC DiFu06
	CALL Intr21
	JNC DiFu03
	CMP AX, STRICT WORD 53h
	JNE DiFu07
DiFu06:	MOV AX, 100h
	JMP DiFu14
DiFu07:	MOV SI, MD.TmpBuf
	DW _MOV_DX_SI
	CALL CutPath
	DW _CMP_SI_DX
	JBE DiFu06
	MOV AL, [SI-1]
	CMP AL, '\'
	JNE DiFu08
	DEC SI
	DW _CMP_SI_DX
	JBE DiFu06
	MOV BYTE [SI], 0
	MOV AL, [SI-1]
DiFu08:	CMP AL, ':'
	JE DiFu13
	DW _MOV_SI_DX
	CALL CutPath
	PUSH SI
	MOV DI, MD.MenuBuf
	MOV CX, 13
	REP MOVSB
	POP DI
	PUSH CS
	POP DS
	MOV SI, Mask_S+1
	MOV CX, 4
	REP MOVSB
	PUSH ES
	POP DS
	CALL ChgDisk
	JC DiFu06
	MOV CX, 37h
	MOV AH, 4Eh
	JMP DiFu11
DiFu09:	TEST BYTE [MD.DTA+DTAs.FilAttr], 10h
	JZ DiFu10
	MOV DI, MD.MenuBuf
	MOV CX, 13
	MOV AL, 0
	PUSH DI
	REPNE SCASB
	DW _MOV_CX_DI
	POP DI
	DW _SUB_CX_DI
	MOV SI, MD.DTA+DTAs.FilName
	REPE CMPSB
	JE DiFu12
DiFu10:	MOV AH, 4Fh
DiFu11:	CALL Intr21
	JNC DiFu09
	JMP DiFu06
DiFu12:	MOV SI, MD.TmpBuf
	CALL CutPath
	DW _MOV_DI_SI
	MOV SI, MD.MenuBuf
	MOV CX, 13
	REP MOVSB
DiFu13:	DW _MOV_AX_BX
DiFu14:	RET
;DirFunc ENDP

FncSel:	MOV AL, 0  ; Selected files and directories
	MOV [ES:MD.ZoomOne], AL
	MOV [ES:MD.TmpBuf+91], AL
	MOV DS, [ES:MD.WCBcrn]
	MOV SI, [WCBdef.CurAdr]
	CMP BYTE [ES:MD.OneFile], 0
	JNZ FncSl5
	MOV SI, WCBdef.DskBuf
FncSl1:	CMP SI, [WCBdef.EndBuf]
	JAE FncSl2
	AND BYTE [SI+FILENT.AttrF], 7Fh
	ADD SI, FILENT_size
	JMP FncSl1
FncSl2:	CALL TotSel
	MOV SI, [WCBdef.CurAdr]
	DW _OR_BX_DX
	JE FncSl5
	MOV SI, WCBdef.DskBuf
FncSl3:	CMP SI, [WCBdef.EndBuf]
	JB FncSl4
	JMP FncExt
FncSl4:	TEST BYTE [SI+FILENT.AttrF], 40h
	JNZ FncSl5
	JMP FncSl9
FncSl5:	PUSH SI
	MOV DI, MD.TmpBuf
	MOV CX, 13
	REP MOVSB
	POP SI
	MOV AL, [SI+FILENT.AttrF]
	CALL [ES:MD.FncAddr]
	OR [ES:MD.TmpBuf+91], AL
	MOV DS, [ES:MD.WCBcrn]
	CMP BYTE [ES:MD.OneFile], 0
	JNZ FncExt
	PUSH AX
	CMP AL, 0
	JZ FncSl8
	TEST BYTE [SI+FILENT.AttrF], 40h
	JZ FncSl8
	AND BYTE [SI+FILENT.AttrF], 3Fh
	OR BYTE [SI+FILENT.AttrF], 80h
	CMP BYTE [ES:MD.UnSlct], 0  ; Who sets this?
	JZ FncSl8
	CALL PutFls
	CALL LnsAX
	DW _MOV_CX_AX
	DW _MOV_AX_SI
	SUB AX, [WCBdef.First]
	MOV BX, FILENT_size
	DW _XOR_DX_DX
	DIV BX
	DW _XOR_DX_DX
	DIV CX
	DW _XOR_CX_CX
	CMP [WCBdef.BrfFul], CL
	JNE FncSl6
	MOV CL, 2
FncSl6:	DW _CMP_AX_CX
	JA FncSl7
	CALL BegBX
	ADD BX, 201h
	DW _ADD_BH_DL
	MOV DX, 126h
	CALL Window
FncSl7:	CMP BYTE [ES:MD.MiniSta], 0
	JZ FncSl8
	CALL BegBX
	CALL SizDX
	DW _ADD_BH_DH
	SUB BH, 2
	MOV DX, 128h
	CALL Window
FncSl8:	POP AX
	CALL TstBrk
	JC FncExt
	DW _OR_AH_AH
	JNZ FncExt
FncSl9:	ADD SI, FILENT_size
	JMP FncSl3

FncExt:	CMP BYTE [ES:MD.TmpBuf+91], 0  ; Exit
	JE FncEx2
FncEx1:	MOV DS, [ES:MD.WCBcrn]
	MOV BYTE [WCBdef.ChgFlg], 1
	CALL InvWCB
	MOV BYTE [WCBdef.ChgFlg], 1
	JMP Init50
FncEx2:	JMP Func04

NoFnc_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 2
	DW MD.ErrBuf
	DW MD.TmpBuf
	DB 7, 64
	DW MD.TmpBuf+100
	DB 0, 50
	DW Inc_S
	DW NoFnc_S
	DW Var_S
	DW Ok_S
NoFnc_B	DW NoFnc_P, 928h, 0
	DB 1, 0FFh, 0, 2
	DB 4
	DB 0, 0, 0, 0
	DW 426h, MD.TmpBuf+100, OkMn_D
	DB 0

Copy1_P	DB Box_C, BoxCu_C, Box_C, 0
	DB 5, 2
	DW MD.MenuBuf+500
	DW CpVar1
	DB 0, 70
	DW CpVar2
	DB 0, 70
	DW Var_S
	DW Var2_S
	DW Empty_S
	DW 0
	DW CoMnu_S
Copy1_B	DW Copy1_P, 528h, F35_61
	DB 8, 2, 0, 8
	DB 1
	DB 1, 1, 0, 0
	DW 305h, CpInpt, 200h+LenStr
	DB 4
	DB 0, 0, 1, 1
	DW 516h, CpMenu, Copy_D
	DB 0
Copy2_P	DB Box_C, BoxCu_C, Box_C, 0
	DB 7, 2
	DW MD.MenuBuf+500
	DW CpVar1
	DB 0, 70
	DW CpVar2
	DB 0, 70
	DW Var_S
	DW Var2_S
	DW Empty_S
	DW CpTo1_S
	DW Empty_S
	DW 0
	DW CoMnu_S
Copy2_B	DW Copy2_P, 528h, F35_60
	DB 8, 2, 0, 8
	DB 1
	DB 2, 1, 0, 0
	DW 305h, MD.ViewFil, 300h+LenStr
	DB 1
	DB 0, 2, 1, 1
	DW 505h, CpInpt, 200h+LenStr
	DB 4
	DB 1, 0, 2, 2
	DW 716h, CpMenu, Copy_D
	DB 0
Renam_P	DB Box_C, BoxCu_C, 0, 0
	DB 3, 1
	DW MD.WinBuf
	DW CpDest
	DB 0, 30
	DW Ren0_S
	DW Ren1_S
	DW Empty_S
Renam_B	DW Renam_P, 528h, 0
	DB 1, 2, 0, 0
	DB 1
	DB 0, 0, 0, 0
	DW 305h, CpDest, 20Ch
	DB 0
CopFi_P	DB Box_C, 0, 0, 0
	DB 6, 2
	DW MD.WinBuf
	DW CpSrc
	DB 7, 64
	DW CpDest
	DB 4, 64
	DW Copy0_S
	DW CopFi_S
	DW Var_S
	DW CopTo_S+3
	DW Var2_S
	DW Diagr_S
MovFi_P	DB Box_C, 0, 0, 0
	DB 6, 2
	DW MD.WinBuf
	DW CpSrc
	DB 7, 64
	DW CpDest
	DB 4, 64
	DW Move0_S
	DW MovFi_S
	DW Var_S
	DW CopTo_S+3
	DW Var2_S
	DW Diagr_S
RenFi_P	DB Box_C, 0, 0, 0
	DB 4, 2
	DW MD.WinBuf
	DW CpSrc
	DB 7, 64-3
	DW CpDest
	DB 7, 64
	DW Ren0_S
	DW RenFi_S
	DW CopTo_S
	DW Var2_S
CopDi_P	DB Box_C, 0, 0, 0
	DB 5, 2
	DW MD.WinBuf
	DW CpSrc
	DB 6, 64
	DW CpDest
	DB 6, 64
	DW Inc_S
	DW CopDi_S
	DW Var_S
	DW CopTo_S+3
	DW Var2_S
MovDi_P	DB Box_C, 0, 0, 0
	DB 5, 2
	DW MD.WinBuf
	DW CpSrc
	DB 6, 64
	DW CpDest
	DB 6, 64
	DW Inc_S
	DW MovDi_S
	DW Var_S
	DW CopTo_S+3
	DW Var2_S
OvrCo_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 5, 1
	DW MD.ErrBuf
	DW CpDest
	DB 4, 64
	DW Inc_S
	DW OvRn1_S
	DW Var_S
	DW OvRn2_S
	DW OvrAp_S
OvrCo_B	DW OvrCo_P, 928h, 0
	DB 1, 0FFh, 0, 5
	DB 4
	DB 0, 0, 0, 0
	DW 517h, CpMenu, OvrAp_D
	DB 0
Cont_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 5, 2
	DW MD.ErrBuf
	DW CpSrc
	DB 7, 64
	DW CpDest
	DB 4, 64
	DW Inc_S
	DW Cont1_S
	DW CopTo_S
	DW Var2_S
	DW Cont2_S
Cont_B	DW Cont_P, 928h, 0
	DB 1, 0FFh, 0, 5
	DB 4
	DB 0, 0, 0, 0
	DW 51Fh, CpMenu, Cont_D
	DB 0
OpnEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW CpDest
	DB 4, 64
	DW Inc_S
	DW OpnEr_S
	DW Var_S
	DW OkCan_S
OpnEr_B	DW OpnEr_P, 928h, 0
	DB 1, 0FFh, 0, 6
	DB 4
	DB 0, 0, 0, 0
	DW 422h, CpMenu, OkCan_D
	DB 0
Itslf_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW CpSrc
	DB 7, 64
	DW Inc_S
	DW Itslf_S
	DW Var_S
	DW OkCan_S
Itslf_B	DW Itslf_P, 928h, 0
	DB 1, 0FFh, 0, 6
	DB 4
	DB 0, 0, 0, 0
	DW 422h, CpMenu, OkCan_D
	DB 0
RenEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW CpSrc
	DB 7, 64
	DW Ren0_S
	DW RenEr_S
	DW Var_S
	DW OkCan_S
RenEr_B	DW RenEr_P, 928h, 0
	DB 1, 0FFh, 0, 6
	DB 4
	DB 0, 0, 0, 0
	DW 422h, CpMenu, OkCan_D
	DB 0
Prot_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 5, 1
	DW MD.WinBuf+2000
	DW CpDest
	DB 4, 64
	DW Inc_S
	DW Var_S
	DW Prot1_S
	DW Prot2_S
	DW YesNo_S
Prot_B	DW Prot_P, 928h, 0
	DB 1, 0FFh, 0, 5
	DB 4
	DB 0, 0, 0, 0
	DW 523h, MD.TmpErr, YesNo_D
	DB 0
Copy_D	DB 8, 0
	DB 12,11
	DB 10,26
	DB 0
OvrAp_D	DB 11, 0
	DB 5,12
	DB 8,18
	DB 6,27
	DB 0
OvrSk_D	DB 11, 0
	DB 5,12
	DB 6,18
	DB 0
Cont_D	DB 7, 0
	DB 10, 8
	DB 0

View_T	DW 001Bh, V13_00
	DW 3D00h, V13_00
	DW 4400h, V13_00
	DW 4B00h, V01_00
	DW 0013h, V01_00
	DW 4D00h, V03_00
	DW 0004h, V03_00
	DW 7300h, V02_00
	DW 0001h, V02_00
	DW 7400h, V04_00
	DW 0006h, V04_00
	DW 4800h, V05_00
	DW 0005h, V05_00
	DW 5000h, V06_00
	DW 0018h, V06_00
	DW 4900h, V07_00
	DW 0012h, V07_00
	DW 5100h, V08_00
	DW 0003h, V08_00
	DW 4700h, V09_00
	DW 7700h, V09_00
	DW 8400h, V09_00
	DW 4F00h, V10_00
	DW 7500h, V10_00
	DW 7600h, V10_00
	DW 3E00h, V11_00
	DW 000Dh, V11_00
	DW 3C00h, V12_00
	DW 4100h, V14_00
	DW 5A00h, V15_00
	DW 0
ViewPar	DB 0,'Socha',0
	DW 11Fh
RunEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.TmpBuf
	DB 0, 50
	DW Err_S
	DW Inc_S
	DW Var_S
	DW Ok_S
RunEr_B	DW RunEr_P, 928h, 0  ; _BOXHD
	    DB 2, 0FFh, 0FFh, 2
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 426h, MD.TmpBuf, OkMn_D
	DB 0
ViFil_P	DB Box_C, BoxCu_C, 0, 0
	DB 3, 0
	DW MD.WinBuf
	DW ViFi0_S
	DW ViFi1_S
	DW Empty_S
ViFil_B	DW ViFil_P, 528h, 0
	DB 1, 2, 0, 0
	DB 1
	DB 0, 0, 0, 0
	DW 305h, MD.ViewFil, 200h+LenStr
	DB 0
Viewr_P	DB Box_C, 0, 0, 0
	DB 3, 1
	DW MD.WinBuf
	DW MD.TmpBuf
	DB 7, 64
	DW ViFl_S
	DW ViFl1_S
	DW Var_S
Editr_P	DB Box_C, 0, 0, 0
	DB 3, 1
	DW MD.WinBuf
	DW MD.TmpBuf
	DB 7, 64
	DW EdFl_S
	DW EdFl1_S
	DW Var_S
RdFil_P	DB Box_C, 0, 0, 0
	DB 3, 1
	DW MD.WinBuf
	DW MD.ViewFil
	DB 7, 64
	DW Inc_S
	DW RdFil_S
	DW Var_S
Srch_P	DB Box_C, BoxCu_C, 0, 0
	DB 3, 0
	DW MD.WinBuf
	DW Inc_S
	DW Srch_S
	DW Empty_S
Srch_B	DW Srch_P, 528h, 0
	DB 1, 0FFh, 0, 0
	DB 1
	DB 0, 0, 0, 0
	DW 305h, MD.SrchStr, LenStr
	DB 0
SrFor_P	DB Box_C, 0, 0, 0
	DB 3, 1
	DW MD.WinBuf
	DW MD.SrchStr
	DB 0, LenStr
	DW Inc_S
	DW SrFor_S
	DW Kov_S
FndEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.ViewFil
	DB 7, 64
	DW Inc_S
	DW NoFnd_S
	DW Var_S
	DW Ok_S
FndEr_B	DW FndEr_P, 928h, 0
	DB 1, 0FFh, 0, 2
	DB 4
	DB 0, 0, 0, 0
	DW 426h, MD.TmpBuf, OkMn_D
	DB 0
SrEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.WinBuf+2000
	DW MD.SrchStr
	DB 0, LenStr
	DW Inc_S
	DW SrEr_S
	DW Kov_S
	DW Ok_S
SrEr_B	DW SrEr_P, 928h, 0
	DB 1, 0FFh, 0, 0
	DB 4
	DB 0, 0, 0, 0
	DW 426h, MD.TmpBuf, OkMn_D
	DB 0

EdtH_P	DB HlpMn_C
Edit_T	DW 0009h, T03_00  ; Tab
	DW 0011h, T04_00  ; ^Q
	DW 4B00h, T05_00  ; Left
	DW 0013h, T05_00  ; ^S
	DW 4D00h, T06_00  ; Right
	DW 0004h, T06_00  ; ^D
	DW 7300h, T07_00  ; ^Left
	DW 0001h, T07_00  ; ^A
	DW 7400h, T08_00  ; ^Right
	DW 0006h, T08_00  ; ^F
	DW 4800h, T09_00  ; Up
	DW 0005h, T09_00  ; ^E
	DW 5000h, T10_00  ; Down
	DW 0018h, T10_00  ; ^X
	DW 4900h, T11_00  ; PgUp
	DW 0012h, T11_00  ; ^R
	DW 5100h, T12_00  ; PgDn
	DW 0003h, T12_00  ; ^C
	DW 4700h, T13_00  ; Home
	DW 4F00h, T14_00  ; End
	DW 8400h, T15_00  ; ^PgUp
	DW 7600h, T16_00  ; ^PgDn
	DW 7700h, T15_00  ; ^Home
	DW 7500h, T16_00  ; ^End
	DW 5300h, T20_00  ; Del
	DW 0007h, T20_00  ; ^G
	DW 0008h, T21_00  ; BackSpace
	DW 007Fh, T22_00  ; ^BS
	DW 0017h, T22_00  ; ^W
	DW 0014h, T23_00  ; ^T
	DW 000Bh, T24_00  ; ^K
	DW 0019h, T25_00  ; ^Y
	DW 0015h, T26_00  ; ^U
	DW 3E00h, T30_00  ; F4
	DW 4100h, T31_00  ; F7
	DW 5A00h, T32_00  ; Shift F7
	DW 5500h, T33_00  ; Shift F2
	DW 3C00h, T34_00  ; F2
	DW 001Bh, T35_00  ; Esc
	DW 4400h, T35_00  ; F10
	DW 5D00h, T35_01  ; Shift F10
	DW 0
SavFi_P	DB Box_C, 0, 0, 0
	DB 3, 1
	DW MD.WinBuf
	DW MD.ViewFil
	DB 7, 64
	DW EdFl_S
	DW SavFi_S
	DW Var_S
SavAs_P	DB Box_C, BoxCu_C, 0, 0
	DB 3, 0
	DW MD.WinBuf
	DW EdFl_S
	DW SavAs_S
	DW Empty_S
SavAs_B	DW SavAs_P, 528h, 0  ; _BOXHD
	    DB 1, 0FFh, 0, 0
	DB 1, 0, 0, 0, 0  ; _BOXMN
	    DW 305h, MD.ViewFil, 200h+LenStr
	DB 0
SavCn_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 3, 0
	DW MD.WinBuf
	DW EdFl_S
	DW SvCn1_S
	DW SvCn2_S
SavCn_B	DW SavCn_P, 528h, 0  ; _BOXHD
	    DB 1, 0FFh, 0, 1
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 315h, MD.TmpErr, SavCn_D
	DB 0
BigFi_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.ViewFil
	DB 7, 64-9
	DW EdFl_S
	DW BgFi1_S
	DW BgFi2_S
	DW BgFi3_S
BigFi_B	DW BigFi_P, 928h, 0  ; _BOXHD
	    DB 1, 0FFh, 0, 0
	DB 4 , 0, 0, 0, 0  ; _BOXMN
	    DW 420h, MD.TmpErr, BigFi_D
	DB 0
NewFi_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.ViewFil
	DB 7, 64
	DW EdFl_S
	DW NoFnd_S
	DW Var_S
	DW NewFi_S
NewFi_B	DW NewFi_P, 928h, 0  ; _BOXHD
	    DB 1, 0FFh, 0, 0
	DB 4 , 0, 0, 0, 0  ; _BOXMN
	    DW 41Eh, MD.TmpErr, NewFi_D
	DB 0
SavEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.WinBuf+2000
	DW MD.ViewFil
	DB 7, 64
	DW EdFl_S
	DW SavEr_S
	DW Var_S
	DW Ok_S
SavEr_B	DW SavEr_P, 928h, 0  ; _BOXHD
	    DB 1, 0FFh, 0, 2
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 426h, MD.TmpErr, OkMn_D
	DB 0
SavCn_D	DB 6, 0
	DB 12, 7
	DB 18,20
	DB 0
BigFi_D	DB 6, 0
	DB 8, 7
	DB 0
NewFi_D	DB 10, 0
	DB 8,11
	DB 0

HlpMn_P	DB Help_C, HlpRe_C, HlpRe_C
Help_P	DB Help_C, HlpRe_C, HlpBo_C, HlpUn_C
HlMn1_D	DB 8, 14
	DB 10, 25
	DB 0
HlMn2_D	DB 8, 0
	DB 12, 11
	DB 9, 26
	DB 10, 38
	DB 0
Help_T	DW 4800h, Help50
	DW 5000h, Help53
	DW 4700h, Help55
	DW 4F00h, Help56
	DW 4900h, Help57
	DW 5100h, Help58
	DW 000Dh, Help60
	DW 001Bh, Help66
	DW 4400h, Help66
	DW 0
HlpEr_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 0
	DW HlpData_size
	DW Help_S
	DW HlEr1_S
	DW HlEr2_S
	DW Ok_S
HlpEr_B	DW HlpEr_P, 928h, 0
	DB 2, 0FFh, 0FFh, 2
	DB 4
	DB 0, 0, 0, 0
	DW 426h, MD.TmpErr, OkMn_D
	DB 0

Memo_P	DB Conf_C, CnfBo_C, CnfRe_C, CnfUn_C
Memo1_P	DB Conf_C, CnfRe_C, CnfRe_C
Memo_T	DW 4800h, F65_50
	DW 5000h, F65_52
	DW 4700h, F65_54
	DW 4F00h, F65_55
	DW 4900h, F65_56
	DW 5100h, F65_57
	DW 5200h, F65_60
	DW 4E2Bh, F65_62
	DW 4A2Dh, F65_63
	DW 000Dh, F65_70
	DW 001Bh, F65_83
	DW 4400h, F65_83
	DW 0
Memo_D	DB 11, 0
	DB 10, 14
	DB 0

Find_P	DB Conf_C, CnfRe_C, CnfBo_C, CnfUn_C
FnFl_P	DB Conf_C, CnfRe_C, CnfRe_C
Find_B	DW Find_P, 0, 0
	DB 1, 0FFh, 32, 10h
	DB 1
	DB 1, 1, 0, 0
	DW 305h, MD.FindStr, LenStr
	DB 1
	DB 0, 0, 1, 1
	DW 505h, MD.SrchStr, 100h+LenStr
	DB 0
Find_T	DW 4800h, FnMv12
	DW 5000h, FnMv13
	DW 4700h, FnMv10
	DW 4F00h, FnMv11
	DW 4900h, FnMv14
	DW 5100h, FnMv15
	DW 000Dh, FnMv31
	DW 001Bh, FnMv32
	DW 4400h, FnMv32
	DW 0
Find5_D	DB 8, 0
	DB 9, 11
	DB 8, 23
	DB 0
Find6_D	DB 14, 0
	DB 9, 17
	DB 8, 29
	DB 0

RtAb_D	DB 7, 0
	DB 7, 8
	DB 0
FtEr1_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf1
	DW MD.TmpErr+1
	DB 0, 70
	DW Err_S
	DW Var_S
	DW Inc_S
	DW RtAb_S
FtEr2_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 4, 1
	DW MD.ErrBuf1
	DW MD.TmpErr+1
	DB 0, 70
	DW Err_S
	DW Var_S
	DW Inc_S
	DW Ok_S
FtEr1_B	DW FtEr1_P, 928h, 0  ; _BOXHD
	    DB 2, 0FFh, 0FFh, 7
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 420h, MD.TmpErr, RtAb_D
	DB 0
FtEr2_B	DW FtEr2_P, 928h, 0  ; _BOXHD
	    DB 2, 0FFh, 0FFh, 7
	DB 4, 0, 0, 0, 0  ; _BOXMN
	    DW 426h, MD.TmpErr, OkMn_D
	DB 0
OkMn_D	DB 4, 0
	DB 0
SecDat	DW 0

NoRd_P	DB Err_C, ErInv_C, 0, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.TmpErr+1
	DB 0, 55
	DW Err_S
	DW NoRd1_S
	DW NoRd2_S
	DW NoRd3_S
Ready_T	DW 001Bh, ErRdy6
	DW 4400h, ErRdy6
	DW 000Dh, ErRdy7
	DW 0

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

;-------------------- Output key bar -------------------
;			   AL - Case
KeyB_T	DB 1, 2, 3, 4  ;  0
	DB 7, 0, 0, 0  ;  1
	DB 8, 0, 0, 0  ;  2
	DB 9,12, 0, 0  ;  3
	DB 10,12, 0, 0  ;  4
	DB 11,12, 0, 0  ;  5
	DB 13,16, 0, 0  ;  6
	DB 14,16, 0, 0  ;  7
	DB 6, 0, 0,17  ;  8
	DB 1, 2, 3, 5  ;  9
	DB 15,16, 0, 0  ; 10
	DB 1, 1, 1, 1  ; 11
	DB 2, 2, 2, 2  ; 12
	DB 4, 4, 4, 4  ; 13
	DB 18, 0, 0, 0  ; 14
LenKeyB EQU $ - KeyB_T

KeyC_T	DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ;  0
	DB 1, 2, 3, 4, 5, 6, 7, 8, 9, 10  ;  1
	DB 0, 31, 3, 4, 5, 6, 7, 8, 11, 12  ;  2
	DB 13, 14, 0, 32, 5, 6, 0, 8, 0, 0  ;  3
	DB 13, 14, 15, 16, 30, 17, 18, 19, 20, 21  ;  4
	DB 13, 14, 15, 16, 30, 17, 18, 19, 0, 21  ;  5
	DB 1, 0, 0, 0, 0, 0, 0, 0, 0, 21  ;  6
	DB 1, 0, 0, 0, 0, 0, 0, 0, 0, 10  ;  7
	DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 10  ;  8
	DB 1, 0, 10, 22, 0, 0, 26, 0, 0, 10  ;  9
	DB 1, 24, 10, 23, 0, 0, 26, 0, 0, 10  ; 10
	DB 1, 25, 10, 23, 0, 0, 26, 0, 0, 10  ; 11
	DB 0, 0, 0, 0, 0, 0, 26, 0, 0, 0  ; 12
	DB 1, 27, 0, 22, 0, 0, 26, 0, 0, 10  ; 13
	DB 1, 27, 0, 23, 0, 0, 26, 0, 0, 10  ; 14
	DB 1, 27, 0, 0, 0, 0, 26, 0, 0, 10  ; 15
	DB 0, 28, 0, 0, 0, 0, 26, 0, 0, 29  ; 16
	DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 21  ; 17
	DB 1, 33, 0, 0, 0, 0, 0, 0, 0, 10  ; 18

PtMnu_B	DB Menu_C

Panel_P	DB Back_C, Title_C
Brief_T	DB 13, 26, 0
Full_T	DB 13, 23, 32, 0

PutPt_P	DB Back_C, Cursr_C

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

Tree_P	DB Box_C, 0, 0, 0
	DB 4, 1
	DW MD.ErrBuf
	DW MD.MenuBuf
	DB 0, 25
	DW Tree_S
	DW Scan1_S
	DW Scan2_S
	DW Scan3_S
TrSav_P	DB Box_C, 0, 0, 0
	DB 3, 0
	DW MD.ErrBuf
	DW Tree_S
	DW Scan4_S
	DW Scan5_S

PtFs_P	DB Slct_C

PutTr_P	DB Back_C, Cursr_C, Slct_C, CurSl_C

PtIn_P	DB Back_C, Title_C

Fant_P	DB Err_C, ErInv_C, ErInv_C, 0
	DB 3, 1
	DW MD.ErrBuf1
	DW MD.TmpErr+1
	DB 0, 25
	DW Fant0_S
	DW Fant1_S
	DW OkCan_S
Fant_B	DW Fant_P, 928h, 0
	DB 2, 0FFh, 0FFh, 5
	DB 4
	DB 0, 0, 0, 0
	DW 322h, MD.TmpErr, OkCan_D
	DB 0
OkCan_D	DB 4, 0
	DB 8, 5
	DB 0

ChTr_P	DB Conf_C, CnfRe_C, CnfBo_C, CnfUn_C
ChTr_T	DW 4800h, ChTr35
	DW 5000h, ChTr37
	DW 4900h, ChTr40
	DW 5100h, ChTr42
	DW 4700h, ChTr30
	DW 4F00h, ChTr32
	DW 000Dh, ChTr45
	DW 001Bh, ChTr46
	DW 4400h, ChTr46
	DW 3C00h, ChTr55
	DW 0012h, ChTr55
	DW 0

;SECTION .CONST
	TIMES ($$-$)&1 DB 0  ; EVEN

Title_S	DB 0FFh,14,'The ','Volkov Commander',', Version ','4.05',0  ; PrgName, VcVers.
%if SHWW_LE_1
Suff_S	DB ' ','shareware',0  ; VcSuff.
%else
Suff_S	DB ' ','freeware',0  ; VcSuff.
%endif
Copyr_S	DB 13,10, 'Copyright (C) 1991-2000 Vsevolod V. Volkov',0
%if SHWW_LE_1
RegTo_S	DB 13,10, 'Registered to: ', 0
NumCp_S	DB 13,10, 'Number of copies: ',0
%endif
CrLf_S	DB 13,10, '$'
Retrn_S	DB 13,10, 'Press ENTER to return ', 0
	DB 13,10, 'to the ','Volkov Commander', 0  ; PrgName.
NoIni_S	DB 'VC.INI is not correct.',13,10, 0
Vers_S	DB 13,10, 'This program requires DOS 3.20 or later.'
	DB 13,10, 0
Comsp	DB 'COMSPEC='
NcEnv	DB 'VC='
TempEnv	DB 'TEMP='

Sel_S	DB 'Select',0
Unsl_S	DB 'Unselect',0
Inv_S	DB 'Invert',0
IncSp_S	DB ' ^I ',0
Sel1_S	DB '^I the files', 0
ErSel_S	DB 'Could not find a match',0
Kov_S	DB '"^V"'
Empty_S	DB 0

CDir_S	DB '\',0

Name_S	DB 'Volkov Commander',0  ; PrgName.
Quit1_S	DB ' The ^I ',0
Quit2_S	DB 'Do you want to quit the ^I?',0
YesNo_S	DB 'Yes',0FFh,3,'No',0

Menu_F	DB 'VC.MNU',0
User_S	DB ' User Menu ',0
User1_S	DB 'Could not find the menu file',0

DrLe_S	DB ' Drive letter '
Choo_S	DB 'Choose '
Left_S	DB 'left'
Rght_S	DB 'right'
Driv_S	DB ' drive:'

Hist_S	DB ' History '

AltSr_S	DB 'Search: ^r',0FFh,12,'^r',0

List_F	DB 'vc.lst',0

MenuLn1	DB ' Brief' ,0
	DB ' Full' ,0
	DB ' Info' ,0
	DB ' Tree' ,0
	DB ' On/Off' ,0FFh,7,'^F1',0
	DB 0
	DB ' Name' ,0
	DB ' eXtension' ,0
	DB ' tiMe' ,0
	DB ' Size' ,0
	DB ' Unsorted' ,0
	DB 0
	DB ' Re-read' ,0FFh,6,'^R' ,0
	DB ' fiLter...' ,0FFh,4,'^F' ,0
	DB ' Drive...' ,0FFh,5,'@F1',0
MenuLn2	DB 'Help' ,0FFh,14,'F1',0
	DB 'User menu' ,0FFh, 9,'F2',0
	DB 'View' ,0FFh,14,'F3',0
	DB 'Edit' ,0FFh,14,'F4',0
	DB 'Copy' ,0FFh,14,'F5',0
	DB 'Rename or move' ,0FFh, 4,'F6',0
	DB 'Make directory' ,0FFh, 4,'F7',0
	DB 'Delete' ,0FFh,12,'F8',0
	DB 0
	DB 'file Attributes' ,0FFh, 3,'^A',0
	DB 0
	DB 'select Group' ,0FFh,6,'Gray +',0
	DB 'uNselect group',0FFh,4,'Gray -',0
	DB 'Invert group' ,0FFh,6,'Gray *',0
	DB 'reStore selection ^M' ,0
	DB 0
	DB 'Quit' ,0FFh,14,'F10' ,0
MenuLn3	DB 'Tree' ,0FFh,18,'@F10',0
	DB 'Volume label' ,0FFh,10,'^F4' ,0
	DB 'memory Info' ,0FFh,11,'@F5' ,0
	DB 'Directory sizes',0FFh, 7,'@F6' ,0
	DB 'Find file' ,0FFh,13,'@F7' ,0
	DB 'History' ,0FFh,15,'@F8' ,0
	DB 'EGA lines' ,0FFh,13,'@F9' ,0
	DB 0
	DB 'Swap panels' ,0FFh,11,'^U',0
	DB 'Panels on/off' ,0FFh, 9,'^O',0
	DB 'Compare directories',0FFh,3,'^C',0
	DB 0
	DB 'Menu file edit' ,0
MenuLn4	DB ' Configuration...' ,0
	DB ' advanced Options...' ,0
	DB ' eXtension file edit...' ,0
	DB ' Viewers...' ,0
	DB ' Editors...' ,0
	DB 0
	DB ' Auto menus' ,0
	DB ' Path prompt' ,0
	DB ' Key bar' ,0FFh,12,'^B',0
	DB ' Full screen' ,0
	DB ' auto Directory sizes' ,0
	DB ' miNi status' ,0
	DB ' cLock' ,0
	DB ' Memory allocation' ,0
	DB 0
	DB ' Save setup' ,0FFh,9,'Shift-F9',0
Ctrl_S	DB 'Ctrl-'
Alt_S	DB 'Alt-'

Filt0_S	DB ' Filter ',0
Filt1_S	DB 'Select files to display',0
Filt2_S	DB 'Custom:',0FFh,14,0
Filt3_S	DB '[ ] Hidden files',0FFh,5,0
Filt4_S	DB '[ ] Executable files ',0
OkCn_S	DB '[ Ok ]',0FFh,3,'[ Cancel ]',0

DiSi1_S	DB 'Scanning sizes of subdirectories',0
DiSi2_S	DB 'on drive ^V:',0

Cmp0_S	DB ' Compare ',0
Cmp1_S	DB 'The two directories appear',0
Cmp2_S	DB 'to be identical.',0

Cnf00_S	DB ' Configuration ',0
Cnf01_S	DB ' Ú ^bScreen colors^b ',0FFh,80h+6,'Ä¿  Ú ^bPanel options^b ',0FFh,80h+16,'Ä¿ ',0
Cnf02_S	DB ' ³  ( ) Black & White  ³^IIns moves down',0FFh,11,'³ ',0
Cnf03_S	DB ' ³  ( ) Color',0FFh,10,'³^IAuto change directory',0FFh,4,'³ ',0
Cnf04_S	DB ' ³  ( ) Laptop',0FFh,9,'³  À',0FFh,80h+31,'ÄÙ ',0
Cnf05_S	DB ' À',0FFh,80h+21,'ÄÙ  Ú ^bOther options^b ',0FFh,80h+16,'Ä¿ ',0
Cnf06_S	DB ' Ú ^bScreen blank delay^b Ä¿^IMenu bar always visible  ³ ',0
Cnf07_S	DB ' ³  ( ) 40 minutes',0FFh,5,'³^IAuto save setup',0FFh,10,'³ ',0
Cnf08_S	DB ' ³  ( ) 20 minutes',0FFh,5,'³^IConfirmation on quit',0FFh,5,'³ ',0
Cnf09_S	DB ' ³  ( )  5 minutes',0FFh,5,'³^IZooming boxes',0FFh,12,'³ ',0
Cnf10_S	DB ' ³  ( )  3 minutes',0FFh,5,'³  À',0FFh,80h+31,'ÄÙ ',0
Cnf11_S	DB ' ³  ( )  1 minute',0FFh,6,'³  Ú ^bMouse options^b ',0FFh,80h+16,'Ä¿ ',0
Cnf12_S	DB ' ³  ( ) Off',0FFh,12,'³^ILeft-handed mouse',0FFh,8,'³ ',0
Cnf13_S	DB ' À',0FFh,80h+21,'ÄÙ  À',0FFh,80h+31,'ÄÙ ',0
Cnf14_S	DB 'Press ^r Space ^r to change an option, ^r  ^r and ^r  ^r',0
Cnf15_S	DB 'to move between options',0
Chk1_S	DB '  '
Chk2_S	DB '³  [ ] ',0

Set00_S	DB ' Advanced Options ' ,0
Set01_S	DB 'Ú ^bKey configuration^b ',0FFh,80h+16,'Ä¿',0
Set02_S	DB '^IAlt alone selects menu',0FFh,7,'³',0
Set03_S	DB '^IEscape toggles panels on/off ³',0
Set04_S	DB '^IAlternative viewer',0FFh,11,'³',0
Set05_S	DB '^IAlternative editor',0FFh,11,'³',0
Set07_S	DB 'Ú ^bOther options^b ',0FFh,80h+20,'Ä¿',0
Set08_S	DB '^IQuick execute commands',0FFh,7,'³',0
Set09_S	DB '^IClear keyboard buffer',0FFh,8,'³',0
Set10_S	DB ' À',0FFh,80h+35,'ÄÙ ',0
Set11_S	DB 'Press ^r Space ^r to change an option,' ,0
Set12_S	DB 'arrows to move between options',0

ExFl_S	DB ' Extension File ',0
MnLc1_S	DB 'Do you wish to edit the main,',0
MnLc2_S	DB 'or a local ^I?',0
UsMnu_S	DB 'user menu',0
ExtFl_S	DB 'extension file',0
MnLc3_S	DB 'Main',0FFh,3,'Local',0FFh,3,'Cancel',0

SvSt0_S	DB ' Setup ',0
SvSt1_S	DB 'Do you wish to save',0
SvSt2_S	DB 'the current setup?',0
SvSt3_S	DB 'Save',0FFh,3,'Cancel',0
StEr1_S	DB 'There was an error while',0
StEr2_S	DB 'saving the setup file',0

; --- include vcf1.inc

;-------------------------------------------------------
;		Version :	16.10.1999
;-------------------------------------------------------

MkDir_S	DB " Make directory ",0
MkDi1_S	DB "^I",0FFh,LenStr-20,0
CrDir_S	DB "Create the directory",0
MkErr_S	DB "Can't create the directory",0

Del_S	DB " Delete ",0
DlMas_S	DB "Delete the file:",0FFh,LenStr-16,0
DelFl_S	DB "Deleting the file^I",0
DelFs_S	DB "s",0
DelDr_S	DB "Deleting the subdirectory",0
DelSl_S	DB "You have selected",0
Del1_S	DB "Do you wish to delete^I",0
Subdi_S	DB " the directory",0
RdOn_S	DB "The following file is marked read-only.",0
NoEmp_S	DB "The following subdirectory is not empty.",0
StDel_S	DB "Do you still wish to delete it?",0
CnDl_S	DB "Can't delete the file",0
CnSb_S	DB "Can't delete the subdirectory",0
DlWr1_S	DB "WARNING!",0
DlWr2_S	DB "Do you want to delete all the files",0
DlWr3_S	DB "^V?",0
DlWr4_S	DB "in the current directory",0
DlSel_S	DB "You are ^uDELETING^u",0
From_S	DB "^V from",0
Var2_S	DB "^W",0
DelCa_S	DB " Delete",0FFh,3,"Cancel ",0
DelAl_S	DB " Delete",0FFh,3,"All",0FFh,3,"Cancel ",0
DelSk_S	DB "Delete",0FFh,3,"Skip",0FFh,3,"Cancel",0

Attr_S	DB " Attributes ",0
Attr1_S	DB "Change file attributes^I",0
Attr2_S	DB "^uSet  Clear^u",0FFh,21,0
Attr3_S	DB " [ ]  [ ] Read only",0FFh,4,"Date",0FFh,6,0
Attr4_S	DB " [ ]  [ ] Archive",0FFh,16,0
Attr5_S	DB " [ ]  [ ] Hidden",0FFh,7,"Time",0FFh,6,0
Attr6_S	DB " [ ]  [ ] System",0FFh,17,0
Attr7_S	DB "[ Set ]   [ Cancel ]",0
Attr8_S	DB " for",0
StAtr_S	DB "Setting attributes:",0
NoDt1_S	DB "Can't set the attributes.",0
NoDt2_S	DB "Illegal date or time.",0
NoFnd_S	DB "Can't find the file",0
NoAtr_S	DB "Can't set attributes",0

Lab0_S	DB ' Volume Label ',0
Lab1_S	DB 'Change volume label^V to',0
Lab2_S	DB 'Do you wish to delete volume label',0
Lab3_S	DB '^V ?',0
ErVol_S	DB 'Could not set the volume label',0

PthEr_S	DB 'Path too long', 0

NoFnc_S	DB "Can't find file^W",0

; --- include vccopy.inc

;-------------------------------------------------------
;		Version :	27.08.1999
;-------------------------------------------------------

Copy0_S	DB ' Copy ',0
Move0_S	DB ' Move ',0
Ren0_S	DB ' Rename ',0
Ren1_S	DB 'Rename "^V" to',0
RnMv_S	DB 'Rename or move '
CopTo_S	DB '^V to',0
CpTo1_S	DB 'to',0FFh,LenStr-2,0
CoMnu_S	DB '[^I]',0FFh,3,'[ F10-Tree ]',0FFh,3,'[ Cancel ]',0
CopFi_S	DB 'Copying the file',0
MovFi_S	DB 'Moving the file',0
RenFi_S	DB 'Renaming or moving the file',0
CopDi_S	DB 'Copying the directory',0
MovDi_S	DB 'Renaming or moving the directory',0
Diagr_S	DB 0FFh, 24, 0
OvRn1_S	DB 'The following file exists',0
OvRn2_S	DB 'Do you wish to write over the old file?',0
OvrAp_S	DB 'Overwrite',0FFh,3,'All',0FFh,3,'aPpend',0FFh,3,'Skip',0
Prot1_S	DB 'is a read-only file.',0
Prot2_S	DB 'Do you still wish to overwrite it?',0
Cont1_S	DB "There isn't enough room to copy",0
Cont2_S	DB "Abort",0FFh,3,"Continue",0
OpnEr_S	DB "Can't open the file",0
Itslf_S	DB "You can't copy a file to itself",0
RenEr_S	DB "Can't rename the file",0

; --- include vcview.inc

;-------------------------------------------------------
;		Version :	14.06.2000
;-------------------------------------------------------

ViewE_F	DB "VCVIEW.EXT",0
EditE_F	DB "VCEDIT.EXT",0
Col_S	DB "Col",0
Byts_S	DB " Bytes"
ViFl_S	DB " View ",0
ViFl1_S	DB "Loading the viewer:",0
EdFl_S	DB " Edit ",0
EdFl1_S	DB "Loading the editor:",0
ViFi0_S	DB " ^I",0
ViFi1_S	DB "^Ithe file:",0FFh,LenStr-14,0
RdFil_S	DB "Reading the file",0
Srch_S	DB "Search for the string",0FFh,LenStr-21,0
SrFor_S	DB "Searching for",0
SrEr_S	DB "Could not find the string",0
RunEr_S	DB "Not enough memory to load",0
Run1_S	DB "Can't run commands for some reason.",0
Run2_S	DB "Try rebooting.",0

; --- include vcedit.inc

;-------------------------------------------------------
;		Version :	16.10.1999
;-------------------------------------------------------

LenEdit EQU LenMenu  ; Length of edit buffer
; The length of undo buffer must be greate then edit buffer

Line_S	DB "Line",0
FrBuf_S	DB "Free",0
BgFi1_S	DB "The file ^V",0
BgFi2_S	DB "is too large for Edit.",0
BgFi3_S	DB "View",0FFh,3,"Cancel",0
NewFi_S	DB "New-file",0FFh,3,"Cancel",0
SvCn1_S	DB "You've made changes since the last save.",0
SvCn2_S	DB "Save",0FFh,3,"Don't save",0FFh,3,"Continue editing",0
SavAs_S	DB "Save this file as",0FFh,LenStr-17,0
SavFi_S	DB "Saving the file",0
SavEr_S	DB "There was an error writing the file",0
EdtH_S	DB "³  !.!  Filename with extension",0
	DB "³  !:",0FFh,3,"Drive letter",0
	DB "³  !\",0FFh,3,"Path name",0
	DB "³  !!",0FFh,3,"!",0
	DB "³  !",0FFh,4,"Filename w/o extension",0
	DB "³  !@",0FFh,3,"File list",0
EdtH1_S	DB " User Menu Help ",0
	DB "File format for user defined menus:",0
	DB 0
	DB "' comment",0FFh,7,"Comment line",0
	DB "m: Menu Label",0FFh,3,"Appears in the pop-up menu",0
	DB 0FFh,5,"edit !.!",0FFh,3,"Any DOS command",0
	DB 0FFh,5,"cls",0FFh,8,"Any additional commands",0
EdtH2_S	DB " Extension File Help ",0
	DB "Format of the extension file:",0
	DB 0
	DB "' comment",0FFh,10,"Comment line",0
	DB "txt: edit !.!",0FFh,6,"Any DOS command",0
	DB " ",0FFh,3,"cls",0FFh,11,"Any additional commands",0
	DB " À",0FFh,80h+16,"Ä File extension",0

; --- include vchelp.inc

;-------------------------------------------------------
;		Version :	09.05.95
;-------------------------------------------------------

Help_F	DB 'VC.HLP',0
HlpHead	DB 'VC 4.05 Help' ,0  ; HelpVer.
Help_S	DB ' Help ',0
HlEr1_S	DB 'There was error reading data',0
HlEr2_S	DB 'from the help file.',0
HlMn1_S	DB 0FFh,21,'[ Help ]',0FFh,3,'[ Cancel ]',0
HlMn2_S	DB 0FFh, 7,'[ Next ]',0FFh,3,'[ Previous ]',0FFh,3,'[ Index ]',0FFh,3,'[ Cancel ]',0

; --- include vcmem.inc

;-------------------------------------------------------
;		Version :	07.06.2000
;-------------------------------------------------------

MaxVect EQU 8
SegDOS EQU 70h

Mem0_S	DB ' Memory Info ',0
Mem1_S	DB 'Address Blocks',0FFh,3,'Size',0FFh,4,'Program',0FFh,8,'Hooked vectors',0
Mem2_S	DB '^r[ Release ]^r',0FFh,3,'[ Cancel ]',0
DosMe_S	DB 'DOS ',0
FrMem_S	DB 'free memory',0
Syst_S	DB 'system',0
Unknw_S	DB 'unknown',0

; --- include vcfind.inc

;-------------------------------------------------------
;		Version :	10.01.2000
;-------------------------------------------------------

LenFnf EQU LenStr+1

Find0_S	DB ' Find File ',0
Find1_S	DB 'File name:',0
Find2_S	DB 'Containing:',0
Find3_S	DB 'Scanning:',0
Find5_S	DB '^r[ Stop ]^r',0FFh,3,'[ Go to ]',0FFh,3,'[ Quit ]',0
Find6_S	DB '[ New search ]',0FFh,3,'[ Go to ]',0FFh,3,'[ Quit ]',0
FnFl6_S	DB ' files',0
FnFl7_S	DB ' found.',0

;--------------------- Fatal error ---------------------
Err_S	DB ' Error ',0
OnDr_S	DB 'on drive A',0
OnDv_S	DB 'on device '
Errs_S	DB 'Attempt to write on write-protected disk.',0
	DB 'Unknown disk drive.',0
	DB 'Drive or device not ready.',0
	DB 'Unknown command.',0
	DB 'Data error.',0
	DB 'Bad request.',0
	DB 'Seek error.',0
	DB 'Non-DOS disk.',0
	DB 'Sector not found.',0
	DB 'Printer out of paper.',0
	DB 'Write fault.',0
	DB 'Read fault.',0
	DB 'General failure.',0
	DB 'Sharing violation.',0
	DB 'Lock violation.',0
	DB 'Invalid disk change.',0
	DB 'FCB unavailable.',0
	DB 'Sharing buffer overflow.',0
	DB 'Code page mismatch.',0
	DB 'Out of input.',0
	DB 'Insufficient disk space.',0
	DB 'Unknown error.',0
FatEr_S	DB 'File allocation table bad.',0
RtAb_S	DB ' Retry   Abort ',0
Ok_S	DB ' Ok ',0
Var_S	DB '^V',0
Inc_S	DB '^I',0

NoRd1_S	DB "Can't read the disk in drive ^V:",0
NoRd2_S	DB "Press ENTER to try again, ESC to abort,",0
NoRd3_S	DB "or enter a different drive letter here ^r^V^r:",0

Key_S	DB '      '  ;  0
	DB 'Help  '  ;  1
	DB 'Menu  '  ;  2
	DB 'View  '  ;  3
	DB 'Edit  '  ;  4
	DB 'Copy  '  ;  5
	DB 'RenMov'  ;  6
	DB 'Mkdir '  ;  7
	DB 'Delete'  ;  8
	DB 'PullDn'  ;  9
	DB 'Quit  '  ; 10
	DB 'SavSet'  ; 11
	DB 'PullDn'  ; 12
	DB 'Left  '  ; 13
	DB 'Right '  ; 14
	DB 'View..'  ; 15
	DB 'Edit..'  ; 16
	DB 'DirSiz'  ; 17
	DB 'Find  '  ; 18
	DB 'Histry'  ; 19
	DB 'EGA Ln'  ; 20
	DB 'Tree  '  ; 21
	DB 'ASCII '  ; 22
	DB 'Hex   '  ; 23
	DB 'Wrap  '  ; 24
	DB 'Unwrap'  ; 25
	DB 'Search'  ; 26
	DB 'Save  '  ; 27
	DB 'Save..'  ; 28
	DB 'Q&Save'  ; 29
	DB 'Memory'  ; 30
	DB 'Main  '  ; 31
	DB 'Label '  ; 32
	DB 'Rescan'  ; 33

PtMnu_S	DB 0FFh,4,'Left',0FFh,4,'Files',0FFh,4,'Commands'
	DB 0FFh,4,'Options',0FFh,4,'Right',0FFh,31,0

Brief_S	DB '^rName',0FFh,9,'Name',0FFh,9,'Name',0
Full_S	DB '^rName',0FFh,8,'Size',0FFh,5,'Date',0FFh,4,'Time',0

Ext_S	DB 'com','exe','bat'

Tree_S	DB ' Tree ',0
Info_S	DB ' Info ',0
Progs_S	DB ' Progs',0

UpDir	DB 'UP--DIR'
SubDir	DB 'SUB-DIR'

FilDi_S	DB ' files and  directoriesy'

Mask_S	DB '\*.*',0
Ext_F	DB 'VC.EXT',0

Tree_F	DB '\TREEINFO.NCD',0
TreBeg	DB 'PNCI',0
Scan1_S	DB 'Scanning the directory',0
Scan2_S	DB 'structure on drive ^V:',0
Scan3_S	DB '0',0
Scan4_S	DB 'Saving the',0
Scan5_S	DB 'directory information...',0

DrIn_F	DB 'DIRINFO',0

BytIn_S	DB ' bytes in  selected files'

PtIn1_S	DB "^r^V^r Bytes ^I",0
PtIn2_S	DB "Memory",0
PtIn3_S	DB "Free",0
PtIn4_S	DB "Volume in drive ^r^W:^r ^I^r^V",0
PtInA_S	DB "is ",0
PtInB_S	DB "has no label",0
PtIn5_S	DB "^r^V^r ^I on drive ^r^W:",0
PtIn6_S	DB "total bytes",0
PtIn7_S	DB "bytes free",0
PtIn8_S	DB "^r^V^r files uses ^r^W^r bytes in",0
PtIn9_S	DB " No `dirinfo' file in this directory",0

Init_F	DB 'VC.INI',0

Fant0_S	DB ' Change drive ',0
Fant1_S	DB 'Insert diskette for drive ^V:',0
OkCan_S	DB ' Ok',0FFh,3,'Cancel',0

ChTr0_S	DB ' Choose Directory ',0
ChTr1_S	DB 'Reading directory tree...',0
	DB 'Speed search: ^r',0FFh,12,0

; --- continue vc.asm

;SECTION .DATA?  ; Same effect as .CONST.
	ABSOLUTE $
	RESB ($$-$)&1  ; EVEN

LastPtr:

; __END__
