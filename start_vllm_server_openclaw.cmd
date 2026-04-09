@echo off
setlocal EnableExtensions

set "DISTRO=Ubuntu-22.04"
set "VENV_NAME=vllm-env"
set "MODEL=TeichAI/gemma-4-31B-it-Claude-Opus-Distill"
set "HOST=0.0.0.0"
set "MAX_MODEL_LEN=96000"
set "PORT=8000"
set "DRY_RUN=0"
set "MODEL_OVERRIDE="
set "PAUSE_ON_EXIT=1"

:collect_args
if "%~1"=="" goto :args_done
if /I "%~1"=="/?" goto :usage
if /I "%~1"=="-h" goto :usage
if /I "%~1"=="--help" goto :usage
if /I "%~1"=="--dry-run" (
    set "DRY_RUN=1"
    shift /1
    goto :collect_args
)
if /I "%~1"=="--no-pause" (
    set "PAUSE_ON_EXIT=0"
    shift /1
    goto :collect_args
)
if defined MODEL_OVERRIDE (
    set "MODEL_OVERRIDE=%MODEL_OVERRIDE% %~1"
) else (
    set "MODEL_OVERRIDE=%~1"
)
shift /1
goto :collect_args

:args_done
if defined MODEL_OVERRIDE set "MODEL=%MODEL_OVERRIDE%"

set "API_BASE_URL=http://127.0.0.1:%PORT%/v1"
set "WSL_COMMAND=set -e; if [ ! -f ~/%VENV_NAME%/bin/activate ]; then echo 'Virtual environment ~/%VENV_NAME% was not found. Run setup_vllm_wsl.cmd first.'; exit 1; fi; . ~/%VENV_NAME%/bin/activate; vllm serve '%MODEL%' --host %HOST% --port %PORT% --max-model-len %MAX_MODEL_LEN%"

echo OpenClaw Mode : Windows OpenClaw to WSL2 vLLM
echo Distro        : %DISTRO%
echo Venv Name     : %VENV_NAME%
echo Model         : %MODEL%
echo Host          : %HOST%
echo Max Model Len : %MAX_MODEL_LEN%
echo Port          : %PORT%
echo Endpoint      : %API_BASE_URL%
echo API Key       : sk-local
echo API           : openai-responses
echo Test URL      : %API_BASE_URL%/models
echo.
echo Keep this window open while the vLLM server is running.

if "%DRY_RUN%"=="1" (
    echo.
    echo [dry-run] wsl -d %DISTRO% -- bash -lc "%WSL_COMMAND%"
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

echo.
echo Starting vLLM server for OpenClaw...
wsl -d %DISTRO% -- bash -lc "%WSL_COMMAND%"
set "WSL_EXIT_CODE=%errorlevel%"
if not "%WSL_EXIT_CODE%"=="0" (
    echo.
    echo OpenClaw vLLM server exited with code %WSL_EXIT_CODE%.
    echo Check the output above for the reason.
    call :pause_if_needed
    exit /b %WSL_EXIT_CODE%
)

echo.
echo OpenClaw vLLM server stopped.
call :pause_if_needed
exit /b 0

:usage
echo Usage:
echo   start_vllm_server_openclaw.cmd
echo   start_vllm_server_openclaw.cmd "TeichAI/gemma-4-31B-it-Claude-Opus-Distill"
echo   start_vllm_server_openclaw.cmd --dry-run
echo   start_vllm_server_openclaw.cmd --dry-run "TeichAI/gemma-4-31B-it-Claude-Opus-Distill"
echo   start_vllm_server_openclaw.cmd --no-pause
echo.
echo Notes:
echo   - Default command:
echo     vllm serve TeichAI/gemma-4-31B-it-Claude-Opus-Distill --host 0.0.0.0 --port 8000 --max-model-len 96000
echo   - This script prints the OpenClaw endpoint before starting the server.
echo   - Double-click mode keeps this window open after the server stops or startup fails.
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
