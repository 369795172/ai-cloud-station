#!/bin/bash
set -e

# --- 1. 从环境变量中获取统一密码，并设置给新用户 'dev' ---
USER_PASSWORD=${PASSWORD:-"DefaultPasswordPleaseChange"}

# --- 1.1 从环境变量中获取端口配置 ---
SSH_PORT=${SSH_PORT:-22}
VSCODE_PORT=${VSCODE_PORT:-8080}
VNC_PORT=${VNC_PORT:-6080}
VNC_DISPLAY_PORT=${VNC_DISPLAY_PORT:-5901}
# 使用 sudo 来更改 'dev' 用户的密码
echo "dev:$USER_PASSWORD" | sudo chpasswd
echo "✅ User 'dev' password set."

# --- 1.5 确保挂载的工作区目录可写，并属于 dev 用户 ---
WORKSPACE_DIR="/home/dev/workspace"
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "📂 工作区不存在，正在创建 $WORKSPACE_DIR ..."
    sudo mkdir -p "$WORKSPACE_DIR"
fi
# 无论目录是否预先存在，都确保归属权正确
sudo chown -R dev:dev "$WORKSPACE_DIR"

# 创建兼容路径 /workspace (某些 VS Code 内部逻辑会默认该路径)
if [ ! -e "/workspace" ]; then
    echo "🔗 创建 /workspace -> $WORKSPACE_DIR 的符号链接..."
    sudo ln -s "$WORKSPACE_DIR" /workspace
fi
# 确保链接目标的权限也归 dev
sudo chown -h dev:dev /workspace

# --- 1.7 为新用户生成 环境说明.md ---
README_FILE="/home/dev/workspace/环境说明.md"
if [ ! -f "$README_FILE" ]; then
    echo "📝 正在生成欢迎文件 环境说明.md ..."
    cat <<'EOF' | sudo tee "$README_FILE" > /dev/null
# 欢迎使用团队 AI 云端工作站

您正在使用基于 Docker 构建的 **AI 编码 3.0** 环境。

## 快速提示
1. **全自动执行 Claude Code Agent**  
   在 VS Code 终端或 SSH 中执行：
   ```bash
   claude --dangerously-skip-permissions
   ```
   该模式下，AI 可以无需人工确认直接执行命令，请谨慎使用。
2. 如果在线IDE个别扩展功能不正常（又非常想用的情况下），请配置反向代理 + 域名 + SSL，并通过"https://域名"访问在线IDE，具体可以问问claude是怎么配的

## 预装工具 (常见版本)
| 工具 | 版本 | 说明 |
|------|------|------|
| Ubuntu | 22.04 LTS | 基础镜像 |
| Bash | 5.x | 默认 Shell |
| OpenSSH Server | 最新 | 方便远程 SSH 登录 |
| **Node.js** | 22.x | 由 NodeSource 仓库安装 |
| pnpm | 最新 | 全局包管理器 |
| **Python** | 3.10 | 系统自带 + `python3-pip` |
| Poetry | 最新 | 现代化 Python 依赖管理 |
| **Playwright** | 最新 | 以及 `chrome` 浏览器依赖 |
| code-server | 最新 | VS Code Web 版 |
| xfce4 / TigerVNC / noVNC | 最新 | 远程桌面环境 |
| **Claude CLI** | 最新 | `@anthropic-ai/claude-code` |
| **Anon Kode** | 最新 | 交互式 AI 编程助手 |
| **uv** | 最新 | Rust 实现的极速 Python 包管理器 |
| Git / Vim / curl / build-essential | - | 常用开发工具 |

> 注：版本号可能随镜像重新构建而更新，可在终端通过 `node -v`、`python --version` 等命令查看。

## 目录结构
- `/home/dev`：您的主目录（VS Code 默认打开）。
- `/home/dev/workspace`：持久化工作区，会映射到宿主机。
- `/workspace`：指向 `/home/dev/workspace` 的符号链接，兼容部分插件。

## 资源限制
管理员在部署脚本中为每个容器设置了 `--cpus` 与 `--memory` 参数，避免资源争用。如需更多资源，请联系管理员。

祝你编码愉快！
EOF
    sudo chown dev:dev "$README_FILE"
fi

# --- 2. 使用sudo启动需要root权限的核心服务 ---
# 配置 SSH 端口
sudo sed -i "s/^#*Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config
sudo /etc/init.d/ssh start
echo "✅ SSH server started on port $SSH_PORT."

# --- 3. 以 'dev' 用户身份，在用户主目录中配置并启动桌面和Web IDE ---
# 设置 VNC 密码并启动 VNC (路径修改为 /home/dev)
mkdir -p /home/dev/.vnc
echo "$USER_PASSWORD" | vncpasswd -f > /home/dev/.vnc/passwd
chmod 600 /home/dev/.vnc/passwd
# 计算VNC显示号（基于端口基数）
VNC_DISPLAY_NUM=${PORT_BASE:-1}
vncserver :$VNC_DISPLAY_NUM -geometry 1280x800 -rfbport $VNC_DISPLAY_PORT -localhost no
echo "✅ VNC server started on display :$VNC_DISPLAY_NUM, port $VNC_DISPLAY_PORT."

# 启动 noVNC (Web VNC 客户端)
websockify --web=/usr/share/novnc/ $VNC_PORT localhost:$VNC_DISPLAY_PORT &
echo "✅ noVNC (Web VNC client) started on port $VNC_PORT."

# 启动 code-server (Web IDE)，并默认打开工作区
# 所有路径都指向 /home/dev/workspace 下的持久化目录
# 确保使用conda环境中的Python
PASSWORD="$USER_PASSWORD" /usr/bin/code-server \
    --bind-addr 0.0.0.0:$VSCODE_PORT \
    --auth password \
    --user-data-dir /workspace/.vscode-server \
    --extensions-dir /workspace/.vscode-server/extensions \
    /home/dev/workspace &
echo "✅ code-server (Web IDE) started on port $VSCODE_PORT."

# --- 1.6 修复 Claude 配置目录权限 ---
CLAUDE_DIR="/home/dev/.claude"
CLAUDE_FILE="/home/dev/.claude.json"
if [ -e "$CLAUDE_DIR" ]; then
    sudo chown -R dev:dev "$CLAUDE_DIR"
fi
if [ -e "$CLAUDE_FILE" ]; then
    sudo chown dev:dev "$CLAUDE_FILE"
fi

echo "🚀 Cloud Dev Environment is ready. Welcome to AI Coding 3.0."
# 使用 tail -f 保持容器前台运行，确保所有后台服务持续工作
tail -f /dev/null 