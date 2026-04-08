# eazy_vllm

請完全放棄在原生 Windows Python 環境下安裝 `vLLM` 的想法。這個專案的建議做法是只使用 `WSL2 + Ubuntu 22.04 + Python virtualenv`，避免 Windows 原生 Python、驅動、CUDA 與套件相依性衝突。

## 可直接使用的 CMD 腳本

這個專案已經把能自動化的步驟整理成以下 Windows `.cmd`：

- `install_wsl2_ubuntu.cmd`：安裝 `WSL2` 與 `Ubuntu-22.04`，必須用系統管理員身分執行。
- `setup_vllm_wsl.cmd`：在 WSL2 的 Ubuntu 內更新套件、建立 `~/vllm-env`，並安裝 `vllm`。
- `start_vllm_server.cmd`：啟動雙卡 `vLLM` 伺服器，預設模型是 `Qwen/Qwen2.5-14B-Instruct-AWQ`。

也可以先用 `--dry-run` 檢查腳本會執行什麼命令：

```cmd
install_wsl2_ubuntu.cmd --dry-run
setup_vllm_wsl.cmd --dry-run
start_vllm_server.cmd --dry-run
```

## 部署原則

- 第一階段必須在「系統管理員身分」開啟的 Windows PowerShell 執行。
- 安裝完 WSL2 後需要重新開機。
- 重新開機後，後續所有安裝指令都在 WSL2 的 Ubuntu Linux 終端機內執行。
- 不要在原生 Windows Python 環境中安裝 `vllm`。

## 第一階段：用 PowerShell 建立 WSL2 基礎環境

請用系統管理員身分開啟 Windows PowerShell，依序執行：

```powershell
# 安裝 WSL2 與 Ubuntu 22.04
wsl --install -d Ubuntu-22.04
wsl --set-default-version 2
```

如果你想直接執行腳本，也可以改用：

```cmd
install_wsl2_ubuntu.cmd
```

注意事項：

- 安裝完成後請重新開機。
- 重開機後再次開啟 PowerShell，輸入 `wsl` 即可進入 Linux 終端機。
- 從這一步開始，後續所有指令都在 Ubuntu 內執行。

## 第二階段：在 WSL2 內建立乾淨的 Python 環境

在 Ubuntu 終端機中執行：

```bash
# 更新系統套件並安裝 Python 虛擬環境工具
sudo apt update && sudo apt upgrade -y
sudo apt install python3-pip python3-venv -y

# 建立並啟動名為 vllm-env 的虛擬環境
python3 -m venv ~/vllm-env
source ~/vllm-env/bin/activate
```

這樣做的目的，是把 `vLLM` 與系統 Python 套件隔離，降低相依套件衝突風險。

如果你想用 Windows 直接觸發這些步驟，可以改用：

```cmd
setup_vllm_wsl.cmd
```

## 第三階段：安裝 vLLM

在已啟動的 `vllm-env` 虛擬環境中執行：

```bash
pip install --upgrade pip
pip install vllm
```

這會自動安裝適用於 Linux 的 `PyTorch` 與相關 CUDA 執行時期函式庫。

`setup_vllm_wsl.cmd` 已經包含第二階段與第三階段，所以正常情況下不需要再手動重打一次。

## 第四階段：雙 5070 Ti 的啟動方式

安裝完成後，可用以下指令啟動 OpenAI 相容的 API 伺服器：

```bash
vllm serve "Qwen/Qwen2.5-14B-Instruct-AWQ" \
  --tensor-parallel-size 2 \
  --max-model-len 8192 \
  --gpu-memory-utilization 0.9 \
  --port 8000
```

### 參數說明

- `--tensor-parallel-size 2`：雙卡核心設定，將模型張量運算分配到兩張 `5070 Ti`。
- `--max-model-len 8192`：設定上下文長度上限。
- `--gpu-memory-utilization 0.9`：允許 vLLM 使用約 90% 的 VRAM，提升模型權重與 KV Cache 可用空間。
- `--port 8000`：將 API 服務啟動在 `8000` 連接埠。

## 日常使用：Windows PowerShell 一鍵啟動

之後每次重新開機，不需要手動先輸入 `wsl` 再逐步啟動虛擬環境。只要在一般 Windows PowerShell 輸入以下單行指令即可：

```powershell
# 請將 your_ubuntu_username 與 your-model-name-or-path 替換成實際值
wsl -d Ubuntu-22.04 -u your_ubuntu_username -- bash -lc "source ~/vllm-env/bin/activate && vllm serve 'your-model-name-or-path' --tensor-parallel-size 2 --max-model-len 8192 --gpu-memory-utilization 0.9 --port 8000"
```

如果你要直接使用前面的範例模型，命令可以寫成：

```powershell
wsl -d Ubuntu-22.04 -u your_ubuntu_username -- bash -lc "source ~/vllm-env/bin/activate && vllm serve 'Qwen/Qwen2.5-14B-Instruct-AWQ' --tensor-parallel-size 2 --max-model-len 8192 --gpu-memory-utilization 0.9 --port 8000"
```

如果你想直接用現成腳本，平常可直接執行：

```cmd
start_vllm_server.cmd
```

如果要臨時改模型，不用改檔案，直接把模型名稱當參數傳入即可：

```cmd
start_vllm_server.cmd "Qwen/Qwen2.5-14B-Instruct-AWQ"
```

## 與 OpenClaw 連接

WSL2 內啟動的 `vLLM`，一般可以讓 Windows 端的 `OpenClaw` 透過本機位址直接連線。實務上建議把 `vLLM` 的 API 視為：

```text
http://127.0.0.1:8000/v1
```

如果你主要就是要讓 Windows 端的 `OpenClaw` 連進 WSL2 內的 `vLLM`，建議把啟動命令改成明確綁定所有介面：

```bash
vllm serve "Qwen/Qwen2.5-14B-Instruct-AWQ" \
  --host 0.0.0.0 \
  --port 8000 \
  --tensor-parallel-size 2 \
  --max-model-len 8192 \
  --gpu-memory-utilization 0.9
```

### OpenClaw 設定方向

在 `OpenClaw` 內，重點是把本地模型提供者指向 `vLLM` 的 OpenAI 相容端點：

```json
{
  "baseUrl": "http://127.0.0.1:8000/v1",
  "apiKey": "sk-local",
  "api": "openai-responses"
}
```

### 注意事項

- 若 `OpenClaw` 能列出模型，但 agent 實際執行失敗，通常先檢查相容性設定，而不一定是 WSL2 網路本身有問題。
- 某些 OpenAI-compatible 後端在 `OpenClaw` 下可能需要補 `compat.supportsTools: false`。
- 某些後端也可能需要 `compat.requiresStringContent: true`。
- 若你要從 Windows 直接測試 `vLLM` 是否有成功對外提供服務，可以先用瀏覽器或 `curl` 測 `http://127.0.0.1:8000/v1/models`。

### 參考文件

- `OpenClaw` 本地模型與 OpenAI-compatible 後端說明：<https://docs.openclaw.ai/gateway/local-models>
- `vLLM` OpenAI-compatible server 文件：<https://docs.vllm.ai/en/stable/cli/serve/>
- Microsoft WSL 網路說明：<https://learn.microsoft.com/en-us/windows/wsl/networking>

## 建議檢查事項

- 確認 Windows 顯示卡驅動已更新到支援 WSL2 GPU 的版本。
- 確認在 WSL2 內可以看到 GPU。
- 若模型較大或上下文更長，請視顯存情況調整 `--gpu-memory-utilization` 與 `--max-model-len`。
