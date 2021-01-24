local config = require("neuron/config")
local Job = require("plenary/job")
local api = vim.api
local utils = require("neuron/utils")

local M = {}
local ns = api.nvim_create_namespace("neuron.nvim")

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

function M.add_all_virtual_titles(buf)
  local cur_zettelid = utils.get_current_id()
  if not NeuronGraph[cur_zettelid]["connections"] then
    return
  end

  local links_to = NeuronGraph[cur_zettelid]["connections"]

  for ln, line in ipairs(api.nvim_buf_get_lines(buf, 0, -1, true)) do
    M.add_virtual_title_current_line(buf, ln, line, links_to)
  end
end

function M.add_virtual_title_current_line(buf, ln, line, connections)
  local ordinary_links
  local folgezettels
  if connections["ordinary"] then
    ordinary_links = connections["ordinary"]
  end
  if connections["folgezettel"] then
    folgezettels = connections["folgezettel"]
  end
  print(vim.inspect(folgezettels))
  print(vim.inspect(ordinary_links))
  assert(1 == 2)

  -- TODO: Add link scanner from utils branch --
  -- local id = utils.match_link(line)
  -- if id == nil then
  --   return
  -- end
  -- local start_col, end_col = utils.find_link(line)

  -- Todo: add array of titles, if line contains more than one link
  local title
  -- lua is one indexed
  api.nvim_buf_set_extmark(buf, ns, ln - 1, start_col - 1, {
    end_col = end_col,
    virt_text = {{title, config.virt_text_highlight}},
  })
  -- TODO: Remove this query and use NeuronGraph instead
  -- cmd.query_id(id, config.neuron_dir, function(json)
  --   if type(json) == "userdata" then
  --     return
  --   end
  --   if json == nil then
  --     return
  --   end
  --   if json.error then
  --     return
  --   end
  --   if json.result.Left ~= nil then
  --     utils.delete_range_extmark(buf, ns, ln - 1, ln) -- minus one to convert from 1 based index to api zero based index
  --     return
  --   end
  -- local title = json.result.Right.zettelTitle
  -- -- lua is one indexed
  -- api.nvim_buf_set_extmark(buf, ns, ln - 1, start_col - 1, {
  --   end_col = end_col,
  --   virt_text = {{title, config.virt_text_highlight}},
  -- })
  -- end)
end

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

    print("Caching Neuron data...")
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

    M.add_all_virtual_titles()
    print("Done caching Neuron..")
  end)
end

return M
