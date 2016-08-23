# XiVO docker installation
FROM debian:jessie
MAINTAINER Clement Mutz "c.mutz@whoople.fr"

# Set ENV
ENV DEBIAN_FRONTEND noninteractive
ENV LANG fr_FR.UTF-8
ENV LC_ALL fr_FR.UTF-8
ENV HOME /root
ENV init /lib/systemd/systemd


# Update locales
RUN echo "fr_FR.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen fr_FR.UTF-8
RUN update-locale LANG=fr_FR.UTF-8
RUN dpkg-reconfigure locales


# Fix
RUN rm /usr/sbin/policy-rc.d
RUN touch /etc/network/interfaces

# Fix for systemd on docker
RUN cd /lib/systemd/system/sysinit.target.wants/; ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1 \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*; \
    rm -f /lib/systemd/system/plymouth*; \
    rm -f /lib/systemd/system/systemd-update-utmp*;
RUN systemctl set-default multi-user.target

VOLUME [ "/sys/fs/cgroup" ]
EXPOSE 22 80 443 5060 1000-2000

ENTRYPOINT ["/lib/systemd/systemd"]
