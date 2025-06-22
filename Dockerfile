FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# 安装核心依赖
RUN apt-get update && apt-get install -y \
    curl sudo wget git vim net-tools gnupg ca-certificates \
    xfce4 xfce4-goodies tigervnc-standalone-server novnc websockify \
    openssh-server \
    build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/miniconda3 && \
    rm /tmp/miniconda.sh && \
    /opt/miniconda3/bin/conda config --set auto_activate_base true && \
    /opt/miniconda3/bin/conda install -y python=3.10

# 设置 Miniconda 环境变量，使其成为系统默认 Python
ENV PATH="/opt/miniconda3/bin:${PATH}"
ENV CONDA_DEFAULT_ENV=base

# 在 base 环境中安装 Poetry
RUN /opt/miniconda3/bin/pip install poetry

# 为所有用户配置 conda
RUN echo 'eval "$(/opt/miniconda3/bin/conda shell.bash hook)"' >> /etc/bash.bashrc && \
    echo 'conda activate base' >> /etc/bash.bashrc

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

# 确保 dev 用户也能使用 miniconda，并设置正确的初始化
RUN echo '# >>> conda initialize >>>' >> /home/dev/.bashrc && \
    echo 'eval "$(/opt/miniconda3/bin/conda shell.bash hook)"' >> /home/dev/.bashrc && \
    echo 'conda activate base' >> /home/dev/.bashrc && \
    echo '# <<< conda initialize <<<' >> /home/dev/.bashrc

EXPOSE 22 5901 6080 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
