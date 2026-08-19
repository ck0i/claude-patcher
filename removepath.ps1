$ErrorActionPreference = 'Stop'

$patcherDir = $PSScriptRoot.TrimEnd('\')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')

if ([string]::IsNullOrEmpty($userPath)) {
    Write-Host "[--] User PATH is empty, nothing to remove"
    exit 0
}

$entries = $userPath -split ';' | Where-Object {
    $_ -and ($_.TrimEnd('\') -ine $patcherDir)
}
$newPath = ($entries -join ';').TrimEnd(';')

if ($newPath -eq $userPath) {
    Write-Host "[--] $patcherDir not found in user PATH"
} else {
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "[OK] Removed $patcherDir from user PATH"
}