	MOV	AH,9
	MOV	DX,OFFSET AMSG
	INT	21H
	MOV	AH,30H
	INT	21H
	TEST	AL,AL
	JNZ	MAIN
	MOV	AH,9
	MOV	DX,OFFSET DOSERR
	INT	21H
	INT	20H
MAIN:	CALL	CMDLIN
	JNC	CORE
	MOV	AH,9
	MOV	DX,OFFSET USAGE
	INT	21H
	INT	20H
CORE:	MOV	DX,OFFSET DOTASM
	MOV	BX,OFFSET DOTCOM
	MOV	AX,[FUNC]
	TEST	AX,8080H
	JZ	CORE1
	XCHG	DX,BX
CORE1:	MOV	SI,DX
	MOV	DI,OFFSET INFILE
	CLC
	CALL	ADDEXT
	MOV	SI,BX
	MOV	DI,OFFSET OUTFILE
	CLC
	CALL	ADDEXT
	MOV	SI,OFFSET DOTLST
	MOV	DI,OFFSET LSTFILE
	CLC
	CALL	ADDEXT
	MOV	DI,OFFSET TEMP
	MOV	SI,OFFSET INM
	CALL	WRM
	MOV	SI,OFFSET INFILE
	CALL	WRM
	CALL	CRLF
PROC:	CALL	PROCF
	JC	OUTC
	MOV	AX,[ERRS]
	TEST	AX,AX
	JNZ	ERRORS
	MOV	AX,[FUNC]
	PUSH	AX
	XOR	AL,AL
	XCHG	AL,AH
	MOV	[FUNC],AX
	TEST	AX,AX
	POP	AX
	JNZ	PROC
	MOV	DI,OFFSET TEMP
	MOV	SI,OFFSET OUTM
	CALL	WRM
	MOV	SI,OFFSET OUTFILE
	CALL	WRM
	TEST	AL,40H
	JZ	OUTC
	MOV	AX,202CH
	STOSW
	MOV	SI,OFFSET LSTFILE
	CALL	WRM
OUTC:	CALL	CRLF
	INT	20H
ERRORS:	TEST	BYTE PTR [FUNC],8
	JZ	ERR0
	MOV	AH,41H
	MOV	DX,OFFSET OUTFILE+1
	INT	21H
ERR0:	INT	20H
CMDLIN:	XOR	AL,AL
	MOV	[INFILE],AL
	MOV	[OUTFILE],AL
	MOV	[LSTFILE],AL
	MOV	AX,0E05H
	MOV	[FUNC],AX
	MOV	SI,81H
PARAM:	MOV	DI,OFFSET TEMP
	CALL	GETFN
	JZ	PARAM2
	MOV	AX,[TEMP]
	CMP	AX,2F02H
	JZ	PARAM5
	MOV	DI,OFFSET INFILE
	MOV	AL,[DI]
	TEST	AL,AL
	JZ	PARAM1
	MOV	DI,OFFSET OUTFILE
	MOV	AL,[DI]
	TEST	AL,AL
	JZ	PARAM1
	MOV	DI,OFFSET LSTFILE
	MOV	AL,[DI]
	TEST	AL,AL
	JZ	PARAM1
PARAM0:	STC
	RET
PARAM1:	PUSH	SI
	MOV	SI,OFFSET TEMP
	MOVSB
	DEC	SI
	CALL	WRM
	MOVSB
	POP	SI
	JMP	SHORT PARAM
PARAM2:	MOV	AL,[INFILE]
	TEST	AL,AL
	JZ	PARAM0
	MOV	DI,OFFSET OUTFILE
	CALL	PARAM3
	MOV	DI,OFFSET LSTFILE
PARAM3:	MOV	AL,[DI]
	TEST	AL,AL
	JNZ	PARAM4
	MOV	SI,OFFSET INFILE
	PUSH	DI
	MOVSB
	DEC	SI
	CALL	WRM
	POP	DI
	STC
	CALL	ADDEXT
PARAM4:	CLC
	RET
PARAM5:	MOV	AL,[TEMP+2]
	CMP	AL,44H
	JZ	PDIS
	CMP	AL,4CH
	JZ	PLST
	STC
	RET
PDIS:	MOV	AX,8CH
	MOV	[FUNC],AX
	JMP	PARAM
PLST:	MOV	AX,[FUNC]
	TEST	AH,AH
	JZ	PARAM
	OR	AH,40H
	MOV	[FUNC],AX
	JMP	PARAM
GETFN:	XOR	CX,CX
	PUSH	DI
	INC	DI
	CLD
GETFN1:	LODSB
	CMP	AL,0DH
	JZ	GETFN0
	CMP	AL,21H
	JC	GETFN2
	CMP	AL,61H
	JC	GETFN3
	CMP	AL,7BH
	JNC	GETFN3
	AND	AL,0DFH
GETFN3:	INC	CX
	STOSB
	JMP	SHORT GETFN1
GETFN2:	TEST	CX,CX
	JZ	GETFN1
GETFN0:	DEC	SI
	MOV	[DI],CH
	POP	DI
	MOV	[DI],CL
	TEST	CX,CX
	RET
ADDEXT:	LAHF
	CLD
	MOV	BP,DI
	XOR	CH,CH
	MOV	CL,[DI]
	INC	DI
	MOV	AL,2EH
	REPNZ	SCASB
	JNZ	ADDXT2
	SAHF
	JNC	ADDXT0
	DEC	DI
ADDXT2:	SAHF
	JC	ADDXT1
	STOSB
	CALL	WRM
ADDXT1:	MOV	[DI],CH
	MOV	AX,DI
	SUB	AX,BP
	DEC	AX
	MOV	DI,BP
	STOSB
ADDXT0:	RET
CRLF:	MOV	AX,0A0DH
	STOSW
	MOV	AX,924H
	STOSB
	MOV	DX,OFFSET TEMP
	INT	21H
	RET
PROCF:	TEST	BYTE PTR [FUNC],4
	JNZ	PROCF0
	RET
PROCF0:	XOR	AX,AX
	MOV	[PC],AX
	MOV	[USIZE],AX
	MOV	[ERRS],AX
	MOV	[INCLEV],AX
	TEST	BYTE PTR [FUNC],2
	JNZ	NOCSYM
	MOV	[SYMBS],AX
NOCSYM:	INC	AH
	MOV	[VORG],AX
	MOV	[STK+2],SP
	TEST	BYTE PTR [FUNC],40H
	JZ	PROCF1
	MOV	AH,3CH
	XOR	CX,CX
	MOV	SI,OFFSET LSTFILE
	MOV	DX,SI
	INC	DX
	INT	21H
	JC	FFAIL
	MOV	[LSTHDL],AX
PROCF1:	TEST	BYTE PTR [FUNC],8
	JZ	PROCF2
	MOV	AH,3CH
	XOR	CX,CX
	MOV	SI,OFFSET OUTFILE
	MOV	DX,SI
	INC	DX
	INT	21H
	JC	FFAIL
	MOV	[OUTHDL],AX
PROCF2:	MOV	SI,OFFSET INFILE
	CALL	INCF
	JC	FFAIL
ASMFL:	CALL	RD
	JC	ASMF0
	CALL	ASM
	JNC	ASMNER
	CALL	CRLF
	TEST	BYTE PTR [FUNC],40H
	JZ	ASMNER
	DEC	DI
	MOV	SI,OFFSET LSTFILE
	MOV	AH,40H
	MOV	CX,DI
	MOV	DX,OFFSET TEMP
	SUB	CX,DX
	MOV	BX,[LSTHDL]
	INT	21H
	JC	FFAIL
ASMNER:	CALL	LLST
	CALL	WR
	JNC	ASMFL
ASMCL:	CALL	DECF
	JNC	ASMCL
	CALL	CLOSF
	MOV	SI,OFFSET OUTFILE
FFAIL:	MOV	DI,OFFSET TEMP
	PUSH	SI
	MOV	SI,OFFSET EMB
	CALL	WRM
	POP	SI
	CALL	WRM
	STC
	RET
ASMF0:	CALL	DECF
	JNC	ASMFL
CLOSF:	TEST	BYTE PTR [FUNC],40H
	JZ	CLOSF1
	MOV	AH,3EH
	MOV	BX,[LSTHDL]
	INT	21H
CLOSF1:	TEST	BYTE PTR [FUNC],8
	JZ	CLOSF0
	MOV	AH,3EH
	MOV	BX,[OUTHDL]
	INT	21H
CLOSF0:	CLC
	RET
LLST:	TEST	BYTE PTR [FUNC],40H
	JZ	LLST0
	MOV	SI,OFFSET OUTPUT
	MOV	DI,OFFSET TEMP
	CLD
	XOR	AH,AH
	LODSB
	MOV	BP,AX
	MOV	AL,[INPUT]
	XCHG	AX,CX
	JCXZ	LLST3
	PUSH	CX
	CALL	LLWB
	MOV	CX,20H
	MOV	AX,DI
	SUB	AX,OFFSET TEMP
	SUB	CX,AX
	SHR	CX,1
	SHR	CX,1
	SHR	CX,1
	MOV	AL,9
	REPZ	STOSB
	POP	CX
	PUSH	SI
	MOV	SI,OFFSET INPUT+1
	REPZ	MOVSB
	POP	SI
LLST2:	MOV	DX,OFFSET TEMP
	MOV	CX,DI
	MOV	AH,40H
	MOV	BX,[LSTHDL]
	SUB	CX,DX
	INT	21H
	TEST	BP,BP
	JZ	LLST0
	MOV	DI,OFFSET TEMP
LLST3:	CALL	LLWB
	MOV	AX,0A0DH
	STOSW
	JMP	SHORT LLST2
LLST0:	RET
LLWB:	MOV	AX,[PC+2]
	ADD	AX,[VORG]
	PUSH	AX
	MOV	AL,AH
	CALL	HALX
	POP	AX
	CALL	HALX
	MOV	AL,20H
	STOSB
	TEST	BP,BP
	JZ	LLWB0
	MOV	CX,8
	CMP	CX,BP
	JC	LLWB1
	MOV	CX,BP
LLWB1:	ADD	[PC+2],CX
	SUB	BP,CX
LLWB2:	LODSB
	CALL	HALX
	LOOP	LLWB2
