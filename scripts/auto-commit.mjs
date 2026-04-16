#!/usr/bin/env node
/**
 * Auto-commit-on-save watcher.
 *
 * Watches the repo for any file change and, after a short quiet period,
 * runs:  git add -A  &&  git commit -m "..."  &&  git push
 *
 * Works on Windows, macOS, Linux, and inside GitHub Codespaces.
 *
 * Env vars:
 *   AUTO_COMMIT_DEBOUNCE_MS  (default 5000)  quiet period before committing
 *   AUTO_COMMIT_BRANCH       (default: current branch)
 *   AUTO_COMMIT_REMOTE       (default "origin")
 *   AUTO_COMMIT_PUSH         "false" to skip pushing (commit only)
 *   AUTO_COMMIT_PREFIX       (default "chore(auto)")  commit message prefix
 */

import { spawn } from 'node:child_process';
import chokidar from 'chokidar';
import os from 'node:os';

const DEBOUNCE_MS = Number(process.env.AUTO_COMMIT_DEBOUNCE_MS || 5000);
const REMOTE = process.env.AUTO_COMMIT_REMOTE || 'origin';
const PUSH = process.env.AUTO_COMMIT_PUSH !== 'false';
const PREFIX = process.env.AUTO_COMMIT_PREFIX || 'chore(auto)';

const IGNORED = [
  /(^|[/\\])\.(?!gitignore$|gitattributes$|env\.example$)/, // dotfiles except a few
  '**/node_modules/**',
  '**/build/**',
  '**/dist/**',
  '**/.next/**',
  '**/coverage/**',
  '**/.cache/**',
  '**/.turbo/**',
  '**/*.log',
  '**/.DS_Store',
];

function ts() {
  return new Date().toISOString().replace('T', ' ').split('.')[0];
}

function log(...args) {
  console.log(`[auto-commit ${ts()}]`, ...args);
}

function run(cmd, args) {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    p.stdout.on('data', (d) => (stdout += d.toString()));
    p.stderr.on('data', (d) => (stderr += d.toString()));
    p.on('close', (code) => {
      if (code === 0) resolve({ stdout, stderr });
      else reject(new Error(`${cmd} ${args.join(' ')} (exit ${code}): ${stderr.trim() || stdout.trim()}`));
    });
    p.on('error', reject);
  });
}

async function currentBranch() {
  if (process.env.AUTO_COMMIT_BRANCH) return process.env.AUTO_COMMIT_BRANCH;
  const { stdout } = await run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  return stdout.trim();
}

async function hasChanges() {
  const { stdout } = await run('git', ['status', '--porcelain']);
  return stdout.trim().length > 0;
}

async function changedSummary() {
  const { stdout } = await run('git', ['status', '--porcelain']);
  const lines = stdout.trim().split('\n').filter(Boolean);
  const count = lines.length;
  const sample = lines
    .slice(0, 3)
    .map((l) => l.trim().split(/\s+/).slice(1).join(' '))
    .join(', ');
  return count <= 3 ? sample : `${sample} (+${count - 3} more)`;
}

let timer = null;
let running = false;
let pending = false;

async function commitAndPush() {
  if (running) {
    pending = true;
    return;
  }
  running = true;
  try {
    if (!(await hasChanges())) {
      return;
    }

    const summary = await changedSummary();
    await run('git', ['add', '-A']);

    if (!(await hasChanges())) {
      return;
    }

    const msg = `${PREFIX}: ${summary} [${os.hostname()} ${ts()}]`;
    log(`committing: ${msg}`);
    await run('git', ['commit', '-m', msg]);

    if (PUSH) {
      const branch = await currentBranch();
      log(`pushing -> ${REMOTE}/${branch}`);
      try {
        await run('git', ['push', REMOTE, branch]);
      } catch (err) {
        log('push failed, attempting to set upstream…', err.message);
        await run('git', ['push', '--set-upstream', REMOTE, branch]);
      }
      log('✓ pushed');
    } else {
      log('✓ committed (push disabled)');
    }
  } catch (err) {
    log('ERROR:', err.message);
  } finally {
    running = false;
    if (pending) {
      pending = false;
      schedule();
    }
  }
}

function schedule() {
  if (timer) clearTimeout(timer);
  timer = setTimeout(commitAndPush, DEBOUNCE_MS);
}

async function main() {
  try {
    await run('git', ['rev-parse', '--is-inside-work-tree']);
  } catch {
    console.error('Not inside a git repository. Aborting.');
    process.exit(1);
  }

  const branch = await currentBranch();
  log(`watching repo on branch "${branch}" (remote: ${REMOTE}, push: ${PUSH})`);
  log(`debounce: ${DEBOUNCE_MS}ms`);

  const watcher = chokidar.watch('.', {
    ignored: IGNORED,
    ignoreInitial: true,
    persistent: true,
    awaitWriteFinish: { stabilityThreshold: 400, pollInterval: 100 },
  });

  watcher
    .on('add', (p) => {
      log('+ ' + p);
      schedule();
    })
    .on('change', (p) => {
      log('~ ' + p);
      schedule();
    })
    .on('unlink', (p) => {
      log('- ' + p);
      schedule();
    })
    .on('ready', () => log('ready — any file change will be auto-committed'))
    .on('error', (err) => log('watcher error:', err.message));

  const shutdown = async (signal) => {
    log(`received ${signal}, flushing final commit…`);
    try {
      await watcher.close();
      await commitAndPush();
    } finally {
      process.exit(0);
    }
  };
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
