---@class TerminalOutput
---@field win snacks.win Build terminal window
---@field job_id integer? Running build job id
---@field event nio.control.Event? Running build job event
---@field buffers table<string, string[]> Available buffer contents
---@field buffer string Selected buffer content
local M = setmetatable({}, {
    __call = function(t, ...)
        return t.new(...)
    end
})
M.__index = M

function M.new()
    local self = setmetatable({}, M)
    self.buffers = {
        build = {},
        app = {}
    }
    self.buffer = "build"

    self.win = Snacks.win.new {
        buf = vim.api.nvim_create_buf(false, true),
        style = "terminal",
        position = "bottom",
        keys = { q = "hide" }
    }

    vim.api.nvim_set_option_value("filetype", "terminal", { buf = self.win.buf })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = self.win.buf })
    vim.api.nvim_set_option_value("modifiable", false, { buf = self.win.buf })

    self.win:hide()

    return self
end

function M:show()
    self.win:show()
end

function M:toggle()
    self.win:toggle()
end

function M:change_buffer(buffer_name)
    if self.buffers[buffer_name] then
        self.buffer = buffer_name
        self:update_buf()
    end

    return self
end

function M:get_buffer(buffer_name)
    return self.buffers[buffer_name or self.buffer]
end

function M:update_buf()
    if not self.win:buf_valid() then
        vim.notify("Buffer is not valid", vim.log.levels.ERROR)
        return
    end

    vim.api.nvim_set_option_value("modifiable", true, { buf = self.win.buf })
    vim.api.nvim_buf_set_lines(self.win.buf, 0, -1, false, self:get_buffer())

    local last_line = math.max(1, #self:get_buffer())
    if self.win:win_valid() then
        vim.api.nvim_win_set_cursor(self.win.win, {last_line, 0})
    end
    vim.api.nvim_set_option_value("modifiable", false, { buf = self.win.buf })
end

function M:insert(content, buffer_name)
    table.insert(self:get_buffer(buffer_name), content)

    if not buffer_name or buffer_name == self.buffer then
        self:update_buf()
    end
end

function M:stop_job()
    if self.job_id and vim.fn.jobwait({self.job_id}, 0)[1] == -1 then
        vim.fn.jobstop(self.job_id)
        self:insert("[Process stopped]")
    end
    self.job_id = nil
end

function M:clear(buffer_name)
    local buffer = self:get_buffer(buffer_name)

    while #buffer > 0 do
        table.remove(buffer)
    end
    if (not buffer_name or self.buffer == buffer_name) and self.win:buf_valid() then
        vim.api.nvim_set_option_value("modifiable", true, { buf = self.win.buf })
        vim.api.nvim_buf_set_lines(self.win.buf, 0, -1, false, {})
        vim.api.nvim_set_option_value("modifiable", false, { buf = self.win.buf })
    end

    return self
end

---Run command
---@param cmd string
---@param opts ExecuteOpts?
---@return integer exit_code
function M:execute(cmd, opts)
    opts = opts or {}

    -- Cancel previous task
    if self.job_id and vim.fn.jobwait({self.job_id}, 0)[1] == -1 then
        if self.event then self.event.set() end
        vim.fn.jobstop(self.job_id)
    end

    local function on_output(_, data, _)
        if not data then return end

        for _, line in ipairs(data) do
            if line ~= "" then
                table.insert(self:get_buffer(opts.buffer), line)
            end
        end

        if not opts.buffer or opts.buffer == self.buffer then
            self:update_buf()
        end
    end

    self.event = require("nio").control.event()

    local job_env = vim.fn.environ()
    if opts.env then
        for k, v in pairs(opts.env) do
            job_env[k] = v
        end
    end

    local code = 0

    self.job_id = vim.fn.jobstart(cmd, {
        stdout_buffered = false,
        on_stdout = on_output,
        on_stderr = on_output,
        env = job_env,
        on_exit = function(_, exit_code, _)
            code = exit_code
            self.job_id = nil
            self:insert("[Process exited with code ${code}]" % { code = exit_code }, opts.buffer)
            self.event.set()
        end,
    })

    if self.job_id <= 0 then
        self:insert("Error: failed to start job", opts.buffer)
        self.job_id = nil
    end

    self.event.wait()
    self.event = nil
    return code
end

return M
