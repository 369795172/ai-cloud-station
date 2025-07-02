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

# 安装 Miniconda (Python 3.10)
RUN curl -sSLo /tmp/miniconda.sh "https://repo.anaconda.com/miniconda/Miniconda3-py310_23.5.2-0-Linux-x86_64.sh" && \
    bash /tmp/miniconda.sh -b -p /opt/miniconda && \
    rm /tmp/miniconda.sh
ENV PATH="/opt/miniconda/bin:${PATH}"

# 安装 Poetry 和 uv
RUN python -m pip install poetry && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv

# 设置全局PATH
ENV PATH="/root/.local/bin:${PATH}"

# 创建 dev 用户
RUN useradd -m -s /bin/bash dev && \
    usermod -aG sudo dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 配置 SSH
RUN sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 安装 Node.js 和全局工具
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && npm install -g pnpm playwright @anthropic-ai/claude-code @google/gemini-cli

# 安装 Playwright 浏览器依赖和 code-server
RUN playwright install-deps && playwright install chrome
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
RUN echo 'export PATH="/opt/miniconda/bin:/root/.local/bin:/root/.cargo/bin:$PATH"' >> /home/dev/.bashrc && \
    echo 'alias yolo="claude --dangerously-skip-permissions"' >> /home/dev/.bashrc && \
    echo 'alias gyolo="gemini --yolo"' >> /home/dev/.bashrc && \
    echo 'export PATH="/home/dev/.local/bin:$PATH"' >> /home/dev/.bashrc && \
    /opt/miniconda/bin/conda init bash && \
    echo 'conda activate base' >> /home/dev/.bashrc

EXPOSE 22 5901 6080 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
