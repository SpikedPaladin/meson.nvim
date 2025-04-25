---@class Config
local M = {}

---@class DefaultOptions
M.defaults = {
    autoload = true,
    workdir = vim.fn.stdpath("data") .. "/meson"
}

---@class Options
M.options = {}

---Extend the defaults options table with the user options
---@param opts UserOptions: plugin options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
