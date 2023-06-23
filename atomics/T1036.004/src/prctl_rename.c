#include        <sys/prctl.h>
#include        <unistd.h>
#include        <stdio.h>

int
main (int argc, const char* const argv[])
{
	const char *new_name = "totally_legit";

        if (prctl(PR_SET_NAME, new_name, 0, 0, 0) < 0) {
                perror("prctl");
                return 4;
        }
	usleep(3*1000000);

        return 0;
}
