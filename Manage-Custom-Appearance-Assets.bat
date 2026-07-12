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

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\open_custom_appearance_manager.ps1" -GameDir "%GAME_DIR%"
