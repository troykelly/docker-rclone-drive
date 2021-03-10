#!/usr/bin/env sh

DRIVE_USER=$(getent passwd "1000" | cut -d: -f1)
DRIVE_HOMEDIR=$( getent passwd "${DRIVE_USER}" | cut -d: -f6 )
RSYNCCONF="${DRIVE_HOMEDIR}/.config/rclone/rclone.conf"
DRIVESERVICEACCOUNTFILE="${DRIVE_HOMEDIR}/.config/rclone/sa.conf"
RCLONE=$(command -v rclone)

RSYNCCONFFOLDER=$(dirname ${RSYNCCONF})
RSYNCCONFFILE=$(basename ${RSYNCCONF})


if [ ! -f ${RSYNCCONF} ]; then
  mkdir -p ${RSYNCCONFFOLDER}

  if [ ! -z ${DRIVE_ACCESSTOKEN} ]; then
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
token = {"access_token":"${DRIVE_ACCESSTOKEN}","token_type":"Bearer","refresh_token":"${DRIVE_REFRESHTOKEN}","expiry":"${DRIVE_TOKENEXPIRY}"}
team_drive = ${DRIVE_ROOTFOLDER}
EOF
  elif [ ! -z ${DRIVE_PROJECT_ID} ]; then
cat << EOF > ${DRIVESERVICEACCOUNTFILE}
{
  "type": "service_account",
  "project_id": "${DRIVE_PROJECT_ID}",
  "private_key_id": "${DRIVE_PRIVATE_KEY_ID}",
  "private_key": "${DRIVE_PRIVATE_KEY}",
  "client_email": ${DRIVE_CLIENT_EMAIL}",
  "client_id": "${DRIVE_CLIENT_ID}",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "${DRIVE_CERTIFICATE_URL}"
}
EOF
cat << EOF > ${RSYNCCONFFOLDER}/${RSYNCCONFFILE}
[gdrive]
type = drive
client_id = ${GOOGLE_CLIENTID}
client_secret = ${GOOGLE_CLIENTSECRET}
scope = drive
root_folder_id = 
service_account_file = ${DRIVESERVICEACCOUNTFILE}
team_drive = ${DRIVE_ROOTFOLDER}
use_trash = false
skip_gdocs = true
chunk_size = 128M
EOF
  else
    echo "No access method (token or service account). Giving up."
    sleep 10
    exit 1
  fi

cat << EOF >> ${RSYNCCONFFOLDER}/${RSYNCCONFFILE}

[gcache]
type = cache
remote = gdrive:/gdrive
chunk_size = 10M
info_age = 1h0m0s
chunk_total_size = 50G

[gcrypt]
type = crypt
remote = gcache:/crypt
filename_encryption = standard
directory_name_encryption = true
password = ${GCRYPT_PASSWORD}
password2 = ${GCRYPT_PASSWORD2}
EOF

chown -R 1000:1000 ${RSYNCCONFFOLDER}
cat ${DRIVESERVICEACCOUNTFILE}
cat ${RSYNCCONFFOLDER}/${RSYNCCONFFILE}
fi

_term() { 
  echo "Shutting down..." 
  kill -TERM "$child" 2>/dev/null
}

trap _term SIGTERM

echo "Mounting..."
mkdir -p /mount${DRIVE_MOUNTFOLDER}
chown -R 1000:1000 /mount${DRIVE_MOUNTFOLDER}
su-exec 1000:1000 ${RCLONE} lsd gcrypt:${DRIVE_TARGETFOLDER}
RCLONECMD="su-exec 1000:1000 ${RCLONE} mount --vfs-cache-mode full --buffer-size 128M --vfs-read-ahead 512M gcrypt:${DRIVE_TARGETFOLDER} /mount${DRIVE_MOUNTFOLDER}"
while :
do
  nice -n 20 $RCLONECMD &
  child=$! 
  echo "Ready."
  wait "$child"
  echo "Unmounting..."
  fusermount -u /mount${DRIVE_MOUNTFOLDER} && rm -Rf /mount${DRIVE_MOUNTFOLDER}
  echo "Finished..."
  exit 0
done
