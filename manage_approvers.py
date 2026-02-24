#!/usr/bin/env python3
"""审批人员管理工具"""
import json
import os
from datetime import datetime

CONFIG_FILE = 'approver_config.json'

def load_config():
    if not os.path.exists(CONFIG_FILE):
        print(f'❌ 配置文件不存在: {CONFIG_FILE}')
        return None
    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_config(config):
    with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
        json.dump(config, f, ensure_ascii=False, indent=2)
    print(f'✅ 配置已保存')

def show_approvers():
    config = load_config()
    if not config:
        return
    
    print('\n当前审批节点配置：\n')
    for key, info in config['审批节点配置'].items():
        names = ' / '.join(info['names'])
        print(f'{info["label"]:<15} {names}')

def update_approver():
    config = load_config()
    if not config:
        return
    
    print('\n更新审批人员\n')
    nodes = list(config['审批节点配置'].keys())
    for i, node in enumerate(nodes, 1):
        info = config['审批节点配置'][node]
        names = ' / '.join(info['names'])
        print(f'{i}. {info["label"]} - 当前: {names}')
    
    try:
        choice = int(input('\n选择节点编号 (0=取消): '))
        if choice == 0 or choice < 1 or choice > len(nodes):
            return
        
        node_key = nodes[choice - 1]
        node_info = config['审批节点配置'][node_key]
        
        new_names = input('输入新负责人（多个用逗号分隔）: ').strip()
        if not new_names:
            print('❌ 负责人不能为空')
            return
        
        old_names = node_info['names']
        node_info['names'] = [name.strip() for name in new_names.split(',')]
        
        config['更新记录'].append({
            '日期': datetime.now().strftime('%Y-%m-%d'),
            '变更': f'{node_key}从"{"/".join(old_names)}"变更为"{"/".join(node_info["names"])}"'
        })
        
        save_config(config)
        print(f'\n✅ 已更新为: {" / ".join(node_info["names"])}')
        print('\n⚠️  记得重新生成数据: python parse_excel.py')
        
    except (ValueError, KeyboardInterrupt):
        print('\n已取消')

def main():
    while True:
        print('\n' + '='*50)
        print('审批人员管理')
        print('='*50)
        print('1. 查看配置')
        print('2. 更新人员')
        print('0. 退出')
        
        try:
            choice = input('\n选择: ').strip()
            if choice == '1':
                show_approvers()
            elif choice == '2':
                update_approver()
            elif choice == '0':
                break
        except KeyboardInterrupt:
            print('\n\n再见！')
            break

if __name__ == '__main__':
    main()
