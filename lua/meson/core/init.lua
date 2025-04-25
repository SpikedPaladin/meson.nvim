---@class meson.Core
---@field project_name? string project name
---@field project_targets? table project targets
local M = {}

---Tries to reload meson configuration
---@param notify? boolean display notification if failed
function M.reload(notify)
    M.project_name = require("meson.core.util").get_project_name()

    if not M.project_name and notify then
        vim.notify("Failed to load meson introspection: not a meson project!", vim.log.levels.WARN)
    end

    if not M.project_name then
        return
    end
end

local function try_get_name()
    if not M.project_name then
        M.reload()
    end

    if not M.project_name then
        vim.notify("Not a meson project!", vim.log.levels.WARN)
    end

    return M.project_name
end

local function try_get_targets()
    local name = try_get_name()
    if not name then return nil end

    local get_targets = require("meson.core.introspect").get_targets
    if not M.project_targets then
        M.project_targets = get_targets(name)
    end

    if not M.project_targets then
        if require("meson.core.introspect").setup(name) then
            M.project_targets = get_targets(name)
        end
    end

    return M.project_targets
end

function M.targets()
    local targets = try_get_targets()
    if not targets then return end

    for _, item in ipairs(targets) do
        print(item.name)
    end
end

function M.install()
    local targets = try_get_targets()
    if not targets then return end

    require("meson.core.terminal").install(M.project_name)
end

function M.run(target_name)
    local targets = try_get_targets()
    local selected_target
    if not targets then return end

    for _, item in ipairs(targets) do
        if target_name then
            if target_name == item.name then
                selected_target = item
                break
            end
        elseif item.type == "executable" then
            selected_target = item
            break;
        end
    end

    if selected_target then
        require("meson.core.terminal").run(M.project_name, selected_target.filename[1])
    end

    vim.notify("Executable target not found", vim.log.levels.WARN)
end

function M.build()
    local targets = try_get_targets()
    if not targets then return end

    require("meson.core.terminal").build(M.project_name)
end

if require("meson.config").options.autoload then
    M.reload()
end

return M
