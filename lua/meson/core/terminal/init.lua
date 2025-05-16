---@class Terminal
---@field output TerminalOutput Build and application output
local M = {
    output = require("meson.core.terminal.output").new()
}

---Switch output buffer content
---@param output_name string name of the output buffer content
---@param show boolean?
function M.switch_output_buffer(output_name, show)
    if output_name == "b" or output_name == "build" then
        M.output:change_buffer("build")
    elseif output_name == "a" or output_name == "app" then
        M.output:change_buffer("app")
    end

    M.output:update_buf()
    if show then
        M.output:show()
    end
end

---Run meson setup
---@param name string project name
local function setup(name)
    M.output:execute(require("meson.core.util").get_setup_command(name), { buffer = "build" })
end

local function build(name)
    M.output:execute(require("meson.core.util").get_build_command(name), { buffer = "build" })
end

---@async
function M.setup(name)
    M.output:change_buffer("build"):clear()
    setup(name)
end

---@async
function M.rebuild(name)
    M.output:change_buffer("build"):clear()
    require("meson.core.util").clear_build_dir(name, function(text)
        M.output:insert(text, "build")
    end)
    setup(name)
    build(name)
end

---@async
function M.build(name)
    M.output:change_buffer("build"):clear()
    build(name)
end

---@async
function M.install(name)
    M.output:change_buffer("build"):clear()
    M.output:execute(require("meson.core.util").get_install_command(name), { buffer = "build" })
end

---@async
function M.run(name, target)
    M.output:change_buffer("build"):clear()
    local exit_code = M.output:execute(require("meson.core.util").get_install_command(name), { buffer = "build" })
    if exit_code ~= 0 then
        vim.notify("Failed to build!", vim.log.levels.ERROR)
        return
    end
    M.output:change_buffer("app"):clear()
    M.output:execute(target, {
        env = {
            GSETTINGS_SCHEMA_DIR = "${install}:${current}" % {
                install = require("meson.core.util").get_gschema_dir(name),
                current = vim.fn.environ().GSETTINGS_SCHEMA_DIR or ""
            }
        },
        buffer = "app"
    })
end

return M
