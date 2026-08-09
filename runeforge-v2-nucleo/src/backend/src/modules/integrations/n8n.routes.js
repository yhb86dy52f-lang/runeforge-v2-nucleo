const express = require('express');
const fs = require('fs');
const path = require('path');

const router = express.Router();

const DEFAULT_N8N_PING_URL = 'http://127.0.0.1:5680/webhook/rf-core-ping-v1';
const DEFAULT_N8N_TASK_INTAKE_URL = 'http://127.0.0.1:5680/webhook/rf-task-intake-v2';
const DEFAULT_N8N_ACTION_ROUTER_URL = 'http://127.0.0.1:5680/webhook/rf-action-router-v3';

function getPingUrl() {
  return process.env.RF_N8N_PING_URL || process.env.N8N_PING_URL || DEFAULT_N8N_PING_URL;
}

function getTaskIntakeUrl() {
  return process.env.RF_N8N_TASK_INTAKE_URL || process.env.N8N_TASK_INTAKE_URL || DEFAULT_N8N_TASK_INTAKE_URL;
}

function getActionRouterUrl() {
  return process.env.RF_N8N_ACTION_ROUTER_URL || process.env.N8N_ACTION_ROUTER_URL || DEFAULT_N8N_ACTION_ROUTER_URL;
}

function getTimeoutMs() {
  const value = Number(process.env.RF_N8N_TIMEOUT_MS || process.env.N8N_TIMEOUT_MS || 8000);
  return Number.isFinite(value) && value > 0 ? value : 8000;
}

function getTraceDir() {
  const root = process.env.RUNEFORGE_ROOT || path.resolve(process.cwd(), '..');
  return path.join(root, 'data', 'traces');
}

function appendTrace(prefix, event) {
  try {
    const traceDir = getTraceDir();
    fs.mkdirSync(traceDir, { recursive: true });
    const day = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const traceFile = path.join(traceDir, `${prefix}_${day}.jsonl`);
    fs.appendFileSync(traceFile, JSON.stringify(event) + '\n', 'utf8');
    return traceFile;
  } catch (_) {
    return null;
  }
}

async function fetchJsonWithTimeout(url, requestOptions, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, {
      ...requestOptions,
      signal: controller.signal
    });

    const text = await response.text();
    let data = null;

    try {
      data = text ? JSON.parse(text) : null;
    } catch (_) {
      data = { raw: text };
    }

    return {
      httpStatus: response.status,
      httpOk: response.ok,
      data
    };
  } finally {
    clearTimeout(timer);
  }
}

async function handleN8nPing(req, res) {
  const startedAt = Date.now();
  const url = getPingUrl();
  const timeoutMs = getTimeoutMs();

  try {
    const upstream = await fetchJsonWithTimeout(url, { method: 'GET' }, timeoutMs);
    const durationMs = Date.now() - startedAt;
    const n8nOk = upstream.httpOk && upstream.data && upstream.data.ok === true;

    const payload = {
      ok: n8nOk,
      service: 'Runeforge',
      integration: 'n8n',
      mode: 'ping',
      status: n8nOk ? 'N8N_OK' : 'N8N_ERROR',
      durationMs,
      upstream: {
        url,
        httpStatus: upstream.httpStatus,
        httpOk: upstream.httpOk,
        response: upstream.data
      },
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      ts: new Date().toISOString()
    };

    const traceFile = appendTrace('rf_core_n8n_ping', {
      timestamp: new Date().toISOString(),
      event: n8nOk ? 'RF_CORE_N8N_PING_OK' : 'RF_CORE_N8N_PING_ERROR',
      route: req.originalUrl,
      url,
      duration_ms: durationMs,
      response_ok: n8nOk,
      upstream,
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO'
    });

    payload.traceFile = traceFile || 'TRACE_WRITE_SKIPPED';

    return res.status(n8nOk ? 200 : 502).json(payload);
  } catch (error) {
    const durationMs = Date.now() - startedAt;

    const payload = {
      ok: false,
      service: 'Runeforge',
      integration: 'n8n',
      mode: 'ping',
      status: 'N8N_UNREACHABLE',
      durationMs,
      upstream: {
        url,
        error: error.message
      },
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      ts: new Date().toISOString()
    };

    const traceFile = appendTrace('rf_core_n8n_ping', {
      timestamp: new Date().toISOString(),
      event: 'RF_CORE_N8N_PING_EXCEPTION',
      route: req.originalUrl,
      url,
      duration_ms: durationMs,
      response_ok: false,
      error: error.message,
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO'
    });

    payload.traceFile = traceFile || 'TRACE_WRITE_SKIPPED';

    return res.status(503).json(payload);
  }
}

