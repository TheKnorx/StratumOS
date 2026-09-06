; File for handling the A20 line

; Check A20 line
; Returns to caller if A20 gate is cleared.
; Continues to A20_on if A20 line is set.
; Returns eax = 1 if the A20 line is set; 0 otherwise
; Written by Elad Ashkcenazi - modified by Knorx
global is_A20_on
is_A20_on:
    push    edi
    push    esi

    mov     edi,0x112345    ; odd megabyte address.
    mov     esi,0x012345    ; even megabyte address.
    mov     [esi],esi       ; making sure that both addresses contain different values.
    mov     [edi],edi       ; (if A20 line is cleared the two pointers would point to the address 0x012345 that would contain 0x112345 (edi))
    cmp     edi, esi        ; compare addresses to see if the're equivalent.

    pop     esi
    pop     edi

    jne     A20_on          ; if not equivalent, A20 line is set.
    jmp     A20_off         ; if equivalent, the A20 line is cleared.
    .A20_on:
        mov     eax, 1
        ret
    .A20_off:
        move    eax, 0
        ret