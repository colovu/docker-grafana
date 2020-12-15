# Ver: 1.4 by Endial Fang (endial@126.com)
#

# 预处理 =========================================================================
ARG registry_url="registry.cn-shenzhen.aliyuncs.com"
FROM ${registry_url}/colovu/dbuilder as builder

# sources.list 可使用版本：default / tencent / ustc / aliyun / huawei
ARG apt_source=aliyun

# 编译镜像时指定用于加速的本地服务器地址
ARG local_url=""

ENV APP_NAME=grafana \
	APP_VERSION=7.1.0

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
	cd /usr/local/${APP_NAME}-${APP_VERSION}/conf; \
	mv sample.ini grafana.ini; 

# Alpine: scanelf --needed --nobanner --format '%n#p' --recursive /usr/local | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }'
# Debian: find /usr/local/redis/bin -type f -executable -exec ldd '{}' ';' | awk '/=>/ { print $(NF-1) }' | sort -u | xargs -r dpkg-query --search | cut -d: -f1 | sort -u


# 镜像生成 ========================================================================
FROM ${registry_url}/colovu/debian:10

# sources.list 可使用版本：default / tencent / ustc / aliyun / huawei
ARG apt_source=aliyun

# 编译镜像时指定用于加速的本地服务器地址
ARG local_url=""

ENV APP_NAME=grafana \
	APP_USER=grafana \
	APP_EXEC=grafana-server \
	APP_VERSION=7.1.0

ENV	APP_HOME_DIR=/usr/local/${APP_NAME} \
	APP_DEF_DIR=/etc/${APP_NAME} \
	APP_CONF_DIR=/srv/conf/${APP_NAME} \
	APP_DATA_DIR=/srv/data/${APP_NAME} \
	APP_DATA_LOG_DIR=/srv/datalog/${APP_NAME} \
	APP_CACHE_DIR=/var/cache/${APP_NAME} \
	APP_RUN_DIR=/var/run/${APP_NAME} \
	APP_LOG_DIR=/var/log/${APP_NAME} \
	APP_CERT_DIR=/srv/cert/${APP_NAME}

ENV PATH="${APP_HOME_DIR}/bin:${PATH}"

LABEL \
	"Version"="v${APP_VERSION}" \
	"Description"="Docker image for ${APP_NAME}(v${APP_VERSION})." \
	"Dockerfile"="https://github.com/colovu/docker-${APP_NAME}" \
	"Vendor"="Endial Fang (endial@126.com)"

COPY customer /

# 以包管理方式安装软件包(Optional)
RUN select_source ${apt_source}
RUN install_pkg libfontconfig ca-certificates apt-transport-https

RUN create_user && prepare_env

# 从预处理过程中拷贝软件包(Optional)
#COPY --from=0 /usr/local/bin/ /usr/local/bin
COPY --from=builder /usr/local/grafana-7.1.0/ /usr/local/grafana
COPY --from=builder /usr/local/grafana-7.1.0/conf/ /etc/grafana

# 执行预处理脚本，并验证安装的软件包
RUN set -eux; \
	override_file="/usr/local/overrides/overrides-${APP_VERSION}.sh"; \
	[ -e "${override_file}" ] && /bin/bash "${override_file}"; \
	gosu ${APP_USER} ${APP_EXEC} -v ; \
	:;

# 默认提供的数据卷
VOLUME ["/srv/conf", "/srv/data", "/var/log"]

# 默认使用gosu切换为新建用户启动，必须保证端口在1024之上
EXPOSE 3000

# 容器初始化命令，默认存放在：/usr/local/bin/entry.sh
ENTRYPOINT ["entry.sh"]

WORKDIR /srv/data/grafana

# 应用程序的服务命令，必须使用非守护进程方式运行。如果使用变量，则该变量必须在运行环境中存在（ENV可以获取）
CMD ["${APP_EXEC}", "--homepath=${APP_HOME_DIR} --config=${APP_CONF_FILE}"]

