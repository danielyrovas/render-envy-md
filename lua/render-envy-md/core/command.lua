-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local name = "RenderEnvy"
local plugin = "render-envy-md"

---@type table<string, fun()>
local commands = {
  enable = function()
    require("render-envy-md.core.manager").set(true)
  end,
  disable = function()
    require("render-envy-md.core.manager").set(false)
  end,
  toggle = function()
    require("render-envy-md.core.manager").set()
  end,
  buf_enable = function()
    require("render-envy-md.core.manager").set_buf(nil, true)
  end,
  buf_disable = function()
    require("render-envy-md.core.manager").set_buf(nil, false)
  end,
  buf_toggle = function()
    require("render-envy-md.core.manager").set_buf(nil)
  end,
}

---@class render.envy.Command
local M = {}

---called from plugin directory
function M.init()
  vim.api.nvim_create_user_command(name, M.command, {
    nargs = "?",
    desc = plugin .. " commands",
    ---@param arg_lead string
    ---@return string[]
    complete = function(arg_lead)
      local result = {} ---@type string[]
      for method in pairs(commands) do
        if vim.startswith(method, arg_lead) then
          result[#result + 1] = method
        end
      end
      table.sort(result)
      return result
    end,
  })
end

---@private
---@param args vim.api.keyset.create_user_command.command_args
function M.command(args)
  local method = args.fargs[1] or "enable"
  local command = commands[method]
  if not command then
    vim.notify(("%s: invalid command - %s"):format(plugin, method), vim.log.levels.ERROR)
    return
  end
  command()
end

return M
