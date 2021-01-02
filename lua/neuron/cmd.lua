local api = vim.api
local utils = require("neuron/utils")
local Job = require("plenary/job")

local M = {}

function M.query(flags, neuron_dir, on_stdout)
  local args = {"query"}
  vim.list_extend(args, flags)

  Job:new {
    command = "neuron",
    args = args,
    cwd = neuron_dir,
    on_stderr = utils.on_stderr_factory("neuron query"),
    on_stdout = vim.schedule_wrap(on_stdout),
  }:start()
end

return M
