# 🚀 详细部署指引

## 📋 部署信息

- **服务器IP**: 139.227.233.75
- **域名**: blitzepanda.top
- **访问地址**: http://blitzepanda.top/approvalquery
- **部署方式**: GitHub + FinalShell
- **管理工具**: FinalShell

---

## 🎯 部署步骤总览

1. [准备GitHub仓库](#步骤1-准备github仓库)
2. [配置服务器环境](#步骤2-配置服务器环境)
3. [部署应用](#步骤3-部署应用)
4. [配置Nginx反向代理](#步骤4-配置nginx反向代理)
5. [配置域名](#步骤5-配置域名)
6. [设置开机自启](#步骤6-设置开机自启)
7. [日常维护](#步骤7-日常维护)

---

## 步骤1: 准备GitHub仓库

### 1.1 创建GitHub仓库

1. 登录 GitHub
2. 点击右上角 `+` → `New repository`
3. 仓库名称: `approval-viewer` (或其他名称)
4. 设置为 `Private` (推荐，因为包含业务数据)
5. 点击 `Create repository`

### 1.2 上传代码到GitHub

在本地项目目录打开命令行：

```bash
# 进入项目目录
cd temp_view

# 初始化Git仓库
git init

# 创建 .gitignore 文件
echo "*.log
*.pyc
__pycache__/
.DS_Store
*_backup_*.xlsx
server.log" > .gitignore

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: Approval viewer system"

# 关联远程仓库（替换为你的仓库地址）
git remote add origin https://github.com/你的用户名/approval-viewer.git

# 推送到GitHub
git branch -M main
git push -u origin main
```

---

## 步骤2: 配置服务器环境

### 2.1 使用FinalShell连接服务器

1. 打开 FinalShell
2. 点击 `连接` → `SSH连接(Linux)`
3. 填写信息：
   - 名称: `BlitzePanda服务器`
   - 主机: `139.227.233.75`
   - 端口: `22` (默认)
   - 用户名: `root` (或你的用户名)
   - 密码: (你的服务器密码)
4. 点击 `确定` 并连接

### 2.2 安装必要软件

连接成功后，在终端执行：

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装Python3和pip
sudo apt install python3 python3-pip -y

# 安装Git
sudo apt install git -y

# 安装Nginx
sudo apt install nginx -y

# 验证安装
python3 --version
pip3 --version
git --version
nginx -v
```

### 2.3 创建项目目录

```bash
# 创建项目目录
sudo mkdir -p /var/www/approval-viewer
sudo chown -R $USER:$USER /var/www/approval-viewer
cd /var/www/approval-viewer
```

---

## 步骤3: 部署应用

### 3.1 从GitHub克隆代码

```bash
# 克隆仓库（替换为你的仓库地址）
git clone https://github.com/你的用户名/approval-viewer.git .

# 如果是私有仓库，需要输入GitHub用户名和密码
# 或者使用Personal Access Token
```

### 3.2 安装Python依赖

```bash
# 安装依赖
pip3 install -r requirements.txt

# 或使用国内镜像加速
pip3 install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### 3.3 生成初始数据

```bash
# 确保Excel文件存在
ls -lh 线上建店审批.xlsx

# 生成数据
python3 parse_excel.py
```

### 3.4 测试应用

```bash
# 测试运行（前台）
python3 deploy_server.py

# 在浏览器访问: http://139.227.233.75:8080
# 如果能访问，说明应用正常，按 Ctrl+C 停止
```

---

## 步骤4: 配置Nginx反向代理

### 4.1 创建Nginx配置文件

```bash
# 创建配置文件
sudo nano /etc/nginx/sites-available/approval-viewer
```

### 4.2 粘贴以下配置

```nginx
server {
    listen 80;
    server_name blitzepanda.top www.blitzepanda.top;

    # 审批查询系统
    location /approvalquery {
        alias /var/www/approval-viewer;
        index index.html;
        
        # 处理静态文件
        location ~* \.(html|css|js|json|xlsx)$ {
            alias /var/www/approval-viewer;
            expires 1h;
            add_header Cache-Control "public, must-revalidate";
        }
        
        # 如果需要代理到Python服务器（可选）
        # location /approvalquery/api {
        #     proxy_pass http://127.0.0.1:8080;
        #     proxy_set_header Host $host;
        #     proxy_set_header X-Real-IP $remote_addr;
        #     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # }
    }

    # 其他路径可以配置其他服务
    location / {
        root /var/www/html;
        index index.html index.htm;
    }
}
```

**注意**: 由于我们的应用是纯静态的（HTML+JSON），不需要Python服务器一直运行。Nginx直接提供静态文件即可。

### 4.3 启用配置

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/approval-viewer /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 如果显示 "syntax is ok" 和 "test is successful"，则重启Nginx
sudo systemctl restart nginx

# 设置Nginx开机自启
sudo systemctl enable nginx
```

### 4.4 配置防火墙

```bash
# 允许HTTP和HTTPS
sudo ufw allow 'Nginx Full'

# 或者单独允许端口
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 查看状态
sudo ufw status
```

---

## 步骤5: 配置域名

### 5.1 配置DNS解析

1. 登录你的域名注册商（购买 blitzepanda.top 的地方）
2. 进入DNS管理
3. 添加A记录：
   - 主机记录: `@`
   - 记录类型: `A`
   - 记录值: `139.227.233.75`
   - TTL: `600` (10分钟)
4. 添加www记录（可选）：
   - 主机记录: `www`
   - 记录类型: `A`
   - 记录值: `139.227.233.75`
   - TTL: `600`

### 5.2 等待DNS生效

```bash
# 测试DNS解析（在本地电脑执行）
ping blitzepanda.top

# 或使用在线工具
# https://www.whatsmydns.net/
```

DNS通常需要10分钟到24小时生效。

### 5.3 测试访问

在浏览器访问：
- http://blitzepanda.top/approvalquery

---

## 步骤6: 设置开机自启

由于我们使用Nginx直接提供静态文件，不需要Python服务器一直运行。

但如果将来需要动态功能，可以配置systemd服务：

### 6.1 创建systemd服务文件（可选）

```bash
sudo nano /etc/systemd/system/approval-viewer.service
```

### 6.2 粘贴以下内容

```ini
[Unit]
Description=Approval Progress Viewer
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/approval-viewer
ExecStart=/usr/bin/python3 /var/www/approval-viewer/deploy_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 6.3 启用服务

```bash
# 重载systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start approval-viewer

# 设置开机自启
sudo systemctl enable approval-viewer

# 查看状态
sudo systemctl status approval-viewer
```

---

## 步骤7: 日常维护

### 7.1 更新数据（使用FinalShell）

#### 方法1: 使用FinalShell的SFTP功能

1. 在FinalShell中，连接到服务器
2. 点击顶部的 `SFTP` 标签
3. 导航到 `/var/www/approval-viewer/`
4. 将新的Excel文件拖拽上传
5. 在终端执行：

```bash
cd /var/www/approval-viewer
python3 update_excel.py 新文件名.xlsx
```

#### 方法2: 使用命令行

```bash
# SSH连接到服务器
cd /var/www/approval-viewer

# 如果文件已上传到服务器某个位置
python3 update_excel.py /path/to/新文件.xlsx

# 或者直接替换文件
cp 新文件.xlsx 线上建店审批.xlsx
python3 parse_excel.py
```

#### 方法3: 使用GitHub同步（推荐）

在本地更新数据后：

```bash
# 本地
cd temp_view
python3 parse_excel.py
git add .
git commit -m "Update data: $(date +%Y-%m-%d)"
git push
```

在服务器上：

```bash
# 服务器
cd /var/www/approval-viewer
git pull
```

### 7.2 查看日志

```bash
# Nginx访问日志
sudo tail -f /var/log/nginx/access.log

# Nginx错误日志
sudo tail -f /var/log/nginx/error.log

# 应用日志（如果使用systemd）
sudo journalctl -u approval-viewer -f
```

### 7.3 重启服务

```bash
# 重启Nginx
sudo systemctl restart nginx

# 重启应用（如果使用systemd）
sudo systemctl restart approval-viewer
```

### 7.4 清理备份文件

```bash
cd /var/www/approval-viewer

# 查看备份文件
ls -lh *_backup_*.xlsx

# 删除7天前的备份
find . -name "*_backup_*.xlsx" -mtime +7 -delete
```

---

## 🔒 安全加固（可选但推荐）

### 1. 配置HTTPS（免费SSL证书）

```bash
# 安装Certbot
sudo apt install certbot python3-certbot-nginx -y

# 获取SSL证书
sudo certbot --nginx -d blitzepanda.top -d www.blitzepanda.top

# 自动续期测试
sudo certbot renew --dry-run
```

### 2. 添加密码保护

编辑Nginx配置：

```bash
sudo nano /etc/nginx/sites-available/approval-viewer
```

在 `location /approvalquery` 块中添加：

```nginx
location /approvalquery {
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    alias /var/www/approval-viewer;
    index index.html;
}
```

创建密码文件：

```bash
# 安装工具
sudo apt install apache2-utils -y

# 创建用户（替换username为你的用户名）
sudo htpasswd -c /etc/nginx/.htpasswd username

# 重启Nginx
sudo systemctl restart nginx
```

### 3. 限制IP访问（可选）

如果只想内网访问，在Nginx配置中添加：

```nginx
location /approvalquery {
    allow 192.168.1.0/24;  # 允许的IP段
    allow 你的办公室IP;
    deny all;
    
    alias /var/www/approval-viewer;
    index index.html;
}
```

---

## 📝 快速命令参考

### 连接服务器
```bash
ssh root@139.227.233.75
```

### 进入项目目录
```bash
cd /var/www/approval-viewer
```

### 更新数据
```bash
python3 update_excel.py 新文件.xlsx
```

### 从GitHub更新代码
```bash
git pull
```

### 重启Nginx
```bash
sudo systemctl restart nginx
```

### 查看日志
```bash
sudo tail -f /var/log/nginx/access.log
```

---

## ❓ 常见问题

### Q1: 访问显示403 Forbidden

**解决方案**:
```bash
# 检查文件权限
ls -la /var/www/approval-viewer/

# 修改权限
sudo chown -R www-data:www-data /var/www/approval-viewer
sudo chmod -R 755 /var/www/approval-viewer
```

### Q2: 访问显示404 Not Found

**解决方案**:
```bash
# 检查Nginx配置
sudo nginx -t

# 检查文件是否存在
ls -la /var/www/approval-viewer/index.html

# 重启Nginx
sudo systemctl restart nginx
```

### Q3: 数据不更新

**解决方案**:
```bash
# 检查JSON文件时间
ls -lh /var/www/approval-viewer/approval_data.json

# 手动重新生成
cd /var/www/approval-viewer
python3 parse_excel.py

# 清除浏览器缓存，强制刷新（Ctrl+F5）
```

### Q4: 域名无法访问

**解决方案**:
```bash
# 检查DNS解析
ping blitzepanda.top

# 检查Nginx是否运行
sudo systemctl status nginx

# 检查防火墙
sudo ufw status
```

### Q5: 上传文件失败

**解决方案**:
```bash
# 检查磁盘空间
df -h

# 检查目录权限
ls -la /var/www/approval-viewer/
```

---

## 🎯 部署检查清单

- [ ] GitHub仓库已创建并上传代码
- [ ] 服务器已安装Python3、Git、Nginx
- [ ] 代码已克隆到 `/var/www/approval-viewer`
- [ ] Python依赖已安装
- [ ] 初始数据已生成
- [ ] Nginx配置已创建并启用
- [ ] 防火墙已开放80端口
- [ ] DNS已配置A记录指向服务器IP
- [ ] 可以通过域名访问: http://blitzepanda.top/approvalquery
- [ ] 数据更新流程已测试
- [ ] （可选）HTTPS已配置
- [ ] （可选）密码保护已启用

---

## 📞 需要帮助？

如果遇到问题，请提供：
1. 错误信息截图
2. Nginx错误日志: `sudo tail -50 /var/log/nginx/error.log`
3. 浏览器控制台错误（F12）
4. 执行的命令和输出

---

**部署文档版本**: 1.0  
**最后更新**: 2026-01-31  
**目标域名**: blitzepanda.top/approvalquery
