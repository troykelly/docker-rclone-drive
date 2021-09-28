FROM alpine:latest

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

ARG APP_USER=drive
ARG APP_GROUP=drive
ARG BUILD_DESCRIPTION="Access an encrypted google drive"
ARG BUILD_NAME="RClone Mount Google Drive"
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

COPY rootfs /

RUN echo Building for ${TARGETARCH}
RUN echo Building os ${TARGETOS}
RUN echo Building varient ${TARGETVARIANT}

RUN apk add --no-cache --update curl=7.79.1-r0 unzip=6.0-r9 fuse=2.9.9-r1 su-exec=0.2-r1 && \
 addgroup -g 1000 ${APP_GROUP} && \
 adduser -D -h /home/${APP_USER} -s /sbin/nologin -u 1000 -G ${APP_GROUP} ${APP_USER} && \
 mkdir -p /mount /home/${APP_USER}/.config/rclone && \
 chown -R ${APP_USER}:${APP_GROUP} /mount /home/${APP_USER}

COPY rootfs /
RUN chmod +x /usr/sbin/mount.sh /usr/sbin/push.sh /usr/sbin/generate-config.sh &&\
    chgrp -R ${APP_GROUP} /usr/sbin/mount.sh /usr/sbin/push.sh /usr/sbin/generate-config.sh

WORKDIR /home/${APP_USER}

RUN curl -O https://downloads.rclone.org/rclone-current-${TARGETOS}-${TARGETARCH}.zip && \
 unzip rclone-current-${TARGETOS}-${TARGETARCH}.zip && \
 cd rclone-*-${TARGETOS}-${TARGETARCH} && \
 cp rclone /usr/bin/ && \
 chmod 755 /usr/bin/rclone && \
 cd .. && \
 rm -Rf ./rclone*

USER ${APP_USER}:${APP_GROUP}

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