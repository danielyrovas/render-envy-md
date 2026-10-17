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
---@return render.envy.test.Mark
local function dim(col)
  return { row = 0, col = col, end_row = 0, end_col = col + 1, hl_group = "RenderEnvyEmphasisDim" }
end

T["dims italic delimiters"] = function()
  H.render(child, { "*a* _b_" })
  eq(H.marks(child), { dim(0), dim(2), dim(4), dim(6) })
end

T["dims bold delimiters"] = function()
  H.render(child, { "**a**" })
  eq(H.marks(child), { dim(0), dim(1), dim(3), dim(4) })
end

T["stays on the cursor line and in reveal modes"] = function()
  H.render(child, { "*a*" })
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  child.type_keys("i")
  H.flush(child)
  eq(H.marks(child), { dim(0), dim(2) })
end

T["leaves strikethrough and plain text alone"] = function()
  child.lua([[require("render-envy-md").setup({ strikethrough = { enabled = false } })]])
  H.render(child, { "~~a~~ 2*3" })
  eq(H.marks(child), {})
end

T["hides delimiters off the cursor line"] = function()
  child.lua([[require("render-envy-md").setup({ emphasis = { delimiters = "hide" } })]])
  H.render(child, { "**a** b", "" })
  child.api.nvim_win_set_cursor(0, { 2, 0 })
  H.flush(child)
  eq(H.screen(child, 1), { "a   b" })
  eq(table.concat(child.get_screenshot().text[1]):sub(1, 7), "  a   b")
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  H.flush(child)
  eq(H.screen(child, 1), { "**a** b" })
end

T["leaves delimiters alone"] = function()
  child.lua([[require("render-envy-md").setup({ emphasis = { delimiters = false } })]])
  H.render(child, { "*a*" })
  eq(H.marks(child), {})
end

T["can be disabled"] = function()
  child.lua([[require("render-envy-md").setup({ emphasis = { enabled = false } })]])
  H.render(child, { "*a*" })
  eq(H.marks(child), {})
end

return T
