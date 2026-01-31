# 🎯 从这里开始

## 欢迎！

这是审批进度可视化系统的部署包。

---

## 📋 你的部署信息

- **服务器IP**: 139.227.233.75
- **域名**: blitzepanda.top
- **访问地址**: http://blitzepanda.top/approvalquery
- **管理工具**: FinalShell

---

## ⚡ 3步快速部署

### 1️⃣ 上传文件
用FinalShell的SFTP功能，将整个 `temp_view` 文件夹上传到服务器 `/root/`

### 2️⃣ 运行安装
在FinalShell终端执行:
```bash
cd /root/temp_view
chmod +x install.sh
./install.sh
```

### 3️⃣ 配置域名
在域名注册商添加A记录: `@ → 139.227.233.75`

**完成！** 访问 http://blitzepanda.top/approvalquery

---

## 📚 详细文档

### 🌟 推荐阅读（按顺序）

1. **[FINALSHELL_GUIDE.md](FINALSHELL_GUIDE.md)** ⭐⭐⭐
   - 图文并茂的FinalShell操作指引
   - 适合新手，包含每一步截图说明
   - 包含常见问题解答

2. **[部署检查清单.md](部署检查清单.md)** ⭐⭐
   - 逐项检查部署进度
   - 确保不遗漏任何步骤
   - 包含故障排查

3. **[QUICK_START.md](QUICK_START.md)** ⭐
   - 5分钟快速部署
   - 精简版命令
   - 适合有经验的用户

### 📖 参考文档

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - 完整详细的部署文档
- **[README_CN.md](README_CN.md)** - 中文快速参考
- **[README_DEPLOY.md](README_DEPLOY.md)** - 技术部署文档

---

## 📊 每日更新数据（5分钟）

### 最简单的方法

1. 用FinalShell连接服务器
2. 切换到SFTP标签
3. 上传新Excel到 `/var/www/approval-viewer/`
4. 切换到终端标签
5. 执行:
```bash
cd /var/www/approval-viewer
./daily_update.sh 新文件.xlsx
```
6. 刷新浏览器（Ctrl+F5）

详细说明见 [FINALSHELL_GUIDE.md](FINALSHELL_GUIDE.md) 第二部分。

---

## 🔧 常用命令

```bash
# 进入项目
cd /var/www/approval-viewer

# 更新数据
./daily_update.sh 新文件.xlsx

# 重启Nginx
sudo systemctl restart nginx

# 查看日志
sudo tail -f /var/log/nginx/access.log
```

---

## 🔒 可选优化

### 启用HTTPS（推荐）
```bash
sudo certbot --nginx -d blitzepanda.top
```

### 添加密码保护
```bash
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

详细步骤见 [FINALSHELL_GUIDE.md](FINALSHELL_GUIDE.md) 第四、五部分。

---

## ❓ 遇到问题？

1. 查看 **[FINALSHELL_GUIDE.md](FINALSHELL_GUIDE.md)** 的常见问题部分
2. 查看 **[部署检查清单.md](部署检查清单.md)** 的故障排查部分
3. 运行诊断命令收集信息

---

## 📞 需要帮助？

运行诊断命令:
```bash
cd /var/www/approval-viewer
echo "=== 系统信息 ===" && uname -a
echo "=== Python版本 ===" && python3 --version
echo "=== Nginx状态 ===" && sudo systemctl status nginx
echo "=== 项目文件 ===" && ls -la
echo "=== 最近错误 ===" && sudo tail -20 /var/log/nginx/error.log
```

将输出结果发给技术支持。

---

## 📦 项目文件说明

### 核心文件（必需）
- `index.html` - 前端页面
- `parse_excel.py` - 数据解析脚本
- `update_excel.py` - 数据更新脚本
- `requirements.txt` - Python依赖
- `线上建店审批.xlsx` - Excel数据源

### 部署脚本
- `install.sh` - 一键安装脚本 ⭐
- `daily_update.sh` - 每日更新脚本 ⭐
- `deploy.sh` - 通用部署脚本
- `deploy_server.py` - Python服务器（可选）

### 文档（推荐阅读）
- `START_HERE.md` - 本文件 ⭐
- `FINALSHELL_GUIDE.md` - FinalShell操作指引 ⭐⭐⭐
- `部署检查清单.md` - 部署检查清单 ⭐⭐
- `QUICK_START.md` - 快速开始
- `DEPLOYMENT_GUIDE.md` - 完整部署指南
- `README_CN.md` - 中文快速参考
- `README_DEPLOY.md` - 技术文档

### 其他文件
- `.gitignore` - Git忽略文件
- `approval_data.json` - 生成的数据（自动）

---

## ✅ 部署成功标志

- [ ] 可以访问 http://blitzepanda.top/approvalquery
- [ ] 看到审批系统页面
- [ ] 数据显示正常
- [ ] 筛选和搜索功能正常
- [ ] 已测试数据更新流程

---

## 🎉 开始部署吧！

1. 打开 **[FINALSHELL_GUIDE.md](FINALSHELL_GUIDE.md)**
2. 按照步骤操作
3. 遇到问题查看常见问题部分

**预计时间**: 30分钟（首次部署）

**每日维护**: 5分钟（更新数据）

---

**祝部署顺利！** 🚀

如有问题，随时查看文档或寻求帮助。

---

**版本**: 1.0  
**更新**: 2026-01-31  
**目标**: blitzepanda.top/approvalquery
