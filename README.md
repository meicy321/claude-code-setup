# Claude Code 無痛安裝（Windows 教學包）

> 給新手：不用一個一個手動下載 Node.js、Git。**複製一行指令，全自動裝好。**

---

## 🚀 方法一｜一鍵腳本（最無痛，推薦給純新手）

1. 按 **開始** → 搜尋 **PowerShell** → 打開
2. 複製下面這一行，貼上、按 Enter：

```powershell
irm https://raw.githubusercontent.com/<你的GitHub帳號>/<你的repo>/main/install-claude-code.ps1 | iex
```

腳本會自動：
- ✅ 檢查你的 Windows 版本（太舊會提醒）
- ✅ 安裝 **Git for Windows**（給 Claude Code 的 Bash 工具用，體驗更好）
- ✅ 安裝 **Node.js LTS**（給 MCP server / npx / 前端專案用）
- ✅ 用官方**原生方式**安裝 Claude Code 本體（不透過 npm，才能自動更新、不被 Node 版本綁死）
- ✅ 幫你寫好設定檔
- ✅ 告訴你怎麼登入

> 💡 觀念：**「裝 Node.js」和「用 npm 裝 Claude Code」是兩件事。**
> 我們兩個都給你——裝 Node.js（給 MCP／專案用），但 Claude Code 本體走原生安裝，最穩。

裝完 → 關掉重開 PowerShell → 到你的專案資料夾 → 輸入 `claude` → 瀏覽器登入即可。

---

## ⚡ 方法二｜官方原生安裝（兩行，官方推薦）

適合大多數 Windows 10 (1809+) / 11。**不需要 Node.js。**

```powershell
winget install Git.Git                 # 選配，給 Bash 工具（建議裝）
irm https://claude.ai/install.ps1 | iex   # 安裝 Claude Code 本體
```

---

## 🧩 方法三｜Node.js / npm 路線（＝HiSKIO 課程教的方式）

只有在「你本來就有 Node.js」或「想跟課程畫面完全一致」時才用這條。

```powershell
winget install OpenJS.NodeJS            # Node.js 22 以上
winget install Git.Git                  # Git for Windows
npm install -g @anthropic-ai/claude-code
```

> ⚠️ 注意：Node 版本要 **22 以上**，否則 npm 安裝會失敗。

---

## 🔑 安裝後：登入與第一次使用

```powershell
cd C:\你的專案資料夾
claude
```

- 第一次會自動開瀏覽器登入（用 Claude Pro / Max 訂閱，或 Console API 帳號）
- 瀏覽器沒開？在畫面按 `c` 複製登入網址，手動貼上
- 對話中打 `/login` 換帳號、`/logout` 登出

常用維護指令：

```powershell
claude update    # 更新到最新版
claude --version # 看版本
```

---

## 🩺 不同 Windows 版本 / 常見問題

| 狀況 | 解法 |
|---|---|
| 找不到 `winget` | 開 Microsoft Store 搜「App Installer」更新，或到 https://aka.ms/getwinget |
| Windows 太舊（低於 10 1809） | 先更新 Windows，或改用 WSL 安裝 |
| 下載一直失敗 / TLS 錯誤 | 腳本已自動強制 TLS 1.2；手動時先跑 `[Net.ServicePointManager]::SecurityProtocol = 'Tls12'` |
| 打 `claude` 說找不到指令 | 關掉 PowerShell 重開一個新視窗（讓 PATH 生效） |
| 有裝 Git 但 Claude 找不到 Bash | 在 `%USERPROFILE%\.claude\settings.json` 設定 `CLAUDE_CODE_GIT_BASH_PATH` |

---

## 📋 系統需求
- Windows 10 (Build 1809 / 17763) 以上，或 Windows 11
- 4GB 以上記憶體、x64 或 ARM64、需連網
- Git for Windows 為選配（沒有會自動用 PowerShell 當 shell）
