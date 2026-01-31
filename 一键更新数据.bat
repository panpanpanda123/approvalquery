@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo 📤 审批数据一键更新工具
echo ========================================
echo.
echo 💡 使用说明:
echo    1. 把新下载的Excel文件放到这个bat文件同一目录
echo    2. 双击运行这个bat文件
echo    3. 输入Excel文件名
echo.
echo ========================================
echo.

REM 检查Python是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误: 未检测到Python，请先安装Python
    echo.
    echo 💡 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM 检查依赖
echo 🔍 检查依赖...
pip show openpyxl >nul 2>&1
if errorlevel 1 (
    echo 📦 正在安装依赖 openpyxl...
    pip install openpyxl
    echo.
)

pip show pandas >nul 2>&1
if errorlevel 1 (
    echo 📦 正在安装依赖 pandas...
    pip install pandas
    echo.
)

REM 列出当前目录的Excel文件
echo 📁 当前目录的Excel文件:
echo.
dir /b *.xlsx 2>nul
if errorlevel 1 (
    echo    (没有找到Excel文件)
)
echo.

REM 获取Excel文件名
set /p EXCEL_FILE="请输入Excel文件名 (例如: 线上建店审批.xlsx): "

REM 检查文件是否存在
if not exist "%EXCEL_FILE%" (
    echo.
    echo ❌ 错误: 文件不存在
    echo.
    echo � 请确保Excel文件在当前目录下
    pause
    exit /b 1
)

echo.
echo ========================================
echo � 步骤 1/2: 解析Exc=el数据
echo ========================================
echo.

REM 解析Excel生成JSON
python parse_excel.py "%EXCEL_FILE%"
if errorlevel 1 (
    echo.
    echo ❌ 数据解析失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo 📤 步骤 2/2: 上传到服务器
echo ========================================
echo.

REM 读取或创建配置
if not exist "server_config.txt" (
    echo 💡 首次使用需要配置服务器信息
    echo.
    set /p SERVER_IP="请输入服务器IP地址 (例如: 139.224.200.133): "
    set /p SERVER_USER="请输入服务器用户名 (默认root): "
    if "!SERVER_USER!"=="" set SERVER_USER=root
    
    echo !SERVER_IP!>server_config.txt
    echo !SERVER_USER!>>server_config.txt
    echo.
    echo ✅ 配置已保存到 server_config.txt
    echo.
) else (
    REM 读取配置
    set /p SERVER_IP=<server_config.txt
    for /f "skip=1 delims=" %%a in (server_config.txt) do (
        set SERVER_USER=%%a
        goto :config_loaded
    )
    :config_loaded
)

echo 🌐 服务器: %SERVER_USER%@%SERVER_IP%
echo 📁 上传文件: approval_data.json
echo.

REM 检查scp命令
where scp >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误: 未找到scp命令
    echo.
    echo 💡 请安装 Git for Windows: https://git-scm.com/download/win
    echo    安装后重启电脑
    echo.
    pause
    exit /b 1
)

REM 上传文件（支持密钥登录）
echo 🚀 正在上传...
echo.
echo 💡 如果使用SSH密钥登录，直接按回车
echo    如果使用密码登录，输入密码后按回车
echo.

scp approval_data.json %SERVER_USER%@%SERVER_IP%:/var/www/approval-viewer/approvalquery/
if errorlevel 1 (
    echo.
    echo ❌ 上传失败
    echo.
    echo 💡 可能的原因:
    echo    1. 服务器IP地址不对 (当前: %SERVER_IP%)
    echo    2. SSH密钥未配置或密码错误
    echo    3. 服务器路径不存在
    echo.
    echo 💡 修改配置: 删除 server_config.txt 后重新运行
    echo.
    echo 💡 测试SSH连接:
    echo    ssh %SERVER_USER%@%SERVER_IP%
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ 完成！
echo ========================================
echo.
echo 🎉 数据更新成功！
echo.
echo 🌐 访问地址: 
echo    http://blitzepanda.top/approvalquery
echo    http://%SERVER_IP%/approvalquery
echo.
echo 💡 提示: 按 Ctrl+F5 强制刷新浏览器查看最新数据
echo.
echo ========================================
pause
