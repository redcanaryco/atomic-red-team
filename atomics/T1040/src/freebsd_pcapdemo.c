#include <fcntl.h>
#include <getopt.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/errno.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

#include <arpa/inet.h>
#include <net/bpf.h>
#include <net/if.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <netinet/ip.h>
#include <netinet/if_ether.h>
#include <netinet/in.h>

#define DEFAULT_IFNAME "en0"
#define DEFAULT_BUFSIZE 32767

static const struct option longopts[] = {
    { "filter",  no_argument,  NULL, 'f'},
    { "promisc",  no_argument,  NULL, 'p'},
    { "ifname",  required_argument,  NULL, 'i'},
    { "time",    required_argument,  NULL, 't'},
    { 0, 0, 0, 0 }
};

// counters for each protocol seen

static int64_t gNumTcp = 0;
static int64_t gNumUdp = 0;
static int64_t gNumIcmp = 0;
static int64_t gNumOther = 0;

static void usage(const char *progname)
{
    printf("usage: %s <options>\n", progname);
    printf(" -f --filter                     Set BPF filter to UDP. Default is unfiltered.\n");
    printf(" -p --promisc                    Will enable promisc to capture packets not destined for this system.\n");
    printf(" -i --ifname <interface name>    Specify ifname. Default is 'en0'.\n");
    printf(" -t --time <num seconds>         Exit after number of seconds. Default is to run until killed.\n");
}

typedef struct {
    char interfaceName[16];
    unsigned int bufferLength;
} BpfOption;

typedef struct {
    int fd;
    char deviceName[16];
    unsigned int bufferLength;
    unsigned int lastReadLength;
    unsigned int readBytesConsumed;
    char *buffer;
} BpfSniffer;

typedef struct {
    char *data;
} CapturedInfo;

/*
 * pick next available /dev/bpf<N> device file.
 * @returns 0 and sets sniffer->fd on success, returns -1 on failure.
 */
int pick_bpf_device(BpfSniffer *sniffer)
{
    char dev[16] = {0};
    for (int i = 0; i < 99; ++i) {
        sprintf(dev, "/dev/bpf%i", i);
        sniffer->fd = open(dev, O_RDONLY);
        if (sniffer->fd != -1) {
            fprintf(stderr, "opened '%s'\n", dev);
            strcpy(sniffer->deviceName, dev);
            return 0;
        }
    }
    return -1;
}

/*
 * Based on https://gist.github.com/c-bata/ca188c0184715efc2660422b4b3851c6
 */
int new_bpf_sniffer(const char *ifname, BpfSniffer *sniffer, int isBpfFilterEnabled, int isPromiscEnabled)
{
    unsigned int bufferLength = DEFAULT_BUFSIZE;
    if (pick_bpf_device(sniffer) == -1)
        return -1;

    // setup packet buffer length

    if (ioctl(sniffer->fd, BIOCSBLEN, &bufferLength) == -1) {
        perror("ioctl BIOCSBLEN");
        return -1;
    }
    sniffer->bufferLength = bufferLength;

    // specify interface

    struct ifreq interface;
    strcpy(interface.ifr_name, ifname);
    if(ioctl(sniffer->fd, BIOCSETIF, &interface) > 0) {
        perror("ioctl BIOCSETIF");
        return -1;
    }

    // immediate packet callback?

    unsigned int enable = 1;
    if (ioctl(sniffer->fd, BIOCIMMEDIATE, &enable) == -1) {
        perror("ioctl BIOCIMMEDIATE");
        return -1;
    }

    // enable Promisc if enabled

    if (isPromiscEnabled) {
        printf("Attempting to enable PRMOMISC\n");
        if (ioctl(sniffer->fd, BIOCPROMISC, NULL) == -1) {
            perror("ioctl BIOCPROMISC");
            return -1;
        }
    }

    // set a BPF traffic filter if set

    if (isBpfFilterEnabled) {
        // generated using 'tcpdump -i en0 udp -dd'
        struct bpf_insn instructions[] = {
{ 0x28, 0, 0, 0x0000000c },
{ 0x15, 0, 5, 0x000086dd },
{ 0x30, 0, 0, 0x00000014 },
{ 0x15, 6, 0, 0x00000011 },
{ 0x15, 0, 6, 0x0000002c },
{ 0x30, 0, 0, 0x00000036 },
{ 0x15, 3, 4, 0x00000011 },
{ 0x15, 0, 3, 0x00000800 },
{ 0x30, 0, 0, 0x00000017 },
{ 0x15, 0, 1, 0x00000011 },
{ 0x6, 0, 0, 0x00040000 },
{ 0x6, 0, 0, 0x00000000 },
            };
        struct bpf_program filter = {12, instructions};

        printf("Adding BPF filter to only match 'udp' traffic\n");

        if (ioctl(sniffer->fd, BIOCSETF, &filter) == -1) {
            perror("ioctl BIOCSETF");
            return -1;
        }
    }

    // finally, allocate buffer and initialize

    sniffer->readBytesConsumed = 0;
    sniffer->lastReadLength = 0;
    sniffer->buffer = (char *)malloc(sizeof(char) * sniffer->bufferLength);
    return 0;
}

