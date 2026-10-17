local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "tests/minimal_init.lua" })
    end,
    post_once = child.stop,
  },
})

T["setup()"] = MiniTest.new_set()

T["setup()"]["uses default config"] = function()
  child.lua([[require("render-envy-md").setup()]])
  eq(child.lua_get([[require("render-envy-md").config.greeting]]), "Hello from render-envy-md")
end

T["setup()"]["merges user config"] = function()
  child.lua([[require("render-envy-md").setup({ greeting = "Hi" })]])
  eq(child.lua_get([[require("render-envy-md").config.greeting]]), "Hi")
end

T["registers user command"] = function()
  eq(child.fn.exists(":RenderEnvy"), 2)
end

return T
