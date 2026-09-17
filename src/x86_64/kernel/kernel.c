#include "../bootloader/multiboot2.h"

extern void print_str64(char* format);

void kernel_main(void) {
    print_str64("And this is a hello from the C kernel!");
    return;
}
