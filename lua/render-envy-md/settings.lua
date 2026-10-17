-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

---@class render.envy.Settings
local M = {}

---@class render.envy.base.Settings
M.base = {}

---@class (exact) render.envy.base.Config
---@field enabled boolean

---@alias render.envy.Modes boolean|string[]

-- not in upstream: how markdown syntax around text is shown, 'hide' overlays
-- it with spaces off the cursor line and dims it on the cursor line, 'dim'
-- always dims it, false leaves it alone. The line width never changes.
---@alias render.envy.Delimiters "hide"|"dim"|false

---@class render.envy.anti.conceal.Settings
M.anti_conceal = {}

---@class (exact) render.envy.anti.conceal.Config
---@field enabled boolean
---@field lines_above integer
---@field lines_below integer
---@field reveal_modes render.envy.Modes

---@type render.envy.anti.conceal.Config
M.anti_conceal.default = {
  -- This enables hiding marks that conceal text on the lines around the cursor.
  -- Marks that cover text with the same width, i.e. bullets, are shown on the
  -- cursor line, hidden in reveal_modes and under the cursor.
  enabled = true,
  -- Number of lines above cursor to show.
  lines_above = 0,
  -- Number of lines below cursor to show.
  lines_below = 0,
  -- Vim modes that show concealed text on every line, not only around the cursor.
  -- Marks that do not hide any text, i.e. dimmed brackets, are still shown.
  -- Bullets and quote markers are hidden too.
  reveal_modes = { "i", "v", "V", "\22" },
}

---@class render.envy.injections.Settings
M.injections = {}

---@alias render.envy.injection.Configs table<string, render.envy.injection.Config>

---@class (exact) render.envy.injection.Config
---@field enabled boolean
---@field query string