async function handleN8nTaskIntake(req, res) {
  const startedAt = Date.now();
  const url = getTaskIntakeUrl();
  const timeoutMs = getTimeoutMs();

  const body = req.body && typeof req.body === 'object' ? req.body : {};

  const outbound = {
    intent: body.intent || 'core_task_intake',
    source: body.source || 'runeforge_core',
    payload: body.payload || body,
    meta: {
      route: req.originalUrl,
      bridge: 'RUNEFORGE_CORE_TO_N8N_TASK_INTAKE_V2',
      backend_core: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      ts: new Date().toISOString()
    }
  };

  try {
    const upstream = await fetchJsonWithTimeout(url, {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify(outbound)
    }, timeoutMs);

    const durationMs = Date.now() - startedAt;
    const n8nOk = upstream.httpOk && upstream.data && upstream.data.ok === true;

    const payload = {
      ok: n8nOk,
      service: 'Runeforge',
      integration: 'n8n',
      mode: 'task-intake',
      status: n8nOk ? 'N8N_TASK_INTAKE_OK' : 'N8N_TASK_INTAKE_ERROR',
      durationMs,
      sent: outbound,
      upstream: {
        url,
        httpStatus: upstream.httpStatus,
        httpOk: upstream.httpOk,
        response: upstream.data
      },
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      ts: new Date().toISOString()
    };

    const traceFile = appendTrace('rf_core_n8n_task_intake', {
      timestamp: new Date().toISOString(),
      event: n8nOk ? 'RF_CORE_N8N_TASK_INTAKE_OK' : 'RF_CORE_N8N_TASK_INTAKE_ERROR',
      route: req.originalUrl,
      url,
      duration_ms: durationMs,
      response_ok: n8nOk,
      sent: outbound,
      upstream,
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO'
    });

    payload.traceFile = traceFile || 'TRACE_WRITE_SKIPPED';

    return res.status(n8nOk ? 200 : 502).json(payload);
  } catch (error) {
    const durationMs = Date.now() - startedAt;

    const payload = {
      ok: false,
      service: 'Runeforge',
      integration: 'n8n',
      mode: 'task-intake',
      status: 'N8N_TASK_INTAKE_UNREACHABLE',
      durationMs,
      sent: outbound,
      upstream: {
        url,
        error: error.message
      },
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      ts: new Date().toISOString()
    };

    const traceFile = appendTrace('rf_core_n8n_task_intake', {
      timestamp: new Date().toISOString(),
      event: 'RF_CORE_N8N_TASK_INTAKE_EXCEPTION',
      route: req.originalUrl,
      url,
      duration_ms: durationMs,
      response_ok: false,
      sent: outbound,
      error: error.message,
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO'
    });

    payload.traceFile = traceFile || 'TRACE_WRITE_SKIPPED';

    return res.status(503).json(payload);
  }
}

