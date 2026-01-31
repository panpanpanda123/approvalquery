#!/bin/bash
# 快速查看当前nginx配置

echo "========================================"
echo "📋 当前nginx配置概览"
echo "========================================"
echo ""

echo "1️⃣  配置文件列表："
echo ""
echo "可用配置 (sites-available):"
ls -1 /etc/nginx/sites-available/
echo ""
echo "已启用配置 (sites-enabled):"
ls -1 /etc/nginx/sites-enabled/
echo ""

echo "========================================"
echo "2️⃣  项目目录结构："
echo "========================================"
echo ""
tree -L 2 -d /var/www/ 2>/dev/null || find /var/www/ -maxdepth 2 -type d
echo ""

echo "========================================"
echo "3️⃣  default 配置中的 location："
echo "========================================"
echo ""
grep -E "location|alias|root" /etc/nginx/sites-available/default | grep -v "#"
echo ""

if [ -f "/etc/nginx/sites-available/approval-viewer" ]; then
    echo "========================================"
    echo "4️⃣  approval-viewer 独立配置："
    echo "========================================"
    echo ""
    grep -E "location|alias|root" /etc/nginx/sites-available/approval-viewer | grep -v "#"
    echo ""
fi

echo "========================================"
echo "5️⃣  访问测试："
echo "========================================"
echo ""
for path in approvalquery kart wuliu weeklycheck; do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/$path/ 2>/dev/null)
    if [ "$status" = "200" ]; then
        echo "✅ /$path/ → HTTP $status"
    elif [ "$status" = "404" ]; then
        echo "❌ /$path/ → HTTP $status (未配置或路径错误)"
    elif [ "$status" = "403" ]; then
        echo "⚠️  /$path/ → HTTP $status (权限问题)"
    else
        echo "❓ /$path/ → HTTP $status"
    fi
done
echo ""

echo "========================================"
echo "💡 问题诊断："
echo "========================================"
echo ""

# 检查是否有冲突配置
enabled_count=$(ls /etc/nginx/sites-enabled/ | wc -l)
if [ $enabled_count -gt 1 ]; then
    echo "⚠️  发现多个启用的配置文件，可能有冲突："
    ls -1 /etc/nginx/sites-enabled/
    echo ""
    echo "建议：使用一个default配置管理所有项目"
    echo "运行：bash 一键整理nginx.sh"
else
    echo "✅ 只有一个配置文件，配置结构清晰"
fi
echo ""

# 检查approval-viewer独立配置
if [ -f "/etc/nginx/sites-enabled/approval-viewer" ]; then
    echo "⚠️  发现approval-viewer独立配置已启用"
    echo "   这可能与default配置冲突"
    echo ""
    echo "建议：合并到default配置"
    echo "运行：bash 一键整理nginx.sh"
    echo ""
fi

echo "========================================"