LLWB0:	RET
CALF:	TEST	BYTE PTR [FUNC],4
	JZ	CALF0
	MOV	AX,[INCLEV]
	TEST	AX,AX
	JZ	CALF0
	DEC	AX
	XCHG	AL,AH
	SHR	AX,1
	SHR	AX,1
	ADD	AX,OFFSET INCLEV+2
	CLC
	RET
CALF0:	STC
	RET
INCF:	INC	WORD PTR [INCLEV]
	CALL	CALF
	JC	INCF0
	MOV	DI,3D00H
	MOV	DX,SI
	XCHG	AX,DI
	INC	DX
	INT	21H
	JC	INCF0
	STOSW
	XOR	AX,AX
	STOSW
	MOVSB
	DEC	SI
	CALL	WRM
	CLC
	RET
INCF0:	DEC	WORD PTR [INCLEV]
	STC
	RET
DECF:	CALL	CALF
	JC	DECF0
	MOV	SI,AX
	MOV	AH,3EH
	MOV	BX,[SI]
	INT	21H
	DEC	WORD PTR [INCLEV]
	CLC
DECF0:	RET
RD:	CALL	CALF
	JC	RD0
	MOV	BX,AX
	INC	WORD PTR [BX+2]
	MOV	BX,[BX]
	MOV	DX,OFFSET INPUT+1
	TEST	BYTE PTR [FUNC],80H
	JZ	RD1
	MOV	AX,4200H
	XOR	CX,CX
	PUSH	DX
	MOV	DX,[PC]
	PUSH	BX
	INT	21H
	POP	BX
	POP	DX
	JC	RD0
	MOV	AH,3FH
	MOV	CL,8
	INT	21H
	JC	RD0
	MOV	[INPUT],AL
	CMP	AL,1
RD0:	RET
RD1:	MOV	AH,3FH
	MOV	CX,7EH
	MOV	DI,DX
	PUSH	BX
	INT	21H
	POP	BX
	JC	RD0
	CMP	AL,1
	JC	RD0
	XCHG	AX,CX
	MOV	AL,0DH
	CLD
	REPNZ	SCASB
	JNZ	RD0
	MOV	AL,0AH
	JCXZ	RD2
	DEC	CX
	SCASB
	JZ	RD3
	DEC	DI
	INC	CX
RD2:	STOSB
RD3:	MOV	AX,OFFSET INPUT
	XCHG	AX,DI
	SUB	AX,DI
	DEC	AX
	STOSB
	XOR	AX,AX
	SUB	AX,CX
	JZ	RD0
	CWD
	MOV	CX,4201H
	XCHG	AX,DX
	XCHG	AX,CX
	INT	21H
	RET
WR:	OR	BYTE PTR [OUTPUT],0
	JZ	WR0
	TEST	BYTE PTR [FUNC],8
	JZ	WR4
	OR	WORD PTR [USIZE],0
	JZ	WR3
	MOV	DI,OFFSET TEMP
	MOV	CX,80H
	XOR	AL,AL
	CLD
	REPZ	STOSB
WR1:	MOV	CX,80H
	CMP	[USIZE],CX
	JNC	WR2
	MOV	CX,[USIZE]
WR2:	MOV	AH,40H
	MOV	DX,OFFSET TEMP
	MOV	BX,[OUTHDL]
	INT	21H
	SUB	[USIZE],CX
	JA	WR1
WR3:	MOV	AH,40H
	XOR	CH,CH
	MOV	CL,[OUTPUT]
	MOV	DX,OFFSET OUTPUT+1
	MOV	BX,[OUTHDL]
	INT	21H
	JC	WR0
WR4:	XOR	AX,AX
	MOV	[USIZE],AX
WR0:	RET
ASM:	MOV	AX,[PC]
	MOV	[PC+2],AX
	XOR	AX,AX
	MOV	[OUTPUT],AL
	MOV	[STK],SP
	MOV	DI,OFFSET FLAGS
	MOV	CX,14
	CLD
	REPZ	STOSB
	MOV	SI,OFFSET INPUT
	LODSB
	TEST	AL,AL
	JZ	DSA0
	TEST	BYTE PTR [FUNC],80H
	JZ	ASM1
	MOV	DI,OFFSET OUTPUT+1
DSAS:	MOV	SP,[STK]
	MOV	AL,9
	STOSB
	LODSB
	MOV	[OPCODE],AL
	AND	AL,1
	MOV	CL,4
	SHL	AL,CL
	MOV	[WADJ],AL
	MOV	AL,[OPCODE]
	XOR	AH,AH
	SHL	AX,1
	SHL	AX,1
	ADD	AX,OFFSET BIN86
	PUSH	SI
	MOV	SI,AX
	LODSW
	PUSH	SI
	MOV	SI,AX
	XOR	AH,AH
	LODSB
	MOV	CX,AX
	JCXZ	NOMNEM
	REPZ	MOVSB
	MOV	AL,9
	STOSB
NOMNEM:	POP	SI
	LODSW
	POP	SI
	CALL	AX
	CALL	ENDL
	CALL	LSPR
	MOV	AX,SI
	SUB	AX,OFFSET INPUT+1
	ADD	[PC],AX
	MOV	AX,DI
	SUB	AX,OFFSET OUTPUT+1
	MOV	[OUTPUT],AL
DSA0:	CLC
	RET
ASM1:	CALL	CC
	MOV	BP,SI
ASML:	MOV	SP,[STK]
	CALL	CC
	JZ	ASM0
	MOV	DI,OFFSET I8086
	CALL	SL
	JC	NOGOOD
	MOV	[OPCODE],AL
	OR	BYTE PTR [FLAGS],20H
	XOR	AL,AL
	XCHG	AL,AH
	SHL	AX,1
	ADD	AX,OFFSET IHDL
	MOV	BX,AX
	CALL	[BX]
	CALL	CC
	JNZ	BADF9
ASM0:	MOV	AL,[FLAGS]
	TEST	AL,0FFH
	JNZ	WRB
	JMP	SHORT WRUPD
NOGOOD:	CALL	SCREG
	JC	BAD
	CALL	GSPR
	JC	BADFC
	CALL	OUTW
	JMP	SHORT ASML
BAD:	CMP	BP,SI
	JC	BADF3
	MOV	DI,OFFSET SYMBS
	CALL	SL
	JC	BADD
	TEST	BYTE PTR [FUNC],1
	JZ	BADX
	MOV	AL,0AH
	JMP	FAIL
BADD:	MOV	AL,BL
	STOSB
	MOV	CX,BX
	REPZ	MOVSB
	MOV	AX,[PC]
	ADD	AX,[VORG]
	STOSW
	INC	WORD PTR [SYMBS]
BADX:	CALL	CC
	JZ	BADF3
	CMP	AL,3AH
	JNZ	ASML
	INC	SI
	JMP	SHORT ASML
BADF3:	MOV	AL,3
	JMP	FAIL
BADFC:	MOV	AL,0CH
	JMP	FAIL
BADF9:	MOV	AL,9
	JMP	FAIL
WRB:	CALL	OUTW
WRUPD:	XOR	AH,AH
	MOV	AL,[OUTPUT]
	ADD	[PC],AX
	CLC
	RET
OUTW:	CLD
	PUSH	SI
	XOR	AH,AH
	MOV	AL,[OUTPUT]
	MOV	DI,OFFSET OUTPUT+1
	ADD	DI,AX
	MOV	SI,OFFSET SEGPREF
	MOV	DL,[FLAGS]
	LODSB
	TEST	DL,40H
	JZ	NOSPR
	STOSB
NOSPR:	LODSB
	TEST	DL,20H
	JZ	NOOPC
	STOSB
NOOPC:	LODSB
	TEST	DL,10H
	JZ	NOMOD
	STOSB
NOMOD:	LODSW
	TEST	DL,8
	JZ	WNDISP
	TEST	DL,4
	JZ	WBDISP
	STOSB
	MOV	AL,AH
WBDISP:	STOSB
WNDISP:	LODSW
	TEST	DL,2
	JZ	WNIMM
	TEST	DL,1
	JZ	WBIMM
	STOSB
	MOV	AL,AH
WBIMM:	STOSB
WNIMM:	MOV	AX,DI
	SUB	AX,OFFSET OUTPUT+1
	MOV	[OUTPUT],AL
	XOR	AL,AL
	MOV	[FLAGS],AL
	POP	SI
	RET
CC:	XOR	BX,BX
CCM:	MOV	AL,[BX+SI]
	CMP	AL,0
	JZ	CCT
	CMP	AL,0DH
	JZ	CCT
	CMP	AL,21H
	JC	CCK
	CMP	AL,22H
	JZ	CCQ
	CMP	AL,27H
	JZ	CCQ
	CMP	AL,2CH
	JZ	CCK
	CMP	AL,30H
	JC	CCS
	CMP	AL,3AH
	JC	CCL
	CMP	AL,3BH
	JZ	CCT
	CMP	AL,41H
	JC	CCS
	CMP	AL,5BH
	JC	CCL
	CMP	AL,5FH
	JZ	CCL
	CMP	AL,61H
	JC	CCS
	CMP	AL,7BH
	JNC	CCS
	AND	AL,0DFH
	MOV	[BX+SI],AL
CCL:	INC	BX
	JMP	SHORT CCM
CCQ:	TEST	BX,BX
	JNZ	CCT
CCW:	INC	BX
	CMP	[BX+SI],AL
	JNZ	CCW
	INC	BX
CCT:	MOV	AL,[SI]
	TEST	BX,BX
	RET
CCS:	TEST	BX,BX
	JNZ	CCT
	INC	BX
	JMP	SHORT CCT
CCK:	TEST	BX,BX
	JNZ	CCT
	INC	SI
	JMP	SHORT CCM
RN:	SUB	AL,48
	JC	RN9
	CMP	AL,10
	JNC	RN9
	XOR	AH,AH
	CMP	BX,1
	JC	RN9
	JA	RN1
	INC	SI
	RET
