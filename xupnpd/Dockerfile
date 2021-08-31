FROM debian:buster-slim as build

ENV DEBIAN_FRONTEND noninteractive

RUN  apt-get update && \
     apt-get install -y wget apt-transport-https ca-certificates locales && \
     apt-get update

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales && \
    /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN apt-get install -y build-essential git uuid-dev

# setup XUPNPD
# build
WORKDIR /build

RUN git clone https://github.com/anabolyc/xupnpd.git
WORKDIR /build/xupnpd
RUN ls -al && make

FROM debian:buster-slim

ENV DEBIAN_FRONTEND noninteractive

RUN  apt-get update && \
     apt-get install -y wget apt-transport-https ca-certificates locales && \
     apt-get update

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales && \
    /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# RUN  apt-get update && \
#      apt-get install -y libmp3lame-dev libxml2-dev libshout-dev libvorbis-dev

# RUN apt-get clean -y && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /build/xupnpd/staging ./xupnpd
RUN mkdir ./playlists
ADD start.sh .
RUN useradd -ms /bin/bash xupnpd
RUN chown xupnpd /app -R

USER xupnpd
 
# EXPOSE 5000

ENV FRONTEND_NAME 2X2
ENV FRONTEND_PORT 4044
ENV BACKEND_GUID bcebdd31-ebb6-4773-88fb-5812b2778a6e
ENV VLC_ADDR localhost:5000

CMD ["/bin/bash", "./start.sh"]
