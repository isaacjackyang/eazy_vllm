@echo off
setlocal EnableExtensions

set "DISTRO=Ubuntu-22.04"
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

if "%DRY_RUN%"=="1" (
    echo Distro: %DISTRO%
    echo [dry-run] wsl --install -d %DISTRO%
    echo [dry-run] wsl --set-default-version 2
    call :pause_if_needed
    exit /b 0
)

net session >nul 2>&1
if errorlevel 1 (
    echo Please run this script from an Administrator Command Prompt or PowerShell.
    call :pause_if_needed
    exit /b 1
)

echo Distro: %DISTRO%

call :distro_exists
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
echo Finished.
echo Reboot Windows, then open %DISTRO% once to create your Linux username and password.
echo After that, run setup_vllm_wsl.cmd.
call :pause_if_needed
exit /b 0

:fail
echo.
echo WSL2 installation setup failed.
call :pause_if_needed
exit /b 1

:usage
echo Usage:
echo   install_wsl2_ubuntu.cmd
echo   install_wsl2_ubuntu.cmd --dry-run
echo   install_wsl2_ubuntu.cmd --no-pause
echo.
echo Notes:
echo   - Run this script as Administrator.
echo   - Reboot Windows after it finishes.
echo   - Double-click mode keeps this window open so you can read the result.
echo   - Add --no-pause when running from an existing terminal.
call :pause_if_needed
exit /b 0

:distro_exists
wsl -d %DISTRO% -u root -- bash -lc "exit 0" >nul 2>&1
exit /b %errorlevel%

:pause_if_needed
if "%PAUSE_ON_EXIT%"=="1" (
    echo.
    pause
)
exit /b 0
