-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Base = require("render-envy-md.render.base")

---@class render.envy.render.markdown.Dash: render.envy.Render
---@field private config render.envy.dash.Config
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  self.config = self.context.config.dash
  return self.config.enabled
end

---@protected
function Render:run()
  local highlight = self.node.type == "thematic_break" and "RenderEnvyDash" or "RenderEnvyDashMetadata"
  local start_row, end_row = self.node.start_row, self.node.end_row - 1
  self:dash(start_row, highlight)
  if end_row > start_row then
    self:dash(end_row, highlight)
  end
end

---@private
---@param row integer
---@param highlight string
function Render:dash(row, highlight)
  -- overlay past the end of the line does not move any text, it is hidden on
  -- the cursor line to show the raw text
  self.marks:add(true, row, 0, {
    virt_text = { { self.config.icon:rep(vim.o.columns), highlight } },
    virt_text_pos = "overlay",
  })
end

return Render
