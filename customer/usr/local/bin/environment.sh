#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
# 
# 应用环境变量定义及初始化

# 通用设置
export ENV_DEBUG=${ENV_DEBUG:-false}
export ALLOW_ANONYMOUS_LOGIN="${ALLOW_ANONYMOUS_LOGIN:-no}"

# 通过读取变量名对应的 *_FILE 文件，获取变量值；如果对应文件存在，则通过传入参数设置的变量值会被文件中对应的值覆盖
# 变量优先级： *_FILE > 传入变量 > 默认值
app_env_file_lists=(
	APP_PASSWORD
)
for env_var in "${app_env_file_lists[@]}"; do
    file_env_var="${env_var}_FILE"
    if [[ -n "${!file_env_var:-}" ]]; then
        export "${env_var}=$(< "${!file_env_var}")"
        unset "${file_env_var}"
    fi
done
unset app_env_file_lists

# 应用路径参数
export APP_HOME_DIR="/usr/local/${APP_NAME}"
export APP_DEF_DIR="/etc/${APP_NAME}"
export APP_CONF_DIR="/srv/conf/${APP_NAME}"
export APP_DATA_DIR="/srv/data/${APP_NAME}"
export APP_DATA_LOG_DIR="/srv/datalog/${APP_NAME}"
export APP_CACHE_DIR="/var/cache/${APP_NAME}"
export APP_RUN_DIR="/var/run/${APP_NAME}"
export APP_LOG_DIR="/var/log/${APP_NAME}"
export APP_CERT_DIR="/srv/cert/${APP_NAME}"


# 应用配置参数
export GF_PATHS_DATA="${GF_PATHS_DATA:-${APP_DATA_DIR}}"
export GF_PATHS_LOGS="${GF_PATHS_LOGS:-${APP_LOG_DIR}}"
export GF_PATHS_PLUGINS="${GF_PATHS_PLUGINS:-${APP_DATA_DIR}/plugins}"
export GF_PATHS_PROVISIONING="${GF_PATHS_PROVISIONING:-${APP_CONF_DIR}/provisioning}"

export GF_LOG_MODE="console file"

# 内部变量
export APP_PID_FILE="${APP_PID_FILE:-${APP_RUN_DIR}/${APP_NAME}.pid}"
export APP_CONF_FILE="${APP_CONF_DIR}/grafana.ini"

export APP_DAEMON_USER="${APP_NAME}"
export APP_DAEMON_GROUP="${APP_NAME}"

# 个性化变量        
