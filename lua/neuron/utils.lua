local api = vim.api
local uv = vim.loop
local Job = require("plenary/job")

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

function M.on_stderr_factory(name)
  return vim.schedule_wrap(function(error, data)
    assert(not error, error)
    if data ~= nil then
      vim.cmd(string.format("echoerr 'An error occured from running %s: %s'",
                            name, data))
    end
  end)
end

function M.on_exit_factory(name)
  return vim.schedule_wrap(function(self, code, _signal)
    if code ~= 0 then
      error(string.format("The job %s exited with a non-zero code: %s", name,
                          code))
    end
  end)
end

function M.feedkeys(string, mode)
  api.nvim_feedkeys(api.nvim_replace_termcodes(string, true, true, true), mode,
                    true)
end

function M.feedraw(s)
  api.nvim_feedkeys(s, "n", false)
end

local TRIPLE_LINK_RE = "%[%[%[(%w+)%]%]%]"
local DOUBLE_LINK_RE = "%[%[(%w+)%]%]"

---@param s string
function M.match_link(s)
  return s:match(TRIPLE_LINK_RE) or s:match(DOUBLE_LINK_RE)
end

function M.find_link(s)
  return s:find(TRIPLE_LINK_RE) or s:find(DOUBLE_LINK_RE)
end

function M.get_cword()
  -- (1,0)-indexed (row, col) tuple cursor position in window 0 (current window)
  local pos = vim.api.nvim_win_get_cursor(0)
  -- string
  local line = vim.api.nvim_get_current_line()
  local pattern = ("\\v\\k*%%%sc\\k+"):format(pos[2] + 1)
  local str, start_byte = unpack(vim.fn.matchstrpos(line, pattern))
  if start_byte == -1 then
    return
  end
  local after_part = vim.fn.strpart(line, start_byte)
  local start = #line - #after_part
  local finish = start + #str
  return {str = str, start = start, finish = finish}
end

-- Creates a link
-- visual)
function M.create_link(visual)
  local word

  if visual then
    word = M.get_visual()
  else
    word = M.get_cword()
  end

  if not word then
    return
  end

  print(string.format("found: %s", vim.inspect(word)))

  local line = api.nvim_get_current_line()
  -- -- local file_name =
end

function M.get_link()
  line = vim.api.nvim_get_current_line()
  local x = vim.api.nvim_win_get_cursor(0)[2] + 1

  for v in M.scanner(line) do
    if x >= v.start and x <= v.finish then
      return v
    end
  end
end

-- https://github.com/srid/neuron/blob/8d9bc7341422a2346d8fd6dc35624723c6525f40/neuron/src/lib/Neuron/Zettelkasten/ID.hs#L83
local allowed_chars = {
  "_",
  "-",
  ".",
  -- Whitespace is essential for title IDs
  -- This gets replaced with underscore in ID slug
  " ",
  -- Allow some puctuation letters that are common in note titles
  ",",
  ";",
  "(",
  ")",
  ":",
  "\"",
  "'",
}

function M.scanner(line)
  local pos = 1
  return function()
    while true do
      -- TODO: Is the "%b[]" enough? <20-01-21, Frands Otting> --
      local start, finish = line:find("%b[]", pos)

      if not start then
        break
      end

      pos = finish + 1

      str = line:sub(start, finish)

      -- TODO: Check for allowed_chars see above ^^^ Frands --
      return {
        str = str,
        zettelID = str:match("%[(.-[^%[%]]+)%]"),
        start = start,
        finish = finish,
      }
    end
  end
end

local function msub(line, s, f)
  return line:sub(s, f) .. vim.fn.strcharpart(line:sub(f + 1), 0, 1)
end

function M.get_visual()
  local s = vim.fn.getpos("'<")
  local f = vim.fn.getpos("'>")

  if s[2] ~= f[2] then
    return vim.cmd(
             [[echo "Selection spans multiple lines - Only single line links allowed"]])
  end

  local str = msub(vim.api.nvim_get_current_line(), s[3], f[3] - 1)
  local start = s[3] - 1
  local finish = start + str:len()

  return {str = str, start = start, finish = finish}
end

-- deletes a range of extmarks line wise, zero based index
function M.delete_range_extmark(buf, namespace, start, finish)
  local extmarks = api.nvim_buf_get_extmarks(buf, namespace, {start, 0},
                                             {finish, 0}, {})
  for _, v in ipairs(extmarks) do
    api.nvim_buf_del_extmark(buf, namespace, v[1])
  end
end

function M.os_open(path)
  local os = uv.os_uname().sysname

  local open_cmd
  if os == "Linux" then
    open_cmd = "xdg-open"
  elseif os == "Windows" then
    open_cmd = "start"
  elseif os == "Darwin" then
    open_cmd = "open"
  end

  Job:new{
    command = open_cmd,
    args = {path},
    on_stderr = M.on_stderr_factory(open_cmd),
  }:start()
end

function M.get_localhost_address(s)
  return s:gsub(".+(:%d+)", "http://localhost%1")
end

function M.get_current_id()
  return vim.fn.expand("%:t:r")
end

function M.start_insert_header()
  M.feedkeys("Go<CR>#<space>", "n")
end

return M
