; Global descripor table for 64 bit
; Since we operate in 64 bit, where segmentation is disabled,
; no other segments desciptors are needed, except for the
; code and data one.
;
; GDT for minimal setup
;  ├── null
;  └── 64-bit code
;
; GDT for an OS with privilege levels
; ├── null
; ├── kernel codez
; ├── kernel data
; ├── user code
; └── user data
;
; A limit of 4 GiB is needed, cause the processor does a last check
; before it jumps to long mode. Having a limit of 0
; will cause a General-Protection Fault

; Macro for unsetting/clearing a flag by XOR'ing it thogether
%define NOT(FLAG) (FLAG ^ FLAG)

GDTR_odd_align:
    ; The intel manual says that the pseudeo-descriptor
    ; should be located at an odd word address.
    ; ( gdtr_address MOD 4 == 2 )
    db              0x00

global GDTR
GDTR:
    dw              GDT_END - GDT - 1   ; 16-Bit Limit
    dd              GDT                 ; 32-Bit Baseaddress

align 8                         ; align the GDT on a 8 byte boundary
global GDT
GDT:
    dq 0x0000000000000000       ; Null Descriptor

    ; CODE Segment
    global .Code
    .Code:          equ $ - GDT
    .Code.limit1_lo:dw  0xFFFF ; Set the limit to 4GiB
    .Code.base1_lo: dw  0x00   ; this is ignored in 64 bit
    .Code.base2_mid:db  0x00   ; this is ignored in 64 bit
    ; Set the bits of the Access Byte accordingly (for description see below)
    .Code.access_b: db  PRESENT | PRIVILEGE | CODE_SEG | EXECUTABLE | DC_CONFORM | READ_O | ACCESSED
    ; Higher 3 bits are flags, lower ones are the higher limit (for description see below)
    .Code.flags_lim:db  GRAN_4k | CLEARED_SZ | LONG_MODE | 0x0F ; the 4th bit is reserved
    .Code.base_hi:  db  0x00    ; this is ignored in 64 bit

    ; DATA segment
    global .Data
    .Data:          equ $ - GDT
    .Data.limit_lo: dw  0xFFFF  ; Set the limit to 4 GiB
    .Data.base_lo:  dw  0x00    ; this is ignored in 64 bit
    .Data.base2:    db  0x00    ; this is ignored in 64 bit
    ; Set the bits of the Access Byte accordingly (for description see below)
    .Data.access_b: db  PRESENT | PRIVILEGE | DATA_SEG | NOT(EXECUTABLE) | DC_DIREC | READ_WRITE | ACCESSED
    ; Higher 3 bits are flags, lower ones are the higher limit (for description see below)
    ; The L (long mode) flag has to be 0
    .Data.flags_lim:db  GRAN_4k | CLEARED_SZ | NOT(LONG_MODE) | 0x0F   ; the 4th bit is reserved
    .Data.base_hi:  db  0x00    ; this is ignored in 64 bit

GDT_END:


; Interrupt Descriptor Table for 64 bit
;
; Intel Manual 3;   Because there are only 256 interrupt or exception vectors, the IDT need not
;                   contain more than 256 descriptors. It can contain fewer than 256 descriptors [...].
;
; Interrupt gates automatically clear the IF flag upon entry, disabling further
; maskable hardware interrupts until the handler returns via an IRET instruction.
; This prevents nested interrupts and stack overflow, making them the standard
; choice for hardware interrupt handling (e.g., keyboard or network interrupts)
;
; Trap gates do not clear the IF flag, allowing new interrupts to occur during the
; handler's execution. This makes them ideal for system calls, software interrupts,
; and exceptions (e.g., page faults or division by zero), where minimizing interrupt
; latency and maintaining system responsiveness is critical.

; Macro for building either an interrupt or a trap interrupt descriptors
; Parameters in the following order:
; 1) Descriptor to generate - trap or interrupt gate
; 2) first offset       4) segment selector
; 3) second offset      5) flags: P(16), DPL(13), D(11)
%macro BUILD_IDT_DESCRIPTOR 5
    IDT.%{%IG_off1}:    dw  %2  ; first offset
    IDT.%{%IG_ss}:      dw  %4  ; segment selector

    %if %1 == M_CREAT_IG
        IDT.%{%IF_flags}:   dw  IG_FLAG_ID | %5  ; combine the IG identifier with the IG flags
    %elseif %1 == M_CREAT_TG
        IDT.%{%IF_flags}:   dw  TG_FLAG_ID | %5  ; combine the TG identifier with the TG flags
    %else %error "IDT descriptor builder: Received invalid descriptor type"
    %endif

    IDT.%{%IG_off2}:    dw  %3  ; second offset
%endmacro

global IDTR
IDTR:
    dw  IDT_END - IDT-1      ; 16-Bit Limit
    dd  IDT                  ; 32-Bit Basisadresse

align 8                         ; align the GDT on a 8 byte boundary
IDT:

IDT_END:



section .rodata
; Access bits:
PRESENT:    equ (1<<7)      ; Set the P flag to indicate its present
PRIVILEGE:  equ (0<<5)      ; Clear the DPL flag to indicate the highest privilege level (for now)
CODE_SEG:   equ (1<<4)      ; Set the S flag to indicate its a code segment, not a system segment
DATA_SEG:   equ (1<<4)      ; Set the S flag to indicate its a data segment, not a system segment
EXECUTABLE: equ (1<<3)      ; Set the E (executable) bit to indicate its executable
DC_CONFORM: equ (1<<2)      ; Set the DC (conforming) bit to allow execution of this code from every privilege level (for now)
DC_DIREC:   equ (0<<2)      ; Clear the DC (direction) bit, leading the data segment to grow upwards
READ_O:     equ (1<<1)      ; Set the RW (readable/writable) bit to read only for code segment; write is always not allowed
READ_WRITE: equ (1<<1)      ; Set the RW (readable/writable) bit to write for data segment; read is always allowed
ACCESSED:   equ (1<<0)      ; Set the A (accessed) bit

; Flags bits:
GRAN_4k:    equ (1<<7)      ; Set the G (granularity) bit ==> the Limit is in 4 KiB blocks (page granularity)
CLEARED_SZ: equ (0<<6)      ; Clear it cause it should be clear if the LongMode bit is set (->wiki.osdev.org)
LONG_MODE:  equ (1<<5)      ; Set the L (long mode) flag to indicate its a descriptor for a 64 bit code segment

; Macro flags:
M_CREAT_IG: equ 0           ; Create a interrupt gate descriptor
M_CREAT_TG: equ 1           ; Create a trap gate descriptor

; IDT constants
IG_FLAG_ID: equ (3<<9)      ; bits that identify the desciptor as a interrupt gate
TG_FLAG_ID: equ (7<<8)      ; bits that identify the desciptor as a trap gate