RN1:	CLD
	PUSH	DX
	PUSH	BX
	PUSH	SI
	DEC	BX
	XOR	DX,DX
	MOV	AL,[BX+SI]
	MOV	CL,4
	CMP	AL,48
	JC	RN0
	CMP	AL,58
	JC	RN5
	CMP	AL,72
	JZ	RN6
	CMP	AL,79
	JZ	RN8
	CMP	AL,81
	JZ	RN4
	CMP	AL,66
	JZ	RN2
RN0:	POP	SI
	POP	BX
	POP	DX
RN9:	STC
	RET
RN2:	DEC	CX
RN4:	DEC	CX
RN8:	DEC	CX
RN6:	SHL	DX,CL
	LODSB
	SUB	AL,48
	JC	RN0
	CMP	AL,10
	JC	RN7
	SUB	AL,7
RN7:	OR	DL,AL
	DEC	BX
	JNZ	RN6
RN3:	MOV	AX,DX
	POP	SI
	POP	BX
	ADD	SI,BX
	POP	DX
	RET
RN5:	LODSB
	SUB	AL,48
	JC	RN0
	CMP	AL,10
	JNC	RN0
	SHL	DX,1
	MOV	CX,DX
	SHL	DX,1
	SHL	DX,1
	ADD	DX,CX
	ADD	DX,AX
	DEC	BX
	JNS	RN5
	JMP	SHORT RN3
SL:	XOR	CH,CH
	MOV	AX,[DI]
SL1:	INC	DI
	INC	DI
	TEST	AX,AX
	JNZ	SL2
	STC
	RET
SL2:	MOV	CL,[DI]
	INC	DI
	CMP	CL,BL
	JNZ	SL3
	PUSH	SI
	CLD
	REPZ	CMPSB
	POP	SI
	JNZ	SL3
	ADD	SI,BX
	MOV	AX,[DI]
	CLC
	RET
SL3:	ADD	DI,CX
	DEC	AX
	JMP	SHORT SL1
WDA:	MOV	CX,10
WN:	CLD
	CMP	AX,CX
	JNC	WN1
	CMP	AX,10
	JNC	WN1
	OR	AL,30H
	STOSB
	RET
WN1:	MOV	SI,DI
WN2:	XOR	DX,DX
	DIV	CX
	XCHG	AX,DX
	CMP	AL,10
	SBB	AL,105
	DAS
	STOSB
	XCHG	AX,DX
	TEST	AX,AX
	JNZ	WN2
	CMP	DL,58
	JC	WN5
	MOV	AL,48
	STOSB
WN5:	MOV	CX,DI
	SUB	CX,SI
	SHR	CX,1
	JZ	WN0
	SUB	DI,CX
	ADD	SI,CX
WN4:	DEC	SI
	MOV	AL,[DI]
	XCHG	[SI],AL
	STOSB
	LOOP	WN4
WN0:	RET
AA:	TEST	AX,AX
	JNS	AANS
	CMP	AX,0FF80H
	RET
AANS:	CMP	AX,80H
	CMC
	RET
SW:	CALL	CC
	JZ	SW0
SW1:	MOV	DI,OFFSET I8086
	PUSH	SI
	CALL	SL
	POP	SI
	JC	SW2
	CMP	AH,15H
	JNZ	SW2
	ADD	SI,BX
	TEST	AX,AX
	RET
SW2:	XOR	AX,AX
	RET
SW0:	STC
	RET
SIZAL:	TEST	BYTE PTR [FUNC],1
	JNZ	SIZAL0
	TEST	BYTE PTR [WADJ],0FFH
	JNZ	SIZAL0
	TEST	AH,AH
	JZ	SIZAL0
	CALL	AA
	JNC	SIZAL0
	MOV	AL,7
	JMP	FAIL
SIZAL0:	RET
RA:	CALL	CC
	CALL	SCREG
	JNC	RAR
	CALL	BORW
	JNC	RAD
	CALL	RE
	AND	DH,3
	JNZ	RAIW	
	MOV	CL,2
	TEST	AH,AH
	JZ	RAIB
	CALL	AA
	JNC	RAIB
RAIW:	MOV	CL,3
RAIB:	XOR	AL,AL
	JMP	WARG0
RAR:	CALL	GSPR
	JNC	RAD
	MOV	DX,203H
	CMP	AL,10H
	JNC	RARS
	MOV	DL,1
	CMP	AL,8
	JNC	RARS
	MOV	DH,1
RARS:	AND	AL,7
	XCHG	DH,AL
	JMP	WARG
RAD:	XOR	CX,CX
	MOV	DX,8002H
RADM:	XOR	DH,80H
RADP:	AND	DH,0BFH
	INC	SI
RADL:	CALL	CC
	JZ	RAD8
	CMP	AL,5DH
	JZ	RADX
	CMP	AL,2BH
	JZ	RADP
	CMP	AL,2DH
	JZ	RADM
	PUSH	CX
	CALL	SCREG
	POP	CX
	JNC	RADR
	PUSH	CX
	CALL	GV
	POP	CX
	JC	RA1
	ADD	[DISP],AX
	JMP	SHORT RADL
RADR:	MOV	CL,1
	CMP	AL,11
	JZ	BXD
	CMP	AL,13
	JZ	BPD
	CMP	AL,14
	JZ	SID
	CMP	AL,15
	JZ	DID
	CALL	GSPR
	JNC	RADL
RAD2:	MOV	AL,2
	JMP	FAIL
RAD8:	MOV	AL,8
	JMP	FAIL
SID:	SHL	CL,1
DID:	SHL	CL,1
BPD:	SHL	CL,1
BXD:	TEST	CH,CL
	JNZ	RAD2
	TEST	DH,80H
	JNZ	RAD2
	OR	CH,CL
	OR	DH,40H
	JMP	SHORT RADL
RA1:	MOV	AL,1
	JMP	FAIL
RADX:	TEST	DH,DH
	JZ	RAD8
	INC	SI
	MOV	AL,CH
	MOV	BX,OFFSET RM
	XLATB
	TEST	AL,0F0H
	JNZ	RAD2
	XCHG	AL,DH
	TEST	AL,3
	JNZ	RADW
	CMP	DH,0EH
	JZ	RADW
	XOR	CL,CL
	MOV	AX,[DISP]
	TEST	AX,AX
	JZ	RADB
	MOV	CL,8
	CALL	AA
	JNC	RADB
RADW:	MOV	CL,0CH
RADB:	MOV	AL,[WADJ]
WARG0:	OR	[FLAGS],CL
WARG:	MOV	CL,4
	TEST	BYTE PTR [ARGS],0FH
	JZ	NARGS
	ROL	AL,CL
	ROL	DX,CL
NARGS:	OR	[ARGS+2],AL
	OR	[ARGS],DX
	MOV	AX,[ARGS]
	RET
RE:	MOV	DX,8004H
	DEC	SI
RESM:	XOR	DH,80H
RESP:	AND	DH,0BFH
	INC	SI
REL:	CALL	CC
	JZ	REE
	CMP	AL,2BH
	JZ	RESP
	CMP	AL,2DH
	JZ	RESM
	CALL	GV
	JC	REE
	ADD	[IMM],AX
	JMP	SHORT REL
REE:	TEST	DH,40H
	JZ	RE8
	MOV	AX,[IMM]
	RET
RE8:	MOV	AL,8
	JMP	FAIL
BORW:	CMP	AL,5BH
	JZ	BRACP
	CALL	SW
	JZ	BORW0
SPTR:	CMP	AL,8
	JNC	BORW0
	MOV	[WADJ],AL
	CALL	SW
	JC	BORW8
	CMP	AL,11H
	JNZ	SPTRR
	CALL	CC
	JZ	BORW8
	CALL	SCREG
	JC	SPTRR
	CALL	GSPR
	JC	BORW1
SPTRR:	CALL	CC
	CMP	AL,5BH
	JNZ	BORW1
BRACP:	RET
BORW0:	STC
	RET
BORW1:	MOV	AL,1
	JMP	FAIL
BORW8:	MOV	AL,8
	JMP	FAIL
GSPR:	CMP	AL,16
	JC	GSPR0
	PUSH	AX
	CALL	CC
	CMP	AL,3AH
	POP	AX
	JNZ	GSPR0
	AND	AL,3
	SHL	AL,1
	SHL	AL,1
	SHL	AL,1
	OR	AL,26H
	MOV	[SEGPREF],AL
	MOV	AL,[FLAGS]
	TEST	AL,40H
	JNZ	GSPR0
	OR	AL,40H
	MOV	[FLAGS],AL
	INC	SI
	CLC
	RET
GSPR0:	STC
	RET
SCREG:	CLD
	LODSW
	CMP	BX,2
	JNZ	SCREG0
	MOV	DI,OFFSET REGS
	MOV	CX,14H
	REPNZ	SCASW
	JNZ	SCREG0
	MOV	AL,13H
	SUB	AL,CL
	CLC
	RET
SCREG0:	DEC	SI
	DEC	SI
	STC
	RET
GV:	TEST	DH,40H
	JNZ	GVA
	CALL	CC
	JZ	GVA
	CMP	AL,24H
	JZ	GVC
	CMP	AL,22H
	JZ	GVQ
	CMP	AL,27H
	JZ	GVQ
	CALL	RN
	JC	GVL
GVV:	TEST	DH,80H
	JZ	GVX
	NEG	AX
GVX:	AND	DH,7FH
	OR	DH,40H
	CLC
	RET
GVA:	STC
	RET
GVC:	OR	DH,2
	MOV	AX,[PC]
	ADD	AX,[VORG]
	ADD	SI,BX
	JMP	SHORT GVV
GVQ:	PUSH	WORD PTR [SI+1]
	ADD	SI,BX
	MOV	AL,BL
	CMP	AL,3
	JC	GV8
	CMP	AL,4
	JA	GV7
	POP	AX
	JNC	GVV
	XOR	AH,AH
	JMP	SHORT GVV
GV7:	MOV	AL,7
	JMP	FAIL
GV8:	MOV	AL,8
	JMP	FAIL
G15H:	MOV	AL,0CH
	JMP	FAIL
GVL:	CALL	SCREG
	JNC	G15H
	OR	DH,1
	CALL	SW1
	JZ	GVL1
	CMP	AL,10H
	JNZ	G15H
	CALL	CC
	JZ	GV8
