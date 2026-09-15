%define VGA_BUFFER      0xB8000
%define COLOR_FORMAT    0x1f

bits 64

section .text

global LongMode
LongMode:
    mov     rdi, hello_str
    call    print_str
    jmp $

; print a null-termianted string, whos pointer is located in edi, to the VGA buffer
; void print_str(char* str);
print_str:
    mov     rsi, rdi
    mov     rdi, VGA_BUFFER

    .move_chars_to_vga:
        mov     al, [rsi]
        inc     rsi
        test    al, al
        jz      .done
        mov     [rdi], al
        inc     rdi
        mov     byte [rdi], COLOR_FORMAT
        inc     rdi
        jmp     .move_chars_to_vga
    .done:
        ret

section .rodata
hello_str: db "Hello from long mode!", 0x00