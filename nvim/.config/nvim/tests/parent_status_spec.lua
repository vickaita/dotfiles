local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
vim.opt.rtp:prepend(plenary_path)

local markdown = require("util.markdown")

describe("parent status changes", function()
  local function extract_checkbox_items(lines, buffer_id)
    if not lines then
      return {}
    end

    local items = {}
    local config = markdown._config

    for idx, line in ipairs(lines) do
      local status = markdown._detect_status(line)
      if status then
        local indent = #(line:match("^(%s*)") or "")
        local text = line:match("%[.%]%s*(.*)") or ""
        table.insert(items, {
          text = text,
          status = status,
          indent = indent,
          line_num = idx,
          full_line = line,
        })
      end
    end

    return items
  end

  local function find_changes(current_items, previous_items)
    if not current_items then
      return {}
    end

    if not previous_items or #previous_items == 0 then
      -- All current items are new
      local changes = {}
      for _, item in ipairs(current_items) do
        if item.text and item.text ~= "" then
          table.insert(changes, {
            text = item.text,
            status = item.status,
            indent = item.indent,
            type = "new",
            change_type = "added",
          })
        end
      end
      return changes
    end

    local changes = {}
    local prev_items_map = {}

    -- Create a map of previous item texts to their status
    for _, prev_item in ipairs(previous_items) do
      if prev_item.text and prev_item.text ~= "" then
        prev_items_map[prev_item.text:lower()] = prev_item
      end
    end

    -- Check each current item
    for _, curr_item in ipairs(current_items) do
      if curr_item.text and curr_item.text ~= "" then
        local normalized_text = curr_item.text:lower()
        local prev_item = prev_items_map[normalized_text]

        if not prev_item then
          -- This is a new item
          table.insert(changes, {
            text = curr_item.text,
            status = curr_item.status,
            indent = curr_item.indent,
            type = "new",
            change_type = "added",
          })
        elseif prev_item.status ~= curr_item.status then
          -- This item exists but status changed
          table.insert(changes, {
            text = curr_item.text,
            status = curr_item.status,
            prev_status = prev_item.status,
            indent = curr_item.indent,
            type = "status_change",
            change_type = "status_changed",
          })
        end
      end
    end

    return changes
  end

  it("should detect when parent status stays progress but child changes", function()
    -- Previous day: parent in progress, child 1 done, child 2 todo
    local previous_content = {
      "- [-] parent",
      "    - [x] child 1",
      "    - [ ] child 2",
    }

    -- Current day: parent still in progress, child 1 done, child 2 now in progress
    local current_content = {
      "- [-] parent",
      "    - [x] child 1",
      "    - [-] child 2",
    }

    local previous_items = extract_checkbox_items(previous_content)
    local current_items = extract_checkbox_items(current_content)
    local changes = find_changes(current_items, previous_items)

    print("Previous items:")
    for i, item in ipairs(previous_items) do
      print("  " .. i .. ": '" .. item.text .. "' (status: " .. item.status .. ", indent: " .. item.indent .. ")")
    end

    print("Current items:")
    for i, item in ipairs(current_items) do
      print("  " .. i .. ": '" .. item.text .. "' (status: " .. item.status .. ", indent: " .. item.indent .. ")")
    end

    print("Changes found:")
    for i, change in ipairs(changes) do
      print(
        "  "
          .. i
          .. ": '"
          .. change.text
          .. "' "
          .. (change.prev_status or "new")
          .. " -> "
          .. change.status
          .. " (indent: "
          .. change.indent
          .. ")"
      )
    end

    -- Should only find 1 change (child 2: todo -> progress)
    -- Parent status didn't change (progress -> progress), so no change detected
    assert.equals(1, #changes)
    assert.equals("child 2", changes[1].text)
    assert.equals("todo", changes[1].prev_status)
    assert.equals("progress", changes[1].status)

    -- The problem: we want to show progress on the parent even though its status didn't change
    -- because a child changed underneath it
  end)

  it("should detect when parent changes from progress to done", function()
    -- Previous day: parent in progress, some children incomplete
    local previous_content = {
      "- [-] parent",
      "    - [x] child 1",
      "    - [ ] child 2",
    }

    -- Current day: parent done, all children done
    local current_content = {
      "- [x] parent",
      "    - [x] child 1",
      "    - [x] child 2",
    }

    local previous_items = extract_checkbox_items(previous_content)
    local current_items = extract_checkbox_items(current_content)
    local changes = find_changes(current_items, previous_items)

    print("Changes found:")
    for i, change in ipairs(changes) do
      print(
        "  "
          .. i
          .. ": '"
          .. change.text
          .. "' "
          .. (change.prev_status or "new")
          .. " -> "
          .. change.status
          .. " (indent: "
          .. change.indent
          .. ")"
      )
    end

    -- Should find 2 changes: parent (progress -> done) and child 2 (todo -> done)
    assert.equals(2, #changes)

    local parent_change = nil
    local child_change = nil
    for _, change in ipairs(changes) do
      if change.text == "parent" then
        parent_change = change
      elseif change.text == "child 2" then
        child_change = change
      end
    end

    assert.is_not_nil(parent_change)
    assert.equals("progress", parent_change.prev_status)
    assert.equals("done", parent_change.status)

    assert.is_not_nil(child_change)
    assert.equals("todo", child_change.prev_status)
    assert.equals("done", child_change.status)
  end)
end)

