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
  return { row = row or 0, col = col, end_row = row or 0, end_col = end_col, hl_group = "RenderEnvyInlineHighlightDim" }
end

---@param col integer
---@param end_col integer
---@param row? integer
---@return render.envy.test.Mark
local function highlight(col, end_col, row)
  return { row = row or 0, col = col, end_row = row or 0, end_col = end_col, hl_group = "RenderEnvyInlineHighlight" }
end

---@param row integer
---@param col integer
---@param text string
---@return render.envy.test.Mark
local function overlay(row, col, text)
  return { row = row, col = col, virt_text = { { text, "RenderEnvyInlineHighlightDim" } }, virt_text_pos = "overlay" }
end

---renders the lines below an empty first line that holds the cursor
---@param lines string[]
local function render_off_cursor(lines)
  H.render(child, vim.list_extend({ "" }, lines))
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  H.flush(child)
end

T["dims equals and highlights text"] = function()
  H.render(child, { "a ==bc== d ==e==" })
  eq(H.marks(child), { dim(2, 4), highlight(4, 6), dim(6, 8), dim(11, 13), highlight(13, 14), dim(14, 16) })
end

T["stays on the cursor line and in reveal modes"] = function()
  H.render(child, { "==a==" })
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  child.type_keys("i")
  H.flush(child)
  eq(H.marks(child), { dim(0, 2), highlight(2, 3), dim(3, 5) })
end

T["leaves code spans and single equals alone"] = function()
  H.render(child, { "`==a==` a=b" })
  eq(H.marks(child), {})
end

T["hides equals off the cursor line"] = function()
  render_off_cursor({ "a ==bc== d" })
  eq(H.marks(child), {
    dim(2, 4, 1),
    overlay(1, 2, "  "),
    highlight(4, 6, 1),
    dim(6, 8, 1),
    overlay(1, 6, "  "),
  })
  eq(H.screen(child, 2), { "", "a   bc   d" })
end

T["only dims equals"] = function()
  child.lua([[require("render-envy-md").setup({ inline_highlight = { delimiters = "dim" } })]])
  render_off_cursor({ "==a==" })
  eq(H.marks(child), { dim(0, 2, 1), highlight(2, 3, 1), dim(3, 5, 1) })
end

T["leaves equals alone"] = function()
  child.lua([[require("render-envy-md").setup({ inline_highlight = { delimiters = false } })]])
  render_off_cursor({ "==a==" })
  eq(H.marks(child), { highlight(2, 3, 1) })
end

T["can be disabled"] = function()
  child.lua([[require("render-envy-md").setup({ inline_highlight = { enabled = false } })]])
  H.render(child, { "==a==" })
  eq(H.marks(child), {})
end

return T
