const fs = require('fs');
const path = require('path');

const botforceRoot = path.resolve(process.cwd(), '..', 'data', 'botforce');
const dirs = {
  root: botforceRoot,
  inbox: path.join(botforceRoot, 'inbox'),
  outbox: path.join(botforceRoot, 'outbox'),
  trace: path.join(botforceRoot, 'trace'),
  notes: path.join(botforceRoot, 'notes')
};

function ensureDirs() {
  Object.values(dirs).forEach((dir) => fs.mkdirSync(dir, { recursive: true }));
}

function stamp() {
  return new Date().toISOString().replace(/[:.]/g, '-');
}

function safeSlug(value) {
  return String(value || 'event')
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60) || 'event';
}

function writeJson(kind, payload) {
  ensureDirs();
  const id = `${stamp()}_${safeSlug(kind)}_${Math.random().toString(16).slice(2, 8)}`;
  const file = path.join(dirs.trace, `${id}.json`);
  const record = {
    id,
    ts: new Date().toISOString(),
    kind,
    ...payload
  };
  fs.writeFileSync(file, JSON.stringify(record, null, 2), 'utf8');
  return { id, file, record };
}

function writeMarkdown(kind, title, body) {
  ensureDirs();
  const id = `${stamp()}_${safeSlug(kind)}_${Math.random().toString(16).slice(2, 8)}`;
  const file = path.join(dirs.notes, `${id}.md`);
  fs.writeFileSync(file, body, 'utf8');
  return { id, file };
}

function latestTrace() {
  ensureDirs();
  const files = fs.readdirSync(dirs.trace)
    .filter((name) => name.endsWith('.json'))
    .map((name) => path.join(dirs.trace, name))
    .sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);
  if (!files.length) return null;
  const file = files[0];
  return {
    file,
    data: JSON.parse(fs.readFileSync(file, 'utf8'))
  };
}

module.exports = {
  dirs,
  ensureDirs,
  writeJson,
  writeMarkdown,
  latestTrace
};
