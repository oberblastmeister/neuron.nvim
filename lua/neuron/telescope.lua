local Job = require("plenary/job")
local uv = vim.loop
local pickers = require('telescope.pickers')
local api = vim.api
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local utils = require("neuron/utils")
local cmd = require("neuron/cmd")
local neuron = require("neuron")

local M = {}

local function gen_from_zettels(entry)
  local value = string.format("%s/%s", neuron.config.neuron_dir, entry.zettelPath)
  local display = entry.zettelTitle
  return {
    display = display,
    value = value,
    ordinal = display,
    id = entry.zettelID,
  }
end

--- Backlinks or uplinks
local function gen_from_links(entry)
  local not_folgezettal = entry[2]
  return gen_from_zettels(not_folgezettal)
end

local function gen_from_tags(entry)
  local display = entry.name
  return {
    display = display,
    value = display,
    ordinal = display,
  }
end

local function find_zettels_json(opts)
  opts = opts or {}

  local picker_opts = {
    prompt_title = opts.title or 'Find Zettels',
    finder = finders.new_table {
      results = opts.json.result,
      entry_maker = opts.entry_maker or gen_from_zettels,
    },
    previewer = opts.previewer or previewers.vim_buffer_cat.new(opts),
    sorter = opts.sorter or conf.generic_sorter(opts),
  }

  if opts.insert then
    picker_opts.attach_mappings = function(_)
      actions.goto_file_selection_edit:replace(function(prompt_bufnr)
        actions.close(prompt_bufnr)

        local entry = actions.get_selected_entry()
        api.nvim_put({entry.id}, "c", true, false)
      end)
      return true
    end
  end

  pickers.new(opts, picker_opts):find()
end

function M.find_zettels(opts)
  opts = opts or {}

  cmd.query({
    cached = opts.cached
  }, neuron.config.neuron_dir, function(json)
    opts.json = json
    find_zettels_json(opts)
  end)
end

function M.find_backlinks(opts)
  opts = opts or {}

  cmd.query({
    up = opts.up,
    back = opts.back or true,
    id = opts.id or utils.get_current_id(),
    cached = opts.cached
  }, neuron.config.neuron_dir, function(json)
    opts.json = json
    opts.title = 'Find Backlinks'
    opts.entry_maker = gen_from_links
    find_zettels_json(opts)
  end)
end

function M.find_tags(opts)
  opts = opts or {}

  cmd.query({uri = "z:tags"}, neuron.config.neuron_dir, function(json)
    opts.json = json
    opts.title = "Find Tags"
    opts.entry_maker = gen_from_tags
    opts.previewer = false -- TODO: find better way to preview
    find_zettels_json(opts)
  end)
end

return M
