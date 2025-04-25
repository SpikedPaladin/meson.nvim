<h1 align="center">meson.nvim</h1>
<h4 align="center">Meson build system support for Neovim</h4>

## Installation
### Using [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
return {
    "SpikedPaladin/meson.nvim",
    event = "VeryLazy",
    dependencies = {
        "nvim-neotest/nvim-nio"
    }
}
```

## Usage
### Commands
#### Build
`Meson build`
#### Run
`Meson run` - run first executable target  
`Meson run [target name]` - run specific target