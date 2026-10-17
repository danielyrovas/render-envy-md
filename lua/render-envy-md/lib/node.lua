-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local str = require("render-envy-md.lib.str")

---@enum render.envy.node.Position
local Position = {
  above = "above",
  first = "first",
  below = "below",
  last = "last",
}

---@class render.envy.node.Body
---@field text string
---@field start_row integer
---@field start_col integer
---@field end_row integer
---@field end_col integer

---@class render.envy.Node: render.envy.node.Body
---@field private buf integer
---@field private node TSNode
---@field type string
local Node = {}
Node.__index = Node

---@param buf integer
---@param node TSNode
---@return render.envy.Node
function Node.new(buf, node)
  local self = setmetatable({}, Node)
  self.buf = buf
  self.node = node
  self.type = node:type()
  self.text = vim.treesitter.get_node_text(node, buf)
  local start_row, start_col, end_row, end_col = node:range()
  self.start_row = start_row
  self.start_col = start_col
  self.end_row = end_row
  self.end_col = end_col
  return self
end

---@private
---@param node TSNode
---@return render.envy.Node
function Node:create(node)
  return Node.new(self.buf, node)
end

---@return TSNode
function Node:get()
  return self.node
end

---@return integer
function Node:col()
  return self.start_col + str.spaces("start", self.text)
end

---@return integer
function Node:height()
  return self.end_row - self.start_row + 1
end

---@param target string
---@return integer, render.envy.Node?
function Node:level_in(target)
  local level = 0
  local root = nil ---@type TSNode?
  local node = self.node ---@type TSNode?
  while node and node:type() ~= "document" do
    if node:type() == target then
      level = level + 1
      root = node
    end
    node = node:parent()
  end
  return level, root and self:create(root)
end

---@param target string
---@return render.envy.Node?
function Node:parent(target)
  local node = self.node:parent()
  while node do
    if node:type() == target then
      return self:create(node)
    end
    node = node:parent()
  end
  return nil
end

---@param target string
---@return render.envy.Node?
function Node:sibling(target)
  local node = self.node ---@type TSNode?
  while node do
    if node:type() == target then
      return self:create(node)
    end
    node = node:next_sibling()
  end
  return nil
end

---@param target string
---@return integer
function Node:sibling_count(target)
  local count = 0
  local node = self.node ---@type TSNode?
  while node and node:type() == target do
    count = count + 1
    node = node:prev_sibling()
  end
  return count
end

---@param index integer
---@return render.envy.Node?
function Node:child_at(index)
  local node = self.node:named_child(index)
  return node and self:create(node)
end

---@param target string
---@param row? integer
---@return render.envy.Node?
function Node:child(target, row)
  for node in self.node:iter_children() do
    if node:type() == target then
      if not row or node:range() == row then
        return self:create(node)
      end
    end
  end
  return nil
end

---@param callback fun(node: render.envy.Node)
function Node:for_each_child(callback)
  for node in self.node:iter_children() do
    callback(self:create(node))
  end
end

---@param target string
---@return render.envy.Node?
function Node:descendant(target)
  for node in self.node:iter_children() do
    local child = self:create(node)
    if child.type == target then
      return child
    end
    local nested = child:descendant(target)
    if nested then
      return nested
    end
  end
  return nil
end

---@param pattern string
---@return Range4[]
function Node:find(pattern)
  local result = {} ---@type Range4[]
  local index = 1 ---@type integer?
  while index do
    local start_index, end_index = self.text:find(pattern, index)
    if not start_index or not end_index then
      index = nil
    else
      index = end_index + 1
      -- start : 1-based inclusive -> 0-based inclusive = -1 offset
      -- end   : 1-based inclusive -> 0-based exclusive =  0 offset
      local start_row, start_col = self:position(start_index, -1)
      local end_row, end_col = self:position(end_index, 0)
      result[#result + 1] = { start_row, start_col, end_row, end_col }
    end
  end
  return result
end

---@private
---@param index integer
---@param offset integer
---@return integer, integer
function Node:position(index, offset)
  local lines = vim.split(self.text:sub(1, index), "\n", { plain = true })
  -- start row includes first line
  local row = self.start_row + #lines - 1
  local col = #lines[#lines] + offset
  if row == self.start_row then
    col = col + self.start_col
  end
  return row, col
end

---@param position render.envy.node.Position
---@param by integer
---@return integer, string?
function Node:line(position, by)
  local row ---@type integer
  if position == Position.above then
    row = self.start_row - by
  elseif position == Position.first then
    row = self.start_row + by
  elseif position == Position.below then
    row = self.end_row - (self:height() == 1 and 0 or 1) + by
  elseif position == Position.last then
    row = self.end_row - (self:height() == 1 and 0 or 1) - by
  else
    error(("invalid position: %s"):format(position))
  end
  return row, vim.api.nvim_buf_get_lines(self.buf, row, row + 1, false)[1]
end

return Node
