.model tiny
.code
org 100h

Start:
    push 1111
    pop ax

    push 2222
    pop bx

    push 3333
    pop cx

    push 4444
    pop dx

    mov ax, 4c00h
    int 21h         ;the end

end	Start
