# NVR (Neovim Remote)

Control a connected Neovim instance using `nvr` (neovim-remote). The socket path is in the `NVA_SOCKET` environment variable.

All commands use `nvr --servername "$NVA_SOCKET"` as the base.

## Socket

```bash
echo "$NVA_SOCKET"
```

Always pass `--servername "$NVA_SOCKET"` to every `nvr` invocation.

## Opening Files

```bash
# Open a file in the current window
nvr --servername "$NVA_SOCKET" --remote file.py

# Open at a specific line
nvr --servername "$NVA_SOCKET" --remote +42 file.py

# Open in a split
nvr --servername "$NVA_SOCKET" -o file.py        # horizontal
nvr --servername "$NVA_SOCKET" -O file.py        # vertical

# Open in a new tab
nvr --servername "$NVA_SOCKET" --remote-tab file.py
```

## Running Ex Commands

```bash
nvr --servername "$NVA_SOCKET" -c "edit src/main.rs"
nvr --servername "$NVA_SOCKET" -c "w"            # save
nvr --servername "$NVA_SOCKET" -c "42"           # jump to line
```

## Evaluating Expressions

```bash
# Current file path
nvr --servername "$NVA_SOCKET" --remote-expr 'expand("%:p")'

# Current line number
nvr --servername "$NVA_SOCKET" --remote-expr 'line(".")'

# Buffer content (all lines)
nvr --servername "$NVA_SOCKET" --remote-expr 'getline(1, "$")'

# Line range (10-20)
nvr --servername "$NVA_SOCKET" --remote-expr 'getline(10, 20)'

# List buffers
nvr --servername "$NVA_SOCKET" --remote-expr 'execute("ls")'
```

## Setting the Location List

Primary way to show files/locations to the user in Neovim:

```bash
nvr --servername "$NVA_SOCKET" -c "call setloclist(0, [
  \ {'filename': 'src/main.py', 'lnum': 10, 'text': 'TODO: refactor'},
  \ {'filename': 'src/utils.py', 'lnum': 42, 'text': 'FIXME: edge case'},
  \ {'filename': 'tests/test_main.py', 'lnum': 5, 'text': 'add test coverage'}
  \ ]) | lopen"
```

Use `'r'` flag to replace the list: `setloclist(0, [...], 'r')`.

## Quickfix List

```bash
nvr --servername "$NVA_SOCKET" -c "call setqflist([
  \ {'filename': 'src/app.py', 'lnum': 20, 'text': 'error here'}
  \ ]) | copen"
```

## Buffer Management

```bash
nvr --servername "$NVA_SOCKET" --remote-expr 'execute("ls")'   # list
nvr --servername "$NVA_SOCKET" -c "buffer 3"                    # switch
nvr --servername "$NVA_SOCKET" -c "bdelete"                     # close
```

## Visual Selection

```bash
nvr --servername "$NVA_SOCKET" --remote-expr 'getline("''<", "''>")'
```

## Workflow Tips

- **Show modified files**: Set a location list with all modified files for review.
- **Jump to errors**: Parse build/test output into quickfix list entries.
- **Preview before edit**: Read buffer content via `--remote-expr` before making changes.
- **Save after changes**: `nvr --servername "$NVA_SOCKET" -c "wall"` to save all buffers.

## Guardrails

- Always check that `$NVA_SOCKET` is set before running nvr commands.
- Prefer `--remote` over `-c "edit ..."` for opening files.
- Use location list (`setloclist` + `lopen`) rather than quickfix for task-scoped results.
- Escape single quotes in text fields when building location lists programmatically.
