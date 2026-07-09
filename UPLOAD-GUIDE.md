# 📤 如何把這包上傳到你的 GitHub（三選一）

> 目標：上傳後，學生只要複製「一行指令」就能無腦安裝。
> 這個資料夾我已經幫你 **git 初始化並 commit 好了**，你只差把它推到 GitHub。

---

## 先決定 repo 名稱
建議叫 `claude-code-setup`（下面都用這個名字示範）。

---

## 🟢 方法 A：網頁拖拉上傳（不用打指令，最簡單）

1. 到 https://github.com/new 建立新 repo
   - Repository name：`claude-code-setup`
   - 選 **Public**（一定要 public，學生才抓得到）
   - **不要**勾 Add a README（這包已經有了）
   - 按 **Create repository**
2. 在新頁面點 **uploading an existing file**
3. 把這個資料夾裡的 4 個檔案全部拖進去：
   - `install-claude-code.ps1`
   - `README.md`
   - `handout.html`
   - `UPLOAD-GUIDE.md`
4. 按 **Commit changes** ✅ 完成

---

## 🟡 方法 B：用 GitHub CLI（gh）一鍵推送

若你有裝 `gh`（沒有的話：`winget install GitHub.cli`，然後 `gh auth login`）：

```powershell
cd C:\Users\user\claude-code-setup
gh repo create claude-code-setup --public --source=. --remote=origin --push
```

一行就建 repo + 推上去。

---

## 🔵 方法 C：用 git 指令推送

先在 https://github.com/new 建好一個**空的** public repo（不要加 README），然後：

```powershell
cd C:\Users\user\claude-code-setup
git branch -M main
git remote add origin https://github.com/meicy321/claude-code-setup.git
git push -u origin main
```

第一次 push 會跳出 GitHub 登入視窗，照著授權即可。

---

## ✅ 上傳完成後：拿到「給學生的一行指令」

你的安裝腳本 raw 網址會是：

```
https://raw.githubusercontent.com/meicy321/claude-code-setup/main/install-claude-code.ps1
```

所以發給學生的**一行指令**是：

```powershell
irm https://raw.githubusercontent.com/meicy321/claude-code-setup/main/install-claude-code.ps1 | iex
```

> 把 `meicy321` 換成你的 GitHub 帳號。這行貼進投影片 / 課程頁即可。

### 記得順手改兩個地方的佔位字（換成你真實帳號）
1. `README.md` 裡的 `<你的GitHub帳號>/<你的repo>`
2. `handout.html` 裡的 `meicy321`（第一個 code 區塊，以及最下面 `<script>` 的 `text` 變數）

改完再重新上傳覆蓋即可。（用方法 A 就是再拖一次同名檔案。）

---

## 🌐 線上講義（已幫你發佈）
一頁式教學網頁（可投影 / 發連結給學生）：
**https://claude.ai/code/artifact/01f2fc7e-4390-4867-bf7f-3e509e2ce479**

> 這是預設私人的；要給學生看的話，到該頁右上角的分享選單設成可分享。