async function handleN8nActionRouter(req, res) {
  const startedAt = Date.now();
  const url = getActionRouterUrl();
  const timeoutMs = getTimeoutMs();

  const body = req.body && typeof req.body === 'object' ? req.body : {};

  const outbound = {
    request_id: body.request_id || `rf-core-${Date.now()}`,
    intent: body.intent || '',
    source: body.source || 'runeforge_core',
    payload: body.payload || {},
    meta: {
      route: req.originalUrl,
      bridge: 'RUNEFORGE_CORE_TO_N8N_ACTION_ROUTER_V3',
      backend_core: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      policy: 'ALLOWLIST_INTENTS_ONLY_NO_SHELL',
      ts: new Date().toISOString()
    }
  };

  try {
    const upstream = await fetchJsonWithTimeout(url, {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify(outbound)
    }, timeoutMs);

    const durationMs = Date.now() - startedAt;
    const n8nAccepted = upstream.httpOk && upstream.data && upstream.data.ok === true;
    const n8nBlocked = upstream.httpOk && upstream.data && upstream.data.status === 'INTENT_NOT_ALLOWED';
    const ok = n8nAccepted || n8nBlocked;

    const payload = {
      ok,
      accepted: n8nAccepted,
      blocked: n8nBlocked,
      service: 'Runeforge',
      integration: 'n8n',
      mode: 'action-router-v3',
      status: n8nAccepted ? 'N8N_ACTION_ROUTER_ACCEPTED' : (n8nBlocked ? 'N8N_ACTION_ROUTER_BLOCKED' : 'N8N_ACTION_ROUTER_ERROR'),
      durationMs,
      sent: outbound,
      upstream: {
        url,
        httpStatus: upstream.httpStatus,
        httpOk: upstream.httpOk,
        response: upstream.data
      },
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      execution_policy: {
        shell: false,
        filesystem_write: false,
        external_network: false,
        controlled_actions_only: true
      },
      ts: new Date().toISOString()
    };

    const traceFile = appendTrace('rf_core_n8n_action_router_v3', {
      timestamp: new Date().toISOString(),
      event: n8nAccepted ? 'RF_CORE_N8N_ACTION_ROUTER_V3_ACCEPTED' : (n8nBlocked ? 'RF_CORE_N8N_ACTION_ROUTER_V3_BLOCKED' : 'RF_CORE_N8N_ACTION_ROUTER_V3_ERROR'),
      route: req.originalUrl,
      url,
      duration_ms: durationMs,
      response_ok: ok,
      accepted: n8nAccepted,
      blocked: n8nBlocked,
      sent: outbound,
      upstream,
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO'
    });

    payload.traceFile = traceFile || 'TRACE_WRITE_SKIPPED';

    return res.status(ok ? 200 : 502).json(payload);
  } catch (error) {
    const durationMs = Date.now() - startedAt;

    const payload = {
      ok: false,
      accepted: false,
      blocked: false,
      service: 'Runeforge',
      integration: 'n8n',
      mode: 'action-router-v3',
      status: 'N8N_ACTION_ROUTER_UNREACHABLE',
      durationMs,
      sent: outbound,
      upstream: {
        url,
        error: error.message
      },
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      ts: new Date().toISOString()
    };

    const traceFile = appendTrace('rf_core_n8n_action_router_v3', {
      timestamp: new Date().toISOString(),
      event: 'RF_CORE_N8N_ACTION_ROUTER_V3_EXCEPTION',
      route: req.originalUrl,
      url,
      duration_ms: durationMs,
      response_ok: false,
      sent: outbound,
      error: error.message,
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO'
    });

    payload.traceFile = traceFile || 'TRACE_WRITE_SKIPPED';

    return res.status(503).json(payload);
  }
}

router.get('/integrations/n8n/ping', handleN8nPing);
router.get('/api/integrations/n8n/ping', handleN8nPing);

router.post('/integrations/n8n/task-intake', handleN8nTaskIntake);
router.post('/api/integrations/n8n/task-intake', handleN8nTaskIntake);

router.post('/integrations/n8n/action-router', handleN8nActionRouter);
router.post('/api/integrations/n8n/action-router', handleN8nActionRouter);
router.post('/integrations/n8n/action-router-v3', handleN8nActionRouter);
router.post('/api/integrations/n8n/action-router-v3', handleN8nActionRouter);


