#!/bin/bash

# generate playlist
echo "Generating playlist..."
find "$ROOT_FOLDER" -type f | sed -e 's/^/setup channel1 input "/' -e 's/$/"/' > ./playlist.conf && \
cat ./playlist.conf && \
echo "Starting vls stream..." && \
vlc -Ihttp --vlm-conf /app/vlm.conf --random --loop --network-caching 1000 --sout-mux-caching 2000 --clock-jitter 0 --http-password ${BACKEND_PASSWORD}