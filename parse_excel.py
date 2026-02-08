"""
解析Excel文件，生成JSON数据供前端展示
支持两种格式：
1. 企微审批导出格式（线上建店审批.xlsx）
2. 建店进度格式（线上建店进度.xlsx）
"""
import pandas as pd
import json
from datetime import datetime
import re
import sys

def detect_excel_format(df):
    """
    检测Excel格式类型
    返回: 'approval' 或 'progress'
    """
    columns = set(df.columns)
    
    # 审批格式的特征列
    approval_columns = {'审批单编号', '门店编码', '门店名称', '当前审批状态', '审批流程'}
    # 进度格式的特征列
    progress_columns = {'门店号', '店铺名称', '建店单', '资料包'}
    
    if approval_columns.issubset(columns):
        return 'approval'
    elif progress_columns.issubset(columns):
        return 'progress'
    else:
        # 默认尝试审批格式
        return 'approval'

def parse_approval_flow(flow_text, status):
    """
    解析审批流程文本，提取关键审批节点
    """
    if pd.isna(flow_text):
        return [], []
    
    # 定义9个关键审批节点
    key_approvers = {
        '财务部-1': {'names': ['贺龙娇', '诸静逸'], 'label': '财务审批-1', 'completed': False, 'time': None},
        '财务部-2': {'names': ['谢珍珍', '杨文慧'], 'label': '财务审批-2', 'completed': False, 'time': None},
        '装修审核': {'names': ['施工监理-范钟欣', '范钟欣'], 'label': '装修审核', 'completed': False, 'time': None},
        '培训部': {'names': ['王伟清'], 'label': '培训审批', 'completed': False, 'time': None},
        '视频监控': {'names': ['刘崇宇'], 'label': '视频监控', 'completed': False, 'time': None},
        '线下运营': {'names': ['蔡文佳'], 'label': '线下运营', 'completed': False, 'time': None},
        '信息收集': {'names': ['线下堂食助理-婷婷', '婷婷'], 'label': '信息收集', 'completed': False, 'time': None},
        '督导部': {'names': ['单玮'], 'label': '督导审批', 'completed': False, 'time': None},
        '最终审批': {'names': ['苏磊'], 'label': '最终审批', 'completed': False, 'time': None}
    }
    
    lines = str(flow_text).split('\n')
    
    # 解析审批流程
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        if '已同意' not in line and '审批中' not in line:
            continue
            
        for key, info in key_approvers.items():
            for name in info['names']:
                if name in line and '已同意' in line:
                    info['completed'] = True
                    time_match = re.search(r'(\d{1,2}/\d{1,2}\s+\d{1,2}:\d{2})', line)
                    if time_match:
                        info['time'] = time_match.group(1)
                    break
    
    # 构建节点列表
    completed_nodes = []
    pending_nodes = []
    
    node_order = [
        '财务部-1', '财务部-2', '装修审核', '培训部', 
        '视频监控', '线下运营', '信息收集', '督导部', '最终审批'
    ]
    
    for key in node_order:
        info = key_approvers[key]
        node = {
            'key': key,
            'label': info['label'],
            'approver': ' / '.join(info['names']),
            'completed': info['completed'],
            'time': info['time']
        }
        
        if info['completed']:
            completed_nodes.append(node)
        else:
            pending_nodes.append(node)
    
    return completed_nodes, pending_nodes

def clean_value(value):
    """清理数据值，处理NaN和None"""
    if pd.isna(value):
        return ''
    if isinstance(value, float):
        if value != value:  # NaN检查
            return ''
        if value == float('inf') or value == float('-inf'):
            return ''
    return value

