---@class render.envy.Config
---@field greeting? string

local M = {}

---@type render.envy.Config
M.config = {
  greeting = "Hello from render-envy-md",
}

---@param opts? render.envy.Config
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.hello()
  vim.notify(M.config.greeting)
end

return M
