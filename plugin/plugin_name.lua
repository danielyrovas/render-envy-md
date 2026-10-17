if vim.g.loaded_plugin_name then
  return
end
vim.g.loaded_plugin_name = true

vim.api.nvim_create_user_command("PluginName", function()
  require("plugin_name").hello()
end, { desc = "Say hello from plugin_name" })
