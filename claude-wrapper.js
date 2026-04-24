const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const { patch } = require('./patcher');

const UPDATE_CACHE = path.join(__dirname, '.update-cache.json');
const CHECK_INTERVAL_MS = 24 * 60 * 60 * 1000; // once per day

function checkAndUpdateClaudeCode() {
    const pkgPath = path.join(process.env.APPDATA || '', 'npm', 'node_modules', '@anthropic-ai', 'claude-code', 'package.json');

    let currentVersion;
    try {
        currentVersion = JSON.parse(fs.readFileSync(pkgPath, 'utf8')).version;
    } catch {
        return;
    }

    // load cached latest-version + last-check timestamp
    let cache = {};
    try { cache = JSON.parse(fs.readFileSync(UPDATE_CACHE, 'utf8')); } catch {}

    const stale = !cache.checkedAt || (Date.now() - new Date(cache.checkedAt).getTime()) > CHECK_INTERVAL_MS;
    let latestVersion = cache.latestVersion;

    if (stale || !latestVersion) {
        try {
            latestVersion = execSync('npm view @anthropic-ai/claude-code version', { timeout: 8000 }).toString().trim();
            fs.writeFileSync(UPDATE_CACHE, JSON.stringify({ checkedAt: new Date().toISOString(), latestVersion }));
        } catch {
            return; // network unavailable — skip silently
        }
    }

    if (currentVersion === latestVersion) return;

    console.log(`[updater] ${currentVersion} → ${latestVersion}, installing...`);
    try {
        execSync('npm install -g @anthropic-ai/claude-code', { stdio: 'inherit', timeout: 120000 });
        // refresh cache so we don't re-check immediately after install
        fs.writeFileSync(UPDATE_CACHE, JSON.stringify({ checkedAt: new Date().toISOString(), latestVersion }));
        console.log('[updater] done');
    } catch (e) {
        console.error(`[updater] update failed: ${e.message}`);
    }
}

// update if available, then patch (patcher detects hash change from new install)
checkAndUpdateClaudeCode();
patch();

// find the real claude executable
const claudePath = path.join(process.env.APPDATA, 'npm', 'claude.cmd');

// forward all arguments to claude
const args = process.argv.slice(2);
const child = spawn(claudePath, args, {
    stdio: 'inherit',
    shell: true
});

child.on('exit', (code) => {
    process.exit(code ?? 0);
});
