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

---@param row integer
---@param col integer
---@param end_col integer
---@return render.envy.test.Mark
local function dim(row, col, end_col)
  return { row = row, col = col, end_row = row, end_col = end_col, hl_group = "RenderEnvyLinkDim" }
end

---renders the lines below an empty first line that holds the cursor
---@param lines string[]
local function render_off_cursor(lines)
  H.render(child, vim.list_extend({ "" }, lines))
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  H.flush(child)
end

T["dims syntax of inline link"] = function()
  render_off_cursor({ "a [text](url) b" })
  eq(H.marks(child), { dim(1, 2, 3), dim(1, 7, 8), dim(1, 8, 13) })
end

T["dims title of inline link"] = function()
  render_off_cursor({ '[text](url "title")' })
  eq(H.marks(child), { dim(1, 0, 1), dim(1, 5, 6), dim(1, 6, 19) })
end

T["hides syntax of inline link"] = function()
  child.lua([[require("render-envy-md").setup({ link = { inline = { delimiters = "hide" } } })]])
  render_off_cursor({ "a [text](url) b" })
  eq(table.concat(child.get_screenshot().text[2]):sub(1, 15), "a  text (url) b")
end

T["hides url of inline link"] = function()
  child.lua([[require("render-envy-md").setup({ link = { inline = { url = "hide" } } })]])
  render_off_cursor({ 'a [text](url "t") b' })
  local hide = { row = 1, col = 8, virt_text = { { (" "):rep(9), "RenderEnvyLinkDim" } }, virt_text_pos = "overlay" }
  eq(H.marks(child), { dim(1, 2, 3), dim(1, 7, 8), dim(1, 8, 17), hide })
  child.api.nvim_win_set_cursor(0, { 2, 0 })
  H.flush(child)
  eq(H.marks(child), { dim(1, 2, 3), dim(1, 7, 8), dim(1, 8, 17) })
end

T["leaves url of inline link alone"] = function()
  child.lua([[require("render-envy-md").setup({ link = { inline = { url = false } } })]])
  render_off_cursor({ "a [text](url) b" })
  eq(H.marks(child), { dim(1, 2, 3), dim(1, 7, 8) })
end

T["leaves syntax of inline link alone"] = function()
  child.lua([[require("render-envy-md").setup({ link = { inline = { delimiters = false } } })]])
  render_off_cursor({ "a [text](url) b" })
  eq(H.marks(child), { dim(1, 8, 13) })
end

T["dims brackets of autolink"] = function()
  render_off_cursor({ "a <https://x.io> b" })
  eq(H.marks(child), { dim(1, 2, 3), dim(1, 15, 16) })
end

T["dims empty link text"] = function()
  render_off_cursor({ "[](url)" })
  eq(H.marks(child), { dim(1, 0, 2), dim(1, 2, 7) })
end

T["does not dim link text"] = function()
  render_off_cursor({ "[text](url)" })
  for _, mark in ipairs(H.marks(child)) do
    eq(mark.end_col <= 1 or mark.col >= 5, true)
  end
end

T["is the same on and off the cursor line"] = function()
  local lines = { "a [text](url) b", '[t](u "x") <https://x.io>' }
  render_off_cursor(lines)
  local off = H.marks(child)
  eq(H.screen(child, 3), { "", lines[1], lines[2] })
  child.api.nvim_win_set_cursor(0, { 2, 0 })
  H.flush(child)
  eq(H.marks(child), off)
  child.api.nvim_win_set_cursor(0, { 3, 0 })
  H.flush(child)
  eq(H.marks(child), off)
  eq(H.screen(child, 3), { "", lines[1], lines[2] })
end

T["ignores images and reference links"] = function()
  render_off_cursor({ "![alt](src)", "[text][ref]", "", "[ref]: url" })
  eq(H.marks(child), {})
end

T["can be disabled"] = function()
  child.lua([[require("render-envy-md").setup({ link = { inline = { enabled = false } } })]])
  render_off_cursor({ "[text](url) <https://x.io>" })
  eq(H.marks(child), {})
  child.lua([[require("render-envy-md").setup({ link = { enabled = false } })]])
  H.flush(child)
  eq(H.marks(child), {})
end

T["renders alongside WikiLinks"] = function()
  render_off_cursor({ "[[page]] [text](url)" })
  local marks = H.marks(child)
  eq(#marks, 7)
  eq(marks[1].hl_group, "RenderEnvyWikiLinkDim")
  eq(marks[2].virt_text_pos, "overlay")
  eq(marks[5], dim(1, 9, 10))
  eq(marks[6], dim(1, 14, 15))
  eq(marks[7], dim(1, 15, 20))
end

return T
