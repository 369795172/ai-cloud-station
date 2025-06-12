#!/bin/bash
# Filename: resync_auth.sh

echo "开始同步最新的 Claude 认证信息..."

SOURCE_CONFIG_DIR="/root/.claude"
SOURCE_CONFIG_FILE="/root/.claude.json"
USER_DATA_ROOT="/srv/user-data"

if [ ! -d "$SOURCE_CONFIG_DIR" ] || [ ! -f "$SOURCE_CONFIG_FILE" ]; then
    echo "错误: 未找到源配置。请确保管理员已在主机上重新登录Claude。"
    exit 1
fi

for user_dir in "$USER_DATA_ROOT"/*; do
    if [ -d "$user_dir" ]; then
        USER_NAME=$(basename "$user_dir")
        echo "-> 正在为用户 '$USER_NAME' 同步..."
        sudo cp -rT "$SOURCE_CONFIG_DIR" "$user_dir/.claude"
        sudo cp "$SOURCE_CONFIG_FILE" "$user_dir/.claude.json"
        echo "   '$USER_NAME' 同步完成。"
    fi
done

echo "✅ 所有用户的 Claude 认证信息已同步至最新！"