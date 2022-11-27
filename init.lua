
temp_effects = {
  mod_storage = minetest.get_mod_storage(),
}

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/api.lua")
dofile(modpath.."/effects.lua")

