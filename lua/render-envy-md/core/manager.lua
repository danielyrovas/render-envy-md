-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local env = require("render-envy-md.lib.env")
local state = require("render-envy-md.state")

-- not in upstream: loaded on the first attach to keep start-up small
---@type render.envy.Ui
local ui

---@class render.envy.Manager
local M = {}

---@private
M.group = vim.api.nvim_create_augroup("RenderEnvy", {})

---@private
---@type integer[]
M.buffers = {}

---called from plugin directory
function M.init()
  -- lazy loading: FileType event may have already executed for loaded buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      M.attach(buf)
    end
  end
  -- attempt to attach to all buffers, cannot use pattern to support plugin directory
  vim.api.nvim_create_autocmd("FileType", {
    group = M.group,
    callback = function(args)
      M.attach(args.buf)
    end,
  })
end

-- not in upstream
---called on the first attach, loads the ui and highlights once a buffer needs them
---@private
function M.load()
  if ui then
    return
  end
  ui = require("render-envy-md.core.ui")
  require("render-envy-md.core.colors").init()
  -- window resizing is not buffer specific so is managed more globally
  vim.api.nvim_create_autocmd("WinResized", {
    group = M.group,
    callback = function()
      for _, win in ipairs(vim.v.event.windows or {}) do
        local buf = env.win.buf(win)
        if M.attached(buf) and state.get(buf).enabled then
          ui.update(buf, win, true)
        end
      end
    end,
  })
end

---@param buf integer
---@return boolean
function M.attached(buf)
  return vim.tbl_contains(M.buffers, buf)
end

---called from init on setup, re-render attached buffers with new configuration
function M.refresh()
  for _, buf in ipairs(M.buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      ui.update(buf, env.buf.win(buf), true)
    end
  end
end

---@param enable? boolean
function M.set(enable)
  if enable ~= nil then
    state.enabled = enable
  else
    state.enabled = not state.enabled
  end
  for _, buf in ipairs(M.buffers) do
    M.set_buf(buf, state.enabled)
  end
end

---@param buf? integer
---@param enable? boolean
function M.set_buf(buf, enable)
  buf = buf or env.buf.current()
  if M.attached(buf) and env.buf.valid(buf) then
    local config = state.get(buf)
    if enable ~= nil then
      config.enabled = enable
    else
      config.enabled = not config.enabled
    end
    ui.update(buf, env.buf.win(buf), true)
  end
end

---@private
---@param buf integer
function M.attach(buf)
  if not M.should_attach(buf) then
    return
  end

  M.load()
  local config = state.get(buf)

  local events = {
    "BufWinEnter",
    "BufLeave",
    "CursorHold",
    "CursorMoved",
    "ModeChanged",
    "TextChanged",
    "WinScrolled",
  }
  if config:render("i") then
    events[#events + 1] = "CursorHoldI"
    events[#events + 1] = "CursorMovedI"
    events[#events + 1] = "TextChangedI"
  end

  vim.api.nvim_create_autocmd(events, {
    group = M.group,
    buffer = buf,
    callback = function()
      if not state.get(buf).enabled then
        return
      end
      ui.update(buf, env.buf.win(buf), false)
    end,
  })

  if config.enabled then
    ui.update(buf, env.buf.win(buf), true)
  end
end

---@private
---@param buf integer
---@return boolean
function M.should_attach(buf)
  if M.attached(buf) then
    return false
  end

  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  if not vim.tbl_contains(state.file_types, env.buf.get(buf, "filetype")) then
    return false
  end

  if env.file_size_mb(buf) > state.max_file_size then
    return false
  end

  M.buffers[#M.buffers + 1] = buf
  return true
end

return M
