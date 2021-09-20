#!/usr/bin/env sh
# set -e

RCLONE=$(command -v rclone)

if [ -z ${GENERATE_CONFIG} ]; then
  GENERATE_CONFIG="/usr/sbin/generate-config.sh"
fi

if [ -z ${RCLONE_CONFIG} ]; then
  RCLONE_CONFIG="${HOME}/.config/rclone/rclone.conf"
fi

if [ -z ${RCLONE_CRYPT_STORE} ]; then
  RCLONE_CRYPT_STORE=gcrypt
fi

if [ -z ${DRIVE_TARGETFOLDER} ]; then
  DRIVE_TARGETFOLDER=
fi

if [ -z ${RCLONE_PID_FILE} ]; then
  RCLONE_PID_FILE=/tmp/rclone.pid
fi

if [ -z ${RCLONE_PID_DIR} ]; then
  RCLONE_PID_DIR=$(dirname ${RCLONE_PID_FILE})
fi

if [ ! -z ${USER_EMAIL} ]; then
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
if ! ${GENERATE_CONFIG}; then
  echo "Failed to generate configuration file."
  exit 4
fi

mkdir -p ${RCLONE_PID_DIR}

if [ -f ${RCLONE_PID_FILE} ]; then
  RCLONE_PID=$(<"$RCLONE_PID_FILE")
  if ps -p ${RCLONE_PID} > /dev/null
  then
    echo "RClone is running as PID ${RCLONE_PID}"
    exit 1
  fi
  rm ${RCLONE_PID_FILE}
fi

_term() { 
  echo "👋 Shutting down..."
  if [ ! -z "${CHILD_RCLONE}" ]; then
    kill -TERM "$CHILD_RCLONE" 2>/dev/null
  fi
  if [ ! -z "${CHILD_SLEEP}" ]; then
    echo "Exiting sleep"
    KEEP_RUNNING=false
    kill -TERM "$CHILD_SLEEP" 2>/dev/null
  fi
}

echo "🔌 Pusing to ${RCLONE_CRYPT_STORE}:${DRIVE_TARGETFOLDER}"

trap _term SIGTERM

KEEP_RUNNING=true
RCLONECMD="${RCLONE} ${DRIVE_IMPERSONATE} move --config ${RCLONE_CONFIG} --delete-after -v --stats 60s /upload ${RCLONE_CRYPT_STORE}:${DRIVE_TARGETFOLDER}"
while :
do
  nice -n 20 $RCLONECMD &
  CHILD_RCLONE=$! 
  echo "💪 Moving."
  wait "$CHILD_RCLONE"
  echo "😴 Moving finished, sleeping."
  sleep 1800 &
  CHILD_SLEEP=$!
  wait "$CHILD_SLEEP"
  if [ "$KEEP_RUNNING" != "true" ]; then
    exit 0
  fi
done