GVL1:	MOV	DI,OFFSET SYMBS
	CALL	SL
	JNC	GVV
	TEST	BYTE PTR [FUNC],2
	JZ	GVC
	MOV	AL,4
	JMP	FAIL
WA:	PUSH	AX
	MOV	AL,[ARGS+2]
	MOV	AH,AL
	MOV	CL,4
	SHR	AH,CL
	AND	AX,0F0FH
	JZ	WAZ
	TEST	AL,AL
	JZ	WALZ
	TEST	AH,AH
	JZ	WAHZ
	CMP	AL,AH
	JZ	WAHZ
WA0:	MOV	AL,6
	JMP	FAIL
WALZ:	CMP	AL,AH
	JZ	WAZ
	MOV	AL,AH
WAHZ:	CMP	AL,2
	JA	WA0
	DEC	AX
WAZ:	MOV	[WADJ],AL
	TEST	BYTE PTR [FLAGS],2
	JZ	WAE
WAX:	TEST	AL,AL
	JZ	WAB
	OR	[FLAGS],AL
	POP	AX
	RET
WAB:	MOV	AX,[IMM]
	CALL	SIZAL
	AND	BYTE PTR [FLAGS],0FEH
WAE:	POP	AX
	RET
MMODRM:	OR	BYTE PTR [FLAGS],10H
	MOV	AX,[ARGS]
	MOV	CL,4
	CMP	AL,11H
	JZ	MREGL
	CMP	AL,12H
	JZ	MMEMR
	CMP	AL,13H
	JZ	MREGL
	CMP	AL,21H
	JZ	MMEML
	CMP	AL,23H
	JZ	MMEML
	CMP	AL,31H
	JZ	MREGR
	CMP	AL,32H
	JZ	MMEMR
	AND	AX,0F0FH
	CMP	AL,1
	JZ	MREGR
	CMP	AL,2
	JZ	MMEMR
	MOV	AX,[ARGS]
	ROR	AX,CL
	AND	AX,0F0FH
	CMP	AL,1
	JZ	MREGR
	CMP	AL,2
	JZ	MMEMR
	RET
MMEML:	ROR	AH,CL
MMEMR:	MOV	AL,AH
	PUSH	AX
	AND	AX,7007H
	ROR	AH,1
	OR	AL,AH
	OR	[MODRM],AL
	POP	AX
	TEST	AL,8
	JNZ	MME
	TEST	BYTE PTR [FLAGS],8
	JZ	MM0
	MOV	AL,40H
	TEST	BYTE PTR [FLAGS],4
	JZ	MM8
	SHL	AL,1
MM8:	OR	[MODRM],AL
	RET
MM0:	AND	AL,7
	CMP	AL,6
	JNZ	MME
	OR	BYTE PTR [FLAGS],8
	OR	BYTE PTR [MODRM],40H
MME:	RET
MREGL:	ROR	AH,CL
MREGR:	MOV	AL,AH
	ROR	AH,1
	AND	AX,3807H
	OR	AL,AH
	OR	AL,0C0H
	OR	[MODRM],AL
	RET
FAIL:	MOV	SP,[STK]
	CLD
	INC	WORD PTR [ERRS]
	MOV	DI,OFFSET TEMP
	XOR	AH,AH
	PUSH	AX
	SHL	AX,1
	ADD	AX,OFFSET ERRM
	MOV	SI,AX
	MOV	SI,[SI]
	TEST	BYTE PTR [FUNC],4
	JZ	FAIL0
	CALL	CALF
	JC	FAIL0
	PUSH	DX
	PUSH	SI
	MOV	SI,AX
	ADD	SI,4
	CALL	WRM
	MOV	SI,202CH
	XCHG	AX,SI
	INC	SI
	INC	SI
	STOSW
	LODSW
	CALL	WDA
	MOV	AX,203AH
	STOSW
	POP	SI
	POP	DX
FAIL0:	CALL	WRM
	POP	AX
	MOV	SI,OFFSET INCFILE
	CMP	AL,5
	JZ	FAIL5
	CMP	AL,0BH
	JZ	FAILW
	STC
	RET	
FAIL5:	MOV	AX,[IMM]
	TEST	AX,AX
	JNS	FAILNS
	NEG	AX
	DEC	AX
FAILNS:	SUB	AX,7FH
	PUSH	AX
	CALL	WDA
	POP	AX
	MOV	SI,OFFSET BYTEM
FAILW:	CALL	WRM
	STC
	RET
WRM:	MOV	CL,[SI]
	XOR	CH,CH
	INC	SI
	CLD
	REPZ	MOVSB
	RET
G1:	CALL	RA
	CALL	RA
	CALL	WA
	CMP	AL,11H
	JZ	G1RM
	CMP	AL,12H
	JZ	G1MR
	CMP	AL,21H
	JZ	G1RM
	CMP	AL,41H
	JZ	G1RI
	CMP	AL,42H
	JZ	G1MI
	XOR	AL,AL
	JMP	FAIL
G1RI:	AND	AH,7
	JNZ	G1MI
	MOV	AL,[WADJ]
	OR	AL,4
	OR	[OPCODE],AL
	RET
G1MI:	MOV	AL,80H
	XCHG	AL,[OPCODE]
	OR	[MODRM],AL
	MOV	AX,[IMM]
	CALL	AA
	JC	G1MR
	AND	BYTE PTR [FLAGS],0FEH
	TEST	BYTE PTR [WADJ],0FFH
	JZ	G1MR
G1RM:	OR	BYTE PTR [OPCODE],2
G1MR:	MOV	AL,[WADJ]
	OR	[OPCODE],AL
	JMP	MMODRM
G2:	CALL	RA
	CALL	WA
	MOV	AL,[OPCODE]
	MOV	[MODRM],AL
	MOV	AL,[WADJ]
	OR	AL,0D0H
	MOV	[OPCODE],AL
	CALL	CC
	JZ	G2N
	CMP	BX,2
	JZ	G2R
G2V:	CALL	RE
	CMP	AX,1
	JZ	G2N
	XOR	AL,AL
	JMP	FAIL
G2R:	MOV	AX,[REGS+2]
	CMP	AX,[SI]
	JNZ	G2V
	OR	BYTE PTR [OPCODE],2
	ADD	SI,BX
G2N:	JMP	MMODRM
G3:	CALL	RA
	OR	BYTE PTR [OPCODE],0
	JNZ	G3S
	CALL	RA
G3S:	CALL	WA
	CMP	AL,1
	JZ	G3R
	CMP	AL,2
	JZ	G3R
	CMP	AL,11H
	JZ	G3RM
	CMP	AL,12H
	JZ	G3RM
	CMP	AL,21H
	JZ	G3RM
	CMP	AL,41H
	JZ	G3RA
	CMP	AL,42H
	JZ	G3R
	XOR	AL,AL
	JMP	FAIL
G3RM:	MOV	AH,84H
	JMP	SHORT G3E
G3RA:	TEST	AH,7
	JZ	G3A
G3R:	MOV	AH,0F6H
G3E:	MOV	AL,[WADJ]
	OR	AL,AH
	XCHG	AL,[OPCODE]
	OR	[MODRM],AL
	JMP	MMODRM
G3A:	MOV	AL,[WADJ]
	OR	AL,0A8H
	MOV	[OPCODE],AL
	RET
G4:	CALL	RA
	CALL	WA
	CMP	AL,1
	JZ	G4R
	CMP	AL,2
	JZ	G4M
	CMP	AL,3
	JZ	G4S
	XOR	AL,AL
	JMP	FAIL
G4R:	MOV	AL,[ARGS+2]
	CMP	AL,2
	JC	G4M
	MOV	AL,[OPCODE]
	AND	AL,18H
	OR	AL,40H
	OR	AL,AH
	MOV	[OPCODE],AL
	RET
G4M:	MOV	AL,[OPCODE]
	CMP	AL,38H
	MOV	AX,8FH
	JZ	G4P
	MOV	AL,[ARGS+2]
	TEST	AL,AL
	MOV	AL,[WADJ]
	JNZ	G4W
	INC	AX
G4W:	OR	AL,0FEH
	MOV	AH,[OPCODE]
G4P:	MOV	[OPCODE],AX
	JMP	MMODRM
G4S:	DEC	CX
	SHL	AH,CL
	MOV	AL,[OPCODE]
	SHR	AL,CL
	AND	AL,1
	OR	AL,AH
	OR	AL,6
	MOV	[OPCODE],AL
	RET
G5:	CALL	RE
	OR	BYTE PTR [FLAGS],2
	TEST	BYTE PTR [FUNC],2
	JZ	G5X
	SUB	AX,[PC]
	SUB	AX,[VORG]
	DEC	AX
	DEC	AX
	MOV	[IMM],AX
	CALL	AA
	JNC	G5X
	MOV	AL,5
	JMP	FAIL
G5X:	RET
G6:	CALL	SW
	JC	G6F8
	JZ	G6U
	PUSH	AX
	CALL	SW
	JC	G6F8
	JZ	G6P
	CMP	AL,11H
	JNZ	G6F0
G6P:	POP	AX
	CMP	AL,2
	JZ	G6N
	CMP	AL,3
	JZ	G6F
	CMP	AL,8
	JZ	G6S
	CMP	AL,9
	JZ	G6N
	CMP	AL,0AH
	JNZ	G6F0
G6F:	OR	BYTE PTR [MODRM],8
G6N:	CALL	RA
	CMP	AL,1
	JZ	G6R
	CMP	AL,2
	JNZ	G6F0
G6R:	MOV	CL,0FFH
	XCHG	CL,[OPCODE]
	MOV	AL,10H
	SHL	AL,CL
	OR	[MODRM],AL
	JMP	MMODRM
G6S:	MOV	AL,0EBH
	XCHG	AL,[OPCODE]
	TEST	AL,AL
	JZ	G6F1
	JMP	G5
G6F0:	XOR	AL,AL
	JMP	FAIL
G6F1:	MOV	AL,1
	JMP	FAIL
G6F8:	MOV	AL,8
	JMP	FAIL
G6U:	CALL	RA
	CMP	AL,1
	JZ	G6R
	CMP	AL,2
	JZ	G6R
	CMP	AL,4
	JNZ	G6F0
	CALL	CC
	JNZ	G6IF
	MOV	AX,[IMM]
	SUB	AX,[PC]
	SUB	AX,[VORG]
	SUB	AX,3
	MOV	[IMM],AX
	OR	BYTE PTR [FLAGS],3
	OR	BYTE PTR [OPCODE],0E8H
	RET
