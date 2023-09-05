# 构建部署

[English](../en/build-and-deploy.md) | 简体中文

## 源码下载

请按顺序执行一下命令，下载整个项目源码:

- 创建并进入本地工作目录， 执行命令: `mkdir ./WORKDIR && cd ./WORKDIR`
- 下载源码，执行命令: `git clone --recurse-submodules git@github.com:ao-space/ao.space.git`
- 进入代码目录： `cd ao.space`

## 构建和部署

### 平台构建和部署

我们在 [platform-deploy仓库](https://github.com/ao-space/platform-deploy) 中详细介绍了平台的构建和部署过程。

需要提醒的是上述过程使用了 platform-deploy 仓库中的 docker-compose.yml 文件来编排相关组件的容器部署，其所使用的镜像为 github 镜像仓库中 dev 分支的最新镜像。

如果您希望用本地自己构建的镜像来替换部分组件，可将相关组件的 image 项修改为您自己编译的镜像地址，并执行 `docker-compose up -d` 命令即可。

### 服务端构建和部署 

#### 环境准备

- docker (>=18.09)
- git
- golang 1.18 +

#### 服务端构建

docker镜像构建方式基本一样，都是用Dockerfile来构建镜像

构建之前，我想提醒您，如果您希望用本地自己构建的镜像来运行傲空间

建议您先构建除了 space-agent 之外的其他镜像，最后再构建space-agent

在构建 aospace-agent 之前， 需要将 space-agent/res/docker-compose_run_as_docker.yml （win/Mac）

或者 space-agent/res/docker-compose_run_as_docker_network_mode_host.yml （linux） 中的相关 image 项修改为您自己编译的镜像地址

例如这里用的 *local/space-aofs:{tag}*

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

可以通过 `docker images` 查看自己是否构建成功

#### 服务端部署

全部构建完成后，您可以开始部署自己的傲空间

确保 space-agent 中的 docker-compose 文件在编译前已被修改使用本地的image后

使用以下命令部署并运行

- Linux

```shell
DATADIR="$HOME/aospace"
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

你需要将{tag} 修改为自己本地构建的镜像tag

- Windows

```shell
docker network create ao-space
docker run -d --name aospace-all-in-one \
        --restart always \
        --network=ao-space `
        --publish 5678:5678 `
        --publish 127.0.0.1:5680:5680 `
        -v c:/aospace:/aospace ` # you can change c:/ to your own disk ,like d:/
        -v //var/run/docker.sock:/var/run/docker.sock:ro `
        -e AOSPACE_DATADIR=/run/desktop/mnt/host/c/aospace `
        local/space-agent:{tag}
```

你需要将{tag} 修改为自己本地构建的镜像tag

- MacOS

```zsh
docker network create ao-space
HOME="/Users/User-Name-Here"
DATADIR="$HOME/aospace"
docker run -d --name aospace-all-in-one  \
        --restart always  \
        --network=ao-space  \
        --publish 5678:5678  \
        --publish 127.0.0.1:5680:5680  \
        -v $DATADIR:/aospace  \
        -v /var/run/docker.sock.raw:/var/run/docker.sock:ro  \
        -e AOSPACE_DATADIR=$DATADIR  \
        local/space-agent:{tag}
```

你需要将{tag} 修改为自己本地构建的镜像tag

### 客户端构建和运行  

#### Android

环境准备：

- 安装 Java 开发工具包 (JDK)，配置 JAVA_HOME 环境变量
- 下载并安装 Android Studio 开发工具，在安装过程中，选择安装 Android SDK 和其他必要的组件
- 创建 Android 虚拟设备（AVD），或使用Android系统手机，打开开发者选项，连接开发设备

源码下载：

可以使用[项目整体下载](xxx)下载的方式，也可以通过通过一下命令下载本模块的仓库：

- `git clone git@github.com:ao-space/client-android`

部署：

使用 Android Studio 导入 client-android 项目。可在点击 `Run app` 直接在虚拟设备/真机上运行、调试项目。也可通过点击 `Build - Generate Signed Bundle or APK` ，选择 APK ， 使用自己创建的密钥库文件进行签名打包，以安装包的形式安装到Android系统手机上。

#### iOS

获取源码：

可以通过 clone 命令方式

` git clone <https://github.com/ao-space/client-ios.git> `

 或者直接下载的方式获取。  

安装依赖库：

傲空间源码中使用了一些第三方开源库代码，在运行项目工程前需要先安装依赖的库。具体方式为：打开 Mac 上终端应用程序，进入源码文件所在目录（Podfile 文件所在目录），执行 `Pod install` 命令，安装项目所依赖的第三方开源库。  

运行：
用 Xcode 打开工程文件 EulixSpace.xcworkspace 后 Run 项目。APP 使用到摄像头，可以在 iPhone 设备上运行，或者通过模拟器 My Mac(Designed for iPhone) 来运行程序。

## Release 版本下载和部署

### 空间平台 Release 版本下载和部署

你可以在 [这里](https://ao.space/download/platform) 找到我们最新发布的版本，解压缩后，按照 README.md 文档进行部署。

### 服务器 Release 版本下载

你可以在[here](https://github.com/ao-space/space-agent/pkgs/container/space-agent)找到我们最新发布的版本

如果你想要安装最新版本的傲空间

#### 服务器环境准备

- docker (>=18.09)

#### 安装部署

注：DATADIR为aospace的安装目录

##### Linux

```shell
export DATADIR="$HOME/aospace";
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

你需要将{tag} 修改为自己本地构建的镜像tag

##### Windows

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
        ghcr.io/ao-space/space-agent:v1.0.0
```

##### MacOS

```zsh
HOME="/Users/User-Name-Here" # you can change User-Name-Here to your own name
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
        ghcr.io/ao-space/space-agent:v1.0.0
```

更多部署文档请参考[官网](https://ao.space/open/documentation/105001)

### Clients download and run  @fuyu
