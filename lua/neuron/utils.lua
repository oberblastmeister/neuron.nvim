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
  local folgezettel = string.match(s, '%[%[%[(.+)%]%]%]') -- if it is [[id]]

  if folgezettel == nil then
    folgezettel =  string.match(s, '%[%[(.+)%]%]')
  end

  return folgezettel

  -- local right_id = s.match(left_id or '', '%[(.*)%]') -- check if there is one more layer of [], if it is [[[id]]]
  -- return right_id or left_id
end

function M.match_link_idx(string)
  local i, j = string.find(string, '%[%[(.+)%]%]')
  return i, j
end

return M
