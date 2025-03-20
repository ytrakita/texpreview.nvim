local qf = require 'texpreview.qf'
local util = require 'texpreview.util'

local vim = vim
local api = vim.api
local vfn = vim.fn
local fs = vim.fs
local uv = vim.uv

local M = {}

function M.view_pdf(vw_cmd, src_path)
  local pdf_path = src_path:gsub('%.%w+$', '.pdf')
  vw_cmd = vim.iter {
    vw_cmd,
    api.nvim_win_get_cursor(0)[1],
    pdf_path,
  } :flatten():totable()
  vim.system(vw_cmd, {}, function() end)
end

function M.typeset(bnum, ts_cmd, tmp_path, vw_cmd, msg)
  local buf_path = api.nvim_buf_get_name(bnum)

  local lines = api.nvim_buf_get_lines(bnum, 0, -1, false)
  local src_path = fs.joinpath(tmp_path, fs.basename(buf_path))
  vfn.writefile(lines, src_path)

  ts_cmd = vim.iter {
    'env',
    ('TEXINPUTS=.:%s:'):format(fs.dirname(buf_path)),
    ts_cmd,
    src_path,
  } :flatten():totable()
  vim.system(ts_cmd, { cwd = tmp_path }, vim.schedule_wrap(function(obj)
    if obj.code > 0 then
      qf.open(bnum, src_path, true)
      return
    elseif vw_cmd then
      M.view_pdf(vw_cmd, src_path)
    end
    if msg then
      util.echo(msg)
    end
    vim.cmd.cclose()
  end))
end

local timer

function M.update(bnum, ts_cmd, tmp_path, timeout)
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  timer = uv.new_timer()
  timer:start(timeout, 0, vim.schedule_wrap(function()
    M.typeset(bnum, ts_cmd, tmp_path)
  end))
end

return M
