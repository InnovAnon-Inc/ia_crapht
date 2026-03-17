-- ia_crapht/crawler.lua
local modname = minetest.get_current_modname()
local log     = ia_util.get_logger(modname)
local assert  = ia_util.get_assert(modname)

ia_crapht.cache = {}
ia_crapht.leafs = {}
ia_crapht.groups = {} 

function ia_crapht.analyze_world()
    log(ia_util.log_levels.INFO, "Initiating global industrial analysis...")
    
    -- 1. Map Groups (Item -> List of groups it belongs to)
    for name, def in pairs(minetest.registered_items) do
        if def.groups then
            for g, _ in pairs(def.groups) do
                local gname = "group:" .. g
                ia_crapht.groups[gname] = ia_crapht.groups[gname] or {}
                table.insert(ia_crapht.groups[gname], name)
            end
        end
    end

    -- 2. Map Recipes and Leafs
    for name, _ in pairs(minetest.registered_items) do
        local recipes = minetest.get_all_craft_recipes(name)
        if recipes and #recipes > 0 then
            ia_crapht.cache[name] = recipes
        else
            ia_crapht.leafs[name] = true
        end
    end
    
    log(ia_util.log_levels.INFO, "Analysis complete.")
end

minetest.register_on_mods_loaded(ia_crapht.analyze_world)
