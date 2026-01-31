"""
解析企微审批Excel文件，生成JSON数据供前端展示
"""
import pandas as pd
import json
from datetime import datetime
import re

def parse_approval_flow(flow_text, status):
    """
    解析审批流程文本，提取关键审批节点
    
    只关注9个关键审批节点（忽略抄送）：
    1. 财务部（贺龙娇/诸静逸/谢珍珍/杨文慧）- 2项审批
    2. 施工监理-范钟欣 - 装修审核
    3. 王伟清 - 培训部
    4. 刘崇宇 - 视频监控
    5. 蔡文佳 - 线下运营
    6. 线下堂食助理-婷婷 - 信息收集
    7. 单玮 - 督导部
    8. 苏磊 - 最终审批
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
    
    lines = flow_text.split('\n')
    
    # 解析审批流程，只关注"已同意"和"审批中"
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        # 只匹配"已同意"和"审批中"，忽略"已抄送"
        if '已同意' not in line and '审批中' not in line:
            continue
            
        # 检查是否是关键审批人
        for key, info in key_approvers.items():
            for name in info['names']:
                if name in line and '已同意' in line:
                    info['completed'] = True
                    # 提取时间：格式如 "1/23 20:21"
                    time_match = re.search(r'(\d{1,2}/\d{1,2}\s+\d{1,2}:\d{2})', line)
                    if time_match:
                        info['time'] = time_match.group(1)
                    break
    
    # 构建已完成和待审批节点列表
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
            'time': info['time']  # 添加时间字段
        }
        
        if info['completed']:
            completed_nodes.append(node)
        else:
            pending_nodes.append(node)
    
    return completed_nodes, pending_nodes

def parse_excel_to_json(excel_path, output_path):
    """解析Excel文件并生成JSON"""
    df = pd.read_excel(excel_path)
    
    # 处理每个门店
    stores = []
    approved_count = 0
    rejected_count = 0
    in_progress_count = 0
    withdrawn_count = 0
    
    for idx, row in df.iterrows():
        current_status = row['当前审批状态'] if pd.notna(row['当前审批状态']) else ''
        
        # 解析审批流程
        completed_nodes, pending_nodes = parse_approval_flow(row.get('审批流程', ''), current_status)
        all_nodes = completed_nodes + pending_nodes
        
        # 检查苏磊是否已审批 - 如果苏磊已同意，标记为已通过
        sulei_approved = any(node['key'] == '最终审批' and node['completed'] for node in all_nodes)
        
        # 更新状态：如果苏磊已审批，强制标记为已通过
        if sulei_approved and current_status == '审批中':
            current_status = '已通过'
        
        # 计算审批进度
        total_nodes = len(all_nodes)
        completed_count = len(completed_nodes)
        progress_percentage = (completed_count / total_nodes * 100) if total_nodes > 0 else 0
        
        # 计算审批耗时（天数）
        duration_days = None
        if pd.notna(row.get('提交时间')) and pd.notna(row.get('完成时间')):
            try:
                # 解析中文日期格式：2026年1月8日 10:16
                submit_str = str(row['提交时间'])
                complete_str = str(row['完成时间'])
                
                # 提取日期部分
                submit_match = re.search(r'(\d{4})年(\d{1,2})月(\d{1,2})日', submit_str)
                complete_match = re.search(r'(\d{4})年(\d{1,2})月(\d{1,2})日', complete_str)
                
                if submit_match and complete_match:
                    submit_date = datetime(int(submit_match.group(1)), int(submit_match.group(2)), int(submit_match.group(3)))
                    complete_date = datetime(int(complete_match.group(1)), int(complete_match.group(2)), int(complete_match.group(3)))
                    duration_days = (complete_date - submit_date).days
            except Exception as e:
                print(f"解析日期失败: {e}")
                pass
        
        # 统计各状态数量
        if current_status == '已通过':
            approved_count += 1
        elif current_status == '已驳回':
            rejected_count += 1
        elif current_status == '审批中':
            in_progress_count += 1
        elif current_status == '已撤销':
            withdrawn_count += 1
        
        store = {
            'id': int(row['审批单编号']),
            'store_code': int(row['门店编码']) if pd.notna(row['门店编码']) else None,
            'store_name': row['门店名称'] if pd.notna(row['门店名称']) else '',
            'city': row['门店所在城市'] if pd.notna(row['门店所在城市']) else '',
            'franchisee': row['加盟商'] if pd.notna(row['加盟商']) else '',
            'opening_date': row['建店时间'] if pd.notna(row['建店时间']) else '',
            'submit_time': row['提交时间'] if pd.notna(row['提交时间']) else '',
            'complete_time': row['完成时间'] if pd.notna(row['完成时间']) else '',
            'status': current_status,
            'original_status': row['当前审批状态'] if pd.notna(row['当前审批状态']) else '',
            'applicant': row['申请人'] if pd.notna(row['申请人']) else '',
            'department': row['申请人部门'] if pd.notna(row['申请人部门']) else '',
            'duration_days': duration_days,
            
            # 关键节点状态
            'contract_signed': row['合同签订'] if pd.notna(row['合同签订']) else '',
            'decoration': row['装修'] if pd.notna(row['装修']) else '',
            'training': row['开业培训（理论&实操）'] if pd.notna(row['开业培训（理论&实操）']) else '',
            'equipment': row['设备采购'] if pd.notna(row['设备采购']) else '',
            'license': row['营业执照'] if pd.notna(row['营业执照']) else '',
            'food_permit': row['食品经营许可证'] if pd.notna(row['食品经营许可证']) else '',
            'trial_operation': row['试营业3天'] if pd.notna(row['试营业3天']) else '',
            
            # 审批流程节点
            'approval_nodes': all_nodes,
            'completed_nodes': completed_nodes,
            'pending_nodes': pending_nodes,
            'approval_count': total_nodes,
            'completed_count': completed_count,
            'progress_percentage': round(progress_percentage, 1)
        }
        
        stores.append(store)
    
    # 生成统计数据
    stats = {
        'total': len(df),
        'approved': approved_count,
        'rejected': rejected_count,
        'in_progress': in_progress_count,
        'withdrawn': withdrawn_count
    }
    
    # 生成输出数据
    output_data = {
        'stats': stats,
        'stores': stores,
        'generated_at': datetime.now().isoformat()
    }
    
    # 写入JSON文件
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)
    
    print(f'✅ 数据解析完成！')
    print(f'总计: {stats["total"]} 个审批')
    print(f'已通过: {stats["approved"]} 个')
    print(f'审批中: {stats["in_progress"]} 个')
    print(f'已驳回: {stats["rejected"]} 个')
    print(f'已撤销: {stats["withdrawn"]} 个')
    print(f'\n数据已保存到: {output_path}')

if __name__ == '__main__':
    import sys
    
    # 支持命令行参数
    if len(sys.argv) > 1:
        excel_file = sys.argv[1]
        output_file = sys.argv[2] if len(sys.argv) > 2 else 'approval_data.json'
    else:
        excel_file = '线上建店审批.xlsx'
        output_file = 'approval_data.json'
    
    parse_excel_to_json(excel_file, output_file)
