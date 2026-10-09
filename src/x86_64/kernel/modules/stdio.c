int printf(const char *__restrict __attribute__((unused)) format, ...) {
    format = format + 1;
    return 0;
}

