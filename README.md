# Claude Code Patcher

> **Educational Disclaimer:** This tool is intended solely for authorized security research, penetration testing, and educational purposes. Use only on systems you own or have explicit written permission to test. Misuse of this tool to bypass safety measures outside of a legitimate research context may violate Anthropic's Terms of Service and applicable laws. The authors assume no liability for unauthorized or malicious use.

Patches Claude Code's security restrictions and re-applies automatically on every invocation.

## Prerequisites

This patcher targets both the **npm version** of Claude Code (`@anthropic-ai/claude-code`) **and the official native installer** (the standalone `claude.exe` dropped in `%USERPROFILE%\.local\bin` by Anthropic's installer script). Node.js is still required to run the patcher itself.

**Install Node.js** (includes npm): https://nodejs.org — LTS version recommended.

**Install Claude Code** — pick whichever you prefer:

```batch
:: Option A — npm
npm install -g @anthropic-ai/claude-code

:: Option B — native installer (PowerShell)
irm https://claude.ai/install.ps1 | iex
```

Verify it installed correctly:

```batch
claude --version
```

> **Default target resolution (no `--target` required), in order:**
> 1. **npm new installs** (Claude Code ≥ ~0.2): `%APPDATA%\npm\node_modules\@anthropic-ai\claude-code\bin\claude.exe`
> 2. **npm legacy installs**: `%APPDATA%\npm\node_modules\@anthropic-ai\claude-code\cli.js`
> 3. **Native installer**: `%USERPROFILE%\.local\bin\claude.exe`
>
> The patcher walks the list and patches the first one it finds — only one target per run. The launch banner reports which source it picked (`npm` or `native`).

---

## Quick Start

**1. Install (run once):**

```batch
install.cmd
```

Applies the patches immediately and adds the patcher directory to your PATH.

**2. Open a new terminal and run Claude normally:**

```batch
claude
```

The wrapper intercepts the `claude` command, re-patches if needed (e.g. after an update), then launches Claude. On launch it prints a banner listing how many patches are currently active and their short names:

```
[patched] launching claude (npm) — 7 patches active: security-policy, malicious-folder-warning, malicious-code-warning, tool-denial-message, co-author-commit-default, co-author-pr-default, file-read-system-reminder
```

## Manual Commands

```batch
:: Check patch status
node patcher.js --status

:: Validate whether each patch's find string is still present (detects outdated patches after updates)
node patcher.js --validate

:: Force re-patch
node patcher.js --force

:: Patch a specific target (exe, asar, or directory)
node patcher.js --target "C:\path\to\app.exe"

:: Validate patches against a specific target
node patcher.js --validate --target "C:\path\to\app.exe"
```

## How It Works

1. `install.cmd` puts the patcher directory at the front of your user PATH
2. When you type `claude`, Windows finds `claude.cmd` in the patcher dir before npm's version
3. `claude.cmd` runs `claude-wrapper.js`, which calls `patcher.js` then launches the real Claude
4. **Content-based matching** — patches target actual string content, not minified variable names
5. **Hash tracking** — detects when a Claude update reverts the patch and re-applies automatically

## Patches Applied

| Name | Description |
|------|-------------|
| `security-policy` | Removes the built-in restriction on assisting with security/offensive tooling |
| `malicious-folder-warning` | Replaces the folder trust warning with a neutral message |
| `malicious-code-warning` | Changes the file-read prompt to allow full assistance with any code |
| `tool-denial-message` | Replaces the tool-denial guidance with unrestricted permission for all tool use |
| `malicious-exe-skip` | Removes the block on running executables flagged as potentially malicious *(text/cli.js targets only — string removed from compiled binary in newer releases)* |
| `co-author-commit-default` | Flips the commit attribution default to off — `Co-Authored-By: Claude` is suppressed unless `"includeCoAuthoredBy": true` is set explicitly in `settings.json` |
| `co-author-pr-default` | Same flip for PR descriptions — the `🤖 Generated with [Claude Code]` line is suppressed by default |
| `file-read-system-reminder` | Further reduces the per-file-read malware reminder after `malicious-code-warning` has run *(binary mode chains off the first patch's replacement)* |

## Files

| File | Purpose |
|------|---------|
| `patcher.js` | Core patching logic — text and binary (asar/exe) targets |
| `claude-wrapper.js` | Patches then spawns the real Claude |
| `claude.cmd` | Entry point — invoked when you type `claude` |
| `install.cmd` | One-time setup: PATH + initial patch |
| `uninstall.cmd` | Removes patch marker file |
| `addpath.ps1` | Adds patcher dir to user PATH (called by install.cmd) |

## Native / Electron App Targets

The patcher supports native Electron-based Claude installs in addition to the npm CLI. Point `--target` at the install directory or executable and it will automatically locate and patch the bundled `app.asar`:

```batch
node patcher.js --target "C:\Users\<you>\AppData\Local\Programs\Claude Code"
node patcher.js --target "C:\Users\<you>\AppData\Local\Programs\Claude Code\Claude Code.exe"
```

> **Asar integrity warning:** Some Electron builds embed a hash of `app.asar` inside the executable. If the app refuses to launch after patching, the build likely enforces asar integrity. The patcher will print a warning when this is detected. A `.bak` backup of the original asar is always created before any binary patch is applied.

## Adding Custom Patches

Edit the `patches` array in `patcher.js`:

```javascript
{
    name: 'my-patch',
    find: 'exact string to find',
    replace: 'replacement string',
    // for binary targets (asar/exe), optionally override:
    binaryFind: 'shorter string that fits in binary',
    binaryReplace: 'shorter replacement (must be ≤ binaryFind length)',
    // set true to skip binary targets entirely (e.g. string removed in compiled builds):
    textOnly: true,
}
```
