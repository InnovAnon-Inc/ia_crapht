-- ia_crapht/leaf_book.lua
-- The "Leaf Index": A global report of raw materials (Global) or assembly steps (Targeted).

local modname = minetest.get_current_modname() or "ia_crapht"

ia_gutenberg.register_document(modname, "global_leaf_ledger", {
    title = "The Master Leaf Ledger",
    description = "Global raw material index or targeted assembly blueprint.",
    dynamic = true, -- Changed to true to support targeted analysis
    
    privs = {forensics = true},
    craft_privs = {forensics = true},
    recipe = ia_gutenberg.get_standard_recipe(ia_gutenberg.recipe_tiers.POWERED, {
        "default:diamond",
        "group:leaves",
    }),
    
    icon = "default_leaves.png",
    
    get_text = function(itemstack, user, target)
        local item_to_analyze = ""
        
        -- Target Detection
        if target.type == "node" then
            item_to_analyze = target.name
        elseif target.type == "player" or target.type == "entity" then
            local wielded = target.ref:get_wielded_item()
            if not wielded:is_empty() then 
                item_to_analyze = wielded:get_name() 
            end
        end

        -- LOGIC: GLOBAL LEAF REPORT (If no target or targeting self)
        if item_to_analyze == "" or item_to_analyze == modname .. ":global_leaf_ledger" then
            local text = "GLOBAL RAW MATERIAL INDEX (LEAFS)\n"
            text = text .. "Industrial Audit: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
            text = text .. string.rep("=", 40) .. "\n\n"

            local sorted_leafs = {}
            for name, _ in pairs(ia_crapht.leafs) do 
                table.insert(sorted_leafs, name) 
            end
            table.sort(sorted_leafs)

            local current_mod = ""
            for _, name in ipairs(sorted_leafs) do
                local mod_prefix = name:split(":")[1] or "unknown"
                if mod_prefix ~= current_mod then
                    current_mod = mod_prefix
                    text = text .. "\n[" .. current_mod:upper() .. "]\n" .. string.rep("-", 20) .. "\n"
                end
                text = text .. "  • " .. name .. "\n"
            end

            text = text .. "\n" .. string.rep("=", 40) .. "\n"
            text = text .. "TOTAL RAW MATERIALS INDEXED: " .. #sorted_leafs
            return text
        end

        -- LOGIC: TARGETED ASSEMBLY BLUEPRINT
        local text = "ASSEMBLY BLUEPRINT: " .. item_to_analyze .. "\n"
        text = text .. string.rep("=", 40) .. "\n\n"

        -- 1. Bill of Materials (Raw Leaf Ingredients)
        local leafs = ia_crapht.get_leaf_requirements(item_to_analyze)
        text = text .. "PHASE 1: RAW MATERIAL GATHERING\n"
        text = text .. "------------------------------\n"
        
        local sorted_bill = {}
        for name, count in pairs(leafs) do 
            table.insert(sorted_bill, {n=name, c=count}) 
        end
        table.sort(sorted_bill, function(a,b) return a.n < b.n end)

        for _, data in ipairs(sorted_bill) do
            text = text .. string.format(" [ ] %-25s (Qty: %d)\n", data.n, data.c)
        end

        -- 2. Assembly Steps
        text = text .. "\nPHASE 2: ASSEMBLY STEPS\n"
        text = text .. "------------------------------\n"
        
        local steps = ia_crapht.get_assembly_steps(item_to_analyze)
        if not steps or #steps == 0 then
            text = text .. "!! STATUS: RAW MATERIAL !!\n"
            text = text .. "This item is a base leaf. No assembly required."
        else
            for i, step in ipairs(steps) do
                -- Display step with method info for clarity (e.g., cooking vs normal craft)
                local method_tag = "[" .. step.method:upper() .. "]"
                text = text .. string.format(" %2d. %-10s Craft %d x %s\n", i, method_tag, step.count, step.name)
            end
        end

        text = text .. "\n" .. string.rep("=", 40) .. "\n"
        text = text .. "END OF BLUEPRINT"
        
        return text
    end
})
