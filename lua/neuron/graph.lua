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

  local basic_data = {
    "zettelTags",
    "zettelDate",
    "zettelID",
    "zettelSlug",
    "zettelPath",
    "zettelTitle",
  }

  M.query_graph(function(graph)

    NeuronGraph = {}

    -- Parts of the json output to go trough
    local vertices = graph.result.vertices
    local adjacency_map = graph.result.adjacencyMap
    local skipped = graph.skipped

    -----------------------
    --  Find basic info  --
    -----------------------
    --
    -- Add basic info, e.g zettelDate, zettelTitle etc.
    --
    for zettelid, zetteltbl in pairs(vertices) do

      NeuronGraph[zettelid] = {}

      for k, v in pairs(zetteltbl) do
        if vim.tbl_contains(basic_data, k) then
          if v ~= vim.NIL then
            NeuronGraph[zettelid][k] = v
          end
        end

      end
    end

    ------------------------
    --  Find connections  --
    ------------------------
    --
    -- go trough adjacencyMap
    --
    for zettelid, links in pairs(adjacency_map) do
      for k, v in pairs(links) do

        if not NeuronGraph[zettelid]["connections"] then
          NeuronGraph[zettelid]["connections"] = {}
        end

        if v[1] == "Folgezettel" then
          if not NeuronGraph[zettelid]["connections"]["folgezettel"] then
            NeuronGraph[zettelid]["connections"]["folgezettel"] = {}
          end
          table.insert(NeuronGraph[zettelid]["connections"]["folgezettel"], k)
        end

        if v[1] == "OrdinaryConnection" then
          if not NeuronGraph[zettelid]["connections"]["ordinary"] then
            NeuronGraph[zettelid]["connections"]["ordinary"] = {}
          end
          table.insert(NeuronGraph[zettelid]["connections"]["ordinary"], k)
        end
      end
    end

    -------------------
    --  Find issues  --
    -------------------
    --
    -- find missing links. If a valid link doesn't lead to a existing note
    --
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

    print(vim.inspect(NeuronGraph))

  end)
end

return M
