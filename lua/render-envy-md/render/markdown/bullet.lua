-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Base = require("render-envy-md.render.base")
local list = require("render-envy-md.lib.list")
local str = require("render-envy-md.lib.str")

---@class render.envy.bullet.Data
---@field marker render.envy.Node
---@field icon? string

---@class render.envy.render.Bullet: render.envy.Render
---@field private config render.envy.bullet.Config
---@field private data render.envy.bullet.Data
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  self.config = self.context.config.bullet
  if not self.config.enabled then
    return false
  end
  local marker = self.node:child_at(0)
  if not marker then
    return false
  end
  -- ordered list markers are left alone
  local unordered_types = { "list_marker_minus", "list_marker_plus", "list_marker_star" }
  if not vim.tbl_contains(unordered_types, marker.type) then
    return false
  end
  ---@type render.envy.bullet.Context
  local ctx = {
    level = self.node:level_in("list"),
    index = self.node:sibling_count("list_item"),
    value = marker.text,
  }
  self.data = {
    marker = marker,
    icon = Render.get_string(self.config.icons, ctx),
  }
  return true
end

---@private
---@param values render.envy.bullet.String
---@param ctx render.envy.bullet.Context
---@return string?
function Render.get_string(values, ctx)
  if type(values) == "function" then
    return values(ctx)
  else
    local value = list.cycle(values, ctx.level)
    return list.clamp(value, ctx.index)
  end
end

---@protected
function Render:run()
  local icon = self.data.icon
  if not icon then
    return
  end
  -- https://github.com/tree-sitter-grammars/tree-sitter-markdown/issues/127
  local node = self.data.marker
  local spaces = str.spaces("start", node.text)
  local text = str.pad(spaces) .. icon
  -- an overlay wider than the marker would cover the item text, the
  -- alternative of inline text + conceal changes the line width -> skip
  if str.width(text) > str.width(node.text) then
    return
  end
  -- hidden under the cursor, as a block cursor on the icon looks cut
  self.marks:start("cell", node, {
    end_row = node.start_row,
    end_col = node.start_col + spaces + 1,
    virt_text = { { text, "RenderEnvyBullet" } },
    virt_text_pos = "overlay",
  })
end

return Render
