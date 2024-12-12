# QKeyViewer

A Neovim plugin to display all your keymaps in a floating window.

## Features

- Display all configured keymaps in a floating window
- Easy to open with `<Space><Space>`
- Quick close with `q`
- Beautiful floating window interface

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "yourusername/qkeyviewer",
    event = "VeryLazy",
    config = true
}
```

## Usage

Press `<Space><Space>` to open the keymap viewer window.
Press `q` to close the window.

## Requirements

- Neovim >= 0.8.0

## License

MIT
