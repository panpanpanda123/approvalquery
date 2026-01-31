#!/bin/bash
# 服务器端快速部署脚本

echo "========================================"
echo "🚀 审批系统部署"
echo "========================================"
echo ""

# 检查是否在正确的目录
if [ ! -f "index.html" ] || [ ! -f "parse_excel.py" ]; then
    echo "❌ 请在项目目录中运行此脚本"
    exit 1
fi

PROJECT_DIR=$(pwd)
echo "📂 项目目录: $PROJECT_DIR"
echo ""

# 安装Python依赖
echo "📦 安装依赖..."
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
    echo "✅ 依赖安装完成"
else
    echo "⚠️  requirements.txt 不存在，跳过"
fi
echo ""

# 生成数据
echo "📊 生成数据..."
if [ -f "线上建店审批.xlsx" ]; then
    python3 parse_excel.py
    echo "✅ 数据生成完成"
else
    echo "⚠️  Excel文件不存在，跳过数据生成"
fi
echo ""

# 设置权限
echo "🔐 设置权限..."
chmod 644 *.html *.json 2>/dev/null
chmod 755 *.sh 2>/dev/null
chown -R www-data:www-data . 2>/dev/null || echo "⚠️  无法设置所有者，可能需要sudo"
echo "✅ 权限设置完成"
echo ""

# 配置nginx
echo "🌐 配置nginx..."
read -p "是否配置nginx？(y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "检测并配置nginx.sh" ]; then
        bash 检测并配置nginx.sh
    else
        echo "❌ 配置脚本不存在"
    fi
else
    echo "⏭️  跳过nginx配置"
fi
echo ""

echo "========================================"
echo "✅ 部署完成！"
echo "========================================"
echo ""
echo "📋 下一步："
echo "  1. 确保Excel文件已上传"
echo "  2. 运行: python3 parse_excel.py"
echo "  3. 访问: http://blitzepanda.top/approvalquery"
echo ""
