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

T["fills the window width"] = function()
  H.render(child, { "a", "", "---", "", "b" })
  eq(H.marks(child), {
    { row = 2, col = 0, virt_text = { { ("─"):rep(40), "RenderEnvyDash" } }, virt_text_pos = "overlay" },
  })
  eq(H.screen(child, 5), { "a", "", ("─"):rep(40), "", "b" })
end

T["renders all markers"] = function()
  H.render(child, { "", "***", "", "___", "", "- - -" })
  eq(#H.marks(child), 3)
end

T["leaves setext headings alone"] = function()
  child.lua([[require("render-envy-md").setup({ heading = { enabled = false } })]])
  H.render(child, { "", "title", "---" })
  eq(H.marks(child), {})
end

T["shows raw text on the cursor line"] = function()
  H.render(child, { "---", "" })
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  H.flush(child)
  eq(H.screen(child, 1), { "---" })
end

T["renders front matter delimiters"] = function()
  H.render(child, { "---", "a: 1", "---", "", "b" })
  child.api.nvim_win_set_cursor(0, { 5, 0 })
  H.flush(child)
  local line = { { ("─"):rep(40), "RenderEnvyDashMetadata" } }
  eq(H.marks(child), {
    { row = 0, col = 0, virt_text = line, virt_text_pos = "overlay" },
    { row = 2, col = 0, virt_text = line, virt_text_pos = "overlay" },
  })
end

T["can be disabled"] = function()
  child.lua([[require("render-envy-md").setup({ dash = { enabled = false } })]])
  H.render(child, { "", "---" })
  eq(H.marks(child), {})
end

return T
