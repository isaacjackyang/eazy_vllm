@echo off
setlocal EnableExtensions

set "DISTRO=Ubuntu-22.04"
set "VENV_NAME=vllm-env"
set "DRY_RUN=0"

if /I "%~1"=="/?" goto :usage
if /I "%~1"=="-h" goto :usage
if /I "%~1"=="--help" goto :usage
if /I "%~1"=="--dry-run" set "DRY_RUN=1"

set "WSL_COMMAND=set -e; sudo apt update; sudo apt upgrade -y; sudo apt install -y python3-pip python3-venv; python3 -m venv ~/%VENV_NAME%; . ~/%VENV_NAME%/bin/activate; python3 -m pip install --upgrade pip; pip install vllm"

echo Distro   : %DISTRO%
echo Venv Name: %VENV_NAME%
echo.
echo This script runs inside WSL and may prompt for your Ubuntu password.

if "%DRY_RUN%"=="1" (
    echo [dry-run] wsl -d %DISTRO% -- bash -lc "%WSL_COMMAND%"
    exit /b 0
)

wsl -l -q | findstr /IX "%DISTRO%" >nul
if errorlevel 1 (
    echo %DISTRO% was not found. Run install_wsl2_ubuntu.cmd first.
    exit /b 1
)

wsl -d %DISTRO% -- bash -lc "%WSL_COMMAND%"
if errorlevel 1 (
    echo.
    echo vLLM environment setup failed.
    exit /b 1
)

echo.
echo vLLM environment setup completed successfully.
exit /b 0

:usage
echo Usage:
echo   setup_vllm_wsl.cmd
echo   setup_vllm_wsl.cmd --dry-run
echo.
echo What it does:
echo   - Updates Ubuntu packages
echo   - Installs python3-pip and python3-venv
echo   - Creates ~/%VENV_NAME%
echo   - Installs vllm into that virtual environment
exit /b 0
