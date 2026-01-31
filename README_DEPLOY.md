# 审批进度可视化系统 - 部署指南

## 📦 项目说明

这是一个独立的审批进度可视化系统，用于展示企微审批数据。

## 🚀 快速部署

### 1. 环境要求

- Python 3.8+
- pip

### 2. 安装依赖

```bash
pip install -r requirements.txt
```

### 3. 准备数据

将初始的Excel文件命名为 `线上建店审批.xlsx` 放在项目目录

### 4. 生成数据

```bash
python parse_excel.py
```

### 5. 启动服务器

```bash
python deploy_server.py
```

服务器将在 `http://0.0.0.0:8080` 启动

## 📊 更新数据

### 方法1: 使用更新脚本（推荐）

```bash
python update_excel.py 新下载的文件.xlsx
```

脚本会自动：
1. 备份旧文件
2. 删除旧文件
3. 复制新文件
4. 重新解析数据

### 方法2: 手动更新

```bash
# 1. 替换Excel文件
cp 新文件.xlsx 线上建店审批.xlsx

# 2. 重新生成数据
python parse_excel.py
```

## 🗂️ 项目结构

```
temp_view/
├── index.html              # 前端页面
├── parse_excel.py          # 数据解析脚本
├── deploy_server.py        # 生产服务器
├── update_excel.py         # 数据更新脚本
├── requirements.txt        # Python依赖
├── 线上建店审批.xlsx       # Excel数据文件
├── approval_data.json      # 生成的JSON数据
└── README_DEPLOY.md        # 本文件
```

## 🔧 配置说明

### 修改端口

编辑 `deploy_server.py`:

```python
PORT = 8080  # 改为你需要的端口
```

### 防火墙设置

确保服务器防火墙允许访问端口（默认8080）

## 📝 日常维护

### 每日更新流程

1. 从企微下载最新Excel
2. 上传到服务器
3. 运行更新脚本：
   ```bash
   python update_excel.py 新文件.xlsx
   ```
4. 完成！无需重启服务器

## ⚠️ 注意事项

1. **文件替换**: 更新脚本会自动删除旧文件，保持目录整洁
2. **备份**: 每次更新会自动备份旧文件（带时间戳）
3. **清理**: 定期清理备份文件，只保留最近几个
4. **权限**: 确保脚本有读写权限

## 🛡️ 安全建议

1. 使用防火墙限制访问IP
2. 考虑使用Nginx反向代理
3. 启用HTTPS（通过Nginx）
4. 定期更新依赖包

## 📞 故障排查

### 问题1: 端口被占用
```bash
# 查看端口占用
lsof -i :8080

# 或使用其他端口
```

### 问题2: 权限不足
```bash
# 给脚本执行权限
chmod +x *.py
```

### 问题3: 依赖安装失败
```bash
# 使用国内镜像
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

## 🔄 后台运行

### 使用 nohup

```bash
nohup python deploy_server.py > server.log 2>&1 &
```

### 使用 systemd（推荐）

创建服务文件 `/etc/systemd/system/approval-viewer.service`:

```ini
[Unit]
Description=Approval Progress Viewer
After=network.target

[Service]
Type=simple
User=your_user
WorkingDirectory=/path/to/temp_view
ExecStart=/usr/bin/python3 deploy_server.py
Restart=always

[Install]
WantedBy=multi-user.target
```

启动服务:
```bash
sudo systemctl start approval-viewer
sudo systemctl enable approval-viewer
```

## 📊 监控

查看服务器日志:
```bash
tail -f server.log
```

## 🎯 下一步

部署完成后，请提供以下信息以完善上传功能：

1. **服务器信息**
   - 操作系统（Linux/Windows）
   - Python版本
   - 服务器IP或域名

2. **访问方式**
   - 是否需要密码保护
   - 访问端口
   - 是否使用域名

3. **更新方式**
   - 使用FTP/SFTP上传
   - 使用Web上传界面
   - 使用命令行

提供这些信息后，我会创建更完善的上传脚本。

---

最后更新：2026-01-31