int read_bpf_packet_data(BpfSniffer *sniffer, CapturedInfo *info)
{
    struct bpf_hdr *bpfPacket;
    if (sniffer->readBytesConsumed + sizeof(sniffer->buffer) >= sniffer->lastReadLength) {
        sniffer->readBytesConsumed = 0;
        memset(sniffer->buffer, 0, sniffer->bufferLength);

        ssize_t lastReadLength = read(sniffer->fd, sniffer->buffer, sniffer->bufferLength);
        if (lastReadLength == -1) {
            sniffer->lastReadLength = 0;
            perror("read bpf packet:");
            return -1;
        }
        sniffer->lastReadLength = (unsigned int) lastReadLength;
    }

    bpfPacket = (struct bpf_hdr*)((long)sniffer->buffer + (long)sniffer->readBytesConsumed);
    info->data = sniffer->buffer + (long)sniffer->readBytesConsumed + bpfPacket->bh_hdrlen;
    sniffer->readBytesConsumed += BPF_WORDALIGN(bpfPacket->bh_hdrlen + bpfPacket->bh_caplen);
    return bpfPacket->bh_datalen;
}

int close_bpf_sniffer(BpfSniffer *sniffer)
{
    free(sniffer->buffer);

    if (close(sniffer->fd) == -1)
        return -1;
    return 0;
}

void ProcessIncomingPacketLoop(BpfSniffer *psniffer, int timeout)
{
    CapturedInfo info = { NULL };
    int dataLength = 0;
    time_t tstop = time(NULL) + timeout;

    // loop to process incoming packets

    while((dataLength = read_bpf_packet_data(psniffer, &info)) != -1)
    {
        char* pend = (info.data + dataLength);
        struct ether_header* eh = (struct ether_header*)info.data;

        if (ntohs(eh->ether_type) == ETHERTYPE_IP) {

            struct ip* ip = (struct ip*)((long)eh + sizeof(struct ether_header));
            switch(ip->ip_p) {
                case IPPROTO_TCP:
                    ++gNumTcp;
                    break;
                case IPPROTO_UDP:
                    ++gNumUdp;
                    break;
                case IPPROTO_ICMP:
                    ++gNumIcmp;
                    break;
                default:
                    ++gNumOther;
                    break;
            }

        } else {
            gNumOther++;
        }

        if (timeout > 0 && time(NULL) >= tstop) {
            break;
        }
    }    
}

void PrintStats()
{
    printf("TCP:%lld UDP:%lld ICMP:%lld Other:%lld\n", gNumTcp, gNumUdp, gNumIcmp, gNumOther);    
}

void sigint_handler(int sig)
{
    PrintStats();
}

int main(int argc, char *argv[])
{
    BpfSniffer sniffer;
    int isBpfFilterEnabled = 0;
    int isPromiscEnabled = 0;
    int timeout = 0;
    char ifname[16] = DEFAULT_IFNAME;
    int c;

    memset(&sniffer, 0, sizeof(sniffer));

    while(1)
    {
        int option_index = 0;

        c = getopt_long(argc, argv, "fpi:t:", longopts, &option_index);
        if (c == -1)
            break;

        switch (c) {
        case 'f':
            isBpfFilterEnabled = 1;
            break;
        case 'p':
            isPromiscEnabled = 1;
            break;
        case 'i':
            strcpy(ifname, optarg);
            printf("using interface '%s'\n", optarg);
            break;
        case 't':
            timeout = atoi(optarg);
            printf("will exit after about %d seconds (if packet activity)\n", timeout);
            break;
        default:
            printf("invalid argument: '%c'\n", c);
            usage(argv[0]);
            return -1;
        }
    }

    if (new_bpf_sniffer(ifname, &sniffer, isBpfFilterEnabled, isPromiscEnabled) == -1)
        return 1;

    signal(SIGINT, sigint_handler);

    ProcessIncomingPacketLoop(&sniffer, timeout);

    PrintStats();

    close_bpf_sniffer(&sniffer);
    return 0;
}
