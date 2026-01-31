# ⚡ 快速开始 - 5分钟部署

## 📋 前提条件

- 服务器: 139.227.233.75
- 域名: blitzepanda.top
- 工具: FinalShell
- GitHub账号

---

## 🚀 5步部署

### 1️⃣ 上传到GitHub（本地电脑）

```bash
cd temp_view
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/你的用户名/approval-viewer.git
git push -u origin main
```

### 2️⃣ 连接服务器（FinalShell）

- 主机: 139.227.233.75
- 端口: 22
- 用户名: root
- 密码: (你的密码)

### 3️⃣ 安装环境（服务器终端）

```bash
# 一键安装
sudo apt update && sudo apt install -y python3 python3-pip git nginx

# 创建目录
sudo mkdir -p /var/www/approval-viewer
sudo chown -R $USER:$USER /var/www/approval-viewer
```

### 4️⃣ 部署应用（服务器终端）

```bash
# 克隆代码
cd /var/www/approval-viewer
git clone https://github.com/你的用户名/approval-viewer.git .

# 安装依赖
pip3 install -r requirements.txt

# 生成数据
python3 parse_excel.py
```

### 5️⃣ 配置Nginx（服务器终端）

```bash
# 创建配置
sudo tee /etc/nginx/sites-available/approval-viewer > /dev/null <<'EOF'
server {
    listen 80;
    server_name blitzepanda.top www.blitzepanda.top;

    location /approvalquery {
        alias /var/www/approval-viewer;
        index index.html;
        try_files $uri $uri/ =404;
    }

    location / {
        root /var/www/html;
        index index.html;
    }
}
EOF

# 启用配置
sudo ln -s /etc/nginx/sites-available/approval-viewer /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

# 开放端口
sudo ufw allow 80/tcp
```

---

## 🌐 配置域名

1. 登录域名注册商
2. 添加A记录:
   - 主机记录: `@`
   - 记录值: `139.227.233.75`
3. 等待5-10分钟

---

## ✅ 测试访问

浏览器打开: **http://blitzepanda.top/approvalquery**

---

## 📊 更新数据

### 方法1: FinalShell上传

1. 连接服务器
2. 点击SFTP标签
3. 上传新Excel到 `/var/www/approval-viewer/`
4. 终端执行:
```bash
cd /var/www/approval-viewer
python3 update_excel.py 新文件.xlsx
```

### 方法2: GitHub同步

本地:
```bash
cd temp_view
python3 parse_excel.py
git add .
git commit -m "Update data"
git push
```

服务器:
```bash
cd /var/www/approval-viewer
git pull
```

---

## 🔒 启用HTTPS（可选）

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d blitzepanda.top -d www.blitzepanda.top
```

---

## 📝 常用命令

```bash
# 进入项目
cd /var/www/approval-viewer

# 更新数据
python3 update_excel.py 新文件.xlsx

# 从GitHub更新
git pull

# 重启Nginx
sudo systemctl restart nginx

# 查看日志
sudo tail -f /var/log/nginx/access.log
```

---

## ❓ 遇到问题？

查看详细文档: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

**完成！** 🎉
