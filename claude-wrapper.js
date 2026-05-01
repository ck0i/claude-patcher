const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const { patch, getActivePatches } = require('./patcher');

const UPDATE_CACHE = path.join(__dirname, '.update-cache.json');
const CHECK_INTERVAL_MS = 24 * 60 * 60 * 1000; // once per day

// npm install doesn't self-update; the native installer does, so we only run this for npm.
function checkAndUpdateNpmClaudeCode() {
    const pkgPath = path.join(process.env.APPDATA || '', 'npm', 'node_modules', '@anthropic-ai', 'claude-code', 'package.json');

    const currentVersion = JSON.parse(fs.readFileSync(pkgPath, 'utf8')).version;

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

// find the real claude executable — prefer npm install, fall back to native installer
const npmCmd = path.join(process.env.APPDATA || '', 'npm', 'claude.cmd');
const nativeExe = path.join(process.env.USERPROFILE || process.env.HOME || '', '.local', 'bin', 'claude.exe');

let claudePath, source;
if (fs.existsSync(npmCmd)) {
    claudePath = npmCmd;
    source = 'npm';
} else if (fs.existsSync(nativeExe)) {
    claudePath = nativeExe;
    source = 'native';
} else {
    console.error('[wrapper] no claude install found');
    console.error(`  checked (npm): ${npmCmd}`);
    console.error(`  checked (native): ${nativeExe}`);
    process.exit(1);
}

// npm install needs an external update check; native installer self-updates on launch.
if (source === 'npm') checkAndUpdateNpmClaudeCode();
patch();

// let the user know they're entering the patched context
const active = getActivePatches();
const summary = active.length === 0
    ? 'no active patches'
    : `${active.length} patch${active.length === 1 ? '' : 'es'} active: ${active.join(', ')}`;
console.log(`\x1b[35m[patched]\x1b[0m launching claude (${source}) — ${summary}\n`);

// forward all arguments to claude
const args = process.argv.slice(2);
const child = spawn(claudePath, args, {
    stdio: 'inherit',
    shell: true
});

child.on('exit', (code) => {
    process.exit(code ?? 0);
});