G6IF:	CMP	AL,3AH
	JNZ	G6F1
	INC	SI
	XOR	AX,AX
	XCHG	AX,[IMM]
	PUSH	AX
	CALL	RE
	MOV	[DISP],AX
	POP	WORD PTR [IMM]
	OR	BYTE PTR [FLAGS],0FH
	MOV	AL,[OPCODE]
	TEST	AL,AL
	JZ	G6I
	MOV	BYTE PTR [OPCODE],0EAH
	RET
G6I:	MOV	BYTE PTR [OPCODE],9AH
	RET
G7:	CALL	CC
	JNZ	G7A
	MOV	AX,0AH
	MOV	[IMM],AX
G7B:	OR	BYTE PTR [FLAGS],2
	RET
G7A:	CALL	RE
	TEST	AH,AH
	JZ	G7B
	MOV	AL,7
	JMP	FAIL
G8:	CALL	RA
	CALL	RA
	CMP	AL,21H
	JNZ	G8F
	JMP	MMODRM
G9:	CALL	RA
	CALL	RA
	CALL	WA
	CMP	AL,11H
	JZ	G9RM
	CMP	AL,12H
	JZ	G9MR
	CMP	AL,13H
	JZ	G9SR
	CMP	AL,21H
	JZ	G9RM
	CMP	AL,23H
	JZ	G9SR
	CMP	AL,31H
	JZ	G9RS
	CMP	AL,32H
	JZ	G9RS
	CMP	AL,41H
	JZ	G9RI
	CMP	AL,42H
	JZ	G9MI
G8F:	XOR	AL,AL
	JMP	FAIL
G9RI:	MOV	AL,[WADJ]
	DEC	CX
	SHL	AL,CL
	OR	AL,AH
	OR	AL,0B0H
	MOV	[OPCODE],AL
	RET
G9MI:	MOV	AL,[WADJ]
	OR	AL,0C6H
	JMP	SHORT G9E
G9RM:	MOV	AL,2
	CMP	AH,0E0H
	JNZ	G9NA
G9A:	XOR	AL,2
	OR	AL,0A0H
	OR	AL,[WADJ]
	MOV	[OPCODE],AL
	MOV	AL,[FLAGS]
	AND	AL,0E3H
	OR	AL,3
	MOV	[FLAGS],AL
	MOV	AX,[DISP]
	MOV	[IMM],AX
	RET
G9MR:	XOR	AL,AL
	CMP	AH,0EH
	JZ	G9A
G9NA:	OR	AL,[WADJ]
	OR	AL,[OPCODE]
	JMP	SHORT G9E
G9RS:	MOV	AL,8CH
	JMP	SHORT G9E
G9SR:	MOV	AL,8EH
G9E:	MOV	[OPCODE],AL
	JMP	MMODRM
G0AH:	CALL	CC
	JZ	G0
	CALL	OUTW
	JMP	ASML
G0:	RET
G0BH2:	OR	BYTE PTR [OPCODE],8
G0BH:	CALL	SW
	JC	G0BH0
	JZ	G0BH1
	CMP	AL,9
	JZ	G0BH
	CMP	AL,10
	JZ	G0BH2
G0BH1:	CALL	RE
	OR	BYTE PTR [FLAGS],3
	DEC	BYTE PTR [OPCODE]
G0BH0:	RET
G0CH:	CALL	RE
	CMP	AX,3
	JZ	G0CH3
	OR	AH,AH
	JNZ	G0CHF
	OR	BYTE PTR [FLAGS],2
	RET
G0CH3:	DEC	BYTE PTR [OPCODE]
	RET
G0CHF:	MOV	AL,7
	JMP	FAIL
G0DH:	PUSH	SI
	MOV	SI,BP
	CALL	CC
	MOV	DI,OFFSET SYMBS
	CALL	SL
	POP	SI
	PUSH	DI
	CALL	RE
	POP	DI
	STOSW
	XOR	AL,AL
	MOV	[FLAGS],AL
	RET
G0EH:	CALL	RA
	CALL	RA
	CMP	AL,14H
	JZ	G0EHRM
	CMP	AL,24H
	JZ	G0EHRM
	XOR	AL,AL
	JMP	FAIL
G0EHRM:	MOV	AX,[IMM]
	CMP	AX,3FH
	JA	G0EHF
	MOV	AH,AL
	DEC	CX
	ROR	AL,CL
	AND	AX,707H
	ROL	AH,CL
	OR	[OPCODE],AX
	AND	BYTE PTR [FLAGS],0FCH
	JMP	MMODRM
G0EHF:	MOV	AL,7
	JMP	FAIL
G0FH:	XOR	AL,AL
	MOV	[FLAGS],AL
	TEST	BYTE PTR [FUNC],4
	JNZ	G0FH1
	RET
G0FH1:	CALL	CC
	JZ	G0FHF8
	CMP	AL,22H
	JZ	G0FHQ
	CMP	AL,27H
	JNZ	G0FHG
G0FHQ:	INC	SI
	SUB	BX,2
	JNA	G0FHF8
	XOR	AL,AL
	MOV	[BX+SI],AL
G0FHG:	MOV	DI,OFFSET INCFILE
	CALL	GETFN
	PUSH	SI
	MOV	SI,OFFSET INCFILE
	CALL	INCF
	POP	SI
	JC	G0FHF
	RET
G0FHF:	MOV	AL,0BH
	JMP	FAIL
G0FHF8:	MOV	AL,8
	JMP	FAIL
G10H:	CALL	RA
	CALL	RA
	CALL	WA
	CMP	AL,11H
	JZ	G10HR
	CMP	AL,12H
	JZ	G10HM
	CMP	AL,21H
	JZ	G10HM
	XOR	AL,AL
	JMP	FAIL
G10HR:	MOV	AL,[WADJ]
	TEST	AL,0FFH
	JZ	G10HM
	MOV	AL,AH
	TEST	AL,0FH
	JZ	G10HAR
	TEST	AL,0F0H
	JZ	G10HRA
G10HM:	MOV	AL,[WADJ]
	OR	AL,86H
	MOV	[OPCODE],AL
	JMP	MMODRM
G10HAR:	SHR	AL,CL
G10HRA:	OR	AL,90H
	MOV	[OPCODE],AL
	RET
G11H:	CALL	RA
	CALL	RA
	AND	BYTE PTR [FLAGS],0FEH
	MOV	CH,[ARGS+2]
	CMP	AL,41H
	JZ	G11HI
	CMP	AL,14H
	JZ	G11HO
	OR	BYTE PTR [OPCODE],8
	CMP	AX,2011H
	JZ	G11HI
	CMP	AX,211H
	JZ	G11HO
G11HF:	XOR	AL,AL
	JMP	FAIL
G11HO:	SHR	CH,CL
G11HI:	MOV	AL,CH
	AND	AL,0FH
	CMP	AL,2
	JC	G11H0
	INC	BYTE PTR [OPCODE]
G11H0:	RET
G12H:	TEST	BYTE PTR [FUNC],4
	JZ	G12H0
	MOV	SP,[STK+2]
	JMP	ASMF0
G12H0:	RET
G13H:	CALL	RE
	MOV	[VORG],AX
	XOR	AL,AL
	MOV	[FLAGS],AL
	RET
G14H:	XOR	AX,AX
	MOV	BP,AX
	MOV	[FLAGS],AL
	MOV	DI,OFFSET OUTPUT+1
G14HL:	CLD
	CALL	CC
	JZ	G14H0
	CMP	AL,3FH
	JZ	G14HU
	CALL	G14HS
	CMP	AL,22H
	JZ	G14HQ
	CMP	AL,27H
	JZ	G14HQ
	PUSH	DI
	CALL	RE
	POP	DI
	XOR	AX,AX
	XCHG	AX,[IMM]
	MOV	CL,[OPCODE]
	DEC	CX
	JNZ	G14HNZ
	CALL	SIZAL
G14HNZ:	MOV	DX,1
	SHL	DX,CL
	STOSB
	TEST	CL,CL
	JZ	G14HB
	MOV	AL,AH
	STOSB
G14HB:	SUB	DX,2
	JNA	G14HL
	MOV	CX,DX
	RCL	AH,1
	SALC
	REPZ	STOSB
	JMP	SHORT G14HL
G14HQ:	CMP	BYTE PTR [OPCODE],1
	JA	G14HF
	MOV	AH,AL
	MOV	CX,BX
	SUB	CX,2
	JNA	G14HF
	INC	SI
	REPZ	MOVSB
	LODSB
	CMP	AL,AH
	JZ	G14HL
G14HF:	MOV	AL,1
	JMP	FAIL
G14HU:	MOV	CL,[OPCODE]
	MOV	AX,1
	DEC	CX
	SHL	AX,CL
	ADD	BP,AX
	INC	SI
	JMP	SHORT G14HL
G14H0:	MOV	AX,DI
	SUB	AX,OFFSET OUTPUT+1
	MOV	[OUTPUT],AL
	ADD	[USIZE],BP
	ADD	[PC],BP
	RET
G14HS:	XOR	CX,CX
	XCHG	CX,BP
	JCXZ	G14HS0
	PUSH	AX
	XOR	AL,AL
	REPZ	STOSB
	POP	AX
G14HS0:	RET
G16H:	CALL	CC
	CMP	AL,3AH
	JNZ	G16H1
	INC	SI
	AND	BYTE PTR [FLAGS],0DFH
	RET
G16H1:	CALL	RE
	ADD	[USIZE],AX
	ADD	[PC],AX
	XOR	AL,AL
	MOV	[FLAGS],AL
	RET
G17H:	MOV	AX,[PC]
	AND	AL,1
	JNZ	G17H0
	MOV	[FLAGS],AL
G17H0:	RET
HALX:	MOV	AH,AL
	SHR	AH,1
	SHR	AH,1
	SHR	AH,1
	SHR	AH,1
	AND	AL,0FH
	CMP	AL,0AH
	JC	HALX1
	ADD	AL,7
