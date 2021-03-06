#!/usr/bin/env sh
# set -e

RCLONE=$(command -v rclone)

if [ -z ${RCLONE_CONFIG} ]; then
  RCLONE_CONFIG="${HOME}/.config/rclone/rclone.conf"
fi

if [ -z ${RCLONE_CONFIG_DIR} ]; then
  RCLONE_CONFIG_DIR=$(dirname ${RCLONE_CONFIG})
fi

RCLONE_CONFIG_LOG="${RCLONE_CONFIG_DIR}/config.log"

if [ -z ${RCLONE_CACHE} ]; then
  RCLONE_CACHE=false
fi

if [ -z ${RCLONE_TEAMDRIVE} ]; then
  RCLONE_TEAMDRIVE=false
fi

if [ -z ${DRIVE_TARGETFOLDER} ]; then
  DRIVE_TARGETFOLDER=
fi

if [ -z ${RCLONE_PRIMARY_STORE} ]; then
  RCLONE_PRIMARY_STORE=gdrive
fi

if [ -z ${RCLONE_CACHE_STORE} ]; then
  RCLONE_CACHE_STORE=gcache
fi

if [ -z ${RCLONE_CRYPT_STORE} ]; then
  RCLONE_CRYPT_STORE=gcrypt
fi

if [ -z ${SHARE_UID} ]; then
  SHARE_UID=1000
fi

if [ -z ${SHARE_GID} ]; then
  SHARE_GID=1000
fi

if [ ! -z ${USER_EMAIL} ]; then
  DRIVE_IMPERSONATE="--drive-impersonate ${USER_EMAIL}"
else
  DRIVE_IMPERSONATE=
fi

if [ -z ${SERVICE_ACCOUNT_FILE} ]; then
  SERVICE_ACCOUNT_FILE="${RCLONE_CONFIG_DIR}/sa.conf"
fi

if [ -z ${FORCE_NO_CRYPT} ]; then
  FORCE_NO_CRYPT=false
fi

mkdir -p ${RCLONE_CONFIG_DIR}

# Remove old configuration
if [ -f ${RCLONE_CONFIG} ]; then
  rm -Rf ${RCLONE_CONFIG}
fi
if [ -f ${SERVICE_ACCOUNT_FILE} ]; then
  rm -Rf ${SERVICE_ACCOUNT_FILE}
fi
if [ -f ${RCLONE_CONFIG_LOG} ]; then
  rm -Rf ${RCLONE_CONFIG_LOG}
fi

if [ ! -z "${DRIVE_ACCESSTOKEN}" ] && [ ! -z "${DRIVE_REFRESHTOKEN}" ] && [ ! -z "${DRIVE_TOKENEXPIRY}" ]; then
  RCLONE_TOKEN="{\"access_token\":\"${DRIVE_ACCESSTOKEN}\",\"token_type\":\"Bearer\",\"refresh_token\":\"${DRIVE_REFRESHTOKEN}\",\"expiry\":\"${DRIVE_TOKENEXPIRY}\"}"
  SERVICE_ACCOUNT_FILE=
else
  RCLONE_TOKEN=
fi

config_error() { 
  echo "Failed to start. Invalid config."
  sleep 10
  exit 2
}

FAILED=false
if ! { [ "${RCLONE_TEAMDRIVE}" == "true" ] || [ "${RCLONE_TEAMDRIVE}" == "false" ]; }; then
  echo "RCLONE_TEAMDRIVE must be true or false - you set it as ${RCLONE_TEAMDRIVE}"
  FAILED=true
fi
if [ ! -z "${DRIVE_PROJECT_ID}" ] && [ ! -z "${DRIVE_PRIVATE_KEY_ID}" ] && [ ! -z "${DRIVE_PRIVATE_KEY}" ] && [ ! -z "${DRIVE_CLIENT_EMAIL}" ] && [ ! -z "${DRIVE_CLIENT_ID}" ] && [ ! -z "${DRIVE_CERTIFICATE_URL}" ] && [ ! -z "${RCLONE_TOKEN}" ]; then
  echo "Must supply either SA details DRIVE_PROJECT_ID etc or token details DRIVE_ACCESSTOKEN etc"
  FAILED=true
fi
if [ ! -z "${DRIVE_IMPERSONATE}" ] && [ -z ${SERVICE_ACCOUNT_FILE} ]; then
  echo "Must not set DRIVE_IMPERSONATE without using a service account."
  FAILED=true
fi
if [ -z "${GOOGLE_CLIENTID}" ] && [ -z "${DRIVE_IMPERSONATE}" ]; then
  echo "Missing GOOGLE_CLIENTID. Must supply unless using USER_EMAIL"
  FAILED=true
