# adapted from https://raw.githubusercontent.com/nvim-telescope/telescope.nvim/master/Makefile


test:
	nvim --noplugin --headless -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/automated/ { minimal_init = './scripts/minimal_init.vim' }"

lint:
	luacheck lua

gendocs:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "luafile ./scripts/gendocs.lua" -c 'qa'