HALX1:	XCHG	AL,AH
	CMP	AL,0AH
	JC	HALX2
	ADD	AL,7
HALX2:	ADD	AX,3030H
	STOSW
	RET
RELBD:	CMP	BYTE PTR [OPCODE],0EBH
	JNZ	NOTJMP
	PUSH	SI
	MOV	SI,OFFSET _SHORT+1
	MOVSW
	MOVSW
	MOVSB
	POP	SI
	MOV	AL,20H
	STOSB
NOTJMP:	MOV	AX,2B24H
	STOSW
	LODSB
	ADD	AL,2
	JNS	RELBNM
	DEC	DI
RELBNM:	CBW
WHAS:	TEST	AX,AX
	JNS	WHA
	NEG	AX
	MOV	BYTE PTR [DI],2DH
	INC	DI
WHA:	PUSH	SI
	PUSH	AX
	MOV	CX,16
	CALL	WN
	POP	AX
	POP	SI
	CMP	AX,9
	JNA	WHA0
	MOV	AL,48H
	STOSB
WHA0:	RET
WREG:	CLD
	PUSH	SI
	MOV	SI,AX
	SHR	SI,1
	SHR	SI,1
	AND	SI,0EH
	ADD	SI,OFFSET REGS
	ADD	SI,[WADJ]
	MOVSW
	POP	SI
	RET
PSRD:	MOV	AL,[OPCODE]
WSR:	SHR	AL,1
	SHR	AL,1
	AND	AX,6
	ADD	AX,OFFSET REGS+20H
	XCHG	AX,SI
	MOVSW
	XCHG	AX,SI
	RET
WSPR:	CLD
	XOR	AL,AL
	XCHG	AL,[SEGPREF]
	TEST	AL,AL
	JZ	WSPR0
	CALL	WSR
	MOV	AL,3AH
	STOSB
WSPR0:	RET
LSPR:	XOR	DL,DL
	XCHG	DL,[SEGPREF]
	TEST	DL,DL
	JZ	LSPR0
	CLD
	PUSH	DI
	MOV	DI,OFFSET TEMP+1
	MOV	AL,9
	STOSB
	MOV	AL,DL
	CALL	WSR
	MOV	AL,3AH
	STOSB
	MOV	BP,OFFSET TEMP+1
	CALL	TABS
	MOV	AX,[PC]
	ADD	AX,[VORG]
	PUSH	AX
	MOV	AL,AH
	CALL	HALX
	POP	AX
	CALL	HALX
	MOV	AL,20H
	STOSB
	MOV	AL,DL
	CALL	HALX
	MOV	AX,0A0DH
	STOSW
	POP	CX
	PUSH	SI
	MOV	SI,OFFSET OUTPUT+1
	SUB	CX,SI
	REPZ	MOVSB
	MOV	CX,DI
	MOV	SI,OFFSET TEMP+1
	SUB	CX,SI
	MOV	DI,OFFSET OUTPUT+1
	REPZ	MOVSB
	POP	SI
LSPR0:	RET
GRP:	PUSH	SI
	MOV	AL,[SI]
	SHR	AL,1
	SHR	AL,1
	AND	AX,0EH
	ADD	AX,DX
	MOV	SI,AX
	MOV	SI,[SI]
	CALL	WRM
	POP	SI
	MOV	AL,9
	STOSB
	LODSB
WPTR:	CMP	AL,0C0H
	JNC	WDISP
	PUSH	AX
	PUSH	SI
	MOV	SI,OFFSET _WORD+1
	TEST	BYTE PTR [WADJ],0FFH
	JNZ	WSELF
	MOV	SI,OFFSET _BYTE+1
WSELF:	MOVSW
	MOVSW
	MOV	SI,OFFSET _PTR+1
	MOV	AL,20H
	STOSB
	MOVSW
	MOVSB
	STOSB
	POP	SI
	POP	AX
WDISP:	CMP	AL,0C0H
	JC	WDRM
	PUSH	SI
	MOV	SI,AX
	AND	SI,7
	SHL	SI,1
	ADD	SI,OFFSET REGS
	ADD	SI,[WADJ]
	MOVSW
	POP	SI
	RET
WDRM:	PUSH	AX
	CALL	WSPR
	MOV	AL,5BH
	STOSB
	POP	AX
	PUSH	AX
	AND	AL,0C7H
	CMP	AL,6
	JNZ	WDR
	LODSW
	CALL	WHA
	JMP	SHORT WDX
WDR:	PUSH	SI
	MOV	BX,OFFSET _DISP
	AND	AL,7
	XLATB
	MOV	AH,AL
	AND	AX,0F00FH
	SHR	AH,1
	SHR	AH,1
	SHR	AH,1
	SHL	AL,1
	XOR	DX,DX
	XCHG	DL,AH
	ADD	AX,OFFSET REGS
	MOV	SI,AX
	MOVSW
	TEST	DL,DL
	JZ	WD1R
	MOV	AL,2BH
	STOSB
	MOV	SI,OFFSET REGS
	ADD	SI,DX
	MOVSW
WD1R:	POP	SI
	POP	AX
	PUSH	AX
	CMP	AL,40H
	JC	WDX
	CMP	AL,80H
	JC	WDD8
	LODSW
	JMP	SHORT WDD
WDD8:	LODSB
	CBW
WDD:	TEST	AX,AX
	JS	WDM
	JZ	WDX
	MOV	BYTE PTR [DI],2BH
	INC	DI
WDM:	CALL	WHAS
WDX:	MOV	AL,5DH
	STOSB
	POP	AX
	RET
TABS:	CLD
	PUSH	SI
	MOV	SI,BP
	MOV	CX,DI
	SUB	CX,BP
	JNA	TABS0
	XOR	AH,AH
TABS1:	LODSB
	CMP	AL,9
	JNZ	TABS2
	MOV	AL,AH
	AND	AL,7
	XOR	AL,0FFH
	ADD	AL,8
	ADD	AH,AL
TABS2:	INC	AH
	LOOP	TABS1
TABS3:	MOV	AL,9
	MOV	CL,5
	SHR	AH,1
	SHR	AH,1
	SHR	AH,1
	SUB	CL,AH
	JNA	TABS4
	REPZ	STOSB
TABS4:	MOV	AL,3BH
	STOSB
TABS0:	POP	SI
	RET
SINGD:	DEC	DI
	RET
SPREFD:	MOV	AL,[OPCODE]
	MOV	[SEGPREF],AL
	DEC	DI
	JMP	DSAS
ENDL:	MOV	BP,OFFSET OUTPUT+1
	CALL	TABS
	MOV	AX,[PC]
	MOV	BP,SI
	SUB	BP,BX
	MOV	SI,BX
	TEST	BYTE PTR [SEGPREF],0FFH
	JZ	SKSPR
	INC	AX
	INC	SI
	DEC	BP
SKSPR:	MOV	[PC+2],AX
	CALL	LLWB
	MOV	AX,0A0DH
	STOSW
	RET
ACCID:	XOR	AL,AL
	CALL	WREG
	JMP	G03DT
MRD:	LODSB
	PUSH	AX
	CALL	WDISP
	MOV	AL,2CH
	STOSB
	POP	AX
	JMP	WREG
RWMD:	MOV	AL,10H
	MOV	[WADJ],AL
RMD:	LODSB
	CALL	WREG
	PUSH	AX
	MOV	AL,2CH
	STOSB
	POP	AX
	JMP	WDISP
MSD:	MOV	AL,10H
	MOV	[WADJ],AL
	LODSB
	PUSH	AX
	CALL	WDISP
	MOV	AL,2CH
	STOSB
	POP	AX
	JMP	WSR
SMD:	MOV	AL,10H
	MOV	[WADJ],AL
	LODSB
	PUSH	AX
	CALL	WSR
	MOV	AL,2CH
	STOSB
	POP	AX
	JMP	WDISP
ACCRD:	MOV	AX,[REGS+10H]
	STOSW
	MOV	AL,2CH
	STOSB
REGWD:	MOV	AL,10H
	MOV	[WADJ],AL
	MOV	AL,[OPCODE]
	OR	AL,0C0H
	JMP	WDISP
ACCMD:	XOR	AL,AL
	CALL	WREG
	MOV	AL,2CH
	STOSB
	CALL	WSPR
	MOV	AL,5BH
	STOSB
	LODSW
	CALL	WHA
	MOV	AL,5DH
	STOSB
	RET
MACCD:	CALL	WSPR
	MOV	AL,5BH
	STOSB
	LODSW
	CALL	WHA
	MOV	AX,2C5DH
	STOSW
	XOR	AL,AL
	JMP	WREG
RMID:	LODSB
	CALL	WPTR
	JMP	G03DT
RIMMD:	MOV	AL,[OPCODE]
	PUSH	SI
	AND	AX,0FH
	SHL	AL,1
	PUSH	AX
	ADD	AX,OFFSET REGS
	MOV	SI,AX
	MOVSW
	POP	AX
	AND	AL,10H
	POP	SI
	MOV	[WADJ],AL
	JMP	G03DT
RELWD:	MOV	AX,2B24H
	STOSW
	LODSW
	ADD	AX,3
	JNS	RELWNM
	DEC	DI
RELWNM:	JMP	WHAS
AAMD:	LODSB
	CMP	AL,0AH
	JZ	AAMD0
	XOR	AH,AH
	CALL	WHA
AAMD0:	RET
ESCD:	MOV	AL,[OPCODE]
	MOV	AH,[SI]
	MOV	CL,3
	ROR	AH,CL
	AND	AX,707H
	ROL	AL,CL
	OR	AL,AH
	XOR	AH,AH
	CALL	WHA
	MOV	AL,2CH
	STOSB
	LODSB
	JMP	WDISP
INTD:	LODSB
	XOR	AH,AH
	JMP	WHA
INT3D:	MOV	AL,33H
	STOSB
	RET
RETFD:	PUSH	SI
	MOV	SI,OFFSET _FAR+1
	MOVSW
	MOVSB
	POP	SI
	TEST	BYTE PTR [OPCODE],1
	JNZ	NORET
	MOV	AL,20H
	STOSB
RETD:	LODSW
	CALL	WHA
