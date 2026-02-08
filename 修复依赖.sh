#!/bin/bash
# 修复Python依赖问题

echo "========================================"
echo "🔧 修复Python依赖"
echo "========================================"
echo ""

cd /var/www/approval-viewer/approvalquery

echo "📦 重新安装依赖..."
pip3 install --upgrade --force-reinstall pandas numpy openpyxl

echo ""
echo "✅ 依赖修复完成"
echo ""

echo "🧪 测试解析..."
python3 parse_excel.py

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 测试成功！"
    chmod 644 approval_data.json
else
    echo ""
    echo "❌ 测试失败"
    echo ""
    echo "💡 尝试使用虚拟环境："
    echo "   python3 -m venv venv"
    echo "   source venv/bin/activate"
    echo "   pip install pandas openpyxl"
    echo "   python parse_excel.py"
fi
