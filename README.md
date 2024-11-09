# texpreview.nvim

A Neovim plugin to preview (La)TeX output (macOS only).

## Requirements

- [latexmk](https://ctan.org/pkg/latexmk)
- [Skim.app](https://skim-app.sourceforge.io)

## Skim configuration for SyncTeX

To enable backward search:

Skim > Prefarence > Sync > PDF-TeX Sync support

- Preset: `Custom`
- Command: `nvim`
- Arguments: `--server ~/.cache/nvim/synctex-server.pipe --remote-send '<Cmd>lua require "texpreview".backward_search(%line, "%file")<CR>'`
