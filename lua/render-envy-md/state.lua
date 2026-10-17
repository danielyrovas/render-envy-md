-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

---@class render.envy.State: render.envy.state.Config
---@field config render.envy.Config
---@field enabled boolean
local M = {}

---@private
---@type table<integer, render.envy.buf.Config>
M.cache = {}

---called from init on setup
---@param config render.envy.Config
function M.setup(config)
  M.config = config
  M.enabled = config.enabled
  M.file_types = config.file_types
  M.max_file_size = config.max_file_size
  M.injections = config.injections

  -- reset cache
  M.cache = {}

  require("render-envy-md.core.ts").setup()

  -- not in upstream: the ui is loaded on the first attach, before that there are no marks to clear
  local ui = package.loaded["render-envy-md.core.ui"]
  if ui then
    ui.setup()
  end
end

---@param buf integer
---@return render.envy.buf.Config
function M.get(buf)
  if not M.cache[buf] then
    local Config = require("render-envy-md.lib.config")
    M.cache[buf] = Config.new(M.config, M.enabled, buf)
  end
  return assert(M.cache[buf], "missing buffer config")
end

return M
