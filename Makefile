# adapted from https://raw.githubusercontent.com/nvim-telescope/telescope.nvim/master/Makefile


test:
	nvim --headless -c "PlenaryBustedDirectory lua/tests/automated/"

lint:
	luacheck lua
