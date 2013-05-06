;------------------------------------------------------
; moveCursor
;  @ah  - row
;  @al  - column
;  !nothing
;  #none
;------------------------------------------------------

moveCursor:
  push  rcx
  push  rbx
  push  rax

  xor   ebx, ebx
  mov   [std_x], ah
  mov   [std_y], al
  mov   bl, ah
  
  ; new offset
  and   rax, 0xFF
  mov   cl, 80
  mul   cl                  ; ax = al * cl
  add   ax, bx
  shl   ax, 1

  add rax, 0xB8000
  mov [std_offset], rax     ; offset contains linear byte offset
  
  pop rax
  pop rbx
  pop rcx
  ret



;------------------------------------------------------
; putLine
;   @none
;   !nothing
;   #none
;------------------------------------------------------

putLine:
  push  rax

  mov   ah, 0             ; x = 0
  mov   al, [std_y]
  cmp   al, [std_height]
  ;je    .scroll
  
  inc   al                ; y += 1
  jmp   .done
  
  ;.scroll:
  ;  mov ax, 0x0000       ; wrap around, no clear - TODO - duh

  .done:
    call moveCursor

  pop rax
  ret



;------------------------------------------------------
; putc
;  @al  - character
;  !nothing
;  #none
;------------------------------------------------------

putc:
  push rdi

  mov rdi, [std_offset]
  stosb
  add qword [std_offset], 2

  pop rdi
  ret





;------------------------------------------------------
; puts
;  @rsi - string location (must be null terminated)
;  !nothing
;  #none
;------------------------------------------------------

puts:
  push rsi
  push rax

  ; force 'left-to-right' reading of string
  cld

  .next:
    lodsb
    cmp   al, 0
    je    .done

    cmp   al, '\n'
    je    .newLine

    call  putc

    jmp   .next

  .newLine:
    call  putLine
    jmp   .next

.done:
  pop rax
  pop rsi
  ret