local popup = require('popup')
local config = require('neuron.config')
local cmd = require('neuron.cmd')
local utils = require('neuron.utils')
local a = vim.api

local neuron_prompt_prefix_ns = a.nvim_create_namespace("neuron_prompt_prefix")

local M = {}

function M.prompt_callback(text_inserted)
  vim.cmd [[stopinsert]]
  vim.cmd [[quit!]]

  if text_inserted ~= nil and text_inserted ~= "" then
    local relative_path = utils.get_neuron_path(text_inserted, config.neuron_dir)
    if vim.fn.filereadable(relative_path) then
      vim.cmd('edit ' .. relative_path)
    else
      cmd.new_edit_named(config.neuron_dir, text_inserted)
    end
  end
end

function M.prompt_new_zettel(opts)
  local opt_default = opts or {
    border = {},
    borderchars = {"─", "│", "─", "│", "╭", "╮", "╯", "╰"},
    col = 0,
    line = 0,
    width = 0,
    height = 1,
    enter = true,
    title = "New Zettel"
  }

  local cols = a.nvim_get_option('columns')
  local lines = a.nvim_get_option('lines')

  -- Avoid having float
  local width = math.floor(cols / 4)
  local col = math.floor(cols/2 - width/2)

  opt_default.col = col
  opt_default.width = width

  local line = lines / 2
  opt_default.line = line

  local prompt_win, prompt_opt = popup.create('', opt_default)
  local prompt_bufnr = a.nvim_win_get_buf(prompt_win)
  -- Telescope is required, let's keep a visual consistency by using its highlight
  a.nvim_win_set_option(prompt_win, 'winhl', 'Normal:TelescopeNormal')

  local prompt_border_win = prompt_opt.border and prompt_opt.border.win_id

  if prompt_border_win then
    a.nvim_win_set_option(prompt_border_win, 'winhl', 'Normal:TelescopePromptBorder')
  end

  a.nvim_buf_set_option(prompt_bufnr, 'buftype', 'prompt')
  a.nvim_buf_set_keymap(prompt_bufnr, 'n', '<Esc>', '<cmd>quit!<cr>', {})

  vim.fn.prompt_setprompt(prompt_bufnr, "> ")
  vim.fn.prompt_setcallback(prompt_bufnr, M.prompt_callback)
  a.nvim_buf_add_highlight(prompt_bufnr, neuron_prompt_prefix_ns, 'TelescopePromptPrefix', 0, 0, 2)
  vim.cmd [[startinsert]]
end

return M
