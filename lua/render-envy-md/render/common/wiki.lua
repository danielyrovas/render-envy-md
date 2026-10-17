-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Base = require("render-envy-md.render.base")
local str = require("render-envy-md.lib.str")

---@class render.envy.render.common.Wiki: render.envy.Render
---@field private config render.envy.link.wiki.Config
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  local config = self.context.config.link
  self.config = config.wiki
  return config.enabled and self.config.enabled
end

---@protected
function Render:run()
  local _, _, pre, text, post = self.node.text:find("^(.-%[+)(.-)(%]+.-)$")
  if not pre or not text or not post then
    return -- not inside square brackets
  end
  if #pre ~= #post then
    return -- pre and post are not balanced
  end

  local start_col = self.node.start_col + #pre
  local end_col = self.node.end_col - #pre
  local separator = text:find("|", 1, true)

  local row = self.node.start_row
  local highlight = "RenderEnvyWikiLinkDim"
  -- unlike upstream 'page|' of an alias is not concealed
  if separator then
    self:delimiter(self.config.alias, row, start_col, start_col + separator, highlight)
  end

  local delimiters = self.config.delimiters
  local width = 2 -- of '[[' and ']]'
  local icon = self.config.icon
  -- an icon wider than the brackets would cover the link text -> spaces
  if delimiters and icon and str.width(icon) <= width then
    -- dimmed on the cursor line, off it the icon covers the raw brackets
    self:delimiter("dim", row, start_col - 2, start_col, highlight)
    self:overlay(start_col - 2, icon .. str.pad(width - str.width(icon)))
  else
    self:delimiter(delimiters, row, start_col - 2, start_col, highlight)
  end
  self:delimiter(delimiters, row, end_col, end_col + 2, highlight)
end

---@private
---@param col integer
---@param text string
function Render:overlay(col, text)
  -- keeps the line width so there is no layout shift, hidden by anti-conceal
  -- to show the raw brackets on the cursor line, default hl_mode 'replace' ->
  -- dim highlight below does not show through
  self.marks:add(true, self.node.start_row, col, {
    virt_text = { { text, "RenderEnvyWikiLink" } },
    virt_text_pos = "overlay",
  })
end

return Render
