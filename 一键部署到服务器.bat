@echo off
chcp 65001 >nul
echo ====================================
echo   一键部署到服务器
echo ====================================
echo.

REM 服务器配置
set SERVER=root@139.224.200.133
set PROJECT_DIR=/var/www/approval-viewer/approvalquery

echo 📋 部署流程：
echo   1. 本地测试配置
echo   2. 提交到GitHub
echo   3. 服务器拉取更新
echo   4. 重新生成数据
echo.

REM 步骤1：本地测试
echo ====================================
echo 步骤1/4: 本地测试配置
echo ====================================
echo.

if exist "test_approver_config.py" (
    echo 🧪 运行配置测试...
    python test_approver_config.py
    if errorlevel 1 (
        echo.
        echo ❌ 配置测试失败，请先修复问题
        pause
        exit /b 1
    )
    echo.
) else (
    echo ⚠️  未找到测试脚本，跳过测试
    echo.
)

REM 步骤2：提交到GitHub
echo ====================================
echo 步骤2/4: 提交到GitHub
echo ====================================
echo.

REM 显示修改的文件
git status -s
echo.

set /p commit_msg="请输入提交说明（直接回车使用默认）: "
if "%commit_msg%"=="" (
    set commit_msg=更新审批系统 %date:~0,10%
)

echo.
echo 📝 提交信息: %commit_msg%
echo.

git add .
git commit -m "%commit_msg%"

if errorlevel 1 (
    echo ⚠️  没有需要提交的修改，继续部署...
    echo.
) else (
    echo 📤 推送到GitHub...
    git push origin main
    
    if errorlevel 1 (
        echo ❌ 推送失败
        pause
        exit /b 1
    )
    echo ✅ 推送成功
    echo.
)

REM 步骤3：服务器拉取更新
echo ====================================
echo 步骤3/4: 服务器拉取更新
echo ====================================
echo.

echo 🔗 连接服务器: %SERVER%
echo.

ssh %SERVER% "cd %PROJECT_DIR% && git pull origin main"

if errorlevel 1 (
    echo.
    echo ❌ 服务器拉取失败
    echo 请检查：
    echo   - SSH连接是否正常
    echo   - 服务器Git配置是否正确
    pause
    exit /b 1
)

echo ✅ 代码同步成功
echo.

REM 步骤4：重新生成数据
echo ====================================
echo 步骤4/4: 重新生成数据
echo ====================================
echo.

echo 📊 执行数据生成脚本...
echo.

ssh %SERVER% "cd %PROJECT_DIR% && python3 parse_excel.py && chmod 644 approval_data.json"

if errorlevel 1 (
    echo.
    echo ❌ 数据生成失败
    echo 请手动登录服务器检查
    pause
    exit /b 1
)

echo.
echo ====================================
echo   ✅ 部署完成！
echo ====================================
echo.

REM 验证部署
echo 🔍 验证部署结果...
echo.

ssh %SERVER% "cd %PROJECT_DIR% && python3 -c \"import json; data=json.load(open('approval_data.json')); print(f'总门店: {data[\\\"stats\\\"][\\\"total\\\"]}, 已通过: {data[\\\"stats\\\"][\\\"approved\\\"]}, 审批中: {data[\\\"stats\\\"][\\\"in_progress\\\"]}')\""

echo.
echo 🌐 访问地址：
echo    - http://blitzepanda.top/approvalquery/
echo    - http://139.224.200.133/approvalquery/
echo.
echo 💡 提示：
echo    - 按 Ctrl+F5 强制刷新浏览器
echo    - 如有问题，查看服务器日志：
echo      ssh %SERVER% "tail -50 /var/log/nginx/error.log"
echo.

pause
