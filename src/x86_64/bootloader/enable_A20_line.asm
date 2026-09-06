; File for handling the A20 line
;
; From wiki.osdev.org:
;
; Recommended Method
; Because there are several different methods that may or may not be supported,
; and because some of them cause problems on some computers; the recommended method
; is to try all of them until one works in the "order of least risk". Essentially:
;
; Test if A20 is already enabled - if it is you don't need to do anything at all
; Try the BIOS function. Ignore the returned status.
; Test if A20 is enabled (to see if the BIOS function actually worked or not)
; Try the keyboard controller method.
; Test if A20 is enabled in a loop with a time-out (as the keyboard controller method may work slowly)
; Try the Fast A20 method last
; Test if A20 is enabled in a loop with a time-out (as the fast A20 method may work slowly)
; If none of the above worked, give up

bits 32

; Check A20 line
; Returns to caller if A20 gate is cleared.
; Continues to A20_on if A20 line is set.
; Written by Elad Ashkcenazi - modified by Knorx
; Returns eax = 1 if the A20 line is set; 0 otherwise
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

bits 16

; (From the wiki:) Most BIOSes provide a function in interrupt 0x15 to quickly enable the A20 gate
; Returns eax = 1 if the A20 line is set; 0 if its not supported;
; -1 if the state of the gate could not be retrieved; -2 is the gate could not be actived
global  enable_A20_bios
enable_A20_bios:
    mov     ax, 0x2403      ; Query A20 gate support
    int     0x15
    jc      a20_nis         ; INT 0x15 is not supported
    test    ah, ah
    jnz     a20_nis         ; INT 0x15 is not supported

    mov     ax, 0x2402      ; Get A20 gate status
    int     0x15
    jc      a20_ngs         ; Couldn't get status
    test    ah, ah
    jnz     a20_ngs         ; Couldn't get status
    test    al, al
    jnz     a20_activated   ; AL = 1, A20 gate is already activated

    mov     ax, 0x2401      ; Activate A20 gate
    int     0x15
    jc      a20_failed      ; Couldn't activate the gate
    test    ah, ah
    jnz     a20_failed      ; Couldn't activate the gate

    .a20_nis:   ; INT 0x15 is not supported by BIOS (no interrupt support)
        mov     eax, 0
        ret
    .a20_ngs:   ; the A20 gate state could not be retrieved (no gate state)
        mov     eax, -1
        ret
    .a20_na:    ; the A20 gate could not be actived (no activation)
        mov     eax, -2
        ret
    a20_activated:
        mov     eax, 1
        ret