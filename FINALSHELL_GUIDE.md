# 📱 FinalShell 操作指引

## 🎯 目标

使用FinalShell将审批系统部署到服务器，并实现每日数据更新。

---

## 第一部分: 初次部署（只需做一次）

### 步骤1: 连接服务器

1. **打开FinalShell**

2. **创建新连接**
   - 点击顶部 `连接` → `SSH连接(Linux)`
   - 或点击左侧 `+` 号

3. **填写连接信息**
   ```
   名称: BlitzePanda服务器
   主机: 139.227.233.75
   端口: 22
   认证方式: 密码
   用户名: root
   密码: (你的服务器密码)
   ```

4. **保存并连接**
   - 点击 `确定`
   - 双击连接名称
   - 首次连接会提示接受密钥，点击 `接受并保存`

### 步骤2: 安装环境（复制粘贴命令）

连接成功后，在下方终端窗口依次执行：

```bash
# 1. 更新系统（等待完成，可能需要1-2分钟）
sudo apt update && sudo apt upgrade -y
```

```bash
# 2. 安装必要软件（等待完成）
sudo apt install python3 python3-pip git nginx -y
```

```bash
# 3. 验证安装
python3 --version
nginx -v
```

看到版本号说明安装成功。

### 步骤3: 创建项目目录

```bash
# 创建目录
sudo mkdir -p /var/www/approval-viewer
sudo chown -R $USER:$USER /var/www/approval-viewer
cd /var/www/approval-viewer
```

### 步骤4: 上传项目文件

#### 方法A: 使用FinalShell的SFTP（推荐，简单）

1. **切换到SFTP标签**
   - 在FinalShell窗口顶部，点击 `SFTP` 标签
   - 会看到左右两个窗口：左边是本地，右边是服务器

2. **导航到服务器目录**
   - 在右侧（服务器）窗口，输入路径: `/var/www/approval-viewer`
   - 按回车

3. **上传文件**
   - 在左侧（本地）窗口，找到你的 `temp_view` 文件夹
   - 选中以下文件（按住Ctrl多选）：
     - index.html
     - parse_excel.py
     - deploy_server.py
     - update_excel.py
     - requirements.txt
     - 线上建店审批.xlsx
   - 右键 → `上传` 或直接拖拽到右侧窗口

4. **等待上传完成**
   - 底部会显示上传进度

#### 方法B: 使用GitHub（适合团队协作）

如果你已经把代码上传到GitHub：

```bash
# 在终端执行
cd /var/www/approval-viewer
git clone https://github.com/你的用户名/approval-viewer.git .
```

### 步骤5: 安装Python依赖

切换回 `终端` 标签，执行：

```bash
cd /var/www/approval-viewer
pip3 install -r requirements.txt
```

### 步骤6: 生成初始数据

```bash
python3 parse_excel.py
```

看到 "✅ 数据解析完成！" 说明成功。

### 步骤7: 配置Nginx

#### 7.1 创建配置文件

```bash
sudo nano /etc/nginx/sites-available/approval-viewer
```

#### 7.2 粘贴配置

在打开的编辑器中，粘贴以下内容：

```nginx
server {
    listen 80;
    server_name blitzepanda.top www.blitzepanda.top;

    location /approvalquery {
        alias /var/www/approval-viewer;
        index index.html;
        
        location ~* \.(html|css|js|json|xlsx)$ {
            alias /var/www/approval-viewer;
            expires 1h;
            add_header Cache-Control "public, must-revalidate";
        }
    }

    location / {
        root /var/www/html;
        index index.html index.htm;
    }
}
```

#### 7.3 保存并退出

- 按 `Ctrl + O` (保存)
- 按 `Enter` (确认)
- 按 `Ctrl + X` (退出)

