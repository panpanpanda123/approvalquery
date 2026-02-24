@echo off
chcp 65001 >nul
echo ====================================
echo   Git 快速提交脚本
echo ====================================
echo.

REM 检查是否在Git仓库中
git status >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误：当前目录不是Git仓库
    pause
    exit /b 1
)

REM 显示当前状态
echo 📋 当前修改的文件：
echo.
git status -s
echo.

REM 询问提交信息
set /p commit_msg="请输入提交说明（直接回车使用默认）: "

REM 如果没有输入，使用默认信息
if "%commit_msg%"=="" (
    set commit_msg=更新审批系统 %date:~0,10%
)

echo.
echo 📝 提交信息: %commit_msg%
echo.

REM 添加所有修改
echo 📥 添加文件...
git add .

REM 提交
echo 💾 提交到本地仓库...
git commit -m "%commit_msg%"

if errorlevel 1 (
    echo.
    echo ⚠️  没有需要提交的修改
    echo.
    pause
    exit /b 0
)

REM 推送到GitHub
echo 📤 推送到GitHub...
git push origin main

if errorlevel 1 (
    echo.
    echo ❌ 推送失败
    echo 可能原因：
    echo   - 网络问题
    echo   - 需要先git pull
    echo   - 权限问题
    echo.
    pause
    exit /b 1
)

echo.
echo ====================================
echo   ✅ 提交成功！
echo ====================================
echo.
echo 📌 下一步操作：
echo.
echo 1. SSH登录服务器：
echo    ssh root@139.224.200.133
echo.
echo 2. 进入项目目录：
echo    cd /var/www/approval-viewer/approvalquery
echo.
echo 3. 执行更新脚本：
echo    bash 服务器一键更新.sh
echo.
echo 或者一行命令：
echo ssh root@139.224.200.133 "cd /var/www/approval-viewer/approvalquery && bash 服务器一键更新.sh"
echo.

pause
