-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Node = require("render-envy-md.lib.node")
local env = require("render-envy-md.lib.env")
local interval = require("render-envy-md.lib.interval")

---@class render.envy.request.View
---@field private buf integer
---@field private ranges render.envy.Range[]
local View = {}
View.__index = View

---@param buf integer
---@return render.envy.request.View
function View.new(buf)
  local self = setmetatable({}, View)
  self.buf = buf
  local ranges = {} ---@type render.envy.Range[]
  for _, win in ipairs(env.buf.wins(buf)) do
    ranges[#ranges + 1] = env.range(buf, win, 10)
  end
  self.ranges = interval.coalesce(ranges)
  return self
end

---@param win integer
---@return boolean
function View:contains(win)
  local rows = env.range(self.buf, win, 0)
  for _, range in ipairs(self.ranges) do
    if interval.contains(range, rows) then
      return true
    end
  end
  return false
end

---@param node TSNode
---@return boolean
function View:overlaps(node)
  local start_row, _, end_row = node:range()
  for _, range in ipairs(self.ranges) do
    if interval.overlap(range, { start_row, end_row }) then
      return true
    end
  end
  return false
end

-- not in upstream
---@param rows render.envy.Range rows to limit, end row included
---@return render.envy.Range[] parts of rows in the view, end row included
function View:clip(rows)
  local result = {} ---@type render.envy.Range[]
  -- ranges do not include their end row and do not overlap once coalesced
  for _, range in ipairs(self.ranges) do
    local part = interval.overlap({ range[1], range[2] - 1 }, rows)
    if part then
      result[#result + 1] = part
    end
  end
  return result
end

---@param parser vim.treesitter.LanguageTree
---@param callback fun()
function View:parse(parser, callback)
  for _, range in ipairs(self.ranges) do
    parser:parse(range)
  end
  callback()
end

---@param root TSNode
---@param query vim.treesitter.Query
---@param callback fun(capture: string, node: render.envy.Node)
function View:nodes(root, query, callback)
  -- not in upstream: a node in more than one range, i.e. a long block seen in
  -- two windows, is captured once per range -> handle it once
  local seen = {} ---@type table<string, boolean>
  for _, range in ipairs(self.ranges) do
    local start, stop = range[1], range[2]
    for id, ts_node in query:iter_captures(root, self.buf, start, stop) do
      local key = id .. ":" .. ts_node:id()
      if not seen[key] and not ts_node:has_error() then
        seen[key] = true
        callback(query.captures[id], Node.new(self.buf, ts_node))
      end
    end
  end
end

return View
