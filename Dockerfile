# Ver: 1.8 by Endial Fang (endial@126.com)
#

# 可变参数 ========================================================================

# 设置当前应用名称及版本
ARG app_name=grafana
ARG app_version=7.1.0

# 设置默认仓库地址，默认为 阿里云 仓库
ARG registry_url="registry.cn-shenzhen.aliyuncs.com"

# 设置 apt-get 源：default / tencent / ustc / aliyun / huawei
ARG apt_source=aliyun

# 编译镜像时指定用于加速的本地服务器地址
ARG local_url=""


# 0. 预处理 ======================================================================
FROM ${registry_url}/colovu/dbuilder as builder

# 声明需要使用的全局可变参数
ARG app_name
ARG app_version
ARG registry_url
ARG apt_source
ARG local_url


ENV APP_NAME=${app_name} \
	APP_VERSION=${app_version}

# 选择软件包源(Optional)，以加速后续软件包安装
RUN select_source ${apt_source};

# 安装依赖的软件包及库(Optional)
#RUN install_pkg xz-utils

# 下载并解压软件包
RUN set -eux; \
	dpkgOsArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	dpkgOsName="$(uname | tr [:'upper':] [:'lower':])"; \
	appName="${APP_NAME}-${APP_VERSION}.${dpkgOsName}-${dpkgOsArch}.tar.gz"; \
	sha256="4b6d6ce3670b281919dac8da4bf6d644bc8403ceae215e4fd10db0f2d1e5718e"; \
	[ ! -z ${local_url} ] && localURL=${local_url}/grafana; \
	appUrls="${localURL:-} \
		https://dl.grafana.com/oss/release \
		"; \
	download_pkg unpack ${appName} "${appUrls}" -s "${sha256}"; \
	cd /tmp/${APP_NAME}-${APP_VERSION}/conf; \
	mv sample.ini grafana.ini; 



# 1. 生成镜像 =====================================================================
FROM ${registry_url}/colovu/debian:buster

# 声明需要使用的全局可变参数
ARG app_name
ARG app_version
ARG registry_url
ARG apt_source
ARG local_url

# 镜像所包含应用的基础信息，定义环境变量，供后续脚本使用
ENV APP_NAME=${app_name} \
	APP_USER=${app_name} \
	APP_EXEC=grafana-server \
	APP_VERSION=${app_version}

ENV	APP_HOME_DIR=/usr/local/${APP_NAME} \
	APP_DEF_DIR=/etc/${APP_NAME}

ENV PATH="${APP_HOME_DIR}/sbin:${APP_HOME_DIR}/bin:${PATH}" \
	LD_LIBRARY_PATH="${APP_HOME_DIR}/lib"

LABEL \
	"Version"="v${APP_VERSION}" \
	"Description"="Docker image for ${APP_NAME}(v${APP_VERSION})." \
	"Dockerfile"="https://github.com/colovu/docker-${APP_NAME}" \
	"Vendor"="Endial Fang (endial@126.com)"

# 从预处理过程中拷贝软件包(Optional)，可以使用阶段编号或阶段命名定义来源
COPY --from=builder /tmp/grafana-7.1.0/ /usr/local/grafana

# 拷贝应用使用的客制化脚本，并创建对应的用户及数据存储目录
COPY customer /
RUN set -eux; \
#	create_user; \
	prepare_env; \
	/bin/bash -c "ln -sf /usr/local/${APP_NAME}/conf /etc/${APP_NAME}";

# 选择软件包源(Optional)，以加速后续软件包安装
RUN select_source ${apt_source}

# 安装依赖的软件包及库(Optional)
RUN install_pkg libfontconfig ca-certificates apt-transport-https

# 执行预处理脚本，并验证安装的软件包
RUN set -eux; \
	override_file="/usr/local/overrides/overrides-${APP_VERSION}.sh"; \
	[ -e "${override_file}" ] && /bin/bash "${override_file}"; \
	${APP_EXEC} -v ;

# 默认提供的数据卷
VOLUME ["/srv/conf", "/srv/data", "/var/log"]

# 默认non-root用户启动，必须保证端口在1024之上
EXPOSE 3000

# 关闭基础镜像的健康检查
#HEALTHCHECK NONE

# 应用健康状态检查
#HEALTHCHECK --interval=30s --timeout=30s --retries=3 \
#	CMD curl -fs http://localhost:8080/ || exit 1
HEALTHCHECK --interval=10s --timeout=10s --retries=3 \
	CMD netstat -ltun | grep 3000

# 使用 non-root 用户运行后续的命令
USER 1001

# 设置工作目录
WORKDIR /srv/data/${APP_NAME}

# 容器初始化命令
ENTRYPOINT ["/usr/local/bin/entry.sh"]

# 应用程序的启动命令，必须使用非守护进程方式运行
CMD ["/usr/local/bin/run.sh"]

