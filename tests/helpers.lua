---@class render.envy.test.Helpers
local H = {}

---restarts the child with the plugin loaded and a small screen
---@param child MiniTest.child
function H.restart(child)
  child.restart({ "-u", "tests/minimal_init.lua" })
  child.o.lines, child.o.columns = 10, 40
end

---lets scheduled updates run in the child, waits past the debounce window since
---updates requested while the debounce timer is running are dropped
---@param child MiniTest.child
function H.flush(child)
  child.lua([[
    local ms = require("render-envy-md.state").get(0).debounce + 20
    vim.wait(ms, function() return false end)
  ]])
end

---opens a markdown buffer with the given lines in the child and waits for it to render
---@param child MiniTest.child
---@param lines string[]
function H.render(child, lines)
  child.lua(
    [[
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, ...)
    vim.bo.filetype = "markdown"
  ]],
    { lines }
  )
  H.flush(child)
end

---@class render.envy.test.Mark
---@field row integer
---@field col integer
---@field end_row? integer
---@field end_col? integer
---@field virt_text? [string, string][]
---@field virt_text_pos? string
---@field conceal? string
---@field hl_group? string
---@field hl_eol? boolean
---@field sign_text? string
---@field sign_hl_group? string
---@field number_hl_group? string

---returns the plugin's extmarks in the current buffer of the child, sorted by position
---@param child MiniTest.child
---@return render.envy.test.Mark[]
function H.marks(child)
  return child.lua([[
    local ns = require("render-envy-md.core.ui").ns
    local result = {}
    for _, extmark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
      local _, row, col, details = unpack(extmark)
      local virt_text = nil
      if details.virt_text then
        virt_text = {}
        for _, chunk in ipairs(details.virt_text) do
          virt_text[#virt_text + 1] = { chunk[1], chunk[2] }
        end
      end
      result[#result + 1] = {
        row = row,
        col = col,
        end_row = details.end_row,
        end_col = details.end_col,
        virt_text = virt_text,
        virt_text_pos = details.virt_text_pos,
        conceal = details.conceal,
        hl_group = details.hl_group,
        hl_eol = details.hl_eol or nil,
        sign_text = details.sign_text,
        sign_hl_group = details.sign_hl_group,
        number_hl_group = details.number_hl_group,
      }
    end
    return result
  ]])
end

---returns the text of the first n screen lines of the child
---@param child MiniTest.child
---@param n integer
---@return string[]
function H.screen(child, n)
  local text = child.get_screenshot().text
  local result = {} ---@type string[]
  for i = 1, n do
    result[i] = vim.trim(table.concat(text[i]))
  end
  return result
end

return H
