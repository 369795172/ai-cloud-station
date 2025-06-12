#!/bin/bash
# Filename: deploy_user.sh
# Description: Deploys a standardized AI development environment for a user.

# --- 参数校验 ---
USER_NAME=$1
PORT_BASE=$2

if [[ -z "$USER_NAME" || -z "$PORT_BASE" ]]; then
    echo "用法: ./deploy_user.sh <用户名> <端口基数>"
    echo "      <用户名>     - 用于命名容器和目录，例如: xinlu"
    echo "      <端口基数>   - 两位数，用于生成唯一端口，例如: 10"
    echo "示例: ./deploy_user.sh xinlu 10 (将使用 1022, 1080, 1081 端口)"
    exit 1
fi

# --- 自动生成唯一的强密码 (16位，仅字母和数字) ---
USER_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
DATA_DIR="/srv/user-data/$USER_NAME"

# --- 为用户准备持久化目录和独立的AI认证 ---
echo "正在为用户 $USER_NAME 准备目录: $DATA_DIR"
sudo mkdir -p "$DATA_DIR/workspace"
sudo chown -R 1000:1000 "$DATA_DIR/workspace"

# 关键步骤：将主机的Claude配置"复制"一份给用户
echo "正在为用户 $USER_NAME 创建独立的AI工具配置..."
if [ -d "/root/.claude" ] && [ -f "/root/.claude.json" ]; then
    sudo cp -r /root/.claude "$DATA_DIR/.claude"
    sudo cp /root/.claude.json "$DATA_DIR/.claude.json"
    sudo chown -R 1000:1000 "$DATA_DIR/.claude"
    sudo chown 1000:1000 "$DATA_DIR/.claude.json"
else
    echo "警告: 未在主机 /root/ 目录下找到Claude配置，容器内可能无法使用。"
fi

# --- 定义资源限制 (可按需调整) ---
CPUS="2"
MEMORY="8g"

# --- 部署容器 ---
echo "正在为用户 $USER_NAME 部署容器..."
DOCKER_OUTPUT=$(docker run -d \
    --name ai-dev-$USER_NAME \
    --restart always \
    --cpus="$CPUS" --memory="$MEMORY" \
    -p "${PORT_BASE}22:22" \
    -p "${PORT_BASE}80:8080" \
    -p "${PORT_BASE}81:6080" \
    -v "$DATA_DIR/workspace:/home/dev/workspace" \
    -v "$DATA_DIR/.claude:/home/dev/.claude" \
    -v "$DATA_DIR/.claude.json:/home/dev/.claude.json" \
    -e "PASSWORD=$USER_PASSWORD" \
    ai-dev-env:latest 2>&1)
DOCKER_STATUS=$?

if [ $DOCKER_STATUS -eq 0 ]; then
    echo ""
    echo "🎉 用户 $USER_NAME 的环境已部署完成！"
    echo "--------------------------------------------------"
    echo "🔑 初始登录密码 (所有服务通用): $USER_PASSWORD"
    echo "👶 用户容器内终端登录名称：dev"
    echo "--------------------------------------------------"
    echo "    -> 🌐 Web VS Code (推荐): http://YOUR_SERVER_IP:${PORT_BASE}80"
    echo "    -> 🖥️  Web VNC 桌面: http://YOUR_SERVER_IP:${PORT_BASE}81"
    echo "    -> 📡 SSH 终端: ssh dev@YOUR_SERVER_IP -p ${PORT_BASE}22"
    echo "--------------------------------------------------"
    echo "请将 'YOUR_SERVER_IP' 替换为你的主机公网IP地址。"
    echo "--------------------------------------------------"
    echo "🚀 如需全自动执行Claude Code Agent（所有ai执行的Linux命令无需手动批准，享受它！)，在容器内的终端执行启动命令：claude --dangerously-skip-permissions"
    echo "--------------------------------------------------"
else
    echo "❌ 部署失败！"
    echo "错误信息如下："
    echo "$DOCKER_OUTPUT"
    exit 2
fi 