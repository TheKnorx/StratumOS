bits 64

; Replacement-function for:
; void *memcpy(void dest[restrict .n], const void src[restrict .n],
;              size_t n);
; --> needed asm-inst: rep movsb
global memcpy
memcpy:
    ; no prolog or epilog needed

    ; rdi - parameter dest[restrict .n] - rdi already contains destination memory address
    ; rsi - parameter src[restrict .n] - rsi already contains the source memory address
    mov     r9, rdi     ; save s[.n] into r9 for later use
    mov     rcx, rdx    ; move parameter n into counter register
    cld                 ; clear direction flag so that we overwrite upwards from the base memory address
    rep movsb           ; overwrite whole allocated memory with char in al

    mov     rax, r9     ; move r9/s[.n] into rax for returning
    .return: ret