// === RF_ACTIONS_CONTROLADAS_V4_BEGIN ===
async function handleActionsV4(req, res) {
  const startedAt = Date.now();
  const body = req.body && typeof req.body === 'object' ? req.body : {};
  const requestId = body.request_id || `rf-actions-v4-${Date.now()}`;
  const intent = String(body.intent || '').trim();
  const source = body.source || 'runeforge_core_actions_v4';
  const payload = body.payload && typeof body.payload === 'object' ? body.payload : {};
  const policyUrl = getActionRouterUrl();
  const timeoutMs = getTimeoutMs();

  const outbound = {
    request_id: requestId,
    intent,
    source,
    payload,
    meta: {
      route: req.originalUrl,
      bridge: 'RUNEFORGE_CORE_ACTIONS_CONTROLADAS_V4',
      backend_core: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      policy: 'ALLOWLIST_INTENTS_ONLY_NO_SHELL',
      ts: new Date().toISOString()
    }
  };

  let policy;
  try {
    policy = await fetchJsonWithTimeout(policyUrl, {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify(outbound)
    }, timeoutMs);
  } catch (error) {
    const durationMs = Date.now() - startedAt;
    const traceFile = appendTrace('rf_actions_v4_error', {
      timestamp: new Date().toISOString(),
      event: 'RF_ACTIONS_V4_POLICY_UNREACHABLE',
      request_id: requestId,
      intent,
      source,
      error: error.message,
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO'
    });

    return res.status(503).json({
      ok: false,
      accepted: false,
      blocked: false,
      service: 'Runeforge',
      module: 'RF_ACTIONS_CONTROLADAS_V4',
      status: 'POLICY_ROUTER_UNREACHABLE',
      durationMs,
      policy_router: { url: policyUrl, error: error.message },
      traceFile: traceFile || 'TRACE_WRITE_SKIPPED',
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      ts: new Date().toISOString()
    });
  }

  const policyData = policy.data || {};
  const accepted = policy.httpOk === true && policyData.ok === true && policyData.status === 'RF_ACTION_ROUTER_V3_ACCEPTED';
  const blocked = policy.httpOk === true && policyData.status === 'INTENT_NOT_ALLOWED';

  if (blocked || !accepted) {
    const durationMs = Date.now() - startedAt;
    const traceFile = appendTrace('rf_actions_v4_blocked', {
      timestamp: new Date().toISOString(),
      event: 'RF_ACTIONS_V4_BLOCKED',
      request_id: requestId,
      intent,
      source,
      policy_response: policyData,
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO'
    });

    return res.status(200).json({
      ok: true,
      accepted: false,
      blocked: true,
      service: 'Runeforge',
      module: 'RF_ACTIONS_CONTROLADAS_V4',
      status: blocked ? 'RF_ACTIONS_V4_BLOCKED_BY_POLICY' : 'RF_ACTIONS_V4_POLICY_REJECTED',
      durationMs,
      intent,
      request_id: requestId,
      allowed_intents: policyData.allowed_intents || ['ping','echo','trace_event','health_check_request'],
      policy_router: { url: policyUrl, httpStatus: policy.httpStatus, response: policyData },
      execution_policy: { shell: false, filesystem_write: 'trace_only', external_network: false, controlled_actions_only: true },
      traceFile: traceFile || 'TRACE_WRITE_SKIPPED',
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      ts: new Date().toISOString()
    });
  }

  let actionResult = {};
  let status = 'RF_ACTION_EXECUTED';
  let traceWritten = false;

  try {
    if (intent === 'ping') {
      actionResult = { pong: true, message: 'RF_ACTIONS_CONTROLADAS_V4_OK' };
    } else if (intent === 'echo') {
      actionResult = { echo: payload };
    } else if (intent === 'trace_event') {
      const rawEvent = String(payload.event || payload.name || 'rf_trace_event');
      const safeEvent = rawEvent.replace(/[^a-zA-Z0-9_\-:.]/g, '_').slice(0, 80) || 'rf_trace_event';
      const traceFile = appendTrace('rf_actions_v4_trace_event', {
        timestamp: new Date().toISOString(),
        event: safeEvent,
        request_id: requestId,
        source,
        payload,
        action: 'trace_event',
        backend: 'RUNEFORGE_CORE',
        runtime_original: 'NO_TOCADO',
        module: 'RF_ACTIONS_CONTROLADAS_V4'
      });
      traceWritten = !!traceFile;
      actionResult = { trace_event: safeEvent, trace_written: traceWritten, trace_file: traceFile || 'TRACE_WRITE_SKIPPED' };
    } else if (intent === 'health_check_request') {
      const healthUrl = 'http://127.0.0.1:3100/health';
      const health = await fetchJsonWithTimeout(healthUrl, { method: 'GET' }, timeoutMs);
      actionResult = { health_url: healthUrl, http_status: health.httpStatus, http_ok: health.httpOk, response: health.data };
    } else {
      status = 'RF_ACTION_UNKNOWN_AFTER_POLICY';
      actionResult = { error: 'Intent accepted by policy router but not implemented in V4.', intent };
    }
  } catch (error) {
    status = 'RF_ACTION_EXECUTION_ERROR';
    actionResult = { error: error.message, intent };
  }

  const durationMs = Date.now() - startedAt;
  const ok = status === 'RF_ACTION_EXECUTED';

  const traceFile = appendTrace('rf_actions_v4_execute', {
    timestamp: new Date().toISOString(),
    event: status,
    request_id: requestId,
    intent,
    source,
    duration_ms: durationMs,
    response_ok: ok,
    action_result: actionResult,
    backend: 'RUNEFORGE_CORE',
    runtime_original: 'NO_TOCADO'
  });

  return res.status(ok ? 200 : 500).json({
    ok,
    accepted: true,
    blocked: false,
    service: 'Runeforge',
    module: 'RF_ACTIONS_CONTROLADAS_V4',
    status,
    action: intent,
    request_id: requestId,
    durationMs,
    trace_written: traceWritten,
    action_result: actionResult,
    policy_router: { url: policyUrl, httpStatus: policy.httpStatus, response: policyData },
    execution_policy: { shell: false, filesystem_write: 'trace_only', external_network: false, controlled_actions_only: true },
    traceFile: traceFile || 'TRACE_WRITE_SKIPPED',
    backend: 'RUNEFORGE_CORE',
    runtime_original: 'NO_TOCADO',
    ts: new Date().toISOString()
  });
}

