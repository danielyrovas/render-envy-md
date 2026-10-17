local H = dofile("tests/helpers.lua")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      H.restart(child)
    end,
    post_once = child.stop,
  },
})

---renders lines below an empty first line, so the cursor is not on them
---@param lines string[]
local function render(lines)
  H.render(child, vim.list_extend({ "" }, lines))
end

---@param row integer
---@param col integer
---@param end_col integer
---@return render.envy.test.Mark
local function dim(row, col, end_col)
  return { row = row, col = col, end_row = row, end_col = end_col, hl_group = "RenderEnvyCodeDim" }
end

---@param n integer
---@return string
local function rule(n)
  return ("─"):rep(n)
end

---@param row integer
---@param col integer
---@return render.envy.test.Mark
local function border(row, col)
  return {
    row = row,
    col = col,
    virt_text = { { rule(40), "RenderEnvy_RenderEnvyCodeFallback_Fade35" } },
    virt_text_pos = "overlay",
  }
end

---@param icon? string
local function icon(icon)
  child.lua(
    [[
    local icon = ...
    require("render-envy-md.lib.icons").get = function() return icon, "Special" end
  ]],
    { icon }
  )
end

T["overlays language and dims delimiters"] = function()
  child.lua([[require("render-envy-md").setup({ code = { line_numbers = false } })]])
  -- no icon provider in the test child -> only the language name
  render({ "```lua", "print(1)", "```" })
  eq(H.marks(child), {
    dim(1, 0, 3),
    {
      row = 1,
      col = 0,
      virt_text = {
        { " ", "RenderEnvyCodeInfo" },
        { "", "RenderEnvyCodeFallback" },
        { "  ", "RenderEnvyCodeInfo" },
        { "lua", "RenderEnvyCodeFallback" },
        { "", "RenderEnvyCodeInfo" },
        { " ", "RenderEnvyCodeInfo" },
        { rule(40), "RenderEnvy_RenderEnvyCodeFallback_Fade35" },
      },
      virt_text_pos = "overlay",
    },
    { row = 1, col = 3, end_row = 1, end_col = 6, hl_group = "RenderEnvyCodeFallback" },
    dim(3, 0, 3),
    border(3, 0),
  })
end

T["uses the icon provider"] = function()
  icon("L")
  render({ "```lua", "x", "```" })
  local overlay = vim.tbl_filter(function(mark)
    return mark.row == 1 and mark.virt_text ~= nil
  end, H.marks(child))[1]
  eq(overlay.virt_text, {
    { " ", "RenderEnvyCodeInfo" },
    { "L", "Special" },
    { " ", "RenderEnvyCodeInfo" },
    { "lua", "Special" },
    { "", "RenderEnvyCodeInfo" },
    { " ", "RenderEnvyCodeInfo" },
    { rule(40), "RenderEnvy_Special_Fade35" },
  })
end

T["does not change line width"] = function()
  -- the sign column is not part of the text
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
  icon("L")
  render({ "```lua title=x", "x", "```" })
  eq(H.screen(child, 4), { "", "L lua title=x " .. rule(25), "x", rule(40) })
  -- the language stays in the same column
  eq(child.fn.screenstring(2, 4), "l")
end

T["shows raw text on the cursor line"] = function()
  render({ "```lua", "x", "```" })
  child.api.nvim_win_set_cursor(0, { 2, 0 })
  H.flush(child)
  eq(H.screen(child, 4), { "", "```lua", "x", rule(40) })
end

T["keeps the language colors on the cursor line"] = function()
  icon("L")
  render({ "```lua title=x", "x", "```" })
  local raw = vim.tbl_filter(function(mark)
    return mark.row == 1 and mark.hl_group ~= nil and mark.col > 0
  end, H.marks(child))
  eq(raw, {
    { row = 1, col = 3, end_row = 1, end_col = 6, hl_group = "Special" },
    { row = 1, col = 6, end_row = 1, end_col = 14, hl_group = "RenderEnvyCodeInfo" },
  })
