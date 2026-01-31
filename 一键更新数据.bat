@echo off
chcp 65001 >nul
echo ========================================
echo 📤 审批数据一键更新工具
echo ========================================
echo.
echo 💡 使用说明:
echo    1. 把新下载的Excel文件拖到这个窗口
echo    2. 按回车键
echo    3. 等待上传完成
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

REM 获取Excel文件路径
set /p EXCEL_FILE="📁 请拖入新的Excel文件，然后按回车: "

REM 去除引号
set EXCEL_FILE=%EXCEL_FILE:"=%

REM 检查文件是否存在
if not exist "%EXCEL_FILE%" (
    echo.
    echo ❌ 错误: 文件不存在
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo 📊 步骤 1/3: 解析Excel数据
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
echo 📤 步骤 2/3: 上传到服务器
echo ========================================
echo.

REM 提示输入服务器信息（首次使用）
if not exist "server_config.txt" (
    echo 💡 首次使用需要配置服务器信息
    echo.
    set /p SERVER_IP="请输入服务器IP地址: "
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
    echo 💡 请安装以下工具之一:
    echo    - Git for Windows (推荐): https://git-scm.com/download/win
    echo    - OpenSSH: 在Windows设置中启用
    echo.
    pause
    exit /b 1
)

REM 上传文件
echo 🚀 正在上传...
scp approval_data.json %SERVER_USER%@%SERVER_IP%:/var/www/approval-viewer/
if errorlevel 1 (
    echo.
    echo ❌ 上传失败，请检查:
    echo    1. 服务器IP地址是否正确
    echo    2. 是否能SSH连接到服务器
    echo    3. 服务器路径是否正确
    echo.
    echo 💡 如需修改配置，请删除 server_config.txt 后重新运行
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ 步骤 3/3: 完成！
echo ========================================
echo.
echo 🎉 数据更新成功！
echo.
echo 🌐 访问地址: http://blitzepanda.top/approvalquery
echo.
echo 💡 提示: 按 Ctrl+F5 强制刷新浏览器查看最新数据
echo.
echo ========================================
pause