router.post('/actions/v4/execute', handleActionsV4);
router.post('/api/actions/v4/execute', handleActionsV4);
// === RF_ACTIONS_CONTROLADAS_V4_END ===


// === RF_ACTIONS_CONTROLADAS_V5_BEGIN ===
function rfV5GetActionRouterUrl() {
  return process.env.RF_N8N_ACTION_ROUTER_V5_URL || process.env.N8N_ACTION_ROUTER_V5_URL || 'http://127.0.0.1:5680/webhook/rf-action-router-v5';
}

function rfV5Root() {
  return process.env.RUNEFORGE_ROOT || 'C:\\RUNEFOGE_PRO\\runeforge';
}

function rfV5ObsidianDir() {
  return process.env.RF_OBSIDIAN_RUNEFORGE_DIR || 'C:\\Users\\nesth\\Documents\\EL_ABISMO\\RUNEFORGE_OBSIDIAN\\01_RUNEFORGE';
}

function rfV5Stamp() {
  return new Date().toISOString().replace(/[:.]/g, '-');
}

function rfV5Day() {
  return new Date().toISOString().slice(0, 10).replace(/-/g, '');
}

function rfV5SafeSlug(value, fallback) {
  const raw = String(value || fallback || 'rf_v5').trim();
  const slug = raw.replace(/[^a-zA-Z0-9_\-]+/g, '_').replace(/^_+|_+$/g, '').slice(0, 80);
  return slug || fallback || 'rf_v5';
}

function rfV5EnsureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function rfV5WriteTextFile(file, content) {
  rfV5EnsureDir(path.dirname(file));
  fs.writeFileSync(file, content, 'utf8');
  return file;
}

function rfV5WriteJsonFile(file, obj) {
  rfV5EnsureDir(path.dirname(file));
  fs.writeFileSync(file, JSON.stringify(obj, null, 2), 'utf8');
  return file;
}

function rfV5AppendJsonl(file, obj) {
  rfV5EnsureDir(path.dirname(file));
  fs.appendFileSync(file, JSON.stringify(obj) + '\n', 'utf8');
  return file;
}

