-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

---@class render.envy.Str
local M = {}

---@param s? string
---@return integer
function M.width(s)
  return s and vim.fn.strdisplaywidth(s) or 0
end

---@param pos 'start'|'end'
---@param s string
---@return integer
function M.spaces(pos, s)
  local pattern = pos == "start" and "^%s*" or "%s*$"
  local from, to = s:find(pattern)
  return (from and to) and to - from + 1 or 0
end

---@param n integer
---@return string
function M.pad(n)
  return n > 0 and (" "):rep(n) or ""
end

return M
