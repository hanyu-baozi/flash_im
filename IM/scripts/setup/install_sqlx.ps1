# SQLx CLI Install & Verify Script
# Detects sqlx-cli, installs via cargo if missing.
# Run: powershell -ExecutionPolicy Bypass -File scripts\setup\install_sqlx.ps1

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SQLx CLI Environment Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── 0. check rustup ──────────────────────────────────────────
Write-Host "[0/3] Checking rustup..." -ForegroundColor Yellow
$rustupPath = Get-Command rustup -ErrorAction SilentlyContinue
if (-not $rustupPath) {
    Write-Host "  rustup not found. Please install Rust first:" -ForegroundColor Red
    Write-Host "  https://rustup.rs" -ForegroundColor Red
    exit 1
}
Write-Host "  rustup: $($rustupPath.Source)" -ForegroundColor Green

# ── 1. check cargo ───────────────────────────────────────────
Write-Host "[1/3] Checking cargo..." -ForegroundColor Yellow
$cargoPath = Get-Command cargo -ErrorAction SilentlyContinue
if (-not $cargoPath) {
    Write-Host "  cargo not found" -ForegroundColor Red
    exit 1
}
Write-Host "  cargo: $($cargoPath.Source)" -ForegroundColor Green

# ── 2. check / install sqlx-cli ──────────────────────────────
Write-Host "[2/3] Checking sqlx-cli..." -ForegroundColor Yellow
$sqlxPath = Get-Command sqlx -ErrorAction SilentlyContinue

if ($sqlxPath) {
    Write-Host "  sqlx-cli found: $($sqlxPath.Source)" -ForegroundColor Green
    & sqlx --version 2>&1 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host "  sqlx-cli NOT found, installing via cargo..." -ForegroundColor Yellow
    cargo install sqlx-cli --no-default-features --features postgres,rustls 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Install FAILED" -ForegroundColor Red
        exit 1
    }
    Write-Host "  sqlx-cli installed successfully" -ForegroundColor Green
}

# ── 3. check PostgreSQL service ──────────────────────────────
Write-Host "[3/3] Checking PostgreSQL..." -ForegroundColor Yellow
$pg = Get-Service -Name "*postgresql*" -ErrorAction SilentlyContinue
if ($pg) {
    Write-Host "  Service: $($pg.Name) — $($pg.Status)" -ForegroundColor Green
} else {
    Write-Host "  PostgreSQL service not found, but CLI is ready" -ForegroundColor Yellow
    Write-Host "  Make sure PostgreSQL is running before using db scripts" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Environment ready." -ForegroundColor Green
Write-Host "  You can now run:" -ForegroundColor White
Write-Host "    .\scripts\db\init.ps1" -ForegroundColor White
