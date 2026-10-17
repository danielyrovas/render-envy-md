if vim.g.loaded_render_envy_md then
  return
end
vim.g.loaded_render_envy_md = true

vim.api.nvim_create_user_command("RenderEnvy", function()
  require("render-envy-md").hello()
end, { desc = "Say hello from render-envy-md" })
