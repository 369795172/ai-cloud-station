FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 安装核心依赖
RUN apt-get update && apt-get install -y \
    curl sudo wget git vim net-tools gnupg ca-certificates \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    openssh-server \
    python3.10 python3-pip python3.10-venv \
    build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 创建 dev 用户
RUN useradd -m -s /bin/bash dev && \
    usermod -aG sudo dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 配置 SSH
RUN sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 安装 Node.js、全局工具
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g pnpm playwright @anthropic-ai/claude-code anon-kode \
    && curl -LsSf https://astral.sh/uv/install.sh | sh

# 安装 Playwright 浏览器依赖和 code-server
RUN playwright install-deps && playwright install chrome
RUN curl -fsSL https://code-server.dev/install.sh | sh

# 复制入口脚本
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER dev
WORKDIR /home/dev/workspace

# 安装 Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/home/dev/.local/bin:${PATH}"

EXPOSE 22 5901 6080 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
