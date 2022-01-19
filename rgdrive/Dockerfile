FROM alpine:latest

ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG TARGETVARIANT=

ARG APP_USER=drive
ARG APP_GROUP=drive
ARG BUILD_DESCRIPTION="Access an encrypted google drive"
ARG BUILD_NAME="RClone Mount Google Drive"
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

COPY rootfs /

RUN apk add --no-cache --update curl=7.80.0-r0 unzip=6.0-r9 fuse=2.9.9-r1 su-exec=0.2-r1 libarchive-tools=3.5.2-r0 && \
 addgroup -g 1000 ${APP_GROUP} && \
 adduser -D -h /home/${APP_USER} -s /sbin/nologin -u 1000 -G ${APP_GROUP} ${APP_USER} && \
 mkdir -p /mount /home/${APP_USER}/.config/rclone && \
 chown -R ${APP_USER}:${APP_GROUP} /mount /home/${APP_USER} && \
 chmod +x /usr/sbin/mount.sh /usr/sbin/push.sh /usr/sbin/generate-config.sh &&\
 chgrp -R ${APP_GROUP} /usr/sbin/mount.sh /usr/sbin/push.sh /usr/sbin/generate-config.sh

WORKDIR /home/${APP_USER}

RUN if [ "$TARGETARCH" = "arm" ] && [ "$TARGETVARIANT" = "v7" ] ;\
    then curl -L https://downloads.rclone.org/rclone-current-${TARGETOS}-${TARGETARCH}-${TARGETVARIANT}.zip -o rclone-current-${TARGETOS}-${TARGETARCH}.zip ;\
    else curl -LO https://downloads.rclone.org/rclone-current-${TARGETOS}-${TARGETARCH}.zip ; fi && \
 mkdir rclone-current-${TARGETOS}-${TARGETARCH} && \
 cd rclone-current-${TARGETOS}-${TARGETARCH} && \
 bsdtar -xf ../rclone-current-${TARGETOS}-${TARGETARCH}.zip -s'|[^/]*/||' && \
 cp rclone /usr/bin/ && \
 chmod 755 /usr/bin/rclone && \
 cd .. && \
 rm -Rf ./rclone* && \
 /usr/bin/rclone version --check

USER ${APP_USER}:${APP_GROUP}

ARG HEALTHCHECK_INTERVAL=30s
ARG HEALTHCHECK_TIMEOUT=30s
ARG HEALTHCHECK_START_PERIOD=4m
ARG HEALTHCHECK_RETRIES=3

ARG RCLONE_PID_FILE=/tmp/rclone.pid
ENV RCLONE_PID_FILE=${RCLONE_PID_FILE}

HEALTHCHECK --interval=${HEALTHCHECK_INTERVAL} \
    --timeout=${HEALTHCHECK_TIMEOUT} \
    --start-period=${HEALTHCHECK_START_PERIOD} \
    --retries=${HEALTHCHECK_RETRIES} \
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