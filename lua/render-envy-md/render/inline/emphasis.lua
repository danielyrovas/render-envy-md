local Base = require("render-envy-md.render.base")

---@class render.envy.render.inline.Emphasis: render.envy.Render
---@field private config render.envy.emphasis.Config
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  self.config = self.context.config.emphasis
  if not self.config.enabled then
    return false
  end
  -- the '~' of strikethrough is also an emphasis delimiter -> skip
  local parent = self.node:get():parent()
  local types = { "emphasis", "strong_emphasis" }
  return parent ~= nil and vim.tbl_contains(types, parent:type())
end

---@protected
function Render:run()
  local node = self.node
  self:delimiter(self.config.delimiters, node.start_row, node.start_col, node.end_col, "RenderEnvyEmphasisDim")
end

return Render
