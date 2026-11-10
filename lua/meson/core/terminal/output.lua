---@class TerminalBuffer
---@field buf integer Terminal buffer handle
---@field channel integer Terminal input channel

---@class TerminalOutput
---@field win snacks.win Build terminal window
---@field job_id integer? Running build job id
---@field event nio.control.Event? Running build job event
---@field buffers table<string, TerminalBuffer> Available terminal buffers
---@field buffer string Selected buffer name
local M = setmetatable({}, {
    __call = function(t, ...)
        return t.new(...)
    end
})
M.__index = M

---@return TerminalBuffer
local function create_terminal()
    local buf = vim.api.nvim_create_buf(false, true)
    local channel = vim.api.nvim_open_term(buf, {})
    vim.api.nvim_set_option_value("filetype", "terminal", { buf = buf })

    return { buf = buf, channel = channel }
end

function M.new()
    local self = setmetatable({}, M)
    self.buffers = {
        build = create_terminal(),
        app = create_terminal()
    }
    self.buffer = "build"

    self.win = Snacks.win.new {
        buf = self.buffers.build.buf,
        style = "terminal",
        position = "bottom"
    }

    for _, terminal in pairs(self.buffers) do
        vim.keymap.set("n", "q", function() self.win:hide() end, { buffer = terminal.buf })
    end

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
    local terminal = self.buffers[buffer_name]
    if terminal then
        self.buffer = buffer_name
        if self.win:win_valid() then
            self.win:set_buf(terminal.buf)
        else
            self.win.buf = terminal.buf
        end
    end

    return self
end

function M:get_buffer(buffer_name)
    return self.buffers[buffer_name or self.buffer]
end

---@param content string
---@param buffer_name string?
function M:write(content, buffer_name)
    local terminal = self:get_buffer(buffer_name)
    if not terminal or not vim.api.nvim_buf_is_valid(terminal.buf) then return end

    vim.api.nvim_chan_send(terminal.channel, content)

    if self.win:win_valid() and self.win.buf == terminal.buf then
        local last_line = vim.api.nvim_buf_line_count(terminal.buf)
        vim.api.nvim_win_set_cursor(self.win.win, { last_line, 0 })
    end
end

function M:insert(content, buffer_name)
    self:write(content .. "\r\n", buffer_name)
end

function M:stop_job()
    if self.job_id and vim.fn.jobwait({self.job_id}, 0)[1] == -1 then
        vim.fn.jobstop(self.job_id)
        self:insert("[Process stopped]")
    end
    self.job_id = nil
end

function M:clear(buffer_name)
    local name = buffer_name or self.buffer
    local previous = self.buffers[name]
    if not previous then return self end

    self.buffers[name] = create_terminal()
    vim.keymap.set("n", "q", function() self.win:hide() end, { buffer = self.buffers[name].buf })
    if name == self.buffer then
        self:change_buffer(name)
    end
    if vim.api.nvim_buf_is_valid(previous.buf) then
        vim.api.nvim_buf_delete(previous.buf, { force = true })
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

        self:write(table.concat(data, "\r\n"), opts.buffer)
    end

    self.event = require("nio").control.event()

    local job_env = vim.fn.environ()
    job_env.CLICOLOR_FORCE = job_env.CLICOLOR_FORCE or "1"
    if opts.env then
        for k, v in pairs(opts.env) do
            job_env[k] = v
        end
    end

    local code = 0

    self.job_id = vim.fn.jobstart(cmd, {
        pty = true,
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
