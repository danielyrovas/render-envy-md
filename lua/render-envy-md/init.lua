-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local settings = require("render-envy-md.settings")

---@class render.envy.Init
local M = {}

---@class (exact) render.envy.Config: render.envy.partial.Config, render.envy.state.Config

---@class (exact) render.envy.partial.Config: render.envy.base.Config
---@field render_modes render.envy.Modes
---@field debounce integer
---@field anti_conceal render.envy.anti.conceal.Config
---@field sign render.envy.sign.Config
---@field bullet render.envy.bullet.Config
---@field callout render.envy.callout.Configs
---@field code render.envy.code.Config
---@field dash render.envy.dash.Config
---@field emphasis render.envy.emphasis.Config
---@field heading render.envy.heading.Config
---@field inline_highlight render.envy.inline.highlight.Config
---@field link render.envy.link.Config
---@field quote render.envy.quote.Config
---@field strikethrough render.envy.strikethrough.Config

---@class (exact) render.envy.state.Config
---@field file_types string[]
---@field max_file_size number
---@field injections render.envy.injection.Configs
---@field overrides render.envy.overrides.Config

---@class (exact) render.envy.overrides.Config
---@field buftype table<string, render.envy.partial.UserConfig>
---@field filetype table<string, render.envy.partial.UserConfig>

---@private
---@type boolean
M.initialized = false

---@type render.envy.Config
M.default = {
  -- Whether markdown should be rendered by default.
  enabled = true,
  -- Vim modes that will show a rendered view of the markdown file, :h mode().
  -- true renders in every mode so changing mode never moves the text, concealed
  -- text is shown with anti_conceal.reveal_modes instead. A list is matched
  -- against the full mode and its family, i.e. 'i' also matches 'ic', 'R' and
  -- 'niI', 'n' matches 'no', 'v' matches 's'. Remaining modes are unaffected.
  render_modes = true,
  -- Milliseconds that must pass before updating marks, updates occur
  -- within the context of the visible window, not the entire buffer.
  debounce = 100,
  -- Filetypes this plugin will run on.
  file_types = { "markdown", "gitcommit" },
  -- Maximum file size (in MB) that this plugin will attempt to render.
  -- File larger than this will effectively be ignored.
  max_file_size = 10.0,
  injections = settings.injections.default,
  -- Configuration for some buffers only. Values not set use the top level
  -- configuration, filetype is applied after buftype. Supports all fields
  -- except file_types, max_file_size and overrides.
  overrides = {
    -- Override for buffers with this 'buftype'. Floating windows such as LSP
    -- hover are 'nofile', a sign column would move and wrap their text.
    buftype = {
      nofile = {
        sign = { enabled = false },
      },
    },
    -- Override for buffers with this 'filetype'.
    filetype = {},
  },
  anti_conceal = settings.anti_conceal.default,
  sign = settings.sign.default,
  bullet = settings.bullet.default,
  callout = settings.callout.default,
  code = settings.code.default,
  dash = settings.dash.default,
  emphasis = settings.emphasis.default,
  heading = settings.heading.default,
  inline_highlight = settings.inline_highlight.default,
  link = settings.link.default,
  quote = settings.quote.default,
  strikethrough = settings.strikethrough.default,
}

---@param opts? render.envy.UserConfig
function M.setup(opts)
  -- This handles discrepancies in initialization order of different plugin managers, some
  -- run the plugin directory first (lazy.nvim) while others run setup first (vim-plug).
  -- To support both we want to pickup the last non-empty configuration. This works because
  -- the plugin directory supplies an empty configuration which will be skipped if state
  -- has already been initialized by the user.
  if M.initialized and vim.tbl_count(opts or {}) == 0 then
    return
  end
  M.initialized = true
  local config = vim.tbl_deep_extend("force", M.default, opts or {})
  require("render-envy-md.state").setup(config)
  -- re-render buffers that were attached using the previous configuration
  local manager = package.loaded["render-envy-md.core.manager"]
  if manager then
    manager.refresh()
  end
end

return M
