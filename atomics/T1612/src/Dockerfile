FROM ubuntu:20.04
WORKDIR /
LABEL key="CyberSecurity_project"
RUN echo "CyberSecurity_project"
RUN apt update && apt install -y git
COPY test.sh /test.sh
RUN chmod +x /test.sh
ENTRYPOINT ["tail", "-f", "/dev/null"]

