@echo off
setlocal

echo Claude Code Patcher Uninstaller
echo ================================
echo.

set "PATCHER_DIR=%~dp0"
if "%PATCHER_DIR:~-1%"=="\" set "PATCHER_DIR=%PATCHER_DIR:~0,-1%"

:: revert patches: restores each detected target from its .bak (or reverse-replaces text targets)
:: and deletes the marker file the patcher wrote at install time
echo Reverting patches...
node "%~dp0patcher.js" --unpatch
echo.

:: remove patcher dir from user PATH so 'claude' resolves to the real binary again
echo Removing PATH entry...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0removepath.ps1"
echo.

:: remove the claude.cmd shim — without it, the real claude is found via the rest of PATH
if exist "%~dp0claude.cmd" (
    del "%~dp0claude.cmd"
    echo [OK] Removed claude.cmd shim
) else (
    echo [--] No claude.cmd shim to remove
)
echo.

:: clean up the per-target marker files left in the patcher dir
:: (cli.js's legacy .patched marker lives next to cli.js itself, so it's already handled by --unpatch)
for %%f in ("%~dp0.patched-*") do (
    del "%%f" 2>nul
    echo [OK] Removed marker %%~nxf
)
echo.

echo ================================
echo Uninstall complete!
echo.
echo - Open a NEW terminal for PATH changes to take effect.
echo - You can now delete %PATCHER_DIR% if you want.
echo ================================
echo.

endlocal
