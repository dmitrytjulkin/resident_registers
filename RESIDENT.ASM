.model tiny
.code
org 100h

VIDEOSEG	equ 0b800h
FRAME_ADDR	equ 80h*5 + 40h
SYMB_COLOR	equ 070h			;= black on white
SCAN_CODE	equ 00Fh			;= tab
NEIGHB_BY_VERT equ 0A0h
FRAME_WIDTH	equ 010h

REGS_COUNT	equ 0Dh
FLAGS_COUNT equ 08h

HOR_BRDR 	equ 0CDh
VER_BRDR	equ 0BAh
TL_BRDR		equ 0C9h
TR_BRDR		equ 0BBh
BL_BRDR		equ 0C8h
BR_BRDR		equ 0BCh
SPACE		equ 020h

Start:
	mov ax, 3509h				;es:bx = address of int handler

	int 21h

	mov OldOffset, bx
	mov OldSegment, es			;save es:bx as variables

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
	add dx, 10h

	int 21h

DoUntilEscape	proc
	mov cs:[reg_arr + 0], ax
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

	pop ax bx cx
	push cx bx ax					;ax = ip, bx = cs, cx = flags

	mov cs:[reg_arr + 22], bx
	mov cs:[reg_arr + 24], ax
	mov cs:[reg_arr + 26], cx

	xor cx, cx

	mov ax, VIDEOSEG
	mov es, ax
	mov bx, FRAME_ADDR			;set address to start printing

	in al, 60h

	cmp al, SCAN_CODE
	jne skip_printing

	mov ah, SYMB_COLOR
	call PrintFrame
	call PrintRegsNFlags		;printing regs value

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
	mov ss, cs:[reg_arr + 20]	;recovery of registers

	db 0eah						; = jump far
	OldOffset dw 0				;	on this offset
	OldSegment dw 0				;	of this segment

;___________________________________________________________________________;

;__PRINTREGSNFLAGS__
;Printing values of all registers and flags
;Entry: all registers that stored in reg_arr (flags considers as another reg)
;___________________________________________________________________________;
PrintRegsNFlags		proc
	mov ax, cs:[reg_arr + 0]
	mov di, FRAME_ADDR
	xor bx, bx
	call PrintReg				;printing ax

	mov ax, cs:[reg_arr + 2]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing bx

	mov ax, cs:[reg_arr + 4]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing cx

	mov ax, cs:[reg_arr + 6]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing dx

	mov ax, cs:[reg_arr + 8]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing si

	mov ax, cs:[reg_arr + 10]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing di

	mov ax, cs:[reg_arr + 12]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing bp

	mov ax, cs:[reg_arr + 14]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing sp

	mov ax, cs:[reg_arr + 16]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing ds

	mov ax, cs:[reg_arr + 18]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing es

	mov ax, cs:[reg_arr + 20]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing ss

	mov ax, cs:[reg_arr + 22]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing cs

	mov ax, cs:[reg_arr + 24]
	add di, NEIGHB_BY_VERT
	add bx, 5
	call PrintReg				;printing ip

	mov ax, cs:[reg_arr + 26]
	add di, 0Bh * 2
	mov bx, offset flag_phrase
	call PrintFlags				;printing flags

	mov ax, cs:[reg_arr + 0]	;recover ax
	mov bx, cs:[reg_arr + 2]	;recover bx
	mov di, cs:[reg_arr + 10]	;recover di

	ret
	endp
;___________________________________________________________________________;

;__PRINTREG__
;The function is printing at es:[di] actual value of register, stored in AX.
;Also its printing reg phrase like "ax = ". Address to it stored in BX.	;//FIXME
;Entry: AX, BX, DI
;___________________________________________________________________________;
PrintReg		proc
	push ax bx dx di

	push ax
	mov cx, 4				;len("ax = ")
	mov ah, SYMB_COLOR
print_phrase:
	mov al, cs:[reg_phrase + bx]
	stosw
	inc bx
	loop print_phrase
	pop ax

	mov cx, 4h				;cycle counter = count of regs digits
	mov bx, 10h				;bx keeps divider
	add di, 2*4h			;address to print from right to left

printing_reg_val:
	xor dx, dx
	div bx					;dx = ax (mod 2)

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
	mov es:[di], ax
	sub di, 2
	pop ax

	loop printing_reg_val

	pop di dx bx ax
	ret
	endp
;___________________________________________________________________________;

;__PRINTFLAGS__
;Printing flags at es:[di] that stored in AX in correct order with phrase
;like "c = ". BX have to pointing at this phrase.
;Entry: AX, BX, DI
;Destr: -
;___________________________________________________________________________;
PrintFlags		proc
	push di

	mov cx, FLAGS_COUNT

printing_flags:
	mov ah, SYMB_COLOR
	push ax cx
	mov cx, 4				;length of phrase
printing_flag_phrase:
	mov al, cs:[bx]
	inc bx
	STOSW
	loop printing_flag_phrase
	pop cx ax

	push bx
	xor ah, ah
	xor dx, dx
	mov bx, 2h
	div bx					;dx = ax (mod 2)
	pop bx

	add dx, '0'
	mov ax, dx
	mov ah, SYMB_COLOR
	mov es:[di], ax

	sub di, NEIGHB_BY_VERT + 4h * 2
	loop printing_flags

	pop di
	ret
	endp
;___________________________________________________________________________;

;__PRINTFRAME__
;Printing frame with special color and with given size relative to sentence
;Entry: AH - color of symbols
;Destr: AL, BX, CX, DX, DI
;___________________________________________________________________________;
PrintFrame		proc
	mov di, FRAME_ADDR
	sub di, NEIGHB_BY_VERT	;di = address to print (for stosw)

	mov cx, REGS_COUNT + 2	;+2 - for vertical borders

build_frame:
	cmp cx, REGS_COUNT + 2
	jne not_upper_border
	mov bx, 0
	jmp do_next
not_upper_border:

	cmp cx, 1
	jne not_lower_border
	mov bx, 6
	jmp do_next
not_lower_border:

	mov bx, 3
do_next:					;to read symbols from array

	mov al, cs:[frame_symb + bx]
	mov es:[di-2], ax		;printing the edge of string

	mov al, cs:[frame_symb + bx + 1]
	push cx					;save cx value for double cycle
	mov cl, FRAME_WIDTH
	REP STOSW				;printing the center of string
	pop cx

	mov al, cs:[frame_symb + bx + 2]
	mov es:[di], ax			;printing the edge of string

	add di, NEIGHB_BY_VERT
	sub di, 2 * FRAME_WIDTH	;addressing to the start of next string

	loop build_frame

	ret
	endp
;___________________________________________________________________________;
	endp		;DoUntilProc

reg_arr dw 15 dup(0)
frame_symb db 	TL_BRDR, HOR_BRDR, TR_BRDR, \
				VER_BRDR, SPACE, VER_BRDR, \
				BL_BRDR, HOR_BRDR, BR_BRDR
reg_phrase db 	'ax = bx = cx = dx = si = di = ', \
				'bp = sp = ds = es = ss = cs = ip = fl = '
flag_phrase db	'd = i = a = p = o = s = z = c = '

EndOfProgram:

end	Start
