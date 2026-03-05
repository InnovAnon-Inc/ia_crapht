-- ia_crapht/init.lua

-- TODO need a book of useless items

assert(minetest.get_modpath('ia_util'))
assert(ia_util ~= nil)
local modname                    = minetest.get_current_modname() or "ia_crapht"
local storage                    = minetest.get_mod_storage()
ia_crapht                        = {
	--cache                    = {},
	--leafs                    = {},
}
local modpath, S                 = ia_util.loadmod(modname)
local log                        = ia_util.get_logger(modname)
local assert                     = ia_util.get_assert(modname)


