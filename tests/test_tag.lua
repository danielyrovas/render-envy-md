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
local function tag(col, end_col, row)
  return { row = row or 0, col = col, end_row = row or 0, end_col = end_col, hl_group = "RenderEnvyTag" }
end

T["highlights tags"] = function()
  H.render(child, { "#idea a #b/c-d_e (#f)" })
  eq(H.marks(child), { tag(0, 5), tag(8, 16), tag(18, 20) })
end

T["highlights tags on a later line"] = function()
  H.render(child, { "a", "#b" })
  eq(H.marks(child), { tag(0, 2, 1) })
end

T["leaves other hashes alone"] = function()
  H.render(child, { "a#b /#c ## #1 # d `#e`" })
  eq(H.marks(child), {})
end

T["can be disabled"] = function()
  child.lua([[require("render-envy-md").setup({ tag = { enabled = false } })]])
  H.render(child, { "#idea" })
  eq(H.marks(child), {})
end

return T
