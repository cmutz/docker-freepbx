# XiVO docker installation
FROM debian:jessie
MAINTAINER Clement Mutz "c.mutz@whoople.fr"

# Set ENV
ENV DEBIAN_FRONTEND noninteractive
ENV LANG fr_FR.UTF-8
ENV LC_ALL fr_FR.UTF-8
ENV HOME /root
ENV init /lib/systemd/systemd
ENV ASTERISKUSER asterisk

CMD ["/sbin/my_init"]

# Setup services
COPY start-apache2.sh /etc/service/apache2/run
RUN chmod +x /etc/service/apache2/run

COPY start-mysqld.sh /etc/service/mysqld/run
RUN chmod +x /etc/service/mysqld/run

COPY start-asterisk.sh /etc/service/asterisk/run
RUN chmod +x /etc/service/asterisk/run

COPY start-amportal.sh /etc/my_init.d/start-amportal.sh
RUN chmod +x /etc/my_init.d/start-amportal.sh

RUN apt-get -qq update \
    && apt-get upgrade -y \
    && apt-get -qq -y install \
                      	apt-utils \
                      	locales \
                      	wget \
                      	vim \
                      	net-tools \
                      	rsyslog \
                      	udev \
                      	iptables \
		      	kmod	\
		      	openssh-server \
			build-essential \ 
			linux-headers-`uname -r` \
			apache2 \
			mysql-server \
  			mysql-client \
			bison \
			flex \
			php5 \
			php5-curl \
			php5-cli \
			php5-mysql \
			php-pear \
			php5-gd \
			curl \
			sox \
			libncurses5-dev \
			libssl-dev \
			libmysqlclient-dev \
			mpg123 \
			libxml2-dev \
			libnewt-dev \
			sqlite3 \
			libsqlite3-dev \
			pkg-config \
			automake \
			libtool \
			autoconf \
			git \
			unixodbc-dev \
			uuid uuid-dev \
			libasound2-dev \
			libogg-dev \
			libvorbis-dev \
			libcurl4-openssl-dev \
			libical-dev \
			libneon27-dev \
			libsrtp0-dev \
			libspandsp-dev \
			sudo \
			libmyodbc \
			subversion \
			fail2ban \
			supervisor \
		&& apt-get clean \
		&& rm -rf /var/lib/apt/lists/*

# Update locales
RUN echo "fr_FR.UTF-8 UTF-8" > /etc/locale.gen
RUN locale-gen fr_FR.UTF-8
RUN update-locale LANG=fr_FR.UTF-8
RUN dpkg-reconfigure locales

# Replace default conf files to reduce memory usage
COPY conf/my-small.cnf /etc/mysql/my.cnf
COPY conf/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

# Install Legacy pear requirements
RUN pear install Console_Getopt

# Compile and install pjproject
WORKDIR /usr/src
RUN curl -sf -o pjproject.tar.bz2 -L http://www.pjsip.org/release/2.4/pjproject-2.4.tar.bz2 \
	&& tar -xjvf pjproject.tar.bz2 \
	&& rm -f pjproject.tar.bz2 \
	&& cd pjproject-2.4 \
	&& CFLAGS='-DPJ_HAS_IPV6=1' ./configure --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr \
	&& make dep \
	&& make \ 
	&& make install \
	&& rm -r /usr/src/pjproject-2.4

# Compile and Install jansson
WORKDIR /usr/src
RUN curl -sf -o jansson.tar.gz -L http://www.digip.org/jansson/releases/jansson-2.7.tar.gz \
	&& mkdir jansson \
	&& tar -xzf jansson.tar.gz -C jansson --strip-components=1 \
	&& rm jansson.tar.gz \
	&& cd jansson \
	&& autoreconf -i \
	&& ./configure \
	&& make \
	&& make install \
	&& rm -r /usr/src/jansson

# Compile and Install Asterisk
WORKDIR /usr/src
RUN curl -sf -o asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz \
	&& mkdir asterisk \
	&& tar -xzf /usr/src/asterisk.tar.gz -C /usr/src/asterisk --strip-components=1 \
	&& rm asterisk.tar.gz \
	&& cd asterisk \
	&& ./configure \
	&& contrib/scripts/get_mp3_source.sh \
	&& make menuselect.makeopts \
	&& sed -i "s/format_mp3//" menuselect.makeopts \
	&& sed -i "s/BUILD_NATIVE//" menuselect.makeopts \
	&& make \
	&& make install \
	&& make config \
	&& ldconfig \
	&& update-rc.d -f asterisk remove \
	&& rm -r /usr/src/asterisk
COPY conf/asterisk.conf /etc/asterisk/asterisk.conf

# Download extra sounds
WORKDIR /var/lib/asterisk/sounds
RUN curl -sf -o asterisk-core-sounds-fr-wav-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-fr-wav-current.tar.gz \
	&& tar -xzf asterisk-core-sounds-fr-wav-current.tar.gz \
	&& rm -f asterisk-core-sounds-fr-wav-current.tar.gz \
	&& curl -sf -o asterisk-extra-sounds-fr-wav-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-fr-wav-current.tar.gz \
	&& tar -xzf asterisk-extra-sounds-fr-wav-current.tar.gz \
	&& rm -f asterisk-extra-sounds-fr-wav-current.tar.gz \
	&& curl -sf -o asterisk-core-sounds-fr-g722-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-fr-g722-current.tar.gz \
	&& tar -xzf asterisk-core-sounds-fr-g722-current.tar.gz \
	&& rm -f asterisk-core-sounds-fr-g722-current.tar.gz \
	&& curl -sf -o asterisk-extra-sounds-fr-g722-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-fr-g722-current.tar.gz \
	&& tar -xzf asterisk-extra-sounds-fr-g722-current.tar.gz \
	&& rm -f asterisk-extra-sounds-fr-g722-current.tar.gz

# Add Asterisk user
RUN useradd -m $ASTERISKUSER \
	&& chown $ASTERISKUSER. /var/run/asterisk \ 
	&& chown -R $ASTERISKUSER. /etc/asterisk \
	&& chown -R $ASTERISKUSER. /var/lib/asterisk \
	&& chown -R $ASTERISKUSER. /var/log/asterisk \
	&& chown -R $ASTERISKUSER. /var/spool/asterisk \
	&& chown -R $ASTERISKUSER. /usr/lib/asterisk \
	&& chown -R $ASTERISKUSER. /var/www/ \
	&& chown -R $ASTERISKUSER. /var/www/* \
	&& rm -rf /var/www/html

# Configure apache
RUN sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php5/apache2/php.ini \
	&& cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig \
	&& sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf \
	&& sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Configure Asterisk database in MYSQL
RUN /etc/init.d/mysql start \
	&& mysqladmin -u root create asterisk \
	&& mysqladmin -u root create asteriskcdrdb \
	&& mysql -u root -e "GRANT ALL PRIVILEGES ON asterisk.* TO $ASTERISKUSER@localhost IDENTIFIED BY '';" \
	&& mysql -u root -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO $ASTERISKUSER@localhost IDENTIFIED BY '';" \
	&& mysql -u root -e "flush privileges;"

#Make CDRs work
COPY conf/cdr/odbc.ini /etc/odbc.ini
COPY conf/cdr/odbcinst.ini /etc/odbcinst.ini
COPY conf/cdr/cdr_adaptive_odbc.conf /etc/asterisk/cdr_adaptive_odbc.conf
RUN chown asterisk:asterisk /etc/asterisk/cdr_adaptive_odbc.conf \
	&& chmod 775 /etc/asterisk/cdr_adaptive_odbc.conf

# Download and install FreePBX
WORKDIR /usr/src
RUN curl -sf -o freepbx.tgz -L http://mirror.freepbx.org/modules/packages/freepbx/freepbx-13.0-latest.tgz \
	&& tar xfz freepbx.tgz \
	&& rm freepbx.tgz \
	&& cd /usr/src/freepbx \
	&& /etc/init.d/mysql start \
	&& mkdir /var/www/html \
	&& /etc/init.d/apache2 start \
	&& /usr/sbin/asterisk \
	&& sleep 5 \
	&& ./install -n \
	&& rm -r /usr/src/freepbx

WORKDIR /

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

VOLUME [ "/sys/fs/cgroup" ]
EXPOSE 22 80 443 5060 1000-2000
ENTRYPOINT ["/usr/bin/supervisord"]

