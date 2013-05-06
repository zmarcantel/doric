;*****************************************************
; Doric Bootloader
; Written By: Zachary Marcantel (zmarcantel@utexas.edu)
;
; Version: 0.0.1
;
; For licensing, see README
;*****************************************************




;------------------------------------------------------
; Entry
; * clear all registers
; * set stack to 0x8000
;   * provides 1K of stack space (0x7C00)
;------------------------------------------------------

USE16
ORG 0x00008000
start:
  cli
  xor eax, eax
  xor ebx, ebx
  xor ecx, ecx
  xor edx, edx
  xor esi, esi
  xor edi, edi
  xor ebp, ebp
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov fs, ax
  mov gs, ax
  mov esp, 0x8000

firstPass:
  ; after intial boot, this is overwritten with nop's and skipped
  jmp   firstCoreBoot
  nop

startAnotherCore:
;  %include    "hardware/start_core.asm"



;------------------------------------------------------
; 16 Bit Real Mode Startup
;------------------------------------------------------

USE16
firstCoreBoot:
  jmp   0x0000:clearcs

clearcs:

  ; set to standard 80x25 -- TODO: change to variable max res once tested
  mov   ax, 0x0003
  int   0x10

  ; Print message
  mov   si, msg_intro
  call  puts
  mov   si, version
  call  puts

  cli
  hlt

%include  "core/stdout.asm"

version:      db "0.0.1b"
msg_welcome:  db "Doric Bootloader v"
