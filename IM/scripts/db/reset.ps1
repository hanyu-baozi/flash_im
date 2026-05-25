# Database Reset Script
# Drops the database, recreates it, and re-applies all migrations.
# Equivalent to: clean + re-seed (but physically drops the DB).
#
# Usage (from project root: im-server/):
#   powershell -ExecutionPolicy Bypass -File ..\..\scripts\db\reset.ps1
#   powershell -ExecutionPolicy Bypass -File ..\..\scripts\db\reset.ps1 -Database flash_im_dev -Confirm:$false

param(
    [string]$Database = "flash_im",
    [switch]$Confirm = $true
)

$ErrorActionPreference = "Stop"

$PGHOST     = if ($env:PGHOST)     { $env:PGHOST }     else { "localhost" }
$PGPORT     = if ($env:PGPORT)     { $env:PGPORT }     else { "5432" }
$PGUSER     = if ($env:PGUSER)     { $env:PGUSER }     else { "postgres" }
$PGPASSWORD = if ($env:PGPASSWORD) { $env:PGPASSWORD } else { "123456" }

$env:PGPASSWORD = $PGPASSWORD

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$INIT_SCRIPT = Join-Path $SCRIPT_DIR "init.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Database Reset" -ForegroundColor Cyan
Write-Host "  DB: $Database" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($Confirm) {
    $answer = Read-Host "  This will DROP and RECREATE '$Database'. ALL DATA will be lost. Continue? (y/N)"
    if ($answer -notin @("y", "Y", "yes", "Yes")) {
        Write-Host "  Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# ── 1. kill active connections ────────────────────────────────
Write-Host "[1/3] Terminating active connections..." -ForegroundColor Yellow
$killSql = @"
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$Database' AND pid <> pg_backend_pid();
"@
& psql -h $PGHOST -p $PGPORT -U $PGUSER -d postgres -c $killSql 2>&1 | Out-Null

# ── 2. drop database ──────────────────────────────────────────
Write-Host "[2/3] Dropping database '$Database'..." -ForegroundColor Yellow
& dropdb -h $PGHOST -p $PGPORT -U $PGUSER --if-exists $Database 2>&1 | Out-Null
Write-Host "  Database dropped" -ForegroundColor Green

# ── 3. re-init ───────────────────────────────────────────────
Write-Host "[3/3] Re-initializing..." -ForegroundColor Yellow
& powershell -ExecutionPolicy Bypass -File $INIT_SCRIPT -Database $Database
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Reset FAILED" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Reset complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
