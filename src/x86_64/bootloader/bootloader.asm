#include "multiboot2.h"

%define STACK_SIZE      0x4000

%define COLOR_FORMAT    0x1f
%define VGA_BUFFER      0xB8000

; macro for printing an error and stopping execution
%macro HANDLE_ERROR 1
    mov     edi, %1
    call    print_str
    jmp     $
%endmacro

section .text
bits 32

extern checkCPUID, queryLongMode, try_enable_A20, disablePaging, enablePaging, setupPaging64

global start
start:
    /*  Initialize the stack pointer. */
    mov     esp, stack_top

    /*  Reset EFLAGS. */
    push    0
    popfd

    call    check_multiboot

    mov     edi, hello_message
    call    print_str

.check_CPUID:  ; check if CPUID is supported
    call    checkCPUID
    test    eax, eax        ; check the return value
    jnz     .check_extended ; if supported, continue
    HANDLE_ERROR err_no_CPUID   ; else throw an error
.check_extended:  ; check if the CPU supportes extended functions
                  ; and if long mode is supported
    call    queryLongMode
    test    eax, eax        ; check the return value
    jnz     .enable_A20     ; if supported, continue
    HANDLE_ERROR err_no_LM  ; else throw an error
.enable_A20:
    ; enable the A20 line if possible...
    call    try_enable_A20
    test    eax, eax
    jnz     .disable_32Paging   ; successfully enabled the A20 line!
    ; Now if we did not succeed in enabling the A20 line,
    ; there is nothing left to do, so we have to give up.
    ; The only thing we can do is to inform the user about this
    mov     edi, info_no_A20
    call    print_str
.disable_32Paging:
    call    disablePaging       ; has no return value
.enable_64Paging:
    call    setupPaging64       ; set up paging for 64 bit
    call    enablePaging        ; has no return value

    ; ToDo: enable long mode, transerfer control to C kernel
    nop

    jmp     loop

/*  Am I booted by a Multiboot-compliant boot loader? */
check_multiboot:
    cmp     eax, MULTIBOOT2_BOOTLOADER_MAGIC
    je      .ret        ; if we were bootes by multiboot, continue

    .no_multiboot:      ; else print an error message
        mov     edi, err_no_multiboot
        call    print_str

    .ret: ret

; print a null-termianted string, whos pointer is located in edi, to the VGA buffer
; void print_str(char* str);
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
info_no_A20:
    db      "A20 line not supported. Continuing...", 0x00
/* Error messages: */
err_no_multiboot:
    db      "Not loaded by mutliboot", 0x00
err_no_CPUID:
    db      "CPUID is not supported", 0x00
err_no_LM:
    db      "CPU does not support long mode"

section .bss
/*  Our stack area. */
align 16
stack_bottom:
    resb    STACK_SIZE
stack_top:
