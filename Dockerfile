FROM dockerfile/java:oracle-java7
MAINTAINER Yolanda Robla <info@ysoft.biz>

### Install dependencies ###
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
  apt-get -yq install pwgen && \
  rm -rf /var/lib/apt/lists/*

### Install nuodb ###
RUN wget -q -O /tmp/nuodb_2.1.0.2.deb "http://download.nuohub.org/nuodb_2.1.0.2.deb" && \
    sudo -E bash -c "dpkg --install /tmp/nuodb_2.1.0.2.deb" && \
    sudo rm /tmp/nuodb_2.1.0.2.deb

### Setup ###
# Mount volume
RUN mkdir -p /var/opt/nuodb/production-archives
RUN chown nuodb:nuodb /var/opt/nuodb/production-archives
VOLUME ["/var/opt/nuodb/production-archives"]

# Add files
ADD run.sh /run.sh
ADD default.properties.tpl /opt/nuodb/etc/default.properties.tpl
ADD webapp.properties.tpl /opt/nuodb/etc/webapp.properties.tpl
ADD nuodb-rest-api.yml.tpl /opt/nuodb/etc/nuodb-rest-api.yml.tpl

RUN chmod +x /run.sh

# Environment variables
ENV NUODB_HOME /opt/nuodb
ENV AUTOMATION true
ENV AUTOMATION_BOOTSTRAP true
ENV LOG_LEVEL INFO

# Define working directory.
WORKDIR /opt/nuodb

# Broker
EXPOSE 48004
EXPOSE 48005
EXPOSE 48006
# For admin database
EXPOSE 48007
EXPOSE 48008
# for additional databases
EXPOSE 48009
EXPOSE 48010
EXPOSE 48011
EXPOSE 48012
EXPOSE 48013
EXPOSE 48014
EXPOSE 48015
EXPOSE 48016
EXPOSE 48017
EXPOSE 48018
EXPOSE 48019
EXPOSE 48020
EXPOSE 48021
EXPOSE 48022
EXPOSE 48023
EXPOSE 48024
EXPOSE 48025
EXPOSE 48026
EXPOSE 48027
EXPOSE 48028
EXPOSE 48029
EXPOSE 48030

# webconsole
EXPOSE 48080

# autoconsole
EXPOSE 8888
EXPOSE 8889

CMD /run.sh 
