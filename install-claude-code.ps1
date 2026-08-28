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

# --- 0. 基本設定 ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# 注意：這裡刻意「不」設成 Stop。設 Stop 會讓任何一個小失誤（例如某個路徑不存在）
#       就把整支腳本中斷，學員只看到跑一半就沒了。改用各段自己 try/catch。
$ErrorActionPreference = "Continue"
$ProgressPreference    = "SilentlyContinue"

function Write-Step($msg)  { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Write-Err2($msg)  { Write-Host "  [X] $msg" -ForegroundColor Red }

# 讓這個視窗立刻看得到剛剛 winget 裝好的東西（不用重開終端機）
function Sync-Path {
    $u = [Environment]::GetEnvironmentVariable('Path','User')
    $m = [Environment]::GetEnvironmentVariable('Path','Machine')
    $env:Path = (@($m, $u) | Where-Object { $_ }) -join ';'
}
function Test-Cmd($name) { $null -ne (Get-Command $name -ErrorAction SilentlyContinue) }

# 寫 JSON 一律不加 BOM（PowerShell 5.1 的 -Encoding UTF8 會加 BOM，帶 BOM 的 JSON 會解析失敗）
function Write-JsonNoBom($path, $obj) {
    $json = $obj | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($path, $json, (New-Object System.Text.UTF8Encoding($false)))
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

# --- 0.5 全程紀錄：萬一又出事，桌面會留下一份紀錄可以傳給老師 ---
$logPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "claude-code-安裝紀錄.txt"
$logging = $false
try {
    Start-Transcript -Path $logPath -Force -ErrorAction Stop | Out-Null
    $logging = $true
} catch {
    # 有些環境不支援 transcript，略過即可，不影響安裝
}

Write-Host "============================================" -ForegroundColor Magenta
Write-Host "   Claude Code 無痛安裝精靈 (Windows)" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta
if ($logging) {
    Write-Host "  (安裝過程會記錄在桌面的『claude-code-安裝紀錄.txt』，" -ForegroundColor DarkGray
    Write-Host "   萬一裝不起來，把這個檔案傳給老師就能查原因)" -ForegroundColor DarkGray
}
Write-Host "  PowerShell 版本：$($PSVersionTable.PSVersion) / 64位元行程：$([Environment]::Is64BitProcess)" -ForegroundColor DarkGray

# --- 1. 檢查環境 ---
Write-Step "檢查 Windows 版本"
$os = [System.Environment]::OSVersion.Version
$build = $os.Build
Write-Host "  偵測到 Windows 版本：$($os.Major).$($os.Minor) (Build $build)"
if ($build -lt 17763) {
    Write-Err2 "你的 Windows 太舊 (需要 Windows 10 1809 / Build 17763 以上)。"
    Write-Err2 "請先更新 Windows，或改用 WSL 安裝。安裝中止。"
    if ($logging) { try { Stop-Transcript | Out-Null } catch { } }
    return
}
if (-not [Environment]::Is64BitOperatingSystem) {
    Write-Err2 "Claude Code 不支援 32 位元 Windows。安裝中止。"
    if ($logging) { try { Stop-Transcript | Out-Null } catch { } }
    return
}
if (-not [Environment]::Is64BitProcess) {
    Write-Err2 "你開到的是 32 位元的 PowerShell（視窗標題會寫 x86），Claude Code 不支援。"
    Write-Err2 "請關掉這個視窗，改從「開始」搜尋『Windows PowerShell』（不要選 x86 那個）重開。"
    if ($logging) { try { Stop-Transcript | Out-Null } catch { } }
    return
}
Write-Ok "Windows 版本符合需求"

Write-Host ""
Write-Host "  小提醒：等一下安裝 Git / VS Code 時，Windows 可能會跳出" -ForegroundColor Yellow
Write-Host "  「是否允許此應用程式變更你的裝置？」的藍色視窗，請按【是】。" -ForegroundColor Yellow
Write-Host "  （它有時候會躲在其他視窗後面，若畫面卡住不動，請看一下工作列。）" -ForegroundColor Yellow

# --- 1.5 專案資料夾命名 ---
Write-Step "幫你的專案資料夾取個名字"
Write-Host "  這是等一下 Claude Code 會在裡面工作的資料夾。"
$projName = Read-Host "  想叫什麼名字？（建議用英文/數字/減號；直接按 Enter 用預設 my-project）"
if ([string]::IsNullOrWhiteSpace($projName)) { $projName = "my-project" }
$projName = ($projName -replace '[<>:"/\\|?*]', '').Trim()
if ([string]::IsNullOrWhiteSpace($projName)) { $projName = "my-project" }
Write-Ok "好，專案資料夾就叫：$projName"

# --- 2. winget ---
Write-Step "檢查套件管理器 winget"
$hasWinget = Test-Cmd winget
if ($hasWinget) {
    Write-Ok "winget 已安裝"
} else {
    Write-Warn2 "找不到 winget（舊版 Windows 常見）。"
    Write-Warn2 "請開啟 Microsoft Store 搜尋『App Installer』並更新/安裝，然後重跑本腳本。"
    Write-Warn2 "或前往：https://aka.ms/getwinget"
    Write-Host  "  (沒有 winget 也可以，稍後會用官方安裝腳本，但建議先裝好較穩定)"
}

# --- 3. Git for Windows ---
Write-Step "檢查 / 安裝 Git for Windows（Claude Code 的 Bash 工具會用到）"
if (Test-Cmd git) {
    Write-Ok "Git 已安裝：$(git --version)"
} elseif ($hasWinget) {
    Write-Host "  正在用 winget 安裝 Git...（可能要等 1-2 分鐘，若跳出詢問請按【是】）"
    winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements
    Sync-Path
    if (Test-Cmd git) { Write-Ok "Git 安裝完成：$(git --version)" }
    else { Write-Warn2 "Git 似乎沒裝成功，可手動安裝：https://git-scm.com/download/win" }
} else {
    Write-Warn2 "沒有 Git 也沒有 winget，Claude Code 會改用 PowerShell 當 shell（仍可運作）。"
    Write-Warn2 "若要完整功能，請手動安裝：https://git-scm.com/download/win"
}
# 重要：這裡才確定 Git 到底有沒有裝好，後面全部用這個變數
$hasGit = Test-Cmd git

# --- 3.5 Node.js ---
Write-Step "檢查 / 安裝 Node.js（給 MCP server、npx、前端專案用）"
if (Test-Cmd node) {
    Write-Ok "Node.js 已安裝：$(node --version)"
} elseif ($hasWinget) {
    Write-Host "  正在用 winget 安裝 Node.js LTS..."
    winget install --id OpenJS.NodeJS.LTS -e --source winget --silent --accept-package-agreements --accept-source-agreements
    Sync-Path
    if (Test-Cmd node) { Write-Ok "Node.js 安裝完成：$(node --version)" }
    else { Write-Warn2 "Node.js 似乎沒裝成功，可手動安裝（選 LTS）：https://nodejs.org/" }
} else {
    Write-Warn2 "沒有 winget，Node.js 未安裝。MCP server 等進階功能會需要它。"
    Write-Warn2 "可手動安裝（選 LTS）：https://nodejs.org/"
}

# --- 4. Claude Code 本體 ---
# 重要：官方安裝腳本內部一旦失敗會呼叫 exit。如果直接在本視窗執行，
#       那個 exit 會把「整個 PowerShell 視窗」關掉，後面步驟全都不會跑、catch 也接不到。
#       所以改成開一個獨立的 PowerShell 子行程去跑，再用結束代碼判斷成敗。
Write-Step "安裝 Claude Code 本體（原生安裝，與上面的 Node.js 各自獨立）"
if (Test-Cmd claude) {
    Write-Ok "Claude Code 已安裝：$(claude --version 2>$null)"
    Write-Host "  若要更新，稍後可執行： claude update"
} else {
    Write-Host "  正在使用官方原生安裝腳本..."
    $inner = '[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; ' +
             '& ([scriptblock]::Create((irm https://claude.ai/install.ps1))) stable'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $inner
    $rc = $LASTEXITCODE
    Sync-Path
    if (Test-Cmd claude) {
        Write-Ok "Claude Code 安裝完成"
    } else {
        Write-Warn2 "原生安裝沒有成功（結束代碼 $rc），改用備援方案（winget）..."
        if ($hasWinget) {
            winget install --id Anthropic.ClaudeCode -e --source winget --silent --accept-package-agreements --accept-source-agreements
            Sync-Path
            if (Test-Cmd claude) { Write-Ok "已透過 winget 安裝 Claude Code" }
            else { Write-Err2 "Claude Code 安裝失敗，請把上面的訊息截圖回報。" }
        } else {
            Write-Err2 "安裝失敗且無 winget 可用。請檢查網路後重試。"
        }
    }
}

# --- 4.5 VS Code + 擴充套件 ---
Write-Step "安裝 VS Code 與『Claude Code for VS Code』擴充套件"
if (-not (Test-Cmd code) -and -not (Get-CodeCmd) -and $hasWinget) {
    Write-Host "  正在用 winget 安裝 VS Code..."
    # --scope user：裝在使用者資料夾，不需要系統管理員權限，學員比較不會卡在 UAC
    winget install --id Microsoft.VisualStudioCode -e --source winget --scope user --silent --accept-package-agreements --accept-source-agreements
    Sync-Path
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

    # 把 VS Code 的預設終端機設成 Git Bash
    # 重要：舊版在 settings.json 解析失敗時會「整份覆蓋」，把學員原本的設定清光。
    #       這裡改成解析不了就不動它，只提示。
    if ($hasGit) {
        try {
            $vsDir = Join-Path $env:APPDATA 'Code\User'
            if (-not (Test-Path $vsDir)) { New-Item -ItemType Directory -Path $vsDir -Force | Out-Null }
            $vsSettings = Join-Path $vsDir 'settings.json'
            $obj = $null
            $parseFailed = $false
            if (Test-Path $vsSettings) {
                $raw = Get-Content $vsSettings -Raw -ErrorAction SilentlyContinue
                if ([string]::IsNullOrWhiteSpace($raw)) {
                    $obj = New-Object PSObject
                } else {
                    try { $obj = $raw | ConvertFrom-Json -ErrorAction Stop } catch { $parseFailed = $true }
                }
            } else {
                $obj = New-Object PSObject
            }

            if ($parseFailed) {
                Write-Warn2 "你的 VS Code settings.json 有自訂內容（或含註解），為了不覆蓋掉它，這步跳過。"
                Write-Warn2 '可自行加入： "terminal.integrated.defaultProfile.windows": "Git Bash"'
            } else {
                $obj | Add-Member -NotePropertyName 'terminal.integrated.defaultProfile.windows' -NotePropertyValue 'Git Bash' -Force
                Write-JsonNoBom $vsSettings $obj
                Write-Ok "已把 VS Code 的預設終端機設成 Git Bash"
            }
        } catch {
            Write-Warn2 "設定 VS Code 終端機時略過（不影響使用）"
        }
    } else {
        Write-Warn2 "沒有 Git，VS Code 終端機維持 PowerShell（Claude Code 仍可使用）"
    }
} else {
    Write-Warn2 "找不到 VS Code（可能沒有 winget）。可手動安裝：https://code.visualstudio.com/"
}

# --- 5. 告訴 Claude Code 去哪裡找 Git Bash ---
Write-Step "設定 Git Bash 路徑（若適用）"
$gitBash = $null
foreach ($p in @("C:\Program Files\Git\bin\bash.exe",
                 "C:\Program Files (x86)\Git\bin\bash.exe",
                 (Join-Path $env:LOCALAPPDATA 'Programs\Git\bin\bash.exe'))) {
    if (Test-Path $p) { $gitBash = $p; break }
}
if (-not $gitBash -and $hasGit) {
    # 從 git.exe 的位置反推 bash.exe
    $gitExe = (Get-Command git -ErrorAction SilentlyContinue).Source
    if ($gitExe) {
        $cand = Join-Path (Split-Path (Split-Path $gitExe -Parent) -Parent) 'bin\bash.exe'
        if (Test-Path $cand) { $gitBash = $cand }
    }
}
if ($gitBash) {
    try {
        $claudeDir = Join-Path $env:USERPROFILE ".claude"
        if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }
        $settingsPath = Join-Path $claudeDir "settings.json"

        # 重要：舊版是「檔案存在就整段跳過」，等於重跑也永遠補不上這個設定。
        #       改成讀進來合併，只加 / 更新這一個 key。
        $s = $null
        $skip = $false
        if (Test-Path $settingsPath) {
            $raw = Get-Content $settingsPath -Raw -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($raw)) { $s = New-Object PSObject }
            else { try { $s = $raw | ConvertFrom-Json -ErrorAction Stop } catch { $skip = $true } }
        } else {
            $s = New-Object PSObject
        }

        if ($skip) {
            Write-Warn2 "~/.claude/settings.json 讀不懂，為避免覆蓋你的設定，這步跳過。"
        } else {
            if ($null -eq $s.PSObject.Properties['env']) {
                $s | Add-Member -NotePropertyName 'env' -NotePropertyValue (New-Object PSObject) -Force
            }
            $s.env | Add-Member -NotePropertyName 'CLAUDE_CODE_GIT_BASH_PATH' -NotePropertyValue $gitBash -Force
            # 一定要無 BOM：帶 BOM 的 JSON 會讓 Claude Code 讀設定失敗
            Write-JsonNoBom $settingsPath $s
            Write-Ok "已寫入 Git Bash 路徑：$gitBash"
        }
    } catch {
        Write-Warn2 "寫入 settings.json 時略過：$($_.Exception.Message)"
    }
} else {
    Write-Host "  未偵測到 Git Bash 路徑，略過"
}

