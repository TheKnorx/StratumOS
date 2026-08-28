#include "multiboot2.h"

%define STACK_SIZE      0x4000

%define COLOR_FORMAT    0x1f
%define VGA_BUFFER      0xB8000

section .text
bits 32

global start
start:
    /*  Initialize the stack pointer. */
    mov     esp, stack_top

    /*  Reset EFLAGS. */
    push    0
    popfd

    mov     edi, hello_message
    call    print_str

    call    check_multiboot

    ; ToDo: Enable long mode, paging, ..., transfer control to C kernel

    mov     edi, hello_message
    call    print_str

    jmp     loop

/*  Am I booted by a Multiboot-compliant boot loader? */
check_multiboot:
    cmp     eax, MULTIBOOT2_BOOTLOADER_MAGIC
    je      .ret        ; if we were bootes by multiboot, continue

    .no_multiboot:      ; else print an error message
        mov     rdi, err_no_multiboot
        call    print_str

    .ret: ret

print_str:
    mov     esi, edi
    mov     edi, VGA_BUFFER

    .move_chars_to_vga:
        mov     al, [esi]
        inc     esi
        test    al, al
        jz      .done
        mov     [edi], al
        inc     edi
        mov     byte [edi], COLOR_FORMAT
        inc     edi
        jmp     .move_chars_to_vga
    .done:
        ret

loop:
    hlt
    jmp     loop

section .rodata
hello_message:
    db      "Hello World!", 0

/* Error messages: */
err_no_multiboot:
    db      "Not loaded by mutliboot", 0

section .bss
/*  Our stack area. */
align 16
stack_bottom:
    resb    STACK_SIZE
stack_top:
