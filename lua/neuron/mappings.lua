local api = vim.api
local config = require("neuron/config")

local M = {}

function M.map_buf(key, rhs)
  local lhs = string.format("%s%s", config.leader, key)
  api.nvim_buf_set_keymap(0, "n", lhs, rhs, {noremap = true, silent = true})
end

function M.map(key, rhs)
  local lhs = string.format("%s%s", config.leader, key)
  api.nvim_set_keymap("n", lhs, rhs, {noremap = true, silent = true})
end

function M.set_keymaps()
  api.nvim_buf_set_keymap(0, "n", "<CR>",
                          ":lua require'neuron'.enter_link()<CR>",
                          {noremap = true, silent = true})
  -- M.map_buf("<CR>", "<cmd>lua require'neuron'.enter_link()<CR>")

  M.map_buf("n",
            "<cmd>lua require'neuron/cmd'.new_edit(require'neuron/config'.neuron_dir)<CR>")

  M.map_buf("z", "<cmd>lua require'neuron/telescope'.find_zettels()<CR>")
  M.map_buf("Z",
            "<cmd>lua require'neuron/telescope'.find_zettels {insert = true}<CR>")

  M.map_buf("b", "<cmd>lua require'neuron/telescope'.find_backlinks()<CR>")
  M.map_buf("B",
            "<cmd>lua require'neuron/telescope'.find_backlinks {insert = true}<CR>")

  M.map_buf("t", "<cmd>lua require'neuron/telescope'.find_tags()<CR>")

  M.map_buf("s", "<cmd>lua require'neuron'.rib()<CR>")

  M.map_buf("]", "<cmd>lua require'neuron'.goto_next_extmark()<CR>")
  M.map_buf("[", "<cmd>lua require'neuron'.goto_prev_extmark()<CR>")

  api.nvim_buf_set_keymap(0, "v", "<CR>",
                          ":lua require'neuron/utils'.create_link(1)<CR>",
                          {noremap = true})
  M.map_buf("j", "<cmd>lua require'neuron/utils'.get_link()<CR>")
end

function M.setup()
  vim.cmd(string.format(
            "au BufRead %s/*.md lua require'neuron/mappings'.set_keymaps()",
            config.neuron_dir))
  M.map("i", "<cmd>lua require'neuron'.goto_index()<CR>")
end

return M
