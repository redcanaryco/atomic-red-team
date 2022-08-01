#include <errno.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, const char * argv[]) {
    if (argc < 2) {
      printf("usage: %s </path/to/file>\n", argv[0]);
      return 2;
    }

    //change user and group to root
    const char *filepath = argv[1];
    int rv = chown(filepath, 0, 0);
    if (0 != rv) {
      printf("chmod failed. errno:%d\n", errno);
    }
      
    printf("done\n");
    return 0;
}