# --- 5.4 美化 Git Bash 提示字 ---
Write-Step "美化終端機提示字（讓畫面更乾淨好讀）"
try {
    $bashrc = Join-Path $env:USERPROFILE ".bashrc"
    $marker = "# >>> mienjing-ai-prompt >>>"
    $existing = if (Test-Path $bashrc) { Get-Content $bashrc -Raw -ErrorAction SilentlyContinue } else { "" }
    if ($null -eq $existing) { $existing = "" }
    if ($existing -notmatch [regex]::Escape($marker)) {
        # 用 LF 換行寫入（.bashrc 不能有 CR，否則 bash 會出錯）
        $lines = @(
            '',
            '# >>> mienjing-ai-prompt >>>',
            '# clean short prompt: show current folder only',
            'PS1=''\n\[\e[36m\]\w\[\e[0m\]\n$ ''',
            '# <<< mienjing-ai-prompt <<<',
            ''
        )
        $block = ($lines -join "`n")
        [System.IO.File]::AppendAllText($bashrc, $block, (New-Object System.Text.UTF8Encoding($false)))
        Write-Ok "終端機提示字已美化（乾淨短版）"
    } else {
        Write-Host "  提示字設定已存在，略過"
    }
} catch {
    Write-Warn2 "美化提示字時略過（不影響使用）"
}

