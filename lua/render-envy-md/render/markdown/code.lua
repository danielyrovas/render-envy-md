-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Base = require("render-envy-md.render.base")
local colors = require("render-envy-md.core.colors")
local icons = require("render-envy-md.lib.icons")
local str = require("render-envy-md.lib.str")

---@class render.envy.render.markdown.Code: render.envy.Render
---@field private config render.envy.code.Config
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  self.config = self.context.config.code
  if not self.config.enabled then
    return false
  end
  -- skip single line code block
  return self.node:height() > 2
end

---@protected
function Render:run()
  local start_row = self.node.start_row
  local end_row = self.node.end_row - 1

  local above = self.node:child("fenced_code_block_delimiter", start_row)
  local below = self.node:child("fenced_code_block_delimiter", end_row)

  -- unlike upstream the delimiters are not concealed and there is no
  -- background, the overlays cover them
  local line, language_hl = self:language(above)
  self:dim(above, line ~= nil or self.config.border)
  self:dim(below, self.config.border)
  language_hl = language_hl or "RenderEnvyCodeFallback"
  local border_hl = self.config.highlight_border or colors.fade(language_hl, self.config.language_color_fade)
  self:overlay(above, line, border_hl)
  self:overlay(below, {}, border_hl)
  self:number(language_hl)
end

-- not in upstream
---@private
---@param highlight string
function Render:number(highlight)
  if not self.config.line_numbers then
    return
  end
  -- the number column keeps its own background
  local number_hl = self.config.highlight_line_numbers
    or colors.fade(highlight, self.config.language_color_fade, "LineNr")
  -- the number column does not hold buffer text, but the color replaces the
  -- cursor line number -> hidden on the cursor row only, includes the bottom
  -- delimiter, the node ends on the row after it, only rows in the view, a long
  -- block would otherwise add a mark for every row
  for _, rows in ipairs(self.context.view:clip({ self.node.start_row, self.node.end_row - 1 })) do
    for row = rows[1], rows[2] do
      self.marks:add("cursor", row, 0, {
        number_hl_group = number_hl,
      })
    end
  end
end

---@private
---@param delim? render.envy.Node
---@param line? [string, string][]
---@param border_hl string
function Render:overlay(delim, line, border_hl)
  if not delim then
    return
  end
  line = line or {}
  if self.config.border then
    -- overlay past the end of the line does not move any text, same as dash
    if #line > 0 then
      line[#line + 1] = { " ", "RenderEnvyCodeInfo" }
    end
    line[#line + 1] = { self.config.border_icon:rep(vim.o.columns), border_hl }
  end
  if #line == 0 then
    return
  end
  -- hidden by anti-conceal to show the raw delimiter on the cursor line
  self.marks:add(true, delim.start_row, delim:col(), {
    virt_text = line,
    virt_text_pos = "overlay",
  })
end

---@private
---@param node? render.envy.Node
---@param covered boolean
function Render:dim(node, covered)
  if not node then
    return
  end
  -- off the cursor line an overlay covers the delimiter -> only dimmed
  local delimiters = self.config.delimiters
  if covered and delimiters == "hide" then
    delimiters = "dim"
  end
  self:delimiter(delimiters, node.start_row, node:col(), node.end_col, "RenderEnvyCodeDim")
end

---@private
---@param delim? render.envy.Node
---@return [string, string][]?, string?
function Render:language(delim)
  local info = self.node:child("info_string")
  local language = info and info:child("language")
  if not self.config.language_icon or not info or not language or not delim then
    return
  end

  local icon, icon_hl = icons.get(language.text)
  if self.config.highlight_language then
    icon_hl = self.config.highlight_language
  end
  self:sign(self.config.sign, icon, icon_hl)
  local language_hl = icon_hl or "RenderEnvyCodeFallback"

  -- not in upstream: the raw info string keeps the overlay colors when
  -- anti-conceal hides the overlay -> no color change on the cursor line
  self.marks:add(false, language.start_row, language.start_col, {
    end_col = language.end_col,
    hl_group = language_hl,
  })
  if info.end_col > language.end_col then
    self.marks:add(false, info.start_row, language.end_col, {
      end_col = info.end_col,
      hl_group = "RenderEnvyCodeInfo",
    })
  end

  -- overlay starts at the delimiter and covers it and the info string, every
  -- character of the info string stays in place -> no layout shift, the icon
  -- is centred in the space of the delimiter before the language
  local col = delim:col()
  local _, text = self.node:line("first", 0)
  local before = str.width((text or ""):sub(col + 1, language.start_col))
  local width = str.width(icon)
  -- an icon wider than the delimiter would cover the language -> no icon
  if not icon or width > before then
    icon, width = "", 0
  end
  local left = math.floor((before - width) / 2)

  local offset = info.start_col
  ---@type [string, string][]
  local line = {
    { str.pad(left), "RenderEnvyCodeInfo" },
    { icon, language_hl },
    { str.pad(before - width - left), "RenderEnvyCodeInfo" },
    { language.text, language_hl },
    { info.text:sub(language.end_col - offset + 1), "RenderEnvyCodeInfo" },
  }
  return line, language_hl
end

return Render
