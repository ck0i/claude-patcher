@echo off
setlocal

echo Claude Code Patcher Installer
echo ==============================
echo.

:: add patcher dir to user PATH (before npm) so 'claude' runs the wrapper
set "PATCHER_DIR=%~dp0"
if "%PATCHER_DIR:~-1%"=="\" set "PATCHER_DIR=%PATCHER_DIR:~0,-1%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0addpath.ps1"
echo.

:: apply patch immediately
echo Applying patches...
node "%~dp0patcher.js"
echo.

:: create scheduled task to patch on login (survives updates)
echo Creating scheduled task for auto-patching...
schtasks /create /tn "ClaudeCodePatcher" /tr "node \"%~dp0patcher.js\"" /sc onlogon /rl highest /f >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Scheduled task created - will auto-patch on login
) else (
    echo [WARN] Could not create scheduled task - run as admin or create manually
)

:: create file watcher alternative using powershell
echo.
echo Creating file watcher script...
(
echo $watcher = New-Object System.IO.FileSystemWatcher
echo $watcher.Path = "$env:APPDATA\npm\node_modules\@anthropic-ai\claude-code"
echo $watcher.Filter = "cli.js"
echo $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
echo $watcher.EnableRaisingEvents = $true
echo $action = { node "%~dp0patcher.js" }
echo Register-ObjectEvent $watcher "Changed" -Action $action
echo while ($true^) { Start-Sleep -Seconds 60 }
) > "%~dp0watcher.ps1"
echo [OK] File watcher script created at %~dp0watcher.ps1
echo.

echo ==============================
echo Installation complete!
echo.
echo Usage:
echo   Just run 'claude' in a new terminal - the wrapper handles patching automatically.
echo   Optional watcher (auto-repatch on update): powershell -ExecutionPolicy Bypass -File "%~dp0watcher.ps1"
echo.
echo Run 'node %~dp0patcher.js --status' to check patch status anytime.
echo.

endlocal
