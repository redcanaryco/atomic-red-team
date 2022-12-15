#include <errno.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <arpa/inet.h>
#include <linux/filter.h>
#include <netinet/ether.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <sys/socket.h>

#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))

static const struct option longopts[] = {
    {"afpacket", no_argument, NULL, 'a'},
    {"afinet4", no_argument, NULL, '4'},
    {"afinet6", no_argument, NULL, '6'},
    {"protocol", required_argument, NULL, 'p'},
    {"sockpacket", no_argument, NULL, 'P'},
    {"sockraw", no_argument, NULL, 'R'},
    {"filter", no_argument, NULL, 'f'},
    {"time", required_argument, NULL, 't'},
    {0, 0, 0, 0}};

static void usage(const char *progname) {
  printf("usage: %s <options>\n", progname);
  printf(" -a --afpacket                   Set domain to AF_PACKET.\n");
  printf(" -4 --afinet                     Set domain to AF_INET (default).\n");
  printf(" -6 --afinet6                    Set domain to AF_PACKET.\n");
  printf(" -p --protocol <int value>       Integer value to set as protocol "
         "argument. For AF_INET default is IPPROTO_TCP=6. "
         "Others:IPPROTO_UDP=17 IPPROTO_ICMP=1\n");
  printf(" -P --sockpacket                 Set sock_type to SOCK_PACKET.\n");
  printf(
      " -R --sockraw                    Set sock_type to SOCK_RAW (default)\n");
  printf(" -f --filter                     Adds BPF filter for UDP. Use with "
         "AF_PACKET.\n");
  printf(" -t --time <num seconds>         Exit after number of seconds. "
         "Default is to run until killed.\n");
}

void ProcessPacket(unsigned char *buf, int size, int af);

int sock_raw;
int tcp = 0, udp = 0, icmp = 0, others = 0, igmp = 0, total = 0, i, j;
struct sockaddr_in source, dest;

/*
 * Instructions generated using 'sudo tcpdump udp -dd'
 * https://andreaskaris.github.io/blog/networking/bpf-and-tcpdump/
 */
void SetBpfFilter(int sock_raw, int af) {
  if (AF_PACKET == af) {
    struct sock_filter instructions[] = {
        {0x28, 0, 0, 0x0000000c}, {0x15, 0, 5, 0x000086dd},
        {0x30, 0, 0, 0x00000014}, {0x15, 6, 0, 0x00000011},
        {0x15, 0, 6, 0x0000002c}, {0x30, 0, 0, 0x00000036},
        {0x15, 3, 4, 0x00000011}, {0x15, 0, 3, 0x00000800},
        {0x30, 0, 0, 0x00000017}, {0x15, 0, 1, 0x00000011},
        {0x6, 0, 0, 0x00040000},  {0x6, 0, 0, 0x00000000},
    };
    struct sock_fprog filter = {ARRAY_SIZE(instructions), instructions};
    int rv = setsockopt(sock_raw, SOL_SOCKET, SO_ATTACH_FILTER, &filter,
                        sizeof(filter));
    if (0 > rv) {
      printf("Failed to set BPF filter. errcode:%d\n", errno);
    }
  } else {

    // instructions have to be modified to offset from IP layer

    printf("ERROR: BPF filter is only setup to work for AF_PACKET\n");
  }
}

int main(int argc, char *argv[]) {
  int af = AF_INET;
  int sock_type = SOCK_RAW;
  int sock_protocol_inet = IPPROTO_TCP;
  int sock_protocol = sock_protocol_inet;
  int timeout = 0;
  int isBpfFilterEnabled = 0;

  int sock_protocol_packet = htons(3); // AF_PACKET

  socklen_t saddr_size;
  int data_size;
  struct sockaddr saddr;
  struct in_addr in;

  unsigned char *buffer = (unsigned char *)malloc(65536);

  int c;

  while (1) {
    int option_index = 0;

    c = getopt_long(argc, argv, "a46p:PRft:", longopts, &option_index);
    if (c == -1)
      break;

    switch (c) {
    case 'a':
      af = AF_PACKET;
      sock_protocol = sock_protocol_packet;
      break;
    case '4':
      af = AF_INET;
      break;
    case '6':
      af = AF_INET6;
      break;
    case 'P':
      sock_type = SOCK_PACKET;
      break;
    case 'R':
      sock_type = SOCK_RAW;
      break;
    case 'f':
      isBpfFilterEnabled = 1;
      break;
    case 'p':
      sock_protocol = atoi(optarg);
      printf("using protocol=%d (0x%x)\n", sock_protocol, sock_protocol);
      break;
    case 't':
      timeout = atoi(optarg);
      printf("will exit after %d seconds\n", timeout);
      break;
    default:
      printf("invalid argument: '%c'\n", c);
      usage(argv[0]);
      return -1;
    }
  }

  printf("Starting...\n");

  // create RAW socket to capture packets

  sock_raw = socket(af, sock_type, sock_protocol);
  if (sock_raw < 0) {
    printf("Socket Error\n");
    return 1;
  }

  if (isBpfFilterEnabled) {
    SetBpfFilter(sock_raw, af);
  }

  // loop to capture packets

  time_t tstop = time(NULL) + timeout;
  while (1) {
    int flags = MSG_DONTWAIT;
    saddr_size = sizeof saddr;
    // Receive a packet
    data_size = recvfrom(sock_raw, buffer, 65536, flags, &saddr, &saddr_size);
    if (data_size < 0) {
      if (EAGAIN == errno || EWOULDBLOCK == errno) {
        usleep(15000);
        if (timeout > 0 && time(NULL) >= tstop) {
          break;
        }
        continue;
      }

      printf("Recvfrom error , failed to get packets\n");
      return 1;
    }

    ProcessPacket(buffer, data_size, af);
  }
  close(sock_raw);
  printf("Finished\n");
  return 0;
}

void ProcessPacket(unsigned char *buffer, int size, int af) {
  unsigned char *pipbuf = buffer;
  ++total;

  if (AF_PACKET == af) {
    struct ether_header *eh = (struct ether_header *)buffer;
    if (ntohs(eh->ether_type) != ETHERTYPE_IP) {
      return;
    }
    pipbuf = buffer + sizeof(struct ether_header);
  }

  // Get the IP Header part of this packet
  struct iphdr *iph = (struct iphdr *)pipbuf;
  switch (iph->protocol) // Check the Protocol and do accordingly...
  {
  case IPPROTO_ICMP:
    ++icmp;
    break;

  case IPPROTO_TCP:
    ++tcp;
    break;

  case IPPROTO_UDP:
    ++udp;
    break;

  default:
    ++others;
    break;
  }
  printf("TCP : %d   UDP : %d   ICMP : %d   Others : %d   Total : %d\n", tcp,
         udp, icmp, others, total);
}
