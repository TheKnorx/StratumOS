#pragma once

/* If including this in asm files:
 * http://thomasloven.com/blog/2012/06/C-Headers-In-Asm/
 * $ cpp -I include -x assembler-with-cpp myAsmFile.asm -o myAsmFile.s
 * $ nasm myAsmFile.s
 */

/*  The magic field should contain this. */
#define MULTIBOOT2_HEADER_MAGIC         0xe85250d6

/*  This should be in %eax. */
#define MULTIBOOT2_BOOTLOADER_MAGIC     0x36d76289

/*  Flags set in the 'flags' member of the multiboot header. */
#define MULTIBOOT_HEADER_TAG_END  0
#define MULTIBOOT_ARCHITECTURE_I386  0
#define MULTIBOOT_HEADER_TAG_OPTIONAL 1
#define MULTIBOOT_TAG_TYPE_END               0
#define MULTIBOOT_TAG_TYPE_CMDLINE           1
#define MULTIBOOT_TAG_TYPE_BOOT_LOADER_NAME  2
#define MULTIBOOT_TAG_TYPE_MODULE            3
#define MULTIBOOT_TAG_TYPE_BASIC_MEMINFO     4
#define MULTIBOOT_TAG_TYPE_BOOTDEV           5
#define MULTIBOOT_TAG_TYPE_MMAP              6
#define MULTIBOOT_TAG_TYPE_FRAMEBUFFER       8




/*  Multiboot header tags */
#define MULTIBOOT_HEADER_TAG_FRAMEBUFFER  5


/*
 * C specific macros that won't be evaluated
 * by the preprocessor if processing assembly files
 */
#ifndef __ASSEMBLER__
#include <sys/types.h>

#include "kernel/modules/common.h"

struct multiboot_tag
{
    __uint32_t type;
    __uint32_t size;
};

struct multiboot_tag_string
{
    __uint32_t type;
    __uint32_t size;
    char string[1];
};

struct multiboot_tag_module
{
    __uint32_t type;
    __uint32_t size;
    __uint32_t mod_start;
    __uint32_t mod_end;
    char cmdline[1];
};

struct multiboot_tag_basic_meminfo
{
    __uint32_t type;
    __uint32_t size;
    __uint32_t mem_lower;
    __uint32_t mem_upper;
};
struct multiboot_tag_bootdev
{
    __uint32_t type;
    __uint32_t size;
    __uint32_t biosdev;
    __uint32_t slice;
    __uint32_t part;
};

/* Framebuffer */
#define MULTIBOOT_FRAMEBUFFER_TYPE_INDEXED 0
#define MULTIBOOT_FRAMEBUFFER_TYPE_RGB     1
#define MULTIBOOT_FRAMEBUFFER_TYPE_EGA_TEXT     2

struct multiboot_color
{
    __uint8_t red;
    __uint8_t green;
    __uint8_t blue;
};

struct multiboot_tag_framebuffer_common
{
    __uint32_t type;
    __uint32_t size;

    __uint64_t framebuffer_addr;
    __uint32_t framebuffer_pitch;
    __uint32_t framebuffer_width;
    __uint32_t framebuffer_height;
    __uint8_t framebuffer_bpp;      // Framebuffer bits per pixel
    __uint8_t framebuffer_type;
    __uint16_t reserved;
};

struct multiboot_tag_framebuffer_S
{
    struct multiboot_tag_framebuffer_common common;

    union
    {
        struct
        {
            __uint16_t framebuffer_palette_num_colors;
            struct multiboot_color framebuffer_palette[1];
        };
        struct
        {
            __uint8_t framebuffer_red_field_position;
            __uint8_t framebuffer_red_mask_size;
            __uint8_t framebuffer_green_field_position;
            __uint8_t framebuffer_green_mask_size;
            __uint8_t framebuffer_blue_field_position;
            __uint8_t framebuffer_blue_mask_size;
        };
    };
} multiboot_tag_framebuffer_T;

#endif
