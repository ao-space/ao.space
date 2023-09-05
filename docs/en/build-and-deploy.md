# build and deploy

Englis | [简体中文](../cn/build-and-deploy.md)

## Source code download

Please execute the following command to download the entire source code of the project:

- Create a local directory, run cmd:  `mkdir ./WORKDIR && cd ./WORKDIR`
- Download source code, run cmd: `git clone --recurse-submodules git@github.com:ao-space/ao.space.git`
- Enter the folder/directory, run cmd: `cd ./ao.space`

## Build and deploy

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
docker build -t local/space-agent:{tag} ./space-postgresql
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

You can download the project as a whole through [xxx], or download this module's repository using the following command:

- `git clone git@github.com:ao-space/space-aofs.git ./client-android`

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

more docs refer to [AOspace Website](https://ao.space/open/documentation/105001)

### Clients download and run  @fuyu
