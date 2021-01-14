local Job = require("plenary/job")
local uv = vim.loop
local api = vim.api
local utils = require("neuron/utils")
local cmd = require("neuron/cmd")

local M = {}

local ns

function M.rib(opts)
  assert(not NeuronJob, "you already started a neuron server")

  opts = opts or {}
  opts.address = opts.address or "127.0.0.1:8200"
  -- opts.open = opts.open or true

  NeuronJob = {}
  NeuronJob =
    Job:new {
    command = "neuron",
    cwd = M.config.neuron_dir,
    args = {"rib", "-w", "-s", opts.address},
    name = "neuron.rib",
    on_stderr = nil,
    interactive = false
  }
  NeuronJob.address = opts.address
  NeuronJob:start()

  vim.cmd [[augroup NeuronJobStop]]
  vim.cmd [[au!]]
  vim.cmd [[au VimLeave * lua require'neuron'.stop()]]
  vim.cmd [[augroup END]]

  if opts.verbose then
    print("Started neuron server at", opts.address)
  end

  local open_address = utils.get_localhost_address(opts.address)

  utils.os_open(open_address)
end

function M.stop()
  if NeuronJob ~= nil then
    uv.kill(NeuronJob.pid, 15) -- sigterm
    NeuronJob = nil
  end
end

function M.open_from_server(opts)
  opts = opts or {}

  utils.os_open(utils.get_localhost_address(NeuronJob.address))
end

function M.enter_link()
  local word = vim.fn.expand("<cWORD>")

  local id = utils.match_link(word)

  if id == nil then
    vim.cmd("echo 'There is no link under the cursor'")
    return
  end

  cmd.query_id(
    id,
    M.config.neuron_dir,
    function(json)
      -- vim.cmd("edit " .. json.result.zettelPath)
      if json.result.Left ~= nil then
        return
      end
      vim.cmd(string.format("edit %s/%s.md", M.config.neuron_dir, json.result.Right.zettelID))
    end
  )
end

function M.add_all_virtual_titles(buf)
  for ln, line in ipairs(api.nvim_buf_get_lines(buf, 0, -1, true)) do
    M.add_virtual_title_current_line(buf, ln, line)
  end
end

function M.add_virtual_title_current_line(buf, ln, line)
  if type(line) ~= "string" then
    return
  end
  local id = utils.match_link(line)
  if id == nil then
    return
  end
  local start_col, end_col = utils.find_link(line)
  cmd.query_id(
    id,
    M.config.neuron_dir,
    function(json)
      if type(json) == "userdata" then
        return
      end
      if json == nil then
        return
      end
      if json.error then
        return
      end
      if json.result.Left ~= nil then
        utils.delete_range_extmark(buf, ns, ln - 1, ln) -- minus one to convert from 1 based index to api zero based index
        return
      end
      local title = json.result.Right.zettelTitle
      -- lua is one indexed
      api.nvim_buf_set_extmark(
        buf,
        ns,
        ln - 1,
        start_col - 1,
        {
          end_col = end_col,
          virt_text = {{title, "Comment"}}
        }
      )
    end
  )
end

function M.update_virtual_titles(buf)
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  M.add_all_virtual_titles()
end

function M.attach_buffer_fast()
  local function on_lines(buf, firstline, new_lastline)
    -- -- local params = {...}
    -- local buf = params[2]
    -- -- local changedtick = params[3]
    -- local firstline = params[4]
    -- -- local lastline = params[5]
    -- local new_lastline = params[6]

    local lines = api.nvim_buf_get_lines(buf, firstline, new_lastline, false)

    if #lines == 0 then
      -- local extmarks = api.nvim_buf_get_extmarks(0, ns, {firstline, 0}, {new_lastline, 0}, {})
      -- for _, v in ipairs(extmarks) do
      --   api.nvim_buf_del_extmark(buf, ns, v[1])
      -- end
      utils.delete_range_extmark(buf, ns, firstline, new_lastline)
    else
      for i = firstline, new_lastline - 1 do -- minus one because in lua loop range is inclusive
        -- local async
        -- async =
        --   uv.new_async(
        --   vim.schedule_wrap(
        --     function(...)
        --       M.add_virtual_title_current_line(...)
        --       async:close()
        --     end
        --   )
        -- )
        M.add_virtual_title_current_line(buf, i + 1, lines[i - firstline + 1])
        -- async:send(buf, i + 1, lines[i - firstline + 1])
      end
    end
  end

  local task
  api.nvim_buf_attach(
    0,
    true,
    {
      on_lines = vim.schedule_wrap(
        function(...)
          local empty = task == nil

          task = {...}

          if empty then
            vim.defer_fn(
              function()
                on_lines(task[2], task[4], task[6])
                task = nil
              end,
              350
            )
          end
        end
      ),
      on_detach = function()
        task = nil
      end
    }
  )
