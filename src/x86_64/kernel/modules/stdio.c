#include <unistd.h>
#include "../assets/font8x8.h"
#include "common.h"
#include "../../multiboot2.h"

/* Distance of pixels between the bottom of
 * the line and the pixels for the new line */
#define NEWLINE_PXS 3
/* Padding between text and display end */
#define START_PADDING 50
/* Number of pixels between the letters */
#define SPACING 2
#define WHITE_COLOR 0x00FFFFFF
#define EOF ((int64_t)-1)
/* Cache sizes of the buffer*/
#define FRAMEBUFFER_ENTRY_SZ 80  // amount of chars per line
#define FRAMEBUFFER_BUFFER_SZ (FRAMEBUFFER_ENTRY_SZ * FRAMEBUFFER_ENTRY_SZ)

struct multiboot_tag_framebuffer_S * multiboot_tag_framebuffer;
static void* __framebuffer_ptr;
static __uint32_t __framebuffer_pitch;
typedef struct position_S {
    __uint32_t x;
    __uint32_t y;
} position_T;
static position_T current_position = {.x = START_PADDING, .y = START_PADDING};
static char __buffer[FRAMEBUFFER_ENTRY_SZ][FRAMEBUFFER_ENTRY_SZ];  // buffer to write all the letters into to flush into the framebuffer


void __init_framebuffer(void* addr) {
    for (const struct multiboot_tag *tag = (struct multiboot_tag *) (ADD_TO_VOID_PTR(addr, 8));
        tag -> type != MULTIBOOT_TAG_TYPE_END;
        tag = (struct multiboot_tag * )((__uint8_t * ) tag + ((tag -> size + 7) & ~7))) {
        if (MULTIBOOT_TAG_TYPE_FRAMEBUFFER == tag->type) {
            multiboot_tag_framebuffer = (struct multiboot_tag_framebuffer_S * ) tag;
            break;
        }
    }
    __framebuffer_ptr = (void*)multiboot_tag_framebuffer -> common.framebuffer_addr;
    __framebuffer_pitch = multiboot_tag_framebuffer->common.framebuffer_pitch;

    const char hello[] = "Hello World!\0";
    for (int i = 0;; i++) {
        const char c = hello[i];

        __buffer[0][i] = c;
        if (c == '\0') return;
    }
}

// for now, we only support flushing to stdout
int fflush() {
    for (int entry_i = 0; entry_i < FRAMEBUFFER_ENTRY_SZ; entry_i++) {
        for (int char_i = 0; char_i < FRAMEBUFFER_ENTRY_SZ; char_i++) {
            const unsigned char* char_bitmap = *(font8x8_basic + __buffer[entry_i][char_i]);
            for (int pixel_row_i = 0; pixel_row_i < FONT_SIZE; pixel_row_i++) {
                for (int pixel_i = 7; pixel_i >= 0; pixel_i--) {
                    if (char_bitmap[pixel_row_i] & (1 << pixel_i)) {
                        __uint32_t* pixel = ADD_TO_VOID_PTR(__framebuffer_ptr,
                            (current_position.y+pixel_row_i) * __framebuffer_pitch + (current_position.x+pixel_i) * 4);
                        *pixel = WHITE_COLOR;  // should be red
                    }
                }
            }
            current_position.x += FONT_SIZE;
        }

        current_position.x = START_PADDING;
        current_position.y += FONT_SIZE + NEWLINE_PXS;
    }
    return 0;
}

int printf(const char *__restrict __attribute__((unused)) format, ...) {
    format = format + 1;
    return 0;
}

void handle_newline() {

}

int putchar(const int c) {
    return c;
}

int puts(const char *s) {
    __uint32_t* pixel = ADD_TO_VOID_PTR(__framebuffer_ptr, 100 * __framebuffer_pitch + 100 * 4);
    *pixel = 0x00FF0000;  // should be red

    int i;
    for (i = 0; s[i] != '\0'; i++) putchar(s[i]);
    fflush();
    return i;
}