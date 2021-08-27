#include <stdio.h>
#include <unistd.h>
int main()
{
    sleep(5);
    setuid(0);
    printf("UID: %d\n", getuid());
    return 0;
}
