local config = require("neuron/config")
local M = {}

function M.gen_from_zettels(entry)
  -- neuron now inputs this path instead with ./ in front
  if vim.startswith(entry.Path, "./") then
    entry.Path = entry.Path:sub(3)
  end

  local value = string.format("%s/%s", config.neuron_dir, entry.Path)

  local display = entry.Title
  return {display = display, value = value, ordinal = display, id = entry.ID}
end

--- Backlinks or uplinks
function M.gen_from_links(entry)
  local not_folgezettal = entry[2]
  return M.gen_from_zettels(not_folgezettal)
end

function M.gen_from_tags(entry)
  local display = entry.name
  return {display = display, value = display, ordinal = display}
end

return M
