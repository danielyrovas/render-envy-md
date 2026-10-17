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
---@param level integer
---@return render.envy.test.Mark
local function dim(row, level)
  return { row = row, col = 0, end_row = row, end_col = level - 1, hl_group = "RenderEnvyHeadingDim" }
end

local icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " }

---@param row integer
---@param level integer
---@return render.envy.test.Mark
local function marker(row, level)
  local text = (" "):rep(level - 1) .. icons[level]
  return { row = row, col = 0, virt_text = { { text, "RenderEnvyH" .. level } }, virt_text_pos = "overlay" }
end

---@param row integer
---@param col integer
---@param end_col integer
---@param level integer
---@return render.envy.test.Mark
local function text(row, col, end_col, level)
  return { row = row, col = col, end_row = row, end_col = end_col, hl_group = "RenderEnvyH" .. level .. "Text" }
end

T["renders the marker and dim"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
  H.render(child, { "", "### title" })
  eq(H.marks(child), { dim(1, 3), marker(1, 3), text(1, 4, 9, 3) })
end

T["moves the marker right for each level"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
  H.render(child, { "", "# a", "## b", "### c", "#### d", "##### e", "###### f" })
  eq(H.screen(child, 7), { "", "󰲡 a", "󰲣 b", "󰲥 c", "󰲧 d", "󰲩 e", "󰲫 f" })
  local text = child.get_screenshot().text
  for level = 1, 6 do
    eq(text[level + 1][level], vim.trim(icons[level]))
  end
end

T["does not move the heading text"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
  H.render(child, { "", "### title" })
  local raw = child.lua_get([[vim.fn.screenpos(0, 2, 5).col]])
  eq(child.get_screenshot().text[2][raw], "t")
  eq(vim.trim(table.concat(child.get_screenshot().text[2])), "󰲥 title")
end

T["can use a '#' as the icon"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false }, heading = { icons = { "# " } } })]])
  H.render(child, { "", "### title" })
  eq(H.screen(child, 2), { "", "# title" })
  eq(table.concat(child.get_screenshot().text[2]):sub(1, 9), "  # title")
end

T["hides the marker without an icon"] = function()
  child.lua([[require("render-envy-md").setup({
    sign = { enabled = false },
    heading = { icons = {}, delimiters = "hide" },
  })]])
  H.render(child, { "", "### title" })
  eq(table.concat(child.get_screenshot().text[2]):sub(1, 9), "  # title")
  child.api.nvim_win_set_cursor(0, { 2, 0 })
  H.flush(child)
  eq(H.screen(child, 2), { "", "### title" })
end

T["does not dim the marker"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false }, heading = { delimiters = false } })]])
  H.render(child, { "", "### title" })
  eq(H.marks(child), { marker(1, 3), text(1, 4, 9, 3) })
end

T["shows the raw marker on the cursor line"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
  H.render(child, { "", "### title" })
  child.api.nvim_win_set_cursor(0, { 2, 0 })
  H.flush(child)
  eq(H.screen(child, 2), { "", "### title" })
end

T["does not dim a level 1 marker"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
  H.render(child, { "", "# a" })
  eq(H.marks(child), { marker(1, 1), text(1, 2, 3, 1) })
end

T["highlights the level 1 text"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
  H.render(child, { "", "# title", "## b" })
  local text = vim.tbl_filter(function(mark)
    return mark.hl_group == "RenderEnvyH1Text"
  end, H.marks(child))
  eq(text, { { row = 1, col = 2, end_row = 1, end_col = 7, hl_group = "RenderEnvyH1Text" } })
  local hl = child.lua_get([[vim.api.nvim_get_hl(0, { name = "RenderEnvyH1Text" })]])
  eq({ hl.bold, hl.underline, hl.fg }, { true, true, nil })
end

T["has no text style for other levels"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
  H.render(child, { "", "## ab" })
  eq(H.marks(child), { dim(1, 2), marker(1, 2), text(1, 3, 5, 2) })
  eq(child.lua_get([[vim.api.nvim_get_hl(0, { name = "RenderEnvyH2Text" })]]), { default = true })
end

T["covers past the end of an empty heading"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
  H.render(child, { "", "##" })
  eq(H.screen(child, 2), { "", "󰲣" })
end

T["skips icons wider than the marker"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false }, heading = { icons = { "## " } } })]])
  H.render(child, { "", "# a", "## b" })
  local virt = vim.tbl_filter(function(mark)
    return mark.virt_text ~= nil
  end, H.marks(child))
  eq(virt, { { row = 2, col = 0, virt_text = { { "## ", "RenderEnvyH2" } }, virt_text_pos = "overlay" } })
end

T["only adds the sign and text highlight to setext headings"] = function()
  H.render(child, { "", "a", "===", "", "b", "---" })
  eq(H.marks(child), {
    { row = 1, col = 0, sign_text = "󰫎 ", sign_hl_group = "RenderEnvy_RenderEnvyH1_RenderEnvySign" },
    { row = 1, col = 0, end_row = 1, end_col = 1, hl_group = "RenderEnvyH1Text" },
    { row = 4, col = 0, sign_text = "󰫎 ", sign_hl_group = "RenderEnvy_RenderEnvyH2_RenderEnvySign" },
    text(4, 0, 1, 2),
  })
  eq(H.screen(child, 6), { "", "󰫎 a", "===", "", "󰫎 b", "---" })
end

T["adds the sign"] = function()
  H.render(child, { "", "## a" })
  local signs = vim.tbl_filter(function(mark)
    return mark.sign_text ~= nil
  end, H.marks(child))
  eq(signs, { { row = 1, col = 0, sign_text = "󰫎 ", sign_hl_group = "RenderEnvy_RenderEnvyH2_RenderEnvySign" } })
end

T["can disable the sign"] = function()
  child.lua([[require("render-envy-md").setup({ heading = { sign = false } })]])
  H.render(child, { "", "## a" })
  eq(H.marks(child), { dim(1, 2), marker(1, 2), text(1, 3, 4, 2) })
end

T["can disable the marker"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false }, heading = { icons = {} } })]])
  H.render(child, { "", "## a" })
  eq(H.marks(child), { dim(1, 2), text(1, 3, 4, 2) })
end

T["can be disabled"] = function()
  child.lua([[require("render-envy-md").setup({ heading = { enabled = false } })]])
  H.render(child, { "", "# a" })
  eq(H.marks(child), {})
end

return T
