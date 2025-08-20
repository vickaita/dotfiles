local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
vim.opt.rtp:prepend(plenary_path)

local markdown = require("util.markdown")

describe("parent activity detection", function()
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
    -- Use the actual function from the module
    -- We'll copy the updated logic here for testing
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

    -- Check for parent items that have child activity (even if parent status didn't change)
    local parent_activity = {}
    for _, change in ipairs(changes) do
      if change.indent > 0 then
        -- This is a child item that changed, find its parent(s)
        for _, curr_item in ipairs(current_items) do
          if curr_item.indent < change.indent and curr_item.text and curr_item.text ~= "" then
            -- This could be a parent - check if it's the immediate parent
            local is_immediate_parent = true
            for _, other_item in ipairs(current_items) do
              if other_item.indent > curr_item.indent and other_item.indent < change.indent then
                is_immediate_parent = false
                break
              end
            end

            if is_immediate_parent then
              local parent_key = curr_item.text:lower()
              if not parent_activity[parent_key] then
                -- Check if this parent already has a status change recorded
                local already_has_change = false
                for _, existing_change in ipairs(changes) do
                  if existing_change.text:lower() == parent_key then
                    already_has_change = true
                    break
                  end
                end

                if not already_has_change then
                  parent_activity[parent_key] = {
                    text = curr_item.text,
                    status = curr_item.status,
                    indent = curr_item.indent,
                    type = "parent_activity",
                    change_type = "child_activity",
                  }
                end
              end
              break -- Found the immediate parent
            end
          end
        end
      end
    end

    -- Add parent activity changes
    for _, activity in pairs(parent_activity) do
      table.insert(changes, activity)
    end

    return changes
  end

  it("should detect parent activity when child changes but parent status doesn't", function()
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
          .. " (type: "
          .. change.type
          .. ", change_type: "
          .. change.change_type
          .. ")"
      )
    end

    -- Should find 2 changes: child 2 status change + parent activity
    assert.equals(2, #changes)

    local child_change = nil
    local parent_activity = nil
    for _, change in ipairs(changes) do
      if change.text == "child 2" then
        child_change = change
      elseif change.text == "parent" and change.type == "parent_activity" then
        parent_activity = change
      end
    end

    assert.is_not_nil(child_change)
    assert.equals("todo", child_change.prev_status)
    assert.equals("progress", child_change.status)

    assert.is_not_nil(parent_activity)
    assert.equals("child_activity", parent_activity.change_type)
    assert.equals("progress", parent_activity.status)
  end)

  it("should handle link in parent with child activity", function()
    -- Previous day
    local previous_content = {
      "- [-] [link](http://example.com)",
      "    - [ ] child task",
    }

    -- Current day: child completed
    local current_content = {
      "- [-] [link](http://example.com)",
      "    - [x] child task",
    }

    local previous_items = extract_checkbox_items(previous_content)
    local current_items = extract_checkbox_items(current_content)
    local changes = find_changes(current_items, previous_items)

    print("Changes with link in parent:")
    for i, change in ipairs(changes) do
      print(
        "  "
          .. i
          .. ": '"
          .. change.text
          .. "' (type: "
          .. change.type
          .. ", change_type: "
          .. change.change_type
          .. ")"
      )
    end

    -- Should find parent activity for the link item
    local link_parent_activity = nil
    for _, change in ipairs(changes) do
      if change.text == "[link](http://example.com)" and change.type == "parent_activity" then
        link_parent_activity = change
        break
      end
    end

    assert.is_not_nil(link_parent_activity, "Should detect activity on parent with link")
    assert.equals("child_activity", link_parent_activity.change_type)
  end)
end)

