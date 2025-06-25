FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 安装核心依赖
RUN apt-get update && apt-get install -y \
    curl sudo wget git vim net-tools gnupg ca-certificates \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    openssh-server \
    software-properties-common \
    build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 添加deadsnakes PPA并安装Python 3.12
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y python3.12 python3.12-dev python3.12-venv python3.12-distutils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 设置python和python3命令指向python3.12
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# 安装pip for Python 3.12
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12

# 安装Poetry和uv到系统Python
RUN pip install poetry && \
    curl -LsSf https://astral.sh/uv/install.sh | sh

# 设置全局PATH包含poetry和uv
ENV PATH="/root/.local/bin:/root/.cargo/bin:${PATH}"

# 创建 dev 用户
RUN useradd -m -s /bin/bash dev && \
    usermod -aG sudo dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 配置 SSH
RUN sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 安装 Node.js、全局工具（移除anon-kode）
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g pnpm playwright @anthropic-ai/claude-code

# 安装 Playwright 浏览器依赖和 code-server
RUN playwright install-deps && playwright install chrome
RUN curl -fsSL https://code-server.dev/install.sh | sh

# 复制入口脚本
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 添加系统级别名
RUN echo 'alias yolo="claude --dangerously-skip-permissions"' >> /etc/bash.bashrc

USER dev
WORKDIR /home/dev/workspace

# 为dev用户设置Poetry、uv路径和yolo别名
RUN echo 'export PATH="/root/.local/bin:/root/.cargo/bin:$PATH"' >> /home/dev/.bashrc && \
    echo 'alias yolo="claude --dangerously-skip-permissions"' >> /home/dev/.bashrc && \
    echo 'export PATH="/home/dev/.local/bin:$PATH"' >> /home/dev/.bashrc

EXPOSE 22 5901 6080 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
