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
    dq              0x00                ; zero entry

    ; CODE Segment
    global .Code
    .Code:          equ $ - GDT
    .Code.limit1_lo:dw  0xFFFF  ; Is needed cause the processor does a last check
                                ; before it jumps to long mode. Having a limit of 0
                                ; will cause a General-Protection Fault
    .Code.base1_lo: dw  0x00   ; this is ignored in 64 bit
    .Code.base2_mid:db  0x00   ; this is ignored in 64 bit

    ; Set the bits of the Access Byte accordingly
    ; Set the P flag to indicate its present
    ; Clear the DPL flag to indicate the highest privilege level (for now)
    ; Set the S flag to indicate its a code segment
    ; Set the E (executable) bit to indicate its executable
    ; Set the DC (conforming) bit to allow execution of this code from every privilege level (for now)
    ; Set the RW (readable/writable) bit to read only
    ; Set the A (accessed) bit
    .Code.access_b: db  (1<<7) || (0<<5) || (1<<4) || (1<<3) || (1<<2) || (1<<1) || (1<<0)

    ; Higher 3 bits are flags, lower ones are the higher limit
    ; Set the G (granularity) bit (- this is ignored in 64 bit)
    ; Clear the DB (default operation size)
    ; Set the L (long mode) flag to indicate its a descriptor for a 64 bit code segment
    ; Also set the limit to all 1s
    .Code.flags_lim:db  (1<<7) || (0<<6) || (1<<5) || 0x0F ; the 4th bit is reserved

    .Code.base_hi:  db  0x00    ; this is ignored in 64 bit


    ; DATA segment
    global .Data
    .Data:          equ $ - GDT
    .Data.limit_lo: dw  0xFFFF  ; Is needed cause the processor does a last check
                                ; before it jumps to long mode. Having a limit of 0
                                ; will cause a General-Protection Fault
    .Data.base_lo:  dw  0x00    ; this is ignored in 64 bit
    .Data.base2:    db  0x00    ; this is ignored in 64 bit

    ; Set the bits of the Access Byte accordingly
    ; Set the P flag to indicate its present
    ; Clear the DPL flag to indicate the highest privilege level (for now)
    ; Set the S flag to indicate its a data segment
    ; Clear the E (executable) bit to indicate its not executable, i.g. a data segment
    ; Set the DC (direction) bit, leading to the data segment to grow upwards
    ; Set the RW (readable/writable) bit to read+write
    ; Set the A (accessed) bit
    .Data.access_b: db  (1<<7) || (0<<5) || (1<<4) || (0<<3) || (0<<2) || (1<<1) || (1<<0)

    ; Higher 3 bits are flags, lower ones are the higher limit
    ; Set the G (granularity) bit (- this is ignored in 64 bit)
    ; Set the DB (default operation size) to 32bit
    ; Set the L (long mode) flag to indicate its a descriptor for a 64 bit code segment
    .Data.flags_lim:db  (0<<7) || (1<<6) || (1<<5) || 0x0F   ; the 4th bit is reserved

    .Data.base_hi:  db  0x00    ; this is ignored in 64 bit

align 4  ; padding for the GDT_END pointer
GDT_END: