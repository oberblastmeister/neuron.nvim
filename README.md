# neuron.nvim

**note**: This is the unstable branch. If you are using the latest version of neuron use this branch

Make neovim the best note taking application. This plugin uses **neovim 0.5** to be able to take advantage of the latest cool features.

## Why

Neovim combined with lua and the neuron binary allow one of the coolest note taking experiences. This plugin is like notational velocity combined with vimwiki with much more features. Do you like notational velocity? Well you can do that here. Run `lua require'neuron/telescope'.find_zettels()` to be able to find your notes. If you typed something that doesn't match any existing note, it will create one. Because this plugin is built on the latest features from neovim 0.5, it allows for asynchronous update. For example, if you type a valid link (not just a valid link syntax wise, this plugin also checks if the file exists), it will put virtual text on the side. No need `:w` neovim to update these titles, they update automatically while you type. You can run a neuron server inside neovim asynchronously and it will render all your markdown notes on the web, and auto update on save.

## Features

- Great integration with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (currently the most extensible fuzzy finder)
- Because of that integration, can find tags, backlinks, notes
- Uses the new extmark api, sets an extmark for each valid link
- Fast because written in lua rather than vimscript

## Installation

### Prerequisites

Make sure you have the [neuron](https://github.com/srid/neuron/releases) binary installed

neuron.nvim depends on the neovim plugins [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) and [plenary.nvim](https://github.com/nvim-lua/plenary.nvim). Why plenary.nvim? Telescope.nvim depends on plenary.nvim which contains lots of useful functions for lua because of how minimal lua is. This encourages code reuse and allows for many cool things

### Plugins

using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use "oberblastmeister/neuron.nvim"
use "nvim-lua/plenary.nvim"
use "nvim-telescope/telescope.nvim"
```

vim-plug:

```vim
Plug 'oberblastmeister/neuron.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
```

## Usage

You must run the setup function to be able to use this plugins. The setup function takes your config and merges it with the default config. Any key not specified will be a default. In your [init.lua](https://github.com/neovim/neovim/issues/7895), run

```lua
-- these are all the default values
require'neuron'.setup {
    virtual_titles = true,
    mappings = true,
    run = nil, -- function to run when in neuron dir
    neuron_dir = "~/neuron", -- the directory of all of your notes, expanded by default (currently supports only one directory for notes, find a way to detect neuron.dhall to use any directory)
    leader = "gz", -- the leader key to for all mappings, remember with 'go zettel'
}
```

After running the setup function opening a note will show virtual text on the side to show the title of the note.

### Default mappings

```vim
 " click enter on [[my_link]] or [[[my_link]]] to enter it
nnoremap <buffer> <CR> <cmd>lua require'neuron'.enter_link()<CR>

" create a new note
nnoremap <buffer> gzn <cmd>lua require'neuron/cmd'.new_edit(require'neuron/config'.neuron_dir)<CR>

" find your notes, click enter to create the note if there are not notes that match
nnoremap <buffer> gzz <cmd>lua require'neuron/telescope'.find_zettels()<CR>
" insert the id of the note that is found
nnoremap <buffer> gzZ <cmd>lua require'neuron/telescope'.find_zettels {insert = true}<CR>

" find the backlinks of the current note all the note that link this note
nnoremap <buffer> gzb <cmd>lua require'neuron/telescope'.find_backlinks()<CR>
" same as above but insert the found id
nnoremap <buffer> gzB <cmd>lua require'neuron/telescope'.find_backlinks {insert = true}<CR>

" find all tags and insert
nnoremap <buffer> gzt <cmd>lua require'neuron/telescope'.find_tags()<CR>

" start the neuron server and render markdown, auto reload on save
nnoremap <buffer> gzs <cmd>lua require'neuron'.rib {address = "127.0.0.1:8200", verbose = true}<CR>

" go to next [[my_link]] or [[[my_link]]]
nnoremap <buffer> gz] <cmd>lua require'neuron'.goto_next_extmark()<CR>
" go to previous
nnoremap <buffer> gz[ <cmd>lua require'neuron'.goto_prev_extmark()<CR>]]
```

## Syntax Highlighting

neuron.nvim does not provide its own syntax highlighting out of the box because there are many better options. I recommend [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) because it currently offers the best syntax highlighting and also also to highlight code fences.

## Comparisons

neuron.nvim was heavily inspired by [neuron.vim](https://github.com/fiatjaf/neuron.vim). Here is table table to show the differences. I also used to use [vimwiki](https://github.com/vimwiki/vimwiki) so there is a comparison to that also.


|header|neuron.nvim|neuron.vim|vimwiki|
|------|-----------|----------|-------|
|virtual text|:heavy_check_mark:|:heavy_check_mark:|:x:
|asynchronous update|:heavy_check_mark:|:x:|N.A
|fuzzy finding|telescope.nvim|fzf.vim|:x:|
|asynchronous jobs integration|:heavy_check_mark:|:x:|:x:
|extmarks|:heavy_check_mark:|:x:|:x:
|written in|lua|vimscript|vimscript|
|works for older neovim versions|:x:|:heavy_check_mark:|:heavy_check_mark:
|actions for notes in fuzzy finder|coming soon|:x:|:x:
|render notes|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:
|supports vim|:x:|:heavy_check_mark:|:heavy_check_mark:
|use neuron binary|:heavy_check_mark:|:heavy_check_mark:|:x:

## License

Copyright (c) 2020 Brian Shu

neuron.nvim is distributed under the terms of the MIT license.

See the [LICENSE](LICENSE)
