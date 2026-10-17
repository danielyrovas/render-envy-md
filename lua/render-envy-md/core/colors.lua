-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

---@class render.envy.Colors
local M = {}

---@private
M.prefix = "RenderEnvy"

-- stylua: ignore
-- @see :h highlight-groups
-- @see :h treesitter-highlight-groups
---@private
---@type table<string, string>
M.colors = {
  Bullet = "Normal",
  CodeInfo = "@label",
  CodeFallback = "Normal",
  Dash = "LineNr",
  H1 = "@markup.heading.1.markdown",
  H2 = "@markup.heading.2.markdown",
  H3 = "@markup.heading.3.markdown",
  H4 = "@markup.heading.4.markdown",
  H5 = "@markup.heading.5.markdown",
  H6 = "@markup.heading.6.markdown",
  InlineHighlight = "Visual",
  Quote = "@markup.quote",
  Quote1 = "RenderEnvyQuote",
  Quote2 = "RenderEnvyQuote",
  Quote3 = "RenderEnvyQuote",
  Quote4 = "RenderEnvyQuote",
  Quote5 = "RenderEnvyQuote",
  Quote6 = "RenderEnvyQuote",
  Sign = "SignColumn",
  Success = "DiagnosticOk",
  Info = "DiagnosticInfo",
  Hint = "DiagnosticHint",
  Warn = "DiagnosticWarn",
  Error = "DiagnosticError",
  DashMetadata = "@keyword.directive.markdown",
  WikiLink = "@markup.link.label.markdown_inline",
}

-- stylua: ignore
-- only the foreground is used, color schemes often make Comment italic
---@private
---@type table<string, string>
M.dims = {
  CodeDim = "Comment",
  EmphasisDim = "Comment",
  HeadingDim = "Comment",
  InlineHighlightDim = "Comment",
  WikiLinkDim = "Comment",
  LinkDim = "Comment",
  StrikethroughDim = "Comment",
}

-- not in upstream
-- dims that replace the text attributes below them instead of adding to them,
-- treesitter strikes through the delimiters too
---@private
---@type table<string, boolean>
M.nocombine = {
  StrikethroughDim = true,
}

-- not in upstream
-- only text attributes, the color comes from treesitter
---@private
---@type table<string, vim.api.keyset.highlight>
M.styles = {
  H1Text = { bold = true, underline = true },
  H2Text = {},
  H3Text = {},
  H4Text = {},
  H5Text = {},
  H6Text = {},
  Strikethrough = { strikethrough = true },
}

---@private
---@type table<string, { fg: string, bg: string }>
M.combined = {}

---@private
---@type table<string, { hl: string, amount: number, background?: string }>
M.blended = {}

---called from manager on the first attach
function M.init()
  M.apply()
  -- color schemes clear highlights, including our default links
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("RenderEnvyColors", {}),
    callback = M.apply,
  })
end

---@private
function M.apply()
  for name, link in pairs(M.colors) do
    vim.api.nvim_set_hl(0, M.prefix .. name, {
      link = link,
      default = true,
    })
  end
  for name, style in pairs(M.styles) do
    vim.api.nvim_set_hl(0, M.prefix .. name, vim.tbl_extend("force", style, { default = true }))
  end
  for name, source in pairs(M.dims) do
    local hl = vim.api.nvim_get_hl(0, { name = source, link = false })
    vim.api.nvim_set_hl(0, M.prefix .. name, {
      fg = hl.fg,
      ctermfg = hl.ctermfg,
      nocombine = M.nocombine[name],
      default = true,
    })
  end
  -- generated colors are cleared too
  for _, color in pairs(M.combined) do
    M.combine(color.fg, color.bg, true)
  end
  for _, color in pairs(M.blended) do
    M.fade(color.hl, color.amount, color.background, true)
  end
end

---@param foreground string
---@param background string
---@param force? boolean
---@return string
function M.combine(foreground, background, force)
  local name = ("%s_%s_%s"):format(M.prefix, foreground, background)
  if not M.combined[name] or force then
    local fg = vim.api.nvim_get_hl(0, { name = foreground, link = false })
    local bg = vim.api.nvim_get_hl(0, { name = background, link = false })
    vim.api.nvim_set_hl(0, name, {
      fg = fg.fg,
      bg = bg.bg,
      ctermfg = fg.ctermfg,
      ctermbg = bg.ctermbg,
    })
    M.combined[name] = { fg = foreground, bg = background }
  end
  return name
end

-- not in upstream
---foreground of highlight blended toward the background by amount, with the
---background of an optional other highlight
---@param highlight string
---@param amount number
---@param background? string
---@param force? boolean
---@return string
function M.fade(highlight, amount, background, force)
  local percent = math.floor(amount * 100 + 0.5)
  local name = ("%s_%s_Fade%d"):format(M.prefix, highlight, percent)
  if background then
    name = ("%s_%s"):format(name, background)
  end
  if not M.blended[name] or force then
    local fg = vim.api.nvim_get_hl(0, { name = highlight, link = false })
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    local bg = background and vim.api.nvim_get_hl(0, { name = background, link = false }) or {}
    local from = fg.fg or normal.fg
    -- transparent color schemes have no background
    local to = normal.bg or (vim.o.background == "dark" and 0x000000 or 0xffffff)
    vim.api.nvim_set_hl(0, name, {
      fg = from and M.blend(from, to, amount),
      bg = bg.bg,
      ctermfg = bg.ctermfg or fg.ctermfg,
      ctermbg = bg.ctermbg,
    })
    M.blended[name] = { hl = highlight, amount = amount, background = background }
  end
  return name
end

---@private
---@param from integer
---@param to integer
---@param amount number
---@return integer
function M.blend(from, to, amount)
  local result = 0
  for _, shift in ipairs({ 16, 8, 0 }) do
    local a = bit.band(bit.rshift(from, shift), 0xff)
    local b = bit.band(bit.rshift(to, shift), 0xff)
    local c = math.floor(a + (b - a) * amount + 0.5)
    result = result + bit.lshift(c, shift)
  end
  return result
end

return M
