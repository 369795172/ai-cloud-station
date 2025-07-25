# ai-cloud-station

## 项目简介

**ai-cloud-station** 是一套面向全球协作团队的 AI 云端开发环境一键部署解决方案。通过 Docker 容器化技术，将顶级 AI 编码工具（如 Claude Code、Gemini CLI、OpenAI Codex、Devin 等）和现代开发环境集成在一起，帮助团队成员无论身处何地，都能安全、稳定、高效地使用最强 AI 编码能力。

### 主要特性

- **Python 3.12 系统级集成**: 使用系统级 Python 3.12，`python` 命令直接指向 `python3`，Poetry 和 uv 预装，环境更加简洁稳定。
- **主机网络模式**: 容器与主机共享网络命名空间，可直接暴露任意端口，支持 WebSocket、HTTP 等所有协议的透传访问。
- **灵活资源控制**: 支持通过 `--cpu` 和 `--memory` 参数精确控制容器资源，不指定时默认不限制。
- **便捷别名**: 内置 `yolo` (Claude) 和 `gyolo` (Gemini) 别名，一键启用 AI 全自动执行模式。

## 核心价值

- **极致易用**：一键部署，5 分钟内为每位成员分配专属 AI 云端开发环境。
- **全球可用**：突破地域和网络限制，团队成员可随时随地访问。
- **安全合规**：代码、AI 认证集中在云端，避免本地泄露和账号风控。
- **高效协作**：新成员入职无需复杂配置，环境标准化，极大提升团队效率。
- **开源透明**：所有脚本、配置、流程均开源，便于自定义和二次开发。

## 适用场景

- 跨国/远程/分布式开发团队
- 需要统一 AI 编码环境的企业/创业公司
- 个人开发者希望体验 AI 3.0 时代的云端开发
- 教育/培训/编程教学场景

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/369795172/ai-cloud-station.git
cd ai-cloud-station
```

### 2. 配置Docker镜像加速器（推荐）

#### Windows/macOS用户配置Docker Desktop

1. 在系统托盘图标内右键菜单选择 **Settings**
2. 打开配置窗口后左侧导航菜单选择 **Docker Engine**
3. 编辑窗口内的JSON配置，添加阿里云镜像加速器地址：

```json
{
  "registry-mirrors": [
    "https://[你的专属ID].mirror.aliyuncs.com"
  ]
}
```

4. 点击 **Apply & Restart** 保存并重启Docker

> **获取专属加速器地址**：
> 1. 访问 [阿里云容器镜像服务控制台](https://cr.console.aliyun.com/ap-southeast-1/instances/mirrors)
> 2. 登录阿里云账号
> 3. 复制专属的镜像加速器地址（格式：`https://[专属ID].mirror.aliyuncs.com`）

#### Linux用户配置

```bash
# 创建或编辑Docker配置文件
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://[你的专属ID].mirror.aliyuncs.com"
  ]
}
EOF

# 重启Docker服务
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 3. 构建标准化开发镜像

```bash
# Windows用户
docker build -t ai-dev-env:latest .

# Linux/macOS用户
sudo docker build -t ai-dev-env:latest .
```

> **构建优化提示**：
> - 项目已内置国内镜像源配置，提高Ubuntu软件包下载速度
> - 首次构建可能需要10-20分钟，请耐心等待
> - 如遇到网络问题，建议配置Docker镜像加速器
> - 构建过程中会自动安装Python 3.12、Node.js、开发工具等完整环境

### 4. 为每位成员一键部署专属环境

```bash
chmod +x deploy_user.sh

# 基础用法
./deploy_user.sh 用户名 端口基数

# 指定资源限制
./deploy_user.sh 用户名 端口基数 --cpu 16 --memory 128g

# 示例
./deploy_user.sh xinlu 10                      # 端口: 1022(SSH), 1080(VS Code), 1081(VNC)
./deploy_user.sh alice 20 --cpu 2              # 端口: 2022, 2080, 2081, 限制2核CPU
./deploy_user.sh bob 30 --memory 8g            # 端口: 3022, 3080, 3081, 限制8GB内存
```
- **端口基数**：两位数字，用于生成唯一端口号，避免容器间冲突
- 脚本会自动生成随机密码、初始化持久化目录、同步AI认证
- 容器使用主机网络模式，服务通过环境变量配置端口
- 不指定资源限制时，容器可使用主机全部资源
- 脚本执行成功后，会输出所有访问方式和凭证

### 5. 认证同步/批量维护（如有需要）

```bash
chmod +x resync_auth.sh
./resync_auth.sh
```

### 6. 访问方式

容器使用主机网络模式，服务端口基于端口基数分配：

假设端口基数为 `XX`，则服务端口为：
- **SSH 终端**: `ssh dev@YOUR_SERVER_IP -p XX22` 
- **VS Code Web**: `http://YOUR_SERVER_IP:XX80`
- **noVNC 桌面**: `http://YOUR_SERVER_IP:XX81`
- **VNC 原生端口**: `59XX` (供VNC客户端直连)

示例（端口基数=10）：
- SSH: 端口 1022
- VS Code: 端口 1080
- noVNC: 端口 1081
- VNC: 端口 5910

密码见脚本输出，所有服务使用相同密码。

## 进阶用法与最佳实践

### 1. 网络模式与资源限制

