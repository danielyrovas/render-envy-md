-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

---@class render.envy.request.callout.Value
---@field node render.envy.Node
---@field config render.envy.callout.Config

---@class render.envy.request.Callout
---@field private values table<integer, render.envy.request.callout.Value>
local Callout = {}
Callout.__index = Callout

---@return render.envy.request.Callout
function Callout.new()
  local self = setmetatable({}, Callout)
  self.values = {}
  return self
end

---@param node render.envy.Node
---@param config render.envy.callout.Config
function Callout:set(node, config)
  self.values[node.start_row] = { node = node, config = config }
end

---@param node render.envy.Node
---@return render.envy.request.callout.Value?
function Callout:get(node)
  return self.values[node.start_row]
end

return Callout
