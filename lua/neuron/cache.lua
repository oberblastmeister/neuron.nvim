require"neuron".setup()

local Job = require("plenary/job")
local config = require("neuron/config")

local M = {}

function M.neuronCommand(opts)
  opts = opts or {}

  opts.args = opts.args or {"query"}

  Job:new{
    command = "neuron",
    args = opts.args,
    cwd = opts.cwd or config.neuron_dir,
    on_start = opts.on_start or nil,
    on_stderr = opts.on_stderr or nil,
    on_stdout = vim.schedule_wrap(opts.on_stdout) or nil,
    enable_recording = true,
    interactive = false,
  }:start()

end

local on_start = function()
  vim.cmd("echo 'Hello Pis-Hans'")
end

local function on_stdout()

  return function(error, data)
    assert(not error, tostring(error))

    data = vim.fn.json_decode(data)

    result_table = {}
    for _, zettels in pairs(data.result) do
      for k, v in pairs(zettels) do
        if k == "zettelID" then table.insert(result_table, v) end
      end
    end
    print(vim.inspect(result_table))

  end

end

-- local function on_exit()
--   return
-- end
function Example()

  M.neuronCommand({
    -- args = {},
    cwd = "~/neuron",
    on_start = on_start(),
    on_stdout = on_stdout(),
    -- on_exit = on_exit(),
  })

end

return M
