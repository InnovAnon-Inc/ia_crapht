-- ia_crapht/gold_ingot_book.lua
local modname = minetest.get_current_modname()

ia_gutenberg.register_document(modname, "book_of_ex_nihilo", {
    title = "The Ex Nihilo Audit",
    description = "Detects infinite value glitches and items created from nothing.",
    dynamic = true,
    recipe = ia_gutenberg.get_standard_recipe(ia_gutenberg.recipe_tiers.POWERED, {"default:gold_ingot"}),
    icon = "default_gold_ingot.png",

    get_text = function(itemstack, user, target)
        local item = ia_util.get_target_name(target)
        
        if item == "" then
            local text = "ALCHEMICAL ANOMALY REPORT\n" .. string.rep("=", 30) .. "\n"
            -- Logic: Items with recipes but 0 leaf requirements are 'Ex Nihilo'
            for name, _ in pairs(ia_crapht.cache) do
                local leafs = ia_crapht.get_leaf_requirements(name)
                local leaf_count = 0
                for _ in pairs(leafs) do leaf_count = leaf_count + 1 end
                
                if leaf_count == 0 then
                    text = text .. "  [*] " .. name .. " (Zero-Input)\n"
                end
            end
            return text
        end

        local leafs = ia_crapht.get_leaf_requirements(item)
        local leaf_count = 0
        for _ in pairs(leafs) do leaf_count = leaf_count + 1 end
        
        return "EX NIHILO AUDIT: " .. item .. "\n" ..
               "Total Leaf Ingredients: " .. leaf_count .. "\n" ..
               (leaf_count == 0 and "WARNING: Infinite Resource/Static Definition detected." or "STATUS: Materially Sound.")
    end
})
