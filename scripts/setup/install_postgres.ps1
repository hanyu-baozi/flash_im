#Requires -Version 5.1
<#
.SYNOPSIS
  在本机安装 PostgreSQL 最新稳定版（EDB 官方 Windows 安装包），并配置环境变量。

.DESCRIPTION
  - 默认安装目录: D:\SDK\postgres
  - 自动从 postgresql.org 解析当前稳定主版本（versions.json 中 current=true）
  - 静默安装 server + 命令行工具 + pgAdmin（不含 Stack Builder）
  - 设置系统级 PGHOME / PGDATA / PGPORT / PGUSER，并将 bin 加入 PATH

.PARAMETER InstallDir
  PostgreSQL 安装根目录（--prefix）。

.PARAMETER DataDir
  数据目录；默认 <InstallDir>\data。

.PARAMETER Port
  监听端口，默认 5432。

.PARAMETER SuperPassword
  超级用户 postgres 密码。未指定时在控制台安全输入。

.PARAMETER Version
  指定主版本号（如 18.4）。默认自动解析最新稳定版。

.EXAMPLE
  # 以管理员身份运行 PowerShell：
  .\install_postgres.ps1

.EXAMPLE
  .\install_postgres.ps1 -SuperPassword 'YourStrongPassword!'
#>
[CmdletBinding()]
param(
    [string] $InstallDir = 'D:\SDK\postgres',
    [string] $DataDir = '',
    [int] $Port = 5432,
    [string] $SuperPassword = '',
    [string] $Version = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-LatestStablePostgreSqlVersion {
    $versionsUrl = 'https://www.postgresql.org/versions.json'
    $json = Invoke-RestMethod -Uri $versionsUrl -UseBasicParsing
    $current = @($json | Where-Object { $_.current -eq $true })
    if ($current.Count -eq 0) {
        throw "无法在 $versionsUrl 中找到 current=true 的稳定版本。"
    }
    $major = [string]$current[0].major
    $minor = [string]$current[0].latestMinor
    return ($major + '.' + $minor)
}

function Find-InstallerBuildNumber {
    param(
        [string] $Version,
        [int] $MaxBuild = 10
    )
    for ($build = 1; $build -le $MaxBuild; $build++) {
        $url = ('https://get.enterprisedb.com/postgresql/postgresql-{0}-{1}-windows-x64.exe' -f $Version, $build)
        try {
            $null = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -TimeoutSec 20
            return $build, $url
        } catch {
            continue
        }
    }
    throw "未找到 PostgreSQL $Version 的 Windows x64 安装包（已尝试 build 1..$MaxBuild）。"
}

function Get-SecurePasswordPlain {
    param([string] $Initial = '')
    if ($Initial) { return $Initial }
    $secure = Read-Host '请输入 postgres 超级用户密码' -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Set-MachineEnvVar {
    param(
        [string] $Name,
        [string] $Value
    )
    [Environment]::SetEnvironmentVariable($Name, $Value, [EnvironmentVariableTarget]::Machine)
    Set-Item -Path "Env:$Name" -Value $Value
}

function Add-MachinePathEntry {
    param([string] $Directory)
    if (-not (Test-Path -LiteralPath $Directory)) {
        New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    }
    $machinePath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
    $segments = @($machinePath -split ';' | Where-Object { $_ })
    $normalized = $Directory.TrimEnd('\')
    if ($segments -contains $normalized) {
        Write-Host "PATH 已包含: $normalized"
        return
    }
    $newPath = ($segments + $normalized) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, [EnvironmentVariableTarget]::Machine)
    $env:Path = "$newPath;$env:Path"
    Write-Host "已将以下目录加入系统 PATH: $normalized"
}

function Test-PostgreSqlInstalled {
    param([string] $BinDir)
    $psql = Join-Path $BinDir 'psql.exe'
    return (Test-Path -LiteralPath $psql)
}

# --- 前置检查 ---
if (-not (Test-IsAdministrator)) {
    throw '请使用「以管理员身份运行」的 PowerShell 执行本脚本（安装与写入系统环境变量需要管理员权限）。'
}

if (-not $DataDir) {
    $DataDir = Join-Path $InstallDir 'data'
}

$parentDir = Split-Path -Parent $InstallDir
if ($parentDir -and -not (Test-Path -LiteralPath $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

$binDir = Join-Path $InstallDir 'bin'
$plainPassword = Get-SecurePasswordPlain -Initial $SuperPassword

if (-not $Version) {
    $Version = Get-LatestStablePostgreSqlVersion
    Write-Host "检测到最新稳定版: PostgreSQL $Version"
}

# --- 安装 ---
if (Test-PostgreSqlInstalled -BinDir $binDir) {
    Write-Host "检测到已安装: $binDir\psql.exe，跳过安装程序，仅同步环境变量。"
} else {
    $build, $installerUrl = Find-InstallerBuildNumber -Version $Version
    Write-Host ('安装包: postgresql-{0}-{1}-windows-x64.exe' -f $Version, $build)

    $cacheDir = Join-Path $env:TEMP 'postgresql-installer'
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    $installerPath = Join-Path $cacheDir ('postgresql-{0}-{1}-windows-x64.exe' -f $Version, $build)

    if (-not (Test-Path -LiteralPath $installerPath)) {
        Write-Host "正在下载: $installerUrl"
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
    } else {
        Write-Host "使用已缓存安装包: $installerPath"
    }

    $logFile = Join-Path $cacheDir ('install-{0}-{1}.log' -f $Version, $build)
    $optFile = Join-Path $cacheDir ('install-{0}-{1}.conf' -f $Version, $build)
    @(
        'mode=unattended'
        'unattendedmodeui=none'
        "prefix=$InstallDir"
        "datadir=$DataDir"
        "serverport=$Port"
        "superpassword=$plainPassword"
        'disable-components=stackbuilder'
        'debuglevel=4'
    ) | Set-Content -Path $optFile -Encoding ASCII

    Write-Host "正在静默安装到 $InstallDir ..."
    $proc = Start-Process -FilePath $installerPath -ArgumentList @(
        '--optionfile', $optFile,
        '--debugtrace', $logFile
    ) -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -ne 0) {
        throw "安装失败，退出码 $($proc.ExitCode)。日志: $logFile"
    }
    Write-Host "安装完成。日志: $logFile"
}

if (-not (Test-PostgreSqlInstalled -BinDir $binDir)) {
    throw "安装后未找到 $binDir\psql.exe，请检查安装日志。"
}

# --- 环境变量（系统级，新开终端生效）---
Set-MachineEnvVar -Name 'PGHOME' -Value $InstallDir
Set-MachineEnvVar -Name 'PGROOT' -Value $InstallDir
Set-MachineEnvVar -Name 'PGDATA' -Value $DataDir
Set-MachineEnvVar -Name 'PGPORT' -Value "$Port"
Set-MachineEnvVar -Name 'PGUSER' -Value 'postgres'
Add-MachinePathEntry -Directory $binDir

# 刷新当前会话 PATH（便于脚本末尾自检）
$env:PGHOME = $InstallDir
$env:PGROOT = $InstallDir
$env:PGDATA = $DataDir
$env:PGPORT = "$Port"
$env:PGUSER = 'postgres'

Write-Host ''
Write-Host '=== PostgreSQL 环境变量已配置（系统级）==='
Write-Host "  PGHOME  = $InstallDir"
Write-Host "  PGROOT  = $InstallDir"
Write-Host "  PGDATA  = $DataDir"
Write-Host "  PGPORT  = $Port"
Write-Host "  PGUSER  = postgres"
Write-Host "  PATH   += $binDir"
Write-Host ''
Write-Host '请重新打开终端后执行:'
Write-Host "  psql -U postgres -h localhost -p $Port"
Write-Host ''
Write-Host '服务名通常为 postgresql-x64-<主版本>，可在「服务」中查看或:'
Write-Host '  Get-Service postgresql*'

# 版本自检
& (Join-Path $binDir 'psql.exe') --version
