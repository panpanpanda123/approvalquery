# 🔧 nginx配置整理指南

## 😵 你的问题

你有4个项目，但nginx配置乱了：
- 前3个项目用 `default` 配置
- `approvalquery` 单独搞了一个配置
- 现在不知道哪个配置在起作用

## 🎯 解决方案

### 方案一：一键自动整理（推荐）⭐

**直接运行这个命令：**

```bash
cd /var/www/approval-viewer/approvalquery
bash 一键整理nginx.sh
```

**这个脚本会自动：**
1. ✅ 备份现有配置（安全）
2. ✅ 检测所有项目位置
3. ✅ 生成统一的配置
4. ✅ 删除冲突配置
5. ✅ 重启nginx
6. ✅ 测试所有项目是否能访问

**整理后的结构：**
- 所有4个项目都在一个 `default` 配置里
- 配置清晰，易于管理
- 不会有冲突

---

### 方案二：先查看再决定

**1. 查看当前配置状态：**

```bash
bash 查看当前配置.sh
```

会显示：
- 有哪些配置文件
- 哪些配置已启用
- 每个项目的访问状态
- 是否有冲突

**2. 诊断详细信息：**

```bash
bash nginx配置诊断.sh
```

会显示：
- 完整的配置文件内容
- 项目目录结构
- 访问测试结果

**3. 确认后再整理：**

```bash
bash 一键整理nginx.sh
```

---

## 📋 整理后的配置示例

整理后，你的 `/etc/nginx/sites-available/default` 会变成这样：

```nginx
server {
    listen 80 default_server;
    server_name blitzepanda.top;

    # approvalquery 项目
    location /approvalquery {
        alias /var/www/approval-viewer/approvalquery;
        index index.html;
        try_files $uri $uri/ /approvalquery/index.html;
    }

    # kart 项目
    location /kart {
        alias /var/www/kart;
        index index.html;
        try_files $uri $uri/ /kart/index.html;
    }

    # wuliu 项目
    location /wuliu {
        alias /var/www/wuliu;
        index index.html;
        try_files $uri $uri/ /wuliu/index.html;
    }

    # weeklycheck 项目
    location /weeklycheck {
        alias /var/www/weeklycheck;
        index index.html;
        try_files $uri $uri/ /weeklycheck/index.html;
    }

    location / {
        return 404;
    }
}
```

**优点：**
- ✅ 所有项目在一个文件里
- ✅ 一目了然
- ✅ 修改方便
- ✅ 不会冲突

---

## 🧪 验证整理结果

整理完成后，测试所有项目：

```bash
# 测试访问
curl -I http://localhost/approvalquery/
curl -I http://localhost/kart/
curl -I http://localhost/wuliu/
curl -I http://localhost/weeklycheck/

# 应该都返回 HTTP/1.1 200 OK
```

浏览器访问：
- http://blitzepanda.top/approvalquery
- http://blitzepanda.top/kart
- http://blitzepanda.top/wuliu
- http://blitzepanda.top/weeklycheck

---

## 🔙 如果出问题怎么办？

**不用担心！脚本会自动备份。**

备份位置：`/root/nginx_backup_日期时间/`

**恢复备份：**

```bash
# 找到备份目录
ls -lt /root/nginx_backup_*

# 恢复配置（替换日期时间）
cp /root/nginx_backup_20260131_123456/sites-available/default /etc/nginx/sites-available/
cp /root/nginx_backup_20260131_123456/sites-available/approval-viewer /etc/nginx/sites-available/

# 重启nginx
sudo systemctl reload nginx
```

---

## 📞 常见问题

### Q1: 整理后某个项目访问不了？

**检查项目路径是否正确：**

```bash
# 检查文件是否存在
ls -lh /var/www/approval-viewer/approvalquery/index.html
ls -lh /var/www/kart/index.html
ls -lh /var/www/wuliu/index.html
ls -lh /var/www/weeklycheck/index.html
```

### Q2: 提示权限错误？

**设置正确的权限：**

```bash
sudo chown -R www-data:www-data /var/www/
sudo chmod -R 755 /var/www/
```

### Q3: nginx配置测试失败？

**查看错误信息：**

```bash
sudo nginx -t
```

根据错误提示修改配置。

---

## 🎯 推荐操作流程

**最安全的操作顺序：**

1. **先查看现状**
   ```bash
   bash 查看当前配置.sh
   ```

2. **运行整理脚本**
   ```bash
   bash 一键整理nginx.sh
   ```

3. **测试所有项目**
   ```bash
   # 在浏览器中访问所有4个项目
   # 按 Ctrl+F5 强制刷新
   ```

4. **如果有问题，查看备份位置**
   ```bash
   ls -lt /root/nginx_backup_*
   ```

---

## ✅ 整理完成后的好处

- 🎯 配置集中，一个文件管理所有项目
- 🔍 问题排查更容易
- 📝 添加新项目只需加几行配置
- 🚀 不会有配置冲突
- 💾 自动备份，安全可靠

---

## 🚀 快速开始

**只需要一行命令：**

```bash
cd /var/www/approval-viewer/approvalquery && bash 一键整理nginx.sh
```

搞定！🎉