# --- 5.5 專案資料夾 + 桌面捷徑 ---
Write-Step "建立專案資料夾與桌面「Claude Code」捷徑"
$projDir = Join-Path $env:USERPROFILE $projName
try {
    if (-not (Test-Path $projDir)) { New-Item -ItemType Directory -Path $projDir -Force | Out-Null }

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
    if ([string]::IsNullOrWhiteSpace($desktop)) { $desktop = Join-Path $env:USERPROFILE 'Desktop' }
    $lnkPath = Join-Path $desktop "Claude Code.lnk"
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut($lnkPath)

    $codeExe = $null
    foreach ($p in @((Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'),
                     (Join-Path $env:ProgramFiles 'Microsoft VS Code\Code.exe'))) {
        if (Test-Path $p) { $codeExe = $p; break }
    }

    if ($codeExe) {
        # 雙擊 -> 用 VS Code 打開專案資料夾
        $lnk.TargetPath        = $codeExe
        $lnk.Arguments         = '"' + $projDir + '"'
        $lnk.WorkingDirectory  = $projDir
        $lnk.Description       = "用 VS Code 打開 Claude Code 專案"
        # 用 Windows 內建的資料夾圖示，不要用 VS Code 的圖示（雙擊本來就是開資料夾）
        $iconRes = Join-Path $env:SystemRoot 'System32\imageres.dll'
        if (-not (Test-Path $iconRes)) { $iconRes = Join-Path $env:SystemRoot 'System32\shell32.dll' }
        $lnk.IconLocation = "$iconRes,3"
        $lnk.Save()
        Write-Ok "已在桌面建立「Claude Code」捷徑（雙擊用 VS Code 打開專案）"
    } else {
        # 備援：沒有 VS Code 時，雙擊改用 PowerShell 直接開 claude
        $launcher = Join-Path $projDir "open-claude.ps1"
        $lb = @'
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
Set-Location -LiteralPath $PSScriptRoot
claude
'@
        [System.IO.File]::WriteAllText($launcher, $lb, (New-Object System.Text.UTF8Encoding($true)))
        $lnk.TargetPath       = (Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe")
        $lnk.Arguments        = '-NoExit -ExecutionPolicy Bypass -File "' + $launcher + '"'
        $lnk.WorkingDirectory = $projDir
        $lnk.Description      = "開啟 Claude Code"
        $lnk.Save()
        Write-Ok "已在桌面建立「Claude Code」捷徑（雙擊直接開 Claude Code）"
    }
} catch {
    Write-Warn2 "建立桌面捷徑時有點小狀況（不影響安裝）：$($_.Exception.Message)"
}

# --- 6. 最後驗收：把真實狀態誠實報給學員看 ---
Sync-Path
Write-Step "安裝結果檢查"
$okClaude = Test-Cmd claude
$okGit    = Test-Cmd git
$okNode   = Test-Cmd node
$okCode   = $null -ne (Get-CodeCmd)
function Show-Check($name, $ok, $hint) {
    if ($ok) { Write-Host "  [OK] $name" -ForegroundColor Green }
    else     { Write-Host "  [X]  $name  -> $hint" -ForegroundColor Red }
}
Show-Check "Claude Code" $okClaude "請重開 PowerShell 再跑一次這個安裝指令"
Show-Check "Git"         $okGit    "手動安裝 https://git-scm.com/download/win"
Show-Check "Node.js"     $okNode   "手動安裝 https://nodejs.org/ （選 LTS）"
Show-Check "VS Code"     $okCode   "手動安裝 https://code.visualstudio.com/"

if ($okClaude) {
    Write-Host "`n============================================" -ForegroundColor Green
    Write-Host "   全部裝好了，你辛苦了！" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
} else {
    Write-Host "`n============================================" -ForegroundColor Yellow
    Write-Host "   還差一點點，請看上面紅色那幾行" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "我在你的桌面放了一個『Claude Code』圖示 :)" -ForegroundColor Cyan
Write-Host "你的專案資料夾：$projDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "  接下來這樣用：" -ForegroundColor Cyan
Write-Host "  1. 雙擊桌面的『Claude Code』圖示 -> 會用 VS Code 打開你的專案" -ForegroundColor White
Write-Host "  2. 打開終端機：在 VS Code 最上方的選單列點『Terminal』->『New Terminal』" -ForegroundColor White
Write-Host "     （鍵盤快速鍵：Ctrl 加上左上角 Esc 底下那個 反引號 鍵）"
if ($okGit) {
    Write-Host "     終端機會從畫面下方跳出來，已經幫你設好用 Git Bash"
} else {
    Write-Host "     終端機會從畫面下方跳出來（這台電腦沒有 Git，會是 PowerShell，一樣可以用）"
}
Write-Host "  3. 在跳出來的終端機輸入 claude，第一次會請你用瀏覽器登入" -ForegroundColor White
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

if ($logging) {
    if (-not $okClaude) {
        Write-Host "裝不起來的話，請把桌面的『claude-code-安裝紀錄.txt』傳給老師。" -ForegroundColor Yellow
        Write-Host ""
    }
    try { Stop-Transcript | Out-Null } catch { }
}
