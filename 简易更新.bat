@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo 📤 简易数据更新工具
echo ========================================
echo.
echo 💡 使用方法:
echo    1. 把新的Excel文件改名为: 线上建店审批.xlsx
echo    2. 放到这个bat文件同一目录
echo    3. 双击运行这个bat文件
echo.
echo ========================================
echo.

REM 检查Excel文件
if not exist "线上建店审批.xlsx" (
    echo ❌ 错误: 找不到 线上建店审批.xlsx
    echo.
    echo 💡 请确保:
    echo    1. Excel文件名是: 线上建店审批.xlsx
    echo    2. 文件在当前目录下
    echo.
    pause
    exit /b 1
)

echo ✅ 找到Excel文件
echo.

REM 检查Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误: 未安装Python
    echo.
    echo 💡 请先安装Python: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM 检查依赖
echo 🔍 检查依赖...
pip show openpyxl >nul 2>&1
if errorlevel 1 (
    echo 📦 安装 openpyxl...
    pip install openpyxl >nul 2>&1
)

pip show pandas >nul 2>&1
if errorlevel 1 (
    echo 📦 安装 pandas...
    pip install pandas >nul 2>&1
)

echo ✅ 依赖检查完成
echo.

REM 解析数据
echo 📊 解析Excel数据...
python parse_excel.py "线上建店审批.xlsx"
if errorlevel 1 (
    echo ❌ 解析失败
    pause
    exit /b 1
)

echo ✅ 数据解析完成
echo.

REM 读取配置
if not exist "server_config.txt" (
    echo 💡 首次使用，请配置服务器信息
    echo.
    set /p SERVER_IP="服务器IP (例如: 139.224.200.133): "
    set /p SERVER_USER="用户名 (直接回车默认root): "
    if "!SERVER_USER!"=="" set SERVER_USER=root
    
    echo !SERVER_IP!>server_config.txt
    echo !SERVER_USER!>>server_config.txt
    echo.
)

set /p SERVER_IP=<server_config.txt
for /f "skip=1 delims=" %%a in (server_config.txt) do (
    set SERVER_USER=%%a
    goto :loaded
)
:loaded

echo 📤 上传到服务器: %SERVER_USER%@%SERVER_IP%
echo.

REM 检查scp
where scp >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误: 未安装Git for Windows
    echo.
    echo 💡 请安装: https://git-scm.com/download/win
    pause
    exit /b 1
)

REM 上传
echo 🚀 上传中...
scp approval_data.json %SERVER_USER%@%SERVER_IP%:/var/www/approval-viewer/approvalquery/
if errorlevel 1 (
    echo.
    echo ❌ 上传失败
    echo.
    echo 💡 请检查:
    echo    1. 能否SSH连接: ssh %SERVER_USER%@%SERVER_IP%
    echo    2. 删除 server_config.txt 重新配置
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ 更新成功！
echo ========================================
echo.
echo 🌐 访问: http://blitzepanda.top/approvalquery
echo.
echo 💡 按 Ctrl+F5 刷新浏览器
echo.
pause
