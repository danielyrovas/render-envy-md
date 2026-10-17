-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Base = require("render-envy-md.render.base")
local Wiki = require("render-envy-md.render.common.wiki")

---@class render.envy.render.inline.Shortcut: render.envy.Render
---@field private config render.envy.link.Config
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  local callout = self.context.config:callout_for(self.node)
  if callout then
    self.context.callout:set(self.node, callout)
    return false
  end
  self.config = self.context.config.link
  return self.config.enabled
end

---@protected
function Render:run()
  -- [[page]] is parsed as a shortcut_link of [page] inside an extra pair of
  -- brackets, anything else is a footnote style shortcut, which is left alone
  -- upstream searches the whole line, which also matches [a] in '[[a]] [a]'
  -- -> check the characters around the node instead
  local _, line = self.node:line("first", 0)
  local around = line and line:sub(self.node.start_col, self.node.end_col + 1)
  if around == "[" .. self.node.text .. "]" then
    Wiki:execute(self.context, self.marks, self.node)
  end
end

return Render
