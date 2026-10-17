---@meta

-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

---@class (exact) render.envy.UserConfig: render.envy.partial.UserConfig
---@field file_types? string[]
---@field max_file_size? number
---@field injections? table<string, render.envy.injection.UserConfig>
---@field overrides? render.envy.overrides.UserConfig

---@class (exact) render.envy.injection.UserConfig
---@field enabled? boolean
---@field query? string

---@class (exact) render.envy.overrides.UserConfig
---@field buftype? table<string, render.envy.partial.UserConfig>
---@field filetype? table<string, render.envy.partial.UserConfig>

---@class (exact) render.envy.partial.UserConfig: render.envy.base.UserConfig
---@field render_modes? render.envy.Modes
---@field debounce? integer
---@field anti_conceal? render.envy.anti.conceal.UserConfig
---@field sign? render.envy.sign.UserConfig
---@field bullet? render.envy.bullet.UserConfig
---@field callout? render.envy.callout.UserConfigs
---@field code? render.envy.code.UserConfig
---@field dash? render.envy.dash.UserConfig
---@field emphasis? render.envy.emphasis.UserConfig
---@field heading? render.envy.heading.UserConfig
---@field inline_highlight? render.envy.inline.highlight.UserConfig
---@field link? render.envy.link.UserConfig
---@field quote? render.envy.quote.UserConfig
---@field strikethrough? render.envy.strikethrough.UserConfig

---@class (exact) render.envy.base.UserConfig
---@field enabled? boolean

---@class (exact) render.envy.anti.conceal.UserConfig
---@field enabled? boolean
---@field lines_above? integer
---@field lines_below? integer
---@field reveal_modes? render.envy.Modes

---@class (exact) render.envy.sign.UserConfig
---@field enabled? boolean

---@class (exact) render.envy.bullet.UserConfig: render.envy.base.UserConfig
---@field icons? render.envy.bullet.String

---@alias render.envy.callout.UserConfigs table<string, render.envy.callout.UserConfig>

---@class (exact) render.envy.callout.UserConfig
---@field raw? string
---@field rendered? string
---@field highlight? string
---@field quote_icon? string

---@class (exact) render.envy.code.UserConfig: render.envy.base.UserConfig
---@field sign? boolean
---@field language_icon? boolean
---@field highlight_language? string
---@field border? boolean
---@field border_icon? string
---@field highlight_border? string
---@field delimiters? render.envy.Delimiters
---@field line_numbers? boolean
---@field highlight_line_numbers? string
---@field language_color_fade? number

---@class (exact) render.envy.dash.UserConfig: render.envy.base.UserConfig
---@field icon? string

---@class (exact) render.envy.emphasis.UserConfig: render.envy.base.UserConfig
---@field delimiters? render.envy.Delimiters

---@class (exact) render.envy.heading.UserConfig: render.envy.base.UserConfig
---@field sign? boolean
---@field signs? string[]
---@field icons? string[]
---@field delimiters? render.envy.Delimiters

---@class (exact) render.envy.inline.highlight.UserConfig: render.envy.base.UserConfig
---@field delimiters? render.envy.Delimiters

---@class (exact) render.envy.quote.UserConfig: render.envy.base.UserConfig
---@field icon? string|string[]

---@class (exact) render.envy.link.UserConfig:render.envy.base.UserConfig
---@field inline? render.envy.link.inline.UserConfig
---@field wiki? render.envy.link.wiki.UserConfig

---@class (exact) render.envy.link.inline.UserConfig: render.envy.base.UserConfig
---@field delimiters? render.envy.Delimiters
---@field url? render.envy.Delimiters

---@class (exact) render.envy.link.wiki.UserConfig: render.envy.base.UserConfig
---@field icon? string
---@field delimiters? render.envy.Delimiters
---@field alias? render.envy.Delimiters

---@class (exact) render.envy.strikethrough.UserConfig: render.envy.base.UserConfig
---@field delimiters? render.envy.Delimiters
