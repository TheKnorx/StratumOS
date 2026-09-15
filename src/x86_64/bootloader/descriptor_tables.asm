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
    dd              GDT                 ; 32-Bit Basisadresse
global GDT
GDT:
    dd              0x00                ; zero entry

    ; CODE Segment
    global .Code
    .Code:          equ $ - GDT
    .Code.limit1_lo:dw  0xFFFF ; Set the limit to 4GiB
    .Code.base1_lo: dw  0x00   ; this is ignored in 64 bit
    .Code.base2_mid:db  0x00   ; this is ignored in 64 bit
    ; Set the bits of the Access Byte accordingly (for description see below)
    .Code.access_b: db  PRESENT || PRIVILEGE || CODE_SEG || EXECUTABLE || DC_CONFORM || READ_O || ACCESSED
    ; Higher 3 bits are flags, lower ones are the higher limit (for description see below)
    .Code.flags_lim:db  GRAN_4k || CLEARED_SZ || LONG_MODE || 0x0F ; the 4th bit is reserved
    .Code.base_hi:  db  0x00    ; this is ignored in 64 bit

    ; DATA segment
    global .Data
    .Data:          equ $ - GDT
    .Data.limit_lo: dw  0xFFFF  ; Set the limit to 4 GiB
    .Data.base_lo:  dw  0x00    ; this is ignored in 64 bit
    .Data.base2:    db  0x00    ; this is ignored in 64 bit
    ; Set the bits of the Access Byte accordingly (for description see below)
    .Data.access_b: db  PRESENT || PRIVILEGE || DATA_SEG || NOT(EXECUTABLE) || DC_DIREC || READ_WRITE || ACCESSED
    ; Higher 3 bits are flags, lower ones are the higher limit
    ; Set the G (granularity) bit (- this is ignored in 64 bit)
    ; Set the DB (default operation size) to 32bit
    ; Set the L (long mode) flag to indicate its a descriptor for a 64 bit code segment
    .Data.flags_lim:db  GRAN_4k || CLEARED_SZ || LONG_MODE || 0x0F   ; the 4th bit is reserved
    .Data.base_hi:  db  0x00    ; this is ignored in 64 bit

align 4  ; padding for the GDT_END pointer
GDT_END:

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
GRAN_4k:    equ (1<<7)       ; Set the G (granularity) bit ==> the Limit is in 4 KiB blocks (page granularity)
CLEARED_SZ: equ (0<<6)       ; Clear it cause it should be clear if the LongMode bit is set (->wiki.osdev.org)
LONG_MODE:  equ (1<<5)      ; Set the L (long mode) flag to indicate its a descriptor for a 64 bit code segment
