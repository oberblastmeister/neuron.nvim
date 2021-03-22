local Job = require("plenary/job")
local uv = vim.loop
local api = vim.api
local utils = require("neuron/utils")
local config = require("neuron/config")
local cmd = require("neuron/cmd")

local M = {}

local ns

---starts the neuron server and opens it in the browser
---@param opts table: the options for the job
function M.rib(opts)
  assert(not NeuronJob, "you already started a neuron server")

  opts = opts or {}
  opts.address = opts.address or "127.0.0.1:8200"

  NeuronJob = Job:new{
    command = "neuron",
    cwd = config.neuron_dir,
    args = {"rib", "-w", "-s", opts.address},
    name = "neuron.rib",
    on_stderr = nil,
    interactive = false
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

  local open_address = utils.get_localhost_address(opts.address)

  utils.os_open(open_address)
end

function M.stop()
  if NeuronJob ~= nil then
    uv.kill(NeuronJob.pid, 15) -- sigterm
    NeuronJob = nil
  end
end

function M.open_from_server()
  utils.os_open(utils.get_localhost_address(NeuronJob.address))
end

function M.enter_link()
  local word = vim.fn.expand("<cWORD>")

  local id = utils.match_link(word)

  if id == nil then
    vim.cmd("echo 'There is no link under the cursor'")
    return
  end

  cmd.query_id(id, config.neuron_dir, function(json)
    if type(json) ~= "userdata" then
      vim.cmd(string.format("edit %s/%s.md", config.neuron_dir, json.ID))
    end
  end)
end

function M.add_all_virtual_titles(buf)
  for ln, line in ipairs(api.nvim_buf_get_lines(buf, 0, -1, true)) do
    M.add_virtual_title_current_line(buf, ln, line)
  end
end

function M.add_virtual_title_current_line(buf, ln, line)
  if type(line) ~= "string" then
    return
  end
  local id = utils.match_link(line)
  if id == nil then
    return
  end
  local start_col, end_col = utils.find_link(line)
  cmd.query_id(id, config.neuron_dir, function(json)
    if type(json) == "userdata" then
      return
    end
    if json == nil then
      return
    end
    if json.error then
      return
    end
    -- if json.result.Left ~= nil then
    -- minus one to convert from 1 based index to api zero based index
    --   utils.delete_range_extmark(buf, ns, ln - 1, ln)
    --   return
    -- end
    local title = json.Title
    -- lua is one indexed
    api.nvim_buf_set_extmark(buf, ns, ln - 1, start_col - 1, {
      end_col = end_col,
      virt_text = {{title, config.virt_text_highlight}}
    })
  end)
end

function M.update_virtual_titles(buf)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  M.add_all_virtual_titles()
end

function M.attach_buffer_fast()
  local function on_lines(buf, firstline, new_lastline)
    local lines = api.nvim_buf_get_lines(buf, firstline, new_lastline, false)

    if #lines == 0 then
      utils.delete_range_extmark(buf, ns, firstline, new_lastline)
    else
      for i = firstline, new_lastline - 1 do -- minus one because in lua loop range is inclusive
        M.add_virtual_title_current_line(buf, i + 1, lines[i - firstline + 1])
      end
    end
  end

  local task
  api.nvim_buf_attach(0, true, {
    on_lines = vim.schedule_wrap(function(...)
      local empty = task == nil

      task = {...}

      if empty then
        vim.defer_fn(function()
          on_lines(task[2], task[4], task[6])
          task = nil
        end, 350)
      end
    end),
    on_detach = function()
      task = nil
    end
  })
end

local function setup_autocmds()
  local pathpattern = string.format("%s/*.md", config.neuron_dir)
  vim.cmd [[augroup Neuron]]
  vim.cmd [[au!]]
  if config.gen_cache_on_write == true then
    vim.cmd(string.format(
                "au BufWritePost %s lua require'neuron/cmd'.gen(require'neuron/config'.neuron_dir)",
                pathpattern))
  end
  if config.virtual_titles == true then
    vim.cmd(string.format(
                "au BufRead %s lua require'neuron'.add_all_virtual_titles()",
                pathpattern))
    vim.cmd(string.format(
                "au BufRead %s lua require'neuron'.attach_buffer_fast()",
                pathpattern))
  end
  if config.mappings == true then
    require"neuron/mappings".setup()
  end
  if config.run ~= nil then
    vim.cmd(string.format("au BufRead %s lua require'neuron/config'.run()",
                          pathpattern))
  end
  vim.cmd [[augroup END]]
end

---This is the entry point to the function
---@param user_config table: the config you want to use. Will be merged into the default config
function M.setup(user_config)
  if vim.fn.executable("neuron") == 0 then
    error("neuron is not executable")
  end

  user_config = user_config or {}

  config:setup(user_config)

  ns = api.nvim_create_namespace("neuron.nvim")

  setup_autocmds()
end

function M.goto_next_link()
  local tuple = M.next_link_idx()
  if tuple ~= nil then
    api.nvim_win_set_cursor(0, tuple)
  else
    error("No more next links")
  end
end

function M.goto_next_extmark()
  local tuple = api.nvim_win_get_cursor(0) -- (1, 0) based index
  tuple[1] = tuple[1] - 1 -- convert to zero based

  local extmarks = api.nvim_buf_get_extmarks(0, ns, {tuple[1], tuple[2] + 1},
                                             -1, {}) -- plus one because we don't want the current extmark

  local next_extmark = extmarks[1]
  if next_extmark == nil then
    error("No more next extmarks")
  end

  api.nvim_win_set_cursor(0, {next_extmark[2] + 1, next_extmark[3]})
end

function M.goto_prev_extmark()
  local tuple = api.nvim_win_get_cursor(0) -- (1, 0) based index
  tuple[1] = tuple[1] - 1 -- convert to zero based

  local extmarks = api.nvim_buf_get_extmarks(0, ns, {tuple[1], tuple[2] - 1}, 0,
                                             {}) -- plus one because we don't want the current extmark

  local next_extmark = extmarks[1]
  if next_extmark == nil then
    error("No more previous extmarks")
  end

  api.nvim_win_set_cursor(0, {next_extmark[2] + 1, next_extmark[3]})
end

function M.goto_index()
  vim.cmd(string.format("edit %s/index.md", config.neuron_dir))
end

return M
