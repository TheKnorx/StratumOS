bits 32
; macro for doing the prolog
%macro ENTER_32 0
    push    ebp
    mov     ebp, esp
    and     esp, -16        ; align the stack to multiple of 16
%endmacro

; macro for doing the epilog
; not using 'leave` here cause of performance
%macro LEAVE_32 0
    mov     esp, ebp
    pop     ebp
%endmacro

; do the epilog and return
%macro LEAVE_32_RET 0
    LEAVE
    ret
%endmacro