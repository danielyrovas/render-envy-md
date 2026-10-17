-- Code adapted from render-markdown.nvim
-- Copyright (c) 2024 Vlad, MIT License (see NOTICE)

local icons = require("render-envy-md.lib.icons")
local state = require("render-envy-md.state")

---@class render.envy.Health
local M = {}

function M.check()
  M.start("versions")
  M.neovim("0.12")
  vim.health.ok("tree-sitter ABI: " .. vim.treesitter.language_version)

  M.start("configuration")
  M.signcolumn()

  M.ts_info("markdown", true)
  M.ts_info("markdown_inline", false)

  M.start("injections")
  M.injections()

  M.start("icons")
  local provider = icons.name()
  if provider then
    vim.health.ok("using: " .. provider)
  else
    vim.health.warn("none installed, code blocks have no language icon")
  end

  M.start("conflicts")
  M.plugin("render-markdown")
  M.plugin("markview")
  M.plugin("headlines")
  M.plugin("obsidian", function(obsidian)
    ---@diagnostic disable-next-line: undefined-global
    local client = Obsidian or obsidian.get_client()
    if client.opts.ui.enable == false then
      return nil
    end
    return [[
    disable the ui in your obsidian.nvim config
    require("obsidian").setup({
        ui = { enable = false },
    })
    ]]
  end)
end

---@private
---@param name string
function M.start(name)
  vim.health.start(("render-envy-md [%s]"):format(name))
end

---@private
---@param min string
function M.neovim(min)
  if vim.fn.has("nvim-" .. min) == 0 then
    vim.health.error("neovim < " .. min)
  else
    vim.health.ok("neovim >= " .. min)
  end
end

-- not in upstream
---@private
function M.signcolumn()
  -- top level config, the health buffer is 'nofile' and gets its override
  if not state.config.sign.enabled then
    vim.health.ok("sign: disabled")
  elseif vim.go.signcolumn == "auto" then
    vim.health.warn("signcolumn: auto, the column opens on the first sign and moves the text", {
      "set 'signcolumn' to 'yes', or disable signs",
    })
  else
    vim.health.ok("signcolumn: " .. vim.go.signcolumn)
  end
end

---@private
---@param language string
---@param active boolean
function M.ts_info(language, active)
  M.start("tree-sitter " .. language)

  local has_parser, parser = pcall(vim.treesitter.get_parser, 0, language)
  if has_parser and parser then
    vim.health.ok("parser: installed")
  else
    vim.health.error("parser: not installed")
  end

  local has_info, info = pcall(vim.treesitter.language.inspect, language)
  if has_info and info then
    vim.health.ok("ABI: " .. info.abi_version)
  else
    vim.health.error("ABI: unknown")
  end

  local files = vim.treesitter.query.get_files(language, "highlights")
  if #files > 0 then
    for _, file in ipairs(files) do
      vim.health.ok("highlights: " .. vim.fn.fnamemodify(file, ":~"))
    end
  else
    vim.health.error("highlights: unknown")
  end

  if active then
    -- create a temporary buffer to check if vim.treesitter.start gets called
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = language
    local ok = vim.treesitter.highlighter.active[buf] ~= nil
    vim.api.nvim_buf_delete(buf, { force = true })
    if ok then
      vim.health.ok("highlighter: enabled")
    else
      vim.health.error("highlighter: not enabled", {
        ("call vim.treesitter.start() on %s buffers"):format(language),
      })
    end
  end
end

-- not in upstream
---@private
function M.injections()
  local languages = vim.tbl_keys(state.injections) ---@type string[]
  table.sort(languages)
  for _, language in ipairs(languages) do
    if not state.injections[language].enabled then
      vim.health.ok(language .. ": disabled")
    elseif not vim.tbl_contains(state.file_types, language) then
      vim.health.info(language .. ": not in file_types, add it to render markdown in " .. language)
    elseif not vim.treesitter.language.add(language) then
      vim.health.warn(language .. ": parser not installed")
    else
      vim.health.ok(language .. ": injected")
    end
  end
end

---@private
---@param name string
---@param validate? fun(plugin: any): string?
function M.plugin(name, validate)
  local has_plugin, plugin = pcall(require, name) ---@type boolean, any
  if not has_plugin then
    vim.health.ok(name .. ": not installed")
  elseif not validate then
    vim.health.error(name .. ": installed")
  else
    local advice = validate(plugin)
    if advice then
      vim.health.error(name .. ": installed", M.trim(advice))
    else
      vim.health.ok(name .. ": installed but should not conflict")
    end
  end
end

---@private
---@param s string
---@return string
function M.trim(s)
  return (s:gsub("%s+$", ""))
end

return M
