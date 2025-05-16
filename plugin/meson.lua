local commands = {
    rebuild = require("meson").rebuild,
    install = require("meson").install,
    output = require("meson").output,
    reload = require("meson").reload,
    build = require("meson").build,
    info = require("meson").info,
    run = require("meson").run
}

local commands_keys = {}
for k, _ in pairs(commands) do
    table.insert(commands_keys, k)
end

local function split(line)
    ---@type string[]
    local args = {}
    for arg in line:gmatch("%S+") do
        args[#args + 1] = arg
    end

    return args
end

local function main_cmd(opts)
    local args = split(opts.args)
    local name = table.remove(args, 1)
    local command = commands[name]
    if command == nil then
        vim.notify("Meson: invalid subcommand", vim.log.levels.WARN)
    else
        command.run(args)
    end
end

local function complete(arg_lead, line, pos)
    if line:len() ~= pos then
        return
    end
    ---@type string[]
    local args = split(line)
    local current_arg = #args
    if arg_lead == "" then
        current_arg = current_arg + 1
    end
    if current_arg < 3 then
        return vim
            .iter(commands_keys)
            :filter(function(sub_cmd) return sub_cmd:find(arg_lead) ~= nil end)
            :totable()
    end
    local command = commands[args[2]]

    if current_arg > 3 then return end

    if command.complete then
        return command.complete(arg_lead)
    end
end

vim.api.nvim_create_user_command("Meson", main_cmd, {
    nargs = "?",
    desc = "Meson command",
    complete = complete
})
