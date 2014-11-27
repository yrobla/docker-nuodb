FROM dockerfile/java:oracle-java7
MAINTAINER Yolanda Robla <info@ysoft.biz>

### Install dependencies ###
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
  apt-get -yq install pwgen && \
  rm -rf /var/lib/apt/lists/*

### Install nuodb ###
RUN wget -q -O /tmp/nuodb-2.0.4.linux.x64.deb "http://download.nuohub.org/nuodb-2.0.4.linux.x64.deb" && \
    sudo -E bash -c "dpkg --install /tmp/nuodb-2.0.4.linux.x64.deb" && \
    sudo rm /tmp/nuodb-2.0.4.linux.x64.deb

### Setup ###
# Mount volume
RUN mkdir -p /opt/nuodb/data && \
    mkdir -p /nuodb-override && \
    chown nuodb:nuodb /opt/nuodb/data
VOLUME ["/opt/nuodb/data", "/nuodb-override"]
RUN chown nuodb:nuodb /opt/nuodb/data

# Add files
ADD run.sh /run.sh
ADD default.properties.tpl /opt/nuodb/etc/default.properties.tpl
ADD webapp.properties.tpl /opt/nuodb/etc/webapp.properties.tpl

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
# Webconsole
EXPOSE 48009

CMD /run.sh 

