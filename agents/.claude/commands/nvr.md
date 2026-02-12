# NVR (Neovim Remote)

Control a connected Neovim instance using `nvr` (neovim-remote). Works with `nvim-listen` or NVA sessions.

## Finding the Socket (IMPORTANT)

You MUST determine the socket path before any nvr command. Use this logic:

### 1. Check Environment Variable First
```bash
echo "$NVA_SOCKET"
```

If set, use it:
```bash
nvr --servername "$SOCKET" <command>
```

### 2. Derive from pwd (Fallback)
If `$NVA_SOCKET` is NOT set (common in new panes), derive from current directory:

**macOS:**
```bash
SOCKET="/tmp/nvim-$(echo "$PWD" | md5 -q | head -c 8).sock"
```

**Linux:**
```bash
SOCKET="/tmp/nvim-$(echo "$PWD" | md5sum | cut -d' ' -f1 | head -c 8).sock"
```

### Recommended Pattern
```bash
# Determine socket (env var or derive from pwd)
if [[ -n "$NVA_SOCKET" ]]; then
    SOCKET="$NVA_SOCKET"
else
    SOCKET="/tmp/nvim-$(echo "$PWD" | md5 -q | head -c 8).sock"
fi

# Use $SOCKET for all commands
nvr --servername "$SOCKET" <command>
```

## Opening Files

```bash
# Open a file in the current window
nvr --servername "$SOCKET" --remote file.py

# Open at a specific line
nvr --servername "$SOCKET" --remote +42 file.py

# Open in a split
nvr --servername "$SOCKET" -o file.py        # horizontal
nvr --servername "$SOCKET" -O file.py        # vertical

# Open in a new tab
nvr --servername "$SOCKET" --remote-tab file.py
```

## Running Ex Commands

```bash
nvr --servername "$SOCKET" -c "edit src/main.rs"
nvr --servername "$SOCKET" -c "w"            # save
nvr --servername "$SOCKET" -c "42"           # jump to line
```

## Evaluating Expressions

```bash
# Current file path
nvr --servername "$SOCKET" --remote-expr 'expand("%:p")'

# Current line number
nvr --servername "$SOCKET" --remote-expr 'line(".")'

# Buffer content (all lines)
nvr --servername "$SOCKET" --remote-expr 'getline(1, "$")'

# Line range (10-20)
nvr --servername "$SOCKET" --remote-expr 'getline(10, 20)'

# List buffers
nvr --servername "$SOCKET" --remote-expr 'execute("ls")'
```

## Setting the Location List

Primary way to show files/locations to the user in Neovim:

```bash
nvr --servername "$SOCKET" -c "call setloclist(0, [
  \ {'filename': 'src/main.py', 'lnum': 10, 'text': 'TODO: refactor'},
  \ {'filename': 'src/utils.py', 'lnum': 42, 'text': 'FIXME: edge case'},
  \ {'filename': 'tests/test_main.py', 'lnum': 5, 'text': 'add test coverage'}
  \ ]) | lopen"
```

Use `'r'` flag to replace the list: `setloclist(0, [...], 'r')`.

## Quickfix List

```bash
nvr --servername "$SOCKET" -c "call setqflist([
  \ {'filename': 'src/app.py', 'lnum': 20, 'text': 'error here'}
  \ ]) | copen"
```

## Buffer Management

```bash
nvr --servername "$SOCKET" --remote-expr 'execute("ls")'   # list
nvr --servername "$SOCKET" -c "buffer 3"                    # switch
nvr --servername "$SOCKET" -c "bdelete"                     # close
```

## Visual Selection

```bash
nvr --servername "$SOCKET" --remote-expr 'getline("''<", "''>")'
```

## Workflow Tips

- **Show modified files**: Set a location list with all modified files for review.
- **Jump to errors**: Parse build/test output into quickfix list entries.
- **Preview before edit**: Read buffer content via `--remote-expr` before making changes.
- **Save after changes**: `nvr --servername "$SOCKET" -c "wall"` to save all buffers.

## Guardrails

- **ALWAYS determine the socket first** using the logic above: check `$NVA_SOCKET`, fallback to pwd-based derivation
- Verify socket exists before commands: `[[ -S "$SOCKET" ]] || echo "Socket not found"`
- Prefer `--remote` over `-c "edit ..."` for opening files
- Use location list (`setloclist` + `lopen`) rather than quickfix for task-scoped results
- Escape single quotes in text fields when building location lists programmatically
- If socket not found, remind user to run `nvim-listen` in the current directory
