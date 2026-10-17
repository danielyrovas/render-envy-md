-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Base = require("render-envy-md.render.base")
local list = require("render-envy-md.lib.list")
local str = require("render-envy-md.lib.str")
local ts = require("render-envy-md.core.ts")

---@class render.envy.quote.Data
---@field callout? render.envy.request.callout.Value
---@field level integer
---@field icon string
---@field highlight string

---@class render.envy.render.markdown.Quote: render.envy.Render
---@field private config render.envy.quote.Config
---@field private data render.envy.quote.Data
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  self.config = self.context.config.quote
  if not self.config.enabled then
    return false
  end
  local level = self.node:level_in("block_quote")
  local callout = self.context.callout:get(self.node)
  local config = callout and callout.config
  local icon = config and config.quote_icon or self.config.icon
  -- the quote groups are cycled by level
  local highlight = config and config.highlight or "RenderEnvyQuote" .. ((level - 1) % 6 + 1)
  self.data = {
    callout = callout,
    level = level,
    icon = assert(list.cycle(icon, level)),
    highlight = highlight,
  }
  return true
end

---@protected
function Render:run()
  self:callout()
  self:markers()
end

---@private
function Render:callout()
  local callout = self.data.callout
  if not callout then
    return
  end
  local node = callout.node
  local config = callout.config
  -- not in upstream
  -- the raw value keeps the callout color on the cursor line
  self.marks:over(false, node, {
    hl_group = config.highlight,
  })
  -- unlike upstream a custom title is not concealed, the rendered value is
  -- overlaid on the raw value and padded to its width -> no layout shift
  local space = str.width(node.text) - str.width(config.rendered)
  -- a rendered value wider than the raw value would cover the title -> skip
  if space < 0 then
    return
  end
  -- hidden by anti-conceal to show the raw value on the cursor line
  self.marks:over(true, node, {
    virt_text = { { config.rendered .. str.pad(space), config.highlight } },
    virt_text_pos = "overlay",
  })
end

---@private
function Render:markers()
  -- stylua: ignore
  local query = ts.parse("markdown", [[
    (block_quote_marker) @marker
    (block_continuation) @continuation
  ]])
  self.context.view:nodes(self.node:get(), query, function(capture, node)
    if capture == "marker" then
      -- marker nodes are a single '>' at the start of a block quote
      -- overlay the only range if it is at the current level
      if node:level_in("block_quote") == self.data.level then
        self:marker(node, 1)
      end
    elseif capture == "continuation" then
      -- continuation nodes are a group of '>'s inside a block quote
      -- overlay the range of the one at the current level if it exists
      self:marker(node, self.data.level)
    else
      error(("unhandled quote capture: %s"):format(capture))
    end
  end)
end

---@private
---@param node render.envy.Node
---@param index integer
function Render:marker(node, index)
  local range = node:find(">")[index]
  if not range then
    return
  end
  -- an icon wider than '>' would cover the quote text -> skip
  if str.width(self.data.icon) > 1 then
    return
  end
  -- unlike upstream the overlay keeps the line width so there is no layout
  -- shift, nothing needs to be revealed around the cursor -> only hidden in
  -- reveal modes and under the cursor, as a block cursor on the icon looks cut
  self.marks:add("cell", range[1], range[2], {
    end_row = range[3],
    end_col = range[4],
    virt_text = { { self.data.icon, self.data.highlight } },
    virt_text_pos = "overlay",
  })
end

return Render
