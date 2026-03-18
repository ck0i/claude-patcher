$pdir = $PSScriptRoot
$old = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($old -notlike "*$pdir*") {
    [Environment]::SetEnvironmentVariable("PATH", $pdir + ";" + $old, "User")
    Write-Host "[OK] Added patcher to user PATH - open a new terminal to use 'claude' directly"
} else {
    Write-Host "[OK] Patcher already in user PATH"
}
