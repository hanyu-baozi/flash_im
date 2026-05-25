# IM Server Start Script
# Detects/Starts PostgreSQL, stops existing backend, rebuilds and runs.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts\server\start.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\server\start.ps1 -Port 3000
#
# Environment variable overrides:
#   PGPASSWORD  = postgres password (default: 123456)

param(
    [int]$Port = 3000
)

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Resolve-Path "$SCRIPT_DIR\..\..\im-server"
$PGPASSWORD = if ($env:PGPASSWORD) { $env:PGPASSWORD } else { "123456" }

$env:PGPASSWORD = $PGPASSWORD

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  IM Server Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# [1] PostgreSQL — detect & start
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Write-Host "[1/3] Checking PostgreSQL..." -ForegroundColor Yellow

$pgService = Get-Service -Name "*postgresql*" -ErrorAction SilentlyContinue

if (-not $pgService) {
    Write-Host "  PostgreSQL service NOT found." -ForegroundColor Red
    Write-Host "  Please install PostgreSQL first." -ForegroundColor Red
    exit 1
}

if ($pgService.Status -ne "Running") {
    Write-Host "  PostgreSQL is stopped. Starting..." -ForegroundColor Yellow
    try {
        Start-Service -Name $pgService.Name -ErrorAction Stop
        Start-Sleep -Seconds 2
        Write-Host "  PostgreSQL started: $($pgService.Name) — Running" -ForegroundColor Green
    } catch {
        Write-Host "  Failed to start PostgreSQL: $_" -ForegroundColor Red
        Write-Host "  Try: net start $($pgService.Name)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  PostgreSQL: $($pgService.Name) — Running" -ForegroundColor Green
}

# Quick connectivity test
$pgTest = & psql -U postgres -h localhost -tAc "SELECT 1" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  PostgreSQL connectivity test FAILED." -ForegroundColor Red
    Write-Host "  $pgTest" -ForegroundColor Red
    exit 1
}
Write-Host "  Connectivity: OK" -ForegroundColor Green

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# [2] Backend — stop if running
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Write-Host "[2/3] Checking existing backend on port $Port..." -ForegroundColor Yellow

$pids = & netstat -ano 2>$null | Select-String ":$Port " | ForEach-Object {
    ($_ -split '\s+')[-1]
} | Where-Object { $_ -match '^\d+$' } | Select-Object -Unique

if ($pids) {
    foreach ($pidStr in $pids) {
        $proc = Get-Process -Id $pidStr -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "  Stopping process: $($proc.ProcessName) (PID: $pidStr)" -ForegroundColor Yellow
            Stop-Process -Id $pidStr -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            Write-Host "  Stopped." -ForegroundColor Green
        }
    }
} else {
    Write-Host "  Port $Port is free." -ForegroundColor Green
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# [3] Build & Run
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Write-Host "[3/3] Building & running..." -ForegroundColor Yellow
Write-Host "  Project: $PROJECT_DIR" -ForegroundColor Gray
Write-Host ""

Push-Location $PROJECT_DIR
try {
    cargo run
} finally {
    Pop-Location
}
