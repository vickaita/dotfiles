---
name: "nvr"
description: "Control a Neovim instance via neovim-remote (nvr). Socket path is in $NVA_SOCKET or derived from pwd."
---

# NVR (Neovim Remote) Skill

Control a connected Neovim instance using `nvr` (neovim-remote). This works when Neovim is running with `nvim-listen` or in an NVA session.

## Finding the Socket (IMPORTANT)

The Neovim socket path must be determined before any nvr command. Use this logic:

### 1. Check Environment Variable First
```bash
echo "$NVA_SOCKET"
```

If `$NVA_SOCKET` is set, use it directly:
```bash
nvr --servername "$SOCKET" <command>
```

### 2. Derive from Current Directory (Fallback)
If `$NVA_SOCKET` is NOT set (common in new shell panes), derive the socket path from `pwd`:

**On macOS:**
```bash
SOCKET="/tmp/nvim-$(echo "$PWD" | md5 -q | head -c 8).sock"
```

**On Linux:**
```bash
SOCKET="/tmp/nvim-$(echo "$PWD" | md5sum | cut -d' ' -f1 | head -c 8).sock"
```

Then use:
```bash
nvr --servername "$SOCKET" <command>
```

### Recommended Pattern
Always use this pattern to determine the socket:

```bash
# Determine socket (check env var, fallback to pwd-based derivation)
if [[ -n "$NVA_SOCKET" ]]; then
    SOCKET="$NVA_SOCKET"
else
    # macOS
    SOCKET="/tmp/nvim-$(echo "$PWD" | md5 -q | head -c 8).sock"
fi

# Now use $SOCKET for all nvr commands
nvr --servername "$SOCKET" <command>
```

**Note:** The pwd-based derivation only works if you're in the same directory where `nvim-listen` was called (without a name argument). If `nvim-listen myproject` was used with an explicit name, you must use `SOCKET="/tmp/nvim-myproject.sock"`.

## Opening Files

**Remember:** First determine `$SOCKET` using the logic above, then:

```bash
# Open a file in the current window
nvr --servername "$SOCKET" --remote file.py

# Open a file at a specific line
nvr --servername "$SOCKET" --remote +42 file.py

# Open a file in a new split
nvr --servername "$SOCKET" -o file.py        # horizontal split
nvr --servername "$SOCKET" -O file.py        # vertical split

# Open a file in a new tab
nvr --servername "$SOCKET" --remote-tab file.py
```

## Running Ex Commands

```bash
# Run any Ex command
nvr --servername "$SOCKET" -c "edit src/main.rs"
nvr --servername "$SOCKET" -c "w"            # save current buffer
nvr --servername "$SOCKET" -c "42"           # jump to line 42
nvr --servername "$SOCKET" -c "noh"          # clear search highlighting
```

## Evaluating Expressions

```bash
# Get the current file path
nvr --servername "$SOCKET" --remote-expr 'expand("%:p")'

# Get current line number
nvr --servername "$SOCKET" --remote-expr 'line(".")'

# Get current buffer content (all lines)
nvr --servername "$SOCKET" --remote-expr 'getline(1, "$")'

# Get specific line range (lines 10-20)
nvr --servername "$SOCKET" --remote-expr 'getline(10, 20)'

# List all buffers
nvr --servername "$SOCKET" --remote-expr 'execute("ls")'
```

## Setting the Location List

This is the primary way to show the user a set of files/locations in Neovim. Use `setloclist()` to populate the location list, then `lopen` to display it.

```bash
# Set location list with file + line entries, then open it
nvr --servername "$SOCKET" -c "call setloclist(0, [
  \ {'filename': 'src/main.py', 'lnum': 10, 'text': 'TODO: refactor'},
  \ {'filename': 'src/utils.py', 'lnum': 42, 'text': 'FIXME: edge case'},
  \ {'filename': 'tests/test_main.py', 'lnum': 5, 'text': 'add test coverage'}
  \ ]) | lopen"
```

For programmatic use, build the list in a variable:

```bash
# Build entries from grep/rg output or any source
nvr --servername "$SOCKET" -c "call setloclist(0, [
  \ {'filename': 'file1.py', 'lnum': 1, 'col': 1, 'text': 'description'},
  \ {'filename': 'file2.py', 'lnum': 15, 'col': 1, 'text': 'description'}
  \ ], 'r') | lopen"
```

The `'r'` flag replaces the current list. Omit it to append.

## Quickfix List

Similar to location list but window-independent:

```bash
nvr --servername "$SOCKET" -c "call setqflist([
  \ {'filename': 'src/app.py', 'lnum': 20, 'text': 'error here'}
  \ ]) | copen"
```

## Buffer Management

```bash
# List buffers
nvr --servername "$SOCKET" --remote-expr 'execute("ls")'

# Switch to buffer by number
nvr --servername "$SOCKET" -c "buffer 3"

# Close current buffer
nvr --servername "$SOCKET" -c "bdelete"
```

## Getting Visual Selection

```bash
# Get the last visual selection
nvr --servername "$SOCKET" --remote-expr 'getline("''<", "''>")'
```

## Workflow Tips

- **Show modified files**: After making changes, set a location list with all modified files so the user can review them in Neovim.
- **Jump to errors**: Parse build/test output and populate the quickfix list with error locations.
- **Preview before edit**: Use `--remote-expr 'getline(1, "$")'` to read file content through Neovim before suggesting changes.
- **Save after changes**: Run `nvr --servername "$SOCKET" -c "wall"` to save all buffers after modifications.

## Guardrails

- **ALWAYS determine the socket first** using the logic at the top: check `$NVA_SOCKET`, fallback to pwd-based derivation
- Before running any nvr command, verify the socket exists: `[[ -S "$SOCKET" ]] || echo "Socket not found"`
- Prefer `--remote` over `-c "edit ..."` for opening files (handles special characters better)
- Use location list (`setloclist` + `lopen`) rather than quickfix when showing results scoped to a specific task
- When building location lists programmatically, escape single quotes in text fields
- If socket discovery fails, remind the user to run `nvim-listen` in the target directory
