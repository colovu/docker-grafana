# Grafana

针对 [Grafana]() 应用的 Docker 镜像，用于提供 Grafana 服务。

使用说明可参照：[官方说明](https://grafana.com/docs/grafana/latest/getting-started/)

<img src="img/grafana_logo-web.svg" alt="grafana-logo" style="zoom: 33%;" />

**版本信息：**

- 7.1、latest

**镜像信息：**

* 镜像地址：
  - 阿里云: registry.cn-shenzhen.aliyuncs.com/colovu/grafana:7.1
  - DockerHub：colovu/grafana:7.1
  * 依赖镜像：debian:buster

> 后续相关命令行默认使用`[Docker Hub](https://hub.docker.com)`镜像服务器做说明



## TL;DR

Docker 快速启动命令：

```shell
# 从 Docker Hub 服务器下载镜像并启动
$ docker run -d --name grafana colovu/grafana:7.1

# 从 Aliyun 服务器下载镜像并启动
$ docker run -d --name grafana registry.cn-shenzhen.aliyuncs.com/colovu/grafana:7.1
```

- `colovu/imgname:<TAG>`：镜像名称及版本标签；标签不指定时默认使用`latest`




Docker-Compose 快速启动命令：

```shell
# 从 Gitee 下载 Compose 文件
$ curl -sSL -o https://gitee.com/colovu/docker-grafana/raw/7/docker-compose.yml

# 从 Github 下载 Compose 文件
$ curl -sSL -o https://raw.githubusercontent.com/colovu/docker-grafana/7/docker-compose.yml

# 创建并启动容器
$ docker-compose up -d
```



---



## 默认对外声明

### 端口

- 3000：Web访问端口

### 数据卷

镜像默认提供以下数据卷定义，默认数据分别存储在自动生成的应用名对应`AppName`子目录中：

```shell
/var/log			# 日志输出
/srv/conf			# 配置文件
/srv/data			# 数据存储
```

如果需要持久化存储相应数据，需要**在宿主机建立本地目录**，并在使用镜像初始化容器时进行映射。宿主机相关的目录中如果不存在对应应用`AppName`的子目录或相应数据文件，则容器会在初始化时创建相应目录及文件。



## 容器配置

### 常规配置参数

自 Grafana 7.1 版本起，软件支持通过环境变量的方式配置所有[配置参数](https://grafana.com/docs/grafana/latest/administration/configuration/#configure-with-environment-variables)，使用如下的格式：

```bash
GF_<SectionName>_<KeyName>
```

- SectionName：配置文件中包含在括号（ "["  / "]"）中的部分
- KeyName：配置项名称

同时：

- 环境变量全部使用大写字母
- 小节名称及关键字名称中的所有"."和"-"，都以"_"代替。

例如配置文件中如下的配置项：

```bash
# default section
instance_name = my-instance

[security]
admin_user = admin

[auth.google]
client_secret = 0ldS3cretKey

[plugin.grafana-image-renderer]
rendering_ignore_https_errors = true
```

对应的环境变量为：

```bash
export GF_DEFAULT_INSTANCE_NAME=my-instance
export GF_SECURITY_ADMIN_USER=admin
export GF_AUTH_GOOGLE_CLIENT_SECRET=0ldS3cretKey
export GF_PLUGIN_GRAFANA_IMAGE_RENDERER_RENDERING_IGNORE_HTTPS_ERRORS=true
```

> 注意：
>
> 配置参数生效顺序：`default.ini >> grafana.ini >> 环境变量`
>
> - default.ini 为系统默认加载的配置文件
> - grafana.ini 为容器中服务启动时设置的客户化配置文件
> - 环境变量 为容器启动时设置的环境变量；配置文件 default.ini / grafana.ini 包含的配置信息，会在容器启动时，被环境变量中配置信息替代。



### 容器配置参数



### 集群配置参数

集群配置参数主要为容器在集群状态时需要使用的参数，主要包括：



### 可选配置参数

如果没有必要，可选配置参数可以不用定义，直接使用对应的默认值，主要包括：

#### `ENV_DEBUG`

默认值：**false**。设置是否输出容器调试信息。

> 可设置为：1、true、yes


### 容器安全

本容器默认使用`non-root`运行应用，以加强容器的安全性。在使用`non-root`用户运行容器时，相关的资源访问会受限；应用仅能操作镜像创建时指定的路径及数据。使用`non-root`方式的容器，更适合在生产环境中使用。

如果需要切换为`root`方式运行应用，可以在启动命令中增加`-u root`以指定运行的用户。



## 注意事项

- 容器中应用的启动参数不能配置为后台运行，如果应用使用后台方式运行，则容器的启动命令会在运行后自动退出，从而导致容器退出



## 更新记录

2021/7/22:
- 更新软件包为 7.1.5
- 初始版本7.1.0



----

本文原始来源 [Endial Fang](https://github.com/colovu) @ [Github.com](https://github.com)
