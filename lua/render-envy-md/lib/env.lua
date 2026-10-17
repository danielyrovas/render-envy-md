-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

---@class render.envy.Env
local M = {}

---@param file string|integer
---@return number
function M.file_size_mb(file)
  if type(file) ~= "string" then
    file = vim.api.nvim_buf_get_name(file)
  end
  local ok, stats = pcall(vim.uv.fs_stat, file)
  if not ok or not stats then
    return 0
  end
  return stats.size / (1024 * 1024)
end

---@param buf integer
---@param win integer
---@return boolean
function M.valid(buf, win)
  if not M.buf.valid(buf) or not M.win.valid(win) then
    return false
  end
  return buf == M.win.buf(win)
end

---@param buf integer
---@param win integer
---@param offset integer
---@return render.envy.Range
function M.range(buf, win, offset)
  local top = math.max(M.win.view(win).topline - 1 - offset, 0)
  local bottom = top
  local lines = vim.api.nvim_buf_line_count(buf)
  local size = vim.api.nvim_win_get_height(win) + (2 * offset)
  while bottom < lines and size > 0 do
    bottom = bottom + 1
    if M.row.visible(win, bottom) then
      size = size - 1
    end
  end
  ---@type render.envy.Range
  return { top, bottom }
end

---@class render.envy.env.Row
M.row = {}

---@param buf integer
---@param win integer
---@return integer?
function M.row.get(buf, win)
  if buf ~= M.buf.current() then
    return nil
  end
  return vim.api.nvim_win_get_cursor(win)[1] - 1
end

-- not in upstream
---@param buf integer
---@param win integer
---@return integer?
function M.row.col(buf, win)
  if buf ~= M.buf.current() then
    return nil
  end
  return vim.api.nvim_win_get_cursor(win)[2]
end

---@param win integer
---@param row integer
---@return boolean
function M.row.visible(win, row)
  return vim.api.nvim_win_call(win, function()
    return vim.fn.foldclosed(row) == -1
  end)
end

---@class render.envy.env.Mode
M.mode = {}

---@return string
function M.mode.get()
  return vim.fn.mode(true)
end

-- not in upstream: sub modes that behave like a listed mode, i.e. insert
-- completion 'ic' -> 'i', operator pending 'no' -> 'n', select 's' -> 'v'
---@private
---@param mode string
---@return string
function M.mode.family(mode)
  local first = mode:sub(1, 1)
  if mode:sub(1, 2) == "ni" or first == "R" then
    return "i"
  end
  local select = { s = "v", S = "V", ["\19"] = "\22" }
  return select[first] or first
end

---@param mode string
---@param modes? render.envy.Modes
---@return boolean
function M.mode.is(mode, modes)
  if modes == nil then
    return false
  elseif type(modes) == "boolean" then
    return modes
  else
    return vim.tbl_contains(modes, mode) or vim.tbl_contains(modes, M.mode.family(mode))
  end
end

---@class render.envy.env.Buf
M.buf = {}

---@return integer
function M.buf.current()
  return vim.api.nvim_get_current_buf()
end

---@param buf integer
---@return boolean
function M.buf.valid(buf)
  return vim.api.nvim_buf_is_valid(buf)
end

---@param buf integer
---@param name string
---@return any
---@overload fun(buf: integer, name: 'filetype'): string
function M.buf.get(buf, name)
  return vim.api.nvim_get_option_value(name, { buf = buf })
end

---@param buf integer
---@return boolean
function M.buf.empty(buf)
  if vim.api.nvim_buf_line_count(buf) > 1 then
    return false
  else
    local line = vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
    return not line or line == ""
  end
end

---@param buf integer
---@return integer
function M.buf.win(buf)
  local wins = M.buf.wins(buf)
  if #wins == 0 then
    return -1
  end
  local win = M.win.current()
  return vim.tbl_contains(wins, win) and win or wins[1]
end

---@param buf integer
---@return integer[]
function M.buf.wins(buf)
  return vim.fn.win_findbuf(buf)
end

---@class render.envy.env.Win
M.win = {}

---@return integer
function M.win.current()
  return vim.api.nvim_get_current_win()
end

---@param win integer
---@return boolean
function M.win.valid(win)
  return vim.api.nvim_win_is_valid(win)
end

---@param win integer
---@return integer
function M.win.buf(win)
  return vim.fn.winbufnr(win)
end

---@param win integer
---@return vim.fn.winsaveview.ret
function M.win.view(win)
  return vim.api.nvim_win_call(win, vim.fn.winsaveview)
end

return M