async function handleActionsV5(req, res) {
  const startedAt = Date.now();
  const body = req.body && typeof req.body === 'object' ? req.body : {};
  const requestId = body.request_id || `rf-actions-v5-${Date.now()}`;
  const intent = String(body.intent || '').trim();
  const source = body.source || 'runeforge_core_actions_v5';
  const payload = body.payload && typeof body.payload === 'object' ? body.payload : {};

  const policyUrl = rfV5GetActionRouterUrl();
  const timeoutMs = getTimeoutMs();
  const root = rfV5Root();
  const traceDir = path.join(root, 'data', 'traces');
  const reportDir = path.join(root, 'data', 'reports');
  const obsidianDir = rfV5ObsidianDir();

  const outbound = {
    request_id: requestId,
    intent,
    source,
    payload,
    meta: {
      route: req.originalUrl,
      bridge: 'RUNEFORGE_CORE_ACTIONS_V5',
      backend_core: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      policy: 'ALLOWLIST_V5_NO_SHELL',
      ts: new Date().toISOString()
    }
  };

  let policy;
  try {
    policy = await fetchJsonWithTimeout(policyUrl, {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify(outbound)
    }, timeoutMs);
  } catch (error) {
    const durationMs = Date.now() - startedAt;
    const traceFile = appendTrace('rf_actions_v5_error', {
      timestamp: new Date().toISOString(),
      event: 'RF_ACTIONS_V5_POLICY_UNREACHABLE',
      request_id: requestId,
      intent,
      source,
      error: error.message,
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO'
    });

    return res.status(503).json({
      ok: false,
      accepted: false,
      blocked: false,
      service: 'Runeforge',
      module: 'RF_ACTIONS_V5',
      status: 'POLICY_ROUTER_V5_UNREACHABLE',
      durationMs,
      policy_router: { url: policyUrl, error: error.message },
      traceFile: traceFile || 'TRACE_WRITE_SKIPPED',
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      ts: new Date().toISOString()
    });
  }

  const policyData = policy.data || {};
  const accepted = policy.httpOk === true && policyData.ok === true && policyData.status === 'RF_ACTION_ROUTER_V5_ACCEPTED';
  const blocked = policy.httpOk === true && policyData.status === 'INTENT_NOT_ALLOWED';

  if (blocked || !accepted) {
    const durationMs = Date.now() - startedAt;
    const traceFile = appendTrace('rf_actions_v5_blocked', {
      timestamp: new Date().toISOString(),
      event: 'RF_ACTIONS_V5_BLOCKED',
      request_id: requestId,
      intent,
      source,
      policy_response: policyData,
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO'
    });

    return res.status(200).json({
      ok: true,
      accepted: false,
      blocked: true,
      service: 'Runeforge',
      module: 'RF_ACTIONS_V5',
      status: blocked ? 'RF_ACTIONS_V5_BLOCKED_BY_POLICY' : 'RF_ACTIONS_V5_POLICY_REJECTED',
      durationMs,
      intent,
      request_id: requestId,
      allowed_intents: policyData.allowed_intents || [],
      policy_router: { url: policyUrl, httpStatus: policy.httpStatus, response: policyData },
      execution_policy: {
        shell: false,
        filesystem_write: 'allowlist_only',
        external_network: false,
        controlled_actions_only: true
      },
      traceFile: traceFile || 'TRACE_WRITE_SKIPPED',
      backend: 'RUNEFORGE_CORE',
      runtime_original: 'NO_TOCADO',
      ts: new Date().toISOString()
    });
  }

  let actionResult = {};
  let status = 'RF_ACTION_V5_EXECUTED';

  try {
    if (intent === 'ping') {
      actionResult = { pong: true, message: 'RF_ACTIONS_V5_OK' };

    } else if (intent === 'echo') {
      actionResult = { echo: payload };

    } else if (intent === 'trace_event') {
      const safeEvent = rfV5SafeSlug(payload.event || payload.name || 'RF_ACTIONS_V5_TRACE_EVENT', 'RF_ACTIONS_V5_TRACE_EVENT');
      const file = path.join(traceDir, `rf_actions_v5_trace_event_${rfV5Day()}.jsonl`);
      rfV5AppendJsonl(file, {
        timestamp: new Date().toISOString(),
        event: safeEvent,
        request_id: requestId,
        source,
        payload,
        backend: 'RUNEFORGE_CORE',
        runtime_original: 'NO_TOCADO',
        module: 'RF_ACTIONS_V5'
      });
      actionResult = { trace_written: true, trace_file: file, event: safeEvent };

    } else if (intent === 'create_trace_note') {
      const title = String(payload.title || payload.name || 'Runeforge V5 Trace Note').slice(0, 160);
      const bodyText = String(payload.body || payload.content || payload.message || '').slice(0, 20000);
      const slug = rfV5SafeSlug(title, 'trace_note');
      const file = path.join(reportDir, `RF_V5_TRACE_NOTE_${rfV5Stamp()}_${slug}.md`);
      const md = [
        `# ${title}`,
        '',
        `Fecha: ${new Date().toISOString()}`,
        `RequestId: ${requestId}`,
        `Source: ${source}`,
        `Intent: ${intent}`,
        '',
        '## Contenido',
        '',
        bodyText || 'SIN_CONTENIDO',
        '',
        '## Seguridad',
        '',
        '- shell=false',
        '- filesystem_write=allowlist_only',
        '- external_network=false',
        '- module=RF_ACTIONS_V5'
      ].join('\n');
      rfV5WriteTextFile(file, md);
      actionResult = { note_created: true, file, title };

    } else if (intent === 'append_memory_event') {
      const safeEvent = rfV5SafeSlug(payload.event || payload.name || 'RF_ACTIONS_V5_MEMORY_EVENT', 'RF_ACTIONS_V5_MEMORY_EVENT');
      const file = path.join(traceDir, `rf_actions_v5_memory_event_${rfV5Day()}.jsonl`);
      rfV5AppendJsonl(file, {
        timestamp: new Date().toISOString(),
        event: safeEvent,
        request_id: requestId,
        source,
        payload,
        backend: 'RUNEFORGE_CORE',
        runtime_original: 'NO_TOCADO',
        module: 'RF_ACTIONS_V5'
      });
      actionResult = { memory_event_appended: true, file, event: safeEvent };

    } else if (intent === 'core_health_snapshot') {
      const healthUrl = 'http://127.0.0.1:3100/health';
      const health = await fetchJsonWithTimeout(healthUrl, { method: 'GET' }, timeoutMs);
      const file = path.join(traceDir, `rf_actions_v5_core_health_snapshot_${rfV5Stamp()}.json`);
      const snapshot = {
        timestamp: new Date().toISOString(),
        event: 'RF_ACTIONS_V5_CORE_HEALTH_SNAPSHOT',
        request_id: requestId,
        source,
        health_url: healthUrl,
        health,
        backend: 'RUNEFORGE_CORE',
        runtime_original: 'NO_TOCADO',
        module: 'RF_ACTIONS_V5'
      };
      rfV5WriteJsonFile(file, snapshot);
      actionResult = { snapshot_written: true, file, health_ok: health.httpOk === true, health_status: health.httpStatus, response: health.data };

    } else if (intent === 'obsidian_note_request') {
      const title = String(payload.title || payload.name || 'Runeforge V5 Obsidian Request').slice(0, 160);
      const bodyText = String(payload.body || payload.content || payload.message || '').slice(0, 20000);
      const slug = rfV5SafeSlug(title, 'obsidian_request');
      const file = path.join(obsidianDir, `RF_V5_${rfV5Stamp()}_${slug}.md`);
      const md = [
        `# ${title}`,
        '',
        `Fecha: ${new Date().toISOString()}`,
        `RequestId: ${requestId}`,
        `Source: ${source}`,
        `Intent: ${intent}`,
        '',
        '## Solicitud',
        '',
        bodyText || 'SIN_CONTENIDO',
        '',
        '## Estado',
        '',
        'Generado por RF_ACTIONS_V5 mediante escritura controlada en directorio allowlist.'
      ].join('\n');
      rfV5WriteTextFile(file, md);
      actionResult = { obsidian_request_created: true, file, title };

    } else {
      status = 'RF_ACTION_V5_UNKNOWN_AFTER_POLICY';
      actionResult = { error: 'Intent accepted by policy router but not implemented in Core V5.', intent };
    }
  } catch (error) {
    status = 'RF_ACTION_V5_EXECUTION_ERROR';
    actionResult = { error: error.message, intent };
  }

  const durationMs = Date.now() - startedAt;
  const ok = status === 'RF_ACTION_V5_EXECUTED';

  const traceFile = appendTrace('rf_actions_v5_execute', {
    timestamp: new Date().toISOString(),
    event: status,
    request_id: requestId,
    intent,
    source,
    duration_ms: durationMs,
    response_ok: ok,
    action_result: actionResult,
    backend: 'RUNEFORGE_CORE',
    runtime_original: 'NO_TOCADO'
  });

  return res.status(ok ? 200 : 500).json({
    ok,
    accepted: true,
    blocked: false,
    service: 'Runeforge',
    module: 'RF_ACTIONS_V5',
    status,
    action: intent,
    request_id: requestId,
    durationMs,
    action_result: actionResult,
    policy_router: { url: policyUrl, httpStatus: policy.httpStatus, response: policyData },
    execution_policy: {
      shell: false,
      filesystem_write: 'allowlist_only',
      external_network: false,
      controlled_actions_only: true,
      allowed_directories: [traceDir, reportDir, obsidianDir]
    },
    traceFile: traceFile || 'TRACE_WRITE_SKIPPED',
    backend: 'RUNEFORGE_CORE',
    runtime_original: 'NO_TOCADO',
    ts: new Date().toISOString()
  });
}

router.post('/actions/v5/execute', handleActionsV5);
router.post('/api/actions/v5/execute', handleActionsV5);
// === RF_ACTIONS_CONTROLADAS_V5_END ===

module.exports = router;