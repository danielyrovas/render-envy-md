-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Context = require("render-envy-md.request.context")
local Marks = require("render-envy-md.lib.marks")
local ts = require("render-envy-md.core.ts")

---@class render.envy.handler.Markdown: render.envy.Handler
local M = {}

---@param ctx render.envy.handler.Context
---@return render.envy.Mark[]
function M.parse(ctx)
  -- stylua: ignore
  local query = ts.parse("markdown", [[
    (fenced_code_block) @code

    [
      (thematic_break)
      (minus_metadata)
      (plus_metadata)
    ] @dash

    [
      (atx_heading)
      (setext_heading)
    ] @heading

    (list_item) @list

    (block_quote) @quote
  ]])
  ---@type table<string, render.envy.Render>
  local renders = {
    code = require("render-envy-md.render.markdown.code"),
    dash = require("render-envy-md.render.markdown.dash"),
    heading = require("render-envy-md.render.markdown.heading"),
    list = require("render-envy-md.render.markdown.list"),
    quote = require("render-envy-md.render.markdown.quote"),
  }
  local context = Context.get(ctx.buf)
  local marks = Marks.new()
  context.view:nodes(ctx.root, query, function(capture, node)
    local render = renders[capture]
    assert(render, ("unhandled markdown capture: %s"):format(capture))
    render:execute(context, marks, node)
  end)
  return marks:get()
end

return M