fi
if [ -z "${GOOGLE_CLIENTSECRET}" ] && [ -z "${DRIVE_IMPERSONATE}" ]; then
  echo "Missing GOOGLE_CLIENTSECRET. Must supply unless using USER_EMAIL"
  FAILED=true
fi
if [ -z "${DRIVE_ROOTFOLDER}" ]; then
  echo "Missing DRIVE_ROOTFOLDER"
  FAILED=true
fi
if [ -z "${GCRYPT_PASSWORD}" ]; then
  echo "Missing GCRYPT_PASSWORD"
  FAILED=true
fi
if [ -z "${GCRYPT_PASSWORD2}" ]; then
  echo "Missing GCRYPT_PASSWORD2"
  FAILED=true
fi
if [ "$FORCE_NO_CRYPT" == "true" ] && ! ([ "${GCRYPT_PASSWORD}" == "DANGER" ] && [ "${GCRYPT_PASSWORD2}" == "DANGER" ]); then
  echo "To use FORCE_NO_CRYPT, you must set both GCRYPT_PASSWORD and GCRYPT_PASSWORD2 to 'DANGER'"
  FAILED=true
fi
if [ "$FAILED" == "true" ]; then
  config_error
fi

if [ "$RCLONE_TEAMDRIVE" == "true" ]; then
  RCLONE_ROOT_FOLDER_ID=
  RCLONE_TEAM_DRIVE=${DRIVE_ROOTFOLDER}
else
  RCLONE_ROOT_FOLDER_ID=${DRIVE_ROOTFOLDER}
  RCLONE_TEAM_DRIVE=
fi

echo "???? Generating configuration in ${RCLONE_CONFIG}"
touch ${RCLONE_CONFIG_LOG}

if [ ! -z "${DRIVE_IMPERSONATE}" ]; then
  GOOGLE_CLIENTID=
  GOOGLE_CLIENTSECRET=
fi

if [ "$FORCE_NO_CRYPT" == "true" ]; then
  echo "???? Forcing to not use encryption. Jeez pal - seriously?"
  GCRYPT_PASSWORD=
  GCRYPT_PASSWORD2=
fi

if [ ! -z "${RCLONE_TOKEN}" ]; then
  ${RCLONE} config create --non-interactive --quiet --config ${RCLONE_CONFIG} ${RCLONE_PRIMARY_STORE} drive client_id=${GOOGLE_CLIENTID} client_secret=${GOOGLE_CLIENTSECRET} scope=drive root_folder_id=${RCLONE_ROOT_FOLDER_ID} team_drive=${RCLONE_TEAM_DRIVE} config_team_drive=${RCLONE_TEAM_DRIVE} use_trash=false skip_gdocs=true chunk_size=32M token=${RCLONE_TOKEN} config_refresh_token=false config_change_team_drive=${RCLONE_TEAMDRIVE} >> ${RCLONE_CONFIG_LOG} 2>&1
else
  cat << EOF > ${SERVICE_ACCOUNT_FILE}
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

  ${RCLONE} config create --non-interactive --quiet --config ${RCLONE_CONFIG} ${RCLONE_PRIMARY_STORE} drive client_id=${GOOGLE_CLIENTID} client_secret=${GOOGLE_CLIENTSECRET} scope=drive root_folder_id=${RCLONE_ROOT_FOLDER_ID} team_drive=${RCLONE_TEAM_DRIVE} config_team_drive=${RCLONE_TEAM_DRIVE} use_trash=false skip_gdocs=true chunk_size=32M service_account_file=${SERVICE_ACCOUNT_FILE} config_change_team_drive=${RCLONE_TEAMDRIVE} >> ${RCLONE_CONFIG_LOG} 2>&1
fi

if [ "$RCLONE_CACHE" == "true" ]; then
  ${RCLONE} config create --non-interactive --quiet --config ${RCLONE_CONFIG} ${RCLONE_CACHE_STORE} cache remote=${RCLONE_PRIMARY_STORE}: chunk_size=10M info_age=1d chunk_total_size=1G >> ${RCLONE_CONFIG_LOG} 2>&1
  CRYPT_MOUNT_POINT=${RCLONE_CACHE_STORE}:
else
  CRYPT_MOUNT_POINT=${RCLONE_PRIMARY_STORE}:
fi

if [ "$FORCE_NO_CRYPT" != "true" ]; then
  ${RCLONE} config create --non-interactive --quiet --config ${RCLONE_CONFIG} --obscure ${RCLONE_CRYPT_STORE} crypt remote=${CRYPT_MOUNT_POINT} filename_encryption=standard directory_name_encryption=true password=${GCRYPT_PASSWORD} password2=${GCRYPT_PASSWORD2} >> ${RCLONE_CONFIG_LOG} 2>&1
fi

echo "???? Config created."
exit 0