<#
============================================================
  Claude Code 無痛一鍵安裝腳本 (Windows)
  適用：Windows 10 (1809+) / Windows 11
  用途：教學用，讓新手一行指令裝好 Claude Code 與環境
------------------------------------------------------------
  使用方式（學生只要複製這一行到 PowerShell 貼上）：
  irm https://raw.githubusercontent.com/<你的帳號>/<你的repo>/main/install-claude-code.ps1 | iex
============================================================
#>

# --- 0. 基本設定：強制 TLS 1.2（舊版 Windows 必要，否則下載會失敗）---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

function Write-Step($msg)  { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Write-Err2($msg)  { Write-Host "  [X] $msg" -ForegroundColor Red }

Write-Host "============================================" -ForegroundColor Magenta
Write-Host "   Claude Code 無痛安裝精靈 (Windows)" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

# --- 1. 檢查 Windows 版本 ---
Write-Step "檢查 Windows 版本"
$os = [System.Environment]::OSVersion.Version
$build = $os.Build
Write-Host "  偵測到 Windows 版本：$($os.Major).$($os.Minor) (Build $build)"
if ($build -lt 17763) {
    Write-Err2 "你的 Windows 太舊 (需要 Windows 10 1809 / Build 17763 以上)。"
    Write-Err2 "請先更新 Windows，或改用 WSL 安裝。安裝中止。"
    return
}
Write-Ok "Windows 版本符合需求"

# --- 2. 檢查 / 安裝 winget（套件管理器）---
Write-Step "檢查套件管理器 winget"
$hasWinget = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
if ($hasWinget) {
    Write-Ok "winget 已安裝"
} else {
    Write-Warn2 "找不到 winget（舊版 Windows 常見）。"
    Write-Warn2 "請開啟 Microsoft Store 搜尋『App Installer』並更新/安裝，然後重跑本腳本。"
    Write-Warn2 "或前往：https://aka.ms/getwinget"
    Write-Host  "  (沒有 winget 也可以，稍後會用官方安裝腳本，但建議先裝好較穩定)"
}

# --- 3. 安裝 Git for Windows（提供 Bash 工具，強烈建議）---
Write-Step "檢查 / 安裝 Git for Windows（Claude Code 的 Bash 工具會用到）"
$hasGit = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
if ($hasGit) {
    Write-Ok "Git 已安裝：$(git --version)"
} elseif ($hasWinget) {
    Write-Host "  正在用 winget 安裝 Git..."
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    Write-Ok "Git 安裝完成（可能需要重開終端機才會生效）"
} else {
    Write-Warn2 "沒有 Git 也沒有 winget，Claude Code 會改用 PowerShell 當 shell（仍可運作）。"
    Write-Warn2 "若要完整功能，請手動安裝：https://git-scm.com/download/win"
}

# --- 3.5 安裝 Node.js（Claude Code 本體不需要，但 MCP server / npx / JS 專案會用到，建議裝）---
Write-Step "檢查 / 安裝 Node.js（給 MCP server、npx、前端專案用）"
$hasNode = $null -ne (Get-Command node -ErrorAction SilentlyContinue)
if ($hasNode) {
    Write-Ok "Node.js 已安裝：$(node --version)"
} elseif ($hasWinget) {
    Write-Host "  正在用 winget 安裝 Node.js LTS..."
    winget install --id OpenJS.NodeJS.LTS -e --source winget --accept-package-agreements --accept-source-agreements
    Write-Ok "Node.js 安裝完成（可能需要重開終端機才會生效）"
} else {
    Write-Warn2 "沒有 winget，Node.js 未安裝。MCP server 等進階功能會需要它。"
    Write-Warn2 "可手動安裝（選 LTS）：https://nodejs.org/"
}

# --- 4. 安裝 Claude Code 本體（原生安裝，不透過 npm，這樣才能自動更新、不被 Node 版本綁死）---
Write-Step "安裝 Claude Code 本體（原生安裝，與上面的 Node.js 各自獨立）"
$hasClaude = $null -ne (Get-Command claude -ErrorAction SilentlyContinue)
if ($hasClaude) {
    Write-Ok "Claude Code 已安裝：$(claude --version 2>$null)"
    Write-Host "  若要更新，稍後可執行： claude update"
} else {
    Write-Host "  正在使用官方原生安裝腳本..."
    try {
        # 官方原生安裝（穩定通道），不需 Node.js
        & ([scriptblock]::Create((irm https://claude.ai/install.ps1))) stable
        Write-Ok "Claude Code 安裝完成"
    } catch {
        Write-Warn2 "原生安裝失敗，嘗試備援方案（winget）..."
        if ($hasWinget) {
            winget install --id Anthropic.ClaudeCode -e --accept-package-agreements --accept-source-agreements
            Write-Ok "已透過 winget 安裝 Claude Code"
        } else {
            Write-Err2 "安裝失敗且無 winget 可用。請檢查網路後重試。"
            return
        }
    }
}

# --- 5. 若有裝 Git 但 Claude 找不到，寫入路徑設定 ---
Write-Step "設定 Git Bash 路徑（若適用）"
$gitBash = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path $gitBash) {
    $claudeDir = Join-Path $env:USERPROFILE ".claude"
    if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir | Out-Null }
    $settingsPath = Join-Path $claudeDir "settings.json"
    if (-not (Test-Path $settingsPath)) {
        @{ env = @{ CLAUDE_CODE_GIT_BASH_PATH = $gitBash } } | ConvertTo-Json | Set-Content -Path $settingsPath -Encoding UTF8
        Write-Ok "已寫入 Git Bash 路徑到 settings.json"
    } else {
        Write-Host "  settings.json 已存在，略過（避免覆蓋你的設定）"
    }
} else {
    Write-Host "  未偵測到標準 Git Bash 路徑，略過"
}

# --- 5.5 建立桌面「Claude Code」捷徑（把「cd 進專案 + 開啟」全自動化，學生雙擊就能用）---
Write-Step "建立桌面「Claude Code」捷徑（之後雙擊就能開，不用再打指令）"
try {
    # 專案資料夾（claude 會在這裡啟動）
    $projDir = Join-Path $env:USERPROFILE "claude-code"
    if (-not (Test-Path $projDir)) { New-Item -ItemType Directory -Path $projDir | Out-Null }

    # 寫一支啟動小幫手：重新載入 PATH -> 切到本資料夾 -> 開啟 claude
    $launcher = Join-Path $projDir "open-claude.ps1"
    $launcherBody = @'
# 由安裝精靈自動建立：重新載入 PATH、切到本資料夾、開啟 Claude Code
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','User') + ';' + [System.Environment]::GetEnvironmentVariable('Path','Machine')
Set-Location -LiteralPath $PSScriptRoot
Write-Host ''
Write-Host '正在開啟 Claude Code...（第一次會請你用瀏覽器登入）' -ForegroundColor Cyan
Write-Host ''
claude
'@
    $utf8bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($launcher, $launcherBody, $utf8bom)

    # 桌面捷徑指向這支小幫手
    $desktop = [Environment]::GetFolderPath('Desktop')
    $lnkPath = Join-Path $desktop "Claude Code.lnk"
    $psExe   = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut($lnkPath)
    $lnk.TargetPath = $psExe
    $lnk.Arguments = '-NoExit -ExecutionPolicy Bypass -File "' + $launcher + '"'
    $lnk.WorkingDirectory = $projDir
    $lnk.Description = "開啟 Claude Code"
    $claudeExe = Join-Path $env:USERPROFILE ".local\bin\claude.exe"
    if (Test-Path $claudeExe) { $lnk.IconLocation = "$claudeExe,0" }
    $lnk.Save()
    Write-Ok "已在桌面建立「Claude Code」捷徑，專案資料夾：$projDir"
} catch {
    Write-Warn2 "建立桌面捷徑時有點小狀況（不影響安裝）：$($_.Exception.Message)"
}

# --- 6. 完成與下一步 ---
Write-Host "`n============================================" -ForegroundColor Green
Write-Host "   全部裝好了，你辛苦了！" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "我在你的桌面放了一個『Claude Code』圖示 :)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  以後要用，只要一個動作："
Write-Host "  ★ 直接雙擊桌面上的『Claude Code』圖示 —— 它會自動打開，不用打任何指令" -ForegroundColor White
Write-Host ""
Write-Host "  第一次打開會自動跳出瀏覽器，用你的 Claude 帳號登入就好。"
Write-Host "  （要能實際對話，需要 Claude Pro / Max 訂閱喔）" -ForegroundColor Yellow
Write-Host ""
Write-Host "（進階）想在別的資料夾用，也可以在那個資料夾開 PowerShell、輸入 claude。" -ForegroundColor DarkGray
Write-Host ""
