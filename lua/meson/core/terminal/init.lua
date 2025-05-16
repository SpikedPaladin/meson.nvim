---@class Terminal
---@field buf integer? Current buffer
---@field win snacks.win? Current output window
---@field output string[] Current output history
---@field job_id integer? Current task id
local M = {}

local function setup(name, terminal)
    terminal.execute(require("meson.core.util").get_setup_command(name))
end

local function build(name, terminal)
    terminal.execute(require("meson.core.util").get_build_command(name))
end

---@async
function M.setup(name)
    local output = require("meson.core.terminal.build")
    output.clear()
    setup(name, output)
end

---@async
function M.rebuild(name)
    local output = require("meson.core.terminal.build")

    require("meson.core.util").clear_build_dir(name, output.insert)
    setup(name, output)
    build(name, output)
end

---@async
function M.build(name)
    local output = require("meson.core.terminal.build")
    output.clear()
    build(name, output)
end

---@async
function M.install(name)
    local output = require("meson.core.terminal.build")
    output.clear()
    output.execute(require("meson.core.util").get_install_command(name))
end

---@async
function M.run(name, target)
    local output = require("meson.core.terminal.build")
    output.clear()
    local exit_code = output.execute(require("meson.core.util").get_install_command(name))
    if exit_code ~= 0 then
        vim.notify("Failed to build!", vim.log.levels.ERROR)
        return
    end
    output.execute(target, {
        env = {
            GSETTINGS_SCHEMA_DIR = "${install}:${current}" % {
                install = require("meson.core.util").get_gschema_dir(name),
                current = vim.fn.environ().GSETTINGS_SCHEMA_DIR or ""
            }
        }
    })
end

return M
