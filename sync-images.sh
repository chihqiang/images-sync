#!/bin/bash  # 使用 bash 解释器

# 遇到任何命令出错时立即退出脚本
set -eux

# 设置错误处理函数：脚本失败时打印最后处理的镜像名
trap 'echo "❌ 脚本执行失败，最后处理的镜像是：$FORM_IMAGE" >&2' ERR

# 检查是否设置了镜像仓库的登录用户名
: "${CONTAINER_USERNAME:?❌ 你必须设置环境变量，用于目标容器登录账号 CONTAINER_USERNAME}"

# 检查是否设置了镜像仓库的登录密码
: "${CONTAINER_PASSWORD:?❌ 你必须设置环境变量，用于目标容器登录密码 CONTAINER_PASSWORD}"

# 检查是否设置了镜像仓库命名空间（通常是组织名或用户名）
: "${CONTAINER_NAME:?❌ 你必须设置环境变量，用于目标容器地址 CONTAINER_NAME}"

# 检查是否设置了镜像列表文件路径
: "${IMAGE_LIST_FILE:?❌ 你必须设置环境变量，需要同步的镜像列表文件 IMAGE_LIST_FILE}"

# 设置默认目标镜像仓库地址为 docker.io（如果用户未指定）
: "${CONTAINER_REGISTRY:=docker.io}"

# 打印登录提示信息
echo "🔐 登录 ${CONTAINER_REGISTRY} ..."

# 登录到目标镜像仓库
docker login -u "$CONTAINER_USERNAME" -p "$CONTAINER_PASSWORD" "$CONTAINER_REGISTRY"

# 从镜像列表文件中逐行读取镜像名
while IFS= read -r IMAGE || [[ -n "$IMAGE" ]]; do

    # 如果该行是空的或以 # 开头（注释），则跳过
    [[ -z "$IMAGE" || "$IMAGE" == \#* ]] && continue

    # 打印正在处理的镜像信息
    echo "🚀 正在处理镜像：$IMAGE"

    # 提取镜像名（去除 tag 部分）
    IMAGE_NAME=$(echo "$IMAGE" | cut -d':' -f1)

    # 提取 tag，如果没有写 tag，就为空
    IMAGE_TAG=$(echo "$IMAGE" | cut -s -d':' -f2)

    # 如果 tag 为空，则使用 latest
    [[ -z "$IMAGE_TAG" ]] && IMAGE_TAG="latest"

    # 构建完整的源镜像名称（包含 tag）
    FORM_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

    # 构建目标镜像名称：latest 的镜像不加 tag 后缀，其它的加 -tag 后缀
    if [[ "$IMAGE_TAG" == "latest" ]]; then
        # 镜像名只保留最后一段（去掉路径），用作 tag
        TO_IMAGE="${CONTAINER_REGISTRY}/${CONTAINER_NAME}:${IMAGE_NAME##*/}"
    else
        # 镜像名加上 -tag 后缀，例如 nginx:1.25 → nginx-1.25
        TO_IMAGE="${CONTAINER_REGISTRY}/${CONTAINER_NAME}:${IMAGE_NAME##*/}-${IMAGE_TAG}"
    fi

    # 打印拉取镜像提示
    echo "📥 拉取镜像 $FORM_IMAGE ..."
    # 从源仓库拉取镜像
    docker pull "$FORM_IMAGE"

    # 打印打标签提示
    echo "🏷️  打标签为 $TO_IMAGE ..."
    # 给镜像打上目标仓库的标签
    docker tag "$FORM_IMAGE" "$TO_IMAGE"

    # 打印推送提示
    echo "📤 推送镜像到远程仓库 ..."
    # 推送镜像到目标仓库
    docker push "$TO_IMAGE"
    
    # 打印成功推送信息
    echo "✅ 已成功推送到：$TO_IMAGE"

    # 打印成功推送信息
    echo "🧹 清理本地镜像：$FORM_IMAGE, $TO_IMAGE"
    docker rmi -f "$FORM_IMAGE" "$TO_IMAGE" || true

    # 美观的分隔线
    echo "------------------------------------"

# 将镜像列表文件内容传给 while 循环处理
done < "$IMAGE_LIST_FILE"

# 所有镜像处理完成后的提示信息
echo "🎉 所有镜像同步完成！"
