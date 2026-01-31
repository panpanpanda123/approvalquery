# 审批进度可视化系统

企微审批数据可视化工具，支持9项关键审批追踪。

## 快速开始

### 1. 安装依赖
```bash
pip install -r requirements.txt
```

### 2. 生成数据
```bash
python parse_excel.py
```

### 3. 启动服务器
```bash
python deploy_server.py
```

访问: http://localhost:8080

## 更新数据

```bash
python update_excel.py 新文件.xlsx
```

## 功能特点

- ✅ 9项关键审批追踪
- ✅ 3x3网格可视化
- ✅ 审批时间显示
- ✅ 点击卡片筛选
- ✅ 搜索和筛选
- ✅ 响应式设计

## 项目结构

```
temp_view/
├── index.html           # 前端页面
├── parse_excel.py       # 数据解析
├── deploy_server.py     # 生产服务器
├── update_excel.py      # 数据更新
├── requirements.txt     # 依赖
└── README.md           # 本文件
```

详细部署说明见 [README_DEPLOY.md](README_DEPLOY.md)
