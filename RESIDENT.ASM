.model tiny
.code
org 100h

VIDEOSEG	equ 0b800h
REL_ADDR	equ 160*5 + 80
SYMB_COLOR	equ 70h				;= black on white
SCAN_CODE	equ 0fh				;= tab

Start:
	mov ax, 3509h				;es:bx = address of int handler
	int 21h

	mov OldOffset, bx
	mov bx, es
	mov OldSegment, bx			;save es:bx as variables

	push 0
	pop es						;es = 0

	cli									;disables maskable interrupts
	mov bx, 09h * 4						;	to forbid
	mov es:[bx], offset DoUntilEscape	;pass control to another handler

	mov ax, cs
	mov es:[bx+2], ax
	sti									;enable maskable interrupts

	mov ax, 3100h				;end the program with leaving
								;	memory size to keep resident

	mov dx, offset EndOfProgram	;dx shows the size of resident mem
	shr dx, 4					;dividing by paragraphs
	inc dx						;	with rounding up

	int 21h

DoUntilEscape	proc
	mov cs:[reg_arr + 0], ax	;check what if mov reg_arr[2k], ax
	mov cs:[reg_arr + 2], bx
	mov cs:[reg_arr + 4], cx
	mov cs:[reg_arr + 6], dx
	mov cs:[reg_arr + 8], si
	mov cs:[reg_arr + 10], di
	mov cs:[reg_arr + 12], bp
	mov cs:[reg_arr + 14], sp
	mov cs:[reg_arr + 16], ds
	mov cs:[reg_arr + 18], es
	mov cs:[reg_arr + 20], ss
;	mov cs:[reg_arr + 22], cs
;	mov cs:[reg_arr + 24], ip	;//TODO idea to add flags

	mov ax, VIDEOSEG
	mov es, ax
	mov bx, REL_ADDR			;set address to start printing

	in al, 60h

	cmp al, SCAN_CODE
	jne skip_printing
	call PrintFrame
	call PrintRegs				;printing regs value

skip_printing:
	or al, 80h
	out 61h, al
	and al, not 80h				;"blink" by 7th bit of 61th port
	out 61h, al					;	to enable/disable keyboard

	mov al, 20h
	out 20h, al					;out to Interrupt controller

	mov ax, cs:[reg_arr + 0]
	mov bx, cs:[reg_arr + 2]
	mov cx, cs:[reg_arr + 4]
	mov dx, cs:[reg_arr + 6]
	mov si, cs:[reg_arr + 8]
	mov di, cs:[reg_arr + 10]
	mov bp, cs:[reg_arr + 12]
	mov sp, cs:[reg_arr + 14]
	mov ds, cs:[reg_arr + 16]
	mov es, cs:[reg_arr + 18]
	mov ss, cs:[reg_arr + 20]

	db 0eah						; = jump far
	OldOffset dw 0				;	on this offset
	OldSegment dw 0				;	of this segment

;_____________________________________________________________

;__PRINTREGS__
;Printing values of all registers
;Entry: all registers
;Exit: -
;Destr: -
;_____________________________________________________________
PrintRegs		proc
	mov ax, cs:[reg_arr + 0]
	add bx, 00h
	call PrintRegVal			;printing ax

	mov ax, cs:[reg_arr + 2]
	add bx, 0A0h
	call PrintRegVal			;printing bx

	mov ax, cs:[reg_arr + 4]
	add bx, 0A0h
	call PrintRegVal			;printing cx

	mov ax, cs:[reg_arr + 6]
	add bx, 0A0h
	call PrintRegVal			;printing dx

	mov ax, cs:[reg_arr + 8]
	add bx, 0A0h
	call PrintRegVal			;printing si

	mov ax, cs:[reg_arr + 10]
	add bx, 0A0h
	call PrintRegVal			;printing di

	mov ax, cs:[reg_arr + 0]	;recover ax
	mov bx, cs:[reg_arr + 2]	;recover bx

	ret
	endp
;_____________________________________________________________

;__PRINTREGVAL__
;The function is printing actual value of register, that stored in AX.
;Its printing at es:[bx].
;Entry: AX
;Exit: -
;Destr: -
;_____________________________________________________________
PrintRegVal		proc
	push ax bx cx dx di
	mov cx, 4h				;cycle counter = count of regs digits
	mov di, 10h				;di keeps divider
	add bx, 2*4h			;address to print from right to left

printing_reg_val:
	xor dx, dx
	div di					;quotient ax (remainder dx)

	push ax
	mov ax, dx
	cmp ax, 09h
	ja parse_letter
	add ax, "0"
	jmp go_next

parse_letter:
	add ax, "A"
	sub ax, 0Ah

go_next:
	mov ah, SYMB_COLOR
	mov es:[bx], ax
	sub bx, 2
	pop ax

	loop printing_reg_val

	pop di dx cx bx ax

	ret
	endp
;_____________________________________________________________
	endp		;DoUntilProc

reg_arr dw 14 dup(0)

EndOfProgram:

end	Start
