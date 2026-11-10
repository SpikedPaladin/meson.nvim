local introspection = require("meson.core.introspect")
local terminal = require("meson.core.terminal")
local util = require("meson.core.util")

---@class Project
---@field folder string
---@field name string?
---@field targets table?
local M = setmetatable({}, {
    __call = function(t, ...)
        return t.new(...)
    end
})
M.__index = M

function M.new(opts)
    local self = setmetatable({
        folder = opts.folder or vim.uv.cwd()
    }, M)

    self:reload()

    return self
end

function M:reload(notify)
    self.name = util.get_project_name()

    if not self.name and notify then
        if notify then
            vim.notify("Failed to load meson introspection: not a meson project!", vim.log.levels.WARN)
        end

        return
    end

    self.targets = introspection.get_targets(self.name)
    if not self.targets then
        local exit_code = terminal.setup(self.name)
        if exit_code ~= 0 then
            vim.notify("Failed setup!", vim.log.levels.WARN)
            return
        end

        self.targets = introspection.get_targets(self.name)
    end
end

return M
