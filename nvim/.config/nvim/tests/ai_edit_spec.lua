vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/plenary.nvim")
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/nvim/.config/nvim")

describe("AI selection edits", function()
  local original, buf, input, request, complete, output, schema, notices

  before_each(function()
    original = { input = vim.ui.input, system = vim.system, notify = vim.notify, executable = vim.fn.executable }
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].buftype = ""
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "before", "  old()", "after" })
    vim.bo[buf].filetype = "lua"
    vim.o.selection = "inclusive"
    input, request, complete, output, schema, notices = nil, nil, nil, nil, nil, {}
    vim.ui.input = function(opts, callback)
      assert.matches("instruction", opts.prompt:lower())
      input = callback
    end
    vim.fn.executable = function() return 1 end
    vim.notify = function(message) table.insert(notices, message) end
    vim.system = function(command, opts, callback)
      request = { command = command, opts = opts }
      for i, arg in ipairs(command) do
        if arg == "--output-last-message" then output = command[i + 1] end
        if arg == "--output-schema" then schema = command[i + 1] end
      end
      complete = callback
      return {}
    end
    package.loaded["util.ai_edit"] = nil
  end)

  after_each(function()
    vim.cmd("normal! " .. string.char(27))
    vim.ui.input, vim.system, vim.notify, vim.fn.executable = original.input, original.system, original.notify, original.executable
    vim.o.selection = "inclusive"
    if output then vim.fn.delete(output) end
    if schema then vim.fn.delete(schema) end
    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
  end)

  local function select_keys(keys, opts)
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    vim.cmd("normal! " .. keys)
    require("util.ai_edit").edit_selection(opts)
  end

  local function finish(replacement, code, raw)
    if output then vim.fn.writefile({ raw or vim.json.encode({ replacement = replacement }) }, output) end
    complete({ code = code or 0, stderr = "model failed" })
    vim.wait(1000, function() return not vim.uv.fs_stat(output) end)
  end

  it("registers leader aC only for visual selections", function()
    dofile("nvim/.config/nvim/lua/config/keymaps.lua")
    local mapping = vim.fn.maparg("<leader>aC", "x", false, true)
    assert.are.equal("function", type(mapping.callback))
    assert.are.equal("", vim.fn.maparg("<leader>aC", "n"))
  end)

  it("prompts, sends unsaved context via stdin, and replaces just the selected lines", function()
    select_keys("V")
    assert.is_nil(request)
    input("add types; $(echo unsafe)")
    assert.are.equal("codex", request.command[1])
    assert.is_true(vim.tbl_contains(request.command, "exec"))
    assert.is_true(vim.tbl_contains(request.command, "read-only"))
    assert.is_true(vim.tbl_contains(request.command, "never"))
    assert.matches("add types; %$%(echo unsafe%)", request.opts.stdin)
    assert.matches("before", request.opts.stdin)
    assert.matches("old%(%)", request.opts.stdin)
    assert.is_table(vim.json.decode(table.concat(vim.fn.readfile(schema), "\n")))
    finish("  new()\n  more()")
    assert.are.same({ "before", "  new()", "  more()", "after" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    assert.is_true(vim.bo[buf].modified)
    assert.is_nil(vim.uv.fs_stat(schema))
    vim.cmd.undo()
    assert.are.same({ "before", "  old()", "after" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("handles reversed linewise selections", function()
    select_keys("Vk")
    input("refactor")
    finish("new")
    assert.are.same({ "new", "after" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("preserves text around a character selection including multibyte characters", function()
    vim.api.nvim_buf_set_lines(buf, 1, 2, false, { "xé🙂z" })
    select_keys("lvl")
    input("replace")
    finish("ok")
    assert.are.same({ "before", "xokz", "after" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("respects exclusive character selections", function()
    vim.o.selection = "exclusive"
    select_keys("2lv3l")
    input("replace")
    finish("new")
    assert.are.same({ "before", "  new()", "after" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("can replace a character selection starting on an empty line", function()
    vim.api.nvim_buf_set_lines(buf, 1, 2, false, { "" })
    select_keys("vj2l")
    input("replace")
    finish("new")
    assert.are.same({ "before", "newer" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("does nothing when the instruction is canceled or blank", function()
    select_keys("V")
    input(nil)
    assert.is_nil(request)
    select_keys("V")
    input("  ")
    assert.is_nil(request)
  end)

  it("refuses to overwrite edits made while the request is running", function()
    select_keys("V")
    input("replace")
    vim.api.nvim_buf_set_lines(buf, 1, 2, false, { "user edit" })
    finish("model edit")
    assert.are.equal("user edit", vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1])
    assert.matches("changed", table.concat(notices, "\n"))
  end)

  it("applies to the original buffer after switching buffers", function()
    select_keys("V")
    input("replace")
    vim.cmd.enew()
    finish("new")
    assert.are.equal("new", vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1])
  end)

  it("leaves the selection intact on CLI errors", function()
    select_keys("V")
    input("replace")
    finish("bad", 1)
    assert.are.equal("  old()", vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1])
    assert.matches("model failed", table.concat(notices, "\n"))
    assert.is_nil(vim.uv.fs_stat(schema))
  end)

  it("rejects malformed model output", function()
    select_keys("V")
    input("replace")
    finish(nil, 0, "not JSON")
    assert.are.equal("  old()", vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1])
    assert.matches("invalid", table.concat(notices, "\n"):lower())
  end)

  it("allows deleting a linewise selection", function()
    select_keys("V")
    input("delete this")
    finish("")
    assert.are.same({ "before", "after" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("reports a missing CLI before opening the dialog", function()
    vim.fn.executable = function() return 0 end
    select_keys("V")
    assert.is_nil(input)
    assert.matches("codex", table.concat(notices, "\n"))
  end)

  it("rejects block selections", function()
    select_keys(string.char(22) .. "j")
    assert.is_nil(input)
    assert.matches("block", table.concat(notices, "\n"):lower())
  end)

  it("cleans up when launching the CLI fails", function()
    local capture = vim.system
    vim.system = function(...)
      capture(...)
      error("cannot spawn")
    end
    select_keys("V")
    input("replace")
    assert.matches("cannot spawn", table.concat(notices, "\n"))
    assert.is_nil(vim.uv.fs_stat(schema))
    assert.is_nil(vim.uv.fs_stat(output))
  end)

  it("discards the edit if the original buffer is deleted", function()
    select_keys("V")
    input("replace")
    vim.api.nvim_buf_delete(buf, { force = true })
    finish("new")
    assert.matches("closed", table.concat(notices, "\n"))
  end)

  it("uses the last response file through a real asynchronous process", function()
    local executable = vim.fn.tempname() .. " fake codex"
    vim.fn.writefile({
      "#!/bin/sh",
      'while [ "$#" -gt 0 ]; do',
      '  if [ "$1" = "--output-last-message" ]; then shift; response="$1"; fi',
      "  shift",
      "done",
      "cat >/dev/null",
      'echo \'{"replacement":"  async()"}\' >"$response"',
      "echo 'progress output should not enter the buffer'",
    }, executable)
    vim.fn.setfperm(executable, "rwx------")
    local capture = vim.system
    vim.system = function(command, opts, callback)
      capture(command, opts, callback)
      command[1] = executable
      return original.system(command, opts, callback)
    end
    select_keys("V")
    input("replace")
    local done = vim.wait(3000, function()
      return vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1] == "  async()"
    end)
    vim.fn.delete(executable)
    assert.is_true(done, table.concat(notices, "\n"))
    assert.is_nil(vim.uv.fs_stat(schema))
    assert.is_nil(vim.uv.fs_stat(output))
  end)

  local function finish_claude(payload, code)
    complete({ code = code or 0, stdout = vim.json.encode(payload), stderr = "" })
    assert.is_true(vim.wait(1000, function() return #notices >= 2 end))
  end

  for key, model in pairs({ aH = "haiku", aS = "sonnet", aO = "opus" }) do
    it("maps leader " .. key .. " to Claude " .. model, function()
      dofile("nvim/.config/nvim/lua/config/keymaps.lua")
      local mapping = vim.fn.maparg("<leader>" .. key, "x", false, true)
      assert.are.equal("function", type(mapping.callback))
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      vim.cmd("normal! V")
      mapping.callback()
      input("refactor; $(echo unsafe)")
      assert.are.equal("claude", request.command[1])
      local function argument(flag)
        for i, arg in ipairs(request.command) do
          if arg == flag then return request.command[i + 1] end
        end
      end
      assert.are.equal(model, argument("--model"))
      assert.are.equal("", argument("--tools"))
      assert.are.equal("json", argument("--output-format"))
      assert.are.equal("string", vim.json.decode(argument("--json-schema")).properties.replacement.type)
      assert.matches("refactor; %$%(echo unsafe%)", request.opts.stdin)
      assert.matches("before", request.opts.stdin)
      assert.is_nil(output)
      finish_claude({ is_error = false, structured_output = { replacement = "  " .. model .. "()" } })
      assert.are.same({ "before", "  " .. model .. "()", "after" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
      assert.matches("Claude", table.concat(notices, "\n"))
      vim.cmd.undo()
      assert.are.same({ "before", "  old()", "after" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    end)
  end

  it("reports a missing Claude CLI", function()
    vim.fn.executable = function(command) return command == "codex" and 1 or 0 end
    select_keys("V", { provider = "claude", model = "haiku" })
    assert.is_nil(input)
    assert.matches("claude CLI", table.concat(notices, "\n"))
  end)

  it("rejects Claude error results even when the process exits successfully", function()
    select_keys("V", { provider = "claude", model = "sonnet" })
    input("refactor")
    finish_claude({ is_error = true, result = "authentication failed", structured_output = { replacement = "bad" } })
    assert.are.equal("  old()", vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1])
    assert.matches("authentication failed", table.concat(notices, "\n"))
  end)

  it("rejects Claude responses missing structured output", function()
    select_keys("V", { provider = "claude", model = "opus" })
    input("refactor")
    finish_claude({ is_error = false, result = "some explanation" })
    assert.are.equal("  old()", vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1])
    assert.matches("invalid", table.concat(notices, "\n"))
  end)

  it("protects edits made while Claude is running", function()
    select_keys("V", { provider = "claude", model = "haiku" })
    input("refactor")
    vim.api.nvim_buf_set_lines(buf, 1, 2, false, { "user edit" })
    finish_claude({ is_error = false, structured_output = { replacement = "bad" } })
    assert.are.equal("user edit", vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1])
    assert.matches("changed", table.concat(notices, "\n"))
  end)
end)
