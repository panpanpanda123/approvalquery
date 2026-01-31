"""
Excel文件更新脚本
用于替换旧的Excel文件并重新生成数据
"""
import os
import sys
import shutil
from datetime import datetime

def update_excel(new_file_path):
    """
    更新Excel文件
    
    参数:
        new_file_path: 新Excel文件的路径
    """
    print("=" * 70)
    print("📤 更新审批数据")
    print("=" * 70)
    print()
    
    # 检查新文件是否存在
    if not os.path.exists(new_file_path):
        print(f"❌ 错误: 文件不存在 - {new_file_path}")
        return False
    
    print(f"📁 新文件: {os.path.basename(new_file_path)}")
    
    # 目标文件名
    target_file = '线上建店审批.xlsx'
    
    # 备份旧文件（如果存在）
    if os.path.exists(target_file):
        backup_file = f'线上建店审批_backup_{datetime.now().strftime("%Y%m%d_%H%M%S")}.xlsx'
        shutil.copy(target_file, backup_file)
        print(f"💾 已备份旧文件: {backup_file}")
        
        # 删除旧文件
        os.remove(target_file)
        print(f"🗑️  已删除旧文件: {target_file}")
    
    # 复制新文件
    shutil.copy(new_file_path, target_file)
    print(f"✅ 已复制新文件: {target_file}")
    print()
    
    # 运行解析脚本
    print("🔄 开始解析数据...")
    print()
    
    try:
        from parse_excel import parse_excel_to_json
        parse_excel_to_json(target_file, 'approval_data.json')
        print()
        print("=" * 70)
        print("✅ 更新完成！")
        print("=" * 70)
        print()
        print("💡 下一步:")
        print("   刷新浏览器页面查看最新数据")
        print()
        return True
    except Exception as e:
        print(f"❌ 解析失败: {e}")
        return False

def main():
    """主函数"""
    if len(sys.argv) < 2:
        print("=" * 70)
        print("📤 Excel文件更新工具")
        print("=" * 70)
        print()
        print("使用方法:")
        print(f"  python {sys.argv[0]} <新Excel文件路径>")
        print()
        print("示例:")
        print(f"  python {sys.argv[0]} 新下载的审批数据.xlsx")
        print()
        return
    
    new_file = sys.argv[1]
    update_excel(new_file)

if __name__ == '__main__':
    main()
