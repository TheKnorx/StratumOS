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
    .Code.base3:    db  0x0     ; this is ignored in 64 bit

    ; Set the flag bits accordingly
    ; Clear the G (granularity) bit - this is ignored in 64 bit
    ; Clear the DB (default operation size)
    ; Set the L (long mode) flag to indicate its a descriptor for a 64 bit code segment
    .Code.flags:    db  (0<<3) || (0<<2) || (1<<1)  ; the 0-bit is reserved
    .Code.limit2:   dw  0x0     ; this is ignored in 64 bit

    ; Set the bits of the Access Byte accordingly
    ; Set the P flag to indicate its present
    ; Clear the DPL flag to indicate the highest privilege level (for now)
    ; Set the S flag to indicate its a code segment
    ; Set the E (executable) bit to indicate its executable
    ; Set the DC (conforming) bit to allow execution of this code from every privilege level (for now)
    ; Set the RW (readable/writable) bit to read only
    ; Set the A (accessed) bit
    .Code.access_b: db  (1<<7) || (0<<5) || (1<<4) || (1<<3) || (1<<2) || (1<<1) || (1<<0)
    .Code.base2:    db  0x0     ; this is ignored in 64 bit
    .Code.limit1:   dw  0xffff  ; Is needed cause the processor does a last check
                                ; before it jumps to long mode. Having a limit of 0
                                ; will cause a General-Protection Fault
    .Code.base1:    dw  0x00    ; this is ignored in 64 bit

align 4  ; padding for the GDT_END pointer
GDT_END: