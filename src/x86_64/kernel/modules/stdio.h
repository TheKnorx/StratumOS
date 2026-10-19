/**
* For now, this file will only contain screen io functions
*/

#pragma once

void init_framebuffer(void* addr);
int fflush();
extern int printf (const char *__restrict __format, ...);
int putchar(int c);
int puts(const char *s);
