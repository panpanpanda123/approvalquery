#!/bin/bash
# 立即修复脚本 - 解决路径问题

echo "========================================"
echo "🔧 立即修复数据加载问题"
echo "========================================"
echo ""

# 检查当前情况
echo "📂 当前文件位置："
echo ""

if [ -f "/var/www/approval-viewer/approvalquery/approval_data.json" ]; then
    echo "✅ 找到: /var/www/approval-viewer/approvalquery/approval_data.json"
    JSON_PATH="/var/www/approval-viewer/approvalquery"
elif [ -f "/var/www/approval-viewer/approval_data.json" ]; then
    echo "✅ 找到: /var/www/approval-viewer/approval_data.json"
    JSON_PATH="/var/www/approval-viewer"
else
    echo "❌ 未找到 approval_data.json"
    exit 1
fi
echo ""

# 检查index.html位置
echo "📄 检查index.html位置："
if [ -f "/var/www/approval-viewer/approvalquery/index.html" ]; then
    echo "✅ 找到: /var/www/approval-viewer/approvalquery/index.html"
    HTML_PATH="/var/www/approval-viewer/approvalquery"
elif [ -f "/var/www/approval-viewer/index.html" ]; then
    echo "✅ 找到: /var/www/approval-viewer/index.html"
    HTML_PATH="/var/www/approval-viewer"
else
    echo "❌ 未找到 index.html"
    exit 1
fi
echo ""

# 判断是否需要移动文件
if [ "$JSON_PATH" != "$HTML_PATH" ]; then
    echo "⚠️  文件位置不一致！"
    echo "   JSON在: $JSON_PATH"
    echo "   HTML在: $HTML_PATH"
    echo ""
    echo "🔧 修复方案：统一到 /var/www/approval-viewer/approvalquery/"
    echo ""
    
    # 确保approvalquery目录存在
    mkdir -p /var/www/approval-viewer/approvalquery
    
    # 移动所有文件到approvalquery
    if [ -f "/var/www/approval-viewer/index.html" ]; then
        echo "📦 移动 index.html..."
        mv /var/www/approval-viewer/index.html /var/www/approval-viewer/approvalquery/
    fi
    
    if [ -f "/var/www/approval-viewer/approval_data.json" ]; then
        echo "📦 移动 approval_data.json..."
        mv /var/www/approval-viewer/approval_data.json /var/www/approval-viewer/approvalquery/
    fi
    
    # 移动其他必要文件
    for file in parse_excel.py 线上建店审批.xlsx requirements.txt; do
        if [ -f "/var/www/approval-viewer/$file" ]; then
            echo "📦 移动 $file..."
            mv "/var/www/approval-viewer/$file" /var/www/approval-viewer/approvalquery/
        fi
    done
    
    echo "✅ 文件移动完成"
    echo ""
fi

# 设置权限
echo "🔐 设置文件权限..."
cd /var/www/approval-viewer/approvalquery
chmod 644 *.json *.html 2>/dev/null
chmod 644 *.py 2>/dev/null
chown -R www-data:www-data /var/www/approval-viewer
echo "✅ 权限设置完成"
echo ""

# 检查nginx配置
echo "🌐 检查nginx配置..."
if [ -f "/etc/nginx/sites-available/approval-viewer" ]; then
    echo "当前配置："
    grep -A 5 "location /approvalquery" /etc/nginx/sites-available/approval-viewer
    echo ""
    
    # 检查配置是否正确
    if grep -q "alias /var/www/approval-viewer/approvalquery" /etc/nginx/sites-available/approval-viewer; then
        echo "✅ nginx配置正确"
    elif grep -q "alias /var/www/approval-viewer" /etc/nginx/sites-available/approval-viewer; then
        echo "⚠️  nginx配置需要更新"
        echo ""
        echo "当前配置指向: /var/www/approval-viewer"
        echo "应该指向: /var/www/approval-viewer/approvalquery"
        echo ""
        echo "🔧 修复nginx配置..."
        
        # 备份配置
        cp /etc/nginx/sites-available/approval-viewer /etc/nginx/sites-available/approval-viewer.backup
        
        # 更新配置
        sed -i 's|alias /var/www/approval-viewer;|alias /var/www/approval-viewer/approvalquery;|g' /etc/nginx/sites-available/approval-viewer
        
        echo "✅ 配置已更新"
        echo ""
        echo "🔄 重启nginx..."
        nginx -t && systemctl reload nginx
        echo "✅ nginx已重启"
    fi
else
    echo "❌ nginx配置文件不存在"
fi
echo ""

# 测试访问
echo "🧪 测试文件访问..."
sleep 2

status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/approvalquery/approval_data.json)
if [ "$status" = "200" ]; then
    echo "✅ approval_data.json 可访问 (HTTP $status)"
else
    echo "❌ approval_data.json 访问失败 (HTTP $status)"
    echo ""
    echo "💡 手动测试："
    echo "   curl -I http://localhost/approvalquery/approval_data.json"
fi
echo ""

status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/approvalquery/)
if [ "$status" = "200" ]; then
    echo "✅ index.html 可访问 (HTTP $status)"
else
    echo "❌ index.html 访问失败 (HTTP $status)"
fi
echo ""

echo "========================================"
echo "✅ 修复完成！"
echo "========================================"
echo ""
echo "📁 文件位置: /var/www/approval-viewer/approvalquery/"
ls -lh /var/www/approval-viewer/approvalquery/*.{json,html} 2>/dev/null
echo ""
echo "🌐 访问地址: http://blitzepanda.top/approvalquery"
echo ""
echo "💡 提示: 按 Ctrl+F5 强制刷新浏览器"
echo ""
echo "========================================"