def parse_approval_format(df):
    """解析审批格式的Excel"""
    stores = []
    approved_count = 0
    rejected_count = 0
    in_progress_count = 0
    withdrawn_count = 0
    
    for idx, row in df.iterrows():
        current_status = row.get('当前审批状态', '')
        if pd.isna(current_status):
            current_status = ''
        
        # 解析审批流程
        completed_nodes, pending_nodes = parse_approval_flow(row.get('审批流程', ''), current_status)
        all_nodes = completed_nodes + pending_nodes
        
        # 检查最终审批
        sulei_approved = any(node['key'] == '最终审批' and node['completed'] for node in all_nodes)
        if sulei_approved and current_status == '审批中':
            current_status = '已通过'
        
        # 计算进度
        total_nodes = len(all_nodes)
        completed_count = len(completed_nodes)
        progress_percentage = (completed_count / total_nodes * 100) if total_nodes > 0 else 0
        
        # 计算耗时
        duration_days = None
        if pd.notna(row.get('提交时间')) and pd.notna(row.get('完成时间')):
            try:
                submit_str = str(row['提交时间'])
                complete_str = str(row['完成时间'])
                submit_match = re.search(r'(\d{4})年(\d{1,2})月(\d{1,2})日', submit_str)
                complete_match = re.search(r'(\d{4})年(\d{1,2})月(\d{1,2})日', complete_str)
                
                if submit_match and complete_match:
                    submit_date = datetime(int(submit_match.group(1)), int(submit_match.group(2)), int(submit_match.group(3)))
                    complete_date = datetime(int(complete_match.group(1)), int(complete_match.group(2)), int(complete_match.group(3)))
                    duration_days = (complete_date - submit_date).days
            except:
                pass
        
        # 统计
        if current_status == '已通过':
            approved_count += 1
        elif current_status == '已驳回':
            rejected_count += 1
        elif current_status == '审批中':
            in_progress_count += 1
        elif current_status == '已撤销':
            withdrawn_count += 1
        
        store = {
            'id': int(row.get('审批单编号', idx)),
            'store_code': int(row['门店编码']) if pd.notna(row.get('门店编码')) else None,
            'store_name': clean_value(row.get('门店名称', '')),
            'city': clean_value(row.get('门店所在城市', '')),
            'franchisee': clean_value(row.get('加盟商', '')),
            'opening_date': clean_value(row.get('建店时间', '')),
            'submit_time': clean_value(row.get('提交时间', '')),
            'complete_time': clean_value(row.get('完成时间', '')),
            'status': current_status,
            'original_status': clean_value(row.get('当前审批状态', '')),
            'applicant': clean_value(row.get('申请人', '')),
            'department': clean_value(row.get('申请人部门', '')),
            'duration_days': duration_days,
            'contract_signed': clean_value(row.get('合同签订', '')),
            'decoration': clean_value(row.get('装修', '')),
            'training': clean_value(row.get('开业培训（理论&实操）', '')),
            'equipment': clean_value(row.get('设备采购', '')),
            'license': clean_value(row.get('营业执照', '')),
            'food_permit': clean_value(row.get('食品经营许可证', '')),
            'trial_operation': clean_value(row.get('试营业3天', '')),
            'approval_nodes': all_nodes,
            'completed_nodes': completed_nodes,
            'pending_nodes': pending_nodes,
            'approval_count': total_nodes,
            'completed_count': completed_count,
            'progress_percentage': round(progress_percentage, 1)
        }
        
        stores.append(store)
    
    stats = {
        'total': len(df),
        'approved': approved_count,
        'rejected': rejected_count,
        'in_progress': in_progress_count,
        'withdrawn': withdrawn_count
    }
    
    return stores, stats