NORET:	RET
ADIOD:	MOV	AX,[WADJ]
	ADD	AX,OFFSET REGS
	PUSH	SI
	MOV	SI,AX
	LODSW
	POP	SI
	MOV	DX,[REGS+14H]
	TEST	BYTE PTR [OPCODE],2
	JZ	ADIOD0
	XCHG	AX,DX
ADIOD0:	STOSW
	MOV	AL,2CH
	STOSB
	MOV	AX,DX
	STOSW
	RET
IBAPD:	LODSB
	XOR	AH,AH
	CALL	WHA
	MOV	AL,2CH
	STOSB
	MOV	AL,0C0H
	JMP	WDISP
SEGOFD:	LODSW
	PUSH	AX
	LODSW
	CALL	WHA
	MOV	AL,3AH
	STOSB
	POP	AX
	JMP	WHA
G02D:	MOV	DX,OFFSET _G02D
	CALL	GRP
	MOV	AL,2CH
	STOSB
	TEST	BYTE PTR [OPCODE],2
	JZ	G02D1
	MOV	AX,[REGS+2]
	STOSW
	RET
G02D1:	MOV	AL,31H
	STOSB
	RET
G03D:	MOV	DX,OFFSET _G03D
	CALL	GRP
	TEST	AL,30H
	JZ	G03DT
	RET
G01D:	MOV	DX,OFFSET _G01D
	CALL	GRP
G03DT:	MOV	AL,2CH
	STOSB
	CBW
	LODSB
	TEST	BYTE PTR [WADJ],0FFH
	JZ	G03D0
	CBW
	CMP	BYTE PTR [OPCODE],83H
	JZ	G03D0
	DEC	SI
	LODSW
G03D0:	JMP	WHA
G04D:	PUSH	SI
	LODSB
	SHR	AL,1
	SHR	AL,1
	AND	AX,0EH
	PUSH	AX
	ADD	AX,OFFSET _G04D
	MOV	SI,AX
	MOV	SI,[SI]
	CALL	WRM
	MOV	AL,9
	STOSB
	POP	AX
	POP	SI
	SHR	AL,1
	CMP	AL,7
	JZ	INVD
	CMP	AL,5
	JZ	G04DF
	CMP	AL,4
	JZ	DISPD
	CMP	AL,3
	JZ	G04DF
	CMP	AL,2
	JZ	DISPD
	LODSB
	JMP	WPTR
G04DF:	MOV	AL,[SI]
	PUSH	SI
	MOV	SI,OFFSET _FAR+1
	MOV	AL,20H
	MOVSW
	MOVSB
	STOSB
	POP	SI
DISPD:	LODSB
	JMP	WDISP
INVD:	MOV	AL,[OPCODE]
	XOR	AH,AH
	JMP	WHA
I8086	DW	134
_AAA	DB	3,"AAA",37H,0
_AAD	DB	3,"AAD",0D5H,7
_AAM	DB	3,"AAM",0D4H,7
_AAS	DB	3,"AAS",3FH,0
_ADC	DB	3,"ADC",10H,1
_ADD	DB	3,"ADD",0,1
_AND	DB	3,"AND",20H,1
_BYTE	DB	4,"BYTE",1,15H
_CALL	DB	4,"CALL",0,6
_CBW	DB	3,"CBW",98H,0
_CLC	DB	3,"CLC",0F8H,0
_CLD	DB	3,"CLD",0FCH,0
_CLI	DB	3,"CLI",0FAH,0
_CMC	DB	3,"CMC",0F5H,0
_CMP	DB	3,"CMP",38H,1
_CMPSB	DB	5,"CMPSB",0A6H,0
_CMPSW	DB	5,"CMPSW",0A7H,0
_CWD	DB	3,"CWD",99H,0
_DAA	DB	3,"DAA",27H,0
_DAS	DB	3,"DAS",2FH,0
_DB	DB	2,"DB",1,14H
	DB	2,"DD",3,14H
_DEC	DB	3,"DEC",8,4
_DIV	DB	3,"DIV",30H,3
	DB	2,"DS",0,16H
	DB	2,"DW",2,14H
_DWORD	DB	5,"DWORD",3,15H
	DB	3,"END",0,12H
	DB	3,"EQU",0,0DH
	DB	4,"EVEN",90H,17H
_ESC	DB	3,"ESC",0D8H,0EH
_FAR	DB	3,"FAR",0AH,15H
_HLT	DB	3,"HLT",0F4H,0
_IDIV	DB	4,"IDIV",38H,3
_IMUL	DB	4,"IMUL",28H,3
_IN	DB	2,"IN",0E4H,11H
_INC	DB	3,"INC",0,4
	DB	7,"INCLUDE",0,0FH
_INT	DB	3,"INT",0CDH,0CH
_INTO	DB	4,"INTO",0CEH,0
_IRET	DB	4,"IRET",0CFH,0
_JA	DB	2,"JA",77H,5
	DB	3,"JAE",73H,5
	DB	2,"JB",72H,5
	DB	3,"JBE",76H,5
_JC	DB	2,"JC",72H,5
_JCXZ	DB	4,"JCXZ",0E3H,5
	DB	2,"JE",74H,5
_JG	DB	2,"JG",7FH,5
	DB	3,"JGE",7DH,5
_JL	DB	2,"JL",7CH,5
	DB	3,"JLE",7EH,5
_JMP	DB	3,"JMP",1,6
_JNA	DB	3,"JNA",76H,5
	DB	4,"JNAE",72H,5
	DB	3,"JNB",73H,5
	DB	4,"JNBE",77H,5
_JNC	DB	3,"JNC",73H,5
	DB	3,"JNE",75H,5
_JNG	DB	3,"JNG",7EH,5
	DB	4,"JNGE",7CH,5
_JNL	DB	3,"JNL",7DH,5
	DB	4,"JNLE",7FH,5
_JNO	DB	3,"JNO",71H,5
_JNP	DB	3,"JNP",7BH,5
_JNS	DB	3,"JNS",79H,5
_JNZ	DB	3,"JNZ",75H,5
_JO	DB	2,"JO",70H,5
_JP	DB	2,"JP",7AH,5
	DB	3,"JPE",7AH,5
	DB	3,"JPO",7BH,5
_JS	DB	2,"JS",78H,5
_JZ	DB	2,"JZ",74H,5
_LAHF	DB	4,"LAHF",9FH,0
_LDS	DB	3,"LDS",0C5H,8
_LEA	DB	3,"LEA",8DH,8
_LES	DB	3,"LES",0C4H,8
_LOCK	DB	4,"LOCK",0F0H,0AH
_LODSB	DB	5,"LODSB",0ACH,0
_LODSW	DB	5,"LODSW",0ADH,0
_LOOP	DB	4,"LOOP",0E2H,5
	DB	5,"LOOPE",0E1H,5
	DB	6,"LOOPNE",0E0H,5
_LOOPNZ	DB	6,"LOOPNZ",0E0H,5
_LOOPZ	DB	5,"LOOPZ",0E1H,5
_MOV	DB	3,"MOV",88H,9
_MOVSB	DB	5,"MOVSB",0A4H,0
_MOVSW	DB	5,"MOVSW",0A5H,0
_MUL	DB	3,"MUL",20H,3
_NEAR	DB	4,"NEAR",9,15H
_NEG	DB	3,"NEG",18H,3
_NOP	DB	3,"NOP",90H,0
_NOT	DB	3,"NOT",10H,3
_OFFSET	DB	6,"OFFSET",10H,15H
_OR	DB	2,"OR",8,1
	DB	3,"ORG",0,13H
_OUT	DB	3,"OUT",0E6H,11H
_POP	DB	3,"POP",38H,4
_POPF	DB	4,"POPF",9DH,0
_PTR	DB	3,"PTR",11H,15H
_PUSH	DB	4,"PUSH",30H,4
_PUSHF	DB	5,"PUSHF",9CH,0
_RCL	DB	3,"RCL",10H,2
_RCR	DB	3,"RCR",18H,2
	DB	3,"REP",0F3H,0AH
	DB	4,"REPE",0F3H,0AH
	DB	5,"REPNE",0F2H,0AH
_REPNZ	DB	5,"REPNZ",0F2H,0AH
_REPZ	DB	4,"REPZ",0F3H,0AH
_RET	DB	3,"RET",0C3H,0BH
_ROL	DB	3,"ROL",0,2
_ROR	DB	3,"ROR",8,2
_SAHF	DB	4,"SAHF",9EH,0
_SAL	DB	3,"SAL",30H,2
_SALC	DB	4,"SALC",0D6H,0
_SAR	DB	3,"SAR",38H,2
_SBB	DB	3,"SBB",18H,1
_SCASB	DB	5,"SCASB",0AEH,0
_SCASW	DB	5,"SCASW",0AFH,0
_SHL	DB	3,"SHL",20H,2
_SHORT	DB	5,"SHORT",8,15H
_SHR	DB	3,"SHR",28H,2
_STC	DB	3,"STC",0F9H,0
_STD	DB	3,"STD",0FDH,0
_STI	DB	3,"STI",0FBH,0
_STOSB	DB	5,"STOSB",0AAH,0
_STOSW	DB	5,"STOSW",0ABH,0
_SUB	DB	3,"SUB",28H,1
_TEST	DB	4,"TEST",0,3
_WAIT	DB	4,"WAIT",9BH,0
_WORD	DB	4,"WORD",2,15H
_XCHG	DB	4,"XCHG",86H,10H
_XLATB	DB	5,"XLATB",0D7H,0
_XOR	DB	3,"XOR",30H,1
	EVEN
