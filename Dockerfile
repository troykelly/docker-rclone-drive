FROM alpine

ARG APP_USER=drive
ARG APP_GROUP=drive
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.opencontainers.image.source https://github.com/troykelly/docker-rclone-drive
LABEL org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="RClone Mount Google Drive" \
  org.label-schema.description="Access an encrypted google drive" \
  org.label-schema.url="https://github.com/troykelly/docker-rclone-drive" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/troykelly/docker-rclone-drive" \
  org.label-schema.vendor="Troy Kelly" \
  org.label-schema.version=$VERSION \
  org.label-schema.schema-version="1.0"
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
RUN chmod +x /usr/sbin/mount.sh

RUN addgroup -g 1000 ${APP_GROUP} && \
 adduser -D -h /home/${APP_USER} -s /sbin/nologin -u 1000 -G ${APP_GROUP} ${APP_USER} && \
 chgrp -R ${APP_GROUP} /usr/sbin/mount.sh && \
 mkdir /mount && \
 chown -R ${APP_USER}:${APP_GROUP} /mount

# USER ${APP_USER}:${APP_GROUP}

CMD ["/usr/sbin/mount.sh"]
