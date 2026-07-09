<#
============================================================
  免驚 AI ｜ Claude Code 無痛一鍵安裝腳本 (Windows)
  AI 免驚，跟著做就會。
------------------------------------------------------------
  適用：Windows 10 (1809+) / Windows 11
  用途：讓新手一行指令裝好 Claude Code + VS Code 環境
  使用方式（複製這一行貼到 PowerShell）：
  irm https://raw.githubusercontent.com/meicy321/claude-code-setup/main/install-claude-code.ps1 | iex
------------------------------------------------------------
  Source : github.com/meicy321/claude-code-setup
  作者   : 免驚 AI (github.com/meicy321)
  License: CC BY-NC-SA 4.0（個人使用、學習、分享自由；禁止商業用途）
           https://creativecommons.org/licenses/by-nc-sa/4.0/
  (C) 2026 免驚 AI · fork 請保留本 header 作者資訊，勿冠品牌販售
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

# --- 4.5 安裝 VS Code + Claude Code 擴充套件，並把終端機設成 Git Bash（和課程影片一致）---
Write-Step "安裝 VS Code 與『Claude Code for VS Code』擴充套件"
if ($null -eq (Get-Command code -ErrorAction SilentlyContinue) -and $hasWinget) {
    Write-Host "  正在用 winget 安裝 VS Code..."
    winget install --id Microsoft.VisualStudioCode -e --source winget --accept-package-agreements --accept-source-agreements
    # 重新載入 PATH，讓 code 指令可用
    $env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine')
}

