# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

"免驚 AI" (Mien-Jing AI) — a static, no-build tutorial site + PowerShell installer that teaches complete beginners on Windows how to install and start using Claude Code. There is no application code, no package manager, and no build/test/lint tooling: the repo is a handful of standalone HTML pages and one PowerShell script, published via GitHub Pages.

Live site: https://meicy321.github.io/claude-code-setup/
One-line install command distributed to students:
```powershell
irm https://raw.githubusercontent.com/meicy321/claude-code-setup/main/install-claude-code.ps1 | iex
```

## Repo structure

- `install-claude-code.ps1` — the one-click installer. Checks Windows build ≥ 17763, installs Git for Windows / Node.js LTS / VS Code + the `anthropic.claude-code` extension / Claude Code itself (native installer, not npm) via `winget`, sets `CLAUDE_CODE_GIT_BASH_PATH` in `~/.claude/settings.json`, appends a short-prompt block to `~/.bashrc`, and creates a desktop shortcut that opens a new project folder in VS Code. Every step is wrapped in try/catch and degrades gracefully (e.g. no `winget` → warn and continue) since the audience is non-technical and must not get stuck.
- `index.html` / `en.html` / `tai.html` — the "book": the same multi-chapter tutorial in Traditional Chinese, English, and Taiwanese Hokkien (`lang="nan-Hant-TW"`) respectively. `index.html` is canonical/served at the site root; `en.html`/`tai.html` are language variants reached via the in-page language switcher.
- `statusline.html` / `statusline-en.html` / `statusline-tai.html` — Chapter ② of the same book (installing a Claude Code statusline), one file per language, same pattern as above.
- `README.md` — chapter index + three install methods (one-click script / official native installer / npm route) + troubleshooting table. Chinese-only.
- `UPLOAD-GUIDE.md` — instructions (in Chinese) for the repo owner on publishing this repo to GitHub / GitHub Pages. Not relevant to end users.
- `docs/` — Chinese working notes (dated 工作日誌 = work logs, and a video-script draft). Not part of the published site.
- `.gitignore` — ignores `Thumbs.db`, `desktop.ini`, `.DS_Store`.

## Editing conventions specific to this repo

- **Every user-facing HTML page is a single self-contained file**: inline `<style>` and inline `<script>`, no external assets, no bundler. When editing content, edit the HTML directly — there is no source-of-truth template that generates these pages.
- **Three-language parity is load-bearing.** Any content/structural change to a chapter must be mirrored across its `zh` / `en` / `nan` (Taiwanese) files (e.g. `index.html` ↔ `en.html` ↔ `tai.html`, or `statusline.html` ↔ `statusline-en.html` ↔ `statusline-tai.html`). Git history shows corrections are often driven by native-speaker feedback on the Taiwanese translation specifically — double-check wording there rather than assuming a direct translation from Chinese is correct.
- **GitHub Pages deploys straight off `main`** with no build step — pushing to `main` updates the live site (per `UPLOAD-GUIDE.md`, in ~1 minute). Treat edits to `.html` files as effectively production changes.
- **`install-claude-code.ps1` targets absolute beginners on Windows.** Preserve the pattern of colored `Write-Step`/`Write-Ok`/`Write-Warn2`/`Write-Err2` helper output, and the graceful-degradation style (missing `winget`/Git/Node/VS Code should warn and continue, never hard-fail, except the Windows-build check which intentionally aborts). The script forces TLS 1.2 at the top for older Windows installs — keep that first.
- The installer intentionally installs Claude Code via the official native installer (`irm https://claude.ai/install.ps1 | iex`), not npm, so it can auto-update independent of the Node.js version — don't collapse this into the npm route.
- License is CC BY-NC-SA 4.0, non-commercial; the script header explicitly asks forks to retain author attribution and not resell under a different brand.

## Git / push permissions

The user (meicy321) has pre-authorized pushing to `origin` (`github.com/meicy321/claude-code-setup.git`) on `main` for this repo. Since `main` is what GitHub Pages deploys, this means: after committing a change here, push it to `origin/main` without asking for separate confirmation each time. This does not extend to other repos, and destructive operations (force-push, history rewrite, branch deletion) still require explicit confirmation as usual.

## Testing changes

There is no automated test suite. To verify changes:
- HTML pages: open the file directly in a browser (or via the GitHub Pages URL after pushing) and check rendering/language switch links/copy-to-clipboard button.
- `install-claude-code.ps1`: read through for correctness — running it live performs real system installs (Git/Node/VS Code/Claude Code) and writes to `~/.claude/settings.json` and `~/.bashrc`, so don't execute it casually against a real environment when just reviewing edits.
