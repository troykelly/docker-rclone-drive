#!/usr/bin/env sh

DRIVE_USER=$(getent passwd "1000" | cut -d: -f1)
DRIVE_HOMEDIR=$( getent passwd "${DRIVE_USER}" | cut -d: -f6 )
RSYNCCONF="${DRIVE_HOMEDIR}/.config/rclone/rclone.conf"
RCLONE=$(command -v rclone)

RSYNCCONFFOLDER=$(dirname ${RSYNCCONF})
RSYNCCONFFILE=$(basename ${RSYNCCONF})

if [ ! -f ${RSYNCCONF} ]; then
  mkdir -p ${RSYNCCONFFOLDER}

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