BIN86	DW	_ADD,MRD,_ADD,MRD
	DW	_ADD,RMD,_ADD,RMD
	DW	_ADD,ACCID,_ADD,ACCID
	DW	_PUSH,PSRD,_POP,PSRD
	DW	_OR,MRD,_OR,MRD
	DW	_OR,RMD,_OR,RMD
	DW	_OR,ACCID,_OR,ACCID
	DW	_PUSH,PSRD,_POP,PSRD
	DW	_ADC,MRD,_ADC,MRD
	DW	_ADC,RMD,_ADC,RMD
	DW	_ADC,ACCID,_ADC,ACCID
	DW	_PUSH,PSRD,_POP,PSRD
	DW	_SBB,MRD,_SBB,MRD
	DW	_SBB,RMD,_SBB,RMD
	DW	_SBB,ACCID,_SBB,ACCID
	DW	_PUSH,PSRD,_POP,PSRD
	DW	_AND,MRD,_AND,MRD
	DW	_AND,RMD,_AND,RMD
	DW	_AND,ACCID,_AND,ACCID
	DW	_GRP,SPREFD,_DAA,SINGD
	DW	_SUB,MRD,_SUB,MRD
	DW	_SUB,RMD,_SUB,RMD
	DW	_SUB,ACCID,_SUB,ACCID
	DW	_GRP,SPREFD,_DAS,SINGD
	DW	_XOR,MRD,_XOR,MRD
	DW	_XOR,RMD,_XOR,RMD
	DW	_XOR,ACCID,_XOR,ACCID
	DW	_GRP,SPREFD,_AAA,SINGD
	DW	_CMP,MRD,_CMP,MRD
	DW	_CMP,RMD,_CMP,RMD
	DW	_CMP,ACCID,_CMP,ACCID
	DW	_GRP,SPREFD,_AAS,SINGD
	DW	_INC,REGWD,_INC,REGWD
	DW	_INC,REGWD,_INC,REGWD
	DW	_INC,REGWD,_INC,REGWD
	DW	_INC,REGWD,_INC,REGWD
	DW	_DEC,REGWD,_DEC,REGWD
	DW	_DEC,REGWD,_DEC,REGWD
	DW	_DEC,REGWD,_DEC,REGWD
	DW	_DEC,REGWD,_DEC,REGWD
	DW	_PUSH,REGWD,_PUSH,REGWD
	DW	_PUSH,REGWD,_PUSH,REGWD
	DW	_PUSH,REGWD,_PUSH,REGWD
	DW	_PUSH,REGWD,_PUSH,REGWD
	DW	_POP,REGWD,_POP,REGWD
	DW	_POP,REGWD,_POP,REGWD
	DW	_POP,REGWD,_POP,REGWD
	DW	_POP,REGWD,_POP,REGWD
	DW	_DB,INVD,_DB,INVD
	DW	_DB,INVD,_DB,INVD
	DW	_DB,INVD,_DB,INVD
	DW	_DB,INVD,_DB,INVD
	DW	_DB,INVD,_DB,INVD
	DW	_DB,INVD,_DB,INVD
	DW	_DB,INVD,_DB,INVD
	DW	_DB,INVD,_DB,INVD
	DW	_JO,RELBD,_JNO,RELBD
	DW	_JC,RELBD,_JNC,RELBD
	DW	_JZ,RELBD,_JNZ,RELBD
	DW	_JNA,RELBD,_JA,RELBD
	DW	_JS,RELBD,_JNS,RELBD
	DW	_JP,RELBD,_JNP,RELBD
	DW	_JL,RELBD,_JNL,RELBD
	DW	_JNG,RELBD,_JG,RELBD
	DW	_GRP,G01D,_GRP,G01D
	DW	_GRP,G01D,_GRP,G01D
	DW	_TEST,RMD,_TEST,RMD
	DW	_XCHG,RMD,_XCHG,RMD
	DW	_MOV,MRD,_MOV,MRD
	DW	_MOV,RMD,_MOV,RMD
	DW	_MOV,MSD,_LEA,RMD
	DW	_MOV,SMD,_POP,DISPD
	DW	_NOP,SINGD,_XCHG,ACCRD
	DW	_XCHG,ACCRD,_XCHG,ACCRD
	DW	_XCHG,ACCRD,_XCHG,ACCRD
	DW	_XCHG,ACCRD,_XCHG,ACCRD
	DW	_CBW,SINGD,_CWD,SINGD
	DW	_CALL,SEGOFD,_WAIT,SINGD
	DW	_PUSHF,SINGD,_POPF,SINGD
	DW	_SAHF,SINGD,_LAHF,SINGD
	DW	_MOV,ACCMD,_MOV,ACCMD
	DW	_MOV,MACCD,_MOV,MACCD
	DW	_MOVSB,SINGD,_MOVSW,SINGD
	DW	_CMPSB,SINGD,_CMPSW,SINGD
	DW	_TEST,ACCID,_TEST,ACCID
	DW	_STOSB,SINGD,_STOSW,SINGD
	DW	_LODSB,SINGD,_LODSW,SINGD
	DW	_SCASB,SINGD,_SCASW,SINGD
	DW	_MOV,RIMMD,_MOV,RIMMD
	DW	_MOV,RIMMD,_MOV,RIMMD
	DW	_MOV,RIMMD,_MOV,RIMMD
	DW	_MOV,RIMMD,_MOV,RIMMD
	DW	_MOV,RIMMD,_MOV,RIMMD
	DW	_MOV,RIMMD,_MOV,RIMMD
	DW	_MOV,RIMMD,_MOV,RIMMD
	DW	_MOV,RIMMD,_MOV,RIMMD
	DW	_DB,INVD,_DB,INVD
	DW	_RET,RETD,_RET,SINGD
	DW	_LES,RWMD,_LDS,RMD
	DW	_MOV,RMID,_MOV,RMID
	DW	_DB,INVD,_DB,INVD
	DW	_RET,RETFD,_RET,RETFD
	DW	_INT,INT3D,_INT,INTD
	DW	_INTO,SINGD,_IRET,SINGD
	DW	_GRP,G02D,_GRP,G02D
	DW	_GRP,G02D,_GRP,G02D
	DW	_AAM,AAMD,_AAD,AAMD
	DW	_SALC,SINGD,_XLATB,SINGD
	DW	_ESC,ESCD,_ESC,ESCD
	DW	_ESC,ESCD,_ESC,ESCD
	DW	_ESC,ESCD,_ESC,ESCD
	DW	_ESC,ESCD,_ESC,ESCD
	DW	_LOOPNZ,RELBD,_LOOPZ,RELBD
	DW	_LOOP,RELBD,_JCXZ,RELBD
	DW	_IN,ACCID,_IN,ACCID
	DW	_OUT,IBAPD,_OUT,IBAPD
	DW	_CALL,RELWD,_JMP,RELWD
	DW	_JMP,SEGOFD,_JMP,RELBD
	DW	_IN,ADIOD,_IN,ADIOD
	DW	_OUT,ADIOD,_OUT,ADIOD
	DW	_LOCK,SINGD,_DB,INVD
	DW	_REPNZ,SINGD,_REPZ,SINGD
	DW	_HLT,SINGD,_CMC,SINGD
	DW	_GRP,G03D,_GRP,G03D
	DW	_CLC,SINGD,_STC,SINGD
	DW	_CLI,SINGD,_STI,SINGD
	DW	_CLD,SINGD,_STD,SINGD
	DW	_GRP,G04D,_GRP,G04D
	EVEN
RM	DB	0EH,7,6,0FFH
	DB	5,1,3,0FFH
	DB	4,0,2,0FFH
	DB	0FFH,0FFH,0FFH,0FFH
ERRM	DW	EM0,EM1,EM2,EM3
	DW	EM4,EM5,EM6,EM7
	DW	EM8,EM9,EMA,EMB
	DW	EMC
IHDL	DW	G0,G1,G2,G3
	DW	G4,G5,G6,G7
	DW	G8,G9,G0AH,G0BH
	DW	G0CH,G0DH,G0EH,G0FH
	DW	G10H,G11H,G12H,G13H
	DW	G14H,G15H,G16H,G17H
_G01D	DW	_ADD,_OR,_ADC,_SBB
	DW	_AND,_SUB,_XOR,_CMP
_G02D	DW	_ROL,_ROR,_RCL,_RCR
	DW	_SHL,_SHR,_SAL,_SAR
_G03D	DW	_TEST,_TEST,_NOT,_NEG
	DW	_MUL,_IMUL,_DIV,_IDIV
_G04D	DW	_INC,_DEC,_CALL,_CALL
	DW	_JMP,_JMP,_PUSH,_DB
_DISP	DB	0EBH,0FBH,0EDH,0FDH
	DB	0EH,0FH,0DH,0BH
REGS	DB	"ALCLDLBLAHCHDHBH"
	DB	"AXCXDXBXSPBPSIDI"
	DB	"ESCSSSDS"
_GRP	DB	0,0
DOTASM	DB	3,"ASM"
DOTCOM	DB	3,"COM"
DOTLST	DB	3,"LST"
INM	DB	4,"IN: "
OUTM	DB	5,"OUT: "
EM0	DB	11,"BAD OPERAND"
EM1	DB	12,"SYNTAX ERROR"
EM2	DB	16,"BAD DISPLACEMENT"
EM3	DB	18,"NOT AN INSTRUCTION"
EM4	DB	16,"UNDEFINED SYMBOL"
EM5	DB	16,"OUT OF RANGE BY "
EM6	DB	13,"SIZE MISMATCH"
EM7	DB	18,"CONSTANT TOO LARGE"
EM8	DB	15,"MISSING OPERAND"
EM9	DB	16,"GARBAGE PAST END"
EMA	DB	16,"DUPLICATE SYMBOL"
EMB	DB	14,"ERROR READING "
EMC	DB	13,"RESERVED WORD"
BYTEM	DB	8," BYTE(S)"
AMSG	DB	"PC-72 8086 ASSEMBLER"
	DB	" 1.04 FOR DOS",13,10,36
USAGE	DB	"A72 {[/A] | /D} [/L] <IN> "
	DB	"[<OUT>] [<LIST>]",13,10,36
DOSERR	DB	"BAD DOS VERSION",13,10,36
PC	DW	?,?
USIZE	DW	?
ERRS	DW	?
VORG	DW	?
FUNC	DB	?,?
STK	DW	?,?
FLAGS	DB	?
WADJ	DB	?,?
ARGS	DB	?,?,?
PREFIX	DB	?
SEGPREF	DB	?
OPCODE	DB	?
MODRM	DB	?
DISP	DW	?
IMM	DW	?
OUTHDL	DW	?
LSTHDL	DW	?
INFILE	DS	20H
INCFILE	DS	20H
OUTFILE	DS	20H
LSTFILE	DS	20H
INCLEV	DS	200H
TEMP	DS	80H
INPUT	DS	80H
OUTPUT	DS	80H
SYMBS	DS	2000H
