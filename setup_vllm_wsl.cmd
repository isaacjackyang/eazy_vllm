@echo off
setlocal EnableExtensions

set "DISTRO=Ubuntu-22.04"
set "VENV_NAME=vllm-env"
set "DRY_RUN=0"
set "PAUSE_ON_EXIT=1"

:parse_args
if "%~1"=="" goto :args_done
if /I "%~1"=="/?" goto :usage
if /I "%~1"=="-h" goto :usage
if /I "%~1"=="--help" goto :usage
if /I "%~1"=="--dry-run" (
    set "DRY_RUN=1"
    shift /1
    goto :parse_args
)
if /I "%~1"=="--no-pause" (
    set "PAUSE_ON_EXIT=0"
    shift /1
    goto :parse_args
)
echo Unknown argument: %~1
call :pause_if_needed
exit /b 1

:args_done

set "WSL_COMMAND=set -e; sudo apt update; sudo apt upgrade -y; sudo apt install -y python3-pip python3-venv; python3 -m venv --clear ~/%VENV_NAME%; . ~/%VENV_NAME%/bin/activate; python3 -m pip install --upgrade pip setuptools wheel; python3 -m pip cache purge || true; if python3 -m pip install --no-cache-dir vllm; then echo 'vllm install completed on the first attempt.'; else echo 'First vllm install attempt failed. Retrying once with a clean cache...'; python3 -m pip cache purge || true; python3 -m pip install --no-cache-dir --force-reinstall vllm; fi"
set "VERIFY_COMMAND=set -e; if [ ! -f ~/%VENV_NAME%/bin/activate ]; then echo 'Virtual environment ~/%VENV_NAME% was not found after setup.'; exit 1; fi; . ~/%VENV_NAME%/bin/activate; if command -v vllm >/dev/null 2>&1; then echo vLLM command:; command -v vllm; else echo 'vllm command was not found after setup.'; exit 1; fi; echo vLLM version:; vllm --version"

echo Distro   : %DISTRO%
echo Venv Name: %VENV_NAME%
echo.
echo This script runs inside WSL and may prompt for your Ubuntu password.

if "%DRY_RUN%"=="1" (
    echo [dry-run] wsl -d %DISTRO% -- bash -lc "%WSL_COMMAND%"
    echo [dry-run] wsl -d %DISTRO% -- bash -lc "%VERIFY_COMMAND%"
    call :pause_if_needed
    exit /b 0
)

call :distro_exists
if errorlevel 1 (
    echo %DISTRO% was not found. Run install_wsl2_ubuntu.cmd first.
    call :pause_if_needed
    exit /b 1
)

call :require_default_user
if errorlevel 1 (
    call :pause_if_needed
    exit /b 1
)

wsl -d %DISTRO% -- bash -lc "%WSL_COMMAND%"
if errorlevel 1 (
    echo.
    echo vLLM environment setup failed.
    call :pause_if_needed
    exit /b 1
)

echo.
echo Verifying vLLM installation...
wsl -d %DISTRO% -- bash -lc "%VERIFY_COMMAND%"
if errorlevel 1 (
    echo.
    echo vLLM was installed, but the version check failed.
    call :pause_if_needed
    exit /b 1
)

echo.
echo vLLM environment setup completed successfully.
call :pause_if_needed
exit /b 0

:usage
echo Usage:
echo   setup_vllm_wsl.cmd
echo   setup_vllm_wsl.cmd --dry-run
echo   setup_vllm_wsl.cmd --no-pause
echo.
echo What it does:
echo   - Updates Ubuntu packages
echo   - Installs python3-pip and python3-venv
echo   - Recreates ~/%VENV_NAME% with python3 -m venv --clear
echo   - Purges pip cache before installing vllm
echo   - Installs vllm into that virtual environment
echo   - Retries the vllm install once if the first attempt fails
echo   - Verifies the installation with vllm --version
echo.
echo Notes:
echo   - Double-click mode keeps this window open so you can read the result.
echo   - Add --no-pause when running from an existing terminal.
call :pause_if_needed
exit /b 0

:distro_exists
wsl -d %DISTRO% -u root -- bash -lc "exit 0" >nul 2>&1
exit /b %errorlevel%

:require_default_user
set "WSL_USER="
for /f "usebackq delims=" %%I in (`wsl -d %DISTRO% -- bash -lc "whoami" 2^>nul`) do set "WSL_USER=%%I"
if not defined WSL_USER (
    echo Could not determine the default Ubuntu username.
    echo Open %DISTRO% once from the Start menu, finish the first-run setup, and try again.
    exit /b 1
)
if /I "%WSL_USER%"=="root" (
    echo The default user for %DISTRO% is still root.
    echo Open %DISTRO% once from the Start menu, create your Linux username and password, then run this script again.
    exit /b 1
)
exit /b 0

:pause_if_needed
if "%PAUSE_ON_EXIT%"=="1" (
    echo.
    pause
)
exit /b 0
