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
---@param text string
---@return render.envy.test.Mark
local function bullet(row, col, text)
  return {
    row = row,
    col = col,
    end_row = row,
    end_col = col + 1,
    virt_text = { { text, "RenderEnvyBullet" } },
    virt_text_pos = "overlay",
  }
end

T["treesitter markdown parsers load"] = function()
  eq(child.lua_get([[pcall(vim.treesitter.language.add, "markdown")]]), true)
  eq(child.lua_get([[pcall(vim.treesitter.language.add, "markdown_inline")]]), true)
end

T["renders icon per level"] = function()
  H.render(child, {
    "",
    "- one",
    "  * two",
    "    + three",
    "      - four",
    "        - five",
  })
  eq(H.marks(child), {
    bullet(1, 0, "●"),
    bullet(2, 2, "○"),
    bullet(3, 4, "◆"),
    bullet(4, 6, "◇"),
    bullet(5, 8, "●"),
  })
end

T["does not change line width"] = function()
  H.render(child, { "", "- one", "  - two", "1. three" })
  eq(H.screen(child, 4), { "", "● one", "○ two", "1. three" })
end

T["leaves ordered lists alone"] = function()
  H.render(child, { "1. one", "2) two" })
  eq(H.marks(child), {})
end

T["is shown on the cursor line"] = function()
  H.render(child, { "- one", "- two" })
  child.api.nvim_win_set_cursor(0, { 1, 2 })
  H.flush(child)
  eq(#H.marks(child), 2)
end

T["shows the raw marker under the cursor"] = function()
  -- the block cursor on the icon looks cut
  H.render(child, { "- one", "  - two" })
  child.api.nvim_win_set_cursor(0, { 2, 2 })
  H.flush(child)
  eq(H.screen(child, 2), { "● one", "- two" })
end

for _, keys in ipairs({ "v", "i" }) do
  T["is hidden on every line in mode " .. keys] = function()
    H.render(child, { "- one", "- two" })
    child.api.nvim_win_set_cursor(0, { 1, 0 })
    child.type_keys(keys)
    H.flush(child)
    eq(H.marks(child), {})
    eq(H.screen(child, 2), { "- one", "- two" })
  end
end

T["skips icons wider than the marker"] = function()
  child.lua([[require("render-envy-md").setup({ bullet = { icons = { "-->" } } })]])
  H.render(child, { "- one" })
  eq(H.marks(child), {})
end

T["can be disabled"] = function()
  child.lua([[require("render-envy-md").setup({ bullet = { enabled = false } })]])
  H.render(child, { "- one" })
  eq(H.marks(child), {})
end

T["skips nested markdown"] = function()
  child.lua([[require("render-envy-md").setup({ code = { enabled = false } })]])
  H.render(child, { "```markdown", "- one", "```" })
  eq(H.marks(child), {})
end

return T
