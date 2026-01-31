#!/bin/bash
# nginx配置诊断脚本

echo "========================================"
echo "🔍 nginx配置诊断"
echo "========================================"
echo ""

echo "📋 当前所有nginx配置文件："
echo ""
ls -lh /etc/nginx/sites-available/
echo ""

echo "========================================"
echo "🔗 已启用的配置（软链接）："
echo "========================================"
echo ""
ls -lh /etc/nginx/sites-enabled/
echo ""

echo "========================================"
echo "📄 default 配置内容："
echo "========================================"
cat /etc/nginx/sites-available/default
echo ""

echo "========================================"
echo "📄 approval-viewer 配置内容（如果存在）："
echo "========================================"
if [ -f "/etc/nginx/sites-available/approval-viewer" ]; then
    cat /etc/nginx/sites-available/approval-viewer
else
    echo "❌ 文件不存在"
fi
echo ""

echo "========================================"
echo "📂 检查项目目录："
echo "========================================"
echo ""
for project in approvalquery kart wuliu weeklycheck; do
    echo "🔍 $project:"
    if [ -d "/var/www/$project" ]; then
        echo "   ✅ /var/www/$project"
        ls -lh /var/www/$project/*.html 2>/dev/null | head -3
    elif [ -d "/var/www/approval-viewer/$project" ]; then
        echo "   ✅ /var/www/approval-viewer/$project"
        ls -lh /var/www/approval-viewer/$project/*.html 2>/dev/null | head -3
    elif [ -d "/var/www/approval-viewer" ] && [ "$project" = "approvalquery" ]; then
        echo "   ✅ /var/www/approval-viewer/approvalquery"
        ls -lh /var/www/approval-viewer/approvalquery/*.html 2>/dev/null | head -3
    else
        echo "   ❓ 未找到"
    fi
    echo ""
done

echo "========================================"
echo "🧪 测试访问（从服务器内部）："
echo "========================================"
echo ""
for project in approvalquery kart wuliu weeklycheck; do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/$project/)
    if [ "$status" = "200" ]; then
        echo "✅ /$project/ - HTTP $status"
    else
        echo "❌ /$project/ - HTTP $status"
    fi
done
echo ""

echo "========================================"
echo "💡 配置建议："
echo "========================================"
echo ""
echo "推荐方案：使用一个default配置管理所有项目"
echo ""
echo "优点："
echo "  - 配置集中，易于管理"
echo "  - 不会有冲突"
echo "  - 修改方便"
echo ""
echo "========================================"
