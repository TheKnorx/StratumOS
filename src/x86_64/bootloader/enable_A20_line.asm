; File for handling the A20 line
; ToDo: Replace eax return logic with `stc` anc `clc` for faster checking
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
    ; preserve registers
    push    edi
    push    esi

    mov     edi,0x112345    ; odd megabyte address.
    mov     esi,0x012345    ; even megabyte address.
    mov     [esi],esi       ; making sure that both addresses contain different values.
    mov     [edi],edi       ; (if A20 line is cleared the two pointers would point to the address 0x012345 that would contain 0x112345 (edi))
    cmp     edi, esi        ; compare addresses to see if the're equivalent.

    ; restore preserved registers
    pop     esi
    pop     edi

    jne     .A20_on         ; if not equivalent, A20 line is set.
    jmp     .A20_off        ; if equivalent, the A20 line is cleared.
    .A20_on:
        mov     eax, 1
        ret
    .A20_off:
        mov     eax, 0
        ret

; Check whether A20 became enabled (through a slow method) with a timeout.
; Timeout: 65,536 iterations
; Returns eax = 1 if the A20 line is set; 0 otherwise
is_A20_on_slow:
    xor     cx,cx           ; CX=0 -> LOOP executes 65,536 times
    .check:
        call    is_A20_on
        jnz     .enabled    ; if eax=1, A20 is enabled
        loop    .check      ; increment cx (if possible) and continue looping
        ; cx reached the maximum value i.e. timed out
        mov     eax, 1
        ret
    .enabled:
        mov     eax, 0
        ret

; Try to enable the A20 line by using the keyboard controller
; This function has no return value
global  enable_A20_keyboard_controller
enable_A20_keyboard_controller:
        cli                     ; disable interrupts

        call    .a20wait
        mov     al,0xAD
        out     0x64,al         ; disable keyboard

        call    .a20wait
        mov     al,0xD0
        out     0x64,al         ; read controller output port

        call    .a20wait2
        in      al,0x60         ; save response byte
        push    eax

        call    .a20wait
        mov     al,0xD1
        out     0x64,al         ; write next byte into controller output port

        call    .a20wait
        pop     eax
        or      al,2            ; set controller output bit for A20 on
        out     0x60,al         ; activate A20

        call    .a20wait
        mov     al,0xAE
        out     0x64,al         ; reactivate keyboard

        call    .a20wait
        sti                     ; reactivate interrupts
        ret
    .a20wait:                   ; wait until input buffer is clear
            in      al,0x64
            test    al,2
            jnz     .a20wait
            ret
    .a20wait2:                  ; wait until response byte has arrived
            in      al,0x64
            test    al,1
            jz      .a20wait2
            ret

; Try to enable the A20 Line using the Fast A20 Gate method
; This function has no return value
global  enable_A20_fast_gate
enable_A20_fast_gate:
    in al, 0x92
    test al, 2
    jnz .ret

    or al, 2
    and al, 0xfe
    out 0x92, al

    .ret:ret

; Function for trying all the methods for enabling the A20 line
; Returns eax = 1 if the A20 line is set; 0 otherwise;
global  try_enable_A20
try_enable_A20:
    ; preserve registers
    push ebx

    ; EBX will store the address to jmp to after 'check_A20' is finished

    ; first check if the A20 line is already enabled
    mov     ebx, .try_bios  ; fill the "return-label"
    jmp     .check_A20
    
    .try_bios:
    ; Try to enable the A20 line using the BIOS interrupt function
    call    enable_A20_bios
    test    eax, eax 
    jz      .try_key_cont   ; only jump to the next method if the bios method failed explicitly;
    mov     ebx, .try_key_cont
    call    .check_A20      ; else we recheck with 'is_A20_on'

    .try_key_cont:
    ; Try the keyboard controller method
    call    enable_A20_keyboard_controller
    call    is_A20_on_slow
    test    eax, eax
    jnz     .successful

    .try_fast:
    call    enable_A20_fast_gate
    call    is_A20_on_slow
    test    eax, eax
    jnz     .successful
    ; else fall through to failed

    .failed:
        mov     eax, 0
        jmp     .return
    .successful:
        mov     eax, 1
        ; fall through
    .return:
        pop     ebx         ; restore ebx
        ret

    ; logic for checking if the A20 line is enabled
    ; if its not, jmp back to the address defined in ebx
    ; otherwise, jmp to '.successful'
    .check_A20:
        call    is_A20_on
        test    eax, eax 
        jnz     .successful ; if the A20 Line is enabled, return
        jmp     ebx         ; else jmp to the location at ebx


; --------------------------------------------------
bits 16

; (From the wiki:) Most BIOSes provide a function in interrupt 0x15 to quickly enable the A20 gate
; Returns eax = 1 if the A20 line is set; 0 if its not supported;
; -1 if the state of the gate could not be retrieved; -2 is the gate could not be actived
global  enable_A20_bios
enable_A20_bios:
    mov     ax, 0x2403      ; Query A20 gate support
    int     0x15
    jc      .a20_nis        ; INT 0x15 is not supported
    test    ah, ah
    jnz     .a20_nis        ; INT 0x15 is not supported

    mov     ax, 0x2402      ; Get A20 gate status
    int     0x15
    jc      .a20_ngs        ; Couldn't get status
    test    ah, ah
    jnz     .a20_ngs        ; Couldn't get status
    test    al, al
    jnz     .a20_activated  ; AL = 1, A20 gate is already activated

    mov     ax, 0x2401      ; Activate A20 gate
    int     0x15
    jc      .a20_na         ; Couldn't activate the gate
    test    ah, ah
    jnz     .a20_na         ; Couldn't activate the gate

    .a20_nis:   ; INT 0x15 is not supported by BIOS (no interrupt support)
        mov     eax, 0
        ret
    .a20_ngs:   ; the A20 gate state could not be retrieved (no gate state)
        mov     eax, -1
        ret
    .a20_na:    ; the A20 gate could not be actived (no activation)
        mov     eax, -2
        ret
    .a20_activated:
        mov     eax, 1
        ret