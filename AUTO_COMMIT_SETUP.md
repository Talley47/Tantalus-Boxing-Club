# Cloud Dev + Auto-Commit Pipeline

This repo is wired up so you can work **in the cloud via GitHub Codespaces**
(or locally in Cursor/VS Code) and have every saved change **auto-committed
and pushed to GitHub** without you touching git.

Repo: <https://github.com/Talley47/Tantalus-Boxing-Club>

---

## 1. Open the project in GitHub Codespaces

1. Go to <https://github.com/Talley47/Tantalus-Boxing-Club>.
2. Click the green **`< > Code`** button → **Codespaces** tab → **Create codespace on main**.
3. Wait ~1–2 minutes. The devcontainer will:
   - Boot a Node 20 container
   - Install the GitHub CLI (`gh`)
   - Run `npm install`
   - Auto-configure git (safe.directory, credentials)

Codespaces ships with a `GITHUB_TOKEN` pre-authenticated, so `git push` just
works — no SSH keys or PATs to manage.

### Opening the Codespace from Cursor (optional)

Cursor supports Codespaces through Remote-SSH:

1. In the Codespace, run `gh codespace ssh --config >> ~/.ssh/config` locally
   (requires `gh` CLI and auth on your machine), OR
2. Click **Open in VS Code Desktop** from the GitHub Codespaces UI, which works
   with Cursor too when it's your default.

---

## 2. Start the auto-commit watcher

Inside the Codespace terminal (or any local terminal in this repo):

```bash
npm run watch:commit
```

Output looks like:

```
[auto-commit 2026-01-23 14:02:10] watching repo on branch "main" (remote: origin, push: true)
[auto-commit 2026-01-23 14:02:10] debounce: 5000ms
[auto-commit 2026-01-23 14:02:10] ready — any file change will be auto-committed
```

From now on: **save any file → 5 seconds later it's committed and pushed to
`origin/main`**. The script debounces rapid saves so you get one commit per
editing session, not one per keystroke.

Leave the terminal running while you work. `Ctrl+C` flushes a final commit and
exits cleanly.

### In Codespaces: keep it running in the background

Open a dedicated terminal tab for the watcher and pin it. If you close the
Codespace, it pauses; when you reopen it, just re-run `npm run watch:commit`.

---

## 3. Tuning

All configurable via env vars:

| Variable                  | Default   | What it does                                  |
| ------------------------- | --------- | --------------------------------------------- |
| `AUTO_COMMIT_DEBOUNCE_MS` | `5000`    | Quiet period (ms) before a commit fires.      |
| `AUTO_COMMIT_BRANCH`      | current   | Branch to push to.                            |
| `AUTO_COMMIT_REMOTE`      | `origin`  | Remote name.                                  |
| `AUTO_COMMIT_PUSH`        | `true`    | Set to `false` to commit locally, no push.    |
| `AUTO_COMMIT_PREFIX`      | `chore(auto)` | Commit message prefix.                    |

Examples:

```bash
# Faster commits (2s quiet window):
AUTO_COMMIT_DEBOUNCE_MS=2000 npm run watch:commit

# Commit locally only, push manually later:
AUTO_COMMIT_PUSH=false npm run watch:commit

# Work on a feature branch:
git checkout -b feature/new-thing
AUTO_COMMIT_BRANCH=feature/new-thing npm run watch:commit
```

The defaults for Codespaces are set in `.devcontainer/devcontainer.json`
under `remoteEnv`.

---

## 4. What gets committed

The watcher runs `git add -A`, so your existing `.gitignore` controls what
lands in git (node_modules, build output, `.env.local`, etc. are excluded).

Additional folders the watcher ignores (never triggers a commit):

- `node_modules/`, `build/`, `dist/`, `.next/`, `coverage/`, `.cache/`, `.turbo/`
- Log files (`*.log`)
- Dotfiles (except `.gitignore`, `.gitattributes`, `.env.example`)

---

## 5. Turning it off

Just `Ctrl+C` in the terminal where the watcher is running. No uninstall
needed — it's just an npm script.

If you want to disable it entirely: remove the `"watch:commit"` line from
`package.json`'s `scripts`.

---

## 6. Troubleshooting

**`fatal: not a git repository`** — run `npm run watch:commit` from the repo
root (`tantalus-boxing-club/`), not the parent folder.

**`push failed: Authentication`** — outside Codespaces, make sure
`gh auth login` or an SSH key is configured. Inside Codespaces, auth is
automatic.

**`nothing to commit`** on first save** — expected; the very first save after
boot sometimes only touches an ignored file. Edit a real source file and it
will commit.

**Too many tiny commits** — raise `AUTO_COMMIT_DEBOUNCE_MS` (e.g. `15000` for
one commit every 15s of idle time).
