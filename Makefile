# adapted from https://raw.githubusercontent.com/nvim-telescope/telescope.nvim/master/Makefile


test:
	nvim --noplugin --headless -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/automated/ { minimal_init = './scripts/minimal_init.vim' }"
	# nvim --headless -c "PlenaryBustedDirectory lua/tests/automated/"

lint:
	luacheck lua
