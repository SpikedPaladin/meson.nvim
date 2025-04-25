---@class Terminal
---@field buf integer? Current buffer
---@field win snacks.win? Current output window
---@field output string[] Current output history
---@field job_id integer? Current task id
local M = {}

---@async
function M.setup(name)
    local build = require("meson.core.terminal.build")
    build.clear()
    build.execute(require("meson.core.util").get_setup_command(name))
end

---@async
function M.build(name)
    local build = require("meson.core.terminal.build")
    build.clear()
    build.execute(require("meson.core.util").get_build_command(name))
end

---@async
function M.install(name)
    local build = require("meson.core.terminal.build")
    build.clear()
    build.execute(require("meson.core.util").get_install_command(name))
end

---@async
function M.run(name, target)
    local build = require("meson.core.terminal.build")
    build.clear()
    local exit_code = build.execute(require("meson.core.util").get_install_command(name))
    if exit_code ~= 0 then
        vim.notify("Failed to build!", vim.log.levels.ERROR)
        return
    end
    build.execute(target, {
        env = {
            GSETTINGS_SCHEMA_DIR = "${install}:${current}" % {
                install = require("meson.core.util").get_gschema_dir(name),
                current = vim.fn.environ().GSETTINGS_SCHEMA_DIR or ""
            }
        }
    })
end

return M
