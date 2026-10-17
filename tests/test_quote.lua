local H = dofile("tests/helpers.lua")
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      H.restart(child)
      child.lua([[require("render-envy-md").setup({ sign = { enabled = false } })]])
    end,
    post_once = child.stop,
  },
})

---@param row integer
---@param col integer
---@param highlight string
---@return render.envy.test.Mark
local function marker(row, col, highlight)
  return {
    row = row,
    col = col,
    end_row = row,
    end_col = col + 1,
    virt_text = { { "▋", highlight } },
    virt_text_pos = "overlay",
  }
end

T["renders the quote markers"] = function()
  H.render(child, { "", "> a", "> b" })
  eq(H.marks(child), { marker(1, 0, "RenderEnvyQuote1"), marker(2, 0, "RenderEnvyQuote1") })
  eq(H.screen(child, 3), { "", "▋ a", "▋ b" })
end

T["colors nested quotes by level"] = function()
  H.render(child, { "", "> a", "> > b" })
  eq(H.marks(child), {
    marker(1, 0, "RenderEnvyQuote1"),
    marker(2, 0, "RenderEnvyQuote1"),
    marker(2, 2, "RenderEnvyQuote2"),
  })
  eq(H.screen(child, 3), { "", "▋ a", "▋ ▋ b" })
end

T["shows the marker on the cursor line"] = function()
  H.render(child, { "", "> a" })
  child.api.nvim_win_set_cursor(0, { 2, 2 })
  H.flush(child)
  eq(H.screen(child, 2), { "", "▋ a" })
end

T["shows the raw marker under the cursor"] = function()
  -- the block cursor on the icon looks cut
  H.render(child, { "", "> a" })
  child.api.nvim_win_set_cursor(0, { 2, 0 })
  H.flush(child)
  eq(H.screen(child, 2), { "", "> a" })
end

for _, keys in ipairs({ "v", "i" }) do
  T["hides the marker on every line in mode " .. keys] = function()
    H.render(child, { "", "> a", "> b" })
    child.api.nvim_win_set_cursor(0, { 2, 0 })
    child.type_keys(keys)
    H.flush(child)
    eq(H.marks(child), {})
    eq(H.screen(child, 3), { "", "> a", "> b" })
  end
end

T["skips icons wider than the marker"] = function()
  child.lua([[require("render-envy-md").setup({ sign = { enabled = false }, quote = { icon = "▋▋" } })]])
  H.render(child, { "", "> a" })
  eq(H.marks(child), {})
end

T["renders the callout title"] = function()
  H.render(child, { "", "> [!NOTE]", "> a" })
  eq(H.marks(child), {
    marker(1, 0, "RenderEnvyInfo"),
    { row = 1, col = 2, end_row = 1, end_col = 9, hl_group = "RenderEnvyInfo" },
    {
      row = 1,
      col = 2,
      end_row = 1,
      end_col = 9,
      virt_text = { { "󰋽 Note ", "RenderEnvyInfo" } },
      virt_text_pos = "overlay",
    },
    marker(2, 0, "RenderEnvyInfo"),
  })
  eq(H.screen(child, 3), { "", "▋ 󰋽 Note", "▋ a" })
end

T["matches callouts without case"] = function()
  H.render(child, { "", "> [!warning]" })
  eq(H.screen(child, 2), { "", "▋ 󰀪 Warning" })
end

T["does not move a custom title"] = function()
  H.render(child, { "", "> [!NOTE] title" })
  eq(H.screen(child, 2), { "", "▋ 󰋽 Note  title" })
end

T["shows the raw callout on the cursor line"] = function()
  H.render(child, { "", "> [!NOTE] title" })
  child.api.nvim_win_set_cursor(0, { 2, 2 })
  H.flush(child)
  eq(H.screen(child, 2), { "", "▋ [!NOTE] title" })
end

T["skips titles wider than the raw value"] = function()
  child.lua(
    [[require("render-envy-md").setup({ sign = { enabled = false }, callout = { note = { rendered = "󰋽 Long note" } } })]]
  )
  H.render(child, { "", "> [!NOTE]" })
  eq(H.screen(child, 2), { "", "▋ [!NOTE]" })
end

T["can add a callout"] = function()
  child.lua([[require("render-envy-md").setup({
    sign = { enabled = false },
    callout = { idea = { raw = "[!IDEA]", rendered = "I idea", highlight = "Special", quote_icon = "|" } },
  })]])
  H.render(child, { "", "> [!IDEA]" })
  eq(H.screen(child, 2), { "", "| I idea" })
end

T["can be disabled"] = function()
  child.lua([[require("render-envy-md").setup({ quote = { enabled = false } })]])
  H.render(child, { "", "> [!NOTE]" })
  eq(H.marks(child), {})
end

return T
