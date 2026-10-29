local Base = require("render-envy-md.render.base")

-- not in upstream
---@class render.envy.render.inline.Tag: render.envy.Render
---@field private config render.envy.tag.Config
local Render = setmetatable({}, Base)
Render.__index = Render

---@protected
---@return boolean
function Render:setup()
  self.config = self.context.config.tag
  return self.config.enabled
end

---@protected
function Render:run()
  -- '#' after a non tag character or the start, then a letter, i.e. '#idea',
  -- not 'a#b', '/#b', '##', '# title' or '#1'
  for _, range in ipairs(self.node:find("%f[#%w_/%-]#[%a_][%w_/%-]*")) do
    if self:top_level(range[1], range[2]) then
      self.marks:add(false, range[1], range[2], {
        end_row = range[3],
        end_col = range[4],
        hl_group = "RenderEnvyTag",
      })
    end
  end
end

---@private
---@param row integer
---@param col integer
---@return boolean
function Render:top_level(row, col)
  local node = vim.treesitter.get_node({
    bufnr = self.context.buf,
    pos = { row, col },
    ignore_injections = false,
  })
  return node and node:type() == "inline" or false
end

return Render
