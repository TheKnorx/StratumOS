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


/*
 * C specific macros that won't be evaluated
 * by the preprocessor if processing assembly files
 */
#ifndef __ASSEMBLER__

#endif