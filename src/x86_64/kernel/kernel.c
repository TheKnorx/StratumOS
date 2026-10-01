#include "../bootloader/multiboot2.h"

extern void print_str64(char* format);

void kernel_main(unsigned long __attribute__((unused)) addr) {
    print_str64("And this is a hello from the C kernel!");
    return;
}
