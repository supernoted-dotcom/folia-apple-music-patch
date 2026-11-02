param(
    [ValidateSet('install','uninstall','check')][string]$Action = 'install',
    [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'Programs\Folia')
)
$ErrorActionPreference = 'Stop'
$originalHash = '89AFD1EE1E72104A581A82D1919098801EEC33A450FAB787B317EB8C05962A3C'
$exeHash = '79E475622D6A23A7CEB132E62E94810582CFA89B7788048789D8A3913D04C4BE'
$patchedHash = 'AA3C1EE95369847102021AB47804C4C63324FD6961FDAC45F1211DD67AA7A7F6'
$root = [IO.Path]::GetFullPath($InstallDir).TrimEnd('\')
$exe = Join-Path $root 'Folia.exe'
$resources = Join-Path $root 'resources'
$target = Join-Path $resources 'app.asar'
$backupDir = Join-Path $resources 'folia-apple-backup'
$backup = Join-Path $backupDir 'original.asar'
$hostDir = Join-Path $resources 'folia-apple-host'
$hostTemp = Join-Path $resources 'folia-apple-host.pending'
$source = Join-Path $PSScriptRoot 'payload'
$candidate = Join-Path $source 'app.asar'
$manifestPath = Join-Path $PSScriptRoot 'payload-manifest.json'
function Hash([string]$path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
function RequireFile([string]$path) { if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "找不到必要文件：$path" } }
function RequireStopped {
    $running = @(Get-Process -Name Folia -ErrorAction SilentlyContinue | Where-Object { $_.Path -and [string]::Equals($_.Path, $exe, [StringComparison]::OrdinalIgnoreCase) })
    if ($running.Count -gt 0) { throw '请先退出正在运行的目标 Folia（包括系统托盘），然后重新运行。' }
}
function VerifyHost([string]$hostPath, $entries) {
    $base = [IO.Path]::GetFullPath($hostPath).TrimEnd('\') + '\'
    foreach ($entry in $entries) {
        $file = [IO.Path]::GetFullPath((Join-Path $base ([string]$entry.path)))
        if (!$file.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) { throw '文件清单包含无效路径。' }
        RequireFile $file
        if ((Hash $file) -ne $entry.sha256) { throw "播放器组件校验失败：$($entry.path)" }
    }
}
try {
    RequireFile $exe
    RequireFile $target
    if ((Hash $exe) -ne $exeHash) { throw '不支持此 Folia 构建。此补丁只支持已验证的 Windows 0.7.25 官方安装版。' }
    $current = Hash $target
    if ($Action -eq 'check') {
        if ($current -eq $originalHash) { Write-Host '检测到兼容的 Folia 0.7.25，可安装补丁。'; exit 0 }
        if ($current -eq $patchedHash) { Write-Host '检测到本补丁已安装。'; exit 0 }
        throw '应用文件与兼容清单不一致，未进行任何更改。'
    }
    RequireStopped
    if ($Action -eq 'uninstall') {
        if ($current -eq $originalHash) { Write-Host 'Folia 已是原版，无需恢复。'; exit 0 }
        if ($current -ne $patchedHash) { throw '当前文件不是本补丁版本，已停止恢复以保护已有改动。' }
        RequireFile $backup
        if ((Hash $backup) -ne $originalHash) { throw '原版备份校验失败，已停止恢复。' }
        $temp = Join-Path $resources 'folia-apple-restore.pending'
        $rollback = Join-Path $backupDir ('patched.before-restore.' + [guid]::NewGuid().ToString('N') + '.asar')
        if (Test-Path -LiteralPath $temp) { throw '存在上次恢复遗留文件，请先检查备份目录。' }
        Copy-Item -LiteralPath $backup -Destination $temp
        [IO.File]::Replace($temp, $target, $rollback)
        if ((Hash $target) -ne $originalHash) { throw '恢复后的文件校验失败，请使用备份恢复。' }
        Write-Host '原版 Folia 已恢复。设置、歌库、Apple 登录会话和补丁播放器文件均已保留。'
        exit 0
    }
    if ($current -eq $patchedHash) {
        if (!(Test-Path -LiteralPath $backup) -or (Hash $backup) -ne $originalHash) { throw '检测到接入文件，但本安装器没有可校验的原版备份；请保留现状并检查已有备份。' }
        Write-Host '补丁已安装，且原版备份可用，无需重复安装。'; exit 0
    }
    if ($current -ne $originalHash) { throw '应用文件与兼容清单不一致，未进行任何更改。' }
    RequireFile $candidate
    RequireFile $manifestPath
    if ((Hash $candidate) -ne $patchedHash) { throw '补丁文件校验失败，未更改 Folia。' }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (@($manifest.files).Count -lt 10) { throw '播放器组件清单不完整。' }
    VerifyHost (Join-Path $source 'folia-apple-host') $manifest.files
    if ((Test-Path -LiteralPath $backup) -and (Hash $backup) -ne $originalHash) { throw '现有原版备份校验失败，未进行更改。' }
    if (Test-Path -LiteralPath $hostTemp) { throw '存在上次安装的临时目录，请检查后再试。' }
    if (Test-Path -LiteralPath $hostDir) {
        $owner = Join-Path $hostDir 'folia-apple-owner.txt'
        if (!(Test-Path -LiteralPath $owner) -or (Get-Content -LiteralPath $owner -Raw).Trim() -ne $patchedHash) { throw '已存在无法确认归属的播放器目录，未覆盖。' }
        VerifyHost $hostDir $manifest.files
    } else {
        Copy-Item -LiteralPath (Join-Path $source 'folia-apple-host') -Destination $hostTemp -Recurse
        VerifyHost $hostTemp $manifest.files
        [IO.File]::WriteAllText((Join-Path $hostTemp 'folia-apple-owner.txt'), $patchedHash)
        # Both directories are fixed children of the checked installation resources directory.
        $resolvedResources = [IO.Path]::GetFullPath($resources).TrimEnd('\') + '\'
        if (!([IO.Path]::GetFullPath($hostTemp)).StartsWith($resolvedResources, [StringComparison]::OrdinalIgnoreCase) -or !([IO.Path]::GetFullPath($hostDir)).StartsWith($resolvedResources, [StringComparison]::OrdinalIgnoreCase)) { throw '播放器目录不在预期位置。' }
        [IO.Directory]::Move($hostTemp, $hostDir)
    }
    if (!(Test-Path -LiteralPath $backupDir)) { [void](New-Item -ItemType Directory -Path $backupDir) }
    $temp = Join-Path $resources 'folia-apple-install.pending'
    if (Test-Path -LiteralPath $temp) { throw '存在上次安装的临时文件，请检查后再试。' }
    Copy-Item -LiteralPath $candidate -Destination $temp
    if ((Hash $temp) -ne $patchedHash) { throw '复制的补丁文件校验失败。' }
    $reinstallBackup = $null
    if (Test-Path -LiteralPath $backup) {
        $reinstallBackup = Join-Path $backupDir ('original.reinstall.' + [guid]::NewGuid().ToString('N') + '.asar')
        [IO.File]::Replace($temp, $target, $reinstallBackup)
    } else {
        [IO.File]::Replace($temp, $target, $backup)
    }
    if ((Hash $target) -ne $patchedHash -or (Hash $backup) -ne $originalHash) {
        if ((Test-Path -LiteralPath $backup) -and (Hash $backup) -eq $originalHash) { Copy-Item -LiteralPath $backup -Destination $target -Force }
        throw '安装校验失败；如有可能，已恢复原版。'
    }
    if ($reinstallBackup -and (Test-Path -LiteralPath $reinstallBackup)) { Remove-Item -LiteralPath $reinstallBackup -Force }
    Write-Host '安装完成。请启动 Folia，在「连接在线平台」中选择 Apple Music。'
    Write-Host '原版程序已备份；现有设置和资料库未修改。'
} catch {
    Write-Error $_
    exit 1
}

