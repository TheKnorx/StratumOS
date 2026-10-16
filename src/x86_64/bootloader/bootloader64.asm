%define VGA_BUFFER      0xB8000
%define COLOR_FORMAT    0x1f
%define STACK_SIZE64    8 * 1024 * 1024  ; 1 MiB

bits 64

section .text
extern stack_top, kernel_main, serial_puts64

global LongMode
LongMode:
    ; Reset the stack pointer and the base pointer for long mode (64 bit)
    mov     rsp, stack_top64
    mov     rbp, rsp

    mov     rdi, hello_str
    call    serial_puts64

    ; FOR DEBUGGING: test if paging was setup correctly - otherwise this should result in a #GP
    mov     rdx, 0x140000000
    mov     rax, [rdx]  ; access an address at 5 GiB

    ; mov     rdi, hello_str
    ; call    print_str64

    mov     rdi, rbx    ; pass to the kernel the address of the multiboot information structure
    call    kernel_main

    mov     rdi, good_bye_str
    call    serial_puts64

halt:
    hlt
    jmp     halt

; print a null-termianted string, whos pointer is located in edi, to the VGA buffer
; void print_str(char* str);
global print_str64
print_str64_DEPRECATED:
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
hello_str: db "Hello from long mode!", 0x0A, 0x00
good_bye_str:   db  "Shutting down. Good bye!", 0x0A, 0x00

section .bss
; Our stack area for 64 bit
alignb 16
global stack_bottom64
stack_bottom64:
    resb    STACK_SIZE64
global stack_top64
stack_top64: