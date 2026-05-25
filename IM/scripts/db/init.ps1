# Database Init Script
# Creates the database (if absent) and runs all sqlx migrations.
# Prerequisites: install_sqlx.ps1 must have been run first.
#
# Usage (from project root: im-server/):
#   powershell -ExecutionPolicy Bypass -File ..\..\scripts\db\init.ps1
#   powershell -ExecutionPolicy Bypass -File ..\..\scripts\db\init.ps1 -Database flash_im_dev
#
# Environment variables (optional, defaults below):
#   PGHOST     = localhost
#   PGPORT     = 5432
#   PGUSER     = postgres
#   PGPASSWORD = 123456

param(
    [string]$Database = "flash_im"
)

$ErrorActionPreference = "Stop"

$PGHOST     = if ($env:PGHOST)     { $env:PGHOST }     else { "localhost" }
$PGPORT     = if ($env:PGPORT)     { $env:PGPORT }     else { "5432" }
$PGUSER     = if ($env:PGUSER)     { $env:PGUSER }     else { "postgres" }
$PGPASSWORD = if ($env:PGPASSWORD) { $env:PGPASSWORD } else { "123456" }

$env:PGPASSWORD = $PGPASSWORD

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Resolve-Path "$SCRIPT_DIR\..\..\im-server"
$ENV_FILE = Join-Path $PROJECT_DIR ".env"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Database Init" -ForegroundColor Cyan
Write-Host "  Host: ${PGHOST}:${PGPORT}" -ForegroundColor Gray
Write-Host "  User: $PGUSER" -ForegroundColor Gray
Write-Host "  DB:   $Database" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. check sqlx ────────────────────────────────────────────
Write-Host "[1/4] Checking sqlx-cli..." -ForegroundColor Yellow
$sqlxCmd = Get-Command sqlx -ErrorAction SilentlyContinue
if (-not $sqlxCmd) {
    Write-Host "  sqlx-cli not found. Run first: .\scripts\setup\install_sqlx.ps1" -ForegroundColor Red
    exit 1
}
$sqlxVer = & sqlx --version 2>&1 | Select-Object -First 1
Write-Host "  $sqlxVer" -ForegroundColor Green

# ── 2. create database if not exists ────────────────────────
Write-Host "[2/4] Creating database '$Database'..." -ForegroundColor Yellow
$exists = & psql -h $PGHOST -p $PGPORT -U $PGUSER -tAc "SELECT 1 FROM pg_database WHERE datname='$Database'" 2>&1
if ($exists -ne "1") {
    & createdb -h $PGHOST -p $PGPORT -U $PGUSER $Database 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  createdb failed. Check PostgreSQL is running and credentials are correct." -ForegroundColor Red
        exit 1
    }
    Write-Host "  Database '$Database' created" -ForegroundColor Green
} else {
    Write-Host "  Database '$Database' already exists" -ForegroundColor Green
}

# ── 3. write .env ─────────────────────────────────────────────
Write-Host "[3/4] Writing .env..." -ForegroundColor Yellow
$DATABASE_URL = "postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${Database}"
Set-Content -Path $ENV_FILE -Value "DATABASE_URL=$DATABASE_URL" -Encoding UTF8
Write-Host "  $ENV_FILE" -ForegroundColor Green
Write-Host "  $DATABASE_URL" -ForegroundColor Gray

# ── 4. run migrations ────────────────────────────────────────
Write-Host "[4/4] Running sqlx migrations..." -ForegroundColor Yellow
Push-Location $PROJECT_DIR
try {
    $env:DATABASE_URL = $DATABASE_URL
    & sqlx migrate run 2>&1 | ForEach-Object { Write-Host "  $_" }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Migration FAILED" -ForegroundColor Red
        exit 1
    }
    Write-Host "  Migrations applied successfully" -ForegroundColor Green
} finally {
    Pop-Location
}

# ── verify ────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Verifying tables in '$Database'..." -ForegroundColor Yellow
& psql -h $PGHOST -p $PGPORT -U $PGUSER -d $Database -c "\dt" 2>&1 | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Init complete!" -ForegroundColor Cyan
Write-Host "  DATABASE_URL: $DATABASE_URL" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
