# Dockerfile for anchorectl demonstration

FROM ubuntu:20.04
LABEL maintainer="alan.pope@anchore.com"
LABEL name="anchorectl-test"
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update -y
RUN apt install -y npm
RUN apt install -y openjdk-11-jdk
RUN apt install -y python3-pip
RUN pip3 install Werkzeug==2.3.7
RUN npm i darcyclarke-manifest-pkg@2.1.5
RUN npm i tar@4.4.16

COPY eicarcom2.zip  log4j-core-2.14.1.jar /

###     npm install -g --cache /tmp/empty-cache darcyclarke-manifest-pkg && \
RUN set -ex && \
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > /ssh_key && \
    npm cache clean --force && \
    rm -rf /var/lib/dpkg /tmp 

USER nobody 
ENTRYPOINT /bin/false
