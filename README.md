## Docker 镜像同步脚本说明

本脚本用于从公开镜像仓库（如 Docker Hub）批量拉取镜像，重命名后推送至目标容器仓库（如阿里云、Docker Hub 企业版等）。可用于构建私有镜像代理，或批量同步官方镜像。

---

## 环境变量配置

在运行脚本前，你需要通过以下环境变量提供必要的配置信息：

| 环境变量名           | 是否必须 | 说明                                 |
| -------------------- | -------- | ------------------------------------ |
| `CONTAINER_USERNAME` | ✅        | 目标仓库的登录用户名                 |
| `CONTAINER_PASSWORD` | ✅        | 目标仓库的登录密码或 Token           |
| `CONTAINER_NAME`     | ✅        | 目标仓库的命名空间（组织名/用户名）  |
| `IMAGE_LIST_FILE`    | ✅        | 镜像列表文件路径，每行一个镜像名     |
| `CONTAINER_REGISTRY` | ❌        | 目标镜像仓库地址，默认为 `docker.io` |

## 镜像列表格式

镜像列表文件 `IMAGE_LIST_FILE` 的格式如下：

~~~
mysql:5.7
mysql:8.0
mysql:8.1
mysql:8.2
mysql:8.3
mysql:8.4

mariadb:10.5
mariadb:10.6
mariadb:10.11
mariadb:11.4
mariadb:11.7

redis:6.2
redis:7.4
~~~

> ⚠️ 若未指定 tag，将自动使用 `latest`。

## 脚本功能说明

- 自动登录目标镜像仓库；
- 逐行读取镜像名；
- 自动拉取源镜像；
- 自动重命名目标镜像（`镜像名[-tag]` 格式）；
- 推送到目标仓库；
- 所有镜像处理完成后输出成功提示。

## 使用示例

#### 设置环境变量

~~~
# 检查是否设置了 ACR 用户名
: "${ACR_USERNAME:?❌ 你必须设置环境变量 ACR_USERNAME}"
# 检查是否设置了 ACR 密码
: "${ACR_PASSWORD:?❌ 你必须设置环境变量 ACR_PASSWORD}"
export CONTAINER_USERNAME=${ACR_USERNAME}
export CONTAINER_PASSWORD=${ACR_PASSWORD}
export CONTAINER_REGISTRY=registry.cn-hangzhou.aliyuncs.com
export CONTAINER_NAME=buildx/hub
export IMAGE_LIST_FILE=acr.hub.list
~~~

#### 编写镜像列表 acr.hub.list；

~~~
mysql:5.7
~~~

#### 运行脚本

```
bash sync-images.sh
```

#### 成功输出示例

~~~
🔐 登录 registry.cn-hangzhou.aliyuncs.com ...
🚀 正在处理镜像：mysql:5.7
📥 拉取镜像 mysql:5.7 ...
🏷️  打标签为 registry.cn-hangzhou.aliyuncs.com/buildx/hub:mysql-5.7 ...
📤 推送镜像到远程仓库 ...
✅ 已成功推送到：registry.cn-hangzhou.aliyuncs.com/buildx/hub:mysql-5.7
------------------------------------
🎉 所有镜像同步完成！
~~~

## 故障处理

- 脚本遇到错误时会立刻中止执行；
- 同时会打印出**最后处理失败的镜像名**，方便排查。

## 注意事项

- 请确保本机 Docker 登录权限与网络通畅；
- 目标仓库必须具备写入权限；
- 若用于 CI/CD 环境，建议使用 Token 登录并加密存储密码。
