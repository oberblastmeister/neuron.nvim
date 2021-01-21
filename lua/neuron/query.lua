local Job = require("plenary/job")
local config = require("neuron/config")

local M = {}

function M.path_from_id(id, neuron_dir, callback)
  assert(id, "the id should not be nil")

  Job:new{
    command = "neuron",
    args = {"query", "--id", id, "--cached"},
    cwd = neuron_dir,
    on_stderr = M.on_stderr_factory("neuron query --id"),
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      local path = vim.fn.json_decode(data).result.Right.zettelPath
      callback(path)
    end),
  }:start()
end

M.ZettelIDs = {}

--- Get all existing zettelIDs
-- function M.existing_zettelID()

--   local on_start = function()
--     return vim.cmd([["echo 'Hi I'm Frands"]])
--   end

--   local on_stdout = function(error, data)
--     assert(not error, tostring(error))

--     return function(data)

--     end
--     json = vim.fn.json_decode(data)

--     for _, zettels in pairs(json.result) do
--       for k, v in pairs(zettels) do
--         if k == "zettelID" then
--           table.insert(M.ZettelIDs, v)
--         end
--       end
--     end
--   end

--   -- TODO: use already available functions  --
--   cmd_result = M.neuronCommand({
--     -- Where to run the command
--     cwd = "~/neuron",
--     -- args = {"query"},
--     -- function on start
--     on_start = on_start,
--     -- function on std. In this case json output
--     on_stdout = on_stdout,
--   })

-- end

return M
