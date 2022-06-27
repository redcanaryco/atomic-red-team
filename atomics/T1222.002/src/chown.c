//
//  main.c
//  T1222.002own
//
//  Created by bam on 6/27/22.
//

#include <errno.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, const char * argv[]) {
    // insert code here...
    if (argc < 2) {
      printf("usage: %s </path/to/file>\n", argv[0]);
      return 2;
    }

    const char *filepath = argv[1];
    int rv = chown(filepath, 0, 0);
    if (0 != rv) {
      printf("chmod failed. errno:%d\n", errno);
    }
      
    printf("done\n");
    return 0;
}
