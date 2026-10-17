-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local colors = require("render-envy-md.core.colors")
local str = require("render-envy-md.lib.str")

---@class render.envy.Render
---@field protected context render.envy.request.Context
---@field protected marks render.envy.Marks
---@field protected node render.envy.Node
local Base = {}
Base.__index = Base

---@param context render.envy.request.Context
---@param marks render.envy.Marks
---@param node render.envy.Node
---@return boolean
function Base:execute(context, marks, node)
  local instance = setmetatable({}, self)
  instance.context = context
  instance.marks = marks
  instance.node = node
  if instance:setup() then
    instance:run()
    return true
  else
    return false
  end
end

---@protected
---@return boolean
function Base:setup()
  error("unimplemented", 2)
end

---@protected
function Base:run()
  error("unimplemented", 2)
end

---@protected
---@param enabled boolean
---@param text? string
---@param highlight? string
function Base:sign(enabled, text, highlight)
  local sign = self.context.config.sign
  if not enabled or not text or not sign.enabled then
    return
  end
  local sign_highlight = "RenderEnvySign"
  if highlight then
    sign_highlight = colors.combine(highlight, sign_highlight)
  end
  -- the sign column does not hold buffer text -> always shown
  self.marks:start(false, self.node, {
    sign_text = text,
    sign_hl_group = sign_highlight,
  })
end

-- not in upstream
---@protected
---@param delimiters render.envy.Delimiters
---@param row integer
---@param start_col integer
---@param end_col integer
---@param highlight string
function Base:delimiter(delimiters, row, start_col, end_col, highlight)
  if not delimiters or start_col >= end_col then
    return
  end
  -- always dimmed, off the cursor line a 'hide' overlay covers it
  self.marks:add(false, row, start_col, {
    end_col = end_col,
    hl_group = highlight,
  })
  if delimiters == "hide" then
    -- spaces keep the line width, hidden by anti-conceal on the cursor line
    local text = vim.api.nvim_buf_get_text(self.context.buf, row, start_col, row, end_col, {})[1]
    self.marks:add(true, row, start_col, {
      virt_text = { { str.pad(str.width(text)), highlight } },
      virt_text_pos = "overlay",
    })
  end
end

return Base
