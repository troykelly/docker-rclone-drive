FROM alpine

ARG APP_USER=drive
ARG APP_GROUP=drive
ARG BUILD_DESCRIPTION="Access an encrypted google drive"
ARG BUILD_NAME="RClone Mount Google Drive"
ARG BUILD_DATE
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

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
RUN apk add --no-cache --update curl unzip fuse su-exec

RUN cd ~ && \
 curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
 unzip rclone-current-linux-amd64.zip && \
 cd rclone-*-linux-amd64 && \
 cp rclone /usr/bin/ && \
 chmod 755 /usr/bin/rclone && \
 cd ~ && \
 rm -Rf ./rclone*

COPY ./mount.sh /usr/sbin/
COPY ./push.sh /usr/sbin/
COPY ./generate-config.sh /usr/sbin/
RUN chmod +x /usr/sbin/mount.sh /usr/sbin/push.sh /usr/sbin/generate-config.sh

RUN addgroup -g 1000 ${APP_GROUP} && \
 adduser -D -h /home/${APP_USER} -s /sbin/nologin -u 1000 -G ${APP_GROUP} ${APP_USER} && \
 chgrp -R ${APP_GROUP} /usr/sbin/mount.sh && \
 mkdir -p /mount /home/${APP_USER}/.config/rclone && \
 chown -R ${APP_USER}:${APP_GROUP} /mount /home/${APP_USER}

USER ${APP_USER}:${APP_GROUP}

CMD ["/usr/sbin/mount.sh"]
