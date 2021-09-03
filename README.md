# Containerized vlc + minidlna server

## Description

There are two docker images: vlc (as streaming source) and minidlna (as streaming sink). Vlc will pick up a media content from specified folder and stream in loop in randon order, sort of TV-channel of some sort, but with no commercials obviously. Minidlna instance will expose content via DLNA protocol, that can be picked up by most moderm TVs.

Using docker buildx to target amd64 and armv7 archs. Therefore runnable on RaspberryPi (Raspbian), OrangePi (Armbian) or AMD64 (Ubuntu)

## How to build

(assuming docker and buildx already installed, see links section below)

### VLC

* Go to `vlc` folder 
* Run `config builder` task first to configure docker buildx.
* Run `docker buildx & export to docker` task to build vlc docker image for current arch and export to docker environment.
* (Alternatively) Run `docker buildx` task to build vlc docker image for all archs. This is currently failing to export image to docker environment due to some bug.
* (Alternatively) Run `docker buildx & push to registry` task to build vlc docker image for all archs and push result to registry.

You should have vlc working now, you may test it with `docker run` task to execute vlc or `docker run bash` to run bash in target container and perhaps execute `start.sh` yourself

### MINIDLNA

* Go to `xupnpd` folder 
* Run `config builder` task first to configure docker buildx (in not done while building vlc).
* Run `docker buildx & export to docker` task to build xupnpd docker image for current arch and export to docker environment.
* (Alternatively) Run `docker buildx` task to build xupnpd docker image for all archs. This is currently failing to export image to docker environment due to some bug.
* (Alternatively) Run `docker buildx & push to registry` task to build xupnpd docker image for all archs and push result to registry.

You should have xupnpd working now, you may test it with `docker run` task to execute xupnpd or `docker run bash` to run bash in target container and perhaps execute `start.sh` yourself. When executed you should be able to access frontend at http://localhost:4044 

## How to run

(assuming docker-compose is already installed and working correctly, see links section below)

