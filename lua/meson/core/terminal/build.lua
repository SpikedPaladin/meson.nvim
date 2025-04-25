---@class BuildTerminal
---@field win snacks.win Build terminal window
---@field job_id integer? Running build job id
---@field event nio.control.Event? Running build job event
---@field output string[] Current terminal output
local M = {
    output = {}
}

function M.toggle()
    if not M.win then
        M.create()
    end

    M.win:toggle()
end

function M.create()
    if M.win then return end

    M.win = Snacks.win.new {
        buf = vim.api.nvim_create_buf(false, true),
        style = "terminal",
        position = "bottom",
        keys = { q = "hide" }
    }

    vim.api.nvim_set_option_value("filetype", "terminal", { buf = M.win.buf })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = M.win.buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = M.win.buf })
end

function M.update_buf()
    if not M.win:buf_valid() then
        vim.notify("Buffer is not valid", vim.log.levels.ERROR)
        return
    end

    vim.api.nvim_set_option_value("modifiable", true, { buf = M.win.buf })
    vim.api.nvim_buf_set_lines(M.win.buf, 0, -1, false, M.output)

    local last_line = math.max(1, #M.output)
    if M.win:win_valid() then
        vim.api.nvim_win_set_cursor(M.win.win, {last_line, 0})
    end
    vim.api.nvim_set_option_value("modifiable", false, { buf = M.win.buf })
end

function M.insert(content)
    table.insert(M.output, content)
    M.update_buf()
end

function M.stop_job()
    if M.job_id and vim.fn.jobwait({M.job_id}, 0)[1] == -1 then
        vim.fn.jobstop(M.job_id)
        M.insert("[Process stopped]")
    end
    M.job_id = nil
end

function M.clear()
    if not M.win then
        M.create()
    end

    M.output = {}
    if M.win:buf_valid() then
        vim.api.nvim_set_option_value("modifiable", true, { buf = M.win.buf })
        vim.api.nvim_buf_set_lines(M.win.buf, 0, -1, false, {})
        vim.api.nvim_set_option_value("modifiable", false, { buf = M.win.buf })
    end
end


---Run command
---@param cmd string
---@param opts ExecuteOpts?
---@return integer exit_code
function M.execute(cmd, opts)
    if not M.win then
        M.create()
    end

    opts = opts or {}

    -- Cancel previous task
    if M.job_id and vim.fn.jobwait({M.job_id}, 0)[1] == -1 then
        if M.event then M.event.set() end
        vim.fn.jobstop(M.job_id)
    end

    local function on_output(_, data, _)
        if not data then return end

        for _, line in ipairs(data) do
            if line ~= "" then
                table.insert(M.output, line)
            end
        end

        M.update_buf()
    end

    M.event = require("nio").control.event()

    local job_env = vim.fn.environ()
    if opts.env then
        for k, v in pairs(opts.env) do
            job_env[k] = v
        end
    end

    local code = 0

    M.job_id = vim.fn.jobstart(cmd, {
        stdout_buffered = false,
        on_stdout = on_output,
        on_stderr = on_output,
        env = job_env,
        on_exit = function(_, exit_code, _)
            code = exit_code
            M.job_id = nil
            M.insert("[Process exited with code ${code}]" % { code = exit_code })
            M.event.set()
        end,
    })

    if M.job_id <= 0 then
        M.insert("Error: failed to start job")
        M.job_id = nil
    end

    M.event.wait()
    M.event = nil
    return code
end

return M