end

T["covers the top delimiter without a language"] = function()
  child.lua([[require("render-envy-md").setup({ code = { line_numbers = false } })]])
  render({ "```", "x", "```" })
  eq(H.marks(child), { dim(1, 0, 3), border(1, 0), dim(3, 0, 3), border(3, 0) })
end

T["can disable the border"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false }, code = { border = false } })]])
  icon("L")
  render({ "```lua", "x", "```" })
  eq(H.screen(child, 4), { "", "L lua", "x", "```" })
end

T["only dims without a language or border"] = function()
  child.lua([[require("render-envy-md").setup({ code = { border = false, line_numbers = false } })]])
  render({ "```", "x", "```" })
  eq(H.marks(child), { dim(1, 0, 3), dim(3, 0, 3) })
end

T["centres the icon in long delimiters"] = function()
  -- the sign column is not part of the text
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
  icon("L")
  render({ "````  lua", "x", "````" })
  eq(H.screen(child, 2), { "", "L   lua " .. rule(30) })
  eq(child.fn.screenstring(2, 3), "L")
end

T["skips icons wider than the delimiter"] = function()
  icon("WIDE")
  render({ "```c", "x", "```" })
  eq(H.screen(child, 2), { "", "c " .. rule(35) })
end

T["works inside list items"] = function()
  child.lua([[require("render-envy-md").setup({ bullet = { enabled = false }, sign = { enabled = false } })]])
  icon("L")
  render({ "- a", "", "  ```lua", "  x", "  ```" })
  eq(H.screen(child, 6), { "", "- a", "", "L lua " .. rule(31), "x", rule(38) })
  eq(child.fn.screenstring(4, 4), "L")
end

---@return render.envy.test.Mark[]
local function signs()
  return vim.tbl_filter(function(mark)
    return mark.sign_text ~= nil
  end, H.marks(child))
end

T["adds the icon to the sign column"] = function()
  icon("L")
  render({ "```lua", "x", "```" })
  eq(signs(), {
    { row = 1, col = 0, sign_text = "L ", sign_hl_group = "RenderEnvy_Special_RenderEnvySign" },
  })
end

