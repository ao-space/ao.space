# AO.space

[English](README.md) | 简体中文

**AO.space** 是一个以保护个人数据安全和隐私为核心的解决方案。通过端对端加密、基于设备认证等技术，确保用户完全掌控个人账号和数据。同时，采用平台透明转发、点对点加速、局域网直连等技术，让用户随时随地的极速访问个人数据。利用 PWA（Progressive Web App）和云原生技术，设计并打造前后端一体的应用生态。

**AO.space** 由服务端、客户端、平台端三个部分组成。服务端和客户端只运行在个人设备上，使用公钥认证建立加密通信通道。服务端是管理保护用户数据的核心部分，目前支持 x86_64 和 aarch64 两个架构，可运行在个人服务器、个人计算机等设备上。客户端让用户在不同平台上快速安全的访问个人数据，目前支持 Web、Android 和 iOS，方便用户随时随地使用。平台端既可使用 AO.space 默认提供的平台，也可以自己部署，两种方式下平台都在无法解析用户数据的前提下提供网络通信服务。

**AO.space** 项目现已捐赠到 openEuler 社区，基于社区不断获得产品、方案等更多创新发展，实现共赢。[查看更多 >](https://ao.space/blog/aospace-success-openeuler-summit-2023)

## 系统整体架构

AO.space 系统由三个主要部分构成：服务端、客户端和平台端。服务端为个人空间的核心，部署于个人长期运行的并且联网的设备中，如个人服务器、个人计算机等。客户端为个人日常使用的电子设备，如手机、平板、个人电脑等，目前 AO.space 提供 Web、iOS 和 Android 等客户端。平台端在无法解析用户数据的前提下，为个人空间提供基础网络访问、安全防护等服务。以下是总体的架构设计草图和基础组件的详细信息。

![AO.space-architecture](./assets/architecture.png)

### 服务端

服务端是 AO.space 的核心部分，一般部署在个人设备中，由空间软件、空间服务、容器运行时、基础操作系统（Linux 发行版、Windows、macOS）和硬件组成。在基础操作系统之上，以容器方式部署空间的服务和应用，包括以下模块：

- Web 服务（Nginx）：服务端的入口服务。
- 代理（Agent）：既是空间基础服务的管理者，也是服务端、客户端与平台端之间沟通的桥梁，适应操作系统。
- 网关（Gateway）：负责 API 的路由、转发、端到端加密和解密、认证以及整体空间应用层请求的授权。
- AOFS：提供空间文件的存储和管理功能。它是一个虚拟文件系统，结合了对象存储和文件存储方法。
- 预览（Preview）：负责为空间文件生成预览图。
- 容器管理器（ContainerMgr）：用于与底层容器服务进行通信。
- 数据库：
  - SQL 实例（Postgresql）：为空间内的关系型数据库提供数据存储和管理。
  - NoSQL 实例（Redis）：为空间内的非关系型数据库提供数据存储和管理，以及消息功能。
- 网络客户端（Network client）：与平台端的网络转发服务建立安全通信通道，保证客户端与服务端在不同网络情况下的稳定通信。它还用于与客户端建立点对点（P2P）连接。当前基于 [GT](https://github.com/ao-space/gt) 实现。
- 空间应用：空间支持前端应用、后端应用和前后端混合应用三种类型，用于扩展空间功能。这些官方或第三方应用程序可以通过空间域名访问，例如 Card/CalDAV 服务。

### 客户端

客户端是整个系统的前端，负责用户在不同的个人设备上与空间的交互，使用户能够随时随地访问空间的所有功能。目前提供 Web、iOS 和 Android 客户端，提供以下关键模块：

- 端到端加密通道
- 空间绑定
- 文件
- 设备
- 家庭
- 空间应用
- 安全

### 平台端

平台提供基本网络资源和相关管理能力。它包括以下组件：

- 入口网关（Endpoint）：负责处理和分配空间生态系统内的整体流量。
- 基础服务（BaseService）：提供空间设备注册服务，同时协调和管理平台网络资源（域名、转发代理等）。
- 网络转发服务（Transit server）：提供网络流量转发服务，使用户能够在大多数情况安全的通过互联网网络访问在办公室或家庭网络中的空间服务端。当前基于 [GT](https://github.com/ao-space/gt) 实现。

更多技术内容，请查看 [#文档](#文档)。

## 源码仓库介绍

项目整体包含三大部分 ：

- 服务端 [server](./server/)
- 客户端 [client](./client/)
- 平台端 [platform](./platform/)

### 服务端 Server 仓库介绍

服务器为主要数据载体，也是数据保护的核心，由如下仓库组成：
  
- [space-agent](https://github.com/ao-space/space-agent)：提供设备绑定、系统服务模块启动引导和管理等服务
- [space-aofs](https://github.com/ao-space/space-aofs)：提供文件访问服务，包括文件查询、分片上传、下载等接口
- [space-gateway](https://github.com/ao-space/space-gateway)：端到端的请求安全处理模块，收到请求后解密后转发给相关模块，对回应加密后响应给请求端。
- [space-filepreview](https://github.com/ao-space/space-filepreview)：支持媒体文件的缩略图、预览图的生成
- [space-media-vod](https://github.com/ao-space/space-media-vod)：提供流媒体播放服务
- [space-web](https://github.com/ao-space/space-web)：提供 Web 端的服务资源及请求的反向代理服务
- [space-upgrade](https://github.com/ao-space/space-upgrade)：按需启动，主要负责服务端的升级
- [space-single](https://github.com/ao-space/space-single)：将服务端的所有组件合并到一个容器方便用户一键式部署

### 客户端 Client 仓库介绍

客户端支持 Android、iOS、Web 版本，由如下仓库组成：

- [client-android](https://github.com/ao-space/client-android)：提供 Android 端的客户端
- [client-ios](https://github.com/ao-space/client-ios)：提供 iOS 端的客户端
- [space-web](https://github.com/ao-space/space-web)：部署在 Server 上，提供 Web 端的客户端

### 平台端 Platform 仓库介绍

平台为个人设备提供透明通信通道服务和互联网访问的安全防护，由如下仓库组成：

- [platform-proxy](https://github.com/ao-space/platform-proxy)：为用户域名流量提供高可用转发和横向扩容的支持。
- [platform-base](https://github.com/ao-space/platform-base)：为服务端设备提供注册服务，以及协调和管理平台网络资源。
- [GT](https://github.com/ao-space/gt)：提供通过中继转发的方式穿透 NAT 访问设备的网络支持服务。

## 构建和部署

可以使用发布的版本进行部署，也可以从源码编译构建并部署，请参考 [build-and-deploy](./docs/cn/build-and-deploy.md)。

## 文档

- [开发文档](https://ao.space/docs)
- [使用文档](https://ao.space/support/help)
- [博客](https://ao.space/blog)
- [API 参考文档](https://ao.space/docs/api/)

开发文档和使用文档的仓库为 [官网仓库](https://github.com/ao-space/website)，欢迎提交 PR。

## 贡献指南

我们非常欢迎对本项目进行贡献。以下是一些指导原则和建议，希望能够帮助您参与到项目中来。

[贡献指南](./docs/cn/contribution-guidelines.md)

## 联系我们
- 邮箱：<developer@ao.space>
- 官网：[https://ao.space](https://ao.space)
- slack 讨论组：[https://slack.ao.space](https://slack.ao.space)

## License

AO.space 的主要仓库的开源协议采用 Apache License 2.0 协议, 有一个仓库保持与上游仓库的协议一致为 AGPL-3.0。协议详情请查看 [LICENSE](./LICENSE)。

- [space-media-vod](https://github.com/ao-space/space-media-vod) -  AGPL-3.0 license

## 致谢

我们的项目，离不开其它项目的开源成果，在此特别感谢（列表不分前后，以字母排序） [AFNetworking](https://github.com/AFNetworking/AFNetworking)、[Android-Office](https://github.com/zjtone/Android-Office)、[AndroidPdfViewer](https://github.com/barteksc/AndroidPdfViewer)、[BouncyCastle](https://github.com/bcgit/bc-java)、[CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack)、[commons-codec](https://commons.apache.org/proper/commons-codec/)、[eventbus](https://github.com/greenrobot/EventBus)、[ExoPlayer](https://github.com/google/ExoPlayer)、[fastjson](https://github.com/alibaba/fastjson)、[FileMD5Hash](https://github.com/JoeKun/FileMD5Hash)、[findbugs](https://findbugs.sourceforge.net/)、[FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage)、[GCDWebServer](https://github.com/swisspol/GCDWebServer)、[Gin](https://github.com/gin-gonic/gin)、[Gitlab](https://about.gitlab.com/)、[GKPhotoBrowser](https://github.com/QuintGao/GKPhotoBrowser)、[glide](https://github.com/bumptech/glide)、[Go](https://github.com/golang/go)、[graalvm](https://github.com/graalvm)、[gson](https://github.com/google/gson)、[guava](https://github.com/google/guava)、[ip2region](https://github.com/lionsoul2014/ip2region)、[IQKeyboardManager](https://github.com/hackiftekhar/IQKeyboardManager)、[ISO8601](https://github.com/erlsci/iso8601)、[jakarta.mail](https://github.com/jakartaee/mail-api)、[java-totp](https://github.com/samdjstevens/java-totp)、[JSONModel](https://github.com/jsonmodel/jsonmodel)、[kaltura/nginx-vod-module](https://github.com/kaltura/nginx-vod-module)、[lombok](https://github.com/projectlombok/lombok)、[LookinServer](https://github.com/QMUI/LookinServer)、[lottie-ios](https://github.com/airbnb/lottie-ios)、[lottie](https://github.com/airbnb/lottie-android)、[Masonry](https://github.com/SnapKit/Masonry)、[MJExtension](https://github.com/CoderMJLee/MJExtension)、[nginx](http://nginx.org)、[okhttp](https://github.com/square/okhttp)、[OpenResty](https://github.com/openresty/)、[OpenSSL-Universal](https://github.com/cute/OpenSSL-Universal)、[pinyin4j](https://github.com/belerweb/pinyin4j)、[postgres](https://github.com/postgres/postgres)、[preview-generator](https://github.com/algoo/preview-generator)、[quarkus](https://github.com/quarkusio/quarkus)、[Reachability](https://github.com/tonymillion/Reachability)、[Redis](https://redis.io/)、[rest-assured](https://github.com/rest-assured/rest-assured)、[Retrofit](https://github.com/square/retrofit)、[RxAndroid](https://github.com/ReactiveX/RxAndroid)、[Rxjava](https://github.com/ReactiveX/RxJava)、[SAMKeychain](https://github.com/soffes/SAMKeychain)、[SDCycleScrollView](https://github.com/gsdios/SDCycleScrollView)、[SDWebImage](https://github.com/SDWebImage/SDWebImage)、[SmartRefreshLayout](https://github.com/scwang90/SmartRefreshLayout)、[SocketRocket](https://github.com/facebookincubator/SocketRocket)、[SSZipArchive](https://github.com/wuhaiwei/SSZipArchive)、[SVProgressHUD](https://github.com/SVProgressHUD/SVProgressHUD)、[WCDB](https://github.com/Tencent/wcdb)、[WebSocket](https://github.com/TooTallNate/Java-WebSocket)、[YCBase](https://github.com/ungacy/YCBase)、[YCEasyTool](https://github.com/ungacy/YCEasyTool)、[YYCache](https://github.com/ibireme/YYCache)、[YYModel](https://github.com/ibireme/YYModel)、[ZXing](https://github.com/zxing/zxing) 等。

最后，感谢您对本项目的贡献。我们欢迎各种形式的贡献，包括但不限于代码贡献、问题报告、功能请求、文档编写等。我们相信在您的帮助下，本项目会变得更加完善和强大。