To verify your setup one would run it locally in your environment using below steps. To run this as a service using systemd and have it auto started on boot please use [second part](#run-as-a-service-auto-start-on-boot) of instruction

### Run manually (most probably for testing)

just run `docker-compose up`, you shoul be able to see similar output

```
> Executing task: docker-compose up <

Starting videocast-docker_vlc_1 ... done
Recreating videocast-docker_xupnpd_1 ... done
Attaching to videocast-docker_vlc_1, videocast-docker_xupnpd_1
vlc_1     | Generating playlist...
vlc_1     | setup channel1 input "/media/**********.avi"
vlc_1     | Starting vls stream...
vlc_1     | [000055a5b15c0490] vlcpulse audio output error: PulseAudio server connection failure: Connection refused
vlc_1     | [000055a5b15fd530] dbus interface error: Failed to connect to the D-Bus session daemon: Unable to autolaunch a dbus-daemon without a $DISPLAY for X11
vlc_1     | [000055a5b15fd530] main interface error: no suitable interface module
vlc_1     | [000055a5b152c570] main libvlc error: interface "dbus,none" initialization failed
vlc_1     | [000055a5b15b9f30] main interface error: no suitable interface module
vlc_1     | [000055a5b152c570] main libvlc error: interface "globalhotkeys,none" initialization failed
vlc_1     | [000055a5b15b9f30] [http] lua interface: Lua HTTP interface
vlc_1     | [000055a5b15304e0] main playlist: playlist is empty
xupnpd_1  | Patching xupnp config ..
xupnpd_1  | #EXTINF:-1 group-title="TV" tvg-name="2X2_DEV" tvg-id="" tvg-logo="",2X2_DEV
xupnpd_1  | http://127.0.0.1:5000/live
xupnpd_1  | Starting xupnp server..
```

Now you may see status under http://localhost:4044/ and listen stream using your DLNA client (TV in my case)

### Run as a service (auto start on boot)

Using [this](https://gist.github.com/mosquito/b23e1c1e5723a7fd9e6568e5cf91180f) example.

(Unfortunately as of May 2020 `docker-compose` is not available OOTB in Armbian and i failed to build if from source to working version. Thus below another method not requiring `docker-compose`)

Create generic service runner using `sudo nano /etc/systemd/system/docker-compose@.service`. Place following contents there
```
[Unit]
Description=%i service with docker compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/etc/docker/compose/%i
ExecStart=/usr/local/bin/docker-compose up -d --remove-orphans
ExecStop=/usr/local/bin/docker-compose down

[Install]
WantedBy=multi-user.target
```

Copy `docker-compose.yml` file to `/etc/docker/compose/videocast` and start service like this
```
sudo systemctl start docker-compose@videocast 
```
Hopefully this started without an error, and you should be able to see status `active (running)` 
```
systemctl status docker-compose@videocast 
```
Now you may enbale service to auto start on boot 
```
sudo systemctl enable docker-compose@videocast 
```

### Run as a service, no docker-compose (auto start on boot)
 
(Optional) Create mount file for systemd to mount dedicated storage for the service: `sudo nano /etc/systemd/system/apps-videocast-data.mount`. Place following contents there (adjust your media path accordingly):
```
[Unit]
  Description=transmission mount
  Requires=mnt-local-media.mount
  After=mnt-local-media.mount

[Mount]
  What=/mnt/local/media/media/video/The Simpsons
  Where=/apps/videocast/data
  Options=bind
  Type=none

[Install]
  WantedBy=multi-user.target
```

Create vlc service using `sudo nano /etc/systemd/system/docker-vlccast.service`. Place following contents there
```
[Unit]
Description=vlccast     
Requires=apps-videocast-data.mount docker.service
After=apps-videocast-data.mount docker.service

[Service]
ExecStartPre=-/usr/bin/docker rm -f vlccast     
ExecStartPre=-/usr/bin/docker pull andreymalyshenko/videocast-vlc
ExecStart=/usr/bin/docker run --name vlccast --net=host -v /apps/videocast/data:/media:ro andreymalyshenko/videocast-vlc
ExecStartPost=/bin/sh -c 'while ! docker ps | grep vlccast ; do sleep 0.2; done'
ExecStop=/usr/bin/docker rm -f vlccast     
TimeoutSec=0
RemainAfterExit=no
Restart=always

[Install]
WantedBy=multi-user.target
```
This service will read all media files within supplied folder and start to stream it in random order at localhost:5000/live 


Create xupnpd service using `sudo nano /etc/systemd/system/docker-xupnpd.service`. Place following contents there
```
[Unit]
Description=xupnpd     
Requires=docker-vlccast.service docker.service
After=docker-vlccast.service docker.service

[Service]
ExecStartPre=-/usr/bin/docker rm -f xupnpd     
ExecStartPre=-/usr/bin/docker pull andreymalyshenko/videocast-xupnpd
ExecStart=/usr/bin/docker run --name xupnpd --net=host -e VLC_ADDR=127.0.0.1:5000 andreymalyshenko/videocast-xupnpd
ExecStartPost=/bin/sh -c 'while ! docker ps | grep xupnpd ; do sleep 0.2; done'
ExecStop=/usr/bin/docker rm -f xupnpd     
TimeoutSec=0
RemainAfterExit=no
Restart=always

[Install]
WantedBy=multi-user.target

```

Now start both services by running 
```
sudo systemctl start docker-xupnpd.service
```

You should be able to access xupnpd server UI under http://localhost:4044 as before and listen stream using DLNA client in the same network. If everything works all right, enable autostart by running
```
sudo systemctl enable docker-xupnpd.service
```

### Docker cleanup service (optional)

Docker tends to take to much space with time, so once in a while you may come and run `docker system prune` to remove unused images and volumes. As an alternative one may setup a service to do it automatically once in a while.

Create a timer file `sudo nano /etc/systemd/system/docker-cleanup.timer` and add following content
```
[Unit]
Description=Docker cleanup timer

[Timer]
OnUnitInactiveSec=12h

[Install]
WantedBy=timers.target
```

Create a servce file `sudo nano /etc/systemd/system/docker-cleanup.service` and add following content
```
[Unit]
Description=Docker cleanup
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
WorkingDirectory=/tmp
User=root
Group=root
ExecStart=/usr/bin/docker system prune -af

[Install]
WantedBy=multi-user.target
```

Now enable service with this command
```
systemctl enable docker-cleanup.timer
```

## Links
* [vlc Home](https://xiph.org/)
* [Install Docker](https://docs.docker.com/engine/install/ubuntu/)
* [Install Docker Compose on amd64](https://docs.docker.com/compose/install/)
* [Install Docker Compose on arm](https://www.berthon.eu/2019/revisiting-getting-docker-compose-on-raspberry-pi-arm-the-easy-way/)
* [Install Docker BuildX](https://github.com/docker/buildx/)