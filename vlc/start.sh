#!/bin/bash

CONFIG=./icecast.xml

sed \
    -e 's?<sources>2</sources>?<sources>'"$ICECAST_SRC_LIMIT"'</sources>?g' \
    -e 's?<source-password>hackme</source-password>?<source-password>'"$ICECAST_PASSWORD"'</source-password>?g' \
    -e 's?<relay-password>hackme</relay-password>?<relay-password>'"$ICECAST_PASSWORD"'</relay-password>?g' \
    -e 's?<admin-password>hackme</admin-password>?<admin-password>'"$ICECAST_ADMPASSWORD"'</admin-password>?g' \
    -e 's?<hostname>localhost</hostname>?<hostname>'"$ICECAST_HOST"'</hostname>?g' \
    $ICECAST_CONFIG > $CONFIG

cat $CONFIG

/usr/bin/icecast2 -c $CONFIG