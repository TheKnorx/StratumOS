; ---------------------------------------------------------------------------------
; File containing all the COM1 stuff for the bootloader
; ---------------------------------------------------------------------------------

#include "common.asm.inc"

bits 32  ; this all has to be compiled in 32 bit!

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

; Initialise COM1
global init_COM1_32
init_COM1_32:
    OUT     COM1 + 1, 0x00  ; Disable all interrupts
    OUT     COM1 + 3, 0x80  ; Enable DLAB (set baud rate divisor)
    OUT     COM1 + 0, 0x03  ; Set divisor to 3 (lo byte) 38400 baud
    OUT     COM1 + 1, 0x00  ;                  (hi byte)
    OUT     COM1 + 3, 0x03  ; 8 bits, no parity, one stop bit
    OUT     COM1 + 2, 0xC7  ; Enable FIFO, clear them, with 14-byte threshold
    OUT     COM1 + 4, 0x03  ; IRQs disabled, RTS/DSR set
    ret

; put a char on COM1; char is expected in edi (/ dil)
global serial_putc32
serial_putc32:
    ; Check in a "loop" whether we can send something or not;
    ; i.e. if the THRE bit is set, we are ready to go, otherwise check again
    .wait:
        IN      COM1 + 5    ; get
        test    al, LSR_THRE; check the state of the THRE bit
        jz      .wait       ; do it again if THRE was not set
    mov     eax, edi        ; move the char from edi into eax
    OUT     COM1, al        ; write the char saved in al on COM1
    ret

; print a null terminated string to COM1; char is expected in edi
global serial_puts32
serial_puts32:
    ENTER_32

    push    ebx             ; preserve ebx
    mov     esi, edi        ; move the pointer to the char array from edi into esi
    xor     ebx, ebx        ; use ebx as the counter

    ; iterate through all the chars in the string until the null terminator
    .for:
        xor     eax, eax    ; clear eax register
        mov     al, [esi + ebx]    ; base + index
        test    al, al      ; check if al contains the null terminator
        jz      .end_for    ; if so, exit the loop
        push    esi         ; preserver esi from function call
        mov     edi, eax    ; move eax into edi
        call    serial_putc ; char in edi/dil
        pop     esi         ; restore esi
        inc     ebx         ; increment counter
        jmp     .for        ; continue the loop
    .end_for:

    pop     ebx             ; restore ebx
    LEAVE_32
    ret

; ---------------------------------------------------------------------------------
; Kernel modul in 64 bit for using COM1 communication
; ---------------------------------------------------------------------------------

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
