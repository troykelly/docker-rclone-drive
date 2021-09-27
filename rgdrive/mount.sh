#!/usr/bin/env sh
# set -e

RCLONE=$(command -v rclone)

if [ -z "${GENERATE_CONFIG}" ]; then
  GENERATE_CONFIG="/usr/sbin/generate-config.sh"
fi

if [ -z "${RCLONE_CONFIG}" ]; then
  RCLONE_CONFIG="${HOME}/.config/rclone/rclone.conf"
fi

if [ -z "${RCLONE_PRIMARY_STORE}" ]; then
  RCLONE_PRIMARY_STORE=gdrive
fi

if [ -z "${RCLONE_CRYPT_STORE}" ]; then
  RCLONE_CRYPT_STORE=gcrypt
fi

if [ -z "${DRIVE_TARGETFOLDER}" ]; then
  DRIVE_TARGETFOLDER=
fi

if [ -z "${DRIVE_MOUNTFOLDER}" ]; then
  DRIVE_MOUNTFOLDER=/filestore
fi

# Deprecated: I made a mistake and called these ZFS - so backwards compat for now
if [ -n "${RCLONE_ZFS_CACHE_MODE}" ]; then
  RCLONE_VFS_CACHE_MODE=${RCLONE_ZFS_CACHE_MODE}
fi

if [ -n "${RCLONE_ZFS_READ_AHEAD}" ]; then
  RCLONE_VFS_READ_AHEAD=${RCLONE_ZFS_READ_AHEAD}
fi

# https://rclone.org/commands/rclone_mount/#vfs-file-caching
if [ -z "${RCLONE_VFS_CACHE_MODE}" ]; then
  RCLONE_VFS_CACHE_MODE=minimal
fi

if [ -z "${RCLONE_VFS_READ_AHEAD}" ]; then
  RCLONE_VFS_READ_AHEAD=512M
fi

if [ -z "${RCLONE_BUFFER_SIZE}" ]; then
  RCLONE_BUFFER_SIZE=128M
fi

if [ -z "${RCLONE_PID_FILE}" ]; then
  RCLONE_PID_FILE=/tmp/rclone.pid
fi

if [ -z "${BANDWIDTH_INGRESS}" ]; then
  BANDWIDTH_INGRESS=off
fi

if [ -z "${BANDWIDTH_EGRESS}" ]; then
  BANDWIDTH_EGRESS=off
fi

if [ -z "${FORCE_NO_CRYPT}" ]; then
  FORCE_NO_CRYPT=false
fi

if [ -z "${RCLONE_PID_DIR}" ]; then
  RCLONE_PID_DIR=$(dirname "${RCLONE_PID_FILE}")
fi

if [ -n "${USER_EMAIL}" ]; then
  DRIVE_IMPERSONATE="--drive-impersonate ${USER_EMAIL}"
else
  DRIVE_IMPERSONATE=
fi

if [[ ! -x "$GENERATE_CONFIG" ]]
then
  echo "Unable to generate configuration. ${GENERATE_CONFIG} is not executable."
  exit 3
fi

# Generate configuration files
if ! "${GENERATE_CONFIG}"; then
  echo "Failed to generate configuration file."
  exit 4
fi

if [ "$FORCE_NO_CRYPT" == "true" ]; then
  RCLONE_MOUNT_POINT=${RCLONE_PRIMARY_STORE}
else
  RCLONE_MOUNT_POINT=${RCLONE_CRYPT_STORE}
fi

mkdir -p "${RCLONE_PID_DIR}"

if [ -f "${RCLONE_PID_FILE}" ]; then
  RCLONE_PID=$(<"$RCLONE_PID_FILE")
  if ps -p "${RCLONE_PID}" > /dev/null
  then
    echo "RClone is running as PID ${RCLONE_PID}"
    exit 1
  fi
  rm ${RCLONE_PID_FILE}
fi

_term() { 
  echo "👋 Shutting down..."
  if [ -n "${CHILD_RCLONE}" ]; then
    kill -TERM "$CHILD_RCLONE" 2>/dev/null
  fi
  if [ -n "${CHILD_UNMOUNT}" ]; then
    echo "Waiting for unmount"
  fi
  if [ -n "${CHILD_RM}" ]; then
    echo "Waiting for cleanup"
  fi
}

trap _term SIGTERM

fusermount -u /mount${DRIVE_MOUNTFOLDER} || true
mkdir -p "/mount${DRIVE_MOUNTFOLDER}" || true
${RCLONE} -v "${DRIVE_IMPERSONATE}" --config "${RCLONE_CONFIG}" lsd "${RCLONE_MOUNT_POINT}:${DRIVE_TARGETFOLDER}"
RCLONECMD="${RCLONE} ${DRIVE_IMPERSONATE} --bwlimit ${BANDWIDTH_EGRESS}:${BANDWIDTH_INGRESS} mount --config ${RCLONE_CONFIG} --allow-non-empty --vfs-cache-mode ${RCLONE_VFS_CACHE_MODE} --buffer-size ${RCLONE_BUFFER_SIZE} --vfs-read-ahead ${RCLONE_VFS_READ_AHEAD} ${RCLONE_MOUNT_POINT}:${DRIVE_TARGETFOLDER} /mount${DRIVE_MOUNTFOLDER}"
while :
do
  echo "🔌 Mounting ${RCLONE_MOUNT_POINT}:${DRIVE_TARGETFOLDER} at /mount${DRIVE_MOUNTFOLDER}"
  nice -n 20 "$RCLONECMD" &
  CHILD_RCLONE=$! 
  echo "${CHILD_RCLONE}" > ${RCLONE_PID_FILE}
  echo "💾 Ready (${CHILD_RCLONE})."
  wait "$CHILD_RCLONE"
  fusermount -u /mount${DRIVE_MOUNTFOLDER} &
  CHILD_UNMOUNT=$!
  echo "${CHILD_UNMOUNT}" > ${RCLONE_PID_FILE}
  echo "🛑 Unmounting."
  wait "$CHILD_UNMOUNT"
  rm -Rf /mount${DRIVE_MOUNTFOLDER} &
  CHILD_RM=$!
  echo "${CHILD_RM}" > ${RCLONE_PID_FILE}
  echo "␡ Remove mount point"
  wait "$CHILD_RM"
  rm ${RCLONE_PID_FILE}
  echo "🧹 Cleanup finished."
  exit 0
done