- **主机网络模式**: 容器使用 `--network host` 模式，可以暴露任意端口，支持 WebSocket、HTTP 等所有协议直接访问。
- **端口分配**: 通过端口基数机制自动分配不冲突的端口：
  - 建议为每个用户分配不同的端口基数（10、20、30...）
  - 端口计算规则：`基数+服务端口后缀`（如基数10：1022、1080、1081）
- **资源限制**: 通过 `--cpu` 和 `--memory` 参数控制资源使用，不指定时默认不限制。
  ```bash
  ./deploy_user.sh user1 10 --cpu 2 --memory 8g    # 端口10xx，限制2核CPU，8GB内存
  ./deploy_user.sh user2 20                        # 端口20xx，不限制资源
  ```
- 支持批量部署、批量认证同步，适合 10-50 人团队。

### 2. 数据持久化与备份

- 所有用户代码、AI 配置均挂载到主机 `/srv/user-data/用户名`，容器重建不丢数据。
- 建议定期使用 `cron` 任务自动备份 `/srv/user-data/` 目录到云存储或 NAS，防止意外丢失。

### 3. 认证同步与自动化维护

- Claude 认证并非永久有效，管理员可在主机上重新登录后，运行 `resync_auth.sh` 一键同步所有用户认证，无需重启容器。
- 支持一键批量同步，极大降低维护成本。

### 4. 安全加固建议

- 建议仅开放必要端口，使用防火墙（如 ufw）限制访问来源。
- 推荐为 VS Code Web、noVNC 配置 HTTPS 访问，提升安全性。
- 支持 SSH 密钥认证，进一步提升安全等级。
- 所有认证配置均以只读方式挂载，防止泄露和篡改。

### 5. 性能与运维建议

- 镜像分层优化，减少构建时间和体积。
- 支持自定义 npm/pip 镜像源，加速依赖安装。
- 推荐定期更新基础镜像和工具，及时打安全补丁。
- 可通过 `docker stats`、`df -h` 等命令监控资源使用和健康状态。

## 常见问题（FAQ）

**Q1：Docker构建失败怎么办？**  
A：常见原因和解决方案：
- **网络问题**：配置Docker镜像加速器，参考快速开始第2步
- **软件源问题**：项目已内置国内镜像源配置，如仍有问题可尝试更换其他镜像源
- **内存不足**：确保Docker有足够内存（建议8GB以上）
- **磁盘空间不足**：清理Docker缓存 `docker system prune -a`
- **镜像加速器配置错误**：确保使用正确的专属加速器地址格式

**Q2：如何批量为团队成员分配环境？**  
A：可编写简单的 shell 脚本循环调用 `deploy_user.sh`，或结合 CI/CD 工具实现自动化。

**Q3：Claude 认证失效怎么办？**  
A：管理员在主机上重新登录 Claude 后，运行 `resync_auth.sh` 即可一键同步，无需重启容器。

**Q4：如何实现 HTTPS/子域名访问？**  
A：推荐在主机部署 Nginx/Traefik 反向代理，为每位成员分配独立子域名并配置 SSL 证书。

**Q5：如何扩展更多 AI 工具或自定义开发环境？**  
A：可直接修改 Dockerfile，添加所需依赖和工具，重建镜像即可。

**Q6：多个容器使用主机网络模式时端口冲突怎么办？**  
A：项目已通过端口基数机制解决此问题。每个用户使用不同的端口基数（如10、20、30），容器会自动使用对应的端口范围，避免冲突。

**Q7：如何使用 Python 环境？**  
A：容器使用系统级 Python 3.12，`python` 命令已指向 `python3`。预装了 `pip`、`poetry` 和 `uv` 包管理器，支持虚拟环境创建。

**Q8：容器内服务如何被外部访问？**  
A：由于使用主机网络模式，容器内启动的任何服务都可以通过主机 IP 直接访问，无需额外的端口映射配置。

**Q9：如何使用 AI 助手工具？**  
A：容器预装了多个AI助手和快捷别名：
- `yolo` - Claude全自动执行模式（等价于 `claude --dangerously-skip-permissions`）
- `gyolo` - Gemini全自动执行模式（等价于 `gemini --yolo`）
- `gemini` - Google Gemini交互式AI助手，支持最多60次/分钟，1000次/天的免费请求

## 适用与不适用场景分析

- **最适合**：小型技术团队、重视开发环境标准化、需要快速扩展的企业/创业公司。
- **不推荐**：完全离线环境、对云端数据有极高敏感要求的场景。

## 监控与维护建议

- 定期监控容器 CPU/内存、磁盘使用、Claude API 状态。
- 建议每月更新镜像、工具和安全补丁。
- 支持日志审计，可通过 `docker run --log-driver=syslog ...` 启用。

## 用户反馈与真实体验

> "以前用 Claude Code断断续续，现在丝滑得很，重构大型组件再也不怕了。" —— 前端开发 
> "统一环境确实省心，新人入职直接给账号就能干活，不用再折腾各种配置。" —— 后端架构师 
> "团队开发效率明显提升，大家的代码质量也更一致了。" —— 项目经理 

## 贡献与支持

- 欢迎 Star、Fork、提 Issue、提 PR！
- 如需定制化部署、AI 账号代开、企业级支持、垂直场景Manus开发，欢迎联系 ShareAI 团队 


---

让 AI 赋能每一位开发者，让协作无国界。

---

如需更详细的技术原理、架构设计、实战经验和优化建议，欢迎查阅代码或 Issues 区交流、微信交流。   
ai-lab@foxmail.com
<img src="./qrcode.jpg" width="600">
