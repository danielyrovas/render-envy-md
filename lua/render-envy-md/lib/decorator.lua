-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

---@class render.envy.Decorator
---@field private buf integer
---@field private timer uv.uv_timer_t
---@field private running boolean
---@field private marks render.envy.Extmark[]
---@field private tick integer?
local Decorator = {}
Decorator.__index = Decorator

---@param buf integer
---@return render.envy.Decorator
function Decorator.new(buf)
  local self = setmetatable({}, Decorator)
  self.buf = buf
  self.timer = assert(vim.uv.new_timer())
  self.running = false
  self.marks = {}
  self.tick = nil
  return self
end

---@return boolean
function Decorator:changed()
  return self.tick ~= self:get_tick()
end

---@param marks render.envy.Extmark[]
function Decorator:set(marks)
  self.marks = marks
  self.tick = self:get_tick()
end

---@param ns integer
function Decorator:clear(ns)
  for _, extmark in ipairs(self.marks) do
    extmark:hide(ns, self.buf)
  end
end

---@param ns integer
---@param hide fun(extmark: render.envy.Extmark): boolean
function Decorator:display(ns, hide)
  for _, extmark in ipairs(self.marks) do
    if hide(extmark) then
      extmark:hide(ns, self.buf)
    else
      extmark:show(ns, self.buf)
    end
  end
end

---@param debounce boolean
---@param ms integer
---@param callback fun()
function Decorator:schedule(debounce, ms, callback)
  if debounce and ms > 0 then
    self.timer:start(ms, 0, function()
      self.running = false
    end)
    if not self.running then
      self.running = true
      vim.schedule(callback)
    end
  else
    vim.schedule(callback)
  end
end

---@private
---@return integer
function Decorator:get_tick()
  return vim.api.nvim_buf_get_changedtick(self.buf)
end

return Decorator
