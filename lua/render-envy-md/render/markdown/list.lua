-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Base = require("render-envy-md.render.base")
local Bullet = require("render-envy-md.render.markdown.bullet")

---@class render.envy.render.List: render.envy.Render
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  return true
end

---@protected
function Render:run()
  Bullet:execute(self.context, self.marks, self.node)
end

return Render
