local pickers = require("telescope.pickers")
local make_entry = require("telescope.make_entry")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local utils = require("neuron/utils")
local cmd = require("neuron/cmd")
local neuron_actions = require("neuron/telescope/actions")
local neuron_entry = require("neuron/telescope/make_entry")
local config = require("neuron/config")

local M = {}

function M.find_zettels(opts)
  opts = opts or {}

  cmd.query(
    {
      cached = opts.cached
    },
    config.neuron_dir,
    function(json)
      local picker_opts = {
        prompt_title = "Find Zettels",
        finder = finders.new_table {
          results = json.result,
          entry_maker = neuron_entry.gen_from_zettels
        },
        previewer = previewers.vim_buffer_cat.new(opts),
        sorter = conf.generic_sorter(opts)
      }

      if opts.insert then
        picker_opts.attach_mappings = function()
          actions.goto_file_selection_edit:replace(neuron_actions.insert_maker("id"))
          return true
        end
      else
        picker_opts.attach_mappings = function()
          actions.goto_file_selection_edit:replace(neuron_actions.edit_or_insert)
          return true
        end
      end

      pickers.new(opts, picker_opts):find()
    end
  )
end

function M.find_backlinks(opts)
  opts = opts or {}

  cmd.query(
    {
      up = opts.up,
      back = opts.back or true,
      id = opts.id or utils.get_current_id(),
      cached = opts.cached
    },
    config.neuron_dir,
    function(json)
      local picker_opts = {
        prompt_title = "Find Backlinks",
        finder = finders.new_table {
          results = json.result,
          entry_maker = neuron_entry.gen_from_links
        },
        previewer = previewers.vim_buffer_cat.new(opts),
        sorter = conf.generic_sorter(opts)
      }

      if opts.insert then
        picker_opts.attach_mappings = function()
          actions.goto_file_selection_edit:replace(neuron_actions.insert_maker("id"))
          return true
        end
      end

      pickers.new(opts, picker_opts):find()
    end
  )
end

function M.find_tags(opts)
  opts = opts or {}

  cmd.query(
    {uri = "z:tags"},
    config.neuron_dir,
    function(json)
      local picker_opts = {
        prompt_title = "Find Tags",
        finder = finders.new_table {
          results = json.result,
          entry_maker = neuron_entry.gen_from_tags
        },
        previewer = nil,
        sorter = conf.generic_sorter(opts),
        attach_mappings = function()
          actions.goto_file_selection_edit:replace(neuron_actions.insert_maker("display"))
          return true
        end
      }

      pickers.new(opts, picker_opts):find()
    end
  )
end

function M.find_by_tag(opts)
  opts = opts or {}

  local live_finder =
    finders.new_job(
    function(prompt)
      -- TODO: Probably could add some options for smart case and whatever else rg offers.

      if not prompt or prompt == "" then
        return nil
      end

      return {"neuron", "query", "-t", prompt}
    end,
    opts.entry_maker or make_entry.gen_from_string(opts),
    opts.max_results
  )

  pickers.new(
    opts,
    {
      prompt_title = "Live Find by Tag",
      finder = live_finder,
      previewer = nil,
      sorter = conf.generic_sorter(opts)
    }
  ):find()
end

return M
