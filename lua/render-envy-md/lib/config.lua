-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local env = require("render-envy-md.lib.env")

---@class render.envy.buf.Config: render.envy.partial.Config
---@field private callouts table<string, render.envy.callout.Config>
local Config = {}
Config.__index = Config

---@param root render.envy.Config
---@param enabled boolean
---@param buf integer
---@return render.envy.buf.Config
function Config.new(root, enabled, buf)
  ---@type render.envy.partial.Config
  local config = {
    enabled = enabled,
    render_modes = root.render_modes,
    debounce = root.debounce,
    anti_conceal = root.anti_conceal,
    sign = root.sign,
    bullet = root.bullet,
    callout = root.callout,
    code = root.code,
    dash = root.dash,
    emphasis = root.emphasis,
    heading = root.heading,
    inline_highlight = root.inline_highlight,
    link = root.link,
    quote = root.quote,
    strikethrough = root.strikethrough,
  }
  config = vim.deepcopy(config)

  ---@param override? render.envy.partial.UserConfig
  local function extend(override)
    config = vim.tbl_deep_extend("force", config, override or {})
  end

  extend(root.overrides.buftype[env.buf.get(buf, "buftype")])
  extend(root.overrides.filetype[env.buf.get(buf, "filetype")])

  local self = setmetatable(config, Config)
  ---@cast self -render.envy.partial.Config
  self.callouts = Config.normalize(self.callout)
  return self
end

---@private
---@param configs table<string, render.envy.callout.Config>
---@return table<string, render.envy.callout.Config>
function Config.normalize(configs)
  local result = {} ---@type table<string, render.envy.callout.Config>
  for _, config in pairs(configs) do
    result[config.raw:lower()] = config
  end
  return result
end

---@param mode string
---@return boolean
function Config:render(mode)
  return env.mode.is(mode, self.render_modes)
end

---@param node render.envy.Node
---@return render.envy.callout.Config?
function Config:callout_for(node)
  return self.callouts[node.text:lower()]
end

return Config
