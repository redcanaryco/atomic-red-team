#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
  if (argc < 3) {
    printf("usage: %s </path/to/dir>  <filename>\n", argv[0]);
    return 2;
  }

  const char *dirpath = argv[1];
  const char *filename = argv[2];

  char filepath[1024];
  int rv = snprintf(filepath, sizeof(filepath), "%s/%s", dirpath, filename);
  if (0 >= rv) {
    printf("ERROR: unable to build filepath. larger than %d?\n", (int)sizeof(filepath));
    return 3;
  }

  int fd = open(filepath, O_CREAT | O_APPEND, (mode_t)0600);
  if (fd < 2) {
    printf("ERROR: unable to open/create '%s'\n", filepath);
    return 3;
  }

  // let's try chmods

  rv = fchmod(fd, 0644);
  if (0 != rv) {
    printf("fchmod failed. errno:%d\n", errno);
  }
  close(fd);

  rv = chmod(filepath, 0666);
  if (0 != rv) {
    printf("chmod failed. errno:%d\n", errno);
  }

  // let's try with relative path

  int dirfd = open(dirpath, O_RDONLY, (mode_t)0);
  if (dirfd < 2) {
    printf("ERROR: unable to open '%s'\n", dirpath);
  } else {
    rv = fchmodat(dirfd, filename, 0755, 0);
    if (0 != rv) {
      printf("fchmodat failed. errno:%d\n", errno);
    }
    close(dirfd);
  }
    
  printf("done");
  return 0;
}

