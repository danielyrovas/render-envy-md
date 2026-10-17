-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Context = require("render-envy-md.request.context")
local Marks = require("render-envy-md.lib.marks")
local ts = require("render-envy-md.core.ts")

---@class render.envy.handler.MarkdownInline: render.envy.Handler
local M = {}

---@param ctx render.envy.handler.Context
---@return render.envy.Mark[]
function M.parse(ctx)
  -- stylua: ignore
  local query = ts.parse("markdown_inline", [[
    (shortcut_link) @shortcut

    (emphasis_delimiter) @emphasis

    ((inline) @highlight
      (#lua-match? @highlight "==[^=]+=="))

    (strikethrough) @strikethrough

    [
      (inline_link)
      (uri_autolink)
    ] @link
  ]])
  ---@type table<string, render.envy.Render>
  local renders = {
    emphasis = require("render-envy-md.render.inline.emphasis"),
    highlight = require("render-envy-md.render.inline.highlight"),
    link = require("render-envy-md.render.inline.link"),
    shortcut = require("render-envy-md.render.inline.shortcut"),
    strikethrough = require("render-envy-md.render.inline.strikethrough"),
  }
  local context = Context.get(ctx.buf)
  local marks = Marks.new()
  context.view:nodes(ctx.root, query, function(capture, node)
    local render = renders[capture]
    assert(render, ("unhandled inline capture: %s"):format(capture))
    render:execute(context, marks, node)
  end)
  return marks:get()
end

return M
