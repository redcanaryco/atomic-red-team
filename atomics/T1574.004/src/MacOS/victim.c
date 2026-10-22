#include <stdio.h>

extern void hello(void);

int main(void) {
    printf("victim application starting\n");
    hello();
    return 0;
}
