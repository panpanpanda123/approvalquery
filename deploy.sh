#!/bin/bash
# 一键部署脚本

echo "=================================="
echo "审批进度可视化系统 - 部署脚本"
echo "=================================="
echo ""

# 检查Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: 未找到Python3"
    exit 1
fi

echo "✅ Python版本:"
python3 --version
echo ""

# 安装依赖
echo "📦 安装依赖..."
pip3 install -r requirements.txt
echo ""

# 检查Excel文件
if [ ! -f "线上建店审批.xlsx" ]; then
    echo "⚠️  警告: 未找到Excel文件"
    echo "请将Excel文件命名为 '线上建店审批.xlsx' 并放在当前目录"
    echo ""
    read -p "是否继续? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    # 生成数据
    echo "🔄 生成数据..."
    python3 parse_excel.py
    echo ""
fi

echo "=================================="
echo "✅ 部署完成！"
echo "=================================="
echo ""
echo "启动服务器:"
echo "  python3 deploy_server.py"
echo ""
echo "后台运行:"
echo "  nohup python3 deploy_server.py > server.log 2>&1 &"
echo ""
