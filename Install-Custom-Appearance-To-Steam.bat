@echo off
setlocal EnableExtensions

set "DEFAULT_GAME_DIR=%ProgramFiles(x86)%\Steam\steamapps\common\Battle Brothers"
set /p "GAME_DIR=Battle Brothers Steam folder [%DEFAULT_GAME_DIR%]: "
if "%GAME_DIR%"=="" set "GAME_DIR=%DEFAULT_GAME_DIR%"

if not exist "%GAME_DIR%\data\data_001.dat" (
    echo [ERROR] This is not a Battle Brothers Steam game folder:
    echo %GAME_DIR%
    pause
    exit /b 1
)

tasklist /FI "IMAGENAME eq BattleBrothers.exe" /NH | find /I "BattleBrothers.exe" >nul
if not errorlevel 1 (
    echo [ERROR] Close Battle Brothers before installing. No files were changed.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\install_custom_appearance_pack.ps1" -GameDir "%GAME_DIR%"
if errorlevel 1 (
    echo [ERROR] Installation failed.
    pause
    exit /b 1
)

echo [OK] Custom Appearance was installed. Start the game normally, load a campaign, then press Shift+X.
pause
