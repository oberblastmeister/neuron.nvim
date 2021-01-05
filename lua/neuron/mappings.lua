local M = {}

function M.setup()
  vim.cmd [[
nnoremap <buffer> <CR> <cmd>lua require'neuron'.enter_link()<CR>

nnoremap <buffer> gzn <cmd>lua require'neuron/cmd'.new(require'neuron'.config.neuron_dir)<CR>

nnoremap <buffer> gzz <cmd>lua require'neuron/telescope'.find_zettels()<CR>
nnoremap <buffer> gzZ <cmd>lua require'neuron/telescope'.find_zettels {insert = true}<CR>

nnoremap <buffer> gzb <cmd>lua require'neuron/telescope'.find_backlinks()<CR>
nnoremap <buffer> gzB <cmd>lua require'neuron/telescope'.find_backlinks {insert = true}<CR>

nnoremap <buffer> gzt <cmd>lua require'neuron/telescope'.find_tags()<CR>

nnoremap <buffer> gzs <cmd>lua require'neuron'.rib {address = "127.0.0.1:8200", verbose = true}<CR>

nnoremap <buffer> gz] <cmd>lua require'neuron'.goto_next_extmark()<CR>
nnoremap <buffer> gz[ <cmd>lua require'neuron'.goto_prev_extmark()<CR>]]
end

return M
