#include "../multiboot2.h"
#include "modules/stdio.h"
#include "modules/COM1_io.asm.h"
#include "modules/common.h"
#include <sys/types.h>

extern void print_str64(char* format);
void get_framebuffer_addr(void* addr, struct multiboot_tag_framebuffer_S** mbtfb_ptr);
# define __UNUSED_VAR __attribute__((unused));

void kernel_main(const unsigned long addr) {
    __init_framebuffer((void*)addr);

    fflush();
    // puts("Hello World!\n");

    return;

    struct multiboot_tag_framebuffer_S * mbtf;
    get_framebuffer_addr((void*)addr, &mbtf);
    const void * fb = (void*)mbtf -> common.framebuffer_addr;

    __uint32_t* pixel = ADD_TO_VOID_PTR(fb, 100 * mbtf->common.framebuffer_pitch + 100 * 4);
    *pixel = 0x00FF0000;  // should be red

    // print_str64("And this is a hello from the C kernel!");
    return;
}

void get_framebuffer_addr(void* addr, struct multiboot_tag_framebuffer_S** mbtfb_ptr) {
    for (const struct multiboot_tag *tag = (struct multiboot_tag *) (ADD_TO_VOID_PTR(addr, 8));
        tag -> type != MULTIBOOT_TAG_TYPE_END;
        tag = (struct multiboot_tag * )((__uint8_t * ) tag + ((tag -> size + 7) & ~7))) {
        if (MULTIBOOT_TAG_TYPE_FRAMEBUFFER == tag->type) {
            *mbtfb_ptr = (struct multiboot_tag_framebuffer_S * ) tag;
            break;
        }
    }
}


// void parse_multiboot_info_structure(const unsigned long addr) {
//     if (addr & 7) {
//         serial_puts64("Unaligned mbi!");
//         return;
//     }
//
//     const unsigned size = * (unsigned * ) addr;
//     printf ("Announced mbi size 0x%x\n", size);
//     for (struct multiboot_tag *tag = (struct multiboot_tag *) (addr + 8);
//         tag -> type != MULTIBOOT_TAG_TYPE_END;
//         tag = (struct multiboot_tag * )((__uint8_t * ) tag + ((tag -> size + 7) & ~7)))
//     {
//         printf("Tag 0x%x, Size 0x%x\n", tag -> type, tag -> size);
//         switch (tag -> type) {
//             case MULTIBOOT_TAG_TYPE_CMDLINE:
//                 printf("Command line = %s\n",
//                     ((struct multiboot_tag_string * ) tag) -> string);
//                 break;
//             case MULTIBOOT_TAG_TYPE_BOOT_LOADER_NAME:
//                 printf("Boot loader name = %s\n",
//                     ((struct multiboot_tag_string * ) tag) -> string);
//                 break;
//             case MULTIBOOT_TAG_TYPE_MODULE:
//                 printf("Module at 0x%x-0x%x. Command line %s\n",
//                     ((struct multiboot_tag_module * ) tag) -> mod_start,
//                     ((struct multiboot_tag_module * ) tag) -> mod_end,
//                     ((struct multiboot_tag_module * ) tag) -> cmdline);
//                 break;
//             case MULTIBOOT_TAG_TYPE_BASIC_MEMINFO:
//                 printf("mem_lower = %uKB, mem_upper = %uKB\n",
//                     ((struct multiboot_tag_basic_meminfo * ) tag) -> mem_lower,
//                     ((struct multiboot_tag_basic_meminfo * ) tag) -> mem_upper);
//                 break;
//             case MULTIBOOT_TAG_TYPE_BOOTDEV:
//                 printf("Boot device 0x%x,%u,%u\n",
//                     ((struct multiboot_tag_bootdev * ) tag) -> biosdev,
//                     ((struct multiboot_tag_bootdev * ) tag) -> slice,
//                     ((struct multiboot_tag_bootdev * ) tag) -> part);
//                 break;
//             case MULTIBOOT_TAG_TYPE_FRAMEBUFFER: {
//                 __uint32_t color;
//                 unsigned i;
//                 const struct multiboot_tag_framebuffer_S * tagfb = (struct multiboot_tag_framebuffer_S * ) tag;
//                 const void * fb = (void * )(unsigned long) tagfb -> common.framebuffer_addr;
//
//                 switch (tagfb -> common.framebuffer_type) {
//                 case MULTIBOOT_FRAMEBUFFER_TYPE_INDEXED: {
//                     const struct multiboot_color * palette = tagfb -> framebuffer_palette;
//
//                     color = 0;
//                     unsigned best_distance = 4 * 256 * 256;
//
//                     for (i = 0; i < tagfb -> framebuffer_palette_num_colors; i++) {
//                         const unsigned distance = (0xff - palette[i].blue) *
//                             (0xff - palette[i].blue) +
//                             palette[i].red * palette[i].red +
//                             palette[i].green * palette[i].green;
//                         if (distance < best_distance) {
//                             color = i;
//                             best_distance = distance;
//                         }
//                     }
//                 }
//                 break;
//
//                 case MULTIBOOT_FRAMEBUFFER_TYPE_RGB:
//                     color = ((1 << tagfb -> framebuffer_blue_mask_size) - 1) <<
//                         tagfb -> framebuffer_blue_field_position;
//                     break;
//
//                 case MULTIBOOT_FRAMEBUFFER_TYPE_EGA_TEXT:
//                     color = '\\' | 0x0100;
//                     break;
//
//                 default:
//                     color = 0xffffffff;
//                     break;
//                 }
//
//                 for (i = 0; i < tagfb -> common.framebuffer_width && i < tagfb -> common.framebuffer_height; i++) {
//                     switch (tagfb -> common.framebuffer_bpp) {
//                         case 8: {
//                             __uint8_t * pixel = ADD_TO_VOID_PTR(fb, tagfb -> common.framebuffer_pitch * i + i);
//                             * pixel = color;
//                         }
//                         break;
//                         case 15:
//                         case 16: {
//                             __uint16_t * pixel = ADD_TO_VOID_PTR(fb, tagfb -> common.framebuffer_pitch * i + 2 * i);
//                             * pixel = color;
//                         }
//                         break;
//                         case 24: {
//                             __uint32_t * pixel = ADD_TO_VOID_PTR(fb, tagfb -> common.framebuffer_pitch * i + 3 * i);
//                             * pixel = (color & 0xffffff) | ( * pixel & 0xff000000);
//                         }
//                         break;
//
//                         case 32: {
//                             __uint32_t * pixel = ADD_TO_VOID_PTR(fb, tagfb -> common.framebuffer_pitch * i + 4 * i);
//                             * pixel = color;
//                         }
//                         break;
//                         default: {
//                             serial_puts64("Received unexpected bits per pixel for framebuffer");
//                         }
//                         break;
//                     }
//                 }
//                 break;
//             }
//         }
//     }
// }