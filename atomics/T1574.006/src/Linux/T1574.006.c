/*
    Atomic Red Team Shared Object Library
    Uses code inspired by Zombie Ant Farm (https://github.com/dsnezhkov/zombieant)

    Compilation
    -------------
    gcc -shared -fPIC -o ../bin/T1574.006.so T1055.c
*/

#include <stdio.h>

static void init(int argc, char **argv, char **envp) {
    printf("Loaded Atomic Red Team Library successfully!\n");
}

static void fini(void) {
    printf("Unloading Atomic Red Team preload...\n");
}


__attribute__((section(".init_array"), used)) static typeof(init) *init_p = init;
__attribute__((section(".fini_array"), used)) static typeof(fini) *fini_p = fini;