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
import os

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

# 审批节点定义：按角色关键词识别，不依赖具体人名
# 顺序即为审批流程顺序
APPROVAL_NODES = [
    {
        'key': '财务审批-1',
        'label': '财务审批',
        # 第一个出现的财务角色（无特定职位关键词，靠顺序判断）
        'keywords': [],
        'role_type': 'finance_1',  # 特殊处理：流程中第一个财务
    },
    {
        'key': '财务审批-2',
        'label': '财务复核',
        'keywords': [],
        'role_type': 'finance_2',  # 特殊处理：流程中第二个财务
    },
    {
        'key': '装修审核',
        'label': '装修审核',
        'keywords': ['施工监理', '装修'],
        'role_type': 'keyword',
    },
    {
        'key': '培训审批',
        'label': '培训审批',
        'keywords': ['培训', '商学院', '王伟清'],
        'role_type': 'keyword',
    },
    {
        'key': '视频监控',
        'label': '视频监控',
        'keywords': ['视频', '监控', '刘崇宇'],
        'role_type': 'keyword',
    },
    {
        'key': '线下运营',
        'label': '线下运营',
        'keywords': ['线下运营'],
        'role_type': 'keyword',
    },
    {
        'key': '信息收集',
        'label': '信息收集',
        'keywords': ['堂食助理', '线上助理'],
        'role_type': 'keyword',
    },
    {
        'key': '督导审批',
        'label': '督导审批',
        'keywords': ['督导部', '督导'],
        'role_type': 'keyword',
    },
    {
        'key': '最终审批',
        'label': '最终审批',
        # 最终审批通常是流程最后一个"已同意"且不属于其他角色的人
        'keywords': ['苏磊'],
        'role_type': 'final',
    },
]

# 明确排除的角色（抄送、助理等不算审批节点）
EXCLUDE_KEYWORDS = ['已抄送', '督导服务号', '谢芳', '卢家豪', '周幂', '翁嘉隆', '黄琪艳', '王京海', '鹿世鸣']


def classify_approver(name):
    """
    根据角色关键词判断审批人属于哪个节点
    返回节点key，或None（不属于任何关键节点）
    """
    for node in APPROVAL_NODES:
        if node['role_type'] in ('finance_1', 'finance_2'):
            continue  # 财务节点单独处理
        for kw in node['keywords']:
            if kw in name:
                return node['key']
    return None


def parse_approval_flow(flow_text, status):
    """
    解析审批流程文本，按角色关键词识别节点，不依赖具体人名。
    财务审批按出现顺序识别（第1、2个财务角色）。
    """
    if pd.isna(flow_text) or not str(flow_text).strip():
        return [], []

    # 初始化节点状态
    node_status = {node['key']: {'completed': False, 'time': None, 'approver': ''} for node in APPROVAL_NODES}

    # 按顺序解析每一行
    finance_count = 0  # 记录已出现的财务审批次数
    known_role_keywords = []
    for node in APPROVAL_NODES:
        known_role_keywords.extend(node['keywords'])

    for line in str(flow_text).split(';'):
        line = line.strip()
        if not line or '已同意' not in line:
            continue

        # 跳过抄送和排除角色
        if any(ex in line for ex in EXCLUDE_KEYWORDS):
            continue

        # 提取人名和时间
        match = re.search(r'已同意\s*\|\s*(.+?)\s+已同意\s+(\d{1,2}/\d{1,2}\s+\d{1,2}:\d{2})', line)
        if not match:
            # 尝试没有时间的格式
            match = re.search(r'已同意\s*\|\s*(.+?)\s+已同意', line)
            if not match:
                continue
            name = match.group(1).strip()
            time_val = ''
        else:
            name = match.group(1).strip()
            time_val = match.group(2).strip()

        # 跳过排除角色
        if any(ex in name for ex in EXCLUDE_KEYWORDS):
            continue

        # 先尝试关键词匹配
        matched_key = classify_approver(name)

        if matched_key:
            node_status[matched_key]['completed'] = True
            node_status[matched_key]['time'] = time_val
            node_status[matched_key]['approver'] = name
        else:
            # 没有匹配到关键词 → 判断是否是财务角色
            # 财务角色特征：不含任何已知角色关键词，且不在排除列表
            is_known = any(kw in name for kw in known_role_keywords)
            if not is_known:
                finance_count += 1
                if finance_count == 1:
                    node_status['财务审批-1']['completed'] = True
                    node_status['财务审批-1']['time'] = time_val
                    node_status['财务审批-1']['approver'] = name
                elif finance_count == 2:
                    node_status['财务审批-2']['completed'] = True
                    node_status['财务审批-2']['time'] = time_val
                    node_status['财务审批-2']['approver'] = name

    # 构建有序节点列表
    completed_nodes = []
    pending_nodes = []

    for node in APPROVAL_NODES:
        key = node['key']
        s = node_status[key]
        entry = {
            'key': key,
            'label': node['label'],
            'approver': s['approver'],
            'completed': s['completed'],
            'time': s['time'],
        }
        if s['completed']:
            completed_nodes.append(entry)
        else:
            pending_nodes.append(entry)

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
        completed_nodes, pending_nodes = parse_approval_flow(
            row.get('审批流程', ''),
            current_status
        )
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
        jiandian_status = str(row.get('建店单', '')).strip()
        ziliao_status = str(row.get('资料包', '')).strip()
        approval_status = row.get('当前审批状态', '')
        
        if pd.notna(approval_status) and approval_status:
            current_status = str(approval_status)
        elif jiandian_status == '已提交' and ziliao_status == '已收集':
            current_status = '审批中'
        elif jiandian_status == '已提交':
            current_status = '审批中'
        else:
            current_status = '准备中'
        
        # 解析审批流程
        completed_nodes, pending_nodes = parse_approval_flow(
            row.get('审批流程', ''),
            current_status
        )
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
