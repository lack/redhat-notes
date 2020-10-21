from fedora:latest
RUN dnf install -y iptables iproute psutils iputils nftables iptables-nft libcap tcpdump strace
RUN touch /run/xtables.lock ; chmod 666 /run/xtables.lock
COPY setsockopt/setsockopt /bin/
CMD /bin/bash -c "while true; do sleep 10; echo Running; done"
