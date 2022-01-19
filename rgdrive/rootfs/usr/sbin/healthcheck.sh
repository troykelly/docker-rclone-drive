#!/usr/bin/env sh

if [ -z "${RCLONE_PID_FILE}" ]; then
  RCLONE_PID_FILE=/tmp/rclone.pid
fi

if [[ ! -f "$RCLONE_PID_FILE" ]]; then
    exit 1
fi

PID=$(<$RCLONE_PID_FILE)

if [ -z "${PID}" ]; then
    exit 2
fi

kill ${PID} > /dev/null 2>&1
KILL_EXIT_CODE=$?

if [ $KILL_EXIT_CODE -ne 0 ]; then
    exit 3
fi

exit 0