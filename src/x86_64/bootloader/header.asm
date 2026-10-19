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
align 8    ; align: tag % 8 = 0
framebuffer_tag_start:
    dw      MULTIBOOT_HEADER_TAG_FRAMEBUFFER             ; type = Framebuffer
    dw      MULTIBOOT_HEADER_TAG_OPTIONAL                ; flags (1 = optional)
    dd      framebuffer_tag_end - framebuffer_tag_start  ; size of tag (excluding type, flags, size)
    dd      1024         ; preferred width
    dd      768          ; preferred height
    dd      32           ; preferred bits per pixel
framebuffer_tag_end:
align 8    ; align: tag % 8 = 0
tag_end:  ; terminate the tags
    dw      MULTIBOOT_HEADER_TAG_END
    dw      0
    dd      8
multiboot_header_end:

