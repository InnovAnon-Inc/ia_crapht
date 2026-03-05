-- ia_crapht/root_book.lua
-- The "Root" Book: Analyzes an item's industrial "Growth" (Upward Trace).

local modname = minetest.get_current_modname() or "ia_crapht"

ia_gutenberg.register_document(modname, "industrial_root_audit", {
    title = "Industrial Root Audit",
    description = "Trace an item's utility. Shows all products rooted in this material.",
    dynamic = true,

    privs = {forensics = true},
    craft_privs = {forensics = true},
    recipe = ia_gutenberg.get_standard_recipe(ia_gutenberg.recipe_tiers.POWERED, {
        "default:sapling",
    }),

    icon = "default_sapling.png",
    
    get_text = function(itemstack, user, target)
        local item_to_analyze = ""
        
        if target.type == "node" then
            item_to_analyze = target.name
        elseif target.type == "player" or target.type == "entity" then
            local wielded = target.ref:get_wielded_item()
            if not wielded:is_empty() then 
                item_to_analyze = wielded:get_name() 
            end
        end

        -- GLOBAL SINK REPORT
        if item_to_analyze == "" or item_to_analyze == modname .. ":industrial_root_audit" then
            local text = "GLOBAL UTILITY AUDIT: INDUSTRIAL SINKS\n"
            text = text .. "Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
            text = text .. "Identifying items with zero downstream uses.\n"
            text = text .. string.rep("=", 45) .. "\n\n"

            local usage_map = {}
            for name, _ in pairs(minetest.registered_items) do
                local recipes = minetest.get_all_craft_recipes(name)
                if recipes then
                    for _, r in ipairs(recipes) do
                        -- FIX: Use helper to populate usage map from 1D and 2D recipes
                        ia_crapht.for_each_ingredient(r, function(ing)
                            usage_map[ing] = true
                        end)
                    end
                end
            end

            local sinks = {}
            for name, _ in pairs(minetest.registered_items) do
                -- Check direct name AND if the item belongs to any used group
                local is_used = usage_map[name]
                if not is_used then
                    for group_node, _ in pairs(usage_map) do
                        if group_node:sub(1,6) == "group:" and ia_crapht.is_ingredient_match(name, group_node) then
                            is_used = true
                            break
                        end
                    end
                end

                if not is_used and not name:find("ia_crapht:") then
                    table.insert(sinks, name)
                end
            end
            table.sort(sinks)

            local current_mod = ""
            for _, name in ipairs(sinks) do
                local m = name:split(":")[1] or "unknown"
                if m ~= current_mod then
                    current_mod = m
                    text = text .. "\n[" .. current_mod:upper() .. "]\n" .. string.rep("-", 20) .. "\n"
                end
                text = text .. "  • " .. name .. "\n"
            end

            return text .. "\nTOTAL INDUSTRIAL SINKS: " .. #sinks
        end

        -- TARGETED ROOT AUDIT
        local products = {}
        for name, _ in pairs(minetest.registered_items) do
            local recipes = minetest.get_all_craft_recipes(name)
            if recipes then
                for _, recipe in ipairs(recipes) do
                    -- FIX: Use helper to iterate through 1D/2D ingredients
                    ia_crapht.for_each_ingredient(recipe, function(ingredient)
                        if ia_crapht.is_ingredient_match(item_to_analyze, ingredient) then
                            products[name] = true
                        end
                    end)
                end
            end
        end

        local text = "ROOT AUDIT: " .. item_to_analyze .. "\n"
        text = text .. string.rep("=", 40) .. "\n\n"
        
        local sorted = {}
        for name in pairs(products) do table.insert(sorted, name) end
        table.sort(sorted)

        if #sorted == 0 then
            text = text .. "!! STATUS: INDUSTRIAL DEAD-END !!\n"
            text = text .. "This material has no registered 'Roots' (Uses)."
        else
            text = text .. "PRODUCTS ROOTED IN THIS MATERIAL:\n"
            for _, name in ipairs(sorted) do 
                text = text .. "  [+] " .. name .. "\n" 
            end
            text = text .. "\nTOTAL INDUSTRIAL UTILITY: " .. #sorted
        end
        
        return text
    end
})
