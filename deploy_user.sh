#!/bin/bash
# Filename: deploy_user.sh
# Description: Deploys a standardized AI development environment for a user.

# --- 参数处理 ---
USER_NAME=""
PORT_BASE=""
CPUS=""
MEMORY=""

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --cpu)
            CPUS="$2"
            shift 2
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        *)
            if [[ -z "$USER_NAME" ]]; then
                USER_NAME="$1"
            elif [[ -z "$PORT_BASE" ]]; then
                PORT_BASE="$1"
            else
                echo "错误: 未知参数 '$1'"
                exit 1
            fi
            shift
            ;;
    esac
done

# 参数校验
if [[ -z "$USER_NAME" || -z "$PORT_BASE" ]]; then
    echo "用法: ./deploy_user.sh <用户名> <端口基数> [选项]"
    echo "      <用户名>     - 用于命名容器和目录，例如: xinlu"
    echo "      <端口基数>   - 两位数，用于生成唯一端口，例如: 10"
    echo ""
    echo "选项:"
    echo "      --cpu <数量>    - 限制CPU核心数，例如: --cpu 2"
    echo "      --memory <大小> - 限制内存大小，例如: --memory 8g"
    echo ""
    echo "示例: ./deploy_user.sh xinlu 10"
    echo "      ./deploy_user.sh xinlu 10 --cpu 4 --memory 16g"
    echo ""
    echo "注意: 不指定CPU和内存时将不限制资源使用"
    echo "      端口分配规则: SSH=${PORT_BASE}22, VS Code=${PORT_BASE}80, VNC=${PORT_BASE}81"
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

# --- 构建docker run命令 ---
DOCKER_CMD="docker run -d --name ai-dev-$USER_NAME --restart always --network host"

# 添加资源限制（如果指定了）
if [[ -n "$CPUS" ]]; then
    DOCKER_CMD="$DOCKER_CMD --cpus=$CPUS"
fi
if [[ -n "$MEMORY" ]]; then
    DOCKER_CMD="$DOCKER_CMD --memory=$MEMORY"
fi

# 添加卷挂载和环境变量
DOCKER_CMD="$DOCKER_CMD -v $DATA_DIR/workspace:/home/dev/workspace"
DOCKER_CMD="$DOCKER_CMD -v $DATA_DIR/.claude:/home/dev/.claude"
DOCKER_CMD="$DOCKER_CMD -v $DATA_DIR/.claude.json:/home/dev/.claude.json"
DOCKER_CMD="$DOCKER_CMD -e PASSWORD=$USER_PASSWORD"
DOCKER_CMD="$DOCKER_CMD -e SSH_PORT=${PORT_BASE}22"
DOCKER_CMD="$DOCKER_CMD -e VSCODE_PORT=${PORT_BASE}80"
DOCKER_CMD="$DOCKER_CMD -e VNC_PORT=${PORT_BASE}81"
DOCKER_CMD="$DOCKER_CMD -e VNC_DISPLAY_PORT=59${PORT_BASE}"
DOCKER_CMD="$DOCKER_CMD -e PORT_BASE=${PORT_BASE}"
DOCKER_CMD="$DOCKER_CMD ai-dev-env:latest"

# --- 部署容器 ---
echo "正在为用户 $USER_NAME 部署容器..."
DOCKER_OUTPUT=$($DOCKER_CMD 2>&1)
DOCKER_STATUS=$?

if [ $DOCKER_STATUS -eq 0 ]; then
    echo ""
    echo "🎉 用户 $USER_NAME 的环境已部署完成！"
    echo "--------------------------------------------------"
    echo "🔑 初始登录密码 (所有服务通用): $USER_PASSWORD"
    echo "👶 用户容器内终端登录名称：dev"
    echo "--------------------------------------------------"
    echo "🌐 容器使用主机网络模式，服务端口："
    echo "    -> Web VS Code: http://YOUR_SERVER_IP:${PORT_BASE}80"
    echo "    -> Web VNC 桌面: http://YOUR_SERVER_IP:${PORT_BASE}81"
    echo "    -> SSH 终端: ssh dev@YOUR_SERVER_IP -p ${PORT_BASE}22"
    echo "--------------------------------------------------"
    echo "⚠️  注意: 容器内服务已配置为使用指定端口，避免多容器冲突"
    echo "    所有端口都直接暴露在主机上，请确保防火墙规则配置正确"
    echo "--------------------------------------------------"
    if [[ -n "$CPUS" ]]; then
        echo "📊 CPU限制: $CPUS 核"
    fi
    if [[ -n "$MEMORY" ]]; then
        echo "💾 内存限制: $MEMORY"
    fi
    if [[ -z "$CPUS" && -z "$MEMORY" ]]; then
        echo "📊 资源限制: 未设置（使用主机全部资源）"
    fi
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