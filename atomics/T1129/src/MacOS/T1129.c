#include <stdio.h>

__attribute__((constructor))
static void run(void) {
    FILE *f = fopen("/tmp/T1129_module_loaded.txt", "w");
    if (f) {
        fprintf(f, "shared module executed via dlopen\n");
        fclose(f);
    }
}
