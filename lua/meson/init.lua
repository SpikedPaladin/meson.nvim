---@class Meson
local M = {}

---Setup the meson plugin
---@param opts UserOptions: plugin options
function M.setup(opts)
    require("meson.config").setup(opts)
end

---@type MesonCommand
M.output = {
    run = function(args)
        if #args > 0 then
            require("meson.core.terminal").switch_output_buffer(args[1], true)
        else
            require("meson.core.terminal").output:toggle()
        end
    end,
    complete = function(arg_lead)
        return vim
            .iter({ "build", "b", "app", "a" })
            :filter(function(arg) return arg:find(arg_lead) ~= nil end)
            :totable()
    end
}

---@type MesonCommand
M.rebuild = {
    run = function()
        local nio = require("nio")

        nio.run(function()
            require("meson.core").rebuild()
        end)
    end
}

---@type MesonCommand
M.build = {
    run = function()
        local nio = require("nio")

        nio.run(function()
            require("meson.core").build()
        end)
    end
}

---@type MesonCommand
M.reload = {
    run = function()
        print(vim.inspect(vim.fn.environ()))
        local nio = require("nio")

        nio.run(function()
            require("meson.core").reload(true)
        end)
    end
}

---@type MesonCommand
M.install = {
    run = function()
        local nio = require("nio")

        nio.run(function ()
            require("meson.core").install()
        end)
    end
}

---@type MesonCommand
M.run = {
    run = function(args)
        local nio = require("nio")

        nio.run(function()
            require("meson.core").run(args[1])
        end)
    end,
    complete = function(arg_lead)
        local targets = require("meson.core").project_targets
        if not targets then return end

        return vim
            .iter(targets)
            :filter(function(item) return item.type == "executable" and item.name:find(arg_lead) ~= nil end)
            :map(function(item) return item.name end)
            :totable()
    end
}

M.info = {
    run = function()
        local str
        local project_name = require("meson.core").project_name
        if project_name then
            str = "Project name: " .. require("meson.core").project_name
        else
            str = "cwd is not a meson project"
        end
        vim.print(str)
    end
}

local function interp(s, tab)
    return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

local original_mod = getmetatable("").__mod
getmetatable("").__mod = function(s, tab)
    local result = interp(s, tab)

    if original_mod then
        result = original_mod(result, tab)
    end

    return result
end

return M
