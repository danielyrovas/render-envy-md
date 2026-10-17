if vim.g.loaded_render_envy_md then
  return
end
vim.g.loaded_render_envy_md = true

-- the ui and highlights are loaded by the manager when the first supported buffer attaches
require("render-envy-md").setup(vim.g.render_envy_md_config)
require("render-envy-md.core.command").init()
require("render-envy-md.core.manager").init()
