local config = require("neuron/config")
local Job = require("plenary/job")

local M = {}

function M.query_graph(callback_fn)

  Job:new{
    command = "neuron",
    args = {"-d", config.neuron_dir, "query", "--graph", "--cached"},
    interactive = false,
    enable_recording = true,
    on_stdout = vim.schedule_wrap(M.wrap_json(callback_fn)),
  }:start()
end

function M.wrap_json(callback_fn)

  return function(error, data)
    assert(not error, error)

    -- local decoded_data = vim.fn.json_decode(data)
    local decoded_data = vim.fn.json_decode(data)
    callback_fn(decoded_data)
  end
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

    -- Parts of the json output to go trough
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

    -- find connections
    for zettelid, links in pairs(adjacency_map) do
      NeuronGraph[zettelid]["connections"] = {}
      for k, v in pairs(links) do
        NeuronGraph[zettelid]["connections"][k] = v[1]
      end
    end
    ---------------------------------------------

    -- find missing links. If a valid link doesn't lead to a existing note
    for zettelid, issues in pairs(skipped) do
      NeuronGraph[zettelid]["issues"] = {}
      for _, v in pairs(issues) do
        if v == "ZettelIssue_MissingLinks" then
          NeuronGraph[zettelid]["issues"]["missing_links"] = {}
          NeuronGraph[zettelid]["issues"]["missing_links"] =
            issues["contents"][2]
        end
      end
    end
    --------------------------------------

    print(vim.inspect(NeuronGraph))
  end)
end

return M
