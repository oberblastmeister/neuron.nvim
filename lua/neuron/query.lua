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

--- Get all existing zettelIDs
function M.existing_zettelID()

  local on_start = function()
    vim.cmd("echo 'Hi I'm Frands")
  end

  local function on_stdout()

    return function(error, data)
      assert(not error, tostring(error))

      data = vim.fn.json_decode(data)

      all_zettels = {}
      for _, zettels in pairs(data.result) do
        for k, v in pairs(zettels) do
          if k == "zettelID" then
            table.insert(all_zettels, v)
          end
        end
      end
      print(vim.inspect(all_zettels))

    end

  end

  -- TODO: use already available functions  --
  M.neuronCommand({
    -- Where to run the command
    cwd = "~/neuron",
    -- function on start
    on_start = on_start(),
    -- function on std. In this case json output
    on_stdout = on_stdout(),
  })

end

return M
