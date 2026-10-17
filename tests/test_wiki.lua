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

local icon = "󱗖 "

---@param row integer
---@param col integer
---@param end_col integer
---@return render.envy.test.Mark
local function dim(row, col, end_col)
  return { row = row, col = col, end_row = row, end_col = end_col, hl_group = "RenderEnvyWikiLinkDim" }
end

---@param row integer
---@param col integer
---@param text string
---@return render.envy.test.Mark
local function overlay(row, col, text)
  return { row = row, col = col, virt_text = { { text, "RenderEnvyWikiLink" } }, virt_text_pos = "overlay" }
end

---@param row integer
---@param col integer
---@return render.envy.test.Mark
local function spaces(row, col)
  return { row = row, col = col, virt_text = { { "  ", "RenderEnvyWikiLinkDim" } }, virt_text_pos = "overlay" }
end

---renders the lines below an empty first line that holds the cursor
---@param lines string[]
local function render_off_cursor(lines)
  H.render(child, vim.list_extend({ "" }, lines))
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  H.flush(child)
end

T["renders plain link"] = function()
  render_off_cursor({ "a [[page]] b" })
  eq(H.marks(child), {
    dim(1, 2, 4),
    overlay(1, 2, icon),
    dim(1, 8, 10),
    spaces(1, 8),
  })
end

T["dims destination of alias"] = function()
  render_off_cursor({ "[[page|alias]]" })
  eq(H.marks(child), {
    dim(1, 0, 2),
    overlay(1, 0, icon),
    dim(1, 2, 7),
    dim(1, 12, 14),
    spaces(1, 12),
  })
end

T["does not change line width off the cursor line"] = function()
  render_off_cursor({ "a [[page]] b", "[[page|alias]] c" })
  eq(H.screen(child, 3), { "", "a " .. icon .. "page   b", icon .. "page|alias   c" })
end

T["shows raw brackets on the cursor line"] = function()
  H.render(child, { "a [[page]] b", "" })
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  H.flush(child)
  -- overlays are hidden, dim marks stay
  eq(H.marks(child), { dim(0, 2, 4), dim(0, 8, 10) })
  eq(H.screen(child, 1), { "a [[page]] b" })
end

for _, keys in ipairs({ "v", "V", "<C-v>", "i" }) do
  T["reveals all lines with dim brackets in mode " .. keys] = function()
    H.render(child, { "a [[page]] b", "[[c]]" })
    child.api.nvim_win_set_cursor(0, { 1, 0 })
    child.type_keys(keys)
    H.flush(child)
    -- overlays are hidden on every line, dim marks stay
    eq(H.marks(child), { dim(0, 2, 4), dim(0, 8, 10), dim(1, 0, 2), dim(1, 3, 5) })
    eq(H.screen(child, 2), { "a [[page]] b", "[[c]]" })
    -- back in normal mode only the cursor line is revealed
    child.type_keys("<Esc>")
    H.flush(child)
    eq(H.marks(child), { dim(0, 2, 4), dim(0, 8, 10), dim(1, 0, 2), overlay(1, 0, icon), dim(1, 3, 5), spaces(1, 3) })
  end
end

T["dim highlight is not italic"] = function()
  -- colors are set up on the first attach
  render_off_cursor({ "[[a]]" })
  -- color schemes clear highlights before they are applied
  child.cmd("highlight clear")
  child.cmd("highlight Comment guifg=#808080 gui=italic")
  child.cmd("doautocmd ColorScheme")
  local hl = child.lua_get([[vim.api.nvim_get_hl(0, { name = "RenderEnvyWikiLinkDim" })]])
  eq({ hl.fg, hl.italic }, { 0x808080, nil })
end

T["renders two links on one line"] = function()
  render_off_cursor({ "[[a]] [[b|c]]" })
  eq(H.marks(child), {
    dim(1, 0, 2),
    overlay(1, 0, icon),
    dim(1, 3, 5),
    spaces(1, 3),
    dim(1, 6, 8),
    overlay(1, 6, icon),
    dim(1, 8, 10),
    dim(1, 11, 13),
    spaces(1, 11),
  })
  eq(H.screen(child, 2)[2], icon .. "a   " .. icon .. "b|c")
end

T["ignores unbalanced brackets"] = function()
  render_off_cursor({ "[[page]", "[page]]", "[[a] b]" })
  eq(H.marks(child), {})
end

T["ignores other links"] = function()
  -- inline links have their own render, see test_link.lua
  child.lua([[require("render-envy-md").setup({ link = { inline = { enabled = false } } })]])
  render_off_cursor({ "[text](url)", "[x]", "[[a]] [a]", "- [x] task" })
  local marks = H.marks(child)
  -- only the link and the bullet are rendered
  eq(#marks, 5)
  eq(marks[2], overlay(3, 0, icon))
  eq(marks[4], spaces(3, 3))
  eq(marks[5].virt_text, { { "●", "RenderEnvyBullet" } })
end

T["can be disabled"] = function()
  child.lua([[require("render-envy-md").setup({ link = { wiki = { enabled = false } } })]])
  render_off_cursor({ "[[page]]" })
  eq(H.marks(child), {})
  child.lua([[require("render-envy-md").setup({ link = { enabled = false } })]])
  H.flush(child)
  eq(H.marks(child), {})
end

T["pads narrow icon"] = function()
  child.lua([[require("render-envy-md").setup({ link = { wiki = { icon = "@" } } })]])
  render_off_cursor({ "[[page]]" })
  eq(H.marks(child)[2], overlay(1, 0, "@ "))
end

T["skips wide icon"] = function()
  child.lua([[require("render-envy-md").setup({ link = { wiki = { icon = "-->" } } })]])
  render_off_cursor({ "[[page]]" })
  eq(H.marks(child), { dim(1, 0, 2), spaces(1, 0), dim(1, 6, 8), spaces(1, 6) })
end

T["only dims the closing brackets"] = function()
  child.lua([[require("render-envy-md").setup({ link = { wiki = { delimiters = "dim" } } })]])
  render_off_cursor({ "[[page]]" })
  eq(H.marks(child), { dim(1, 0, 2), overlay(1, 0, icon), dim(1, 6, 8) })
  eq(H.screen(child, 2)[2], icon .. "page]]")
end

T["leaves the brackets alone"] = function()
  child.lua([[require("render-envy-md").setup({ link = { wiki = { delimiters = false, alias = false } } })]])
  render_off_cursor({ "[[page|alias]]" })
  eq(H.marks(child), {})
end

T["hides the destination of an alias"] = function()
  child.lua([[require("render-envy-md").setup({ link = { wiki = { alias = "hide" } } })]])
  render_off_cursor({ "[[page|alias]]" })
  eq(H.marks(child)[3], dim(1, 2, 7))
  eq(
    H.marks(child)[4],
    { row = 1, col = 2, virt_text = { { "     ", "RenderEnvyWikiLinkDim" } }, virt_text_pos = "overlay" }
  )
  eq(H.screen(child, 2)[2], icon .. "     alias")
end

return T
