local Base = require("render-envy-md.render.base")

---@class render.envy.render.inline.Strikethrough: render.envy.Render
---@field private config render.envy.strikethrough.Config
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  self.config = self.context.config.strikethrough
  if not self.config.enabled then
    return false
  end
  -- '~~a~~' is parsed as '~a~' inside '~(...)~' -> skip the inner node
  local parent = self.node:get():parent()
  if parent and parent:type() == "strikethrough" then
    local _, start_col = parent:start()
    return self.node.start_col ~= start_col + 1
  end
  return true
end

---@protected
function Render:run()
  local node = self.node
  -- '~' or '~~', the same on both ends
  local width = #node.text:match("^~*")
  local delimiters = self.config.delimiters
  local highlight = "RenderEnvyStrikethroughDim"
  self:delimiter(delimiters, node.start_row, node.start_col, node.start_col + width, highlight)
  self:delimiter(delimiters, node.end_row, node.end_col - width, node.end_col, highlight)
  self.marks:over(false, node, {
    hl_group = "RenderEnvyStrikethrough",
  }, { 0, width, 0, -width })
end

return Render
