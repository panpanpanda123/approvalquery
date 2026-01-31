#!/bin/bash
# 诊断当前问题

echo "========================================"
echo "🔍 诊断数据加载失败问题"
echo "========================================"
echo ""

echo "📂 检查文件位置..."
echo ""
echo "方案1: /var/www/approval-viewer/"
ls -lh /var/www/approval-viewer/*.json 2>/dev/null || echo "   ❌ 此目录下没有JSON文件"
echo ""
echo "方案2: /var/www/approval-viewer/approvalquery/"
ls -lh /var/www/approval-viewer/approvalquery/*.json 2>/dev/null || echo "   ❌ 此目录下没有JSON文件"
echo ""

echo "========================================"
echo "📄 检查nginx配置"
echo "========================================"
echo ""
cat /etc/nginx/sites-available/approval-viewer 2>/dev/null || echo "❌ 配置文件不存在"
echo ""

echo "========================================"
echo "🧪 测试文件访问"
echo "========================================"
echo ""

# 测试不同路径
echo "测试1: http://localhost/approvalquery/approval_data.json"
curl -I http://localhost/approvalquery/approval_data.json 2>/dev/null | head -5
echo ""

echo "测试2: http://localhost/approvalquery/index.html"
curl -I http://localhost/approvalquery/index.html 2>/dev/null | head -5
echo ""

echo "========================================"
echo "💡 问题分析"
echo "========================================"
echo ""

if [ -f "/var/www/approval-viewer/approvalquery/approval_data.json" ]; then
    echo "✅ JSON文件存在于: /var/www/approval-viewer/approvalquery/"
    echo ""
    echo "🔧 可能的问题："
    echo "   1. nginx配置的路径不对"
    echo "   2. index.html在错误的位置"
    echo ""
    echo "📍 检查index.html位置："
    find /var/www/approval-viewer -name "index.html" -type f
    echo ""
fi

echo "========================================"
