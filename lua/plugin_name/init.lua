---@class plugin_name.Config
---@field greeting? string

local M = {}

---@type plugin_name.Config
M.config = {
  greeting = "Hello from plugin_name",
}

---@param opts? plugin_name.Config
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.hello()
  vim.notify(M.config.greeting)
end

return M
