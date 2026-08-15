local M = {}

local function git_output(args, opts)
  local command = { "git" }
  vim.list_extend(command, args)

  local result = vim.system(command, {
    cwd = opts and opts.cwd or nil,
    text = true,
  }):wait()

  if result.code ~= 0 then
    return nil
  end

  local output = vim.trim(result.stdout or "")
  return output ~= "" and output or nil
end

function M.resolve_default_branch(opts)
  local origin_head = git_output({
    "symbolic-ref",
    "--quiet",
    "--short",
    "refs/remotes/origin/HEAD",
  }, opts)
  local candidates = {
    "origin/main",
    "origin/master",
    "main",
    "master",
  }

  if origin_head then
    table.insert(candidates, 1, origin_head)
  end

  local seen = {}
  for _, candidate in ipairs(candidates) do
    if not seen[candidate] then
      seen[candidate] = true
      local commit = git_output({
        "rev-parse",
        "--verify",
        "--quiet",
        candidate .. "^{commit}",
      }, opts)

      if commit then
        return candidate
      end
    end
  end

  return nil
end

function M.default_branch_diff(opts)
  local base = M.resolve_default_branch(opts)
  if not base then
    return nil
  end

  return {
    base = base,
    diff_cmd = "git diff --unified=0 " .. vim.fn.shellescape(base .. "...HEAD"),
    prompt = string.format("Git Hunks (vs %s)> ", base),
  }
end

return M