T["keeps the sign on the cursor line"] = function()
  icon("L")
  render({ "```lua", "x", "```" })
  child.api.nvim_win_set_cursor(0, { 2, 0 })
  H.flush(child)
  eq(#signs(), 1)
end

T["has no sign without an icon"] = function()
  render({ "```lua", "x", "```" })
  eq(signs(), {})
end

T["can disable the sign"] = function()
  child.lua([[require("render-envy-md").setup({ code = { sign = false } })]])
  icon("L")
  render({ "```lua", "x", "```" })
  eq(signs(), {})
end

T["can disable all signs"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
  icon("L")
  render({ "```lua", "x", "```" })
  eq(signs(), {})
end

---@return string[]
local function numbers()
  local result = {} ---@type string[]
  for _, mark in ipairs(H.marks(child)) do
    if mark.number_hl_group then
      result[#result + 1] = mark.row .. ":" .. mark.number_hl_group
    end
  end
  return result
end

T["colors the line numbers of all rows"] = function()
  icon("L")
  render({ "```lua", "x", "y", "```", "z" })
  local hl = "RenderEnvy_Special_Fade35_LineNr"
  eq(numbers(), { "1:" .. hl, "2:" .. hl, "3:" .. hl, "4:" .. hl })
end

T["keeps the cursor line number"] = function()
  icon("L")
  render({ "```lua", "x", "```" })
  child.api.nvim_win_set_cursor(0, { 3, 0 })
  H.flush(child)
  local hl = "RenderEnvy_Special_Fade35_LineNr"
  eq(numbers(), { "1:" .. hl, "3:" .. hl })
end

T["keeps the other line numbers in insert mode"] = function()
  icon("L")
  render({ "```lua", "x", "```" })
  child.api.nvim_win_set_cursor(0, { 3, 0 })
  child.type_keys("i")
  H.flush(child)
  eq(child.fn.mode(), "i")
  local hl = "RenderEnvy_Special_Fade35_LineNr"
  eq(numbers(), { "1:" .. hl, "3:" .. hl })
end

T["blends the language color toward the background"] = function()
  child.lua([[
    vim.api.nvim_set_hl(0, "Normal", { fg = 0xffffff, bg = 0x000000 })
    vim.api.nvim_set_hl(0, "LineNr", { fg = 0x808080, bg = 0x101010 })
    vim.api.nvim_set_hl(0, "Special", { fg = 0xff8000 })
  ]])
  icon("L")
  render({ "```lua", "x", "```" })
  local hl = child.api.nvim_get_hl(0, { name = "RenderEnvy_Special_Fade35_LineNr" })
  eq({ hl.fg, hl.bg }, { 0xa65300, 0x101010 })
end

T["uses the fallback color without an icon"] = function()
  render({ "```", "x", "```" })
  eq(numbers()[1], "1:RenderEnvy_RenderEnvyCodeFallback_Fade35_LineNr")
end

T["can override the number highlight"] = function()
  child.lua([[require("render-envy-md").setup({ code = { highlight_line_numbers = "Title" } })]])
  render({ "```lua", "x", "```" })
  eq(numbers(), { "1:Title", "2:Title", "3:Title" })
end

---@return integer[]
local function number_rows()
  local result = {} ---@type integer[]
  for _, mark in ipairs(H.marks(child)) do
    if mark.number_hl_group then
      result[#result + 1] = mark.row
    end
  end
  return result
end

---rows from start to stop, both included, without the skipped rows
---@param start integer
---@param stop integer
---@param skip? integer[]
---@return integer[]
local function rows(start, stop, skip)
  local result = {} ---@type integer[]
  for row = start, stop do
    if not vim.tbl_contains(skip or {}, row) then
      result[#result + 1] = row
    end
  end
  return result
end

---@param before integer rows of text above the block
---@param n integer rows of code in the block
---@param after integer rows of text below the block
---@return string[]
local function block(before, n, after)
  local lines = { "" }
  for i = 1, before do
    lines[#lines + 1] = "a" .. i
  end
  lines[#lines + 1] = "```lua"
  for i = 1, n do
    lines[#lines + 1] = "x" .. i
  end
  lines[#lines + 1] = "```"
  for i = 1, after do
    lines[#lines + 1] = "z" .. i
  end
  return lines
end

---renders the lines with the top of the current window on the given row, the
---cursor on that row, the request range is known before the first render,
---split -> one more window above with its top on that row
---@param lines string[]
---@param top integer
---@param split? integer
local function render_at(lines, top, split)
  child.lua(
    [[
    local lines, top, split = ...
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    if split >= 0 then
      vim.cmd("split")
      vim.fn.winrestview({ topline = split + 1, lnum = split + 1 })
      vim.cmd("wincmd p")
    end
    vim.fn.winrestview({ topline = top + 1, lnum = top + 1 })
    vim.bo.filetype = "markdown"
  ]],
    { lines, top, split or -1 }
  )
  H.flush(child)
end

---@param top integer
local function scroll(top)
  child.fn.winrestview({ topline = top + 1, lnum = top + 1 })
  H.flush(child)
end

---@param win? integer
---@return integer
local function height(win)
  return child.api.nvim_win_get_height(win or 0)
end

-- the request range of a window is its height and 10 rows above and below,
-- rows above the first row move below

T["colors only the line numbers in view of a long block"] = function()
  -- block from row 1 to 3002
  render_at(block(0, 3000, 0), 0)
  local h = height()
  eq(number_rows(), rows(1, h + 19, { 0 }))
  -- marks depend on the view, not the length of the block
  eq(#H.marks(child) < 50, true)
end

T["colors the line numbers in view after scrolling a long block"] = function()
  render_at(block(0, 3000, 0), 0)
  scroll(1500)
  local h = height()
  -- the cursor row keeps its own line number
  eq(number_rows(), rows(1490, 1500 + h + 9, { 1500 }))
  scroll(2990)
  eq(number_rows(), rows(2980, 3002, { 2990 }))
end

T["colors the line number of the top delimiter at the start of the view"] = function()
  -- range starts on the top delimiter
  render_at(block(0, 3000, 0), 11)
  local h = height()
  eq(number_rows(), rows(1, 11 + h + 9, { 11 }))
  -- range starts after the top delimiter
  render_at(block(0, 3000, 0), 12)
  eq(number_rows(), rows(2, 12 + h + 9, { 12 }))
end

T["colors the line number of the top delimiter at the end of the view"] = function()
  local h = height()
  -- range ends on the top delimiter
  render_at(block(h + 18, 2, 0), 0)
  eq(number_rows(), { h + 19 })
  -- range ends before the top delimiter
  render_at(block(h + 19, 2, 0), 0)
  eq(number_rows(), {})
end

T["colors the line number of the bottom delimiter at the start of the view"] = function()
  -- block from row 1 to 3002, range starts on the bottom delimiter
  render_at(block(0, 3000, 20), 3012)
  eq(number_rows(), { 3002 })
  -- range starts after the bottom delimiter
  render_at(block(0, 3000, 20), 3013)
  eq(number_rows(), {})
end

T["colors the line number of the bottom delimiter at the end of the view"] = function()
  local h = height()
  -- range ends on the bottom delimiter
  render_at(block(0, h + 17, 5), 0)
  eq(number_rows(), rows(1, h + 19))
  -- range ends before the bottom delimiter
  render_at(block(0, h + 18, 5), 0)
  eq(number_rows(), rows(1, h + 19))
end

T["colors the line numbers in view of every window"] = function()
  -- cursor of the current window on the empty first row
  render_at(block(0, 3000, 0), 0, 2000)
  local h, other = height(), height(child.fn.win_getid(child.fn.winnr("k")))
  eq(number_rows(), vim.list_extend(rows(1, h + 19), rows(1990, 2000 + other + 9)))
  eq(#H.marks(child) < 80, true)
end

T["does not repeat line numbers in windows with overlapping views"] = function()
  render_at(block(0, 3000, 0), 0, 15)
  local h, other = height(), height(child.fn.win_getid(child.fn.winnr("k")))
  -- ranges overlap from row 5
  eq(h + 19 >= 5, true)
  -- sorted rows without repeats
  eq(number_rows(), rows(1, math.max(h + 19, 15 + other + 9)))
end

T["can disable the numbers"] = function()
  child.lua([[require("render-envy-md").setup({ code = { line_numbers = false } })]])
  render({ "```lua", "x", "```" })
  eq(numbers(), {})
end

T["hides fences without an icon or border"] = function()
  child.lua([[require("render-envy-md").setup({
    sign = { enabled = false },
    code = { language_icon = false, border = false, line_numbers = false, delimiters = "hide" },
  })]])
  H.render(child, { "", "```", "a", "```" })
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  H.flush(child)
  eq(H.screen(child, 4), { "", "", "a", "" })
end

T["leaves fences alone"] = function()
  child.lua([[require("render-envy-md").setup({
    sign = { enabled = false },
    code = { language_icon = false, border = false, line_numbers = false, delimiters = false },
  })]])
  H.render(child, { "```", "a", "```" })
  eq(H.marks(child), {})
end

T["can be disabled"] = function()
  child.lua([[require("render-envy-md").setup({ code = { enabled = false } })]])
  render({ "```lua", "x", "```" })
  eq(H.marks(child), {})
end

return T
