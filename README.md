# render-envy-md

Another Neovim plugin for rendering markdown. This is highly _opinionated_, focussing on reducing **layout shift**. Much of the code is ported from [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim).

Tested with Neovim v12+

## Installation

Requirements:

- The `markdown` and `markdown_inline` treesitter parsers.
- Optional: [mini.icons](https://github.com/echasnovski/mini.icons) or [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) for code block language icons.

With `vim.pack`:

```lua
vim.pack.add({ "https://github.com/danielyrovas/render-envy-md" })
-- call setup to configure
-- require("render-envy-md").setup({ file_types = { "markdown" } })
```

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "danielyrovas/render-envy-md",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  -- add opts {} to configure
}
```

## Configuration

Calling `setup` is only needed if you want to change the defaults

### Defaults

`delimiters`
- `"hide"`: Replace the syntax with spaces. On the cursor line the syntax is
  shown and dimmed.
- `"dim"`: Always show the syntax with a dim colour.
- `false`: Do not change the syntax.

```lua
{
  -- Render markdown when a buffer is opened.
  enabled = true,
  -- Vim modes that show the rendered view, see :h mode(). true is every mode.
  -- A list also matches related modes, i.e. "i" matches insert completion and
  -- replace, "n" matches operator pending and "v" matches select.
  render_modes = true,
  -- Milliseconds to wait after a change before the view updates.
  debounce = 100,
  -- Filetypes to attach to.
  file_types = { "markdown", "gitcommit" },
  -- Files larger than this (in MB) are not rendered.
  max_file_size = 10.0,

  -- Render markdown inside other filetypes, see :h treesitter-language-injections.
  -- Only used for filetypes in file_types.
  injections = {
    gitcommit = {
      enabled = true,
      query = [[
        ((message) @injection.content
          (#set! injection.combined)
          (#set! injection.include-children)
          (#set! injection.language "markdown"))
      ]],
    },
  },

  -- Settings for some buffers only. They take any setting except file_types,
  -- max_file_size and overrides. filetype is applied after buftype.
  overrides = {
    -- Floating windows such as LSP hover are 'nofile'. A sign column would
    -- move and wrap their text.
    buftype = {
      nofile = {
        sign = { enabled = false },
      },
    },
    -- i.e. filetype = { markdown = { code = { line_numbers = false } } }
    filetype = {},
  },

  anti_conceal = {
    -- Show raw text on the cursor line.
    enabled = true,
    -- Extra lines around the cursor that also show raw text.
    lines_above = 0,
    lines_below = 0,
    -- Modes that show raw text on every line.
    reveal_modes = { "i", "v", "V", "\22" },
  },

  sign = {
    -- Show signs in the sign column
    enabled = true,
  },

  bullet = {
    enabled = true,
    -- List icons, cycles in order
    icons = { "●", "○", "◆", "◇" },
  },

  callout = {
    note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderEnvyInfo" },
    -- GitHub: tip, important, warning, caution
    -- Obsidian: abstract, summary, tldr, info, todo, hint, success, check,
    --   done, question, help, faq, attention, failure, fail, missing,
    --   danger, error, bug, example, quote, cite
  },

  code = {
    enabled = true,
    -- Show the language icon in the sign column.
    sign = true,
    -- Replace the opening fence with the language icon, i.e. '```lua' -> ' 󰢱 lua'.
    language_icon = true,
    -- Colour for the language icon and name, in place of the icon provider colour.
    highlight_language = nil,
    -- Replace the fences with a full width line.
    border = true,
    border_icon = "─",
    -- Colour for the border, in place of the faded language colour.
    highlight_border = nil,
    -- The fences. "hide" only applies when there is no icon or border.
    delimiters = "dim",
    -- Colour the line numbers of the block.
    line_numbers = true,
    -- Colour for the line numbers, in place of the faded language colour.
    highlight_line_numbers = nil,
    -- Blend the border towards the background colour.
    language_color_fade = 0.35,
  },

  dash = {
    enabled = true,
    -- Replaces '---', '***', '___' and front matter fences with a full width line.
    icon = "─",
  },

  emphasis = {
    -- *italic*, _italic_ and **bold**.
    enabled = true,
    delimiters = "dim",
  },

  heading = {
    enabled = true,
    -- Show a sign.
    sign = true,
    -- Cycled by level.
    signs = { "󰫎 " },
    -- Replace the '#'s and the space after them, i.e. '### title' -> '  󰲥 title'.
    -- Cycled by level. Use { "# " } for a '#', or {} for no icon.
    icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    delimiters = "dim", -- only applied when not using an icon
  },

  inline_highlight = {
    -- ==text==
    enabled = true,
    delimiters = "hide",
  },

  link = {
    enabled = true,
    -- [text](url) and <url>.
    inline = {
      enabled = true,
      -- The '[' and ']', or '<' and '>'.
      delimiters = "dim",
      -- The '(url "title")' part.
      url = "dim",
    },
    -- [[page]] and [[page|alias]].
    wiki = {
      enabled = true,
      -- Replaces '[['
      icon = "󱗖 ",
      delimiters = "dim",
      -- The 'page|' part of an alias.
      alias = "dim",
    },
  },

  quote = {
    enabled = true,
    -- Replaces '>'. A list is cycled by nesting level.
    icon = "▋",
  },

  strikethrough = {
    -- ~text~
    enabled = true,
    delimiters = "hide",
  },
}
```

## Free Software

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <https://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <https://opensource.org/licenses/MIT>)

at your option.

The Software is provided “as is”, without warranty of any kind. In no event shall the authors or copyright holders be liable for any claim, damages or other liability in connection with the Software.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
