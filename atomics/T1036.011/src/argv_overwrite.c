/*
 * T1036.011 - Masquerading: Overwrite Process Arguments
 *
 * Benign test program for Atomic Red Team. It zeroes every command-line
 * argument in its own argv memory, writes a spoofed string into the space
 * that argv[0] used, sleeps, and exits. Nothing else happens.
 *
 * Because the overwrite happens at runtime, /proc/<pid>/cmdline and `ps`
 * show the spoofed name, while the original command line exists only in
 * telemetry captured at exec time (e.g. auditd EXECVE, Sysmon for Linux
 * EID 1, eBPF exec events). This mirrors the behavior described for
 * BPFDoor and XorDdos.
 *
 * Usage: argv_overwrite <spoofed_name> <seconds> [any extra args to erase]
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
    if (argc < 3) {
        fprintf(stderr, "usage: %s <spoofed_name> <seconds> [args...]\n", argv[0]);
        return 1;
    }

    /* Copy what we need before wiping argv. */
    char spoof[256];
    strncpy(spoof, argv[1], sizeof(spoof) - 1);
    spoof[sizeof(spoof) - 1] = '\0';
    int seconds = atoi(argv[2]);

    /* argv strings sit back to back in memory; compute the whole region. */
    char *start = argv[0];
    char *end = argv[argc - 1] + strlen(argv[argc - 1]);
    size_t region = (size_t)(end - start);

    /* Erase every argument, then write the spoofed name into argv[0]'s space. */
    memset(start, 0, region);
    strncpy(start, spoof, region);

    printf("PID %d now presents as: %s\n", getpid(), start);
    fflush(stdout);

    sleep(seconds > 0 ? (unsigned int)seconds : 60);
    return 0;
}
