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

local M = {}

local ns

function M.rib(opts)
  assert(not NeuronJob, "you already started a neuron server")

  opts = opts or {}
  opts.address = opts.address or "127.0.0.1:8080"

  NeuronJob = Job:new {
    command = "neuron",
    cwd = vim.g.neuron_directory or "~/neuron",
    args = {"rib", "-w", "-s", opts.address},
    on_stderr = utils.on_stderr_factory("neuron rib"),
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
    on_stderr = utils.on_stderr_factory("neuron open"),
    on_exit = utils.on_exit_factory("neuron open"),
  }:start()
end

function M.new(opts)
  opts = opts or {}

  Job:new {
    command = "neuron",
    args = {"new"},
    cwd = M.config.neuron_dir,
    on_stderr = utils.on_stderr_factory("neuron new"),
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      vim.cmd("edit " .. data)
      utils.feedkeys("Go<CR>#<space>", 'n')
    end),
    on_exit = utils.on_exit_factory("neuron new"),
  }:start()
end

local function gen_from_zettels(entry)
  local value = string.format("%s/%s", M.config.neuron_dir, entry.zettelPath)
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
    args = {"query", "--cached"},
    cwd = opts.cwd or M.config.neuron_dir,
    on_stderr = utils.on_stderr_factory("neuron query"),
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      _find_zettels {json = data}
    end)
  }:start()
end

function M.find_links(opts)
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
    cwd = opts.cwd or M.config.neuron_dir,
    on_stderr = utils.on_stderr_factory("neuron query --backlinks-of"),
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      _find_zettels {
        json = data,
        entry_maker = gen_from_links
      }
    end)
  }:start()
end

function M.enter_link()
  local word = vim.fn.expand("<cWORD>")

  local id = utils.match_link(word)

  if id == nil then
    error("There is no link under the cursor")
  end

  cmd.query_id(id, M.config.neuron_dir, function(json)
    vim.cmd("edit " .. json.result.zettelPath)
  end)
end

function M.add_virtual_titles(buf)
  for ln, line in ipairs(api.nvim_buf_get_lines(buf, 0, -1, true)) do
    if line ~= nil or line ~= "" then
      local start_col, end_col = utils.match_link_idx(line)
      local id = utils.match_link(line)
      print('id is', id)
      if id then
        cmd.query_id(id, M.config.neuron_dir, function(json)
          if json.error then
            return
          end

          local title = json.result.zettelTitle
          -- lua is one indexed
          -- api.nvim_buf_set_virtual_text(buf, ns, ln - 1, {{title, "TabLineFill"}}, {})
          api.nvim_buf_set_extmark(buf, ns, ln - 1, start_col - 1, {
            end_col = end_col - 1,
            virt_text = {{title, "TabLineFill"}},
          })
        end)
      end
    end
  end
end

function M.update_virtual_titles(buf)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  M.add_virtual_titles()
end

do
  local lock = false

  function M.attach_buffer()
    api.nvim_buf_attach(0, true, {
        on_lines = vim.schedule_wrap(function(...)
          local params = {...}

          if lock == false then
            vim.defer_fn(function()
              M.update_virtual_titles(params[2])

              -- done
              lock = false
            end, 200)

            lock = true
          end
        end)
      })
  end
end

do
  local default_config = {
    neuron_dir = os.getenv("HOME") .. "/" .. "neuron",
  }

  local function setup_autocmds()
    vim.cmd [[augroup NeuronVirtualText]]
    vim.cmd [[au!]]
    vim.cmd [[au BufRead * lua require'neuron'.update_virtual_titles()]]
    vim.cmd [[au BufRead * lua require'neuron'.attach_buffer()]]
    vim.cmd [[augroup END]]
  end

  function M.setup(user_config)
    user_config = user_config or {}
    M.config = vim.tbl_extend("keep", user_config, default_config)
    ns = api.nvim_create_namespace("neuron.nvim")

    setup_autocmds()
  end
end

return M
