local config = require("neuron/config")
local Job = require("plenary/job")
local api = vim.api

local M = {}

function M.query_graph(callback_fn)

  Job:new{
    command = "neuron",
    args = {"-d", config.neuron_dir, "query", "--graph"},
    interactive = false,
    enable_recording = true,
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      local graph = vim.fn.json_decode(data)
      callback_fn(graph)
    end),
  }:start()

end

function Mbuild_table()

  return M.query_graph(function(graph)
    return graph
  end)

end

local basic_data = {
  "zettelTags",
  "zettelDate",
  "zettelID",
  "zettelSlug",
  "zettelPath",
  "zettelTitle",
}

function M.build_table()

  M.query_graph(function(graph)
    NeuronGraph = {}

    local vertices = graph.result.vertices
    local adjacency_map = graph.result.adjacencyMap

    -- Add basic info, e.g zettelDate, zettelTitle etc.
    for zettelid, zetteltbl in pairs(vertices) do

      NeuronGraph[zettelid] = {}

      for k, v in pairs(zetteltbl) do
        if vim.tbl_contains(basic_data, k) then
          NeuronGraph[zettelid][k] = v
        end

      end
    end

    ------------

    for zettelid, v in pairs(adjacency_map) do

      -- vim.tbl_extend("keep", NeuronGraph[zettelid], v)
    end

    print(vim.inspect(NeuronGraph))
  end)
end

return M
