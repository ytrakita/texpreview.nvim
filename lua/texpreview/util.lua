local api = vim.api

local M = {}

function M.echo(msg)
  api.nvim_echo({ { ('[texpreview] %s'):format(msg) } }, false, {})
end

return M
