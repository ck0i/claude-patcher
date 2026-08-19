@echo off
setlocal

echo Claude Code Patcher Installer
echo ==============================
echo.

:: add patcher dir to user PATH (before npm/native) so 'claude' runs the wrapper
set "PATCHER_DIR=%~dp0"
if "%PATCHER_DIR:~-1%"=="\" set "PATCHER_DIR=%PATCHER_DIR:~0,-1%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0addpath.ps1"
echo.

:: write the claude.cmd shim — it forwards every 'claude' invocation through the wrapper
:: so the patcher runs (and reapplies if needed) on each command before claude itself starts
echo Installing claude.cmd shim...
> "%~dp0claude.cmd" echo @echo off
>>"%~dp0claude.cmd" echo node "%%~dp0claude-wrapper.js" %%*
echo.

:: apply patch immediately
echo Applying patches...
node "%~dp0patcher.js"
echo.

echo ==============================
echo Installation complete!
echo.
echo Usage:
echo   Just run 'claude' in a new terminal - the wrapper patches automatically on each invocation.
echo.
echo Run 'node %~dp0patcher.js --status' to check patch status anytime.
echo.

endlocal