#### 7.4 启用配置

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/approval-viewer /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx
```

#### 7.5 开放防火墙

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 步骤8: 配置域名DNS

1. **登录域名注册商**（购买 blitzepanda.top 的网站）

2. **进入DNS管理**

3. **添加A记录**
   ```
   主机记录: @
   记录类型: A
   记录值: 139.227.233.75
   TTL: 600
   ```

4. **添加www记录**（可选）
   ```
   主机记录: www
   记录类型: A
   记录值: 139.227.233.75
   TTL: 600
   ```

5. **等待生效**（10分钟到24小时）

### 步骤9: 测试访问

在浏览器打开: **http://blitzepanda.top/approvalquery**

看到审批系统页面说明部署成功！🎉

---

## 第二部分: 每日更新数据（重复操作）

### 方法1: FinalShell SFTP上传（最简单）

1. **下载最新Excel**
   - 从企微下载最新的审批Excel文件
   - 保存到本地，例如: `新审批数据-2026-01-31.xlsx`

2. **打开FinalShell并连接服务器**

3. **切换到SFTP标签**

4. **导航到项目目录**
   - 右侧窗口输入: `/var/www/approval-viewer`

5. **上传新Excel**
   - 在左侧找到新下载的Excel文件
   - 拖拽到右侧窗口上传

6. **切换到终端标签**

7. **执行更新命令**
   ```bash
   cd /var/www/approval-viewer
   python3 update_excel.py 新审批数据-2026-01-31.xlsx
   ```

8. **刷新浏览器**
   - 打开 http://blitzepanda.top/approvalquery
   - 按 `Ctrl + F5` 强制刷新
   - 查看最新数据

### 方法2: 直接替换文件（更快）

1. **上传新Excel**（同上）

2. **重命名为标准文件名**
   ```bash
   cd /var/www/approval-viewer
   mv 新审批数据-2026-01-31.xlsx 线上建店审批.xlsx
   ```

3. **重新生成数据**
   ```bash
   python3 parse_excel.py
   ```

4. **刷新浏览器查看**

### 方法3: 使用GitHub同步（适合团队）

**本地电脑操作**:
```bash
cd temp_view
# 替换Excel文件
python3 parse_excel.py
git add .
git commit -m "Update data: 2026-01-31"
git push
```

**服务器操作**（在FinalShell终端）:
```bash
cd /var/www/approval-viewer
git pull
```

---

## 第三部分: 常用操作

### 查看当前数据状态

```bash
cd /var/www/approval-viewer
ls -lh approval_data.json
```

查看文件修改时间，确认是否是最新的。

### 查看访问日志

```bash
sudo tail -f /var/log/nginx/access.log
```

可以看到谁在什么时间访问了系统。

### 重启Nginx

```bash
sudo systemctl restart nginx
```

### 清理旧备份文件

```bash
cd /var/www/approval-viewer
ls -lh *_backup_*.xlsx
# 删除7天前的备份
find . -name "*_backup_*.xlsx" -mtime +7 -delete
```

### 查看磁盘空间

```bash
df -h
```

---

## 第四部分: 启用HTTPS（可选但推荐）

### 安装SSL证书（免费）

```bash
# 安装Certbot
sudo apt install certbot python3-certbot-nginx -y

# 获取证书
sudo certbot --nginx -d blitzepanda.top -d www.blitzepanda.top
```

按提示操作：
1. 输入邮箱
2. 同意服务条款（输入 Y）
3. 选择是否重定向HTTP到HTTPS（推荐选择 2）

完成后，访问地址变为: **https://blitzepanda.top/approvalquery**

---

## 第五部分: 添加密码保护（可选）

### 创建密码

```bash
# 安装工具
sudo apt install apache2-utils -y

# 创建用户和密码
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

输入两次密码。

### 修改Nginx配置

```bash
sudo nano /etc/nginx/sites-available/approval-viewer
```

在 `location /approvalquery` 块中添加：

```nginx
location /approvalquery {
    auth_basic "请输入密码访问";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    alias /var/www/approval-viewer;
    index index.html;
}
```

保存并重启：

```bash
sudo systemctl restart nginx
```

现在访问需要输入用户名（admin）和密码。

---

## 📋 快速命令速查表

| 操作 | 命令 |
|------|------|
| 连接服务器 | 在FinalShell双击连接 |
| 进入项目目录 | `cd /var/www/approval-viewer` |
| 更新数据 | `python3 update_excel.py 新文件.xlsx` |
| 重新生成数据 | `python3 parse_excel.py` |
| 重启Nginx | `sudo systemctl restart nginx` |
| 查看日志 | `sudo tail -f /var/log/nginx/access.log` |
| 查看文件 | `ls -lh` |
| 清理备份 | `find . -name "*_backup_*.xlsx" -mtime +7 -delete` |

---

## ❓ 常见问题

### Q: 上传文件后找不到？

**A**: 检查上传路径是否正确
```bash
cd /var/www/approval-viewer
ls -la
```

### Q: 权限不足？

**A**: 修改文件权限
```bash
sudo chown -R www-data:www-data /var/www/approval-viewer
sudo chmod -R 755 /var/www/approval-viewer
```

### Q: 浏览器显示旧数据？

**A**: 清除浏览器缓存
- 按 `Ctrl + Shift + Delete`
- 或按 `Ctrl + F5` 强制刷新

### Q: 域名无法访问？

**A**: 检查DNS是否生效
```bash
ping blitzepanda.top
```

### Q: FinalShell连接失败？

**A**: 检查：
1. 服务器IP是否正确
2. 端口是否是22
3. 用户名密码是否正确
4. 服务器防火墙是否允许SSH

---

## 🎯 每日维护流程（5分钟）

1. ✅ 从企微下载最新Excel
2. ✅ 打开FinalShell连接服务器
3. ✅ 切换到SFTP标签
4. ✅ 上传Excel到 `/var/www/approval-viewer`
5. ✅ 切换到终端标签
6. ✅ 执行: `cd /var/www/approval-viewer && python3 update_excel.py 新文件.xlsx`
7. ✅ 刷新浏览器查看

---

## 📞 需要帮助？

遇到问题时，在FinalShell终端执行：

```bash
# 收集诊断信息
echo "=== 系统信息 ===" && uname -a
echo "=== Python版本 ===" && python3 --version
echo "=== Nginx状态 ===" && sudo systemctl status nginx
echo "=== 项目文件 ===" && ls -la /var/www/approval-viewer/
echo "=== 最近错误 ===" && sudo tail -20 /var/log/nginx/error.log
```

将输出结果截图发给技术支持。

---

**FinalShell操作指引版本**: 1.0  
**适用于**: Windows/Mac/Linux  
**最后更新**: 2026-01-31
