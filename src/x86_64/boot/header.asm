/*
 * This file represents the Multiboot 2 header.
 * For details, see https://wiki.osdev.org/Multiboot
*/

#include "multiboot2.h"

/*  Align 64 bits boundary. */
align  8

multiboot_header:
    /*  magic */
    dd      MULTIBOOT2_HEADER_MAGIC
    /*  ISA: i386 */
    dd      MULTIBOOT_ARCHITECTURE_I386
    /*  Header length. */
    dd      multiboot_header_end - multiboot_header
    /*  checksum */
    dd      -(MULTIBOOT2_HEADER_MAGIC + MULTIBOOT_ARCHITECTURE_I386 + (multiboot_header_end - multiboot_header))
; <tags>
tag_end:  ; terminate the tags
    dw      MULTIBOOT_HEADER_TAG_END
    dw      0
    dw      8
multiboot_header_end:

