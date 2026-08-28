; https://wiki.osdev.org/Setting_Up_Long_Mode
; 
; To enable long mode, certain things have to be present and available:
; 1) CPUID must be supported
; 2) Extended requests have to be supported by the CPU
; 3)  ...

section .text
bits 32

; Checks if CPUID is supported by attempting to flip the ID bit (bit 21) in
; the EFLAGS register. If we can flip it, CPUID is available.
; returns eax = 1 if there is cpuid support; 0 otherwise
global 	checkCPUID
checkCPUID:
    pushfd 					; retrieve the EFLAGS from the CPU and push them onto stack
    pop 	eax 			; pop them into eax

    ; The original value should be saved for comparison and restoration later
    mov 	ecx, eax  		; make a copy of EFLAGS into ecx
    xor 	eax, EFLAGS_ID 	; flip the bit specified by EFLAGS_ID

    ; storing the eflags and then retrieving it again will show whether or not
    ; the bit could successfully be flipped
    push 	eax      		; push the modified EFLAGS onto stack
    popfd 					; try to overwrite the EFLAGS in the CPU 
							; with the modified EFLAGS in stack
    pushfd              	; retrieve the EFLAGS from the CPU
    pop 	eax 			; pop them into eax

    ; Restore EFLAGS to its original value
    push 	ecx 			; push the original EFLAGS onto stack
    popfd 					; reset the EFLAGS from the CPU with the original ones

    ; if the bit in eax was successfully flipped (eax != ecx), CPUID is supported.
    xor 	eax, ecx
    jnz 	.supported
    .notSupported: 			; eax == ecx, so CPUID is not supported
        mov	eax, 0
        ret
    .supported: 			; eax != ecx, so CPUID is supported
        mov eax, 1
        ret

; Checks is long mode (LM) is supported by the CPU by first determining 
; the CPU's supports of extended functions, and then checking whether
; the LM-Bit is set.
; returns eax = 1 if there is LM support; 0 otherwise
global 	queryLongMode
queryLongMode:
	; check if the CPU supports extended requests
	; for that, eax has to be equal or greater than 0x80000001
    mov 	eax, CPUID_EXTENSIONS
    cpuid
    cmp 	eax, CPUID_EXT_FEATURES
    jb 		.NoLongMode     ; if the CPU does not support extended requests,
    						; then it likely also doesn't support long mode
    ; check if the long mode bit is set (LM Bit at position 29)
    mov 	eax, CPUID_EXT_FEATURES
    cpuid
    test 	edx, CPUID_EDX_EXT_FEAT_LM	; test said bit
    jz 		.NoLongMode 

    mov 	eax, 1
    .NoLongMode	
    	mov 	eax, 0
    	ret		


section .data
EFLAGS_ID 			equ 1 << 21   	; if this bit can be flipped, the CPUID instruction is available
CPUID_EXTENSIONS 	equ 0x80000000 	; returns the maximum extended requests for cpuid
CPUID_EXT_FEATURES 	equ 0x80000001 	; returns flags containing long mode support among other things
CPUID_EDX_EXT_FEAT_LM equ 1 << 29   ; if this is set, the CPU supports long mode
