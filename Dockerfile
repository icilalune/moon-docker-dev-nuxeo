# Nuxeo Base image is a ubuntu precise image with all the dependencies needed by Nuxeo Platform
#
# VERSION               0.0.1

FROM      ubuntu:precise
MAINTAINER Laurent Doguin <ldoguin@nuxeo.com>


# Set locale
RUN locale-gen --no-purge en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Install dependencies
ENV DEBIAN_FRONTEND noninteractive

# make sure the package repository is up to date
RUN echo "deb http://mir1.ovh.net/ubuntu precise  main restricted universe multiverse" > /etc/apt/sources.list
RUN echo "deb http://ftp.free.fr/mirrors/ftp.ubuntu.com/ubuntu precise  main restricted universe multiverse" >> /etc/apt/sources.list
RUN apt-get update

RUN apt-get install -y python-software-properties wget sudo net-tools


# Add Nuxeo Repository
RUN apt-add-repository "deb http://apt.nuxeo.org/ precise fasttracks"
RUN wget -q -O - http://apt.nuxeo.org/nuxeo.key | apt-key add -

# Upgrade Ubuntu
RUN apt-get update
RUN apt-get upgrade -y


# Small trick to Install fuse(libreoffice dependency) because of container permission issue.
RUN apt-get -y install fuse || true
RUN rm -rf /var/lib/dpkg/info/fuse.postinst
RUN apt-get -y install fuse

# Install Nuxeo Dependencies
RUN sudo apt-get install -y acpid openjdk-7-jdk openjdk-7-jre openjdk-7-jre-headless openjdk-7-jre-lib libreoffice imagemagick poppler-utils ffmpeg ffmpeg2theora ufraw libwpd-tools perl locales pwgen dialog supervisor unzip vim

RUN mkdir -p /var/log/supervisor

# create Nuxeo user
RUN useradd -m -d /home/nuxeo -p nuxeo nuxeo && adduser nuxeo sudo && chsh -s /bin/bash nuxeo
ENV NUXEO_USER nuxeo

# Download latest LTS nuxeo version
RUN wget http://community.nuxeo.com/static/releases/nuxeo-5.8/nuxeo-cap-5.8-tomcat.zip && mv nuxeo-cap-5.8-tomcat.zip nuxeo-distribution.zip

ENV NUXEOCTL /var/lib/nuxeo/server/bin/nuxeoctl
ENV NUXEO_CONF /etc/nuxeo/nuxeo.conf

# Add postgresql Repository
RUN apt-add-repository "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main"
RUN wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update

# Install apache and ssh server
RUN sudo apt-get install -y openssh-server apache2 postgresql-9.3
RUN mkdir -p /var/run/sshd

ADD supervisor_nuxeo.conf /etc/supervisor/conf.d/supervisor_nuxeo.conf
ADD nuxeo.apache2 /etc/apache2/sites-available/nuxeo
ADD postinst.sh /root/postinst.sh
ADD firstboot.sh /root/firstboot.sh
ADD entrypoint.sh /entrypoint.sh
ADD pgListener.py pgListener.py

RUN /root/postinst.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord"]

