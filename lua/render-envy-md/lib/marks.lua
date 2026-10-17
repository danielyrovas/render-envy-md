-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

---@class (exact) render.envy.Mark
---@field conceal render.envy.mark.Conceal
---@field start_row integer
---@field start_col integer
---@field opts render.envy.mark.Opts

---@class render.envy.mark.Opts: vim.api.keyset.set_extmark
---@field virt_text? render.envy.mark.Line
---@field virt_lines? render.envy.mark.Line[]

---@alias render.envy.mark.Line render.envy.mark.Text[]

---@class (exact) render.envy.mark.Text
---@field [1] string text
---@field [2] render.envy.mark.Hl highlight

---@alias render.envy.mark.Hl string|string[]

-- 'cursor', 'reveal' and 'cell' are not in upstream
---@alias render.envy.mark.Conceal boolean|'cursor'|'reveal'|'cell'

---@class render.envy.Marks
---@field private marks render.envy.Mark[]
local Marks = {}
Marks.__index = Marks

---@return render.envy.Marks
function Marks.new()
  local self = setmetatable({}, Marks)
  self.marks = {}
  return self
end

---@return render.envy.Mark[]
function Marks:get()
  return self.marks
end

---conceal: whether the mark should be hidden by anti-conceal, i.e. it hides
---buffer text that should be visible around the cursor, 'cursor' -> hidden on
---the cursor row in every mode, i.e. it replaces a cursor line highlight,
---'reveal' -> hidden on every row in reveal modes only, i.e. it covers text
---with the same width so the cursor line does not need it hidden, 'cell' ->
---as 'reveal' and also hidden when the cursor is on the text it covers, i.e.
---the block cursor shows the raw text instead of the overlay
---@param conceal render.envy.mark.Conceal
---@param node render.envy.Node
---@param opts render.envy.mark.Opts
function Marks:start(conceal, node, opts)
  self:add(conceal, node.start_row, node.start_col, opts)
end

---@param conceal render.envy.mark.Conceal
---@param node? render.envy.Node
---@param opts render.envy.mark.Opts
---@param offset? Range4
---@return boolean
function Marks:over(conceal, node, opts, offset)
  if not node then
    return false
  end
  offset = offset or { 0, 0, 0, 0 }
  local start_row = node.start_row + offset[1]
  local start_col = node.start_col + offset[2]
  opts.end_row = node.end_row + offset[3]
  opts.end_col = node.end_col + offset[4]
  self:add(conceal, start_row, start_col, opts)
  return true
end

---@param conceal render.envy.mark.Conceal
---@param start_row integer
---@param start_col integer
---@param opts render.envy.mark.Opts
function Marks:add(conceal, start_row, start_col, opts)
  self.marks[#self.marks + 1] = {
    conceal = conceal,
    start_row = start_row,
    start_col = start_col,
    opts = opts,
  }
end

return Marks
