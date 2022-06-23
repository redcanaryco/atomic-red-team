#include <stdio.h>
#include <stdlib.h>
int system(const char *command);
__attribute__((constructor))
static void customConstructor(int argc, const char **argv)
{
system("open -a Calculator.app");
}