function Get-CodeCmd {
    $c = Get-Command code -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in @((Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
                     (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd'))) {
        if (Test-Path $p) { return $p }
    }
    return $null
}
$codeCmd = Get-CodeCmd
if ($codeCmd) {
    Write-Ok "VS Code 已就緒"
    Write-Host "  正在安裝『Claude Code for VS Code』擴充套件..."
    try {
        & $codeCmd --install-extension anthropic.claude-code --force | Out-Null
        Write-Ok "擴充套件安裝完成"
    } catch {
        Write-Warn2 "擴充套件安裝時有點小狀況（開 VS Code 後在擴充商店搜『Claude Code』也可手動裝）"
    }
    # 把 VS Code 的預設終端機設成 Git Bash（和課程影片一樣）
    try {
        $vsDir = Join-Path $env:APPDATA 'Code\User'
        if (-not (Test-Path $vsDir)) { New-Item -ItemType Directory -Path $vsDir | Out-Null }
        $vsSettings = Join-Path $vsDir 'settings.json'
        $obj = $null
        if (Test-Path $vsSettings) {
            try { $obj = Get-Content $vsSettings -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop } catch { $obj = $null }
        }
        if ($null -eq $obj) { $obj = New-Object PSObject }
        if ($hasGit) {
            $obj | Add-Member -NotePropertyName 'terminal.integrated.defaultProfile.windows' -NotePropertyValue 'Git Bash' -Force
            $obj | ConvertTo-Json -Depth 20 | Set-Content -Path $vsSettings -Encoding UTF8
            Write-Ok "已把 VS Code 的預設終端機設成 Git Bash"
        }
    } catch {
        Write-Warn2 "設定 VS Code 終端機時略過（不影響使用）"
    }
} else {
    Write-Warn2 "找不到 VS Code（可能沒有 winget）。可手動安裝：https://code.visualstudio.com/"
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

# --- 5.5 建立專案資料夾 + 桌面捷徑（雙擊用 VS Code 打開專案，和課程影片一致）---
Write-Step "建立專案資料夾與桌面「Claude Code」捷徑"
try {
    $projDir = Join-Path $env:USERPROFILE "claude-code"
    if (-not (Test-Path $projDir)) { New-Item -ItemType Directory -Path $projDir | Out-Null }

    # 放一個小說明檔，學生用 VS Code 打開專案就看得到怎麼開始
    $howto = Join-Path $projDir "先看我-如何開始.txt"
    $howtoBody = @'
歡迎使用 Claude Code！

在這個 VS Code 視窗裡，這樣開始：
  1. 上方選單點 [Terminal] -> [New Terminal]（或按 Ctrl 和左上角的 反引號 鍵）
  2. 終端機會用 Git Bash 打開
  3. 輸入：  claude
  4. 第一次會請你用瀏覽器登入（需要 Claude Pro / Max 訂閱）

之後把你的程式檔案放進這個資料夾，就能請 Claude 幫你寫程式了。
'@
    [System.IO.File]::WriteAllText($howto, $howtoBody, (New-Object System.Text.UTF8Encoding($true)))

    $desktop = [Environment]::GetFolderPath('Desktop')
    $lnkPath = Join-Path $desktop "Claude Code.lnk"
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut($lnkPath)

    function Get-CodeExe {
        foreach ($p in @((Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'),
                         (Join-Path $env:ProgramFiles 'Microsoft VS Code\Code.exe'))) {
            if (Test-Path $p) { return $p }
        }
        return $null
    }
    $codeExe = Get-CodeExe
    if ($codeExe) {
        # 雙擊 -> 用 VS Code 打開專案資料夾
        $lnk.TargetPath = $codeExe
        $lnk.Arguments = '"' + $projDir + '"'
        $lnk.WorkingDirectory = $projDir
        $lnk.Description = "用 VS Code 打開 Claude Code 專案"
        $lnk.Save()
        Write-Ok "已在桌面建立「Claude Code」捷徑（雙擊用 VS Code 打開專案）"
    } else {
        # 備援：沒有 VS Code 時，雙擊改用 PowerShell 直接開 claude
        $launcher = Join-Path $projDir "open-claude.ps1"
        $lb = @'
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','User') + ';' + [System.Environment]::GetEnvironmentVariable('Path','Machine')
Set-Location -LiteralPath $PSScriptRoot
claude
'@
        [System.IO.File]::WriteAllText($launcher, $lb, (New-Object System.Text.UTF8Encoding($true)))
        $lnk.TargetPath = (Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe")
        $lnk.Arguments = '-NoExit -ExecutionPolicy Bypass -File "' + $launcher + '"'
        $lnk.WorkingDirectory = $projDir
        $lnk.Description = "開啟 Claude Code"
        $lnk.Save()
        Write-Ok "已在桌面建立「Claude Code」捷徑（雙擊直接開 Claude Code）"
    }
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
Write-Host "  接下來這樣用（和課程影片一樣）：" -ForegroundColor Cyan
Write-Host "  1. 雙擊桌面的『Claude Code』圖示 -> 會用 VS Code 打開你的專案" -ForegroundColor White
Write-Host '  2. 在 VS Code 上方點 Terminal -> New Terminal（或按 Ctrl 和左上角的 反引號 鍵）'
Write-Host "     （終端機已經幫你設成 Git Bash，和影片一樣）"
Write-Host "  3. 在終端機輸入 claude，第一次會請你用瀏覽器登入" -ForegroundColor White
Write-Host ""
Write-Host "  小提醒：要能實際對話，需要 Claude Pro / Max 訂閱喔" -ForegroundColor Yellow
Write-Host ""
Write-Host "===============================================================" -ForegroundColor DarkGray
Write-Host " 免驚 AI ｜ Claude Code 無痛安裝教學" -ForegroundColor Magenta
Write-Host " AI 免驚，跟著做就會" -ForegroundColor Magenta
Write-Host " -------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " Source  : github.com/meicy321/claude-code-setup" -ForegroundColor Gray
Write-Host " License : CC BY-NC-SA 4.0 - 個人使用、學習、分享自由；禁止商業用途" -ForegroundColor Gray
Write-Host " (C) 2026 免驚 AI - 歡迎分享，勿改標後販售" -ForegroundColor Gray
Write-Host "===============================================================" -ForegroundColor DarkGray
Write-Host ""
