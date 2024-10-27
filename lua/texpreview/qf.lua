local util = require 'texpreview.util'

local vim = vim
local api = vim.api
local vfn = vim.fn

local M = {}

local errfmt = {
  [[%-P**%f]],
  [[%-P**\"%f\"]],

  [[%-G%.%#\ Fatal\ error\ occurred\,%m]],

  [[%E! LaTeX %trror: %m]],
  [[%E%f:%l: %m]],
  [[%E! %m]],

  [[%Z<argument> %m]],

  [[%Cl.%l %m]],

  [[%+WLaTeX Font Warning: %.%#line %l%.%#]],
  [[%-CLaTeX Font Warning: %m]],
  [[%-C(Font)%m]],
  [[%+WLaTeX %.%#Warning: %.%#line %l%.%#]],
  [[%+WLaTeX %.%#Warning: %m]],
  [[%+WOverfull %\%\hbox%.%# at lines %l--%*\d]],
  [[%+WOverfull %\%\hbox%.%# at line %l]],
  [[%+WOverfull %\%\vbox%.%# at line %l]],
  [[%+WUnderfull %\%\hbox%.%# at lines %l--%*\d]],
  [[%+WUnderfull %\%\vbox%.%# at line %l]],

  [[%-G%.%#]],
}

local function set_qflist(bnum, src_path, log_path)
  api.nvim_set_option_value('errorformat', table.concat(errfmt, ','), {
    buf = bnum,
  })
  vfn.setqflist({}, 'r')
  vim.cmd.caddfile(log_path)

  local qflist = vim.tbl_map(function(qf)
    if api.nvim_buf_get_name(qf.bufnr) == src_path then
      qf.bufnr = tonumber(bnum)
    end
    return qf
  end, vfn.getqflist())
  vfn.setqflist(qflist, 'r')
  vfn.setqflist({}, 'a', { title = 'texpreview errors' })

  return qflist
end

function M.open(bnum, src_path, keep_focus)
  local log_path = src_path:gsub('%.%w+$', '.log')
  if vfn.filereadable(log_path) == 0 then
    util.echo 'No log file is found'
    return
  end

  local qflist = set_qflist(bnum, src_path, log_path)
  if vim.tbl_isempty(qflist) then
    util.echo 'No errors'
    return
  end

  if keep_focus then
    local win_id = api.nvim_get_current_win()
    vim.schedule(function() api.nvim_set_current_win(win_id) end)
  end

  vim.cmd.cwindow { mods = { split = 'botright' } }
  vim.cmd.redraw()
end

return M
