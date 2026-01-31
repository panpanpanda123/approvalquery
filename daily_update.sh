#!/bin/bash
# 每日数据更新脚本

set -e

PROJECT_DIR="/var/www/approval-viewer"

echo "========================================"
echo "审批数据更新脚本"
echo "========================================"
echo ""

# 检查参数
if [ $# -eq 0 ]; then
    echo "使用方法:"
    echo "  $0 <新Excel文件路径>"
    echo ""
    echo "示例:"
    echo "  $0 /root/新审批数据.xlsx"
    echo "  $0 ~/Downloads/审批-2026-01-31.xlsx"
    echo ""
    exit 1
fi

NEW_FILE="$1"

# 检查文件是否存在
if [ ! -f "$NEW_FILE" ]; then
    echo "❌ 错误: 文件不存在 - $NEW_FILE"
    exit 1
fi

echo "📁 新文件: $(basename "$NEW_FILE")"
echo "📂 项目目录: $PROJECT_DIR"
echo ""

# 进入项目目录
cd $PROJECT_DIR

# 备份旧文件
if [ -f "线上建店审批.xlsx" ]; then
    BACKUP_NAME="线上建店审批_backup_$(date +%Y%m%d_%H%M%S).xlsx"
    cp "线上建店审批.xlsx" "$BACKUP_NAME"
    echo "💾 已备份旧文件: $BACKUP_NAME"
fi

# 复制新文件
cp "$NEW_FILE" "线上建店审批.xlsx"
echo "✅ 已复制新文件"
echo ""

# 重新生成数据
echo "🔄 正在解析数据..."
python3 parse_excel.py
echo ""

# 显示结果
if [ -f "approval_data.json" ]; then
    # 设置正确的文件权限
    chmod 644 approval_data.json
    echo "✅ 已设置文件权限"
    
    echo "========================================"
    echo "✅ 更新完成！"
    echo "========================================"
    echo ""
    echo "📊 数据文件: approval_data.json"
    echo "📅 更新时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "🌐 访问地址: http://blitzepanda.top/approvalquery"
    echo ""
    echo "💡 提示: 刷新浏览器查看最新数据 (Ctrl+F5)"
    echo ""
    
    # 清理7天前的备份
    OLD_BACKUPS=$(find . -name "*_backup_*.xlsx" -mtime +7 2>/dev/null | wc -l)
    if [ $OLD_BACKUPS -gt 0 ]; then
        echo "🧹 清理 $OLD_BACKUPS 个旧备份文件..."
        find . -name "*_backup_*.xlsx" -mtime +7 -delete
    fi
    
    echo "========================================"
else
    echo "❌ 错误: 数据生成失败"
    exit 1
fi
