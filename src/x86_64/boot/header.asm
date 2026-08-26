/*
 * This file represents the Multiboot 2 header.
 * For details, see https://wiki.osdev.org/Multiboot
*/

#include "multiboot2.h"

%define STACK_SIZE      0x4000

%define COLOR_FORMAT    0x1f
%define VGA_BUFFER      0xB8000

section .text
bits 32

global start
start:
    jmp     multiboot_entry

    /*  Align 64 bits boundary. */
    align  8

multiboot_header:
    /*  magic */
    dd      MULTIBOOT2_HEADER_MAGIC
    /*  ISA: i386 */
    dd      MULTIBOOT_ARCHITECTURE_I386
    /*  Header length. */
    dd      multiboot_header_end - multiboot_header
    /*  checksum */
    dd      -(MULTIBOOT2_HEADER_MAGIC + MULTIBOOT_ARCHITECTURE_I386 + (multiboot_header_end - multiboot_header))
; <tags>
tag_end:  ; terminate the tags
    dw      MULTIBOOT_HEADER_TAG_END
    dw      0
    dw      8
multiboot_header_end:
multiboot_entry:
    mov word [0xB8000], 0x1F58

    /*  Initialize the stack pointer. */
    mov     esp, stack_top

    /*  Reset EFLAGS. */
    push    0
    popfd

    cld                     ; Clear direction flag (string increments forward)
    mov     edi, hello_message
    call    print_str

    jmp     loop

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

section .bss
/*  Our stack area. */
align 16
stack_bottom:
    resb    STACK_SIZE
stack_top:


