#!/usr/bin/env sh

RSYNCCONF="${HOME}/.config/rclone/rclone.conf"
SERVICEACCOUNTFILE="${HOME}/.config/rclone/sa.conf"
RCLONE=$(command -v rclone)

RSYNCCONFFOLDER=$(dirname ${RSYNCCONF})
RSYNCCONFFILE=$(basename ${RSYNCCONF})

if [ -z ${RCLONE_BUFFER_SIZE} ]; then
  RCLONE_BUFFER_SIZE=128M
fi

if [ -z ${RCLONE_ZFS_CACHE_MODE} ]; then
  RCLONE_ZFS_CACHE_MODE=minimal
fi

if [ -z ${RCLONE_ZFS_READ_AHEAD} ]; then
  RCLONE_ZFS_READ_AHEAD=512M
fi

if [ -z ${RCLONE_CACHE} ]; then
  RCLONE_CACHE=false
fi

if [ -z ${RCLONE_TEAMDRIVE} ]; then
  RCLONE_TEAMDRIVE=false
fi

if [ -z ${DRIVE_TARGETFOLDER} ]; then
  DRIVE_TARGETFOLDER=
fi

mkdir -p ${RSYNCCONFFOLDER}

# Remove old configuration
if [ -f ${RSYNCCONF} ]; then
  rm -Rf ${RSYNCCONF}
fi

cat << EOF > ${RSYNCCONFFOLDER}/${RSYNCCONFFILE}
[gdrive]
type = drive
client_id = ${GOOGLE_CLIENTID}
client_secret = ${GOOGLE_CLIENTSECRET}
scope = drive
root_folder_id = ${DRIVE_ROOTFOLDER}
use_trash = false
skip_gdocs = true
chunk_size = 32M
EOF

if [ "$RCLONE_TEAMDRIVE" == "true" ]; then
cat << EOF >> ${RSYNCCONFFOLDER}/${RSYNCCONFFILE}
team_drive = ${DRIVE_ROOTFOLDER}
EOF

if [ ! -z ${DRIVE_ACCESSTOKEN} ]; then
cat << EOF >> ${RSYNCCONFFOLDER}/${RSYNCCONFFILE}
token = {"access_token":"${DRIVE_ACCESSTOKEN}","token_type":"Bearer","refresh_token":"${DRIVE_REFRESHTOKEN}","expiry":"${DRIVE_TOKENEXPIRY}"}
EOF
elif [ ! -z ${DRIVE_PROJECT_ID} ]; then
cat << EOF >> ${RSYNCCONFFOLDER}/${RSYNCCONFFILE}
service_account_file = ${SERVICEACCOUNTFILE}
EOF
cat << EOF > ${SERVICEACCOUNTFILE}
{
  "type": "service_account",
  "project_id": "${DRIVE_PROJECT_ID}",
  "private_key_id": "${DRIVE_PRIVATE_KEY_ID}",
  "private_key": "${DRIVE_PRIVATE_KEY}",
  "client_email": "${DRIVE_CLIENT_EMAIL}",
  "client_id": "${DRIVE_CLIENT_ID}",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "${DRIVE_CERTIFICATE_URL}"
}
EOF
else
  echo "No access method (token or service account). Giving up."
  sleep 10
  exit 1
fi

if [ "$RCLONE_CACHE" == "true" ]; then
FILE_REMOTE=gcache:
cat << EOF >> ${RSYNCCONFFOLDER}/${RSYNCCONFFILE}

[gcache]
type = cache
remote = gdrive:
chunk_size = 10M
info_age = 1h0m0s
chunk_total_size = 50G
EOF
if [ ! -z ${PLEX_HOST} ]; then
cat << EOF >> ${RSYNCCONFFOLDER}/${RSYNCCONFFILE}
plex_url = ${PLEX_HOST}
plex_username = ${PLEX_USERNAME}
plex_password = ${PLEX_PASSWORD}
plex_token = ${PLEX_TOKEN}
EOF
fi
else
  FILE_REMOTE=gdrive:
fi

cat << EOF >> ${RSYNCCONFFOLDER}/${RSYNCCONFFILE}

[gcrypt]
type = crypt
remote = ${FILE_REMOTE}
filename_encryption = standard
directory_name_encryption = true
password = ${GCRYPT_PASSWORD}
password2 = ${GCRYPT_PASSWORD2}
EOF

_term() { 
  echo "Shutting down..." 
  kill -TERM "$child" 2>/dev/null
}

trap _term SIGTERM

echo "Mounting..."
mkdir -p /mount${DRIVE_MOUNTFOLDER}
chown -R $(id -u):$(id -g) /mount${DRIVE_MOUNTFOLDER}
${RCLONE} lsd gcrypt:${DRIVE_TARGETFOLDER}
RCLONECMD="${RCLONE} mount --vfs-cache-mode ${RCLONE_ZFS_CACHE_MODE} --buffer-size ${RCLONE_BUFFER_SIZE} --vfs-read-ahead ${RCLONE_ZFS_READ_AHEAD} gcrypt:${DRIVE_TARGETFOLDER} /mount${DRIVE_MOUNTFOLDER}"
while :
do
  echo ${RCLONECMD}
  nice -n 20 $RCLONECMD &
  child=$! 
  echo "Ready."
  wait "$child"
  echo "Unmounting..."
  fusermount -u /mount${DRIVE_MOUNTFOLDER} && rm -Rf /mount${DRIVE_MOUNTFOLDER}
  echo "Finished..."
  exit 0
done
