#!/bin/bash
# 智能检测所有项目并配置nginx

echo "========================================"
echo "🔍 检测服务器上的所有Web项目"
echo "========================================"
echo ""

# 配置变量
DOMAIN="blitzepanda.top"
SERVER_IP="139.224.200.133"
NGINX_CONFIG="/etc/nginx/sites-available/default"
BACKUP_DIR="/root/nginx_backup_$(date +%Y%m%d_%H%M%S)"

# 要查找的项目名称
PROJECT_NAMES=("approvalquery" "kart" "wuliu" "weeklycheck")

echo "📂 搜索项目位置..."
echo "   搜索范围: /var/www, /opt, /home"
echo ""

# 存储找到的项目
declare -A FOUND_PROJECTS

# 搜索每个项目
for project in "${PROJECT_NAMES[@]}"; do
    echo "🔍 搜索: $project"
    
    # 在常见位置搜索
    for base_dir in /var/www /opt /home; do
        if [ -d "$base_dir" ]; then
            # 查找包含index.html的目录
            found=$(find "$base_dir" -maxdepth 3 -type d -name "$project" 2>/dev/null | while read dir; do
                if [ -f "$dir/index.html" ]; then
                    echo "$dir"
                    break
                fi
            done)
            
            if [ -n "$found" ]; then
                FOUND_PROJECTS[$project]="$found"
                echo "   ✅ 找到: $found"
                break
            fi
        fi
    done
    
    if [ -z "${FOUND_PROJECTS[$project]}" ]; then
        echo "   ❌ 未找到"
    fi
    echo ""
done

# 显示检测结果
echo "========================================"
echo "📋 检测结果汇总"
echo "========================================"
echo ""

if [ ${#FOUND_PROJECTS[@]} -eq 0 ]; then
    echo "❌ 没有找到任何项目"
    echo ""
    echo "💡 手动搜索所有index.html文件："
    echo "   find /var/www /opt /home -name 'index.html' -type f 2>/dev/null"
    exit 1
fi

echo "找到 ${#FOUND_PROJECTS[@]} 个项目："
echo ""
for project in "${!FOUND_PROJECTS[@]}"; do
    path="${FOUND_PROJECTS[$project]}"
    size=$(du -sh "$path" 2>/dev/null | cut -f1)
    echo "  ✅ $project"
    echo "     路径: $path"
    echo "     大小: $size"
    echo ""
done

# 显示当前nginx配置
echo "========================================"
echo "📄 当前nginx配置"
echo "========================================"
echo ""
if [ -f "$NGINX_CONFIG" ]; then
    echo "配置文件: $NGINX_CONFIG"
    echo ""
    echo "当前的location配置："
    grep -E "location /|alias |root " "$NGINX_CONFIG" | grep -v "#" | head -20
else
    echo "❌ nginx配置文件不存在"
fi
echo ""

# 询问是否继续
read -p "是否生成新的nginx配置？(y/n) " -n 1 -r
echo ""
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 备份现有配置
echo "========================================"
echo "📦 备份现有配置"
echo "========================================"
echo ""
mkdir -p "$BACKUP_DIR"
if [ -f "$NGINX_CONFIG" ]; then
    cp "$NGINX_CONFIG" "$BACKUP_DIR/"
    echo "✅ 备份到: $BACKUP_DIR"
else
    echo "⚠️  配置文件不存在，跳过备份"
fi
echo ""

# 生成新配置
echo "========================================"
echo "📝 生成nginx配置"
echo "========================================"
echo ""

cat > /tmp/nginx_config_new << EOF
# nginx配置 - 多项目管理
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 自动生成，请勿手动编辑

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    # 支持域名和IP访问
    server_name $DOMAIN $SERVER_IP _;

    # 日志
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # 根路径
    location = / {
        return 404 "请访问具体项目路径";
    }

EOF

# 为每个找到的项目生成配置
for project in "${!FOUND_PROJECTS[@]}"; do
    path="${FOUND_PROJECTS[$project]}"
    echo "添加配置: /$project → $path"
    
    cat >> /tmp/nginx_config_new << EOF
    # $project 项目
    location /$project {
        alias $path;
        index index.html index.htm;
        try_files \$uri \$uri/ /$project/index.html;

        # 数据文件缓存控制
        location ~ \.(json|txt|csv|xlsx)$ {
            add_header Cache-Control "no-store, no-cache, must-revalidate";
            add_header Access-Control-Allow-Origin "*";
        }

        # 静态资源缓存
        location ~ \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
            expires 7d;
            add_header Cache-Control "public, immutable";
        }
    }

EOF
done

# 添加默认处理
cat >> /tmp/nginx_config_new << 'EOF'
    # 其他路径返回404
    location / {
        return 404;
    }
}
EOF

echo "✅ 配置生成完成"
echo ""

# 显示配置预览
echo "========================================"
echo "📄 配置预览"
echo "========================================"
cat /tmp/nginx_config_new
echo "========================================"
echo ""

read -p "配置正确吗？应用配置？(y/n) " -n 1 -r
echo ""
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 应用配置
echo "========================================"
echo "🔧 应用配置"
echo "========================================"
echo ""

cp /tmp/nginx_config_new "$NGINX_CONFIG"
echo "✅ 配置已写入: $NGINX_CONFIG"
echo ""

# 测试配置
echo "🧪 测试nginx配置..."
if nginx -t; then
    echo "✅ 配置测试通过"
    echo ""
    echo "🔄 重启nginx..."
    systemctl reload nginx
    echo "✅ nginx已重启"
else
    echo "❌ 配置测试失败"
    echo ""
    echo "🔙 恢复备份..."
    if [ -f "$BACKUP_DIR/default" ]; then
        cp "$BACKUP_DIR/default" "$NGINX_CONFIG"
        systemctl reload nginx
        echo "✅ 已恢复到备份配置"
    fi
    exit 1
fi

# 验证访问
echo ""
echo "========================================"
echo "🧪 验证项目访问"
echo "========================================"
echo ""
sleep 2

for project in "${!FOUND_PROJECTS[@]}"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/$project/ 2>/dev/null)
    if [ "$status" = "200" ]; then
        echo "✅ /$project/ - HTTP $status"
    else
        echo "❌ /$project/ - HTTP $status"
    fi
done

echo ""
echo "========================================"
echo "✅ 配置完成！"
echo "========================================"
echo ""
echo "🌐 访问地址："
for project in "${!FOUND_PROJECTS[@]}"; do
    echo ""
    echo "  📱 $project:"
    echo "     http://$DOMAIN/$project/"
    echo "     http://$SERVER_IP/$project/"
done
echo ""
echo "📦 备份位置: $BACKUP_DIR"
echo ""
echo "💡 提示："
echo "   - 浏览器访问测试所有项目"
echo "   - 按 Ctrl+F5 强制刷新"
echo "   - 如有问题，备份在: $BACKUP_DIR"
echo ""
echo "========================================"
