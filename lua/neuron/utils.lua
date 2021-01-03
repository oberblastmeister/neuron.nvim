local api = vim.api
local Job = require("plenary/job")

local M = {}

function M.path_from_id(id, neuron_dir, callback)
  assert(id, "the id should not be nil")

  Job:new {
    command = "neuron",
    args = {"query", "--id", id, "--cached"},
    cwd = neuron_dir,
    on_stderr = M.on_stderr_factory("neuron query --id"),
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      local path = vim.fn.json_decode(data).result.zettelPath
      callback(path)
    end)
  }:start()
end

function M.on_stderr_factory(name)
  return vim.schedule_wrap(function(error, data)
    assert(not error, error)
    vim.cmd(string.format("echoerr 'An error occured from running %s: %s'", name, data))
  end)
end

function M.on_exit_factory(name)
  return vim.schedule_wrap(function(self, code, _signal)
    if code ~= 0 then
      error(string.format("The job %s exited with a non-zero code: %s", name, code))
    end
  end)
end

function M.feedkeys(string, mode)
  api.nvim_feedkeys(api.nvim_replace_termcodes(string, true, true, true), mode, true)
end

function M.match_link(s)
  local maybe_folgezettel = string.match(s, '%[%[%[(%w%w%w%w%w%w%w%w)%]%]%]') -- kinda dumb lua regex, matches 8 alphanum

  if maybe_folgezettel == nil then
    maybe_folgezettel =  string.match(s, '%[%[(%w%w%w%w%w%w%w%w)%]%]')
  end

  return maybe_folgezettel
end

function M.match_link_idx(string)
  local i, j = string.find(string, '%[%[(%w%w%w%w%w%w%w%w)%]%]')
  return i, j
end

-- deletes a range of extmarks line wise, zero based index
function M.delete_range_extmark(buf, namespace, start, finish)
  local extmarks = api.nvim_buf_get_extmarks(buf, namespace, {start, 0}, {finish, 0}, {})
  for _, v in ipairs(extmarks) do
    api.nvim_buf_del_extmark(buf, namespace, v[1])
  end
end

return M
