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

#### 方法1：简易更新（推荐）⭐

1. 把新Excel改名为 `线上建店审批.xlsx`
2. 双击 `简易更新.bat`

#### 方法2：GitHub同步

```bash
# 本地
git add .
git commit -m "更新"
git push

# 服务器
ssh root@139.224.200.133
cd /var/www/approval-viewer/approvalquery
bash 服务器一键更新.sh
```

#### 方法3：完整部署

```bash
# 一键完成所有操作
双击 一键部署到服务器.bat
```

## 📁 文件说明

### 核心文件
- `index.html` - 前端页面
- `parse_excel.py` - Excel数据解析脚本
- `approval_data.json` - 生成的JSON数据
- `线上建店审批.xlsx` - 源Excel文件

### 配置管理
- `approver_config.json` - 审批人员配置
- `manage_approvers.py` - 审批人员管理工具

### 脚本工具
- `简易更新.bat` - 更新Excel数据 ⭐推荐
- `一键部署到服务器.bat` - 完整部署
- `服务器一键更新.sh` - 服务器端更新
- `一键更新数据.bat` - 灵活更新
- `快速提交.bat` - 快速Git提交

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

系统自动识别并支持两种Excel格式：

### 格式1：企微审批导出（线上建店审批.xlsx）
- 审批单编号、门店编码、门店名称
- 当前审批状态、审批流程
- 9个关键审批节点
- 关键节点完成情况（合同、装修、培训等）

### 格式2：建店进度表（线上建店进度.xlsx）
- 门店号、店铺名称、战区、省份
- 建店单、资料包状态
- 预计开业、实际开业时间
- 当前审批状态、审批流程（可选）

**智能识别：** 脚本会自动检测Excel格式并使用对应的解析逻辑。

## 🔧 审批人员管理

修改审批人员：编辑 `approver_config.json` 或运行 `python manage_approvers.py`

修改后必须重新生成数据：`python parse_excel.py`

## 🔄 更新日志

- 2026-02-24: 财务审批-1更新为李婕，新增审批人员配置管理
- 2026-01-31: 初始版本

## 📞 技术支持

遇到问题请检查：
1. 文件权限是否正确
2. nginx配置是否生效
3. Python依赖是否安装
4. 浏览器控制台错误信息
