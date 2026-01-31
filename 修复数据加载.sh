#!/bin/bash
# 修复数据加载问题

echo "========================================"
echo "🔧 修复数据加载问题"
echo "========================================"
echo ""

cd /var/www/approval-viewer/approvalquery || exit 1

# 检查Excel文件
if [ ! -f "线上建店审批.xlsx" ]; then
    echo "❌ Excel文件不存在"
    echo "请先上传: scp 线上建店审批.xlsx root@服务器IP:/var/www/approval-viewer/approvalquery/"
    exit 1
fi

# 生成JSON数据
echo "🔄 生成数据..."
python3 parse_excel.py || exit 1

# 设置权限
echo "🔐 设置权限..."
chmod 644 approval_data.json index.html
chown www-data:www-data approval_data.json index.html

# 验证
echo ""
echo "✅ 修复完成！"
echo ""
echo "📊 文件信息:"
ls -lh approval_data.json index.html
echo ""

# 测试访问
echo "🧪 测试访问..."
status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/approvalquery/approval_data.json)
if [ "$status" = "200" ]; then
    echo "✅ 数据文件可访问 (HTTP $status)"
else
    echo "❌ 数据文件访问失败 (HTTP $status)"
fi

status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/approvalquery/)
if [ "$status" = "200" ]; then
    echo "✅ 页面可访问 (HTTP $status)"
else
    echo "❌ 页面访问失败 (HTTP $status)"
fi

echo ""
echo "🌐 访问: http://blitzepanda.top/approvalquery"
echo "💡 按 Ctrl+F5 强制刷新浏览器"
echo ""
