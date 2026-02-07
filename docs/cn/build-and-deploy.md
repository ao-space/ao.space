# 构建部署

[English](../en/build-and-deploy.md) | 简体中文

## 源码下载

请按顺序执行一下命令，下载整个项目源码:

- 创建并进入本地工作目录， 执行命令: `mkdir ./WORKDIR && cd ./WORKDIR`
- 下载源码，执行命令: `git clone --recurse-submodules git@github.com:ao-space/ao.space.git`
- 进入代码目录： `cd ao.space`

## 构建和部署

如果需要简化的 compose 部署方式，请查看：
1. `deploy/server/README.md`
2. `deploy/platform/README.md`

### 服务端（无平台）构建与部署（推荐本地/开发）

此模式不依赖平台。平台相关能力（互联网通道、推送、应用商店、版本检查）不可用。

1. 复制 `.env` 并配置密码/端口：

```shell
cd deploy/server
cp .env.example .env
```

2. 修改 `deploy/server/system-agent.yml`，让 Redis 密码与 `.env` 保持一致。

3. 构建镜像：

```shell
docker compose --env-file .env build
```

说明：
1. `space-gateway` 使用 `server/space-gateway/Dockerfile.jvm.build` 在构建镜像时编译 Quarkus。
2. 运行时基础镜像使用 `eclipse-temurin:17-jre`，避免在构建中通过 `yum` 安装 JDK 导致空间不足。
3. 无平台模式下将平台地址设置为 `http://127.0.0.1`，避免 SSL 报错。

### 离线构建 / 预编译（space-gateway）

如果 `docker build` 无法访问 Maven 仓库，可以先本地预编译 gateway，然后使用预编译 JVM 运行镜像。

1. 本地编译：

```shell
cd server/space-gateway
./mvnw -Dmaven.test.skip=true package
```

2. 修改 compose 使用 `Dockerfile.jvm.prebuilt`：

```yaml
services:
  aospace-gateway:
    build:
      context: ../../server/space-gateway
      dockerfile: Dockerfile.jvm.prebuilt
```

4. 启动：

```shell
docker compose --env-file .env up -d --build
```

### 平台构建和部署

