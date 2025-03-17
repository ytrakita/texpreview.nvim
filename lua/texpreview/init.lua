local preview = require 'texpreview.preview'
local qf = require 'texpreview.qf'
local util = require 'texpreview.util'

local vim = vim
local api = vim.api
local vfn = vim.fn
local fs = vim.fs

local M = {}

local function get_stdpath(what, idx)
  if not what then return end

  local ret = vfn.stdpath(what)
  if type(ret) == 'table' then
    ret = ret[idx]
  end
  return ret
end

M.config = {
  ts_cmd = {
    'latexmk',
    '-pdf',
  },
  vw_cmd = {
    '/Applications/Skim.app/Contents/SharedSupport/displayline',
    '-n',
  },
  cl_cmd = {
    'latexmk',
    '-C',
  },
  tmp_path = fs.joinpath(get_stdpath 'state', 'texpreview.nvim', 'tmp'),
  timeout = 1500,
  server_name = fs.joinpath(get_stdpath 'cache', 'synctex-server.pipe'),
}

local status = {}

local function start()
  local cfg = M.config
  local bnum = api.nvim_get_current_buf()

  vfn.mkdir(cfg.tmp_path, 'p')
  if not vim.tbl_contains(vfn.serverlist(), cfg.server_name) then
    vfn.serverstart(cfg.server_name)
  end

  preview.typeset(bnum, cfg.ts_cmd, cfg.tmp_path, cfg.vw_cmd)
  util.echo 'Preview starts'

  local augroup_id = api.nvim_create_augroup('texpreview', { clear = false })
  vim.b.texpreview = api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = augroup_id,
    buffer = bnum,
    callback = function()
      preview.update(bnum, cfg.ts_cmd, cfg.tmp_path, cfg.timeout)
    end,
  })

  table.insert(status, { buf = bnum })
end

local function stop()
  api.nvim_del_autocmd(vim.b.texpreview)
  vim.b.texpreview = nil
  util.echo 'Preview stopped'
  local bnum = api.nvim_get_current_buf()
  local idx
  for i, v in ipairs(status) do
    if v.buf == bnum then
      idx = i
      break
    end
  end
  table.remove(status, idx)
end

function M.typeset()
  local cfg = M.config
  local bnum = api.nvim_get_current_buf()

  vfn.mkdir(cfg.tmp_path, 'p')
  if not vim.tbl_contains(vfn.serverlist(), cfg.server_name) then
    vfn.serverstart(cfg.server_name)
  end

  preview.typeset(bnum, cfg.ts_cmd, cfg.tmp_path)
  local fname = api.nvim_buf_get_name(bnum)
  local msg = ('typeset %s.pdf'):format(vfn.fnamemodify(fname, ':t:r'))
  util.echo(msg)
end

function M.toggle()
  if vim.b.texpreview then
    stop()
  else
    start()
  end
end

function M.clean()
  local cfg = M.config
  local buf_base = fs.basename(api.nvim_buf_get_name(0))
  local cmd = vim.iter{ cfg.cl_cmd, buf_base }:flatten():totable()
  vim.system(cmd, { cwd = cfg.tmp_path }, function() end)
end

function M.save_pdf()
  local cfg = M.config

  local buf_path = api.nvim_buf_get_name(0)
  local buf_base = fs.basename(buf_path) or ''
  local pdf_base = buf_base:gsub('%.%w+$', '.pdf')
  local pdf_path = fs.joinpath(cfg.tmp_path, pdf_base)

  if vfn.filereadable(pdf_path) == 0 then
    util.echo 'No PDF file can be saved'
    return
  end

  local buf_dir = fs.dirname(buf_path)
  local cmd = { 'cp', pdf_path, buf_dir }

  vim.system(cmd, {}, vim.schedule_wrap(function()
    local msg = ([[%s is saved]]):format(pdf_base)
    util.echo(msg)
  end))
end

function M.view_pdf()
  local cfg = M.config
  local buf_path = api.nvim_buf_get_name(0)
  local src_path = fs.joinpath(cfg.tmp_path, fs.basename(buf_path))

  preview.view_pdf(cfg.vw_cmd, src_path)
end

local function is_qf_win_open()
  for _, win in ipairs(vfn.getwininfo()) do
    if win.quickfix == 1 then
      return true
    end
  end
end

function M.qf_toggle()
  if is_qf_win_open() then
    vim.cmd.cclose()
  else
    local bnum = api.nvim_get_current_buf()
    local src_base = fs.basename(api.nvim_buf_get_name(bnum))
    local src_path = fs.joinpath(M.config.tmp_path, src_base)
    qf.open(bnum, src_path)
  end
end

function M.backward_search(line, file)
  local buf_path, buf_base
  for _, v in ipairs(status) do
    buf_path = api.nvim_buf_get_name(v.buf)
    buf_base = fs.basename(buf_path)
    if fs.joinpath(M.config.tmp_path, buf_base) == file then break end
  end

  vim.cmd.buffer(buf_path)
  api.nvim_win_set_cursor(0, { line, 0 })
  vim.cmd 'normal! zv'
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

return M
