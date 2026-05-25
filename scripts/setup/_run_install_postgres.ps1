$ErrorActionPreference = 'Stop'
$setupDir = $PSScriptRoot
$resultFile = 'D:\SDK\postgres-install-result.txt'
$credFile = 'D:\SDK\postgres-superuser-password.txt'
$password = 'PostgresLocal2026'

if (Test-Path 'D:\SDK\postgres') {
    Remove-Item -LiteralPath 'D:\SDK\postgres' -Recurse -Force -ErrorAction SilentlyContinue
}

$runnerPath = Join-Path $env:TEMP 'cursor-pg-install-runner.ps1'
$runnerContent = @"
`$ErrorActionPreference = 'Stop'
try {
  & '$setupDir\install_postgres.ps1' -SuperPassword '$password'
  'SUCCESS' | Set-Content '$resultFile' -Encoding utf8
  Add-Content '$resultFile' "Password: $password"
  Add-Content '$resultFile' "psql: `$(Test-Path 'D:\SDK\postgres\bin\psql.exe')"
  @('postgres superuser password', "Created: `$(Get-Date -Format o)", 'Password: $password') | Set-Content '$credFile' -Encoding utf8
  exit 0
} catch {
  'FAILED' | Set-Content '$resultFile' -Encoding utf8
  Add-Content '$resultFile' `$_.Exception.Message
  exit 1
}
"@
Set-Content -Path $runnerPath -Value $runnerContent -Encoding UTF8

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = 'powershell.exe'
$psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$runnerPath`""
$psi.Verb = 'runas'
$psi.UseShellExecute = $true
$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal

Write-Host '请在 UAC 弹窗中点击「是」以开始安装（约 5–10 分钟）...'
$proc = [System.Diagnostics.Process]::Start($psi)
$proc.WaitForExit()

Start-Sleep -Seconds 2
if (Test-Path $resultFile) { Get-Content $resultFile }
Write-Host "Elevated exit: $($proc.ExitCode)"
Write-Host "psql installed: $(Test-Path 'D:\SDK\postgres\bin\psql.exe')"
if (Test-Path $credFile) { Write-Host "Password file: $credFile" }

if (Test-Path 'D:\SDK\postgres\bin\psql.exe') { exit 0 } else { exit 1 }
