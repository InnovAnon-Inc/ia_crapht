-- ia_crapht/heavy_steel_bottle_book.lua
local modname = minetest.get_current_modname()

ia_gutenberg.register_document(modname, "book_of_bottlenecks", {
    title = "The Book of Bottlenecks",
    description = "Ranks items by industrial demand. Highlights critical failure points.",
    dynamic = true,
    recipe = ia_gutenberg.get_standard_recipe(ia_gutenberg.recipe_tiers.POWERED, {"vessels:steel_bottle"}),
    icon = "vessels_steel_bottle.png",

    get_text = function(itemstack, user, target)
        local item = ia_util.get_target_name(target)
        
        if item == "" then
            local text = "INFRASTRUCTURE CRITICALITY REPORT\n" .. string.rep("=", 35) .. "\n"
            local list = {}
            for name, score in pairs(ia_crapht.metrics.centrality) do
                if score > 5 then table.insert(list, {n=name, s=score}) end
            end
            table.sort(list, function(a,b) return a.s > b.s end)
            
            for i=1, math.min(20, #list) do
                text = text .. string.format("%2d. %-20s (Demand: %d)\n", i, list[i].n, list[i].s)
            end
            return text
        end

        local score = ia_crapht.metrics.centrality[item] or 0
        return "BOTTLENECK ANALYSIS: " .. item .. "\n" ..
               "Systemic Demand Score: " .. score .. "\n\n" ..
               "High scores indicate that many recipes will break if this item is unavailable."
    end
})
