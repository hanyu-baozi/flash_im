@echo off
setlocal
REM 以管理员权限启动 PostgreSQL 安装脚本（安装目录默认 D:\SDK\postgres）
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 需要管理员权限，正在请求提升...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_postgres.ps1" %*
exit /b %errorlevel%
