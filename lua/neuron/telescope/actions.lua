local api = vim.api
local neuron = require("neuron")
local cmd = require("neuron/cmd")
local utils = require("neuron/utils")
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local M = {}

function M.insert_maker(key)
  return function(prompt_bufnr)
    actions.close(prompt_bufnr)

    local entry = action_state.get_selected_entry()
    api.nvim_put({entry[key]}, "c", true, true)
  end
end

function M.edit_or_insert(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = action_state.get_selected_entry()
  if entry ~= nil then
    vim.cmd("edit " .. entry.value)
  else
    local current_line = action_state.get_current_line() -- todo, need pr telescope for this
    cmd.new_and_callback(neuron.config.neuron_dir, function(data)
      vim.cmd("edit " .. data)
      utils.start_insert_header()
      utils.feedraw(current_line)
      utils.feedkeys("<CR><CR>", "n")
    end)
  end
end

function M.insert(prompt_bufnr)
  actions.close(prompt_bufnr)

  local entry = action_state.get_selected_entry()
  api.nvim_put({entry.id}, "c", true, true)
end

function M.new(prompt_bufnr)
  actions.close(prompt_bufnr)

  vim.cmd("edit " .. action_state.get_current_line() .. ".md")
end

return M
