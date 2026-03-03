# Docker 使用说明

本目录用于构建并运行 `xiaoheifs` 后端服务。

## 推荐组合

- 后端镜像：`xiaoheifs-backend:latest`（Debian）
- 数据库：MySQL（`docker-compose.mysql.yaml`）

## 目录结构

```text
docker/
├── README.md
├── build/
│   ├── Dockerfile                   # Debian 版镜像构建文件（默认）
│   ├── Dockerfile.alpine            # Alpine 版镜像构建文件
│   ├── sources.list                 # Debian APT 镜像源配置（清华源）
│   ├── start.sh                     # 容器入口脚本，按环境变量生成 app.config.yaml
│   ├── build-docker-image.sh        # Linux/macOS 构建脚本（交互支持 latest/alpine/all）
│   ├── build-docker-image.ps1       # Windows PowerShell 构建脚本（交互支持 latest/alpine/all）
│   └── build-docker-image.bat       # Windows CMD 构建脚本（交互支持 latest/alpine/all）
└── docker-compose/
    ├── docker-compose.mysql.yaml    # MySQL 部署
    ├── docker-compose.postgres.yaml # PostgreSQL 部署
    └── docker-compose.sqlite.yaml   # SQLite 部署（仅测试，暂未支持）
```

## 构建镜像

### Linux/macOS

```bash
./docker/build/build-docker-image.sh
```

交互输入：
- `1` = `latest`（Debian）
- `2` = `alpine`
- `0` = `all`

### Windows PowerShell

```powershell
.\docker\build\build-docker-image.ps1
```

### Windows CMD

```bat
.\docker\build\build-docker-image.bat
```

## 启动服务

### 推荐：MySQL

```bash
docker compose -f docker/docker-compose/docker-compose.mysql.yaml up -d --build
```

### PostgreSQL

```bash
docker compose -f docker/docker-compose/docker-compose.postgres.yaml up -d --build
```

### SQLite（仅测试，暂未支持）

```bash
docker compose -f docker/docker-compose/docker-compose.sqlite.yaml up -d --build
```

## 停止与清理

```bash
docker compose -f docker/docker-compose/docker-compose.mysql.yaml down
```

删除容器并清理数据卷（会删除数据库数据）：

```bash
docker compose -f docker/docker-compose/docker-compose.mysql.yaml down -v
```

## 说明

- compose 文件中默认镜像为 `xiaoheifs-backend:latest`。
- 如需切换 Alpine 镜像，可将 compose 中应用镜像改为 `xiaoheifs-backend:alpine`。
- compose 中的数据库密码为测试用途，请勿用于生产环境。
