-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Base = require("render-envy-md.render.base")
local list = require("render-envy-md.lib.list")
local str = require("render-envy-md.lib.str")

---@class render.envy.heading.Data
---@field atx boolean
---@field marker render.envy.Node
---@field level integer
---@field sign? string
---@field fg string
---@field text string

---@class render.envy.render.markdown.Heading: render.envy.Render
---@field private config render.envy.heading.Config
---@field private data render.envy.heading.Data
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  self.config = self.context.config.heading
  if not self.config.enabled then
    return false
  end
  local atx ---@type boolean
  local marker ---@type render.envy.Node
  local level ---@type integer
  if self.node.type == "atx_heading" then
    atx = true
    marker = assert(self.node:child_at(0), "atx heading missing marker")
    level = select(2, marker.text:gsub("#", ""))
  elseif self.node.type == "setext_heading" then
    atx = false
    marker = assert(self.node:child_at(1), "setext heading missing underline")
    level = marker.type == "setext_h1_underline" and 1 or 2
  else
    return false
  end
  self.data = {
    atx = atx,
    marker = marker,
    level = level,
    sign = list.cycle(self.config.signs, level),
    fg = "RenderEnvyH" .. level,
    text = "RenderEnvyH" .. level .. "Text",
  }
  return true
end

---@protected
function Render:run()
  self:sign(self.config.sign, self.data.sign, self.data.fg)
  self:text()
  -- unlike upstream there is no background, setext headings only get the sign
  -- and the text highlight, the underline is not concealed
  if self.data.atx then
    local icon = self:icon()
    self:dim(icon ~= nil)
    self:marker(icon)
  end
end

-- not in upstream
---@private
function Render:text()
  local highlight = self.data.text
  -- only text attributes, nothing is hidden -> always shown
  self.marks:over(false, self.node:descendant("inline"), {
    hl_group = highlight,
  })
end

-- not in upstream
---@private
---@param icon boolean
function Render:dim(icon)
  -- the last '#' keeps the heading color, the '#'s before it are changed, off
  -- the cursor line the icon covers them -> only dimmed
  local delimiters = self.config.delimiters
  if icon and delimiters == "hide" then
    delimiters = "dim"
  end
  local marker = self.data.marker
  self:delimiter(delimiters, marker.start_row, marker.start_col, marker.end_col - 1, "RenderEnvyHeadingDim")
end

---@private
---@return string?
function Render:icon()
  local icon = list.cycle(self.config.icons, self.data.level)
  -- the space after the marker is included, past the end of the line for an
  -- empty heading -> no layout shift
  local width = str.width(self.data.marker.text) + 1
  -- an icon wider than the marker would cover the heading text -> no icon
  if not icon or str.width(icon) > width then
    return nil
  end
  return str.pad(width - str.width(icon)) .. icon
end

---@private
---@param icon? string
function Render:marker(icon)
  if not icon then
    return
  end
  -- unlike upstream the '#'s are not concealed, the icon is overlaid on the
  -- right of the marker, i.e. '### ' -> '  󰲥 ', hidden by anti-conceal to
  -- show the raw marker on the cursor line
  self.marks:start(true, self.data.marker, {
    virt_text = { { icon, self.data.fg } },
    virt_text_pos = "overlay",
  })
end

return Render
