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
  child.lua([[require("plugin_name").setup()]])
  eq(child.lua_get([[require("plugin_name").config.greeting]]), "Hello from plugin_name")
end

T["setup()"]["merges user config"] = function()
  child.lua([[require("plugin_name").setup({ greeting = "Hi" })]])
  eq(child.lua_get([[require("plugin_name").config.greeting]]), "Hi")
end

T["registers user command"] = function()
  eq(child.fn.exists(":PluginName"), 2)
end

return T
