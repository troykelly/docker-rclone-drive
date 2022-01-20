FROM ubuntu:latest

ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG TARGETVARIANT=

ARG APP_USER=drive
ARG APP_GROUP=drive
ARG BUILD_DESCRIPTION="Access an encrypted google drive"
ARG RCLONE_VERSION=1.56.2
ARG BUILD_NAME="RClone v${RCLONE_VERSION} Mount Google Drive"
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION


COPY rootfs /

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates=20210119~20.04.2 \
    curl=7.68.0-1ubuntu2.7 \
    fuse=2.9.9-3 \
    libarchive-tools=3.4.0-2ubuntu1 \
    unzip=6.0-25ubuntu1 && \
    rm -rf /var/lib/apt/lists/* && \
    addgroup --gid 1000 ${APP_GROUP} && \
    adduser --disabled-login --home /home/${APP_USER} --shell /sbin/nologin --uid 1000 --ingroup ${APP_GROUP} --gecos "${APP_USER},,,,Script User" ${APP_USER} && \
    mkdir -p /mount /home/${APP_USER}/.config/rclone && \
    chown -R ${APP_USER}:${APP_GROUP} /mount /home/${APP_USER} && \
    chmod +x /usr/sbin/mount.sh /usr/sbin/push.sh /usr/sbin/generate-config.sh /usr/sbin/healthcheck.sh && \
    chgrp -R ${APP_GROUP} /usr/sbin/mount.sh /usr/sbin/push.sh /usr/sbin/generate-config.sh /usr/sbin/healthcheck.sh

WORKDIR /home/${APP_USER}

RUN if [ "$TARGETARCH" = "arm" ] && [ "$TARGETVARIANT" = "v7" ] ;\
    then curl -L https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-${TARGETOS}-${TARGETARCH}-${TARGETVARIANT}.zip -o rclone-${RCLONE_VERSION}-${TARGETOS}-${TARGETARCH}.zip ;\
    else curl -L https://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-${TARGETOS}-${TARGETARCH}.zip  -o rclone-${RCLONE_VERSION}-${TARGETOS}-${TARGETARCH}.zip ; fi && \
 mkdir rclone-${RCLONE_VERSION}-${TARGETOS}-${TARGETARCH} && \
 cd rclone-${RCLONE_VERSION}-${TARGETOS}-${TARGETARCH} && \
 bsdtar -xf ../rclone-${RCLONE_VERSION}-${TARGETOS}-${TARGETARCH}.zip -s'|[^/]*/||' && \
 cp rclone /usr/bin/ && \
 chmod 755 /usr/bin/rclone && \
 cd .. && \
 rm -Rf ./rclone* && \
 /usr/bin/rclone version --check

USER ${APP_USER}:${APP_GROUP}

HEALTHCHECK --interval=30s \
    --timeout=30s \
    --start-period=4m \
    --retries=3 \
    CMD /usr/sbin/healthcheck.sh

CMD ["/usr/sbin/mount.sh"]

LABEL \
    maintainer="Troy Kelly <troy@troykelly.com>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Troy Kelly" \
    org.opencontainers.image.authors="Troy Kelly <troy@troykelly.com>" \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.url="https://troykelly" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}