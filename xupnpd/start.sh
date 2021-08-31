#!/bin/bash

echo "Patching xupnp config .."
# patch config

if [ ! -f /app/xupnpd/.xupnpd.lua.patched ]; then
	sed -e "s/UPnP-IPTV/${FRONTEND_NAME}/" -e "s/4044/${FRONTEND_PORT}/" -e "s/60bd2fb3-dabe-cb14-c766-0e319b54c29a/${BACKEND_GUID}/" -i /app/xupnpd/xupnpd.lua 
	sed -e "s/playlists_update_interval=60/playlists_update_interval=0/" -e "s/cfg\.group=true/cfg\.group=false/" -e "s/cfg\.debug=1/cfg\.debug=0/" -i /app/xupnpd/xupnpd.lua
	sed -e "s/xupnpd/${BACKEND_GUID}/" -i /app/xupnpd/www/dev.xml
	touch /app/xupnpd/.xupnpd.lua.patched
else
	echo "Config file appears to be patched already"
fi

echo "#EXTINF:-1 group-title="TV" tvg-name="${FRONTEND_NAME}" tvg-id="" tvg-logo="",${FRONTEND_NAME}\nhttp://${VLC_ADDR}/live" > /app/playlists/list.m3u 

echo "Starting xupnp server.."
/app/xupnpd/xupnpd