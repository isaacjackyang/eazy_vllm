@echo off
setlocal EnableExtensions

set "DISTRO=Ubuntu-22.04"
set "VENV_NAME=vllm-env"
set "MODEL=Qwen/Qwen2.5-14B-Instruct-AWQ"
set "HOST=0.0.0.0"
set "TENSOR_PARALLEL_SIZE=2"
set "MAX_MODEL_LEN=8192"
set "GPU_MEMORY_UTILIZATION=0.9"
set "PORT=8000"
set "DRY_RUN=0"
set "MODEL_OVERRIDE="

if /I "%~1"=="/?" goto :usage
if /I "%~1"=="-h" goto :usage
if /I "%~1"=="--help" goto :usage

if /I "%~1"=="--dry-run" (
    set "DRY_RUN=1"
    shift /1
)

:collect_args
if "%~1"=="" goto :args_done
if defined MODEL_OVERRIDE (
    set "MODEL_OVERRIDE=%MODEL_OVERRIDE% %~1"
) else (
    set "MODEL_OVERRIDE=%~1"
)
shift /1
goto :collect_args

:args_done
if defined MODEL_OVERRIDE set "MODEL=%MODEL_OVERRIDE%"

set "WSL_COMMAND=set -e; if [ ! -f ~/%VENV_NAME%/bin/activate ]; then echo 'Virtual environment ~/%VENV_NAME% was not found. Run setup_vllm_wsl.cmd first.'; exit 1; fi; . ~/%VENV_NAME%/bin/activate; vllm serve '%MODEL%' --host %HOST% --tensor-parallel-size %TENSOR_PARALLEL_SIZE% --max-model-len %MAX_MODEL_LEN% --gpu-memory-utilization %GPU_MEMORY_UTILIZATION% --port %PORT%"

echo Distro       : %DISTRO%
echo Venv Name    : %VENV_NAME%
echo Model        : %MODEL%
echo Host         : %HOST%
echo TP           : %TENSOR_PARALLEL_SIZE%
echo Max Model Len: %MAX_MODEL_LEN%
echo GPU Memory   : %GPU_MEMORY_UTILIZATION%
echo Port         : %PORT%

if "%DRY_RUN%"=="1" (
    echo.
    echo [dry-run] wsl -d %DISTRO% -- bash -lc "%WSL_COMMAND%"
    exit /b 0
)

wsl -l -q | findstr /IX "%DISTRO%" >nul
if errorlevel 1 (
    echo %DISTRO% was not found. Run install_wsl2_ubuntu.cmd first.
    exit /b 1
)

echo.
echo Starting vLLM server...
wsl -d %DISTRO% -- bash -lc "%WSL_COMMAND%"
exit /b %errorlevel%

:usage
echo Usage:
echo   start_vllm_server.cmd
echo   start_vllm_server.cmd "Qwen/Qwen2.5-14B-Instruct-AWQ"
echo   start_vllm_server.cmd --dry-run
echo   start_vllm_server.cmd --dry-run "Qwen/Qwen2.5-14B-Instruct-AWQ"
echo.
echo Notes:
echo   - Edit the config values at the top of this file if needed.
echo   - If you pass a model path or name, it overrides the default MODEL value.
exit /b 0
