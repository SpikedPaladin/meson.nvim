local M = {}

---Validate the options table obtained from merging defaults and user options
local function validate_opts_table()
  local opts = require("meson.config").options

  local ok, err = pcall(function()
    vim.validate {
      workdir = { opts.workdir, "string" },
      autoload = { opts.autoload, "boolean" }
    }
  end)

  if not ok then
    vim.health.error("Invalid setup options: " .. err)
  else
    vim.health.ok("opts are correctly set")
  end
end

M.check = function()
  vim.health.start("meson.nvim health check")

  validate_opts_table()
end

return M
