# Database Clean Script
# Truncates all user tables, keeping schema intact.  Seed data remains deleted.
#
# Usage (from project root: im-server/):
#   powershell -ExecutionPolicy Bypass -File ..\..\scripts\db\clean.ps1
#   powershell -ExecutionPolicy Bypass -File ..\..\scripts\db\clean.ps1 -Confirm:$false

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

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Database Clean" -ForegroundColor Cyan
Write-Host "  DB: $Database" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($Confirm) {
    $answer = Read-Host "  This will DELETE ALL DATA from '$Database'. Continue? (y/N)"
    if ($answer -notin @("y", "Y", "yes", "Yes")) {
        Write-Host "  Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# ── 1. list current tables ───────────────────────────────────
Write-Host "[1/2] Current tables:" -ForegroundColor Yellow
& psql -h $PGHOST -p $PGPORT -U $PGUSER -d $Database -c "\dt" 2>&1 | ForEach-Object { Write-Host "  $_" }

# ── 2. truncate all tables ──────────────────────────────────
Write-Host "[2/2] Truncating all tables..." -ForegroundColor Yellow

$sql = @'
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'TRUNCATE TABLE ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;
'@

& psql -h $PGHOST -p $PGPORT -U $PGUSER -d $Database -c $sql 2>&1 | ForEach-Object { Write-Host "  $_" }
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Clean FAILED" -ForegroundColor Red
    exit 1
}

# ── verify ────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Verifying..." -ForegroundColor Yellow
& psql -h $PGHOST -p $PGPORT -U $PGUSER -d $Database -c "\dt" 2>&1 | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "  All tables truncated, schema preserved." -ForegroundColor Green
Write-Host "  Run 'scripts\db\init.ps1' to re-apply seed data." -ForegroundColor Gray
