FROM ubuntu:latest
WORKDIR /
RUN apt-get update && apt-get install nmap -y
RUN apt-get update && apt-get install -y tcpdump
RUN apt-get update && apt-get install net-tools
RUN apt-get update && apt-get install iproute2 -y
COPY scan.sh /scan.sh
RUN chmod +x /scan.sh
ENTRYPOINT ["tail", "-f", "/dev/null"]