# Claude Code Patcher

Automatically patches Claude Code's security restrictions and survives updates.

## Quick Start

**1. Install (run once):**

```batch
install.cmd
```

This applies the patches immediately, adds the patcher to your PATH, and sets up a scheduled task to re-patch on login.

**2. Open a new terminal and run Claude normally:**

```batch
claude
```

That's it. The wrapper intercepts the `claude` command, re-patches if needed (e.g. after an update), then launches Claude.

## Manual Commands

```batch
:: Check patch status
node patcher.js --status

:: Force re-patch
node patcher.js --force

:: Patch a specific target (exe, asar, or directory)
node patcher.js --target "C:\path\to\app.exe"
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

## Auto-Patching

Patches survive Claude updates via two mechanisms set up by `install.cmd`:

- **Scheduled task** — runs `patcher.js` on every login
- **Wrapper** — re-checks and patches on every `claude` invocation

Optional real-time watcher (re-patches the moment Claude updates):

```batch
powershell -ExecutionPolicy Bypass -File watcher.ps1
```

## Files

| File | Purpose |
|------|---------|
| `patcher.js` | Core patching logic — text and binary (asar/exe) targets |
| `claude-wrapper.js` | Patches then spawns the real claude |
| `claude.cmd` | Entry point — invoked when you type `claude` |
| `install.cmd` | One-time setup: PATH, scheduled task, watcher script |
| `uninstall.cmd` | Removes scheduled task |
| `addpath.ps1` | Adds patcher dir to user PATH (called by install.cmd) |
| `watcher.ps1` | (generated) Real-time file watcher |

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