def parse_progress_format(df):
    """解析进度格式的Excel"""
    stores = []
    approved_count = 0
    in_progress_count = 0
    
    for idx, row in df.iterrows():
        # 从建店单和资料包状态判断进度
        jiandian_status = str(row.get('建店单', '')).strip()
        ziliao_status = str(row.get('资料包', '')).strip()
        approval_status = row.get('当前审批状态', '')
        
        # 判断状态
        if pd.notna(approval_status) and approval_status:
            current_status = str(approval_status)
        elif jiandian_status == '已提交' and ziliao_status == '已收集':
            current_status = '审批中'
        elif jiandian_status == '已提交':
            current_status = '审批中'
        else:
            current_status = '准备中'
        
        # 解析审批流程（如果有）
        completed_nodes, pending_nodes = parse_approval_flow(row.get('审批流程', ''), current_status)
        all_nodes = completed_nodes + pending_nodes
        
        # 如果没有审批流程，根据状态创建简单节点
        if not all_nodes:
            if jiandian_status == '已提交':
                completed_nodes.append({
                    'key': '建店单',
                    'label': '建店单提交',
                    'approver': '运营',
                    'completed': True,
                    'time': None
                })
            if ziliao_status == '已收集':
                completed_nodes.append({
                    'key': '资料包',
                    'label': '资料包收集',
                    'approver': '运营',
                    'completed': True,
                    'time': None
                })
            all_nodes = completed_nodes + pending_nodes
        
        # 计算进度
        total_nodes = max(len(all_nodes), 2)  # 至少2个节点
        completed_count = len(completed_nodes)
        progress_percentage = (completed_count / total_nodes * 100) if total_nodes > 0 else 0
        
        # 统计
        if current_status == '已通过':
            approved_count += 1
        else:
            in_progress_count += 1
        
        # 处理日期（Excel日期格式）
        opening_date = ''
        if pd.notna(row.get('预计开业')):
            try:
                # 尝试转换Excel日期数字
                date_val = row['预计开业']
                if isinstance(date_val, (int, float)):
                    # Excel日期从1900-01-01开始
                    base_date = datetime(1899, 12, 30)
                    opening_date = (base_date + pd.Timedelta(days=int(date_val))).strftime('%Y-%m-%d')
                else:
                    opening_date = str(date_val)
            except:
                opening_date = str(row.get('预计开业', ''))
        
        store = {
            'id': int(row.get('门店号', idx)),
            'store_code': int(row['门店号']) if pd.notna(row.get('门店号')) else None,
            'store_name': clean_value(row.get('店铺名称', '')),
            'city': clean_value(row.get('省份', '')),
            'franchisee': clean_value(row.get('运营', '')),
            'opening_date': opening_date,
            'submit_time': '',
            'complete_time': '',
            'status': current_status,
            'original_status': current_status,
            'applicant': clean_value(row.get('运营', '')),
            'department': clean_value(row.get('战区', '')),
            'duration_days': None,
            'contract_signed': clean_value(jiandian_status),
            'decoration': '',
            'training': '',
            'equipment': '',
            'license': '',
            'food_permit': '',
            'trial_operation': clean_value(ziliao_status),
            'approval_nodes': all_nodes,
            'completed_nodes': completed_nodes,
            'pending_nodes': pending_nodes,
            'approval_count': total_nodes,
            'completed_count': completed_count,
            'progress_percentage': round(progress_percentage, 1)
        }
        
        stores.append(store)
    
    stats = {
        'total': len(df),
        'approved': approved_count,
        'rejected': 0,
        'in_progress': in_progress_count,
        'withdrawn': 0
    }
    
    return stores, stats

def parse_excel_to_json(excel_path, output_path='approval_data.json'):
    """解析Excel文件并生成JSON"""
    print(f'📖 读取文件: {excel_path}')
    df = pd.read_excel(excel_path)
    
    # 检测格式
    format_type = detect_excel_format(df)
    print(f'📋 检测到格式: {"审批格式" if format_type == "approval" else "进度格式"}')
    
    # 根据格式解析
    if format_type == 'approval':
        stores, stats = parse_approval_format(df)
    else:
        stores, stats = parse_progress_format(df)
    
    # 生成输出数据
    output_data = {
        'stats': stats,
        'stores': stores,
        'generated_at': datetime.now().isoformat(),
        'source_format': format_type
    }
    
    # 写入JSON文件（处理NaN值）
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2, allow_nan=False)
    
    print(f'\n✅ 数据解析完成！')
    print(f'总计: {stats["total"]} 个门店')
    print(f'已通过: {stats["approved"]} 个')
    print(f'审批中: {stats["in_progress"]} 个')
    print(f'已驳回: {stats["rejected"]} 个')
    print(f'已撤销: {stats["withdrawn"]} 个')
    print(f'\n💾 数据已保存到: {output_path}')

if __name__ == '__main__':
    # 支持命令行参数
    if len(sys.argv) > 1:
        excel_file = sys.argv[1]
        output_file = sys.argv[2] if len(sys.argv) > 2 else 'approval_data.json'
    else:
        excel_file = '线上建店审批.xlsx'
        output_file = 'approval_data.json'
    
    try:
        parse_excel_to_json(excel_file, output_file)
    except Exception as e:
        print(f'\n❌ 错误: {e}')
        import traceback
        traceback.print_exc()
        sys.exit(1)
