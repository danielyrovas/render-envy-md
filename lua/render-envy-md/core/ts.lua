-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local state = require("render-envy-md.state")

---@class render.envy.Ts
local M = {}

---@private
---@type table<string, vim.treesitter.Query>
M.queries = {}

---called from state on setup
function M.setup()
  for _, language in ipairs(state.file_types) do
    M.inject(language)
  end
end

---@private
---@param language string
function M.inject(language)
  local injection = state.injections[language]
  if not injection or not injection.enabled then
    return
  end
  local query = ";; extends\n" .. injection.query
  -- parser for the language may not be installed
  pcall(vim.treesitter.query.set, language, "injections", query)
end

---@param language string
---@param query string
---@return vim.treesitter.Query
function M.parse(language, query)
  local key = language .. "\0" .. query
  local result = M.queries[key]
  if not result then
    result = vim.treesitter.query.parse(language, query)
    M.queries[key] = result
  end
  return result
end

return M
