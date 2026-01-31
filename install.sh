#!/bin/bash
# 一键安装脚本 - 在服务器上运行

set -e  # 遇到错误立即退出

echo "========================================"
echo "审批系统自动部署脚本"
echo "目标: blitzepanda.top/approvalquery"
echo "========================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}提示: 建议使用root用户运行此脚本${NC}"
    echo "如果遇到权限问题，请在命令前加 sudo"
    echo ""
fi

# 1. 检查并安装依赖
echo -e "${GREEN}[1/7] 检查系统依赖...${NC}"
if ! command -v python3 &> /dev/null; then
    echo "安装 Python3..."
    sudo apt update
    sudo apt install -y python3 python3-pip
else
    echo "✓ Python3 已安装: $(python3 --version)"
fi

if ! command -v git &> /dev/null; then
    echo "安装 Git..."
    sudo apt install -y git
else
    echo "✓ Git 已安装: $(git --version)"
fi

if ! command -v nginx &> /dev/null; then
    echo "安装 Nginx..."
    sudo apt install -y nginx
else
    echo "✓ Nginx 已安装: $(nginx -v 2>&1)"
fi

echo ""

# 2. 创建项目目录
echo -e "${GREEN}[2/7] 创建项目目录...${NC}"
PROJECT_DIR="/var/www/approval-viewer"
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR
echo "✓ 项目目录: $PROJECT_DIR"
echo ""

# 3. 检查项目文件
echo -e "${GREEN}[3/7] 检查项目文件...${NC}"
cd $PROJECT_DIR

if [ ! -f "index.html" ]; then
    echo -e "${RED}错误: 未找到项目文件${NC}"
    echo "请先上传项目文件到 $PROJECT_DIR"
    echo ""
    echo "使用FinalShell的SFTP功能上传以下文件:"
    echo "  - index.html"
    echo "  - parse_excel.py"
    echo "  - update_excel.py"
    echo "  - requirements.txt"
    echo "  - 线上建店审批.xlsx"
    echo ""
    exit 1
fi

echo "✓ 项目文件已就绪"
ls -lh *.html *.py *.txt 2>/dev/null || true
echo ""

# 4. 安装Python依赖
echo -e "${GREEN}[4/7] 安装Python依赖...${NC}"
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
    echo "✓ Python依赖安装完成"
else
    echo -e "${YELLOW}警告: 未找到 requirements.txt${NC}"
fi
echo ""

# 5. 生成初始数据
echo -e "${GREEN}[5/7] 生成初始数据...${NC}"
if [ -f "线上建店审批.xlsx" ]; then
    python3 parse_excel.py
    echo "✓ 数据生成完成"
else
    echo -e "${YELLOW}警告: 未找到 Excel 文件${NC}"
fi
echo ""

# 6. 配置Nginx
echo -e "${GREEN}[6/7] 配置Nginx...${NC}"

NGINX_CONFIG="/etc/nginx/sites-available/approval-viewer"

if [ -f "$NGINX_CONFIG" ]; then
    echo -e "${YELLOW}Nginx配置已存在，跳过创建${NC}"
else
    sudo tee $NGINX_CONFIG > /dev/null <<'EOF'
server {
    listen 80;
    server_name blitzepanda.top www.blitzepanda.top;

    location /approvalquery {
        alias /var/www/approval-viewer;
        index index.html;
        
        location ~* \.(html|css|js|json|xlsx)$ {
            alias /var/www/approval-viewer;
            expires 1h;
            add_header Cache-Control "public, must-revalidate";
        }
    }

    location / {
        root /var/www/html;
        index index.html index.htm;
    }
}
EOF
    echo "✓ Nginx配置文件已创建"
fi

# 启用配置
if [ ! -L "/etc/nginx/sites-enabled/approval-viewer" ]; then
    sudo ln -s $NGINX_CONFIG /etc/nginx/sites-enabled/
    echo "✓ Nginx配置已启用"
fi

# 测试配置
if sudo nginx -t 2>&1 | grep -q "successful"; then
    echo "✓ Nginx配置测试通过"
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    echo "✓ Nginx已重启"
else
    echo -e "${RED}错误: Nginx配置测试失败${NC}"
    sudo nginx -t
    exit 1
fi
echo ""

# 7. 配置防火墙
echo -e "${GREEN}[7/7] 配置防火墙...${NC}"
if command -v ufw &> /dev/null; then
    sudo ufw allow 80/tcp 2>/dev/null || true
    sudo ufw allow 443/tcp 2>/dev/null || true
    echo "✓ 防火墙规则已添加"
else
    echo "⚠ UFW未安装，请手动配置防火墙"
fi
echo ""

# 完成
echo "========================================"
echo -e "${GREEN}✅ 部署完成！${NC}"
echo "========================================"
echo ""
echo "📍 访问地址: http://blitzepanda.top/approvalquery"
echo ""
echo "📝 下一步:"
echo "  1. 配置域名DNS (如果还没配置)"
echo "     - 登录域名注册商"
echo "     - 添加A记录: @ → 139.227.233.75"
echo ""
echo "  2. 等待DNS生效 (10分钟-24小时)"
echo "     - 测试: ping blitzepanda.top"
echo ""
echo "  3. 启用HTTPS (可选但推荐)"
echo "     - 运行: sudo certbot --nginx -d blitzepanda.top"
echo ""
echo "  4. 每日更新数据"
echo "     - 运行: python3 update_excel.py 新文件.xlsx"
echo ""
echo "📊 查看日志:"
echo "  sudo tail -f /var/log/nginx/access.log"
echo ""
echo "🔄 重启服务:"
echo "  sudo systemctl restart nginx"
echo ""
echo "========================================"
