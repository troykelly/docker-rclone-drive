# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.194.0/containers/alpine/.devcontainer/base.Dockerfile

# [Choice] Alpine version: 3.14, 3.13, 3.12, 3.11
ARG VARIANT="3.15"

FROM mcr.microsoft.com/vscode/devcontainers/base:0-alpine-${VARIANT}

# ** [Optional] Uncomment this section to install additional packages. **
RUN apk update \
    && apk add --no-cache curl unzip fuse su-exec

RUN cd ~ && \
 bash <(curl https://getcas.codenotary.io -L) && \
 curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
 unzip rclone-current-linux-amd64.zip && \
 cd rclone-*-linux-amd64 && \
 cp rclone /usr/bin/ && \
 chmod 755 /usr/bin/rclone && \
 cd ~ && \
 rm -Rf ./rclone* && \
 mkdir -p /mount && \
 chown -R vscode:vscode /mount