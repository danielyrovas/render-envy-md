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

T["setup()"] = MiniTest.new_set()

T["setup()"]["uses default config"] = function()
  child.lua([[require("render-envy-md").setup()]])
  eq(child.lua_get([[require("render-envy-md.state").file_types]]), { "markdown", "gitcommit" })
  eq(child.lua_get([[require("render-envy-md.state").get(0).bullet.icons]]), { "●", "○", "◆", "◇" })
  eq(
    child.lua_get([[require("render-envy-md.state").get(0).anti_conceal]]),
    { enabled = true, lines_above = 0, lines_below = 0, reveal_modes = { "i", "v", "V", "\22" } }
  )
end

T["setup()"]["merges user config"] = function()
  child.lua([[require("render-envy-md").setup({ debounce = 5, bullet = { icons = { "-" } } })]])
  local config = child.lua_get([[require("render-envy-md.state").get(0)]])
  eq(config.debounce, 5)
  eq(config.bullet.icons, { "-" })
  eq(config.bullet.enabled, true)
  eq(config.render_modes, true)
end

T["setup()"]["applies buftype and filetype overrides"] = function()
  child.lua([[require("render-envy-md").setup({
    overrides = { filetype = { markdown = { bullet = { icons = { "-" } } } } },
  })]])
  H.render(child, { "", "- a" })
  eq(child.lua_get([[require("render-envy-md.state").get(vim.api.nvim_get_current_buf()).sign.enabled]]), true)
  eq(H.marks(child)[1].virt_text, { { "-", "RenderEnvyBullet" } })
  child.lua([[
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = "markdown"
    _G.nofile = require("render-envy-md.state").get(buf)
  ]])
  eq(child.lua_get([[_G.nofile.sign.enabled]]), false)
  eq(child.lua_get([[_G.nofile.bullet.icons]]), { "-" })
end

T["injections"] = MiniTest.new_set()

T["injections"]["renders markdown in a commit message"] = function()
  if not child.lua_get([[vim.treesitter.language.add("gitcommit") == true]]) then
    MiniTest.skip("gitcommit parser not installed")
  end
  child.lua([[require("render-envy-md").setup({})]])
  child.lua([[
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "subject", "", "- a" })
    vim.bo.filetype = "gitcommit"
    vim.treesitter.start()
  ]])
  H.flush(child)
  eq(H.marks(child)[1].virt_text, { { "●", "RenderEnvyBullet" } })
end

T["health"] = MiniTest.new_set()

T["health"]["runs without errors"] = function()
  child.cmd("checkhealth render-envy-md")
  -- checks run asynchronously, the last section is written last
  local lines = child.lua([[
    local function text()
      return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    end
    vim.wait(2000, function() return text():find("[conflicts]", 1, true) ~= nil end)
    return text()
  ]])
  eq(lines:find("render-envy-md [versions]", 1, true) ~= nil, true)
  eq(lines:find("render-envy-md [conflicts]", 1, true) ~= nil, true)
  eq(lines:find("Failed to run healthcheck", 1, true), nil)
end

T["mode"] = MiniTest.new_set()

T["mode"]["matches the mode family"] = function()
  local is = function(mode, modes)
    return child.lua_get("require('render-envy-md.lib.env').mode.is(...)", { mode, modes })
  end
  local reveal = { "i", "v", "V", "\22" }
  for _, mode in ipairs({ "i", "ic", "ix", "niI", "R", "Rv", "s", "S", "\19", "vs", "\22s" }) do
    eq(is(mode, reveal), true)
  end
  for _, mode in ipairs({ "n", "no", "nov", "c", "nt" }) do
    eq(is(mode, reveal), false)
  end
  eq(is("no", { "n" }), true)
  eq(is("ic", { "ic" }), true)
end

T["setup()"]["re-renders attached buffers"] = function()
  H.render(child, { "", "- a" })
  eq(H.marks(child)[1].virt_text, { { "●", "RenderEnvyBullet" } })
  child.lua([[require("render-envy-md").setup({ bullet = { icons = { "*" } } })]])
  H.flush(child)
  eq(H.marks(child)[1].virt_text, { { "*", "RenderEnvyBullet" } })
end

T["command"] = MiniTest.new_set()

T["command"]["is registered"] = function()
  eq(child.fn.exists(":RenderEnvy"), 2)
end

T["command"]["completes subcommands"] = function()
  eq(child.fn.getcompletion("RenderEnvy buf_", "cmdline"), { "buf_disable", "buf_enable", "buf_toggle" })
end

T["command"]["disable clears marks and enable restores them"] = function()
  H.render(child, { "", "- a", "- b" })
  eq(#H.marks(child), 2)
  child.cmd("RenderEnvy disable")
  H.flush(child)
  eq(H.marks(child), {})
  child.cmd("RenderEnvy enable")
  H.flush(child)
  eq(#H.marks(child), 2)
end

T["command"]["toggle and buf_toggle"] = function()
  H.render(child, { "", "- a" })
  child.cmd("RenderEnvy toggle")
  H.flush(child)
  eq(H.marks(child), {})
  child.cmd("RenderEnvy toggle")
  H.flush(child)
  eq(#H.marks(child), 1)
  child.cmd("RenderEnvy buf_toggle")
  H.flush(child)
  eq(H.marks(child), {})
end

T["start-up does not load the ui"] = function()
  eq(child.lua_get([[package.loaded["render-envy-md.core.ui"] ~= nil]]), false)
  eq(child.lua_get([[package.loaded["render-envy-md.core.colors"] ~= nil]]), false)
  eq(child.lua_get([[next(vim.api.nvim_get_hl(0, { name = "RenderEnvyBullet" })) ~= nil]]), false)
end

T["highlight groups are defined"] = function()
  H.render(child, { "- a" })
  eq(child.lua_get([[vim.api.nvim_get_hl(0, { name = "RenderEnvyBullet" }).link]]), "Normal")
  child.cmd("highlight clear")
  child.cmd("doautocmd ColorScheme")
  eq(child.lua_get([[vim.api.nvim_get_hl(0, { name = "RenderEnvyBullet" }).link]]), "Normal")
end

T["does not attach to other file types"] = function()
  child.lua([[
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- a" })
    vim.bo.filetype = "text"
  ]])
  H.flush(child)
  eq(child.lua_get([[require("render-envy-md.core.manager").attached(0)]]), false)
end

return T
