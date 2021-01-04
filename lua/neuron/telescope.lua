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
    ordinal = display
  }
end

--- Backlinks or uplinks
local function gen_from_links(entry)
  local not_folgezettal = entry[2]
  return gen_from_zettels(not_folgezettal)
end

local function _find_zettels(opts)
  opts = opts or {}

  local json = vim.fn.json_decode(opts.json).result
  local entry_maker = gen_from_zettels

  pickers.new(opts, {
    prompt_title = opts.title or 'Find Zettels',
    finder = finders.new_table {
      results = json,
      entry_maker = opts.entry_maker or entry_maker,
    },
    previewer = opts.previewer or previewers.vim_buffer_cat.new(opts),
    sorter = opts.sorter or conf.generic_sorter(opts),
  }):find()
end

function M.find_zettels(opts)
  opts = opts or {}

  Job:new {
    command = "neuron",
    args = {"query", "--cached"},
    cwd = opts.cwd or neuron.config.neuron_dir,
    on_stderr = utils.on_stderr_factory("neuron query"),
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      _find_zettels {json = data}
    end)
  }:start()
end

function M.find_backlinks(opts)
  opts = opts or {}

  local args = {"query"}

  opts.back = opts.back or true
  if opts.back then
    table.insert(args, "--backlinks-of")
  else
    table.insert(args, "--uplinks-of")
  end

  table.insert(args, opts.id or M.get_current_id())

  if opts.cached ~= false then
    table.insert(args, "--cached")
  end

  Job:new {
    command = "neuron",
    -- args = {"query", "--backlinks-of", opts.id or M.get_current_id(), "--cached"},
    args = args,
    cwd = opts.cwd or neuron.config.neuron_dir,
    on_stderr = utils.on_stderr_factory("neuron query --backlinks-of"),
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      _find_zettels {
        title = 'Find Backlinks',
        json = data,
        entry_maker = gen_from_links
      }
    end)
  }:start()
end

return M
