#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
# 
# 应用通用业务处理函数

# 加载依赖脚本
. /usr/local/scripts/libcommon.sh       # 通用函数库
. /usr/local/scripts/libfile.sh
. /usr/local/scripts/libfs.sh
. /usr/local/scripts/libos.sh
. /usr/local/scripts/libservice.sh
. /usr/local/scripts/libvalidations.sh
. /usr/local/scripts/libnet.sh

# 函数列表

# 加载应用使用的环境变量初始值，该函数在相关脚本中以 eval 方式调用
# 全局变量:
#   ENV_*   : 容器使用的全局变量
#   APP_*   : 在镜像创建时定义的全局变量
#   *_*     : 应用配置文件使用的全局变量，变量名根据配置项定义
#   GF_*    : 对应的变量为配置文件中配置项转后后的名称，具体参见项目 README 文件说明
# 返回值:
#   可以被 'eval' 使用的序列化输出
docker_app_env() {
    cat <<"EOF"
# Common Settings
export ENV_DEBUG=${ENV_DEBUG:-false}
export ALLOW_EMPTY_PASSWORD="${ALLOW_EMPTY_PASSWORD:-no}"

# Paths
export GF_PATHS_DATA="${GF_PATHS_DATA:-${APP_DATA_DIR}}"
export GF_PATHS_LOGS="${GF_PATHS_LOGS:-${APP_LOG_DIR}}"
export GF_PATHS_PLUGINS="${GF_PATHS_PLUGINS:-${APP_DATA_DIR}/plugins}"
export GF_PATHS_PROVISIONING="${GF_PATHS_PROVISIONING:-${APP_CONF_DIR}/provisioning}"

export APP_CONF_FILE="${APP_CONF_DIR}/grafana.ini"

# Users

# Application settings
export GF_LOG_MODE="console file"

# Application Cluster configuration

# Application TLS Settings

# Application Authentication

EOF

    # 利用 *_FILE 设置密码，不在配置命令中设置密码，增强安全性
#    if [[ -f "${ZOO_CLIENT_PASSWORD_FILE:-}" ]]; then
#        cat <<"EOF"
#export ZOO_CLIENT_PASSWORD="$(< "${ZOO_CLIENT_PASSWORD_FILE}")"
#EOF
#    fi
}

# 根据用户设置，安装相应的插件
# 全局变量：
#   - GF_ENV_INSTALL_PLUGINS: 以 ","/";"/" " 分隔的插件 id 列表，如果为第三方地址，形式类似"id=url"
grafana_install_plugins(){
    if [[ -n "${GF_ENV_INSTALL_PLUGINS:-}" ]]; then
    splitted_plugin_list=$(tr ',;' ' ' <<< "${GF_ENV_INSTALL_PLUGINS}")
    read -r -a gf_plugins_list <<< "${splitted_plugin_list}"
    for plugin in "${gf_plugins_list[@]}"; do
        grafana_install_plugin_args=("--pluginsDir" "${GF_PATHS_PLUGINS}")
        plugin_id="${plugin}"
        if echo "${plugin}" | grep "=" > /dev/null 2>&1; then
            splitted_plugin_entry=$(tr '=' ' ' <<< "${plugin}")
            read -r -a plugin_url_array <<< "$splitted_plugin_entry"
            LOG_I "Installing plugin with id ${plugin_url_array[0]} and url ${plugin_url_array[1]}"
            plugin_id="${plugin_url_array[0]}"
            grafana_install_plugin_args+=("--pluginUrl" "${plugin_url_array[1]}")
        else
            LOG_I "Installing plugin with id ${plugin_id}"
        fi
        if [[ "${GF_ENV_INSTALL_PLUGINS_SKIP_TLS:-}" = "yes" ]]; then
            grafana_install_plugin_args+=("--insecure")
        fi
        grafana_install_plugin_args+=("plugins" "install" "${plugin_id}")
        grafana-cli "${grafana_install_plugin_args[@]}"
    done
fi
}

# 应用默认初始化操作
# 执行完毕后，生成文件 ${APP_CONF_DIR}/.app_init_flag 及 ${APP_DATA_DIR}/.data_init_flag 文件
docker_app_init() {
    LOG_D "Check init status of ${APP_NAME}..."

    # 检测配置文件是否存在
    if [[ ! -f "${APP_CONF_DIR}/.app_init_flag" ]]; then
        LOG_I "No injected configuration file found, creating default config files..."
        
        # TODO: 生成配置文件，并按照容器运行参数进行相应修改

        touch ${APP_CONF_DIR}/.app_init_flag
        echo "$(date '+%Y-%m-%d %H:%M:%S') : Init success." >> ${APP_CONF_DIR}/.app_init_flag
    else
        LOG_I "User injected custom configuration detected!"
    fi

    if [[ ! -f "${APP_DATA_DIR}/.data_init_flag" ]]; then
        LOG_I "Deploying ${APP_NAME} from scratch..."
		
        grafana_install_plugins

        touch ${APP_DATA_DIR}/.data_init_flag
        echo "$(date '+%Y-%m-%d %H:%M:%S') : Init success." >> ${APP_DATA_DIR}/.data_init_flag
    else
        LOG_I "Deploying ${APP_NAME} with persisted data..."
    fi
}

# 用户自定义的应用初始化操作，依次执行目录initdb.d中的初始化脚本
# 执行完毕后，生成文件 ${APP_DATA_DIR}/.custom_init_flag
docker_custom_init() {
    LOG_D "Check custom init status of ${APP_NAME}..."

    # 检测用户配置文件目录是否存在 initdb.d 文件夹，如果存在，尝试执行目录中的初始化脚本
    if [ -d "/srv/conf/${APP_NAME}/initdb.d" ]; then
    	# 检测数据存储目录是否存在已初始化标志文件；如果不存在，检索可执行脚本文件并进行初始化操作
    	if [[ -n $(find "/srv/conf/${APP_NAME}/initdb.d/" -type f -regex ".*\.\(sh\)") ]] && \
            [[ ! -f "${APP_DATA_DIR}/.custom_init_flag" ]]; then
            LOG_I "Process custom init scripts from /srv/conf/${APP_NAME}/initdb.d..."

            # 检索所有可执行脚本，排序后执行
    		find "/srv/conf/${APP_NAME}/initdb.d/" -type f -regex ".*\.\(sh\)" | sort | while read -r f; do
                case "$f" in
                    *.sh)
                        if [[ -x "$f" ]]; then
                            LOG_D "Executing $f"; "$f"
                        else
                            LOG_D "Sourcing $f"; . "$f"
                        fi
                        ;;
                    *)        LOG_D "Ignoring $f" ;;
                esac
            done

            touch ${APP_DATA_DIR}/.custom_init_flag
    		echo "$(date '+%Y-%m-%d %H:%M:%S') : Init success." >> ${APP_DATA_DIR}/.custom_init_flag
    		LOG_I "Custom init for ${APP_NAME} complete."
    	else
    		LOG_I "Custom init for ${APP_NAME} already done before, skipping initialization."
    	fi
    fi
}
