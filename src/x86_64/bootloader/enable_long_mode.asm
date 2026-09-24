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

; Explicitly enable paging for 64 bit
; This function has no return value
global  enablePaging64
enablePaging64:
    mov eax, cr0            ; move control register cr0 into eax
    or eax, CR0_PG_ENABLE | CR0_PM_ENABLE   ; ensuring that PM is set will allow for jumping
                                            ; from real mode to compatibility mode directly
    mov cr0, eax
    ret

; Enable long mode
; This function has no return value
global enable_LM
enable_LM:
    mov ecx, EFER_MSR       ; Specify the EFER register to read from
    rdmsr                   ; Read from the EFER Model-Specific-Register
    or eax, EFER_LM_ENABLE  ; Set the LME bit in the loaded EFER
    wrmsr                   ; write the modified values back into the register
    ret

; Enable 64-Bit PAE (Physical Address Extension) paging, which includes:
; Page Map Level 4 Table (PML4T), Page Directory Pointer Table (PDPT),
; Page Directory Table (PDT), Page Table (PT);
global  setupPaging64
setupPaging64:
    ; preserve registers
    push    edi
    push    ebx

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
    ; 1. Put PDPT address into the 1st entry of PML4:
    mov     dword [edi], PDPT_ADDR & PT_ADDR_MASK | PT_PRESENT | PT_READABLE
    ; 2. Put PDT address into the 1st entry of PDPT:
    mov     edi, PDPT_ADDR
    mov     dword [edi], PDT_ADDR & PT_ADDR_MASK | PT_PRESENT | PT_READABLE
    ; 3. Put PT address into the 1st entry of PDT:
    mov     edi, PDT_ADDR
    mov     dword [edi], PT_ADDR & PT_ADDR_MASK | PT_PRESENT | PT_READABLE

    ; Now all that's left to do is fill the page table:
    mov edi, PT_ADDR
    mov ebx, PT_PRESENT | PT_READABLE
    mov ecx, ENTRIES_PER_PT      ; 1 full page table addresses 2MiB

    .SetEntry:
        mov     [edi], ebx      ; PT[i] = Physical Address + Flags
        add     ebx, PAGE_SIZE  ; Advance physical address by 4096 bytes (0x1000)
        add     edi, SIZEOF_PT_ENTRY    ; Advance entry pointer by 8 bytes
        loop    .SetEntry       ; Set the next entry.

    ; Now PAE can be enabled using the cr4 register
    mov     eax, cr4
    or      eax, CR4_PAE_ENABLE
    mov     cr4, eax

    ; restore registers
    pop     ebx
    pop     edi
    ret

