-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local iter = require("render-envy-md.lib.iter")

---@class (exact) render.envy.Handler
---@field parse fun(ctx: render.envy.handler.Context): render.envy.Mark[]

---@class (exact) render.envy.handler.Context
---@field buf integer
---@field root TSNode

---@class render.envy.Handlers
local M = {}

---@private
---@type table<string, render.envy.Handler>
M.builtin = {
  markdown = require("render-envy-md.handler.markdown"),
  markdown_inline = require("render-envy-md.handler.markdown_inline"),
}

---@param context render.envy.request.Context
---@param parser vim.treesitter.LanguageTree
---@return render.envy.Mark[]
function M.run(context, parser)
  local language_roots = {} ---@type table<string, TSNode[]>
  parser:for_each_tree(function(tree, language_tree)
    local root = tree:root()
    local language = language_tree:lang()
    if M.builtin[language] and M.level(language_tree) == 1 and context.view:overlaps(root) then
      local roots = language_roots[language]
      if not roots then
        roots = {}
        language_roots[language] = roots
      end
      roots[#roots + 1] = root
    end
  end)

  -- languages that run later will have more complete state
  local languages = vim.tbl_keys(language_roots) ---@type string[]
  local order = { markdown = 100 } ---@type table<string, integer>
  iter.list.sort(languages, function(language)
    return order[language] or 0
  end)

  local marks = {} ---@type render.envy.Mark[]
  for _, language in ipairs(languages) do
    local handler = M.builtin[language]
    for _, root in ipairs(language_roots[language]) do
      vim.list_extend(marks, handler.parse({ buf = context.buf, root = root }))
    end
  end
  return marks
end

---only top level markdown is rendered, i.e. markdown nested inside a markdown
---code block is skipped
---@private
---@param tree? vim.treesitter.LanguageTree
---@return integer
function M.level(tree)
  local result = 0
  while tree do
    if tree:lang() == "markdown" then
      result = result + 1
    end
    tree = tree:parent()
  end
  return result
end

return M
