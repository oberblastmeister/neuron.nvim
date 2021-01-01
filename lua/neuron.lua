local Job = require("plenary/job")
local uv = vim.loop
local lunajson = require("lunajson")
local pickers = require('telescope.pickers')
local api = vim.api
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local conf = require('telescope.config').values
local actions = require('telescope.actions')

local config = {}

local M = {}

local function on_stderr_factory(name)
  return vim.schedule_wrap(function(error, data)
    assert(not error, error)
    vim.cmd(string.format("echoerr 'An error occured from running %s: %s'", name, data))
  end)
end

local function on_exit_factory(name)
  return vim.schedule_wrap(function(self, code, _signal)
    if code ~= 0 then
      error(string.format("The job %s exited with a non-zero code: %s", name, code))
    end
  end)
end

local function feedkeys(string, mode)
  api.nvim_feedkeys(api.nvim_replace_termcodes(string, true, true, true), mode, true)
end

function M.rib(opts)
  assert(not NeuronJob, "you already started a neuron server")

  opts = opts or {}
  opts.address = opts.address or "127.0.0.1:8080"

  NeuronJob = Job:new {
    command = "neuron",
    cwd = vim.g.neuron_directory or "~/neuron",
    args = {"rib", "-w", "-s", opts.address},
    on_stderr = on_stderr_factory("neuron rib"),
  }
  NeuronJob.address = opts.address
  NeuronJob:start()

  vim.cmd [[augroup NeuronJobStop]]
  vim.cmd [[au!]]
  vim.cmd [[au VimLeave * lua require'neuron'.stop()]]
  vim.cmd [[augroup END]]

  if opts.verbose then
    print("Started neuron server at", opts.address)
  end
end

function M.stop()
  if NeuronJob ~= nil then
    uv.kill(NeuronJob.pid, 15) -- sigterm
    NeuronJob = nil
  end
end

function M.open(opts)
  opts = opts or {}

  Job:new {
    command = "neuron",
    args = {"open"},
    cwd = vim.g.neuron_directory or "~/neuron",
    on_stderr = on_stderr_factory("neuron open"),
    on_exit = on_exit_factory("neuron open"),
  }:start()
end

function M.new(opts)
  opts = opts or {}

  Job:new {
    command = "neuron",
    args = {"new"},
    cwd = config.neuron_dir,
    on_stderr = on_stderr_factory("neuron new"),
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      vim.cmd("edit " .. data)
      feedkeys("Go<CR>#<space>", 'n')
    end),
    on_exit = on_exit_factory("neuron new"),
  }:start()
end

local function gen_from_zettels(entry)
  local value = string.format("%s/%s", config.neuron_dir, entry.zettelPath)
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

  local json = lunajson.decode(opts.json).result
  local entry_maker = gen_from_zettels

  pickers.new(opts, {
    prompt_title = 'Find Zettels',
    finder = finders.new_table {
      results = json,
      entry_maker = opts.entry_maker or entry_maker,
    },
    previewer = opts.previewer or previewers.vim_buffer_cat.new(opts),
    sorter = conf.generic_sorter(opts),
  }):find()
end

function M.get_current_id()
  local path = vim.fn.expand("%:t")
  return path:sub(1, -4)
end

function M.find_zettels(opts)
  opts = opts or {}

  Job:new {
    command = "neuron",
    args = {"query"},
    cwd = opts.cwd or config.neuron_dir,
    on_stderr = on_stderr_factory("neuron query"),
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      _find_zettels {json = data}
    end)
  }:start()
end

function M.find_links(opts)
  opts = opts or {}

  local args = {"query"}

  if not opts.back then
    table.insert(args, "--backlinks-of")
  else
    table.insert(args, "--uplinks-of")
  end

  table.insert(args, opts.id or M.get_current_id())

  if opts.cached ~= false then
    table.insert(args, "--cached")
  end

  dump(args)

  Job:new {
    command = "neuron",
    -- args = {"query", "--backlinks-of", opts.id or M.get_current_id(), "--cached"},
    args = args,
    cwd = opts.cwd or config.neuron_dir,
    on_stderr = on_stderr_factory("neuron query --backlinks-of"),
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      _find_zettels {
        json = data,
        entry_maker = gen_from_links
      }
    end)
  }:start()
end

do
  local default_config = {
    neuron_dir = os.getenv("HOME") .. "/" .. "neuron",
  }

  function M.setup(user_config)
    user_config = user_config or {}
    config = vim.tbl_extend("keep", user_config, default_config)
  end
end

return M
