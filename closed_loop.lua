-- ia_closed_loop/init.lua
----
----local log = ia_util.get_logger("ia_closed_loop")
----local items_with_recipes = {}
----local items_with_uses = {}
----local group_to_items = {}
----
------ 1. Map Groups to Items
----local function build_group_map()
----    for name, def in pairs(minetest.registered_items) do
----        if def.groups then
----            for group, _ in pairs(def.groups) do
----                group_to_items[group] = group_to_items[group] or {}
----                table.insert(group_to_items[group], name)
----            end
----        end
----    end
----end
----
------ 2. Deep Recipe Analysis
------local function analyze_crafts()
------    for name, _ in pairs(minetest.registered_items) do
------        local recipes = minetest.get_all_craft_recipes(name)
------        if recipes then
------            -- This item has a way to be created
------            items_with_recipes[name] = true
------            
------            for _, recipe in ipairs(recipes) do
------                -- recipe.items is a table of input itemstrings or groups
------                for _, input in ipairs(recipe.items) do
------                    -- Handle groups (e.g., "group:stick")
------                    if input:find("group:") then
------                        local group_name = input:gsub("group:", "")
------                        local members = group_to_items[group_name] or {}
------                        for _, member in ipairs(members) do
------                            items_with_uses[member] = true
------                        end
------                    else
------                        -- Handle direct items (e.g., "screwdriver:screwdriver")
------                        -- Strip count if present "default:dirt 99" -> "default:dirt"
------                        local item_name = input:match("([^ ]+)")
------                        if item_name then
------                            items_with_uses[item_name] = true
------                        end
------                    end
------                end
------            end
------        end
------    end
------end
----
------ 3. Check for Fuel (Common "Use" for wood/coal/etc)
----local function analyze_fuel()
----    for name, _ in pairs(minetest.registered_items) do
----        local fuel = minetest.get_craft_result({method="fuel", width=1, items={ItemStack(name)}})
----        if fuel and fuel.time > 0 then
----            items_with_uses[name] = true
----        end
----    end
----end
----
------ REPLACEMENT: Updated to count occurrences of items in recipes
----local function analyze_crafts()
----    for name, _ in pairs(minetest.registered_items) do
----        local recipes = minetest.get_all_craft_recipes(name)
----        if recipes and #recipes > 0 then
----            -- Store the first recipe as the "primary" for cost calculations
----            items_with_recipes[name] = recipes[1]
----
----            for _, recipe in ipairs(recipes) do
----                for _, input in ipairs(recipe.items) do
----                    -- 1. Handle Group inputs
----                    if input:find("group:") then
----                        local group_name = input:gsub("group:", "")
----                        local members = group_to_items[group_name] or {}
----                        for _, member in ipairs(members) do
----                            items_with_uses[member] = (items_with_uses[member] or 0) + 1
----                        end
----                    else
----                        -- 2. Handle Direct Item inputs (e.g., "screwdriver:screwdriver")
----                        local item_name = input:match("([^ ]+)")
----                        if item_name then
----                            items_with_uses[item_name] = (items_with_uses[item_name] or 0) + 1
----                        end
----                    end
----                end
----            end
----        end
----    end
----end
----
------ NEW: Recursive Cost Calculation (Calculates "Expense" Weight)
----local function get_resource_cost(item_name, depth)
----    -- Prevent infinite recursion from circular recipes (A -> B -> A)
----    if depth > 10 then return 1 end
----    if recipe_cache[item_name] then return recipe_cache[item_name] end
----
----    local recipe = items_with_recipes[item_name]
----    -- If no recipe exists, it is a "Base Resource" with a weight of 1
----    if not recipe then
----        return 1
----    end
----
----    local total_cost = 0
----    for _, input in ipairs(recipe.items) do
----        if input:find("group:") then
----            -- Average the cost of all items currently in the group
----            local group_name = input:gsub("group:", "")
----            local members = group_to_items[group_name] or {}
----            local group_sum = 0
----            for _, m in ipairs(members) do
----                group_sum = group_sum + get_resource_cost(m, depth + 1)
----            end
----            total_cost = total_cost + (group_sum / math.max(1, #members))
----        else
----            local input_name = input:match("([^ ]+)")
----            if input_name then
----                total_cost = total_cost + get_resource_cost(input_name, depth + 1)
----            end
----        end
----    end
----
----    -- Cache result to speed up subsequent lookups
----    recipe_cache[item_name] = total_cost
----    return total_cost
----end
----
----minetest.register_on_mods_loaded(function()
----    --log("info", "Starting Closed Loop Analysis...")
----    
----    build_group_map()
----    analyze_crafts()
----    analyze_fuel()
----
----    local no_recipes = {}
----    local no_uses = {}
----
----    for name, def in pairs(minetest.registered_items) do
----        -- Filter: Only items visible in creative and not technical aliases
----        local in_creative = (def.groups and (def.groups.not_in_creative_inventory or 0) == 0)
----        local is_real = name:find(":") and name ~= "air" and name ~= "ignore"
----
----        if is_real and in_creative then
----            if not items_with_recipes[name] then
----                table.insert(no_recipes, name)
----            end
----            if not items_with_uses[name] then
----                table.insert(no_uses, name)
----            end
----        end
----    end
----
----    table.sort(no_recipes)
----    table.sort(no_uses)
----
----    print("\n[IA_CLOSED_LOOP] REPORT")
----    print("---------------------------------")
----    print("DEAD ENDS (No Uses in recipes/fuel):")
----    for _, n in ipairs(no_uses) do print("  - " .. n) end
----    
----    print("\nUNCRAFTABLE (No Recipes found):")
----    for _, n in ipairs(no_recipes) do print("  - " .. n) end
----    print("---------------------------------\n")
----
----    -- Sort and Print Popularity
----    table.sort(report_data, function(a, b) return a.uses > b.uses end)
----    print("\n[TOP 10 MOST POPULAR ITEMS (Used as ingredients)]")
----    for i=1, 10 do
----        local d = report_data[i]
----        if d and d.uses > 0 then
----            print(string.format("  %d. %-35s : %d recipes", i, d.name, d.uses))
----        end
----    end
----
----    -- Sort and Print Expense
----    table.sort(report_data, function(a, b) return a.cost > b.cost end)
----    print("\n[TOP 10 MOST EXPENSIVE ITEMS (Total Raw Materials)]")
----    for i=1, 10 do
----        local d = report_data[i]
----        if d and d.has_recipe then
----            print(string.format("  %d. %-35s : Weight %.1f", i, d.name, d.cost))
----        end
----    end
----end)
--local log = ia_util.get_logger("ia_closed_loop")
--local items_with_recipes = {} -- name -> recipe_table
--local items_with_uses = {}    -- name -> count
--local group_to_items = {}
--local recipe_cache = {}
--
---- 1. Map Groups to Items
--local function build_group_map()
--    for name, def in pairs(minetest.registered_items) do
--        if def.groups then
--            for group, _ in pairs(def.groups) do
--                group_to_items[group] = group_to_items[group] or {}
--                table.insert(group_to_items[group], name)
--            end
--        end
--    end
--end
--
------ 2. Deep Recipe Analysis
----local function analyze_crafts()
----    for name, _ in pairs(minetest.registered_items) do
----        local recipes = minetest.get_all_craft_recipes(name)
----        if recipes and #recipes > 0 then
----            items_with_recipes[name] = recipes[1] -- Store primary recipe for cost analysis
----            
----            for _, recipe in ipairs(recipes) do
----                for _, input in ipairs(recipe.items) do
----                    if input:find("group:") then
----                        local group_name = input:gsub("group:", "")
----                        local members = group_to_items[group_name] or {}
----                        for _, member in ipairs(members) do
----                            items_with_uses[member] = (items_with_uses[member] or 0) + 1
----                        end
----                    else
----                        local item_name = input:match("([^ ]+)")
----                        if item_name then
----                            items_with_uses[item_name] = (items_with_uses[item_name] or 0) + 1
----                        end
----                    end
----                end
----            end
----        end
----    end
----end
--
------ 3. Recursive Cost Calculation (The "Expensive" Metric)
----local function get_resource_cost(item_name, depth)
----    if depth > 10 then return 1 end -- Prevent infinite loops (circular recipes)
----    if recipe_cache[item_name] then return recipe_cache[item_name] end
----
----    local recipe = items_with_recipes[item_name]
----    if not recipe then
----        return 1 -- Base resource
----    end
----
----    local total_cost = 0
----    for _, input in ipairs(recipe.items) do
----        local input_name = input:match("([^ ]+)")
----        if input:find("group:") then
----            -- For groups, we take the average cost of its members
----            local group_name = input:gsub("group:", "")
----            local members = group_to_items[group_name] or {}
----            local group_cost = 0
----            for _, m in ipairs(members) do
----                group_cost = group_cost + get_resource_cost(m, depth + 1)
----            end
----            total_cost = total_cost + (group_cost / math.max(1, #members))
----        elseif input_name then
----            total_cost = total_cost + get_resource_cost(input_name, depth + 1)
----        end
----    end
----
----    recipe_cache[item_name] = total_cost
----    return total_cost
----end
--
---- REPLACEMENT: Updated to count occurrences of items in recipes
--local function analyze_crafts()
--    for name, _ in pairs(minetest.registered_items) do
--        local recipes = minetest.get_all_craft_recipes(name)
--        if recipes and #recipes > 0 then
--            -- Store the first recipe as the "primary" for cost calculations
--            items_with_recipes[name] = recipes[1]
--
--            for _, recipe in ipairs(recipes) do
--                for _, input in ipairs(recipe.items) do
--                    -- 1. Handle Group inputs
--                    if input:find("group:") then
--                        local group_name = input:gsub("group:", "")
--                        local members = group_to_items[group_name] or {}
--                        for _, member in ipairs(members) do
--                            items_with_uses[member] = (items_with_uses[member] or 0) + 1
--                        end
--                    else
--                        -- 2. Handle Direct Item inputs (e.g., "screwdriver:screwdriver")
--                        local item_name = input:match("([^ ]+)")
--                        if item_name then
--                            items_with_uses[item_name] = (items_with_uses[item_name] or 0) + 1
--                        end
--                    end
--                end
--            end
--        end
--    end
--end
--
---- NEW: Recursive Cost Calculation (Calculates "Expense" Weight)
--local function get_resource_cost(item_name, depth)
--    -- Prevent infinite recursion from circular recipes (A -> B -> A)
--    if depth > 10 then return 1 end
--    if recipe_cache[item_name] then return recipe_cache[item_name] end
--
--    local recipe = items_with_recipes[item_name]
--    -- If no recipe exists, it is a "Base Resource" with a weight of 1
--    if not recipe then
--        return 1
--    end
--
--    local total_cost = 0
--    for _, input in ipairs(recipe.items) do
--        if input:find("group:") then
--            -- Average the cost of all items currently in the group
--            local group_name = input:gsub("group:", "")
--            local members = group_to_items[group_name] or {}
--            local group_sum = 0
--            for _, m in ipairs(members) do
--                group_sum = group_sum + get_resource_cost(m, depth + 1)
--            end
--            total_cost = total_cost + (group_sum / math.max(1, #members))
--        else
--            local input_name = input:match("([^ ]+)")
--            if input_name then
--                total_cost = total_cost + get_resource_cost(input_name, depth + 1)
--            end
--        end
--    end
--
--    -- Cache result to speed up subsequent lookups
--    recipe_cache[item_name] = total_cost
--    return total_cost
--end
--
--minetest.register_on_mods_loaded(function()
--    --log("info", "Starting Advanced Closed Loop Analysis...")
--    
--    build_group_map()
--    analyze_crafts()
--    
--    local report_data = {}
--
--    for name, def in pairs(minetest.registered_items) do
--        local in_creative = (def.groups and (def.groups.not_in_creative_inventory or 0) == 0)
--        local is_real = name:find(":") and name ~= "air" and name ~= "ignore"
--
--        if is_real and in_creative then
--            table.insert(report_data, {
--                name = name,
--                uses = items_with_uses[name] or 0,
--                cost = get_resource_cost(name, 0),
--                has_recipe = items_with_recipes[name] ~= nil
--            })
--        end
--    end
--
--    -- Sort for Popularity (Uses)
--    table.sort(report_data, function(a, b) return a.uses > b.uses end)
--    print("\n[TOP 10 MOST USEFUL/POPULAR ITEMS]")
--    for i=1, 10 do
--        local d = report_data[i]
--        if d then print(string.format("  %d. %-30s (%d recipes)", i, d.name, d.uses)) end
--    end
--
--    -- Sort for Expense (Raw Cost)
--    table.sort(report_data, function(a, b) return a.cost > b.cost end)
--    print("\n[TOP 10 MOST EXPENSIVE ITEMS (RAW RESOURCE WEIGHT)]")
--    for i=1, 10 do
--        local d = report_data[i]
--        if d then print(string.format("  %d. %-30s (Weight: %.1f)", i, d.name, d.cost)) end
--    end
--
--    -- Dead Ends and Uncraftables (from previous logic)
--    print("\n[CRITICAL GAPS]")
--    local dead_ends = 0
--    for _, d in ipairs(report_data) do
--        if d.uses == 0 then dead_ends = dead_ends + 1 end
--    end
--    print("  - Items with zero uses: " .. dead_ends)
--    print("---------------------------------\n")
--end)
-- ia_closed_loop/init.lua
local log = ia_util.get_logger("ia_closed_loop")
local items_with_recipes = {} -- name -> recipe table
local items_with_uses = {}    -- name -> count
local group_to_items = {}
local recipe_cache = {}

-- 1. Map Groups to Items
local function build_group_map()
    for name, def in pairs(minetest.registered_items) do
        if def.groups then
            for group, _ in pairs(def.groups) do
                group_to_items[group] = group_to_items[group] or {}
                table.insert(group_to_items[group], name)
            end
        end
    end
end

-- 2. Recursive Cost Calculation (Expense Weight)
local function get_resource_cost(item_name, depth)
    -- Prevent infinite recursion from circular recipes (A -> B -> A)
    if depth > 10 then return 1 end 
    if recipe_cache[item_name] then return recipe_cache[item_name] end

    local recipe = items_with_recipes[item_name]
    -- If no recipe exists, it is a "Base Resource" with a weight of 1
    if not recipe then
        return 1
    end

    local total_cost = 0
    for _, input in ipairs(recipe.items) do
        if input:find("group:") then
            -- Average the cost of all items currently in the group
            local group_name = input:gsub("group:", "")
            local members = group_to_items[group_name] or {}
            local group_sum = 0
            for _, m in ipairs(members) do
                group_sum = group_sum + get_resource_cost(m, depth + 1)
            end
            total_cost = total_cost + (group_sum / math.max(1, #members))
        else
            local input_name = input:match("([^ ]+)")
            if input_name then
                total_cost = total_cost + get_resource_cost(input_name, depth + 1)
            end
        end
    end

    recipe_cache[item_name] = total_cost
    return total_cost
end

-- 3. Deep Recipe Analysis
local function analyze_crafts()
    for name, _ in pairs(minetest.registered_items) do
        local recipes = minetest.get_all_craft_recipes(name)
        if recipes and #recipes > 0 then
            -- Store first recipe for cost analysis
            items_with_recipes[name] = recipes[1]
            
            for _, recipe in ipairs(recipes) do
                for _, input in ipairs(recipe.items) do
                    if input:find("group:") then
                        local group_name = input:gsub("group:", "")
                        local members = group_to_items[group_name] or {}
                        for _, member in ipairs(members) do
                            items_with_uses[member] = (items_with_uses[member] or 0) + 1
                        end
                    else
                        local item_name = input:match("([^ ]+)")
                        if item_name then
                            items_with_uses[item_name] = (items_with_uses[item_name] or 0) + 1
                        end
                    end
                end
            end
        end
    end
end

-- 4. Check for Fuel (Adds "Use" for items like wood/coal)
local function analyze_fuel()
    for name, _ in pairs(minetest.registered_items) do
        local fuel = minetest.get_craft_result({method="fuel", width=1, items={ItemStack(name)}})
        if fuel and fuel.time > 0 then
            items_with_uses[name] = (items_with_uses[name] or 0) + 1
        end
    end
end

minetest.register_on_mods_loaded(function()
    --log("info", "Starting Combined Closed Loop Analysis...")
    
    build_group_map()
    analyze_crafts()
    analyze_fuel()

    local report_data = {}
    local no_recipes = {}
    local no_uses = {}

    for name, def in pairs(minetest.registered_items) do
        local in_creative = (def.groups and (def.groups.not_in_creative_inventory or 0) == 0)
        local is_real = name:find(":") and name ~= "air" and name ~= "ignore"

        if is_real and in_creative then
            local data = {
                name = name,
                uses = items_with_uses[name] or 0,
                cost = get_resource_cost(name, 0),
                has_recipe = items_with_recipes[name] ~= nil
            }
            table.insert(report_data, data)

            -- Collect Gaps
            if not data.has_recipe then table.insert(no_recipes, name) end
            if data.uses == 0 then table.insert(no_uses, name) end
        end
    end

    -- SORTING
    table.sort(no_recipes)
    table.sort(no_uses)

    -- OUTPUT REPORT
    print("\n" .. string.rep("=", 40))
    print("IA_CLOSED_LOOP FULL AUDIT REPORT")
    print(string.rep("=", 40))

    print("\n[1] DEAD ENDS (Items with NO uses):")
    for _, n in ipairs(no_uses) do print("  - " .. n) end

    print("\n[2] UNCRAFTABLE (Items with NO recipes):")
    for _, n in ipairs(no_recipes) do print("  - " .. n) end

    -- Sort for Popularity
    table.sort(report_data, function(a, b) return a.uses > b.uses end)
    print("\n[3] TOP 10 MOST POPULAR (Highest usage in recipes):")
    for i=1, 10 do
        local d = report_data[i]
        if d and d.uses > 0 then 
            print(string.format("  %d. %-35s (%d uses)", i, d.name, d.uses)) 
        end
    end

    -- Sort for Expense
    table.sort(report_data, function(a, b) return a.cost > b.cost end)
    print("\n[4] TOP 10 MOST EXPENSIVE (Raw resource weight):")
    for i=1, 10 do
        local d = report_data[i]
        if d and d.has_recipe then 
            print(string.format("  %d. %-35s (Weight %.1f)", i, d.name, d.cost)) 
        end
    end
    print("\n" .. string.rep("=", 40) .. "\n")
end)
