# Grafana

针对 [Grafana]() 应用的 Docker 镜像，用于提供 Grafana 服务。

使用说明可参照：[官方说明](https://grafana.com/docs/grafana/latest/getting-started/)

![grafana_logo-web](img/grafana_logo-web.svg)



**版本信息：**

- 7、7.1、latest

**镜像信息：**

* 镜像地址：registry.cn-shenzhen.aliyuncs.com/colovu/grafana:7



## TL;DR

Docker 快速启动命令：

```shell
$ docker run -d registry.cn-shenzhen.aliyuncs.com/colovu/grafana:7
```

Docker-Compose 快速启动命令：

```shell
$ curl -sSL https://raw.githubusercontent.com/colovu/docker-imgname/master/docker-compose.yml > docker-compose.yml

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

举例：

- 使用宿主机`/host/dir/to/conf`存储配置文件
- 使用宿主机`/host/dir/to/data`存储数据文件
- 使用宿主机`/host/dir/to/log`存储日志文件

创建以上相应的宿主机目录后，容器启动命令中对应的数据卷映射参数类似如下：

```shell
-v /host/dir/to/conf:/srv/conf -v /host/dir/to/data:/srv/data -v /host/dir/to/log:/var/log
```

使用 Docker Compose 时，配置文件类似如下：

```yaml
services:
  AppName:
  ...
    volumes:
      - /host/dir/to/conf:/srv/conf
      - /host/dir/to/data:/srv/data
      - /host/dir/to/log:/var/log
  ...
```

> 注意：如果应用使用的子目录不存在，会在容器初始化时自动创建相应目录，并生成相关配置文件及数据文件。



## 基本使用

- 在后续介绍中，启动的容器**默认命名为`AppName`**，需要根据实际情况修改
- 在后续介绍中，容器默认使用的网络命名为`app-tier`，需要根据实际情况修改



### 容器网络

在工作在同一个网络组中时，如果容器需要互相访问，相关联的容器可以使用容器初始化时定义的名称作为主机名进行互相访问。

创建网络：

```shell
$ docker network create app-tier --driver bridge
```

- 使用桥接方式，创建一个命名为`app-tier`的网络



如果使用已创建的网络连接不同容器，需要在启动命令中增加类似`--network app-tier`的参数。使用 Docker Compose时，在docker-compose的配置文件中增加：

```yaml
services:
  AppName:
    ...
    networks:
      - app-tier

networks:
  app-tier:
    driver: bridge
```



### 下载镜像

可以不单独下载镜像，如果镜像不存在，会在初始化容器时自动下载。

```shell
# 下载指定Tag的镜像
$ docker pull colovu/AppName:TAG

# 下载最新镜像
$ docker pull colovu/AppName:latest
```

> TAG：替换为指定的标签名



### 持久化数据存储

如果需要将容器数据持久化存储至宿主机或数据存储中，需要确保宿主机对应的路径存在，并在启动时，映射为对应的数据卷。

AppName 镜像默认配置了用于存储数据的数据卷 `/srv/data`。可以使用宿主机目录映射相应的数据卷，将数据持久化存储在宿主机中。路径中，应用对应的子目录如果不存在，容器会在初始化时创建，并生成相应的默认文件。

> 注意：将数据持久化存储至宿主机，可避免容器销毁导致的数据丢失。同时，将数据存储及数据日志分别映射为不同的本地设备（如不同的共享数据存储）可提供较好的性能保证。



### 实例化服务容器

生成并运行一个新的容器：

```shell
$ docker run -d --restart always --name AppName colovu/AppName:latest
```

- `-d`: 使用服务方式启动容器
- `--restart always`: 在容器失败或系统重启后，自动重启容器
- `--name AppName`: 为当前容器命名



使用数据卷映射生成并运行一个容器：

```shell
 $ docker run -d --restart always \
  --name AppName \
  -v /host/dir/to/data:/srv/data \
  -v /host/dir/to/conf:/srv/conf \
  colovu/AppName:latest
```

- `-v /host/dir/to/data:/srv/data`: 为容器数据存储映射宿主机目录
- `-v /host/dir/to/conf:/srv/conf`: 为容器配置文件映射宿主机目录



### 连接容器

启用 [Docker container networking](https://docs.docker.com/engine/userguide/networking/)后，工作在容器中的 ZooKeeper 服务可以被其他应用容器访问和使用。

#### 命令行方式

定义网络，并启动 AppName 容器：

```shell
$ docker network create app-tier --driver bridge

$ docker run -d --restart always --name AppName -e ZOO_ALLOW_ANONYMOUS_LOGIN=yes \
	--network app-tier \
	colovu/AppName:latest
```

- `--network app-tier`: 容器使用的网络



其他业务容器连接至 AppName 容器：

```shell
$ docker run --network app-tier --name other-app --link AppName:name-in-container -d other-app-image:tag
```

- `--link AppName:name-in-container`: 链接 AppName 容器，并命名为`name-in-container`进行使用（如果其他容器中使用了该名称进行访问）



#### Docker Compose 方式

如使用配置文件`docker-compose-test.yml`:

```yaml
version: '3.6'

services:
  AppName:
    image: 'colovu/AppName:latest'
    networks:
      - app-tier
  myapp:
    image: 'other-app-img:tag'
    links:
    	- AppName:name-in-container
    networks:
      - app-tier
      
networks:
  app-tier:
    driver: bridge
```

> 注意：
>
> - 需要修改 `other-app-img:tag`为相应业务镜像的名字
> - 在其他的应用中，使用`AppName`连接 AppName 容器，如果应用不是使用的该名字，可以重定义启动时的命名，或使用`links: AppName:name-in-container`进行名称映射

启动方式：

```shell
$ docker-compose up -d -f docker-compose-test.yml
```

- 如果配置文件命名为`docker-compose.yml`，可以省略`-f docker-compose-test.yml`参数



#### 其他连接操作

使用 exec 命令访问容器ID或启动时的命名，进入容器并执行命令：

```shell
$ docker exec -it AppName /bin/bash
```

- `/bin/bash`: 在进入容器后，运行的命令



使用 attach 命令进入已运行的容器：

```shell
$ docker attach  --sig-proxy=false AppName
```

- 该方式无法执行命令
- 如果不使用` --sig-proxy=false`，关闭终端或`Ctrl + C`时，会导致容器停止



### 停止容器

使用 stop 命令以容器ID或启动时的命名方式停止容器：

```shell
$ docker stop AppName
```

如果应用支持自定义脚本停止命令，可以使用以下类似方式停止容器：

```shell
$ docker exec -it AppName shell-name.sh stop
```

- `shell-name.sh`: 可执行脚本，用于服务操作



### 查看日志

默认方式启动容器时，容器的运行日志输出至终端，可使用如下方式进行查看：

```shell
$ docker logs AppName
```

在使用 Docker Compose 管理容器时，使用以下命令查看：

```shell
$ docker-compose logs AppName
```



## docker-compose部署

### 单机部署

根据需要，修改 Docker Compose 配置文件，如`docker-compose.yml`，并启动:

```bash
$ docker-compose up -d
```

- 在不定义配置文件的情况下，默认使用当前目录的`docker-compose.yml`文件
- 如果配置文件为其他名称，可以使用`-f 文件名`方式指定



`docker-compose.yml`文件参考如下：

```yaml
version: '3.6'

services:
  AppName:
    image: colovu/AppName:latest
    ports:
      - '80:8080'
```



#### 环境验证





### 集群部署

根据需要，修改 Docker Compose 配置文件，如`docker-compose-cluster.yml`，并启动:

```bash
$ docker-compose -f docker-compose-cluster.yml up -d
```

- 在不定义配置文件的情况下，默认使用当前目录的`docker-compose.yml`文件



 `docker-compose-cluster.yml` 配置文件参考如下：

```yaml
version: '3.6'

services:
  AppName1:
    image: colovu/AppName:latest
    restart: always
    hostname: AppName1

  AppName2:
    image: colovu/AppName:latest
    restart: always
    hostname: AppName2

  AppName3:
    image: colovu/AppName:latest
    restart: always
    hostname: AppName3
```



#### 环境验证



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



### 应用配置文件

#### 使用已有配置文件

`AppName` 容器的配置文件默认存储在数据卷`/srv/conf`中，文件名及子路径为`grafana/grafana.ini`。有以下两种方式可以使用自定义的配置文件：

- 直接映射配置文件

```shell
$ docker run -d --restart always --name grafana -v $(pwd)/grafana.ini:/srv/conf/grafana/grafana.ini colovu/grafana:latest
```

- 映射配置文件数据卷

```shell
$ docker run -d --restart always --name grafana -v $(pwd):/srv/conf colovu/grafana:latest
```

> 宿主机路径 $(pwd) 中需要包含 grafana 子目录，且相应配置文件存放在该子目录中



#### 生成配置文件并修改

可以使用配置文件的方式，直接定义容器中应用启动时使用的各项参数。配置文件一般存储在数据卷`/srv/conf`对应的`AppName`目录中。

如果没有配置文件模板，可以在容器自动创建后，修改相应的配置文件（例如宿主机使用`/path/to/conf`存储容器配置文件）：

##### 使用镜像初始化启动容器

使用宿主机配置文件存储目录`/path/to/conf`映射为容器`/srv/conf`数据卷，并启动容器：

```bash
$ docker run -d --name AppName -v /path/to/conf:/srv/conf colovu/AppName:TAG 
```

使用 Docker Compose 管理时，修改配置文件`docker-compose.yml`确保如下类似内容存在：

```yaml
...
services:
	AppName:
		...
		volumes:
			- /path/to/conf:/srv/conf
```

并使用命令`docker-compose up -d`启动容器。

##### 修改配置文件

容器会自动在宿主机目录中生成子目录及相关默认配置文件，可以在宿主机环境使用工具修改该配置文件。

##### 重新启动容器

修改完成后，重新启动容器，则新的配置自动生效：

```bash
$ docker restart AppName
```

使用 Docker Compose 管理时，使用如下命令：

```bash
$ docker-compose restart AppName
```



## 安全

### 用户及密码



### 证书加密





## 日志

默认情况下，Docker镜像配置为将容器日志直接输出至`stdout`，可以使用以下方式查看：

```bash
$ docker logs AppName
```

使用 Docker Compose 管理时，使用以下命令：

```bash
$ docker-compose logs AppName
```

实际使用时，可以使用`--log-driver`配置容器的 [logging driver](https://docs.docker.com/engine/admin/logging/overview/) 。默认情况下，使用`json-file`驱动。



## 容器维护

### 容器数据备份

默认情况下，镜像都会提供`/srv/data`数据卷持久化保存数据。如果在容器创建时，未映射宿主机目录至容器，需要在删除容器前对数据进行备份，否则，容器数据会在容器删除后丢失。

如果需要备份数据，可以使用按照以下步骤进行：

#### 停止当前运行的容器

如果使用命令行创建的容器，可以使用以下命令停止：

```bash
$ docker stop AppName
```

如果使用 Docker Compose 创建的，可以使用以下命令停止：

```bash
$ docker-compose stop AppName
```

#### 执行备份命令

在宿主机创建用于备份数据的目录`/path/to/back-up`，并执行以下命令：

```bash
$ docker run --rm -v /path/to/back-up:/backups --volumes-from AppName busybox \
  cp -a /srv/data/AppName /backups/
```

如果容器使用 Docker Compose 创建，执行以下命令：

```bash
$ docker run --rm -v /path/to/back-up:/backups --volumes-from `docker-compose ps -q AppName` busybox \
  cp -a /srv/data/AppName /backups/
```



### 容器数据恢复

在容器创建时，如果未映射宿主机目录至容器数据卷，则容器会创建私有数据卷。如果是启动新的容器，可直接使用备份的数据进行数据卷映射，命令类似如下：

```bash
$ docker run -v /path/to/back-up:/srv/data colovu/AppName:latest
```

使用 Docker Compose 管理时，可直接在`docker-compose.yml`文件中指定：

```yaml
AppName:
	volumes:
		- /path/to/back-up:/srv/data
```



### 镜像更新

针对当前镜像，会根据需要不断的提供更新版本。针对更新版本（大版本相同的情况下，如果大版本不同，需要参考指定说明处理），可使用以下步骤使用新的镜像创建容器：

#### 获取新版本的镜像

```bash
$ docker pull colovu/AppName:TAG
```

这里`TAG`为指定版本的标签名，如果使用最新的版本，则标签为`latest`。

#### 停止容器并备份数据

如果容器未使用宿主机目录映射为容器数据卷的方式创建，参照`容器数据备份`中方式，备份容器数据。

如果容器使用宿主机目录映射为容器数据卷的方式创建，不需要备份数据。

#### 删除当前使用的容器

```bash
$ docker rm -v AppName
```

使用 Docker Compose 管理时，使用以下命令：

```bash
$ docker-compose rm -v AppName
```

#### 使用新的镜像启动容器

将宿主机备份目录映射为容器数据卷，并创建容器：

```bash
$ docker run --name AppName -v /path/to/back-up:/srv/data colovu/AppName:TAG
```

使用 Docker Compose 管理时，确保`docker-compose.yml`文件中包含数据卷映射指令，使用以下命令启动：

```bash
$ docker-compose up AppName
```



## 注意事项

- 容器中启动参数不能配置为后台运行，如果应用使用后台方式运行，则容器的启动命令会在运行后自动退出，从而导致容器退出；只能使用前台运行方式，即：`daemonize no`



## 更新记录

- 7、7.1、latest



----

本文原始来源 [Endial Fang](https://github.com/colovu) @ [Github.com](https://github.com)
