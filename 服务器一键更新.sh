#!/bin/bash
# 服务器端一键更新脚本
# 用途：从GitHub拉取最新代码并重新生成数据
# 使用：bash 服务器一键更新.sh

echo "=================================="
echo "  审批系统一键更新脚本"
echo "=================================="
echo ""

# 检查是否在正确的目录
if [ ! -f "parse_excel.py" ]; then
    echo "❌ 错误：当前目录不是项目目录"
    echo "请先执行: cd /var/www/approval-viewer/approvalquery"
    exit 1
fi

echo "📍 当前目录: $(pwd)"
echo ""

# 1. 拉取最新代码
echo "📥 步骤1/4: 拉取最新代码..."
git pull origin main

if [ $? -ne 0 ]; then
    echo "❌ Git拉取失败"
    echo "可能原因："
    echo "  - 网络问题"
    echo "  - 本地有未提交的修改"
    echo "  - 权限问题"
    echo ""
    echo "尝试解决："
    echo "  git stash        # 暂存本地修改"
    echo "  git pull         # 重新拉取"
    echo "  git stash pop    # 恢复本地修改"
    exit 1
fi

echo "✅ 代码拉取成功"
echo ""

# 2. 检查配置文件
echo "🔍 步骤2/4: 检查配置文件..."
if [ -f "approver_config.json" ]; then
    echo "✅ 发现审批人员配置文件"
    # 显示财务审批-1的配置
    python3 -c "import json; config=json.load(open('approver_config.json')); print(f\"   财务审批-1: {', '.join(config['审批节点配置']['财务部-1']['names'])}\")" 2>/dev/null
else
    echo "⚠️  未找到 approver_config.json"
fi

if [ -f "线上建店审批.xlsx" ]; then
    echo "✅ 发现Excel数据文件"
    ls -lh 线上建店审批.xlsx | awk '{print "   大小: " $5 ", 修改时间: " $6 " " $7 " " $8}'
else
    echo "⚠️  未找到 线上建店审批.xlsx"
    echo "   请先上传Excel文件"
fi
echo ""

# 3. 重新生成数据
echo "📊 步骤3/4: 重新生成数据..."
python3 parse_excel.py

if [ $? -ne 0 ]; then
    echo "❌ 数据生成失败"
    echo "请检查："
    echo "  - Excel文件是否存在"
    echo "  - Python依赖是否安装 (pip3 install openpyxl pandas)"
    echo "  - 配置文件格式是否正确"
    exit 1
fi

echo "✅ 数据生成成功"
echo ""

# 4. 设置文件权限
echo "🔒 步骤4/4: 设置文件权限..."
chmod 644 approval_data.json
chmod 644 approver_config.json 2>/dev/null
chmod 644 *.html 2>/dev/null
chmod 644 *.json 2>/dev/null

echo "✅ 权限设置完成"
echo ""

# 显示结果
echo "=================================="
echo "  ✅ 更新完成！"
echo "=================================="
echo ""
echo "🌐 访问地址："
echo "   - http://blitzepanda.top/approvalquery/"
echo "   - http://139.224.200.133/approvalquery/"
echo ""

# 显示数据统计
if [ -f "approval_data.json" ]; then
    echo "📊 数据统计："
    python3 << 'PYEOF'
import json
try:
    with open('approval_data.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    stats = data['stats']
    print(f"   总门店数: {stats['total']}")
    print(f"   已通过: {stats['approved']}")
    print(f"   审批中: {stats['in_progress']}")
    print(f"   已驳回: {stats['rejected']}")
    print(f"   已撤销: {stats['withdrawn']}")
except Exception as e:
    print(f"   无法读取统计信息: {e}")
PYEOF
fi

echo ""
echo "💡 提示："
echo "   - 如需验证配置: python3 test_approver_config.py"
echo "   - 如需管理审批人员: python3 manage_approvers.py"
echo "   - 如需查看日志: tail -50 /var/log/nginx/error.log"
echo ""