---@type render.envy.injection.Configs
M.injections.default = {
  -- Language injections for known filetypes that allow markdown to be
  -- interpreted in specified locations, see :h treesitter-language-injections.
  -- Only applied to filetypes in file_types. Set enabled to false in order to
  -- disable.

  gitcommit = {
    enabled = true,
    query = [[
      ((message) @injection.content
        (#set! injection.combined)
        (#set! injection.include-children)
        (#set! injection.language "markdown"))
    ]],
  },
}

---@class render.envy.bullet.Settings
M.bullet = {}

---@class (exact) render.envy.bullet.Config: render.envy.base.Config
---@field icons render.envy.bullet.String

---@class (exact) render.envy.bullet.Context
---@field level integer
---@field index integer
---@field value string

---@alias render.envy.bullet.String
---| string
---| string[]
---| string[][]
---| fun(ctx: render.envy.bullet.Context): string?

---@type render.envy.bullet.Config
M.bullet.default = {
  -- Useful context to have when evaluating values.
  -- | level | how deeply nested the list is, 1-indexed          |
  -- | index | how far down the item is at that level, 1-indexed |
  -- | value | text value of the marker node                     |

  -- Turn on / off list bullet rendering.
  enabled = true,
  -- Replaces '-'|'+'|'*' of 'list_item', ordered list markers are left alone.
  -- The icon is overlaid on the marker so the line width never changes, icons
  -- wider than the marker (including its trailing space) are not rendered.
  -- Output is evaluated depending on the type.
  -- | function   | `value(context)`                                    |
  -- | string     | `value`                                             |
  -- | string[]   | `cycle(value, context.level)`                       |
  -- | string[][] | `clamp(cycle(value, context.level), context.index)` |
  icons = { "●", "○", "◆", "◇" },
}

---@class render.envy.callout.Settings
M.callout = {}

---@alias render.envy.callout.Configs table<string, render.envy.callout.Config>

---@class (exact) render.envy.callout.Config
---@field raw string
---@field rendered string
---@field highlight string
---@field quote_icon? string

-- stylua: ignore
---@type render.envy.callout.Configs
M.callout.default = {
  -- Callouts are a special instance of a 'block_quote' that start with a 'shortcut_link'.
  -- The key is to allow users to change its values, value type below.
  -- | raw        | matched against the raw text of a 'shortcut_link', case insensitive |
  -- | rendered   | overlaid on the 'raw' value, padded with spaces to its width        |
  -- | highlight  | highlight for the 'rendered' text and quote markers                 |
  -- | quote_icon | optional override for quote.icon value for individual callout       |
  -- A 'rendered' value wider than 'raw' is not rendered, the raw value is shown
  -- with the highlight. Unlike upstream a custom title is not concealed, the
  -- 'rendered' value is shown before it.

  -- GitHub
  note      = { raw = "[!NOTE]",      rendered = "󰋽 Note",      highlight = "RenderEnvyInfo"    },
  tip       = { raw = "[!TIP]",       rendered = "󰌶 Tip",       highlight = "RenderEnvySuccess" },
  important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderEnvyHint"    },
  warning   = { raw = "[!WARNING]",   rendered = "󰀪 Warning",   highlight = "RenderEnvyWarn"    },
  caution   = { raw = "[!CAUTION]",   rendered = "󰳦 Caution",   highlight = "RenderEnvyError"   },
  -- Obsidian: https://help.obsidian.md/Editing+and+formatting/Callouts
  abstract  = { raw = "[!ABSTRACT]",  rendered = "󰨸 Abstract",  highlight = "RenderEnvyInfo"    },
  summary   = { raw = "[!SUMMARY]",   rendered = "󰨸 Summary",   highlight = "RenderEnvyInfo"    },
  tldr      = { raw = "[!TLDR]",      rendered = "󰨸 Tldr",      highlight = "RenderEnvyInfo"    },
  info      = { raw = "[!INFO]",      rendered = "󰋽 Info",      highlight = "RenderEnvyInfo"    },
  todo      = { raw = "[!TODO]",      rendered = "󰗡 Todo",      highlight = "RenderEnvyInfo"    },
  hint      = { raw = "[!HINT]",      rendered = "󰌶 Hint",      highlight = "RenderEnvySuccess" },
  success   = { raw = "[!SUCCESS]",   rendered = "󰄬 Success",   highlight = "RenderEnvySuccess" },
  check     = { raw = "[!CHECK]",     rendered = "󰄬 Check",     highlight = "RenderEnvySuccess" },
  done      = { raw = "[!DONE]",      rendered = "󰄬 Done",      highlight = "RenderEnvySuccess" },
  question  = { raw = "[!QUESTION]",  rendered = "󰘥 Question",  highlight = "RenderEnvyWarn"    },
  help      = { raw = "[!HELP]",      rendered = "󰘥 Help",      highlight = "RenderEnvyWarn"    },
  faq       = { raw = "[!FAQ]",       rendered = "󰘥 Faq",       highlight = "RenderEnvyWarn"    },
  attention = { raw = "[!ATTENTION]", rendered = "󰀪 Attention", highlight = "RenderEnvyWarn"    },
  failure   = { raw = "[!FAILURE]",   rendered = "󰅖 Failure",   highlight = "RenderEnvyError"   },
  fail      = { raw = "[!FAIL]",      rendered = "󰅖 Fail",      highlight = "RenderEnvyError"   },
  missing   = { raw = "[!MISSING]",   rendered = "󰅖 Missing",   highlight = "RenderEnvyError"   },
  danger    = { raw = "[!DANGER]",    rendered = "󱐌 Danger",    highlight = "RenderEnvyError"   },
  error     = { raw = "[!ERROR]",     rendered = "󱐌 Error",     highlight = "RenderEnvyError"   },
  bug       = { raw = "[!BUG]",       rendered = "󰨰 Bug",       highlight = "RenderEnvyError"   },
  example   = { raw = "[!EXAMPLE]",   rendered = "󰉹 Example",   highlight = "RenderEnvyHint"    },
  quote     = { raw = "[!QUOTE]",     rendered = "󱆨 Quote",     highlight = "RenderEnvyQuote"   },
  cite      = { raw = "[!CITE]",      rendered = "󱆨 Cite",      highlight = "RenderEnvyQuote"   },
}

---@class render.envy.sign.Settings
M.sign = {}

---@class (exact) render.envy.sign.Config
---@field enabled boolean

---@type render.envy.sign.Config
M.sign.default = {
  -- Turn on / off sign rendering.
  -- The sign column opens on the first sign if 'signcolumn' is 'auto', which
  -- moves the text, set it to 'yes' to keep the layout fixed.
  enabled = true,
}

---@class render.envy.code.Settings
M.code = {}

---@class (exact) render.envy.code.Config: render.envy.base.Config
---@field sign boolean
---@field language_icon boolean
---@field highlight_language? string
---@field border boolean
---@field border_icon string
---@field highlight_border? string
---@field delimiters render.envy.Delimiters
---@field line_numbers boolean
---@field highlight_line_numbers? string
---@field language_color_fade number

---@type render.envy.code.Config
M.code.default = {
  -- Turn on / off code block rendering.
  enabled = true,
  -- Turn on / off sign column related rendering, shows the language icon.
  sign = true,
  -- Overlays the icon of the language on the top delimiter, i.e. '```lua' ->
  -- ' 󰢱 lua'. The icon is centred in the space of the delimiter, the language
  -- stays in place. Icons wider than the delimiter are not rendered, only the
  -- delimiter is covered. Hidden on the cursor line.
  -- Unlike upstream there is no background and the delimiters are not concealed.
  language_icon = true,
  -- Highlight for the language icon and name, overrides the icon provider.
  highlight_language = nil,
  -- Overlays a line over the full width of the window on the bottom delimiter,
  -- and on the top delimiter one space after the info string. Without a
  -- language the line covers all of the top delimiter. Hidden on the cursor line.
  border = true,
  -- Repeated to make the border line.
  border_icon = "─",
  -- Highlight for the border line, overrides the faded language color.
  highlight_border = nil,
  -- The fences and info string under the icon and border, see Delimiters.
  -- 'hide' only applies when there is no icon or border to cover them.
  delimiters = "dim",
  -- Colors the line numbers of all rows of the block, delimiters included.
  -- Not in upstream. Hidden on the cursor row to keep 'CursorLineNr'.
  line_numbers = true,
  -- Highlight for the line numbers, overrides the faded language color.
  highlight_line_numbers = nil,
  -- The border and number color is the language color, blended toward the
  -- background by this amount, 0 is the language color and 1 is the background.
  -- Not in upstream.
  language_color_fade = 0.35,
}

---@class render.envy.dash.Settings
M.dash = {}

---@class (exact) render.envy.dash.Config: render.envy.base.Config
---@field icon string

---@type render.envy.dash.Config
M.dash.default = {
  -- Turn on / off thematic break rendering.
  enabled = true,
  -- Replaces '---'|'***'|'___' of 'thematic_break' and the top and bottom
  -- delimiters of front matter, i.e. 'minus_metadata' and 'plus_metadata'.
  -- Repeated over the full width of the window. Hidden on the cursor line to
  -- show the raw text.
  icon = "─",
}

---@class render.envy.emphasis.Settings
M.emphasis = {}

---@class (exact) render.envy.emphasis.Config: render.envy.base.Config
---@field delimiters render.envy.Delimiters

-- not in upstream
---@type render.envy.emphasis.Config
M.emphasis.default = {
  -- Turn on / off emphasis rendering, i.e. *italic*, _italic_ and **bold**.
  enabled = true,
  -- The '*', '_' and '**' around the text, see Delimiters.
  delimiters = "dim",
}

---@class render.envy.heading.Settings
M.heading = {}

---@class (exact) render.envy.heading.Config: render.envy.base.Config
---@field sign boolean
---@field signs string[]
---@field icons string[]
---@field delimiters render.envy.Delimiters

---@type render.envy.heading.Config
M.heading.default = {
  -- Turn on / off heading rendering, both atx ('# title') and setext ('title'
  -- above '===' or '---'). Setext headings only get the sign.
  enabled = true,
  -- Turn on / off sign column related rendering.
  sign = true,
  -- Added to the sign column if enabled.
  -- Output is evaluated by `cycle(value, level)`.
  signs = { "󰫎 " },
  -- Overlaid on the right of the atx marker and the space after it, before the
  -- heading text, i.e. '### title' -> '  󰲥 title'. The width of the line does
  -- not change. Unlike upstream the marker is not concealed. Hidden on the
  -- cursor line to show the raw marker. Icons wider than the marker and its
  -- space are not rendered. Use { "# " } for a '#' or {} for no icon.
  -- Output is evaluated by `cycle(value, level)`.
  icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
  -- The '#'s before the last one, see Delimiters. 'hide' only applies when
  -- there is no icon to cover them.
  delimiters = "dim",
}

---@class render.envy.inline.highlight.Settings
M.inline_highlight = {}

---@class (exact) render.envy.inline.highlight.Config: render.envy.base.Config
---@field delimiters render.envy.Delimiters

---@type render.envy.inline.highlight.Config
M.inline_highlight.default = {
  -- Mimics Obsidian inline highlights when content is surrounded by double
  -- equals. Not in upstream: the equals are dimmed, not concealed.

  -- Turn on / off inline highlight rendering.
  enabled = true,
  -- The '==' around the text, see Delimiters.
  delimiters = "hide",
}

---@class render.envy.quote.Settings
M.quote = {}

---@class (exact) render.envy.quote.Config: render.envy.base.Config
---@field icon string|string[]

---@type render.envy.quote.Config
M.quote.default = {
  -- Turn on / off block quote & callout rendering.
  enabled = true,
  -- Overlaid on '>' of 'block_quote'. The width does not change so it is
  -- shown on the cursor line, hidden in anti_conceal.reveal_modes and under
  -- the cursor so a block cursor is not cut. Icons wider than '>' are not
  -- rendered.
  -- If a list is provided output is evaluated by `cycle(value, level)`.
  icon = "▋",
}

---@class render.envy.link.Settings
M.link = {}

---@class (exact) render.envy.link.Config: render.envy.base.Config
---@field inline render.envy.link.inline.Config
---@field wiki render.envy.link.wiki.Config

---@class (exact) render.envy.link.inline.Config: render.envy.base.Config
---@field delimiters render.envy.Delimiters
---@field url render.envy.Delimiters

---@class (exact) render.envy.link.wiki.Config: render.envy.base.Config
---@field icon string
---@field delimiters render.envy.Delimiters
---@field alias render.envy.Delimiters

---@type render.envy.link.Config
M.link.default = {
  -- Turn on / off inline link rendering.
  enabled = true,
  -- How to handle inline links and autolinks, i.e. [text](url) and <url>.
  -- Images and reference links are left alone.
  inline = {
    -- Turn on / off inline link rendering.
    enabled = true,
    -- The '[' and ']' of an inline link, or the '<' and '>' of an
    -- autolink, see Delimiters. 'hide' only covers syntax on one line.
    delimiters = "dim",
    -- The '(url "title")' of an inline link, see Delimiters. The url of an
    -- autolink is its text and is left alone.
    url = "dim",
  },
  -- How to handle WikiLinks, i.e. [[page]] and [[page|alias]].
  wiki = {
    -- Turn on / off WikiLink rendering.
    enabled = true,
    -- Overlaid on the opening '[[' unless delimiters is false, padded with
    -- spaces to its width. Icons wider than the brackets are not rendered.
    icon = "󱗖 ",
    -- The '[[' and ']]', see Delimiters.
    delimiters = "hide",
    -- The 'page|' before the alias of [[page|alias]], see Delimiters.
    alias = "dim",
  },
}

---@class render.envy.strikethrough.Settings
M.strikethrough = {}

---@class (exact) render.envy.strikethrough.Config: render.envy.base.Config
---@field delimiters render.envy.Delimiters

-- not in upstream
---@type render.envy.strikethrough.Config
M.strikethrough.default = {
  -- Turn on / off strikethrough rendering, i.e. ~~text~~ and ~text~.
  enabled = true,
  -- The '~' or '~~' around the text, see Delimiters.
  delimiters = "hide",
}

return M
