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

RUN  apt-get install -y vlc-bin vlc-plugin-base # vlc

RUN apt-get clean -y && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ADD start.sh .
ADD vlm.conf .
RUN useradd -ms /bin/bash vlc
RUN chown vlc /app -R

USER vlc
 
EXPOSE 5000

ENV ROOT_FOLDER "/media"
ENV BACKEND_PASSWORD 87813686-a290-4e78-a49f-f815e60ef969
# ENV VLC_PLUGIN_PATH /usr/lib/vlc/plugins/

CMD ["/bin/bash", "./start.sh"]
