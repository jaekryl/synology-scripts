#!/bin/sh

mkdir -p /volume1/@tmp/plex/ || exit 2
cd /volume1/@tmp/plex || exit 2

TOKEN=$(grep -oP 'PlexOnlineToken="\K[^"]+' /volume1/Plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml)
URL="https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=${TOKEN}"
JSON=$(curl -s "${URL}")

PKG_NAME="Plex Media Server"
NEW_VERSION=$(echo "${JSON}" | jq -r '.nas.Synology.version')
echo "New version: ${NEW_VERSION}"
CURRENT_VERSION=$(synopkg version "${PKG_NAME}")
echo "Current version: ${CURRENT_VERSION}"

if [ "${NEW_VERSION}" != "${CURRENT_VERSION}" ]; then
  # /usr/syno/bin/synonotify PKGHasUpgrade "{\"%PKG_HAS_UPDATE%\": \"${PKG_NAME}\", \"%COMPANY_NAME%\": \"Plex Inc.\"}"
  echo "New version available!"
  echo

  CPU=$(uname -m)
  if [ "${CPU}" = "x86_64" ]; then
    URL=$(echo "${JSON}" | jq -r '.nas.Synology.releases[1] | .url')
  else
    URL=$(echo "${JSON}" | jq -r '.nas.Synology.releases[0] | .url')
  fi

  /bin/wget "${URL}" -P .
  /usr/syno/bin/synopkg install *.spk || exit 1
  /usr/syno/bin/synopkg start "${PKG_NAME}" || exit 1

  /usr/syno/bin/synonotify PkgMgr_UpgradedPkg "{\"%PKG_NAME%\": \"${PKG_NAME}\", \"%PKG_VERSION%\": \"${NEW_VERSION}\"}"
  echo "Upgraded to new version!"
else
  echo "${PKG_NAME} is up to date"
fi

rm -rf /volume1/@tmp/plex
exit 0
