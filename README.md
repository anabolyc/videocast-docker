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

--> 

### MINIDLNA

* Go to `icecast` folder 
* Run `config builder` task first to configure docker buildx (in not done while building vlc).
* Run `docker buildx & export to docker` task to build icecast docker image for current arch and export to docker environment.
* (Alternatively) Run `docker buildx` task to build icecast docker image for all archs. This is currently failing to export image to docker environment due to some bug.
* (Alternatively) Run `docker buildx & push to registry` task to build icecast docker image for all archs and push result to registry.

You should have icecast working now, you may test it with `docker run` task to execute icecast or `docker run bash` to run bash in target container and perhaps execute `start.sh` yourself. When executed you should be able to access web page at http://localhost:8000 and log on as admin using password specified in `ICECAST_ADMPASSWORD` container environment variable.

## How to run

(assuming docker-compose is already installed and working correctly, see links section below)

To verify your setup one would run it locally in your environment using below steps. To run this as a service using systemd and have it auto started on boot please use [second part](#run-as-a-service-auto-start-on-boot) of instruction

### Run manually (most probably for testing)

just run `docker-compose up`, you shoul be able to see similar output
```
Creating network "foldercast-docker_default" with the default driver
Creating foldercast-docker_icecast_1 ... done
Creating foldercast-docker_vlc_1    ... done
Attaching to foldercast-docker_icecast_1, foldercast-docker_vlc_1
icecast_1  | [2020-05-10  11:19:51] WARN CONFIG/_parse_root Warning, <hostname> not configured, using default value "localhost". This will cause problems, e.g. with YP directory listings.
icecast_1  | [2020-05-10  11:19:51] WARN CONFIG/_parse_root Warning, <location> not configured, using default value "Earth".
icecast_1  | [2020-05-10  11:19:51] WARN CONFIG/_parse_root Warning, <admin> contact not configured, using default value "icemaster@localhost".
icecast_1  | [2020-05-10  11:19:51] WARN fserve/fserve_recheck_mime_types Cannot open mime types file /etc/mime.types
```

Now you may see status under http://localhost:8000/admin/ and listen stream under http://localhost:8000/listen

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

Copy `docker-compose.yml` file to `/etc/docker/compose/foldercast` and start service like this
```
sudo systemctl start docker-compose@foldercast 
```
Hopefully this started without an error, and you should be able to see status `active (running)` 
```
systemctl status docker-compose@foldercast 
```
Now you may enbale service to auto start on boot 
```
sudo systemctl enable docker-compose@foldercast 
```

### Run as a service, no docker-compose (auto start on boot)

Create icecast service using `sudo nano /etc/systemd/system/icecast-docker.service`. Place following contents there
```
[Unit]
Description=dockerized icecast
Requires=docker.service network-online.service
After=docker.service network-online.service

[Service]
ExecStartPre=-/usr/bin/docker rm -f icecast-instance
ExecStartPre=-/usr/bin/docker pull andreymalyshenko/icecast
ExecStart=/usr/bin/docker run --name icecast-instance -p 8000:8000 -e ICECAST_HOST=icecast-instance andreymalyshenko/icecast
ExecStartPost=/bin/sh -c 'while ! docker ps | grep icecast-instance ; do sleep 0.2; done'
ExecStop=/usr/bin/docker rm -f icecast-instance
TimeoutSec=0
RemainAfterExit=no
Restart=always

[Install]
WantedBy=multi-user.target
```

Create vlc service using `sudo nano /etc/systemd/system/vlc-docker.service`. Place following contents there
```
[Unit]
Description=dockerized vlc-1
Requires=docker.service network-online.service icecast-docker.service
After=docker.service network-online.service icecast-docker.service

[Service]
ExecStartPre=-/usr/bin/docker rm -f vlc-instance-1
ExecStartPre=-/usr/bin/docker pull andreymalyshenko/vlc
ExecStart=/usr/bin/docker run --name vlc-instance-1 -v '/data2/muzlo/ Radio/Fabio And Grooverider:/media:ro' -e STREAM_HOST=icecast-instance -e STREAM_PATH='/fg' -e STREAM_NAME='Fabio & Grooverider' -e STREAM_GENRE='Drum&Bass' -e STREAM_DESCRIPTION='Wall to wall drum and bass.' andreymalyshenko/vlc
ExecStartPost=/bin/sh -c 'while ! docker ps | grep vlc-instance-1 ; do sleep 0.2; done'
ExecStop=/usr/bin/docker rm -f vlc-instance-1
TimeoutSec=0
RemainAfterExit=no
Restart=always

[Install]
WantedBy=multi-user.target

```

Now start both servvlc by running 
```
sudo systemctl start vlc-docker.service
```

You should be able to access icecast server UI under http://localhost:8000 as before and listen stream under http://localhost:8000/fg. If everything works all right, enable autostart by running
```
sudo systemctl enable vlc-docker.service
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
