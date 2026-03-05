-- ia_crapht/bucket_of_water_book.lua
local modname = minetest.get_current_modname()

ia_gutenberg.register_document(modname, "book_of_cycles", { -- FIXME don't wax poetic
    title = "The Book of Cycles",
    description = "Identifies circular dependencies and feedback loops in manufacturing.",
    dynamic = true,
    recipe = ia_gutenberg.get_standard_recipe(ia_gutenberg.recipe_tiers.POWERED, {"bucket:bucket_water"}),
    icon = "bucket_water.png",

    get_text = function(itemstack, user, target)
        local item = ia_util.get_target_name(target) -- Assume helper exists
        
        if item == "" then
            local text = "GLOBAL RECURSION AUDIT\n" .. string.rep("=", 30) .. "\n"
            local count = 0
            for name, is_cycle in pairs(ia_crapht.metrics.cycles) do
                if is_cycle then
                    text = text .. "  [!] " .. name .. "\n"
                    count = count + 1
                end
            end
            return text .. "\nTotal Loops Detected: " .. count
        end

        local is_looping = ia_crapht.metrics.cycles[item]
        return "CYCLE ANALYSIS: " .. item .. "\n" ..
               string.rep("-", 30) .. "\n" ..
               "Status: " .. (is_looping and "RECURSIVE LOOP" or "LINEAR PATH") .. "\n\n" ..
               "Recursive items can lead to infinite resource feedback if not balanced."
    end
})
