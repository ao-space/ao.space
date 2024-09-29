# AO.space

English | [简体中文](./README_cn.md)

AO.space is a solution that focuses on protecting personal data security and privacy. Utilizing end-to-end encryption and device-based authentication, users have complete control over their personal accounts and data. AO.space also employs various technologies, including transparent platform forwarding, peer-to-peer acceleration, and LAN direct connection, to enable fast access to personal data from anywhere at any time. Leveraging Progressive Web App and cloud-native technology, AO.space has developed an integrated application ecosystem that could include both front-end and back-end components.

AO.space is composed of three parts: server-side, client-side, and platform-side. The server-side and client-side run on personal devices and establish encrypted communication channels with public key authentication. The server-side supports x86_64 and aarch64 architectures and can run on personal servers, computers, or other similar devices. The client-side supports Android, iOS, and Web platforms, providing users with the convenience of using AO.space anywhere and anytime. For platform side, user can either use the default platform provided by AO.space or deploy by own. In both cases, the platform provides network communication services without the capability to decipher user data.

The AO.space project has been donated to the openEuler community. Based on the community, we will continue to obtain more innovative developments such as products and solutions to achieve a win-win situation.[Learn more >](https://ao.space/en/blog/aospace-success-openeuler-summit-2023)

## Architecture

An architectural design overview is as below, along with detailed information about the core components, encompassing server-side, client-side, and platform-side. The server-side serves as the core of the personal space and is deployed on long-running, connected devices such as personal servers and personal computers. The client-side is used for everyday personal electronic devices, including smartphones, tablets, and personal computers. AO.space currently offers clients for Web, iOS, and Android. The platform-side provides network communication services without the capability to decipher user data.

![AO.space-architecture](./assets/architecture.png)

### Server-side

The core of the AO.space, also known as the AO.space Server, consists of sofeware, hardware, operating system (such as EulixOS/openEuler and other Linux distributions). On top of the basic operating system, various space-related services and essential components are deployed primarily using containerization. It comprises the following modules:

- Web Server(nginx): The entry service for traffic into the AO.space.
- Agent: It acts as a bridge between the client, platform, and server, adapting to the operating system.
- Gateway: Responsible for API routing, forwarding, end-to-end encryption and decryption, authentication, and authorization of overal the AO.space application-layer requests.
- AOFS: It offers storage and management functionalities for space files. It is a virtual file system that combines object storage and file storage methods.
- Preview: It's in charge of generating preview images for space files.
- ContainerMgr: It is used to communicate with underlying container services.
- Databases:
  - SQL Instance (Postgresql): It provides data storage and management for relational databases within the space.
  - NoSQL Instance (Redis): It offers data storage and management for non-relational databases within the space, as well as messaging capabilities.
- Network client: It's part of implementation for transiting network from internet to NAT office or home netrok. It also helps to establish P2P connections with the AO.space client.
- Applications: They are divided into three types: front-end only, back-end only, and hybrid applications which contain front-end and back-end. They are mainly used to expand the functionality of the AO.space services and are the key elements of the AO.space ecosystem. These official or third-party applications can be accessed through the AO.space Space user domain from internet, such as Card/CalDAV services.

### Client-side

The client functions as the system's frontend, granting us with access to all functionalities of the AO.space. It encompasses Web, iOS, Android platforms, providing the following key modules:

- End-to-End Encryption Channel
- Files
- Devices
- Family
- Space Application
- Developer Options
- Security

### Platform-side

The platform offers essential network resources and associated management capabilities. It comprises the subsequent components:

- Endpoint: It handles and dispatches the overall traffic within the AO.space ecosystem.
- BaseService: It offers the AO.space device registration service, along with coordinating and managing platform network resources (domains, forwarding proxies, etc.).
- Transit server: It gives us the ability to send network traffic from internet to the AO.space device typically connected within a NAT office or home network. Additionally, it also supplies STUN services to enable to transit traffic through p2p channel using the WebRTC-based protocol.

For more information, please visit the [#Documentation](#documentation).

## Source code repository introduction

The overall project includes ：

- [server](./server/)
- [client](./client/)
- [platform](./platform/)

### Server repository introduction

The server is the main data carrier of AO.space and is also the core of data protection. It consists of the following repositories:
  
- [space-agent](https://github.com/ao-space/space-agent)：It provides services such as device binding, system service module startup bootstrapping, and management.
- [space-aofs](https://github.com/ao-space/space-aofs)：It provides file access services, including interfaces for file querying, chunked uploading, downloading, and more.
- [space-gateway](https://github.com/ao-space/space-gateway)：The end-to-end request security processing module receives requests, decrypts them, and forwards them to the relevant modules. It encrypts the responses and sends them back to the requesting client.
- [space-filepreview](https://github.com/ao-space/space-filepreview)：It supports the generation of thumbnails and preview images for media files. This functionality allows users to generate smaller versions or preview images of their media files, which can be useful for displaying file previews or creating thumbnails for faster loading.
- [space-media-vod](https://github.com/ao-space/space-media-vod)：Provide streaming media data access services
- [space-web](https://github.com/ao-space/space-web)：Providing an Nginx reverse proxy service for serving web-based service resources and requests
- [space-upgrade](https://github.com/ao-space/space-upgrade)：On-demand startup, mainly responsible for server-side upgrades
- [space-single](https://github.com/ao-space/space-single)：Combine all server-side components into a single container for easy one-click deployment.

### Clients repository introduction

The client supports Android, iOS, and Web versions, and consists of the following repositories:

- [client-android](https://github.com/ao-space/client-android)：Provide a client on Android platform for AO.space.
- [client-ios](https://github.com/ao-space/client-ios)：Provide a client on iOS platform for AO.space.
- [space-web](https://github.com/ao-space/space-web)：Deployed on the server, providing a web-based client for AO.space.

### Platform repository introduction

The responsibility of AO.space Platform is to establish a transparent communication channel for personal equipment. It consists of the following repositories:

- [platform-proxy](https://github.com/ao-space/platform-proxy)：provide high-availability forwarding and horizontal expansion support for the requests from clients.
- [platform-base](https://github.com/ao-space/platform-base)：provide the registration service of AO.space, and coordinate and manage the platform network resources.
- [gt](https://github.com/ao-space/gt)：provides network support services that penetrate NAT access AO.space through relay forwarding.

## Build and deploy

To deploy and run the project from a release version, or to build and run it from the source code, please refer to [build-and-deploy](./docs/en/build-and-deploy.md).

## Documentation

- [Developer Documentation](https://ao.space/en/docs)
- [User Manual](https://ao.space/en/support/help)
- [Blog](https://ao.space/en/blog)
- [API References](https://ao.space/docs/api/)

## Contribution Guidelines

Contributions to this project are very welcome. Here are some guidelines and suggestions to help you get involved in the project.

[Contribution Guidelines](./docs/en/contribution-guidelines.md)

## Contact us

- Email: <developer@ao.space>
- Website：[https://ao.space](https://ao.space)
- Discussion group：[https://slack.ao.space](https://slack.ao.space)

## License

AO.space is open-sourced under Apache License 2.0, see [LICENSE](./LICENSE). The following sub-projects use other open-source licenses：

- [space-media-vod](https://github.com/ao-space/space-media-vod) -  AGPL-3.0 license

## Acknowledgments

AO.space heavily relies on the open-source achievements of other projects. We would like to express our special thanks to them(in alphabetical order):
[AFNetworking](https://github.com/AFNetworking/AFNetworking), [Android-Office](https://github.com/zjtone/Android-Office), [AndroidPdfViewer](https://github.com/barteksc/AndroidPdfViewer), [BouncyCastle](https://github.com/bcgit/bc-java), [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack), [commons-codec](https://commons.apache.org/proper/commons-codec/), [eventbus](https://github.com/greenrobot/EventBus), [ExoPlayer](https://github.com/google/ExoPlayer), [fastjson](https://github.com/alibaba/fastjson), [FileMD5Hash](https://github.com/JoeKun/FileMD5Hash), [findbugs](https://findbugs.sourceforge.net/), [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage), [GCDWebServer](https://github.com/swisspol/GCDWebServer), [Gin](https://github.com/gin-gonic/gin), [Gitlab](https://about.gitlab.com/), [GKPhotoBrowser](https://github.com/QuintGao/GKPhotoBrowser), [glide](https://github.com/bumptech/glide), [Go](https://github.com/golang/go), [graalvm](https://github.com/graalvm), [gson](https://github.com/google/gson), [guava](https://github.com/google/guava), [ip2region](https://github.com/lionsoul2014/ip2region), [IQKeyboardManager](https://github.com/hackiftekhar/IQKeyboardManager), [ISO8601](https://github.com/erlsci/iso8601), [jakarta.mail](https://github.com/jakartaee/mail-api), [java-totp](https://github.com/samdjstevens/java-totp), [JSONModel](https://github.com/jsonmodel/jsonmodel), [kaltura/nginx-vod-module](https://github.com/kaltura/nginx-vod-module), [lombok](https://github.com/projectlombok/lombok), [LookinServer](https://github.com/QMUI/LookinServer), [lottie-ios](https://github.com/airbnb/lottie-ios), [lottie](https://github.com/airbnb/lottie-android), [Masonry](https://github.com/SnapKit/Masonry), [MJExtension](https://github.com/CoderMJLee/MJExtension), [nginx](http://nginx.org), [okhttp](https://github.com/square/okhttp), [OpenResty](https://github.com/openresty/), [OpenSSL-Universal](https://github.com/cute/OpenSSL-Universal), [pinyin4j](https://github.com/belerweb/pinyin4j), [postgres](https://github.com/postgres/postgres), [preview-generator](https://github.com/algoo/preview-generator), [quarkus](https://github.com/quarkusio/quarkus), [Reachability](https://github.com/tonymillion/Reachability), [Redis](https://redis.io/), [rest-assured](https://github.com/rest-assured/rest-assured), [Retrofit](https://github.com/square/retrofit), [RxAndroid](https://github.com/ReactiveX/RxAndroid), [Rxjava](https://github.com/ReactiveX/RxJava), [SAMKeychain](https://github.com/soffes/SAMKeychain), [SDCycleScrollView](https://github.com/gsdios/SDCycleScrollView), [SDWebImage](https://github.com/SDWebImage/SDWebImage), [SmartRefreshLayout](https://github.com/scwang90/SmartRefreshLayout), [SocketRocket](https://github.com/facebookincubator/SocketRocket), [SSZipArchive](https://github.com/wuhaiwei/SSZipArchive), [SVProgressHUD](https://github.com/SVProgressHUD/SVProgressHUD), [WCDB](https://github.com/Tencent/wcdb), [WebSocket](https://github.com/TooTallNate/Java-WebSocket), [YCBase](https://github.com/ungacy/YCBase), [YCEasyTool](https://github.com/ungacy/YCEasyTool), [YYCache](https://github.com/ibireme/YYCache), [YYModel](https://github.com/ibireme/YYModel), [ZXing](https://github.com/zxing/zxing) and so on。

Finally, thank you for your contribution to this project. We welcome contributions in all forms, including but not limited to code contributions, issue reports, feature requests, documentation writing, etc. We believe that with your help, this project will become more perfect and stronger.
