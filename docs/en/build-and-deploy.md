# build and deploy

Englis | [简体中文](../cn/build-and-deploy.md)

## Source code download

Please execute the following command to download the entire source code of the project:

- Create a local directory, run cmd:  `mkdir ./WORKDIR && cd ./WORKDIR`
- Download source code, run cmd: `git clone --recurse-submodules git@github.com:ao-space/ao.space.git`
- Enter the folder/directory, run cmd: `cd ./ao.space`

## Build and deploy

If you want a simplified compose-based setup, see:
1. `deploy/server/README.md`
2. `deploy/platform/README.md`

### Server (no platform) build + deploy (recommended for local/dev)

This mode runs the server without platform dependencies. Platform-related features (internet access, push, app store, version checks) are unavailable.

1. Copy `.env` and update passwords/ports:

```shell
cd deploy/server
cp .env.example .env
```

2. Update `deploy/server/system-agent.yml` to match `.env` (Redis password).

3. Build images:

```shell
docker compose --env-file .env build
```

Notes:
1. `space-gateway` uses `server/space-gateway/Dockerfile.jvm.build` to compile Quarkus during the image build.
2. Runtime base image uses `eclipse-temurin:17-jre` to avoid installing JDK via `yum` during build.
3. No-platform mode sets platform URLs to `http://127.0.0.1` to avoid SSL errors.

### Offline build / prebuild (space-gateway)

If you cannot access Maven repositories during `docker build`, you can prebuild the gateway locally and use the prebuilt JVM runtime Dockerfile.

1. Build locally:

```shell
cd server/space-gateway
./mvnw -Dmaven.test.skip=true package
```

2. Update compose to use `Dockerfile.jvm.prebuilt`:

```yaml
services:
  aospace-gateway:
    build:
      context: ../../server/space-gateway
      dockerfile: Dockerfile.jvm.prebuilt
```

4. Start:

```shell
docker compose --env-file .env up -d --build
```

### Platform build and deploy

