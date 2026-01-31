#!/bin/bash
# 快速修复脚本 - 解决"数据加载失败"问题

echo "========================================"
echo "🔧 快速修复：数据加载失败"
echo "========================================"
echo ""

PROJECT_DIR="/var/www/approval-viewer"

# 进入项目目录
cd $PROJECT_DIR || exit 1

echo "📂 当前目录: $(pwd)"
echo ""

# 步骤1：检查Excel文件
echo "步骤 1/4: 检查Excel文件..."
if [ -f "线上建店审批.xlsx" ]; then
    echo "✅ Excel文件存在"
else
    echo "❌ Excel文件不存在"
    echo ""
    echo "💡 请先上传Excel文件到服务器："
    echo "   scp 线上建店审批.xlsx root@服务器IP:/var/www/approval-viewer/"
    exit 1
fi
echo ""

# 步骤2：生成JSON数据
echo "步骤 2/4: 生成JSON数据..."
python3 parse_excel.py
if [ $? -eq 0 ]; then
    echo "✅ 数据生成成功"
else
    echo "❌ 数据生成失败"
    echo ""
    echo "💡 可能的原因："
    echo "   1. Python3未安装"
    echo "   2. openpyxl库未安装: pip3 install openpyxl"
    exit 1
fi
echo ""

# 步骤3：设置文件权限
echo "步骤 3/4: 设置文件权限..."
chmod 644 approval_data.json
chmod 644 index.html
chown -R www-data:www-data .
echo "✅ 权限设置完成"
echo ""

# 步骤4：测试访问
echo "步骤 4/4: 测试文件访问..."
if command -v curl &> /dev/null; then
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/approvalquery/approval_data.json)
    if [ "$status" = "200" ]; then
        echo "✅ 数据文件可访问 (HTTP $status)"
    else
        echo "⚠️  数据文件访问异常 (HTTP $status)"
        echo ""
        echo "💡 可能需要重启nginx："
        echo "   sudo systemctl reload nginx"
    fi
else
    echo "⚠️  curl未安装，跳过测试"
fi
echo ""

echo "========================================"
echo "✅ 修复完成！"
echo "========================================"
echo ""
echo "🌐 访问地址: http://blitzepanda.top/approvalquery"
echo ""
echo "💡 提示: 按 Ctrl+F5 强制刷新浏览器"
echo ""
echo "📊 生成的文件："
ls -lh approval_data.json index.html
echo ""
echo "========================================"
