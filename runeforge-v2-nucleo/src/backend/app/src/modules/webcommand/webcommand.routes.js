const express = require('express');
const { execFile } = require('child_process');
const fs = require('fs');
const path = require('path');

const router = express.Router();

const RF_ROOT = 'C:\\RUNEFOGE_PRO\\runeforge';
const RF_APP = path.join(RF_ROOT, 'app');

const ALLOWED_ACTIONS = new Set([
  'status',
  'backend-root',
  'package',
  'src-tree',
  'pm2-health'
]);

function runPwsh(args, cwd = RF_ROOT, timeoutMs = 15000) {
  return new Promise((resolve) => {
    execFile(
      'pwsh.exe',
      ['-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', ...args],
      {
        cwd,
        timeout: timeoutMs,
        windowsHide: true,
        maxBuffer: 1024 * 1024
      },
      (error, stdout, stderr) => {
        resolve({
          ok: !error,
          code: error && typeof error.code !== 'undefined' ? error.code : 0,
          stdout: String(stdout || ''),
          stderr: String(stderr || ''),
          error: error ? String(error.message || error) : null
        });
      }
    );
  });
}

function safeJsonRead(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (err) {
    return { error: String(err.message || err) };
  }
}

router.get('/api/webcommand/health', (req, res) => {
  res.json({
    ok: true,
    service: 'Runeforge WebCommand',
    mode: 'safe-readonly',
    allowedActions: Array.from(ALLOWED_ACTIONS)
  });
});

router.post('/api/webcommand', async (req, res) => {
  const action = String(req.body && req.body.action ? req.body.action : '').trim();

  if (!ALLOWED_ACTIONS.has(action)) {
    return res.status(400).json({
      ok: false,
      error: 'ACTION_NOT_ALLOWED',
      action,
      allowedActions: Array.from(ALLOWED_ACTIONS)
    });
  }

  try {
    if (action === 'status') {
      return res.json({
        ok: true,
        action,
        result: {
          root: RF_ROOT,
          app: RF_APP,
          rootExists: fs.existsSync(RF_ROOT),
          appExists: fs.existsSync(RF_APP),
          packageJsonExists: fs.existsSync(path.join(RF_APP, 'package.json')),
          serverJsExists: fs.existsSync(path.join(RF_APP, 'src', 'server.js')),
          appJsExists: fs.existsSync(path.join(RF_APP, 'src', 'app.js')),
          timestamp: new Date().toISOString()
        }
      });
    }

    if (action === 'backend-root') {
      const output = await runPwsh([
        '-Command',
        "$Root='C:\\RUNEFOGE_PRO\\runeforge'; Get-ChildItem $Root -Force | Select-Object Mode,Length,LastWriteTime,Name | Format-Table -AutoSize | Out-String"
      ]);
      return res.json({ ok: output.ok, action, output });
    }

    if (action === 'package') {
      const pkgPath = path.join(RF_APP, 'package.json');
      return res.json({
        ok: fs.existsSync(pkgPath),
        action,
        packagePath: pkgPath,
        result: fs.existsSync(pkgPath) ? safeJsonRead(pkgPath) : null
      });
    }

    if (action === 'src-tree') {
      const output = await runPwsh([
        '-Command',
        "$Src='C:\\RUNEFOGE_PRO\\runeforge\\app\\src'; Get-ChildItem $Src -Recurse -File -Include *.js,*.ts | Where-Object {$_.FullName -notmatch '\\\\node_modules\\\\'} | Select-Object FullName,Length | Format-Table -AutoSize | Out-String"
      ]);
      return res.json({ ok: output.ok, action, output });
    }

    if (action === 'pm2-health') {
      const output = await runPwsh([
        '-Command',
        "$pm2=(Get-Command pm2 -ErrorAction SilentlyContinue); $health=$null; try{$health=Invoke-RestMethod 'http://127.0.0.1:3100/health' -TimeoutSec 5}catch{$health=[pscustomobject]@{error=$_.Exception.Message}}; [pscustomobject]@{pm2Exists=[bool]$pm2; pm2Path=if($pm2){$pm2.Source}else{$null}; health=$health; ts=(Get-Date).ToString('o')} | ConvertTo-Json -Depth 8"
      ]);
      return res.json({ ok: output.ok, action, output });
    }

    return res.status(500).json({ ok: false, error: 'UNHANDLED_ACTION', action });
  } catch (err) {
    return res.status(500).json({
      ok: false,
      action,
      error: String(err.message || err)
    });
  }
});



// === RF_PANEL_WEBCOMMAND_STATIC_V1_1_BEGIN ===
router.get("/panel/webcommand", (req, res) => {
  res.sendFile(path.join(RF_ROOT, "data", "webcommand", "panel", "RUNEFORGE_PANEL_WEBCOMMAND_V1_1.html"));
});

router.get("/api/panel/webcommand", (req, res) => {
  res.redirect("/panel/webcommand");
});
// === RF_PANEL_WEBCOMMAND_STATIC_V1_1_END ===


module.exports = router;
