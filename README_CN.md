# 🚀 审批系统部署 - 快速指引

## 📋 基本信息

- **服务器**: 139.227.233.75
- **域名**: blitzepanda.top
- **访问地址**: http://blitzepanda.top/approvalquery
- **管理工具**: FinalShell

---

## ⚡ 快速部署（首次）

### 1. 连接服务器（FinalShell）
```
主机: 139.227.233.75
端口: 22
用户: root
```

### 2. 上传文件（SFTP）
上传整个 `temp_view` 文件夹到服务器 `/root/`

### 3. 运行安装脚本
```bash
cd /root/temp_view
chmod +x install.sh
./install.sh
```

### 4. 配置域名DNS
在域名注册商添加A记录:
```
@ → 139.227.233.75
```

### 5. 访问测试
http://blitzepanda.top/approvalquery

---

## 📊 每日更新数据

### 方法1: 使用更新脚本（推荐）

1. 用FinalShell的SFTP上传新Excel到服务器
2. 运行更新脚本:
```bash
cd /var/www/approval-viewer
./daily_update.sh /root/新文件.xlsx
```

### 方法2: 手动更新

```bash
cd /var/www/approval-viewer
python3 update_excel.py 新文件.xlsx
```

---

## 📚 详细文档

- **新手指引**: [FINALSHELL_GUIDE.md](FINALSHELL_GUIDE.md) ⭐推荐
- **完整部署**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **5分钟部署**: [QUICK_START.md](QUICK_START.md)

---

## 🔧 常用命令

```bash
# 进入项目
cd /var/www/approval-viewer

# 更新数据
python3 update_excel.py 新文件.xlsx

# 重启Nginx
sudo systemctl restart nginx

# 查看日志
sudo tail -f /var/log/nginx/access.log
```

---

## 🔒 可选优化

### 启用HTTPS
```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d blitzepanda.top
```

### 添加密码保护
```bash
sudo apt install apache2-utils -y
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

然后修改Nginx配置添加:
```nginx
auth_basic "请输入密码";
auth_basic_user_file /etc/nginx/.htpasswd;
```

---

## ❓ 遇到问题？

1. 查看 [FINALSHELL_GUIDE.md](FINALSHELL_GUIDE.md) 的常见问题部分
2. 检查Nginx日志: `sudo tail -50 /var/log/nginx/error.log`
3. 确认文件权限: `ls -la /var/www/approval-viewer/`

---

## 📞 技术支持

提供以下信息以便诊断:
```bash
cd /var/www/approval-viewer
echo "=== 系统信息 ===" && uname -a
echo "=== Python版本 ===" && python3 --version
echo "=== Nginx状态 ===" && sudo systemctl status nginx
echo "=== 项目文件 ===" && ls -la
echo "=== 最近错误 ===" && sudo tail -20 /var/log/nginx/error.log
```

---

**版本**: 1.0  
**更新**: 2026-01-31
