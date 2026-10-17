-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Base = require("render-envy-md.render.base")

---@class render.envy.render.inline.Highlight: render.envy.Render
---@field private config render.envy.inline.highlight.Config
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  self.config = self.context.config.inline_highlight
  return self.config.enabled
end

---@protected
function Render:run()
  for _, range in ipairs(self.node:find("==[^=]+==")) do
    local top_level = self:top_level(range[1], range[2]) and self:top_level(range[3], range[4])
    if top_level then
      -- not in upstream: equal signs are not concealed
      local delimiters = self.config.delimiters
      local highlight = "RenderEnvyInlineHighlightDim"
      self:delimiter(delimiters, range[1], range[2], range[2] + 2, highlight)
      self:delimiter(delimiters, range[3], range[4] - 2, range[4], highlight)

      -- highlight contents
      self.marks:add(false, range[1], range[2] + 2, {
        end_row = range[3],
        end_col = range[4] - 2,
        hl_group = "RenderEnvyInlineHighlight",
      })
    end
  end
end

---@private
---@param row integer
---@param col integer
---@return boolean
function Render:top_level(row, col)
  local node = vim.treesitter.get_node({
    bufnr = self.context.buf,
    pos = { row, col },
    ignore_injections = false,
  })
  return node and node:type() == "inline" or false
end

return Render
