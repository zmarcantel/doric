USE16
org 0x7C00

entry:
	cli
;	xchg 	bx, bx			; bochs debug
	xor 	ax, ax
	mov 	ss, ax
	mov 	es, ax
	mov 	ds, ax
	mov 	sp, 0x7C00
	sti

	; passed by BIOS
	mov 	[drive_number], dl

	mov 	si, msg_entry
	call 	puts


	;read in GPT header
	mov		eax, 0
	mov		ebx, 1
	mov		cx, 0x8000
	call	readsector

	xor		eax, eax
	xor		ebx, ebx
	xor		ecx, ecx
	.checkGPTHeader:
		cmp 	ecx, 8
		je		.checkGPTdone

		mov		eax, [0x8000 + ecx]
		mov		ebx, [gpt_signature + ecx]
		cmp		eax, ebx
		jne		gpt_fail

		inc 	ecx
		jmp 	.checkGPTHeader

		.gpt_fail:
			mov		si, gpt_fail
			call	puts
			jmp 	halt

	.checkGPTdone:

	mov		si, msg_done
	call	puts

halt:
	hlt
	jmp halt

;------------------------------------------------------------------------------
; Read a sector from a disk, using LBA
; IN:	EAX - High word of 64-bit DOS sector number
;	EBX - Low word of 64-bit DOS sector number
;	ES:CX - destination buffer
; OUT:	ES:CX points one byte after the last byte read
;	EAX - High word of next sector
;	EBX - Low word of sector
readsector:
	push eax
	xor eax, eax			; We don't need to load from sectors > 32-bit
	push dx
	push si
	push di

read_it:
	push eax			; Save the sector number
	push ebx
	mov di, sp			; remember parameter block end

	push eax			; [C] sector number high 32bit
	push ebx			; [8] sector number low 32bit
	push es				; [6] buffer segment
	push cx				; [4] buffer offset
	push byte 1			; [2] 1 sector (word)
	push byte 16			; [0] size of parameter block (word)

	mov si, sp
	mov dl, [drive_number]
	mov ah, 42h			; EXTENDED READ
	int 0x13			; http://hdebruijn.soo.dto.tudelft.nl/newpage/interupt/out-0700.htm#0651

	mov sp, di			; remove parameter block from stack
	pop ebx
	pop eax				; Restore the sector number

	jnc read_ok			; jump if no error

	push ax
	xor ah, ah			; else, reset and retry
	int 0x13
	pop ax
	jmp read_it

read_ok:
	add ebx, 1			; increment next sector with carry
	adc eax, 0
	add cx, 512			; Add bytes per sector
	jnc no_incr_es			; if overflow...

incr_es:
	mov dx, es
	add dh, 0x10			; ...add 1000h to ES
	mov es, dx

no_incr_es:
	pop di
	pop si
	pop dx
	pop eax

	ret
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; 16-bit function to print a sting to the screen
; IN:	SI - Address of start of string
puts:			; Output string in SI to screen
	pusha
	mov ah, 0x0E			; int 0x10 teletype function
.repeat:
	lodsb				; Get char from string
	cmp al, 0
	je .done			; If char is zero, end of string
	int 0x10			; Otherwise, print it
	jmp short .repeat
.done:
	popa
	ret
;------------------------------------------------------------------------------

drive_number 		db 0

msg_entry		 	db "Doric MBR Boot", 0
msg_done 	 		db "Done", 0
msg_not_found 		db "Not found", 0

gpt_signature		db "EFI PART", 0
gpt_fail			db "Invalid GPT", 0

times 510-$+$$ db 0

sign dw 0xAA55
