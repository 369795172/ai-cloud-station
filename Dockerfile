FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 配置国内镜像源以提高下载速度
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# 安装核心依赖
RUN apt-get update && apt-get install -y \
    curl sudo wget git vim net-tools gnupg ca-certificates \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    openssh-server \
    software-properties-common \
    build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 Python 3.12 (系统级)
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y python3.12 python3.12-venv python3.12-dev python3-pip && \
    ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 Poetry 和 uv
RUN curl -sSL https://install.python-poetry.org | python - && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv

# 设置全局PATH
ENV PATH="/root/.local/bin:${PATH}"

# 创建 dev 用户
RUN useradd -m -s /bin/bash dev && \
    usermod -aG sudo dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 配置 SSH
RUN sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    ssh-keygen -A

# 安装 Node.js 和全局工具
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g pnpm playwright @anthropic-ai/claude-code @google/gemini-cli

# 安装 Playwright 浏览器依赖和 code-server
RUN playwright install-deps && \
    arch=$(arch) && \
    if [ "$arch" = "aarch64" ]; then \
        # arm64 没有 chrome，用官方 Chromium/Firefox/WebKit 即可
        playwright install chromium; \
    else \
        playwright install chrome; \
    fi
RUN curl -fsSL https://code-server.dev/install.sh | sh

# 复制入口脚本
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 添加系统级别名
RUN echo 'alias yolo="claude --dangerously-skip-permissions"' >> /etc/bash.bashrc && \
    echo 'alias gyolo="gemini --yolo"' >> /etc/bash.bashrc

USER dev
WORKDIR /home/dev/workspace

# 为dev用户设置环境
RUN echo 'export PATH="/root/.local/bin:/root/.cargo/bin:$PATH"' >> /home/dev/.bashrc && \
    echo 'alias yolo="claude --dangerously-skip-permissions"' >> /home/dev/.bashrc && \
    echo 'alias gyolo="gemini --yolo"' >> /home/dev/.bashrc && \
    echo 'export PATH="/home/dev/.local/bin:$PATH"' >> /home/dev/.bashrc

EXPOSE 22 5901 6080 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
