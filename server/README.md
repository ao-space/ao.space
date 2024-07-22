# 服务端构建方式：



## 构建环境：

- python3

- docker (>=18.09)

- git

  

## 构建步骤：

1、对config.yaml 文件进行配置

如果在中国大陆，需要配置proxy使用代理来获取docker镜像依赖

2、更新submodules

```bash
# 在ao.space目录中执行
git submodule init        
git submodule update --remote
```

2、使用命令开始构建：

```bash
# 在ao.space/server目录中执行
sudo make build
```

3、构建完成后运行容器：

```bash
sudo make run
```

