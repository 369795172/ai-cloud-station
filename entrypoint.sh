#!/bin/bash
set -e

USER_PASSWORD=${PASSWORD:-"DefaultPasswordPleaseChange"}
SSH_PORT=${SSH_PORT:-22}
VSCODE_PORT=${VSCODE_PORT:-8080}
VNC_PORT=${VNC_PORT:-6080}
VNC_DISPLAY_PORT=${VNC_DISPLAY_PORT:-5901}

echo "dev:$USER_PASSWORD" | sudo chpasswd
echo "✅ User 'dev' password set."

WORKSPACE_DIR="/home/dev/workspace"
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "📂 Creating workspace directory $WORKSPACE_DIR..."
    sudo mkdir -p "$WORKSPACE_DIR"
fi
sudo chown -R dev:dev "$WORKSPACE_DIR"

if [ ! -e "/workspace" ]; then
    echo "🔗 Creating symlink /workspace -> $WORKSPACE_DIR..."
    sudo ln -s "$WORKSPACE_DIR" /workspace
fi
sudo chown -h dev:dev /workspace

README_FILE="/home/dev/workspace/环境说明.md"
if [ ! -f "$README_FILE" ]; then
    echo "📝 Generating welcome file 环境说明.md..."
    cat <<'EOF' | sudo tee "$README_FILE" > /dev/null
# 欢迎使用团队 AI 云端工作站

您正在使用基于 Docker 构建的 **AI 编码 3.0** 环境。

## 快速提示
1. **AI 助手工具**  
   在 VS Code 终端或 SSH 中使用：
   ```bash
   # Claude Code Agent
   claude --dangerously-skip-permissions
   yolo    # Claude全自动模式简化别名
   
   # Google Gemini CLI
   gemini           # ��互式AI助手
   gemini --yolo    # Gemini全自动模式
   gyolo           # Gemini全自动模式简化别名
   ```
   yolo/gyolo模式下，AI 可以无需人工确认直接执行命令，请谨慎使用。
2. 如果在线IDE个别扩展功能不正常（又非常想用的情况下），请配置反向代理 + 域名 + SSL，并通过"https://域名"访问在线IDE，具体可以问问claude是怎么配的

## 预装工具 (常见版本)
| 工具 | 版本 | 说明 |
|------|------|------|
| Ubuntu | 22.04 LTS | 基础镜像 |
| Bash | 5.x | 默认 Shell |
| OpenSSH Server | 最新 | 方便远程 SSH 登录 |
| **Node.js** | 23.x | 由 NodeSource 仓库安装 |
| pnpm | 最新 | 全局包管理器 |
| **Python** | 3.12 | 系统级安装 |
| Poetry | 最新 | 现代化 Python 依赖管理 |
| **Playwright** | 最新 | 以及 `chrome` 浏览器依赖 |
| code-server | 最新 | VS Code Web 版 |
| xfce4 / TigerVNC / noVNC | 最新 | 远程桌面环境 |
| **Claude CLI** | 最新 | `@anthropic-ai/claude-code`，别名 `yolo` |
| **Gemini CLI** | 最新 | `@google/gemini-cli`，Google AI 助手 |
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

# 配置 SSH 服务
sudo sed -i "s/^#*Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config
# 确保 SSH 监听所有接口
sudo sed -i "s/^#*ListenAddress .*/ListenAddress 0.0.0.0/" /etc/ssh/sshd_config
sudo /etc/init.d/ssh start
echo "✅ SSH server started on port $SSH_PORT."

# 设置 VNC
mkdir -p /home/dev/.vnc
echo "$USER_PASSWORD" | vncpasswd -f > /home/dev/.vnc/passwd
chmod 600 /home/dev/.vnc/passwd
VNC_DISPLAY_NUM=${PORT_BASE:-1}
vncserver :$VNC_DISPLAY_NUM -geometry 1280x800 -rfbport $VNC_DISPLAY_PORT -localhost no
echo "✅ VNC server started on display :$VNC_DISPLAY_NUM, port $VNC_DISPLAY_PORT."

# 启动 noVNC
websockify --web=/usr/share/novnc/ -v $VNC_PORT 0.0.0.0:$VNC_DISPLAY_PORT &
echo "✅ noVNC (Web VNC client) started on port $VNC_PORT."

# 启动 VS Code Server
PASSWORD="$USER_PASSWORD" /usr/bin/code-server \
    --bind-addr 0.0.0.0:$VSCODE_PORT \
    --auth password \
    --user-data-dir /workspace/.vscode-server \
    --extensions-dir /workspace/.vscode-server/extensions \
    /home/dev/workspace &
echo "✅ code-server (Web IDE) started on port $VSCODE_PORT."

# 设置 Claude 权限
CLAUDE_DIR="/home/dev/.claude"
CLAUDE_FILE="/home/dev/.claude.json"
if [ -e "$CLAUDE_DIR" ]; then
    sudo chown -R dev:dev "$CLAUDE_DIR"
fi
if [ -e "$CLAUDE_FILE" ]; then
    sudo chown dev:dev "$CLAUDE_FILE"
fi

echo "🚀 Cloud Dev Environment is ready. Welcome to AI Coding 3.0."
tail -f /dev/null 