;
; helloo16.nasm: minimalistic hello-world WebAssembly WASI binary .wasm
; by pts@fazekas.hu at Wed Jan 18 12:12:00 CET 2023
;
; Compile: nasm -O0 -f bin -o hellowas.wasm hellowas.nasm
; Works with NASM >= 0.98.39.
;
; Compile: mininasm -O0 -f bin -o hellowas.wasm hellowas.nasm
;
; The created executable program is 124 bytes.
;
; Run: wasmtime run hellowas.wasm
;
; It's also possible to run it with wasmer.
;
; WASM decoder and disassembler: https://wasdk.github.io/wasmcodeexplorer/
;
; .wasm file format: https://webassembly.github.io/spec/core/binary/
;
; The generated hellowas.wasm (in WebAssembly binary format) is equivalent to
; the following .wat (WebAssembly text format).
;
;   (module
;     (func $import0 (import "wasi_unstable" "fd_write")
;                    (param i32 i32 i32 i32) (result i32))
;     (memory $memory0 1)
;     (export "memory" (memory $memory0))
;     (export "_start" (func $func1))
;     (func $func1
;       i32.const 1
;       i32.const 16
;       i32.const 1
;       i32.const 32
;       call $import0
;       drop
;     )
;     (data (i32.const 2) "Hello, World!\0a\02\00\00\00\0e")
;   );
;
; `wasmtime run' can also run .wat files. 
;
; To convert from .wat to .wasm, use the wat2wasm tool (without the
; --debug-names command-line flag) from https://github.com/webassembly/wabt .
;
; The single-byte (`db') encoding of integers works only for unsigned values
; 0..0x7f and signed values -0x40..0x3f. (All values in this file are within
; those ranges.) See for variable-width encoding (LEB128) of integers;
; https://webassembly.github.io/spec/core/binary/values.html#integers
;

wasm_binary_module:  ; https://webassembly.github.io/spec/core/binary/
.magic:		db 0, 'asm'  ; WebAssembly .wasm signature.
.version:	dd 1

section0:	db 1  ; ID: Type. https://webassembly.github.io/spec/core/binary/modules.html#type-section
		db section0_end-$-1
		db 2  ; Count.
type0:
.form:		db 0x60  ; Function (functype).
.arg_count:	db 4
.arg0:		db 0x7f  ; i32.
.arg1:		db 0x7f  ; i32.
.arg2:		db 0x7f  ; i32.
.arg3:		db 0x7f  ; i32.
.result_count:	db 1
.result0:	db 0x7f  ; i32.
type1:
.form:		db 0x60  ; Function (functype).
.arg_count:	db 0
.result_count:	db 0
section0_end:

section1:	db 2  ; ID: Import.
		db section1_end-$-1
		db 1  ; Count.
import0:
		; 'wasi_unstable' ABI is older, 'wasi_snapshot_preview1' ABI
		; is newer (2019+). 'fd_write' behaves identically in these
		; ABIs, so we use the ABI with the shorter name.
.module_name:	db .module_name_end-$-1, 'wasi_unstable'
.module_name_end:
.function_name:	db .function_name_end-$-1, 'fd_write'
.function_name_end:
.import_type:	db 0  ; typeidx.
.type_index:	db 0  ; type0.
section1_end:

section2:	db 3  ; ID: Function.
		db section2_end-$-1
		db 1  ; Count.
function1:  ; It's not function0, because function0 is fd_write.
.type_index:	db 1  ; type1.
section2_end:

section3:	db 5  ; ID: Memory.
		db section3_end-$-1
		db 1  ; Count.
memory0:
.limit_type:	db 0  ; Only min_size follows, there is no max.
.min_size:	db 1  ; * 64 KiB. Page size is always 64 KiB.
section3_end:

section4:	db 7  ; ID; Export.
		db section4_end-$-1
		db 2  ; Count.
export0:
.name:		db .name_end-$-1, 'memory'
.name_end:
.kind:		db 2  ; Kind: memory.
.index:		db 0  ; memory0.
export1:
.name:		db .name_end-$-1, '_start'  ; Entry point identified by function name.
.name_end:
.kind:		db 0  ; Kind: function.
.index:		db 1  ; function1 == _start.
section4_end:

; WASM assembly instruction opcodes.
I32_CONST	equ 0x41  ; i32.const
$CALL		equ 0x10  ; call
DROP		equ 0x1a  ; drop
END		equ 0x0b  ; end

section5:	db 0xa  ; ID: Code.
		db section5_end-$-1
		db 1  ; Count.
.body0:		db .body0_end-$-1
.local_count:	db 0
.asm:		db I32_CONST, 1  ; fd: STDOUT_FILENO.
		db I32_CONST, ..@iov_base_ofs  ; iov.
		db I32_CONST, 1  ; iovcnt: 1.
		db I32_CONST, ..@size_out_ofs  ; i32.
		db $CALL, 0  ; function0 == fd_write.
		db DROP
		db END
.body0_end:
section5_end:

section6:	db 0xb  ; ID: Data.
		db section6_end-$-1
		db 1  ; Count.
data0:
.data_type:	db 0  ; mode: Active, memory0. Active means: copy these bytes to memory0 during initialization.
.offset_expr:	db I32_CONST, .msg_ofs
		db END
		db .data_end-$-1
..@msg:		db 'Hello, World!', 10  ; 10 is \n (ASCII LF line feed).
..@msg_end:
.msg_ofs	equ (..@msg-..@msg_end)&3  ; Align to multiple of 4. Is it needed?
..@iov_base_ofs	equ .msg_ofs+(..@msg_end-..@msg)
.iov_base:	dd .msg_ofs
.iov_len:	db ..@msg_end-..@msg  ; Zero-extended to 4 bytes (`dd').
..@size_out_ofs	equ ..@iov_base_ofs+8+8  ; The first 8 is sizeof(iov), the second 8 is random padding.
.data_end:
section6_end:

; __END__
