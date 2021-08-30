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

RUN  apt-get install -y icecast2

WORKDIR /icecast2
ADD start.sh .
RUN chown icecast2 /icecast2 -R
 
EXPOSE 8000

USER icecast2

ENV ICECAST_PASSWORD "f498f60c-4ca0-4506-b9ac-1b9623d3db6e"
ENV ICECAST_ADMPASSWORD "b4c6c873-08d1-41b7-adcd-a1d7773c53fa"
ENV ICECAST_CONFIG /etc/icecast2/icecast.xml
ENV ICECAST_HOST localhost
ENV ICECAST_SRC_LIMIT 10

CMD ["/bin/bash", "./start.sh"]