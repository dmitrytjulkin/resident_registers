.model tiny
.code
org 100h

VIDEOSEG	equ 0b800h

Start:
	push VIDEOSEG
	pop es

	mov ax, 2345h
	mov bx, 5051h
	mov cx, 6969h
	mov dx, 9999h
	call PrintRegs

	mov ax, 4c00h
	int 21h
;_____________________________________________________________

;__PRINTREGS__
;Printing values of all registers
;Entry: all registers
;Exit: -
;Destr: -
;_____________________________________________________________
PrintRegs	proc
	push ax bx

	mov bx, 00h
	call PrintRegVal		;printing ax

	pop bx
	mov ax, bx
	push bx
	mov bx, 50h
	call PrintRegVal		;printing bx

	pop bx ax

	ret
	endp
;_____________________________________________________________

;__PRINTREGVAL__
;The function is printing actual value of register, that stored in AX.
;Its printing at es:[bx].
;Entry: AX
;Exit: -
;Destr: ...
;_____________________________________________________________
PrintRegVal	proc
	push ax bx cx di bp 
	mov cx, 4h			;cycle counter
	mov di, 10h			;di keeps divider
	xor bp, bp
	add bx, 2*4h

printing_reg_val:
	xor dx, dx
	div di

	push ax
	mov ax, dx
	add ax, "0"
	mov ah, 73h
	mov es:[bx], ax
	sub bx, 2
	pop ax

	loop printing_reg_val

	pop bp di cx bx ax

	ret
	endp
;_____________________________________________________________

end	Start