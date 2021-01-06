local api = vim.api
local neuron = require("neuron")

local M = {}

function M.map(key, rhs)
  local lhs = string.format("%s%s", neuron.config.leader, key)
  api.nvim_buf_set_keymap(0, 'n', lhs, rhs, {noremap = true, silent = true})
end

function M.set_keymaps()
  api.nvim_buf_set_keymap(0, 'n', "<CR>", ":lua require'neuron'.enter_link()<CR>", {noremap = true, silent = true})
  M.map("<CR>", ":lua require'neuron'.enter_link()<CR>")

  M.map("n", ":lua require'neuron/cmd'.new_edit(require'neuron'.config.neuron_dir)<CR>")

  M.map("z", ":lua require'neuron/telescope'.find_zettels()<CR>")
  M.map("Z", ":lua require'neuron/telescope'.find_zettels {insert = true}<CR>")

  M.map("b", ":lua require'neuron/telescope'.find_backlinks()<CR>")
  M.map("B", ":lua require'neuron/telescope'.find_backlinks {insert = true}<CR>")

  M.map("t", ":lua require'neuron/telescope'.find_tags()<CR>")

  M.map("s", [[:lua require'neuron'.rib {address = "127.0.0.1:8200", verbose = true}<CR>]])

  M.map("]", ":lua require'neuron'.goto_next_extmark()<CR>")
  M.map("[", ":lua require'neuron'.goto_prev_extmark()<CR>")
end

function M.setup()
  vim.cmd(string.format("au BufRead %s/*.md lua require'neuron/mappings'.set_keymaps()", neuron.config.neuron_dir))
end

return M
