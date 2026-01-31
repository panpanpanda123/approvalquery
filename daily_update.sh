#!/bin/bash
# 服务器端数据更新脚本

set -e

PROJECT_DIR="/var/www/approval-viewer/approvalquery"

echo "========================================"
echo "📤 审批数据更新"
echo "========================================"
echo ""

# 检查参数
if [ $# -eq 0 ]; then
    echo "使用方法:"
    echo "  $0 <新Excel文件路径>"
    echo ""
    echo "示例:"
    echo "  $0 /root/新审批数据.xlsx"
    echo ""
    exit 1
fi

NEW_FILE="$1"

# 检查文件是否存在
if [ ! -f "$NEW_FILE" ]; then
    echo "❌ 文件不存在: $NEW_FILE"
    exit 1
fi

echo "📁 新文件: $(basename "$NEW_FILE")"
echo ""

# 进入项目目录
cd $PROJECT_DIR

# 备份旧文件
if [ -f "线上建店审批.xlsx" ]; then
    BACKUP_NAME="线上建店审批_backup_$(date +%Y%m%d_%H%M%S).xlsx"
    cp "线上建店审批.xlsx" "$BACKUP_NAME"
    echo "💾 已备份: $BACKUP_NAME"
fi

# 复制新文件
cp "$NEW_FILE" "线上建店审批.xlsx"
echo "✅ 已更新Excel文件"
echo ""

# 重新生成数据
echo "🔄 解析数据..."
python3 parse_excel.py

# 设置权限
chmod 644 approval_data.json
chown www-data:www-data approval_data.json

echo ""
echo "========================================"
echo "✅ 更新完成！"
echo "========================================"
echo ""
echo "🌐 访问: http://blitzepanda.top/approvalquery"
echo "💡 刷新浏览器 (Ctrl+F5) 查看最新数据"
echo ""

# 清理7天前的备份
find . -name "*_backup_*.xlsx" -mtime +7 -delete 2>/dev/null || true
