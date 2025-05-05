#!/bin/bash 

# ========= 环境变量检查 =========
# 检查是否设置了 ACR 用户名
: "${ACR_USERNAME:?❌ 你必须设置环境变量 ACR_USERNAME}"
# 检查是否设置了 ACR 密码
: "${ACR_PASSWORD:?❌ 你必须设置环境变量 ACR_PASSWORD}"


export CONTAINER_USERNAME=${ACR_USERNAME}
export CONTAINER_PASSWORD=${ACR_PASSWORD}
export CONTAINER_REGISTRY=registry.cn-hangzhou.aliyuncs.com
export CONTAINER_NAME=buildx/hub
export IMAGE_LIST_FILE=acr.hub.list
# =================================

source ./sync-images.sh