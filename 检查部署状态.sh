#!/bin/bash
# 部署状态检查脚本

echo "========================================"
echo "🔍 审批系统部署状态检查"
echo "========================================"
echo ""

PROJECT_DIR="/var/www/approval-viewer"

# 检查项目目录
echo "📂 检查项目目录..."
if [ -d "$PROJECT_DIR" ]; then
    echo "✅ 项目目录存在: $PROJECT_DIR"
else
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi
echo ""

# 检查关键文件
echo "📄 检查关键文件..."
cd $PROJECT_DIR

files=("index.html" "approval_data.json" "parse_excel.py" "线上建店审批.xlsx")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        size=$(ls -lh "$file" | awk '{print $5}')
        echo "✅ $file ($size)"
    else
        echo "❌ $file (不存在)"
    fi
done
echo ""

# 检查文件权限
echo "🔐 检查文件权限..."
if [ -f "approval_data.json" ]; then
    perms=$(stat -c "%a" approval_data.json)
    owner=$(stat -c "%U:%G" approval_data.json)
    echo "   approval_data.json: $perms ($owner)"
    
    if [ "$perms" != "644" ]; then
        echo "⚠️  建议权限: 644"
        echo "   修复命令: chmod 644 approval_data.json"
    fi
else
    echo "❌ approval_data.json 不存在"
    echo "   生成命令: python3 parse_excel.py"
fi
echo ""

# 检查nginx配置
echo "🌐 检查nginx配置..."
if [ -f "/etc/nginx/sites-available/approval-viewer" ]; then
    echo "✅ nginx配置文件存在"
    
    if grep -q "alias /var/www/approval-viewer" /etc/nginx/sites-available/approval-viewer; then
        echo "✅ 路径配置正确"
    else
        echo "⚠️  路径配置可能有问题"
    fi
    
    if [ -L "/etc/nginx/sites-enabled/approval-viewer" ]; then
        echo "✅ 配置已启用"
    else
        echo "❌ 配置未启用"
        echo "   启用命令: sudo ln -s /etc/nginx/sites-available/approval-viewer /etc/nginx/sites-enabled/"
    fi
else
    echo "❌ nginx配置文件不存在"
fi
echo ""

# 检查nginx状态
echo "🔄 检查nginx状态..."
if systemctl is-active --quiet nginx; then
    echo "✅ nginx正在运行"
else
    echo "❌ nginx未运行"
    echo "   启动命令: sudo systemctl start nginx"
fi
echo ""

# 测试文件访问
echo "🧪 测试文件访问..."
if command -v curl &> /dev/null; then
    # 测试index.html
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/approvalquery/)
    if [ "$status" = "200" ]; then
        echo "✅ index.html 可访问 (HTTP $status)"
    else
        echo "❌ index.html 访问失败 (HTTP $status)"
    fi
    
    # 测试approval_data.json
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/approvalquery/approval_data.json)
    if [ "$status" = "200" ]; then
        echo "✅ approval_data.json 可访问 (HTTP $status)"
    else
        echo "❌ approval_data.json 访问失败 (HTTP $status)"
    fi
else
    echo "⚠️  curl未安装，跳过访问测试"
fi
echo ""

# 检查Python环境
echo "🐍 检查Python环境..."
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version)
    echo "✅ $python_version"
    
    if python3 -c "import openpyxl" 2>/dev/null; then
        echo "✅ openpyxl 已安装"
    else
        echo "❌ openpyxl 未安装"
        echo "   安装命令: pip3 install openpyxl"
    fi
else
    echo "❌ Python3 未安装"
fi
echo ""

# 总结
echo "========================================"
echo "📊 检查总结"
echo "========================================"
echo ""

# 判断是否需要生成数据
if [ ! -f "approval_data.json" ]; then
    echo "⚠️  需要生成数据文件"
    echo ""
    echo "🔧 修复步骤:"
    echo "   1. cd /var/www/approval-viewer"
    echo "   2. python3 parse_excel.py"
    echo "   3. chmod 644 approval_data.json"
    echo ""
elif [ ! -r "approval_data.json" ]; then
    echo "⚠️  数据文件权限问题"
    echo ""
    echo "🔧 修复步骤:"
    echo "   chmod 644 /var/www/approval-viewer/approval_data.json"
    echo ""
else
    echo "✅ 系统状态正常"
    echo ""
    echo "🌐 访问地址: http://blitzepanda.top/approvalquery"
    echo ""
fi

echo "========================================"
