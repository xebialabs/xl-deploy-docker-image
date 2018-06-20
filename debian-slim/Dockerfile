FROM alpine:3.7 as installer

# Install dependencies
RUN apk add --no-cache gawk unzip

ARG XLD_VERSION
ENV APP_ROOT=/opt
ENV APP_HOME=/opt/xl-deploy-server

# Install XL Deploy
ADD resources/xl-deploy-${XLD_VERSION}-server.zip /tmp
RUN mkdir -p ${APP_ROOT} && \
    unzip /tmp/xl-deploy-${XLD_VERSION}-server.zip -d ${APP_ROOT} && \
    mv ${APP_ROOT}/xl-deploy-${XLD_VERSION}-server ${APP_HOME}

# Add bin/run-in-container.sh
ADD resources/bin/run-in-container.sh ${APP_HOME}/bin/

# Modify bin/run.sh so that java becomes a child process of dumb-init
RUN sed -i 's/^\($JAVACMD $XL_RELEASE_SERVER_OPTS\)/exec \1/' ${APP_HOME}/bin/run.sh

# Move and augment conf directory of regular install
RUN mv ${APP_HOME}/conf ${APP_HOME}/default-conf && \
    mkdir ${APP_HOME}/conf
COPY resources/default-conf ${APP_HOME}/default-conf

# Modify conf/xld-wrapper-linux.conf to add node-conf to the classpath and to add container-specific VM options
RUN gawk -i inplace '/^wrapper.java.classpath.1=/ { print "wrapper.java.classpath.1=node-conf" } \
{ if (match($0, /^(wrapper.java.classpath).([0-9]+)=(.*)$/, a)) { printf("%s.%d=%s\n", a[1], (a[2]+1), a[3]) } else \
  if (/^wrapper.java.additional.1=-Xms1024m$/) { print "wrapper.java.additional.1=-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap" } else \
  { print $0 }}' ${APP_HOME}/default-conf/xld-wrapper-linux.conf

# Create node-specific conf directory and add template for node-specific xl-deploy.conf file
RUN mkdir ${APP_HOME}/node-conf
ADD resources/node-conf/xl-deploy.conf.template ${APP_HOME}/node-conf

# Move plugins directory
RUN mv ${APP_HOME}/plugins ${APP_HOME}/default-plugins && \
    mkdir ${APP_HOME}/plugins

# Create empty repository directory
RUN mkdir ${APP_HOME}/repository

# Set permissions
RUN chgrp -R 0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT} && \
    chmod g+x ${APP_HOME}/bin/*.sh

FROM openjdk:8-jdk-slim-stretch
MAINTAINER XebiaLabs Development <docker@xebialabs.com>

LABEL name="xebialabs/xl-deploy" \
      maintainer="docker@xebialabs.com" \
      vendor="XebiaLabs" \
      version="8.1.0-rc.2" \
      release="1" \
      summary="XL Deploy" \
      description="Enterprise-scale Application Release Automation for any environment" \
      url="https://www.xebialabs.com/xl-deploy"

# Install dependencies
RUN apt-get update && \
    apt-get install -y dumb-init pwgen && \
    apt-get clean

ENV USER_NAME=xl-deploy USER_UID=10001 APP_ROOT=/opt
ENV APP_HOME=/opt/xl-deploy-server

# Copy installed XL Deploy
COPY --from=installer ${APP_ROOT} ${APP_ROOT}

WORKDIR ${APP_HOME}

# Don't run as root
USER 10001

VOLUME ["${APP_HOME}/conf", "${APP_HOME}/hotfix/lib", "${APP_HOME}/hotfix/plugins", "${APP_HOME}/ext", "${APP_HOME}/plugins", "${APP_HOME}/repository"]
EXPOSE 4516

# Environment variables are not expanded when using the exec form of the ENTRYPOINT command. They are
# expanded when using the shell form, but that results in dumb-init running with a PID higher than 1.
ENTRYPOINT ["/usr/bin/dumb-init", "/opt/xl-deploy-server/bin/run-in-container.sh"]
