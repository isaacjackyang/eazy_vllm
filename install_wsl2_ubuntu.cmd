@echo off
setlocal EnableExtensions

set "DISTRO=Ubuntu-22.04"
set "DRY_RUN=0"

if /I "%~1"=="/?" goto :usage
if /I "%~1"=="-h" goto :usage
if /I "%~1"=="--help" goto :usage
if /I "%~1"=="--dry-run" set "DRY_RUN=1"

if "%DRY_RUN%"=="1" (
    echo Distro: %DISTRO%
    echo [dry-run] wsl --install -d %DISTRO%
    echo [dry-run] wsl --set-default-version 2
    exit /b 0
)

net session >nul 2>&1
if errorlevel 1 (
    echo Please run this script from an Administrator Command Prompt or PowerShell.
    exit /b 1
)

echo Distro: %DISTRO%

wsl -l -q | findstr /IX "%DISTRO%" >nul
if errorlevel 1 (
    echo Installing WSL2 and %DISTRO%...
    wsl --install -d %DISTRO%
    if errorlevel 1 goto :fail
) else (
    echo %DISTRO% is already installed. Skipping distro install.
)

echo Setting WSL default version to 2...
wsl --set-default-version 2
if errorlevel 1 goto :fail

echo.
echo Finished. Reboot Windows before running the next step.
exit /b 0

:fail
echo.
echo WSL2 installation setup failed.
exit /b 1

:usage
echo Usage:
echo   install_wsl2_ubuntu.cmd
echo   install_wsl2_ubuntu.cmd --dry-run
echo.
echo Notes:
echo   - Run this script as Administrator.
echo   - Reboot Windows after it finishes.
exit /b 0
