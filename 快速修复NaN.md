# 快速修复 NaN 问题

## 问题
浏览器报错：`SyntaxError: Unexpected token 'N', ..."_signed": NaN,`

## 原因
Excel中的空值被转换为 `NaN`，JSON不支持 `NaN` 值。

## 解决方案

### 1. 提交最新代码
```bash
git add parse_excel.py
git commit -m "修复NaN问题，清理空值"
git push
```

### 2. 服务器更新
```bash
# SSH登录
ssh root@139.224.200.133

# 进入目录
cd /var/www/approval-viewer/approvalquery

# 拉取最新代码
git pull

# 重新生成数据
python3 parse_excel.py

# 设置权限
chmod 644 approval_data.json
```

### 3. 验证
浏览器访问：http://blitzepanda.top/approvalquery

按 `Ctrl+F5` 强制刷新

## 一行命令
```bash
cd /var/www/approval-viewer/approvalquery && git pull && python3 parse_excel.py && chmod 644 approval_data.json
```

完成！
