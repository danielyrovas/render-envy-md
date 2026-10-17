-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local interval = require("render-envy-md.lib.interval")

---@class render.envy.Extmark
---@field private id? integer
---@field private mark render.envy.Mark
---@field private range render.envy.Range
local Extmark = {}
Extmark.__index = Extmark

---@param mark render.envy.Mark
---@return render.envy.Extmark
function Extmark.new(mark)
  local self = setmetatable({}, Extmark)
  self.id = nil
  self.mark = mark
  local top = mark.start_row
  local bottom = mark.opts.end_row or top
  -- hl_eol should not include last line
  if mark.opts.hl_eol then
    bottom = bottom - 1
  end
  self.range = { top, bottom }
  return self
end

---@return render.envy.Mark
function Extmark:get()
  return self.mark
end

---@param range? render.envy.Range
---@return boolean
function Extmark:overlaps(range)
  if not range then
    return false
  end
  return interval.overlap(self.range, range) ~= nil
end

-- not in upstream
---@param cursor? { [1]: integer, [2]: integer } row, col
---@return boolean
function Extmark:contains(cursor)
  if not cursor then
    return false
  end
  local mark = self.mark
  local row, col = cursor[1], cursor[2]
  local end_row = mark.opts.end_row or mark.start_row
  local end_col = mark.opts.end_col or mark.start_col + 1
  if row < mark.start_row or row > end_row then
    return false
  end
  if row == mark.start_row and col < mark.start_col then
    return false
  end
  if row == end_row and col >= end_col then
    return false
  end
  return true
end

---@param ns integer
---@param buf integer
function Extmark:show(ns, buf)
  if self.id then
    return
  end
  local mark = self.mark
  mark.opts.strict = false
  local ok, id = pcall(vim.api.nvim_buf_set_extmark, buf, ns, mark.start_row, mark.start_col, mark.opts)
  if ok then
    self.id = id
  end
end

---@param ns integer
---@param buf integer
function Extmark:hide(ns, buf)
  if not self.id then
    return
  end
  vim.api.nvim_buf_del_extmark(buf, ns, self.id)
  self.id = nil
end

return Extmark
