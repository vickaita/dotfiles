---
name: "nvr"
description: "Use when running alongside a Neovim instance connected via NVA_SOCKET to control the editor remotely -- open files, set location lists, jump to lines, view buffers."
---

# NVR (Neovim Remote) Skill

Control a connected Neovim instance using `nvr` (neovim-remote). The socket path is available in the `NVA_SOCKET` environment variable.

All commands below use `nvr --servername "$NVA_SOCKET"` as the base. For brevity, this prefix is shown as `nvr ...` in examples.

## Socket

```bash
# The socket is set by the NVA session
echo "$NVA_SOCKET"
```

Always pass `--servername "$NVA_SOCKET"` to every `nvr` invocation.

## Opening Files

```bash
# Open a file in the current window
nvr --servername "$NVA_SOCKET" --remote file.py

# Open a file at a specific line
nvr --servername "$NVA_SOCKET" --remote +42 file.py

# Open a file in a new split
nvr --servername "$NVA_SOCKET" -o file.py        # horizontal split
nvr --servername "$NVA_SOCKET" -O file.py        # vertical split

# Open a file in a new tab
nvr --servername "$NVA_SOCKET" --remote-tab file.py
```

## Running Ex Commands

```bash
# Run any Ex command
nvr --servername "$NVA_SOCKET" -c "edit src/main.rs"
nvr --servername "$NVA_SOCKET" -c "w"            # save current buffer
nvr --servername "$NVA_SOCKET" -c "42"           # jump to line 42
nvr --servername "$NVA_SOCKET" -c "noh"          # clear search highlighting
```

## Evaluating Expressions

```bash
# Get the current file path
nvr --servername "$NVA_SOCKET" --remote-expr 'expand("%:p")'

# Get current line number
nvr --servername "$NVA_SOCKET" --remote-expr 'line(".")'

# Get current buffer content (all lines)
nvr --servername "$NVA_SOCKET" --remote-expr 'getline(1, "$")'

# Get specific line range (lines 10-20)
nvr --servername "$NVA_SOCKET" --remote-expr 'getline(10, 20)'

# List all buffers
nvr --servername "$NVA_SOCKET" --remote-expr 'execute("ls")'
```

## Setting the Location List

This is the primary way to show the user a set of files/locations in Neovim. Use `setloclist()` to populate the location list, then `lopen` to display it.

```bash
# Set location list with file + line entries, then open it
nvr --servername "$NVA_SOCKET" -c "call setloclist(0, [
  \ {'filename': 'src/main.py', 'lnum': 10, 'text': 'TODO: refactor'},
  \ {'filename': 'src/utils.py', 'lnum': 42, 'text': 'FIXME: edge case'},
  \ {'filename': 'tests/test_main.py', 'lnum': 5, 'text': 'add test coverage'}
  \ ]) | lopen"
```

For programmatic use, build the list in a variable:

```bash
# Build entries from grep/rg output or any source
nvr --servername "$NVA_SOCKET" -c "call setloclist(0, [
  \ {'filename': 'file1.py', 'lnum': 1, 'col': 1, 'text': 'description'},
  \ {'filename': 'file2.py', 'lnum': 15, 'col': 1, 'text': 'description'}
  \ ], 'r') | lopen"
```

The `'r'` flag replaces the current list. Omit it to append.

## Quickfix List

Similar to location list but window-independent:

```bash
nvr --servername "$NVA_SOCKET" -c "call setqflist([
  \ {'filename': 'src/app.py', 'lnum': 20, 'text': 'error here'}
  \ ]) | copen"
```

## Buffer Management

```bash
# List buffers
nvr --servername "$NVA_SOCKET" --remote-expr 'execute("ls")'

# Switch to buffer by number
nvr --servername "$NVA_SOCKET" -c "buffer 3"

# Close current buffer
nvr --servername "$NVA_SOCKET" -c "bdelete"
```

## Getting Visual Selection

```bash
# Get the last visual selection
nvr --servername "$NVA_SOCKET" --remote-expr 'getline("''<", "''>")'
```

## Workflow Tips

- **Show modified files**: After making changes, set a location list with all modified files so the user can review them in Neovim.
- **Jump to errors**: Parse build/test output and populate the quickfix list with error locations.
- **Preview before edit**: Use `--remote-expr 'getline(1, "$")'` to read file content through Neovim before suggesting changes.
- **Save after changes**: Run `nvr --servername "$NVA_SOCKET" -c "wall"` to save all buffers after modifications.

## Guardrails

- Always check that `$NVA_SOCKET` is set before running nvr commands.
- Prefer `--remote` over `-c "edit ..."` for opening files (handles special characters better).
- Use location list (`setloclist` + `lopen`) rather than quickfix when showing results scoped to a specific task.
- When building location lists programmatically, escape single quotes in text fields.
