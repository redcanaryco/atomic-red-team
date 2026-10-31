#include <stdio.h>

__attribute__((constructor))
static void run(void) {
    FILE *f = fopen("/tmp/T1546.006_dylib_loaded.txt", "w");
    if (f) {
        fprintf(f, "LC_LOAD_DYLIB payload executed\n");
        fclose(f);
    }
}
