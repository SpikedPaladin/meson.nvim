local M = {}

---Tries to setup meson project
---@param name string Project name
---@return boolean success
function M.setup(name)
    vim.fn.system(require("meson.core.util").get_setup_command(name))
    if vim.v.shell_error ~= 0 then
        print("Setup failed! Not a meson project!")
        return false
    end

    return true
end

---Tries to get current targets
---@param name string Project name
---@return table? targets If project configured
function M.get_targets(name)
    local command = require("meson.core.util").get_targets_command(name)

    local out = vim.fn.system(command)
    local result, json = pcall(vim.json.decode, out)
    if not result then
        return nil
    end

    return json
end

return M
