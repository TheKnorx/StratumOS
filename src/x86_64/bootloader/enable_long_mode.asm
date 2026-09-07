; https://wiki.osdev.org/Setting_Up_Long_Mode
; 
; To enable long mode, certain things have to be present and available:
; 1) CPUID must be supported
; 2) Extended requests have to be supported by the CPU
; 3) Enable the A20 Line (- physical representation of the 21st bit) - separate file
; 4) Disable 32-Bit paging
; 5) Enable 64-Bit paging

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
    ret
    .NoLongMode:
    	mov 	eax, 0
    	ret		

; Explicitly disable paging
; This function has no return value
global  disablePaging
disablePaging:
    mov     eax, cr0        ; move control register cr0 into eax
    and     eax, ~CR0_PAGING; flip all bits of 'CR0_PAGING' so that only the bit
                            ; we specified is cleared and the rest of cr0 is preserved
    mov     cr0, eax        ; copy the modified cr0 from eax into cr0
    ret

; Explicitly enable paging
; This function has no return value
global  enablePaging
enablePaging:
    mov     eax, cr0        ; move control register cr0 into eax
    or      eax, CR0_PAGING ; only flip the bit specified in 'CR0_PAGING'
    mov     cr0, eax        ; copy the modified cr0 from eax into cr0
    ret

; Enable 64-Bit PAE (Physical Address Extension) paging, which includes:
; Page Map Level 4 Table (PML4T), Page Directory Pointer Table (PDPT),
; Page Directory Table (PDT), Page Table (PT);
setupPaging64:
    mov     edi, PML4T_ADDR
    mov     cr3, edi        ; cr3 lets the CPU know where the page tables are

    ; First, clear the tables
    xor     eax, eax
    mov     ecx, SIZEOF_PAGE_TABLE
    rep     stosd           ; writes 4 * SIZEOF_PAGE_TABLE bytes, which is enough space
                            ; for the 4 page tables
    mov     edi, cr3        ; reset edi back to the beginning of the page table

    ; Next is to link up just the first entries of each table,
    ; since 2 megabytes doesn't use more than one PDT entry.
    ; EDI was previously set to PML4T_ADDR
    mov     [edi], PDPT_ADDR & PT_ADDR_MASK | PT_PRESENT | PT_READABLE
    mov     edi, PDPT_ADDR
    mov     [edi], PDT_ADDR & PT_ADDR_MASK | PT_PRESENT | PT_READABLE
    mov     edi, PDT_ADDR
    mov     [edi], PT_ADDR & PT_ADDR_MASK | PT_PRESENT | PT_READABLE

    ; Now all that's left to do is fill the page table:
    mov edi, PT_ADDR
    mov ebx, PT_PRESENT | PT_READABLE
    mov ecx, ENTRIES_PER_PT      ; 1 full page table addresses 2MiB

    .SetEntry:
        mov     [edi], ebx
        add     ebx, PAGE_SIZE
        add     edi, SIZEOF_PT_ENTRY
        loop    .SetEntry       ; Set the next entry.

    ; Now PAE can be enabled using the cr4 register
    mov     eax, cr4
    or      eax, CR4_PAE_ENABLE
    mov     cr4, eax

section .rodate  ; we can define those labels as constants and make them read only
; CPUID/LM constants
EFLAGS_ID 			equ 1 << 21   	; if this bit can be flipped, the CPUID instruction is available
CPUID_EXTENSIONS 	equ 0x80000000 	; returns the maximum extended requests for cpuid
CPUID_EXT_FEATURES 	equ 0x80000001 	; returns flags containing long mode support among other things
CPUID_EDX_EXT_FEAT_LM equ 1 << 29   ; if this is set, the CPU supports long mode

; Paging constants
CR0_PAGING          equ 1 << 31     ; CR0 bit for enabling or disabling paging on protected- and long-mode
CR4_PAE_ENABLE      equ 1 << 5      ; CR4 bit for enabling or disabling PAE
PML4T_ADDR          equ 0x1000      ; beginning of the PML4 Table
SIZEOF_PAGE_TABLE   equ 4096        ; size of one page table
PML4T_ADDR          equ 0x1000      ; address of the PML4T
PDPT_ADDR           equ 0x2000      ; address of PDPT
PDT_ADDR            equ 0x3000      ; address of PDT
PT_ADDR             equ 0x4000      ; address of PT
PT_ADDR_MASK        equ 0xffffffffff000 ; the page table only uses certain parts of the actual address
PT_PRESENT          equ 1           ; marks the entry as in use
PT_READABLE         equ 2           ; marks the entry as r/w
ENTRIES_PER_PT      equ 512         ; entries per page table
SIZEOF_PT_ENTRY     equ 8           ; size of one entry in the page level
PAGE_SIZE           equ 0x1000      ; size of one page level