global setupPaging64_16GiB
setupPaging64_16GiB:
    ; As we map 16 GiB into the virtual address space, paging will work the following:
    ; 1 PML4 with 1 entry (pointing to 1 PDPT)
    ; 1 PDPT with 16 entrys (each pointing to 1 PDT, representing 1 GiB each)
    ; 16 PDTs with 16 * 512 = 8,192 entries (each pointing to 1 PT, representing 2 MiB each)
    ; 8,192 PTs with 8,192 * 512 = 4,194,304 entries (each pointing to a 4 KiB page)
    ;
    ; So the overall size of the whole PML4 Table is:
    ; (SIZEOF_PT_ENTRY * ENTRIES_PER_PT)(1 + 1 + 16 + 8,192) = (SIZEOF_PAGE_TABLE) * 8,210
    ;                                                        = 8 * 512 * 8,210 = 33,628,160 = 33.62816 MiB
    ;
    ; In this function, esi and edi have the following roles:
    ; Source Index (esi): Points to the table (-entry) that will be filled
    ; Destination Index (edi): Points to the table that is filled into esi

    ; preserve registers
    push    edi
    push    esi
    push    ebx

    mov     esi, PML4T_ADDR
    mov     cr3, esi            ; cr3 lets the CPU know where the page tables are

    ; First, clear the tables
    xor     eax, eax,           ; value to override the memory with
    ; the esi register points to the memory to override
    ; The counter has to store the amount of 32Bit values that will get written to memory
    mov     ecx, (SIZEOF_PAGE_TABLE*(1 + 1 + 16 + 8192)) / 4
    rep     stosd               ; zero out the page table
    mov     esi, cr3            ; reset esi back to the beginning of the page table

    ; Next link the tables thogether. Since all those tables are located at the bottom
    ; of the memory and are addressable only by using the lower 32Bit,
    ; we can leave the upper 32Bit zeroed out for now.
    ; ESI was previously set to PML4T_ADDR
    ;
    ; 1: put the address of the PDPT into the first entry of the PML4
    mov    dword [esi], PDPT_ADDR & PT_ADDR_MASK | PT_PRESENT | PT_READABLE

    ; 2: put the addresses of the 16 PDTs into the first 16 entries of the PDPT
    xor     ecx, ecx            ; counter for the loop
    mov     esi, PDPT_ADDR      ; base_addres of the PDPT
    mov     edi, PDT_ADDR       ; move into edi the base_address of the PDT
    .fillPDPT:
        ; To calculate the next PDT, add to the pointer the size of the table
        add     edi, SIZEOF_PAGE_TABLE  ; advance the PDT pointer to the next PDT

        ; PDPT[ecx] = with_flags(PDT_ecx)
        and     edi, PT_ADDR_MASK | PT_PRESENT | PT_READABLE  ; set all the flags
        mov     dword [esi + ecx*8], edi    ; and put it in there!

        ; Finally check the bounds
        cmp     ecx, 16
        jge     .end_fillPDPT   ; end the loop if: ecx >= 16
        add     ecx, 0x01       ; else ecx++
        jmp     .fillPDPT       ; and continue
    .end_fillPDPT:

    ; 3. Put PT addresses into entrys of the PDTs.
    ; Because all entries of the 16 PDTs are filled, we just interpret
    ; the PDTs as a flat array of pointers to PTs.
    ; So we do: *(PDT current_address + offset) = PT   -; streching over multiple PDTs
    xor     ecx, ecx            ; reset counter for loop
    mov     esi, PDT_ADDR       ; move into esi the base_address of the PDT
    mov     edi, PT_ADDR        ; move into edi the base_address of the PT
    .fillPDTs:
        mov    [esi], edi       ; move the current PT into the current PDT entry

        ; Calculate the address of the next PDT entry: PDT entry = PDT current_address + sizeof(entry)
        add     esi, SIZEOF_TABLE_ENTRY     ; advance the base_address of the PDT by sizeof(entry)
        ; Calculate the address of the next PT: PT_ecx = PT current_address + sizeof(entry)
        add     edi, SIZEOF_TABLE_ENTRY     ; advance the base_address of the PT by sizeof(entry)

        ; Now check the loop condition - esi has to be in bounds of the PDT address space:
        cmp     esi, PT_ADDR
        jb      .fillPDTs       ; if esi < PT_ADDR: continue the loop
        ; else fall through and end the loop

    ; 4. Put the physical addresses of the pages into the Page Table (PT) - 4KiB each
    ; Because this is a 64 bit page table, therefore requiring 64 bit addresses in the PT,
    ; and because its populated while in protected (32 bit) mode, we use EDX:EAX to create 64 bit addresses
    mov     esi, PT_ADDR        ; move into esi the base_address of the PT
    mov     eax, PT_PRESENT | PT_READABLE   ; move the flags into eax
    xor     edx, edx            ; clear edx
    mov     ecx, 8192 * ENTRIES_PER_PT  ; eax = amount of PT entries per PT * amount of PTs
    .fillPTs:
        mov     [esi], edx      ; move edx into the upper 32 bit of the address part
        mov     [esi], eax      ; move eax into the lower 32 bit of the address part

        ; Advance the address by a page size
        add     eax, PAGE_SIZE  ; add to the lower half the size of a page - sets OF and CF on overflow
        adc     edx, 0x00       ; add the carry from the previous add if there was any

        ; Calculate the address of the next PT entry: PT entry = PT current_address + sizeof(entry)
        add     edi, SIZEOF_PT_ENTRY    ; advance the base_address of the PT by sizeof(entry)

        dec     ecx             ; decrement the counter
        jnz     .fillPTs        ; if ecx > 0: continue the loop
        ; else fall through

    ; Finally restore all the saved registers
    pop     ebx
    pop     esi
    pop     edi
    ret



section .rodata  ; we can define those labels as constants and make them read only
; CPUID/LM constants
EFLAGS_ID 			equ 1 << 21   	; if this bit can be flipped, the CPUID instruction is available
CPUID_EXTENSIONS 	equ 0x80000000 	; returns the maximum extended requests for cpuid
CPUID_EXT_FEATURES 	equ 0x80000001 	; returns flags containing long mode support among other things
CPUID_EDX_EXT_FEAT_LM equ 1 << 29   ; if this is set, the CPU supports long mode
EFER_MSR            equ 0xC0000080  ; Extended Feature Enable Register (EFER)
EFER_LM_ENABLE      equ 1 << 8      ; Bit of the EFER to enable Long Mode

; Paging constants
PML4T_ADDR          equ 0x1000      ; beginning of the PML4 Table
PDPT_ADDR           equ 0x2000      ; address of PDPT   = 0x1000 + 4096 * 1
PDT_ADDR            equ 0x3000      ; address of PDT    = 0x2000 + 4096 * 1
PT_ADDR             equ 0x13000     ; address of PT     = 0x3000 + 4096 * 16
PT_ADDR_MASK        equ 0xffffffffff000 ; the page table only uses certain parts of the actual address
PT_PRESENT          equ 1           ; marks the entry as in use
PT_READABLE         equ 2           ; marks the entry as r/w
ENTRIES_PER_PT      equ 512         ; entries per page table
SIZEOF_PAGE_TABLE   equ 4096        ; size of one page table
SIZEOF_TABLE_ENTRY  equ 8           ; generel size for all entries in every table
SIZEOF_PT_ENTRY     equ 8           ; size of one entry in the page level
PAGE_SIZE           equ 0x1000      ; size of one page level

; CR bits
CR0_PM_ENABLE       equ 1 << 0
CR0_PG_ENABLE       equ 1 << 31
CR0_PAGING          equ 1 << 31     ; CR0 bit for enabling or disabling paging on protected- and long-mode
CR4_PAE_ENABLE      equ 1 << 5      ; CR4 bit for enabling or disabling PAE