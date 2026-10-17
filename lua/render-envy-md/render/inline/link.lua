-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local Base = require("render-envy-md.render.base")

---@class render.envy.render.inline.Link: render.envy.Render
---@field private config render.envy.link.inline.Config
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  local config = self.context.config.link
  self.config = config.inline
  if not config.enabled or not self.config.enabled then
    return false
  end
  -- [[page]](url) holds a WikiLink, which is rendered by the shortcut
  return not self.node:descendant("shortcut_link")
end

---@protected
function Render:run()
  -- unlike upstream nothing is concealed and there is no icon, only the syntax
  -- around the text is changed -> no layout shift
  local node = self.node
  local delimiters = self.config.delimiters
  if node.type == "uri_autolink" then
    -- '<' and '>', the url keeps its color
    self:dim(delimiters, node.start_row, node.start_col, node.start_row, node.start_col + 1)
    self:dim(delimiters, node.end_row, node.end_col - 1, node.end_row, node.end_col)
    return
  end
  -- '[' and ']' around the text, '(url "title")' after it
  local url = (node:child("link_destination") or node:child("link_title")) and node:child("(")
  local end_row, end_col = node.end_row, node.end_col
  if url then
    end_row, end_col = url.start_row, url.start_col
  end
  local text = node:child("link_text")
  if text then
    self:dim(delimiters, node.start_row, node.start_col, text.start_row, text.start_col)
    self:dim(delimiters, text.end_row, text.end_col, end_row, end_col)
  else
    self:dim(delimiters, node.start_row, node.start_col, end_row, end_col)
  end
  if url then
    self:dim(self.config.url, url.start_row, url.start_col, node.end_row, node.end_col)
  end
end

---@private
---@param delimiters render.envy.Delimiters
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
function Render:dim(delimiters, start_row, start_col, end_row, end_col)
  if start_row == end_row then
    self:delimiter(delimiters, start_row, start_col, end_col, "RenderEnvyLinkDim")
    return
  end
  -- spaces cannot cover syntax over more than one line -> only dimmed
  if not delimiters then
    return
  end
  self.marks:add(false, start_row, start_col, {
    end_row = end_row,
    end_col = end_col,
    hl_group = "RenderEnvyLinkDim",
  })
end

return Render
