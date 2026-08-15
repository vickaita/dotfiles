local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
vim.opt.rtp:prepend(plenary_path)
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/nvim/.config/nvim")

local module_loaded, git_hunks = pcall(require, "util.git_hunks")
assert.is_true(module_loaded, "util.git_hunks should be available")

local function git(repo, args)
  local command = { "git", "-C", repo }
  vim.list_extend(command, args)

  local result = vim.system(command, { text = true }):wait()
  assert.are.equal(0, result.code, result.stderr)

  return vim.trim(result.stdout or "")
end

local function write_file(path, lines)
  assert.are.equal(0, vim.fn.writefile(lines, path))
end

local function find_mapping(config_root, lhs)
  local specs = dofile(config_root .. "/nvim/.config/nvim/lua/plugins/fzf-lua.lua")
  for _, candidate in ipairs(specs[1].keys) do
    if candidate[1] == lhs then
      return candidate
    end
  end
end

describe("default branch git hunks", function()
  local repo

  before_each(function()
    repo = vim.fn.tempname()
    assert.are.equal(1, vim.fn.mkdir(repo, "p"))

    git(repo, { "init", "--initial-branch=master" })
    git(repo, { "config", "user.name", "Test User" })
    git(repo, { "config", "user.email", "test@example.com" })

    write_file(repo .. "/tracked.txt", { "base" })
    git(repo, { "add", "tracked.txt" })
    git(repo, { "commit", "-m", "base" })
  end)

  after_each(function()
    vim.fn.delete(repo, "rf")
  end)

  it("prefers the valid origin HEAD target", function()
    local head = git(repo, { "rev-parse", "HEAD" })
    git(repo, { "update-ref", "refs/remotes/origin/trunk", head })
    git(repo, { "update-ref", "refs/remotes/origin/main", head })
    git(repo, { "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/trunk" })

    assert.are.equal("origin/trunk", git_hunks.resolve_default_branch({ cwd = repo }))
  end)

  it("falls back to origin main", function()
    local head = git(repo, { "rev-parse", "HEAD" })
    git(repo, { "update-ref", "refs/remotes/origin/main", head })

    assert.are.equal("origin/main", git_hunks.resolve_default_branch({ cwd = repo }))
  end)

  it("falls back to origin master", function()
    local head = git(repo, { "rev-parse", "HEAD" })
    git(repo, { "update-ref", "refs/remotes/origin/master", head })

    assert.are.equal("origin/master", git_hunks.resolve_default_branch({ cwd = repo }))
  end)

  it("falls back to local main", function()
    git(repo, { "branch", "main" })

    assert.are.equal("main", git_hunks.resolve_default_branch({ cwd = repo }))
  end)

  it("falls back to local master", function()
    assert.are.equal("master", git_hunks.resolve_default_branch({ cwd = repo }))
  end)

  it("builds a three-dot HEAD diff for the resolved base", function()
    assert.are.equal("function", type(git_hunks.default_branch_diff))

    local head = git(repo, { "rev-parse", "HEAD" })
    git(repo, { "update-ref", "refs/remotes/origin/main", head })

    local diff = git_hunks.default_branch_diff({ cwd = repo })
    assert.are.same({
      base = "origin/main",
      diff_cmd = "git diff --unified=0 " .. vim.fn.shellescape("origin/main...HEAD"),
      prompt = "Git Hunks (vs origin/main)> ",
    }, diff)
  end)
end)

describe("default branch hunk mapping", function()
  it("registers leader fhm", function()
    local mapping = find_mapping(vim.fn.getcwd(), "<leader>fhm")

    assert.is_not_nil(mapping)
    assert.are.equal("function", type(mapping[2]))
    assert.are.equal("Git hunks (vs default branch)", mapping.desc)
  end)
end)

describe("default branch hunk picker", function()
  local original_cwd
  local original_fzf
  local repo

  before_each(function()
    original_cwd = vim.fn.getcwd()
    original_fzf = package.loaded["fzf-lua"]
    repo = vim.fn.tempname()
    assert.are.equal(1, vim.fn.mkdir(repo, "p"))

    git(repo, { "init", "--initial-branch=main" })
    git(repo, { "config", "user.name", "Test User" })
    git(repo, { "config", "user.email", "test@example.com" })

    write_file(repo .. "/tracked.txt", { "base" })
    git(repo, { "add", "tracked.txt" })
    git(repo, { "commit", "-m", "base" })
    git(repo, { "switch", "-c", "feature" })

    write_file(repo .. "/tracked.txt", { "base", "feature commit" })
    git(repo, { "add", "tracked.txt" })
    git(repo, { "commit", "-m", "feature" })

    git(repo, { "switch", "main" })
    write_file(repo .. "/main-only.txt", { "main only" })
    git(repo, { "add", "main-only.txt" })
    git(repo, { "commit", "-m", "main only" })
    local main_head = git(repo, { "rev-parse", "HEAD" })
    git(repo, { "update-ref", "refs/remotes/origin/main", main_head })
    git(repo, { "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/main" })

    git(repo, { "switch", "feature" })
    write_file(repo .. "/dirty.txt", { "uncommitted" })
    vim.fn.chdir(repo)
  end)

  after_each(function()
    vim.fn.chdir(original_cwd)
    package.loaded["fzf-lua"] = original_fzf
    vim.fn.delete(repo, "rf")
  end)

  it("shows only committed feature hunks with the resolved base", function()
    local captured_entries
    local captured_opts
    package.loaded["fzf-lua"] = {
      fzf_exec = function(entries, opts)
        captured_entries = entries
        captured_opts = opts
      end,
    }

    local mapping = find_mapping(original_cwd, "<leader>fhm")

    mapping[2]()

    assert.are.same({ "tracked.txt:2: base" }, captured_entries)
    assert.are.equal("Git Hunks (vs origin/main)> ", captured_opts.prompt)
    assert.matches("git diff %-U10 'origin/main%.%.%.HEAD'", captured_opts.fzf_opts["--preview"])

    captured_opts.actions.default(captured_entries)
    assert.are.equal(vim.uv.fs_realpath(repo .. "/tracked.txt"), vim.api.nvim_buf_get_name(0))
    assert.are.same({ 2, 0 }, vim.api.nvim_win_get_cursor(0))
  end)
end)

describe("missing default branch", function()
  local original_cwd
  local original_fzf
  local original_notify
  local repo

  before_each(function()
    original_cwd = vim.fn.getcwd()
    original_fzf = package.loaded["fzf-lua"]
    original_notify = vim.notify
    repo = vim.fn.tempname()
    assert.are.equal(1, vim.fn.mkdir(repo, "p"))
    git(repo, { "init", "--initial-branch=topic" })
    vim.fn.chdir(repo)
  end)

  after_each(function()
    vim.fn.chdir(original_cwd)
    package.loaded["fzf-lua"] = original_fzf
    vim.notify = original_notify
    vim.fn.delete(repo, "rf")
  end)

  it("reports an error without opening fzf", function()
    local fzf_opened = false
    local notification
    package.loaded["fzf-lua"] = {
      fzf_exec = function()
        fzf_opened = true
      end,
    }
    vim.notify = function(message, level)
      notification = { message = message, level = level }
    end

    local mapping = find_mapping(original_cwd, "<leader>fhm")

    mapping[2]()

    assert.are.same({
      message = "Unable to find a default Git branch (origin/HEAD, origin/main, origin/master, main, or master)",
      level = vim.log.levels.ERROR,
    }, notification)
    assert.is_false(fzf_opened)
  end)
end)
