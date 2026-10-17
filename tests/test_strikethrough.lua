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

---@param col integer
---@param end_col integer
---@param row? integer
---@return render.envy.test.Mark
local function dim(col, end_col, row)
  return { row = row or 0, col = col, end_row = row or 0, end_col = end_col, hl_group = "RenderEnvyStrikethroughDim" }
end

---@param col integer
---@param end_col integer
---@param row? integer
---@return render.envy.test.Mark
local function strike(col, end_col, row)
  return { row = row or 0, col = col, end_row = row or 0, end_col = end_col, hl_group = "RenderEnvyStrikethrough" }
end

---@param row integer
---@param col integer
---@param text string
---@return render.envy.test.Mark
local function overlay(row, col, text)
  return { row = row, col = col, virt_text = { { text, "RenderEnvyStrikethroughDim" } }, virt_text_pos = "overlay" }
end

---renders the lines below an empty first line that holds the cursor
---@param lines string[]
local function render_off_cursor(lines)
  H.render(child, vim.list_extend({ "" }, lines))
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  H.flush(child)
end

T["dims tildes and strikes text"] = function()
  H.render(child, { "a ~~bc~~ d" })
  eq(H.marks(child), { dim(2, 4), strike(4, 6), dim(6, 8) })
end

T["handles single tildes"] = function()
  H.render(child, { "~a~" })
  eq(H.marks(child), { dim(0, 1), strike(1, 2), dim(2, 3) })
end

T["stays on the cursor line and in reveal modes"] = function()
  H.render(child, { "~~a~~" })
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  child.type_keys("i")
  H.flush(child)
  eq(H.marks(child), { dim(0, 2), strike(2, 3), dim(3, 5) })
end

T["dim replaces the treesitter strikethrough on the tildes"] = function()
  H.render(child, { "~~a~~" })
  eq(child.lua_get([[vim.api.nvim_get_hl(0, { name = "RenderEnvyStrikethroughDim" }).nocombine]]), true)
end

T["hides tildes off the cursor line"] = function()
  render_off_cursor({ "a ~~bc~~ d" })
  eq(H.marks(child), {
    dim(2, 4, 1),
    overlay(1, 2, "  "),
    strike(4, 6, 1),
    dim(6, 8, 1),
    overlay(1, 6, "  "),
  })
  eq(H.screen(child, 2), { "", "a   bc   d" })
end

T["only dims tildes"] = function()
  child.lua([[require("render-envy-md").setup({ strikethrough = { delimiters = "dim" } })]])
  render_off_cursor({ "~~a~~" })
  eq(H.marks(child), { dim(0, 2, 1), strike(2, 3, 1), dim(3, 5, 1) })
end

T["leaves tildes alone"] = function()
  child.lua([[require("render-envy-md").setup({ strikethrough = { delimiters = false } })]])
  render_off_cursor({ "~~a~~" })
  eq(H.marks(child), { strike(2, 3, 1) })
end

T["can be disabled"] = function()
  child.lua([[require("render-envy-md").setup({ strikethrough = { enabled = false } })]])
  H.render(child, { "~~a~~" })
  eq(H.marks(child), {})
end

return T
