local M = {}

---Looks for checked out git branch
---@return string? branch If git repository exists
function M.get_current_branch()
    local git_dir = vim.fn.finddir(".git", ".;")
    if git_dir == "" then return nil end

    local file = io.open(git_dir .. "/HEAD")
    if not file then return nil end

    local head = file:read("*a")
    file:close()

    return head:match("ref: refs/heads/([^\n]+)")
end

---Tries to find project name
---@return string? if cwd is meson project
function M.get_project_name()
    local meson_file = vim.fn.getcwd() .. '/meson.build'

    if vim.fn.filereadable(meson_file) == 0 then
        return nil
    end

    local content = table.concat(vim.fn.readfile(meson_file), '\n')
    content = content:gsub('#.-[\r\n]', '')
    content = content:gsub('%s+', ' ')

    local pattern = "project%(%s*'([^'':]+)'[^%)]*%)"
    local project_name = content:match(pattern)

    return project_name
end

function M.get_targets_command(name)
    return "meson introspect ${build} --targets" % {
        build = M.get_build_dir(name)
    }
end

function M.get_setup_command(name)
    return "meson setup --prefix=${install} ${build}" % {
        install = M.get_install_dir(name),
        build = M.get_build_dir(name)
    }
end

function M.get_build_command(name)
    return "meson compile -C ${build}" % {
        build = M.get_build_dir(name)
    }
end

function M.get_install_command(name)
    return "meson install -C ${build}" % {
        build = M.get_build_dir(name)
    }
end

function M.get_gschema_dir(name)
    return "${install}/share/glib-2.0/schemas" % {
        install = M.get_install_dir(name)
    }
end

local function get_build_path()
    local branch = M.get_current_branch()
    if branch ~= nil then
        return "/builds/default-" .. branch
    else
        return "/builds/default"
    end
end

function M.get_project_dir(name)
    return "${workdir}/${name}" % {
        workdir = require("meson.config").options.workdir,
        name = name
    }
end

function M.get_install_dir(name)
    return M.get_project_dir(name) .. "/install"
end

function M.get_build_dir(name)
    return M.get_project_dir(name) .. get_build_path()
end

return M
