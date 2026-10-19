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
    LEAVE_32
    ret
%endmacro


bits 64
; macro for doing the prolog
%macro ENTER_64 0
    push    rbp
    mov     rbp, rsp
    and     rsp, -16        ; align the stack to multiple of 16
%endmacro

; macro for doing the epilog
; not using 'leave` here cause of performance
%macro LEAVE_64 0
    mov     rsp, rbp
    pop     rbp
%endmacro

; do the epilog and return
%macro LEAVE_64_RET 0
    LEAVE_64
    ret
%endmacro