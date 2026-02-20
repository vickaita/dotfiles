---
name: env-toolbox
description: "Reference for CLI tools, custom commands, and language runtimes available in this environment. Use when you need to know what tools are installed, how to invoke custom git commands, or which modern CLI replacements to prefer over legacy defaults."
---

# Environment Toolbox

Quick reference for tools and custom commands available in this dev environment.

## Runtime & Language Management — mise

[mise](https://mise.jdx.dev/) manages language runtimes and tools.

| Runtime | Versions             | Notes          |
| ------- | -------------------- | -------------- |
| Node    | 20.0, 20.9, 22, 24  | `lts` default  |
| Python  | 3.14                 | `latest`       |
| Ruby    | 4.0                  | `latest`       |
| AWS CLI | 2.30                 |                |

```bash
mise list              # show installed runtimes
mise use node@22       # activate a version in current project
mise install python    # install configured version
mise tasks ls          # list project-level tasks
```

## Custom Git Commands

Located in `~/.dotfiles/bin/`. Invoked as git subcommands.

### `git wip` — Quick work-in-progress commits

Auto-stages all changes, skips pre-commit hooks.

```bash
git wip                          # commit with message "wip"
git wip -m "fixing auth bug"     # commit with message "wip: fixing auth bug"
git wip --amend                  # amend the last wip commit with current changes
```

### `git squash` — Squash wip commits

Finds all consecutive `wip` commits from HEAD and squashes them into the first non-wip commit. The original commit message is preserved (editable).

```bash
git squash --dry-run    # preview what would be squashed
git squash              # perform the squash
```

**Safety:** aborts if HEAD isn't a wip commit, if there are uncommitted changes, or if no non-wip commit is found.

### `git cleanup` — Delete merged branches

Deletes local branches already merged into the current branch. Protects `main`, `master`, `develop`, and the current branch by default.

```bash
git cleanup --dry-run                # preview deletions
git cleanup                          # delete merged branches
git cleanup --protect staging        # also protect 'staging'
```

## Git Diff Aliases

| Alias                    | Description                                      |
| ------------------------ | ------------------------------------------------ |
| `git delta`              | Pipe diff through delta                          |
| `git delta-split`        | Side-by-side delta diff                          |
| `git diffbat`            | Full-context diff with bat syntax highlighting   |
| `git dft`                | Structural diff via difftastic (excludes locks)  |
| `git dlog`               | `git log -p` with difftastic                     |
| `git dshow`              | `git show` with difftastic                       |
| `git diff-no-lock`       | Diff excluding lockfiles (package-lock, etc.)    |
| `git delta-no-lock`      | Delta diff excluding lockfiles                   |
| `git diffbat-no-lock`    | Bat diff excluding lockfiles                     |
| `git delta-split-no-lock`| Side-by-side delta excluding lockfiles           |

All `-no-lock` variants exclude: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `composer.lock`, `Pipfile.lock`, `poetry.lock`, `Cargo.lock`, `Gemfile.lock`, `go.sum`.

## Modern CLI Tools

Prefer these over legacy equivalents.

| Tool     | Replaces  | Usage                                        |
| -------- | --------- | -------------------------------------------- |
| `rg`     | `grep`    | `rg "pattern" src/`                          |
| `fd`     | `find`    | `fd "\.ts$" src/`                            |
| `bat`    | `cat`     | `bat file.py` (syntax highlighting + paging) |
| `delta`  | diff pager| Configured as git pager; also piped manually |
| `difft`  | `diff`    | `difft file_a file_b` (structural/AST diff)  |
| `eza`    | `ls`      | `eza -la --git` (git-aware listing)          |
| `zoxide` | `cd`      | `z project-name` (frecency-based jump)       |
| `fzf`    | —         | Fuzzy finder, pipe anything into it          |
| `jq`     | —         | `jq '.key' file.json` (JSON processing)      |

## Other Utilities

### `markdown-server`

A self-contained Python script (runs via `uv`) that serves local markdown files as rendered HTML with syntax-highlighted code blocks.

```bash
markdown-server         # serve on port 8000
markdown-server 3000    # serve on custom port
```
