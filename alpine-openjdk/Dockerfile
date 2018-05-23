FROM alpine:3.7 as installer

# Install dependencies
RUN apk -U upgrade && apk add unzip

ARG XLD_VERSION
ENV APP_ROOT=/opt/xl-deploy
ENV APP_HOME=${APP_ROOT}/xld-server BOOTSTRAP_DIR=${APP_ROOT}/xld-bootstrap DATA_DIR=${APP_ROOT}/xld-data

# Install XL Deploy
COPY xl-deploy-${XLD_VERSION}-server.zip /tmp
RUN mkdir -p ${APP_ROOT} && \
    unzip /tmp/xl-deploy-${XLD_VERSION}-server.zip -d ${APP_ROOT} && \
    mv ${APP_ROOT}/xl-deploy-${XLD_VERSION}-server ${APP_HOME} && \
    mkdir ${BOOTSTRAP_DIR} && \
    mkdir ${DATA_DIR} && \
    chgrp -R 0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT}

# Add run-in-container script
COPY bin/run-in-container.sh ${APP_HOME}/bin
RUN chmod g+x ${APP_HOME}/bin/run-in-container.sh && \
    chgrp 0 ${APP_HOME}/bin/run-in-container.sh

# Add modified run script
COPY bin/run.sh ${APP_HOME}/bin
RUN chmod g+x ${APP_HOME}/bin/run.sh && \
    chgrp 0 ${APP_HOME}/bin/run.sh

FROM openjdk:8-jdk-alpine3.7
MAINTAINER XebiaLabs Development <docker@xebialabs.com>

LABEL name="xebialabs/xl-deploy" \
      maintainer="docker@xebialabs.com" \
      vendor="XebiaLabs" \
      version="${XLD_VERSION}" \
      release="1" \
      summary="XL Deploy" \
      description="Deployment automation" \
### Required labels above - recommended below
      url="https://www.xebialabs.com/xl-deploy"
      # run='docker run -tdi --name ${NAME} ${IMAGE}' \
      # io.k8s.description="Starter app will do ....." \
      # io.k8s.display-name="Starter app" \
      # io.openshift.expose-services="" \
      # io.openshift.tags="acme,starter"


# Install dependencies
RUN apk -U upgrade && apk add bash dumb-init

# Copy installed XL Deploy
ENV USER_NAME=xl-dpeloy USER_UID=10001 APP_ROOT=/opt/xl-deploy
ENV APP_HOME=${APP_ROOT}/xld-server BOOTSTRAP_DIR=${APP_ROOT}/xld-bootstrap DATA_DIR=${APP_ROOT}/xld-data

COPY --from=installer ${APP_ROOT} ${APP_ROOT}

# Copy configuration templates
COPY conf-templates /tmp/templates

# Don't run as root
USER 10001
WORKDIR ${APP_HOME}

# plugins, hotfix, ext and conf will be copied from the /xlr-bootstrap by the bootstrapper into the installation
# repository and archive will be the persistent data layer for the standalone version of XLR
VOLUME ${BOOTSTRAP_DIR} ${DATA_DIR}

ENV CLUSTER_MODE default
ENV DB_TYPE h2
ENV REPO_DB_URL jdbc:h2:file:${DATA_DIR}/xld-repo
ENV REPO_DB_USERNAME sa
ENV REPO_DB_PASSWORD 123
ENV ARCHIVE_DB_URL jdbc:h2:file:${DATA_DIR}/xld-archive
ENV ARCHIVE_DB_USERNAME sa
ENV ARCHIVE_DB_PASSWORD 123
ENV METRICS_ENABLED false
ENV DEVELOPMENT_MODE false

EXPOSE 4516
# Environment variables are not expanded when using the exec form of the ENTRYPOINT command. They are
# expanded when using the shell form, but that results in dumb-init running with a PID higher than 1.
ENTRYPOINT ["/usr/bin/dumb-init", "/opt/xl-deploy/xld-server/bin/run-in-container.sh"]
