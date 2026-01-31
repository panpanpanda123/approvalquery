# 线上建店审批进度可视化

企业微信审批数据可视化系统，用于展示门店审批进度。

## 🚀 快速开始

### 服务器部署

1. **首次部署**
```bash
# 克隆项目
git clone <your-repo-url>
cd approval-viewer

# 安装依赖
pip3 install -r requirements.txt

# 配置nginx
bash 配置nginx多项目.sh

# 生成数据
python3 parse_excel.py
```

2. **访问地址**
- http://blitzepanda.top/approvalquery/
- http://139.224.200.133/approvalquery/

### 更新数据

#### 方法1：Windows一键更新（推荐）

**简易版（最简单）：**
1. 把新Excel改名为 `线上建店审批.xlsx`
2. 放到 `简易更新.bat` 同一目录
3. 双击运行

**完整版（灵活）：**
1. 把新Excel放到 `一键更新数据.bat` 同一目录
2. 双击运行，输入文件名

**首次使用需安装：**
- [Python](https://www.python.org/downloads/)
- [Git for Windows](https://git-scm.com/download/win)

**SSH密钥登录：** 查看 `SSH密钥配置.md`

#### 方法2：服务器端更新

```bash
# 上传Excel到服务器
scp 新审批数据.xlsx root@服务器IP:/var/www/approval-viewer/approvalquery/

# SSH登录服务器
ssh root@服务器IP

# 运行更新脚本
cd /var/www/approval-viewer/approvalquery
bash daily_update.sh 新审批数据.xlsx
```

## 📁 文件说明

### 核心文件
- `index.html` - 前端页面
- `parse_excel.py` - Excel数据解析脚本
- `approval_data.json` - 生成的JSON数据
- `线上建店审批.xlsx` - 源Excel文件

### 脚本工具
- `简易更新.bat` - Windows简易更新（固定文件名）⭐推荐
- `一键更新数据.bat` - Windows灵活更新（任意文件名）
- `检测并配置nginx.sh` - 智能检测并配置nginx多项目
- `daily_update.sh` - 服务器端数据更新脚本
- `修复数据加载.sh` - 数据加载问题修复
- `服务器部署.sh` - 快速部署脚本

### 配置文件
- `requirements.txt` - Python依赖
- `.gitignore` - Git忽略规则

## 🔧 nginx多项目管理

智能检测并配置所有项目：

```bash
bash 检测并配置nginx.sh
```

这个脚本会：
- 自动搜索 /var/www, /opt, /home 目录
- 检测所有项目（approvalquery, kart, wuliu, weeklycheck）
- 生成统一的nginx配置
- 支持域名和IP访问
- 自动备份旧配置

## 🛠️ 故障排查

### 数据加载失败

```bash
cd /var/www/approval-viewer/approvalquery
python3 parse_excel.py
chmod 644 approval_data.json
```

### nginx配置问题

```bash
# 测试配置
sudo nginx -t

# 重启nginx
sudo systemctl reload nginx

# 查看错误日志
sudo tail -50 /var/log/nginx/error.log
```

### 权限问题

```bash
cd /var/www/approval-viewer/approvalquery
sudo chown -R www-data:www-data .
sudo chmod 644 *.json *.html
```

## 📊 数据格式

系统从企业微信审批导出的Excel文件中解析以下信息：
- 审批状态（已通过/审批中/已驳回/已撤销）
- 门店基本信息（名称、编号、城市、加盟商）
- 审批流程（9个关键审批节点）
- 关键节点完成情况（合同、装修、培训等）

## 🔄 更新日志

- 2026-01-31: 初始版本，支持审批进度可视化
- 支持多项目nginx配置管理
- 添加Windows一键更新工具

## 📞 技术支持

遇到问题请检查：
1. 文件权限是否正确
2. nginx配置是否生效
3. Python依赖是否安装
4. 浏览器控制台错误信息