end

local default_config = {
  neuron_dir = "~/neuron",
  gen_cache_on_write = true,
  mappings = true, -- to set default mappings
  virtual_titles = true, -- set virtual titles
  run = nil, -- custom code to run
  leader = "gz" -- the leader key to for all mappings
}

local function setup_autocmds()
  local pathpattern = string.format("%s/*.md", M.config.neuron_dir)
  vim.cmd [[augroup Neuron]]
  vim.cmd [[au!]]
  if M.config.gen_cache_on_write == true then
    vim.cmd(string.format("au BufWritePost %s lua require'neuron/cmd'.gen(require'neuron'.config.neuron_dir)", pathpattern))
  end
  if M.config.virtual_titles == true then
    vim.cmd(string.format("au BufRead %s lua require'neuron'.add_all_virtual_titles()", pathpattern))
    vim.cmd(string.format("au BufRead %s lua require'neuron'.attach_buffer_fast()", pathpattern))
  end
  if M.config.mappings == true then
    require "neuron/mappings".setup()
  end
  if M.config.run ~= nil then
    vim.cmd(string.format("au BufRead %s lua require'neuron'.config.run()", pathpattern))
  end
  vim.cmd [[augroup END]]
end

---@param user_config table
function M.setup(user_config)
  if vim.fn.executable("neuron") == 0 then
    error("neuron is not executable")
  end

  user_config = user_config or {}
  -- assert(type(user_config) == "table", "[neuron.setup] - ")
  M.config = vim.tbl_extend("keep", user_config, default_config)
  M.config.neuron_dir = vim.fn.expand(M.config.neuron_dir)

  ns = api.nvim_create_namespace("neuron.nvim")

  setup_autocmds()
end

-- local tuple = {}

function M.goto_next_link()
  local tuple = M.next_link_idx()
  if tuple ~= nil then
    api.nvim_win_set_cursor(0, tuple)
  else
    error("No more next links")
  end
end

function M.goto_next_extmark()
  local tuple = api.nvim_win_get_cursor(0) -- (1, 0) based index
  tuple[1] = tuple[1] - 1 -- convert to zero based

  local extmarks = api.nvim_buf_get_extmarks(0, ns, {tuple[1], tuple[2] + 1}, -1, {}) -- plus one because we don't want the current extmark

  local next_extmark = extmarks[1]
  if next_extmark == nil then
    error("No more next extmarks")
  end

  api.nvim_win_set_cursor(0, {next_extmark[2] + 1, next_extmark[3]})
end

function M.goto_prev_extmark()
  local tuple = api.nvim_win_get_cursor(0) -- (1, 0) based index
  tuple[1] = tuple[1] - 1 -- convert to zero based

  local extmarks = api.nvim_buf_get_extmarks(0, ns, {tuple[1], tuple[2] - 1}, 0, {}) -- plus one because we don't want the current extmark

  local next_extmark = extmarks[1]
  if next_extmark == nil then
    error("No more previous extmarks")
  end

  api.nvim_win_set_cursor(0, {next_extmark[2] + 1, next_extmark[3]})
end

function M.goto_index()
  vim.cmd(string.format("edit %s/index.md", M.config.neuron_dir))
end

return M
