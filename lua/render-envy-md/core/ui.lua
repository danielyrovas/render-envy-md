-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Context = require("render-envy-md.request.context")
local env = require("render-envy-md.lib.env")
local iter = require("render-envy-md.lib.iter")
local state = require("render-envy-md.state")

---@class render.envy.Ui
local M = {}

M.ns = vim.api.nvim_create_namespace("render-envy-md")

---@private
---@type table<integer, render.envy.Decorator>
M.cache = {}

---called from state on setup
function M.setup()
  -- clear marks and reset cache
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  end
  M.cache = {}
end

---@param buf integer
---@return render.envy.Decorator
function M.get(buf)
  local result = M.cache[buf]
  if not result then
    result = require("render-envy-md.lib.decorator").new(buf)
    M.cache[buf] = result
  end
  return result
end

---@param buf integer
---@param win integer
---@param force boolean
function M.update(buf, win, force)
  M.updater.new(buf, win, force):start()
end

---@class render.envy.ui.Updater
---@field private buf integer
---@field private win integer
---@field private force boolean
---@field private decorator render.envy.Decorator
---@field private config render.envy.buf.Config
---@field private mode string
local Updater = {}
Updater.__index = Updater

---@param buf integer
---@param win integer
---@param force boolean
---@return render.envy.ui.Updater
function Updater.new(buf, win, force)
  local self = setmetatable({}, Updater)
  self.buf = buf
  self.win = win
  self.force = force
  self.decorator = M.get(buf)
  self.config = state.get(buf)
  return self
end

function Updater:start()
  if not env.valid(self.buf, self.win) then
    return
  end
  self.decorator:schedule(self:changed() and not env.buf.empty(self.buf), self.config.debounce, function()
    self:run()
  end)
end

---@private
---@return boolean
function Updater:changed()
  -- force or buffer has changed or we have not handled the visible range yet
  return self.force or self.decorator:changed() or not Context.contains(self.buf, self.win)
end

---@private
function Updater:run()
  if not env.valid(self.buf, self.win) then
    return
  end
  self.mode = env.mode.get() -- mode is only available after this point
  local render = self.config.enabled and self.config:render(self.mode) and env.win.view(self.win).leftcol == 0
  if not render then
    self:clear()
  else
    self:render()
  end
end

---@private
function Updater:clear()
  self.decorator:clear(M.ns)
  vim.api.nvim_buf_clear_namespace(self.buf, M.ns, 0, -1)
end

---@private
function Updater:render()
  if self:changed() then
    local extmarks = self:parse()
    if not extmarks then
      return
    end
    self:clear()
    self.decorator:set(extmarks)
  end
  self:display()
end

---@private
---@return render.envy.Extmark[]?
function Updater:parse()
  local ok, parser = pcall(vim.treesitter.get_parser, self.buf)
  if not ok or not parser then
    return nil
  end
  -- reset buffer context
  local context = Context.new(self.buf, self.win, self.config)
  local result = nil ---@type render.envy.Extmark[]?
  context.view:parse(parser, function()
    local Extmark = require("render-envy-md.lib.extmark")
    local handlers = require("render-envy-md.core.handlers")
    local marks = handlers.run(context, parser)
    result = iter.list.map(marks, Extmark.new)
  end)
  return result
end

---@private
function Updater:display()
  local range = self:hidden()
  local reveal = self:reveal()
  -- row is not known -> buffer is not active -> no cursor row
  local row = env.row.get(self.buf, self.win)
  ---@type render.envy.Range?
  local cursor = row and { row, row } or nil
  local col = env.row.col(self.buf, self.win)
  local cell = row and col and { row, col } or nil
  self.decorator:display(M.ns, function(extmark)
    return self:hide(extmark, range, cursor, cell, reveal)
  end)
end

-- not in upstream
---@private
---@return boolean
function Updater:reveal()
  local config = self.config.anti_conceal
  return config.enabled and env.mode.is(self.mode, config.reveal_modes)
end

---@private
---@return render.envy.Range?
function Updater:hidden()
  -- anti-conceal is not enabled -> hide nothing
  local config = self.config.anti_conceal
  if not config.enabled then
    return nil
  end
  -- in reveal mode -> hide on every line
  if self:reveal() then
    ---@type render.envy.Range
    return { 0, vim.api.nvim_buf_line_count(self.buf) }
  end
  -- row is not known -> buffer is not active -> hide nothing
  local row = env.row.get(self.buf, self.win)
  if not row then
    return nil
  end
  if env.mode.is(self.mode, { "v", "V", "\22" }) then
    local start = vim.fn.getpos("v")[2] - 1
    ---@type render.envy.Range
    return { math.min(row, start), math.max(row, start) }
  else
    ---@type render.envy.Range
    return { row - config.lines_above, row + config.lines_below }
  end
end

---@private
---@param extmark render.envy.Extmark
---@param range? render.envy.Range
---@param cursor? render.envy.Range
---@param cell? { [1]: integer, [2]: integer }
---@param reveal boolean
---@return boolean
function Updater:hide(extmark, range, cursor, cell, reveal)
  -- not in upstream: replaces a cursor line highlight -> hide on cursor row
  if extmark:get().conceal == "cursor" then
    return extmark:overlaps(cursor)
  end
  -- not in upstream: same width as the text it covers -> hide in reveal mode
  if extmark:get().conceal == "reveal" then
    return reveal
  end
  -- not in upstream: as reveal, also hide under the cursor -> full block cursor
  if extmark:get().conceal == "cell" then
    return reveal or extmark:contains(cell)
  end
  -- does not overlap with hidden range -> show
  if not extmark:overlaps(range) then
    return false
  end
  -- mark conceals buffer text -> hide, otherwise -> show
  return extmark:get().conceal == true
end

---@private
M.updater = Updater

return M
