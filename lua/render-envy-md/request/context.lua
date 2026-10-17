-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

---@class render.envy.request.Context
---@field buf integer
---@field win integer
---@field config render.envy.buf.Config
---@field view render.envy.request.View
---@field callout render.envy.request.Callout
local Context = {}
Context.__index = Context

---@param buf integer
---@param win integer
---@param config render.envy.buf.Config
---@param view render.envy.request.View
---@return render.envy.request.Context
function Context.new(buf, win, config, view)
  local self = setmetatable({}, Context)
  self.buf = buf
  self.win = win
  self.config = config
  self.view = view
  self.callout = require("render-envy-md.request.callout").new()
  return self
end

---@class render.envy.request.context.Manager
local M = {}

---@private
---@type table<integer, render.envy.request.Context>
M.cache = {}

---@param buf integer
---@param win integer
---@return boolean
function M.contains(buf, win)
  local context = M.cache[buf]
  return context and context.view:contains(win) or false
end

---@param buf integer
---@param win integer
---@param config render.envy.buf.Config
---@return render.envy.request.Context
function M.new(buf, win, config)
  local view = require("render-envy-md.request.view").new(buf)
  local context = Context.new(buf, win, config, view)
  M.cache[buf] = context
  return context
end

---@param buf integer
---@return render.envy.request.Context
function M.get(buf)
  return assert(M.cache[buf], "missing request context")
end

return M
