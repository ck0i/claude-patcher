# Claude Code Patcher

> **Educational Disclaimer:** This tool is intended solely for authorized security research, penetration testing, and educational purposes. Use only on systems you own or have explicit written permission to test. Misuse of this tool to bypass safety measures outside of a legitimate research context may violate Anthropic's Terms of Service and applicable laws. The authors assume no liability for unauthorized or malicious use.

Patches Claude Code's security restrictions and re-applies automatically on every invocation.

## Prerequisites

This patcher targets the **npm version** of Claude Code (`@anthropic-ai/claude-code`).

**Install Node.js** (includes npm): https://nodejs.org — LTS version recommended.

**Install Claude Code via npm:**

```batch
npm install -g @anthropic-ai/claude-code
```

Verify it installed correctly:

```batch
claude --version
```

> The patcher expects Claude Code at `%APPDATA%\npm\node_modules\@anthropic-ai\claude-code\cli.js` — the default global npm install location on Windows.

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

The wrapper intercepts the `claude` command, re-patches if needed (e.g. after an update), then launches Claude.

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
| `malicious-exe-skip` | Removes the block on running executables flagged as potentially malicious |
| `file-read-system-reminder` | Replaces the per-file-read malware refusal reminder with a permissive researcher prompt |

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
    binaryReplace: 'shorter replacement',
}
```
