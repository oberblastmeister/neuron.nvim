local api = vim.api
local utils = require("neuron/utils")
local Job = require("plenary/job")

local M = {}

---@param opts table
function M.neuron(opts)
  Job:new {
    command = "neuron",
    args = opts.args,
    cwd = opts.neuron_dir,
    on_stderr = utils.on_stderr_factory(opts.name or "cmd.neuron"),
    on_stdout = vim.schedule_wrap(M.json_stdout_wrap(opts.callback)),
    -- on_stdout = function()
    --   if opts.callback then
    --     vim.schedule_wrap(M.json_stdout_wrap(opts.callback))
    --   end
    -- end,
    interactive = false
  }:start()
end

--- Query content of neuron
---@param arg_opts table
---@param neuron_dir string
---@param json_fn function
function M.query(arg_opts, neuron_dir, json_fn)
  M.neuron {
    args = M.query_arg_maker(arg_opts),
    neuron_dir = neuron_dir,
    name = "cmd.query",
    callback = json_fn
  }
end

---@param opts table
function M.query_arg_maker(opts)
  ---@type table
  local args = {"query"}

  -- if opts.id then
  --   table.insert(args, "--id")
  --   table.insert(args, opts.id)
  -- end

  if opts.uri then
    table.insert(args, "--uri")
    table.insert(args, opts.uri)
    return args
  end

  if opts.up then
    table.insert(args, "--uplinks-of")
    table.insert(args, opts.id)
  elseif opts.back then
    table.insert(args, "--backlinks-of")
    table.insert(args, opts.id)
  end

  if opts.cached ~= false then
    table.insert(args, "--cached")
  end

  return args
end

---@param id string
---@param neuron_dir string
---@param json_fn function
function M.query_id(id, neuron_dir, json_fn)
  M.neuron {
    args = {"query", "--cached", "--id", id},
    neuron_dir = neuron_dir,
    name = "cmd.query_id",
    callback = json_fn
    -- interactive = false
  }
end

--- json_fn takes a json table
function M.json_stdout_wrap(json_fn)
  return function(error, data)
    assert(not error, error)

    json_fn(vim.fn.json_decode(data))
  end
end

function M.new_edit(neuron_dir)
  Job:new {
    command = "neuron",
    args = {"new"},
    cwd = neuron_dir,
    -- on_stderr = utils.on_stderr_factory("neuron new"),
    interactive = false,
    on_stdout = vim.schedule_wrap(
      function(error, data)
        assert(not error, error)

        vim.cmd("edit " .. data)
        utils.start_insert_header()
      end
    ),
    on_exit = utils.on_exit_factory("neuron new")
  }:start()
end

function M.new_and_callback(neuron_dir, callback)
  Job:new {
    command = "neuron",
    args = {"new"},
    cwd = neuron_dir,
    on_stderr = utils.on_stderr_factory("neuron new"),
    on_stdout = vim.schedule_wrap(
      function(error, data)
        assert(not error, error)

        callback(data)
      end
    ),
    on_exit = utils.on_exit_factory("neuron new")
  }:start()
end

function M.gen(neuron_dir)
  Job:new {
    command = "neuron",
    name = "neuron.gen_cache_on_write",
    args = {"gen"},
    cwd = neuron_dir,
    interactive = false
  }:start()
end

return M
