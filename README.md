# rclone-drive

Encrypted file mount

Mounts Google Drive with encryption

You can either mount a Google Drive, or
Push all the files in a path to a Google Drive (hint)

```yaml
command: ["/usr/sbin/push.sh"]
```

This readme is rubbish at the moment - sorry -
the details below are not even current

<!-- markdownlint-capture -->
<!-- markdownlint-disable -->

| Environment Variable  | Notes                                                        | Required |
| --------------------- | ------------------------------------------------------------ | -------- |
| RCLONE_BUFFER_SIZE    | TBC                                                          | [ ]      |
| RCLONE_ZFS_CACHE_MODE | TBC                                                          | [ ]      |
| RCLONE_ZFS_READ_AHEAD | TBC                                                          | [ ]      |
| RCLONE_TEAMDRIVE      | Is this a team drive (shared drive)                          | [ ]      |
| RCLONE_CACHE          | Can be `true` or `false` depending if you want cache or not. | [ ]      |
| PLEX_HOST             | If using cache - can supply details for plex                 | [ ]      |
| PLEX_USERNAME         | If using cache - can supply details for plex                 | [ ]      |
| PLEX_PASSWORD         | If using cache - can supply details for plex                 | [ ]      |
| PLEX_TOKEN            | If using cache - can supply details for plex                 | [ ]      |
| DRIVE_TARGETFOLDER    | TBC                                                          | [ ]      |
| GOOGLE_CLIENTID       | The app client ID                                            | [x]      |
| GOOGLE_CLIENTSECRET   | The app client secret                                        | [x]      |
| DRIVE_ROOTFOLDER      | The root folder ID (from the URL) not the name - the id.     | [x]      |
| DRIVE_ACCESSTOKEN     | The access token to authenticate with                        | [ ]      |
| DRIVE_REFRESHTOKEN    | If using `DRIVE_ACCESSTOKEN` supply the refresh token        | [ ]      |
| DRIVE_TOKENEXPIRY     | If using `DRIVE_ACCESSTOKEN` supply the token expiry         | [ ]      |
| DRIVE_PROJECT_ID      | Service Account: The project ID of the Service Account       | [ ]      |
| DRIVE_PRIVATE_KEY_ID  | Service Account: The private key id                          | [ ]      |
| DRIVE_PRIVATE_KEY     | Service Account: The private key                             | [ ]      |
| DRIVE_CLIENT_EMAIL    | Service Account: The client email                            | [ ]      |
| DRIVE_CLIENT_ID       | Service Account: The client id                               | [ ]      |
| DRIVE_CERTIFICATE_URL | Service Account: The certificate url                         | [ ]      |
| GCRYPT_PASSWORD       | The password for encryption                                  | [ ]      |
| GCRYPT_PASSWORD2      | The salt for the password                                    | [ ]      |

<!-- markdownlint-enable -->
