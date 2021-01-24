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
  assert(cur_zettelid)

  -- if not NeuronGraph[cur_zettelid]["connections"]
  --   or NeuronGraph[cur_zettelid]["issues"] then
  --   return
  -- end

  local zettel_info = NeuronGraph[cur_zettelid]

  for ln, line in ipairs(api.nvim_buf_get_lines(buf, 0, -1, true)) do
    M.add_virtual_title_current_line(buf, ln, line, zettel_info)
  end
end

function M.add_virtual_title_current_line(buf, ln, line, zettel_info)

  local links_to_find = nil
  local issues_to_find = nil

  if zettel_info.connections.ordinary then
    local ord_links = zettel_info.connections.ordinary
    for ol in pairs(ord_links) do
      -- print(vim.inspect(ord_links[ol]))
      local get_zettel_info = NeuronGraph[ord_links[ol]]
      -- TODO: Use scanner here <24-01-21, Frands Otting> --
      -- TODO: don't find link title, unless there's a valid link <24-01-21, Frands Otting> --
      local link_title = get_zettel_info["zettelTitle"]
      if link_title then
        if not links_to_find then
          links_to_find = {}
        end
        if not links_to_find.ordinary_links then
          links_to_find["ordinary_links"] = {}
        end
        links_to_find["ordinary_links"][ord_links[ol]] = link_title
      end
    end
    print(vim.inspect(links_to_find))
  end

  if zettel_info.connections.folgezettel then
    local folgezettels = zettel_info.connections.folgezettel
    for fz in pairs(folgezettels) do
      -- print(vim.inspect(folgezettels[fz]))
      local get_zettel_info = NeuronGraph[folgezettels[fz]]
      -- TODO: Use scanner here <24-01-21, Frands Otting> --
      -- TODO: don't find link title, unless there's a valid link <24-01-21, Frands Otting> --
      local link_title = get_zettel_info["zettelTitle"]
      if link_title then
        if not links_to_find then
          links_to_find = {}
        end
        if not links_to_find.folgezettels then
          links_to_find["folgezettels"] = {}
        end
        links_to_find["folgezettels"][folgezettels[fz]] = link_title
      end
    end
    print(vim.inspect(links_to_find))
  end

  if zettel_info.issues then
    local cur_issues = zettel_info.issues
    for issue, _ in pairs(cur_issues) do
      -- print(vim.inspect(issue))
      for _, v in pairs(cur_issues[issue]) do
        -- print(vim.inspect(v))
        if not issues_to_find then
          issues_to_find = {}
        end
        if not issues_to_find[issue] then
          issues_to_find[issue] = {}
        end
        table.insert(issues_to_find[issue], v)
      end
    end
    print(vim.inspect(issues_to_find))
  end

  assert(1 == 2)

  -- local local_line = line
  -- TODO: Add link scanner from utils branch --
  -- local id = utils.match_link(line)
  -- if id == nil then
  --   return
  -- end
  local start_col, end_col = utils.find_link(line)

  -- Todo: add array of titles when line contains more than one link
  local title
  -- lua is one indexed
  api.nvim_buf_set_extmark(buf, ns, ln - 1, start_col - 1, {
    end_col = end_col,
    virt_text = {{title, config.virt_text_highlight}},
  })
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
