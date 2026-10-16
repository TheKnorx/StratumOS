; Kernel modul in 64 bit for using COM1 communication
; This is essentially the same cose as the bootloader, but in 64 bit for the kernel

bits 64

#include "common.asm.inc"

; Macro for doing an OUT instruction by setting up the DX and AL registers
; out dx, al
%macro OUT 2
    mov     dx, %1          ; port in dx
    mov     al, %2          ; byte to write in al
    out     dx, al          ; do the IO write
%endmacro

; Macro for doing an IN instruction by setting up the DX register
; in al, dx
%macro IN 1
    mov     dx, %1          ; port in dx
    in      al, dx          ; result in al
%endmacro

; put a char on COM1; char is expected in rdi (/ dil)
global serial_putc64
serial_putc64:
    ; Check in a "loop" whether we can send something or not;
    ; i.e. if the THRE bit is set, we are ready to go, otherwise check again
    .wait:
        IN      COM1 + 5    ; get
        test    al, LSR_THRE; check the state of the THRE bit
        jz      .wait       ; do it again if THRE was not set
    mov     rax, rdi        ; move the char from rdi into rax
    OUT     COM1, al        ; write the char saved in al on COM1
    ret

; print a null terminated string to COM1; char is expected in rdi
global serial_puts64
serial_puts64:
    ENTER_64
    mov     rsp, rbp
    push    rbp

    push    rbx             ; preserve rbx
    mov     rsi, rdi        ; move the pointer to the char array from edi into rsi
    xor     rbx, rbx        ; use rbx as the counter

    ; iterate through all the chars in the string until the null terminator
    .for:
        xor     rdi, rdi    ; clear rdi register
        mov     dil, [rsi + rbx]    ; base + index
        test    dil, dil      ; check if dil contains the null terminator
        jz      .end_for    ; if so, exit the loop
        push    rsi         ; preserver rsi from function call
        call    serial_putc64   ; char alreay in rdi/dil
        pop     rsi         ; restore rsi
        inc     rbx         ; increment counter
        jmp     .for        ; continue the loop
    .end_for:

    ; if we came here, we received a null terminator
    ; but the string didn't contain a newline so we create one
    mov     rdi, 0x0A       ; newline
    call    serial_putc64   ; send it to COM1

    ; finaly, do epilog and return from function
    pop     rbx             ; restore rbx
    mov     rsp, rbp
    LEAVE_64
    ret

section .rodata:
COM1:       equ     0x03F8  ; Port address for serial port COM1
LSR_THRE:   equ     0x20    ; Line Status Register --> Transmitter holding register empty (THRE) bit