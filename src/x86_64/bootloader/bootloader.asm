#include "multiboot2.h"

%define STACK_SIZE      0x100000    ; have 1 MByte as stack size

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

extern checkCPUID, queryLongMode, try_enable_A20, disablePaging, enablePaging64, setupPaging64, enable_LM
extern GDTR, GDT, GDT.Code, LongMode, GDT.Data

global start
start:
    ; Initialize the stack pointer
    mov     esp, stack_top

    ; Reset EFLAGS
    push    0
    popfd

    ; Check if we where booted by a multiboot compliant
    ; bootloader by verifying the signature in eax
    call    check_multiboot
    cmp     eax, 0x00
    jz      loop            ; the check encountered an error, so we halt execution

    ; Check if the multiboot information structure is aligned correctly
    call    check_mbi
    cmp     eax, 0x00
    jz      loop            ; the check encountered an error, so we halt execution


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
    jnz     .setupPaging   ; successfully enabled the A20 line!
    ; Now if we did not succeed in enabling the A20 line,
    ; there is nothing left to do, so we have to give up.
    ; The only thing we can do is to inform the user about this
    mov     edi, info_no_A20
    call    print_str
.setupPaging:
    call    disablePaging       ; has no return value
    call    setupPaging64       ; set up paging for 64 bit
    call    enable_LM           ; enable long mode before enabeling 64 bit paging
    call    enablePaging64      ; has no return value
;.setupPaging end

    lgdt    [GDTR]              ; load that shit (load the global descriptor table)

    ; Set all the segment registers
    cli
    ; ToDo: do this before switching to long mode
    mov ax, GDT.Data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    sti
    jmp far GDT.Code:LongMode   ; jump to the 64 bit code using a far jump

; Am I booted by a multiboot-compliant boot loader?
; returns eax = 1 if loaded by multiboot; 0 otherwise
check_multiboot:
    ; Check if the signature passed to us in eax
    ; matches the bootloaders magic number

    cmp     eax, MULTIBOOT2_BOOTLOADER_MAGIC
    je      .multiboot          ; we were booted my multiboot
    ; else, we were not - print an error message
    .no_multiboot:
        mov     edi, err_no_multiboot
        call    print_str
        mov     eax, 0
        ret
    .multiboot:
        mov     eax, 1
        ret

; Is the multiboot information structure aligned correctly?
; returns eax = 1 if mbi is aligned; 0 otherwise
check_mbi:
    ; Check if the multiboot information structure pointed to by ebx
    ; is aligned correctly. Fist 3 bits have to be cleared.
    ; --> address needs to *not* be divisible by 8

    mov     edx, ebx        ; copy ebx into edx
    and     edx, 0x07       ; check alignment
    jnz     .is_not_aligned ; if the AND did not result in zero, mbi is not aligned
    ; else, mbi is aligned - fall through
    .is_aligned:
        mov     eax, 1
        ret
    .is_not_aligned:
        mov     edi, err_mbi_misaligned
        call    print_str
        mov     eax, 0
        ret

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
err_mbi_misaligned:
    db      "Multiboot information structure is missaligned", 0x00
err_no_CPUID:
    db      "CPUID is not supported", 0x00
err_no_LM:
    db      "CPU does not support long mode", 0x00

section .bss
; Our stack area.
align 16
global stack_bottom
stack_bottom:
    resb    STACK_SIZE
global stack_top
stack_top:
