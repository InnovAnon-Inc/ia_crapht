-- ia_crapht/resolver.lua
local modname = minetest.get_current_modname()
local assert  = ia_util.get_assert(modname)

-- Helper: Get the first recipe for an item (standardizes lookup)
local function get_primary_recipe(item_name)
    assert(item_name ~= nil, "item_name cannot be nil")
    
    local target = item_name
    -- If we are looking for the recipe of a group, find a member first
    if item_name:sub(1, 6) == "group:" then
        local members = ia_crapht.groups[item_name]
        if members and #members > 0 then
            target = members[1]
        else
            return nil -- Group has no members, cannot have a recipe
        end
    end
    
    return minetest.get_all_craft_recipes(target)
end

-- Checks if 'item' satisfies the 'ingredient' requirement (Direct or Group)
function ia_crapht.is_ingredient_match(item, ingredient)
    if item == ingredient then return true end
    if ingredient:sub(1, 6) == "group:" then
        local group_name = ingredient:sub(7)
        return minetest.get_item_group(item, group_name) > 0
    end
    return false
end

-- Iterates over recipe items regardless of 1D or 2D structure
function ia_crapht.for_each_ingredient(recipe, func)
    if not recipe or not recipe.items then return end
    for _, slot in pairs(recipe.items) do
        if type(slot) == "table" then
            for _, item in pairs(slot) do
                if item ~= "" then func(item) end
            end
        elseif slot ~= "" then
            func(slot)
        end
    end
end

-- Resolves an item down to its raw leaf components
function ia_crapht.get_leaf_requirements(item_name, req_table, visited)
    req_table = req_table or {}
    visited = visited or {}

    if visited[item_name] then return req_table end
    visited[item_name] = true

    local recipes = get_primary_recipe(item_name)
    
    if not recipes or #recipes == 0 then
        -- It's a leaf!
        req_table[item_name] = (req_table[item_name] or 0) + 1
    else
        ia_crapht.for_each_ingredient(recipes[1], function(ing)
            ia_crapht.get_leaf_requirements(ing, req_table, visited)
        end)
    end

    return req_table
end

-- Generates assembly steps
function ia_crapht.get_assembly_steps(item_name, steps, visited)
    steps = steps or {}
    visited = visited or {}

    if visited[item_name] then return steps end
    visited[item_name] = true

    -- If this is a group, resolve it to a real item for the blueprint
    local actual_item = item_name
    if item_name:sub(1, 6) == "group:" then
        local members = ia_crapht.groups[item_name]
        actual_item = (members and members[1]) or item_name
    end

    local recipes = get_primary_recipe(actual_item)
    if not recipes or #recipes == 0 then return steps end

    local recipe = recipes[1]
    ia_crapht.for_each_ingredient(recipe, function(ing)
        ia_crapht.get_assembly_steps(ing, steps, visited)
    end)

    local output_count = recipe.output:match("%s(%d+)$") or 1
    table.insert(steps, {
        name = actual_item, -- Record the actual item, not the group name
        count = tonumber(output_count),
        method = recipe.type or "normal"
    })

    return steps
end