In the [platform-deploy depository](https://github.com/ao-space/platform-deploy), we provided a detailed introduction to the construction and deployment process of the platform.

It should be noted that the above process used the docker-compose.yml file in the platform-deploy repository to orchestrate the container deployment of related components. The image used is the latest image of the dev branch in the github image repository.

If you want to replace some component images with locally built images, you can modify the image entry of the relevant components to the image address compiled by yourself and execute the `docker-compose up -d` command.


### Server build and deploy 

#### Prepare Environment

- docker (>=18.09)
- git
- golang 1.18 +

#### Server build

Docker images are built in basically the same way, using a Dockerfile to build the image.

Before building, I would like to remind you that if you want to run space-agent with your own locally-built image, it is recommended that you build all the images except space-agent first, and then build space-agent last.

It is recommended that you build everything except space-agent first, and then build space-agent last.

Before building aospace-agent, you need to set space-agent/res/docker-compose_run_as_docker.yml (Win/Mac)

or space-agent/res/docker-compose_run_as_docker_network_mode_host.yml (linux) to the address of the image you compiled.

For example, *local/space-aofs:{tag}* is used here.



```shell
cd ./server ; 
docker build -t local/space-aofs:{tag} ./space-aofs
docker build -t local/space-gateway:{tag} ./space-gateway
docker build -t local/space-web:{tag} ./space-web
docker build -t local/space-filepreview:{tag} ./space-filepreview
docker build -t local/space-media-vod:{tag} ./space-media-vod
docker build -t local/space-postgresql:{tag} ./space-postgresql
docker build -t local/space-agent:{tag} ./space-agent
docker build -t local/space-upgrade:{tag} ./space-upgrade

```

#### server deploy

Once all the builds are complete, you can start deploying your own AOspace

After making sure that the docker-compose file in space-agent has been modified before compiling using a local image

Use the following command to deploy and run

Notes: DATADIR is aospace server directory which you want to install

- Linux

```shell
export DATADIR="$HOME/aospace"
sudo docker network create ao-space;
sudo docker run -d --name aospace-all-in-one  \
        --restart always  \
        --network=ao-space  \
        --publish 5678:5678  \
        --publish 127.0.0.1:5680:5680  \
        -v $DATADIR:/aospace  \
        -v /var/run/docker.sock:/var/run/docker.sock:ro  \
        -e AOSPACE_DATADIR=$DATADIR \
        -e RUN_NETWORK_MODE="host"  \
        local/space-agent:{tag}
```

you need to change {tag} to your own build tag

- Windows

```shell
docker network create ao-space
docker run -d --name aospace-all-in-one \
        --restart always \
        --network=ao-space \
        --publish 5678:5678 \
        --publish 127.0.0.1:5680:5680 \
        -v c:/aospace:/aospace \ # you can change c:/ to your own disk ,like d:/
        -v //var/run/docker.sock:/var/run/docker.sock:ro \
        -e AOSPACE_DATADIR=/run/desktop/mnt/host/c/aospace \
        local/space-agent:{tag} 
```

you need to change {tag} to your own build tag

- MacOS

```bash
HOME="/Users/User-Name-Here"
DATADIR="$HOME/aospace"
docker network create ao-space
docker run -d --name aospace-all-in-one  \
        --restart always  \
        --network=ao-space  \
        --publish 5678:5678  \
        --publish 127.0.0.1:5680:5680  \
        -v $DATADIR:/aospace  \
        -v /var/run/docker.sock.raw:/var/run/docker.sock:ro  \
        -e AOSPACE_DATADIR=$DATADIR  \
        local/space-agent:{tag}  # you can change {tag} to your own build tag
```

you need to change {tag} to your own build tag

### Clients build and run  

#### Android

Environment

- Install Java Development Kit (JDK) and configure the JAVA_HOME environment variable.

- Download and install Android Studio development tool. During the installation process, choose to install Android SDK and other necessary components.

- Create an Android Virtual Device (AVD), or use an Android phone. Open the Developer Options and connect the development device.

Source code download

You can download the project as a whole through [GitHub](https://github.com/ao-space/ao.space), or download this module's repository using the following command:

- `git clone git@github.com:ao-space/client-android.git ./client-android`

Deploy

Import the client-android project into Android Studio. Click "Run app" to directly run and debug the project on a virtual device/real device. Alternatively, click "Build - Generate Signed Bundle or APK", choose APK, and sign and package it with your own keystore file to install it as an APK on an Android phone.

#### iOS

Get the source code

You can use the clone command

  ```text
  git clone https://github.com/ao-space/client-ios.git
  ```

  Or get it directly by downloading.

Install dependent libraries

Some third-party open source library codes are used in the Aospace source code, and the dependent libraries need to be installed before running the project. The specific method is: open the terminal application on the Mac, enter the directory where the source code file is located (the directory where the Podfile file is located), execute the `Pod install` command, and install the third-party open source library that the project depends on.

Run Application

Open the project file EulixSpace.xcworkspace with Xcode and run the project. The APP uses the camera and can run on the iPhone device, or through the emulator My Mac (Designed for iPhone) to run the program.

### Client connect (no platform / LAN-only)

In no-platform mode, only LAN access is supported. Make sure the phone and server are on the same LAN.

1. Server web entry (for quick check): `http://<server-ip>` or `https://<server-ip>`
2. When binding/initializing the device in the mobile app, choose the LAN/local channel.
3. If the app asks for a platform URL, leave it empty or disable Internet access.

### Regression and troubleshooting (validated)

The following flow was validated on `2026-02-06` and can be reused directly.

1. Restart regression (service recovery):

```shell
cd deploy/server
docker compose --env-file .env.aofs -f docker-compose.yml down
docker compose --env-file .env.aofs -f docker-compose.yml up -d
AOFS_BASE=http://127.0.0.1:2001 AGENT_BASE=http://127.0.0.1:5678 GATEWAY_BASE=http://127.0.0.1:8080 ./scripts/api-full-regression.sh
```

2. Upload stability regression (long-run + concurrent):

```shell
AOFS_BASE=http://127.0.0.1:2001 ./scripts/api-e2e-write.sh
AOFS_BASE=http://127.0.0.1:2001 ./scripts/api-e2e-write.sh

# 2 concurrent multipart lanes
AOFS_BASE=http://127.0.0.1:2001 ./scripts/api-e2e-multipart.sh &
AOFS_BASE=http://127.0.0.1:2001 ./scripts/api-e2e-multipart.sh &
wait
```

3. LAN binding / online-state critical settings:
- In `deploy/server/docker-compose.full.yml`, `aospace-gateway` must expose `0.0.0.0:80->8080`; otherwise Android may show the device as offline.
- `deploy/server/data-aofs/etc/ao-space/hardware/host_ip.data` must contain a LAN address (for example `192.168.x.x:80`), not `127.0.0.1:*`.

4. Quick probes:

```shell
curl -sS "http://127.0.0.1:80/space/status"
curl -sS "http://127.0.0.1:2001/space/v1/api/status?userId=1"
curl -sS "http://127.0.0.1:5678/agent/status"
```

## Release download and deply

### Platform download and deploy

You can find our latest released version at [here](https://ao.space/download/platform), extract it, and deploy it according to the README.md document.

### Server download and deploy 

you can find our newest published aospace-all-in-one image at [here](https://github.com/ao-space/space-agent/pkgs/container/space-agent)

if you want to deploy newest AOspace

#### Server Prepare Environment

- docker (>=18.09)

#### Deploy

- Linux

```shell
export DATADIR="$HOME/aospace"
sudo docker network create ao-space;
sudo docker run -d --name aospace-all-in-one  \
        --restart always  \
        --network=ao-space  \
        --publish 5678:5678  \
        --publish 127.0.0.1:5680:5680  \
        -v $DATADIR:/aospace  \
        -v /var/run/docker.sock:/var/run/docker.sock:ro  \
        -e AOSPACE_DATADIR=$DATADIR \
        -e RUN_NETWORK_MODE="host"  \
        ghcr.io/ao-space/space-agent:v1.0.0
```

- Windows

```shell
docker network create ao-space
docker run -d --name aospace-all-in-one `
        --restart always `
        --network=ao-space `
        --publish 5678:5678 `
        --publish 127.0.0.1:5680:5680 `
        -v c:/aospace:/aospace ` # you can change c:/ to your own disk ,like d:/
        -v //var/run/docker.sock:/var/run/docker.sock:ro `
        -e AOSPACE_DATADIR=/run/desktop/mnt/host/c/aospace `
        ghcr.io/ao-space/space-agent:v1.0.0
```

- MacOS

```zsh
docker network create ao-space
HOME="/Users/User-Name-Here" # you can change User-Name-Here to your own name
DATADIR="$HOME/aospace"
docker run -d --name aospace-all-in-one  \
        --restart always  \
        --network=ao-space  \
        --publish 5678:5678  \
        --publish 127.0.0.1:5680:5680  \
        -v $DATADIR:/aospace  \
        -v /var/run/docker.sock.raw:/var/run/docker.sock:ro  \
        -e AOSPACE_DATADIR=$DATADIR  \
        ghcr.io/ao-space/space-agent:v1.0.0
```

more docs refer to [AO.space Website](https://ao.space/en/docs/install-opensource-overview)

### Install Client

- No need to download source code, quick installation experience
- Android support 5.0 and above
- iOS supports 12.0 and above

Please refer to the [download page](https://ao.space/download) to install the client.