我们在 [platform-deploy仓库](https://github.com/ao-space/platform-deploy) 中详细介绍了平台的构建和部署过程。

需要提醒的是上述过程使用了 platform-deploy 仓库中的 docker-compose.yml 文件来编排相关组件的容器部署，其所使用的镜像为 github 镜像仓库中 dev 分支的最新镜像。

如果您希望用本地自己构建的镜像来替换部分组件，可将相关组件的 image 项修改为您自己编译的镜像地址，并执行 `docker-compose up -d` 命令即可。

#### 精简平台部署 (单机)

对于个人/单机部署，我们提供了简化的配置：

1. 配置环境：

```shell
cd deploy/platform
cp .env.simple.example .env
# 编辑 .env 设置域名和密码
```

2. 配置 SSL 证书：

```shell
mkdir -p data/ssl
# 将通配符证书复制到 data/ssl/tls.crt 和 data/ssl/tls.key
```

3. 启动平台：

```shell
docker compose -f docker-compose.simple.yml up -d
./scripts/init-network.sh
```

4. 验证部署：

```shell
curl -H "Request-Id: test" https://your-domain.com/v2/platform/status
```

DNS 和 SSL 配置详情请参阅 `deploy/platform/README-simple.md`。

精简版平台还提供一步注册 API (`POST /v2/platform/spaces`)。详情请参阅 [平台 API 变更说明](./platform-api-changes.md)。

### 服务端构建和部署 

#### 环境准备

- docker (>=18.09)
- git
- golang 1.18 +

#### 服务端构建

docker镜像构建方式基本一样，都是用Dockerfile来构建镜像

构建之前，我想提醒您，如果您希望用本地自己构建的镜像来运行 AO.space

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
docker build -t local/space-agent:{tag} ./space-agent
docker build -t local/space-upgrade:{tag} ./space-upgrade

```

可以通过 `docker images` 查看自己是否构建成功

#### 服务端部署

全部构建完成后，您可以开始部署自己的 AO.space

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

可以使用[项目整体下载](https://github.com/ao-space/ao.space)下载的方式，也可以通过通过一下命令下载本模块的仓库：

- `git clone git@github.com:ao-space/client-android`

部署：

使用 Android Studio 导入 client-android 项目。可在点击 `Run app` 直接在虚拟设备/真机上运行、调试项目。也可通过点击 `Build - Generate Signed Bundle or APK` ，选择 APK ， 使用自己创建的密钥库文件进行签名打包，以安装包的形式安装到Android系统手机上。

#### iOS

获取源码：

可以通过 clone 命令方式

` git clone <https://github.com/ao-space/client-ios.git> `

 或者直接下载的方式获取。  

安装依赖库：

AO.space 源码中使用了一些第三方开源库代码，在运行项目工程前需要先安装依赖的库。具体方式为：打开 Mac 上终端应用程序，进入源码文件所在目录（Podfile 文件所在目录），执行 `Pod install` 命令，安装项目所依赖的第三方开源库。  

运行：
用 Xcode 打开工程文件 EulixSpace.xcworkspace 后 Run 项目。APP 使用到摄像头，可以在 iPhone 设备上运行，或者通过模拟器 My Mac(Designed for iPhone) 来运行程序。

### 客户端连接（无平台 / 仅局域网）

无平台模式下仅支持局域网访问，请确保手机与服务器在同一局域网内。

1. 服务器 Web 入口（用于快速检查）：`http://<server-ip>` 或 `https://<server-ip>`
2. 在移动端绑定/初始化设备时，选择局域网/本地通道。
3. 如果客户端要求填写平台地址，请留空或关闭互联网访问选项。

### 精简模式回归与排障（已验证）

以下流程已在 `2026-02-06` 验证通过，可直接复用。

1. 重启回归（验证服务恢复能力）：

```shell
cd deploy/server
docker compose --env-file .env.aofs -f docker-compose.yml down
docker compose --env-file .env.aofs -f docker-compose.yml up -d
AOFS_BASE=http://127.0.0.1:2001 AGENT_BASE=http://127.0.0.1:5678 GATEWAY_BASE=http://127.0.0.1:8080 ./scripts/api-full-regression.sh
```

2. 上传稳定性回归（长时 + 并发）：

```shell
AOFS_BASE=http://127.0.0.1:2001 ./scripts/api-e2e-write.sh
AOFS_BASE=http://127.0.0.1:2001 ./scripts/api-e2e-write.sh

# 并发 2 路分片上传
AOFS_BASE=http://127.0.0.1:2001 ./scripts/api-e2e-multipart.sh &
AOFS_BASE=http://127.0.0.1:2001 ./scripts/api-e2e-multipart.sh &
wait
```

3. 局域网绑定/在线状态关键配置：
- `deploy/server/docker-compose.full.yml` 中 `aospace-gateway` 需暴露 `0.0.0.0:80->8080`，否则手机端会显示断线。
- `deploy/server/data-aofs/etc/ao-space/hardware/host_ip.data` 应为局域网地址（如 `192.168.x.x:80`），不能是 `127.0.0.1:*`。

4. 快速检查命令：

```shell
curl -sS "http://127.0.0.1:80/space/status"
curl -sS "http://127.0.0.1:2001/space/v1/api/status?userId=1"
curl -sS "http://127.0.0.1:5678/agent/status"
```

## Release 版本下载和部署

### 空间平台 Release 版本下载和部署

你可以在 [这里](https://ao.space/download/platform) 找到我们最新发布的版本，解压缩后，按照 README.md 文档进行部署。

### 服务器 Release 版本下载

你可以在[here](https://github.com/ao-space/space-agent/pkgs/container/space-agent)找到我们最新发布的版本

如果你想要安装最新版本的 AO.space

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

更多文档请参考官网 [开源版安装指南](https://ao.space/docs/install-opensource-overview)

### 安装客户端

- 无需下载源码，快速安装体验
- Android 支持 5.0 及以上系统版本
- iOS 支持 12.0 及以上系统版本

请访问[下载页面](https://ao.space/download)安装客户端。
