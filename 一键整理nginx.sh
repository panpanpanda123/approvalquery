#!/bin/bash
# 一键整理nginx配置脚本

set -e

echo "========================================"
echo "🔧 一键整理nginx配置"
echo "========================================"
echo ""
echo "这个脚本会："
echo "  1. 备份现有配置"
echo "  2. 检测所有项目位置"
echo "  3. 生成统一的nginx配置"
echo "  4. 删除冲突的配置"
echo "  5. 重启nginx"
echo ""
read -p "按回车继续，或 Ctrl+C 取消..." 

echo ""
echo "========================================"
echo "📦 步骤 1/6: 备份现有配置"
echo "========================================"
echo ""

BACKUP_DIR="/root/nginx_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
cp -r /etc/nginx/sites-available $BACKUP_DIR/
cp -r /etc/nginx/sites-enabled $BACKUP_DIR/
echo "✅ 备份保存到: $BACKUP_DIR"
echo ""

echo "========================================"
echo "📂 步骤 2/6: 检测项目位置"
echo "========================================"
echo ""

# 检测每个项目的实际位置
declare -A PROJECT_PATHS

# approvalquery
if [ -d "/var/www/approval-viewer/approvalquery" ] && [ -f "/var/www/approval-viewer/approvalquery/index.html" ]; then
    PROJECT_PATHS[approvalquery]="/var/www/approval-viewer/approvalquery"
    echo "✅ approvalquery: /var/www/approval-viewer/approvalquery"
elif [ -d "/var/www/approvalquery" ] && [ -f "/var/www/approvalquery/index.html" ]; then
    PROJECT_PATHS[approvalquery]="/var/www/approvalquery"
    echo "✅ approvalquery: /var/www/approvalquery"
else
    echo "❌ approvalquery: 未找到"
fi

# kart
if [ -d "/var/www/kart" ] && [ -f "/var/www/kart/index.html" ]; then
    PROJECT_PATHS[kart]="/var/www/kart"
    echo "✅ kart: /var/www/kart"
else
    echo "❌ kart: 未找到"
fi

# wuliu
if [ -d "/var/www/wuliu" ] && [ -f "/var/www/wuliu/index.html" ]; then
    PROJECT_PATHS[wuliu]="/var/www/wuliu"
    echo "✅ wuliu: /var/www/wuliu"
else
    echo "❌ wuliu: 未找到"
fi

# weeklycheck
if [ -d "/var/www/weeklycheck" ] && [ -f "/var/www/weeklycheck/index.html" ]; then
    PROJECT_PATHS[weeklycheck]="/var/www/weeklycheck"
    echo "✅ weeklycheck: /var/www/weeklycheck"
else
    echo "❌ weeklycheck: 未找到"
fi

echo ""

if [ ${#PROJECT_PATHS[@]} -eq 0 ]; then
    echo "❌ 错误: 没有找到任何项目"
    exit 1
fi

echo "========================================"
echo "📝 步骤 3/6: 生成统一配置"
echo "========================================"
echo ""

# 生成新的default配置
cat > /tmp/nginx_default_new << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    # 支持域名和IP访问
    server_name blitzepanda.top 139.224.200.133 _;

    # 根路径返回404或重定向
    location = / {
        return 404;
    }

EOF

# 为每个项目添加location块
for project in "${!PROJECT_PATHS[@]}"; do
    path="${PROJECT_PATHS[$project]}"
    echo "添加配置: /$project -> $path"
    
    cat >> /tmp/nginx_default_new << EOF
    # $project 项目
    location /$project {
        alias $path;
        index index.html;
        try_files \$uri \$uri/ /$project/index.html;
        
        # 允许访问JSON等数据文件
        location ~ \.(json|txt|csv)$ {
            add_header Cache-Control "no-store, no-cache, must-revalidate";
            add_header Access-Control-Allow-Origin "*";
        }
    }

EOF
done

# 添加配置文件结尾
cat >> /tmp/nginx_default_new << 'EOF'
    # 其他路径返回404
    location / {
        return 404;
    }
}
EOF

echo "✅ 配置生成完成"
echo ""

echo "========================================"
echo "📄 步骤 4/6: 预览新配置"
echo "========================================"
echo ""
cat /tmp/nginx_default_new
echo ""

read -p "配置看起来正确吗？按回车继续..." 

echo ""
echo "========================================"
echo "🗑️  步骤 5/6: 清理旧配置"
echo "========================================"
echo ""

# 删除approval-viewer的独立配置（如果存在）
if [ -f "/etc/nginx/sites-enabled/approval-viewer" ]; then
    echo "删除: /etc/nginx/sites-enabled/approval-viewer"
    rm /etc/nginx/sites-enabled/approval-viewer
fi

if [ -f "/etc/nginx/sites-available/approval-viewer" ]; then
    echo "移动到备份: /etc/nginx/sites-available/approval-viewer"
    mv /etc/nginx/sites-available/approval-viewer $BACKUP_DIR/
fi

# 应用新配置
echo "应用新配置到: /etc/nginx/sites-available/default"
cp /tmp/nginx_default_new /etc/nginx/sites-available/default

# 确保default配置已启用
if [ ! -L "/etc/nginx/sites-enabled/default" ]; then
    echo "启用default配置"
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
fi

echo "✅ 配置清理完成"
echo ""

echo "========================================"
echo "🔄 步骤 6/6: 测试并重启nginx"
echo "========================================"
echo ""

# 测试配置
echo "测试nginx配置..."
if nginx -t; then
    echo "✅ 配置测试通过"
    echo ""
    echo "重启nginx..."
    systemctl reload nginx
    echo "✅ nginx已重启"
else
    echo "❌ 配置测试失败"
    echo ""
    echo "恢复备份..."
    cp $BACKUP_DIR/sites-available/default /etc/nginx/sites-available/default
    systemctl reload nginx
    echo "已恢复到备份配置"
    exit 1
fi

echo ""
echo "========================================"
echo "🧪 验证访问"
echo "========================================"
echo ""

sleep 2

for project in "${!PROJECT_PATHS[@]}"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/$project/)
    if [ "$status" = "200" ]; then
        echo "✅ http://blitzepanda.top/$project/ - HTTP $status"
    else
        echo "❌ http://blitzepanda.top/$project/ - HTTP $status"
    fi
done

echo ""
echo "========================================"
echo "✅ 配置整理完成！"
echo "========================================"
echo ""
echo "📋 配置摘要："
echo "  - 所有项目统一在 /etc/nginx/sites-available/default"
echo "  - 旧配置备份在: $BACKUP_DIR"
echo ""
echo "🌐 访问地址："
for project in "${!PROJECT_PATHS[@]}"; do
    echo "  - http://blitzepanda.top/$project/"
done
echo ""
echo "💡 提示："
echo "  - 刷新浏览器查看效果 (Ctrl+F5)"
echo "  - 如有问题，备份在: $BACKUP_DIR"
echo ""
echo "========================================"
