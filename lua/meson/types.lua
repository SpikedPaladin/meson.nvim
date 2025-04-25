---@meta

-- lua/meson/init.lua -----------------------------------------------------------

---@class Meson
---@field setup function: setup the plugin

---@class MesonCommand
---@field run fun(args:string[]) Func command
---@field complete? fun(arg_lead:string): string[]? Command complete

-- lua/meson/config.lua ---------------------------------------------------------

---@class Config
---@field defaults Options: default options
---@field options Options: user options
---@field setup function: setup the plugin

---@class UserOptions
---@field autoload? boolean: Load meson introspection automatically
---@field workdir? string: Plugin working directory

---@class DefaultOptions
---@field autoload boolean: Load meson introspection automatically
---@field workdir string: Plugin working directory

---@class Options
---@field autoload boolean: Load meson introspection automatically
---@field workdir string: Plugin working directory

-- lua/meson/core/util.lua ------------------------------------------------------

---@class ExecuteOpts
---@field env table<string, string>?: Custom environment variables
